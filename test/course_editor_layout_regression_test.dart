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
import 'package:quisquislingo_app/services/team_service.dart';
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

  test('Course metadata helper text uses multiline field layouts', () {
    final createSource = File(
      'lib/screens/course_projects_screen.dart',
    ).readAsStringSync();
    final createDialog = createSource.substring(
      createSource.indexOf('Future<Course?> _createCourse()'),
      createSource.indexOf('Future<void> _newCourse()'),
    );
    expect(createSource, contains("labelText: 'Course Maintainer'"));
    expect(createSource, isNot(contains('Choose an individual user.')));
    expect(createDialog, contains('helper: Text('));
    expect(createDialog, isNot(contains('helperMaxLines: 3')));

    final editorSource = File(
      'lib/screens/course_editor_screen.dart',
    ).readAsStringSync();
    final infoEditor = editorSource.substring(
      editorSource.indexOf('final narrowCourseInfo ='),
      editorSource.indexOf('Future<void> _openLessons()'),
    );
    for (final label in [
      'Course name',
      'Course Maintainer',
      'Assigned Team',
      r'Custom role\(s\)',
      r'Buy a Coffee URL \(optional\)',
    ]) {
      expect(
        RegExp(
          "labelText: '$label',[\\s\\S]{0,260}helper: (?:const )?Text\\(",
        ).hasMatch(infoEditor),
        isTrue,
        reason: '$label helper text must wrap instead of clipping',
      );
    }
    expect(
      RegExp(r'helper: Text\(helperText\)').hasMatch(infoEditor),
      isTrue,
      reason: 'read-only metadata helpers must wrap too',
    );
    expect(infoEditor, isNot(contains('helperMaxLines: 3')));
  });

  testWidgets('Course metadata helpers wrap at 320 logical pixels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const longProfileName = 'Alexandria Montgomery-Worthington 12345';
    SharedPreferences.setMockInitialValues(
      _profilePreferences(longProfileName),
    );
    final currentCourse = Course(
      courseId: 'bundled_helper_layout',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Bundled helper layout',
      ttsLanguage: 'it-IT',
      lessons: const [],
    );

    await tester.pumpWidget(
      MaterialApp(home: CourseProjectsScreen(currentCourse: currentCourse)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-course-icon-action')));
    await tester.pumpAndSettle();

    final maintainerHelper = find.text(
      'The person currently responsible for maintaining this Course.',
      skipOffstage: false,
    );
    expect(maintainerHelper, findsOneWidget);
    expect(tester.widget<Text>(maintainerHelper).maxLines, isNull);
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    const teamId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    final profiles = ProfileService();
    final teams = TeamService(
      profileService: profiles,
      idGenerator: () => teamId,
    );
    await teams.createTeam(
      creatorProfileId: _ownerProfileId,
      displayName:
          'International Collaborative Language Curriculum Team With Long Name',
    );
    final custom = Course(
      courseId: 'custom_helper_layout',
      originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
        profileId: _ownerProfileId,
        displayName: longProfileName,
      ),
      maintainer: const CourseMaintainer(_ownerProfileId),
      assignedTeamId: teamId,
      originalCreatedAtUtc: '2026-09-12T09:00:00.000Z',
      lastVersionEditorProfileId: _ownerProfileId,
      lastVersionEditorDisplayName: longProfileName,
      modifiedAtUtc: '2026-09-12T09:00:00.000Z',
      publicationState: PublicationState.draft,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title:
          'A deliberately long Course name that remains readable at narrow widths',
      ttsLanguage: 'it-IT',
      authors: const [
        CourseAuthor(
          name: 'A Contributor With A Deliberately Long Attribution Name',
          roles: ['Contributor'],
        ),
      ],
      rightsHolders: const [
        CourseRightsHolder(
          type: CourseRightsHolderType.organization,
          name: 'A Rights Organization With A Deliberately Long Name',
        ),
      ],
      courseVersion: '1',
      lessons: const [],
    );
    await CourseEditorService(profileService: profiles).saveUserCourse(custom);
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: custom,
          userCourse: true,
          editorService: CourseEditorService(profileService: profiles),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-editor-lock')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Course Info Editor'));
    await tester.tap(find.text('Course Info Editor'));
    await tester.pumpAndSettle();

    for (final helper in const [
      'Renaming keeps the same Course ID.',
      'The person currently responsible for maintaining this Course.',
      'Grants Team management access; the Course Maintainer and Original Course Creator stay unchanged.',
      'Optional; separate roles with commas.',
      'HTTPS only; shown in Course Info.',
      'A person or organization; descriptive only.',
    ]) {
      final finder = find.text(helper, skipOffstage: false);
      expect(finder, findsWidgets, reason: helper);
      expect(
        tester.widget<Text>(finder.first).maxLines,
        isNull,
        reason: helper,
      );
    }
    expect(tester.takeException(), isNull);
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
      expect(find.text('License / Rights'), findsOneWidget);
      expect(
        find.byKey(const Key('new-course-rights-holder-name-0')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('new-course-rights-holder-name-0')),
        'Independent Language Foundation',
      );
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
      await tester.tap(find.byKey(const Key('course-editor-lock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
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
      expect(created.rightsHolders, hasLength(1));
      expect(
        created.rightsHolders.single.name,
        'Independent Language Foundation',
      );
      expect(created.rightsHolders.single.type, CourseRightsHolderType.person);
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
      originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
        profileId: _ownerProfileId,
        displayName: 'Menu owner',
      ),
      maintainer: const CourseMaintainer(_ownerProfileId),
      originalCreatedAtUtc: '2026-09-12T09:00:00.000Z',
      publicationState: PublicationState.draft,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Menu Course',
      ttsLanguage: 'it-IT',
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
      'Copy as New Course',
      'Audit',
      'Export JSON',
      'Delete course',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Duplicate custom course'), findsNothing);
    await tester.tap(find.text('Copy as New Course'));
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
          find.text('Fork'),
          policy == DerivativeWorksPolicy.allowed
              ? findsOneWidget
              : findsNothing,
        );
        expect(find.text('Copy as New Course'), findsNothing);
        expect(find.text('Delete course'), findsNothing);
      },
    );
  }

  testWidgets(
    'custom Course Editor exposes Copy as New Course while Delete stays in Course Manager',
    (tester) async {
      const profileId = _ownerProfileId;
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: profileId,
            displayName: 'Copy Author',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: profileId,
      });
      final custom = Course(
        courseId: 'editor_copy_as_new',
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: profileId,
          displayName: 'Copy Author',
        ),
        maintainer: const CourseMaintainer(profileId),
        originalCreatedAtUtc: '2026-09-12T09:00:00.000Z',
        publicationState: PublicationState.draft,
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Editor Copy',
        ttsLanguage: 'it-IT',
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
        find.byKey(const Key('course-editor-copy-as-new-course')),
        findsOneWidget,
      );
      expect(find.text('Copy as New Course'), findsOneWidget);
      expect(find.text('Duplicate'), findsNothing);
      expect(find.text('Delete course'), findsNothing);
      expect(find.byTooltip('Run Course Audit'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Run audit'), findsOneWidget);

      await tester.tap(find.byKey(const Key('course-editor-lock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Course Info Editor'));
      await tester.pumpAndSettle();
      expect(find.text('License / Rights'), findsOneWidget);
      expect(
        find.byKey(const Key('course-info-rights-holder-name-0')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('course-info-rights-holder-name-0')),
        'Independent Course Rights Organization',
      );
      await tester.ensureVisible(find.byKey(const Key('course-info-save')));
      await tester.tap(find.byKey(const Key('course-info-save')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('lessons-search-action')), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Run audit'), findsNothing);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('course-editor-copy-as-new-course')),
      );
      await tester.pumpAndSettle();
      final copyEditor = tester.widget<CourseEditorScreen>(
        find.byType(CourseEditorScreen).last,
      );
      expect(copyEditor.isNewCourse, isFalse);
      expect(copyEditor.course.originType, CourseOriginType.custom);
      expect(copyEditor.course.courseId, isNot(custom.courseId));
      expect(copyEditor.course.forkProvenance, isNull);
      expect(copyEditor.course.rightsHolders, hasLength(1));
      expect(
        copyEditor.course.rightsHolders.single.name,
        'Independent Course Rights Organization',
      );
      expect(
        copyEditor.course.lessons.single.lessonId,
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
      await tester.tap(find.text('Fork'));
      await tester.pumpAndSettle();

      final forkEditor = tester.widget<CourseEditorScreen>(
        find.byType(CourseEditorScreen).last,
      );
      expect(forkEditor.isNewCourse, isFalse);
      expect(forkEditor.course.originType, CourseOriginType.custom);
      expect(forkEditor.course.courseId, isNot(official.courseId));
      expect(
        forkEditor.course.forkProvenance?.sourceCourseId,
        official.courseId,
      );
      expect(
        forkEditor.course.forkProvenance?.forkCreatedByDisplayName,
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
    derivativeWorksPolicy: policy,
    lessons: const [],
  );
  return Course.fromJson({
    ...course.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(course),
  });
}
