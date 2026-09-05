import 'package:flutter/material.dart';

import '../models/course_models.dart';

class AuthoringDestination {
  const AuthoringDestination(this.lessonId, [this.roundId]);
  final String lessonId;
  final String? roundId;
}

/// Choosing or cancelling a destination never mutates the working copy.
Future<AuthoringDestination?> chooseAuthoringDestination(
  BuildContext context, {
  required Course course,
  required bool exercise,
  required bool copy,
  required String sourceLessonId,
  String? sourceRoundId,
}) => showDialog<AuthoringDestination>(
  context: context,
  builder: (context) {
    String? lessonId;
    String? roundId;
    return StatefulBuilder(
      builder: (context, setState) {
        final lessons = course.lessons
            .where(
              (lesson) => exercise || copy || lesson.lessonId != sourceLessonId,
            )
            .toList();
        final lesson = lessons.where((l) => l.lessonId == lessonId).firstOrNull;
        final rounds =
            lesson?.rounds
                .where(
                  (round) =>
                      copy ||
                      lessonId != sourceLessonId ||
                      round.id != sourceRoundId,
                )
                .toList() ??
            <LearningRound>[];
        return AlertDialog(
          title: Text(
            '${copy ? 'Copy' : 'Move'} ${exercise ? 'Exercise' : 'Round'} to',
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Course: ${course.title}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('transfer-destination-lesson'),
                  initialValue: lessonId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Lesson'),
                  items: [
                    for (final l in lessons)
                      DropdownMenuItem(
                        value: l.lessonId,
                        child: Text(
                          'Lesson ${course.lessons.indexOf(l) + 1}: ${l.title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    lessonId = value;
                    roundId = null;
                  }),
                ),
                if (exercise) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('transfer-destination-round-$lessonId'),
                    initialValue: roundId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Round'),
                    items: [
                      for (final r in rounds)
                        DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            r.displayTitle(lesson!.rounds.indexOf(r)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => roundId = value),
                  ),
                  if (lesson != null && rounds.isEmpty)
                    const Text(
                      'This Lesson has no eligible destination Round. Choose another Lesson or create a Round first.',
                    ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Changes stay in this course working copy until Confirm course changes. Cancel course changes discards them.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-authoring-transfer'),
              onPressed: lessonId == null || (exercise && roundId == null)
                  ? null
                  : () => Navigator.pop(
                      context,
                      AuthoringDestination(lessonId!, roundId),
                    ),
              child: Text(copy ? 'Copy here' : 'Move here'),
            ),
          ],
        );
      },
    );
  },
);
