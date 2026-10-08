import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/main.dart';
import 'package:quisquislingo_app/services/learner_theme_schedule.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/learner_theme_mode_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Day/Night resolves the exact local-time boundaries', () {
    expect(
      LearnerThemeSchedule.brightnessAt(DateTime(2026, 9, 7, 6, 59, 59)),
      Brightness.dark,
    );
    expect(
      LearnerThemeSchedule.brightnessAt(DateTime(2026, 9, 7, 7)),
      Brightness.light,
    );
    expect(
      LearnerThemeSchedule.brightnessAt(DateTime(2026, 9, 7, 12)),
      Brightness.light,
    );
    expect(
      LearnerThemeSchedule.brightnessAt(DateTime(2026, 9, 7, 18, 59, 59)),
      Brightness.light,
    );
    expect(
      LearnerThemeSchedule.brightnessAt(DateTime(2026, 9, 7, 19)),
      Brightness.dark,
    );
    expect(
      LearnerThemeSchedule.brightnessAt(DateTime(2026, 9, 7, 23)),
      Brightness.dark,
    );
  });

  test('Theme modes remain learner scoped and course independent', () async {
    final profiles = ProfileService();
    final settings = SettingsService();
    await profiles.addProfile('Day Night Learner');
    final dayNightId = (await profiles.getActiveProfileId())!;
    await profiles.setThemeMode(LearnerThemeMode.dayNight);
    await settings.setLastSelectedCourseCode('course-a');
    await settings.setLastSelectedCourseCode('course-b');
    expect(await profiles.getThemeMode(), LearnerThemeMode.dayNight);

    await profiles.addProfile('Light Learner');
    final lightId = (await profiles.getActiveProfileId())!;
    await profiles.setThemeMode(LearnerThemeMode.light);

    final restarted = ProfileService();
    await restarted.setActiveProfileById(dayNightId);
    expect(await restarted.getThemeMode(), LearnerThemeMode.dayNight);
    await restarted.setActiveProfileById(lightId);
    expect(await restarted.getThemeMode(), LearnerThemeMode.light);
  });

  testWidgets('stored Default is displayed as live System', (tester) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    final profiles = ProfileService();
    await profiles.addProfile('System Learner');
    final learnerId = (await profiles.getActiveProfileId())!;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      profiles.keyForProfileId(learnerId, 'theme_mode'),
      'default',
    );

    await tester.pumpWidget(
      QuisquisLingoApp(
        profileService: profiles,
        home: Builder(
          builder: (context) => Scaffold(
            body: Text(
              Theme.of(context).brightness.name,
              key: const Key('brightness-probe'),
            ),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.themeAnimationDuration, Duration.zero);
    expect(
      tester
          .widget<LearnerThemeModeScope>(find.byType(LearnerThemeModeScope))
          .mode,
      LearnerThemeMode.defaultMode,
    );
    expect(find.text('light'), findsOneWidget);

    dispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    expect(find.text('dark'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Day/Night switches live at the next boundary', (tester) async {
    final profiles = ProfileService();
    await profiles.addProfile('Boundary Learner');
    await profiles.setThemeMode(LearnerThemeMode.dayNight);
    var currentTime = DateTime(2026, 9, 7, 18, 59, 59);

    await tester.pumpWidget(
      QuisquisLingoApp(
        profileService: profiles,
        now: () => currentTime,
        home: const Scaffold(body: Text('Boundary probe')),
      ),
    );
    await _pumpFrames(tester);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    currentTime = DateTime(2026, 9, 7, 19);
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Day/Night re-evaluates local time on resume', (tester) async {
    final profiles = ProfileService();
    await profiles.addProfile('Resume Learner');
    await profiles.setThemeMode(LearnerThemeMode.dayNight);
    var currentTime = DateTime(2026, 9, 7, 8);

    await tester.pumpWidget(
      QuisquisLingoApp(
        profileService: profiles,
        now: () => currentTime,
        home: const Scaffold(body: Text('Resume probe')),
      ),
    );
    await _pumpFrames(tester);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    currentTime = DateTime(2026, 9, 7, 20);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('persisted Day/Night recalculates after app restart', (
    tester,
  ) async {
    final profiles = ProfileService();
    await profiles.addProfile('Restart Learner');
    await profiles.setThemeMode(LearnerThemeMode.dayNight);
    var currentTime = DateTime(2026, 9, 7, 9);

    Widget app() => QuisquisLingoApp(
      profileService: ProfileService(),
      now: () => currentTime,
      home: const Scaffold(body: Text('Restart probe')),
    );

    await tester.pumpWidget(app());
    await _pumpFrames(tester);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    currentTime = DateTime(2026, 9, 7, 21);
    await tester.pumpWidget(app());
    await _pumpFrames(tester);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      tester
          .widget<LearnerThemeModeScope>(find.byType(LearnerThemeModeScope))
          .mode,
      LearnerThemeMode.dayNight,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 12}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
}
