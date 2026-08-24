import '../models/course_models.dart';

class UnlockService {
  bool isChapterUnlocked({
    required int chapterIndex,
    required Course course,
    required Set<String> completedTopics,
    required Set<String> wonDuels,
  }) {
    if (chapterIndex == 0) return true;

    final previous = course.chapters[chapterIndex - 1];
    final completedInPrevious = previous.learningTopics
        .where((topic) => completedTopics.contains(topic.id))
        .length;

    final completedEnough =
        completedInPrevious >= previous.requiredTopics;
    final wonPreviousDuel = wonDuels.contains(previous.duel.id);

    return completedEnough || wonPreviousDuel;
  }
}
