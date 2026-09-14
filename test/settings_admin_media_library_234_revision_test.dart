import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';
const _learnerId = '22222222-2222-4222-8222-222222222222';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings exposes global media editing only to an Admin', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _adminId,
          displayName: 'Admin',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _adminId,
      ProfileService.adminProfileIdsKey: [_adminId],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: _course, onManageLearners: (_) async {}),
      ),
    );
    await _pumpFrames(tester);
    expect(
      find.byKey(const Key('settings-admin-media-library')),
      findsOneWidget,
    );

    final adminMedia = find.byKey(const Key('settings-admin-media-library'));
    await tester.ensureVisible(adminMedia);
    await tester.tap(adminMedia);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FlatImageLibraryScreen), findsOneWidget);
    final library = tester.widget<FlatImageLibraryScreen>(
      find.byType(FlatImageLibraryScreen),
    );
    expect(library.metadataEditingEnabled, isTrue);
    expect(library.actorProfileId, _adminId);
  });

  testWidgets('Settings hides global media editing from a non-Admin', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _adminId,
          displayName: 'Admin',
        ).encode(),
        const LearnerProfile(
          learnerProfileId: _learnerId,
          displayName: 'Learner',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _learnerId,
      ProfileService.adminProfileIdsKey: [_adminId],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: _course, onManageLearners: (_) async {}),
      ),
    );
    await _pumpFrames(tester);
    expect(find.byKey(const Key('settings-admin-media-library')), findsNothing);
  });
}

final _course = Course(
  courseId: 'qql-234-metadata-settings-course',
  learningLanguage: 'Japanese',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Japanese',
  targetLanguageTag: 'ja-JP',
  title: 'QQL 234 Metadata Settings Course',
  ttsLanguage: 'ja-JP',
  lessons: const [],
);

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
