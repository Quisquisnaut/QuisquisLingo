import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/main.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/lesson_fallback_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final mode in [LearnerThemeMode.light, LearnerThemeMode.dark]) {
    final brightness = mode == LearnerThemeMode.light
        ? Brightness.light
        : Brightness.dark;

    for (final persisted in ['monochrome', 'coloredLessonNumbers']) {
      testWidgets(
        '$persisted loads as the one theme-colored circle in ${mode.name}',
        (tester) async {
          final course = _reload(_course(persisted));
          expect(course.toJson()['defaultLessonIconStyle'], persisted);
          final profiles = await _profile(mode);
          await tester.pumpWidget(
            QuisquisLingoApp(
              profileService: profiles,
              home: Scaffold(
                body: Center(
                  child: LessonFallbackIcon(
                    style: course.defaultLessonIconStyle,
                    number: 1,
                    size: 84,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final fallback = find.byType(LessonFallbackIcon);
          final theme = Theme.of(tester.element(fallback));
          expect(theme.brightness, brightness);
          expect(tester.getSize(fallback), const Size(84, 84));
          final number = tester.widget<Text>(
            find.descendant(of: fallback, matching: find.text('1')),
          );

          expect(
            tester
                .widget<CircleAvatar>(find.byType(CircleAvatar))
                .backgroundColor,
            theme.colorScheme.primaryContainer,
          );
          expect(number.style!.color, theme.colorScheme.onPrimaryContainer);
          expect(
            find.descendant(of: fallback, matching: find.byType(ClipOval)),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'explicit custom Lesson icon ignores $persisted in ${mode.name}',
        (tester) async {
          final bytes = File('assets/lesson_icons/home.png').readAsBytesSync();
          final asset = CourseLessonIconAsset(
            assetId: 'custom-number-icon-regression',
            base64Png: base64Encode(bytes),
          );
          final course = _reload(_course(persisted, customIcon: asset));
          final profiles = await _profile(mode);
          await tester.binding.setSurfaceSize(const Size(430, 1000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            QuisquisLingoApp(
              profileService: profiles,
              home: LessonEditorScreen(
                course: course,
                lesson: course.lessons.single,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final field = find.byKey(const Key('lesson-theme-icon-field'));
          await tester.scrollUntilVisible(
            field,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();

          expect(Theme.of(tester.element(field)).brightness, brightness);
          final image = tester.widget<Image>(
            find.descendant(of: field, matching: find.byType(Image)),
          );
          expect(image.image, isA<MemoryImage>());
          expect((image.image as MemoryImage).bytes, orderedEquals(bytes));
          expect(image.color, isNull);
          expect(image.colorBlendMode, isNull);
          expect(
            find.descendant(
              of: field,
              matching: find.byType(LessonFallbackIcon),
            ),
            findsNothing,
          );
          expect(course.toJson()['defaultLessonIconStyle'], persisted);
          expect(course.lessons.single.themeIconAsset, asset.reference);
          expect(course.lessonIconAssets.single.base64Png, asset.base64Png);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<ProfileService> _profile(LearnerThemeMode mode) async {
  final profiles = ProfileService();
  await profiles.addProfile('Fallback rendering');
  await profiles.setThemeMode(mode);
  return profiles;
}

Course _reload(Course course) => Course.fromJson(
  jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>,
);

Course _course(String persisted, {CourseLessonIconAsset? customIcon}) =>
    Course.fromJson({
      ...Course(
        courseId: 'fallback-number-icons',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Fallback number icons',
        ttsLanguage: 'it-IT',
        version: '1',
        lessons: [
          Lesson(
            lessonId: 'number-lesson',
            title: 'Number lesson',
            themeIconAsset: customIcon?.reference,
            rounds: const [],
          ),
        ],
        lessonIconAssets: [if (customIcon != null) customIcon],
      ).toJson(),
      'defaultLessonIconStyle': persisted,
    });
