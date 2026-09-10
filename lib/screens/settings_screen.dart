import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/app_metadata.dart';
import '../services/settings_service.dart';
import '../services/sound_effect_service.dart';
import 'tts_settings_screen.dart';
import 'do_not_disturb_settings_screen.dart';
import 'debug_screen.dart';
import 'info_screen.dart';
import 'profile_screen.dart';
import 'update_settings_screen.dart';
import 'flag_game_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Course course;
  final Future<void> Function(BuildContext context) onManageLearners;
  final SoundEffectService? soundEffectService;
  final WidgetBuilder? flagGameBuilder;

  const SettingsScreen({
    super.key,
    required this.course,
    required this.onManageLearners,
    this.soundEffectService,
    this.flagGameBuilder,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  late final SoundEffectService _sounds;
  late final bool _ownsSounds;
  bool _loading = true;
  bool _editorUnlocked = false;
  int _versionTapCount = 0;
  int _flagGameTapCount = 0;
  Timer? _flagGameTapResetTimer;

  @override
  void initState() {
    super.initState();
    _ownsSounds = widget.soundEffectService == null;
    _sounds = widget.soundEffectService ?? SoundEffectService();
    _load();
  }

  @override
  void dispose() {
    _flagGameTapResetTimer?.cancel();
    if (_ownsSounds) unawaited(_sounds.dispose());
    super.dispose();
  }

  Future<void> _tapFlagGameTrigger() async {
    _flagGameTapResetTimer?.cancel();
    _flagGameTapCount++;
    if (_flagGameTapCount < 5) {
      _flagGameTapResetTimer = Timer(const Duration(seconds: 3), () {
        _flagGameTapCount = 0;
      });
      return;
    }
    _flagGameTapCount = 0;
    await _sounds.playSuspense();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: widget.flagGameBuilder ?? (_) => const FlagGameScreen(),
      ),
    );
  }

  Future<void> _load() async {
    try {
      final editorUnlocked = await _settings.isCourseEditorUnlocked();
      if (!mounted) return;
      setState(() {
        _editorUnlocked = editorUnlocked;
        _versionTapCount = 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionTapCount = 0;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'Some settings could not be loaded. Safe defaults are being used.',
            ),
          ),
        );
      });
    }
  }

  Future<void> _tapVersion() async {
    // Deliberately no timeout: ten taps may be made at a normal pace.
    _versionTapCount++;
    if (_versionTapCount >= 10 && !_editorUnlocked) {
      await _settings.setCourseEditorUnlocked(true);
      final playSound = await _settings.areSoundEffectsEnabled();
      if (playSound) await _sounds.playDuelWin();
      if (!mounted) return;
      setState(() => _editorUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('Course Manager unlocked.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          key: const Key('settings-flag-game-trigger'),
          behavior: HitTestBehavior.opaque,
          onTap: _tapFlagGameTrigger,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Settings'),
                SizedBox(width: 7),
                _WavingFlagIcon(),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Profile'),
                  subtitle: const Text(
                    'Learner identity, avatar, profiles and gamification.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          course: widget.course,
                          onManageLearners: widget.onManageLearners,
                        ),
                      ),
                    );
                    if (mounted) await _load();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('App Info'),
                  subtitle: const Text(
                    'Learning rules, metrics and app behavior.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const InfoScreen())),
                ),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: const Text('Audio Settings'),
                  subtitle: const Text(
                    'Learner audio exercises, text-to-speech and voice preference.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TtsSettingsScreen(course: widget.course),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.do_not_disturb_on_outlined),
                  title: const Text('Do Not Disturb'),
                  subtitle: const Text(
                    'Sound effects, animations and one-time notices.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DoNotDisturbSettingsScreen(),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Debug'),
                  subtitle: const Text(
                    'Crash Log and Diagnostic Log troubleshooting tools.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DebugScreen()),
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const Key('settings-version-build-area'),
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version and Build'),
                  subtitle: const Text(AppMetadata.displayLabel),
                  onTap: _tapVersion,
                ),
                ListTile(
                  leading: const Icon(Icons.system_update_alt),
                  title: const Text('Update'),
                  subtitle: const Text(
                    'Check GitHub for a newer QuisquisLingo release and manage automatic checks.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UpdateSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _WavingFlagIcon extends StatefulWidget {
  const _WavingFlagIcon();

  @override
  State<_WavingFlagIcon> createState() => _WavingFlagIconState();
}

class _WavingFlagIconState extends State<_WavingFlagIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 0.5,
    );
    _turns = Tween<double>(
      begin: -0.018,
      end: 0.018,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startWaving(PointerEnterEvent _) {
    _controller.repeat(reverse: true);
  }

  void _stopWaving(PointerExitEvent _) {
    _controller.stop();
    _controller.animateTo(0.5, duration: const Duration(milliseconds: 180));
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tap tap... Flag Game',
      child: MouseRegion(
        onEnter: _startWaving,
        onExit: _stopWaving,
        child: RotationTransition(
          key: const Key('settings-flag-wave'),
          turns: _turns,
          alignment: Alignment.bottomLeft,
          child: const Icon(Icons.outlined_flag, size: 18),
        ),
      ),
    );
  }
}
