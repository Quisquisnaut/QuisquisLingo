import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_model_v12_converter.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/widgets/exercise_image_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 257: the note shown before a Round starts is a Before you start
/// card, an ordinary presentation card of the Round (text element with role
/// `intro`) with an optional Open GuideBook button (owner decisions of 29
/// September 2026): editable and publishable, never one of the Round's
/// steps, never shown in Review.
final _stamp = DateTime.utc(2026, 9, 29);

Exercise _card(
  String id, {
  String text = 'This Round practises greetings.',
  bool guidebook = false,
  PublicationState state = PublicationState.published,
}) => Exercise.beforeYouStart(
  id: id,
  publicationState: state,
  updatedAt: _stamp,
  text: text,
  guidebookButton: guidebook,
  authoringMetadata: const {'presetId': 'before_you_start'},
);

Exercise _select(String id) => Exercise.canonical(
  id: id,
  updatedAt: _stamp,
  primitive: ExercisePrimitive.select,
  promptElements: [PromptElement(type: 'text', text: 'Question $id')],
  items: [
    ExerciseItem(
      id: '${id}_a',
      content: [PromptElement(type: 'text', text: 'Right $id')],
    ),
    ExerciseItem(
      id: '${id}_b',
      content: [PromptElement(type: 'text', text: 'Wrong $id')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_a'],
  ),
);

LearningRound _round(List<Exercise> exercises, {String id = 'round'}) =>
    LearningRound(
      id: id,
      title: 'Greetings',
      updatedAt: _stamp,
      content: [for (final e in exercises) LearningContent.fromExercise(e)],
    );

Course _course(
  List<LearningRound> rounds, {
  bool useGuidebook = true,
  PublicationState guidebookState = PublicationState.published,
}) => Course(
  courseId: 'before-you-start-course',
  title: 'Before you start course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  useGuidebook: useGuidebook,
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: rounds,
      guidebook: Guidebook(
        overview: 'Greetings.',
        publicationState: guidebookState,
      ),
    ),
  ],
);

Set<String> _codes(Course course) =>
    CourseAuditService().auditCourse(course).issues.map((i) => i.code).toSet();

void main() {
  group('model and recipe', () {
    test('the card is a presentation with an intro note and an option', () {
      final card = _card('intro', guidebook: true);
      final f = ExerciseFeatures(card);
      expect(card.primitive, ExercisePrimitive.presentation);
      expect(f.kind, LearnerExerciseKind.roundIntro);
      expect(f.introText, 'This Round practises greetings.');
      expect(f.guidebookButton, isTrue);
      expect(card.toJson()['options'], {'guidebookButton': true});
      expect(
        ExerciseFeatures(_card('plain')).guidebookButton,
        isFalse,
        reason: 'the option defaults to off and is then not stored',
      );
      expect(_card('plain').toJson().containsKey('options'), isFalse);
      final back = Exercise.fromJson(
        jsonDecode(jsonEncode(card.toJson())) as Map<String, dynamic>,
        contentId: 'intro',
        publicationState: PublicationState.published,
      );
      expect(back.semanticallyEquals(card), isTrue);
      expect(
        PrimitiveCapabilityRegistry.validate(
          primitive: card.primitive,
          options: card.options,
          evaluationMode: card.canonicalEvaluation.mode,
        ),
        isEmpty,
      );
    });

    test('the option belongs to the presentation primitive only', () {
      final json = _select('q').toJson()
        ..['options'] = {'guidebookButton': true};
      expect(
        () => Exercise.fromJson(
          json,
          contentId: 'q',
          publicationState: PublicationState.published,
        ),
        throwsFormatException,
      );
    });

    test('the Before you start recipe represents, decomposes and rebuilds', () {
      final card = _card('intro', guidebook: true);
      expect(PresetRecipes.represents(card, 'before_you_start'), isTrue);
      expect(PresetRecipes.recognize(card), 'before_you_start');
      expect(PresetRecipes.represents(card, 'note_card'), isFalse);
      final draft = PresetRecipes.decompose(card, 'before_you_start');
      expect(draft.prompt, 'This Round practises greetings.');
      expect(draft.guidebookButton, isTrue);
      final built = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: card,
          type: 'before_you_start',
          publicationState: PublicationState.draft,
          prompt: '  A new note.  ',
        ),
      ).candidate!;
      expect(ExerciseFeatures(built).introText, 'A new note.');
      expect(ExerciseFeatures(built).guidebookButton, isFalse);
      expect(built.publicationState, PublicationState.draft);
    });
  });

  group('playability and Audit', () {
    test('the card is never a step; the first published one introduces', () {
      final round = _round([
        _card('draft', text: 'Draft note', state: PublicationState.draft),
        _card('empty', text: ''),
        _card('intro'),
        _select('q1'),
      ]);
      final service = RoundPlayabilityService();
      expect(service.playableExerciseIndices(round), [3]);
      expect(service.playableExerciseIndices(round, includeDrafts: true), [3]);
      expect(service.introFor(round)?.id, 'intro');
      expect(service.introFor(round, includeDrafts: true)?.id, 'draft');
      expect(
        service.introFor(_round([_select('q1')])),
        isNull,
        reason: 'a Round without a card starts at once',
      );
    });

    test('a Round of a card alone has nothing to play', () {
      final round = _round([_card('intro')]);
      expect(RoundPlayabilityService().playableExerciseIndices(round), isEmpty);
      expect(
        RoundPlayabilityService().laurelEligibleRoundIds(_course([round])),
        isEmpty,
      );
    });

    test('empty and duplicate cards; the first Round wants one', () {
      expect(
        CourseAuditService()
            .auditExercise(_card('empty', text: ' '))
            .map((i) => i.code),
        contains('ROUND_INTRO_EMPTY'),
      );
      final twice = _course([
        _round([_card('a'), _card('b'), _select('q1')]),
      ]);
      expect(_codes(twice), contains('ROUND_INTRO_DUPLICATE'));
      expect(_codes(twice), isNot(contains('LESSON_INTRO_MISSING')));
      final none = _course([
        _round([_select('q1')]),
      ]);
      expect(_codes(none), contains('LESSON_INTRO_MISSING'));
      expect(_codes(none), isNot(contains('ROUND_INTRO_DUPLICATE')));
    });
  });

  group('conversion and generation', () {
    test(
      'a v11 Lesson introduction converts to a card offering the GuideBook',
      () {
        final v11 =
            jsonDecode(
                  File(
                    'test/fixtures/v11/exercise_laboratory_en_it.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final v11Intro =
            (((v11['lessons'] as List).first as Map)['rounds'] as List).first
                as Map;
        final intro = (v11Intro['content'] as List).first as Map;
        expect(intro['role'], 'lesson_intro');
        final course = Course.fromJson(convertCourseJsonToV12(v11).json);
        final round = course.lessons.first.rounds.first;
        final card = round.exercises.first;
        expect(card.id, intro['id']);
        expect(card.editorTemplate, 'before_you_start');
        expect(ExerciseFeatures(card).kind, LearnerExerciseKind.roundIntro);
        expect(ExerciseFeatures(card).introText, intro['text']);
        expect(ExerciseFeatures(card).guidebookButton, isTrue);
        expect(round.content.first.role, isEmpty);
      },
    );

    test('the bundled and demo Courses open every Lesson with a card', () {
      for (final path in [
        'assets/courses/exercise_laboratory_en_it.json',
        // The Edge Case to import (Build 259 Revision 5).
        'demo_courses/edge_case_it_en.json',
      ]) {
        final course = Course.fromJson(
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
        );
        for (final lesson in course.lessons) {
          final first = lesson.rounds.first.exercises.first;
          expect(
            ExerciseFeatures(first).kind,
            LearnerExerciseKind.roundIntro,
            reason: '$path ${lesson.lessonId}',
          );
        }
        for (final lesson in course.lessons) {
          for (final round in lesson.rounds) {
            expect(
              round.content.where((c) => c.role == 'lesson_intro'),
              isEmpty,
              reason: '$path ${round.id} keeps no old note',
            );
          }
        }
      }
    });

    test('the Round Wizard opens its first Round with a Draft card', () {
      final guidebook = Guidebook(
        overview: 'Everyday food and drinks.',
        vocabulary: const [
          'cappuccino = cappuccino',
          'pane = bread',
          'acqua = water',
          'tavolo = table',
        ],
        examples: const ['Vorrei un cappuccino oggi.', 'Il pane è sul tavolo.'],
      );
      final generator = GuidebookRoundGenerator(randomSeed: 3);
      final drafts = generator.createDrafts(
        guidebook,
        generator.plan(guidebook, roundCount: 2, exercisesPerRound: 2),
      );
      final card = drafts.first.exercises.first;
      expect(ExerciseFeatures(card).kind, LearnerExerciseKind.roundIntro);
      expect(ExerciseFeatures(card).introText, 'Everyday food and drinks.');
      expect(ExerciseFeatures(card).guidebookButton, isTrue);
      expect(card.publicationState, PublicationState.draft);
      expect(card.editorTemplate, 'before_you_start');
      expect(PresetRecipes.represents(card, 'before_you_start'), isTrue);
      expect(
        drafts.last.exercises.where(RoundPlayabilityService.isRoundIntro),
        isEmpty,
      );
    });
  });

  group('Round screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Before you start learner');
      _platforms();
      keepCrashLogUnavailable();
    });

    testWidgets('the card comes first, with Open GuideBook when asked', (
      tester,
    ) async {
      final round = _round([_select('q1'), _card('intro', guidebook: true)]);
      await _pump(tester, _course([round]), round);
      expect(find.text('Before you start'), findsOneWidget);
      expect(find.text('This Round practises greetings.'), findsOneWidget);
      expect(
        find.byKey(const Key('before-you-start-guidebook')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('before-you-start-continue')));
      await _frames(tester);
      expect(find.text('Before you start'), findsNothing);
      expect(find.text('Question q1'), findsWidgets);
    });

    testWidgets('no button without the switch, Use GuideBook or publication', (
      tester,
    ) async {
      for (final course in [
        _course([
          _round([_card('intro'), _select('q1')]),
        ]),
        _course([
          _round([_card('intro', guidebook: true), _select('q1')]),
        ], useGuidebook: false),
        _course([
          _round([_card('intro', guidebook: true), _select('q1')]),
        ], guidebookState: PublicationState.draft),
      ]) {
        final round = course.lessons.single.rounds.single;
        await _pump(tester, course, round);
        expect(find.text('Before you start'), findsOneWidget);
        expect(
          find.byKey(const Key('before-you-start-guidebook')),
          findsNothing,
        );
      }
    });

    testWidgets('Review starts at once, without the card', (tester) async {
      final round = _round([_card('intro', guidebook: true), _select('q1')]);
      await _pump(tester, _course([round]), round, review: true);
      expect(find.text('Before you start'), findsNothing);
      expect(find.text('Question q1'), findsWidgets);
    });

    testWidgets('the Preview of a card alone shows it and closes', (
      tester,
    ) async {
      final round = _round([_card('intro', state: PublicationState.draft)]);
      final course = _course([round]);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RoundScreen(
                    course: course,
                    lesson: course.lessons.single,
                    round: round,
                    ttsLanguage: 'it-IT',
                    roundIndex: 0,
                    previewMode: true,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await _frames(tester);
      expect(find.text('This Round practises greetings.'), findsOneWidget);
      expect(find.text('Close preview'), findsOneWidget);
      await tester.tap(find.byKey(const Key('before-you-start-continue')));
      await _frames(tester);
      expect(find.text('open'), findsOneWidget);
      expect(find.text('Before you start'), findsNothing);
    });
  });

  group('editor form', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('the Open GuideBook switch follows Use GuideBook', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final uses in [false, true]) {
        Exercise? saved;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: _card('intro', text: '', state: PublicationState.draft),
              title: 'Before you start form',
              isNew: true,
              course: _course(const [], useGuidebook: uses),
              onExerciseSaved: (value) => saved = value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(
          const Key('before-you-start-guidebook-switch'),
        );
        expect(toggle, findsOneWidget);
        expect(
          tester.widget<SwitchListTile>(toggle).onChanged,
          uses ? isNotNull : isNull,
        );
        expect(find.byType(ExerciseImageField), findsNothing);
        if (!uses) continue;
        await tester.enterText(
          find.byKey(const ValueKey('exercise-field-prompt')),
          'Read the GuideBook first.',
        );
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pump();
        final save = find.byKey(const Key('exercise-save-draft'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(saved, isNotNull);
        expect(ExerciseFeatures(saved!).introText, 'Read the GuideBook first.');
        expect(ExerciseFeatures(saved!).guidebookButton, isTrue);
        expect(saved!.editorTemplate, 'before_you_start');
      }
    });
  });
}

void _platforms() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => testSupportDirectory.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (_) async => null,
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

Future<void> _frames(WidgetTester tester, {int count = 30}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pump(
  WidgetTester tester,
  Course course,
  LearningRound round, {
  bool review = false,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        key: UniqueKey(),
        course: course,
        lesson: course.lessons.single,
        round: round,
        ttsLanguage: 'it-IT',
        roundIndex: 0,
        reviewMode: review,
      ),
    ),
  );
  await _frames(tester);
}
