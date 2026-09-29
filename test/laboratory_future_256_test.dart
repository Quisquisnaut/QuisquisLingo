import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

import 'support/fake_file_dialog_backend.dart';

/// Build 256 Revision 7 (plan A.12): the test-only fixture Course
/// `test/fixtures/v12/laboratory_future_en_it.json`, written by the
/// Laboratory generator, holds what this version cannot play yet: Speak,
/// Ink and Submit exercises, a Story ending on a Speak step and a Story
/// whose flow branches. QQL reads it, the Audit passes it with information
/// and warnings only, nothing of it plays, and the canonical editor, JSON
/// and packages carry it unchanged.
const _fixture = 'test/fixtures/v12/laboratory_future_en_it.json';

Map<String, dynamic> _json() =>
    jsonDecode(File(_fixture).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final course = Course.fromJson(_json());
  final rounds = course.lessons.single.rounds;
  final exercises = rounds.expand((round) => round.exercises).toList();

  test('the fixture is what the generator wrote and reads back unchanged', () {
    expect(course.toJson(), _json());
    expect(course.lessons.single.title, 'Future');
    expect(rounds.map((round) => round.title), [
      'Speak',
      'Ink and Submit',
      'A Story that ends on speech',
      'A branching Story',
    ]);
    expect(
      exercises.map((exercise) => exercise.primitive).toSet(),
      containsAll([
        ExercisePrimitive.speak,
        ExercisePrimitive.ink,
        ExercisePrimitive.submit,
        ExercisePrimitive.select,
        ExercisePrimitive.presentation,
      ]),
    );
    for (final exercise in exercises) {
      expect(exercise.authoringMetadata, isEmpty, reason: exercise.id);
    }
    final restored = Course.fromJson(
      jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), course.toJson());
  });

  test('the Audit accepts it with information and warnings only', () {
    final issues = CourseAuditService().auditCourse(course).issues;
    expect(
      issues.where((issue) => issue.severity == AuditSeverity.error),
      isEmpty,
      reason: issues
          .where((issue) => issue.severity == AuditSeverity.error)
          .map(
            (issue) => '${issue.code} ${issue.message} (${issue.exerciseId})',
          )
          .join('\n'),
    );
    final notExecutable = exercises
        .where((exercise) => !exercise.isExecutable)
        .map((exercise) => exercise.id)
        .toSet();
    expect(notExecutable, isNotEmpty);
    expect(
      issues
          .where((issue) => issue.code == 'EXERCISE_NOT_EXECUTABLE')
          .map((issue) => issue.exerciseId)
          .toSet(),
      notExecutable,
    );
    expect(
      issues
          .where((issue) => issue.code == 'ROUND_NOT_COMPLETABLE')
          .map((issue) => issue.roundId)
          .toSet(),
      rounds.map((round) => round.id).toSet(),
      reason: 'every Round of the fixture waits for a later version',
    );
  });

  test('nothing of it plays in this version, and no Laurel can be earned', () {
    final playability = RoundPlayabilityService();
    for (final round in rounds) {
      final playable = playability.playableExerciseIndices(round);
      // A Story keeps its cover and lines; a practice Round has nothing.
      for (final index in playable) {
        expect(
          round.exercises[index].primitive,
          ExercisePrimitive.presentation,
          reason: '${round.id} ${round.exercises[index].id}',
        );
      }
    }
    expect(playability.laurelEligibleRoundIds(course), isEmpty);
    final branching = rounds.last;
    expect(branching.flow, isNotNull);
    expect(branching.flow!.isValid, isTrue);
    expect(branching.flow!.hasBranching, isTrue);
    expect(playability.playableExerciseIndices(branching), isEmpty);
  });

  test(
    'the canonical editor, a JSON file and a package carry it unchanged',
    () async {
      for (final exercise in exercises) {
        final draft = CanonicalExerciseDraft.fromExercise(exercise);
        expect(draft.violations, isEmpty, reason: exercise.id);
        final rebuilt = draft.toExercise(
          publicationState: exercise.publicationState,
          updatedAt: exercise.updatedAt,
        );
        expect(
          rebuilt.semanticallyEquals(exercise),
          isTrue,
          reason: exercise.id,
        );
      }
      // The fixture sits on the Laboratory's bundled root, which the import
      // route refuses by design; the package is read back with the plain
      // parser, as a converter's own tests would.
      final bytes = File(_fixture).readAsBytesSync();
      expect(
        () =>
            CustomCourseTransferService().courseFromBytes(bytes, 'future.json'),
        throwsFormatException,
      );
      final packages = CoursePackageService(stager: testImportStager());
      final zip = await packages.build(course, bytes);
      final package = await packages.parse(
        zip,
        (raw, _) async => Course.fromJson(
          jsonDecode(utf8.decode(raw)) as Map<String, dynamic>,
        ),
      );
      try {
        expect(package.course.toJson(), course.toJson());
      } finally {
        await package.discard();
      }
    },
  );
}
