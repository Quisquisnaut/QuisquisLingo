import 'course_models.dart';

/// Immutable, presentation-ready snapshot of authoritative learner status.
class LearnerStatusState {
  final String? activeProfile;
  final Course? course;
  final String? courseCode;
  final int weeklyXp;
  final int? weeklyXpGoal;
  final int? streak;
  final int? laurels;

  const LearnerStatusState({
    required this.activeProfile,
    required this.course,
    required this.courseCode,
    required this.weeklyXp,
    required this.weeklyXpGoal,
    required this.streak,
    required this.laurels,
  });

  const LearnerStatusState.loading()
    : activeProfile = null,
      course = null,
      courseCode = null,
      weeklyXp = 0,
      weeklyXpGoal = null,
      streak = null,
      laurels = null;

  bool get hasCourse => course != null;
}
