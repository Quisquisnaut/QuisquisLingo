import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_errors.dart';
import '../services/diagnostic_log_service.dart';
import 'learner_navigation.dart';

/// Build 270 Revision 9 (owner decision of 10 October 2026): a Course change
/// saved without its backup, because QQL may not use the Backups folder
/// (Android 7-10 with the storage permission refused), is told, not hidden.
abstract final class CourseBackupNotice {
  static void report(String folder) {
    unawaited(
      DiagnosticLogService().log(
        AppErrorCode.localStorageError,
        context:
            'A Course change was saved without its backup: QQL may not use '
            '$folder.',
      ),
    );
    final context = learnerNavigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        key: const Key('course-backup-skipped'),
        duration: const Duration(seconds: 10),
        content: Text(
          'Saved without a backup: QuisquisLingo may not use $folder. To keep '
          'backups, allow storage for QuisquisLingo in Android Settings › '
          'Apps › QuisquisLingo › Permissions.',
        ),
      ),
    );
  }
}
