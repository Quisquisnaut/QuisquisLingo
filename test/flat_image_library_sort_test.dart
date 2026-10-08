import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';

class _Catalog extends ExerciseImageMetadataService {
  _Catalog(this.records);
  final List<ExerciseImageMetadata> records;

  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => records;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _adminId,
          displayName: 'Admin',
        ).encode(),
      ],
      ProfileService.adminProfileIdsKey: [_adminId],
    });
  });

  testWidgets('Image Library sorts by name, date added and file size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final temp = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_library_sort_'),
    ))!;
    addTearDown(() => temp.delete(recursive: true));
    final apple = (await tester.runAsync(
      () => File('assets/exercise_images/apple.webp').readAsBytes(),
    ))!;
    Future<String> write(String name, int bytes) async {
      final file = File('${temp.path}${Platform.pathSeparator}$name');
      await tester.runAsync(
        () => file.writeAsBytes(List<int>.filled(bytes, 1)),
      );
      return file.path;
    }

    // Cat is the older import and the larger file; Zebra the newer and smaller.
    final records = [
      const ExerciseImageMetadata(
        id: 'apple',
        label: 'Apple',
        category: 'food_drinks',
        tags: ['apple'],
        assetPath: 'assets/exercise_images/apple.webp',
        origin: 'bundled',
      ),
      ExerciseImageMetadata(
        id: 'local_1000000000000000',
        label: 'Zebra',
        category: 'animals',
        tags: const ['zebra'],
        assetPath: await write('zebra.webp', 10),
        origin: 'local',
      ),
      ExerciseImageMetadata(
        id: 'local_900000000000000',
        label: 'Cat',
        category: 'animals',
        tags: const ['cat'],
        assetPath: await write('cat.webp', apple.length + 10),
        origin: 'local',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: FlatImageLibraryScreen(
          selectMode: false,
          metadataEditingEnabled: true,
          actorProfileId: _adminId,
          metadataService: _Catalog(records),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('exercise-image-grid')).evaluate().isNotEmpty,
    );

    List<String> order() {
      final ids = records.map((record) => record.id).toList();
      double x(String id) =>
          tester.getTopLeft(find.byKey(ValueKey('exercise-image-$id'))).dx;
      ids.sort((a, b) => x(a).compareTo(x(b)));
      return ids;
    }

    Future<void> sortBy(String name) async {
      await tester.tap(find.byKey(const Key('exercise-image-sort')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('exercise-image-sort-$name')));
      await tester.pumpAndSettle();
    }

    const cat = 'local_900000000000000';
    const zebra = 'local_1000000000000000';
    expect(order(), ['apple', cat, zebra]);
    await sortBy('newest');
    expect(order(), [zebra, cat, 'apple']);
    await sortBy('oldest');
    expect(order(), ['apple', cat, zebra]);
    await sortBy('largest');
    await tester.pumpUntilFileIoState(() => order().first == cat);
    expect(order(), [cat, 'apple', zebra]);
    await sortBy('smallest');
    expect(order(), [zebra, 'apple', cat]);

    // The delete control sits inside the image area, not in a row below it.
    final tile = find.byKey(ValueKey('exercise-image-$zebra'));
    final button = find.descendant(
      of: tile,
      matching: find.byTooltip('Delete imported image'),
    );
    final label = find.descendant(of: tile, matching: find.text('zebra'));
    expect(
      tester.getBottomRight(button).dy,
      lessThanOrEqualTo(tester.getTopLeft(label).dy),
    );
    expect(find.byTooltip('Delete imported image'), findsNWidgets(2));
    // So do the badges, on the left and at the image's bottom edge.
    final badge = find.descendant(of: tile, matching: find.text('DEVICE'));
    expect(
      tester.getBottomLeft(badge).dy,
      lessThanOrEqualTo(tester.getTopLeft(label).dy),
    );
    expect(tester.getTopLeft(badge).dx, lessThan(tester.getTopLeft(button).dx));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
