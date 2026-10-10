import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/lesson_presentation_service.dart';
import '../services/round_type_presentation.dart';
import 'labelled_text.dart';

/// Labels come from the current working copy; IDs, never labels, locate nodes.
class EditorBreadcrumbs extends StatelessWidget {
  const EditorBreadcrumbs({
    super.key,
    required this.course,
    this.lessonId,
    this.roundId,
    this.exercise = false,
    this.onParent,
  });

  final Course course;
  final String? lessonId;
  final String? roundId;
  final bool exercise;
  final VoidCallback? onParent;

  /// "Step 2: Coffee", or the Round type when the numbering is off.
  (String, String?) _roundCrumb(LearningRound round, int number) {
    final label =
        RoundTypePresentation.numberLabel(
          number,
          course.roundNumberingMode,
          customPrefix: course.customRoundLabel,
        ) ??
        RoundTypePresentation.label(round.roundType);
    final title = RoundTypePresentation.authoredTitle(round);
    return (title.isEmpty ? label : '$label: $title', label);
  }

  @override
  Widget build(BuildContext context) {
    final lessonIndex = course.lessons.indexWhere(
      (l) => l.lessonId == lessonId,
    );
    final lesson = lessonIndex < 0 ? null : course.lessons[lessonIndex];
    final roundIndex = lesson?.rounds.indexWhere((r) => r.id == roundId) ?? -1;
    // Build 270 Revision 12 (owner report): each crumb's label follows the
    // Course's numbering and is drawn in the label style.
    final labels = <(String, String?)>[
      (course.title.isEmpty ? 'Course' : course.title, null),
      if (lessonId != null)
        if (lesson == null)
          ('Lesson', null)
        else
          () {
            final identity = const LessonPresentationService().identity(
              course,
              lessonIndex,
            );
            return (identity.fullText, identity.prefix);
          }(),
      if (roundId != null)
        if (roundIndex < 0)
          ('New Round', null)
        else
          _roundCrumb(lesson!.rounds[roundIndex], roundIndex + 1),
      if (exercise) ('Exercise', null),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) const Text('>'),
            if (index == labels.length - 2 && onParent != null)
              TextButton(
                onPressed: onParent,
                child: LabelledText(labels[index].$1, label: labels[index].$2),
              )
            else
              LabelledText(labels[index].$1, label: labels[index].$2),
          ],
        ],
      ),
    );
  }
}
