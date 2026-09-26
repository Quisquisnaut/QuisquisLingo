import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/crash_log_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documents;
  late Directory logs;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('qql_abnormal_');
    // The private logs folder in app support (Build 255 Revision 3); this
    // file's path_provider answers one directory for everything.
    logs = Directory(
      '${documents.path}${Platform.pathSeparator}'
      '${DiagnosticLogService.logsDirectoryName}',
    )..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => documents.path);
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    try {
      await documents.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a handle.
    }
  });

  test(
    'leftover session marker is reported, then removed on clean exit',
    () async {
      final sep = Platform.pathSeparator;
      final marker =
          File('${logs.path}$sep${CrashLogService.sessionMarkerFileName}')
        ..writeAsStringSync(
          'Started: earlier\nLast state: resumed at earlier\n',
        );

      await CrashLogService.instance.initialise();

      final log = File('${logs.path}$sep${CrashLogService.crashLogFileName}');
      final text = log.readAsStringSync();
      expect(text, contains('abnormal termination detected'));
      expect(text, contains('Last state: resumed at earlier'));
      // The current session is now marked as running.
      expect(marker.readAsStringSync(), contains('Last state: started'));

      CrashLogService.instance.markCleanShutdown();
      expect(marker.existsSync(), isFalse);
      expect(log.readAsStringSync(), contains('session ended cleanly'));
    },
    skip: !(Platform.isWindows || Platform.isLinux),
  );
}
