import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  for (final saveDraft in [false, true]) {
    testWidgets(
      'Exercise ${saveDraft ? 'Save as draft retains' : 'Save reconciles'} provisional parents through the actual navigation stack',
      (tester) async {
        final original = _course();
        final beforeJson = jsonEncode(original.toJson());
        final changes = <Course>[];
        await _mount(tester, original, changes);
        final beforePreferences = await workflow.preferences();
        await _openRound(tester);
        await _saveExercise(tester, draft: saveDraft);
        expect(changes, isNotEmpty);
        final updated = changes.last;
        final lesson = updated.lessons.single;
        final round = lesson.rounds.single;
        final expected = saveDraft
            ? PublicationState.draft
            : PublicationState.published;
        expect(round.exercises.single.publicationState, expected);
        expect(round.publicationState, expected);
        expect(lesson.publicationState, expected);
        expect(round.provisionalDraft, saveDraft);
        expect(lesson.provisionalDraft, saveDraft);
        expect(updated.publicationState, PublicationState.draft);
        expect(round.id, 'provisional-round');
        expect(lesson.lessonId, 'provisional-lesson');
        expect(round.exercises.single.id, 'provisional-exercise');
        expect(updated.sectionNames, ['Section A', 'Unused']);
        expect(lesson.sectionName, 'Section A');

        // No parent Save was used. These Back operations exercise the real
        // Round -> Rounds -> Lesson -> Lessons return values and callbacks.
        for (var level = 0; level < 3; level++) {
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(changes.last.lessons.single.publicationState, expected);
          expect(
            changes.last.lessons.single.rounds.single.publicationState,
            expected,
          );
        }
        expect(find.byType(LessonManagementScreen), findsOneWidget);
        expect(changes.last.publicationState, PublicationState.draft);
        expect(await workflow.preferences(), beforePreferences);
        expect(jsonEncode(original.toJson()), beforeJson);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'reconciled Round requires confirmation before an explicit Draft save',
    (tester) async {
      final changes = <Course>[];
      await _mount(tester, _course(), changes);
      final beforePreferences = await workflow.preferences();
      await _openRound(tester);
      await _saveExercise(tester);
      expect(
        changes.last.lessons.single.rounds.single.publicationState,
        PublicationState.published,
      );
      final savedCount = changes.length;

      // The route was originally opened with a Draft Round. The confirmation
      // must use its current reconciled state, not that original route argument.
      await workflow.tapKey(tester, 'round-save-draft');
      expect(find.text('Save Round as draft?'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      expect(changes, hasLength(savedCount));
      expect(
        changes.last.lessons.single.rounds.single.publicationState,
        PublicationState.published,
      );

      await workflow.tapKey(tester, 'round-save-draft');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Save as draft'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LessonRoundsScreen), findsOneWidget);
      expect(
        changes.last.lessons.single.rounds.single.publicationState,
        PublicationState.draft,
      );
      expect(
        changes.last.lessons.single.rounds.single.provisionalDraft,
        isFalse,
      );
      expect(changes.last.publicationState, PublicationState.draft);
      expect(await workflow.preferences(), beforePreferences);
      expect(tester.takeException(), isNull);
    },
  );

  for (final explicitOwner in ['Round', 'Lesson', 'legacy']) {
    testWidgets(
      '$explicitOwner Draft intent survives a complete non-Draft Exercise Save',
      (tester) async {
        final original = _course(provisional: explicitOwner != 'legacy');
        final changes = <Course>[];
        await _mount(tester, original, changes);
        final beforePreferences = await workflow.preferences();
        if (explicitOwner == 'Lesson') {
          await _tapEntry(tester, 'lesson-status-indicator-provisional-lesson');
          await workflow.tapKey(tester, 'save-lesson-draft');
          expect(find.byType(LessonManagementScreen), findsOneWidget);
          expect(changes.last.lessons.single.provisionalDraft, isFalse);
          expect(
            changes.last.lessons.single.publicationState,
            PublicationState.draft,
          );
        }
        await _openRound(tester);
        if (explicitOwner == 'Round') {
          await workflow.tapKey(tester, 'round-save-draft');
          expect(find.byType(LessonRoundsScreen), findsOneWidget);
          expect(
            changes.last.lessons.single.rounds.single.provisionalDraft,
            isFalse,
          );
          expect(
            changes.last.lessons.single.rounds.single.publicationState,
            PublicationState.draft,
          );
          await _tapEntry(tester, 'round-status-indicator-provisional-round');
        }
        await _saveExercise(tester);
        final lesson = changes.last.lessons.single;
        final round = lesson.rounds.single;
        expect(
          round.exercises.single.publicationState,
          PublicationState.published,
        );
        expect(lesson.publicationState, PublicationState.draft);
        expect(lesson.provisionalDraft, explicitOwner == 'Round');
        expect(
          round.publicationState,
          explicitOwner == 'Lesson'
              ? PublicationState.published
              : PublicationState.draft,
        );
        expect(round.provisionalDraft, isFalse);
        expect(changes.last.publicationState, PublicationState.draft);
        for (var level = 0; level < 3; level++) {
          await tester.pageBack();
          await tester.pumpAndSettle();
          if (explicitOwner == 'Lesson' && level == 1) {
            // A later Guidebook save must respect the same explicit Lesson
            // Draft decision as the Exercise save, even with valid content.
            await workflow.tapKey(tester, 'lesson-guidebook-navigation');
            await tester.enterText(
              workflow.field('Overview'),
              'Useful greetings.',
            );
            await workflow.tapKey(tester, 'guidebook-save-appbar');
            expect(
              changes.last.lessons.single.guidebook.overview,
              'Useful greetings.',
            );
            expect(
              changes.last.lessons.single.publicationState,
              PublicationState.draft,
            );
            expect(changes.last.lessons.single.provisionalDraft, isFalse);
          }
        }
        expect(find.byType(LessonManagementScreen), findsOneWidget);
        expect(
          changes.last.lessons.single.publicationState,
          PublicationState.draft,
        );
        expect(
          changes.last.lessons.single.provisionalDraft,
          explicitOwner == 'Round',
        );
        expect(await workflow.preferences(), beforePreferences);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _mount(
  WidgetTester tester,
  Course course,
  List<Course> changes,
) async {
  await workflow.useViewport(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: LessonManagementScreen(
        course: course,
        initiallyLocked: false,
        onCourseChanged: changes.add,
        clock: () => DateTime.utc(2026, 9, 7, 12),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openRound(WidgetTester tester) async {
  await _tapEntry(tester, 'lesson-status-indicator-provisional-lesson');
  await workflow.tapKey(tester, 'lesson-rounds-navigation');
  await _tapEntry(tester, 'round-status-indicator-provisional-round');
  expect(find.byType(RoundEditorScreen), findsOneWidget);
}

Future<void> _tapEntry(WidgetTester tester, String indicatorKey) async {
  final entry = find
      .descendant(
        of: find.byKey(Key(indicatorKey)),
        matching: find.byType(ListTile),
      )
      .first;
  await tester.ensureVisible(entry);
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

Future<void> _saveExercise(WidgetTester tester, {bool draft = false}) async {
  await _tapEntry(tester, 'exercise-status-indicator-provisional-exercise');
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
  await tester.enterText(
    workflow.field('Prompt / instruction'),
    'Choose the greeting.',
  );
  await workflow.tapKey(
    tester,
    draft ? 'exercise-save-draft' : 'exercise-save',
  );
  expect(find.byType(RoundEditorScreen), findsOneWidget);
}

Course _course({bool provisional = true}) => Course(
  courseId: 'provisional-course',
  publicationState: PublicationState.draft,
  title: 'Provisional parent fixture',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  useGuidebook: false,
  createDuels: false,
  sectionNames: ['Section A', 'Unused'],
  lessons: [
    Lesson(
      lessonId: 'provisional-lesson',
      title: 'Greetings',
      section: true,
      sectionName: 'Section A',
      publicationState: PublicationState.draft,
      provisionalDraft: provisional,
      rounds: [
        LearningRound(
          id: 'provisional-round',
          title: '',
          publicationState: PublicationState.draft,
          provisionalDraft: provisional,
          exercises: [workflow.exampleExercise(id: 'provisional-exercise')],
        ),
      ],
    ),
  ],
);
