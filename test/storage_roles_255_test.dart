import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/import/selected_external_file.dart';
import 'package:quisquislingo_app/services/storage/file_system_storage.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';

import 'support/dialog_test_course.dart';
import 'support/fake_file_dialog_backend.dart';

final _sep = Platform.pathSeparator;

void main() {
  group('Build 255 storage layout', () {
    test('Course Quick folders are Import/Courses and Export/Courses on '
        'every desktop', () {
      for (final platform in [
        QqlStoragePlatform.windows,
        QqlStoragePlatform.macos,
        QqlStoragePlatform.linux,
        QqlStoragePlatform.ios,
      ]) {
        final layout = QqlStorageLayout.forPlatform(platform);
        expect(
          layout.folderLabel(QqlStorageRole.courseImports),
          'Documents/QuisquisLingo/Import/Courses',
          reason: platform.name,
        );
        expect(
          layout.folderLabel(QqlStorageRole.courseExports),
          'Documents/QuisquisLingo/Export/Courses',
          reason: platform.name,
        );
      }
    });

    test('one pattern on every system: Import, Export, Logs and ToBeMerged, '
        'one subfolder per kind, no spaces', () {
      expect(
        [for (final folder in QqlTopFolder.values) folder.folderName],
        ['Import', 'Export', 'Logs', 'ToBeMerged'],
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
      for (final role in QqlStorageRole.values) {
        final segments = QqlStorageLayout.documents.segments(role);
        expect(segments.first, QqlStorageLayout.topFolder(role).folderName);
        expect(segments.any((name) => name.contains(' ')), isFalse);
      }
      for (final entry in expected.entries) {
        expect(
          QqlStorageLayout.documents.segments(entry.key).join('/'),
          entry.value,
          reason: '${entry.key}',
        );
      }
      expect(
        QqlStorageLayout.documents.fileLabel(
          QqlStorageRole.learnerDataImports,
          'learner_import.json',
        ),
        'Documents/QuisquisLingo/Import/UserData/learner_import.json',
      );
    });

    test('every role is listed once with its own Help placeholder', () {
      final roles = QqlStorageRole.values;
      expect(roles.toSet(), hasLength(roles.length));
      expect(roles.map((role) => role.placeholder).toSet(), hasLength(13));
      expect(
        roles.map((role) => (role.direction, role.category)).toSet(),
        hasLength(roles.length),
      );
      final values = QqlStorageLayout.helpValues();
      expect(values.keys.toSet(), {
        ...roles.map((role) => role.placeholder),
        'folderImport',
        'folderExport',
        'folderLogs',
        'folderToBeMerged',
        'folderRoot',
      });
      expect(values['folderRoot'], 'Documents/QuisquisLingo');
      expect(values['folderLogs'], 'Documents/QuisquisLingo/Logs');
    });
  });

  group('Build 255 Help folder placeholders', () {
    test('Help shows this platform\'s folders and no raw placeholder', () {
      for (final locale in AppLocale.values) {
        for (final key in helpEn.keys) {
          expect(
            helpText.lookup(locale, key),
            isNot(contains('{folder')),
            reason: '${locale.id} $key',
          );
        }
      }
      expect(
        helpText.lookup(AppLocale.italian, 'editorHelp.importCustomCourse.body'),
        contains('Documents/QuisquisLingo/Import/Courses/import.zip'),
      );
      expect(
        helpText.lookup(AppLocale.spanish, 'editorHelp.exportCustomCourse.body'),
        contains('Documents/QuisquisLingo/Export/Courses'),
      );
    });

    test('translations name no folder English does not, and no catalog '
        'spells out a Quick folder', () {
      final placeholder = RegExp(r'\{folder[A-Za-z]+\}');
      Set<String> folders(String text) =>
          placeholder.allMatches(text).map((match) => match[0]!).toSet();
      var named = 0;
      for (final entry in helpEn.entries) {
        final english = folders(entry.value);
        named += english.length;
        for (final catalog in [helpIt, helpEs]) {
          final translated = catalog[entry.key];
          if (translated == null || translated.isEmpty) continue;
          // A translation may leave a folder out, never name another one.
          expect(english.containsAll(folders(translated)), isTrue,
              reason: entry.key);
        }
      }
      expect(named, greaterThan(10));
      // No folder is spelled out, and no old folder path survives: only
      // Inventory names the earlier folders, without a path.
      final literal = RegExp(
        r'(Documents|Download)/QuisquisLingo|\b(Imports|Exports|Merges)/',
      );
      for (final catalog in [helpEn, helpIt, helpEs]) {
        for (final entry in catalog.entries) {
          expect(literal.hasMatch(entry.value), isFalse, reason: entry.key);
        }
      }
    });

    test('a caller value still wins over a folder name', () {
      expect(
        helpText.lookup(
          AppLocale.english,
          'editorHelp.importCustomCourse.body',
          values: const {'folderCourseImports': 'HERE'},
        ),
        contains('HERE/import.zip'),
      );
    });
  });

  group('Build 255 file-system backend', () {
    late Directory documents;
    late FileSystemStorageBackend backend;

    setUp(() async {
      documents = await Directory.systemTemp.createTemp('qql_storage_255_');
      backend = FileSystemStorageBackend(
        documentsDirectory: () async => documents,
      );
    });

    tearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });

    String qql(String relative) =>
        '${documents.path}${_sep}QuisquisLingo$_sep'
        '${relative.replaceAll('/', _sep)}';

    test('folders resolve below Documents/QuisquisLingo', () async {
      final imports = await backend.importFolder(QqlStorageRole.courseImports);
      final exports = await backend.exportFolder(QqlStorageRole.courseExports);
      expect(imports.location, qql('Import/Courses'));
      expect(exports.location, qql('Export/Courses'));
      expect(await Directory(imports.location).exists(), isTrue);
      // An export folder appears with its first file.
      expect(await Directory(exports.location).exists(), isFalse);
      await exports.write(baseName: 'a', extension: 'zip', bytes: [1]);
      expect(await Directory(exports.location).exists(), isTrue);
      expect(imports.locationOf('import.zip'), qql('Import/Courses/import.zip'));
    });

    test('files() lists ordinary files only; file() finds exact names', () async {
      final folder = await backend.importFolder(QqlStorageRole.audioImports);
      await File(folder.locationOf('b.mp3')).writeAsBytes([1, 2, 3]);
      await File(folder.locationOf('a.mp3')).writeAsBytes([4]);
      await Directory(folder.locationOf('sub')).create();
      var linked = false;
      try {
        await Link(folder.locationOf('link.mp3')).create(
          folder.locationOf('a.mp3'),
        );
        linked = true;
      } on FileSystemException {
        // Creating links needs a privilege on some Windows setups.
      }

      final names = (await folder.files()).map((file) => file.name).toList()
        ..sort();
      expect(names, ['a.mp3', 'b.mp3']);
      final found = await folder.file('b.mp3');
      expect(found!.isOrdinaryFile, isTrue);
      expect(found.reportedSize, 3);
      expect(found.displayName, 'b.mp3');
      expect(await folder.file('missing.mp3'), isNull);
      expect(await folder.file('sub'), isNull);
      if (linked) {
        final link = await folder.file('link.mp3');
        expect(link!.isOrdinaryFile, isFalse);
        await expectLater(
          readQuickImportFile(link, maxBytes: 10),
          throwsA(isA<ImportAccessException>()),
        );
      }
    });

    test('write() adds _2 and _3, and replace overwrites', () async {
      final folder = await backend.exportFolder(QqlStorageRole.learnerDataExports);
      final first = await folder.write(
        baseName: 'backup',
        extension: 'json',
        bytes: [1],
      );
      final second = await folder.write(
        baseName: 'backup',
        extension: 'json',
        bytes: [2],
      );
      final third = await folder.write(
        baseName: 'backup',
        extension: 'json',
        bytes: [3],
      );
      expect(first.fileName, 'backup.json');
      expect(second.fileName, 'backup_2.json');
      expect(third.fileName, 'backup_3.json');
      expect(first.location, qql('Export/UserData/backup.json'));
      final replaced = await folder.write(
        baseName: 'backup',
        extension: 'json',
        bytes: [9, 9],
        replace: true,
      );
      expect(replaced.location, first.location);
      expect(await File(first.location).readAsBytes(), [9, 9]);
    });

    test('readQuickImportFile enforces its limit and allows empty files', () async {
      final folder = await backend.importFolder(QqlStorageRole.imageImports);
      await File(folder.locationOf('big.png')).writeAsBytes(
        Uint8List(11),
      );
      await File(folder.locationOf('empty.png')).writeAsBytes(const []);
      await expectLater(
        readQuickImportFile((await folder.file('big.png'))!, maxBytes: 10),
        throwsA(isA<ImportTooLargeException>()),
      );
      expect(
        await readQuickImportFile((await folder.file('big.png'))!, maxBytes: 11),
        hasLength(11),
      );
      expect(
        await readQuickImportFile((await folder.file('empty.png'))!, maxBytes: 1),
        isEmpty,
      );
    });
  });

  group('Build 255 Course Quick routes', () {
    late FakeFileDialogBackend dialogs;
    late CustomCourseTransferService transfer;

    setUp(() {
      dialogs = FakeFileDialogBackend();
      transfer = CustomCourseTransferService(
        fileDialogs: FileDialogService(
          backend: dialogs,
          stager: testImportStager(),
        ),
      );
    });

    Future<String> root() async =>
        '${(await getApplicationDocumentsDirectory()).path}${_sep}QuisquisLingo';

    test('Quick Export writes QQL_ files to Export/Courses and Quick Import '
        'reads Import/Courses, without any dialog', () async {
      final course = dialogTestCourse();
      final exported = await transfer.exportCourse(course);
      final qql = await root();
      expect(File(exported).parent.path, '$qql${_sep}Export${_sep}Courses');
      expect(File(exported).uri.pathSegments.last, 'QQL_EN_IT_dialog_course.zip');

      final imports = await transfer.importFolder();
      expect(imports.location, '$qql${_sep}Import${_sep}Courses');
      await File(exported).copy(imports.locationOf('import.zip'));
      final imported = await transfer.importCoursePackage();
      addTearDown(imported.discard);
      expect(imported.course.courseId, course.courseId);
      expect(dialogs.startedIn, isEmpty);
    });

    test('a Course file left in an earlier Imports folder is not read',
        () async {
      final exported = await transfer.exportCourse(dialogTestCourse());
      final qql = await root();
      await Directory('$qql${_sep}Imports${_sep}Courses').create(recursive: true);
      await File(exported).copy('$qql${_sep}Imports${_sep}import.zip');
      await File(exported).copy('$qql${_sep}Imports${_sep}Courses${_sep}import.zip');

      await expectLater(
        transfer.importCoursePackage(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('No Course file found'),
              contains('Import${_sep}Courses'),
            ),
          ),
        ),
      );
      expect(dialogs.startedIn, isEmpty);
    });

    test('an empty import.zip is reported like the Open from… route', () async {
      final folder = await transfer.importFolder();
      await File(folder.locationOf('import.zip')).writeAsBytes(const []);
      await expectLater(
        transfer.importCoursePackage(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'import.zip is empty.',
          ),
        ),
      );
    });
  });
}
