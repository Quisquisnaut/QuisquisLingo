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

/// Builds the eSpeak argument list.
///
/// The `--` matters: eSpeak parses options with `getopt_long`, which scans every
/// argument, not just the leading ones. Without an end-of-options marker, course
/// text beginning with `-` is consumed as options rather than spoken, and
/// `-w <path>` would make eSpeak write a file of the author's choosing. There is
/// no shell involved either way; this closes the separate argv-parsing hole.
List<String> espeakArguments({
  required String voice,
  required int wordsPerMinute,
  required String wavPath,
  required String text,
}) => ['-v', voice, '-s', '$wordsPerMinute', '-w', wavPath, '--', text];

/// Resolve an executable by inspecting PATH directly. This deliberately avoids
/// `sh -c`, so no shell parser is involved in TTS command discovery.
Future<String?> _findExecutable(List<String> names) async {
  final path = Platform.environment['PATH'] ?? '';
  final dirs = path
      .split(Platform.isWindows ? ';' : ':')
      .where((e) => e.isNotEmpty);
  for (final name in names) {
    for (final dir in dirs) {
      // Build 270 Revision 2: a relative entry (such as `.`) would find a
      // program in whatever folder QQL was started from.
      if (!dir.startsWith('/')) continue;
      final candidate = File('$dir${Platform.pathSeparator}$name');
      if (await candidate.exists()) return candidate.path;
    }
  }
  return null;
}

/// The eSpeak or aplay process running now, and a count that
/// [stopLinuxTts] raises (Build 270 Revision 2: before, stop() did nothing
/// on Linux, and a player that never ended held speech forever).
Process? _running;
int _stops = 0;

/// Stops the speech playing now, if any.
Future<void> stopLinuxTts() async {
  _stops++;
  _running?.kill();
  _running = null;
}

/// Runs [executable] with a time limit; -1 when it was stopped or took too
/// long.
Future<int> _run(
  String executable,
  List<String> arguments,
  Duration limit,
  int stops,
) async {
  if (stops != _stops) return -1;
  final process = await Process.start(executable, arguments);
  _running = process;
  // Nothing reads the output: drain it so the process never blocks.
  process.stdout.drain<void>();
  process.stderr.drain<void>();
  final code = await process.exitCode.timeout(
    limit,
    onTimeout: () {
      process.kill();
      return -1;
    },
  );
  if (identical(_running, process)) _running = null;
  return stops == _stops ? code : -1;
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
  final tempDir = await Directory.systemTemp.createTemp('QQL_TTS_');
  final wav = File('${tempDir.path}/speech.wav');
  try {
    // User/course text is passed as a separate Process argument, never
    // interpolated into a shell command, and always after `--` so eSpeak
    // cannot mistake it for options.
    final stops = _stops;
    final synth = await _run(
      command,
      espeakArguments(
        voice: voice,
        wordsPerMinute: wordsPerMinute,
        wavPath: wav.path,
        text: text,
      ),
      const Duration(seconds: 30),
      stops,
    );
    if (synth != 0 || !await wav.exists() || await wav.length() == 0) {
      return false;
    }
    // At the slowest speed a character takes about a tenth of a second.
    final playing = Duration(seconds: 30 + text.length ~/ 5);
    final plug = await _run(
      aplay,
      ['-q', '-D', 'plughw:0,0', wav.path],
      playing,
      stops,
    );
    if (plug == 0) return true;
    if (stops != _stops) return false;
    final fallback = await _run(aplay, ['-q', wav.path], playing, stops);
    return fallback == 0;
  } finally {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  }
}
