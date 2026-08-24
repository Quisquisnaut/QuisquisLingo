import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'settings_service.dart';
import 'app_errors.dart';
import 'diagnostic_log_service.dart';
import 'tts_linux_backend.dart';
import 'tts_windows_backend.dart';

class TtsCacheService {
  // Create the flutter_tts object only on platforms that actually use the
  // plugin. Windows and Linux have dedicated backends, so constructing the
  // plugin there is unnecessary and can expose platform-plugin failures even
  // before speech is requested.
  FlutterTts? _ttsInstance;
  FlutterTts get _tts => _ttsInstance ??= FlutterTts();
  final SettingsService _settings = SettingsService();
  final DiagnosticLogService _log = DiagnosticLogService();

  bool get isTtsSupported => kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;

  String _locale(dynamic raw, String fallback) =>
      (raw is Map ? (raw['locale'] ?? fallback) : fallback)
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
    if (RegExp(r'\b(zira|hazel|susan|hedda|helena|sabina|elsa|cosimo female|female)\b').hasMatch(n)) return 'female';
    if (RegExp(r'\b(david|mark|george|stefan|male)\b').hasMatch(n)) return 'male';
    return '';
  }

  Future<bool> speak({
    required String text,
    required String language,
    double rate = 0.5,
  }) async {
    final enabled = await _settings.isTtsEnabled();
    if (!enabled || text.trim().isEmpty) return false;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      try {
        final ok = await speakWithLinuxTts(text: text, language: language, rate: rate);
        if (ok) return true;
        await _log.log(AppErrorCode.ttsUnavailable, context: 'Linux TTS requires eSpeak NG or eSpeak.');
      } catch (e, st) {
        await _log.log(AppErrorCode.ttsSynthesisFailed, context: 'Linux speech language=$language text=$text', exception: e, stackTrace: st);
      }
      return false;
    }

    if (!isTtsSupported) {
      await _log.log(AppErrorCode.ttsUnavailable, context: 'Unsupported Flutter platform.');
      return false;
    }

    try {
      final wanted = language.toLowerCase().replaceAll('_', '-');
      final wantedBase = wanted.split('-').first;
      final preference = await _settings.getTtsVoicePreference();

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        // Windows uses System.Speech directly. This avoids the flutter_tts
        // platform-thread warning observed with current Flutter/plugin builds.
        final ok = await speakWithWindowsTts(
          text: text,
          language: language,
          voicePreference: preference,
          rate: rate,
        );
        if (!ok) {
          await _log.log(AppErrorCode.ttsUnavailable, context: 'No compatible Windows System.Speech voice could speak $language.');
        } else {
          await _log.logInfo('Windows System.Speech TTS requested=$language preference=$preference');
        }
        return ok;
      } else {
        var selectedLanguage=language;
        var languageSet = await _tts.setLanguage(selectedLanguage);
        if (languageSet != 1) {
          final available=await _tts.getLanguages;
          if(available is List){
            final wantedBase=language.toLowerCase().replaceAll('_','-').split('-').first;
            for(final candidate in available){
              final locale=candidate.toString();
              if(locale.toLowerCase().replaceAll('_','-').split('-').first==wantedBase){selectedLanguage=locale;break;}
            }
          }
          languageSet=await _tts.setLanguage(selectedLanguage);
        }
        if (languageSet != 1) {
          await _log.log(AppErrorCode.ttsUnavailable, context: 'Requested TTS language is not installed: $language');
          return false;
        }
        if(!kIsWeb&&defaultTargetPlatform==TargetPlatform.android){
          // Waiting for completion makes emulator/device playback state more
          // predictable when exercises advance quickly.
          await _tts.awaitSpeakCompletion(true);
        }
        // Platforms that expose voice metadata can still honor the gender
        // preference, but inability to match it never blocks speech.
        if (preference != 'system') {
          final voices = await _tts.getVoices;
          if (voices is List) {
            final compatible = voices.where((v) {
              final locale = _locale(v, language);
              return (locale == wanted || locale.startsWith('$wantedBase-')) && _gender(v) == preference;
            }).toList();
            if (compatible.isNotEmpty && compatible.first is Map) {
              final raw = compatible.first as Map;
              await _tts.setVoice({
                'name': (raw['name'] ?? '').toString(),
                'locale': (raw['locale'] ?? language).toString(),
              });
            }
          }
        }
      }

      await _tts.setSpeechRate(rate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      final result = await _tts.speak(text);
      return result == 1;
    } catch (e, st) {
      await _log.log(AppErrorCode.ttsSynthesisFailed, context: 'Speak language=$language rate=$rate text=$text', exception: e, stackTrace: st);
      return false;
    }
  }

  Future<void> synthesizeCached({required String text, required String language, String voice = '', double rate = 0.5}) async {
    if (text.trim().isEmpty) return;
    final enabled = await _settings.isTtsEnabled();
    if (!enabled) return;
  }

  Future<void> stop() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows)) return;
    try { await _tts.stop(); } catch (_) {}
  }
}
