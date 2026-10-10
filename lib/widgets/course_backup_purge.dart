import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/app_errors.dart';
import '../services/course_backup_retention.dart';
import '../services/course_backup_service.dart';
import '../services/diagnostic_log_service.dart';
import 'reported_action.dart';

/// After a save, asks whether to delete a custom Course's older backups
/// (Build 270 Revision 9, owner decisions of 10 October 2026): only when
/// Course Info sets how many backups this device keeps and the Course has
/// more; nothing is deleted without the learner's yes, and Not now asks
/// again after the next save. To stop the question, the learner keeps every
/// backup in Course Info.
abstract final class CourseBackupPurge {
  static Future<void> offer(
    BuildContext context,
    Course course, {
    required CourseBackupService backups,
    CourseBackupRetention? retention,
  }) async {
    if (course.originType.isOfficial) return;
    List<CourseBackupRecord> older;
    int keep;
    try {
      final kept = await (retention ?? CourseBackupRetention()).keepFor(
        course.courseId,
      );
      if (kept == null) return;
      keep = kept;
      older = await backups.olderThanNewest(course.courseId, keep);
    } catch (error) {
      // Nothing to offer when the backups cannot be read now (Android 7-10
      // without the storage permission has said so already).
      await DiagnosticLogService().log(
        AppErrorCode.localStorageError,
        context:
            'Older Course backups could not be listed after a save: '
            '${readableError(error)}',
      );
      return;
    }
    if (older.isEmpty || !context.mounted) return;
    final count = older.length;
    final noun = count == 1 ? 'backup' : 'backups';
    final delete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('course-backup-purge'),
        title: const Text('Delete older backups?'),
        content: Text(
          '“${course.title}” keeps its newest $keep backups on this device '
          '(Course Info). Delete the $count older $noun? The pictures and '
          'recordings that only they hold go too. This cannot be undone.\n\n'
          'Not now asks again after the next save; to stop the question, '
          'keep every backup in Course Info.',
        ),
        actions: [
          TextButton(
            key: const Key('course-backup-purge-not-now'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const Key('course-backup-purge-delete'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete $count $noun'),
          ),
        ],
      ),
    );
    if (delete != true || !context.mounted) return;
    final deleted = await runReported(
      context,
      'Deleting older backups',
      () => backups.deleteBackups(course.courseId, older),
    );
    if (deleted == null || !context.mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        key: const Key('course-backup-purge-result'),
        content: Text(
          'Deleted $deleted older ${deleted == 1 ? 'backup' : 'backups'} '
          'of “${course.title}”.',
        ),
      ),
    );
  }
}
