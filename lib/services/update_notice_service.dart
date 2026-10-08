import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';
import 'update_service.dart';

/// Holds the result of the startup update check and decides who should be told.
///
/// The check itself runs once per launch and is not tied to any learner. The
/// notice is shown to each learner separately, once per day per release: a
/// learner who chooses "Not today" is reminded again the following day, while
/// other learners on the same device still see it today.
class UpdateNoticeService {
  static const _keyBase = 'update_notice_last_shown';

  static UpdateRelease? _pending;

  /// Bumped whenever the pending release changes so an open Home screen can
  /// react to a check that finishes after the learner is already active.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static UpdateRelease? get pending => _pending;

  static void setPending(UpdateRelease? release) {
    _pending = release;
    changes.value++;
  }

  final ProfileService _profiles;
  final DateTime Function() _now;

  UpdateNoticeService({ProfileService? profiles, DateTime Function()? now})
    : _profiles = profiles ?? ProfileService(),
      _now = now ?? DateTime.now;

  String _stamp(UpdateRelease release) {
    final n = _now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}|${release.version}';
  }

  /// The pending release when the active learner has not yet been told about
  /// it today, otherwise null. Nothing is recorded until [markShown].
  Future<UpdateRelease?> dueForActiveLearner() async {
    final release = _pending;
    if (release == null) return null;
    final activeId = await _profiles.getActiveProfileId();
    if (activeId == null) return null;
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(
      _profiles.keyForProfileId(activeId, _keyBase),
    );
    return stored == _stamp(release) ? null : release;
  }

  /// Records that the active learner has now been told about [release] today.
  Future<void> markShown(UpdateRelease release) async {
    final activeId = await _profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      _profiles.keyForProfileId(activeId, _keyBase),
      _stamp(release),
    );
  }

  static Future<void> show(
    BuildContext context,
    UpdateRelease release,
    UpdateService updates,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QuisquisLingo update available'),
        content: Text(
          'Version ${release.version} is available. '
          'Open Settings > Update for release notes and installation instructions, '
          'or open the official GitHub release page now.\n\n'
          'If you choose Not today, this reminder appears again tomorrow.',
        ),
        actions: [
          TextButton(
            key: const Key('update-notice-not-today'),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not today'),
          ),
          FilledButton(
            key: const Key('update-notice-open'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await updates.openRelease(release);
            },
            child: const Text('Open GitHub release'),
          ),
        ],
      ),
    );
  }
}
