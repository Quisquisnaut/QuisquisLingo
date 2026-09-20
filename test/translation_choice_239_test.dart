import 'support/test_directories.dart';
// QQL Build 239: focused tests for the two Select-based translation choice
// presets, "Pick the translation (to target)" and "(to source)".
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/new_course_structure.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/translation_choice_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;

const _toTarget = TranslationChoice.toTarget;
const _toSource = TranslationChoice.toSource;

Exercise _translationChoice({
  String id = 'tc',
  String type = _toTarget,
  String? text,
  List<String>? answers,
  int correct = 0,
  String imageAsset = '',
  String prompt = '',
  String? tts,
}) {
  final toTarget = type == _toTarget;
  return Exercise(
    id: id,
    updatedAt: DateTime.utc(2026, 9, 18),
    type: type,
    prompt: prompt,
    question: text ?? (toTarget ? 'I am going to London' : 'Vado a Londra.'),
    answers:
        answers ??
        (toTarget
            ? const [
                'Vado a Londra.',
                'Sono andato a Londra.',
                'Vengo da Londra.',
              ]
            : const [
                'I am going to London.',
                'I went to London.',
                'I am coming from London.',
              ]),
    correct: correct,
    tts: tts,
    accepted: const [],
    tokens: const [],
    orderAnswer: const [],
    pairs: const [],
    hint: '',
    icons: const [],
    imageAsset: imageAsset,
  );
}

Exercise _legacyChoice() => Exercise(
  id: 'legacy-choice',
  updatedAt: DateTime.utc(2026, 9, 18),
  type: 'choice',
  prompt: 'Good morning',
  question: '',
  answers: const ['Buongiorno', 'Buonanotte', 'Ciao'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Course _course({
  String source = 'English',
  String target = 'Italian',
  List<Lesson> lessons = const [],
}) => Course(
  courseId: 'tc-239-course',
  learningLanguage: target,
  interfaceLanguage: 'English',
  sourceLanguage: source,
  targetLanguage: target,
  title: 'Translation choice',
  ttsLanguage: 'it-IT',
  lessons: lessons,
);

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
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        final playerId = arguments['playerId'] as String;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/$playerId',
          (message) async =>
              const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (message) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 160; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for the expected widget.');
}

Future<void> _pumpRound(
  WidgetTester tester,
  Exercise exercise, {
  bool preview = true,
  SettingsService? settings,
  Course? course,
}) async {
  _bigWindow(tester);
  final round = LearningRound(
    id: 'round-${exercise.id}',
    title: 'Translation choice round',
    content: [LearningContent.fromExercise(exercise)],
  );
  final lesson = Lesson(
    lessonId: 'lesson-${exercise.id}',
    title: 'Translation choice lesson',
    rounds: [round],
  );
  final resolved = course ?? _course(lessons: [lesson]);
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: resolved,
        lesson: lesson,
        round: round,
        ttsLanguage: 'it-IT',
        roundIndex: 0,
        previewMode: preview,
        settingsService: settings,
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await _pumpUntil(tester, find.byKey(const Key('translation-choice-text')));
}

Future<void> _pumpDuel(
  WidgetTester tester,
  String type, {
  SettingsService? settings,
  ThemeData? theme,
}) async {
  _bigWindow(tester);
  final round = LearningRound(
    id: 'duel-round',
    title: 'Duel round',
    exercises: [
      for (var index = 0; index < 25; index++)
        _translationChoice(id: 'duel-$index', type: type),
    ],
  );
  final lesson = Lesson(
    lessonId: 'duel-lesson',
    title: 'Duel lesson',
    rounds: [round],
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: DuelScreen(
        course: _course(lessons: [lesson]),
        lesson: lesson,
        ttsLanguage: 'it-IT',
        settingsService: settings ?? _Settings(audio: true, tts: true),
      ),
    ),
  );
  await _pumpUntil(tester, find.text('Question 1/25 · 4 lives'));
}

FilledButton _button(WidgetTester tester, String text) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, text).first);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPluginMocks();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Translation choice learner');
    await SettingsService().setSoundEffectsEnabled(false);
  });

  group('registry and model', () {
    test('both presets appear in the Translation category', () {
      final translation = ExercisePresetRegistry.inCategory(
        ExerciseCategory.translation,
      ).map((preset) => preset.id);
      expect(translation, contains(_toTarget));
      expect(translation, contains(_toSource));
      expect(
        ExercisePresetRegistry.byId(_toTarget)?.name,
        'Pick the translation (to target)',
      );
      expect(
        ExercisePresetRegistry.byId(_toSource)?.name,
        'Pick the translation (to source)',
      );
    });

    test('both presets resolve to the existing Select primitive', () {
      for (final id in [_toTarget, _toSource]) {
        final preset = ExercisePresetRegistry.byId(id)!;
        expect(preset.model, CanonicalExerciseModel.select);
        expect(preset.description, startsWith('Select:'));
        expect(ExercisePresetRegistry.helpByPreset[id], startsWith('Select'));
        final exercise = _translationChoice(type: id);
        expect(exercise.interaction.kind, 'select');
        expect(exercise.evaluation.kind, 'selected_items');
      }
    });

    test('language roles follow the direction', () {
      final course = _course();
      expect(TranslationChoice.mainTextIsTarget(_toTarget), isFalse);
      expect(TranslationChoice.mainTextIsTarget(_toSource), isTrue);
      expect(TranslationChoice.answerLanguage(course, _toTarget), 'Italian');
      expect(TranslationChoice.answerLanguage(course, _toSource), 'English');
    });

    test('the learner instruction is generated from the course languages', () {
      expect(
        TranslationChoice.instruction(_course(), _toTarget),
        'Pick the correct Italian translation',
      );
      expect(
        TranslationChoice.instruction(_course(), _toSource),
        'Pick the correct English translation',
      );
      expect(
        TranslationChoice.instruction(
          _course(source: 'English', target: 'French'),
          _toTarget,
        ),
        'Pick the correct French translation',
      );
      expect(
        TranslationChoice.instruction(
          _course(source: 'French', target: 'German'),
          _toSource,
        ),
        'Pick the correct French translation',
      );
      expect(
        TranslationChoice.instruction(
          _course(source: 'Italian', target: 'English'),
          _toTarget,
        ),
        'Pick the correct English translation',
      );
    });

    test('only the to-source text is speakable before answering', () {
      final toTarget = _translationChoice(type: _toTarget);
      final toSource = _translationChoice(type: _toSource);
      expect(TranslationChoice.spokenText(toTarget, answered: false), isNull);
      expect(
        TranslationChoice.spokenText(toTarget, answered: true),
        'Vado a Londra.',
      );
      expect(
        TranslationChoice.spokenText(toSource, answered: false),
        'Vado a Londra.',
      );
    });

    test('the New Course sample is Pick the translation (to target)', () {
      final lessons = NewCourseStructure.create(
        lessonCount: 1,
        roundsPerLesson: 1,
        sourceLanguage: 'English',
        learningLanguage: 'Italian',
        updatedAt: DateTime.utc(2026, 9, 19),
      );
      final sample = lessons.single.rounds.single.exercises.single;
      expect(sample.type, _toTarget);
      expect(sample.publicationState, PublicationState.draft);
      expect(sample.prompt, isEmpty);
      expect(sample.question, 'Text in English');
      expect(sample.answers, ['Translation in Italian', 'Wrong Answer']);
      expect(sample.correct, 0);
      expect(CourseAuditService().auditExercise(sample), isEmpty);
    });

    test('exercises round-trip through JSON', () {
      for (final type in [_toTarget, _toSource]) {
        final exercise = _translationChoice(type: type, correct: 1);
        final restored = Exercise.fromV2Json(
          exercise.toJson(),
          contentId: exercise.id,
          editorTemplate: exercise.editorTemplate,
          publicationState: exercise.publicationState,
        );
        expect(restored.type, type);
        expect(restored.question, exercise.question);
        expect(restored.answers, exercise.answers);
        expect(restored.correct, 1);
      }
    });

    test('existing exercise types remain available and unchanged', () {
      for (final id in [
        'choice',
        'gap_choice',
        'type_translation',
        'build_translation',
        'dialogue_response',
        'word_order',
      ]) {
        expect(ExercisePresetRegistry.byId(id), isNotNull, reason: id);
      }
      final legacy = _legacyChoice();
      expect(legacy.type, 'choice');
      expect(legacy.isMultiSelect, isFalse);
      expect(legacy.correct, 0);
      expect(
        ExerciseCopyService.typeLabel(_course(), 'choice'),
        isNot(anyOf(isEmpty, contains('translation'))),
      );
    });
  });

  group('audit', () {
    List<String> codes(Exercise exercise) => CourseAuditService()
        .auditExercise(exercise)
        .map((issue) => issue.code)
        .toList();

    test('valid exercises produce no issues', () {
      expect(codes(_translationChoice(type: _toTarget)), isEmpty);
      expect(codes(_translationChoice(type: _toSource)), isEmpty);
    });

    test('the code list documents TRANSLATION_CHOICE_TEXT_REQUIRED', () {
      final code = AuditCodeRegistry.byCode('TRANSLATION_CHOICE_TEXT_REQUIRED');
      expect(code, isNotNull);
      expect(code!.severity, AuditSeverity.error);
      expect(code.scope, contains('Pick the translation'));
    });

    test('blank text to translate is an error', () {
      expect(
        codes(_translationChoice(text: '  ')),
        contains('TRANSLATION_CHOICE_TEXT_REQUIRED'),
      );
    });

    test('too few answers and invalid correct answers are flagged', () {
      expect(
        codes(_translationChoice(answers: const ['Vado a Londra.'])),
        contains('CHOICE_ANSWERS_REQUIRED'),
      );
      expect(
        codes(_translationChoice(correct: 9)),
        contains('CHOICE_CORRECT_ANSWER_INVALID'),
      );
    });

    test('duplicate and blank options are flagged', () {
      expect(
        codes(_translationChoice(answers: const ['Ciao', 'ciao', 'Salve'])),
        contains('CHOICE_ANSWER_DUPLICATE'),
      );
    });

    test('an authored prompt or spoken text is an unexpected field', () {
      expect(
        codes(_translationChoice(prompt: 'Translate this')),
        contains('EXERCISE_FIELD_UNEXPECTED'),
      );
      expect(
        codes(_translationChoice(tts: 'Vado a Londra.')),
        contains('EXERCISE_FIELD_UNEXPECTED'),
      );
    });

    test('the Exercise Help example names the course pair', () {
      for (final id in [_toTarget, _toSource]) {
        final help = ExercisePresetRegistry.helpByPreset[id]!;
        expect(help, contains('Example (for an English → Italian course):'));
        expect(help, contains('two to five different'));
      }
    });

    test('at most 5 answer options are accepted', () {
      expect(
        codes(_translationChoice(answers: const ['a', 'b', 'c', 'd', 'e'])),
        isNot(contains('TRANSLATION_CHOICE_TOO_MANY_ANSWERS')),
      );
      expect(
        codes(
          _translationChoice(answers: const ['a', 'b', 'c', 'd', 'e', 'f']),
        ),
        contains('TRANSLATION_CHOICE_TOO_MANY_ANSWERS'),
      );
      final code = AuditCodeRegistry.byCode(
        'TRANSLATION_CHOICE_TOO_MANY_ANSWERS',
      );
      expect(code, isNotNull);
      expect(code!.severity, AuditSeverity.error);
    });

    test(
      'repeated answer phrases are flagged ignoring case, spaces, punctuation',
      () {
        expect(
          TranslationChoice.hasRepeatedAnswers(['Ciao', 'Salve']),
          isFalse,
        );
        expect(TranslationChoice.hasRepeatedAnswers(['Ciao', 'ciao']), isTrue);
        expect(
          TranslationChoice.hasRepeatedAnswers([
            'Vado a Londra.',
            'vado  a londra',
          ]),
          isTrue,
        );
        expect(
          codes(
            _translationChoice(
              answers: const ['Vado a Londra.', 'vado a  londra', 'Ciao'],
            ),
          ),
          contains('CHOICE_ANSWER_DUPLICATE'),
        );
        expect(TranslationChoice.answersProblem(['a', 'b']), isNull);
        expect(TranslationChoice.answersProblem(['a', 'A']), isNotNull);
        expect(
          TranslationChoice.answersProblem(['a', 'b', 'c', 'd', 'e', 'f']),
          isNotNull,
        );
      },
    );

    test('multiple selection is a preset mismatch', () {
      final base = _translationChoice();
      final multi = Exercise.v2(
        id: base.id,
        updatedAt: base.updatedAt,
        editorTemplate: _toTarget,
        promptElements: base.promptElements,
        interaction: ExerciseInteraction(
          kind: 'select',
          minSelections: 2,
          maxSelections: 3,
          items: base.interaction.items,
        ),
        evaluation: const ExerciseEvaluation(
          kind: 'selected_items',
          correctItemIds: ['item_0', 'item_1'],
        ),
      );
      expect(codes(multi), contains('PRESET_CANONICAL_MISMATCH'));
    });

    test('the exercises are not treated as audio exercises', () {
      final availability = AudioExerciseAvailabilityService();
      for (final type in [_toTarget, _toSource]) {
        expect(
          availability.isAudioExercise(
            _translationChoice(type: type, tts: 'anything'),
          ),
          isFalse,
        );
      }
    });

    test('Duel accepts both types', () {
      final round = LearningRound(
        id: 'r',
        title: 'r',
        exercises: [
          for (var i = 0; i < 25; i++)
            _translationChoice(
              id: 'e$i',
              type: i.isEven ? _toTarget : _toSource,
            ),
        ],
      );
      final lesson = Lesson(lessonId: 'l', title: 'l', rounds: [round]);
      final result = const DuelEligibilityService().evaluate(lesson);
      expect(result.eligibleCount, 25);
    });
  });

  group('editor', () {
    for (final type in [_toTarget, _toSource]) {
      testWidgets('$type exposes only the four authoring fields', (
        tester,
      ) async {
        _bigWindow(tester);
        Exercise? saved;
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: _translationChoice(
                type: type,
                text: '',
                answers: const [],
              ),
              title: 'Translation choice authoring',
              isNew: true,
              onExerciseSaved: (e) => saved = e,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(workflow.field('Text to translate'), findsOneWidget);
        expect(workflow.field('Answer options'), findsOneWidget);
        expect(workflow.field('Correct answer number'), findsOneWidget);
        expect(find.text('Exercise image'), findsOneWidget);
        // The Select note lives in Exercise Help, not in the editor form.
        expect(find.textContaining('checked immediately'), findsNothing);
        expect(
          find.byKey(const Key('translation-choice-select-note')),
          findsNothing,
        );

        // Implied configuration and the fixed instruction are not editable.
        expect(workflow.field('Prompt / instruction'), findsNothing);
        expect(workflow.field('Question'), findsNothing);
        expect(workflow.field('Answers'), findsNothing);
        expect(find.byType(SwitchListTile), findsNothing);
        expect(workflow.field('Direction'), findsNothing);
        expect(find.text('Direction'), findsNothing);
        expect(find.text('Source language'), findsNothing);
        expect(find.text('Target language'), findsNothing);

        await tester.enterText(
          workflow.field('Text to translate'),
          'Some text',
        );
        await tester.enterText(
          workflow.field('Answer options'),
          'One\nTwo\nThree',
        );
        await tester.enterText(workflow.field('Correct answer number'), '2');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await workflow.tapKey(tester, 'exercise-save');

        expect(saved, isNotNull);
        expect(saved!.type, type);
        expect(saved!.question, 'Some text');
        expect(saved!.prompt, isEmpty);
        expect(saved!.answers, ['One', 'Two', 'Three']);
        expect(saved!.correct, 1);
        expect(saved!.tts, isNull);
        expect(saved!.interaction.kind, 'select');
        expect(saved!.isMultiSelect, isFalse);
      });
    }

    for (final entry in {
      'more than 5 options': ('A\nB\nC\nD\nE\nF', 'at most 5'),
      'repeated options': ('Ciao\nSalve\nciao', 'repeat the same phrase'),
    }.entries) {
      testWidgets('Save rejects ${entry.key}', (tester) async {
        _bigWindow(tester);
        Exercise? saved;
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: _translationChoice(text: '', answers: const []),
              title: 'Translation choice authoring',
              isNew: true,
              onExerciseSaved: (e) => saved = e,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(workflow.field('Text to translate'), 'Some');
        await tester.enterText(
          workflow.field('Answer options'),
          entry.value.$1,
        );
        await tester.enterText(workflow.field('Correct answer number'), '1');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await workflow.tapKey(tester, 'exercise-save');
        expect(saved, isNull);
        expect(find.textContaining(entry.value.$2), findsWidgets);
      });
    }

    testWidgets('Save accepts exactly 5 different options', (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _translationChoice(text: '', answers: const []),
            title: 'Translation choice authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(workflow.field('Text to translate'), 'Some');
      await tester.enterText(workflow.field('Answer options'), 'A\nB\nC\nD\nE');
      await tester.enterText(workflow.field('Correct answer number'), '1');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      expect(saved!.answers, hasLength(5));
    });

    test(
      'field help exists for every field and the tooltip is the purpose',
      () {
        for (final id in [_toTarget, _toSource]) {
          final keys = ExerciseFieldHelpRegistry.editorFieldKeys(id);
          expect(
            keys,
            containsAll(['question', 'answers', 'correct', 'image']),
          );
          for (final key in keys) {
            final help = ExerciseFieldHelpRegistry.forEditorField(id, key);
            expect(help.purpose, isNotEmpty);
            expect(help.text, isNotEmpty);
          }
        }
        expect(
          ExerciseFieldHelpRegistry.forEditorField(
            _toTarget,
            'question',
          ).purpose,
          contains('source-language'),
        );
        expect(
          ExerciseFieldHelpRegistry.forEditorField(
            _toSource,
            'question',
          ).purpose,
          contains('target-language'),
        );
        // No Field Help dialog of these types carries an example, and the
        // tooltip (purpose) never does either.
        for (final id in [_toTarget, _toSource]) {
          for (final key in ExerciseFieldHelpRegistry.editorFieldKeys(id)) {
            final help = ExerciseFieldHelpRegistry.forEditorField(id, key);
            expect(help.example, isNull, reason: '$id/$key');
            expect(
              help.purpose,
              isNot(contains('Example')),
              reason: '$id/$key',
            );
            expect(help.text, isNot(contains('Example')), reason: '$id/$key');
            expect(help.text, isNot(contains('London')), reason: '$id/$key');
            expect(help.text, isNot(contains('Vado')), reason: '$id/$key');
          }
        }
      },
    );

    for (final type in [_toTarget, _toSource]) {
      testWidgets('$type starts with Correct answer number 1', (tester) async {
        _bigWindow(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: _translationChoice(
                type: type,
                text: '',
                answers: const [],
                correct: -1,
              ),
              title: 'Translation choice authoring',
              isNew: true,
              onExerciseSaved: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final correct = tester.widget<TextField>(
          workflow.field('Correct answer number'),
        );
        expect(correct.controller!.text, '1');
      });
    }
    testWidgets(
      'choosing the type in the picker fills Correct answer number 1',
      (tester) async {
        _bigWindow(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: Exercise(
                id: 'blank-choice-2',
                updatedAt: DateTime.utc(2026, 9, 18),
                type: 'choice',
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
              ),
              title: 'New exercise',
              isNew: true,
              onExerciseSaved: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('exercise-preset-selector')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('exercise-preset-search')),
          'to target',
        );
        await tester.pump();
        await tester.tap(find.text('Pick the translation (to target)'));
        await tester.pumpAndSettle();
        final correct = tester.widget<TextField>(
          workflow.field('Correct answer number'),
        );
        expect(correct.controller!.text, '1');
      },
    );

    testWidgets('Choose does not get an automatic Correct answer number', (
      tester,
    ) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: Exercise(
              id: 'blank-choice',
              updatedAt: DateTime.utc(2026, 9, 18),
              type: 'choice',
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
            ),
            title: 'Choose authoring',
            isNew: true,
            onExerciseSaved: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final correct = tester.widget<TextField>(
        workflow.field('Correct answer number'),
      );
      expect(correct.controller!.text, isEmpty);
    });

    test('the Exercise Help chapter opens with the Select note', () {
      for (final id in [_toTarget, _toSource]) {
        expect(
          ExercisePresetRegistry.helpByPreset[id],
          startsWith(
            'Select · single answer, checked immediately. Direction, '
            'languages and the learner instruction are set by this type.\n\n',
          ),
        );
      }
    });

    for (final type in [_toTarget, _toSource]) {
      testWidgets('$type opens Exercise Help on its own chapter', (
        tester,
      ) async {
        _bigWindow(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: ExerciseEditorScreen(
              exercise: _translationChoice(type: type),
              title: 'Translation choice authoring',
              isNew: true,
              onExerciseSaved: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Exercise Help'));
        await tester.pumpAndSettle();

        final name = ExercisePresetRegistry.byId(type)!.name;
        final search = tester.widget<TextField>(
          find.byKey(const ValueKey('exercise-help-search')),
        );
        expect(search.controller!.text, name);
        expect(
          find.byKey(ValueKey('exercise-help-result-$type')),
          findsOneWidget,
        );
        expect(find.textContaining('Select · single answer'), findsOneWidget);
      });
    }

    testWidgets('an existing type still opens Exercise Help unfiltered', (
      tester,
    ) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _legacyChoice(),
            title: 'Choose authoring',
            isNew: true,
            onExerciseSaved: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Exercise Help'));
      await tester.pumpAndSettle();
      final search = tester.widget<TextField>(
        find.byKey(const ValueKey('exercise-help-search')),
      );
      expect(search.controller!.text, isEmpty);
    });
  });

  group('New exercise default', () {
    testWidgets(
      'the Round New exercise button starts with Pick the translation',
      (tester) async {
        _bigWindow(tester);
        final round = LearningRound(
          id: 'new-ex-round',
          title: 'Round',
          content: const [],
        );
        final lesson = Lesson(
          lessonId: 'new-ex-lesson',
          title: 'Lesson',
          rounds: [round],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: RoundEditorScreen(
              course: _course(lessons: [lesson]),
              lesson: lesson,
              round: round,
              roundIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('new-exercise')));
        await tester.pumpAndSettle();
        expect(find.text('Pick the translation (to target)'), findsWidgets);
        expect(workflow.field('Text to translate'), findsOneWidget);
        final correct = tester.widget<TextField>(
          workflow.field('Correct answer number'),
        );
        expect(correct.controller!.text, '1');
      },
    );
  });

  group('learner Round', () {
    testWidgets('to target shows exactly one principal instruction', (
      tester,
    ) async {
      await _pumpRound(tester, _translationChoice(type: _toTarget));
      expect(
        find.byKey(const Key('translation-choice-instruction')),
        findsOneWidget,
      );
      expect(find.text('Pick the correct Italian translation'), findsOneWidget);
      expect(find.textContaining('Pick the correct'), findsOneWidget);
      expect(find.text('I am going to London'), findsOneWidget);
      // The editor-only preset name and stock type labels are never shown.
      expect(find.text('Pick the translation (to target)'), findsNothing);
      expect(find.text('CHOOSE'), findsNothing);
      expect(find.text('Choose the correct answer.'), findsNothing);
    });

    testWidgets('to source shows exactly one principal instruction', (
      tester,
    ) async {
      await _pumpRound(tester, _translationChoice(type: _toSource));
      expect(find.text('Pick the correct English translation'), findsOneWidget);
      expect(find.textContaining('Pick the correct'), findsOneWidget);
      expect(find.text('Vado a Londra.'), findsOneWidget);
      expect(find.text('Pick the translation (to source)'), findsNothing);
    });

    testWidgets('tapping the right answer validates immediately', (
      tester,
    ) async {
      await _pumpRound(tester, _translationChoice(type: _toTarget));
      expect(find.widgetWithText(FilledButton, 'Check'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Submit'), findsNothing);
      await tester.tap(find.text('Vado a Londra.'));
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
      expect(find.textContaining('Correct answer:'), findsNothing);
      // The answer is locked once evaluated.
      expect(_button(tester, 'Sono andato a Londra.').onPressed, isNull);
    });

    testWidgets('a wrong answer reveals the correct answer', (tester) async {
      await _pumpRound(tester, _translationChoice(type: _toTarget));
      await tester.tap(find.text('Vengo da Londra.'));
      await tester.pump();
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Correct answer: Vado a Londra.'), findsOneWidget);
    });

    testWidgets('only one answer can be selected', (tester) async {
      await _pumpRound(tester, _translationChoice(type: _toSource));
      await tester.tap(find.text('I went to London.'));
      await tester.pump();
      await tester.tap(find.text('I am going to London.'));
      await tester.pump();
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Correct'), findsNothing);
    });

    testWidgets('an optional illustration is shown when present', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        _translationChoice(type: _toTarget, imageAsset: 'assets/none.png'),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Pick the correct Italian translation'), findsOneWidget);
    });

    testWidgets('no illustration leaves no placeholder', (tester) async {
      await _pumpRound(tester, _translationChoice(type: _toSource));
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('Image asset'), findsNothing);
    });

    testWidgets('to target never speaks or offers audio before answering', (
      tester,
    ) async {
      await _pumpRound(tester, _translationChoice(type: _toTarget));
      expect(find.byKey(const Key('translation-choice-audio')), findsNothing);
      await tester.tap(find.text('Vado a Londra.'));
      await tester.pump();
      expect(find.text('Listen to the answer'), findsOneWidget);
      final audio = tester.widget<IconButton>(
        find.byKey(const Key('translation-choice-audio')),
      );
      expect(audio.onPressed, isNotNull);
    });

    testWidgets('to source offers the target-language text audio button', (
      tester,
    ) async {
      await _pumpRound(tester, _translationChoice(type: _toSource));
      final audio = tester.widget<IconButton>(
        find.byKey(const Key('translation-choice-audio')),
      );
      expect(audio.onPressed, isNotNull);
      expect(find.text('Listen to the answer'), findsNothing);
    });

    testWidgets('audio and TTS off do not skip the exercise', (tester) async {
      for (final type in [_toTarget, _toSource]) {
        await _pumpRound(
          tester,
          _translationChoice(id: 'off-$type', type: type),
          preview: false,
          settings: _Settings(audio: false, tts: false),
        );
        // The exercise is presented instead of skipped.
        expect(
          find.byKey(const Key('translation-choice-text')),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);
        if (type == _toSource) {
          final audio = tester.widget<IconButton>(
            find.byKey(const Key('translation-choice-audio')),
          );
          expect(audio.onPressed, isNull);
          expect(
            find.byKey(const Key('translation-choice-audio-note')),
            findsOneWidget,
          );
        } else {
          await tester.tap(find.text('Vado a Londra.'));
          await tester.pump();
          final audio = tester.widget<IconButton>(
            find.byKey(const Key('translation-choice-audio')),
          );
          expect(audio.onPressed, isNull);
        }
        // Validation and feedback are unchanged without audio.
        await tester.tap(
          find.text(type == _toTarget ? 'Vado a Londra.' : 'I went to London.'),
          warnIfMissed: false,
        );
        await tester.pump();
        expect(find.byType(SnackBar), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('Preview shows the same single instruction as the learner', (
      tester,
    ) async {
      await _pumpRound(tester, _translationChoice(type: _toTarget));
      final previewText = tester
          .widget<Text>(find.byKey(const Key('translation-choice-instruction')))
          .data;
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpRound(
        tester,
        _translationChoice(id: 'learner', type: _toTarget),
        preview: false,
        settings: _Settings(audio: true, tts: true),
      );
      final learnerText = tester
          .widget<Text>(find.byKey(const Key('translation-choice-instruction')))
          .data;
      expect(learnerText, previewText);
    });

    testWidgets('an existing Choose exercise renders unchanged', (
      tester,
    ) async {
      _bigWindow(tester);
      final exercise = _legacyChoice();
      final round = LearningRound(
        id: 'legacy-round',
        title: 'Legacy',
        content: [LearningContent.fromExercise(exercise)],
      );
      final lesson = Lesson(
        lessonId: 'legacy-lesson',
        title: 'Legacy',
        rounds: [round],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: _course(lessons: [lesson]),
            lesson: lesson,
            round: round,
            ttsLanguage: 'it-IT',
            roundIndex: 0,
            previewMode: true,
          ),
        ),
      );
      await _pumpUntil(
        tester,
        find.byKey(const Key('exercise-renderer-choice')),
      );
      expect(find.text('CHOOSE'), findsOneWidget);
      expect(
        find.byKey(const Key('translation-choice-instruction')),
        findsNothing,
      );
    });
  });

  group('learner Duel', () {
    for (final dark in [true, false]) {
      testWidgets('Duel is readable in ${dark ? 'dark' : 'light'} mode', (
        tester,
      ) async {
        final theme = dark ? ThemeData.dark() : ThemeData.light();
        await _pumpDuel(tester, _toTarget, theme: theme);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        final background = scaffold.backgroundColor!;
        final text = theme.colorScheme.onSurface;
        double contrast(Color a, Color b) {
          final l1 = a.computeLuminance();
          final l2 = b.computeLuminance();
          final hi = l1 > l2 ? l1 : l2;
          final lo = l1 > l2 ? l2 : l1;
          return (hi + 0.05) / (lo + 0.05);
        }

        // The text, the Back arrow and the title use the theme colors on
        // this background, so the pair must have real contrast.
        expect(contrast(background, text), greaterThan(4.5));
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, background);

        await tester.tap(find.widgetWithText(FilledButton, 'Vado a Londra.'));
        await tester.pump();
        final feedback = tester
            .widgetList<Container>(find.byType(Container))
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.color)
            .whereType<Color>()
            .where((c) => c.a > 0)
            .toList();
        // Every opaque-ish panel behind the feedback text keeps contrast.
        for (final color in feedback) {
          final solid = Color.alphaBlend(color, background);
          expect(contrast(solid, text), greaterThan(3.0));
        }
      });
    }

    testWidgets('to target has one instruction and no fallback message', (
      tester,
    ) async {
      await _pumpDuel(tester, _toTarget);
      expect(find.text('Pick the correct Italian translation'), findsOneWidget);
      expect(find.textContaining('Pick the correct'), findsOneWidget);
      expect(find.text('I am going to London'), findsOneWidget);
      expect(find.text('Listen and choose the meaning.'), findsNothing);
      expect(find.text('Pick the translation (to target)'), findsNothing);
      expect(find.byKey(const Key('translation-choice-audio')), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Vado a Londra.'));
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Listen to the answer'), findsOneWidget);
    });

    testWidgets('to source speaks the target text and reveals wrong answers', (
      tester,
    ) async {
      await _pumpDuel(tester, _toSource);
      expect(find.text('Pick the correct English translation'), findsOneWidget);
      expect(find.text('Vado a Londra.'), findsOneWidget);
      expect(find.byKey(const Key('translation-choice-audio')), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'I went to London.'));
      await tester.pump();
      expect(find.text('Incorrect'), findsOneWidget);
      expect(
        find.text('Correct answer: I am going to London.'),
        findsOneWidget,
      );
    });

    testWidgets('audio off greys the button without skipping the exercise', (
      tester,
    ) async {
      await _pumpDuel(
        tester,
        _toSource,
        settings: _Settings(audio: false, tts: false),
      );
      expect(find.text('Question 1/25 · 4 lives'), findsOneWidget);
      final audio = tester.widget<IconButton>(
        find.byKey(const Key('translation-choice-audio')),
      );
      expect(audio.onPressed, isNull);
    });
  });
}
