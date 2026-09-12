import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/main.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _firstLearnerId = '00000000-0000-4000-8000-000000000901';
const _existingLearnerId = '00000000-0000-4000-8000-000000000902';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUpAll(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'qql_startup_profile_gate_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => documentsDirectory.path,
        );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await documentsDirectory.delete(recursive: true);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'startup_animation_enabled': false,
      'automatic_update_check_enabled': false,
    });
  });

  testWidgets(
    'zero-user startup opens mandatory profile creation before startup UI',
    (tester) async {
      final profiles = ProfileService(
        idGenerator: () => _firstLearnerId,
        numericSuffixGenerator: () => 12345,
        randomIndex: (_) => 0,
      );
      await SettingsService().setAnimationsEnabled(true);

      await tester.pumpWidget(QuisquisLingoApp(profileService: profiles));
      await _pumpUntil(tester, find.text('Create Profile'));

      expect(find.text('Create Profile'), findsWidgets);
      expect(find.text('QuisquisLingo'), findsNothing);
      expect(find.text('QuisquisLingo Alpha testing'), findsNothing);
      expect(find.text('Welcome to QuisquisLingo'), findsNothing);
      expect(find.text('Alpha expiry'), findsNothing);
      expect(find.byKey(const Key('qql-startup-animation')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('new-learner-screen-name')),
        'First Learner',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Avatar Customization'), findsOneWidget);
      expect(find.text('QuisquisLingo'), findsNothing);
      expect(find.text('QuisquisLingo Alpha testing'), findsNothing);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Done'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await _pumpUntil(tester, find.byKey(const Key('qql-startup-animation')));

      expect(find.byKey(const Key('qql-startup-animation')), findsOneWidget);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1801));
      await tester.pump();
      await _pumpUntil(tester, find.text('QuisquisLingo Alpha testing'));

      expect(find.text('Create Profile'), findsNothing);
      expect(find.text('QuisquisLingo'), findsNothing);
      expect(find.text('QuisquisLingo Alpha testing'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('QuisquisLingo Alpha testing'), findsOneWidget);
      expect(await profiles.getProfileRecords(), hasLength(1));

      await tester.tap(find.widgetWithText(FilledButton, 'Start testing'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('QuisquisLingo Alpha testing'), findsNothing);
      expect(find.byKey(const Key('qql-startup-animation')), findsNothing);
    },
  );

  testWidgets(
    'existing-user startup enters the normal startup path without profile creation',
    (tester) async {
      final profiles = ProfileService(
        idGenerator: () => _existingLearnerId,
        numericSuffixGenerator: () => 54321,
        randomIndex: (_) => 0,
      );
      await profiles.createProfile('Existing Learner');

      await tester.pumpWidget(QuisquisLingoApp(profileService: profiles));
      await _pumpUntil(tester, find.text('QuisquisLingo Alpha testing'));

      expect(find.text('Create Profile'), findsNothing);
      expect(find.text('QuisquisLingo Alpha testing'), findsOneWidget);
    },
  );

  testWidgets('profile-read failure blocks normal startup and can be retried', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'startup_animation_enabled': false,
      'automatic_update_check_enabled': false,
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _existingLearnerId,
          displayName: 'Existing Learner 54321',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _existingLearnerId,
    });
    final profiles = _RetryingProfileService();

    await tester.pumpWidget(QuisquisLingoApp(profileService: profiles));
    await _pumpUntil(tester, find.text('Unable to load learner profiles.'));

    expect(find.text('Create Profile'), findsNothing);
    expect(find.text('QuisquisLingo Alpha testing'), findsNothing);
    expect(find.byKey(const Key('qql-startup-animation')), findsNothing);
    final attemptsBeforeRetry = profiles.readAttempts;
    expect(attemptsBeforeRetry, greaterThanOrEqualTo(1));

    await tester.tap(find.byKey(const Key('startup-profile-retry')));
    await _pumpUntil(tester, find.text('QuisquisLingo Alpha testing'));

    expect(profiles.readAttempts, greaterThan(attemptsBeforeRetry));
    expect(find.text('Create Profile'), findsNothing);
    expect(find.text('Unable to load learner profiles.'), findsNothing);
  });
}

class _RetryingProfileService extends ProfileService {
  int readAttempts = 0;

  @override
  Future<List<LearnerProfile>> getProfileRecords() async {
    readAttempts += 1;
    if (readAttempts == 1) {
      throw StateError('simulated profile read failure');
    }
    return super.getProfileRecords();
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder.');
}
