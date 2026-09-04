import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  for (final width in [320.0, 375.0, 430.0, 1100.0]) {
    testWidgets('scoped Audit controls fit at ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: CourseAuditScreen(
            course: _course(),
            title: 'Round Audit',
            result: CourseAuditResult(const [
              CourseAuditIssue(
                severity: AuditSeverity.error,
                code: 'ERROR',
                message: 'Blocking problem',
                location: 'Lesson 1 · Round 1',
                exerciseType: 'choice',
              ),
              CourseAuditIssue(
                severity: AuditSeverity.warning,
                code: 'WARNING',
                message: 'Review this',
                location: 'Lesson 1 · Round 1',
                exerciseType: 'type_translation',
              ),
              CourseAuditIssue(
                severity: AuditSeverity.info,
                code: 'INFO',
                message: 'Helpful guidance',
                location: 'Lesson 1',
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Round Audit'), findsOneWidget);
      expect(find.text('Errors 1'), findsOneWidget);
      expect(find.text('Warnings 1'), findsOneWidget);
      expect(find.text('Info 1'), findsOneWidget);
      expect(find.text('By Lesson'), findsOneWidget);
      expect(find.text('Error 1 of 1'), findsOneWidget);
      expect(find.text('Warning 1 of 1'), findsOneWidget);

      await tester.tap(find.text('By Lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Recently modified'), findsOneWidget);
      await tester.tap(find.text('Recently modified').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Info 1 of 1'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Info 1 of 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('only a Round with Audit Errors receives the pink outline', (
    tester,
  ) async {
    final course = _course();
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(course: course, lesson: course.lessons.single),
      ),
    );
    await tester.pumpAndSettle();

    final bad = tester.widget<Card>(find.byKey(const ValueKey('bad-round')));
    final good = tester.widget<Card>(find.byKey(const ValueKey('good-round')));
    expect(
      (bad.shape! as RoundedRectangleBorder).side.color,
      Colors.pinkAccent,
    );
    expect(
      (good.shape! as RoundedRectangleBorder).side.color,
      isNot(Colors.pinkAccent),
    );
  });
}

Course _course() {
  final lesson = Lesson(
    lessonId: 'lesson',
    title: 'Lesson',
    guidebook: Guidebook.empty(),
    rounds: [
      LearningRound(
        id: 'bad-round',
        title: 'Bad',
        exercises: [_choice('bad', correct: 9)],
      ),
      LearningRound(
        id: 'good-round',
        title: 'Good',
        exercises: [_choice('good', correct: 0)],
      ),
    ],
  );
  return Course(
    courseId: 'course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Course',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
}

Exercise _choice(String id, {required int correct}) => Exercise(
  id: id,
  type: 'choice',
  prompt: 'Choose',
  question: 'Question',
  answers: const ['Correct', 'Wrong'],
  correct: correct,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
