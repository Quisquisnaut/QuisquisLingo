import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';

void main() {
  test('first-profile gate owns startup before animation and notices', () {
    final source = File('lib/main.dart').readAsStringSync();
    final materialAppHome = source.indexOf('home:');
    final profileGate = source.indexOf('class _InitialProfileStartupGate');
    final animationGate = source.indexOf('class _StartupGate');

    expect(materialAppHome, greaterThanOrEqualTo(0));
    expect(profileGate, greaterThan(materialAppHome));
    expect(animationGate, greaterThan(profileGate));
    expect(
      source.substring(materialAppHome, profileGate),
      contains('_InitialProfileStartupGate('),
    );
    expect(
      source.substring(materialAppHome, profileGate),
      contains('normalStartup: const _StartupGate()'),
    );
    expect(
      source.substring(profileGate, animationGate),
      contains('NewLearnerFlowScreen('),
    );
  });

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

  test('Beta testing popup retains its instructions and start control', () {
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
    expect(notice, contains("Text('QuisquisLingo Beta testing')"));
    expect(notice, contains('SingleChildScrollView('));
    expect(notice, contains('SelectableText('));
    expect(notice, contains('logPath,'));
    expect(notice, contains('FilledButton('));
    expect(notice, contains("Text('Start testing')"));
  });

  test('automatic update checks start asynchronously after runApp', () {
    final source = File('lib/main.dart').readAsStringSync();
    final runApp = source.indexOf('runApp(const QuisquisLingoApp())');
    final updateCheck = source.indexOf('unawaited(_checkForUpdateAtStartup())');
    final updates = File('lib/services/update_service.dart').readAsStringSync();

    expect(runApp, greaterThanOrEqualTo(0));
    expect(updateCheck, greaterThan(runApp));
    expect(updates, contains('connectionTimeout = const Duration(seconds: 6)'));
    expect(updates, contains('.timeout(const Duration(seconds: 8))'));
  });

  test(
    'crash log records every session start in the shared Logs directory',
    () {
      final source = File(
        'lib/services/crash_log_service.dart',
      ).readAsStringSync();
      expect(source.contains('await _recordSessionStart();'), isTrue);
      expect(
        source.contains('DiagnosticLogService.logsDirectory(create: true)'),
        isTrue,
      );
      expect(source.contains('QuisquisLingo Logs'), isFalse);
      expect(source.contains('quisquislingo_crash.log'), isTrue);
      expect(source.contains(r"Build mode: ${_buildMode()}"), isTrue);
    },
  );

  test('diagnostic writes use the bounded append path', () {
    final crashSource = File(
      'lib/services/crash_log_service.dart',
    ).readAsStringSync();
    final writerSource = File(
      'lib/services/bounded_log_writer.dart',
    ).readAsStringSync();
    expect(crashSource.contains('BoundedLogWriter.appendFile'), isTrue);
    expect(writerSource.contains('mode: FileMode.append'), isTrue);
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

  test('user-facing filesystem locations use QuisquisLingo branding', () async {
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
      // Quick Import and Quick Export folders are named by the storage layer.
      'lib/services/storage/file_system_storage.dart': ['QuisquisLingo'],
      'lib/services/storage/qql_storage_layout.dart': [
        'Documents/QuisquisLingo',
      ],
      'lib/services/course_media_store.dart': ['quisquislingo_course_media'],
      'lib/services/tts_linux_backend_io.dart': ['quisquislingo_tts_'],
    };

    for (final entry in expectedByFile.entries) {
      final source = File(entry.key).readAsStringSync();
      for (final expected in entry.value) {
        expect(source.contains(expected), isTrue, reason: entry.key);
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    final expectedImageDirectory =
        '${documents.path}${Platform.pathSeparator}QuisquisLingo'
        '${Platform.pathSeparator}Imports${Platform.pathSeparator}Images';
    // Single images and Image Bank ZIPs share one role, so one folder.
    final imageFolder = await QqlStorage().importFolder(
      QqlStorageRole.imageImports,
    );
    expect(imageFolder.location, expectedImageDirectory);
    expect(await Directory(expectedImageDirectory).exists(), isTrue);
  });
}
