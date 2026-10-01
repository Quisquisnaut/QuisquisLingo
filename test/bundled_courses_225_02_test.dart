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
    'all production bundled courses meet their documented release gate',
    () async {
      final allIds = <String>{};
      final failures = <String>[];
      final auditSummaries = <String>[];
      var aggregateErrors = 0;
      var aggregateWarnings = 0;
      var aggregateInfo = 0;
      var expectedEmptyCourseWarnings = 0;
      const expectedDemoWarnings = {
        'IT|qql_lab254_card_minimal|FLASHCARD_EXAMPLE_EMPTY',
        'IT|qql_lab254_card_minimal|FLASHCARD_AUDIO_EMPTY',
        'IT|qql_lab254_card_usage|FLASHCARD_AUDIO_EMPTY',
        'IT|qql_lab254_card_usage_translation|FLASHCARD_AUDIO_EMPTY',
        'IT|qql_lab254_card_audio|FLASHCARD_EXAMPLE_EMPTY',
        // The Edge Case's three intentional warnings are checked by
        // edge_case_course_254_test since it left the bundle (Build 259
        // Revision 5).
        'PMS|pms_e5f5585a_l08_r01_e01|OPPOSITE_TOO_EARLY',
      };
      final observedDemoWarnings = <String>[];

      for (final entry in CourseService.courseAssets.entries) {
        final raw = await rootBundle.loadString(entry.value);
        final course = Course.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        final result = CourseAuditService().auditCourse(course);
        final isModelDemo = const {
          'IT',
          'PMS',
          'PMS_MIX',
          'EN_IT',
        }.contains(entry.key);
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
          // Permit only the exact authored boundary case, never a whole code.
          final warningKey = '${entry.key}|${issue.exerciseId}|${issue.code}';
          if (issue.severity == AuditSeverity.warning &&
              expectedDemoWarnings.contains(warningKey)) {
            observedDemoWarnings.add(warningKey);
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
          if (!isModelDemo && !duel.isAvailable) {
            failures.add(
              '${entry.value} | ${course.courseId} | DUEL_UNAVAILABLE | '
              '${lesson.lessonId} | ${duel.eligibleCount}/${duel.requiredCount}',
            );
          }
          for (final round in lesson.rounds) {
            if (!allIds.add(round.id)) {
              failures.add('${entry.value} | DUPLICATE_ID | ${round.id}');
            }
            if (round.publicationState == PublicationState.published &&
                RoundPlayabilityService()
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
              // Usage items of a card built on the flashcard recipe exist
              // only in the runnable projection; canonical Presentation JSON
              // has no Item identities.
              if (exercise.type == 'flashcard') continue;
              for (final item in exercise.interaction.items) {
                if (!allIds.add(item.id)) {
                  failures.add('${entry.value} | DUPLICATE_ID | ${item.id}');
                }
              }
            }
          }
        }
      }

      // QQL Demo: English from Italian joined in Build 260 Revision 2.
      expect(CourseService.courseAssets, hasLength(4));
      final auditReport = <String>[
        ...auditSummaries,
        'BUNDLED_AUDIT aggregate: $aggregateErrors errors, '
            '$aggregateWarnings warnings, $aggregateInfo info',
      ].join('\n');
      expect(aggregateErrors, 0, reason: auditReport);
      expect(
        observedDemoWarnings,
        unorderedEquals(expectedDemoWarnings),
        reason: auditReport,
      );
      expect(expectedEmptyCourseWarnings, 0, reason: auditReport);
      expect(
        failures,
        isEmpty,
        reason: failures.isEmpty
            ? auditReport
            : '$auditReport\n${failures.join('\n')}',
      );
    },
  );

  test('the Piedmontese demo loads through the registry', () async {
    SharedPreferences.setMockInitialValues({});
    final course = await CourseService().loadCourse('PMS');

    expect(course.formatVersion, Course.currentFormatVersion);
    expect(course.title, 'Demo: Piedmontese (sorted by exercise type)');
    expect(course.sourceLanguage, 'English');
    expect(course.targetLanguage, 'Piedmontese');
    expect(course.ttsLanguage, 'pms-IT');
    expect(course.worldFlagId, 'piedmontese');
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
