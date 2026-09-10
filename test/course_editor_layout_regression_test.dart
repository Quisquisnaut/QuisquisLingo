import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ownerProfileId = '12345678-1234-4234-9234-123456789abc';

Map<String, Object> _profilePreferences(String displayName) => {
  ProfileService.profilesKey: [
    LearnerProfile(
      learnerProfileId: _ownerProfileId,
      displayName: displayName,
    ).encode(),
  ],
  ProfileService.activeProfileIdKey: _ownerProfileId,
};

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

  testWidgets(
    'new course defaults to 3 Lessons with one sample Exercise per Round',
    (tester) async {
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
      expect(find.text('Course Manager'), findsOneWidget);
      expect(find.text('Course Editor'), findsNothing);
      expect(find.text('Course Import'), findsNothing);
      expect(find.byTooltip('Course Import'), findsOneWidget);
      expect(find.text('Import instructions'), findsNothing);
      expect(find.text('Import course JSON'), findsNothing);

      await tester.tap(find.byKey(const Key('course-import-icon-action')));
      await tester.pumpAndSettle();
      expect(find.byType(CourseImportScreen), findsOneWidget);
      expect(find.text('Course Import'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Import Course JSON'),
        findsOneWidget,
      );
      expect(find.text('Import instructions'), findsOneWidget);
      expect(
        find.textContaining('Documents/QuisquisLingo/Imports/import.json'),
        findsOneWidget,
      );
      expect(find.textContaining('/Exports/'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('create-course-icon-action')));
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
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      for (final title in ['Lesson 1', 'Lesson 2', 'Lesson 3']) {
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
      expect(created.lessons.expand((lesson) => lesson.rounds), hasLength(3));
      for (final lesson in created.lessons) {
        expect(lesson.rounds, hasLength(1));
        expect(lesson.rounds.single.content, hasLength(1));
        expect(
          lesson.rounds.single.exercises.single.publicationState,
          PublicationState.draft,
        );
        expect(lesson.rounds.single.title, isEmpty);
      }
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
    },
  );

  testWidgets('custom Course menu enters the 225.04 transaction for edits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(_profilePreferences('Menu owner'));
    final custom = Course(
      courseId: 'custom_menu',
      creatorProfileId: _ownerProfileId,
      ownership: const CourseOwnership.individual(_ownerProfileId),
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

    await tester.tap(
      find.byKey(const Key('course-manager-actions-custom_menu')),
    );
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
    expect(await CourseEditorService().listUserCourses(), hasLength(2));
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cancel-course-changes')), findsNothing);
    expect(await CourseEditorService().listUserCourses(), hasLength(2));
  });

  for (final policy in [
    DerivativeWorksPolicy.allowed,
    DerivativeWorksPolicy.forbidden,
    DerivativeWorksPolicy.unspecified,
  ]) {
    testWidgets(
      'Course Manager ${policy.name} official action set keeps licensed Fork distinct',
      (tester) async {
        SharedPreferences.setMockInitialValues(
          _profilePreferences('Official inspector'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: CourseProjectsScreen(currentCourse: _official(policy)),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('course-manager-actions-current')),
        );
        await tester.pumpAndSettle();
        expect(find.text('View (read only)'), findsOneWidget);
        expect(find.text('Audit'), findsOneWidget);
        expect(find.text('Export JSON'), findsOneWidget);
        expect(
          find.text('Fork as custom course'),
          policy == DerivativeWorksPolicy.allowed
              ? findsOneWidget
              : findsNothing,
        );
        expect(find.text('Duplicate custom course'), findsNothing);
        expect(find.text('Delete course'), findsNothing);
      },
    );
  }

  testWidgets(
    'custom Course Editor exposes Duplicate while Delete stays in Course Manager',
    (tester) async {
      const profileId = _ownerProfileId;
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: profileId,
            displayName: 'Duplicate Author',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: profileId,
      });
      final custom = Course(
        courseId: 'editor_duplicate',
        creatorProfileId: profileId,
        ownership: const CourseOwnership.individual(profileId),
        publicationState: PublicationState.draft,
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Editor Duplicate',
        ttsLanguage: 'it-IT',
        version: '1',
        lessons: [
          Lesson(lessonId: 'lesson', title: 'Lesson', rounds: const []),
        ],
      );
      await CourseEditorService().saveUserCourse(custom);
      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: custom, userCourse: true)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('course-editor-duplicate-course')),
        findsOneWidget,
      );
      expect(find.text('Delete course'), findsNothing);
      expect(find.byTooltip('Run Course Audit'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Run audit'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lesson-management-lock')), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Run audit'), findsNothing);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('course-editor-duplicate-course')));
      await tester.pumpAndSettle();
      final duplicateEditor = tester.widget<CourseEditorScreen>(
        find.byType(CourseEditorScreen).last,
      );
      expect(duplicateEditor.isNewCourse, isFalse);
      expect(duplicateEditor.course.originType, CourseOriginType.custom);
      expect(duplicateEditor.course.courseId, isNot(custom.courseId));
      expect(duplicateEditor.course.parentCourseId, custom.courseId);
      expect(
        duplicateEditor.course.lessons.single.lessonId,
        isNot(custom.lessons.single.lessonId),
      );
      expect(await CourseEditorService().listUserCourses(), hasLength(2));
    },
  );

  testWidgets(
    'Course Manager Fork uses licensed provenance and fresh identity semantics',
    (tester) async {
      const profileId = _ownerProfileId;
      final official = _official(DerivativeWorksPolicy.allowed);
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: profileId,
            displayName: 'Manager Forker',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: profileId,
        CourseEditorService.externalOfficialStorageKey: jsonEncode({
          official.courseId: {'source': official.toJson()},
        }),
      });
      final original = official.toJson();
      await tester.pumpWidget(
        MaterialApp(home: CourseProjectsScreen(currentCourse: official)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('course-manager-actions-current')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fork as custom course'));
      await tester.pumpAndSettle();

      final forkEditor = tester.widget<CourseEditorScreen>(
        find.byType(CourseEditorScreen).last,
      );
      expect(forkEditor.isNewCourse, isFalse);
      expect(forkEditor.course.originType, CourseOriginType.custom);
      expect(forkEditor.course.courseId, isNot(official.courseId));
      expect(forkEditor.course.parentCourseId, official.courseId);
      expect(
        forkEditor.course.forkProvenance?.originalCourseId,
        official.courseId,
      );
      expect(
        forkEditor.course.forkProvenance?.forkCreatedByUsername,
        'Manager Forker',
      );
      expect(official.toJson(), original);
      final stored = await CourseEditorService().listUserCourses();
      final customCourses = stored
          .where((course) => course.originType == CourseOriginType.custom)
          .toList();
      expect(customCourses, hasLength(1));
      expect(customCourses.single.courseId, forkEditor.course.courseId);
    },
  );
}

Course _official(DerivativeWorksPolicy policy) {
  final course = Course(
    courseId: 'official-actions',
    originType: CourseOriginType.externalOfficial,
    publisherId: 'publisher',
    publisherName: 'Publisher',
    officialCourseVersion: '1',
    officialReleaseDateUtc: '2026-09-09T00:00:00.000Z',
    officialChecksum: '0' * 64,
    distributionChannel: 'package',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Official actions',
    ttsLanguage: 'it-IT',
    version: '1',
    derivativeWorksPolicy: policy,
    lessons: const [],
  );
  return Course.fromJson({
    ...course.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(course),
  });
}
