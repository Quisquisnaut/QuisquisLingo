import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/crash_log_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/storage/android_storage_backend.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';
import 'package:quisquislingo_app/widgets/quick_import_access.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/dialog_test_course.dart';
import 'support/fake_android_storage.dart';
import 'support/fake_file_dialog_backend.dart';

QqlStorage _androidStorage() => QqlStorage(backend: AndroidStorageBackend());

CustomCourseTransferService _transfer(FakeFileDialogBackend dialogs) =>
    CustomCourseTransferService(
      storage: _androidStorage(),
      fileDialogs: FileDialogService(backend: dialogs, stager: testImportStager()),
      stager: testImportStager(),
    );

Future<Uint8List> _package() async {
  final course = dialogTestCourse();
  return CoursePackageService().build(
    course,
    Uint8List.fromList(utf8.encode(jsonEncode(course.toJson()))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAndroidStorage android;
  late FakeFileDialogBackend dialogs;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    android = FakeAndroidStorage();
    dialogs = FakeFileDialogBackend();
  });

  tearDown(() {
    android.dispose();
    QqlStorageLayout.debugOverride = null;
  });

  group('Build 255 Android layout', () {
    test('every folder is below Download/QuisquisLingo, in the same place as '
        'on desktop', () {
      const layout = QqlStorageLayout.androidPublic;
      expect(
        QqlStorageLayout.forPlatform(QqlStoragePlatform.android),
        same(layout),
      );
      final expected = <QqlStorageRole, String>{
        QqlStorageRole.courseImports: 'Import/Courses',
        QqlStorageRole.courseExports: 'Export/Courses',
        QqlStorageRole.mergeImports: 'ToBeMerged/Courses',
        QqlStorageRole.learnerDataImports: 'Import/UserData',
        QqlStorageRole.learnerDataExports: 'Export/UserData',
        QqlStorageRole.recoveryKeyImports: 'Import/RecoveryKeys',
        QqlStorageRole.recoveryKeyExports: 'Export/RecoveryKeys',
        QqlStorageRole.audioImports: 'Import/Audio',
        QqlStorageRole.imageImports: 'Import/Images',
        QqlStorageRole.lessonIconImports: 'Import/LessonIcons',
        QqlStorageRole.courseFlagImports: 'Import/Flags',
        QqlStorageRole.auditReportExports: 'Export/AuditReports',
        QqlStorageRole.diagnosticLogExports: 'Logs',
      };
      expect(expected.keys.toSet(), QqlStorageRole.values.toSet());
      for (final entry in expected.entries) {
        expect(
          layout.folderLabel(entry.key),
          'Download/QuisquisLingo/${entry.value}',
          reason: '${entry.key}',
        );
        expect(
          layout.segments(entry.key),
          QqlStorageLayout.documents.segments(entry.key),
          reason: '${entry.key}',
        );
      }
      expect(
        layout.topFolderLabel(QqlTopFolder.toBeMerged),
        'Download/QuisquisLingo/ToBeMerged',
      );
    });

    test('Help names the Android folders on Android', () {
      QqlStorageLayout.debugOverride = QqlStorageLayout.androidPublic;
      for (final locale in AppLocale.values) {
        expect(
          helpText.lookup(locale, 'editorHelp.importCustomCourse.body'),
          contains('Download/QuisquisLingo/Import/Courses/import.zip'),
        );
        final logs = helpText.lookup(
          locale,
          'appInfo.crashLogAndDiagnosticLog.body',
        );
        expect(logs, contains('Download/QuisquisLingo/Logs'));
        expect(logs, contains('Crash Log'));
        expect(
          helpText.lookup(locale, 'debugHelp.crashLog.body'),
          contains('QQL_crash_log.txt'),
        );
      }
    });
  });

  group('Build 255 Android Quick Export (Android 10 and later)', () {
    test('writes to Download/QuisquisLingo/Export/Courses with no dialog '
        'and no permission', () async {
      final transfer = _transfer(dialogs);
      final first = await transfer.exportCourse(dialogTestCourse());
      final second = await transfer.exportCourse(dialogTestCourse());
      expect(
        first,
        'Download/QuisquisLingo/Export/Courses/QQL_EN_IT_dialog_course.zip',
      );
      expect(
        second,
        'Download/QuisquisLingo/Export/Courses/QQL_EN_IT_dialog_course_2.zip',
      );
      final written = android.downloads[first]!;
      expect(written.sublist(0, 2), [0x50, 0x4B]); // a ZIP
      expect(android.uiCalls, isEmpty);
      expect(dialogs.startedIn, isEmpty);
      expect(android.allClosed, isTrue);
    });

    test('the Diagnostic Log snapshot replaces its previous copy in Logs',
        () async {
      final log = DiagnosticLogService(storage: _androidStorage());
      await log.logInfo('first');
      final path = await log.exportToFile();
      await log.logInfo('second');
      expect(await log.exportToFile(), path);
      expect(path, 'Download/QuisquisLingo/Logs/QQL_diagnostic_log.txt');
      expect(utf8.decode(android.downloads[path]!), contains('second'));
      expect(
        android.downloads.keys.where((key) => key.contains('diagnostic')),
        hasLength(1),
      );
      expect(await log.exportPath(), path);
    });

    test('the Crash Log Quick Export copies the private log into Logs with no '
        'dialog, replacing its previous copy', () async {
      final crash = CrashLogService.instance;
      await crash.initialise();
      final live = File(crash.crashLogPath!);
      // The live log stays in QQL's private storage.
      expect(live.parent.path, endsWith(DiagnosticLogService.logsDirectoryName));

      final first = await crash.exportCopy(storage: _androidStorage());
      expect(first!.location, 'Download/QuisquisLingo/Logs/QQL_crash_log.txt');
      await live.writeAsString('later entry\n', mode: FileMode.append);
      final second = await crash.exportCopy(storage: _androidStorage());
      expect(second!.location, first.location);
      expect(
        utf8.decode(android.downloads[first.location]!),
        endsWith('later entry\n'),
      );
      expect(
        android.downloads.keys.where((key) => key.contains('crash')),
        hasLength(1),
      );
      expect(android.uiCalls, isEmpty);
      expect(
        await crash.exportPath(storage: _androidStorage()),
        first.location,
      );
    });
  });

  group('Build 255 Android Quick Import (Android 10 and later)', () {
    test('without the folder permission nothing is read and no private '
        'folder is used', () async {
      final transfer = _transfer(dialogs);
      await expectLater(
        transfer.importCoursePackage(),
        throwsA(
          isA<QuickImportAccessRequired>().having(
            (error) => error.folder,
            'folder',
            'Download/QuisquisLingo',
          ),
        ),
      );
      expect(android.calls.map((call) => call.method), isNot(contains('listImports')));
      expect(android.uiCalls, isEmpty);
    });

    test('with the permission, Quick Import reads Import/Courses without a '
        'dialog, through the ordinary checks', () async {
      android.importAccess = true;
      android.imports['Import/Courses/import.zip'] = await _package();
      final package = await _transfer(dialogs).importCoursePackage();
      addTearDown(package.discard);
      expect(package.course.courseId, dialogTestCourse().courseId);
      expect(android.uiCalls, isEmpty);
      expect(dialogs.startedIn, isEmpty);
      expect(android.allClosed, isTrue);
    });

    test('the same permission lets Merge read ToBeMerged/Courses', () async {
      android.importAccess = true;
      android.imports['ToBeMerged/Courses/merge.zip'] = await _package();
      final package = await _transfer(dialogs).mergeCoursePackage();
      addTearDown(package.discard);
      expect(package.course.courseId, dialogTestCourse().courseId);
      expect(android.uiCalls, isEmpty);
      final listed = android.calls
          .where((call) => call.method == 'listImports')
          .map((call) => ((call.arguments as Map)['segments'] as List).join('/'))
          .toSet();
      expect(listed, {'ToBeMerged/Courses'});
    });

    test('an empty folder names the Android folder', () async {
      android.importAccess = true;
      await expectLater(
        _transfer(dialogs).importCoursePackage(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Download/QuisquisLingo/Import/Courses'),
          ),
        ),
      );
    });

    test('a deleted folder or a revoked permission asks again', () async {
      android.importAccess = true;
      android.imports['Import/UserData/learner_import.json'] = Uint8List(1);
      final backup = LearnerBackupService(storage: _androidStorage());

      android.folderGone = true;
      expect(await _androidStorage().hasImportAccess(), isFalse);
      await expectLater(
        backup.readImportFile(),
        throwsA(isA<QuickImportAccessRequired>()),
      );

      // Held at the check, gone when the folder is read.
      android.folderGone = false;
      android.revokeOnList = true;
      expect(await _androidStorage().hasImportAccess(), isTrue);
      await expectLater(
        backup.readImportFile(),
        throwsA(
          isA<QuickImportAccessRequired>().having(
            (error) => error.folder,
            'folder',
            'Download/QuisquisLingo',
          ),
        ),
      );
    });

    test('asking maps every answer, only "granted" gives access, and the '
        'Import and ToBeMerged folders are created', () async {
      final storage = _androidStorage();
      for (final (answer, expected) in [
        ('wrongFolder', QuickImportAccessResult.wrongFolder),
        ('denied', QuickImportAccessResult.denied),
        ('cancelled', QuickImportAccessResult.cancelled),
        ('granted', QuickImportAccessResult.granted),
      ]) {
        android.requestAnswer = answer;
        expect(await storage.requestImportAccess(), expected);
      }
      expect(await storage.hasImportAccess(), isTrue);
      expect(android.requestedFolders.toSet(), {
        'Import/Courses',
        'Import/UserData',
        'Import/RecoveryKeys',
        'Import/Audio',
        'Import/Images',
        'Import/LessonIcons',
        'Import/Flags',
        'ToBeMerged/Courses',
      });
      expect(
        await storage.importAccessSteps(),
        allOf(contains('Download/QuisquisLingo'), contains('Use this folder')),
      );
    });
  });

  group('Build 255 Android 7–9', () {
    late Directory downloads;

    setUp(() async {
      downloads = await Directory.systemTemp.createTemp('qql_downloads_');
      android.scoped = false;
      android.downloadsPath = downloads.path;
    });

    tearDown(() async {
      if (await downloads.exists()) await downloads.delete(recursive: true);
    });

    test('Quick Export asks for the storage permission, then writes to the '
        'Download folder', () async {
      final location = await _transfer(dialogs).exportCourse(
        dialogTestCourse(),
      );
      expect(
        location,
        'Download/QuisquisLingo/Export/Courses/QQL_EN_IT_dialog_course.zip',
      );
      expect(android.uiCalls, ['requestLegacyWriteAccess']);
      final file = File(
        '${downloads.path}/QuisquisLingo/Export/Courses/QQL_EN_IT_dialog_course.zip',
      );
      expect(await file.exists(), isTrue);
      expect(
        android.scanned.single.replaceAll(r'\', '/'),
        file.path.replaceAll(r'\', '/'),
      );
    });

    test('a refused permission writes nothing anywhere', () async {
      android.legacyWriteGranted = false;
      await expectLater(
        _transfer(dialogs).exportCourse(dialogTestCourse()),
        throwsA(isA<QuickExportAccessDenied>()),
      );
      expect(await Directory('${downloads.path}/QuisquisLingo').exists(), isFalse);
    });

    test('Quick Import reads the Download folder once the permission is held',
        () async {
      android.importAccess = true;
      final file = File(
        '${downloads.path}/QuisquisLingo/Import/Courses/import.zip',
      );
      await file.create(recursive: true);
      await file.writeAsBytes(await _package());
      final package = await _transfer(dialogs).importCoursePackage();
      addTearDown(package.discard);
      expect(package.course.courseId, dialogTestCourse().courseId);
    });
  });

  group('Build 255 Android Inventory and Wipe everything', () {
    test('Inventory lists each folder: QQL\'s own files in Export and Logs '
        'and, with access, the files in Import and ToBeMerged', () async {
      android.downloads['Download/QuisquisLingo/Export/Courses/a.zip'] =
          Uint8List(3);
      android.downloads['Download/QuisquisLingo/Logs/QQL_crash_log.txt'] =
          Uint8List(2);
      android.imports['Import/Courses/import.zip'] = Uint8List(5);
      android.imports['ToBeMerged/Courses/merge.zip'] = Uint8List(4);
      Future<InventorySection> section(String title) async =>
          (await InventoryService(
            storage: _androidStorage(),
            courses: () async => const [],
            teams: () async => const [],
          ).load()).singleWhere((section) => section.title == title);

      final exports = await section('Export folder');
      expect(exports.location, 'Download/QuisquisLingo/Export');
      expect(exports.items.single.name, 'Courses/a.zip');
      expect(exports.totalBytes, 3);
      final logs = await section('Logs folder');
      expect(logs.location, 'Download/QuisquisLingo/Logs');
      expect(logs.items.single.name, 'QQL_crash_log.txt');
      expect((await section('Import folder')).items, isEmpty);

      android.importAccess = true;
      final imports = await section('Import folder');
      expect(imports.location, 'Download/QuisquisLingo/Import');
      expect(imports.items.single.name, 'Courses/import.zip');
      final merges = await section('ToBeMerged folder');
      expect(merges.location, 'Download/QuisquisLingo/ToBeMerged');
      expect(merges.items.single.name, 'Courses/merge.zip');
    });

    test('a full wipe follows the ticks and gives back the folder permission',
        () async {
      final profiles = ProfileService();
      final root = await Directory.systemTemp.createTemp('qql_wipe_');
      addTearDown(() => root.delete(recursive: true));
      AppResetService service() => AppResetService(
        profiles: profiles,
        documentsDirectory: () async => root,
        supportDirectory: () async => root,
        storage: _androidStorage(),
      );
      Future<String> admin() async {
        final id = (await profiles.createProfile('Admin')).learnerProfileId;
        await profiles.setOwnAccessPin(actorProfileId: id, pin: '1234');
        return id;
      }

      void fill() {
        android.importAccess = true;
        android.downloads['Download/QuisquisLingo/Export/UserData/x.json'] =
            Uint8List(1);
        android.downloads['Download/QuisquisLingo/Logs/QQL_crash_log.txt'] =
            Uint8List(1);
        android.imports['Import/Courses/import.zip'] = Uint8List(1);
        android.imports['ToBeMerged/Courses/merge.zip'] = Uint8List(1);
      }

      fill();
      await service().reset(
        AppResetScope.everything,
        actorProfileId: await admin(),
        pin: '1234',
      );
      // Kept by default, but the permission is given back.
      expect(android.downloads, hasLength(2));
      expect(android.imports, hasLength(2));
      expect(android.released, isTrue);

      fill();
      await service().reset(
        AppResetScope.everything,
        actorProfileId: await admin(),
        pin: '1234',
        keepExports: false,
        keepImports: false,
      );
      expect(android.downloads.keys, [
        'Download/QuisquisLingo/Logs/QQL_crash_log.txt',
      ]);
      expect(android.imports, isEmpty);

      fill();
      await service().reset(
        AppResetScope.everything,
        actorProfileId: await admin(),
        pin: '1234',
        keepLogs: false,
      );
      expect(
        android.downloads.keys,
        ['Download/QuisquisLingo/Export/UserData/x.json'],
      );
      expect(android.imports, hasLength(2));
    });
  });

  group('Build 255 Revision 5 Android Backups folder', () {
    late Directory downloads;

    setUp(() async {
      downloads = await Directory.systemTemp.createTemp('qql_downloads_');
      android.downloadsPath = downloads.path;
    });

    tearDown(() async {
      if (await downloads.exists()) await downloads.delete(recursive: true);
    });

    String backupsPath() =>
        ['${downloads.path}/QuisquisLingo', 'Backups', 'Courses'].join('/');

    test('Android 11 and later: ordinary files in Download, no permission '
        'screen', () async {
      final storage = _androidStorage();
      expect(storage.courseBackupsLabel, 'Download/QuisquisLingo/Backups/Courses');
      expect((await storage.courseBackupsDirectory()).path, backupsPath());
      expect(android.backupPermission, isFalse);

      // A backup is written there and Version History reads it back.
      final backups = CourseBackupService(
        backupsDirectoryProvider: storage.courseBackupsDirectory,
      );
      final course = Course.fromJson(dialogTestCourse().toJson());
      final record = await backups.createBackup(
        course,
        backedUpAt: DateTime.utc(2026, 9, 26, 15),
        reason: 'Pre-change Course Editor transaction backup',
      );
      expect(
        record.manifestFile.path.replaceAll(r'\', '/'),
        startsWith('${backupsPath().replaceAll(r'\', '/')}/QQL_bkp_EN_IT_'),
      );
      expect(await backups.listBackups(course.courseId), hasLength(1));
    });

    test('Android 7–10: asks for the storage permission; refused, no backup',
        () async {
      android.scoped = false;
      final storage = _androidStorage();
      expect((await storage.courseBackupsDirectory()).path, backupsPath());
      expect(android.backupPermission, isTrue);

      android.backupPermission = false;
      android.legacyWriteGranted = false;
      await expectLater(
        storage.courseBackupsDirectory(),
        throwsA(
          isA<CourseBackupsAccessDenied>().having(
            (error) => error.folder,
            'folder',
            'Download/QuisquisLingo/Backups/Courses',
          ),
        ),
      );
    });

    test('Inventory lists the Backups folder; Wipe everything follows its '
        'tick', () async {
      final file = File(
        '${backupsPath()}/QQL_bkp_EN_IT_x/QQL_bkp_EN_IT_x_v1_S.json',
      );
      await file.create(recursive: true);
      await file.writeAsString('{}');
      final section = (await InventoryService(
        storage: _androidStorage(),
        courses: () async => const [],
        teams: () async => const [],
      ).load()).singleWhere((section) => section.title == 'Backups folder');
      expect(section.location, 'Download/QuisquisLingo/Backups');
      expect(
        section.items.single.name,
        'Courses/QQL_bkp_EN_IT_x/QQL_bkp_EN_IT_x_v1_S.json',
      );

      final profiles = ProfileService();
      final root = await Directory.systemTemp.createTemp('qql_wipe_');
      addTearDown(() => root.delete(recursive: true));
      Future<void> wipe({required bool keepBackups}) async {
        final id = (await profiles.createProfile('Admin')).learnerProfileId;
        await profiles.setOwnAccessPin(actorProfileId: id, pin: '1234');
        await AppResetService(
          profiles: profiles,
          documentsDirectory: () async => root,
          supportDirectory: () async => root,
          storage: _androidStorage(),
        ).reset(
          AppResetScope.everything,
          actorProfileId: id,
          pin: '1234',
          keepBackups: keepBackups,
        );
      }

      await wipe(keepBackups: true);
      expect(await file.exists(), isTrue);
      await wipe(keepBackups: false);
      expect(await file.exists(), isFalse);
    });
  });

  group('Build 255 Quick Import access explanation', () {
    Future<QuickImportAccess?> run(
      WidgetTester tester, {
      required bool offerOpenFrom,
      QqlStorage? storage,
      String? tap,
    }) async {
      QuickImportAccess? outcome;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => outcome = await ensureQuickImportAccess(
                  context,
                  offerOpenFrom: offerOpenFrom,
                  storage: storage ?? _androidStorage(),
                ),
                child: const Text('Quick Import'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Quick Import'));
      await tester.pumpAndSettle();
      if (tap != null) {
        await tester.tap(find.byKey(Key(tap)));
        await tester.pumpAndSettle();
      }
      return outcome;
    }

    testWidgets('desktop and granted Android go straight on', (tester) async {
      expect(
        await run(tester, offerOpenFrom: true, storage: QqlStorage()),
        QuickImportAccess.ready,
      );
      android.importAccess = true;
      expect(await run(tester, offerOpenFrom: true), QuickImportAccess.ready);
      expect(find.byKey(const Key('quick-import-access-dialog')), findsNothing);
    });

    testWidgets('Android explains, asks once and goes on', (tester) async {
      expect(
        await run(
          tester,
          offerOpenFrom: true,
          tap: 'quick-import-access-continue',
        ),
        QuickImportAccess.ready,
      );
      expect(android.uiCalls, ['requestImportAccess']);
    });

    testWidgets('the explanation names the folder and offers Open from…',
        (tester) async {
      await run(tester, offerOpenFrom: true);
      expect(find.byKey(const Key('quick-import-access-dialog')), findsOneWidget);
      expect(
        find.textContaining(
          'Import and ToBeMerged folders of Download/QuisquisLingo',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Use this folder'), findsOneWidget);
      await tester.tap(find.byKey(const Key('quick-import-access-open-from')));
      await tester.pumpAndSettle();
      expect(android.uiCalls, isEmpty);
    });

    testWidgets('Open from… instead and Cancel are honoured', (tester) async {
      expect(
        await run(
          tester,
          offerOpenFrom: true,
          tap: 'quick-import-access-open-from',
        ),
        QuickImportAccess.openFrom,
      );
      expect(
        await run(tester, offerOpenFrom: true, tap: 'quick-import-access-cancel'),
        QuickImportAccess.stop,
      );
      expect(android.uiCalls, isEmpty);
    });

    testWidgets('without a dialog route there is no Open from… button',
        (tester) async {
      await run(tester, offerOpenFrom: false);
      expect(find.byKey(const Key('quick-import-access-open-from')), findsNothing);
    });

    testWidgets('a wrong folder is explained and nothing is read',
        (tester) async {
      android.requestAnswer = 'wrongFolder';
      expect(
        await run(
          tester,
          offerOpenFrom: true,
          tap: 'quick-import-access-continue',
        ),
        QuickImportAccess.stop,
      );
      expect(
        find.textContaining('That was not Download/QuisquisLingo.'),
        findsOneWidget,
      );
      expect(android.importAccess, isFalse);
    });
  });
}
