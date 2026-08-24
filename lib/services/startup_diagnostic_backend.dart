enum StartupDiagnosticLevel { normal, verbose }

StartupDiagnosticLevel parseStartupDiagnosticLevel(String? value) {
  return value?.trim().toLowerCase() == 'verbose'
      ? StartupDiagnosticLevel.verbose
      : StartupDiagnosticLevel.normal;
}

class StartupDiagnosticSession {
  const StartupDiagnosticSession({
    required this.sessionId,
    required this.startedAtUtc,
    required this.appVersion,
    required this.isAlpha,
    required this.buildMode,
    required this.platform,
    required this.architecture,
    required this.level,
  });

  static const int schemaVersion = 1;

  final String sessionId;
  final DateTime startedAtUtc;
  final String appVersion;
  final bool isAlpha;
  final String buildMode;
  final String platform;
  final String architecture;
  final StartupDiagnosticLevel level;
}

abstract interface class StartupDiagnosticBackend {
  StartupDiagnosticSession get session;
  int get processId;
  String get resolvedLogPath;
  Iterable<String> get sensitiveValues;

  void append(String text);
}

class DisabledStartupDiagnosticBackend implements StartupDiagnosticBackend {
  DisabledStartupDiagnosticBackend(StartupDiagnosticLevel level)
    : session = StartupDiagnosticSession(
        sessionId: 'disabled',
        startedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        appVersion: 'unknown',
        isAlpha: true,
        buildMode: 'unknown',
        platform: 'unsupported',
        architecture: 'unknown',
        level: level,
      );

  @override
  final StartupDiagnosticSession session;

  @override
  int get processId => 0;

  @override
  String get resolvedLogPath => '';

  @override
  Iterable<String> get sensitiveValues => const <String>[];

  @override
  void append(String text) {}
}

bool shouldRotateStartupDiagnosticLog(
  int length, {
  int maximumBytes = 1024 * 1024,
}) {
  return length >= maximumBytes;
}

String formatStartupDiagnosticSessionHeader(StartupDiagnosticSession session) {
  String safe(String value) =>
      sanitizeStartupDiagnosticText(value, maximumLength: 80);
  return '=== QUISQUISLINGO_STARTUP_SESSION '
      'schema=${StartupDiagnosticSession.schemaVersion} '
      'session=${safe(session.sessionId)} '
      'start_utc=${session.startedAtUtc.toUtc().toIso8601String()} '
      'version=${safe(session.appVersion)} '
      'alpha=${session.isAlpha} '
      'build_mode=${safe(session.buildMode)} '
      'platform=${safe(session.platform)} '
      'arch=${safe(session.architecture)} '
      'level=${session.level.name} ===\r\n';
}

String sanitizeStartupDiagnosticText(
  String value, {
  Iterable<String> sensitiveValues = const <String>[],
  int maximumLength = 512,
}) {
  var result = value.replaceAll(RegExp(r'[\u0000-\u001f\u007f]+'), ' ');

  result = result.replaceAll(
    RegExp(r'file:\/\/\/[^\s;,"\x27]+', caseSensitive: false),
    '<path>',
  );
  result = result.replaceAll(
    RegExp(r'(?:[A-Za-z]:[\\/]|\\\\)[^\s;,"\x27]+'),
    '<path>',
  );
  result = result.replaceAllMapped(
    RegExp(r'(^|[\s=])/(?:[^\s;,"\x27]+)'),
    (match) => '${match.group(1)}<path>',
  );

  final redactions =
      sensitiveValues.where((entry) => entry.trim().isNotEmpty).toSet().toList()
        ..sort((left, right) => right.length.compareTo(left.length));
  for (final sensitiveValue in redactions) {
    result = result.replaceAll(
      RegExp(RegExp.escape(sensitiveValue), caseSensitive: false),
      '<redacted>',
    );
  }
  result = result.replaceAll('"', "'").trim().replaceAll(RegExp(r'\s+'), ' ');

  if (maximumLength <= 0) return '';
  if (result.length <= maximumLength) return result;
  if (maximumLength <= 3) return '.' * maximumLength;
  return '${result.substring(0, maximumLength - 3)}...';
}

String startupDiagnosticFingerprint(Object value) {
  var hash = 0x811c9dc5;
  for (final codeUnit in value.toString().codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
