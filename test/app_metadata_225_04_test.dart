import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/sound_effect_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'authoritative metadata matches platform-compatible pubspec version',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version = RegExp(
        r'^version:\s*(\S+)$',
        multiLine: true,
      ).firstMatch(pubspec)?.group(1);

      expect(AppMetadata.releaseVersion, '2.0.25');
      expect(AppMetadata.build, '225.04');
      expect(AppMetadata.platformBuildNumber, '22504');
      expect(AppMetadata.technicalVersion, '2.0.25+22504');
      expect(AppMetadata.version, AppMetadata.technicalVersion);
      expect(version, AppMetadata.technicalVersion);
      expect(AppMetadata.displayLabel, 'Version: 2.0.25\nBuild: 225.04');
    },
  );

  testWidgets(
    'complete Settings Version and Build area remains ten-tap target',
    (tester) async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => throw PlatformException(code: 'test-storage'),
          );
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(
            course: _course(),
            onManageLearners: (_) async {},
            soundEffectService: _SilentSounds(),
          ),
        ),
      );
      final target = find.byKey(const Key('settings-version-build-area'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Version and Build'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(target, findsOneWidget);
      expect(find.text(AppMetadata.displayLabel), findsOneWidget);

      for (var tap = 0; tap < 9; tap++) {
        await tester.tap(target);
        await tester.pump();
      }
      expect(find.text('Course Editor unlocked.'), findsNothing);
      expect(await SettingsService().isCourseEditorUnlocked(), isFalse);

      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.text('Course Editor unlocked.'), findsOneWidget);
      expect(await SettingsService().isCourseEditorUnlocked(), isTrue);
      expect(find.text('Course Editor'), findsOneWidget);
    },
  );
}

class _SilentSounds extends SoundEffectService {
  @override
  Future<void> dispose() async {}
}

Course _course() => Course(
  courseId: 'metadata-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Italian',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: const [],
);
