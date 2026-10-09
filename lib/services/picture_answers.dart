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

  /// Whether [course] asks for the line around pictures (Build 267
  /// Revision 7), for itself or in an exercise.
  static bool courseAsksForBorder(Course course) =>
      course.pictureAnswers.border != PictureAnswerStyle.standard.border ||
      course.lessons.any(
        (lesson) => lesson.rounds.any(
          (round) => round.exercises.any(
            (exercise) => PictureAnswerStyle.overridesBorder(exercise.options),
          ),
        ),
      );

  /// The build [course]'s picture answers need, or null.
  static int? requiredBuild(Course course) => courseAsksForBorder(course)
      ? PictureAnswerStyle.borderMinimumAppBuild
      : courseAsksForLook(course)
      ? PictureAnswerStyle.minimumAppBuild
      : null;

  /// [course] with its `minimumAppBuild` raised to the build its picture
  /// answers need ([requiredBuild]) when it records a lower one (never
  /// lowered): an earlier build refuses the new options and Course fields,
  /// so it refuses the Course with a clear reason.
  static Course withMinimumAppBuild(Course course) {
    final required = requiredBuild(course);
    if (required == null) return course;
    final current = course.minimumAppBuild;
    if (current != null && current >= required) return course;
    return Course.fromJson({...course.toJson(), 'minimumAppBuild': required});
  }
}
