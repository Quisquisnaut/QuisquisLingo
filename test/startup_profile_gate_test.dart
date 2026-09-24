import 'dart:async';
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
      // The image-ready animation test below owns its frame timing. First-run
      // profile creation waits for that asynchronous animation to finish.
      await _finishStartupGate(tester);
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

  testWidgets('logo grows throughout its entrance after its image is ready', (
    tester,
  ) async {
    final profiles = ProfileService(
      idGenerator: () => _existingLearnerId,
      numericSuffixGenerator: () => 54321,
      randomIndex: (_) => 0,
    );
    await profiles.createProfile('Existing Learner');
    await SettingsService().setAnimationsEnabled(true);
    final releaseLogo = Completer<void>();
    final bundle = _DelayedLogoBundle(releaseLogo.future);

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: bundle,
        child: QuisquisLingoApp(profileService: profiles),
      ),
    );
    await _pumpUntil(tester, find.byKey(const Key('qql-startup-animation')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();

    double scale() => tester
        .widget<ScaleTransition>(
          find.byKey(const Key('qql-startup-logo-scale')),
        )
        .scale
        .value;
    double opacity() => tester
        .widget<FadeTransition>(find.byKey(const Key('qql-startup-logo-fade')))
        .opacity
        .value;
    double frameScale() => tester
        .widget<Transform>(
          find.descendant(
            of: find.byKey(const Key('qql-startup-logo-scale')),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .storage[0];

    final initialScale = scale();
    await tester.pump(const Duration(milliseconds: 600));
    expect(scale(), closeTo(initialScale, .001));
    expect(opacity(), 0);

    releaseLogo.complete();
    for (var attempt = 0; attempt < 100 && scale() == initialScale; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(scale(), greaterThan(initialScale));
    expect(scale(), lessThan(initialScale + .04));
    await tester.pump(const Duration(milliseconds: 375));
    expect(scale(), closeTo(.475, .03));
    expect(frameScale(), closeTo(.475, .03));
    expect(opacity(), 1);
    await tester.pump(const Duration(milliseconds: 750));
    expect(scale(), closeTo(.825, .03));
    expect(frameScale(), closeTo(.825, .03));
    expect(opacity(), 1);
  });

  testWidgets('Beta testing acknowledgement is shown only once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'startup_animation_enabled': false,
      'automatic_update_check_enabled': false,
      'one_time_notice_seen_beta_testing': true,
    });
    final profiles = ProfileService(
      idGenerator: () => _existingLearnerId,
      numericSuffixGenerator: () => 54321,
      randomIndex: (_) => 0,
    );
    await profiles.createProfile('Existing Learner');

    await tester.pumpWidget(QuisquisLingoApp(profileService: profiles));
    await _pumpUntil(tester, find.byKey(const Key('qql-startup-animation')));
    await _finishStartupGate(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('QuisquisLingo Beta testing'), findsNothing);
  });

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

class _DelayedLogoBundle extends CachingAssetBundle {
  _DelayedLogoBundle(this.logoReady);

  final Future<void> logoReady;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/branding/qql_logo_4.png') await logoReady;
    return rootBundle.load(key);
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
