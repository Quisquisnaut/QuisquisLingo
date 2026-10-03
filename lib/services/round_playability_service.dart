import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'course_audit_service.dart';
import 'round_type_compatibility.dart';
import 'timed_round_rules.dart';

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
  /// Preview shows the same card. A Before you start card is never a step:
  /// the Round screen shows it before the Round starts (Build 257).
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
          round.roundType == RoundType.speak ||
          (round.roundType == RoundType.timed &&
              (!TimedRoundRules.validLimits(round.timedLimitsSeconds) ||
                  round.content.any((content) {
                    final exercise = content.asRunnableExercise();
                    return !content.required || exercise == null;
                  }))) ||
          ((round.roundType == RoundType.story ||
                  round.roundType == RoundType.sequence) !=
              (round.flow != null)) ||
          (round.flow != null && !round.flow!.isLinear) ||
          round.content.any((content) {
            final exercise = content.asRunnableExercise();
            if (exercise == null || isRoundIntro(exercise)) return false;
            return RoundTypeCompatibility.issuesForExercise(
              round.roundType,
              exercise,
              required: content.required,
            ).isNotEmpty;
          })
      ? const []
      : List<int>.generate(round.exercises.length, (index) => index)
            .where(
              (index) =>
                  (includeDrafts ||
                      round.exercises[index].publicationState.isPublished) &&
                  !isRoundIntro(round.exercises[index]) &&
                  !_audit
                      .auditExercise(round.exercises[index])
                      .any((issue) => issue.severity == AuditSeverity.error),
            )
            .toList();

  /// Whether [exercise] is a Before you start card (Build 257).
  static bool isRoundIntro(Exercise exercise) =>
      exercise.primitive == ExercisePrimitive.presentation &&
      ExerciseFeatures(exercise).kind == LearnerExerciseKind.roundIntro;

  /// The Before you start card a learner sees before [round] starts: the
  /// first one that is published (or any, with [includeDrafts]), has a note
  /// and no Audit error; null when there is none.
  Exercise? introFor(LearningRound round, {bool includeDrafts = false}) {
    for (final exercise in round.exercises) {
      if (!isRoundIntro(exercise)) continue;
      if (!includeDrafts && !exercise.publicationState.isPublished) continue;
      if (ExerciseFeatures(exercise).introText.trim().isEmpty) continue;
      if (_audit
          .auditExercise(exercise)
          .any((issue) => issue.severity == AuditSeverity.error)) {
        continue;
      }
      return exercise;
    }
    return null;
  }

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
