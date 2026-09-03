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

  LessonIdentityPresentation identity(Course course, int publishedLessonIndex) {
    final lesson = course.lessons[publishedLessonIndex];
    final number = publishedLessonIndex + 1;
    final prefix = switch (course.lessonNumberingMode) {
      LessonNumberingMode.lesson => 'Lesson $number',
      LessonNumberingMode.unit => 'Unit $number',
      LessonNumberingMode.topic => 'Topic $number',
      LessonNumberingMode.module => 'Module $number',
      LessonNumberingMode.skill => 'Skill $number',
      LessonNumberingMode.chapter => 'Chapter $number',
      LessonNumberingMode.stage => 'Stage $number',
      LessonNumberingMode.step => 'Step $number',
      LessonNumberingMode.part => 'Part $number',
      LessonNumberingMode.other => '${course.customLessonLabel} $number',
      LessonNumberingMode.numberOnly => '$number',
      LessonNumberingMode.none => null,
    };
    final canonicalDefault = 'Lesson $number';
    final deduplicated =
        course.lessonNumberingMode == LessonNumberingMode.lesson &&
        lesson.title == canonicalDefault;
    return LessonIdentityPresentation(
      fullText: deduplicated || prefix == null
          ? lesson.title
          : '$prefix: ${lesson.title}',
      prefix: deduplicated ? null : prefix,
      title: lesson.title,
      number: number,
      deduplicated: deduplicated,
    );
  }
}
