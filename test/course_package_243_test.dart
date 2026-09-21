import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late CourseMediaStore media;
  late CoursePackageService packages;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('qql_course_package_');
    media = CourseMediaStore(supportDirectory: () async => temp);
    packages = CoursePackageService(mediaStore: media);
  });
  tearDown(() => temp.delete(recursive: true));

  Future<Course> fixture({String? recording, String? cover}) async {
    final raw =
        jsonDecode(
              await File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    if (recording != null) {
      raw['audioLibrary'] = [
        {'id': 'recording', 'text': 'ciao', 'filePath': recording},
      ];
    }
    if (cover != null) raw['coverImage'] = cover;
    return Course.fromJson(raw);
  }

  Uint8List zipped(Map<String, List<int>> entries) {
    final archive = Archive();
    for (final entry in entries.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  test(
    'package round trip keeps Course JSON bytes and recording bytes',
    () async {
      final recording = Uint8List.fromList([1, 2, 3, 4]);
      final reference = CourseMediaStore.referenceFor(recording, 'mp3');
      final course = await fixture(recording: reference);
      await media.addBytes(course.courseId, recording, 'mp3');
      final courseJson = Uint8List.fromList(
        utf8.encode(jsonEncode(course.toJson())),
      );

      final zip = await packages.build(course, courseJson);
      final imported = await packages.parse(
        zip,
        (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
      );

      expect(imported.course.toJson(), course.toJson());
      expect(imported.courseJson, courseJson);
      expect(imported.media[reference], recording);
      await imported.withInstalledMedia('destination', () async => null);
      expect(await media.existingFile('destination', reference), isNotNull);
    },
  );

  test(
    'exports only the shared-library image copied into this Course',
    () async {
      final used = Uint8List.fromList([1, 2, 3, 4]);
      final unused = Uint8List.fromList([5, 6, 7, 8]);
      final usedReference = await media.addBytes(
        'italian-demo-2-239',
        used,
        'webp',
      );
      final unusedReference = await media.addBytes(
        'italian-demo-2-239',
        unused,
        'webp',
      );
      final raw =
          jsonDecode(
                await File(
                  'demo_courses/italian_demo_2_pick_the_translation.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final lessons = raw['lessons'] as List;
      final rounds = (lessons.first as Map)['rounds'] as List;
      final content = (rounds.first as Map)['content'] as List;
      final exercise = (content.first as Map)['exercise'] as Map;
      final prompt = exercise['prompt'] as List;
      (prompt[1] as Map)['asset'] = usedReference;
      (prompt[1] as Map)['sharedImageSource'] = {
        'id': 'bank-cat-01',
        'label': 'Cat',
        'category': 'animals',
        'tags': ['cat', 'feline'],
        'origin': 'bank:animals',
        'attribution': {
          'author': 'A. Artist',
          'license': 'CC BY 4.0',
          'title': 'Cat drawing',
          'source': 'https://example.org/cat',
        },
      };
      final course = Course.fromJson(raw);

      final zip = await packages.build(
        course,
        Uint8List.fromList(utf8.encode(jsonEncode(course.toJson()))),
      );
      final archive = ZipDecoder().decodeBytes(zip);
      final names = archive.files.map((file) => file.name);
      expect(
        names,
        contains('media/${CourseMediaStore.fileNameOf(usedReference)}'),
      );
      expect(
        names,
        isNot(
          contains('media/${CourseMediaStore.fileNameOf(unusedReference)}'),
        ),
      );
      expect(names.length, 3);
      final manifest =
          jsonDecode(
                utf8.decode(
                  archive.files
                          .singleWhere(
                            (file) =>
                                file.name == CoursePackageService.manifestName,
                          )
                          .content
                      as List<int>,
                ),
              )
              as Map<String, dynamic>;
      final source = (manifest['sharedImageSources'] as List).single as Map;
      expect(source['media'], usedReference);
      expect(source['sha256'], CourseMediaStore.digestOf(usedReference));
      expect(source['id'], 'bank-cat-01');
      expect(source['tags'], ['cat', 'feline']);
      expect(source['attribution'], {
        'author': 'A. Artist',
        'license': 'CC BY 4.0',
        'title': 'Cat drawing',
        'source': 'https://example.org/cat',
      });
      final imported = await packages.parse(
        zip,
        (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
      );
      expect(
        imported
            .course
            .lessons
            .first
            .rounds
            .first
            .exercises
            .first
            .promptElements[1]
            .sharedImageSource
            ?.id,
        'bank-cat-01',
      );
      expect(
        imported
            .course
            .lessons
            .first
            .rounds
            .first
            .exercises
            .first
            .promptElements[1]
            .sharedImageSource
            ?.attribution
            ?.author,
        'A. Artist',
      );
      final copied = AuthoringDuplicationService().copyCourseAsNew(
        imported.course,
        title: 'Copied course',
        originalCourseCreator: imported.course.originalCourseCreator,
        maintainer: imported.course.maintainer!,
      );
      expect(
        copied
            .lessons
            .first
            .rounds
            .first
            .exercises
            .first
            .promptElements[1]
            .sharedImageSource
            ?.id,
        'bank-cat-01',
      );
      source['id'] = 'different-image';
      await expectLater(
        packages.parse(
          zipped({
            CoursePackageService.manifestName: utf8.encode(
              jsonEncode(manifest),
            ),
            CoursePackageService.courseName: utf8.encode(
              jsonEncode(course.toJson()),
            ),
            'media/${CourseMediaStore.fileNameOf(usedReference)}': used,
          }),
          (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
        ),
        throwsFormatException,
      );
      source['id'] = 'bank-cat-01';
      (source['attribution'] as Map)['author'] = 'Different artist';
      await expectLater(
        packages.parse(
          zipped({
            CoursePackageService.manifestName: utf8.encode(
              jsonEncode(manifest),
            ),
            CoursePackageService.courseName: utf8.encode(
              jsonEncode(course.toJson()),
            ),
            'media/${CourseMediaStore.fileNameOf(usedReference)}': used,
          }),
          (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
        ),
        throwsFormatException,
      );
    },
  );

  test('the checked-in demo ZIP imports as a Course package', () async {
    final zip = await File(
      'demo_courses/italian_demo_2_pick_the_translation.zip',
    ).readAsBytes();
    final imported = await packages.parse(
      zip,
      (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
    );
    expect(imported.course.courseId, 'italian-demo-2-239');
    expect(imported.media, isEmpty);
  });

  test('altered and missing media are refused before installation', () async {
    final original = Uint8List.fromList([1, 2, 3]);
    final reference = CourseMediaStore.referenceFor(original, 'mp3');
    final course = await fixture(recording: reference);
    final courseJson = utf8.encode(jsonEncode(course.toJson()));
    final manifest = utf8.encode('{"packageFormat":1}');
    Future<Course> validate(Uint8List bytes, String _) async =>
        Course.fromJson(jsonDecode(utf8.decode(bytes)));

    await expectLater(
      packages.parse(
        zipped({
          'qql-course-package.json': manifest,
          'course.json': courseJson,
          'media/${CourseMediaStore.fileNameOf(reference)}': [9, 9, 9],
        }),
        validate,
      ),
      throwsFormatException,
    );
    await expectLater(
      packages.parse(
        zipped({
          'qql-course-package.json': manifest,
          'course.json': courseJson,
        }),
        validate,
      ),
      throwsFormatException,
    );
    expect(
      await media.courseDirectory(course.courseId).then((d) => d.exists()),
      isFalse,
    );
  });

  test('dangerous names and non-course ZIPs are refused', () async {
    final course = await fixture();
    final courseJson = utf8.encode(jsonEncode(course.toJson()));
    Future<Course> validate(Uint8List bytes, String _) async =>
        Course.fromJson(jsonDecode(utf8.decode(bytes)));
    for (final name in [
      '../course.json',
      '/course.json',
      'media/../evil.mp3',
    ]) {
      await expectLater(
        packages.parse(
          zipped({
            'qql-course-package.json': utf8.encode('{"packageFormat":1}'),
            'course.json': courseJson,
            name: [1],
          }),
          validate,
        ),
        throwsFormatException,
      );
    }
    await expectLater(
      packages.parse(zipped({'course.json': courseJson}), validate),
      throwsFormatException,
    );
  });

  test(
    'media is copied after acceptance and removed when the save fails',
    () async {
      final recording = Uint8List.fromList([4, 5, 6]);
      final reference = CourseMediaStore.referenceFor(recording, 'mp3');
      final course = await fixture(recording: reference);
      final item = CoursePackage(course, Uint8List(0), {reference: recording});

      await expectLater(
        item.withInstalledMedia('new-course', () async {
          expect(await media.existingFile('new-course', reference), isNotNull);
          throw StateError('save failed');
        }, mediaStore: media),
        throwsStateError,
      );
      expect(await media.existingFile('new-course', reference), isNull);
      await item.withInstalledMedia(
        'new-course',
        () async => null,
        mediaStore: media,
      );
      expect(await media.existingFile('new-course', reference), isNotNull);
    },
  );

  test(
    'Copy or Fork keeps media in the new Course, not a staging folder',
    () async {
      final bytes = Uint8List.fromList([8, 3, 1]);
      final reference = CourseMediaStore.referenceFor(bytes, 'mp3');
      final course = await fixture(recording: reference);
      final package = CoursePackage(course, Uint8List(0), {
        reference: bytes,
      }, mediaStore: media);
      await package.withInstalledMedia(course.courseId, () async {
        expect(await media.existingFile(course.courseId, reference), isNotNull);
        expect(
          await media.copyReferences(course.courseId, 'copied-course', {
            reference,
          }),
          isEmpty,
        );
      }, keepOnSuccess: false);
      expect(await media.existingFile(course.courseId, reference), isNull);
      expect(await media.existingFile('copied-course', reference), isNotNull);
    },
  );

  test('fixed import accepts ZIP and media-free JSON', () async {
    final transfer = CustomCourseTransferService(
      directory: () async => temp,
      packageService: packages,
    );
    final course = await fixture();
    final json = Uint8List.fromList(utf8.encode(jsonEncode(course.toJson())));
    await File(await transfer.importFilePath()).writeAsBytes(json);
    expect(
      (await transfer.importCoursePackage()).course.toJson(),
      course.toJson(),
    );

    await File(await transfer.importFilePath()).delete();
    await File(
      await transfer.importPackagePath(),
    ).writeAsBytes(await packages.build(course, json));
    expect(
      (await transfer.importCoursePackage()).course.toJson(),
      course.toJson(),
    );
  });

  test('single JSON with media references asks for a package', () async {
    final transfer = CustomCourseTransferService(
      directory: () async => temp,
      packageService: packages,
    );
    final reference = CourseMediaStore.referenceFor([1, 2, 3], 'mp3');
    final course = await fixture(recording: reference);
    await File(
      await transfer.importFilePath(),
    ).writeAsString(jsonEncode(course.toJson()));
    await expectLater(transfer.importCoursePackage(), throwsFormatException);
  });

  test(
    'extra valid media is ignored but unexpected files are rejected',
    () async {
      final course = await fixture();
      final extra = Uint8List.fromList([7, 8, 9]);
      final extraRef = CourseMediaStore.referenceFor(extra, 'mp3');
      final entries = <String, List<int>>{
        'qql-course-package.json': utf8.encode('{"packageFormat":1}'),
        'course.json': utf8.encode(jsonEncode(course.toJson())),
        'media/${CourseMediaStore.fileNameOf(extraRef)}': extra,
      };
      Future<Course> validate(Uint8List bytes, String _) async =>
          Course.fromJson(jsonDecode(utf8.decode(bytes)));
      expect((await packages.parse(zipped(entries), validate)).media, isEmpty);
      await expectLater(
        packages.parse(
          zipped({
            ...entries,
            'notes.txt': [1],
          }),
          validate,
        ),
        throwsFormatException,
      );
    },
  );

  test('compressed and expanded package size are checked separately', () async {
    final course = await fixture();
    final zip = zipped({
      'qql-course-package.json': utf8.encode('{"packageFormat":1}'),
      'course.json': utf8.encode(jsonEncode(course.toJson())),
    });
    Future<Course> validate(Uint8List bytes, String _) async =>
        Course.fromJson(jsonDecode(utf8.decode(bytes)));
    await expectLater(
      CoursePackageService(
        mediaStore: media,
        sizeLimit: zip.length - 1,
      ).parse(zip, validate),
      throwsFormatException,
    );
    expect(jsonEncode(course.toJson()).length, greaterThan(zip.length));
    await expectLater(
      CoursePackageService(
        mediaStore: media,
        sizeLimit: zip.length,
      ).parse(zip, validate),
      throwsFormatException,
    );
  });

  test(
    'cover requires real 512 square image with matching file type',
    () async {
      Future<Uint8List> png(int width, int height) async {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawRect(
          ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          ui.Paint()..color = const ui.Color(0xff23aabb),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(width, height);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        return data!.buffer.asUint8List();
      }

      Future<void> check(Uint8List bytes, String extension, bool valid) async {
        final reference = CourseMediaStore.referenceFor(bytes, extension);
        final course = await fixture(cover: reference);
        final zip = zipped({
          'qql-course-package.json': utf8.encode('{"packageFormat":1}'),
          'course.json': utf8.encode(jsonEncode(course.toJson())),
          'media/${CourseMediaStore.fileNameOf(reference)}': bytes,
        });
        final result = packages.parse(
          zip,
          (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
        );
        if (valid) {
          expect((await result).course.coverImage, reference);
        } else {
          await expectLater(result, throwsFormatException);
        }
      }

      await check(await png(512, 512), 'png', true);
      await check(await png(512, 256), 'png', false);
      await check(await png(512, 512), 'jpg', false);
    },
  );
}
