import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
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
    test('every folder is below Download/QuisquisLingo/Imports or Exports', () {
      const layout = QqlStorageLayout.androidPublic;
      expect(
        QqlStorageLayout.forPlatform(QqlStoragePlatform.android),
        same(layout),
      );
      final expected = <QqlStorageRole, String>{
        QqlStorageRole.courseImports: 'Imports/Courses',
        QqlStorageRole.courseExports: 'Exports/Courses',
        QqlStorageRole.mergeImports: 'Imports/Merges',
        QqlStorageRole.learnerDataImports: 'Imports',
        QqlStorageRole.learnerDataExports: 'Exports',
        QqlStorageRole.recoveryKeyImports: 'Imports',
        QqlStorageRole.recoveryKeyExports: 'Exports',
        QqlStorageRole.audioImports: 'Imports/Audio',
        QqlStorageRole.imageImports: 'Imports/Images',
        QqlStorageRole.lessonIconImports: 'Imports/Lesson Icons',
        QqlStorageRole.courseFlagImports: 'Imports',
        QqlStorageRole.auditReportExports: 'Exports',
        QqlStorageRole.diagnosticLogExports: 'Exports/Logs',
      };
      expect(expected.keys.toSet(), QqlStorageRole.values.toSet());
      for (final entry in expected.entries) {
        expect(
          layout.folderLabel(entry.key),
          'Download/QuisquisLingo/${entry.value}',
          reason: '${entry.key}',
        );
      }
      expect(
        layout.directionLabel(QqlTransferDirection.imports),
        'Download/QuisquisLingo/Imports',
      );
    });

    test('Help names the Android folders on Android', () {
      QqlStorageLayout.debugOverride = QqlStorageLayout.androidPublic;
      for (final locale in AppLocale.values) {
        expect(
          helpText.lookup(locale, 'editorHelp.importCustomCourse.body'),
          contains('Download/QuisquisLingo/Imports/Courses/import.zip'),
        );
        final logs = helpText.lookup(
          locale,
          'appInfo.crashLogAndDiagnosticLog.body',
        );
        expect(logs, contains('Download/QuisquisLingo/Exports/Logs'));
        expect(logs, contains('Crash Log'));
      }
    });
  });

  group('Build 255 Android Quick Export (Android 10 and later)', () {
    test('writes to Download/QuisquisLingo/Exports/Courses with no dialog '
        'and no permission', () async {
      final transfer = _transfer(dialogs);
      final first = await transfer.exportCourse(dialogTestCourse());
      final second = await transfer.exportCourse(dialogTestCourse());
      expect(
        first,
        'Download/QuisquisLingo/Exports/Courses/quisquislingo_dialog_course.zip',
      );
      expect(
        second,
        'Download/QuisquisLingo/Exports/Courses/quisquislingo_dialog_course_2.zip',
      );
      final written = android.downloads[first]!;
      expect(written.sublist(0, 2), [0x50, 0x4B]); // a ZIP
      expect(android.uiCalls, isEmpty);
      expect(dialogs.startedIn, isEmpty);
      expect(android.allClosed, isTrue);
    });

    test('the Diagnostic Log snapshot replaces its previous copy', () async {
      final log = DiagnosticLogService(storage: _androidStorage());
      await log.logInfo('first');
      final path = await log.exportToFile();
      await log.logInfo('second');
      expect(await log.exportToFile(), path);
      expect(
        path,
        'Download/QuisquisLingo/Exports/Logs/quisquislingo_diagnostic_log.txt',
      );
      expect(utf8.decode(android.downloads[path]!), contains('second'));
      expect(
        android.downloads.keys.where((key) => key.contains('diagnostic')),
        hasLength(1),
      );
      expect(await log.exportPath(), path);
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
            'Download/QuisquisLingo/Imports',
          ),
        ),
      );
      expect(android.calls.map((call) => call.method), isNot(contains('listImports')));
      expect(android.uiCalls, isEmpty);
    });

    test('with the permission, Quick Import reads Imports/Courses without a '
        'dialog, through the ordinary checks', () async {
      android.importAccess = true;
      android.imports['Courses/import.zip'] = await _package();
      final package = await _transfer(dialogs).importCoursePackage();
      addTearDown(package.discard);
      expect(package.course.courseId, dialogTestCourse().courseId);
      expect(android.uiCalls, isEmpty);
      expect(dialogs.startedIn, isEmpty);
      expect(android.allClosed, isTrue);
    });

    test('an empty folder names the Android folder', () async {
      android.importAccess = true;
      await expectLater(
        _transfer(dialogs).importCoursePackage(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Download/QuisquisLingo/Imports/Courses'),
          ),
        ),
      );
    });

    test('a deleted folder or a revoked permission asks again', () async {
      android.importAccess = true;
      android.imports['learner_import.json'] = Uint8List(1);
      final backup = LearnerBackupService(storage: _androidStorage());

      android.importsFolderGone = true;
      expect(await _androidStorage().hasImportAccess(), isFalse);
      await expectLater(
        backup.readImportFile(),
        throwsA(isA<QuickImportAccessRequired>()),
      );

      // Held at the check, gone when the folder is read.
      android.importsFolderGone = false;
      android.revokeOnList = true;
      expect(await _androidStorage().hasImportAccess(), isTrue);
      await expectLater(
        backup.readImportFile(),
        throwsA(
          isA<QuickImportAccessRequired>().having(
            (error) => error.folder,
            'folder',
            'Download/QuisquisLingo/Imports',
          ),
        ),
      );
    });

    test('asking maps every answer; only "granted" gives access', () async {
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
      expect(
        await storage.importAccessSteps(),
        contains('Use this folder'),
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
        'Download/QuisquisLingo/Exports/Courses/quisquislingo_dialog_course.zip',
      );
      expect(android.uiCalls, ['requestLegacyWriteAccess']);
      final file = File(
        '${downloads.path}/QuisquisLingo/Exports/Courses/'
        'quisquislingo_dialog_course.zip',
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
        '${downloads.path}/QuisquisLingo/Imports/Courses/import.zip',
      );
      await file.create(recursive: true);
      await file.writeAsBytes(await _package());
      final package = await _transfer(dialogs).importCoursePackage();
      addTearDown(package.discard);
      expect(package.course.courseId, dialogTestCourse().courseId);
    });
  });

  group('Build 255 Android Inventory and Wipe everything', () {
    test('Inventory lists QQL exports and, with access, the Imports files',
        () async {
      android.downloads['Download/QuisquisLingo/Exports/Courses/a.zip'] =
          Uint8List(3);
      android.imports['Courses/import.zip'] = Uint8List(5);
      Future<InventorySection> section(String title) async =>
          (await InventoryService(
            storage: _androidStorage(),
            courses: () async => const [],
            teams: () async => const [],
          ).load()).singleWhere((section) => section.title == title);

      final exports = await section('Quick Export folder');
      expect(exports.location, 'Download/QuisquisLingo/Exports');
      expect(exports.items.single.name, 'Courses/a.zip');
      expect(exports.totalBytes, 3);
      expect((await section('Quick Import folder')).items, isEmpty);

      android.importAccess = true;
      final imports = await section('Quick Import folder');
      expect(imports.location, 'Download/QuisquisLingo/Imports');
      expect(imports.items.single.name, 'Courses/import.zip');
    });

    test('a full wipe follows the ticks and gives back the folder permission',
        () async {
      final profiles = ProfileService();
      final admin = (await profiles.createProfile('Admin')).learnerProfileId;
      await profiles.setOwnAccessPin(actorProfileId: admin, pin: '1234');
      final root = await Directory.systemTemp.createTemp('qql_wipe_');
      addTearDown(() => root.delete(recursive: true));
      AppResetService service() => AppResetService(
        profiles: profiles,
        documentsDirectory: () async => root,
        supportDirectory: () async => root,
        storage: _androidStorage(),
      );
      android.importAccess = true;
      android.downloads['Download/QuisquisLingo/Exports/x.json'] = Uint8List(1);
      android.imports['Courses/import.zip'] = Uint8List(1);

      await service().reset(
        AppResetScope.everything,
        actorProfileId: admin,
        pin: '1234',
      );
      // Kept by default, but the permission is given back.
      expect(android.downloads, hasLength(1));
      expect(android.imports, hasLength(1));
      expect(android.released, isTrue);

      final again = (await profiles.createProfile('Admin')).learnerProfileId;
      await profiles.setOwnAccessPin(actorProfileId: again, pin: '1234');
      android.importAccess = true;
      await service().reset(
        AppResetScope.everything,
        actorProfileId: again,
        pin: '1234',
        keepExports: false,
        keepImports: false,
      );
      expect(android.downloads, isEmpty);
      expect(android.imports, isEmpty);
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
        find.textContaining('Download/QuisquisLingo/Imports'),
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
        find.textContaining('That was not Download/QuisquisLingo/Imports'),
        findsOneWidget,
      );
      expect(android.importAccess, isFalse);
    });
  });
}
