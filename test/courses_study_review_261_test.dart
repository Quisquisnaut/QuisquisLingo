import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/courses_screen.dart';
import 'package:quisquislingo_app/screens/do_not_disturb_settings_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/review_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_editor_device_state.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/course_study.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 261 Revision 1 (owner decisions of 1 October 2026): Study and Review
/// in the Course menus of All Courses and Course Studio, and the Course
/// Editor opening mode in Do Not Disturb.
const _alice = '11111111-1111-4111-8111-111111111261';
const _laboratoryId = 'course_50d68435-d2c2-4b63-9a0b-b23161357f1d';
const _englishId = 'course_65dce83b-fd0a-4b83-a5a1-8f8b97a58d05';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final profiles = ProfileService();
  final library = CourseLibraryService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await profiles.createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await profiles.setActiveProfileById(_alice);
  });

  group('Study and Review reasons', () {
    test(
      'a published bundled Course can be studied; Review needs a Round',
      () async {
        final course = await CourseService().loadCourse('EN_IT');
        expect(
          CourseStudy.studyUnavailableReason(course, hasLearner: true),
          isNull,
        );
        expect(
          CourseStudy.studyUnavailableReason(course, hasLearner: false),
          'Select a learner profile first.',
        );
        expect(
          CourseStudy.reviewUnavailableReason(
            course,
            hasLearner: true,
            hasCompletedRounds: false,
          ),
          'Complete a Round of this Course first.',
        );
        expect(
          CourseStudy.reviewUnavailableReason(
            course,
            hasLearner: true,
            hasCompletedRounds: true,
          ),
          isNull,
        );
        final unpublished = Course.fromJson({
          ...course.toJson(),
          'publicationState': 'draft',
        });
        expect(
          CourseStudy.studyUnavailableReason(unpublished, hasLearner: true),
          'Publish this Course before you can study it.',
        );
      },
    );

    test('completed Rounds are read from the Review records', () async {
      await ProgressService().recordRecentRound(
        _englishId,
        'enit_65dce83b_l01',
        'enit_65dce83b_l01_r01',
        errors: 1,
      );
      expect(await CourseStudy.coursesWithCompletedRounds(ProgressService()), {
        _englishId,
      });
    });

    test(
      'Course Studio offers Study and Review apart from its entries',
      () async {
        final course = await CourseService().loadCourse('EN_IT');
        final reviewable = CourseManagerLibrary(
          activeProfileId: _alice,
          reviewableCourseIds: {_englishId},
        );
        expect(
          reviewable.studyEntriesFor(course).map((entry) => entry.action),
          [CourseManagerAction.study, CourseManagerAction.review],
        );
        expect(
          reviewable.studyEntriesFor(course).every((entry) => entry.available),
          isTrue,
        );
        const fresh = CourseManagerLibrary(activeProfileId: _alice);
        expect(
          fresh.studyEntriesFor(course).last.unavailableReason,
          'Complete a Round of this Course first.',
        );
        expect(
          fresh
              .entriesFor(course)
              .map((entry) => entry.action)
              .where(
                (action) =>
                    action == CourseManagerAction.study ||
                    action == CourseManagerAction.review,
              ),
          isEmpty,
        );
      },
    );
  });

  group('Course Editor opening mode', () {
    test('View only until chosen; a first opening remembers it', () async {
      final settings = SettingsService();
      final state = CourseEditorDeviceState();
      expect(
        await settings.getCourseEditorOpeningMode(),
        CourseEditorMode.viewOnly,
      );
      await settings.setCourseEditorOpeningMode(CourseEditorMode.edit);
      expect(
        await state.openingMode('first', canEditOriginal: true),
        CourseEditorMode.edit,
      );
      // Edit opens as View only without editing rights.
      expect(
        await state.openingMode('other', canEditOriginal: false),
        CourseEditorMode.viewOnly,
      );

      // A later default leaves Courses already opened alone.
      await settings.setCourseEditorOpeningMode(CourseEditorMode.locked);
      expect(
        await state.openingMode('first', canEditOriginal: true),
        CourseEditorMode.edit,
      );
      expect(
        await state.openingMode('other', canEditOriginal: true),
        CourseEditorMode.edit,
      );
      expect(
        await state.openingMode('never-opened', canEditOriginal: true),
        CourseEditorMode.locked,
      );
      // A mode chosen in the editor still wins.
      await state.setMode('first', CourseEditorMode.inspection);
      expect(
        await state.openingMode('first', canEditOriginal: true),
        CourseEditorMode.inspection,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          profiles.keyForProfileId(
            _alice,
            SettingsService.courseEditorOpeningModeKey,
          ),
        ),
        'locked',
      );
    });

    test('a legacy lock value keeps its meaning', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('course_editor_locked_LEGACY', false);
      await SettingsService().setCourseEditorOpeningMode(
        CourseEditorMode.locked,
      );
      expect(
        await CourseEditorDeviceState().openingMode(
          'legacy',
          canEditOriginal: true,
        ),
        CourseEditorMode.edit,
      );
    });

    testWidgets('Do Not Disturb sets the opening mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: DoNotDisturbSettingsScreen()),
      );
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('course-editor-opening-mode'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('Course Editor opening mode'), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-editor-opening-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inspection mode').last);
      await tester.pumpUntilFileIoState(() => true);
      expect(
        await tester.runAsync(SettingsService().getCourseEditorOpeningMode),
        CourseEditorMode.inspection,
      );
    });
  });

  group('Study and Review from Courses', () {
    Future<void> openEmptyHome(WidgetTester tester) async {
      await tester.runAsync(() async {
        final settings = SettingsService();
        await settings.completeWelcomeWizard();
        await settings.markOneTimeNoticeSeen(
          'welcome_${AppMetadata.technicalVersion}',
        );
        await settings.setAnimationsEnabled(false);
        for (final code in CourseService.courseAssets.keys) {
          await library.remove(await CourseService().loadCourse(code));
        }
      });
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpUntilFileIoState(
        () => find
            .text('No courses available for study in your library.')
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.text('All Courses'));
      await tester.pumpUntilFileIoState(
        () => find.text('Bundled Courses').evaluate().isNotEmpty,
      );
    }

    Future<void> openMenu(WidgetTester tester, String courseId) async {
      final menu = find.byKey(ValueKey('all-course-actions-$courseId'));
      await tester.scrollUntilVisible(menu, 250);
      await tester.tap(menu);
      await tester.pumpAndSettle();
    }

    testWidgets('Study adds the Course, makes it current, opens it', (
      tester,
    ) async {
      await openEmptyHome(tester);
      await openMenu(tester, _laboratoryId);
      final review = tester.widget<PopupMenuItem<String>>(
        find.byKey(const ValueKey('all-course-action-review')),
      );
      expect(review.enabled, isFalse);
      expect(
        find.text('Complete a Round of this Course first.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('all-course-action-study')));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('unified-topbar-course-selector'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.byType(CoursesScreen), findsNothing);
      final laboratory = await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      );
      expect(
        await tester.runAsync(() => library.contains(laboratory!)),
        isTrue,
      );
      expect(
        await tester.runAsync(SettingsService().getLastSelectedCourseCode),
        'IT',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Review makes the Course current and opens Review', (
      tester,
    ) async {
      await tester.runAsync(
        () => ProgressService().recordRecentRound(
          _englishId,
          'enit_65dce83b_l01',
          'enit_65dce83b_l01_r01',
          errors: 2,
        ),
      );
      await openEmptyHome(tester);
      await openMenu(tester, _englishId);
      await tester.tap(find.byKey(const ValueKey('all-course-action-review')));
      await tester.pumpUntilFileIoState(
        () => find.byType(ReviewScreen).evaluate().isNotEmpty,
      );
      expect(
        tester.widget<ReviewScreen>(find.byType(ReviewScreen)).course.courseId,
        _englishId,
      );
      expect(
        await tester.runAsync(SettingsService().getLastSelectedCourseCode),
        'EN_IT',
      );
    });

    testWidgets('Course Studio closes Courses with the request', (
      tester,
    ) async {
      await tester.runAsync(
        () => SettingsService().setCourseEditorUnlocked(true),
      );
      final results = <CourseStudyRequest?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async => results.add(
                    await Navigator.of(context).push<CourseStudyRequest>(
                      MaterialPageRoute(
                        builder: (_) =>
                            const CoursesScreen(initialTab: CoursesTab.manager),
                      ),
                    ),
                  ),
                  child: const Text('Open Courses'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Courses'));
      final menu = find.byKey(
        const ValueKey('course-manager-actions-$_englishId'),
      );
      await tester.pumpUntilFileIoState(() => menu.evaluate().isNotEmpty);
      await tester.scrollUntilVisible(
        menu,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('course-manager-unavailable-review')),
        findsOneWidget,
      );
      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();
      expect(results, hasLength(1));
      expect(results.single!.course.courseId, _englishId);
      expect(results.single!.action, CourseStudyAction.study);
    });
  });
}
