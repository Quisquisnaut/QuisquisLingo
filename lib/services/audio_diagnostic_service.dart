import 'crash_log_service.dart';
import 'diagnostic_log_service.dart';

typedef AudioCrashWriter = Future<void> Function(String message);

/// One short, correlation-ID-based diagnostic lifecycle for an audio request.
///
/// The event budget prevents a failing backend from flooding either existing
/// log. Callers provide only technical tokens; spoken text, course content and
/// paths are deliberately absent from this API.
class AudioDiagnosticLifecycle {
  static const int maximumEvents = 8;
  static int _sequence = 0;

  final String correlationId;
  final String kind;
  final DiagnosticLogService _diagnosticLog;
  final AudioCrashWriter _crashWriter;
  final bool _enabled;
  int _eventCount = 0;
  bool _disposed = false;

  AudioDiagnosticLifecycle._({
    required this.correlationId,
    required this.kind,
    required DiagnosticLogService diagnosticLog,
    required AudioCrashWriter crashWriter,
    required bool enabled,
  }) : _diagnosticLog = diagnosticLog,
       _crashWriter = crashWriter,
       _enabled = enabled;

  factory AudioDiagnosticLifecycle.start({
    required String kind,
    DiagnosticLogService? diagnosticLog,
    AudioCrashWriter? crashWriter,
    bool enabled = true,
  }) {
    final serial = _sequence++;
    final correlationId =
        'audio-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
        '${serial.toRadixString(36)}';
    return AudioDiagnosticLifecycle._(
      correlationId: correlationId,
      kind: _token(kind),
      diagnosticLog: diagnosticLog ?? DiagnosticLogService(),
      crashWriter:
          crashWriter ?? CrashLogService.instance.recordAudioDiagnostic,
      enabled: enabled,
    );
  }

  Future<void> event(
    String phase, {
    required String outcome,
    String? backend,
    String? language,
    int? count,
    String? failureType,
    String? uiState,
    String? targetExerciseId,
    String? exerciseType,
    bool? prepared,
    bool? active,
    String? trigger,
  }) async {
    if (!_enabled) return;
    if (_disposed || _eventCount >= maximumEvents - 1) return;
    _eventCount++;
    await _write(
      phase,
      outcome: outcome,
      backend: backend,
      language: language,
      count: count,
      failureType: failureType,
      uiState: uiState,
      targetExerciseId: targetExerciseId,
      exerciseType: exerciseType,
      prepared: prepared,
      active: active,
      trigger: trigger,
    );
  }

  Future<void> dispose({required String outcome}) async {
    if (!_enabled) return;
    if (_disposed) return;
    _disposed = true;
    _eventCount++;
    await _write('disposal', outcome: outcome);
  }

  Future<void> _write(
    String phase, {
    required String outcome,
    String? backend,
    String? language,
    int? count,
    String? failureType,
    String? uiState,
    String? targetExerciseId,
    String? exerciseType,
    bool? prepared,
    bool? active,
    String? trigger,
  }) async {
    final message = StringBuffer('AUDIO')
      ..write(' correlationId=$correlationId')
      ..write(' kind=$kind')
      ..write(' phase=${_token(phase)}')
      ..write(' outcome=${_token(outcome)}');
    if (backend != null) message.write(' backend=${_token(backend)}');
    if (language != null) message.write(' language=${_token(language)}');
    if (count != null) message.write(' count=${count.clamp(0, 10000)}');
    if (failureType != null) {
      message.write(' failureType=${_token(failureType)}');
    }
    if (uiState != null) message.write(' uiState=${_token(uiState)}');
    if (targetExerciseId != null) {
      message.write(' targetExerciseId=${_token(targetExerciseId)}');
    }
    if (exerciseType != null) {
      message.write(' exerciseType=${_token(exerciseType)}');
    }
    if (prepared != null) message.write(' prepared=$prepared');
    if (active != null) message.write(' active=$active');
    if (trigger != null) message.write(' trigger=${_token(trigger)}');
    final value = message.toString();
    await Future.wait([_diagnosticLog.logInfo(value), _crashWriter(value)]);
  }

  static String _token(String value) {
    final trimmed = value.trim();
    if (trimmed.contains('/') || trimmed.contains(r'\')) {
      return 'path-redacted';
    }
    final sanitized = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9_.:-]'), '_');
    if (sanitized.isEmpty) return 'none';
    return sanitized.length <= 48 ? sanitized : sanitized.substring(0, 48);
  }
}
