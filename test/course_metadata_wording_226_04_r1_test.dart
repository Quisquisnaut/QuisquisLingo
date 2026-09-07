import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/publication_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  testWidgets(
    'authoring navigation and metadata dialog say Course Info Editor',
    (tester) async {
      final course = _course();
      await _openEditor(tester, course);
      expect(find.text('Course Info Editor'), findsOneWidget);
      expect(find.text('Course Info'), findsNothing);
      expect(find.text('Course info'), findsNothing);
      await tester.tap(find.text('Course Info Editor'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Course Info Editor')),
        findsOneWidget,
      );
      await tester.enterText(workflow.field('Course name'), 'Renamed metadata');
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(FilledButton, 'Save'),
        ),
      );
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      final working = await _workingCourse(tester);
      expect(working.title, 'Renamed metadata');
      expect(working.courseId, course.courseId);
      expect(
        working.lessons.map((lesson) => lesson.lessonId),
        course.lessons.map((lesson) => lesson.lessonId),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'learner Course Info keeps its existing name and read-only role',
    (tester) async {
      await workflow.useViewport(tester);
      await tester.pumpWidget(
        MaterialApp(home: CourseInfoScreen(course: _course())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Course Info'), findsOneWidget);
      expect(find.text('Course Info Editor'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('course-draft-status')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Published and Not published toggle only Course delivery state', (
    tester,
  ) async {
    final course = _course();
    final originalChildren = jsonEncode([
      for (final lesson in course.lessons) lesson.toJson(),
    ]);
    await _openEditor(tester, course);
    _expectDelivery(tester, 'Not published', 'Publish');
    final publish = _deliveryButton(tester, 'Publish');
    expect(
      publish.style?.backgroundColor?.resolve(const <WidgetState>{}),
      const Color(0xFF0756DF),
    );
    expect(
      publish.style?.foregroundColor?.resolve(const <WidgetState>{}),
      Colors.white,
    );
    final publishIcon = find.descendant(
      of: find.byKey(const Key('course-draft-status')),
      matching: find.byIcon(Icons.publish_outlined),
    );
    expect(IconTheme.of(tester.element(publishIcon)).color, Colors.white);
    await _tapDeliveryAction(tester, 'Publish');
    _expectDelivery(tester, 'Published', 'Unpublish');
    expect(_deliveryButton(tester, 'Unpublish').style, isNull);

    final published = await _workingCourse(tester);
    expect(published.publicationState, PublicationState.published);
    expect(
      jsonEncode([for (final lesson in published.lessons) lesson.toJson()]),
      originalChildren,
    );
    final visible = const PublicationService().learnerCourse(published)!;
    expect(visible.lessons.map((lesson) => lesson.lessonId), [
      'published-lesson',
    ]);
    expect(visible.lessons.single.rounds.single.exercises.map((ex) => ex.id), [
      'published-exercise',
    ]);

    await _tapDeliveryAction(tester, 'Unpublish');
    expect(find.text('Set Course to Not published?'), findsOneWidget);
    expect(find.text('Save Course as draft?'), findsNothing);
    expect(find.text('Save as draft'), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    _expectDelivery(tester, 'Published', 'Unpublish');
    await _tapDeliveryAction(tester, 'Unpublish');
    await tester.tap(find.widgetWithText(TextButton, 'Not published'));
    await tester.pumpAndSettle();
    _expectDelivery(tester, 'Not published', 'Publish');
    final unpublished = await _workingCourse(tester);
    expect(unpublished.publicationState, PublicationState.draft);
    expect(
      jsonEncode([for (final lesson in unpublished.lessons) lesson.toJson()]),
      originalChildren,
    );
    expect(const PublicationService().learnerCourse(unpublished), isNull);
    expect(course.publicationState, PublicationState.draft);
    expect(tester.takeException(), isNull);
  });
}

TextButton _deliveryButton(WidgetTester tester, String label) =>
    tester.widget<TextButton>(
      find.descendant(
        of: find.byKey(const Key('course-draft-status')),
        matching: find.widgetWithText(TextButton, label),
      ),
    );

Future<void> _openEditor(WidgetTester tester, Course course) async {
  await workflow.useViewport(tester);
  await SettingsService().setCourseEditorLocked(course.courseId, false);
  await SettingsService().markAudioOrphanCheckRun(
    CourseService.codeForCourse(course),
  );
  await tester.pumpWidget(
    MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
  );
  await tester.pumpAndSettle();
}

void _expectDelivery(WidgetTester tester, String label, String action) {
  final row = find.byKey(const Key('course-draft-status'));
  expect(find.descendant(of: row, matching: find.text(label)), findsOneWidget);
  expect(find.descendant(of: row, matching: find.text(action)), findsOneWidget);
  expect(
    find.descendant(of: row, matching: find.textContaining('Draft')),
    findsNothing,
  );
  expect(
    find.descendant(of: row, matching: find.textContaining('draft')),
    findsNothing,
  );
}

Future<void> _tapDeliveryAction(WidgetTester tester, String label) async {
  final action = find.descendant(
    of: find.byKey(const Key('course-draft-status')),
    matching: find.widgetWithText(TextButton, label),
  );
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<Course> _workingCourse(WidgetTester tester) async {
  final link = find.byKey(const Key('course-editor-lessons-navigation'));
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
  final course = tester
      .widget<LessonManagementScreen>(find.byType(LessonManagementScreen))
      .course;
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
  return course;
}

Course _course() => Course(
  courseId: 'metadata-wording',
  title: 'Metadata wording',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  version: '1',
  license: 'CC0-1.0',
  publicationState: PublicationState.draft,
  useGuidebook: false,
  createDuels: false,
  lessons: [
    Lesson(
      lessonId: 'published-lesson',
      title: 'Greetings',
      rounds: [
        LearningRound(
          id: 'published-round',
          title: '',
          exercises: [
            workflow.exampleExercise(
              id: 'published-exercise',
              state: PublicationState.published,
            ),
            workflow.exampleExercise(id: 'draft-exercise'),
          ],
        ),
      ],
    ),
    Lesson(
      lessonId: 'draft-lesson',
      title: 'Unfinished Lesson',
      publicationState: PublicationState.draft,
      rounds: const [],
    ),
  ],
);
