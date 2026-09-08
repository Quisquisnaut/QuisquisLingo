import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'settings_service.dart';
import 'app_errors.dart';
import 'diagnostic_log_service.dart';
import 'tts_linux_backend.dart';
import 'tts_windows_backend.dart';
import 'tts_language_resolver.dart';
import 'audio_diagnostic_service.dart';

class TtsCacheService {
  // Create the flutter_tts object only on platforms that actually use the
  // plugin. Windows and Linux have dedicated backends, so constructing the
  // plugin there is unnecessary and can expose platform-plugin failures even
  // before speech is requested.
  FlutterTts? _ttsInstance;
  FlutterTts get _tts => _ttsInstance ??= FlutterTts();
  final SettingsService _settings = SettingsService();
  final DiagnosticLogService _log = DiagnosticLogService();
  String? lastFailureDescription;

  bool get isTtsSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  String _locale(dynamic raw) => (raw is Map ? (raw['locale'] ?? '') : '')
      .toString()
      .toLowerCase()
      .replaceAll('_', '-');

  String _name(dynamic raw) => raw is Map ? (raw['name'] ?? '').toString() : '';

  String _gender(dynamic raw) {
    if (raw is! Map) return '';
    final explicit = (raw['gender'] ?? '').toString().toLowerCase();
    if (explicit.contains('female') || explicit == 'f') return 'female';
    if (explicit.contains('male') || explicit == 'm') return 'male';
    final n = _name(raw).toLowerCase();
    // Common Windows voice names are only a fallback when the plugin does not
    // expose a gender field. Unknown names are left neutral.
    if (RegExp(
      r'\b(zira|hazel|susan|hedda|helena|sabina|elsa|cosimo female|female)\b',
    ).hasMatch(n)) {
      return 'female';
    }
    if (RegExp(r'\b(david|mark|george|stefan|male)\b').hasMatch(n)) {
      return 'male';
    }
    return '';
  }

  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
  }) async {
    final lifecycle = AudioDiagnosticLifecycle.start(
      kind: 'tts',
      enabled: applyLearnerSettings,
    );
    var disposalOutcome = 'completed';
    lastFailureDescription = null;
    try {
      final enabled = !applyLearnerSettings || await _settings.isTtsEnabled();
      if (!enabled || text.trim().isEmpty) {
        disposalOutcome = 'excluded';
        await lifecycle.event(
          'source_resolution',
          outcome: !enabled ? 'disabled' : 'empty',
          backend: 'tts',
        );
        return false;
      }

      final requestedLanguage = language;
      try {
        language = TtsLanguageResolver.resolve(
          requestedLanguage: requestedLanguage,
          learningLanguage: learningLanguage,
          targetLanguage: targetLanguage,
        );
      } on FormatException catch (error) {
        disposalOutcome = 'failed';
        lastFailureDescription =
            '${error.message} Check the course language metadata.';
        await lifecycle.event(
          'source_resolution',
          outcome: 'failed',
          backend: 'tts',
          failureType: error.runtimeType.toString(),
        );
        await _log.log(
          AppErrorCode.ttsUnavailable,
          context: 'Invalid requested TTS language metadata.',
        );
        return false;
      }
      await lifecycle.event(
        'source_resolution',
        outcome: 'resolved',
        backend: 'tts',
        language: language,
      );

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
        try {
          await lifecycle.event(
            'initialization',
            outcome: 'started',
            backend: 'linux_espeak',
            language: language,
          );
          await lifecycle.event(
            'playback',
            outcome: 'started',
            backend: 'linux_espeak',
            language: language,
          );
          final ok = await speakWithLinuxTts(
            text: text,
            language: language,
            rate: rate,
          );
          await lifecycle.event(
            'playback',
            outcome: ok ? 'completed' : 'failed',
            backend: 'linux_espeak',
            language: language,
          );
          if (ok) return true;
          disposalOutcome = 'failed';
          await _log.log(
            AppErrorCode.ttsUnavailable,
            context: 'Linux TTS requires eSpeak NG or eSpeak.',
          );
        } catch (e) {
          disposalOutcome = 'failed';
          await lifecycle.event(
            'failure',
            outcome: 'failed',
            backend: 'linux_espeak',
            failureType: e.runtimeType.toString(),
          );
          await _log.log(
            AppErrorCode.ttsSynthesisFailed,
            context: 'Linux speech failed for language=$language.',
          );
        }
        return false;
      }

      if (!isTtsSupported) {
        disposalOutcome = 'unsupported';
        await lifecycle.event(
          'initialization',
          outcome: 'unsupported',
          backend: 'tts',
        );
        await _log.log(
          AppErrorCode.ttsUnavailable,
          context: 'Unsupported Flutter platform.',
        );
        return false;
      }

      try {
        final wanted = language.toLowerCase().replaceAll('_', '-');
        final wantedBase = wanted.split('-').first;
        final preference = applyLearnerSettings
            ? await _settings.getTtsVoicePreference()
            : 'system';

        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
          // Windows uses System.Speech directly. This avoids the flutter_tts
          // platform-thread warning observed with current Flutter/plugin builds.
          await lifecycle.event(
            'initialization',
            outcome: 'started',
            backend: 'windows_system_speech',
            language: language,
          );
          await lifecycle.event(
            'playback',
            outcome: 'started',
            backend: 'windows_system_speech',
            language: language,
          );
          final ok = await speakWithWindowsTts(
            text: text,
            language: language,
            voicePreference: preference,
            rate: rate,
          );
          await lifecycle.event(
            'playback',
            outcome: ok ? 'completed' : 'failed',
            backend: 'windows_system_speech',
            language: language,
          );
          if (!ok) {
            disposalOutcome = 'failed';
            await _log.log(
              AppErrorCode.ttsUnavailable,
              context:
                  'Windows System.Speech could not complete speech for resolved language=$language.',
            );
          } else {
            await _log.logInfo(
              'Windows System.Speech TTS requested=$language preference=$preference',
            );
          }
          return ok;
        } else {
          await lifecycle.event(
            'initialization',
            outcome: 'started',
            backend: 'flutter_tts',
            language: language,
          );
          var selectedLanguage = language;
          var languageSet = await _tts.setLanguage(selectedLanguage);
          if (languageSet != 1) {
            // Enumerate anew after failure: an earlier missing voice must not
            // remain cached after the user installs a compatible system voice.
            final available = await _tts.getLanguages;
            if (available is List) {
              selectedLanguage =
                  TtsLanguageResolver.selectInstalledLocale(
                    language,
                    available.map((candidate) => candidate.toString()),
                  ) ??
                  language;
            }
            languageSet = await _tts.setLanguage(selectedLanguage);
          }
          if (languageSet != 1) {
            disposalOutcome = 'failed';
            await lifecycle.event(
              'initialization',
              outcome: 'failed',
              backend: 'flutter_tts',
              language: language,
            );
            await _log.log(
              AppErrorCode.ttsUnavailable,
              context: 'Requested TTS language is not installed: $language',
            );
            return false;
          }
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
            // Waiting for completion makes emulator/device playback state more
            // predictable when exercises advance quickly.
            await _tts.awaitSpeakCompletion(true);
          }
          // Platforms that expose voice metadata can still honor the gender
          // preference, but inability to match it never blocks speech.
          if (preference != 'system') {
            final voices = await _tts.getVoices;
            if (voices is List) {
              final sameLanguage = voices.where((v) {
                final locale = _locale(v);
                return locale.split('-').first == wantedBase;
              }).toList();
              final exact = sameLanguage
                  .where((v) => _locale(v) == wanted)
                  .toList();
              final compatible = (exact.isNotEmpty ? exact : sameLanguage)
                  .where((v) => _gender(v) == preference)
                  .toList();
              if (compatible.isNotEmpty && compatible.first is Map) {
                final raw = compatible.first as Map;
                await _tts.setVoice({
                  'name': (raw['name'] ?? '').toString(),
                  'locale': (raw['locale'] ?? language).toString(),
                });
              }
            }
          }
          await lifecycle.event(
            'initialization',
            outcome: 'completed',
            backend: 'flutter_tts',
            language: selectedLanguage,
          );
        }

        await _tts.setSpeechRate(rate);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        await lifecycle.event(
          'playback',
          outcome: 'started',
          backend: 'flutter_tts',
          language: language,
        );
        final result = await _tts.speak(text);
        await lifecycle.event(
          'playback',
          outcome: result == 1 ? 'completed' : 'failed',
          backend: 'flutter_tts',
          language: language,
        );
        if (result != 1) disposalOutcome = 'failed';
        return result == 1;
      } catch (e) {
        disposalOutcome = 'failed';
        await lifecycle.event(
          'failure',
          outcome: 'failed',
          backend: 'tts',
          failureType: e.runtimeType.toString(),
        );
        await _log.log(
          AppErrorCode.ttsSynthesisFailed,
          context: 'Speech failed for language=$language.',
        );
        return false;
      }
    } finally {
      await lifecycle.dispose(outcome: disposalOutcome);
    }
  }

  Future<void> synthesizeCached({
    required String text,
    required String language,
    String voice = '',
    double rate = 0.5,
    bool applyLearnerSettings = true,
  }) async {
    if (text.trim().isEmpty) return;
    final enabled = !applyLearnerSettings || await _settings.isTtsEnabled();
    if (!enabled) return;
  }

  Future<void> stop() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      return;
    }
    try {
      final tts = _ttsInstance;
      if (tts == null) return;
      await tts.stop();
    } catch (_) {}
  }
}
