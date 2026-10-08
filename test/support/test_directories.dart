import 'dart:io';

import 'package:quisquislingo_app/services/crash_log_service.dart';

/// Isolated per-test support folder installed by flutter_test_config.dart.
late Directory testSupportDirectory;

/// For test files whose path_provider gives only app support. The Crash Log
/// lived in the documents folder until Build 255 Revision 3 moved it into
/// app support, so in those files it was unavailable and crash and audio
/// diagnostics did no real file I/O in fake time. This keeps it that way,
/// without touching storage.
void keepCrashLogUnavailable() =>
    CrashLogService.instance.debugMarkUnavailable();
