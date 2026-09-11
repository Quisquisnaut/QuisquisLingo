import '../models/course_models.dart';
import 'progress_service.dart';

class ReviewRoundLocation {
  const ReviewRoundLocation({
    required this.entry,
    required this.lessonIndex,
    required this.lesson,
    required this.roundIndex,
    required this.round,
  });

  final RecentRoundEntry entry;
  final int lessonIndex;
  final Lesson lesson;
  final int roundIndex;
  final LearningRound round;
}

class ReviewRoundResolver {
  ReviewRoundResolver({ProgressService? progress})
    : _progress = progress ?? ProgressService();

  final ProgressService _progress;

  Future<ReviewRoundLocation?> firstPending(
    Course course, {
    Set<String> excludedRoundIds = const {},
  }) async {
    final entries = await _progress.getRecentRounds(
      courseId: course.courseId,
      limit: 50,
    );
    for (final entry in entries) {
      if (excludedRoundIds.contains(entry.roundId)) continue;
      final lessonIndex = course.lessons.indexWhere(
        (lesson) => lesson.lessonId == entry.lessonId,
      );
      if (lessonIndex < 0) continue;
      final lesson = course.lessons[lessonIndex];
      final roundIndex = lesson.rounds.indexWhere(
        (round) => round.id == entry.roundId,
      );
      if (roundIndex < 0) continue;
      return ReviewRoundLocation(
        entry: entry,
        lessonIndex: lessonIndex,
        lesson: lesson,
        roundIndex: roundIndex,
        round: lesson.rounds[roundIndex],
      );
    }
    return null;
  }
}
