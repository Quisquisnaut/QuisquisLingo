import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// The one-time introduction a creator sees the first time the Exercise
/// Editor (preset form or canonical editor) opens in a Course: two ways to
/// create exercises (owner request, Build 256 Revision 3 follow-up).
///
/// Stored as a one-time notice keyed by Course, so "Show one-time notices
/// again" in Settings brings it back.
abstract final class ExerciseEditorIntro {
  /// Test seam: the suite turns the introduction off in
  /// `test/flutter_test_config.dart`, because a modal dialog on the first
  /// open would block every editor test; the intro's own test turns it on.
  static bool enabled = true;

  static String noticeId(String courseId) => 'exercise_editor_intro_$courseId';

  static const title = 'Two ways to create an exercise';

  static const presetsText =
      'Presets are ready forms for the most common exercise types: pick one, '
      'fill in a few fields, save. Every preset writes ordinary exercise data.';

  static const canonicalText =
      'The canonical editor gives you the basic structure of any exercise '
      'directly: primitive, options, prompt, items, targets, evaluation. '
      'Powerful, sometimes complex. An exercise that no preset represents '
      'opens there.';

  /// Shows the introduction once per Course; a null [courseId] (standalone
  /// forms) shows nothing.
  static Future<void> showIfNeeded(
    BuildContext context, {
    required String? courseId,
    SettingsService? settings,
  }) async {
    if (!enabled || courseId == null || courseId.isEmpty) return;
    final service = settings ?? SettingsService();
    final id = noticeId(courseId);
    if (await service.hasSeenOneTimeNotice(id)) return;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('exercise-editor-intro'),
        title: const Text(title),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Presets: New Exercise',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(presetsText),
              SizedBox(height: 12),
              Text(
                'Canonical: New Exercise › Canonical editor',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(canonicalText),
              SizedBox(height: 12),
              Text('Editor Help explains both, with examples.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            key: const Key('exercise-editor-intro-ok'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    await service.markOneTimeNoticeSeen(id);
  }
}
