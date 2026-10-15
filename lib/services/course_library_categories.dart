import '../models/course_models.dart';
import 'course_library_service.dart';

/// The fixed Course library section order and its visible headings.
enum CourseLibraryCategory {
  favorites('Favorites', 'favorites'),
  bundled('Bundled Courses', '0'),
  publisher('Publisher Courses', '1'),
  myLocal('My Local Courses', '2'),
  otherLocal('Other Local Courses', '3');

  const CourseLibraryCategory(this.label, this.sectionId);

  final String label;
  final String sectionId;
}

abstract final class CourseLibraryCategories {
  static const standard = [
    CourseLibraryCategory.bundled,
    CourseLibraryCategory.publisher,
    CourseLibraryCategory.myLocal,
    CourseLibraryCategory.otherLocal,
  ];

  /// The [standard] sections a tab draws for its [courses]. Bundled Courses
  /// only while one of them is a Bundled Course: no Course comes with the app
  /// currently, and an empty section said nothing (owner decision of 14
  /// October 2026). The other sections are always drawn.
  static List<CourseLibraryCategory> shownFor(Iterable<Course> courses) => [
    for (final category in standard)
      if (category != CourseLibraryCategory.bundled ||
          courses.any(
            (course) => course.originType == CourseOriginType.bundledOfficial,
          ))
        category,
  ];

  static CourseLibraryCategory of(Course course, String? activeProfileId) {
    if (course.originType == CourseOriginType.bundledOfficial) {
      return CourseLibraryCategory.bundled;
    }
    if (course.originType == CourseOriginType.externalOfficial) {
      return CourseLibraryCategory.publisher;
    }
    return CourseLibraryService.creatorProfileId(course) == activeProfileId
        ? CourseLibraryCategory.myLocal
        : CourseLibraryCategory.otherLocal;
  }

  static bool includes(
    CourseLibraryCategory category,
    Course course, {
    required String? activeProfileId,
    required Set<String> favoriteIds,
  }) => category == CourseLibraryCategory.favorites
      ? favoriteIds.contains(course.courseId)
      : of(course, activeProfileId) == category;
}
