import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'crash_log_service.dart';
import 'startup_diagnostic_service.dart';

/// Intercepts window close so a clean exit can be recorded before the window
/// is destroyed; anything that ends the process otherwise leaves the session
/// marker behind for the next launch to report.
class _CleanCloseListener with WindowListener {
  @override
  void onWindowClose() async {
    CrashLogService.instance.markCleanShutdown();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}

Future<void> configureQuisquisLingoWindow() async {
  if (!Platform.isLinux && !Platform.isWindows) return;
  StartupDiagnosticService.verboseCheckpoint(
    'DART_WINDOW_MANAGER_ENSURE_BEGIN',
  );
  await windowManager.ensureInitialized();
  StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_MANAGER_ENSURE_OK');
  windowManager.addListener(_CleanCloseListener());
  await windowManager.setPreventClose(true);
  final windowOptions = WindowOptions(
    size: Platform.isWindows ? const Size(430, 800) : const Size(390, 700),
    center: true,
    skipTaskbar: false,
    title: 'QuisquisLingo',
  );
  StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_CONFIGURATION_BEGIN');
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setMinimumSize(const Size(320, 600));
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_SHOW_BEGIN');
    await windowManager.show();
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_SHOW_OK');
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_FOCUS_BEGIN');
    await windowManager.focus();
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_FOCUS_OK');
  });
  StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_CONFIGURATION_OK');
}
