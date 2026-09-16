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
const _reducedMotionLearnerId = '00000000-0000-4000-8000-000000000903';

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
      expect(find.text('QuisquisLingo Beta testing'), findsNothing);
      expect(find.text('Welcome to QuisquisLingo'), findsNothing);
      expect(find.text('Beta expiry'), findsNothing);
      expect(find.byKey(const Key('qql-startup-animation')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('new-learner-screen-name')),
        'First Learner',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Avatar Customization'), findsOneWidget);
      expect(find.text('QuisquisLingo'), findsNothing);
      expect(find.text('QuisquisLingo Beta testing'), findsNothing);

      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Done'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await _pumpUntil(tester, find.byKey(const Key('qql-startup-animation')));

      final startup = find.byKey(const Key('qql-startup-animation'));
      final startupLogo = find.descendant(
        of: startup,
        matching: find.byKey(const Key('qql-startup-logo')),
      );
      expect(startup, findsOneWidget);
      expect(startupLogo, findsOneWidget);
      final logo = tester.widget<Image>(startupLogo);
      expect(
        (logo.image as AssetImage).assetName,
        'assets/branding/qql_logo_4.png',
      );
      expect(
        find.image(const AssetImage('assets/olive_tree.png')),
        findsNothing,
      );
      expect(
        find.descendant(of: startup, matching: find.byType(Image)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: startup, matching: find.byType(Text)),
        findsNothing,
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      final fade = tester.widget<FadeTransition>(
        find.byKey(const Key('qql-startup-logo-fade')),
      );
      final scale = tester.widget<ScaleTransition>(
        find.byKey(const Key('qql-startup-logo-scale')),
      );
      expect(fade.opacity.value, 0);
      expect(scale.scale.value, closeTo(.60, .001));
      await tester.pump(const Duration(milliseconds: 600));
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));
      expect(scale.scale.value, greaterThan(.60));
      expect(scale.scale.value, lessThan(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(fade.opacity.value, 1);
      expect(scale.scale.value, 1);
      await tester.pump(const Duration(milliseconds: 799));
      expect(fade.opacity.value, 1);
      expect(scale.scale.value, 1);
      expect(startup, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      await _pumpUntil(tester, find.text('QuisquisLingo Beta testing'));

      expect(find.text('Create Profile'), findsNothing);
      expect(find.text('QuisquisLingo'), findsNothing);
      expect(find.text('QuisquisLingo Beta testing'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('QuisquisLingo Beta testing'), findsOneWidget);
      expect(await profiles.getProfileRecords(), hasLength(1));

      await tester.tap(find.widgetWithText(FilledButton, 'Start testing'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('QuisquisLingo Beta testing'), findsNothing);
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
      final startup = find.byKey(const Key('qql-startup-animation'));
      await _pumpUntil(tester, startup);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();

      expect(
        tester
            .widget<FadeTransition>(
              find.byKey(const Key('qql-startup-logo-fade')),
            )
            .opacity
            .value,
        1,
      );
      expect(
        tester
            .widget<ScaleTransition>(
              find.byKey(const Key('qql-startup-logo-scale')),
            )
            .scale
            .value,
        1,
      );
      await tester.pump(const Duration(milliseconds: 1799));
      expect(startup, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2));
      await _pumpUntil(tester, find.text('QuisquisLingo Beta testing'));

      expect(find.text('Create Profile'), findsNothing);
      expect(find.text('QuisquisLingo Beta testing'), findsOneWidget);
    },
  );

  testWidgets(
    'reduced motion keeps the final logo static for the full startup gate',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final profiles = ProfileService(
        idGenerator: () => _reducedMotionLearnerId,
        numericSuffixGenerator: () => 67890,
        randomIndex: (_) => 0,
      );
      await profiles.createProfile('Reduced Motion Learner');
      await SettingsService().setAnimationsEnabled(true);

      await tester.pumpWidget(QuisquisLingoApp(profileService: profiles));
      final startup = find.byKey(const Key('qql-startup-animation'));
      await _pumpUntil(tester, startup);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();

      expect(find.byKey(const Key('qql-startup-logo')), findsOneWidget);
      expect(
        tester
            .widget<FadeTransition>(
              find.byKey(const Key('qql-startup-logo-fade')),
            )
            .opacity
            .value,
        1,
      );
      expect(
        tester
            .widget<ScaleTransition>(
              find.byKey(const Key('qql-startup-logo-scale')),
            )
            .scale
            .value,
        1,
      );
      await tester.pump(const Duration(milliseconds: 1799));
      expect(startup, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2));
      expect(startup, findsNothing);
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
    expect(find.text('QuisquisLingo Beta testing'), findsNothing);
    expect(find.byKey(const Key('qql-startup-animation')), findsNothing);
    final attemptsBeforeRetry = profiles.readAttempts;
    expect(attemptsBeforeRetry, greaterThanOrEqualTo(1));

    await tester.tap(find.byKey(const Key('startup-profile-retry')));
    await _pumpUntil(tester, find.byKey(const Key('qql-startup-animation')));
    await _finishStartupGate(tester);
    await _pumpUntilAny(tester, [
      find.text('QuisquisLingo Beta testing'),
      find.text('Welcome to QuisquisLingo'),
    ]);

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
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for $finder. Visible text: $visibleText');
}

Future<void> _finishStartupGate(WidgetTester tester) async {
  final startup = find.byKey(const Key('qql-startup-animation'));
  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (startup.evaluate().isEmpty) return;
  }
  fail('Timed out waiting for the startup gate to finish.');
}

Future<void> _pumpUntilAny(WidgetTester tester, List<Finder> finders) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (finders.any((finder) => finder.evaluate().isNotEmpty)) return;
  }
  fail('Timed out waiting for any normal startup notice.');
}
