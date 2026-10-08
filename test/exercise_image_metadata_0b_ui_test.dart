import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';

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

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: FlatImageLibraryScreen(
          selectMode: false,
          metadataEditingEnabled: true,
          actorProfileId: _adminId,
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (
      var attempt = 0;
      attempt < 20 &&
          find.byKey(const Key('exercise-image-search')).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // Build 264 Revision 2: no category can be added; one added before can
  // be removed, and only then does the menu offer it.
  testWidgets('no device category can be created from the menu', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byTooltip('Import'));
    await tester.pumpAndSettle();
    expect(find.text('Manage device categories'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a device category from before can only be removed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _adminId,
          displayName: 'Admin',
        ).encode(),
      ],
      ProfileService.adminProfileIdsKey: [_adminId],
      ExerciseImageMetadataService.preferencesKey: jsonEncode({
        'schemaVersion': 2,
        'records': [],
        'deviceCategories': ['musical_instruments'],
      }),
    });
    await open(tester);
    await tester.tap(find.byTooltip('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage device categories'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('device-category-musical_instruments')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('device-category-add')), findsNothing);
    expect(find.byTooltip('Rename'), findsNothing);
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('No device categories yet.'), findsOneWidget);
    expect(await ExerciseImageMetadataService().deviceCategories(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a QQL image offers Local words, not tag editing', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'people_family_man',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('exercise-image-people_family_man')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Local words'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exercise-image-metadata-edit')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('exercise-image-local-editor')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('exercise-image-tags-editor')), findsNothing);
    expect(find.byKey(const Key('exercise-image-new-category')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
