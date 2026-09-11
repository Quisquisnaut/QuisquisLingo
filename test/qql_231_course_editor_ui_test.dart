import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_editor_search_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';

const ownerId = '00000000-0000-4000-8000-000000000231';
const otherId = '00000000-0000-4000-8000-000000000232';
const _stamp = '2026-09-11T10:00:00.000Z';

Course _course({
  String courseId = 'qql231_course',
  CourseOriginType origin = CourseOriginType.custom,
  CourseOwnership? ownership = const CourseOwnership.individual(ownerId),
}) => Course(
  courseId: courseId,
  creatorProfileId: origin == CourseOriginType.custom ? ownerId : null,
  ownership: origin == CourseOriginType.custom ? ownership : null,
  originType: origin,
  publisherId: origin.isOfficial ? 'org.quisquislingo' : '',
  publisherName: origin.isOfficial ? 'QQL' : '',
  officialCourseVersion: origin.isOfficial ? '1.0.0' : '',
  officialReleaseDateUtc: origin.isOfficial ? _stamp : '',
  officialChecksum: origin.isOfficial ? List.filled(64, 'a').join() : '',
  distributionChannel: origin.isOfficial ? 'bundled' : '',
  publisherVerificationStatus: origin.isOfficial
      ? PublisherVerificationStatus.verified
      : PublisherVerificationStatus.unverified,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'QQL 231 course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson_231',
      updatedAt: DateTime.parse(_stamp),
      title: 'Everyday Italian',
      rounds: [
        LearningRound(
          id: 'round_231',
          updatedAt: DateTime.parse(_stamp),
          title: 'Greetings',
          exercises: [
            Exercise(
              id: 'exercise_come_stai_231',
              updatedAt: DateTime.parse(_stamp),
              type: 'choice',
              prompt: 'Come stai oggi?',
              question: '',
              answers: const ['Bene', 'Male'],
              correct: 0,
              tts: null,
              accepted: const [],
              tokens: const [],
              orderAnswer: const [],
              pairs: const [],
              hint: '',
              icons: const [],
            ),
          ],
        ),
      ],
    ),
  ],
);

CourseAccessCapabilities _ownerAccess(Course course) =>
    CourseAccessPolicy.evaluate(course, profileId: ownerId);

Future<void> _profile(String id) async {
  SharedPreferences.setMockInitialValues({
    ProfileService.profilesKey: [
      LearnerProfile(
        learnerProfileId: id,
        displayName: id == ownerId ? 'Owner' : 'Other',
      ).encode(),
      LearnerProfile(
        learnerProfileId: id == ownerId ? otherId : ownerId,
        displayName: id == ownerId ? 'Other' : 'Owner',
      ).encode(),
    ],
    ProfileService.activeProfileIdKey: id,
  });
  EditorDisplayPreferences.resetForTesting();
}

Future<void> _openViewHierarchy(WidgetTester tester, Course course) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CourseEditorScreen(course: course, access: _ownerAccess(course)),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
  await tester.pumpAndSettle();
  expect(
    find.byKey(const Key('course-editor-view-mode-notice')),
    findsOneWidget,
  );
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async => _profile(ownerId));

  test(
    'view notice and lock mode are independently per user and course',
    () async {
      final settings = SettingsService();
      await settings.setCourseEditorMode('course_x', CourseEditorMode.locked);
      await settings.markCourseEditorViewNoticeSeen('course_x');
      expect(await settings.hasSeenCourseEditorViewNotice('course_x'), isTrue);
      expect(await settings.hasSeenCourseEditorViewNotice('course_y'), isFalse);

      await (await SharedPreferences.getInstance()).setString(
        ProfileService.activeProfileIdKey,
        otherId,
      );
      expect(await settings.hasSeenCourseEditorViewNotice('course_x'), isFalse);
      await settings.markCourseEditorViewNoticeSeen('course_x');
      await settings.resetOneTimeNotices();
      expect(await settings.hasSeenCourseEditorViewNotice('course_x'), isFalse);

      await (await SharedPreferences.getInstance()).setString(
        ProfileService.activeProfileIdKey,
        ownerId,
      );
      expect(await settings.hasSeenCourseEditorViewNotice('course_x'), isTrue);
      expect(
        await settings.getCourseEditorMode('course_x'),
        CourseEditorMode.locked,
      );
    },
  );

  testWidgets(
    'View only is default and Search navigates to normal read-only Exercise form',
    (tester) async {
      final course = _course();
      await _openViewHierarchy(tester, course);

      expect(find.byType(LessonManagementScreen), findsOneWidget);
      expect(find.byKey(const Key('lessons-search-action')), findsOneWidget);
      expect(find.byKey(const Key('lesson-management-lock')), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.byKey(const Key('lessons-search-action')));
      await tester.pumpAndSettle();
      expect(find.byType(CourseEditorSearchScreen), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('course-editor-search-query')),
        'oggi',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('course-editor-search-result-exercise_come_stai_231'),
        ),
        findsOneWidget,
      );
      expect(find.text('Exercise ID: exercise_come_stai_231'), findsNothing);
      await tester.tap(find.byTooltip('Internal IDs hidden. Tap to show'));
      await tester.pumpAndSettle();
      expect(find.text('Exercise ID: exercise_come_stai_231'), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey('course-editor-search-result-exercise_come_stai_231'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      expect(
        find.byKey(const Key('exercise-read-only-notice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('exercise-inspection-presentation')),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('exercise-save')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'Locked rejects structure entry and an outsider cannot select Edit',
    (tester) async {
      final course = _course();
      await SettingsService().setCourseEditorMode(
        course.courseId,
        CourseEditorMode.locked,
      );
      final outside = CourseAccessPolicy.evaluate(course, profileId: otherId);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(course: course, access: outside),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Course Editor is locked'), findsOneWidget);
      expect(find.byType(LessonManagementScreen), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('course-editor-lock')));
      await tester.pumpAndSettle();
      final editItem = tester.widget<PopupMenuItem<CourseEditorMode>>(
        find.ancestor(
          of: find.text('Edit'),
          matching: find.byType(PopupMenuItem<CourseEditorMode>),
        ),
      );
      expect(editItem.enabled, isFalse);
      expect(outside.effectiveEditDeniedReason, contains('Owner'));
    },
  );

  testWidgets('Edit normalizes page icons and Round actions', (tester) async {
    final course = _course();
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(course: course, access: _ownerAccess(course)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-editor-lock')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Course Info Editor'), findsOneWidget);

    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessons-search-action')), findsOneWidget);
    expect(find.byKey(const Key('lesson-management-lock')), findsNothing);
    await tester.tap(find.text('Lesson 1: Everyday Italian'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lesson-search-action')), findsOneWidget);
    expect(find.byTooltip('Rename lesson'), findsNothing);
    expect(find.byTooltip('Generate Rounds from GuideBook'), findsNothing);
    expect(find.byKey(const Key('lesson-title-control')), findsOneWidget);
    expect(find.byKey(const Key('guidebook-round-generator')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rounds-search-action')), findsOneWidget);
    await tester.tap(find.text('Greetings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('round-search-action')), findsOneWidget);
    expect(find.byTooltip('Preview round'), findsNothing);
    expect(find.byTooltip('Rename round'), findsNothing);
    expect(find.byKey(const Key('round-rename-action')), findsOneWidget);
    expect(find.byKey(const Key('round-preview')), findsOneWidget);
    expect(find.byKey(const Key('round-save-draft')), findsOneWidget);
    expect(find.byKey(const Key('round-save')), findsOneWidget);
  });

  testWidgets('Round Preview remains available throughout View only', (
    tester,
  ) async {
    final course = _course(courseId: 'view_preview_course');
    await _openViewHierarchy(tester, course);
    await tester.tap(find.text('Lesson 1: Everyday Italian'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lesson-search-action')), findsOneWidget);
    expect(find.byKey(const Key('save-lesson')), findsNothing);
    await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Greetings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('round-preview')), findsOneWidget);
    expect(find.byKey(const Key('round-save')), findsNothing);
    expect(
      tester
          .widget<ListTile>(find.byKey(const Key('round-rename-action')))
          .onTap,
      isNull,
    );
    await tester.tap(find.byKey(const Key('round-preview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(RoundScreen), findsOneWidget);
  });

  test(
    'Team membership, not Team Lead status, grants existing edit rights',
    () {
      final teamCourse = _course(
        courseId: 'team_course',
        ownership: const CourseOwnership.team(
          '00000000-0000-4000-8000-000000000233',
        ),
      );
      expect(
        CourseAccessPolicy.evaluate(
          teamCourse,
          profileId: otherId,
          memberTeamIds: const {'00000000-0000-4000-8000-000000000233'},
        ).canEditOriginal,
        isTrue,
      );
      expect(
        CourseAccessPolicy.evaluate(
          teamCourse,
          profileId: otherId,
        ).canEditOriginal,
        isFalse,
      );
    },
  );

  testWidgets('official Course remains searchable and read-only in View', (
    tester,
  ) async {
    await _profile(otherId);
    final course = _course(
      courseId: 'official_qql231',
      origin: CourseOriginType.bundledOfficial,
      ownership: null,
    );
    final access = CourseAccessPolicy.evaluate(course, profileId: otherId);
    await SettingsService().setCourseEditorMode(
      course.courseId,
      CourseEditorMode.edit,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(course: course, access: access),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Course Info'), findsOneWidget);
    expect(find.text('Course Info Editor'), findsNothing);
    expect(access.canEditOriginal, isFalse);
    await tester.tap(find.byKey(const Key('course-editor-lock')));
    await tester.pumpAndSettle();
    final editItem = tester.widget<PopupMenuItem<CourseEditorMode>>(
      find.ancestor(
        of: find.text('Edit'),
        matching: find.byType(PopupMenuItem<CourseEditorMode>),
      ),
    );
    expect(editItem.enabled, isFalse);
    await tester.tap(find.text('View only'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await tester.pumpAndSettle();
    expect(find.text('View only'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lessons-search-action')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
