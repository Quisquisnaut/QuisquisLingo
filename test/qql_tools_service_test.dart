import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/qql_tools_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Runner implements QqlToolsProcessRunner {
  QqlToolsProcessOutput output = const QqlToolsProcessOutput(
    exitCode: 0,
    stdout: '',
    stderr: '',
  );
  Object? error;
  int calls = 0;
  String? executable;
  List<String>? arguments;

  @override
  Future<QqlToolsProcessOutput> run(
    String executable,
    List<String> arguments, {
    required Duration timeout,
  }) async {
    calls++;
    this.executable = executable;
    this.arguments = List.of(arguments);
    if (error case final failure?) throw failure;
    return output;
  }
}

String _report({
  bool isValid = true,
  bool isFullyValid = false,
  List<Object> errors = const [],
  List<String> unsupported = const ['media digest verification'],
  Map<String, Object?> extras = const {},
}) => jsonEncode({
  'source': 'selected course',
  'is_valid': isValid,
  'is_fully_valid': isFullyValid,
  'errors': errors,
  'notes': ['A note from QQL-Tools'],
  'implemented_checks': ['JSON decoding'],
  'unsupported_checks': unsupported,
  ...extras,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late ProfileService profiles;
  late SettingsService settings;
  late String adminId;
  late File executable;
  late File course;
  late _Runner runner;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('qql_tools_service_');
    profiles = ProfileService();
    adminId = (await profiles.createProfile('Admin')).learnerProfileId;
    await profiles.setActiveProfileById(adminId);
    settings = SettingsService();
    executable = File('${temp.path}${Platform.pathSeparator}qql-tools.exe');
    await executable.writeAsString('fake executable');
    course = File('${temp.path}${Platform.pathSeparator}A course; name.json');
    await course.writeAsString('{}');
    runner = _Runner();
    await settings.setQqlToolsExecutablePath(
      actorProfileId: adminId,
      path: executable.path,
    );
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a handle.
    }
  });

  QqlToolsService service({bool desktop = true}) => QqlToolsService(
    settings: settings,
    profiles: profiles,
    runner: runner,
    desktopAvailable: desktop,
  );

  test('Test starts the configured executable with --help', () async {
    runner.output = const QqlToolsProcessOutput(
      exitCode: 0,
      stdout: 'usage: qql-tools',
      stderr: '',
    );

    final result = await service().testAvailability(actorProfileId: adminId);

    expect(result.available, isTrue);
    expect(runner.executable, executable.path);
    expect(runner.arguments, ['--help']);
  });

  test('Test handles missing executable and failed --help', () async {
    await executable.delete();
    final missing = await service().testAvailability(actorProfileId: adminId);
    expect(missing.failure, QqlToolsFailure.invalidExecutable);
    expect(runner.calls, 0);

    await executable.writeAsString('fake executable');
    runner.output = const QqlToolsProcessOutput(
      exitCode: 1,
      stdout: '',
      stderr: 'error',
    );
    final failed = await service().testAvailability(actorProfileId: adminId);
    expect(failed.available, isFalse);
    expect(failed.failure, QqlToolsFailure.helpFailed);
  });

  test(
    'validation passes a strange Course path as one separate argument',
    () async {
      runner.output = QqlToolsProcessOutput(
        exitCode: 2,
        stdout: _report(),
        stderr: '',
      );

      final result = await service().validateCourse(
        actorProfileId: adminId,
        coursePath: course.path,
      );

      expect(runner.arguments, ['validate', course.path, '--json']);
      expect(
        result.report?.status,
        QqlToolsValidationStatus.validForImplementedChecks,
      );
      expect(result.report?.unsupportedChecks, ['media digest verification']);
      expect(result.report?.notes, ['A note from QQL-Tools']);
    },
  );

  test('exit 0 is Fully valid only when the JSON agrees', () async {
    runner.output = QqlToolsProcessOutput(
      exitCode: 0,
      stdout: _report(isFullyValid: true, unsupported: const []),
      stderr: '',
    );
    final full = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(full.report?.status, QqlToolsValidationStatus.fullyValid);

    runner.output = QqlToolsProcessOutput(
      exitCode: 0,
      stdout: _report(),
      stderr: '',
    );
    final partial = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(partial.failure, QqlToolsFailure.malformedJson);
    expect(partial.report, isNull);
  });

  test('contradictory validation exit and JSON are report failures', () async {
    runner.output = QqlToolsProcessOutput(
      exitCode: 1,
      stdout: _report(isFullyValid: true, unsupported: const []),
      stderr: '',
    );
    var result = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(result.failure, QqlToolsFailure.malformedJson);

    runner.output = QqlToolsProcessOutput(
      exitCode: 2,
      stdout: _report(
        isValid: false,
        errors: const [
          {'code': 'invalid-root', 'message': 'Invalid root'},
        ],
      ),
      stderr: '',
    );
    result = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(result.failure, QqlToolsFailure.malformedJson);
  });

  test('exit 1 displays structured errors, including location', () async {
    runner.output = QqlToolsProcessOutput(
      exitCode: 1,
      stdout: _report(
        isValid: false,
        errors: const [
          {
            'code': 'missing-course-id',
            'message': 'courseId is missing',
            'location': 'courseId',
          },
        ],
      ),
      stderr: '',
    );
    final result = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(result.report?.status, QqlToolsValidationStatus.invalid);
    expect(result.report?.errors.single.code, 'missing-course-id');
    expect(result.report?.errors.single.message, 'courseId is missing');
    expect(result.report?.errors.single.location, 'courseId');
  });

  test('additional unknown JSON fields do not break reports', () async {
    runner.output = QqlToolsProcessOutput(
      exitCode: 2,
      stdout: _report(
        extras: const {
          'future_field': {'anything': true},
        },
      ),
      stderr: '',
    );
    final result = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(result.report?.implementedChecks, ['JSON decoding']);
    expect(result.failure, isNull);
  });

  test(
    'empty and malformed stdout are report failures even for exit 1',
    () async {
      runner.output = const QqlToolsProcessOutput(
        exitCode: 1,
        stdout: ' ',
        stderr: 'traceback',
      );
      var result = await service().validateCourse(
        actorProfileId: adminId,
        coursePath: course.path,
      );
      expect(result.failure, QqlToolsFailure.emptyOutput);

      runner.output = const QqlToolsProcessOutput(
        exitCode: 0,
        stdout: '{oops',
        stderr: '',
      );
      result = await service().validateCourse(
        actorProfileId: adminId,
        coursePath: course.path,
      );
      expect(result.failure, QqlToolsFailure.malformedJson);
    },
  );

  test('unknown exit code is an execution problem', () async {
    runner.output = QqlToolsProcessOutput(
      exitCode: 7,
      stdout: _report(),
      stderr: '',
    );
    final result = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(result.failure, QqlToolsFailure.unknownExitCode);
    expect(result.report, isNull);
  });

  test('launch, timeout and output-limit failures remain distinct', () async {
    for (final entry in <(QqlToolsProcessIssue, QqlToolsFailure)>[
      (QqlToolsProcessIssue.launchFailed, QqlToolsFailure.launchFailed),
      (QqlToolsProcessIssue.timedOut, QqlToolsFailure.timedOut),
      (QqlToolsProcessIssue.outputTooLarge, QqlToolsFailure.outputTooLarge),
    ]) {
      runner.error = QqlToolsProcessException(entry.$1);
      final result = await service().validateCourse(
        actorProfileId: adminId,
        coursePath: course.path,
      );
      expect(result.failure, entry.$2);
    }
  });

  test(
    'launch diagnostics retain the OS error code without the file path',
    () async {
      runner.error = const QqlToolsProcessException(
        QqlToolsProcessIssue.launchFailed,
        osErrorCode: 5,
      );

      final result = await service().testAvailability(actorProfileId: adminId);

      expect(result.failure, QqlToolsFailure.launchFailed);
      final prefs = await SharedPreferences.getInstance();
      final log = prefs.getString('quisquislingo_diagnostic_log')!;
      expect(log, contains('osErrorCode=5'));
      expect(log, isNot(contains(executable.path)));
    },
  );

  test('mobile never invokes the process runner', () async {
    final tools = service(desktop: false);
    final check = await tools.testAvailability(actorProfileId: adminId);
    final validation = await tools.validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(check.failure, QqlToolsFailure.unsupportedPlatform);
    expect(validation.failure, QqlToolsFailure.unsupportedPlatform);
    expect(runner.calls, 0);
  });

  test('an unavailable configuration leaves the app usable', () async {
    await settings.clearQqlToolsExecutablePath(actorProfileId: adminId);
    final check = await service().testAvailability(actorProfileId: adminId);
    final validation = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(check.failure, QqlToolsFailure.notConfigured);
    expect(validation.failure, QqlToolsFailure.notConfigured);
    expect(runner.calls, 0);
  });

  test(
    'a learner cannot start the external tool after a profile switch',
    () async {
      final learnerId = (await profiles.createProfile(
        'Learner',
      )).learnerProfileId;
      await profiles.setActiveProfileById(learnerId);

      final check = await service().testAvailability(actorProfileId: learnerId);
      final validation = await service().validateCourse(
        actorProfileId: learnerId,
        coursePath: course.path,
      );

      expect(check.failure, QqlToolsFailure.unauthorized);
      expect(validation.failure, QqlToolsFailure.unauthorized);
      expect(runner.calls, 0);
    },
  );

  test('only an existing JSON or ZIP file can be validated', () async {
    final invalidPath = File(
      '${temp.path}${Platform.pathSeparator}not-a-course.txt',
    );
    await invalidPath.writeAsString('{}');
    var result = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: invalidPath.path,
    );
    expect(result.failure, QqlToolsFailure.invalidCourseFile);

    await course.delete();
    result = await service().validateCourse(
      actorProfileId: adminId,
      coursePath: course.path,
    );
    expect(result.failure, QqlToolsFailure.invalidCourseFile);
    expect(runner.calls, 0);
  });
}
