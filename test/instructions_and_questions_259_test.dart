import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/script_recognition_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 259 Revision 0 (plan `docs/CONTEXT_AND_HINT_PLAN.md` §4, owner
/// decisions of 29 September 2026): an authored Instruction or context (a
/// prompt with no language) takes the place of the standard line; a
/// question or sentence is never optional; the optional questions that were
/// instructions are Instruction or context.

final _stamp = DateTime.utc(2026, 9, 30);

Course _laboratory() => Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Exercise _labExercise(String id) => _laboratory().lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.exercises)
    .singleWhere((exercise) => exercise.id == id);

Course _course(List<Lesson> lessons) => Course(
  courseId: 'instructions-259-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Instructions 259',
  ttsLanguage: 'it-IT',
  lessons: lessons,
);

/// A blank exercise for [presetId]'s recipe, as `PresetRecipes.rebuild`
/// makes one: the canonical-only recipes start from a presentation, the
/// others from their base recipe's v11 type.
Exercise _blankFor(String presetId) =>
    PresetRecipes.canonicalOnly.contains(presetId)
    ? Exercise.canonical(
        id: 'blank-$presetId',
        publicationState: PublicationState.draft,
        primitive: ExercisePrimitive.presentation,
        canonicalEvaluation: CanonicalEvaluation.none,
        updatedAt: _stamp,
      )
    : Exercise(
        id: 'blank-$presetId',
        publicationState: PublicationState.draft,
        updatedAt: _stamp,
        type: ExercisePresetRegistry.byId(presetId)!.base,
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
  String presetId, {
  PublicationState state = PublicationState.published,
  String prompt = '',
  String question = '',
  String answers = '',
  String correct = '',
  String accepted = '',
  String tts = '',
  String order = '',
  String extraWords = '',
  String groups = '',
  String slots = '',
  String icons = '',
  String imageAsset = '',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blankFor(presetId),
    type: presetId,
    publicationState: state,
    prompt: prompt,
    question: question,
    answers: answers,
    correct: correct,
    accepted: accepted,
    tts: tts,
    order: order,
    extraWords: extraWords,
    groups: groups,
    slots: slots,
    icons: icons,
    imageAsset: imageAsset,
  ),
);

Exercise _built(
  String presetId, {
  String prompt = '',
  String question = '',
  String answers = '',
  String correct = '',
  String accepted = '',
  String tts = '',
  String order = '',
  String extraWords = '',
  String groups = '',
  String slots = '',
  String icons = '',
  String imageAsset = '',
}) {
  final result = _build(
    presetId,
    prompt: prompt,
    question: question,
    answers: answers,
    correct: correct,
    accepted: accepted,
    tts: tts,
    order: order,
    extraWords: extraWords,
    groups: groups,
    slots: slots,
    icons: icons,
    imageAsset: imageAsset,
  );
  expect(result.error, isNull, reason: '$presetId: ${result.error?.code}');
  return result.candidate!;
}

class _Settings extends SettingsService {
  _Settings({required this.audio, required this.tts});
  final bool audio;
  final bool tts;

  @override
  Future<bool> areAudioExercisesEnabled() async => audio;

  @override
  Future<bool> isTtsEnabled() async => tts;
}

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _installPluginMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return testSupportDirectory.path;
      }
      throw PlatformException(code: 'test_storage_unavailable');
    },
  );
  keepCrashLogUnavailable();
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

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 160; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpRound(WidgetTester tester, Exercise exercise) async {
  _bigWindow(tester);
  final round = LearningRound(
    id: 'round-${exercise.id}',
    title: 'Instructions round',
    content: [LearningContent.fromExercise(exercise)],
  );
  final lesson = Lesson(
    lessonId: 'lesson-${exercise.id}',
    title: 'Instructions lesson',
    rounds: [round],
  );
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: _course([lesson]),
        lesson: lesson,
        round: round,
        ttsLanguage: 'it-IT',
        roundIndex: 0,
        previewMode: true,
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await _pumpUntil(tester, find.byKey(const Key('exercise-instruction')));
}

String _instructionLine(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('exercise-instruction'))).data!;

Future<void> _pumpDuel(
  WidgetTester tester,
  List<Exercise> exercises, {
  required SettingsService settings,
}) async {
  _bigWindow(tester);
  final round = LearningRound(
    id: 'duel-round',
    title: 'Duel round',
    exercises: exercises,
  );
  final lesson = Lesson(
    lessonId: 'duel-lesson',
    title: 'Duel lesson',
    rounds: [round],
  );
  await tester.pumpWidget(
    MaterialApp(
      home: DuelScreen(
        course: _course([lesson]),
        lesson: lesson,
        ttsLanguage: 'it-IT',
        settingsService: settings,
      ),
    ),
  );
  await _pumpUntil(tester, find.text('Question 1/25 · 4 lives'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPluginMocks();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Instructions author');
  });

  group('the authored instruction', () {
    test('is the displayed prompt when it states no language', () {
      final instruction = ExerciseFeatures(
        _labExercise('qql_lab254_arrange_zero'),
      );
      expect(instruction.clueText, isNotEmpty);
      expect(instruction.authoredInstruction, instruction.clueText);
      // A text to translate states its language: it is material.
      final translation = ExerciseFeatures(
        _labExercise('qql_lab254_input_explicit'),
      );
      expect(translation.displayedPrompt, 'Hello.');
      expect(translation.authoredInstruction, isEmpty);
      // So is Spell the word's clue.
      expect(
        ExerciseFeatures(
          _labExercise('qql_lab254_spell_word_clue'),
        ).authoredInstruction,
        isEmpty,
      );
    });

    testWidgets('takes the place of the standard line', (tester) async {
      await _pumpRound(tester, _labExercise('qql_lab254_arrange_zero'));
      expect(
        _instructionLine(tester),
        'Put the Italian sentence in order: The cat sleeps.',
      );
      expect(find.byKey(const Key('exercise-prompt-text')), findsNothing);
    });

    testWidgets('a text to translate keeps its own line', (tester) async {
      await _pumpRound(tester, _labExercise('qql_lab254_input_explicit'));
      expect(_instructionLine(tester), 'Type the translation.');
      expect(
        tester.widget<Text>(find.byKey(const Key('exercise-prompt-text'))).data,
        'Hello.',
      );
    });

    testWidgets('without one the standard line shows', (tester) async {
      await _pumpRound(tester, _labExercise('qql_lab254_select_single'));
      expect(_instructionLine(tester), 'Choose the correct answer.');
      expect(find.text('How do you say ‘thank you’ in Italian?'), findsOne);
    });

    testWidgets('Spell the word in the picture draws its instruction once', (
      tester,
    ) async {
      await _pumpRound(tester, _labExercise('qql_lab254_image_letters'));
      expect(
        _instructionLine(tester),
        'Build the Italian word for this fruit.',
      );
      expect(find.byKey(const Key('exercise-prompt-text')), findsNothing);
      expect(find.text('Build the Italian word for this fruit.'), findsOne);
    });

    testWidgets('Spell the word keeps its clue in the body', (tester) async {
      await _pumpRound(tester, _labExercise('qql_lab254_spell_word_clue'));
      expect(_instructionLine(tester), 'Build the word shown in the image.');
      expect(
        tester.widget<Text>(find.byKey(const Key('exercise-prompt-text'))).data,
        'cat (the animal)',
      );
    });

    testWidgets('Type what you see asks once, in the instruction line', (
      tester,
    ) async {
      await _pumpRound(tester, _labExercise('qql_lab254_picture_name'));
      expect(_instructionLine(tester), 'What is this?');
      expect(find.text('What is this?'), findsOneWidget);
    });

    testWidgets('an Assign shows its instruction', (tester) async {
      await _pumpRound(tester, _labExercise('qql_lab254_assign_groups'));
      expect(_instructionLine(tester), 'Sort the words: animals or plants?');
    });
  });

  group('the optional questions that were instructions', () {
    final cases = <String, Exercise Function()>{
      'picture_choice': () => _built(
        'picture_choice',
        prompt: 'What is this?',
        answers: 'la mela\nla pera',
        correct: '1',
        imageAsset: 'assets/exercise_images/apple.webp',
      ),
      'picture_name': () => _built(
        'picture_name',
        prompt: 'What is this?',
        accepted: 'la mela',
        imageAsset: 'assets/exercise_images/apple.webp',
      ),
      'listening_image_choice': () => _built(
        'listening_image_choice',
        prompt: 'Which picture do you hear?',
        tts: 'il gatto',
        answers: 'il gatto\nil cane',
        correct: '1',
        icons:
            'assets/exercise_images/cat.webp\nassets/exercise_images/dog.webp',
      ),
      'picture_blocks': () => _built(
        'picture_blocks',
        prompt: 'What is this?',
        order: 'il\npane',
        extraWords: 'la',
        imageAsset: 'assets/exercise_images/bread.webp',
      ),
      'sort_into_groups': () => _built(
        'sort_into_groups',
        prompt: 'Sort the words: animals or plants?',
        groups: 'Animals: gatto, cane\nPlants: rosa, pino',
      ),
      'fill_the_slots': () => _built(
        'fill_the_slots',
        prompt: 'Which article goes with each noun?',
        slots: '… gatto = il\n… casa = la',
      ),
    };
    for (final entry in cases.entries) {
      test('${entry.key} stores its Instruction or context', () {
        final exercise = entry.value();
        final f = ExerciseFeatures(exercise);
        expect(f.questionText, isEmpty);
        expect(f.authoredInstruction, isNotEmpty);
        expect(
          exercise.promptElements.where((e) => e.role == 'question'),
          isEmpty,
        );
        expect(PresetRecipes.represents(exercise, entry.key), isTrue);
        expect(
          PresetRecipes.decompose(exercise, entry.key).prompt,
          f.authoredInstruction,
        );
        final keys = ExerciseFieldHelpRegistry.editorFieldKeys(entry.key);
        expect(keys, contains('prompt'));
        expect(keys, isNot(contains('question')));
        expect(
          ExerciseFieldHelpRegistry.forEditorField(entry.key, 'prompt').title,
          'Instruction or context (optional)',
        );
      });
    }

    test('Choose the answer (to source) leaves its instruction unmarked', () {
      final exercise = _built(
        'choice_source',
        prompt: 'Pick the article.',
        question: 'Which article goes with casa?',
        answers: 'la\nil',
        correct: '1',
      );
      final primary = exercise.promptElements.singleWhere(
        (e) => e.role == 'primary',
      );
      final question = exercise.promptElements.singleWhere(
        (e) => e.role == 'question',
      );
      expect(primary.language, isNull);
      expect(question.language, TextLanguage.source);
      expect(
        ExerciseFeatures(exercise).authoredInstruction,
        'Pick the article.',
      );
      expect(PresetRecipes.represents(exercise, 'choice_source'), isTrue);
    });
  });

  group('a question or sentence is never optional', () {
    for (final entry in ExerciseDraftBuilder.requiredTexts.entries) {
      test('${entry.key}: a Published save refuses its empty '
          '${entry.value.$2}', () {
        final result = _build(entry.key);
        expect(result.candidate, isNull);
        expect(result.error?.code, ExerciseDraftErrorCode.textRequired);
        expect(result.error?.field, entry.value.$1);
        expect(result.error?.detail, entry.value.$2);
        final draft = _build(entry.key, state: PublicationState.draft);
        expect(draft.error?.code, isNot(ExerciseDraftErrorCode.textRequired));
      });
    }

    test('the labels are the forms\' labels', () {
      expect(
        ExerciseDraftBuilder.requiredTexts['choice_target']!.$2,
        'Question or sentence',
      );
      expect(ExerciseDraftBuilder.requiredTexts['true_false']!.$2, 'Sentence');
      expect(
        ExerciseDraftBuilder.requiredTexts['reading_answer_target']!.$2,
        'Question',
      );
      expect(
        ExerciseDraftBuilder.requiredTexts['spell_word']!.$2,
        'Clue (source language)',
      );
    });

    testWidgets('the form refuses a Published Choose without a question', (
      tester,
    ) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _blankFor('choice_target'),
            title: 'Required question',
            isNew: true,
            onExerciseSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-answers')),
        'la\nil',
      );
      await tester.pump();
      final save = find.byKey(const Key('exercise-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(
        find.text(
          'Question or sentence: required. Enter it, or save as draft.',
        ),
        findsOneWidget,
      );
    });
  });

  group('the form', () {
    testWidgets('quotes the standard line an instruction replaces', (
      tester,
    ) async {
      _bigWindow(tester);
      final course = _laboratory();
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _labExercise('qql_lab254_sentence_order_story'),
            title: 'Instruction helper',
            isNew: false,
            course: course,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Instruction or context (optional)'), findsOneWidget);
      expect(
        find.textContaining(
          'instead of the standard line “Put the sentences in the correct order.”',
        ),
        findsOneWidget,
      );
    });
  });

  group('Recognize characters', () {
    test('text to image names the character in its question', () {
      final exercise = _labExercise('qql_lab254_script_text_image');
      final f = ExerciseFeatures(exercise);
      expect(f.questionText, 'Select the image of È (E with a grave accent).');
      expect(f.primaryText, isEmpty);
      final issues = CourseAuditService().auditExercise(exercise);
      expect(
        issues.where((issue) => issue.code == 'PRESET_CANONICAL_MISMATCH'),
        isEmpty,
      );
      // A text-to-image exercise stored with a primary text is saved with
      // the text as its question.
      final old = exercise.copyWith(
        promptElements: [
          for (final element in exercise.promptElements)
            element.role == 'question'
                ? element.copyWith(role: 'primary')
                : element,
        ],
      );
      final controller = ScriptRecognitionController(old);
      addTearDown(controller.dispose);
      final rebuilt = controller.build(PublicationState.published);
      expect(
        ExerciseFeatures(rebuilt).questionText,
        'Select the image of È (E with a grave accent).',
      );
      expect(ExerciseFeatures(rebuilt).primaryText, isEmpty);
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'script_recognition',
          'scriptPrompt',
        ).title,
        'Question or sentence',
      );
    });

    test('the Audit wants the question, not the primary text', () {
      final exercise = _labExercise('qql_lab254_script_text_image');
      final withoutQuestion = exercise.copyWith(
        promptElements: [
          for (final element in exercise.promptElements)
            element.role == 'question'
                ? element.copyWith(role: 'primary')
                : element,
        ],
      );
      expect(
        CourseAuditService()
            .auditExercise(withoutQuestion)
            .where((issue) => issue.code == 'PRESET_CANONICAL_MISMATCH')
            .map((issue) => issue.message),
        contains(
          'Text to image requires a question or sentence and at least two image-only options.',
        ),
      );
      expect(AuditCodeRegistry.byCode('PRESET_CANONICAL_MISMATCH'), isNotNull);
    });
  });

  group('the Duel', () {
    Exercise pictureChoice(int index) => _built(
      'picture_choice',
      prompt: 'What is this?',
      answers: 'la mela $index\nla pera $index',
      correct: '1',
      imageAsset: 'assets/exercise_images/apple.webp',
    ).copyWith(id: 'duel-picture-$index');

    Exercise listening(int index) => _built(
      'listening_answer_target',
      tts: 'buongiorno $index',
      answers: 'buongiorno $index\nbuonasera $index',
      correct: '1',
    ).copyWith(id: 'duel-listening-$index');

    testWidgets('a picture asks through its instruction, never "Listen"', (
      tester,
    ) async {
      await _pumpDuel(tester, [
        for (var index = 0; index < 25; index++) pictureChoice(index),
      ], settings: _Settings(audio: false, tts: false));
      expect(find.text('What is this?'), findsOneWidget);
      expect(find.text('Listen and choose the meaning.'), findsNothing);
    });

    testWidgets('a listening exercise without a question keeps the line', (
      tester,
    ) async {
      await _pumpDuel(tester, [
        for (var index = 0; index < 25; index++) listening(index),
      ], settings: _Settings(audio: true, tts: true));
      expect(find.text('Listen and choose the meaning.'), findsOneWidget);
    });
  });
}
