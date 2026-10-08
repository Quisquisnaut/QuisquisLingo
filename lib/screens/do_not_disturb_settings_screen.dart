import 'package:flutter/material.dart';

import '../services/crash_log_service.dart';
import '../services/profile_service.dart';
import '../services/settings_service.dart';

class DoNotDisturbSettingsScreen extends StatefulWidget {
  const DoNotDisturbSettingsScreen({super.key});

  @override
  State<DoNotDisturbSettingsScreen> createState() =>
      _DoNotDisturbSettingsScreenState();
}

class _DoNotDisturbSettingsScreenState
    extends State<DoNotDisturbSettingsScreen> {
  final _settings = SettingsService();

  bool _loading = true;
  bool _soundEffectsEnabled = true;
  bool _animationsEnabled = true;
  CourseEditorMode _openingMode = CourseEditorMode.viewOnly;
  bool _hasLearner = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final soundEffectsEnabled = await _settings.areSoundEffectsEnabled();
      final animationsEnabled = await _settings.areAnimationsEnabled();
      final hasLearner = await ProfileService().getActiveProfileId() != null;
      final openingMode = await _settings.getCourseEditorOpeningMode();
      if (!mounted) return;
      setState(() {
        _soundEffectsEnabled = soundEffectsEnabled;
        _animationsEnabled = animationsEnabled;
        _hasLearner = hasLearner;
        _openingMode = openingMode;
        _loading = false;
      });
    } catch (error, stackTrace) {
      await CrashLogService.instance.record(
        error,
        stackTrace,
        source: 'DoNotDisturbSettingsScreen._load',
      );
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'Some Do Not Disturb settings could not be loaded. Safe defaults are being used.',
            ),
          ),
        );
      });
    }
  }

  Future<void> _setSoundEffects(bool value) async {
    await _settings.setSoundEffectsEnabled(value);
    if (mounted) setState(() => _soundEffectsEnabled = value);
  }

  Future<void> _setAnimations(bool value) async {
    await _settings.setAnimationsEnabled(value);
    if (mounted) setState(() => _animationsEnabled = value);
  }

  Future<void> _setOpeningMode(CourseEditorMode? mode) async {
    if (mode == null) return;
    await _settings.setCourseEditorOpeningMode(mode);
    if (mounted) setState(() => _openingMode = mode);
  }

  Future<void> _showOneTimeNoticesAgain() async {
    await _settings.resetOneTimeNotices();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text('One-time notices will be shown again when relevant.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Do Not Disturb')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SwitchListTile(
                  title: const Text('Sound effects'),
                  subtitle: const Text(
                    'Play short result sounds such as Duel wins and newly earned laurel crowns.',
                  ),
                  value: _soundEffectsEnabled,
                  onChanged: _setSoundEffects,
                ),
                SwitchListTile(
                  title: const Text('Animations'),
                  subtitle: const Text(
                    'Show decorative animations throughout QuisquisLingo, including startup and course-entry animations and the confetti for the weekly goal, a won Duel and a passed Test.',
                  ),
                  value: _animationsEnabled,
                  onChanged: _setAnimations,
                ),
                // Per learner (Build 261 Revision 1, owner decision of 1
                // October 2026).
                ListTile(
                  title: const Text('Course Editor opening mode'),
                  subtitle: Text(
                    _hasLearner
                        ? 'How a Course opens in the Course Editor the first time you open it; then it remembers its own mode. Edit opens as View only where you may not edit.'
                        : 'Choose a learner profile first.',
                  ),
                  trailing: DropdownButton<CourseEditorMode>(
                    key: const Key('course-editor-opening-mode'),
                    value: _openingMode,
                    onChanged: _hasLearner ? _setOpeningMode : null,
                    items: [
                      for (final mode in CourseEditorMode.values)
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Show one-time notices again'),
                  subtitle: const Text(
                    'Reset notices that normally appear only once, including the Welcome Wizard, the version Welcome and Course Editor View notice. This does not reset the Course Editor lock, Guidebooks or learning progress.',
                  ),
                  trailing: const Icon(Icons.replay),
                  onTap: _showOneTimeNoticesAgain,
                ),
              ],
            ),
    );
  }
}
