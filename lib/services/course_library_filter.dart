import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import 'course_library_categories.dart';
import 'course_library_presentation.dart';
import 'publication_service.dart';

/// One section's complete membership and currently visible Courses.
class CourseLibrarySelection {
  const CourseLibrarySelection({required this.all, required this.shown});

  final List<Course> all;
  final List<Course> shown;
}

/// Page-session presentation rules shared by All Courses and Course Studio.
abstract final class CourseLibraryFilter {
  static bool isUnavailable(Course course, {Set<String>? draftCourseIds}) =>
      !course.publicationState.isPublished ||
      PublicationService.requiresPublisherVerification(course) ||
      (draftCourseIds?.contains(course.courseId) ??
          CourseDraftStatus.courseHasDraft(course));

  static CourseLibrarySelection select({
    required Iterable<Course> courses,
    required CourseLibraryCategory category,
    required String? activeProfileId,
    required Set<String> favoriteIds,
    required bool showUnavailable,
    required String search,
    required CourseLibrarySort sort,
    required String Function(Course) maintainerOf,
    Set<String>? draftCourseIds,
  }) {
    final all = courses
        .where(
          (course) => CourseLibraryCategories.includes(
            category,
            course,
            activeProfileId: activeProfileId,
            favoriteIds: favoriteIds,
          ),
        )
        .toList();
    final query = search.trim().toLowerCase();
    final shown = CourseLibraryPresentation.sorted(
      all.where(
        (course) =>
            (showUnavailable ||
                !isUnavailable(course, draftCourseIds: draftCourseIds)) &&
            (query.isEmpty ||
                course.title.toLowerCase().contains(query) ||
                course.sourceLanguage.toLowerCase().contains(query) ||
                course.targetLanguage.toLowerCase().contains(query)),
      ),
      sort,
      maintainerOf: maintainerOf,
    );
    return CourseLibrarySelection(all: all, shown: shown);
  }
}
