import '../models/course_models.dart';
import 'lesson_icon_catalog.dart';

/// Build 264 Revision 8: the Course-wide rule behind Lesson icons taken from
/// the image library (pure Dart, no Flutter).
abstract final class LessonIconPictures {
  /// Whether a Lesson of [course] uses an icon an earlier build lacks: a QQL
  /// picture of the image library, or one of the icons added in Build 264
  /// Revision 8.
  static bool courseUsesLibraryPicture(Course course) => course.lessons.any(
    (lesson) =>
        lesson.themeIconAsset != null &&
        (LessonIconCatalog.isLibraryPicture(lesson.themeIconAsset!) ||
            LessonIconCatalog.addedInBuild264.contains(lesson.themeIconAsset)),
  );

  /// [course] with its `minimumAppBuild` raised to
  /// [LessonIconCatalog.libraryPictureMinimumAppBuild] when a Lesson uses
  /// such an icon and the Course records a lower build (never lowered): an
  /// earlier build refuses a library picture as a Lesson icon, or lacks the
  /// new icon, so it refuses the Course with a clear reason.
  static Course withMinimumAppBuild(Course course) {
    final current = course.minimumAppBuild;
    if (current != null &&
        current >= LessonIconCatalog.libraryPictureMinimumAppBuild) {
      return course;
    }
    if (!courseUsesLibraryPicture(course)) return course;
    return Course.fromJson({
      ...course.toJson(),
      'minimumAppBuild': LessonIconCatalog.libraryPictureMinimumAppBuild,
    });
  }
}
