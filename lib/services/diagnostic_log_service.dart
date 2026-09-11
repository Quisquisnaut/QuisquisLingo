import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_errors.dart';
import 'bounded_log_writer.dart';

class DiagnosticLogService {
  static const _logKey = 'quisquislingo_diagnostic_log';
  static const _maximumLogCharacters = 256 * 1024;
  Future<void> _pendingLogWrite = Future<void>.value();

  Future<void> _append(String entry) {
    final ready = _pendingLogWrite.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    final operation = ready.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getString(_logKey) ?? '';
      await prefs.setString(
        _logKey,
        BoundedLogWriter.appendString(
          current: previous,
          entry: entry,
          maximumCharacters: _maximumLogCharacters,
        ),
      );
    });
    _pendingLogWrite = operation;
    return operation;
  }

  static Future<Directory?> logsDirectory({bool create = false}) async {
    if (kIsWeb) return null;
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo'
      '${Platform.pathSeparator}Logs',
    );
    if (create) await directory.create(recursive: true);
    return directory;
  }

  Future<void> log(
    AppErrorCode error, {
    String? context,
    Object? exception,
    StackTrace? stackTrace,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final entry = StringBuffer()
        ..writeln('[$timestamp] ${error.code}')
        ..writeln('User message: ${error.userMessage}');
      if (context != null && context.isNotEmpty) {
        entry.writeln('Context: $context');
      }
      if (exception != null) entry.writeln('Exception: $exception');
      if (stackTrace != null) entry.writeln('Stack trace: $stackTrace');
      entry.writeln('---');
      await _append(entry.toString());
    } catch (_) {
      // Logging must never crash the app.
    }
  }

  /// Writes a non-error diagnostic event. Useful for voice selection and
  /// other platform decisions that help diagnose behavior without inventing
  /// an error code.
  Future<void> logInfo(String message) async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      await _append('[$timestamp] INFO\n$message\n---\n');
    } catch (_) {}
  }

  Future<bool> hasEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString(_logKey) ?? '').trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> exportPath() async {
    try {
      final directory = await logsDirectory();
      if (directory == null) return null;
      return '${directory.path}${Platform.pathSeparator}quisquislingo_diagnostic_log.txt';
    } catch (_) {
      return null;
    }
  }

  /// Exports a snapshot of the internal diagnostic-event log to a predictable
  /// file. The internal log remains available after export.
  Future<String?> exportToFile() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final log = prefs.getString(_logKey) ?? '';
      if (log.trim().isEmpty) return null;
      final path = await exportPath();
      if (path == null) return null;
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(log, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logKey);
    } catch (_) {}
  }
}
