import 'startup_diagnostic_backend.dart';
import 'startup_diagnostic_backend_stub.dart'
    if (dart.library.io) 'startup_diagnostic_backend_io.dart'
    as platform_backend;

export 'startup_diagnostic_backend.dart' show StartupDiagnosticLevel;

/// Permanent, dependency-light startup lifecycle diagnostics.
///
/// Normal checkpoints are enabled by default in Alpha builds. Set the process
/// environment variable `QUISQUISLINGO_STARTUP_DIAGNOSTICS=verbose` before launch
/// to include low-level diagnostic checkpoints. Logging failures are always
/// ignored so this service cannot prevent normal application startup.
class StartupDiagnosticService {
  static final StartupDiagnosticLogger _logger = StartupDiagnosticLogger(
    platform_backend.createStartupDiagnosticBackend(),
  );

  static String get resolvedLogPath => _logger.resolvedLogPath;

  static StartupDiagnosticLevel get level => _logger.level;

  static void checkpoint(String name, [String? context]) {
    _logger.checkpoint(name, context: context);
  }

  static void verboseCheckpoint(String name, [String? context]) {
    _logger.checkpoint(
      name,
      context: context,
      requiredLevel: StartupDiagnosticLevel.verbose,
    );
  }

  static void checkpointOnce(String name, [String? context]) {
    _logger.checkpointOnce(name, context: context);
  }

  static void verboseCheckpointOnce(String name, [String? context]) {
    _logger.checkpointOnce(
      name,
      context: context,
      requiredLevel: StartupDiagnosticLevel.verbose,
    );
  }

  static void recordError(String source, Object error, StackTrace stackTrace) {
    _logger.recordError(source, error, stackTrace);
  }
}

class StartupDiagnosticLogger {
  StartupDiagnosticLogger(
    this._backend, {
    DateTime Function()? now,
    int? processId,
  }) : _now = now ?? DateTime.now,
       _processId = processId ?? _backend.processId;

  final StartupDiagnosticBackend _backend;
  final DateTime Function() _now;
  final int _processId;
  final Set<String> _once = <String>{};

  StartupDiagnosticLevel get level => _backend.session.level;
  String get resolvedLogPath => _backend.resolvedLogPath;

  void checkpoint(
    String name, {
    String? context,
    StartupDiagnosticLevel requiredLevel = StartupDiagnosticLevel.normal,
  }) {
    if (!_isEnabled(requiredLevel)) return;
    try {
      final safeName = sanitizeStartupDiagnosticText(name, maximumLength: 80);
      final safeContext = context == null
          ? ''
          : sanitizeStartupDiagnosticText(
              context,
              sensitiveValues: _backend.sensitiveValues,
            );
      final line = StringBuffer()
        ..write(_now().toUtc().toIso8601String())
        ..write(' checkpoint=$safeName')
        ..write(' session=${_backend.session.sessionId}');
      if (_processId > 0) line.write(' pid=$_processId');
      if (safeContext.isNotEmpty) line.write(' context="$safeContext"');
      line.write('\r\n');
      _backend.append(line.toString());
    } catch (_) {
      // Startup diagnostics must never affect application startup.
    }
  }

  void checkpointOnce(
    String name, {
    String? context,
    StartupDiagnosticLevel requiredLevel = StartupDiagnosticLevel.normal,
  }) {
    if (!_isEnabled(requiredLevel) || !_once.add(name)) return;
    checkpoint(name, context: context, requiredLevel: requiredLevel);
  }

  void recordError(String source, Object error, StackTrace stackTrace) {
    try {
      final firstFrame = stackTrace
          .toString()
          .split(RegExp(r'[\r\n]+'))
          .firstWhere((line) => line.trim().isNotEmpty, orElse: () => 'none');
      checkpoint(
        'DART_UNCAUGHT_ERROR',
        context:
            'source=$source; error_type=${error.runtimeType}; '
            'error_fingerprint=${startupDiagnosticFingerprint(error)}; '
            'stack_fingerprint=${startupDiagnosticFingerprint(stackTrace)}; '
            'first_frame=$firstFrame',
      );
    } catch (_) {
      checkpoint('DART_UNCAUGHT_ERROR', context: 'source=unknown');
    }
  }

  bool _isEnabled(StartupDiagnosticLevel requiredLevel) {
    return level.index >= requiredLevel.index;
  }
}
