import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
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
      first: 'Unit 1: Lesson 1',
      second: 'Unit 2: Greetings',
    ),
    (
      choice: 'Other...',
      mode: LessonNumberingMode.other,
      first: 'Level 1: Lesson 1',
      second: 'Level 2: Greetings',
    ),
  ]) {
    testWidgets(
      'Course Info ${scenario.choice} updates real Preview and reload at 320 px without renaming Lessons',
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
        await tester.tap(find.text('Course info'));
        await tester.pumpAndSettle();
        final modeField = find.byType(
          DropdownButtonFormField<LessonNumberingMode>,
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
        expect(
          tester.state<FormFieldState<LessonNumberingMode>>(modeField).value,
          scenario.mode,
        );
        if (scenario.mode == LessonNumberingMode.other) {
          final custom = find.byWidgetPredicate(
            (widget) =>
                widget is TextField &&
                widget.decoration?.labelText == 'Custom Lesson label',
          );
          await tester.ensureVisible(custom);
          await tester.pumpAndSettle();
          await tester.enterText(custom, 'Level');
        }
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.widgetWithText(FilledButton, 'Save'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        final lessonsLink = find.byKey(
          const Key('course-editor-lessons-navigation'),
        );
        await tester.ensureVisible(lessonsLink);
        await tester.pumpAndSettle();
        await tester.tap(lessonsLink);
        await tester.pumpAndSettle();
        final working = tester
            .widget<LessonManagementScreen>(find.byType(LessonManagementScreen))
            .course;
        expect(working.lessonNumberingMode, scenario.mode);
        expect(working.lessons.map((lesson) => lesson.title), [
          'Lesson 1',
          'Greetings',
        ]);
        expect(working.lessons.map((lesson) => lesson.lessonId), [
          'default-title',
          'authored-title',
        ]);
        for (final entry in [
          ('default-title', scenario.first),
          ('authored-title', scenario.second),
        ]) {
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
      },
    );
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
