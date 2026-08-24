import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_errors.dart';

class DiagnosticLogService {
  static const _logKey = 'quisquislingo_diagnostic_log';

  Future<void> log(
    AppErrorCode error, {
    String? context,
    Object? exception,
    StackTrace? stackTrace,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      final entry = StringBuffer()
        ..writeln('[$timestamp] ${error.code}')
        ..writeln('User message: ${error.userMessage}');
      if (context != null && context.isNotEmpty) entry.writeln('Context: $context');
      if (exception != null) entry.writeln('Exception: $exception');
      if (stackTrace != null) entry.writeln('Stack trace: $stackTrace');
      entry.writeln('---');
      final previous = prefs.getString(_logKey) ?? '';
      await prefs.setString(_logKey, '$previous${entry.toString()}');
    } catch (_) {
      // Logging must never crash the app.
    }
  }

  /// Writes a non-error diagnostic event. Useful for voice selection and
  /// other platform decisions that help diagnose behavior without inventing
  /// an error code.
  Future<void> logInfo(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().toIso8601String();
      final previous = prefs.getString(_logKey) ?? '';
      await prefs.setString(_logKey, '$previous[$timestamp] INFO\n$message\n---\n');
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
    if (kIsWeb) return null;
    try {
      final documents = await getApplicationDocumentsDirectory();
      final dir = Directory(
        '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Logs',
      );
      return '${dir.path}${Platform.pathSeparator}quisquislingo_diagnostic_log.txt';
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
