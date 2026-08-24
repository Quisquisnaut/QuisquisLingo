import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/startup_diagnostic_backend.dart';
import 'package:quisquislingo_app/services/startup_diagnostic_backend_io.dart';
import 'package:quisquislingo_app/services/startup_diagnostic_service.dart';

void main() {
  const startedAt = '2026-08-19T12:34:56.000Z';

  test('normal mode is default and filters verbose checkpoints', () {
    expect(parseStartupDiagnosticLevel(null), StartupDiagnosticLevel.normal);
    expect(
      parseStartupDiagnosticLevel('verbose'),
      StartupDiagnosticLevel.verbose,
    );

    final backend = _MemoryBackend(StartupDiagnosticLevel.normal);
    final logger = StartupDiagnosticLogger(
      backend,
      now: () => DateTime.parse(startedAt),
    );

    logger.checkpoint('NORMAL_MARKER');
    logger.checkpoint(
      'VERBOSE_MARKER',
      requiredLevel: StartupDiagnosticLevel.verbose,
    );

    expect(backend.output, contains('NORMAL_MARKER'));
    expect(backend.output, isNot(contains('VERBOSE_MARKER')));
  });

  test('verbose mode includes normal and verbose checkpoints', () {
    final backend = _MemoryBackend(StartupDiagnosticLevel.verbose);
    final logger = StartupDiagnosticLogger(backend);

    logger.checkpoint('NORMAL_MARKER');
    logger.checkpoint(
      'VERBOSE_MARKER',
      requiredLevel: StartupDiagnosticLevel.verbose,
    );

    expect(backend.output, contains('NORMAL_MARKER'));
    expect(backend.output, contains('VERBOSE_MARKER'));
  });

  test('session header contains the permanent schema and support fields', () {
    final header = formatStartupDiagnosticSessionHeader(
      StartupDiagnosticSession(
        sessionId: 'session-205',
        startedAtUtc: DateTime.parse(startedAt),
        appVersion: '2.0.5+205',
        isAlpha: true,
        buildMode: 'release',
        platform: 'windows',
        architecture: 'x64',
        level: StartupDiagnosticLevel.normal,
      ),
    );

    expect(header, startsWith('=== QUISQUISLINGO_STARTUP_SESSION schema=1'));
    expect(header, contains('session=session-205'));
    expect(header, contains('start_utc=$startedAt'));
    expect(header, contains('version=2.0.5+205'));
    expect(header, contains('alpha=true'));
    expect(header, contains('build_mode=release'));
    expect(header, contains('platform=windows'));
    expect(header, contains('arch=x64'));
    expect(header, contains('level=normal'));
  });

  test('diagnostic text removes personal paths and bounded sensitive text', () {
    final sanitized = sanitizeStartupDiagnosticText(
      'user=Alice path=C:\\Users\\Alice\\private\\course.json\n'
      'uri=file:///C:/Users/Alice/private/course.json',
      sensitiveValues: const ['Alice', r'C:\Users\Alice'],
      maximumLength: 90,
    );

    expect(sanitized, isNot(contains('Alice')));
    expect(sanitized, isNot(contains('course.json')));
    expect(sanitized, contains('<redacted>'));
    expect(sanitized.length, lessThanOrEqualTo(90));
    expect(sanitized, isNot(contains('\n')));
  });

  test(
    'errors record bounded categories and fingerprints, not raw content',
    () {
      final backend = _MemoryBackend(
        StartupDiagnosticLevel.normal,
        sensitiveValues: const ['Learner Secret'],
      );
      final logger = StartupDiagnosticLogger(backend);
      final error = StateError(
        r'Learner Secret at C:\Users\Alice\private\answer.txt',
      );
      final stack = StackTrace.fromString(
        r'#0 handler (C:\Users\Alice\source\main.dart:10:3)',
      );

      logger.recordError('runZonedGuarded', error, stack);

      expect(backend.output, contains('checkpoint=DART_UNCAUGHT_ERROR'));
      expect(backend.output, contains('error_type=StateError'));
      expect(backend.output, contains('error_fingerprint='));
      expect(backend.output, contains('stack_fingerprint='));
      expect(backend.output, isNot(contains('Learner Secret')));
      expect(backend.output, isNot(contains('answer.txt')));
      expect(backend.output, isNot(contains(r'C:\Users')));
    },
  );

  test('checkpoint context is bounded', () {
    final backend = _MemoryBackend(StartupDiagnosticLevel.normal);
    final logger = StartupDiagnosticLogger(backend);

    logger.checkpoint('BOUNDED_CONTEXT', context: 'x' * 2000);

    expect(backend.output, contains('...'));
    expect(backend.output.length, lessThan(700));
  });

  test('rotation keeps two previous logs and starts a new active log', () {
    final directory = Directory.systemTemp.createTempSync(
      'quisquislingo_startup_diagnostic_test_',
    );
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    final path = '${directory.path}${Platform.pathSeparator}startup.log';
    File(path).writeAsStringSync('active-log');
    File('$path.1').writeAsStringSync('previous-log');
    File('$path.2').writeAsStringSync('oldest-log');

    rotateStartupDiagnosticLogs(path, maximumBytes: 5);

    expect(File(path).existsSync(), isFalse);
    expect(File('$path.1').readAsStringSync(), 'active-log');
    expect(File('$path.2').readAsStringSync(), 'previous-log');
  });

  test('diagnostic backend failures never propagate', () {
    final logger = StartupDiagnosticLogger(_ThrowingBackend());

    expect(() => logger.checkpoint('SAFE_FAILURE'), returnsNormally);
    expect(
      () => logger.recordError(
        'test',
        StateError('private value'),
        StackTrace.current,
      ),
      returnsNormally,
    );
    expect(
      () => rotateStartupDiagnosticLogs(r'Z:\missing\startup.log'),
      returnsNormally,
    );
  });

  test('application-facing static facade retains startup call signatures', () {
    void Function(String, [String?]) normal =
        StartupDiagnosticService.checkpoint;
    void Function(String, [String?]) verbose =
        StartupDiagnosticService.verboseCheckpoint;
    void Function(String, [String?]) once =
        StartupDiagnosticService.checkpointOnce;

    expect(normal, isNotNull);
    expect(verbose, isNotNull);
    expect(once, isNotNull);
  });
}

class _MemoryBackend implements StartupDiagnosticBackend {
  _MemoryBackend(
    StartupDiagnosticLevel level, {
    this.sensitiveValues = const <String>[],
  }) : session = StartupDiagnosticSession(
         sessionId: 'test-session',
         startedAtUtc: DateTime.utc(2026, 8, 19),
         appVersion: '2.0.5+205',
         isAlpha: true,
         buildMode: 'test',
         platform: 'windows',
         architecture: 'x64',
         level: level,
       );

  final StringBuffer _output = StringBuffer();

  String get output => _output.toString();

  @override
  final StartupDiagnosticSession session;

  @override
  int get processId => 205;

  @override
  String get resolvedLogPath => '';

  @override
  final Iterable<String> sensitiveValues;

  @override
  void append(String text) => _output.write(text);
}

class _ThrowingBackend extends _MemoryBackend {
  _ThrowingBackend() : super(StartupDiagnosticLevel.normal);

  @override
  void append(String text) => throw FileSystemException('expected failure');
}
