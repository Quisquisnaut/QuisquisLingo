import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/controllers/learner_status_controller.dart';
import 'package:quisquislingo_app/main.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/avatar_settings_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/gamification_settings_screen.dart';
import 'package:quisquislingo_app/screens/profile_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/learner_avatar.dart';
import 'package:quisquislingo_app/widgets/learner_bottom_actions.dart';
import 'package:quisquislingo_app/widgets/learner_theme_mode_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('local logout clears only the active learner reference', () async {
    final profiles = ProfileService();
    await profiles.addProfile(
      'Stored Learner',
      skinTone: 'light',
      hairTone: 'light',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('learner_Stored%20Learner_xp_IT', 275);
    await prefs.setStringList('learner_Stored%20Learner_completed_rounds_v4', [
      'round-1',
    ]);
    final beforeKeys = prefs.getKeys().where((key) => key != 'active_learner');
    final beforeValues = {for (final key in beforeKeys) key: prefs.get(key)};

    await profiles.clearActiveProfile();

    final statusController = LearnerStatusController(
      profileService: profiles,
      observeLifecycle: false,
    );
    await statusController.refresh();
    statusController.dispose();

    expect(await profiles.getActiveProfile(), isNull);
    expect(await profiles.getProfiles(), ['Stored Learner']);
    expect(prefs.containsKey('active_learner'), isFalse);
    expect(prefs.getKeys(), beforeValues.keys.toSet());
    expect({
      for (final key in beforeValues.keys) key: prefs.get(key),
    }, beforeValues);

    await profiles.setActiveProfile('Stored Learner');
    expect(await profiles.getActiveProfile(), 'Stored Learner');
    expect(await profiles.getSkinTone(), 'light');
    expect(await profiles.getHairTone(), 'light');
    expect(prefs.getInt('learner_Stored%20Learner_xp_IT'), 275);
  });

  test(
    'theme modes are learner-scoped and survive logout and service restart',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Learner A');
      expect(await profiles.getThemeMode(), LearnerThemeMode.defaultMode);
      await profiles.setThemeMode(LearnerThemeMode.dark);

      await profiles.addProfile('Learner B');
      await profiles.setThemeMode(LearnerThemeMode.light);
      expect(await profiles.getThemeMode(), LearnerThemeMode.light);

      await profiles.setActiveProfile('Learner A');
      expect(await profiles.getThemeMode(), LearnerThemeMode.dark);
      await profiles.clearActiveProfile();
      expect(await profiles.getThemeMode(), LearnerThemeMode.defaultMode);
      await profiles.setThemeMode(LearnerThemeMode.dark);
      expect(await profiles.getThemeMode(), LearnerThemeMode.defaultMode);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('learner_default_theme_mode'), isFalse);
      expect(prefs.getString('learner_Learner%20A_theme_mode'), 'dark');
      expect(prefs.getString('learner_Learner%20B_theme_mode'), 'light');

      final restartedProfiles = ProfileService();
      await restartedProfiles.setActiveProfile('Learner A');
      expect(await restartedProfiles.getThemeMode(), LearnerThemeMode.dark);
      await restartedProfiles.setActiveProfile('Learner B');
      expect(await restartedProfiles.getThemeMode(), LearnerThemeMode.light);
    },
  );

  test(
    'flag background modes are learner-scoped and survive service restart',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Learner A');
      expect(
        await profiles.getFlagBackgroundMode(),
        LearnerFlagBackgroundMode.small,
      );
      await profiles.setFlagBackgroundMode(LearnerFlagBackgroundMode.off);

      await profiles.addProfile('Learner B');
      await profiles.setFlagBackgroundMode(LearnerFlagBackgroundMode.extended);
      expect(
        await profiles.getFlagBackgroundMode(),
        LearnerFlagBackgroundMode.extended,
      );

      await profiles.setActiveProfile('Learner A');
      expect(
        await profiles.getFlagBackgroundMode(),
        LearnerFlagBackgroundMode.off,
      );
      await profiles.clearActiveProfile();
      expect(
        await profiles.getFlagBackgroundMode(),
        LearnerFlagBackgroundMode.small,
      );
      await profiles.setFlagBackgroundMode(LearnerFlagBackgroundMode.extended);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.containsKey('learner_default_flag_background_mode'),
        isFalse,
      );
      expect(
        prefs.getString('learner_Learner%20A_flag_background_mode'),
        'off',
      );
      expect(
        prefs.getString('learner_Learner%20B_flag_background_mode'),
        'extended',
      );

      final restartedProfiles = ProfileService();
      await restartedProfiles.setActiveProfile('Learner B');
      expect(
        await restartedProfiles.getFlagBackgroundMode(),
        LearnerFlagBackgroundMode.extended,
      );
    },
  );

  testWidgets(
    'learner bottom keeps three primary actions plus compact appearance utilities',
    (tester) async {
      await ProfileService().addProfile('Bottom Learner');
      var reviewTaps = 0;
      var courseInfoTaps = 0;
      var profileTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnerBottomActions(
              onProfile: () => profileTaps++,
              onReview: () => reviewTaps++,
              onCourseInfo: () => courseInfoTaps++,
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.byKey(const Key('learner-bottom-profile')), findsOneWidget);
      expect(find.byKey(const Key('learner-bottom-review')), findsOneWidget);
      expect(
        find.byKey(const Key('learner-bottom-course-info')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Leaderboard'), findsNothing);
      expect(find.bySemanticsLabel('Buy a coffee'), findsNothing);
      expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);
      expect(find.byIcon(Icons.coffee_outlined), findsNothing);
      expect(find.byKey(const Key('learner-bottom-theme')), findsOneWidget);
      expect(find.byTooltip('Theme: Default'), findsOneWidget);
      expect(find.bySemanticsLabel('Theme: Default'), findsOneWidget);
      expect(
        find.byKey(const Key('learner-bottom-flag-background')),
        findsOneWidget,
      );
      expect(find.byTooltip('Flag background: Small'), findsOneWidget);
      expect(find.bySemanticsLabel('Flag background: Small'), findsOneWidget);

      await tester.tap(find.byKey(const Key('learner-bottom-profile')));
      await tester.tap(find.byKey(const Key('learner-bottom-review')));
      await tester.tap(find.byKey(const Key('learner-bottom-course-info')));
      expect((profileTaps, reviewTaps, courseInfoTaps), (1, 1, 1));
    },
  );

  testWidgets(
    'flag background utility cycles Small, Off, Extended, then Small',
    (tester) async {
      final profiles = ProfileService();
      await profiles.addProfile('Flag Learner');

      await tester.pumpWidget(
        QuisquisLingoApp(
          profileService: profiles,
          home: Scaffold(
            body: LearnerBottomActions(
              profileService: profiles,
              onProfile: () {},
              onReview: () {},
              onCourseInfo: () {},
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      LearnerFlagBackgroundMode scopedMode() => tester
          .widget<LearnerFlagBackgroundModeScope>(
            find.byType(LearnerFlagBackgroundModeScope),
          )
          .mode;
      final control = find.byKey(const Key('learner-bottom-flag-background'));

      expect(scopedMode(), LearnerFlagBackgroundMode.small);
      expect(find.byTooltip('Flag background: Small'), findsOneWidget);

      Future<void> tapAndExpect(LearnerFlagBackgroundMode mode) async {
        await tester.tap(control);
        await _pumpFrames(tester);
        expect(await profiles.getFlagBackgroundMode(), mode);
        expect(scopedMode(), mode);
        expect(
          find.byTooltip('Flag background: ${mode.label}'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Flag background: ${mode.label}'),
          findsOneWidget,
        );
      }

      await tapAndExpect(LearnerFlagBackgroundMode.off);
      await tapAndExpect(LearnerFlagBackgroundMode.extended);
      await tapAndExpect(LearnerFlagBackgroundMode.small);
    },
  );

  testWidgets(
    'theme utility cycles Default, Light, Dark and immediately applies each mode',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);
      final profiles = ProfileService();
      await profiles.addProfile('Theme Learner');

      await tester.pumpWidget(
        QuisquisLingoApp(
          profileService: profiles,
          home: Scaffold(
            body: LearnerBottomActions(
              profileService: profiles,
              onProfile: () {},
              onReview: () {},
              onCourseInfo: () {},
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      MaterialApp app() => tester.widget<MaterialApp>(find.byType(MaterialApp));
      LearnerThemeMode scopedMode() => tester
          .widget<LearnerThemeModeScope>(find.byType(LearnerThemeModeScope))
          .mode;
      final control = find.byKey(const Key('learner-bottom-theme'));

      expect(app().themeMode, ThemeMode.system);
      expect(scopedMode(), LearnerThemeMode.defaultMode);
      expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);

      Future<void> tapAndExpect({
        required LearnerThemeMode mode,
        required ThemeMode materialMode,
        required IconData icon,
      }) async {
        await tester.tap(control);
        await _pumpFrames(tester);
        expect(await profiles.getThemeMode(), mode);
        expect(app().themeMode, materialMode);
        expect(scopedMode(), mode);
        expect(find.byTooltip('Theme: ${mode.label}'), findsOneWidget);
        expect(find.bySemanticsLabel('Theme: ${mode.label}'), findsOneWidget);
        expect(find.byIcon(icon), findsOneWidget);
      }

      await tapAndExpect(
        mode: LearnerThemeMode.light,
        materialMode: ThemeMode.light,
        icon: Icons.light_mode_outlined,
      );
      await tapAndExpect(
        mode: LearnerThemeMode.dark,
        materialMode: ThemeMode.dark,
        icon: Icons.dark_mode_outlined,
      );
      expect(Theme.of(tester.element(control)).brightness, Brightness.dark);
      await tapAndExpect(
        mode: LearnerThemeMode.defaultMode,
        materialMode: ThemeMode.system,
        icon: Icons.brightness_auto_outlined,
      );
      await tapAndExpect(
        mode: LearnerThemeMode.light,
        materialMode: ThemeMode.light,
        icon: Icons.light_mode_outlined,
      );
    },
  );

  testWidgets(
    'active learner immediately restores theme and no learner falls back to Default',
    (tester) async {
      final profiles = ProfileService();
      await profiles.addProfile('Dark Learner');
      await profiles.setThemeMode(LearnerThemeMode.dark);
      await profiles.addProfile('Light Learner');
      await profiles.setThemeMode(LearnerThemeMode.light);

      Widget app() => QuisquisLingoApp(
        profileService: profiles,
        home: Scaffold(
          body: LearnerBottomActions(
            profileService: profiles,
            onProfile: () {},
            onReview: () {},
            onCourseInfo: () {},
          ),
        ),
      );

      await tester.pumpWidget(app());
      await _pumpFrames(tester);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light,
      );
      expect(find.byTooltip('Theme: Light'), findsOneWidget);

      await profiles.setActiveProfile('Dark Learner');
      await _pumpFrames(tester);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(find.byTooltip('Theme: Dark'), findsOneWidget);

      await profiles.clearActiveProfile();
      await _pumpFrames(tester);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(
        tester
            .widget<LearnerThemeModeScope>(find.byType(LearnerThemeModeScope))
            .mode,
        LearnerThemeMode.defaultMode,
      );
      expect(find.byTooltip('Theme: Default'), findsOneWidget);
      await tester.tap(find.byKey(const Key('learner-bottom-theme')));
      await _pumpFrames(tester);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(find.byTooltip('Theme: Default'), findsOneWidget);

      await profiles.setActiveProfile('Dark Learner');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await _pumpFrames(tester);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    },
  );

  testWidgets('Profile bottom action follows the complete fallback hierarchy', (
    tester,
  ) async {
    const longName = 'A learner name that needs two centered lines';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnerBottomActions(
            key: const ValueKey('name-fallback-actions'),
            profileService: _ProfileServiceWithoutAvatar(longName),
            onProfile: () {},
            onReview: () {},
            onCourseInfo: () {},
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    final fallback = tester.widget<Text>(
      find.byKey(const Key('learner-bottom-profile-name')),
    );
    expect(fallback.data, longName);
    expect(fallback.maxLines, 2);
    expect(fallback.overflow, TextOverflow.ellipsis);
    expect(fallback.textAlign, TextAlign.center);
    expect(find.byTooltip(longName), findsOneWidget);
    expect(find.bySemanticsLabel('Profile, $longName'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnerBottomActions(
            key: const ValueKey('icon-fallback-actions'),
            profileService: _ProfileServiceWithoutAvatar(null),
            onProfile: () {},
            onReview: () {},
            onCourseInfo: () {},
          ),
        ),
      ),
    );
    await _pumpFrames(tester);
    expect(
      find.byKey(const Key('learner-bottom-profile-icon')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.bySemanticsLabel('Profile'), findsOneWidget);
  });

  testWidgets(
    'Profile avatar reacts to active learner and appearance changes',
    (tester) async {
      final profiles = ProfileService();
      await profiles.addProfile('First Learner');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnerBottomActions(
              onProfile: () {},
              onReview: () {},
              onCourseInfo: () {},
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.bySemanticsLabel('Profile, First Learner'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('learner-bottom-profile-avatar'))),
        const Size(32, 32),
      );

      await profiles.addProfile(
        'Second Learner',
        skinTone: 'dark',
        hairTone: 'light',
      );
      await _pumpFrames(tester);
      expect(find.bySemanticsLabel('Profile, Second Learner'), findsOneWidget);
      var avatar = tester.widget<LearnerAvatar>(
        find.byKey(const Key('learner-bottom-profile-avatar')),
      );
      expect(avatar.skinTone, 'dark');
      expect(avatar.hairTone, 'light');

      await profiles.setHairTone('dark');
      await _pumpFrames(tester);
      avatar = tester.widget<LearnerAvatar>(
        find.byKey(const Key('learner-bottom-profile-avatar')),
      );
      expect(avatar.hairTone, 'dark');
    },
  );

  testWidgets('bottom actions and theme utility fit required phone widths', (
    tester,
  ) async {
    await ProfileService().addProfile('Responsive Learner');
    final heights = <double>[];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final brightness in Brightness.values) {
      for (final width in const [320.0, 375.0, 430.0]) {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness, useMaterial3: true),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: LearnerBottomActions(
                  onProfile: () {},
                  onReview: () {},
                  onCourseInfo: () {},
                ),
              ),
            ),
          ),
        );
        await _pumpFrames(tester);

        final actions = tester.getRect(
          find.byKey(const Key('learner-bottom-actions')),
        );
        final themeControl = tester.getRect(
          find.byKey(const Key('learner-bottom-theme')),
        );
        final flagControl = tester.getRect(
          find.byKey(const Key('learner-bottom-flag-background')),
        );
        final profile = tester.getRect(
          find.byKey(const Key('learner-bottom-profile')),
        );
        final review = tester.getRect(
          find.byKey(const Key('learner-bottom-review')),
        );
        final courseInfo = tester.getRect(
          find.byKey(const Key('learner-bottom-course-info')),
        );
        expect(actions.left, greaterThanOrEqualTo(0));
        expect(actions.right, lessThanOrEqualTo(width));
        expect(flagControl.right, lessThanOrEqualTo(actions.right));
        expect(themeControl.left, greaterThan(courseInfo.right));
        expect(flagControl.left, greaterThan(themeControl.right));
        expect(themeControl.size, const Size(40, 40));
        expect(flagControl.size, const Size(40, 40));
        expect(profile.width, greaterThan(themeControl.width));
        expect(review.width, greaterThan(themeControl.width));
        expect(courseInfo.width, greaterThan(themeControl.width));
        heights.add(actions.height);
        expect(tester.takeException(), isNull);
      }
    }
    expect(heights.toSet(), {learnerBottomActionsHeight});
  });

  testWidgets('Profile links return naturally to Profile', (tester) async {
    await ProfileService().addProfile(
      'Profile Learner',
      skinTone: 'light',
      hairTone: 'dark',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          onManageLearners: (context) => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: Text('Learner profiles')),
                body: const Center(child: Text('Learner profiles destination')),
              ),
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('Profile Learner'), findsOneWidget);
    expect(find.byKey(const Key('profile-large-avatar')), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Avatar'));
    await _pumpUntil(tester, find.byType(AvatarSettingsScreen));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final learnerProfiles = find.widgetWithText(ListTile, 'Learner profiles');
    await tester.ensureVisible(learnerProfiles);
    await tester.tap(learnerProfiles);
    await _pumpUntil(tester, find.text('Learner profiles destination'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final gamification = find.widgetWithText(ListTile, 'Gamification');
    await tester.ensureVisible(gamification);
    await tester.tap(gamification);
    await _pumpUntil(tester, find.byType(GamificationSettingsScreen));
    await _pumpFrames(tester);
    await tester.pageBack();
    await _pumpFrames(tester);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets(
    'Profile logout confirms and returns to the initial learner flow',
    (tester) async {
      final profiles = ProfileService();
      await profiles.addProfile('Logout Learner');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('learner_Logout%20Learner_xp_IT', 90);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProfileScreen(onManageLearners: (_) async {}),
                    ),
                  ),
                  child: const Text('Open Profile'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Profile'));
      await _pumpUntil(tester, find.byType(ProfileScreen));

      expect(find.text('This is a local profile only.'), findsOneWidget);
      expect(
        find.text('Logging out does not contact any remote server.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your learner profile and progress remain stored on this device.',
        ),
        findsOneWidget,
      );

      await tester.drag(find.byType(ListView), const Offset(0, -260));
      await tester.pumpAndSettle();
      final logout = find.byKey(const Key('profile-logout'));
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await _pumpUntil(tester, find.text('Log out of this local profile?'));
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await profiles.getActiveProfile(), 'Logout Learner');

      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await _pumpUntil(tester, find.text('Log out of this local profile?'));
      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Open Profile'), findsOneWidget);
      expect(await profiles.getActiveProfile(), isNull);
      expect(await profiles.getProfiles(), ['Logout Learner']);
      expect(prefs.getInt('learner_Logout%20Learner_xp_IT'), 90);
    },
  );

  testWidgets('Course Info owns the existing Buy a coffee destination', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: CourseInfoScreen(
          course: _courseFixture(
            supportUrl: 'https://example.com/course-support',
          ),
          launchExternal: (uri) async {
            openedUri = uri;
            return true;
          },
        ),
      ),
    );

    final supportAction = find.widgetWithText(ListTile, 'Buy a coffee');
    expect(supportAction, findsOneWidget);
    await tester.tap(supportAction);
    await tester.pump();
    expect(openedUri, Uri.parse('https://example.com/course-support'));
  });
}

class _ProfileServiceWithoutAvatar extends ProfileService {
  final String? activeProfile;

  _ProfileServiceWithoutAvatar(this.activeProfile);

  @override
  Future<String?> getActiveProfile() async => activeProfile;

  @override
  Future<ProfileAvatarAppearance?> getAvatarAppearanceForProfile(
    String profileName,
  ) async => null;
}

Course _courseFixture({required String supportUrl}) => Course(
  courseId: 'profile-navigation-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Profile Navigation Course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  supportUrl: supportUrl,
  topics: const [],
);

Future<void> _pumpFrames(WidgetTester tester, {int count = 12}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 80; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}
