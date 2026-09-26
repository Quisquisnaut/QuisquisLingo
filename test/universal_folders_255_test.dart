import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/crash_log_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _sep = Platform.pathSeparator;

/// Build 255 Revision 3: one folder pattern on every system. The layout
/// itself is checked in storage_roles_255_test.dart and, for Android, in
/// android_quick_folders_255_test.dart.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<String> qqlRoot() async =>
      '${(await getApplicationDocumentsDirectory()).path}${_sep}QuisquisLingo';

  Future<File> put(String root, String relative, [List<int> bytes = const [1]])
      async {
    final file = File('$root$_sep${relative.replaceAll('/', _sep)}');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return file;
  }

  group('Build 255 Revision 3 flag and export names', () {
    test('Upload custom flag reads Import/Flags, not the Exports folder '
        'earlier versions used', () async {
      await put(await qqlRoot(), 'Exports/flag.png');
      await expectLater(
        CourseFlagService().importPreparedFlag(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('No flag image found'),
              contains('Import${_sep}Flags'),
            ),
          ),
        ),
      );
    });

    test('learner backups and the Diagnostic Log copy start with QQL_',
        () async {
      await ProfileService().createProfile('Ada Lovelace');
      final backup = await LearnerBackupService().saveActiveProfile();
      expect(
        File(backup).parent.path,
        '${await qqlRoot()}${_sep}Export${_sep}UserData',
      );
      // Screen names carry a number suffix, e.g. `ada_lovelace_12345`.
      expect(
        File(backup).uri.pathSegments.last,
        allOf(startsWith('QQL_ada_lovelace'), endsWith('_backup.json')),
      );

      final logs = DiagnosticLogService();
      await logs.logInfo('something happened');
      final copy = await logs.exportToFile();
      expect(copy, '${await qqlRoot()}${_sep}Logs${_sep}QQL_diagnostic_log.txt');
    });
  });

  group('Build 255 private Crash Log and public Course Backups', () {
    test('the live Crash Log lives in QQL\'s private storage and the Course '
        'Backups in the Backups folder', () async {
      final support = (await getApplicationSupportDirectory()).path;
      // Revision 4 gave the log folder a QQL_ name; Revision 5 moved the
      // Course Backups beside Import and Export.
      expect(
        (await DiagnosticLogService.logsDirectory())!.path,
        '$support${_sep}QQL_Logs',
      );
      expect(
        (await CourseBackupService().backupRoot()).path,
        '${await qqlRoot()}${_sep}Backups${_sep}Courses',
      );
    });

    test('Quick Export copies the live Crash Log into Logs as '
        'QQL_crash_log.txt and replaces the previous copy', () async {
      final crash = CrashLogService.instance;
      await crash.initialise();
      final live = File(crash.crashLogPath!);
      expect(
        live.parent.path,
        '${(await getApplicationSupportDirectory()).path}${_sep}QQL_Logs',
      );
      expect(live.uri.pathSegments.last, 'QQL_crash.log');
      final expected = '${await qqlRoot()}${_sep}Logs${_sep}QQL_crash_log.txt';
      expect(await crash.exportPath(), expected);

      final first = await crash.exportCopy();
      expect(first!.location, expected);
      expect(await File(expected).readAsString(), await live.readAsString());

      await live.writeAsString('later entry\n', mode: FileMode.append);
      final second = await crash.exportCopy();
      expect(second!.location, expected);
      expect(await File(expected).readAsString(), endsWith('later entry\n'));
      expect(
        Directory(File(expected).parent.path).listSync().whereType<File>(),
        hasLength(1),
      );
    });
  });

  group('Build 255 Revision 3 Inventory and Wipe everything on desktop', () {
    late Directory documents;
    late Directory support;
    late String qql;

    setUp(() async {
      final root = await Directory.systemTemp.createTemp('qql_r3_folders_');
      addTearDown(() => root.delete(recursive: true));
      documents = await Directory('${root.path}${_sep}documents').create();
      support = await Directory('${root.path}${_sep}support').create();
      qql = '${documents.path}${_sep}QuisquisLingo';
      for (final relative in [
        'Export/Courses/QQL_a.zip',
        'Import/Courses/import.zip',
        'ToBeMerged/Courses/merge.zip',
        'Logs/QQL_crash_log.txt',
        'Imports/old.zip',
        'Exports/Course Backups v11/c1/backup.json',
        'Merges/merge.zip',
        'Notes/readme.txt',
        'Backups/Courses/QQL_bkp_EN_IT_c1/backup.json',
      ]) {
        await put(qql, relative);
      }
      await put(support.path, 'QQL_Logs/QQL_crash.log');
      // The private backup folders of Revisions 4 and 3.
      await put(support.path, 'QQL_CourseBackups/QQL_bkp_EN_IT_c1/backup.json');
      await put(support.path, 'qql_course_backups_v11/c1/backup.json');
    });

    test('Inventory lists the five folders, the private Crash Log and the '
        'folders earlier versions used', () async {
      final sections = await InventoryService(
        documentsDirectory: () async => documents,
        supportDirectory: () async => support,
        courses: () async => const [],
        teams: () async => const [],
      ).load();
      List<String> names(String title) => [
        for (final item in sections.singleWhere((s) => s.title == title).items)
          item.name.replaceAll(r'\', '/'),
      ]..sort();

      expect(names('Export folder'), ['Courses/QQL_a.zip']);
      expect(names('Import folder'), ['Courses/import.zip']);
      expect(names('ToBeMerged folder'), ['Courses/merge.zip']);
      expect(names('Logs folder'), ['QQL_crash_log.txt']);
      expect(names('Backups folder'), [
        'Courses/QQL_bkp_EN_IT_c1/backup.json',
      ]);
      expect(names('Crash Log'), ['QQL_crash.log']);
      expect(names('Private folders from earlier versions'), [
        'QQL_CourseBackups/QQL_bkp_EN_IT_c1/backup.json',
        'qql_course_backups_v11/c1/backup.json',
      ]);
      expect(names('Folders from earlier versions'), [
        'Exports/Course Backups v11/c1/backup.json',
        'Imports/old.zip',
        'Merges/merge.zip',
      ]);
      expect(names('Other files in the QQL folder'), ['Notes/readme.txt']);
    });

    Future<void> wipe({
      bool keepExports = true,
      bool keepLogs = true,
      bool keepImports = true,
      bool keepBackups = true,
    }) async {
      final profiles = ProfileService();
      final admin = (await profiles.createProfile('Admin')).learnerProfileId;
      await profiles.setOwnAccessPin(actorProfileId: admin, pin: '1234');
      await AppResetService(
        profiles: profiles,
        documentsDirectory: () async => documents,
        supportDirectory: () async => support,
      ).reset(
        AppResetScope.everything,
        actorProfileId: admin,
        pin: '1234',
        keepExports: keepExports,
        keepLogs: keepLogs,
        keepImports: keepImports,
        keepBackups: keepBackups,
      );
    }

    List<String> topLevel(String path) => [
      for (final entity in Directory(path).listSync())
        entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
    ]..sort();

    test('a full wipe keeps each ticked folder with its earlier '
        'counterparts', () async {
      const earlierBackups = ['QQL_CourseBackups', 'qql_course_backups_v11'];
      await wipe();
      expect(topLevel(qql), [
        'Backups',
        'Export',
        'Exports',
        'Import',
        'Imports',
        'Logs',
        'Merges',
        'ToBeMerged',
      ]);
      expect(topLevel(support.path), [...earlierBackups, 'QQL_Logs']..sort());

      await wipe(keepExports: false, keepImports: false);
      expect(topLevel(qql), ['Backups', 'Logs']);
      expect(topLevel(support.path), [...earlierBackups, 'QQL_Logs']..sort());

      await wipe(keepLogs: false);
      expect(topLevel(qql), ['Backups']);
      expect(topLevel(support.path), earlierBackups);

      await wipe(keepBackups: false);
      expect(topLevel(qql), isEmpty);
      expect(topLevel(support.path), isEmpty);
    });
  });
}
