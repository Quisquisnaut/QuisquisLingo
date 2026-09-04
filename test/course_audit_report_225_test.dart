import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_report_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  test('complete report includes metadata, totals and every issue context', () {
    final service = CourseAuditReportService(
      clock: () => DateTime(2026, 9, 3, 20, 15, 30),
    );
    final report = service.buildReport(
      course: _course(),
      result: _result(),
      scope: 'Course Audit',
      sortMode: AuditSortMode.lesson,
    );

    expect(report, contains('Version: 2.0.25'));
    expect(report, contains('Build: 225.03'));
    expect(report, contains('Technical version: 2.0.25+22503'));
    expect(report, contains('Generated: 2026-09-03T20:15:30.000'));
    expect(report, contains('Course name: Italian test'));
    expect(report, contains('Course ID: stable_course_id'));
    expect(report, contains('Audit scope: Course Audit'));
    expect(report, contains('Sort mode: By Lesson'));
    expect(report, contains('Errors: 1'));
    expect(report, contains('Warnings: 1'));
    expect(report, contains('Info: 0'));
    expect(report, contains('Code: BLOCKING_TEST'));
    expect(report, contains('Error 1 of 1'));
    expect(report, contains('Warning 1 of 1'));
    expect(report, contains('Message: Blocking finding'));
    expect(report, contains('Lesson: Greetings (lesson_1)'));
    expect(report, contains('Round: First round (round_1)'));
    expect(report, contains('Exercise: 1 (exercise_1)'));
    expect(report, contains('Exercise type: choice (choice)'));
    expect(report, contains('Code: REVIEW_TEST'));
    expect(report, contains('Message: Review finding'));
  });

  test('copy receives the complete deterministic report', () async {
    String? copied;
    final service = CourseAuditReportService(
      copyText: (text) async => copied = text,
      clock: () => DateTime(2026, 9, 3, 20, 15, 30),
    );

    await service.copyReport(
      course: _course(),
      result: _result(),
      scope: 'Lesson Audit',
      sortMode: AuditSortMode.exerciseType,
    );

    expect(copied, contains('Audit scope: Lesson Audit'));
    expect(copied, contains('Sort mode: By Exercise type'));
    expect(copied, contains('Blocking finding'));
    expect(copied, contains('Review finding'));
  });

  test('export writes the same complete report to the QQL export seam', () async {
    final directory = await Directory.systemTemp.createTemp('qql_audit_225_');
    addTearDown(() => directory.delete(recursive: true));
    final service = CourseAuditReportService(
      exportDirectory: () async => directory,
      clock: () => DateTime(2026, 9, 3, 20, 15, 30, 123),
    );

    final path = await service.exportReport(
      course: _course(),
      result: _result(),
      scope: 'Course Audit',
      sortMode: AuditSortMode.lesson,
    );

    expect(
      path,
      endsWith(
        'quisquislingo_audit_italian_test_stable_course_id_20260903201530123.txt',
      ),
    );
    final contents = await File(path).readAsString();
    expect(contents, contains('Blocking finding'));
    expect(contents, contains('Review finding'));
  });

  test('export propagates storage failure without returning a path', () async {
    final service = CourseAuditReportService(
      exportDirectory: () async => throw StateError('storage unavailable'),
      clock: () => DateTime(2026, 9, 3, 20, 15, 30),
    );

    await expectLater(
      service.exportReport(
        course: _course(),
        result: _result(),
        scope: 'Course Audit',
        sortMode: AuditSortMode.lesson,
      ),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets(
    'filtered screen still copies all findings and confirms success',
    (tester) async {
      String? copied;
      final service = CourseAuditReportService(
        copyText: (text) async => copied = text,
        clock: () => DateTime(2026, 9, 3, 20, 15, 30),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseAuditScreen(
            course: _course(),
            result: _result(),
            reportService: service,
          ),
        ),
      );

      await tester.tap(find.text('Errors 1'));
      await tester.pump();
      expect(find.text('Review finding'), findsNothing);
      await tester.tap(find.byKey(const Key('copy-audit-report')));
      await tester.pumpAndSettle();

      expect(copied, contains('Blocking finding'));
      expect(copied, contains('Review finding'));
      expect(find.text('Complete Audit report copied.'), findsOneWidget);
    },
  );

  testWidgets('export success is confirmed with the created path', (
    tester,
  ) async {
    final service = _WidgetReportService(
      exportedPath: r'C:\Documents\QuisquisLingo\Exports\audit.txt',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CourseAuditScreen(
          course: _course(),
          result: _result(),
          reportService: service,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('export-audit-report')));
    for (var frame = 0; frame < 100; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find
          .textContaining('Complete Audit report exported to')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.textContaining('Complete Audit report exported to'),
      findsOneWidget,
    );
    expect(service.exportCalls, 1);
  });

  testWidgets('export failure shows an error and never claims creation', (
    tester,
  ) async {
    final service = _WidgetReportService(
      exportError: StateError('storage unavailable'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CourseAuditScreen(
          course: _course(),
          result: _result(),
          reportService: service,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('export-audit-report')));
    for (var frame = 0; frame < 100; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find
          .textContaining('Could not export Audit report:')
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(
      find.textContaining('Could not export Audit report:'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Complete Audit report exported to'),
      findsNothing,
    );
  });
}

class _WidgetReportService extends CourseAuditReportService {
  _WidgetReportService({this.exportedPath, this.exportError});

  final String? exportedPath;
  final Object? exportError;
  int exportCalls = 0;

  @override
  Future<String> exportReport({
    required Course course,
    required CourseAuditResult result,
    required String scope,
    required AuditSortMode sortMode,
  }) async {
    exportCalls += 1;
    if (exportError != null) throw exportError!;
    return exportedPath!;
  }
}

CourseAuditResult _result() => CourseAuditResult(const [
  CourseAuditIssue(
    severity: AuditSeverity.warning,
    code: 'REVIEW_TEST',
    message: 'Review finding',
    location: 'Course',
  ),
  CourseAuditIssue(
    severity: AuditSeverity.error,
    code: 'BLOCKING_TEST',
    message: 'Blocking finding',
    location: 'Lesson 1 · Greetings · Round 1 · First round · Exercise 1',
    roundId: 'round_1',
    exerciseId: 'exercise_1',
    exerciseType: 'choice',
  ),
]);

Course _course() {
  final exercise = Exercise(
    id: 'exercise_1',
    type: 'choice',
    prompt: '',
    question: 'Choose.',
    answers: const ['Yes', 'No'],
    correct: 0,
    tts: null,
    accepted: const [],
    tokens: const [],
    orderAnswer: const [],
    pairs: const [],
    hint: '',
    icons: const [],
  );
  final round = LearningRound(
    id: 'round_1',
    title: 'First round',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: 'lesson_1',
    title: 'Greetings',
    rounds: [round],
  );
  return Course(
    courseId: 'stable_course_id',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Italian test',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
}
