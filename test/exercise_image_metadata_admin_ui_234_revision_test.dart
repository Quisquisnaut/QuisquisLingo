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

  testWidgets('Admin edits global category and tags from media management', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 800);
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

    expect(find.text('Admin media management'), findsOneWidget);
    expect(
      find.text('Categories and tags must be written in English.'),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'friend',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('exercise-image-people_family_man')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(
      find.byKey(const Key('exercise-image-metadata-edit')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('exercise-image-metadata-edit')));
    await tester.pumpAndSettle();
    expect(
      find.text('Categories and tags must be written in English.'),
      findsNothing,
    );
    await tester.enterText(
      find.byKey(const Key('exercise-image-tags-editor')),
      'man, friend, colleague',
    );
    await tester.tap(find.byKey(const Key('exercise-image-metadata-save')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'colleague',
    );
    await tester.pump();
    expect(find.text('Man'), findsOneWidget);
    expect(
      (await ExerciseImageMetadataService().metadataFor(
        'people_family_man',
      )).tags,
      ['man', 'friend', 'colleague'],
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
