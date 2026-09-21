import '../models/course_models.dart';

/// One place where a Course uses an image.
class CourseImageUse {
  const CourseImageUse({
    required this.asset,
    required this.location,
    this.element,
  });

  /// The image's asset string: an `assets/` path, a `media:` reference or an
  /// embedded `data:` image.
  final String asset;

  /// Where the image is used, for people: `Lesson 2 › Round 1 › item 3`,
  /// `Lesson 1 › GuideBook › item 2` or `Course cover`.
  final String location;

  /// The image element, or null for the Course cover.
  final PromptElement? element;
}

/// The single answer to "where does this Course use this image?".
///
/// A Course uses an image in any image element of any Lesson content — the
/// content of every Round and of the Lesson's GuideBook, whether that content
/// is an exercise (prompt, answer items, layout) or a presentation such as a
/// flashcard, explanation or Lesson introduction — and as its cover. Storage
/// (`CourseMediaStore.referencesOf`), the Image Library's IN USE badge and the
/// Exercise editor all ask here, so they always agree.
abstract final class CourseImageUsage {
  static List<CourseImageUse> uses(Course course) {
    final out = <CourseImageUse>[];
    for (var l = 0; l < course.lessons.length; l++) {
      final lesson = course.lessons[l];
      final lessonName = 'Lesson ${l + 1}';
      for (var r = 0; r < lesson.rounds.length; r++) {
        final round = lesson.rounds[r];
        final content = round.content;
        for (var c = 0; c < content.length; c++) {
          _addContent(
            out,
            content[c],
            '$lessonName › ${round.displayTitle(r)} › item ${c + 1}',
          );
        }
      }
      final guidebook = lesson.guidebook.content;
      for (var c = 0; c < guidebook.length; c++) {
        _addContent(
          out,
          guidebook[c],
          '$lessonName › GuideBook › item ${c + 1}',
        );
      }
    }
    if (course.coverImage.isNotEmpty) {
      out.add(
        CourseImageUse(asset: course.coverImage, location: 'Course cover'),
      );
    }
    return out;
  }

  /// Every image element in the Course's Lessons, in Course order.
  static Iterable<PromptElement> imageElements(Course course) =>
      uses(course).map((use) => use.element).whereType<PromptElement>();

  /// Every image asset the Course uses, the cover included.
  static Set<String> usedAssets(Course course) => {
    for (final use in uses(course)) use.asset,
  };

  /// The Shared Image Library record an image was taken from, when the Course
  /// recorded one for [asset].
  static SharedImageSource? sharedSourceOf(Course course, String asset) {
    for (final element in imageElements(course)) {
      if (element.asset == asset && element.sharedImageSource != null) {
        return element.sharedImageSource;
      }
    }
    return null;
  }

  static void _addContent(
    List<CourseImageUse> out,
    LearningContent content,
    String location,
  ) {
    void add(Iterable<PromptElement> elements) {
      for (final element in elements) {
        if (element.type == 'image') {
          out.add(
            CourseImageUse(
              asset: element.asset,
              location: location,
              element: element,
            ),
          );
        }
      }
    }

    final exercise = content.exercise;
    if (exercise != null) {
      add(exercise.promptElements);
      for (final item in exercise.interaction.items) {
        add(item.content);
      }
      add(exercise.interaction.layout);
    }
    final presentation = content.presentation;
    if (presentation != null) add(presentation.content);
  }
}
