import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 256 Session 4: the Generic Primitive Editor edits every canonical
/// field through [CanonicalExerciseDraft]; an untouched draft changes
/// nothing, a changed one keeps only a preset that still represents it
/// (plan A.13).
Course _laboratory() => Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Iterable<LearningContent> _exerciseContent(Course course) sync* {
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final content in round.content) {
        if (content.exercise != null) yield content;
      }
    }
  }
}

Exercise _laboratoryExercise(String presetId) => _exerciseContent(
  _laboratory(),
).firstWhere((content) => content.editorTemplate == presetId).exercise!;

Future<void> _pump(
  WidgetTester tester,
  Exercise exercise, {
  required bool isNew,
  required ValueChanged<Exercise> onSaved,
}) async {
  tester.view.physicalSize = const Size(1400, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: PrimitiveEditorScreen(
        exercise: exercise,
        title: 'Canonical',
        isNew: isNew,
        clock: () => DateTime.utc(2026, 9, 27, 12),
        onExerciseSaved: onSaved,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _acceptWarnings(WidgetTester tester) async {
  if (find.text('Use anyway').evaluate().isNotEmpty) {
    await tester.tap(find.text('Use anyway'));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
  });

  group('CanonicalExerciseDraft', () {
    test('an untouched draft rebuilds every Laboratory exercise unchanged', () {
      for (final content in _exerciseContent(_laboratory())) {
        final exercise = content.exercise!;
        final rebuilt = CanonicalExerciseDraft.fromExercise(exercise)
            .toExercise(
              publicationState: exercise.publicationState,
              updatedAt: exercise.updatedAt,
            );
        expect(
          rebuilt.semanticallyEquals(exercise),
          isTrue,
          reason: content.id,
        );
        expect(
          rebuilt.authoringMetadata,
          exercise.authoringMetadata,
          reason: content.id,
        );
      }
    });

    test('a changed draft keeps only a preset that still represents it', () {
      final choice = _laboratoryExercise('choice').withAuthoringMetadata({
        'presetId': 'choice',
        'note': 'kept only while unchanged',
      });
      final stamp = DateTime.utc(2026, 9, 27);
      // A change no recipe expresses: the preset and the other keys go.
      final withAudio = CanonicalExerciseDraft.fromExercise(choice);
      withAudio.prompt.add(
        const PromptElement(type: 'audio', text: 'Extra spoken text'),
      );
      final changed = withAudio.toExercise(
        publicationState: choice.publicationState,
        updatedAt: stamp,
      );
      expect(changed.editorTemplate, isEmpty);
      expect(changed.authoringMetadata.containsKey('note'), isFalse);
      expect(changed.promptElements.where((e) => e.isAudio), hasLength(1));
      // A change the Choose recipe still expresses keeps its preset, but
      // the other keys still go: the content is no longer what they described.
      final reworded = CanonicalExerciseDraft.fromExercise(choice);
      final question = reworded.prompt.indexWhere((e) => e.isText);
      reworded.prompt[question] = reworded.prompt[question].copyWith(
        text: 'Which word is Italian for thank you?',
      );
      final kept = reworded.toExercise(
        publicationState: choice.publicationState,
        updatedAt: stamp,
      );
      expect(kept.editorTemplate, 'choice');
      expect(kept.authoringMetadata.containsKey('note'), isFalse);
      expect(
        kept.promptElements[question].text,
        'Which word is Italian for thank you?',
      );
      // The Choose form has no hint field, so a hint makes the exercise one
      // that only the canonical editor represents: the preset goes too.
      final rehinted = CanonicalExerciseDraft.fromExercise(choice)
        ..hint = 'A different hint';
      final unrepresented = rehinted.toExercise(
        publicationState: choice.publicationState,
        updatedAt: stamp,
      );
      expect(unrepresented.editorTemplate, isEmpty);
      expect(unrepresented.hint, 'A different hint');
    });

    test('a blank exercise has no content and the default mode', () {
      final blank = CanonicalExerciseDraft.blankExercise(
        ExercisePrimitive.match,
        id: 'ex_blank',
        updatedAt: DateTime.utc(2026, 9, 27),
      );
      expect(blank.primitive, ExercisePrimitive.match);
      expect(blank.promptElements, isEmpty);
      expect(blank.items, isEmpty);
      expect(blank.options.isEmpty, isTrue);
      expect(
        blank.canonicalEvaluation.mode,
        PrimitiveCapabilityRegistry.capabilityOf(
          ExercisePrimitive.match,
        ).defaultEvaluationMode,
      );
      expect(blank.authoringMetadata, isEmpty);
      expect(blank.publicationState, PublicationState.draft);
      final draft = CanonicalExerciseDraft.blank(
        ExercisePrimitive.select,
        id: 'ex_ids',
      );
      expect(draft.nextItemId(), 'ex_ids_item_0');
      draft.items.add(const ExerciseItem(id: 'ex_ids_item_0', content: []));
      expect(draft.nextItemId(), 'ex_ids_item_1');
      expect(draft.nextTargetId(), 'ex_ids_gap_0');
    });
  });

  group('PrimitiveEditorScreen', () {
    testWidgets('saves an unchanged exercise exactly as it is', (tester) async {
      final exercise = _laboratoryExercise('choice');
      Exercise? saved;
      await _pump(tester, exercise, isNew: false, onSaved: (e) => saved = e);
      expect(find.byKey(const Key('primitive-editor')), findsOneWidget);
      expect(find.text('Playable in this version'), findsOneWidget);
      await tester.tap(find.byKey(const Key('primitive-save')));
      await tester.pumpAndSettle();
      await _acceptWarnings(tester);
      expect(saved, isNotNull);
      expect(identical(saved, exercise), isTrue);
    });

    testWidgets(
      'moving the correct answer keeps the preset and stamps the time',
      (tester) async {
        final exercise = _laboratoryExercise('choice');
        final correct = exercise.canonicalEvaluation.correctItemIds.single;
        final other = exercise.items
            .map((item) => item.id)
            .firstWhere((id) => id != correct);
        Exercise? saved;
        await _pump(tester, exercise, isNew: false, onSaved: (e) => saved = e);
        await tester.tap(find.byKey(Key('primitive-correct-$correct')));
        await tester.pump();
        await tester.tap(find.byKey(Key('primitive-correct-$other')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('primitive-save')));
        await tester.pumpAndSettle();
        await _acceptWarnings(tester);
        expect(saved, isNotNull);
        expect(saved!.canonicalEvaluation.correctItemIds, [other]);
        expect(saved!.editorTemplate, 'choice');
        expect(saved!.updatedAt, DateTime.utc(2026, 9, 27, 12));
        expect(saved!.publicationState, PublicationState.published);
      },
    );

    testWidgets('a new Select exercise is built from nothing', (tester) async {
      final blank = CanonicalExerciseDraft.blankExercise(
        ExercisePrimitive.select,
        id: 'ex_new',
        updatedAt: DateTime.utc(2026, 9, 27),
      );
      Exercise? saved;
      await _pump(tester, blank, isNew: true, onSaved: (e) => saved = e);
      await tester.tap(find.byKey(const Key('primitive-prompt-add-text')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('element-text')).first,
        'Which word means cat?',
      );
      await tester.tap(find.byKey(const Key('primitive-item-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('primitive-item-add')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('element-text')).at(1),
        'gatto',
      );
      await tester.enterText(
        find.byKey(const Key('element-text')).at(2),
        'cane',
      );
      await tester.tap(
        find.byKey(const Key('primitive-correct-ex_new_item_0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('primitive-save-draft')));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.primitive, ExercisePrimitive.select);
      expect(saved!.publicationState, PublicationState.draft);
      expect(saved!.promptElements.single.text, 'Which word means cat?');
      expect(saved!.items.map((item) => item.id), [
        'ex_new_item_0',
        'ex_new_item_1',
      ]);
      expect(saved!.items.first.content.single.text, 'gatto');
      expect(saved!.canonicalEvaluation.correctItemIds, ['ex_new_item_0']);
      // Exactly what the Choose form would have made: recognition names it.
      expect(saved!.editorTemplate, 'choice');
    });

    testWidgets('read-only shows the form without Save', (tester) async {
      final exercise = _laboratoryExercise('word_order');
      tester.view.physicalSize = const Size(1400, 3600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PrimitiveEditorScreen(
            exercise: exercise,
            title: 'Canonical',
            isNew: false,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('primitive-read-only-notice')),
        findsOneWidget,
      );
      final save = tester.widget<FilledButton>(
        find.byKey(const Key('primitive-save')),
      );
      expect(save.onPressed, isNull);
      await tester.tap(find.byKey(const Key('primitive-inspection-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('primitive-inspection-presentation')),
        findsOneWidget,
      );
    });
  });
}
