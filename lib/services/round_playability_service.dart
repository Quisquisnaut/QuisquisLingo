import '../models/course_models.dart';
import 'course_audit_service.dart';

/// Shares the learner-facing definition of a runnable Round exercise.
class RoundPlayabilityService {
  final CourseAuditService _audit;

  RoundPlayabilityService({CourseAuditService? auditService})
    : _audit = auditService ?? CourseAuditService();

  /// The indices of the exercises a learner can play. A Round whose content
  /// flow branches is not playable in this version at all (Build 256, plan
  /// A.7): only linear Stories run. An exercise this version cannot play
  /// (readable but not executable, plan A.6) leaves here too, with the
  /// invalid and unpublished ones and before any audio filter, unless
  /// [keepNotExecutable]: a Story draws a card in its place and the editor
  /// Preview shows the same card.
  List<int> playableExerciseIndices(
    LearningRound round, {
    bool includeDrafts = false,
    bool keepNotExecutable = false,
  }) => _valid(round, includeDrafts: includeDrafts)
      .where(
        (index) => keepNotExecutable || round.exercises[index].isExecutable,
      )
      .toList();

  /// The valid exercises of [round] this version of QQL cannot play: they
  /// are skipped in a practice Round and shown as cards in a Story.
  List<int> notExecutableIndices(
    LearningRound round, {
    bool includeDrafts = false,
  }) => _valid(
    round,
    includeDrafts: includeDrafts,
  ).where((index) => !round.exercises[index].isExecutable).toList();

  List<int> _valid(LearningRound round, {required bool includeDrafts}) =>
      (!includeDrafts && !round.publicationState.isPublished) ||
          (round.flow != null && !round.flow!.isLinear)
      ? const []
      : List<int>.generate(round.exercises.length, (index) => index)
            .where(
              (index) =>
                  (includeDrafts ||
                      round.exercises[index].publicationState.isPublished) &&
                  !_audit
                      .auditExercise(round.exercises[index])
                      .any((issue) => issue.severity == AuditSeverity.error),
            )
            .toList();

  /// The Rounds a Laurel can be earned in: at least one playable exercise
  /// that is scored. A Round of cards, covers or lines only is completed but
  /// never perfect (owner decision, 28 September 2026).
  Set<String> laurelEligibleRoundIds(Course course) => {
    for (final lesson in course.lessons)
      if (course.publicationState.isPublished &&
          lesson.publicationState.isPublished)
        for (final round in lesson.rounds)
          if (playableExerciseIndices(round).any(
            (index) =>
                round.exercises[index].primitive !=
                ExercisePrimitive.presentation,
          ))
            round.id,
  };
}
