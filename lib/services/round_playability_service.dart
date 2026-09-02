import '../models/course_models.dart';
import 'course_audit_service.dart';

/// Shares the learner-facing definition of a runnable Round exercise.
class RoundPlayabilityService {
  final CourseAuditService _audit;

  RoundPlayabilityService({CourseAuditService? auditService})
    : _audit = auditService ?? CourseAuditService();

  List<int> playableExerciseIndices(LearningRound round) =>
      List<int>.generate(round.exercises.length, (index) => index)
          .where(
            (index) => !_audit
                .auditExercise(round.exercises[index])
                .any((issue) => issue.severity == AuditSeverity.error),
          )
          .toList();

  Set<String> laurelEligibleRoundIds(Course course) => {
    for (final lesson in course.lessons)
      for (final round in lesson.rounds)
        if (playableExerciseIndices(round).isNotEmpty) round.id,
  };
}
