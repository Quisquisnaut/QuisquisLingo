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
import 'package:quisquislingo_app/services/preset_recipes.dart';
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

/// Chooses [name] in the preset picker of a new exercise (Build 256
/// Revision 4: inline gaps are presets of their own, not switches).
Future<void> _pickPreset(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('exercise-preset-selector')));
  await tester.pumpAndSettle();
  final tile = find.text(name).last;
  await tester.dragUntilVisible(
    tile,
    find
        .descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(ListView),
        )
        .first,
    const Offset(0, -400),
  );
  await tester.tap(tile);
  await tester.pumpAndSettle();
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
    keepCrashLogUnavailable();
  });

  Exercise legacyChoice() => Exercise(
    id: 'legacy-choice',
    updatedAt: DateTime.utc(2026, 9, 20),
    type: 'choice',
    prompt: '',
    // A question is never optional (Build 259).
    question: 'Good morning',
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
    // Build 259 Revision 4 (owner decision): Pick the words for the gaps is
    // the former Drag the blocks into the gaps, each word filling one gap.
    'choice: Pick the words for the gaps shows gap fields and Save builds one word per gap',
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
      await _pickPreset(tester, 'Pick the words for the gaps');
      expect(workflow.field('Sentence with gaps'), findsOneWidget);
      expect(workflow.field('Answers'), findsNothing);
      expect(workflow.field('Correct answer number'), findsNothing);

      await tester.enterText(
        workflow.field('Sentence with gaps'),
        '_Was_ she happy? _Was_ he late?',
      );
      await tester.enterText(
        workflow.field('Extra distractor words (optional)'),
        'Perhaps',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      final exercise = saved!;
      expect(exercise.primitive, ExercisePrimitive.arrange);
      expect(exercise.targetAssignments.length, 2);
      expect(exercise.targetAssignments.values.toSet(), hasLength(2));
      expect(exercise.interaction.items.length, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('choice: a lone underscore in Sentence with gaps blocks Save', (
    tester,
  ) async {
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
    await _pickPreset(tester, 'Pick the words for the gaps');
    await tester.enterText(
      workflow.field('Sentence with gaps'),
      '_Was she happy?',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    await workflow.tapKey(tester, 'exercise-save');
    expect(saved, isNull);
    expect(tester.takeException(), isNull);
  });

  // Build 259 Revision 4: no preset authors a Select whose option fills two
  // gaps any more (Pick the words for the gaps uses each word once), so the
  // Course Editor opens such a stored exercise in the canonical editor.
  test('an existing linked-gap Select is represented by no preset', () {
    final exercise = linkedGapChoice();
    expect(PresetRecipes.recognize(exercise), isNull);
    expect(PresetRecipes.represents(exercise, 'gap_blocks'), isFalse);
  });

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
      expect(copy.targetAssignments.keys.toSet(), {'gap_1', 'gap_2'});
      expect(copy.targetAssignments.values.toSet(), hasLength(1));
      for (final gapId in copy.targetAssignments.keys) {
        final copiedItemId = copy.targetAssignments[gapId]!;
        expect(
          copy.interaction.items.any((item) => item.id == copiedItemId),
          isTrue,
        );
      }
    },
  );
}
