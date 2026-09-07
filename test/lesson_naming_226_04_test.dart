import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/editor_breadcrumbs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  for (final scenario in [
    (
      choice: 'Lesson + number',
      mode: LessonNumberingMode.lesson,
      first: 'Lesson 1',
      second: 'Lesson 2: Greetings',
    ),
    (
      choice: 'Number only',
      mode: LessonNumberingMode.numberOnly,
      first: '1',
      second: '2: Greetings',
    ),
    (
      choice: 'Title only',
      mode: LessonNumberingMode.none,
      first: 'Lesson 1',
      second: 'Greetings',
    ),
    (
      choice: 'Unit',
      mode: LessonNumberingMode.unit,
      first: 'Unit 1',
      second: 'Unit 2: Greetings',
    ),
    (
      choice: 'Module',
      mode: LessonNumberingMode.module,
      first: 'Module 1',
      second: 'Module 2: Greetings',
    ),
    (
      choice: 'Other...',
      mode: LessonNumberingMode.other,
      first: 'Level 1',
      second: 'Level 2: Greetings',
    ),
  ]) {
    testWidgets(
      'Lessons ${scenario.choice} updates Editor, breadcrumbs, Preview and reload at 320 px without renaming Lessons',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final source = _course();
        final original = jsonEncode(source.toJson());
        await SettingsService().setCourseEditorLocked(source.courseId, false);
        await SettingsService().markAudioOrphanCheckRun(
          CourseService.codeForCourse(source),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: CourseEditorScreen(course: source, userCourse: true),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Course Info Editor'));
        await tester.tap(find.text('Course Info Editor'));
        await tester.pumpAndSettle();
        final modeField = find.byType(
          DropdownButtonFormField<LessonNumberingMode>,
        );
        expect(modeField, findsNothing);
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        final lessonsLink = find.byKey(
          const Key('course-editor-lessons-navigation'),
        );
        await tester.scrollUntilVisible(
          lessonsLink,
          -200,
          scrollable: find
              .descendant(
                of: find.byType(CourseEditorScreen),
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 10,
        );
        await tester.pumpAndSettle();
        await tester.tap(lessonsLink);
        await tester.pumpAndSettle();
        expect(find.text('Lesson appearance'), findsOneWidget);
        expect(
          tester
              .widget<DropdownButton<LessonNumberingMode>>(
                find.descendant(
                  of: modeField,
                  matching: find.byType(DropdownButton<LessonNumberingMode>),
                ),
              )
              .items!
              .map((item) => item.value),
          LessonNumberingMode.values,
        );
        await tester.ensureVisible(modeField);
        await tester.pumpAndSettle();
        await tester.tap(modeField);
        await tester.pumpAndSettle();
        final option = find.text(scenario.choice).last;
        await tester.ensureVisible(option);
        await tester.pumpAndSettle();
        await tester.tap(option);
        await tester.pumpAndSettle();
        if (scenario.mode == LessonNumberingMode.other) {
          expect(find.text('Custom Lesson label'), findsOneWidget);
          final custom = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          );
          await tester.enterText(custom, 'Level');
          await tester.tap(find.widgetWithText(FilledButton, 'Save'));
          await tester.pumpAndSettle();
        }
        expect(
          tester.state<FormFieldState<LessonNumberingMode>>(modeField).value,
          scenario.mode,
        );
        expect(find.byType(AlertDialog), findsNothing);
        if (scenario.mode == LessonNumberingMode.module) {
          await tester.ensureVisible(modeField);
          await tester.tap(modeField);
          await tester.pumpAndSettle();
          final other = find.text('Other...').last;
          await tester.ensureVisible(other);
          await tester.tap(other);
          await tester.pumpAndSettle();
          expect(find.text('Custom Lesson label'), findsOneWidget);
          await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
          await tester.pumpAndSettle();
          expect(
            tester.state<FormFieldState<LessonNumberingMode>>(modeField).value,
            LessonNumberingMode.module,
          );
        }
        Course? working;
        for (final entry in [
          ('default-title', scenario.first),
          ('authored-title', scenario.second),
        ]) {
          final title = find.descendant(
            of: find.byKey(ValueKey('lesson-status-indicator-${entry.$1}')),
            matching: find.text(entry.$2),
          );
          await tester.ensureVisible(title);
          await tester.pumpAndSettle();
          await tester.tap(title);
          await tester.pumpAndSettle();
          expect(find.byType(LessonEditorScreen), findsOneWidget);
          working = tester
              .widget<LessonEditorScreen>(find.byType(LessonEditorScreen))
              .course;
          expect(
            find.descendant(
              of: find.byType(AppBar),
              matching: find.text(entry.$2),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(EditorBreadcrumbs),
              matching: find.text(entry.$2),
            ),
            findsOneWidget,
          );
          await tester.pageBack();
          await tester.pumpAndSettle();
          final actions = find.byKey(ValueKey('lesson-actions-${entry.$1}'));
          await tester.ensureVisible(actions);
          await tester.pumpAndSettle();
          await tester.tap(actions);
          await tester.pumpAndSettle();
          await tester.tap(
            find.widgetWithText(PopupMenuItem<String>, 'Preview'),
          );
          await tester.pumpAndSettle();
          expect(find.byType(LessonAuthoringPreviewScreen), findsOneWidget);
          expect(find.text('PREVIEW · ${entry.$2}'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        expect(working!.lessonNumberingMode, scenario.mode);
        expect(working.lessons.map((lesson) => lesson.title), [
          'Lesson 1',
          'Greetings',
        ]);
        expect(working.lessons.map((lesson) => lesson.lessonId), [
          'default-title',
          'authored-title',
        ]);
        final reloaded = Course.fromJson(
          jsonDecode(jsonEncode(working.toJson())) as Map<String, dynamic>,
        );
        expect(reloaded.lessonNumberingMode, scenario.mode);
        if (scenario.mode == LessonNumberingMode.other) {
          expect(reloaded.customLessonLabel, 'Level');
        }
        await tester.pumpWidget(
          MaterialApp(
            key: const Key('reloaded-preview'),
            home: LessonAuthoringPreviewScreen(
              course: reloaded,
              lesson: reloaded.lessons.first,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('PREVIEW · ${scenario.first}'), findsOneWidget);
        expect(jsonEncode(source.toJson()), original);
        expect(tester.takeException(), isNull);
        if (scenario.mode == LessonNumberingMode.module) {
          await _expectPersistedHome(tester, working);
        }
      },
    );
  }
}

Future<void> _expectPersistedHome(WidgetTester tester, Course course) async {
  await CourseEditorService().saveUserCourse(course);
  final saved = (await CourseEditorService().listUserCourses()).single;
  expect(saved.lessonNumberingMode, LessonNumberingMode.module);
  expect(saved.lessons.map((lesson) => lesson.title), [
    'Lesson 1',
    'Greetings',
  ]);
  await ProfileService().addProfile('Numbering learner');
  final preferences = await SharedPreferences.getInstance();
  await preferences.setBool('sound_effects_enabled', false);
  await preferences.setBool(
    'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}',
    true,
  );
  await SettingsService().setLastSelectedCourseCode(
    'custom:${course.courseId}',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => throw PlatformException(code: 'test_storage_unavailable'),
      );
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });
  for (var launch = 0; launch < 2; launch++) {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey('numbering-learner-launch-$launch'),
        home: const HomeScreen(),
      ),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    if (find.text('Alpha expiry').evaluate().isNotEmpty) {
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    expect(find.text('Module 1', findRichText: true), findsWidgets);
    expect(find.text('Lesson 1: Lesson 1', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  }
}

Course _course() => Course(
  courseId: 'lesson-naming',
  learningLanguage: 'it',
  interfaceLanguage: 'en',
  sourceLanguage: 'en',
  targetLanguage: 'it',
  title: 'Lesson naming',
  ttsLanguage: 'it-IT',
  version: '1',
  license: 'CC0-1.0',
  lessons: [
    Lesson(lessonId: 'default-title', title: 'Lesson 1', rounds: []),
    Lesson(lessonId: 'authored-title', title: 'Greetings', rounds: []),
  ],
);
