import 'support/test_directories.dart';
// QQL Build 238 Phase 2: focused tests for Course Editor authoring support
// of the Select primitive extensions (`choice`: multiple correct answers,
// required-selection count, and linked-gap options). Existing single-select
// `choice` authoring must remain unchanged when both toggles stay off.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;

/// Enlarges the test viewport so the whole Course Editor exercise form
/// renders without needing to scroll, since Flutter's default finders skip
/// widgets scrolled outside the current viewport (ListView lazy visibility).
void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 12000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Select author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationSupportDirectory') {
              return testSupportDirectory.path;
            }
            throw PlatformException(code: 'test_storage_unavailable');
          },
        );
  });

  Exercise legacyChoice() => Exercise(
    id: 'legacy-choice',
    updatedAt: DateTime.utc(2026, 9, 20),
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

  Exercise multiSelectChoice() => Exercise.v2(
    id: 'multi-select-choice',
    updatedAt: DateTime.utc(2026, 9, 20),
    editorTemplate: 'choice',
    promptElements: const [
      PromptElement(role: 'primary', type: 'text', text: 'Choose fruits.'),
    ],
    interaction: const ExerciseInteraction(
      kind: 'select',
      minSelections: 2,
      maxSelections: 3,
      items: [
        ExerciseItem(
          id: 'item_0',
          content: [PromptElement(type: 'text', text: 'Apple')],
        ),
        ExerciseItem(
          id: 'item_1',
          content: [PromptElement(type: 'text', text: 'Carrot')],
        ),
        ExerciseItem(
          id: 'item_2',
          content: [PromptElement(type: 'text', text: 'Banana')],
        ),
      ],
    ),
    evaluation: const ExerciseEvaluation(
      kind: 'selected_items',
      correctItemIds: ['item_0', 'item_2'],
    ),
  );

  Exercise linkedGapChoice() => Exercise.v2(
    id: 'linked-gap-choice',
    updatedAt: DateTime.utc(2026, 9, 20),
    editorTemplate: 'choice',
    promptElements: const [],
    interaction: const ExerciseInteraction(
      kind: 'select',
      items: [
        ExerciseItem(
          id: 'item_was',
          content: [PromptElement(type: 'text', text: 'Was')],
        ),
        ExerciseItem(
          id: 'item_perhaps',
          content: [PromptElement(type: 'text', text: 'Perhaps')],
        ),
      ],
      layout: [
        PromptElement(type: 'gap', text: 'gap_1'),
        PromptElement(type: 'text', text: 'she happy?'),
        PromptElement(type: 'gap', text: 'gap_2'),
        PromptElement(type: 'text', text: 'he late?'),
      ],
    ),
    evaluation: const ExerciseEvaluation(
      kind: 'selected_items',
      gapAssignments: {'gap_1': 'item_was', 'gap_2': 'item_was'},
    ),
  );

  testWidgets(
    'choice: enabling Multiple correct answers reveals set-based fields and Save builds a valid exercise',
    (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: legacyChoice(),
            title: 'Select authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(workflow.field('Correct answer numbers'), findsNothing);
      await workflow.tapKey(tester, 'choice-use-multi-select');
      expect(workflow.field('Correct answer number'), findsNothing);
      expect(workflow.field('Correct answer numbers'), findsOneWidget);
      expect(workflow.field('Required selections (optional)'), findsOneWidget);

      await tester.enterText(
        workflow.field('Answers'),
        'Apple\nCarrot\nBanana',
      );
      await tester.enterText(workflow.field('Correct answer numbers'), '1, 3');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      final exercise = saved!;
      expect(exercise.isMultiSelect, isTrue);
      expect(exercise.requiredSelectionCount, 2);
      final correctTexts = exercise.interaction.items
          .where((i) => exercise.correctItemIdSet.contains(i.id))
          .map((i) => i.value)
          .toSet();
      expect(correctTexts, {'Apple', 'Banana'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'choice: an out-of-range correct answer number blocks Save with a clear error',
    (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: legacyChoice(),
            title: 'Select authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await workflow.tapKey(tester, 'choice-use-multi-select');
      await tester.enterText(workflow.field('Correct answer numbers'), '1, 9');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'choice: legacy single-select authoring is unchanged when both toggles stay off',
    (tester) async {
      _bigWindow(tester);
      final source = legacyChoice();
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: source,
            title: 'Select authoring',
            isNew: false,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(workflow.field('Correct answer number'), findsOneWidget);
      expect(workflow.field('Sentence with gaps'), findsNothing);

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      expect(saved!.isMultiSelect, isFalse);
      expect(saved!.hasSelectGaps, isFalse);
      expect(saved!.correct, source.correct);
      expect(saved!.answers, source.answers);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'choice: reopening an existing multi-select exercise restores the toggle and fields',
    (tester) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: multiSelectChoice(),
            title: 'Select authoring',
            isNew: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('choice-use-multi-select')),
      );
      expect(switchTile.value, isTrue);
      final correctField = tester.widget<TextField>(
        workflow.field('Correct answer numbers'),
      );
      expect(correctField.controller!.text, '1, 3');
      final requiredField = tester.widget<TextField>(
        workflow.field('Required selections (optional)'),
      );
      expect(requiredField.controller!.text, '2');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'choice: enabling Inline gaps reveals gap fields and Save builds a linked-gap exercise',
    (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: legacyChoice(),
            title: 'Select authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(workflow.field('Sentence with gaps'), findsNothing);
      await workflow.tapKey(tester, 'choice-use-inline-gaps');
      expect(workflow.field('Sentence with gaps'), findsOneWidget);
      expect(workflow.field('Answers'), findsNothing);
      expect(workflow.field('Correct answer number'), findsNothing);

      await tester.enterText(
        workflow.field('Sentence with gaps'),
        '{Was} she happy? {Was} he late?',
      );
      await tester.enterText(
        workflow.field('Distractor options (optional)'),
        'Perhaps',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      final exercise = saved!;
      expect(exercise.hasSelectGaps, isTrue);
      expect(exercise.arrangeGapAssignments.length, 2);
      expect(exercise.arrangeGapAssignments.values.toSet(), hasLength(1));
      expect(exercise.interaction.items.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'choice: a stray unmatched brace in Sentence with gaps blocks Save',
    (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: legacyChoice(),
            title: 'Select authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await workflow.tapKey(tester, 'choice-use-inline-gaps');
      await tester.enterText(
        workflow.field('Sentence with gaps'),
        '{Was she happy?',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'choice: reopening an existing linked-gap exercise restores the toggle and fields',
    (tester) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: linkedGapChoice(),
            title: 'Select authoring',
            isNew: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(workflow.field('Sentence with gaps'), findsOneWidget);
      final layoutField = tester.widget<TextField>(
        workflow.field('Sentence with gaps'),
      );
      expect(layoutField.controller!.text, contains('{Was}'));
      expect(layoutField.controller!.text, contains('she happy?'));
      expect(layoutField.controller!.text, contains('he late?'));
      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('choice-use-inline-gaps')),
      );
      expect(switchTile.value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'duplicateExercise preserves multi-select fields and remaps correctItemIds',
    () {
      final service = AuthoringDuplicationService(
        ids: TimestampAuthoringIdGenerator(seed: 1),
      );
      final source = multiSelectChoice();
      final copy = service.duplicateExercise(source);

      expect(copy.id, isNot(source.id));
      expect(copy.isMultiSelect, isTrue);
      expect(copy.requiredSelectionCount, source.requiredSelectionCount);
      expect(copy.maxSelectionCount, source.maxSelectionCount);
      final copyCorrectTexts = copy.interaction.items
          .where((i) => copy.correctItemIdSet.contains(i.id))
          .map((i) => i.value)
          .toSet();
      expect(copyCorrectTexts, {'Apple', 'Banana'});
    },
  );

  test(
    'duplicateExercise preserves the linked-gap layout and remaps gapAssignments item IDs',
    () {
      final service = AuthoringDuplicationService(
        ids: TimestampAuthoringIdGenerator(seed: 1),
      );
      final source = linkedGapChoice();
      final copy = service.duplicateExercise(source);

      expect(copy.hasSelectGaps, isTrue);
      expect(copy.arrangeGapAssignments.keys.toSet(), {'gap_1', 'gap_2'});
      expect(copy.arrangeGapAssignments.values.toSet(), hasLength(1));
      for (final gapId in copy.arrangeGapAssignments.keys) {
        final copiedItemId = copy.arrangeGapAssignments[gapId]!;
        expect(
          copy.interaction.items.any((item) => item.id == copiedItemId),
          isTrue,
        );
      }
    },
  );
}
