import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';

void main() {
  test(
    'technical version is unchanged while the public build label is clear',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(AppMetadata.technicalVersion, '2.0.33+233030');
      expect(AppMetadata.publicBuildLabel, 'Build 233.1');
      expect(AppMetadata.displayLabel, 'Version 2.0.33\nBuild 233.1');
      expect(pubspec, contains('version: 2.0.33+233030'));
    },
  );

  test('platform application identities use the QuisquisLingo namespace', () {
    final linux = File('linux/CMakeLists.txt').readAsStringSync();
    final android = File('android/app/build.gradle.kts').readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/org/quisquislingo/app/MainActivity.kt',
    ).readAsStringSync();
    final windows = File('windows/runner/Runner.rc').readAsStringSync();

    expect(linux, contains('APPLICATION_ID "org.quisquislingo.app"'));
    expect(android, contains('namespace = "org.quisquislingo.app"'));
    expect(android, contains('applicationId = "org.quisquislingo.app"'));
    expect(activity, contains('package org.quisquislingo.app'));
    expect(windows, contains('VALUE "CompanyName", "QuisquisLingo"'));
    for (final source in [linux, android, activity, windows]) {
      expect(source, isNot(contains('com.example')));
    }
    expect(
      File(
        'android/app/src/main/kotlin/com/example/quisquislingo_app/MainActivity.kt',
      ).existsSync(),
      isFalse,
    );
  });

  test('one crash-log writer uses the authoritative Documents log tree', () {
    final dartSources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    final writers = dartSources.where(
      (file) => file.readAsStringSync().contains('quisquislingo_crash.log'),
    );
    final crash = File(
      'lib/services/crash_log_service.dart',
    ).readAsStringSync();
    final directory = File(
      'lib/services/diagnostic_log_service.dart',
    ).readAsStringSync();
    final debug = File('lib/screens/debug_screen.dart').readAsStringSync();

    expect(writers.map((file) => file.path.replaceAll('\\', '/')), [
      'lib/services/crash_log_service.dart',
    ]);
    expect(crash, contains('DiagnosticLogService.logsDirectory(create: true)'));
    expect(directory, contains('getApplicationDocumentsDirectory()'));
    expect(directory, contains('QuisquisLingo'));
    expect(directory, contains('Logs'));
    expect(debug, contains("tooltip: 'Share Crash Log'"));
  });

  test(
    'default Recovery Key actions use Imports and Exports without pickers',
    () {
      final service = File(
        'lib/services/user_recovery_key_service.dart',
      ).readAsStringSync();
      final screen = File(
        'lib/screens/user_data_settings_screen.dart',
      ).readAsStringSync();

      expect(service, contains("'Exports'"));
      expect(service, contains("'Imports'"));
      expect(screen, contains('Export User Recovery Key'));
      expect(screen, contains('Import User Recovery Key'));
      expect(screen, isNot(contains('FilePicker')));
    },
  );

  test(
    'Learner Profiles and duplicate-name warnings keep required wording',
    () {
      final home = File('lib/screens/home_screen.dart').readAsStringSync();
      final profile = File(
        'lib/screens/profile_screen.dart',
      ).readAsStringSync();
      final team = File(
        'lib/screens/team_manager_screen.dart',
      ).readAsStringSync();
      final courseManager = File(
        'lib/screens/course_projects_screen.dart',
      ).readAsStringSync();
      final courseEditor = File(
        'lib/screens/course_editor_screen.dart',
      ).readAsStringSync();

      expect(home, contains("Text('Learners on \$_deviceDisplayName')"));
      expect(home, contains("' (admin)'"));
      expect(home, contains("'\${profile.discordHandle} on Discord'"));
      expect(home, contains("child: Text('Reset PIN')"));
      expect(profile, contains('A user with this Screen Name already exists.'));
      for (final source in [team, courseManager, courseEditor]) {
        expect(source, contains('Continue anyway'));
        expect(source, contains('already exists'));
      }
    },
  );
}
