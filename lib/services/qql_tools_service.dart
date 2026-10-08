import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'diagnostic_log_service.dart';
import 'profile_service.dart';
import 'settings_service.dart';

enum QqlToolsProcessIssue { launchFailed, timedOut, outputTooLarge }

class QqlToolsProcessException implements Exception {
  const QqlToolsProcessException(this.issue, {this.osErrorCode});

  final QqlToolsProcessIssue issue;
  final int? osErrorCode;
}

class QqlToolsProcessOutput {
  const QqlToolsProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// The process boundary is injectable so Flutter tests need no QQL-Tools install.
abstract interface class QqlToolsProcessRunner {
  Future<QqlToolsProcessOutput> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
  });
}

/// Runs an Admin-selected executable without a shell or terminal window.
class DartQqlToolsProcessRunner implements QqlToolsProcessRunner {
  const DartQqlToolsProcessRunner();

  static const maximumStdoutBytes = 2 * 1024 * 1024;
  static const maximumStderrBytes = 64 * 1024;

  @override
  Future<QqlToolsProcessOutput> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
  }) async {
    final Process process;
    try {
      process = await Process.start(
        executable,
        arguments,
        runInShell: false,
        mode: ProcessStartMode.normal,
      );
    } on ProcessException catch (error) {
      throw QqlToolsProcessException(
        QqlToolsProcessIssue.launchFailed,
        osErrorCode: error.errorCode,
      );
    } catch (_) {
      throw const QqlToolsProcessException(QqlToolsProcessIssue.launchFailed);
    }

    final stdout = BytesBuilder(copy: false);
    final stderr = BytesBuilder(copy: false);
    var exceededLimit = false;

    Future<void> collect(
      Stream<List<int>> stream,
      BytesBuilder target,
      int maximumBytes,
    ) async {
      await for (final chunk in stream) {
        if (exceededLimit) continue;
        if (target.length + chunk.length > maximumBytes) {
          exceededLimit = true;
          process.kill(ProcessSignal.sigkill);
        } else {
          target.add(chunk);
        }
      }
    }

    final stdoutDone = collect(process.stdout, stdout, maximumStdoutBytes);
    final stderrDone = collect(process.stderr, stderr, maximumStderrBytes);
    try {
      await process.stdin.close();
      final exitCode = await process.exitCode.timeout(timeout);
      // A child can leave inherited pipe handles open after its own exit.
      await Future.wait([
        stdoutDone,
        stderrDone,
      ]).timeout(const Duration(seconds: 2));
      if (exceededLimit) {
        throw const QqlToolsProcessException(
          QqlToolsProcessIssue.outputTooLarge,
        );
      }
      return QqlToolsProcessOutput(
        exitCode: exitCode,
        stdout: utf8.decode(stdout.takeBytes(), allowMalformed: true),
        stderr: utf8.decode(stderr.takeBytes(), allowMalformed: true),
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      throw QqlToolsProcessException(
        exceededLimit
            ? QqlToolsProcessIssue.outputTooLarge
            : QqlToolsProcessIssue.timedOut,
      );
    } on QqlToolsProcessException {
      rethrow;
    } catch (_) {
      process.kill(ProcessSignal.sigkill);
      throw const QqlToolsProcessException(QqlToolsProcessIssue.launchFailed);
    }
  }
}

enum QqlToolsFailure {
  unsupportedPlatform,
  unauthorized,
  notConfigured,
  invalidExecutable,
  invalidCourseFile,
  launchFailed,
  timedOut,
  outputTooLarge,
  helpFailed,
  emptyOutput,
  malformedJson,
  unknownExitCode,
}

class QqlToolsTestResult {
  const QqlToolsTestResult.available() : available = true, failure = null;

  const QqlToolsTestResult.failed(this.failure) : available = false;

  final bool available;
  final QqlToolsFailure? failure;
}

enum QqlToolsValidationStatus { fullyValid, validForImplementedChecks, invalid }

class QqlToolsValidationError {
  const QqlToolsValidationError({
    required this.code,
    required this.message,
    this.location,
  });

  final String code;
  final String message;
  final String? location;
}

class QqlToolsValidationReport {
  const QqlToolsValidationReport({
    required this.isValid,
    required this.isFullyValid,
    required this.errors,
    required this.notes,
    required this.implementedChecks,
    required this.unsupportedChecks,
    this.source,
  });

  final bool isValid;
  final bool isFullyValid;
  final List<QqlToolsValidationError> errors;
  final List<String> notes;
  final List<String> implementedChecks;
  final List<String> unsupportedChecks;
  final String? source;

  QqlToolsValidationStatus get status => !isValid
      ? QqlToolsValidationStatus.invalid
      : isFullyValid
      ? QqlToolsValidationStatus.fullyValid
      : QqlToolsValidationStatus.validForImplementedChecks;

  factory QqlToolsValidationReport.parse(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic> || decoded['is_valid'] is! bool) {
      throw const FormatException('Invalid QQL-Tools report');
    }
    final fullyValidValue = decoded['is_fully_valid'];
    if (fullyValidValue != null && fullyValidValue is! bool) {
      throw const FormatException('Invalid QQL-Tools report');
    }
    final isValid = decoded['is_valid'] as bool;
    final isFullyValid = fullyValidValue == true;
    final unsupportedChecks = _strings(decoded['unsupported_checks']);
    if (isFullyValid && (!isValid || unsupportedChecks.isNotEmpty)) {
      throw const FormatException('Contradictory QQL-Tools report');
    }

    final errorsValue = decoded['errors'];
    if (errorsValue != null && errorsValue is! List) {
      throw const FormatException('Invalid QQL-Tools errors');
    }
    final errors = <QqlToolsValidationError>[];
    for (final value in (errorsValue as List? ?? const [])) {
      if (value is! Map<String, dynamic> ||
          value['code'] is! String ||
          value['message'] is! String ||
          (value['location'] != null && value['location'] is! String)) {
        throw const FormatException('Invalid QQL-Tools error');
      }
      errors.add(
        QqlToolsValidationError(
          code: value['code'] as String,
          message: value['message'] as String,
          location: value['location'] as String?,
        ),
      );
    }
    return QqlToolsValidationReport(
      isValid: isValid,
      isFullyValid: isFullyValid,
      errors: List.unmodifiable(errors),
      notes: _strings(decoded['notes']),
      implementedChecks: _strings(decoded['implemented_checks']),
      unsupportedChecks: unsupportedChecks,
      source: decoded['source'] is String ? decoded['source'] as String : null,
    );
  }

  static List<String> _strings(Object? value) {
    if (value == null) return const [];
    if (value is! List || value.any((element) => element is! String)) {
      throw const FormatException('Invalid QQL-Tools report list');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}

class QqlToolsValidationResult {
  const QqlToolsValidationResult.report(this.report) : failure = null;
  const QqlToolsValidationResult.failed(this.failure) : report = null;

  final QqlToolsValidationReport? report;
  final QqlToolsFailure? failure;
}

/// Optional validation: it never changes, imports or audits a Course in QQL.
class QqlToolsService {
  QqlToolsService({
    SettingsService? settings,
    ProfileService? profiles,
    QqlToolsProcessRunner? runner,
    DiagnosticLogService? diagnosticLog,
    bool? desktopAvailable,
  }) : _settings = settings ?? SettingsService(),
       _profiles = profiles ?? ProfileService(),
       _runner = runner ?? const DartQqlToolsProcessRunner(),
       _diagnosticLog = diagnosticLog ?? DiagnosticLogService(),
       isDesktopAvailable =
           desktopAvailable ??
           (!kIsWeb &&
               (Platform.isWindows || Platform.isLinux || Platform.isMacOS));

  final SettingsService _settings;
  final ProfileService _profiles;
  final QqlToolsProcessRunner _runner;
  final DiagnosticLogService _diagnosticLog;
  final bool isDesktopAvailable;

  static const testTimeout = Duration(seconds: 10);
  static const validationTimeout = Duration(seconds: 60);

  Future<QqlToolsTestResult> testAvailability({
    required String actorProfileId,
  }) async {
    final (path, failure) = await _executableFor(actorProfileId);
    if (failure != null) return QqlToolsTestResult.failed(failure);
    try {
      final output = await _runner.run(path!, const [
        '--help',
      ], timeout: testTimeout);
      await _log(
        'test',
        output.exitCode == 0 ? null : QqlToolsFailure.helpFailed,
        exitCode: output.exitCode,
        stderrLength: output.stderr.length,
      );
      return output.exitCode == 0
          ? const QqlToolsTestResult.available()
          : const QqlToolsTestResult.failed(QqlToolsFailure.helpFailed);
    } on QqlToolsProcessException catch (error) {
      final failure = _processFailure(error.issue);
      await _log('test', failure, osErrorCode: error.osErrorCode);
      return QqlToolsTestResult.failed(failure);
    } catch (_) {
      await _log('test', QqlToolsFailure.launchFailed);
      return const QqlToolsTestResult.failed(QqlToolsFailure.launchFailed);
    }
  }

  Future<QqlToolsValidationResult> validateCourse({
    required String actorProfileId,
    required String coursePath,
  }) async {
    final (path, failure) = await _executableFor(actorProfileId);
    if (failure != null) return QqlToolsValidationResult.failed(failure);
    final lowerPath = coursePath.toLowerCase();
    if ((!lowerPath.endsWith('.json') && !lowerPath.endsWith('.zip')) ||
        !await _ordinaryFile(coursePath)) {
      return const QqlToolsValidationResult.failed(
        QqlToolsFailure.invalidCourseFile,
      );
    }

    final QqlToolsProcessOutput output;
    try {
      output = await _runner.run(path!, [
        'validate',
        coursePath,
        '--json',
      ], timeout: validationTimeout);
    } on QqlToolsProcessException catch (error) {
      final failure = _processFailure(error.issue);
      await _log('validate', failure, osErrorCode: error.osErrorCode);
      return QqlToolsValidationResult.failed(failure);
    } catch (_) {
      await _log('validate', QqlToolsFailure.launchFailed);
      return const QqlToolsValidationResult.failed(
        QqlToolsFailure.launchFailed,
      );
    }

    if (output.exitCode != 0 && output.exitCode != 1 && output.exitCode != 2) {
      await _log(
        'validate',
        QqlToolsFailure.unknownExitCode,
        exitCode: output.exitCode,
        stderrLength: output.stderr.length,
      );
      return const QqlToolsValidationResult.failed(
        QqlToolsFailure.unknownExitCode,
      );
    }
    if (output.stdout.length > DartQqlToolsProcessRunner.maximumStdoutBytes ||
        output.stderr.length > DartQqlToolsProcessRunner.maximumStderrBytes) {
      await _log(
        'validate',
        QqlToolsFailure.outputTooLarge,
        exitCode: output.exitCode,
      );
      return const QqlToolsValidationResult.failed(
        QqlToolsFailure.outputTooLarge,
      );
    }
    if (output.stdout.trim().isEmpty) {
      await _log(
        'validate',
        QqlToolsFailure.emptyOutput,
        exitCode: output.exitCode,
        stderrLength: output.stderr.length,
      );
      return const QqlToolsValidationResult.failed(QqlToolsFailure.emptyOutput);
    }
    try {
      final report = QqlToolsValidationReport.parse(output.stdout);
      final expectedStatus = switch (output.exitCode) {
        0 => QqlToolsValidationStatus.fullyValid,
        1 => QqlToolsValidationStatus.invalid,
        _ => QqlToolsValidationStatus.validForImplementedChecks,
      };
      if (report.status != expectedStatus) {
        throw const FormatException('QQL-Tools exit and report disagree');
      }
      await _log(
        'validate',
        null,
        exitCode: output.exitCode,
        stderrLength: output.stderr.length,
      );
      return QqlToolsValidationResult.report(report);
    } on FormatException {
      await _log(
        'validate',
        QqlToolsFailure.malformedJson,
        exitCode: output.exitCode,
        stderrLength: output.stderr.length,
      );
      return const QqlToolsValidationResult.failed(
        QqlToolsFailure.malformedJson,
      );
    }
  }

  Future<(String?, QqlToolsFailure?)> _executableFor(String actor) async {
    if (!isDesktopAvailable) return (null, QqlToolsFailure.unsupportedPlatform);
    final active = await _profiles.getActiveProfileId();
    if (active != actor || !await _profiles.isAdmin(actor)) {
      return (null, QqlToolsFailure.unauthorized);
    }
    final path = await _settings.getQqlToolsExecutablePath();
    if (path == null || path.trim().isEmpty) {
      return (null, QqlToolsFailure.notConfigured);
    }
    if ((Platform.isWindows && !path.toLowerCase().endsWith('.exe')) ||
        !await _ordinaryFile(path)) {
      return (null, QqlToolsFailure.invalidExecutable);
    }
    return (path, null);
  }

  Future<bool> _ordinaryFile(String path) async {
    try {
      return await FileSystemEntity.type(path, followLinks: true) ==
          FileSystemEntityType.file;
    } catch (_) {
      return false;
    }
  }

  QqlToolsFailure _processFailure(QqlToolsProcessIssue issue) =>
      switch (issue) {
        QqlToolsProcessIssue.launchFailed => QqlToolsFailure.launchFailed,
        QqlToolsProcessIssue.timedOut => QqlToolsFailure.timedOut,
        QqlToolsProcessIssue.outputTooLarge => QqlToolsFailure.outputTooLarge,
      };

  Future<void> _log(
    String action,
    QqlToolsFailure? failure, {
    int? exitCode,
    int? stderrLength,
    int? osErrorCode,
  }) => _diagnosticLog.logInfo(
    'QQL-Tools $action: ${failure?.name ?? 'completed'}; '
    'exit=${exitCode ?? 'none'}; stderrChars=${stderrLength ?? 0}'
    '${osErrorCode == null ? '' : '; osErrorCode=$osErrorCode'}',
  );
}
