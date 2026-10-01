import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 259 Revision 6 (owner request of 1 October 2026): QQL Demo:
/// Piedmontese holds the Piedmontese demo's exercises mixed at random in
/// one Lesson of 20 Rounds of six, each opening with a Before you start
/// card, then the Story; no GuideBook.

const _asset = 'assets/courses/piedmontese_mixed_en.json';

Map<String, dynamic> _raw(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// A Content's JSON with its own ID (and so its items' IDs) neutralized.
String _withoutIds(LearningContent content) =>
    jsonEncode(content.toJson()).replaceAll('"${content.id}', '"ID');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final raw = _raw(_asset);
  final mixed = Course.fromJson(raw);
  final source = Course.fromJson(_raw('assets/courses/piedmontais_en.json'));

  test('is the third bundled Course, beside the Piedmontese demo', () async {
    expect(CourseService.courseAssets['PMS_MIX'], _asset);
    final loaded = await CourseService().loadBundledCourse('PMS_MIX');
    expect(loaded.title, 'QQL Demo: Piedmontese');
    expect(loaded.originType, CourseOriginType.bundledOfficial);
    expect(CourseService.bundledCodeForCourse(loaded), 'PMS_MIX');
    // Language XP and streaks stay with Piedmontese.
    expect(CourseService.codeForCourse(loaded), 'PMS');
    expect(loaded.courseId, isNot(source.courseId));
    expect(mixed.toJson(), raw);
    expect(CourseChecksums.official(mixed), mixed.officialChecksum);
  });

  test('holds exactly the Piedmontese exercises, mixed', () {
    final sourceExercises = [
      for (final lesson in source.lessons.take(40))
        for (final round in lesson.rounds) ...round.content.skip(1),
    ];
    final practice = mixed.lessons.first;
    final mixedExercises = [
      for (final round in practice.rounds) ...round.content.skip(1),
    ];
    expect(mixedExercises, hasLength(120));
    expect(
      mixedExercises.map(_withoutIds).toList()..sort(),
      sourceExercises.map(_withoutIds).toList()..sort(),
    );
    // No Round is one exercise type, as in the source.
    for (final round in practice.rounds) {
      final types = round.content
          .skip(1)
          .map((content) => content.editorTemplate)
          .toSet();
      expect(types.length, greaterThan(2), reason: round.id);
    }
  });

  test('one Lesson of 20 Rounds of six, each with a card, then the Story', () {
    expect(mixed.useGuidebook, isFalse);
    expect(mixed.lessons, hasLength(2));
    final practice = mixed.lessons.first;
    expect(practice.title, 'Mixed practice');
    expect(practice.rounds, hasLength(20));
    for (final round in practice.rounds) {
      expect(round.flow, isNull);
      expect(round.content, hasLength(7));
      final card = ExerciseFeatures(round.exercises.first);
      expect(card.kind, LearnerExerciseKind.roundIntro);
      expect(card.introText, 'Mixed practice: 6 exercises of different types.');
      expect(card.guidebookButton, isFalse);
      expect(
        round.exercises
            .skip(1)
            .any(
              (exercise) =>
                  exercise.canonicalEvaluation.mode != EvaluationMode.none,
            ),
        isTrue,
        reason: round.id,
      );
    }
    final story = mixed.lessons.last;
    expect(story.rounds.single.isStory, isTrue);
    expect(
      story.rounds.single.content.map(_withoutIds).skip(1),
      source.lessons.last.rounds.single.content
          .map(_withoutIds)
          .skip(1)
          .map(
            (text) => text.replaceAll(
              'pms_e5f5585a_character_',
              'pmsmix_69ff369e_character_',
            ),
          ),
    );
    for (final lesson in mixed.lessons) {
      expect(lesson.guidebook.content, isEmpty);
    }
  });

  test('passes the Audit with no error', () {
    final audit = CourseAuditService().auditCourse(mixed);
    expect(audit.count(AuditSeverity.error), 0);
    expect(
      audit.issues
          .where((issue) => issue.severity == AuditSeverity.warning)
          .map((issue) => '${issue.code}:${issue.exerciseId}'),
      isEmpty,
    );
  });
}
