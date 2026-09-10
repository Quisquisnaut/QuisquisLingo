import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Exercise saves through a Course Audit finding update the open Course before Previous/Next leaves the editor',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final course = _course();
      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
      );
      await tester.pumpAndSettle();
      _expectCourseConcern(tester, true);

      await tester.tap(find.widgetWithText(TextButton, 'Run audit'));
      await tester.pumpAndSettle();
      final issue = find.text('Code: CHOICE_CORRECT_ANSWER_INVALID');
      await tester.ensureVisible(issue);
      await tester.tap(issue);
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      expect(_text(tester, 'Prompt / instruction'), 'Choose greeting 1.');

      await tester.enterText(_field('Correct answer number'), '1');
      await _navigateAndSave(tester, 'exercise-next', draft: false);
      expect(_text(tester, 'Prompt / instruction'), 'Choose greeting 2.');
      _expectCourseConcern(tester, false);

      await tester.enterText(_field('Correct answer number'), '99');
      await _navigateAndSave(tester, 'exercise-previous', draft: true);
      expect(_text(tester, 'Prompt / instruction'), 'Choose greeting 1.');
      _expectCourseConcern(tester, true);

      await tester.tap(find.byKey(const Key('exercise-next')));
      await tester.pumpAndSettle();
      expect(_text(tester, 'Correct answer number'), isEmpty);
      await tester.enterText(_field('Correct answer number'), '1');
      await _navigateAndSave(tester, 'exercise-previous', draft: false);
      _expectCourseConcern(tester, false);
      expect(_text(tester, 'Prompt / instruction'), 'Choose greeting 1.');
      expect(_text(tester, 'Correct answer number'), '1');

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditorScreen), findsNothing);
      _expectCourseConcern(tester, false);
      await tester.tap(find.widgetWithText(TextButton, 'Run audit'));
      await tester.pumpAndSettle();
      final audit = tester
          .widget<CourseAuditScreen>(find.byType(CourseAuditScreen))
          .result;
      expect(
        audit.issues.where(
          (issue) =>
              issue.severity == AuditSeverity.error ||
              issue.severity == AuditSeverity.warning,
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _navigateAndSave(
  WidgetTester tester,
  String key, {
  required bool draft,
}) async {
  final button = find.byKey(Key(key));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.text('Unsaved Exercise changes'), findsOneWidget);
  await tester.tap(
    find.widgetWithText(TextButton, draft ? 'Save as draft' : 'Save'),
  );
  await tester.pumpAndSettle();
  if (draft) {
    expect(find.text('Save Exercise as draft?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Save as draft'));
    await tester.pumpAndSettle();
  }
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
  expect(find.byType(AlertDialog), findsNothing);
  expect(tester.takeException(), isNull);
}

void _expectCourseConcern(WidgetTester tester, bool expected) {
  final indicator = find.byWidgetPredicate(
    (widget) =>
        widget is AuthoringStatusCard &&
        widget.indicatorKey == const Key('course-lessons-status-indicator'),
    skipOffstage: false,
  );
  expect(indicator, findsOneWidget);
  final status = tester.widget<AuthoringStatusCard>(indicator);
  expect(status.hasAuditConcern, expected);
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

String _text(WidgetTester tester, String label) =>
    tester.widget<TextField>(_field(label)).controller!.text;

Course _course() => Course(
  courseId: 'audit-save-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Audit save propagation',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      guidebook: Guidebook(
        content: [
          LearningContent.textual(
            id: 'guide',
            kind: 'explanation',
            role: 'overview',
            text: 'Reviewed overview.',
          ),
        ],
      ),
      rounds: [
        LearningRound(
          id: 'round',
          title: 'Round',
          exercises: [
            for (var index = 1; index <= 3; index++)
              Exercise(
                id: 'exercise-$index',
                publicationState: index == 1
                    ? PublicationState.draft
                    : PublicationState.published,
                type: 'choice',
                prompt: 'Choose greeting $index.',
                question: 'Which greeting fits situation $index?',
                answers: const ['hello', 'goodbye'],
                correct: index == 1 ? 98 : 0,
                tts: null,
                accepted: const [],
                tokens: const [],
                orderAnswer: const [],
                pairs: const [],
                hint: '',
                icons: const [],
              ),
          ],
        ),
      ],
    ),
  ],
);
