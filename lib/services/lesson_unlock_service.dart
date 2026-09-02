import '../models/course_models.dart';

class LessonUnlockService {
  const LessonUnlockService();

  bool isLessonUnlocked({
    required int lessonIndex,
    required Course course,
    required Set<String> completedLessons,
    required Set<String> wonDuels,
  }) {
    if (lessonIndex < 0 || lessonIndex >= course.lessons.length) return false;
    if (lessonIndex == 0) return true;

    final previousLesson = course.lessons[lessonIndex - 1];
    return completedLessons.contains(previousLesson.lessonId) ||
        wonDuels.contains(previousLesson.duel.id);
  }
}
