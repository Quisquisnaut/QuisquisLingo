import 'package:flutter/material.dart';

import '../services/crash_log_service.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final soundEffectsEnabled = await _settings.areSoundEffectsEnabled();
      final animationsEnabled = await _settings.areAnimationsEnabled();
      if (!mounted) return;
      setState(() {
        _soundEffectsEnabled = soundEffectsEnabled;
        _animationsEnabled = animationsEnabled;
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

  Future<void> _showOneTimeNoticesAgain(bool value) async {
    if (!value) return;
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
                    'Show decorative animations throughout QuisquisLingo, including startup and course-entry animations.',
                  ),
                  value: _animationsEnabled,
                  onChanged: _setAnimations,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Show one-time notices again'),
                  subtitle: const Text(
                    'Reset notices that normally appear only once, including the version Welcome. This does not reset Guidebooks or learning progress.',
                  ),
                  value: false,
                  onChanged: _showOneTimeNoticesAgain,
                ),
              ],
            ),
    );
  }
}
