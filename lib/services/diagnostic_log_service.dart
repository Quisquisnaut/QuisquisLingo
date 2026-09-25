import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_errors.dart';
import 'bounded_log_writer.dart';
import 'storage/qql_storage.dart';

class DiagnosticLogService {
  DiagnosticLogService({QqlStorage? storage}) : _storageOverride = storage;

  /// Created only when an export needs it: every service logs through this
  /// class, so it must stay cheap to construct.
  final QqlStorage? _storageOverride;
  QqlStorage get _storage => _storageOverride ?? QqlStorage();

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

  static const exportBaseName = 'quisquislingo_diagnostic_log';
  static const exportFileName = 'quisquislingo_diagnostic_log.txt';

  /// Where Export Diagnostic Log writes, for display.
  Future<String?> exportPath() async {
    if (kIsWeb) return null;
    try {
      final folder = await _storage.exportFolder(
        QqlStorageRole.diagnosticLogExports,
      );
      return folder.locationOf(exportFileName);
    } catch (_) {
      return null;
    }
  }

  /// A snapshot of the log text as UTF-8 bytes, or null when the log is empty.
  /// The internal log is untouched. Used by Save log copy as….
  Future<Uint8List?> exportBytes() async {
    final prefs = await SharedPreferences.getInstance();
    final log = prefs.getString(_logKey) ?? '';
    if (log.trim().isEmpty) return null;
    return Uint8List.fromList(utf8.encode(log));
  }

  /// Exports a snapshot of the internal diagnostic-event log to a predictable
  /// file, replacing the previous snapshot. The internal log remains
  /// available after export.
  Future<String?> exportToFile() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final log = prefs.getString(_logKey) ?? '';
      if (log.trim().isEmpty) return null;
      final folder = await _storage.exportFolder(
        QqlStorageRole.diagnosticLogExports,
      );
      final written = await folder.write(
        baseName: exportBaseName,
        extension: 'txt',
        bytes: utf8.encode(log),
        replace: true,
      );
      return written.location;
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
