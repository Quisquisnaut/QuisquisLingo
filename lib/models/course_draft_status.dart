import 'course_models.dart';

/// The authoritative authored-Draft rule for a Course hierarchy, shared by the
/// Editor's Draft badges and the Course Library availability filter.
///
/// Pure and cheap: it reads publication states only and never runs the Audit.
abstract final class CourseDraftStatus {
  static bool courseHasDraft(Course course) =>
      course.lessons.any((lesson) => lessonHasDraft(course, lesson));

  static bool lessonHasDraft(Course course, Lesson lesson) =>
      !lesson.publicationState.isPublished ||
      lessonGuidebookHasDraft(course, lesson) ||
      lessonHasRoundDraft(lesson);

  /// A turned-off GuideBook never shows a Draft badge and never counts in the
  /// Lesson or Course badge, whatever its stored state.
  static bool lessonGuidebookHasDraft(Course course, Lesson lesson) =>
      course.useGuidebook &&
      (!lesson.guidebook.publicationState.isPublished ||
          lesson.guidebook.content.any(
            (content) => !content.publicationState.isPublished,
          ));

  static bool lessonHasRoundDraft(Lesson lesson) =>
      lesson.rounds.any(roundHasDraft);

  static bool roundHasDraft(LearningRound round) =>
      !round.publicationState.isPublished ||
      round.content.any((content) => !content.publicationState.isPublished);

  static bool exerciseIsDraft(Exercise exercise) =>
      !exercise.publicationState.isPublished;
}
