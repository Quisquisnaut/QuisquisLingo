import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/course_image_usage.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/exercise_image_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/import/selected_external_file.dart';

import 'support/fake_file_dialog_backend.dart';
import 'support/pump_file_io.dart';

class _Catalog extends ExerciseImageMetadataService {
  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => const [];
}

Uint8List _asset(String name) =>
    File('assets/exercise_images/$name').readAsBytesSync();

Map<String, dynamic> _courseJson() =>
    jsonDecode(
          File(
            'demo_courses/italian_demo_2_pick_the_translation.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

void main() {
  group('library entry metadata', () {
    test('round-trips and is omitted when empty', () {
      final json = _courseJson()
        ..['imageLibrary'] = [
          {
            'asset': 'media:${'a' * 64}.png',
            'label': 'Cat',
            'category': 'animals',
            'tags': ['cat', 'pet'],
            'attribution': {'author': 'A. Artist', 'license': 'CC BY 4.0'},
          },
        ];
      final entry = Course.fromJson(json).imageLibrary.single;
      expect(entry.label, 'Cat');
      expect(entry.category, 'animals');
      expect(entry.tags, ['cat', 'pet']);
      expect(entry.attribution?.author, 'A. Artist');
      final plain = const CourseImageLibraryEntry(
        asset: 'media:x.png',
      ).toJson();
      expect(plain.keys, ['asset']);
    });

    test('limits are enforced', () {
      final asset = 'media:${'b' * 64}.png';
      for (final bad in [
        () => CourseImageLibraryEntry.checked(asset: asset, label: 'x' * 201),
        () =>
            CourseImageLibraryEntry.checked(asset: asset, category: 'Bad Cat'),
        () => CourseImageLibraryEntry.checked(
          asset: asset,
          tags: [for (var i = 0; i < 33; i++) 't$i'],
        ),
        () => CourseImageLibraryEntry.checked(asset: asset, tags: ['x' * 81]),
        () => CourseImageLibraryEntry.checked(asset: asset, label: 'a\u0000b'),
      ]) {
        expect(bad, throwsFormatException);
      }
    });
  });

  group('adding to a Course from the Course Editor', () {
    late Directory temp;
    late CourseMediaStore media;
    late FakeFileDialogBackend backend;
    late List<Course> changes;

    Future<Course> show(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('qql_course_library_import_'),
      ))!;
      addTearDown(() async {
        try {
          await temp.delete(recursive: true);
        } catch (_) {}
      });
      media = CourseMediaStore(supportDirectory: () async => temp);
      backend = FakeFileDialogBackend();
      final dialogs = FileDialogService(
        backend: backend,
        stager: testImportStager(),
      );
      changes = [];
      final course = Course.fromJson(_courseJson());
      await tester.pumpWidget(
        MaterialApp(
          home: FlatImageLibraryScreen(
            selectMode: false,
            readOnly: true,
            course: course,
            savedCourse: course,
            mediaStore: media,
            metadataService: _Catalog(),
            imageService: ExerciseImageService(
              fileDialogs: dialogs,
              supportDirectory: () async => temp,
            ),
            bankService: ImageBankService(
              fileDialogs: dialogs,
              temporaryDirectory: () async => temp,
            ),
            onCourseChanged: changes.add,
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.byKey(const Key('course-image-add')).evaluate().isNotEmpty,
      );
      return course;
    }

    Future<void> choose(WidgetTester tester, String label) async {
      await tester.tap(find.byKey(const Key('course-image-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpUntilFileIoState(
        () => find.text('Close').evaluate().isNotEmpty,
      );
    }

    testWidgets('several images: added unused, duplicates and junk reported', (
      tester,
    ) async {
      final course = await show(tester);
      backend.onOpenMany = [
        MemorySelectedFile('apple.webp', _asset('apple.webp')),
        MemorySelectedFile('plane.webp', _asset('airplane.webp')),
        MemorySelectedFile('again.webp', _asset('apple.webp')),
        MemorySelectedFile('notes.png', Uint8List.fromList(utf8.encode('hi'))),
      ];
      await choose(tester, 'Open image files from…');
      expect(find.text('Imported: 2'), findsOneWidget);
      expect(find.text('Duplicates skipped: 1'), findsOneWidget);
      expect(find.text('Unreadable or damaged: 1'), findsOneWidget);

      final changed = changes.single;
      expect(changed.imageLibrary, hasLength(2));
      expect(changed.imageLibrary.first.label, 'apple');
      // In the Course, but not used by any exercise.
      final used = CourseImageUsage.usedAssets(changed);
      for (final entry in changed.imageLibrary) {
        expect(used, isNot(contains(entry.asset)));
        expect(
          await tester.runAsync(
            () => media.existingFile(course.courseId, entry.asset),
          ),
          isNotNull,
        );
      }
      // Nothing went to the Shared Image Library.
      expect(
        Directory(
          '${temp.path}${Platform.pathSeparator}exercise_images',
        ).existsSync(),
        isFalse,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('an Image Bank keeps its names, categories and credits', (
      tester,
    ) async {
      await show(tester);
      final archive = Archive()
        ..addFile(
          ArchiveFile.bytes(
            'image_bank_manifest.json',
            utf8.encode(
              jsonEncode([
                {
                  'id': 'fruit-1',
                  'primary_term': 'Apple',
                  'category': 'food',
                  'keywords': ['apple', 'fruit'],
                  'filename': 'apple.webp',
                  'attribution': {
                    'author': 'A. Artist',
                    'license': 'CC BY 4.0',
                  },
                },
              ]),
            ),
          ),
        )
        ..addFile(ArchiveFile.bytes('apple.webp', _asset('apple.webp')));
      backend.onOpen = () async => FileDialogResult.opened(
        'fruit.zip',
        Uint8List.fromList(ZipEncoder().encode(archive)),
      );
      await choose(tester, 'Open Image Bank ZIP from…');
      expect(find.text('Imported: 1'), findsOneWidget);
      final entry = changes.single.imageLibrary.single;
      expect(entry.label, 'Apple');
      expect(entry.category, 'food_drinks');
      expect(entry.tags, ['apple', 'fruit']);
      expect(entry.attribution?.author, 'A. Artist');
      expect(
        Directory(
          '${temp.path}${Platform.pathSeparator}image_banks',
        ).existsSync(),
        isFalse,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('nothing is written past the 300 MB package limit', (
      tester,
    ) async {
      final course = await show(tester);
      // A Course folder 100 bytes under the limit; the image is larger.
      await tester.runAsync(() async {
        final directory = await media.courseDirectory(
          course.courseId,
          create: true,
        );
        final filler = await File(
          '${directory.path}${Platform.pathSeparator}filler.bin',
        ).open(mode: FileMode.write);
        await filler.truncate(300 * 1024 * 1024 - 100);
        await filler.close();
      });
      backend.onOpenMany = [
        MemorySelectedFile('apple.webp', _asset('apple.webp')),
      ];
      await tester.tap(find.byKey(const Key('course-image-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open image files from…').last);
      await tester.pumpUntilFileIoState(
        () => find.textContaining('300 MB limit').evaluate().isNotEmpty,
      );
      expect(changes, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
