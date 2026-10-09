import '../models/course_models.dart';

/// Editor Notes (Build 267 Revision 8, owner decisions of 9 October 2026):
/// the author's own notes on each exercise of a Round, stored on its
/// Content as `editorNotes`. Pure Dart, no Flutter.
abstract final class EditorNotes {
  /// The first build that reads `editorNotes`: a Course with notes records
  /// it as its `minimumAppBuild`, so an earlier build refuses the Course
  /// with a clear reason instead of losing the notes on its next save.
  static const minimumAppBuild = 267008;

  /// Whether any exercise of [course] has notes.
  static bool courseHasNotes(Course course) => course.lessons.any(
    (lesson) => lesson.rounds.any(
      (round) => round.exercises.any(
        (exercise) => exercise.editorNotes.trim().isNotEmpty,
      ),
    ),
  );

  /// [course] with its `minimumAppBuild` raised to [minimumAppBuild] when it
  /// has notes and records a lower build (never lowered).
  static Course withMinimumAppBuild(Course course) {
    final current = course.minimumAppBuild;
    if (current != null && current >= minimumAppBuild) return course;
    if (!courseHasNotes(course)) return course;
    return Course.fromJson({
      ...course.toJson(),
      'minimumAppBuild': minimumAppBuild,
    });
  }

  /// [course] without any notes: Export as Publisher Course removes them,
  /// as they are the author's own working notes.
  static Course withoutNotes(Course course) {
    if (!courseHasNotes(course)) return course;
    final json = course.toJson();
    for (final lesson in json['lessons'] as List) {
      for (final round in (lesson as Map)['rounds'] as List) {
        for (final content in (round as Map)['content'] as List) {
          (content as Map).remove('editorNotes');
        }
      }
    }
    return Course.fromJson(json);
  }
}
