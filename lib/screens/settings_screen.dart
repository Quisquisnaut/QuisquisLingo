import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/course_models.dart';
import '../services/settings_service.dart';
import '../services/diagnostic_log_service.dart';
import '../services/sound_effect_service.dart';
import '../services/crash_log_service.dart';
import 'course_projects_screen.dart';
import 'tts_settings_screen.dart';
import 'do_not_disturb_settings_screen.dart';
import 'user_data_settings_screen.dart';
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
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _versionLabel = 'QuisquisLingo';
  final _settings = SettingsService();
  final _logs = DiagnosticLogService();
  late final SoundEffectService _sounds;
  late final bool _ownsSounds;
  bool _loading = true;
  bool _editorUnlocked = false;
  bool _iddqdMode = false;
  bool _hasDiagnosticLog = false;
  String? _diagnosticExportPath;
  String? _crashLogPath;
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
    await CrashLogService.instance.recordDebugEvent('Settings: _load started');
    try {
      final hasDiagnosticLog = await _logs.hasEntries();
      final diagnosticExportPath = await _logs.exportPath();
      final crashLogPath = CrashLogService.instance.crashLogPath;
      final editorUnlocked = await _settings.isCourseEditorUnlocked();
      final iddqdMode = await _settings.isIddqdModeEnabled(widget.course.courseId);
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _hasDiagnosticLog = hasDiagnosticLog;
        _diagnosticExportPath = diagnosticExportPath;
        _crashLogPath = crashLogPath;
        _editorUnlocked = editorUnlocked;
        _iddqdMode = iddqdMode;
        _versionLabel = 'QuisquisLingo v${info.version}';
        _loading = false;
      });
    } catch (error, stackTrace) {
      await CrashLogService.instance.record(
        error,
        stackTrace,
        source: 'SettingsScreen._load',
      );
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(duration: Duration(seconds: 8), 
            content: Text('Some settings could not be loaded. Safe defaults are being used.'),
          ),
        );
      });
    }
  }

  Future<void> _clearLog() async {
    await _logs.clear();
    if (!mounted) return;
    setState(() => _hasDiagnosticLog = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(duration: Duration(seconds: 8), content: Text('Diagnostic log cleared.')),
    );
  }

  Future<void> _exportDiagnosticLog() async {
    final path = await _logs.exportToFile();
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text('The Diagnostic Log is empty or could not be exported.'),
        ),
      );
      return;
    }
    setState(() {
      _hasDiagnosticLog = true;
      _diagnosticExportPath = path;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('Diagnostic Log exported to $path'),
      ),
    );
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
        const SnackBar(duration: Duration(seconds: 8), content: Text('Course Editor unlocked.')),
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
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Settings'),
                SizedBox(width: 7),
                Tooltip(
                  message: 'Flag Game',
                  child: Icon(Icons.outlined_flag, size: 18),
                ),
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
                  subtitle: const Text('Learning rules, metrics and app behavior.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const InfoScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: const Text('TTS Settings'),
                  subtitle: const Text(
                    'Text-to-speech, skip TTS exercises, voice preference and Test Voice.',
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
                if (_editorUnlocked)
                  ListTile(
                    leading: const Icon(Icons.edit_note_outlined),
                    title: const Text('Course Editor'),
                    subtitle: const Text('Author courses, generate exercise sets and run Course Audit.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CourseProjectsScreen(currentCourse: widget.course)),
                    ),
                  ),
                SwitchListTile(
                  secondary: const Icon(Icons.lock_open_outlined),
                  title: const Text('IDDQD Mode (you can walk through locks)'),
                  subtitle: const Text('Stored separately for this learner and this course. Real progress and genuine Lesson unlocks continue to be recorded.'),
                  value: _iddqdMode,
                  onChanged: (value) async {
                    await _settings.setIddqdModeEnabled(widget.course.courseId, value);
                    if (!mounted) return;
                    setState(() => _iddqdMode = value);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_shared_outlined),
                  title: const Text('User Data'),
                  subtitle: const Text(
                    'Export or import learner data, or reset the current course progress.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserDataSettingsScreen(course: widget.course),
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: const Text('Crash Log'),
                  subtitle: Text(
                    'Automatic log created at app startup and updated after uncaught errors.\n'
                    'Saved at: ${_crashLogPath ?? 'Path unavailable on this platform.'}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Diagnostic Log'),
                  subtitle: Text(
                    'Internal technical-event log for troubleshooting. It is not a crash file.\n'
                    'Export location: ${_diagnosticExportPath ?? 'Unavailable on this platform.'}',
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'Export Diagnostic Log',
                        onPressed: _hasDiagnosticLog ? _exportDiagnosticLog : null,
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                      IconButton(
                        tooltip: 'Clear Diagnostic Log',
                        onPressed: _hasDiagnosticLog ? _clearLog : null,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Current version'),
                  subtitle: Text(_versionLabel),
                  onTap: _tapVersion,
                ),
                ListTile(
                  leading: const Icon(Icons.system_update_alt),
                  title: const Text('Update'),
                  subtitle: const Text('Check GitHub for a newer QuisquisLingo release and manage automatic checks.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UpdateSettingsScreen()),
                  ),
                ),
              ],
            ),
    );
  }
}
