import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup diagnostic notice is not debug-only', () {
    final source = File('lib/main.dart').readAsStringSync();
    final gateStart = source.indexOf('if (!_show)');
    final gateEnd = source.indexOf('return Scaffold(', gateStart);
    expect(gateStart, greaterThanOrEqualTo(0));
    expect(gateEnd, greaterThan(gateStart));
    final gate = source.substring(gateStart, gateEnd);
    expect(gate.contains('kDebugMode'), isFalse);
    expect(gate.contains('_StartupCrashLogNotice'), isTrue);
  });

  test('Alpha testing popup retains its instructions and start control', () {
    final source = File('lib/main.dart').readAsStringSync();
    final noticeStart = source.indexOf('Future<void> _showInstructions()');
    final noticeEnd = source.indexOf(
      'Future<void> _checkForUpdateAtStartup()',
      noticeStart,
    );
    expect(noticeStart, greaterThanOrEqualTo(0));
    expect(noticeEnd, greaterThan(noticeStart));

    final notice = source.substring(noticeStart, noticeEnd);
    expect(notice, contains('barrierDismissible: false'));
    expect(notice, contains("Text('QuisquisLingo Alpha testing')"));
    expect(notice, contains('SingleChildScrollView('));
    expect(notice, contains('SelectableText('));
    expect(notice, contains('logPath,'));
    expect(notice, contains('FilledButton('));
    expect(notice, contains("Text('Start testing')"));
  });

  test(
    'crash log records every session start and Windows visible log is not debug-only',
    () {
      final source = File(
        'lib/services/crash_log_service.dart',
      ).readAsStringSync();
      expect(source.contains('await _recordSessionStart();'), isTrue);
      expect(source.contains("if (Platform.isWindows)"), isTrue);
      expect(source.contains('QuisquisLingo Logs'), isTrue);
      expect(source.contains('quisquislingo_crash.log'), isTrue);
      expect(source.contains("if (Platform.isWindows && kDebugMode)"), isFalse);
      expect(source.contains(r"Build mode: ${_buildMode()}"), isTrue);
    },
  );

  test('diagnostic writes use append mode so a deleted log is recreated', () {
    final source = File(
      'lib/services/crash_log_service.dart',
    ).readAsStringSync();
    expect(source.contains('mode: FileMode.append'), isTrue);
  });

  test('startup trace and exported diagnostic log use QuisquisLingo paths', () {
    final dartStartupSource = File(
      'lib/services/startup_diagnostic_backend_io.dart',
    ).readAsStringSync();
    final nativeStartupSource = File(
      'windows/runner/startup_diagnostics.h',
    ).readAsStringSync();
    final diagnosticSource = File(
      'lib/services/diagnostic_log_service.dart',
    ).readAsStringSync();

    for (final source in [dartStartupSource, nativeStartupSource]) {
      expect(source.contains('QuisquisLingo'), isTrue);
      expect(source.contains('quisquislingo_startup_trace.log'), isTrue);
    }
    expect(diagnosticSource.contains('QuisquisLingo'), isTrue);
    expect(
      diagnosticSource.contains('quisquislingo_diagnostic_log.txt'),
      isTrue,
    );
  });

  test('user-facing filesystem locations use QuisquisLingo branding', () {
    final expectedByFile = <String, List<String>>{
      'lib/services/custom_course_transfer_service.dart': [
        'QuisquisLingo',
        'quisquislingo_',
      ],
      'lib/services/learner_backup_service.dart': [
        'QuisquisLingo',
        'quisquislingo_',
      ],
      'lib/services/course_flag_service.dart': ['QuisquisLingo'],
      'lib/services/image_bank_service.dart': ['QuisquisLingo'],
      'lib/services/exercise_image_service.dart': ['QuisquisLingo'],
      'lib/services/recorded_audio_service.dart': [
        'QuisquisLingo',
        'quisquislingo_audio',
      ],
      'lib/services/tts_linux_backend_io.dart': ['quisquislingo_tts_'],
    };

    for (final entry in expectedByFile.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final expected in entry.value) {
        expect(source.contains(expected), isTrue, reason: entry.key);
      }
    }
  });
}
