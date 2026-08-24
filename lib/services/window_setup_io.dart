import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'startup_diagnostic_service.dart';

Future<void> configureQuisquisLingoWindow() async {
  if (!Platform.isLinux && !Platform.isWindows) return;
  StartupDiagnosticService.verboseCheckpoint(
    'DART_WINDOW_MANAGER_ENSURE_BEGIN',
  );
  await windowManager.ensureInitialized();
  StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_MANAGER_ENSURE_OK');
  final windowOptions = WindowOptions(
    size: Platform.isWindows ? const Size(430, 800) : const Size(390, 700),
    center: true,
    skipTaskbar: false,
    title: 'QuisquisLingo',
  );
  StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_CONFIGURATION_BEGIN');
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_SHOW_BEGIN');
    await windowManager.show();
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_SHOW_OK');
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_FOCUS_BEGIN');
    await windowManager.focus();
    StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_FOCUS_OK');
  });
  StartupDiagnosticService.verboseCheckpoint('DART_WINDOW_CONFIGURATION_OK');
}
