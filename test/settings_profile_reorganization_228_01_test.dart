import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/debug_screen.dart';
import 'package:quisquislingo_app/screens/profile_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/screens/tts_settings_screen.dart';
import 'package:quisquislingo_app/screens/user_data_settings_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('228.01 Settings has the requested destinations in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: _course, onManageLearners: (_) async {}),
      ),
    );
    await _pumpFrames(tester);

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => tile.title)
        .whereType<Text>()
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(titles, [
      'Profile',
      'App Info',
      'Audio Settings',
      'Do Not Disturb',
      'Debug',
      'Version and Build',
      'Update',
    ]);
    expect(find.text('Course Manager'), findsNothing);
    expect(find.text('User Data'), findsNothing);
    expect(find.text('TTS Settings'), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, 'Audio Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(TtsSettingsScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Audio Settings'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Debug'));
    await _pumpFrames(tester);
    expect(find.byType(DebugScreen), findsOneWidget);
  });

  testWidgets('228.01 flag tooltip and hover wave preserve the trigger', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: _course, onManageLearners: (_) async {}),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byTooltip('Tap tap... Flag Game'), findsOneWidget);
    final flag = find.byKey(const Key('settings-flag-wave'));
    final initialTurns = tester.widget<RotationTransition>(flag).turns.value;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(-10, -10));
    await mouse.moveTo(tester.getCenter(flag));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    final hoveredTurns = tester.widget<RotationTransition>(flag).turns.value;
    expect(hoveredTurns, isNot(initialTurns));
    await mouse.moveTo(const Offset(-10, -10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(
      tester.widget<RotationTransition>(flag).turns.value,
      closeTo(0, 0.0001),
    );
  });

  testWidgets('228.01 User Data follows Gamification inside Profile', (
    tester,
  ) async {
    await ProfileService().addProfile('Profile Learner');
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(course: _course, onManageLearners: (_) async {}),
      ),
    );
    await _pumpFrames(tester);

    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => tile.title)
        .whereType<Text>()
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(titles, [
      'Avatar',
      'Learner profiles',
      'Gamification',
      'Statistics',
      'User Data',
    ]);
    expect(
      tester.getTopLeft(find.byKey(const Key('profile-user-data-link'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('profile-logout'))).dy),
    );

    await tester.tap(find.widgetWithText(ListTile, 'User Data'));
    await tester.pumpAndSettle();
    expect(find.byType(UserDataSettingsScreen), findsOneWidget);
  });
}

final _course = Course(
  courseId: 'qql-228-settings-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'QQL 228 Settings Course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  lessons: const [],
);

Future<void> _pumpFrames(WidgetTester tester, {int count = 16}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
