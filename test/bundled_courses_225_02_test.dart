import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all production bundled courses meet the build 225.02 release gate',
    () async {
      final allIds = <String>{};
      final failures = <String>[];
      final auditSummaries = <String>[];
      var aggregateErrors = 0;
      var aggregateWarnings = 0;
      var aggregateInfo = 0;
      var expectedEmptyCourseWarnings = 0;

      for (final entry in CourseService.courseAssets.entries) {
        final raw = await rootBundle.loadString(entry.value);
        final course = Course.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        final result = CourseAuditService().auditCourse(course);
        final errors = result.count(AuditSeverity.error);
        final warnings = result.count(AuditSeverity.warning);
        final info = result.count(AuditSeverity.info);
        aggregateErrors += errors;
        aggregateWarnings += warnings;
        aggregateInfo += info;
        auditSummaries.add(
          'BUNDLED_AUDIT ${entry.value} ${course.courseId}: '
          '$errors errors, $warnings warnings, $info info',
        );
        for (final issue in result.issues.where(
          (issue) => issue.severity != AuditSeverity.info,
        )) {
          if (course.courseId == 'sample_ja_en_ja' &&
              issue.code == 'COURSE_LESSONS_EMPTY' &&
              issue.severity == AuditSeverity.warning) {
            expectedEmptyCourseWarnings++;
            continue;
          }
          failures.add(
            '${entry.value} | ${course.courseId} | ${issue.code} | '
            '${issue.location} | ${issue.message}',
          );
        }
        if (!allIds.add(course.courseId)) {
          failures.add('${entry.value} | DUPLICATE_ID | ${course.courseId}');
        }
        for (final lesson in course.lessons) {
          if (!allIds.add(lesson.lessonId)) {
            failures.add('${entry.value} | DUPLICATE_ID | ${lesson.lessonId}');
          }
          if (!allIds.add(lesson.duel.id)) {
            failures.add('${entry.value} | DUPLICATE_ID | ${lesson.duel.id}');
          }
          for (final content in lesson.guidebook.content) {
            if (!allIds.add(content.id)) {
              failures.add('${entry.value} | DUPLICATE_ID | ${content.id}');
            }
          }
          final duel = const DuelEligibilityService().evaluate(lesson);
          if (!duel.isAvailable) {
            failures.add(
              '${entry.value} | ${course.courseId} | DUEL_UNAVAILABLE | '
              '${lesson.lessonId} | ${duel.eligibleCount}/${duel.requiredCount}',
            );
          }
          for (final round in lesson.rounds) {
            if (!allIds.add(round.id)) {
              failures.add('${entry.value} | DUPLICATE_ID | ${round.id}');
            }
            if (RoundPlayabilityService()
                .playableExerciseIndices(round)
                .isEmpty) {
              failures.add(
                '${entry.value} | ${course.courseId} | ROUND_UNPLAYABLE | '
                '${lesson.lessonId} | ${round.id}',
              );
            }
            for (final exercise in round.exercises) {
              if (!allIds.add(exercise.id)) {
                failures.add('${entry.value} | DUPLICATE_ID | ${exercise.id}');
              }
              for (final item in exercise.interaction.items) {
                if (!allIds.add(item.id)) {
                  failures.add('${entry.value} | DUPLICATE_ID | ${item.id}');
                }
              }
            }
          }
        }
      }

      expect(CourseService.courseAssets, hasLength(11));
      expect(CourseService.courseAssets['KO'], 'assets/courses/korean_en.json');
      expect(
        CourseService.courseAssets['NAP'],
        'assets/courses/neapolitan_it.json',
      );
      expect(
        CourseService.courseAssets['JA'],
        'assets/courses/japanese_en.json',
      );
      final auditReport = <String>[
        ...auditSummaries,
        'BUNDLED_AUDIT aggregate: $aggregateErrors errors, '
            '$aggregateWarnings warnings, $aggregateInfo info',
      ].join('\n');
      expect(aggregateErrors, 0, reason: auditReport);
      expect(aggregateWarnings, 1, reason: auditReport);
      expect(expectedEmptyCourseWarnings, 1, reason: auditReport);
      expect(
        failures,
        isEmpty,
        reason: failures.isEmpty
            ? auditReport
            : '$auditReport\n${failures.join('\n')}',
      );
    },
  );

  test('Korean course loads through the registry with v9 metadata', () async {
    SharedPreferences.setMockInitialValues({});
    final course = await CourseService().loadKoreanCourse();

    expect(course.formatVersion, 9);
    expect(course.sourceLanguage, 'English');
    expect(course.targetLanguage, 'Korean');
    expect(course.ttsLanguage, 'ko-KR');
    expect(course.flagCode, 'KR');
  });

  testWidgets('Korean registry code renders the South Korean flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FlagBadge('KO'))),
    );
    expect(
      find.descendant(
        of: find.byType(FlagBadge),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
