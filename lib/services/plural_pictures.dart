import '../models/course_models.dart';

/// Build 265 Revision 11 (owner decision of 7 October 2026): a picture in an
/// exercise may stand for several things, "cats" rather than "cat". The
/// author ticks Plural on the picture; the learner sees it as stacked copies
/// (look A). The mark is `plural` on the picture's element: an image element,
/// or the `icon` element naming a QQL picture answer (pure Dart, no Flutter).
abstract final class PluralPictures {
  /// The first build that draws plural pictures.
  static const minimumAppBuild = 265011;

  /// Whether [element] is a picture that can carry the mark.
  static bool isPicture(PromptElement element) =>
      element.isImage || (element.isText && element.role == 'icon');

  /// The picture an element names: an image's asset, an icon's key.
  static String pictureOf(PromptElement element) =>
      element.isImage ? element.asset : element.text;

  /// The pictures of [exercise] marked plural, in its prompt and its items.
  static Set<String> markedIn(Exercise exercise) => {
    for (final element in _elements(exercise))
      if (isPicture(element) && element.isPlural) pictureOf(element),
  };

  /// [exercise] with exactly the pictures in [plural] marked: the others
  /// lose the mark. The form's recipes build pictures in many ways, so the
  /// mark is applied to their result, as the picture look is.
  static Exercise withMarks(Exercise exercise, Set<String> plural) {
    PromptElement mark(PromptElement element) {
      if (!isPicture(element)) return element;
      final wanted = plural.contains(pictureOf(element));
      return wanted == element.isPlural && (wanted || element.plural == null)
          ? element
          : element.withPlural(wanted);
    }

    var changed = false;
    PromptElement marked(PromptElement element) {
      final result = mark(element);
      if (!identical(result, element)) changed = true;
      return result;
    }

    final prompt = [for (final e in exercise.promptElements) marked(e)];
    final items = [
      for (final item in exercise.items)
        item.copyWith(content: [for (final e in item.content) marked(e)]),
    ];
    // Nothing to mark or unmark: the very exercise the recipe built (a
    // controller's candidate crosses the builder unchanged).
    if (!changed) return exercise;
    return exercise.copyWith(promptElements: prompt, items: items);
  }

  static Iterable<PromptElement> _elements(Exercise exercise) sync* {
    yield* exercise.promptElements;
    for (final item in exercise.items) {
      yield* item.content;
    }
  }

  /// Whether [course] marks any picture plural.
  static bool courseUsesPlural(Course course) => course.lessons.any(
    (lesson) => lesson.rounds.any(
      (round) => round.exercises.any(
        (exercise) => _elements(
          exercise,
        ).any((element) => isPicture(element) && element.isPlural),
      ),
    ),
  );

  /// [course] with its `minimumAppBuild` raised to [minimumAppBuild] when it
  /// marks a picture plural and records a lower build (never lowered): an
  /// earlier build would show one picture where the author meant several.
  static Course withMinimumAppBuild(Course course) {
    final current = course.minimumAppBuild;
    if (current != null && current >= minimumAppBuild) return course;
    if (!courseUsesPlural(course)) return course;
    return Course.fromJson({
      ...course.toJson(),
      'minimumAppBuild': minimumAppBuild,
    });
  }
}
