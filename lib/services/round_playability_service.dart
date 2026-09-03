import '../models/course_models.dart';
import 'course_audit_service.dart';

/// Shares the learner-facing definition of a runnable Round exercise.
class RoundPlayabilityService {
  final CourseAuditService _audit;

  RoundPlayabilityService({CourseAuditService? auditService})
    : _audit = auditService ?? CourseAuditService();

  List<int> playableExerciseIndices(
    LearningRound round, {
    bool includeDrafts = false,
  }) => !includeDrafts && !round.publicationState.isPublished
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

  Set<String> laurelEligibleRoundIds(Course course) => {
    for (final lesson in course.lessons)
      if (course.publicationState.isPublished &&
          lesson.publicationState.isPublished)
        for (final round in lesson.rounds)
          if (playableExerciseIndices(round).isNotEmpty) round.id,
  };
}
