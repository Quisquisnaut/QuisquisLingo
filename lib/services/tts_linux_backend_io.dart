import 'dart:io';

import 'tts_language_resolver.dart';

/// Converts validated course language metadata into an eSpeak voice code.
///
/// eSpeak accepts ISO-style base language codes. Passing the requested base
/// through lets the backend report a genuinely unavailable voice instead of
/// silently pronouncing an unsupported language with English rules.
String? linuxTtsVoiceForLanguage(String language) {
  final normalized = TtsLanguageResolver.normalize(language);
  if (normalized == null) return null;
  final base = normalized.split('-').first.toLowerCase();
  return base == 'en' ? 'en-gb' : base;
}

/// Resolve an executable by inspecting PATH directly. This deliberately avoids
/// `sh -c`, so no shell parser is involved in TTS command discovery.
Future<String?> _findExecutable(List<String> names) async {
  final path = Platform.environment['PATH'] ?? '';
  final dirs = path
      .split(Platform.isWindows ? ';' : ':')
      .where((e) => e.isNotEmpty);
  for (final name in names) {
    for (final dir in dirs) {
      final candidate = File('$dir${Platform.pathSeparator}$name');
      if (await candidate.exists()) return candidate.path;
    }
  }
  return null;
}

Future<bool> speakWithLinuxTts({
  required String text,
  required String language,
  required double rate,
}) async {
  if (text.trim().isEmpty) return false;
  final voice = linuxTtsVoiceForLanguage(language);
  if (voice == null) return false;
  final command = await _findExecutable(const ['espeak-ng', 'espeak']);
  final aplay = await _findExecutable(const ['aplay']);
  if (command == null || aplay == null) return false;
  final wordsPerMinute = (110 + (rate.clamp(0.0, 1.0) * 100)).round();
  final tempDir = await Directory.systemTemp.createTemp('quisquislingo_tts_');
  final wav = File('${tempDir.path}/speech.wav');
  try {
    // User/course text is passed as a separate Process argument, never
    // interpolated into a shell command.
    final synth = await Process.run(command, [
      '-v',
      voice,
      '-s',
      '$wordsPerMinute',
      '-w',
      wav.path,
      text,
    ]);
    if (synth.exitCode != 0 || !await wav.exists() || await wav.length() == 0) {
      return false;
    }
    final plug = await Process.run(aplay, ['-q', '-D', 'plughw:0,0', wav.path]);
    if (plug.exitCode == 0) return true;
    final fallback = await Process.run(aplay, ['-q', wav.path]);
    return fallback.exitCode == 0;
  } finally {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  }
}
