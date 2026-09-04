import 'dart:convert';
import 'dart:io';

import 'app_metadata.dart';
import 'startup_diagnostic_backend.dart';

const _fileName = 'quisquislingo_startup_trace.log';
const _maximumLogBytes = 1024 * 1024;
const _rotatedLogCount = 2;

StartupDiagnosticBackend createStartupDiagnosticBackend() {
  final configuredLevel =
      Platform.environment['QUISQUISLINGO_STARTUP_DIAGNOSTICS'];
  final level = parseStartupDiagnosticLevel(configuredLevel);
  if (!Platform.isWindows) {
    return DisabledStartupDiagnosticBackend(level);
  }

  try {
    return _WindowsStartupDiagnosticBackend(level);
  } catch (_) {
    return DisabledStartupDiagnosticBackend(level);
  }
}

class _WindowsStartupDiagnosticBackend implements StartupDiagnosticBackend {
  _WindowsStartupDiagnosticBackend(StartupDiagnosticLevel level)
    : _selectedPath = _resolveWritablePath() ?? '',
      session = _createSession(level) {
    final nativeSession =
        Platform.environment['QUISQUISLINGO_STARTUP_SESSION_ID'];
    final nativeHeaderWritten =
        Platform.environment['QUISQUISLINGO_STARTUP_HEADER_WRITTEN'] == '1';
    if (nativeSession == null || nativeSession.isEmpty) {
      rotateStartupDiagnosticLogs(_selectedPath);
    }
    if (!nativeHeaderWritten) {
      append(formatStartupDiagnosticSessionHeader(session));
    }
  }

  String _selectedPath;

  @override
  final StartupDiagnosticSession session;

  @override
  int get processId => pid;

  @override
  String get resolvedLogPath => _selectedPath;

  @override
  Iterable<String> get sensitiveValues sync* {
    for (final name in const [
      'USERNAME',
      'USERPROFILE',
      'HOME',
      'LOCALAPPDATA',
      'TEMP',
      'TMP',
    ]) {
      final value = Platform.environment[name];
      if (value != null && value.trim().isNotEmpty) yield value;
    }
    try {
      yield Directory.current.path;
    } catch (_) {
      // Path discovery is optional and must not affect startup.
    }
  }

  @override
  void append(String text) {
    if (_selectedPath.isNotEmpty && _append(_selectedPath, text)) return;

    final fallback = _fallbackPath();
    if (fallback == null || fallback == _selectedPath) return;
    if (_append(fallback, text)) _selectedPath = fallback;
  }
}

StartupDiagnosticSession _createSession(StartupDiagnosticLevel level) {
  final environment = Platform.environment;
  final startedAt = DateTime.now().toUtc();
  final nativeSession = environment['QUISQUISLINGO_STARTUP_SESSION_ID'];
  return StartupDiagnosticSession(
    sessionId: nativeSession == null || nativeSession.isEmpty
        ? '${startedAt.microsecondsSinceEpoch.toRadixString(16)}-${pid.toRadixString(16)}'
        : nativeSession,
    startedAtUtc: startedAt,
    appVersion:
        environment['QUISQUISLINGO_STARTUP_APP_VERSION'] ??
        const String.fromEnvironment(
          'QUISQUISLINGO_APP_VERSION',
          defaultValue: AppMetadata.technicalVersion,
        ),
    isAlpha: environment['QUISQUISLINGO_STARTUP_ALPHA'] != 'false',
    buildMode:
        environment['QUISQUISLINGO_STARTUP_BUILD_MODE'] ?? _dartBuildMode(),
    platform: Platform.operatingSystem,
    architecture:
        environment['PROCESSOR_ARCHITEW6432'] ??
        environment['PROCESSOR_ARCHITECTURE'] ??
        'unknown',
    level: level,
  );
}

String _dartBuildMode() {
  const isProduct = bool.fromEnvironment('dart.vm.product');
  const isProfile = bool.fromEnvironment('dart.vm.profile');
  if (isProduct) return 'release';
  if (isProfile) return 'profile';
  return 'debug';
}

String? _resolveWritablePath() {
  final localAppData = Platform.environment['LOCALAPPDATA']?.trim();
  if (localAppData != null && localAppData.isNotEmpty) {
    final directory = Directory(
      '$localAppData${Platform.pathSeparator}QuisquisLingo'
      '${Platform.pathSeparator}Logs',
    );
    final primary = '${directory.path}${Platform.pathSeparator}$_fileName';
    if (_canAppend(directory, primary)) return primary;
  }

  final fallback = _fallbackPath();
  if (fallback == null) return null;
  return _canAppend(File(fallback).parent, fallback) ? fallback : null;
}

String? _fallbackPath() {
  try {
    final environmentTemp = Platform.environment['TEMP']?.trim();
    final directory = environmentTemp != null && environmentTemp.isNotEmpty
        ? Directory(environmentTemp)
        : Directory.systemTemp;
    return '${directory.path}${Platform.pathSeparator}$_fileName';
  } catch (_) {
    return null;
  }
}

bool _canAppend(Directory directory, String path) {
  RandomAccessFile? file;
  try {
    directory.createSync(recursive: true);
    file = File(path).openSync(mode: FileMode.append);
    return true;
  } catch (_) {
    return false;
  } finally {
    try {
      file?.closeSync();
    } catch (_) {}
  }
}

bool _append(String path, String text) {
  RandomAccessFile? file;
  try {
    file = File(path).openSync(mode: FileMode.append);
    file.writeStringSync(text, encoding: utf8);
    file.flushSync();
    return true;
  } catch (_) {
    return false;
  } finally {
    try {
      file?.closeSync();
    } catch (_) {}
  }
}

void rotateStartupDiagnosticLogs(
  String path, {
  int maximumBytes = _maximumLogBytes,
  int rotatedLogCount = _rotatedLogCount,
}) {
  if (path.isEmpty || rotatedLogCount < 1) return;
  try {
    final active = File(path);
    if (!active.existsSync() ||
        !shouldRotateStartupDiagnosticLog(
          active.lengthSync(),
          maximumBytes: maximumBytes,
        )) {
      return;
    }

    final oldest = File('$path.$rotatedLogCount');
    if (oldest.existsSync()) oldest.deleteSync();
    for (var index = rotatedLogCount - 1; index >= 1; index--) {
      final source = File('$path.$index');
      if (source.existsSync()) source.renameSync('$path.${index + 1}');
    }
    active.renameSync('$path.1');
  } catch (_) {
    // Rotation must never interfere with application startup.
  }
}
