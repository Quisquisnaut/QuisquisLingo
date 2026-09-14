import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';
const _learnerId = '22222222-2222-4222-8222-222222222222';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'non-Admin and ordinary Course Editor views have no edit control',
    (tester) async {
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
        ProfileService.adminProfileIdsKey: [_adminId],
      });
      await tester.pumpWidget(
        const MaterialApp(
          home: FlatImageLibraryScreen(
            selectMode: false,
            metadataEditingEnabled: true,
            actorProfileId: _learnerId,
          ),
        ),
      );
      await tester.pumpAndSettle();
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
      await tester.pump();

      expect(
        find.byKey(const Key('exercise-image-metadata-edit')),
        findsNothing,
      );
      expect(find.byTooltip('Import'), findsNothing);
      expect(find.text('Import bank'), findsNothing);
    },
  );
}
