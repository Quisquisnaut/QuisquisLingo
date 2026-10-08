import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/course_image_usage.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/widgets/course_media_image.dart';

import 'support/pump_file_io.dart';

class _Catalog extends ExerciseImageMetadataService {
  _Catalog(this.records);
  final List<ExerciseImageMetadata> records;

  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => records;
}

const _apple = 'assets/exercise_images/apple.webp';
const _banana = 'assets/exercise_images/banana.webp';

const _records = [
  ExerciseImageMetadata(
    id: 'apple',
    label: 'Apple',
    category: 'food_drinks',
    tags: ['apple'],
    assetPath: _apple,
    origin: 'bundled',
  ),
  ExerciseImageMetadata(
    id: 'banana',
    label: 'Banana',
    category: 'food_drinks',
    tags: ['banana'],
    assetPath: _banana,
    origin: 'bundled',
  ),
];

/// The demo Course with the apple as a clue image; the banana is unused.
Course _course() {
  final json =
      jsonDecode(
            File(
              'demo_courses/italian_demo_2_pick_the_translation.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final content =
      (((json['lessons'] as List).first as Map)['rounds'] as List)
              .first['content']
          as List;
  ((content.first as Map)['exercise']['prompt'] as List).add({
    'role': 'clue',
    'type': 'image',
    'asset': _apple,
  });
  return Course.fromJson(json);
}

Finder _inGrid(String text) => find.descendant(
  of: find.byKey(const Key('exercise-image-grid')),
  matching: find.text(text),
);

void main() {
  Future<List<Course>> pump(
    WidgetTester tester, {
    required bool editable,
  }) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final changes = <Course>[];
    await tester.pumpWidget(
      MaterialApp(
        home: FlatImageLibraryScreen(
          selectMode: false,
          readOnly: true,
          course: _course(),
          mediaStore: CourseMediaStore(
            supportDirectory: () async => Directory.systemTemp,
          ),
          metadataService: _Catalog(_records),
          onCourseChanged: editable ? changes.add : null,
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('exercise-image-grid')).evaluate().isNotEmpty,
    );
    return changes;
  }

  testWidgets('IN USE is listed above the source badge', (tester) async {
    await pump(tester, editable: false);
    final tile = find.byKey(const ValueKey('exercise-image-apple'));
    final inUse = find.descendant(of: tile, matching: find.text('IN USE'));
    final qql = find.descendant(of: tile, matching: find.text('QQL'));
    expect(tester.getTopLeft(inUse).dy, lessThan(tester.getTopLeft(qql).dy));
  });

  testWidgets('without Course editing there is no removal', (tester) async {
    await pump(tester, editable: false);
    expect(find.byTooltip('Remove from this Course'), findsNothing);
  });

  testWidgets('removing a used image lists its uses and changes the Course', (
    tester,
  ) async {
    final changes = await pump(tester, editable: true);
    // Only the used image offers removal.
    expect(find.byTooltip('Remove from this Course'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('exercise-image-banana')),
        matching: find.byTooltip('Remove from this Course'),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Remove from this Course'));
    await tester.pumpAndSettle();
    expect(find.text('Remove from this Course?'), findsOneWidget);
    expect(find.textContaining('Used in '), findsOneWidget);
    expect(find.textContaining('• Lesson 1 › '), findsWidgets);
    expect(
      find.textContaining('The QQL image stays available in the library.'),
      findsOneWidget,
    );

    // Cancel changes nothing.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);

    await tester.tap(find.byTooltip('Remove from this Course'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-image-remove-confirm')));
    await tester.pumpUntilFileIoState(() => changes.isNotEmpty);
    await tester.pumpUntilFileIoState(
      () => _inGrid('IN USE').evaluate().isEmpty,
    );

    expect(changes, hasLength(1));
    expect(
      CourseImageUsage.usedAssets(changes.single),
      isNot(contains(_apple)),
    );
    // The QQL image stays in the library, no longer in use.
    expect(_inGrid('apple'), findsOneWidget);
    expect(_inGrid('IN USE'), findsNothing);
    expect(find.byTooltip('Remove from this Course'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('Course-stored images', () {
    late Directory temp;
    late CourseMediaStore media;
    late String reference;

    Future<Course> setUpCourse(
      WidgetTester tester, {
      required bool used,
      bool listed = false,
    }) async {
      temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('qql_course_image_removal_'),
      ))!;
      addTearDown(() async {
        try {
          await temp.delete(recursive: true);
        } catch (_) {}
      });
      media = CourseMediaStore(supportDirectory: () async => temp);
      final json =
          jsonDecode(
                File(
                  'demo_courses/italian_demo_2_pick_the_translation.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final bytes = (await tester.runAsync(() => File(_apple).readAsBytes()))!;
      reference = (await tester.runAsync(
        () => media.addBytes(json['courseId'] as String, bytes, 'webp'),
      ))!;
      if (used) {
        final content =
            (((json['lessons'] as List).first as Map)['rounds'] as List)
                    .first['content']
                as List;
        ((content.first as Map)['exercise']['prompt'] as List).add({
          'role': 'clue',
          'type': 'image',
          'asset': reference,
        });
      }
      if (listed) {
        json['imageLibrary'] = [
          {'asset': reference},
        ];
      }
      return Course.fromJson(json);
    }

    Future<List<Course>> show(WidgetTester tester, Course course) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final changes = <Course>[];
      await tester.pumpWidget(
        MaterialApp(
          home: FlatImageLibraryScreen(
            selectMode: false,
            readOnly: true,
            course: course,
            savedCourse: course,
            mediaStore: media,
            metadataService: _Catalog(const []),
            onCourseChanged: changes.add,
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => _inGrid('COURSE').evaluate().isNotEmpty,
      );
      // Let the preview finish reading its file: Windows cannot delete a file
      // that is still open.
      await tester.pumpUntilFileIoState(
        () => find
            .descendant(
              of: find.byType(CourseMediaImage),
              matching: find.byType(Image),
            )
            .evaluate()
            .isNotEmpty,
      );
      return changes;
    }

    Future<void> tapBin(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Remove from this Course'));
      await tester.pumpAndSettle();
    }

    testWidgets('after its uses are removed it can stay in the library', (
      tester,
    ) async {
      final changes = await show(tester, await setUpCourse(tester, used: true));
      expect(_inGrid('IN USE'), findsOneWidget);
      await tapBin(tester);
      await tester.tap(find.byKey(const Key('exercise-image-remove-confirm')));
      await tester.pumpAndSettle();
      expect(
        find.text("Also remove it from this Course's library?"),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('exercise-image-keep-in-library')));
      await tester.pumpUntilFileIoState(() => changes.isNotEmpty);
      final changed = changes.single;
      expect(CourseImageUsage.usedAssets(changed), isNot(contains(reference)));
      expect(changed.imageLibrary.single.asset, reference);
      await tester.pumpUntilFileIoState(
        () => _inGrid('IN USE').evaluate().isEmpty,
      );
      // Still in the Course, unused, and still removable.
      expect(_inGrid('COURSE'), findsOneWidget);
      expect(find.byTooltip('Remove from this Course'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('an unused library image leaves at the confirmed save', (
      tester,
    ) async {
      final course = await setUpCourse(tester, used: false, listed: true);
      final changes = await show(tester, course);
      await tapBin(tester);
      expect(
        find.text("Remove it from this Course's library?"),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('exercise-image-remove-from-library')),
      );
      await tester.pumpUntilFileIoState(() => changes.isNotEmpty);
      expect(changes.single.imageLibrary, isEmpty);
      // The saved Course still lists it, so Discard must be able to bring it
      // back: the file stays until the confirmed save.
      expect(
        await tester.runAsync(
          () => media.existingFile(course.courseId, reference),
        ),
        isNotNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a leftover file nothing uses is deleted at once', (
      tester,
    ) async {
      final course = await setUpCourse(tester, used: false);
      final changes = await show(tester, course);
      await tapBin(tester);
      await tester.tap(
        find.byKey(const Key('exercise-image-remove-from-library')),
      );
      await tester.pumpUntilFileIoState(
        () => _inGrid('COURSE').evaluate().isEmpty,
      );
      expect(changes, isEmpty);
      expect(
        await tester.runAsync(
          () => media.existingFile(course.courseId, reference),
        ),
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
