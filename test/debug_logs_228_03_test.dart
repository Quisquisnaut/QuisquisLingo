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
    '255 R3: the live Crash Log is private; both log copies go to Logs',
    () async {
      await CrashLogService.instance.initialise();
      final crashPath = CrashLogService.instance.crashLogPath;
      final diagnosticPath = await DiagnosticLogService().exportPath();
      final crashCopyPath = await CrashLogService.instance.exportPath();
      final logsFolder = Directory(
        '${documents.path}${Platform.pathSeparator}QuisquisLingo'
        '${Platform.pathSeparator}Logs',
      ).path;

      // This file's path_provider answers one directory for everything, so
      // app support and documents share a root here.
      expect(
        File(crashPath!).parent.path,
        '${documents.path}${Platform.pathSeparator}QQL_Logs',
      );
      expect(File(crashPath).uri.pathSegments.last, 'QQL_crash.log');
      expect(await File(crashPath).exists(), isTrue);
      expect(File(diagnosticPath!).parent.path, logsFolder);
      expect(
        File(diagnosticPath).uri.pathSegments.last,
        'QQL_diagnostic_log.txt',
      );
      expect(File(crashCopyPath!).parent.path, logsFolder);
      expect(File(crashCopyPath).uri.pathSegments.last, 'QQL_crash_log.txt');
    },
  );

  testWidgets('228.03 Debug page owns both existing log entries', (
    tester,
  ) async {
    // The lazy ListView only builds what fits; a tall fixed surface keeps the
    // lower entries built regardless of the (variable-length) log paths.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: DebugScreen()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Debug'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Crash Log'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Diagnostic Log'), findsOneWidget);
    expect(find.byTooltip('Export Diagnostic Log'), findsOneWidget);
    expect(find.byTooltip('Clear Diagnostic Log'), findsOneWidget);
    expect(find.byKey(const Key('quick-export-crash-log')), findsOneWidget);
    expect(find.byTooltip('Quick Export Crash Log'), findsOneWidget);
    expect(find.textContaining('Quick Export location:'), findsOneWidget);
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

    await tester.tap(find.byKey(const Key('debug-help')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Debug Help'), findsOneWidget);
    expect(find.textContaining('automatic local Crash Log'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('unexpected playback'), findsOneWidget);
    expect(find.textContaining('full personal file paths'), findsOneWidget);
  });
}
