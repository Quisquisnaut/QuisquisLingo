import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_metadata.dart';
import 'profile_service.dart';
import 'settings_service.dart';

/// Android (Build 270 Revision 10, owner decisions of 10 October 2026): QQL
/// has no internet permission there, so it never checks GitHub for a newer
/// release. Instead each learner is reminded, at most every [interval], to
/// check for a newer QuisquisLingo where they got it (the app is not in a
/// store yet). The first reminder comes [interval] after the learner's
/// first start-up with this build; Update › Check automatically at startup
/// (an admin setting) turns the reminders off.
class UpdateReminder {
  static const interval = Duration(days: 14);
  static const keyBase = 'update_reminder_last_shown';

  /// Whether this system gets reminders instead of the update check; a test
  /// seam.
  static bool Function() applies = () => !kIsWeb && Platform.isAndroid;

  UpdateReminder({
    ProfileService? profiles,
    SettingsService? settings,
    DateTime Function()? now,
  }) : _profiles = profiles ?? ProfileService(),
       _settings = settings ?? SettingsService(),
       _now = now ?? DateTime.now;

  final ProfileService _profiles;
  final SettingsService _settings;
  final DateTime Function() _now;

  /// Whether the active learner should be reminded now. The first call for
  /// a learner only starts the count: nothing is shown right after install.
  Future<bool> dueForActiveLearner() async {
    if (!applies()) return false;
    if (!await _settings.isAutomaticUpdateCheckEnabled()) return false;
    final activeId = await _profiles.getActiveProfileId();
    if (activeId == null) return false;
    final preferences = await SharedPreferences.getInstance();
    final key = _profiles.keyForProfileId(activeId, keyBase);
    final last = DateTime.tryParse(preferences.getString(key) ?? '');
    final now = _now().toUtc();
    if (last == null) {
      await preferences.setString(key, now.toIso8601String());
      return false;
    }
    return !now.isBefore(last.add(interval));
  }

  /// Records that the active learner has just been reminded.
  Future<void> markShown() async {
    final activeId = await _profiles.getActiveProfileId();
    if (activeId == null) return;
    await (await SharedPreferences.getInstance()).setString(
      _profiles.keyForProfileId(activeId, keyBase),
      _now().toUtc().toIso8601String(),
    );
  }

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('update-reminder'),
      title: const Text('Check for a newer QuisquisLingo'),
      content: Text(
        'On Android QuisquisLingo does not use the internet, so it cannot '
        'look for updates itself. Check where you got it whether a newer '
        'version is out: this one is ${AppMetadata.technicalVersion}.\n\n'
        'This reminder comes back every two weeks. An admin can turn it off '
        'in Settings › Update.',
      ),
      actions: [
        FilledButton(
          key: const Key('update-reminder-ok'),
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
