import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/models/preset_successors.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 7, fourth follow-up (owner review, 29 September 2026):
/// the preset name in bold; capitals between an answer and its blocks are a
/// Warning, never a blocking error; Name what you see builds the name from
/// word blocks (Type what you see keeps the typed answer); Read and answer
/// keeps its "to target" preset with a source-language text and a dialogue
/// that may be read aloud line by line.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 29, 11);

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  publicationState: PublicationState.draft,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

Exercise _v11Blank(String preset) => Exercise(
  id: 'form-$preset',
  type: presetRecipeBaseOf[preset] ?? preset,
  editorTemplate: preset,
  publicationState: PublicationState.draft,
  updatedAt: _stamp,
  prompt: '',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

ExerciseDraftBuildResult _build(
  String type, {
  Exercise? original,
  PublicationState state = PublicationState.published,
  String prompt = '',
  String question = '',
  String tokens = '',
  String order = '',
  String extraWords = '',
  List<String> correctTranslations = const [],
  String dialogue = '',
  String dialogueReadAloud = 'none',
  String answers = '',
  String correct = '',
  String imageAsset = '',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: original ?? _v11Blank(type),
    type: type,
    publicationState: state,
    requireValidAnswer: true,
    prompt: prompt,
    question: question,
    tokens: tokens,
    order: order,
    extraWords: extraWords,
    correctTranslations: correctTranslations,
    dialogue: dialogue,
    dialogueReadAloud: dialogueReadAloud,
    answers: answers,
    correct: correct,
    imageAsset: imageAsset,
  ),
);

Exercise _built(
  String type, {
  Exercise? original,
  String prompt = '',
  String question = '',
  String tokens = '',
  String order = '',
  String extraWords = '',
  List<String> correctTranslations = const [],
  String dialogue = '',
  String dialogueReadAloud = 'none',
  String answers = '',
  String correct = '',
  String imageAsset = '',
}) {
  final result = _build(
    type,
    original: original,
    prompt: prompt,
    question: question,
    tokens: tokens,
    order: order,
    extraWords: extraWords,
    correctTranslations: correctTranslations,
    dialogue: dialogue,
    dialogueReadAloud: dialogueReadAloud,
    answers: answers,
    correct: correct,
    imageAsset: imageAsset,
  );
  expect(result.error, isNull, reason: '${result.error?.code}');
  return result.candidate!;
}

Set<String> _codes(Exercise exercise) => {
  for (final issue in CourseAuditService().auditExercise(exercise)) issue.code,
};

Iterable<String> _errors(Exercise exercise) => [
  for (final issue in CourseAuditService().auditExercise(exercise))
    if (issue.severity == AuditSeverity.error) issue.code,
];

Course _course(List<Exercise> exercises) => Course(
  courseId: 'fourth_followup_256',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  title: 'Fourth follow-up course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson_one',
      title: 'Lesson one',
      updatedAt: _stamp,
      rounds: [
        LearningRound(
          id: 'round_one',
          title: 'Round one',
          updatedAt: _stamp,
          exercises: exercises,
        ),
      ],
    ),
  ],
);

class _Speech extends TtsCacheService {
  final spoken = <String>[];

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async {
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}
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
}

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  for (var attempt = 0; ; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(
      attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
    );
    if (finder.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) break;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _settle(WidgetTester tester, {int rounds = 80}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<Exercise? Function()> _mountForm(
  WidgetTester tester,
  Exercise exercise, {
  bool isNew = true,
}) async {
  Exercise? saved;
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      home: ExerciseEditorScreen(
        exercise: exercise,
        title: 'Fourth follow-up form',
        isNew: isNew,
        onExerciseSaved: (value) => saved = value,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return () => saved;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Exercise _reading(String readAloud) => _built(
  'reading_answer_target',
  prompt: 'Anna and Luca talk after lunch.',
  dialogue: 'Anna: Vuoi un caffè?\nLuca: Sì, senza zucchero.',
  dialogueReadAloud: readAloud,
  question: 'Come vuole il caffè Luca?',
  answers: 'Senza zucchero.\nCon molto zucchero.',
  correct: '1',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Fourth follow-up author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'sound_effects_enabled': false,
    });
    keepCrashLogUnavailable();
    _platforms();
  });

  group('capitals between an answer and its blocks', () {
    test('Build the translation matches the blocks and only warns', () {
      final e = _built(
        'build_translation_to_target',
        prompt: 'I am Anna.',
        tokens: 'io\nsono\nAnna',
        correctTranslations: ['Io sono Anna'],
      );
      final order = e.canonicalEvaluation.correctOrders.single;
      expect(order.itemIds, hasLength(3));
      expect(_errors(e), isEmpty);
      expect(_codes(e), contains('ARRANGE_ANSWER_CASE_DIFFERS'));
      final exact = _built(
        'build_translation_to_target',
        prompt: 'I am Anna.',
        tokens: 'io\nsono\nAnna',
        correctTranslations: ['io sono Anna'],
      );
      expect(_codes(exact), isNot(contains('ARRANGE_ANSWER_CASE_DIFFERS')));
    });

    test('Put the words in order and a capital inside the sentence', () {
      final e = _built(
        'word_order',
        prompt: 'Put the words in order.',
        tokens: 'il\ngatto\ndi\nanna',
        order: 'Il\ngatto\ndi\nAnna',
      );
      expect(e.canonicalEvaluation.correctOrders.single.itemIds, hasLength(4));
      expect(_errors(e), isEmpty);
      expect(_codes(e), contains('ARRANGE_ANSWER_CASE_DIFFERS'));
    });
  });

  group('Name what you see and Type what you see', () {
    test('the blocks build an Arrange under the picture', () {
      final e = _built(
        'picture_blocks',
        original: _blank('picture-blocks'),
        question: 'What is this?',
        imageAsset: 'assets/exercise_images/bread.webp',
        order: 'il\npane',
        extraWords: 'la',
      );
      final f = ExerciseFeatures(e);
      expect(e.primitive, ExercisePrimitive.arrange);
      expect(e.items.map((item) => item.value), ['il', 'pane', 'la']);
      final order = e.canonicalEvaluation.correctOrders.single;
      expect(order.text, 'il pane');
      expect(order.itemIds, [e.items[0].id, e.items[1].id]);
      expect(f.kind, LearnerExerciseKind.arrangePictureName);
      expect(f.pictureImages, hasLength(1));
      expect(_errors(e), isEmpty);
      final course = _course([e]);
      expect(
        ExerciseCopyService.typeLabel(course, f.kind),
        'NAME WHAT YOU SEE',
      );
      expect(
        ExerciseCopyService.instruction(course, f.kind),
        'Build the name of what you see.',
      );
      final draft = PresetRecipes.decompose(e, 'picture_blocks');
      expect(draft.order, 'il\npane');
      expect(draft.extraWords, 'la');
      expect(PresetRecipes.represents(e, 'picture_blocks'), isTrue);
      expect(
        PresetRecipes.recognize(e.withAuthoringMetadata(const {})),
        'picture_blocks',
      );
      expect(
        ExercisePresetRegistry.byId('picture_blocks')!.name,
        'Name what you see',
      );
    });

    test('the Audit asks for the picture and at most two extra blocks', () {
      final noPicture = _built(
        'picture_blocks',
        original: _blank('no-picture'),
        order: 'il\npane',
      );
      expect(_codes(noPicture), contains('PRESET_CANONICAL_MISMATCH'));
      final tooMany = _built(
        'picture_blocks',
        original: _blank('too-many'),
        imageAsset: 'assets/exercise_images/bread.webp',
        order: 'il\npane',
        extraWords: 'la\nlo\ngli',
      );
      expect(_errors(tooMany), contains('WORD_BLOCK_DISTRACTOR_COUNT'));
      expect(
        _build('picture_blocks', original: _blank('empty')).error?.code,
        ExerciseDraftErrorCode.nameBlocksRequired,
      );
    });

    test('Type what you see keeps the typed answer and says so', () {
      expect(
        ExercisePresetRegistry.byId('picture_name')!.name,
        'Type what you see',
      );
      final e = Exercise.canonical(
        id: 'typed',
        primitive: ExercisePrimitive.input,
        promptElements: const [
          PromptElement(role: 'question', type: 'text', text: 'What is this?'),
          PromptElement(
            role: 'picture',
            type: 'image',
            asset: 'assets/exercise_images/bread.webp',
          ),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.expression,
          answers: ['il pane'],
        ),
        updatedAt: _stamp,
      );
      final kind = ExerciseFeatures(e).kind;
      expect(kind, LearnerExerciseKind.inputPictureName);
      final course = _course([e]);
      expect(ExerciseCopyService.typeLabel(course, kind), 'NAME WHAT YOU SEE');
      expect(
        ExerciseCopyService.instruction(course, kind),
        'Type the name of what you see.',
      );
    });

    testWidgets('the form offers the blocks and the extra blocks', (
      tester,
    ) async {
      _bigWindow(tester);
      // A new exercise is what the recipe builds from empty fields.
      final blank = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _blank('picture-form'),
          type: 'picture_blocks',
          publicationState: PublicationState.draft,
        ),
      ).candidate!;
      final saved = await _mountForm(tester, blank);
      final heading = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('exercise-preset-selector')),
          matching: find.text('Name what you see'),
        ),
      );
      // The preset's name is bold (owner request, same day).
      expect(heading.style?.fontWeight, FontWeight.bold);
      expect(find.text('Blocks of the name, in order'), findsOneWidget);
      expect(find.text('Extra blocks (optional)'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'What is this?',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-order')),
        'il\npane',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-extraWords')),
        'la',
      );
      await tester.pump();
      await _tap(tester, find.byKey(const Key('exercise-save-draft')));
      final exercise = saved();
      expect(exercise, isNotNull);
      expect(exercise!.items.map((item) => item.value), ['il', 'pane', 'la']);
      expect(exercise.editorTemplate, 'picture_blocks');
    });

    testWidgets('a saved exercise shows its type in bold too', (tester) async {
      _bigWindow(tester);
      final exercise = _built(
        'picture_blocks',
        original: _blank('saved-picture'),
        imageAsset: 'assets/exercise_images/bread.webp',
        order: 'il\npane',
      );
      await _mountForm(tester, exercise, isNew: false);
      final label = tester.widget<Text>(find.text('Name what you see'));
      expect(label.style?.fontWeight, FontWeight.bold);
    });
  });

  group('Read and answer', () {
    test('only the "to target" preset remains', () {
      expect(ExercisePresetRegistry.byId('reading_answer_source'), isNull);
      expect(
        presetSuccessorOf['reading_answer_source'],
        'reading_answer_target',
      );
      expect(
        ExercisePresetRegistry.byId('reading_answer_target')!.twin,
        isNull,
      );
    });

    test(
      'the text is in the source language; the dialogue may be read aloud',
      () {
        for (final readAloud in ['automatic', 'manual', 'none']) {
          final e = _reading(readAloud);
          final f = ExerciseFeatures(e);
          final context = e.promptElements.singleWhere(
            (element) => element.isText && element.role == 'context',
          );
          expect(context.language, TextLanguage.source);
          expect(f.dialogueTurns, hasLength(2));
          expect(f.kind, LearnerExerciseKind.selectContext);
          expect(f.requiresAudio, isFalse, reason: readAloud);
          expect(f.contextAudio, isEmpty);
          if (readAloud == 'none') {
            expect(f.dialogueAudio, isEmpty);
          } else {
            expect(f.dialogueAudio.map((e) => e.text), [
              'Vuoi un caffè?',
              'Sì, senza zucchero.',
            ]);
            expect(
              f.dialogueAudio
                  .map((e) => e.effectivePlayback.serialized)
                  .toSet(),
              {readAloud},
            );
            expect(f.dialogueAudio.every((e) => e.required == false), isTrue);
          }
          expect(_errors(e), isEmpty, reason: readAloud);
          final draft = PresetRecipes.decompose(e, 'reading_answer_target');
          expect(draft.dialogueReadAloud, readAloud);
          expect(draft.prompt, 'Anna and Luca talk after lunch.');
          expect(PresetRecipes.represents(e, 'reading_answer_target'), isTrue);
        }
      },
    );

    testWidgets('the form has no Spoken text and a dialogue read-aloud', (
      tester,
    ) async {
      _bigWindow(tester);
      await _mountForm(tester, _v11Blank('reading_answer_target'));
      expect(find.text('Text to read (source language)'), findsOneWidget);
      expect(find.text('Spoken text (optional)'), findsNothing);
      expect(
        find.byKey(const ValueKey('exercise-choice-dialogueReadAloud')),
        findsOneWidget,
      );
    });

    testWidgets('an automatic dialogue is read line by line, a second apart', (
      tester,
    ) async {
      _bigWindow(tester);
      final speech = _Speech();
      final exercise = _reading('automatic');
      final course = _course([exercise]);
      final round = course.lessons.single.rounds.single;
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.single,
            round: round,
            ttsLanguage: course.ttsLanguage,
            roundIndex: 0,
            previewMode: true,
            ttsCacheService: speech,
          ),
        ),
      );
      await _until(tester, find.text('Come vuole il caffè Luca?'));
      await _settle(tester);
      expect(speech.spoken, ['Vuoi un caffè?', 'Sì, senza zucchero.']);
      expect(
        find.byKey(const Key('contextual-comprehension-dialogue-play')),
        findsOneWidget,
      );
      expect(find.byTooltip('Play audio again'), findsNothing);
    });

    testWidgets('a dialogue on request waits for Play dialogue', (
      tester,
    ) async {
      _bigWindow(tester);
      final speech = _Speech();
      final exercise = _reading('manual');
      final course = _course([exercise]);
      final round = course.lessons.single.rounds.single;
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.single,
            round: round,
            ttsLanguage: course.ttsLanguage,
            roundIndex: 0,
            previewMode: true,
            ttsCacheService: speech,
          ),
        ),
      );
      await _until(tester, find.text('Come vuole il caffè Luca?'));
      await _settle(tester, rounds: 20);
      expect(speech.spoken, isNot(contains('Vuoi un caffè?')));
      await tester.tap(
        find.byKey(const Key('contextual-comprehension-dialogue-play')),
      );
      await _settle(tester);
      expect(
        speech.spoken.where((text) => text != 'Senza zucchero.'),
        containsAllInOrder(['Vuoi un caffè?', 'Sì, senza zucchero.']),
      );
    });
  });
}
