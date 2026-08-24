import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/crash_log_service.dart';
import '../services/settings_service.dart';
import '../services/tts_cache_service.dart';

class TtsSettingsScreen extends StatefulWidget {
  final Course course;

  const TtsSettingsScreen({super.key, required this.course});

  @override
  State<TtsSettingsScreen> createState() => _TtsSettingsScreenState();
}

class _TtsSettingsScreenState extends State<TtsSettingsScreen> {
  final _settings = SettingsService();
  final _tts = TtsCacheService();

  bool _loading = true;
  bool _ttsEnabled = true;
  bool _skipTtsExercises = false;
  String _voicePreference = 'system';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ttsEnabled = await _settings.isTtsEnabled();
      final skipTtsExercises = await _settings.shouldSkipTtsExercises();
      final voicePreference = await _settings.getTtsVoicePreference();
      if (!mounted) return;
      setState(() {
        _ttsEnabled = ttsEnabled;
        _skipTtsExercises = skipTtsExercises;
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
              'Some TTS settings could not be loaded. Safe defaults are being used.',
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

  Future<void> _setSkipTts(bool value) async {
    await _settings.setSkipTtsExercises(value);
    if (mounted) setState(() => _skipTtsExercises = value);
  }

  Future<void> _setVoice(String value) async {
    await _settings.setTtsVoicePreference(value);
    if (mounted) setState(() => _voicePreference = value);
  }

  Future<void> _testVoice() async {
    final sample = switch (widget.course.learningLanguage.toUpperCase()) {
      'DE' => 'Guten Tag. Dies ist die ausgewählte Stimme.',
      'ES' => 'Hola. Esta es la voz seleccionada.',
      'EN' => 'Hello. This is the selected voice.',
      'FI' => 'Hei. Tämä on valittu ääni.',
      'NL' => 'Hallo. Dit is de geselecteerde stem.',
      'PT' => 'Olá. Esta é a voz selecionada.',
      'CY' => 'Helo. Dyma’r llais a ddewiswyd.',
      _ => 'Buongiorno. Questa è la voce selezionata.',
    };
    final ok = await _tts.speak(
      text: sample,
      language: widget.course.ttsLanguage,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          ok
              ? 'TTS test started.'
              : 'No compatible voice could be played for ${widget.course.targetLanguage}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SwitchListTile(
                  title: const Text('Text-to-speech'),
                  subtitle: const Text(
                    'Play spoken course audio. Windows uses System.Speech; Linux uses eSpeak NG/eSpeak; other platforms use the platform TTS engine.',
                  ),
                  value: _ttsEnabled,
                  onChanged: _setTts,
                ),
                SwitchListTile(
                  title: const Text('Skip all TTS exercises'),
                  subtitle: const Text(
                    'Audio-dependent exercises are omitted. A zero-error round with skipped TTS receives a separate completion mark, not a laurel crown.',
                  ),
                  value: _skipTtsExercises,
                  onChanged: _setSkipTts,
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
                      DropdownMenuItem(
                        value: 'female',
                        child: Text('Female'),
                      ),
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
                  subtitle: Text(
                    '${widget.course.targetLanguage} · ${widget.course.ttsLanguage}',
                  ),
                  onTap: _ttsEnabled ? _testVoice : null,
                ),
              ],
            ),
    );
  }
}
