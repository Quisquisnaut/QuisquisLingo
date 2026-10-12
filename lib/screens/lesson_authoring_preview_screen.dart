import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/course_language_resolver.dart';
import '../services/lesson_presentation_service.dart';
import 'round_screen.dart';
import '../services/round_type_presentation.dart';
import '../widgets/course_preview_flag.dart';
import '../widgets/labelled_text.dart';

class LessonAuthoringPreviewScreen extends StatelessWidget {
  const LessonAuthoringPreviewScreen({
    super.key,
    required this.course,
    required this.lesson,
  });

  final Course course;
  final Lesson lesson;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: CoursePreviewTitle(
        course: course,
        title: () {
          final index = course.lessons.indexWhere(
            (candidate) => candidate.lessonId == lesson.lessonId,
          );
          final identity = index < 0
              ? null
              : const LessonPresentationService().identity(course, index);
          return LabelledText(
            'PREVIEW · ${identity?.fullText ?? lesson.title}',
            label: identity?.prefix,
          );
        }(),
      ),
    ),
    body: lesson.rounds.isEmpty
        ? const Center(child: Text('This Lesson has no Rounds to preview.'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lesson.rounds.length,
            itemBuilder: (context, index) {
              final round = lesson.rounds[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: LabelledText(
                    RoundTypePresentation.title(
                      round,
                      index + 1,
                      course.roundNumberingMode,
                      customPrefix: course.customRoundLabel,
                    ),
                    label: RoundTypePresentation.prefix(
                      round.roundType,
                      index + 1,
                      course.roundNumberingMode,
                      customPrefix: course.customRoundLabel,
                    ),
                  ),
                  subtitle: Text('${round.exercises.length} exercises'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => RoundScreen(
                        course: course,
                        lesson: lesson,
                        round: round,
                        ttsLanguage:
                            CourseLanguageResolver.learning(course).code ?? '',
                        roundIndex: index,
                        previewMode: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
  );
}
