import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import '../services/course_library_filter.dart';
import '../services/course_library_presentation.dart';
import '../services/course_media_store.dart';
import '../services/publication_service.dart';
import 'course_artwork.dart';

/// The Course details used by both tabs of Courses. The owning tab supplies
/// its own actions and, for Course Studio, its Audit border.
class CourseLibraryRow extends StatelessWidget {
  const CourseLibraryRow({
    super.key,
    required this.course,
    required this.compact,
    required this.maintainer,
    this.mediaStore,
    this.trailing,
    this.supplementalAction,
    this.onTap,
    this.hiddenInLearner = false,
    this.foreground,
  });

  final Course course;
  final bool compact;
  final String maintainer;
  final CourseMediaStore? mediaStore;
  final Widget? trailing;
  final Widget? supplementalAction;
  final VoidCallback? onTap;
  final bool hiddenInLearner;
  final Color? foreground;

  static bool isUnavailable(Course course) =>
      CourseLibraryFilter.isUnavailable(course);

  TextStyle _titleStyle(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontWeight: FontWeight.bold,
      color:
          foreground ??
          switch (course.originType) {
            CourseOriginType.bundledOfficial =>
              dark ? Colors.white : Colors.black,
            CourseOriginType.externalOfficial => Colors.purple,
            CourseOriginType.custom => Colors.orange,
          },
      backgroundColor:
          foreground == null &&
              course.originType == CourseOriginType.bundledOfficial &&
              dark
          ? Colors.black
          : null,
    );
  }

  void _showArtworkPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final viewport = MediaQuery.sizeOf(dialogContext);
        final artworkSize = math.max(
          96.0,
          math.min(520.0, math.min(viewport.width - 80, viewport.height - 180)),
        );
        return Dialog(
          key: ValueKey('course-artwork-preview-${course.courseId}'),
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: artworkSize,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(dialogContext).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('course-artwork-preview-close'),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CourseArtwork(
                  course: course,
                  size: artworkSize,
                  coverFit: BoxFit.contain,
                  mediaStore: mediaStore,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 480;
      final version = CourseLibraryPresentation.version(course);
      final duration = CourseLibraryPresentation.duration(course);
      final edited = CourseLibraryPresentation.lastEdited(course);
      final lastEdited = edited == null
          ? 'Unknown'
          : MaterialLocalizations.of(context).formatShortDate(edited.toLocal());
      final hasDraft = CourseDraftStatus.courseHasDraft(course);
      final unpublished = !course.publicationState.isPublished;
      final verification = PublicationService.requiresPublisherVerification(
        course,
      );
      final details = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            key: ValueKey('device-course-title-${course.courseId}'),
            style: _titleStyle(context),
          ),
          const SizedBox(height: 2),
          DefaultTextStyle.merge(
            style: TextStyle(
              color:
                  foreground ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${course.sourceLanguage} → ${course.targetLanguage}'),
                if (!compact) ...[
                  if (version != null) Text('Version: $version'),
                  Text('Last edited: $lastEdited'),
                  Text('Maintainer: $maintainer'),
                  if (duration != null) Text('Duration: $duration'),
                ],
              ],
            ),
          ),
          if (hasDraft || unpublished || verification || hiddenInLearner)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (hasDraft) const _StatusBadge('Draft'),
                  if (unpublished) const _StatusBadge('Unpublished'),
                  if (verification) const _StatusBadge('Verification required'),
                  if (hiddenInLearner) const _StatusBadge('Hidden in Learner'),
                ],
              ),
            ),
          if (narrow && supplementalAction != null) ...[
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: supplementalAction),
          ],
        ],
      );
      return InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color:
                    foreground?.withValues(alpha: 0.4) ??
                    Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: 'Enlarge Course image',
                  child: InkWell(
                    key: ValueKey('course-artwork-open-${course.courseId}'),
                    onTap: () => _showArtworkPreview(context),
                    borderRadius: BorderRadius.circular(8),
                    child: CourseArtwork(
                      course: course,
                      size: compact ? 40 : 64,
                      mediaStore: mediaStore,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: details),
                if (!narrow && supplementalAction != null) supplementalAction!,
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade300
        : Colors.blue.shade700;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: blue),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(label, style: TextStyle(fontSize: 11, color: blue)),
      ),
    );
  }
}
