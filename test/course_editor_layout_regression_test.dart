import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Course Info avoids intrinsic LayoutBuilder conflict', () {
    final source = File(
      'lib/screens/course_editor_screen.dart',
    ).readAsStringSync().replaceAll(RegExp(r'\s+'), '');
    final start = source.indexOf(
      "finalnarrowCourseInfo=MediaQuery.sizeOf(context).width<560;",
    );
    final end = source.indexOf('Future<void>_openLessons()', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final courseInfo = source.substring(start, end);
    expect(courseInfo.contains('LayoutBuilder('), isFalse);
    expect(courseInfo.contains('for(finalcinnames){'), isTrue);
    expect(courseInfo.contains('for(finalcincustomRoles){'), isTrue);
  });

  test(
    'Course Editor routes direct Lessons through one management subpage',
    () {
      final source = File(
        'lib/screens/course_editor_screen.dart',
      ).readAsStringSync();
      expect(source, contains('Future<void> _addLesson()'));
      expect(source, contains('Future<void> _openLesson(int index)'));
      expect(source, contains('itemCount: _course.lessons.length'));
      expect(source, contains("label: const Text('New lesson')"));
      expect(source, contains('class LessonManagementScreen'));
      expect(
        source,
        contains("key: const Key('course-editor-lessons-navigation')"),
      );
      final mainEditor = source.substring(
        source.indexOf('class _CourseEditorScreenState'),
        source.indexOf('class LessonManagementScreen'),
      );
      expect(mainEditor, isNot(contains("title: const Text('Lock')")));
      expect(mainEditor, isNot(contains('ReorderableListView.builder')));
      expect(source, isNot(contains('class ChapterEditorScreen')));
      expect(source, isNot(contains('required this.chapter')));
    },
  );

  testWidgets('new course starts with 3 direct placeholder Lessons', (
    tester,
  ) async {
    const profileId = '12345678-1234-4234-9234-123456789abc';
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: profileId,
          displayName: 'Layout Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: profileId,
    });
    final currentCourse = Course(
      courseId: 'bundled_test',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Bundled test',
      ttsLanguage: 'it-IT',
      version: '1.0.0',
      lessons: const [],
    );
    await tester.pumpWidget(
      MaterialApp(home: CourseProjectsScreen(currentCourse: currentCourse)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Create new course'));
    await tester.pumpAndSettle();
    final titleField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Course title *',
    );
    final targetField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Target language *',
    );
    await tester.enterText(titleField, 'Direct Lessons');
    await tester.enterText(targetField, 'Italian');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(await CourseEditorService().listUserCourses(), isEmpty);
    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await tester.pumpAndSettle();
    for (final title in [
      'Lesson 1: Lesson 1',
      'Lesson 2: Lesson 2',
      'Lesson 3: Lesson 3',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await tester.pumpAndSettle();

    final stored = await CourseEditorService().listUserCourses();
    expect(stored, hasLength(1));
    final created = stored.single;
    expect(created.courseVersion, '1');
    expect(created.publicationState, PublicationState.draft);
    expect(created.lessons, hasLength(3));
    expect(created.lessons.expand((lesson) => lesson.rounds), isEmpty);
    expect(created.temporarySample, isFalse);
    expect(
      created.lessons.map((lesson) => lesson.lessonId).toSet(),
      hasLength(3),
    );
    expect(
      created.lessons.map((lesson) => lesson.duel.id).toSet(),
      hasLength(3),
    );
    for (final lesson in created.lessons) {
      expect(lesson.publicationState, PublicationState.draft);
      expect(lesson.duel.id, '${lesson.lessonId}_duel');
    }
  });

  testWidgets('custom Course menu enters the 225.04 transaction for edits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final custom = Course(
      courseId: 'custom_menu',
      publicationState: PublicationState.draft,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Menu Course',
      ttsLanguage: 'it-IT',
      version: '1',
      lessons: const [],
    );
    await CourseEditorService().saveUserCourse(custom);
    await tester.pumpWidget(
      MaterialApp(home: CourseProjectsScreen(currentCourse: custom)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Course actions'));
    await tester.pumpAndSettle();
    for (final label in [
      'Edit',
      'Duplicate custom course',
      'Audit',
      'Export JSON',
      'Delete course',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Duplicate custom course'));
    await tester.pumpAndSettle();
    expect(find.text('Course Editor'), findsOneWidget);
    expect(await CourseEditorService().listUserCourses(), hasLength(1));
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('cancel-course-changes')));
    await tester.pumpAndSettle();
    expect(await CourseEditorService().listUserCourses(), hasLength(1));
  });
}
