import 'progress_service.dart';
import 'status_service.dart';

/// Projects the existing learner progression records into one Status rank.
class LearnerStatusLevelService {
  final ProgressService _progress;
  final StatusService _status;

  LearnerStatusLevelService({
    ProgressService? progressService,
    StatusService? statusService,
  }) : _progress = progressService ?? ProgressService(),
       _status = statusService ?? StatusService();

  Future<StatusRank> rankForActiveLearner({
    required String courseId,
    required String courseCode,
  }) async {
    final xp = await _progress.getXp(courseCode: courseCode);
    final streak = await _progress.getStreak(courseCode: courseCode);
    final daysStudied = await _progress.getDaysStudied(courseCode: courseCode);
    final completedRounds = await _progress.getCompletedRounds(
      courseId: courseId,
    );
    final laurels = await _progress.getPerfectRounds(courseId: courseId);
    return _status.rank(
      xp: xp,
      streak: streak,
      daysStudied: daysStudied,
      roundsCompleted: completedRounds.length,
      laurelCrowns: laurels.length,
    );
  }
}
