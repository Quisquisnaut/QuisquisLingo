import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/exercise_image_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/portable_exercise_image.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/services/user_recovery_key_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/dialog_test_course.dart';
import 'support/fake_file_dialog_backend.dart';
import 'support/synthetic_mp3.dart';

// A ZIP with no image_bank_manifest.json: the ordinary importer rejects it.
const _zipWithoutManifest =
    'UEsDBBQAAAAIADW5DV2DFtyMAwAAAAEAAAAJAAAAaW1hZ2UucG5nqwAAUEsBAhQDFAAAAAgANbkNXYMW3IwDAAAAAQAAAAkAAAAAAAAAAAAAAIABAAAAAGltYWdlLnBuZ1BLBQYAAAAAAQABADcAAAAqAAAAAAA=';

Future<String> _diagnosticLog() async =>
    (await SharedPreferences.getInstance()).getString(
      'quisquislingo_diagnostic_log',
    ) ??
    '';

Map<String, dynamic> _withoutTimestamp(List<int> bytes) =>
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map)
      ..remove('exportedAt');

Future<Object?> _thrown(Future<Object?> Function() action) async {
  try {
    await action();
  } catch (error) {
    return error;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FakeFileDialogBackend backend;
  late FileDialogService dialogs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ProfileService.beginAccessSession();
    root = await Directory.systemTemp.createTemp('qql_240_features_');
    backend = FakeFileDialogBackend();
    dialogs = FileDialogService(
      stager: testImportStager(),
      backend: backend,
      diagnosticLog: DiagnosticLogService(),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('Merge From…', () {
    test('returns the same Course as Merges/merge.json would', () async {
      final directory = Directory('${root.path}${Platform.pathSeparator}m');
      final transfer = CustomCourseTransferService(
        directory: () async => directory,
        fileDialogs: dialogs,
      );
      final bytes = Uint8List.fromList(
        utf8.encode(jsonEncode(dialogTestCourse().toJson())),
      );
      backend.onOpen = () async =>
          FileDialogResult.opened('second.json', bytes);
      final merge = CourseMergeService(transfer: transfer);

      final picked = await merge.readMergeCourseFromDialog();
      await File(
        '${(await transfer.mergeDirectory()).path}${Platform.pathSeparator}merge.json',
      ).writeAsBytes(bytes);
      final viaFolder = await merge.readMergeCourse();

      expect(picked.course!.toJson(), viaFolder.toJson());
    });

    test('cancel returns no Course and logs nothing', () async {
      final merge = CourseMergeService(
        transfer: CustomCourseTransferService(fileDialogs: dialogs),
      );
      final picked = await merge.readMergeCourseFromDialog();
      expect(picked.course, isNull);
      expect(picked.dialog.outcome, FileDialogOutcome.cancelled);
      expect(await _diagnosticLog(), isEmpty);
    });

    test('an invalid file is rejected like an invalid merge.json', () async {
      final transfer = CustomCourseTransferService(fileDialogs: dialogs);
      backend.onOpen = () async => FileDialogResult.opened(
        'second.json',
        Uint8List.fromList(utf8.encode('not json')),
      );
      final error = await _thrown(transfer.mergeCourseFromDialog);
      expect(error, isA<FormatException>());
      expect(
        (error as FormatException).message,
        'second.json is not valid JSON.',
      );
    });
  });

  group('Image Bank ZIP Open from…', () {
    late Directory temp;
    late ImageBankService banks;

    setUp(() async {
      temp = Directory('${root.path}${Platform.pathSeparator}tmp')
        ..createSync();
      banks = ImageBankService(
        fileDialogs: dialogs,
        temporaryDirectory: () async => temp,
      );
    });

    test('cancel returns nothing and touches nothing', () async {
      final picked = await banks.importBankZipFromDialog();
      expect(picked.result, isNull);
      expect(picked.dialog.outcome, FileDialogOutcome.cancelled);
      expect(temp.listSync(), isEmpty);
    });

    test('a bad ZIP fails like the ordinary import and the temporary copy is '
        'always deleted', () async {
      final bytes = base64Decode(_zipWithoutManifest);
      backend.onOpen = () async =>
          FileDialogResult.opened('bank.zip', Uint8List.fromList(bytes));

      final viaDialog = await _thrown(banks.importBankZipFromDialog);
      final ordinary = File('${root.path}${Platform.pathSeparator}bank.zip')
        ..writeAsBytesSync(bytes);
      final viaFile = await _thrown(() => banks.importBankZip(ordinary));

      expect(viaDialog, isA<FormatException>());
      expect(
        (viaDialog as FormatException).message,
        (viaFile as FormatException).message,
      );
      expect(temp.listSync(), isEmpty);
    });
  });

  group('User Data', () {
    late ProfileService profiles;
    late LearnerBackupService backup;

    setUp(() async {
      profiles = ProfileService(
        idGenerator: () => '50000000-0000-4000-8000-000000000005',
        numericSuffixGenerator: () => 12345,
        randomIndex: (_) => 0,
      );
      await profiles.createProfile('Mario Rossi');
      backup = LearnerBackupService(
        profileService: profiles,
        documentsDirectoryProvider: () async => root,
        fileDialogs: dialogs,
      );
    });

    test('Save to… writes the same backup as the default Export', () async {
      final path = await backup.saveActiveProfile();
      final result = await backup.saveActiveProfileTo();

      expect(result.outcome, FileDialogOutcome.saved);
      // The suggested name is the one the default export chose.
      expect(
        path.split(Platform.pathSeparator).last,
        backend.saved.single.name,
      );
      expect(
        _withoutTimestamp(backend.saved.single.bytes),
        _withoutTimestamp(await File(path).readAsBytes()),
      );
    });

    test('Open from… decodes like the fixed-folder import', () async {
      final path = await backup.saveActiveProfile();
      final bytes = await File(path).readAsBytes();
      backend.onOpen = () async =>
          FileDialogResult.opened('mine.json', Uint8List.fromList(bytes));
      await File(await backup.importFilePath()).writeAsBytes(bytes);

      final viaDialog = (await backup.readImportFromDialog()).document!;
      final viaFolder = await backup.readImportFile();

      expect(viaDialog.learnerProfileId, viaFolder.learnerProfileId);
      expect(viaDialog.data, viaFolder.data);
    });

    test('an invalid backup is rejected with the same error', () async {
      final bytes = Uint8List.fromList(utf8.encode('{"format":"nope"}'));
      backend.onOpen = () async => FileDialogResult.opened('x.json', bytes);
      await File(await backup.importFilePath()).writeAsBytes(bytes);

      final viaDialog = await _thrown(backup.readImportFromDialog);
      final viaFolder = await _thrown(backup.readImportFile);

      expect(viaDialog, isA<FormatException>());
      expect(
        (viaDialog as FormatException).message,
        (viaFolder as FormatException).message,
      );
    });

    test('a file over 10 MB is rejected with the standard message', () async {
      backend.onOpen = () async => FileDialogResult.opened(
        'big.json',
        Uint8List(LearnerBackupService.maxBackupBytes + 1),
      );
      final error = await _thrown(backup.readImportFromDialog);
      expect(
        (error as FormatException).message,
        contains('larger than the 10 MB safety limit'),
      );
    });

    test('cancel is harmless', () async {
      expect(
        (await backup.readImportFromDialog()).dialog.outcome,
        FileDialogOutcome.cancelled,
      );
      expect(await _diagnosticLog(), isEmpty);
    });
  });

  group('User Recovery Key', () {
    late UserRecoveryKeyService keys;
    late Directory exports;

    setUp(() async {
      final profiles = ProfileService(
        idGenerator: () => '60000000-0000-4000-8000-000000000006',
        secureBytes: (length) => List<int>.generate(length, (i) => i + 1),
      );
      await profiles.createProfile('Mario Rossi');
      exports = Directory('${root.path}${Platform.pathSeparator}Exports');
      keys = UserRecoveryKeyService(
        profileService: profiles,
        exportsDirectoryProvider: () async => exports,
        importsDirectoryProvider: () async => root,
        secureBytes: (length) => List<int>.generate(length, (i) => i + 20),
        fileDialogs: dialogs,
      );
    });

    test('Save to… writes the same key file as the default export', () async {
      final path = await keys.exportActiveUserRecoveryKey();
      final result = await keys.exportActiveUserRecoveryKeyTo();

      expect(result.outcome, FileDialogOutcome.saved);
      expect(backend.saved.single.name, endsWith('.user-recovery-key.json'));
      expect(backend.saved.single.bytes, await File(path).readAsBytes());
    });

    test('Open from… returns the same document and only a file name', () async {
      final path = await keys.exportActiveUserRecoveryKey();
      final bytes = Uint8List.fromList(await File(path).readAsBytes());
      backend.onOpen = () async => FileDialogResult.opened('key.json', bytes);

      final picked = await keys.openUserRecoveryKeyFromDialog();
      final decoded = keys.decodeDocument(bytes);

      expect(picked.candidate!.path, 'key.json');
      expect(
        picked.candidate!.document.learnerProfileId,
        decoded.learnerProfileId,
      );
      expect(picked.candidate!.document.secret, decoded.secret);
    });

    test('a file that is not a Recovery Key is rejected', () async {
      backend.onOpen = () async => FileDialogResult.opened(
        'x.json',
        Uint8List.fromList(utf8.encode('{"format":"other"}')),
      );
      final error = await _thrown(keys.openUserRecoveryKeyFromDialog);
      expect(
        (error as FormatException).message,
        'This is not a supported QQL User Recovery Key.',
      );
    });

    test('an oversized key file is rejected', () async {
      backend.onOpen = () async =>
          FileDialogResult.opened('x.json', Uint8List(64 * 1024 + 1));
      final error = await _thrown(keys.openUserRecoveryKeyFromDialog);
      expect(
        (error as FormatException).message,
        'A User Recovery Key is too large.',
      );
    });

    test('a failed save is logged without the key or any path', () async {
      backend.onSave = (_, __) async => throw FileSystemException(
        'Cannot write file',
        r'C:\Users\Someone\Private\key.json',
        const OSError('Access is denied', 5),
      );
      final result = await keys.exportActiveUserRecoveryKeyTo();
      expect(result.outcome, FileDialogOutcome.failed);
      final log = await _diagnosticLog();
      expect(log, contains('artifact=user-recovery-key'));
      expect(log, isNot(contains('Someone')));
      expect(log, isNot(contains('secret')));
    });
  });

  group('Single exercise image Open from…', () {
    late Directory support;
    late ExerciseImageService images;

    setUp(() {
      support = Directory('${root.path}${Platform.pathSeparator}support');
      images = ExerciseImageService(
        fileDialogs: dialogs,
        supportDirectory: () async => support,
      );
    });

    test(
      'a valid image is checked and returned unchanged; nothing is stored yet',
      () async {
        final bytes = File('assets/lesson_icons/home.png').readAsBytesSync();
        backend.onOpen = () async =>
            FileDialogResult.opened('My Picture (1).png', bytes);

        final result = await images.readImageFromDialog();

        expect(result.dialog.outcome, FileDialogOutcome.opened);
        expect(result.picked!.image.bytes, bytes);
        expect(result.picked!.sourceName, 'My Picture (1).png');
        // Storing happens only when a caller commits it (Shared Image
        // Library or Course media), under a name QQL generates.
        expect(
          Directory(
            '${support.path}${Platform.pathSeparator}exercise_images',
          ).existsSync(),
          isFalse,
        );
      },
    );

    test('cancel stores nothing and logs nothing', () async {
      final picked = await images.readImageFromDialog();
      expect(picked.picked, isNull);
      expect(picked.dialog.outcome, FileDialogOutcome.cancelled);
      expect(
        Directory(
          '${support.path}${Platform.pathSeparator}exercise_images',
        ).existsSync(),
        isFalse,
      );
      expect(support.existsSync(), isFalse);
      expect(await _diagnosticLog(), isEmpty);
    });

    test('an unsupported type or an image over 50 KB is rejected', () async {
      backend.onOpen = () async =>
          FileDialogResult.opened('x.gif', Uint8List(10));
      var error = await _thrown(images.readImageFromDialog);
      expect(error, isA<StateError>());
      expect(
        (error as StateError).message,
        'Choose a PNG, JPG, JPEG or WEBP image.',
      );

      backend.onOpen = () async => FileDialogResult.opened(
        'big.png',
        Uint8List(ExerciseImageService.maxImageBytes + 1),
      );
      error = await _thrown(images.readImageFromDialog);
      expect(
        (error as StateError).message,
        'Image is larger than the 50 KB maximum. Compress or resize it before importing.',
      );
      expect(support.existsSync(), isFalse);
    });

    test(
      'the embedded (portable) route checks the same bytes as the folder route',
      () async {
        final file = File('assets/lesson_icons/home.png');
        final viaFile = await PortableExerciseImageService.fromFile(file);
        final viaBytes = await PortableExerciseImageService.fromBytes(
          file.readAsBytesSync(),
        );
        expect(viaBytes, viaFile);

        final error = await _thrown(
          () => PortableExerciseImageService.fromBytes(
            Uint8List.fromList(utf8.encode('not an image')),
          ),
        );
        expect(
          (error as FormatException).message,
          'Choose a readable PNG, JPEG or WEBP image.',
        );
        final tooBig = await _thrown(
          () => PortableExerciseImageService.fromBytes(
            Uint8List(PortableExerciseImageService.maxImageBytes + 1),
          ),
        );
        expect(
          (tooBig as FormatException).message,
          'Exercise images must not exceed 50 KB.',
        );
      },
    );
  });

  group('Single MP3 Open from…', () {
    late Directory support;
    late RecordedAudioService audio;

    setUp(() {
      support = Directory('${root.path}${Platform.pathSeparator}support');
      audio = RecordedAudioService(
        fileDialogs: dialogs,
        supportDirectory: () async => support,
      );
    });

    test(
      'is stored in the course audio folder, bytes unchanged, no text',
      () async {
        final bytes = syntheticMp3();
        backend.onOpen = () async =>
            FileDialogResult.opened('Buon giorno (1).mp3', bytes);

        final picked = await audio.importMp3FromDialog('course-a');

        final clip = picked.clip!;
        expect(clip.text, isEmpty);
        expect(clip.id, startsWith('audio_'));
        // Build 243: named by content, stored in the Course's media folder.
        expect(clip.filePath, CourseMediaStore.referenceFor(bytes, 'mp3'));
        final stored = await CourseMediaStore(
          supportDirectory: () async => support,
        ).existingFile('course-a', clip.filePath);
        expect(
          stored!.parent.path,
          endsWith(CourseMediaStore.folderNameFor('course-a')),
        );
        expect(await stored.readAsBytes(), bytes);
      },
    );

    test('cancel stores nothing and logs nothing', () async {
      final picked = await audio.importMp3FromDialog('course-a');
      expect(picked.clip, isNull);
      expect(picked.dialog.outcome, FileDialogOutcome.cancelled);
      expect(support.existsSync(), isFalse);
      expect(await _diagnosticLog(), isEmpty);
    });

    test('a non-MP3 name or a file over 50 MB is rejected', () async {
      backend.onOpen = () async =>
          FileDialogResult.opened('x.wav', Uint8List(10));
      var error = await _thrown(() => audio.importMp3FromDialog('course-a'));
      expect((error as StateError).message, 'Choose an MP3 file.');

      backend.onOpen = () async => FileDialogResult.opened(
        'big.mp3',
        Uint8List(RecordedAudioService.maxMp3Bytes + 1),
      );
      error = await _thrown(() => audio.importMp3FromDialog('course-a'));
      expect(
        (error as StateError).message,
        'MP3 files larger than 50 MB are not accepted.',
      );
      expect(support.existsSync(), isFalse);
    });

    test(
      'two imports of the same bytes get distinct clip ids and share one file',
      () async {
        backend.onOpen = () async =>
            FileDialogResult.opened('same.mp3', syntheticMp3());
        final first = (await audio.importMp3FromDialog('course-a')).clip!;
        final second = (await audio.importMp3FromDialog('course-a')).clip!;
        expect(second.id, isNot(first.id));
        // Build 243: course media is named by content.
        expect(second.filePath, first.filePath);
        final folder = await CourseMediaStore(
          supportDirectory: () async => support,
        ).courseDirectory('course-a');
        expect(folder.listSync().whereType<File>(), hasLength(1));
      },
    );
  });

  group('Lesson theme icon Open from…', () {
    testWidgets('a valid image is normalized exactly like the folder import', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final bytes = File('assets/lesson_icons/home.png').readAsBytesSync();
        final backend = FakeFileDialogBackend()
          ..onOpen = () async => FileDialogResult.opened('mine.png', bytes);
        final icons = LessonIconService(
          fileDialogs: FileDialogService(
            stager: testImportStager(),
            backend: backend,
            diagnosticLog: DiagnosticLogService(),
          ),
        );

        final picked = await icons.importPreparedIconFromDialog();
        final direct = await icons.prepareIcon(bytes, assetId: 'custom_direct');

        expect(picked.dialog.outcome, FileDialogOutcome.opened);
        expect(picked.icon!.asset.reference, contains('custom_'));
        expect(picked.icon!.asset.base64Png, direct.asset.base64Png);
        expect(picked.icon!.sourceWidth, direct.sourceWidth);
      });
    });

    testWidgets('cancel returns no icon and logs nothing', (tester) async {
      await tester.runAsync(() async {
        final icons = LessonIconService(
          fileDialogs: FileDialogService(
            stager: testImportStager(),
            backend: FakeFileDialogBackend(),
            diagnosticLog: DiagnosticLogService(),
          ),
        );
        final picked = await icons.importPreparedIconFromDialog();
        expect(picked.icon, isNull);
        expect(picked.dialog.outcome, FileDialogOutcome.cancelled);
        expect(await _diagnosticLog(), isEmpty);
      });
    });

    testWidgets('a non-image and an oversized file are rejected as before', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final backend = FakeFileDialogBackend();
        final icons = LessonIconService(
          fileDialogs: FileDialogService(
            stager: testImportStager(),
            backend: backend,
            diagnosticLog: DiagnosticLogService(),
          ),
        );

        backend.onOpen = () async => FileDialogResult.opened(
          'x.png',
          Uint8List.fromList(utf8.encode('not an image')),
        );
        var error = await _thrown(icons.importPreparedIconFromDialog);
        expect(
          (error as FormatException).message,
          'The selected Lesson icon is not a supported image.',
        );

        backend.onOpen = () async => FileDialogResult.opened(
          'big.png',
          Uint8List(LessonIconService.maxInputBytes + 1),
        );
        error = await _thrown(icons.importPreparedIconFromDialog);
        expect(
          (error as FormatException).message,
          'Lesson icon must be a readable image no larger than 2 MB.',
        );
      });
    });
  });

  group('Diagnostic Log copy', () {
    test('an empty log has nothing to save', () async {
      expect(await DiagnosticLogService().exportBytes(), isNull);
    });

    test('the snapshot equals the log and leaves it unchanged', () async {
      final log = DiagnosticLogService();
      await log.logInfo('hello diagnostic');
      final before = await _diagnosticLog();

      final bytes = await log.exportBytes();

      expect(utf8.decode(bytes!), before);
      expect(await _diagnosticLog(), before);
    });
  });
}
