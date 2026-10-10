import '../models/course_models.dart';

class LessonIdentityPresentation {
  const LessonIdentityPresentation({
    required this.fullText,
    required this.title,
    required this.number,
    this.prefix,
    this.deduplicated = false,
  });

  final String fullText;
  final String? prefix;
  final String title;
  final int number;
  final bool deduplicated;
}

class LessonPresentationService {
  const LessonPresentationService();

  /// The label and number before a Lesson's title, or null when the
  /// numbering is off.
  static String? prefixFor(
    LessonNumberingMode mode,
    int number, {
    String customLabel = '',
  }) => switch (mode) {
    LessonNumberingMode.lesson => 'Lesson $number',
    LessonNumberingMode.unit => 'Unit $number',
    LessonNumberingMode.topic => 'Topic $number',
    LessonNumberingMode.module => 'Module $number',
    LessonNumberingMode.skill => 'Skill $number',
    LessonNumberingMode.chapter => 'Chapter $number',
    LessonNumberingMode.stage => 'Stage $number',
    LessonNumberingMode.step => 'Step $number',
    LessonNumberingMode.part => 'Part $number',
    LessonNumberingMode.other => '$customLabel $number',
    LessonNumberingMode.numberOnly => '$number',
    LessonNumberingMode.none => null,
  };

  /// Whether the learner panel names this Course's Lessons with its own
  /// "Lesson {n}" in the Course's instruction language (the default
  /// numbering); any other numbering is the author's and the panel shows it
  /// as the learner path does (Build 270 Revision 12).
  static bool panelNamesLessons(Course course) =>
      course.lessonNumberingMode == LessonNumberingMode.lesson;

  LessonIdentityPresentation identity(Course course, int publishedLessonIndex) {
    final lesson = course.lessons[publishedLessonIndex];
    final number = publishedLessonIndex + 1;
    final prefix = prefixFor(
      course.lessonNumberingMode,
      number,
      customLabel: course.customLessonLabel,
    );
    // A numbering choice may not hide an authored title. Avoid only the exact
    // duplicate that would show the same text twice.
    final deduplicated = prefix != null && lesson.title == prefix;
    final displayTitle = deduplicated ? prefix : lesson.title;
    return LessonIdentityPresentation(
      fullText: deduplicated || prefix == null
          ? displayTitle
          : '$prefix: ${lesson.title}',
      prefix: deduplicated ? null : prefix,
      title: displayTitle,
      number: number,
      deduplicated: deduplicated,
    );
  }
}
