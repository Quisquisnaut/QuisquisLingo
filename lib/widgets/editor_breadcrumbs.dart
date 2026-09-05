import 'package:flutter/material.dart';

import '../models/course_models.dart';

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

  @override
  Widget build(BuildContext context) {
    final lessonIndex = course.lessons.indexWhere(
      (l) => l.lessonId == lessonId,
    );
    final lesson = lessonIndex < 0 ? null : course.lessons[lessonIndex];
    final roundIndex = lesson?.rounds.indexWhere((r) => r.id == roundId) ?? -1;
    final labels = <String>[
      course.title.isEmpty ? 'Course' : course.title,
      if (lessonId != null)
        lesson == null
            ? 'Lesson'
            : 'Lesson ${lessonIndex + 1}${lesson.title.isEmpty ? '' : ': ${lesson.title}'}',
      if (roundId != null)
        roundIndex < 0
            ? 'New Round'
            : 'Round ${roundIndex + 1}${lesson!.rounds[roundIndex].title.isEmpty ? '' : ': ${lesson.rounds[roundIndex].title}'}',
      if (exercise) 'Exercise',
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
              TextButton(onPressed: onParent, child: Text(labels[index]))
            else
              Text(labels[index]),
          ],
        ],
      ),
    );
  }
}
