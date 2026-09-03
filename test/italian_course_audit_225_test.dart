import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production bundled Italian course has no Audit Errors', () async {
    final raw = await rootBundle.loadString('assets/courses/italian_en.json');
    final course = Course.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );
    final result = CourseAuditService().auditCourse(course);
    final errors = result.issues
        .where((issue) => issue.severity == AuditSeverity.error)
        .toList(growable: false);

    if (errors.isNotEmpty) {
      // Keep a failing release gate actionable without duplicating the asset.
      // ignore: avoid_print
      print(
        'TOTALS: ${result.count(AuditSeverity.error)} errors, '
        '${result.count(AuditSeverity.warning)} warnings, '
        '${result.count(AuditSeverity.info)} info\n'
        '${result.issues.map((issue) => '${issue.severity.name.toUpperCase()} | ${issue.code} | '
            '${issue.location} | ${issue.message}').join('\n')}',
      );
    }

    expect(errors, isEmpty);
    for (final lesson in course.lessons) {
      final duel = const DuelEligibilityService().evaluate(lesson);
      expect(
        duel.isAvailable,
        isTrue,
        reason:
            '${lesson.lessonId} has ${duel.eligibleCount}/${duel.requiredCount} '
            'Duel-eligible exercises',
      );
      for (final round in lesson.rounds) {
        expect(
          RoundPlayabilityService().playableExerciseIndices(round),
          isNotEmpty,
          reason: '${lesson.lessonId}/${round.id} must be learner-playable',
        );
      }
    }
  });
}
