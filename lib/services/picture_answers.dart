import '../models/course_models.dart';

/// Build 263 Revision 2: the Course-wide rule behind picture answers' looks
/// (pure Dart, no Flutter).
abstract final class PictureAnswers {
  /// Whether [course] asks for a look other than the standard one, for
  /// itself in Lesson Options or in an exercise of its own.
  static bool courseAsksForLook(Course course) =>
      !course.pictureAnswers.isStandard ||
      course.lessons.any(
        (lesson) => lesson.rounds.any(
          (round) => round.exercises.any(
            (exercise) => PictureAnswerStyle.overrides(exercise.options),
          ),
        ),
      );

  /// [course] with its `minimumAppBuild` raised to
  /// [PictureAnswerStyle.minimumAppBuild] when it asks for another look and
  /// records a lower build (never lowered): an earlier build refuses the
  /// exercises' new options, so it refuses the Course with a clear reason.
  static Course withMinimumAppBuild(Course course) {
    final current = course.minimumAppBuild;
    if (current != null && current >= PictureAnswerStyle.minimumAppBuild) {
      return course;
    }
    if (!courseAsksForLook(course)) return course;
    return Course.fromJson({
      ...course.toJson(),
      'minimumAppBuild': PictureAnswerStyle.minimumAppBuild,
    });
  }
}
