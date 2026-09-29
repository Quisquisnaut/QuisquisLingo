import 'support/test_directories.dart';
// QQL Build 238 Phase 1: focused tests for Course Editor authoring support
// of the gap-fill extension of the existing Arrange primitive. Since Build
// 256 Revision 4 the gap fill is the preset Drag the blocks into the gaps
// (`gap_blocks`) chosen in the preset picker, not an Inline gaps switch on
// word_order / build_translation. Existing whole-sentence Arrange
// authoring must remain unchanged for Word order.
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

/// Chooses [name] in the preset picker sheet.
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
    await ProfileService().addProfile('Gap fill author');
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

  Exercise legacyWordOrder() => Exercise(
    id: 'legacy-word-order',
    updatedAt: DateTime.utc(2026, 9, 20),
    type: 'word_order',
    prompt: 'Build the sentence.',
    question: '',
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const ['Io', 'bevo', 'un', 'caffè'],
    orderAnswer: const ['Io', 'bevo', 'un', 'caffè'],
    pairs: const [],
    hint: '',
    icons: const [],
  );

  Exercise legacyBuildTranslation() => Exercise(
    id: 'legacy-build-translation',
    updatedAt: DateTime.utc(2026, 9, 20),
    type: 'build_translation',
    prompt: 'I would like a coffee.',
    question: '',
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const ['Io', 'vorrei', 'un', 'caffè'],
    orderAnswer: const [],
    correctTranslations: const ['Io vorrei un caffè.'],
    pairs: const [],
    hint: '',
    icons: const [],
  );

  Exercise gapFillWordOrder() => Exercise.v2(
    id: 'gap-fill-word-order',
    updatedAt: DateTime.utc(2026, 9, 20),
    editorTemplate: 'word_order',
    promptElements: const [
      PromptElement(role: 'clue', type: 'text', text: 'Build the sentence.'),
      PromptElement(type: 'audio', text: 'I go to school.'),
    ],
    interaction: const ExerciseInteraction(
      kind: 'arrange',
      items: [
        ExerciseItem(
          id: 'item_0',
          content: [PromptElement(type: 'text', text: 'go')],
        ),
        ExerciseItem(
          id: 'item_1',
          content: [PromptElement(type: 'text', text: 'goes')],
        ),
        ExerciseItem(
          id: 'item_2',
          content: [PromptElement(type: 'text', text: 'to')],
        ),
      ],
      layout: [
        PromptElement(type: 'text', text: 'I'),
        PromptElement(type: 'gap', text: 'gap_1'),
        PromptElement(type: 'gap', text: 'gap_2'),
        PromptElement(type: 'text', text: 'school.'),
      ],
    ),
    evaluation: const ExerciseEvaluation(
      kind: 'ordered_items',
      gapAssignments: {'gap_1': 'item_0', 'gap_2': 'item_2'},
    ),
  );

  testWidgets(
    'word_order: choosing Drag the blocks into the gaps reveals gap fields and Save builds a valid gap-fill exercise',
    (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: legacyWordOrder(),
            title: 'Gap fill authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(workflow.field('Sentence with gaps'), findsNothing);
      await _pickPreset(tester, 'Drag the blocks into the gaps');
      expect(workflow.field('Sentence with gaps'), findsOneWidget);
      expect(workflow.field('Correct sentence'), findsNothing);
      expect(
        workflow.field('Extra distractor blocks (optional)'),
        findsOneWidget,
      );

      await tester.enterText(
        workflow.field('Sentence with gaps'),
        'I {go} {to} school.',
      );
      await tester.enterText(
        workflow.field('Extra distractor blocks (optional)'),
        'goes\nfrom',
      );
      await tester.enterText(
        workflow.field('Spoken prompt (optional)'),
        'I go to school.',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      final exercise = saved!;
      expect(exercise.hasArrangeGaps, isTrue);
      expect(
        exercise.interaction.layout.map((e) => (e.type, e.text)).toList(),
        [
          ('text', 'I'),
          ('gap', 'gap_1'),
          ('gap', 'gap_2'),
          ('text', 'school.'),
        ],
      );
      expect(exercise.tokens.toSet(), {'go', 'to', 'goes', 'from'});
      final assignedGo = exercise.interaction.items
          .firstWhere((i) => i.id == exercise.targetAssignments['gap_1'])
          .value;
      final assignedTo = exercise.interaction.items
          .firstWhere((i) => i.id == exercise.targetAssignments['gap_2'])
          .value;
      expect(assignedGo, 'go');
      expect(assignedTo, 'to');
      expect(exercise.tts, 'I go to school.');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'word_order: a stray unmatched brace blocks Save with a clear error',
    (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: legacyWordOrder(),
            title: 'Gap fill authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _pickPreset(tester, 'Drag the blocks into the gaps');
      await tester.enterText(
        workflow.field('Sentence with gaps'),
        'I {go to school.',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNull);
      expect(
        find.text(
          'Sentence with gaps: every { must have a matching } directly '
          'around one answer word or phrase, e.g. {go}. Literal { or } '
          "characters can't be used elsewhere in the sentence.",
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('word_order: an empty {} gap blocks Save with a clear error', (
    tester,
  ) async {
    _bigWindow(tester);
    Exercise? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: legacyWordOrder(),
          title: 'Gap fill authoring',
          isNew: true,
          onExerciseSaved: (e) => saved = e,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _pickPreset(tester, 'Drag the blocks into the gaps');
    await tester.enterText(
      workflow.field('Sentence with gaps'),
      'I {go} {} school.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    await workflow.tapKey(tester, 'exercise-save');
    expect(saved, isNull);
    expect(
      find.text(
        'Sentence with gaps: each {…} gap must contain the answer '
        'text, e.g. {go}, not an empty {}.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'word_order: legacy whole-sentence authoring is unchanged when Inline gaps stays off',
    (tester) async {
      _bigWindow(tester);
      final source = legacyWordOrder();
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: source,
            title: 'Gap fill authoring',
            isNew: false,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(workflow.field('Sentence with gaps'), findsNothing);
      expect(workflow.field('Correct sentence'), findsOneWidget);

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      expect(saved!.hasArrangeGaps, isFalse);
      expect(saved!.orderAnswer, source.orderAnswer);
      expect(saved!.tokens, source.tokens);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'word_order: reopening an existing gap-fill exercise restores the preset and fields',
    (tester) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: gapFillWordOrder(),
            title: 'Gap fill authoring',
            isNew: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(workflow.field('Sentence with gaps'), findsOneWidget);
      final layoutField = tester.widget<TextField>(
        workflow.field('Sentence with gaps'),
      );
      expect(layoutField.controller!.text, contains('{go}'));
      expect(layoutField.controller!.text, contains('{to}'));
      expect(layoutField.controller!.text, contains('I'));
      expect(layoutField.controller!.text, contains('school.'));
      final distractorField = tester.widget<TextField>(
        workflow.field('Extra distractor blocks (optional)'),
      );
      expect(distractorField.controller!.text.split('\n'), ['goes']);
      expect(workflow.field('Correct sentence'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'build_translation: choosing Drag the blocks into the gaps hides the translation-variant editor and Save builds a gap-fill exercise',
    (tester) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: legacyBuildTranslation(),
            title: 'Gap fill authoring',
            isNew: true,
            onExerciseSaved: (e) => saved = e,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('build-translation-correct-translations')),
        findsOneWidget,
      );

      await _pickPreset(tester, 'Drag the blocks into the gaps');
      expect(
        find.byKey(const Key('build-translation-correct-translations')),
        findsNothing,
      );
      await tester.enterText(
        workflow.field('Sentence with gaps'),
        'Io {vorrei} un caffè.',
      );
      await tester.enterText(
        workflow.field('Extra distractor blocks (optional)'),
        'prendo',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();

      await workflow.tapKey(tester, 'exercise-save');
      expect(saved, isNotNull);
      final exercise = saved!;
      expect(exercise.hasArrangeGaps, isTrue);
      expect(exercise.targetAssignments.length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'duplicateExercise preserves the gap-fill layout and remaps gapAssignments item IDs',
    () {
      final service = AuthoringDuplicationService(
        ids: TimestampAuthoringIdGenerator(seed: 1),
      );
      final source = gapFillWordOrder();
      final copy = service.duplicateExercise(source);

      expect(copy.id, isNot(source.id));
      expect(copy.hasArrangeGaps, isTrue);
      expect(
        copy.interaction.layout.map((e) => (e.type, e.text)).toList(),
        source.interaction.layout.map((e) => (e.type, e.text)).toList(),
      );
      // Gap IDs are unchanged (they are not owned identities); assigned
      // item IDs are remapped to the copy's own item identities.
      expect(copy.targetAssignments.keys.toSet(), {'gap_1', 'gap_2'});
      for (final gapId in copy.targetAssignments.keys) {
        final copiedItemId = copy.targetAssignments[gapId]!;
        expect(
          copy.interaction.items.any((item) => item.id == copiedItemId),
          isTrue,
          reason: 'copy gapAssignments must reference the copy\'s own items',
        );
      }
      // The underlying answer text is preserved through the remap.
      final sourceGo = source.interaction.items
          .firstWhere((i) => i.id == source.targetAssignments['gap_1'])
          .value;
      final copyGo = copy.interaction.items
          .firstWhere((i) => i.id == copy.targetAssignments['gap_1'])
          .value;
      expect(copyGo, sourceGo);
    },
  );
}
