import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/dialog_test_course.dart';
import 'support/fake_file_dialog_backend.dart';

Future<String> _diagnosticLog() async =>
    (await SharedPreferences.getInstance()).getString(
      'quisquislingo_diagnostic_log',
    ) ??
    '';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late FakeFileDialogBackend backend;
  late CustomCourseTransferService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('qql_240_dialogs_');
    backend = FakeFileDialogBackend();
    service = CustomCourseTransferService(
      directory: () async => directory,
      fileDialogs: FileDialogService(
        backend: backend,
        diagnosticLog: DiagnosticLogService(),
      ),
    );
  });

  tearDown(() => directory.delete(recursive: true));

  test(
    'default Export is unchanged: same folder, name and suffixing',
    () async {
      final first = await service.exportCourse(dialogTestCourse());
      final second = await service.exportCourse(dialogTestCourse());
      expect(
        first,
        '${directory.path}${Platform.pathSeparator}'
        'quisquislingo_dialog_course.json',
      );
      expect(
        second,
        '${directory.path}${Platform.pathSeparator}'
        'quisquislingo_dialog_course_2.json',
      );
      expect(
        backend.saved,
        isEmpty,
        reason: 'the default path never opens a dialog',
      );
    },
  );

  test('Save to… writes exactly the bytes the default Export writes', () async {
    final path = await service.exportCourse(dialogTestCourse());
    final result = await service.exportCourseTo(dialogTestCourse());

    expect(result.outcome, FileDialogOutcome.saved);
    expect(backend.saved.single.name, 'quisquislingo_dialog_course.json');
    expect(backend.saved.single.bytes, await File(path).readAsBytes());
  });

  group('first use starts in Downloads, later uses leave it to the OS', () {
    late Directory downloads;
    late FileDialogService dialogs;

    setUp(() async {
      downloads = await Directory.systemTemp.createTemp('qql_240_downloads_');
      backend.supportsStart = true;
      dialogs = FileDialogService(
        backend: backend,
        diagnosticLog: DiagnosticLogService(),
        downloadsDirectory: () async => downloads,
      );
    });

    tearDown(() => downloads.delete(recursive: true));

    Future<void> save() => dialogs.saveBytes(
      bytes: Uint8List(1),
      suggestedName: 'a.json',
      extensions: const ['json'],
      artifact: 'course',
    );

    test('only the very first dialog is given Downloads', () async {
      await save();
      await save();
      await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 10,
        artifact: 'course',
      );
      expect(backend.startedIn, [downloads.path, null, null]);
    });

    test('cancelling the first dialog still counts as the first use', () async {
      backend.onSave = (_, __) async => const FileDialogResult.cancelled();
      await save();
      await save();
      expect(backend.startedIn, [downloads.path, null]);
    });

    test('an unknown Downloads folder is retried, not counted', () async {
      final noDownloads = FileDialogService(
        backend: backend,
        diagnosticLog: DiagnosticLogService(),
        downloadsDirectory: () async => null,
      );
      await noDownloads.saveBytes(
        bytes: Uint8List(1),
        suggestedName: 'a.json',
        extensions: const ['json'],
        artifact: 'course',
      );
      await save();
      expect(backend.startedIn, [null, downloads.path]);
    });

    test(
      'a picker that chooses its own start (Android) is never told',
      () async {
        backend.supportsStart = false;
        await save();
        backend.supportsStart = true;
        await save();
        expect(backend.startedIn, [null, downloads.path]);
      },
    );
  });

  test('cancelling is harmless: no result data and nothing logged', () async {
    backend.onSave = (_, __) async => const FileDialogResult.cancelled();
    final saved = await service.exportCourseTo(dialogTestCourse());
    expect(saved.outcome, FileDialogOutcome.cancelled);

    final opened = await service.importCourseFromDialog();
    expect(opened.dialog.outcome, FileDialogOutcome.cancelled);
    expect(opened.course, isNull);

    expect(await _diagnosticLog(), isEmpty);
    expect(directory.listSync(), isEmpty);
  });

  test(
    'a failed save is logged with file name and OS error, not the path',
    () async {
      backend.onSave = (_, __) async => throw FileSystemException(
        'Cannot write file',
        r'C:\Users\Someone\Secret Folder\quisquislingo_dialog_course.json',
        const OSError('Access is denied', 5),
      );

      final result = await service.exportCourseTo(dialogTestCourse());

      expect(result.outcome, FileDialogOutcome.failed);
      final log = await _diagnosticLog();
      expect(log, contains('FILE-001'));
      expect(log, contains('direction=save'));
      expect(log, contains('artifact=course'));
      expect(log, contains('file=quisquislingo_dialog_course.json'));
      expect(log, contains('Access is denied'));
      expect(log, isNot(contains('Someone')));
      expect(log, isNot(contains('Secret Folder')));
    },
  );

  test('unavailable backend reports it, logs once and never throws', () async {
    final unavailable = CustomCourseTransferService(
      directory: () async => directory,
      fileDialogs: FileDialogService(
        backend: const UnavailableFileDialogBackend(),
        diagnosticLog: DiagnosticLogService(),
      ),
    );
    expect(unavailable.fileDialogsAvailable, isFalse);

    expect(
      (await unavailable.exportCourseTo(dialogTestCourse())).outcome,
      FileDialogOutcome.unavailable,
    );
    expect(
      (await unavailable.importCourseFromDialog()).dialog.outcome,
      FileDialogOutcome.unavailable,
    );
    final log = await _diagnosticLog();
    expect('FILE-002'.allMatches(log), hasLength(1));
    // The fixed-folder route still works.
    expect(
      await File(await unavailable.exportCourse(dialogTestCourse())).exists(),
      isTrue,
    );
  });

  test(
    'Open from… returns the same Course as the fixed-folder import',
    () async {
      final path = await service.exportCourse(dialogTestCourse());
      final bytes = await File(path).readAsBytes();
      backend.onOpen = () async =>
          FileDialogResult.opened('anywhere.json', bytes);

      await File(
        path,
      ).rename('${directory.path}${Platform.pathSeparator}import.json');
      final viaFolder = await service.importCourse();
      final viaDialog = await service.importCourseFromDialog();

      expect(viaDialog.dialog.outcome, FileDialogOutcome.opened);
      expect(viaDialog.course!.toJson(), viaFolder.toJson());
    },
  );

  group('an invalid file is rejected with the same error on both routes', () {
    final cases = <String, Uint8List>{
      'not UTF-8': Uint8List.fromList([0xff, 0xfe, 0xfd]),
      'not JSON': Uint8List.fromList(utf8.encode('this is not json')),
      'not an object': Uint8List.fromList(utf8.encode('[1, 2, 3]')),
      'unsupported format': Uint8List.fromList(
        utf8.encode('{"formatVersion":5,"courseId":"legacy","lessons":[]}'),
      ),
      'over 10 MB': Uint8List(CustomCourseTransferService.maxJsonBytes + 1),
    };

    cases.forEach((name, bytes) {
      test(name, () async {
        final importFile = File(
          '${directory.path}${Platform.pathSeparator}import.json',
        );
        await importFile.writeAsBytes(bytes);
        backend.onOpen = () async =>
            FileDialogResult.opened('import.json', bytes);

        Object? folderError;
        try {
          await service.importCourse();
        } catch (error) {
          folderError = error;
        }
        Object? dialogError;
        try {
          await service.importCourseFromDialog();
        } catch (error) {
          dialogError = error;
        }

        expect(folderError, isA<FormatException>());
        expect(dialogError, isA<FormatException>());
        expect(
          (dialogError as FormatException).message,
          (folderError as FormatException).message,
        );
      });
    });
  });
}
