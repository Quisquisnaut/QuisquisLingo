import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _expression = '{Io} [prendo|vorrei] un cappuccino';
const _expanded = [
  'Prendo un cappuccino',
  'Vorrei un cappuccino',
  'Io prendo un cappuccino',
  'Io vorrei un cappuccino',
];
const _translations = [
  'Vorrei un cappuccino',
  'Prendo un cappuccino',
  'Desidero un cappuccino',
  'Mi piacerebbe un cappuccino',
  'Un cappuccino per favore',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    _mockAudio();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Translation author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  testWidgets(
    'Expand and Copy all are selectable and make no authoring or preference writes',
    (tester) async {
      _viewport(tester);
      String? clipboard;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final source = _exercise(const [_expression]);
      final beforeJson = jsonEncode(source.toV2Json());
      final preferences = await _preferences();
      Exercise? saved;
      await _openEditor(tester, source, (value) => saved = value);
      await _tap(tester, find.byKey(const Key('expand-translation-answers')));
      expect(find.text('4 answers generated'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText && widget.data == _expanded.join('\n'),
        ),
        findsOneWidget,
      );
      await _tap(tester, find.text('Copy all'));
      expect(clipboard, _expanded.join('\n'));
      await _tap(tester, find.text('Close'));
      expect(await _acceptedText(tester), _expression);
      expect(saved, isNull);
      expect(jsonEncode(source.toV2Json()), beforeJson);
      expect(await _preferences(), preferences);
      expect(tester.takeException(), isNull);
    },
  );

  for (final state in PublicationState.values) {
    testWidgets(
      'materialized answers survive source edits and $state save/reload with canonical metadata',
      (tester) async {
        _viewport(tester, width: 600);
        final source = _exercise(
          const [_expression],
          state: state,
          metadata: true,
        );
        Exercise? saved;
        await _openEditor(tester, source, (value) => saved = value);
        await _tap(tester, find.byKey(const Key('expand-translation-answers')));
        await _tap(tester, find.text('Use expanded answers'));
        expect(
          find.text('4 answers generated; 4 added; 0 already present.'),
          findsOneWidget,
        );
        expect((await _acceptedText(tester)).split('\n'), [
          _expression,
          ..._expanded,
        ]);
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          _field('Accepted translations'),
          ['[caffè|tè]', ..._expanded].join('\n'),
        );
        expect((await _acceptedText(tester)).split('\n').skip(1), _expanded);
        await tester.enterText(
          _field('Accepted translations'),
          _expanded.join('\n'),
        );
        final beforePreview = await _preferences();
        await _tap(tester, find.byKey(const Key('exercise-preview')));
        await _pumpUntil(tester, find.byType(RoundScreen));
        final preview = tester.widget<RoundScreen>(find.byType(RoundScreen));
        expect(preview.previewMode, isTrue);
        expect(preview.round.exercises.single.accepted, _expanded);
        expect(preview.round.exercises.single.feedback, source.feedback);
        expect(
          preview.round.exercises.single.evaluation.normalization,
          source.evaluation.normalization,
        );
        expect(
          preview.round.exercises.single.promptElements.map(
            (item) => item.toJson(),
          ),
          source.promptElements.map((item) => item.toJson()),
        );
        expect(preview.round.exercises.single.publicationState, state);
        expect(saved, isNull);
        expect(await _preferences(), beforePreview);
        await _tap(tester, find.byType(BackButton));
        await _tap(
          tester,
          find.text(state.isPublished ? 'Save' : 'Save as draft').last,
        );
        await _settle(tester);
        expect(saved, isNotNull);
        expect(saved!.accepted, _expanded);
        expect(saved!.id, source.id);
        expect(saved!.publicationState, state);
        expect(saved!.feedback, source.feedback);
        expect(
          saved!.evaluation.normalization,
          source.evaluation.normalization,
        );
        expect(
          saved!.promptElements.map((item) => item.toJson()),
          source.promptElements.map((item) => item.toJson()),
        );
        final reloaded = Exercise.fromV2Json(
          jsonDecode(jsonEncode(saved!.toV2Json())) as Map<String, dynamic>,
          contentId: saved!.id,
          editorTemplate: saved!.editorTemplate,
          publicationState: saved!.publicationState,
        );
        expect(reloaded.toV2Json(), saved!.toV2Json());
        await _openEditor(tester, reloaded, (_) {});
        expect((await _acceptedText(tester)).split('\n'), _expanded);
        expect(source.accepted, const [_expression]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('overflow offers a clear error and cannot partially materialize', (
    tester,
  ) async {
    _viewport(tester);
    final expression =
        '[${List.generate(129, (index) => 'answer$index').join('|')}]';
    Exercise? saved;
    await _openEditor(
      tester,
      _exercise([expression]),
      (value) => saved = value,
    );
    await _tap(tester, find.byKey(const Key('expand-translation-answers')));
    expect(find.text('Cannot expand answers'), findsOneWidget);
    expect(
      find.text(
        'This expression generates more than 128 answers. Simplify it before expanding.',
      ),
      findsOneWidget,
    );
    expect(find.text('Use expanded answers'), findsNothing);
    await _tap(tester, find.text('Close'));
    expect(await _acceptedText(tester), expression);
    expect(saved, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Remove image changes unsaved Translation Preview and Save without losing canonical metadata',
    (tester) async {
      _viewport(tester, width: 600);
      final source = _exercise(
        const ['Vorrei un cappuccino'],
        metadata: true,
        image: true,
      );
      final originalJson = jsonEncode(source.toV2Json());
      Exercise? saved;
      await _openEditor(tester, source, (value) => saved = value);
      await _tap(tester, find.text('Remove image'));
      final beforePreview = await _preferences();
      await _tap(tester, find.byKey(const Key('exercise-preview')));
      await _pumpUntil(tester, find.byType(RoundScreen));
      final preview = tester.widget<RoundScreen>(find.byType(RoundScreen));
      final candidate = preview.round.exercises.single;
      final expectedPrompt = source.promptElements
          .where((element) => element.type != 'image')
          .map((element) => element.toJson())
          .toList();
      expect(candidate.imageAsset, isEmpty);
      expect(
        candidate.promptElements.map((element) => element.toJson()),
        expectedPrompt,
      );
      expect(candidate.evaluation.toJson(), source.evaluation.toJson());
      expect(candidate.feedback, source.feedback);
      expect(candidate.id, source.id);
      expect(candidate.updatedAt, source.updatedAt);
      expect(saved, isNull);
      expect(await _preferences(), beforePreview);
      expect(jsonEncode(source.toV2Json()), originalJson);
      await _tap(tester, find.byType(BackButton));
      await _tap(tester, find.text('Save').last);
      await _settle(tester);
      expect(saved, isNotNull);
      expect(saved!.imageAsset, isEmpty);
      expect(
        saved!.promptElements.map((element) => element.toJson()),
        expectedPrompt,
      );
      expect(saved!.evaluation.toJson(), source.evaluation.toJson());
      expect(saved!.feedback, source.feedback);
      expect(saved!.id, source.id);
      expect(saved!.publicationState, source.publicationState);
      expect(jsonEncode(source.toV2Json()), originalJson);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final count in [1, 2, 3, 5]) {
      testWidgets(
        'incorrect response shows ${count > 3 ? 3 : count} of $count translations at 320px in $brightness',
        (tester) async {
          _viewport(tester);
          final exercise = _exercise(_translations.take(count).toList());
          final before = await _preferences();
          await _answer(tester, exercise, 'Io bevo acqua', brightness);
          expect(find.text('Incorrect'), findsOneWidget);
          final displayed = _feedbackAnswers(tester);
          expect(displayed, hasLength(count > 3 ? 3 : count));
          expect(displayed.toSet().length, displayed.length);
          expect(displayed, everyElement(isIn(exercise.accepted)));
          expect(
            find.text(
              count > 3
                  ? 'Some possible translations:'
                  : 'Correct translations:',
            ),
            findsOneWidget,
          );
          expect(await _preferences(), before);
          expect(tester.takeException(), isNull);
        },
      );
    }
    for (final count in [1, 2, 4]) {
      testWidgets(
        'correct response shows ${count == 1
            ? 0
            : count == 2
            ? 1
            : 2} alternatives from $count at 320px in $brightness',
        (tester) async {
          _viewport(tester);
          final exercise = _exercise(_translations.take(count).toList());
          await _answer(tester, exercise, _translations.first, brightness);
          expect(find.text('Correct'), findsOneWidget);
          final displayed = _feedbackAnswers(tester);
          expect(
            displayed,
            hasLength(
              count == 1
                  ? 0
                  : count == 2
                  ? 1
                  : 2,
            ),
          );
          expect(displayed, isNot(contains(_translations.first)));
          expect(
            find.byKey(const Key('translation-feedback-heading')),
            count == 1 ? findsNothing : findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'typo accepted response excludes its canonical match in $brightness',
      (tester) async {
        _viewport(tester);
        await _answer(
          tester,
          _exercise(_translations.take(3).toList()),
          'Vorrei un capuccino',
          brightness,
        );
        expect(find.text('Correct'), findsOneWidget);
        final displayed = _feedbackAnswers(tester);
        expect(displayed, hasLength(2));
        expect(displayed, isNot(contains('Vorrei un cappuccino')));
        expect(find.textContaining('explicitly allowed typo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);
Future<String> _acceptedText(WidgetTester tester) async {
  final finder = _field('Accepted translations');
  await _reveal(tester, finder);
  return tester.widget<TextField>(finder).controller!.text;
}

List<String> _feedbackAnswers(WidgetTester tester) => [
  for (var index = 0; index < 5; index++)
    if (find
        .byKey(ValueKey('translation-feedback-answer-$index'))
        .evaluate()
        .isNotEmpty)
      tester
          .widget<Text>(
            find.byKey(ValueKey('translation-feedback-answer-$index')),
          )
          .data!
          .substring(2),
];

void _viewport(WidgetTester tester, {double width = 320}) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 100 && finder.evaluate().isEmpty; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
  }
  expect(finder, findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pump(const Duration(milliseconds: 200));
  await _reveal(tester, finder);
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).first;
    final scrollState = tester.state<ScrollableState>(scrollable);
    scrollState.position.jumpTo(scrollState.position.minScrollExtent);
    await tester.pump();
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: scrollable,
      maxScrolls: 20,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  // A jump needs a rendered frame before its target has usable hit-test bounds.
  await tester.pump(const Duration(milliseconds: 200));
}

void _mockAudio() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

Future<void> _openEditor(
  WidgetTester tester,
  Exercise exercise,
  ValueChanged<Exercise> onSaved,
) async {
  final course = _course(exercise);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<Exercise>(
                  builder: (_) => ExerciseEditorScreen(
                    exercise: exercise,
                    title: 'Type the translation',
                    isNew: false,
                    course: course,
                    lesson: course.lessons.single,
                    round: course.lessons.single.rounds.single,
                    onExerciseSaved: onSaved,
                  ),
                ),
              ),
              child: const Text('Open Exercise'),
            ),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Open Exercise'));
  await _reveal(tester, _field('Accepted translations'));
}

Future<void> _answer(
  WidgetTester tester,
  Exercise exercise,
  String response,
  Brightness brightness,
) async {
  final course = _course(exercise);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
        round: course.lessons.single.rounds.single,
        roundIndex: 0,
        ttsLanguage: 'it-IT',
        previewMode: true,
      ),
    ),
  );
  await _pumpUntil(tester, _field('Your answer'));
  await tester.enterText(_field('Your answer'), response);
  await _tap(tester, find.text('Check'));
  await _pumpUntil(tester, find.byKey(const Key('exercise-feedback-surface')));
}

Future<Map<String, Object?>> _preferences() async {
  final preferences = await SharedPreferences.getInstance();
  return {for (final key in preferences.getKeys()) key: preferences.get(key)};
}

Exercise _exercise(
  List<String> accepted, {
  PublicationState state = PublicationState.published,
  bool metadata = false,
  bool image = false,
}) => Exercise.v2(
  id: 'translation-22603',
  updatedAt: DateTime.utc(2026, 9, 6),
  publicationState: state,
  editorTemplate: 'type_translation',
  promptElements: [
    const PromptElement(type: 'text', text: 'I would like a cappuccino.'),
    if (metadata)
      const PromptElement(
        role: 'note',
        type: 'text',
        text: 'Preserved source metadata',
      ),
    if (image)
      const PromptElement(
        role: 'clue',
        type: 'image',
        asset: 'assets/exercise_images/bus.webp',
      ),
  ],
  interaction: const ExerciseInteraction(kind: 'input'),
  evaluation: ExerciseEvaluation(
    kind: 'text_match',
    accepted: accepted,
    normalization: const {
      'case': 'ignore',
      'punctuation': 'ignore',
      'whitespace': 'normalize',
      'accents': 'preserve',
    },
  ),
  feedback: metadata
      ? const {'correct': 'Preserved custom feedback'}
      : const {},
);

Course _course(Exercise exercise) => Course(
  courseId: 'translation-ui-22603',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Translation UI course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'translation-lesson',
      title: 'Translation Lesson',
      rounds: [
        LearningRound(
          id: 'translation-round',
          title: 'Translation Round',
          exercises: [exercise],
        ),
      ],
    ),
  ],
);
