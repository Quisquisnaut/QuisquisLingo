import '../models/course_models.dart';
import '../models/exercise_features.dart';

/// Build 258: the rules a Page's blocks share between the renderer, the
/// Audit and saving (pure Dart, no Flutter).
abstract final class PageBlocks {
  /// The first build that draws Pages. A Course that contains one records
  /// it as its `minimumAppBuild` when saved, so an earlier build refuses the
  /// Course instead of showing its pages unformatted (owner decision, 29
  /// September 2026).
  static const minimumAppBuild = 258000;

  /// Whether [url] may be opened from a Page: an `https` address with a
  /// host. Anything else is refused by the renderer and reported by the
  /// Audit.
  static bool isAcceptableLink(String url) {
    final uri = Uri.tryParse(url.trim());
    // Build 270 Revision 6: no user part, which makes a link look like one
    // site and open another.
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty;
  }

  /// Whether [block] shows something: text, a picture, audio or a link.
  static bool hasContent(PromptElement block) => block.isImage
      ? block.asset.trim().isNotEmpty
      : block.isLink
      ? block.url.trim().isNotEmpty
      : block.text.trim().isNotEmpty;

  /// Whether any exercise of [course] is a Page.
  static bool courseHasPages(Course course) => course.lessons.any(
    (lesson) => lesson.rounds.any(
      (round) => round.exercises.any(
        (exercise) =>
            ExerciseFeatures(exercise).kind == LearnerExerciseKind.page,
      ),
    ),
  );

  /// [course] with its `minimumAppBuild` raised to [minimumAppBuild] when it
  /// contains a Page and records a lower build (never lowered).
  static Course withMinimumAppBuild(Course course) {
    final current = course.minimumAppBuild;
    if (current != null && current >= minimumAppBuild) return course;
    if (!courseHasPages(course)) return course;
    return Course.fromJson({
      ...course.toJson(),
      'minimumAppBuild': minimumAppBuild,
    });
  }
}
