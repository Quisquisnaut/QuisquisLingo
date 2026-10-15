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

  /// The Lesson named once in a page's top bar (Build 274 Revision 0):
  /// its label and number ("Lesson 2", "Unit 2", a custom label as written),
  /// or its title when the numbering has no word (Off, Number only).
  String shortName(Course course, int lessonIndex) {
    final identity = this.identity(course, lessonIndex);
    final mode = course.lessonNumberingMode;
    if (mode == LessonNumberingMode.none ||
        mode == LessonNumberingMode.numberOnly) {
      return identity.title;
    }
    final prefix =
        prefixFor(
          mode,
          identity.number,
          customLabel: course.customLessonLabel,
        )?.trim() ??
        '';
    return prefix.isEmpty ? identity.title : prefix;
  }

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
