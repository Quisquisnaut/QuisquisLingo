import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/portable_exercise_image.dart';
import 'package:quisquislingo_app/widgets/script_recognition_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String blueImage;
  late String redImage;

  setUpAll(() async {
    blueImage = await _image(Colors.blue);
    redImage = await _image(Colors.red);
  });

  setUp(() async {
    _mockAudio();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Script author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  for (final mode in ScriptRecognitionMode.values) {
    test(
      '$mode canonical Select survives Draft and Published JSON round trips',
      () {
        final original = _exercise(mode, blueImage, redImage);
        final controller = ScriptRecognitionController(original);
        addTearDown(controller.dispose);
        expect(controller.mode, mode);
        for (final state in PublicationState.values) {
          final built = controller.build(state);
          final restored = _restore(built);
          expect(restored.toJson(), built.toJson());
          expect(restored.publicationState, state);
          expect(restored.interaction.kind, 'select');
          expect(restored.evaluation.kind, 'selected_items');
          expect(restored.evaluation.correctItemIds, ['letter-a']);
          expect(restored.updatedAt, original.updatedAt);
          expect(restored.hint, original.hint);
          expect(restored.feedback, original.feedback);
          expect(restored.missingWords, original.missingWords);
          expect(
            restored.evaluation.normalization,
            original.evaluation.normalization,
          );
          expect(_errors(restored), isEmpty);
          final reloaded = ScriptRecognitionController(restored);
          expect(reloaded.mode, mode);
          reloaded.dispose();
        }
      },
    );
  }

  test(
    'option editing, reordering, deletion and addition preserve identities',
    () {
      final original = _exercise(
        ScriptRecognitionMode.imageToText,
        blueImage,
        redImage,
      );
      final controller = ScriptRecognitionController(original);
      addTearDown(controller.dispose);
      controller.optionText(0).text = 'alpha';
      controller.moveOption(0, 1);
      expect(controller.optionId(1), 'letter-a');
      expect(controller.isCorrect(1), isTrue);
      controller.removeOption(0);
      controller.addOption();
      final firstNew = controller.optionId(1);
      expect(firstNew, isNot(anyOf('letter-a', 'letter-b')));
      controller.removeOption(1);
      controller.addOption();
      expect(controller.optionId(1), isNot(firstNew));
      final built = controller.build(PublicationState.draft);
      expect(built.id, original.id);
      expect(built.interaction.items.first.id, 'letter-a');
      expect(built.interaction.items.first.text, 'alpha');
      expect(built.evaluation.correctItemIds, ['letter-a']);
      expect(original.interaction.items.first.text, 'ga');
    },
  );

  test(
    'mode changes retain both representations during the unsaved session',
    () {
      final controller = ScriptRecognitionController(
        _exercise(ScriptRecognitionMode.imageToText, blueImage, redImage),
      );
      addTearDown(controller.dispose);
      controller.setMode(ScriptRecognitionMode.textToImage);
      controller.prompt.text = 'Find ga';
      controller.setOptionImage(0, blueImage);
      controller.setOptionImage(1, redImage);
      final imageMode = controller.build(PublicationState.draft);
      expect(
        imageMode.promptElements.where((element) => element.type == 'image'),
        isEmpty,
      );
      expect(imageMode.interaction.items.first.image, blueImage);
      controller.setMode(ScriptRecognitionMode.imageToText);
      expect(controller.promptImages, hasLength(2));
      expect(controller.optionText(0).text, 'ga');
      expect(controller.optionId(0), 'letter-a');
      expect(
        controller.build(PublicationState.draft).interaction.items.first.text,
        'ga',
      );
      controller.setMode(ScriptRecognitionMode.textToImage);
      expect(controller.prompt.text, 'Find ga');
      expect(controller.optionImage(0), blueImage);
    },
  );

  test(
    'zero-option text-to-image Draft retains mode and reports validation',
    () {
      final controller = ScriptRecognitionController(
        _exercise(ScriptRecognitionMode.textToImage, blueImage, redImage),
      );
      addTearDown(controller.dispose);
      controller.removeOption(1);
      controller.removeOption(0);
      final built = _restore(controller.build(PublicationState.draft));
      final reloaded = ScriptRecognitionController(built);
      addTearDown(reloaded.dispose);
      expect(reloaded.mode, ScriptRecognitionMode.textToImage);
      expect(_codes(built), contains('CHOICE_ANSWERS_REQUIRED'));
      expect(_codes(built), contains('CHOICE_CORRECT_ANSWER_INVALID'));
    },
  );

  test(
    'empty assets, missing prompt images and local paths are not publishable',
    () {
      for (final invalid in [
        '',
        r'C:\private\letter.png',
        'data:image/png;base64,AQID',
      ]) {
        final controller = ScriptRecognitionController(
          _exercise(ScriptRecognitionMode.textToImage, blueImage, redImage),
        );
        controller.setOptionImage(0, invalid);
        expect(
          _codes(controller.build(PublicationState.published)),
          contains('PROMPT_MEDIA_UNSUPPORTED'),
        );
        controller.dispose();
      }
      final controller = ScriptRecognitionController(
        _exercise(ScriptRecognitionMode.imageToText, blueImage, redImage),
      );
      addTearDown(controller.dispose);
      controller.removePromptImage(1);
      controller.removePromptImage(0);
      expect(
        _codes(controller.build(PublicationState.published)),
        contains('PRESET_CANONICAL_MISMATCH'),
      );
    },
  );

  test(
    'malformed multiple correct options remain invalid until explicitly corrected',
    () {
      final source = _exercise(
        ScriptRecognitionMode.imageToText,
        blueImage,
        redImage,
      );
      final json = source.toJson();
      (json['evaluation'] as Map<String, dynamic>)['correctItemIds'] = [
        'letter-a',
        'letter-b',
      ];
      final malformed = Exercise.fromV2Json(
        json,
        contentId: source.id,
        editorTemplate: source.editorTemplate,
        publicationState: PublicationState.draft,
      );
      final controller = ScriptRecognitionController(malformed);
      addTearDown(controller.dispose);
      expect(
        _codes(controller.build(PublicationState.draft)),
        contains('CHOICE_CORRECT_ANSWER_INVALID'),
      );
      controller.setCorrect(1);
      expect(_errors(controller.build(PublicationState.published)), isEmpty);
      expect(
        controller.build(PublicationState.published).evaluation.correctItemIds,
        ['letter-b'],
      );
    },
  );

  test(
    'unsupported mixed option content survives inspection for canonical Audit',
    () {
      final source = _exercise(
        ScriptRecognitionMode.textToImage,
        blueImage,
        redImage,
      );
      final json = source.toJson();
      final items =
          (json['interaction'] as Map<String, dynamic>)['items'] as List;
      ((items.first as Map)['content'] as List).add({
        'type': 'text',
        'text': 'unexpected label',
      });
      final malformed = Exercise.fromV2Json(
        json,
        contentId: source.id,
        editorTemplate: source.editorTemplate,
        publicationState: PublicationState.draft,
      );
      final controller = ScriptRecognitionController(malformed);
      addTearDown(controller.dispose);
      final preserved = controller.build(PublicationState.draft);
      expect(preserved.interaction.items.first.content, hasLength(2));
      expect(_codes(preserved), contains('PRESET_CANONICAL_MISMATCH'));
    },
  );

  for (final mode in ScriptRecognitionMode.values) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$mode editor and learner Preview render at 320px in $brightness without writes',
        (tester) async {
          await _viewport(tester, 320);
          final original = _exercise(mode, blueImage, redImage);
          final course = workflow.exampleCourse([original]);
          final beforeJson = jsonEncode(course.toJson());
          var saves = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: ExerciseEditorScreen(
                exercise: original,
                title: 'Recognize characters',
                isNew: false,
                course: course,
                lesson: course.lessons.first,
                round: course.lessons.first.rounds.first,
                onExerciseSaved: (_) => saves++,
                clock: () =>
                    throw StateError('Preview may not stamp authoring time'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final editKey = mode == ScriptRecognitionMode.imageToText
              ? 'script-option-text-0'
              : 'script-prompt';
          final field = find.byKey(ValueKey(editKey));
          await tester.ensureVisible(field);
          await tester.enterText(
            field,
            mode == ScriptRecognitionMode.imageToText
                ? 'ga edited'
                : 'Find ga edited',
          );
          tester.testTextInput.hide();
          await tester.pump();
          final beforePrefs = await workflow.preferences();
          await workflow.tapKey(tester, 'exercise-preview');
          await _waitForImageAction(
            tester,
            () => find.byType(RoundScreen).evaluate().isNotEmpty,
          );
          await workflow.settle(tester);
          expect(find.text('Check character images'), findsNothing);
          expect(find.byType(RoundScreen), findsOneWidget);
          final runtime = tester.widget<RoundScreen>(find.byType(RoundScreen));
          expect(runtime.previewMode, isTrue);
          expect(
            runtime.round.exercises.single.publicationState,
            original.publicationState,
          );
          expect(
            find.descendant(
              of: find.byType(RoundScreen),
              matching: find.byType(PortableExerciseImage),
            ),
            findsNWidgets(2),
          );
          expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
          final correct = mode == ScriptRecognitionMode.imageToText
              ? find.widgetWithText(FilledButton, 'ga edited')
              : find.ancestor(
                  of: find.byWidgetPredicate(
                    (widget) =>
                        widget is PortableExerciseImage &&
                        widget.asset == blueImage,
                  ),
                  matching: find.byType(FilledButton),
                );
          await tester.ensureVisible(correct);
          await tester.tap(correct);
          await workflow.settle(tester);
          expect(find.text('Correct'), findsOneWidget);
          expect(find.text('Finish round'), findsOneWidget);
          expect(saves, 0);
          expect(jsonEncode(course.toJson()), beforeJson);
          expect(await workflow.preferences(), beforePrefs);
          await tester.tap(find.byType(BackButton));
          await workflow.settle(tester);
          expect(
            tester
                .widget<TextField>(find.byKey(ValueKey(editKey)))
                .controller!
                .text,
            mode == ScriptRecognitionMode.imageToText
                ? 'ga edited'
                : 'Find ga edited',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final state in PublicationState.values) {
      testWidgets(
        '$mode real Editor saves $state with portable image and stable IDs',
        (tester) async {
          await _viewport(tester, 1000);
          final original = _exercise(mode, blueImage, redImage);
          final course = workflow.exampleCourse([original]);
          Exercise? saved;
          await tester.pumpWidget(
            MaterialApp(
              home: ExerciseEditorScreen(
                exercise: original,
                title: 'Recognize characters',
                isNew: false,
                course: course,
                lesson: course.lessons.first,
                round: course.lessons.first.rounds.first,
                onExerciseSaved: (value) => saved = value,
                clock: () => DateTime.utc(2026, 9, 6, 12),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final field = find.byKey(
            ValueKey(
              mode == ScriptRecognitionMode.imageToText
                  ? 'script-option-text-0'
                  : 'script-prompt',
            ),
          );
          await tester.ensureVisible(field);
          await tester.enterText(
            field,
            mode == ScriptRecognitionMode.imageToText
                ? 'ga saved'
                : 'Find ga saved',
          );
          await workflow.tapKey(
            tester,
            state == PublicationState.draft
                ? 'exercise-save-draft'
                : 'exercise-save',
          );
          await _waitForImageAction(tester, () => saved != null);
          expect(find.text('Check character images'), findsNothing);
          if (find.text('Use anyway').evaluate().isNotEmpty) {
            await tester.tap(find.text('Use anyway'));
            await tester.pumpAndSettle();
          }
          expect(saved, isNotNull);
          final restored = _restore(saved!);
          expect(restored.publicationState, state);
          expect(restored.id, original.id);
          expect(restored.interaction.items.map((item) => item.id), [
            'letter-a',
            'letter-b',
          ]);
          expect(restored.updatedAt, DateTime.utc(2026, 9, 6, 12));
          expect(_errors(restored), isEmpty);
          expect(restored.toJson(), saved!.toJson());
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'normal learner Select displays the correct image after a wrong character choice',
    (tester) async {
      await _viewport(tester, 1000);
      final controller = ScriptRecognitionController(
        _exercise(ScriptRecognitionMode.textToImage, blueImage, redImage),
      );
      final exercise = controller.build(PublicationState.published);
      controller.dispose();
      final course = workflow.exampleCourse([exercise]);
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
            ttsLanguage: 'ko-KR',
            roundIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final wrong = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is PortableExerciseImage && widget.asset == redImage,
        ),
        matching: find.byType(FilledButton),
      );
      await tester.ensureVisible(wrong);
      await tester.tap(wrong);
      await workflow.settle(tester);
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Correct answer:'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is PortableExerciseImage && widget.asset == blueImage,
        ),
        findsNWidgets(2),
      );
      expect(find.textContaining('base64,'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final mode in ScriptRecognitionMode.values) {
    testWidgets(
      '$mode opens direct contextual Help for every field without changing values',
      (tester) async {
        await _viewport(tester, 320);
        final original = _exercise(mode, blueImage, redImage);
        final controller = ScriptRecognitionController(original);
        addTearDown(controller.dispose);
        var mutations = 0;
        controller.addListener(() => mutations++);
        final before = jsonEncode(
          controller.build(PublicationState.draft).toJson(),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ScriptRecognitionEditor(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final fieldKeys = [
          'scriptMode',
          if (mode == ScriptRecognitionMode.imageToText)
            'scriptPromptImages'
          else
            'scriptPrompt',
          if (mode == ScriptRecognitionMode.imageToText)
            'scriptTextOptions'
          else
            'scriptImageOptions',
          'scriptCorrect',
        ];
        for (final fieldKey in fieldKeys) {
          final controls = find.byKey(
            ValueKey('exercise-field-help-$fieldKey'),
          );
          final count =
              fieldKey == 'scriptCorrect' || fieldKey.endsWith('Options')
              ? 2
              : 1;
          expect(controls, findsNWidgets(count));
          for (var index = 0; index < count; index++) {
            final control = controls.at(index);
            final definition = ExerciseFieldHelpRegistry.forEditorField(
              'script_recognition',
              fieldKey,
            );
            expect(
              tester.widget<IconButton>(control).tooltip,
              definition.purpose,
            );
            await tester.ensureVisible(control);
            await tester.pumpAndSettle();
            await tester.tap(control);
            await tester.pumpAndSettle();
            expect(find.byType(AlertDialog), findsOneWidget);
            expect(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.text(definition.title),
              ),
              findsOneWidget,
            );
            expect(find.text(definition.text), findsOneWidget);
            final bounds = tester.getRect(find.byType(AlertDialog));
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(320));
            await tester.tap(find.widgetWithText(TextButton, 'Close'));
            await tester.pumpAndSettle();
          }
        }
        expect(mutations, 0);
        expect(
          jsonEncode(controller.build(PublicationState.draft).toJson()),
          before,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'script image selector is read-only and exposes no bank mutation actions',
    (tester) async {
      await _viewport(tester, 1000);
      final controller = ScriptRecognitionController(
        _exercise(ScriptRecognitionMode.imageToText, blueImage, redImage),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScriptRecognitionEditor(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('script-add-prompt-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Image Bank'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FlatImageLibraryScreen>(find.byType(FlatImageLibraryScreen))
            .readOnly,
        isTrue,
      );
      expect(find.byTooltip('Import'), findsNothing);
      expect(find.byTooltip('Delete imported image'), findsNothing);
      expect(find.byTooltip('Remove this imported bank'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  for (final action in [
    'exercise-preview',
    'exercise-save',
    'exercise-save-draft',
  ]) {
    testWidgets(
      'corrupt embedded character image blocks $action without writes',
      (tester) async {
        await _viewport(tester, 1000);
        final truncated = base64Decode(
          blueImage.split(',').last,
        ).sublist(0, 24);
        final corrupt = 'data:image/png;base64,${base64Encode(truncated)}';
        final original = _exercise(
          ScriptRecognitionMode.imageToText,
          corrupt,
          redImage,
        );
        final course = workflow.exampleCourse([original]);
        var saves = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: original,
              title: 'Recognize characters',
              isNew: false,
              course: course,
              lesson: course.lessons.first,
              round: course.lessons.first.rounds.first,
              onExerciseSaved: (_) => saves++,
              clock: () => throw StateError(
                'Invalid images must not stamp authoring time',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final beforePrefs = await workflow.preferences();
        final beforeCourse = jsonEncode(course.toJson());
        final button = find.byKey(Key(action));
        // The longer inline guidance changes the lazily measured scroll extent.
        // Finish layout after revealing the action before hit-testing its center.
        for (var attempt = 0; attempt < 3; attempt++) {
          if (button.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              button,
              300,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          if (button.hitTestable().evaluate().isNotEmpty) break;
        }
        expect(button.hitTestable(), findsOneWidget);
        await tester.tap(button);
        await workflow.settle(tester);
        expect(find.text('Check character images'), findsOneWidget);
        expect(find.byType(RoundScreen), findsNothing);
        expect(saves, 0);
        expect(await workflow.preferences(), beforePrefs);
        expect(jsonEncode(course.toJson()), beforeCourse);
        await tester.tap(find.text('Keep editing'));
        await tester.pumpAndSettle();
        expect(find.byType(ScriptRecognitionEditor), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Exercise _exercise(
  ScriptRecognitionMode mode,
  String firstImage,
  String secondImage,
) => Exercise.v2(
  id: 'script-exercise',
  editorTemplate: 'script_recognition',
  publicationState: PublicationState.draft,
  updatedAt: DateTime.utc(2026, 9, 5, 9),
  promptElements: mode == ScriptRecognitionMode.imageToText
      ? [
          PromptElement(type: 'image', asset: firstImage),
          PromptElement(type: 'image', asset: secondImage),
        ]
      : const [PromptElement(type: 'text', text: 'Find ga')],
  interaction: ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'letter-a',
        content: [
          mode == ScriptRecognitionMode.imageToText
              ? const PromptElement(type: 'text', text: 'ga')
              : PromptElement(type: 'image', asset: firstImage),
        ],
      ),
      ExerciseItem(
        id: 'letter-b',
        content: [
          mode == ScriptRecognitionMode.imageToText
              ? const PromptElement(type: 'text', text: 'na')
              : PromptElement(type: 'image', asset: secondImage),
        ],
      ),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    correctItemIds: ['letter-a'],
    normalization: {'caseSensitive': true},
  ),
  hint: 'Look at the shape.',
  feedback: const {'custom': 'Preserved author feedback'},
  missingWords: const ['preserved metadata'],
);

Exercise _restore(Exercise exercise) => Exercise.fromV2Json(
  jsonDecode(jsonEncode(exercise.toJson())) as Map<String, dynamic>,
  contentId: exercise.id,
  editorTemplate: exercise.editorTemplate,
  publicationState: exercise.publicationState,
);

List<CourseAuditIssue> _errors(Exercise exercise) => CourseAuditService()
    .auditExercise(exercise)
    .where((issue) => issue.severity == AuditSeverity.error)
    .toList();
Iterable<String> _codes(Exercise exercise) =>
    CourseAuditService().auditExercise(exercise).map((issue) => issue.code);

Future<void> _viewport(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

Future<void> _waitForImageAction(
  WidgetTester tester,
  bool Function() completed,
) async {
  // Compressed-image validation calls the real engine decoder. Advancing only
  // the widget test's fake clock does not let its native callbacks complete.
  // Allow bounded real event-loop turns, then flush widget microtasks/frames.
  for (var attempt = 0; attempt < 100; attempt++) {
    if (completed() || find.byType(AlertDialog).evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(
    completed() || find.byType(AlertDialog).evaluate().isNotEmpty,
    isTrue,
    reason:
        'Image validation did not reach navigation, save or a visible error.',
  );
}

Future<String> _image(Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(
    recorder,
  ).drawRect(const ui.Rect.fromLTWH(0, 0, 2, 2), ui.Paint()..color = color);
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  try {
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  } finally {
    image.dispose();
    picture.dispose();
  }
}
