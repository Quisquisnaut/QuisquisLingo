import 'package:flutter/material.dart';

import '../services/course_change_summary.dart';

/// What changed since the last save, in the "Unsaved course changes"
/// question (Build 274 Revision 5, owner decisions of 16 October 2026):
/// the areas only, each opening to all its details; text only, nothing
/// opens from here.
class CourseChangesList extends StatelessWidget {
  const CourseChangesList({
    super.key,
    required this.areas,
    this.neverSaved = false,
  });

  final List<CourseChangeArea> areas;

  /// A Course that was never saved: everything in it is new.
  final bool neverSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final never = Text(
      'This Course has not been saved yet: Discard changes means it is not '
      'created.',
      key: const Key('course-changes-never-saved'),
      style: theme.textTheme.bodyMedium,
    );
    if (areas.isEmpty) return neverSaved ? never : const SizedBox.shrink();
    return Column(
      key: const Key('course-changes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (neverSaved) ...[never, const SizedBox(height: 8)],
        Text(
          neverSaved
              ? 'What changed since it was created:'
              : 'What changed since the last save:',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        for (final (i, area) in areas.indexed)
          ExpansionTile(
            key: ValueKey('course-change-area-$i'),
            dense: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              area.details.length == 1
                  ? area.title
                  : '${area.title} (${area.details.length})',
            ),
            children: [
              for (final (j, detail) in area.details.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $detail',
                    key: ValueKey('course-change-detail-$i-$j'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
