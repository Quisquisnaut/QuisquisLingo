import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/exercise_search_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 259 Revision 2 (plan `docs/CONTEXT_AND_HINT_PLAN.md` §6, owner
/// decisions of 29 September 2026): Listen and answer splits into **Listen
/// and choose** (no question, an optional Instruction or context) and
/// **Listen and answer** (a required question); the recording is unchanged.

final _stamp = DateTime.utc(2026, 9, 30);

Course _load(String file) => Course.fromJson(
  jsonDecode(File('assets/courses/$file').readAsStringSync())
      as Map<String, dynamic>,
);

Iterable<LearningContent> _contents(Course course) => course.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.content);

Exercise _exercise(Course course, String id) =>
    _contents(course).singleWhere((content) => content.id == id).exercise!;

Course _course(List<Lesson> lessons) => Course(
  courseId: 'r2-259-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Revision 2 259',
  ttsLanguage: 'it-IT',
  lessons: lessons,
);

Exercise _blankFor(String presetId) => Exercise(
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
).withAuthoringMetadata({'presetId': presetId});

ExerciseDraftBuildResult _build(
  String presetId, {
  PublicationState state = PublicationState.published,
  String prompt = '',
  String question = '',
  String tts = 'Buongiorno.',
  String answers = 'Buongiorno.\nBuonasera.\nBuonanotte.',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blankFor(presetId),
    type: presetId,
    publicationState: state,
    prompt: prompt,
    question: question,
    tts: tts,
    answers: answers,
    correct: '1',
  ),
);

Exercise _built(
  String presetId, {
  String prompt = '',
  String question = '',
  String tts = 'Buongiorno.',
  String answers = 'Buongiorno.\nBuonasera.\nBuonanotte.',
}) {
  final result = _build(
    presetId,
    prompt: prompt,
    question: question,
    tts: tts,
    answers: answers,
  );
  expect(result.error, isNull, reason: '${result.error?.code}');
  return result.candidate!;
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
    title: 'Revision 2 round',
    content: [LearningContent.fromExercise(exercise)],
  );
  final lesson = Lesson(
    lessonId: 'lesson-${exercise.id}',
    title: 'Revision 2 lesson',
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

Future<void> _pumpForm(WidgetTester tester, String presetId) async {
  _bigWindow(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: ExerciseEditorScreen(
        exercise: _blankFor(presetId),
        title: 'Listening form',
        isNew: true,
        course: _course(const []),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPluginMocks();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Revision 2 author');
  });

  group('the catalogue', () {
    test('Listen and choose comes first in Listening, with its twin', () {
      final listening = [
        for (final preset in ExercisePresetRegistry.presets)
          if (preset.category == ExerciseCategory.listening) preset.id,
      ];
      expect(listening.take(4), [
        'listening_choose_target',
        'listening_choose_source',
        'listening_answer_target',
        'listening_answer_source',
      ]);
      final target = ExercisePresetRegistry.byId('listening_choose_target')!;
      final source = ExercisePresetRegistry.byId('listening_choose_source')!;
      expect(target.name, 'Listen and choose (to target)');
      expect(source.name, 'Listen and choose (to source)');
      expect(target.twin, source.id);
      expect(source.twin, target.id);
      expect(target.direction, PresetDirection.toTarget);
      expect(source.direction, PresetDirection.toSource);
      expect(target.base, 'listening_choice');
      expect(target.primitive, ExercisePrimitive.select);
      expect(PresetRecipes.kinds[target.id], {
        LearnerExerciseKind.selectListen,
      });
      expect(
        ExerciseDraftBuilder.requiredTexts['listening_answer_target']!.$2,
        'Question',
      );
      expect(
        ExerciseDraftBuilder.requiredTexts['listening_answer_source']!.$2,
        'Question',
      );
      expect(ExerciseDraftBuilder.requiredTexts, isNot(contains(target.id)));
    });

    test('its form, Search and Help know it', () {
      for (final id in ['listening_choose_target', 'listening_choose_source']) {
        expect(ExerciseFieldHelpRegistry.editorFieldKeys(id), [
          'tts',
          'prompt',
          'answers',
          'correct',
          'image',
        ]);
        expect(
          ExerciseFieldHelpRegistry.forEditorField(id, 'prompt').title,
          'Instruction or context (optional)',
        );
        expect(
          ExerciseSearchRegistry.definitions.map((d) => d.presetId),
          contains(id),
        );
        expect(exerciseHelpPresetIds, contains(id));
        for (final catalog in [helpEn, helpIt, helpEs]) {
          expect(catalog['exerciseHelp.preset.$id.description'], isNotNull);
          expect(catalog['exerciseHelp.preset.$id.body'], isNotNull);
        }
      }
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'listening_answer_target',
          'question',
        ).title,
        'Question',
      );
      for (final catalog in [helpEn, helpIt, helpEs]) {
        expect(
          catalog['exerciseHelp.field.listening_answer.question.body'],
          isNotNull,
        );
      }
    });
  });

  group('Listen and choose', () {
    test('stores its Instruction or context without a language', () {
      final exercise = _built(
        'listening_choose_target',
        prompt: 'Choose the greeting you hear.',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.selectListen);
      expect(f.questionText, isEmpty);
      expect(f.authoredInstruction, 'Choose the greeting you hear.');
      expect(f.automaticAudio?.text, 'Buongiorno.');
      expect(exercise.editorTemplate, 'listening_choose_target');
      expect(
        PresetRecipes.represents(exercise, 'listening_choose_target'),
        isTrue,
      );
      final draft = PresetRecipes.decompose(
        exercise,
        'listening_choose_target',
      );
      expect(draft.prompt, 'Choose the greeting you hear.');
      expect(draft.question, isEmpty);
      // Without an instruction the standard line speaks.
      final plain = _built('listening_choose_target');
      expect(ExerciseFeatures(plain).authoredInstruction, isEmpty);
      expect(
        PresetRecipes.represents(plain, 'listening_choose_target'),
        isTrue,
      );
    });

    test('to source marks the answers, never the instruction', () {
      final exercise = _built(
        'listening_choose_source',
        prompt: 'A friend thanks you.',
        tts: 'Grazie mille!',
        answers: 'Thank you very much\nGood night\nSee you soon',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.authoredInstruction, 'A friend thanks you.');
      expect(
        exercise.items.expand((item) => item.content).map((e) => e.language),
        everyElement(TextLanguage.source),
      );
      expect(
        PresetRecipes.represents(exercise, 'listening_choose_source'),
        isTrue,
      );
    });

    test('recognition prefers it for an exercise without a question', () {
      final plain = _built(
        'listening_choose_target',
      ).withAuthoringMetadata(const {});
      expect(PresetRecipes.recognize(plain), 'listening_choose_target');
      final asked = _built(
        'listening_answer_target',
        question: 'Che cosa dice?',
      ).withAuthoringMetadata(const {});
      expect(PresetRecipes.recognize(asked), 'listening_answer_target');
    });

    testWidgets('shows its instruction in place of the standard line', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _built(
          'listening_choose_target',
          prompt: 'Choose the greeting you hear.',
        ),
      );
      expect(_instructionLine(tester), 'Choose the greeting you hear.');
      expect(find.text('Choose the greeting you hear.'), findsOneWidget);
    });

    testWidgets('the form has an instruction field and no question', (
      tester,
    ) async {
      await _pumpForm(tester, 'listening_choose_target');
      expect(find.text('Instruction or context (optional)'), findsOneWidget);
      expect(
        find.textContaining(
          'instead of the standard line “Select the sentence that you heard.”',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exercise-field-question')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('exercise-field-prompt')),
        findsOneWidget,
      );
    });
  });

  group('Listen and answer', () {
    test('a Published save needs the question; a draft does not', () {
      final published = _build('listening_answer_target');
      expect(published.error?.code, ExerciseDraftErrorCode.textRequired);
      expect(published.error?.detail, 'Question');
      expect(
        _build('listening_answer_target', state: PublicationState.draft).error,
        isNull,
      );
      final source = _build('listening_answer_source', answers: 'Yes\nNo');
      expect(source.error?.code, ExerciseDraftErrorCode.textRequired);
    });

    test('a new one asks its question about the passage', () {
      final exercise = _built(
        'listening_answer_target',
        question: 'Dove fa la spesa Maria?',
        tts: 'Maria compra due mele e un chilo di pane al mercato.',
        answers: 'Al mercato.\nA scuola.\nIn stazione.',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.selectListenPassage);
      expect(f.questionText, 'Dove fa la spesa Maria?');
      expect(f.authoredInstruction, isEmpty);
      expect(
        PresetRecipes.represents(exercise, 'listening_answer_target'),
        isTrue,
      );
    });

    testWidgets('the form labels its question Question', (tester) async {
      await _pumpForm(tester, 'listening_answer_target');
      expect(find.text('Question'), findsOneWidget);
      expect(find.text('Question (optional)'), findsNothing);
      expect(find.text('Instruction or context (optional)'), findsNothing);
    });

    testWidgets('keeps the standard line and asks in the body', (tester) async {
      await _pumpRound(
        tester,
        _built(
          'listening_answer_target',
          question: 'Dove fa la spesa Maria?',
          tts: 'Maria compra due mele e un chilo di pane al mercato.',
          answers: 'Al mercato.\nA scuola.\nIn stazione.',
        ),
      );
      expect(_instructionLine(tester), 'Listen and answer the question.');
      expect(find.text('Dove fa la spesa Maria?'), findsOneWidget);
    });
  });

  group('the demo content', () {
    test('the Laboratory shows both presets in both directions', () {
      final lab = _load('exercise_laboratory_en_it.json');
      final word = _exercise(lab, 'qql_lab254_select_listening_word');
      expect(word.editorTemplate, 'listening_choose_target');
      expect(
        ExerciseFeatures(word).authoredInstruction,
        'Choose the greeting you hear.',
      );
      final source = _exercise(lab, 'qql_lab254_listening_source');
      expect(source.editorTemplate, 'listening_choose_source');
      expect(
        ExerciseFeatures(source).authoredInstruction,
        'What did you hear?',
      );
      final passage = _exercise(lab, 'qql_lab254_select_listening_passage');
      expect(passage.editorTemplate, 'listening_answer_target');
      final question = _exercise(lab, 'qql_lab254_listening_source_question');
      expect(question.editorTemplate, 'listening_answer_source');
      expect(
        ExerciseFeatures(question).questionText,
        'When does the train leave?',
      );
      for (final exercise in [word, source, passage, question]) {
        expect(
          PresetRecipes.represents(exercise, exercise.editorTemplate),
          isTrue,
          reason: exercise.id,
        );
      }
    });
  });
}
