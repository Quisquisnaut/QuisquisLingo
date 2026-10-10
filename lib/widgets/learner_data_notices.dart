import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_errors.dart';
import '../services/crash_log_service.dart';
import '../services/diagnostic_log_service.dart';
import '../services/storage/atomic_preferences_store.dart';
import 'learner_navigation.dart';

/// What the learner hears about the learner-data file (Build 270 Revision 0):
/// a dialog after start-up when the file could not be read, a SnackBar when a
/// change could not be saved. Both are also written to the logs.
abstract final class LearnerDataNotices {
  /// Several failed writes in a row show one SnackBar.
  static const writeNoticeInterval = Duration(minutes: 1);

  static DateTime? _lastWriteNotice;
  static LearnerDataProblem? _pendingRecovery;
  static Future<void>? _showing;

  /// The start-up problem waiting for its dialog.
  static LearnerDataProblem? get pendingRecovery => _pendingRecovery;

  @visibleForTesting
  static void debugReset() {
    _lastWriteNotice = null;
    _pendingRecovery = null;
    _showing = null;
  }

  /// [AtomicPreferencesStore.onProblem].
  static void report(LearnerDataProblem problem) {
    unawaited(_log(problem));
    switch (problem.kind) {
      case LearnerDataProblemKind.restoredLastGood:
      case LearnerDataProblemKind.startedEmpty:
        _pendingRecovery = problem;
      case LearnerDataProblemKind.writeFailed:
        _showWriteFailure();
    }
  }

  static Future<void> _log(LearnerDataProblem problem) async {
    final context = switch (problem.kind) {
      LearnerDataProblemKind.restoredLastGood =>
        'The learner-data file could not be read; the last good copy '
            '(${problem.lastGoodSavedAt?.toIso8601String() ?? 'date unknown'}) '
            'was used. Damaged file kept: ${_name(problem.damagedCopy)}.',
      LearnerDataProblemKind.startedEmpty =>
        'The learner-data file could not be read and no earlier copy '
            'exists; QQL started without learner data. Damaged file kept: '
            '${_name(problem.damagedCopy)}.',
      LearnerDataProblemKind.writeFailed =>
        'A change to the learner-data file could not be saved.',
    };
    try {
      await CrashLogService.instance.record(
        problem.error ?? context,
        StackTrace.current,
        source: 'learner data: $context',
      );
      // Before the Diagnostic Log has its own file it is itself learner data:
      // logging a failed write there would only fail again.
      if (DiagnosticLogService.logFile != null) {
        await DiagnosticLogService().log(
          AppErrorCode.localStorageError,
          context: context,
          exception: problem.error,
        );
      }
    } catch (_) {
      // Reporting must never fail the write it reports.
    }
  }

  /// File names only, as everywhere in the logs.
  static String _name(String? path) {
    if (path == null) return 'none';
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.last;
  }

  static void _showWriteFailure() {
    final now = DateTime.now();
    final last = _lastWriteNotice;
    if (last != null && now.difference(last) < writeNoticeInterval) return;
    final context = learnerNavigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _lastWriteNotice = now;
    messenger.showSnackBar(
      const SnackBar(
        key: Key('learner-data-write-failed'),
        duration: Duration(seconds: 10),
        content: Text(
          'QuisquisLingo could not save your latest progress and settings. '
          'Free some disk space, or close programs that may be using its '
          'files: QQL tries again with your next change.',
        ),
      ),
    );
  }

  /// Shows the start-up problem once, if there is one. The app calls it
  /// after its first frame and the learner page before its own start-up
  /// dialogs, which so wait until this one is closed instead of covering it.
  static Future<void> showPendingRecovery() {
    final running = _showing;
    if (running != null) return running;
    final problem = _pendingRecovery;
    final context = learnerNavigatorKey.currentContext;
    if (problem == null || context == null || !context.mounted) {
      return Future<void>.value();
    }
    _pendingRecovery = null;
    return _showing = _showRecovery(
      context,
      problem,
    ).whenComplete(() => _showing = null);
  }

  static Future<void> _showRecovery(
    BuildContext context,
    LearnerDataProblem problem,
  ) async {
    final kept = problem.damagedCopy == null
        ? ''
        : ' The unreadable file was kept as ${_name(problem.damagedCopy)} in '
              'QQL\'s private folder.';
    final (title, body) = switch (problem.kind) {
      LearnerDataProblemKind.restoredLastGood => (
        'Learner data restored',
        'QuisquisLingo could not read its learner-data file, so it used the '
            'copy saved when QQL last started'
            '${problem.lastGoodSavedAt == null ? '' : ' (${_when(problem.lastGoodSavedAt!)})'}. '
            'Progress made after that may be missing.$kept',
      ),
      _ => (
        'Learner data could not be read',
        'QuisquisLingo could not read its learner-data file and found no '
            'earlier copy, so it started without learner profiles and '
            'progress. Courses you made are not affected. If you have a '
            'learner backup, restore it in Profile › User Data.$kept',
      ),
    };
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('learner-data-recovery'),
        title: Text(title),
        content: Text(body),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String _when(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
