import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/exercise_search_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 259 Revision 1 (plan `docs/CONTEXT_AND_HINT_PLAN.md` §5, owner
/// decisions of 29 September 2026): Complete the text gets an Instruction
/// or context and a hint; Put the sentences in order takes its lines once,
/// in order, with extra lines and a hint; hints show on the gap and order
/// screens; a gap exercise without audio has no Play audio button.

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
  courseId: 'r1-259-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Revision 1 259',
  ttsLanguage: 'it-IT',
  lessons: lessons,
);

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
  Exercise? original,
  PublicationState state = PublicationState.published,
  String prompt = '',
  String question = '',
  String missingWords = '',
  String order = '',
  String extraWords = '',
  String hint = '',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: original ?? _blankFor(presetId),
    type: presetId,
    publicationState: state,
    prompt: prompt,
    question: question,
    missingWords: missingWords,
    order: order,
    extraWords: extraWords,
    hint: hint,
  ),
);

Exercise _built(
  String presetId, {
  Exercise? original,
  String prompt = '',
  String question = '',
  String missingWords = '',
  String order = '',
  String extraWords = '',
  String hint = '',
}) {
  final result = _build(
    presetId,
    original: original,
    prompt: prompt,
    question: question,
    missingWords: missingWords,
    order: order,
    extraWords: extraWords,
    hint: hint,
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
    title: 'Revision 1 round',
    content: [LearningContent.fromExercise(exercise)],
  );
  final lesson = Lesson(
    lessonId: 'lesson-${exercise.id}',
    title: 'Revision 1 lesson',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPluginMocks();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Revision 1 author');
  });

  group('Complete the text', () {
    Exercise text({String question = '', String hint = ''}) => _built(
      'complete_text',
      question: question,
      // The gaps are ___ since Build 259 Revision 3.
      prompt: 'Anna beve un ___ al bar. Poi prende il ___.',
      missingWords: 'caffè\ntreno',
      hint: hint,
    );

    test('stores its Instruction or context as a clue and keeps its hint', () {
      final exercise = text(
        question: 'Anna’s morning before work.',
        hint: 'A drink, then a way to travel.',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.inputComplete);
      expect(f.clueText, 'Anna’s morning before work.');
      expect(f.authoredInstruction, 'Anna’s morning before work.');
      expect(
        exercise.promptElements.firstWhere((e) => e.role == 'clue').language,
        isNull,
      );
      expect(exercise.hint, 'A drink, then a way to travel.');
      expect(PresetRecipes.represents(exercise, 'complete_text'), isTrue);
      final draft = PresetRecipes.decompose(exercise, 'complete_text');
      expect(draft.question, 'Anna’s morning before work.');
      expect(draft.prompt, 'Anna beve un ___ al bar. Poi prende il ___.');
      expect(draft.hint, 'A drink, then a way to travel.');
      // Without an instruction nothing is added.
      expect(ExerciseFeatures(text()).clueText, isEmpty);
    });

    test('the Audit refuses a hint that gives away a missing word', () {
      bool reveals(Exercise exercise) => CourseAuditService()
          .auditExercise(exercise)
          .any((issue) => issue.code == 'HINT_REVEALS_ANSWER');
      expect(reveals(text(hint: 'Treno!')), isTrue);
      expect(reveals(text(hint: 'A drink, then a way to travel.')), isFalse);
    });

    test('its form and Help know both fields', () {
      expect(ExerciseFieldHelpRegistry.editorFieldKeys('complete_text'), [
        'question',
        'prompt',
        'missingWords',
        'hint',
        'image',
      ]);
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'complete_text',
          'question',
        ).title,
        'Instruction or context (optional)',
      );
      expect(
        ExerciseSearchRegistry.definitions
            .singleWhere((d) => d.presetId == 'complete_text')
            .fields,
        contains(ExerciseSearchField.hint),
      );
    });

    testWidgets('shows the instruction, the hint and no Play audio', (
      tester,
    ) async {
      await _pumpRound(
        tester,
        text(
          question: 'Anna’s morning before work.',
          hint: 'A drink, then a way to travel.',
        ),
      );
      expect(_instructionLine(tester), 'Anna’s morning before work.');
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('gap-fields-hint')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'Hint: A drink, then a way to travel.',
      );
      expect(find.text('Play audio'), findsNothing);
    });

    testWidgets('the form offers the instruction first and the hint last', (
      tester,
    ) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _blankFor(
              'complete_text',
            ).withAuthoringMetadata({'presetId': 'complete_text'}),
            title: 'Complete the text form',
            isNew: true,
            onExerciseSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'Anna’s morning before work.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-prompt')),
        'Anna beve un ___ al bar. Poi prende il ___.',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-missingWords')),
        'caffè\ntreno',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-hint')),
        'A drink, then a way to travel.',
      );
      await tester.pump();
      final save = find.byKey(const Key('exercise-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      final f = ExerciseFeatures(saved!);
      expect(f.authoredInstruction, 'Anna’s morning before work.');
      expect(saved!.hint, 'A drink, then a way to travel.');
      expect(saved!.editorTemplate, 'complete_text');
    });
  });

  group('the gap screen', () {
    testWidgets('Missing letters shows its hint', (tester) async {
      final lab = _load('exercise_laboratory_en_it.json');
      final letters = _exercise(lab, 'qql_lab254_missing_letters');
      await _pumpRound(tester, letters.copyWith(hint: 'Two animals.'));
      expect(find.byKey(const Key('gap-fields-hint')), findsOneWidget);
      expect(find.text('Play audio'), findsNothing);
    });

    testWidgets('an empty hint draws no panel', (tester) async {
      final lab = _load('exercise_laboratory_en_it.json');
      await _pumpRound(tester, _exercise(lab, 'qql_lab254_missing_letters'));
      expect(find.byKey(const Key('gap-fields-hint')), findsNothing);
    });

    testWidgets('a gap exercise with audio keeps Play audio', (tester) async {
      final lab = _load('exercise_laboratory_en_it.json');
      await _pumpRound(tester, _exercise(lab, 'qql_lab254_input_missing_one'));
      expect(find.text('Play audio'), findsOneWidget);
    });
  });

  group('Put the sentences in order', () {
    test('builds the lines once, in order, with extra lines and a hint', () {
      final exercise = _built(
        'sentence_order',
        prompt: 'At the bar: a customer orders a coffee.',
        order: 'Buongiorno.\nUn caffè, per favore.\nEcco a lei.',
        extraWords: 'Il treno parte alle nove.',
        hint: 'The customer speaks first.',
      );
      final f = ExerciseFeatures(exercise);
      expect(exercise.primitive, ExercisePrimitive.arrange);
      expect(f.kind, LearnerExerciseKind.arrangeLines);
      expect(f.authoredInstruction, 'At the bar: a customer orders a coffee.');
      expect(exercise.items.map((item) => item.value), [
        'Buongiorno.',
        'Un caffè, per favore.',
        'Ecco a lei.',
        'Il treno parte alle nove.',
      ]);
      final order = exercise.canonicalEvaluation.correctOrders.single;
      expect(order.text, 'Buongiorno. Un caffè, per favore. Ecco a lei.');
      expect(order.itemIds, [
        for (final item in exercise.items.take(3)) item.id,
      ]);
      expect(exercise.hint, 'The customer speaks first.');
      expect(PresetRecipes.represents(exercise, 'sentence_order'), isTrue);
      final draft = PresetRecipes.decompose(exercise, 'sentence_order');
      expect(draft.order, 'Buongiorno.\nUn caffè, per favore.\nEcco a lei.');
      expect(draft.extraWords, 'Il treno parte alle nove.');
      expect(draft.prompt, 'At the bar: a customer orders a coffee.');
    });

    test('keeps item IDs by text and the stored item order', () {
      // Items stored out of order, as the former "in any order" field let
      // an author enter them.
      final stored = Exercise.canonical(
        id: 'stored-order',
        updatedAt: _stamp,
        primitive: ExercisePrimitive.arrange,
        promptElements: const [
          PromptElement(role: 'clue', type: 'text', text: 'Put it in order.'),
        ],
        items: const [
          ExerciseItem(
            id: 'c',
            content: [PromptElement(type: 'text', text: 'Paga e saluta.')],
          ),
          ExerciseItem(
            id: 'a',
            content: [PromptElement(type: 'text', text: 'Anna entra nel bar.')],
          ),
          ExerciseItem(
            id: 'b',
            content: [PromptElement(type: 'text', text: 'Ordina un caffè.')],
          ),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactOrder,
          correctOrders: [
            OrderedAnswer(
              text: 'Anna entra nel bar. Ordina un caffè. Paga e saluta.',
              itemIds: ['a', 'b', 'c'],
            ),
          ],
        ),
      ).withAuthoringMetadata({'presetId': 'sentence_order'});
      expect(PresetRecipes.represents(stored, 'sentence_order'), isTrue);
      expect(PresetRecipes.presetToEdit(stored), 'sentence_order');
      // The author swaps two lines: the IDs follow the texts.
      final edited = _built(
        'sentence_order',
        original: stored,
        prompt: 'Put it in order.',
        order: 'Anna entra nel bar.\nPaga e saluta.\nOrdina un caffè.',
      );
      expect(edited.items.map((item) => item.id), ['c', 'a', 'b']);
      expect(edited.canonicalEvaluation.correctOrders.single.itemIds, [
        'a',
        'c',
        'b',
      ]);
    });

    test('a Published save needs two lines', () {
      final refused = _build('sentence_order', order: 'Anna entra nel bar.');
      expect(refused.error?.code, ExerciseDraftErrorCode.linesRequired);
      final draft = _build(
        'sentence_order',
        state: PublicationState.draft,
        order: 'Anna entra nel bar.',
      );
      expect(draft.error, isNull);
    });

    test('every bundled example opens in its form', () {
      for (final file in const [
        'exercise_laboratory_en_it.json',
        'piedmontais_en.json',
      ]) {
        final orders = [
          for (final content in _contents(_load(file)))
            if (content.exercise?.editorTemplate == 'sentence_order')
              content.exercise!,
        ];
        expect(orders, isNotEmpty, reason: file);
        for (final exercise in orders) {
          expect(
            PresetRecipes.represents(exercise, 'sentence_order'),
            isTrue,
            reason: exercise.id,
          );
        }
      }
      expect(ExerciseFieldHelpRegistry.editorFieldKeys('sentence_order'), [
        'prompt',
        'order',
        'extraWords',
        'hint',
        'image',
      ]);
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'sentence_order',
          'order',
        ).title,
        'Lines, in the correct order',
      );
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'sentence_order',
          'extraWords',
        ).title,
        'Extra lines (optional)',
      );
    });

    testWidgets('shows its instruction and hint above the lines', (
      tester,
    ) async {
      final lab = _load('exercise_laboratory_en_it.json');
      await _pumpRound(
        tester,
        _exercise(lab, 'qql_lab254_sentence_order_dialogue'),
      );
      expect(
        _instructionLine(tester),
        'At the bar: a customer orders a coffee.',
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('order-hint')),
                matching: find.byType(Text),
              ),
            )
            .data,
        'Hint: The barista offers sugar before serving.',
      );
    });

    testWidgets('an empty hint draws no panel', (tester) async {
      final lab = _load('exercise_laboratory_en_it.json');
      await _pumpRound(
        tester,
        _exercise(lab, 'qql_lab254_sentence_order_story'),
      );
      expect(_instructionLine(tester), 'Anna stops at the bar for a coffee.');
      expect(find.byKey(const Key('order-hint')), findsNothing);
    });

    testWidgets('Name what you see shows its hint too', (tester) async {
      final lab = _load('exercise_laboratory_en_it.json');
      final picture = _exercise(lab, 'qql_lab254_picture_blocks');
      await _pumpRound(tester, picture.copyWith(hint: 'Something to eat.'));
      expect(find.byKey(const Key('order-hint')), findsOneWidget);
    });
  });

  group('the demo content', () {
    test('Piedmontese Lessons 18 and 21 can be worked out', () {
      final course = _load('piedmontais_en.json');
      final completeText = [
        for (final content in _contents(course))
          if (content.exercise?.editorTemplate == 'complete_text')
            content.exercise!,
      ];
      expect(completeText.map((e) => e.hint), [
        'One meows, one barks.',
        'Something to eat and something to drink.',
        'Something you read.',
      ]);
      expect(
        ExerciseFeatures(completeText.last).authoredInstruction,
        'You are at home, on the sofa.',
      );
      final orders = [
        for (final content in _contents(course))
          if (content.exercise?.editorTemplate == 'sentence_order')
            content.exercise!,
      ];
      expect(orders.map((e) => ExerciseFeatures(e).authoredInstruction), [
        'Tòni meets Anna in the street and greets her first.',
        'Anna goes to the market in the morning and is home by noon.',
        'In the evening you have dinner, then you read in bed.',
      ]);
      expect(
        orders.last.hint,
        'The last line is what you say before sleeping.',
      );
    });
  });
}
