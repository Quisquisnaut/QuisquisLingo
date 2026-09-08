import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/debug_screen.dart';
import 'package:quisquislingo_app/services/crash_log_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documents;

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('qql_228_logs_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, (_) async => documents.path);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProvider, null);
    try {
      if (await documents.exists()) await documents.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain an append handle after the final assertion.
    }
  });

  test(
    '228.03 Crash and Diagnostic Logs use the same existing directory',
    () async {
      await CrashLogService.instance.initialise();
      final crashPath = CrashLogService.instance.crashLogPath;
      final diagnosticPath = await DiagnosticLogService().exportPath();
      final expectedDirectory = Directory(
        '${documents.path}${Platform.pathSeparator}QuisquisLingo'
        '${Platform.pathSeparator}Logs',
      ).path;

      expect(File(crashPath!).parent.path, expectedDirectory);
      expect(File(diagnosticPath!).parent.path, expectedDirectory);
      expect(File(crashPath).uri.pathSegments.last, 'quisquislingo_crash.log');
      expect(
        File(diagnosticPath).uri.pathSegments.last,
        'quisquislingo_diagnostic_log.txt',
      );
      expect(crashPath, isNot(contains('QuisquisLingo Logs')));
      expect(await File(crashPath).exists(), isTrue);
    },
  );

  testWidgets('228.03 Debug page owns both existing log entries', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DebugScreen()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Debug'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Crash Log'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Diagnostic Log'), findsOneWidget);
    expect(find.byTooltip('Export Diagnostic Log'), findsOneWidget);
    expect(find.byTooltip('Clear Diagnostic Log'), findsOneWidget);
    expect(
      find.textContaining('crashes or closes unexpectedly'),
      findsOneWidget,
    );
    expect(find.textContaining('startup and runtime crashes'), findsOneWidget);
    expect(find.textContaining('unexpected playback'), findsOneWidget);
    expect(
      find.textContaining('export this log shortly afterward'),
      findsOneWidget,
    );
    expect(find.textContaining('clearing is optional'), findsOneWidget);
    expect(
      find.textContaining('export the current Diagnostic Log before clearing'),
      findsOneWidget,
    );
    expect(find.textContaining('spoken text'), findsOneWidget);
    expect(find.textContaining('full personal file paths'), findsOneWidget);
  });
}
