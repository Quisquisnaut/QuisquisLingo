import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../services/settings_service.dart';

/// Build 270 Revision 8 (owner requests of 10 October 2026): on a device with
/// more than one learner, each learner is told once what the Access PIN can
/// and cannot do. The PIN stops mistakes and casual access; it is not a lock
/// against someone determined to get past it.
abstract final class SharedDeviceNotice {
  /// One of the learner's own one-time notices
  /// (`learner_<id>_one_time_notice_seen_shared_device`), so "Show one-time
  /// notices again" shows it again.
  static const noticeId = 'shared_device';

  /// Tests that are not about this notice turn it off
  /// (`test/flutter_test_config.dart`).
  @visibleForTesting
  static bool enabled = true;

  static const title = 'A shared device';
  static const body =
      'More than one learner uses QuisquisLingo on this device. A shared '
      'device cannot fully protect each learner from what the others do: '
      'the Access PIN prevents mistakes and casual access, but it cannot '
      'stop someone determined to get around it, for example by changing '
      "QuisquisLingo's files. Keep anything private off a shared device.";

  /// Shows the notice to the active learner when the device has two or more
  /// learners and this learner has not seen it. Never throws: a notice must
  /// not stop start-up.
  static Future<void> showIfNeeded(
    BuildContext context, {
    ProfileService? profiles,
    SettingsService? settings,
  }) async {
    if (!enabled) return;
    try {
      final notices = settings ?? SettingsService();
      // Null without an active learner: nobody to tell.
      if (await notices.hasSeenLearnerOneTimeNotice(noticeId) != false) {
        return;
      }
      final learners = await (profiles ?? ProfileService()).getProfileRecords();
      if (learners.length < 2 || !context.mounted) return;
      await notices.markLearnerOneTimeNoticeSeen(noticeId);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('shared-device-notice'),
          title: const Text(title),
          content: const Text(body),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      // The notice is information only.
    }
  }
}
