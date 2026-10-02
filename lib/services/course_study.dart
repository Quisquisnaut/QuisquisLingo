import '../models/course_models.dart';
import 'course_service.dart';
import 'progress_service.dart';
import 'publication_service.dart';

/// Study and Review in the Course menus of All Courses and Course Studio
/// (Build 261 Revision 1, owner decision of 1 October 2026).
enum CourseStudyAction { study, review }

/// What a Courses menu asks the learner page to do: add the Course to the
/// learner's courses when it is missing, make it current, and for Review
/// open the Review page on it.
class CourseStudyRequest {
  const CourseStudyRequest(this.course, this.action);

  final Course course;
  final CourseStudyAction action;
}

abstract final class CourseStudy {
  /// Why [course] cannot be studied now, or null. The same reasons as the
  /// Study now offer after an import.
  static String? studyUnavailableReason(
    Course course, {
    required bool hasLearner,
  }) {
    if (!hasLearner) return 'Select a learner profile first.';
    if (PublicationService.requiresPublisherVerification(course)) {
      return 'Publisher verification is required before you can study it.';
    }
    if (!course.publicationState.isPublished) {
      return 'Publish this Course before you can study it.';
    }
    final playable =
        const PublicationService().learnerCourse(course) != null &&
        (course.originType != CourseOriginType.bundledOfficial ||
            CourseService.hasCourse(
              CourseService.bundledCodeForCourse(course),
            ));
    return playable ? null : 'This Course is not available for study yet.';
  }

  /// The Courses in which the active learner has a completed Round that
  /// Review can offer (its records, as the Review page reads them).
  static Future<Set<String>> coursesWithCompletedRounds(
    ProgressService progress,
  ) async => {
    for (final entry in await progress.getRecentRounds(limit: 1 << 30))
      entry.courseId,
  };

  /// Why Review cannot open on [course], or null: the Study reasons, then a
  /// Course with no completed Round to review.
  static String? reviewUnavailableReason(
    Course course, {
    required bool hasLearner,
    required bool hasCompletedRounds,
  }) =>
      studyUnavailableReason(course, hasLearner: hasLearner) ??
      (hasCompletedRounds ? null : 'Complete a Round of this Course first.');
}
