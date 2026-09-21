import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';

import 'support/pump_file_io.dart';

class _Catalog extends ExerciseImageMetadataService {
  _Catalog(this.records);
  final List<ExerciseImageMetadata> records;

  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => records;
}

class _CourseMedia extends CourseMediaStore {
  @override
  Future<Directory> courseDirectory(
    String courseId, {
    bool create = false,
  }) async => Directory('test/nonexistent-image-preview-course');

  @override
  Future<File?> existingFile(String courseId, String reference) async =>
      File('assets/exercise_images/apple.webp');
}

class _Banks extends ImageBankService {
  @override
  Future<List<ImportedImageBank>> banks() async => const [
    ImportedImageBank(id: 'bank_1', path: 'unused', name: 'Fruit pictures'),
  ];
}

bool _tooltipContains(WidgetTester tester, String text) {
  final finder = find.byKey(const Key('image-preview-details-tooltip'));
  if (finder.evaluate().isEmpty) return false;
  return tester.widget<Tooltip>(finder).message?.contains(text) ?? false;
}

void main() {
  testWidgets('only the full-size preview picture has the details tooltip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const item = ExerciseImageMetadata(
      id: 'apple',
      label: 'Apple',
      category: 'food_drinks',
      tags: ['apple'],
      assetPath: 'assets/exercise_images/apple.webp',
      origin: 'bundled',
    );
    const missing = ExerciseImageMetadata(
      id: 'missing',
      label: 'Missing',
      category: 'other',
      tags: [],
      assetPath: 'C:/no-such-image-file.png',
      origin: 'local',
    );
    final bank = ExerciseImageMetadata(
      id: 'bank-apple',
      label: 'Bank apple',
      category: 'food_drinks',
      tags: const ['apple'],
      assetPath: File('assets/exercise_images/apple.webp').absolute.path,
      origin: 'bank:bank_1',
      attribution: const ImageAttribution(
        author: 'A. Artist',
        license: 'CC BY 4.0',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FlatImageLibraryScreen(
          selectMode: false,
          readOnly: true,
          metadataService: _Catalog([item, missing, bank]),
          bankService: _Banks(),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const ValueKey('exercise-image-apple'))
          .evaluate()
          .isNotEmpty,
    );
    expect(
      find.byKey(const Key('image-preview-details-tooltip')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('exercise-image-apple')));
    await tester.pumpUntilFileIoState(
      () => _tooltipContains(tester, 'File: apple.webp'),
    );
    final tooltip = tester.widget<Tooltip>(
      find.byKey(const Key('image-preview-details-tooltip')),
    );
    expect(tooltip.message, contains('File: apple.webp'));
    expect(tooltip.message, contains('Dimensions:'));
    expect(tooltip.message, contains('Included with QQL'));
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('image-preview-details-tooltip'))),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('File: apple.webp'), findsWidgets);
    await mouse.removePointer();
    await tester.longPress(
      find.byKey(const Key('image-preview-details-tooltip')),
    );
    await tester.pump();
    expect(find.textContaining('File: apple.webp'), findsWidgets);
    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-image-missing')));
    await tester.pumpUntilFileIoState(
      () => _tooltipContains(tester, 'File missing'),
    );
    expect(
      tester
          .widget<Tooltip>(
            find.byKey(const Key('image-preview-details-tooltip')),
          )
          .message,
      'File missing',
    );
    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-image-bank-apple')));
    await tester.pumpUntilFileIoState(
      () => _tooltipContains(tester, 'Bank: Fruit pictures'),
    );
    final bankDetails = tester
        .widget<Tooltip>(find.byKey(const Key('image-preview-details-tooltip')))
        .message!;
    expect(bankDetails, contains('Author: A. Artist'));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Course Image Library previews a content-named file', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final media = _CourseMedia();
    final base = Course.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
    final reference = 'media:${'a' * 64}.webp';
    final course = Course.fromJson({...base.toJson(), 'coverImage': reference});
    final item = ExerciseImageMetadata(
      id: 'course-image',
      label: 'Course image',
      category: 'other',
      tags: const [],
      assetPath: reference,
      origin: 'course',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FlatImageLibraryScreen(
          course: course,
          mediaStore: media,
          selectMode: false,
          readOnly: true,
          metadataService: _Catalog([item]),
        ),
      ),
    );
    final tile = find.byKey(const ValueKey('exercise-image-course-image'));
    await tester.pumpUntilFileIoState(() => tile.evaluate().isNotEmpty);
    await tester.tap(tile);
    await tester.pumpUntilFileIoState(
      () => _tooltipContains(tester, 'File: Course file (named by content)'),
    );
    final details = tester
        .widget<Tooltip>(find.byKey(const Key('image-preview-details-tooltip')))
        .message!;
    expect(details, contains('File: Course file (named by content)'));
    expect(details, contains('Format: WebP'));
    expect(details, contains('Dimensions:'));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
