import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/exercise_image_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/import/import_result.dart';
import 'package:quisquislingo_app/services/import/mp3_validator.dart';
import 'package:quisquislingo_app/services/import/selected_external_file.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_service.dart';
import 'package:quisquislingo_app/services/portable_exercise_image.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/services/user_recovery_key_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_file_dialog_backend.dart';

/// Phase 20: each synthetic adversarial artifact is sent through every
/// applicable user-facing import path, not only its validator in isolation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late FakeFileDialogBackend backend;
  late FileDialogService dialogs;
  late ImportStager stager;
  late CoursePackageService packages;

  Uint8List fixture(String name) =>
      File('test/fixtures/import/$name').readAsBytesSync();
  Future<File> put(String relative, List<int> bytes) async {
    final file = File(
      '${temp.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> rejects(
    Future<dynamic> Function() action,
    String message,
  ) async {
    await expectLater(
      action(),
      throwsA(predicate((Object error) => error.toString().contains(message))),
    );
  }

  Uint8List zip(Map<String, List<int>> files) {
    final archive = Archive();
    for (final entry in files.entries) {
      archive.addFile(ArchiveFile.bytes(entry.key, entry.value));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<Uint8List> courseZip({
    Uint8List? courseJson,
    String? mediaReference,
    Uint8List? media,
    bool libraryImage = false,
  }) async {
    final raw =
        jsonDecode(
              await File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    if (mediaReference != null) {
      if (mediaReference.endsWith('.mp3')) {
        raw['audioLibrary'] = [
          {'id': 'clip', 'text': 'word', 'filePath': mediaReference},
        ];
      } else if (libraryImage) {
        raw['imageLibrary'] = [
          {'asset': mediaReference},
        ];
      } else {
        raw['coverImage'] = mediaReference;
      }
    }
    return zip({
      CoursePackageService.manifestName: utf8.encode('{"packageFormat":1}'),
      CoursePackageService.courseName:
          courseJson ?? utf8.encode(jsonEncode(raw)),
      if (mediaReference != null && media != null)
        'media/${CourseMediaStore.fileNameOf(mediaReference)}': media,
    });
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('qql_route_matrix_');
    backend = FakeFileDialogBackend();
    stager = ImportStager(supportDirectory: () async => temp);
    dialogs = FileDialogService(backend: backend, stager: stager);
    packages = CoursePackageService(
      mediaStore: CourseMediaStore(supportDirectory: () async => temp),
      stager: stager,
    );
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => temp.path);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    });
  });

  for (final name in ['deep.json', 'invalid_utf8.json']) {
    final reason = name == 'deep.json' ? 'nested more than' : 'UTF-8';
    group('$name on every structured import route', () {
      test('Course import and Merge, fixed and Open from', () async {
        final bytes = fixture(name);
        final transfer = CustomCourseTransferService(
          importDirectory: () async => temp,
          mergeDirectory: () async => temp,
          fileDialogs: dialogs,
          packageService: packages,
        );
        await put('import.json', bytes);
        await put('merge.json', bytes);
        backend.onOpen = () async => FileDialogResult.opened('bad.json', bytes);
        await rejects(transfer.importCourse, reason);
        await rejects(transfer.mergeCourse, reason);
        await rejects(transfer.importCourseFromDialog, reason);
        await rejects(transfer.mergeCourseFromDialog, reason);
      });

      test('learner backup, fixed and Open from', () async {
        final bytes = fixture(name);
        final backup = LearnerBackupService(
          documentsDirectoryProvider: () async => temp,
          fileDialogs: dialogs,
        );
        await put('QuisquisLingo/Imports/learner_import.json', bytes);
        backend.onOpen = () async => FileDialogResult.opened('bad.json', bytes);
        await rejects(backup.readImportFile, reason);
        await rejects(backup.readImportFromDialog, reason);
      });

      test('Recovery Key, fixed and Open from', () async {
        final bytes = fixture(name);
        final keys = UserRecoveryKeyService(
          importsDirectoryProvider: () async => temp,
          fileDialogs: dialogs,
        );
        await put('bad.user-recovery-key.json', bytes);
        backend.onOpen = () async => FileDialogResult.opened('bad.json', bytes);
        await rejects(
          keys.findImportableUserRecoveryKeys,
          name == 'deep.json' ? reason : 'not valid JSON',
        );
        await rejects(
          keys.openUserRecoveryKeyFromDialog,
          name == 'deep.json' ? reason : 'not valid JSON',
        );
      });

      test('Course JSON inside ZIP, fixed and Open from', () async {
        final bytes = await courseZip(courseJson: fixture(name));
        final transfer = CustomCourseTransferService(
          importDirectory: () async => temp,
          mergeDirectory: () async => temp,
          fileDialogs: dialogs,
          packageService: packages,
        );
        await put('import.zip', bytes);
        await put('merge.zip', bytes);
        backend.onOpen = () async => FileDialogResult.opened('bad.zip', bytes);
        await rejects(transfer.importCoursePackage, reason);
        await rejects(transfer.mergeCoursePackage, reason);
        await rejects(transfer.importPackageFromDialog, reason);
        await rejects(transfer.mergePackageFromDialog, reason);
      });
    });
  }

  test(
    'NUL identity fixture is refused on Course, backup, and Recovery routes',
    () async {
      final nulId =
          (jsonDecode(utf8.decode(fixture('nul_identity.json')))
              as Map)['learnerProfileId'];
      final rawCourse =
          jsonDecode(
                await File(
                  'demo_courses/italian_demo_2_pick_the_translation.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      rawCourse['courseId'] = nulId;
      final courseBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(rawCourse)),
      );
      final transfer = CustomCourseTransferService(
        importDirectory: () async => temp,
        fileDialogs: dialogs,
        packageService: packages,
      );
      await put('import.json', courseBytes);
      backend.onOpen = () async =>
          FileDialogResult.opened('bad.json', courseBytes);
      await rejects(transfer.importCourse, 'NUL character');
      await rejects(transfer.importCourseFromDialog, 'NUL character');
      await File('${temp.path}/import.json').delete();
      final archive = await courseZip(courseJson: courseBytes);
      await put('import.zip', archive);
      backend.onOpen = () async => FileDialogResult.opened('bad.zip', archive);
      await rejects(transfer.importCoursePackage, 'NUL character');
      await rejects(transfer.importPackageFromDialog, 'NUL character');

      final backupBytes = Uint8List.fromList(
        utf8.encode(jsonEncode({'learnerProfileId': nulId})),
      );
      final backup = LearnerBackupService(
        documentsDirectoryProvider: () async => temp,
        fileDialogs: dialogs,
      );
      await put('QuisquisLingo/Imports/learner_import.json', backupBytes);
      backend.onOpen = () async =>
          FileDialogResult.opened('bad.json', backupBytes);
      await rejects(backup.readImportFile, 'NUL character');
      await rejects(backup.readImportFromDialog, 'NUL character');

      final keyBytes = fixture('nul_identity.json');
      final keys = UserRecoveryKeyService(
        importsDirectoryProvider: () async => temp,
        fileDialogs: dialogs,
      );
      await put('bad.user-recovery-key.json', keyBytes);
      backend.onOpen = () async =>
          FileDialogResult.opened('bad.json', keyBytes);
      await rejects(keys.findImportableUserRecoveryKeys, 'NUL character');
      await rejects(keys.openUserRecoveryKeyFromDialog, 'NUL character');
    },
  );

  for (final name in [
    'unsafe_path.zip',
    'missing_manifest.zip',
    'animated_bank.zip',
  ]) {
    final reason = switch (name) {
      'unsafe_path.zip' => 'unsafe path',
      'missing_manifest.zip' => 'image_bank_manifest.json',
      _ => 'Animated images',
    };
    test('$name: Image Bank fixed, Open from, and direct read', () async {
      final bytes = fixture(name);
      final bank = ImageBankService(
        fileDialogs: dialogs,
        temporaryDirectory: () async => temp,
      );
      final file = await put('QuisquisLingo/Imports/Images/bank.zip', bytes);
      backend.onOpen = () async => FileDialogResult.opened('bank.zip', bytes);
      await rejects(bank.readBankFromFolder, reason);
      await rejects(bank.readBankFromDialog, reason);
      await rejects(() => bank.readBank(file), reason);
    });
  }

  test(
    'unsafe ZIP reaches the Course package reader on all four routes',
    () async {
      final bytes = fixture('unsafe_path.zip');
      final transfer = CustomCourseTransferService(
        importDirectory: () async => temp,
        mergeDirectory: () async => temp,
        fileDialogs: dialogs,
        packageService: packages,
      );
      await put('import.zip', bytes);
      await put('merge.zip', bytes);
      backend.onOpen = () async => FileDialogResult.opened('bad.zip', bytes);
      await rejects(transfer.importCoursePackage, 'unsafe path');
      await rejects(transfer.mergeCoursePackage, 'unsafe path');
      await rejects(transfer.importPackageFromDialog, 'unsafe path');
      await rejects(transfer.mergePackageFromDialog, 'unsafe path');
    },
  );

  for (final name in [
    'text_as_image.png',
    'oversized_header.png',
    'animated.png',
  ]) {
    final reason = switch (name) {
      'text_as_image.png' => 'Export the picture again',
      'oversized_header.png' => '4096',
      _ => 'Animated images',
    };
    test('$name: Shared and Course image picks, single and batch', () async {
      final bytes = fixture(name);
      final image = ExerciseImageService(
        fileDialogs: dialogs,
        supportDirectory: () async => temp,
        stager: stager,
      );
      await put('QuisquisLingo/Imports/Images/bad.png', bytes);
      backend.onOpen = () async => FileDialogResult.opened('bad.png', bytes);
      backend.onOpenMany = [MemorySelectedFile('bad.png', bytes)];
      await rejects(image.readImage, reason);
      await rejects(image.readImageFromDialog, reason);
      final batch = await image.readImagesFromDialog();
      expect(batch.items, hasLength(1));
      expect(batch.items.single.outcome, ImportItemOutcome.malformed);
      expect(batch.items.single.message, contains(reason));
      // The Course Editor calls the same reader before addValidated; a bad
      // pick cannot create Course-owned media.
      expect(
        await Directory('${temp.path}/quisquislingo_course_media').exists(),
        isFalse,
      );
    });

    test(
      '$name: Recognize Characters fixed, Open from, and embedded bytes',
      () async {
        final bytes = fixture(name);
        final file = await put('recognize.png', bytes);
        await rejects(
          () => PortableExerciseImageService.fromFile(file),
          reason,
        );
        await rejects(
          () => PortableExerciseImageService.fromBytes(bytes),
          reason,
        );
        // The widget's Open from… route passes picked bytes to fromBytes.
        backend.onOpen = () async =>
            FileDialogResult.opened('recognize.png', bytes);
        final picked = await dialogs.openBytes(
          extensions: const ['png'],
          maxBytes: 50 * 1024,
          artifact: 'recognize-image',
        );
        await rejects(
          () => PortableExerciseImageService.fromBytes(picked.bytes!),
          reason,
        );
      },
    );

    test(
      '$name: Lesson icon fixed, Open from, and embedded preparation',
      () async {
        final bytes = fixture(name);
        final icons = LessonIconService(fileDialogs: dialogs);
        await put('QuisquisLingo/Imports/Lesson Icons/bad.png', bytes);
        backend.onOpen = () async => FileDialogResult.opened('bad.png', bytes);
        await rejects(icons.importPreparedIcon, reason);
        await rejects(icons.importPreparedIconFromDialog, reason);
        await rejects(() => icons.prepareIcon(bytes, assetId: 'bad'), reason);
      },
    );

    test('$name: custom flag fixed and embedded preparation', () async {
      final bytes = fixture(name);
      final flags = CourseFlagService();
      await put('QuisquisLingo/Exports/flag.png', bytes);
      await rejects(flags.importPreparedFlag, reason);
      await rejects(() => flags.prepareFlag(bytes), reason);
    });

    test(
      '$name: cover and library image inside package, fixed and Open from',
      () async {
        final bytes = fixture(name);
        final reference = CourseMediaStore.referenceFor(bytes, 'png');
        final transfer = CustomCourseTransferService(
          importDirectory: () async => temp,
          mergeDirectory: () async => temp,
          fileDialogs: dialogs,
          packageService: packages,
        );
        for (final libraryImage in [false, true]) {
          final archive = await courseZip(
            mediaReference: reference,
            media: bytes,
            libraryImage: libraryImage,
          );
          await put('import.zip', archive);
          await put('merge.zip', archive);
          backend.onOpen = () async =>
              FileDialogResult.opened('bad.zip', archive);
          await rejects(transfer.importCoursePackage, reason);
          await rejects(transfer.mergeCoursePackage, reason);
          await rejects(transfer.importPackageFromDialog, reason);
          await rejects(transfer.mergePackageFromDialog, reason);
        }
      },
    );
  }

  for (final name in ['text_as_audio.mp3', 'truncated.mp3', 'artwork.mp3']) {
    final reason = name == 'artwork.mp3'
        ? 'embedded artwork'
        : name == 'text_as_audio.mp3'
        ? 'web page'
        : 'damaged';
    test('$name: recorded MP3 fixed, Open from, batch, package', () async {
      final bytes = fixture(name);
      final audio = RecordedAudioService(
        fileDialogs: dialogs,
        supportDirectory: () async => temp,
        stager: stager,
      );
      await put('QuisquisLingo/Imports/Audio/bad.mp3', bytes);
      backend.onOpen = () async => FileDialogResult.opened('bad.mp3', bytes);
      backend.onOpenMany = [MemorySelectedFile('bad.mp3', bytes)];
      await rejects(() => audio.importMp3Files('course-a'), reason);
      await rejects(() => audio.importMp3FromDialog('course-a'), reason);
      await rejects(() => Mp3Validator.validate(bytes), reason);
      final batch = await audio.importMp3sFromDialog('course-a');
      expect(batch.clips, isEmpty);
      expect(batch.results, hasLength(1));
      expect(batch.results.single.outcome, ImportItemOutcome.malformed);
      expect(batch.results.single.message, contains(reason));

      final reference = CourseMediaStore.referenceFor(bytes, 'mp3');
      final archive = await courseZip(mediaReference: reference, media: bytes);
      final transfer = CustomCourseTransferService(
        importDirectory: () async => temp,
        mergeDirectory: () async => temp,
        fileDialogs: dialogs,
        packageService: packages,
      );
      await put('import.zip', archive);
      await put('merge.zip', archive);
      backend.onOpen = () async => FileDialogResult.opened('bad.zip', archive);
      await rejects(transfer.importCoursePackage, reason);
      await rejects(transfer.mergeCoursePackage, reason);
      await rejects(transfer.importPackageFromDialog, reason);
      await rejects(transfer.mergePackageFromDialog, reason);
      expect(
        await CourseMediaStore(
          supportDirectory: () async => temp,
        ).existingFile('course-a', reference),
        isNull,
      );
    });
  }

  test(
    'valid synthetic image passes the fixed, dialog, and embedded routes',
    () async {
      final bytes = fixture('valid_flag.png');
      final image = ExerciseImageService(
        fileDialogs: dialogs,
        supportDirectory: () async => temp,
        stager: stager,
      );
      await put('QuisquisLingo/Imports/Images/valid_flag.png', bytes);
      backend.onOpen = () async =>
          FileDialogResult.opened('valid_flag.png', bytes);
      backend.onOpenMany = [MemorySelectedFile('valid_flag.png', bytes)];
      final fixedPicked = await image.readImage();
      expect(fixedPicked.image.bytes, bytes);
      expect((await image.readImageFromDialog()).picked!.image.bytes, bytes);
      expect(
        (await image.readImagesFromDialog()).items.single.outcome,
        ImportItemOutcome.staged,
      );
      final media = CourseMediaStore(supportDirectory: () async => temp);
      final reference = await media.addValidated(
        'editor-course',
        fixedPicked.image,
      );
      expect(await media.existingFile('editor-course', reference), isNotNull);

      final embedded = await PortableExerciseImageService.fromBytes(bytes);
      expect(PortableExerciseImageService.decode(embedded), bytes);
      final file = await put('recognize.png', bytes);
      expect(await PortableExerciseImageService.fromFile(file), embedded);

      final icons = LessonIconService(fileDialogs: dialogs);
      await put('QuisquisLingo/Imports/Lesson Icons/icon.png', bytes);
      expect((await icons.importPreparedIcon()).sourceWidth, 64);
      expect(
        (await icons.importPreparedIconFromDialog()).icon!.sourceHeight,
        40,
      );

      final flags = CourseFlagService();
      await put('QuisquisLingo/Exports/flag.png', bytes);
      expect((await flags.importPreparedFlag()).sourceWidth, 64);
      expect((await flags.prepareFlag(bytes)).sourceHeight, 40);
    },
  );

  test('valid Image Bank, MP3, and Course media pass their routes', () async {
    final bankBytes = fixture('valid_bank.zip');
    final bank = ImageBankService(
      fileDialogs: dialogs,
      temporaryDirectory: () async => temp,
    );
    final bankFile = await put(
      'QuisquisLingo/Imports/Images/bank.zip',
      bankBytes,
    );
    backend.onOpen = () async => FileDialogResult.opened('bank.zip', bankBytes);
    expect((await bank.readBankFromFolder()).images, hasLength(1));
    expect((await bank.readBankFromDialog()).bank!.images, hasLength(1));
    expect((await bank.readBank(bankFile)).images, hasLength(1));

    final mp3 = fixture('valid.mp3');
    final audio = RecordedAudioService(
      fileDialogs: dialogs,
      supportDirectory: () async => temp,
      stager: stager,
    );
    await put('QuisquisLingo/Imports/Audio/valid.mp3', mp3);
    backend.onOpen = () async => FileDialogResult.opened('valid.mp3', mp3);
    backend.onOpenMany = [MemorySelectedFile('valid.mp3', mp3)];
    expect(await audio.importMp3Files('course-a'), hasLength(1));
    expect((await audio.importMp3FromDialog('course-b')).clip, isNotNull);
    expect((await audio.importMp3sFromDialog('course-c')).clips, hasLength(1));
    expect((await Mp3Validator.validate(mp3)).frames, 4);

    final transfer = CustomCourseTransferService(
      importDirectory: () async => temp,
      fileDialogs: dialogs,
      packageService: packages,
    );
    final mp3Zip = await courseZip(
      mediaReference: CourseMediaStore.referenceFor(mp3, 'mp3'),
      media: mp3,
    );
    await put('import.zip', mp3Zip);
    backend.onOpen = () async => FileDialogResult.opened('valid.zip', mp3Zip);
    final fixedMp3 = await transfer.importCoursePackage();
    final dialogMp3 = (await transfer.importPackageFromDialog()).package!;
    expect(fixedMp3.mediaReferences, hasLength(1));
    expect(dialogMp3.mediaReferences, hasLength(1));
    await fixedMp3.discard();
    await dialogMp3.discard();

    final cover = fixture('valid_cover.png');
    final coverZip = await courseZip(
      mediaReference: CourseMediaStore.referenceFor(cover, 'png'),
      media: cover,
    );
    await put('import.zip', coverZip);
    backend.onOpen = () async => FileDialogResult.opened('valid.zip', coverZip);
    final fixedCover = await transfer.importCoursePackage();
    final dialogCover = (await transfer.importPackageFromDialog()).package!;
    expect(fixedCover.mediaReferences, hasLength(1));
    expect(dialogCover.mediaReferences, hasLength(1));
    await fixedCover.discard();
    await dialogCover.discard();
  });

  for (final embedded in ['Recognize image', 'Lesson icon', 'custom flag']) {
    test(
      '$embedded inside Course JSON is checked on fixed, dialog, and ZIP routes',
      () async {
        final raw =
            jsonDecode(
                  await File(
                    'demo_courses/italian_demo_2_pick_the_translation.json',
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        final image = fixture(
          embedded == 'Lesson icon' ? 'animated_icon.png' : 'animated.png',
        );
        if (embedded == 'custom flag') {
          raw['flagImageBase64'] = base64Encode(image);
        } else if (embedded == 'Lesson icon') {
          raw['lessonIconAssets'] = [
            {'assetId': 'bad', 'base64Png': base64Encode(image)},
          ];
        } else {
          final lesson = (raw['lessons'] as List).first as Map<String, dynamic>;
          final round =
              (lesson['rounds'] as List).first as Map<String, dynamic>;
          final content =
              (round['content'] as List).first as Map<String, dynamic>;
          final exercise = content['exercise'] as Map<String, dynamic>;
          final prompt = exercise['prompt'] as List;
          (prompt.firstWhere((item) => item['type'] == 'image')
                  as Map<String, dynamic>)['asset'] =
              'data:image/png;base64,${base64Encode(image)}';
        }
        final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(raw)));
        final archive = await courseZip(courseJson: jsonBytes);
        final transfer = CustomCourseTransferService(
          importDirectory: () async => temp,
          fileDialogs: dialogs,
          packageService: packages,
        );
        await put('import.json', jsonBytes);
        backend.onOpen = () async =>
            FileDialogResult.opened('bad.json', jsonBytes);
        await rejects(transfer.importCourse, 'Animated images');
        await rejects(transfer.importCourseFromDialog, 'Animated images');
        await File('${temp.path}/import.json').delete();
        await put('import.zip', archive);
        backend.onOpen = () async =>
            FileDialogResult.opened('bad.zip', archive);
        await rejects(transfer.importCoursePackage, 'Animated images');
        await rejects(transfer.importPackageFromDialog, 'Animated images');
      },
    );
  }

  test('valid embedded Course JSON images remain importable', () async {
    final raw =
        jsonDecode(
              await File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    raw['flagImageBase64'] = base64Encode(fixture('valid_flag.png'));
    raw['lessonIconAssets'] = [
      {
        'assetId': 'valid',
        'base64Png': base64Encode(fixture('valid_icon.png')),
      },
    ];
    final lesson = (raw['lessons'] as List).first as Map<String, dynamic>;
    final round = (lesson['rounds'] as List).first as Map<String, dynamic>;
    final content = (round['content'] as List).first as Map<String, dynamic>;
    final exercise = content['exercise'] as Map<String, dynamic>;
    final prompt = exercise['prompt'] as List;
    (prompt.firstWhere((item) => item['type'] == 'image')
            as Map<String, dynamic>)['asset'] =
        'data:image/png;base64,${base64Encode(fixture('valid_flag.png'))}';
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(raw)));
    final transfer = CustomCourseTransferService(
      importDirectory: () async => temp,
      fileDialogs: dialogs,
      packageService: packages,
    );
    await put('import.json', jsonBytes);
    backend.onOpen = () async =>
        FileDialogResult.opened('valid.json', jsonBytes);
    expect((await transfer.importCourse()).courseId, raw['courseId']);
    expect(
      (await transfer.importCourseFromDialog()).course!.courseId,
      raw['courseId'],
    );
    await File('${temp.path}/import.json').delete();
    final archive = await courseZip(courseJson: jsonBytes);
    await put('import.zip', archive);
    backend.onOpen = () async => FileDialogResult.opened('valid.zip', archive);
    final fixed = await transfer.importCoursePackage();
    final opened = (await transfer.importPackageFromDialog()).package!;
    expect(fixed.course.courseId, raw['courseId']);
    expect(opened.course.courseId, raw['courseId']);
    await fixed.discard();
    await opened.discard();
  });
}
