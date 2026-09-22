import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';

import 'support/fake_file_dialog_backend.dart';
import 'support/synthetic_mp3.dart';

/// Build 243 Revision 15 (Tranche 4, part 2): a Course package is read from
/// disk a piece at a time and its media wait in staging, not in memory.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late CourseMediaStore media;
  late ImportStager stager;
  late CoursePackageService packages;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('qql_package_on_disk_');
    media = CourseMediaStore(supportDirectory: () async => temp);
    stager = ImportStager(supportDirectory: () async => temp);
    packages = CoursePackageService(mediaStore: media, stager: stager);
  });
  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } catch (_) {}
  });

  Future<Course> validate(Uint8List bytes, String _) async =>
      Course.fromJson(jsonDecode(utf8.decode(bytes)));

  /// A Course using [recordings], zipped with those recordings plus
  /// [extra] unused media entries.
  Future<({Course course, Uint8List zip})> package(
    List<Uint8List> recordings, {
    Map<String, List<int>> extra = const {},
    String prefix = '',
  }) async {
    final raw =
        jsonDecode(
              await File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    raw['audioLibrary'] = [
      for (var i = 0; i < recordings.length; i++)
        {
          'id': 'clip$i',
          'text': 'word $i',
          'filePath': CourseMediaStore.referenceFor(recordings[i], 'mp3'),
        },
    ];
    final course = Course.fromJson(raw);
    final archive = Archive();
    if (prefix.isNotEmpty) {
      archive.addFile(ArchiveFile.directory(prefix));
    }
    archive
      ..addFile(
        ArchiveFile.bytes(
          '$prefix${CoursePackageService.manifestName}',
          utf8.encode('{"packageFormat":1}'),
        ),
      )
      ..addFile(
        ArchiveFile.bytes(
          '$prefix${CoursePackageService.courseName}',
          utf8.encode(jsonEncode(course.toJson())),
        ),
      );
    for (final recording in recordings) {
      archive.addFile(
        ArchiveFile.bytes(
          '${prefix}media/${CourseMediaStore.fileNameOf(CourseMediaStore.referenceFor(recording, 'mp3'))}',
          recording,
        ),
      );
    }
    for (final entry in extra.entries) {
      archive.addFile(ArchiveFile.bytes(entry.key, entry.value));
    }
    return (
      course: course,
      zip: Uint8List.fromList(ZipEncoder().encode(archive)),
    );
  }

  Future<List<File>> stagedParts() async {
    final directory = await stager.stagingDirectory();
    if (!await directory.exists()) return const [];
    return directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.part'))
        .toList();
  }

  Future<File> onDisk(Uint8List bytes, {String name = 'package.zip'}) async {
    final file = File('${temp.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  test(
    'a package on disk is read into staging, installed, discarded',
    () async {
      final one = syntheticMp3(seed: 1);
      final two = syntheticMp3(seed: 2);
      final built = await package([one, two]);
      final parsed = await packages.parseFile(
        await onDisk(built.zip),
        validate,
      );
      expect(parsed.hadMatchingFolderWrapper, isFalse);

      final references = {
        CourseMediaStore.referenceFor(one, 'mp3'),
        CourseMediaStore.referenceFor(two, 'mp3'),
      };
      expect(parsed.mediaReferences, references);
      expect(await stagedParts(), hasLength(2));
      expect(
        await parsed.mediaBytes(CourseMediaStore.referenceFor(two, 'mp3')),
        two,
      );
      // Nothing reached the Course folder while reading.
      expect(
        await media
            .courseDirectory(built.course.courseId)
            .then((d) => d.exists()),
        isFalse,
      );

      await parsed.withInstalledMedia('destination', () async => null);
      for (final reference in references) {
        expect(await media.existingFile('destination', reference), isNotNull);
      }
      await parsed.discard();
      expect(await stagedParts(), isEmpty);
      // Discarding twice is harmless.
      await parsed.discard();
    },
  );

  test('a ZIP-stem folder preserves Course and referenced media', () async {
    final recording = syntheticMp3(seed: 12);
    final built = await package([recording], prefix: 'sample/');
    final parsed = await packages.parseFile(
      await onDisk(built.zip, name: 'sample.zip'),
      validate,
    );

    final reference = CourseMediaStore.referenceFor(recording, 'mp3');
    expect(parsed.hadMatchingFolderWrapper, isTrue);
    expect(parsed.course.toJson(), built.course.toJson());
    expect(parsed.courseJson, utf8.encode(jsonEncode(built.course.toJson())));
    expect(parsed.mediaReferences, {reference});
    expect(await parsed.mediaBytes(reference), recording);
    expect(await stagedParts(), hasLength(1));
    await parsed.discard();
    expect(await stagedParts(), isEmpty);
  });

  test(
    'only an exact ZIP-stem wrapper with expected files is accepted',
    () async {
      final cases =
          <({String name, String prefix, Map<String, List<int>> extra})>[
            (name: 'different folder', prefix: 'other/', extra: {}),
            (name: 'different case', prefix: 'Sample/', extra: {}),
            (name: 'nested folder', prefix: 'sample/inner/', extra: {}),
            (
              name: 'mixed root and wrapper',
              prefix: 'sample/',
              extra: {'course.json': utf8.encode('{}')},
            ),
            (
              name: 'extra wrapper file',
              prefix: 'sample/',
              extra: {
                'sample/notes.txt': [1],
              },
            ),
            (
              name: 'extra root file',
              prefix: 'sample/',
              extra: {
                'notes.txt': [1],
              },
            ),
            (
              name: 'wrapper traversal',
              prefix: 'sample/',
              extra: {
                'sample/../course.json': [1],
              },
            ),
            (
              name: 'duplicate slash alias',
              prefix: 'sample/',
              extra: {
                r'sample\course.json': [1],
              },
            ),
          ];
      for (final entry in cases) {
        final built = await package(
          [],
          prefix: entry.prefix,
          extra: entry.extra,
        );
        await expectLater(
          packages.parseFile(
            await onDisk(built.zip, name: 'sample.zip'),
            validate,
          ),
          throwsFormatException,
          reason: entry.name,
        );
        expect(await stagedParts(), isEmpty, reason: entry.name);
      }
    },
  );

  test('media the Course does not use is never read or staged', () async {
    final built = await package(
      [syntheticMp3(seed: 3)],
      extra: {'media/${'e' * 64}.mp3': utf8.encode('not even audio')},
    );
    final parsed = await packages.parseFile(await onDisk(built.zip), validate);
    expect(parsed.mediaReferences, hasLength(1));
    expect(await stagedParts(), hasLength(1));
    await parsed.discard();
  });

  test('a bad file half-way leaves nothing staged', () async {
    final good = syntheticMp3(seed: 4);
    final fake = Uint8List.fromList(utf8.encode('not audio'));
    final built = await package([good, fake]);
    await expectLater(
      packages.parseFile(await onDisk(built.zip), validate),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Export it as an MP3 again'),
        ),
      ),
    );
    expect(await stagedParts(), isEmpty);
  });

  test('a file over the package limit is refused before reading', () async {
    final small = CoursePackageService(
      mediaStore: media,
      stager: stager,
      sizeLimit: 1024,
    );
    final built = await package([syntheticMp3(seed: 5)]);
    await expectLater(
      small.parseFile(await onDisk(built.zip), validate),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('300 MB'),
        ),
      ),
    );
  });

  group('Open from…', () {
    late FakeFileDialogBackend backend;
    late CustomCourseTransferService transfer;

    setUp(() {
      backend = FakeFileDialogBackend();
      transfer = CustomCourseTransferService(
        directory: () async => temp,
        fileDialogs: FileDialogService(backend: backend, stager: stager),
        packageService: packages,
      );
    });

    test(
      'Import and Merge accept a wrapper matching the picked ZIP name',
      () async {
        final recording = syntheticMp3(seed: 13);
        final built = await package([recording], prefix: 'sample/');
        backend.onOpen = () async =>
            FileDialogResult.opened('sample.zip', built.zip);

        final imported = (await transfer.importPackageFromDialog()).package!;
        expect(imported.hadMatchingFolderWrapper, isTrue);
        expect(imported.course.toJson(), built.course.toJson());
        expect(
          await imported.mediaBytes(
            CourseMediaStore.referenceFor(recording, 'mp3'),
          ),
          recording,
        );
        await imported.discard();
        expect(await stagedParts(), isEmpty);

        final merged = (await transfer.mergePackageFromDialog()).package!;
        expect(merged.hadMatchingFolderWrapper, isTrue);
        expect(merged.course.toJson(), built.course.toJson());
        expect(
          await merged.mediaBytes(
            CourseMediaStore.referenceFor(recording, 'mp3'),
          ),
          recording,
        );
        await merged.discard();
        expect(await stagedParts(), isEmpty);
      },
    );

    test('wrapper matching uses the original picked name, not its display name',
        () async {
      final stem = 'course_${List.filled(130, 'a').join()}';
      final fileName = '$stem.zip';
      final built = await package(const [], prefix: '$stem/');
      backend.onOpen = () async => FileDialogResult.opened(fileName, built.zip);

      final picked = await transfer.importPackageFromDialog();
      expect(picked.dialog.displayName, isNot(fileName));
      expect(picked.dialog.sourceFileName, fileName);
      expect(picked.package!.hadMatchingFolderWrapper, isTrue);
      await picked.package!.discard();

      final displayStem = picked.dialog.displayName!.substring(
        0,
        picked.dialog.displayName!.length - 4,
      );
      final wrongWrapper = await package(const [], prefix: '$displayStem/');
      backend.onOpen = () async => FileDialogResult.opened(
        fileName,
        wrongWrapper.zip,
      );
      await expectLater(
        transfer.importPackageFromDialog(),
        throwsA(isA<FormatException>()),
      );
      expect(await stagedParts(), isEmpty);
    });

    test('a ZIP is staged and read from disk; the copy is removed', () async {
      final recording = syntheticMp3(seed: 6);
      final built = await package([recording]);
      backend.onOpen = () async =>
          FileDialogResult.opened('course.zip', built.zip);
      final picked = await transfer.importPackageFromDialog();
      final parsed = picked.package!;
      expect(parsed.hadMatchingFolderWrapper, isFalse);
      expect(parsed.course.courseId, built.course.courseId);
      // Only the package's own recording is left in staging, not the ZIP.
      final parts = await stagedParts();
      expect(parts, hasLength(1));
      expect(await parts.single.readAsBytes(), recording);
      await parsed.discard();
      expect(await stagedParts(), isEmpty);
    });

    test('a refused ZIP leaves nothing staged', () async {
      backend.onOpen = () async => FileDialogResult.opened(
        'broken.zip',
        Uint8List.fromList(utf8.encode('not a zip')),
      );
      await expectLater(
        transfer.importPackageFromDialog(),
        throwsA(isA<FormatException>()),
      );
      expect(await stagedParts(), isEmpty);
    });

    test('a media-free JSON Course still opens', () async {
      final json = await File(
        'demo_courses/italian_demo_2_pick_the_translation.json',
      ).readAsBytes();
      backend.onOpen = () async => FileDialogResult.opened('course.json', json);
      final picked = await transfer.importPackageFromDialog();
      expect(picked.package!.mediaReferences, isEmpty);
      expect(await stagedParts(), isEmpty);
    });

    test('cancel stages nothing', () async {
      final picked = await transfer.importPackageFromDialog();
      expect(picked.package, isNull);
      expect(picked.dialog.outcome, FileDialogOutcome.cancelled);
      expect(await stagedParts(), isEmpty);
    });
  });
}
