import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/do_not_disturb_settings_screen.dart';
import 'package:quisquislingo_app/screens/update_settings_screen.dart';
import 'package:quisquislingo_app/services/update_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Show one-time notices again is an action, not a switch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'one_time_notice_seen_welcome': true,
      'one_time_notice_seen_audio_help': true,
    });

    await tester.pumpWidget(
      const MaterialApp(home: DoNotDisturbSettingsScreen()),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(SwitchListTile, 'Show one-time notices again'),
      findsNothing,
    );
    expect(
      find.widgetWithText(ListTile, 'Show one-time notices again'),
      findsOneWidget,
    );

    await tester.tap(find.text('Show one-time notices again'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().where(
        (key) => key.startsWith('one_time_notice_seen_'),
      ),
      isEmpty,
    );
    expect(
      find.text('One-time notices will be shown again when relevant.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'missing GitHub Release distinguishes the published source repository',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: UpdateSettingsScreen(
            updateService: _NoPackagedReleaseUpdateService(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Check for updates'));
      await tester.pumpAndSettle();

      expect(find.text('No published release'), findsNothing);
      expect(find.text('No packaged GitHub release'), findsOneWidget);
      expect(
        find.text(
          'The QuisquisLingo source repository is published, but no packaged application release is currently available in GitHub Releases.',
        ),
        findsOneWidget,
      );
      expect(find.text(UpdateService.repositoryUrl), findsOneWidget);
    },
  );

  test(
    'Welcome Wizard completion is per learner and reset with notices',
    () async {
      SharedPreferences.setMockInitialValues({});
      final profiles = ProfileService();
      await profiles.createProfile(
        'Wizard Learner',
        learnerProfileId: '11111111-1111-4111-8111-111111111111',
      );
      final settings = SettingsService();

      expect(await settings.hasCompletedWelcomeWizard(), isFalse);
      await settings.completeWelcomeWizard();
      expect(await settings.hasCompletedWelcomeWizard(), isTrue);
      await settings.markOneTimeNoticeSeen('beta_testing');
      expect(await settings.hasSeenOneTimeNotice('beta_testing'), isTrue);

      await profiles.createProfile(
        'Other Learner',
        learnerProfileId: '22222222-2222-4222-8222-222222222222',
      );
      expect(await settings.hasCompletedWelcomeWizard(), isFalse);
      await profiles.setActiveProfileById(
        '11111111-1111-4111-8111-111111111111',
      );

      await settings.resetOneTimeNotices();
      expect(await settings.hasCompletedWelcomeWizard(), isFalse);
      expect(await settings.hasSeenOneTimeNotice('beta_testing'), isFalse);
    },
  );
}

class _NoPackagedReleaseUpdateService extends UpdateService {
  @override
  Future<UpdateCheckResult> check(String currentVersion) async =>
      const UpdateCheckResult(UpdateCheckStatus.noPublishedRelease);
}
