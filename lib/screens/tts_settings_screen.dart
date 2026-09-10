import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/crash_log_service.dart';
import '../services/course_language_resolver.dart';
import '../services/settings_service.dart';
import '../services/tts_cache_service.dart';

class TtsSettingsScreen extends StatefulWidget {
  final Course course;
  final TtsCacheService? ttsService;

  const TtsSettingsScreen({super.key, required this.course, this.ttsService});

  @override
  State<TtsSettingsScreen> createState() => _TtsSettingsScreenState();
}

class _TtsSettingsScreenState extends State<TtsSettingsScreen> {
  final _settings = SettingsService();
  late final TtsCacheService _tts;

  bool _loading = true;
  bool _audioExercisesEnabled = false;
  bool _ttsEnabled = false;
  String _voicePreference = 'system';

  @override
  void initState() {
    super.initState();
    _tts = widget.ttsService ?? TtsCacheService();
    _load();
  }

  Future<void> _load() async {
    try {
      final ttsEnabled = await _settings.isTtsEnabled();
      final audioExercisesEnabled = await _settings.areAudioExercisesEnabled();
      final voicePreference = await _settings.getTtsVoicePreference();
      if (!mounted) return;
      setState(() {
        _ttsEnabled = ttsEnabled;
        _audioExercisesEnabled = audioExercisesEnabled;
        _voicePreference = voicePreference;
        _loading = false;
      });
    } catch (error, stackTrace) {
      await CrashLogService.instance.record(
        error,
        stackTrace,
        source: 'TtsSettingsScreen._load',
      );
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text(
              'Some Audio Settings could not be loaded. Safe defaults are being used.',
            ),
          ),
        );
      });
    }
  }

  Future<void> _setTts(bool value) async {
    await _settings.setTtsEnabled(value);
    if (mounted) setState(() => _ttsEnabled = value);
  }

  Future<void> _setAudioExercisesEnabled(bool value) async {
    await _settings.setAudioExercisesEnabled(value);
    if (mounted) setState(() => _audioExercisesEnabled = value);
  }

  Future<void> _setVoice(String value) async {
    await _settings.setTtsVoicePreference(value);
    if (mounted) setState(() => _voicePreference = value);
  }

  Future<void> _testVoice() async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _TtsVoiceTestDialog(),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    final language = CourseLanguageResolver.learning(widget.course);
    final ok = await _tts.speak(
      text: text,
      language: language.code ?? '',
      learningLanguage: widget.course.learningLanguage,
      targetLanguage: widget.course.targetLanguage,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          ok
              ? 'TTS test started.'
              : _tts.lastFailureDescription ??
                    'No compatible voice could be played for ${widget.course.targetLanguage}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = CourseLanguageResolver.learning(widget.course);
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SwitchListTile(
                  title: const Text('Enable Audio Exercises'),
                  subtitle: const Text(
                    'Allow learner exercises that use Text-to-speech or Recorded MP3 audio.',
                  ),
                  value: _audioExercisesEnabled,
                  onChanged: _setAudioExercisesEnabled,
                ),
                SwitchListTile(
                  title: const Text('Text-to-speech'),
                  subtitle: const Text(
                    'Play spoken course audio. Windows uses System.Speech; Linux uses eSpeak NG/eSpeak; other platforms use the platform TTS engine.',
                  ),
                  value: _ttsEnabled,
                  onChanged: _setTts,
                ),
                const Divider(),
                const ListTile(
                  title: Text('TTS voice'),
                  subtitle: Text(
                    'Female/Male is a preference. If unavailable, QuisquisLingo uses another voice in the same language.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _voicePreference,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Voice preference',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text('System default'),
                      ),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                    ],
                    onChanged: _ttsEnabled
                        ? (value) {
                            if (value != null) _setVoice(value);
                          }
                        : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: const Text('Test Voice'),
                  subtitle: Text(language.displayLabel),
                  onTap: _ttsEnabled ? _testVoice : null,
                ),
              ],
            ),
    );
  }
}

class _TtsVoiceTestDialog extends StatefulWidget {
  const _TtsVoiceTestDialog();

  @override
  State<_TtsVoiceTestDialog> createState() => _TtsVoiceTestDialogState();
}

class _TtsVoiceTestDialogState extends State<_TtsVoiceTestDialog> {
  final _controller = TextEditingController();
  bool _canPlay = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePlayState(String value) {
    final canPlay = value.trim().isNotEmpty;
    if (_canPlay != canPlay) setState(() => _canPlay = canPlay);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Test Voice'),
    content: TextField(
      key: const Key('tts-voice-test-text'),
      controller: _controller,
      autofocus: true,
      minLines: 2,
      maxLines: 4,
      onChanged: _updatePlayState,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Enter text to test',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('tts-voice-test-play'),
        onPressed: _canPlay
            ? () => Navigator.pop(context, _controller.text)
            : null,
        child: const Text('Play'),
      ),
    ],
  );
}
