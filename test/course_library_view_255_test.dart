import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_categories.dart';
import 'package:quisquislingo_app/services/course_library_view_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/course_library_fixtures.dart';
import 'support/edge_case_fixture.dart';
import 'support/pump_file_io.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _allCourses = 'all_courses';
const _courseStudio = 'course_studio';

class _DeviceCourses extends CourseEditorService {
  _DeviceCourses(this.courses);

  final List<Course> courses;

  @override
  Future<List<Course>> listUserCourses() async => courses;
}

/// Build 255 Revision 6: Courses sections gain Minimal, and each learner's
/// Expanded / Compact / Minimal choice is saved per tab and category.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clean = draftStatusCourse(courseId: 'user_clean', title: 'Clean');

  setUp(() async {
    registerEdgeCaseFixture();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    final profiles = ProfileService();
    for (final (id, name) in [(_alice, 'Alice'), (_bob, 'Bob')]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    await profiles.setActiveProfileById(_alice);
  });

  group('CourseLibraryViewService', () {
    test('the button order is Expanded, Compact, Minimal and back', () {
      expect(CourseLibraryView.expanded.next, CourseLibraryView.compact);
      expect(CourseLibraryView.compact.next, CourseLibraryView.minimal);
      expect(CourseLibraryView.minimal.next, CourseLibraryView.expanded);
      expect(
        CourseLibraryView.fromStorage('minimal'),
        CourseLibraryView.minimal,
      );
      expect(CourseLibraryView.fromStorage(null), CourseLibraryView.expanded);
      expect(
        CourseLibraryView.fromStorage('unknown'),
        CourseLibraryView.expanded,
      );
    });

    test('views are saved per learner, tab and category', () async {
      final service = CourseLibraryViewService();
      final defaults = await service.views(_allCourses);
      expect(defaults, hasLength(CourseLibraryCategory.values.length));
      expect(defaults.values.toSet(), {CourseLibraryView.expanded});

      await service.setView(
        _allCourses,
        CourseLibraryCategory.otherLocal,
        CourseLibraryView.minimal,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(
          '${ProfileService.prefixForProfileId(_alice)}'
          'course_library_view_all_courses_other_local',
        ),
        'minimal',
      );
      final aliceAll = await service.views(_allCourses);
      expect(
        aliceAll[CourseLibraryCategory.otherLocal],
        CourseLibraryView.minimal,
      );
      expect(
        aliceAll[CourseLibraryCategory.bundled],
        CourseLibraryView.expanded,
      );
      final aliceStudio = await service.views(_courseStudio);
      expect(
        aliceStudio[CourseLibraryCategory.otherLocal],
        CourseLibraryView.expanded,
      );
      final bobAll = await service.views(_allCourses, profileId: _bob);
      expect(
        bobAll[CourseLibraryCategory.otherLocal],
        CourseLibraryView.expanded,
      );
    });

    test('without an active learner nothing is read or written', () async {
      await ProfileService().clearActiveProfile();
      final service = CourseLibraryViewService();
      await service.setView(
        _allCourses,
        CourseLibraryCategory.bundled,
        CourseLibraryView.compact,
      );
      expect(await service.views(_allCourses), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((key) => key.contains('course_library_view_')),
        isEmpty,
      );
    });

    test('the setting follows learner backups and survives progress reset', () {
      for (final tab in [_allCourses, _courseStudio]) {
        for (final category in CourseLibraryCategory.values) {
          final suffix = CourseLibraryViewService.suffix(tab, category);
          // Learner backups carry every learner key with a plain suffix.
          expect(suffix, matches(RegExp(r'^[A-Za-z0-9_.:-]{1,160}$')));
          // Resetting progress keeps learner settings.
          expect(
            AppResetService.progressSuffixPatterns.any(suffix.startsWith),
            isFalse,
            reason: suffix,
          );
        }
      }
    });
  });

  group('All Courses', () {
    Finder section(int index) => find.byKey(ValueKey('course-section-$index'));
    Finder inSection(int index, Finder matching) =>
        find.descendant(of: section(index), matching: matching);
    Finder toggle(int index) =>
        find.byKey(ValueKey('course-section-view-$index'));
    String count(WidgetTester tester, int index) => tester
        .widget<Text>(find.byKey(ValueKey('course-section-count-$index')))
        .data!;

    Future<void> pumpLibrary(
      WidgetTester tester, {
      String? highlightCourseId,
    }) async {
      await tester.binding.setSurfaceSize(const Size(800, 8000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: AvailableCoursesScreen(
            editorService: _DeviceCourses([clean]),
            highlightCourseId: highlightCourseId,
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.text('Bundled Courses').evaluate().isNotEmpty,
      );
    }

    testWidgets('Minimal shows only the count, and the choice is kept', (
      tester,
    ) async {
      await pumpLibrary(tester);
      expect(inSection(3, find.text('Expanded')), findsOneWidget);
      expect(count(tester, 3), ' · 1');

      await tester.tap(toggle(3));
      await tester.pump();
      expect(inSection(3, find.text('Compact')), findsOneWidget);
      await tester.tap(toggle(3));
      await tester.pump();
      expect(inSection(3, find.text('Minimal')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('device-course-user_clean')),
        findsNothing,
      );
      expect(inSection(3, find.text('English → Italian')), findsNothing);
      // Minimal always gives both numbers: shown and total.
      expect(count(tester, 3), ' · 1 of 1 shown');
      // Other sections are unaffected.
      expect(inSection(0, find.text('Expanded')), findsOneWidget);
      expect(inSection(0, find.textContaining('Maintainer: ')), findsWidgets);

      // A new visit restores the saved view.
      await pumpLibrary(tester);
      expect(inSection(3, find.text('Minimal')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('device-course-user_clean')),
        findsNothing,
      );
      expect(inSection(0, find.text('Expanded')), findsOneWidget);

      // Another learner has their own views.
      await ProfileService().setActiveProfileById(_bob);
      await pumpLibrary(tester);
      expect(inSection(3, find.text('Expanded')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('device-course-user_clean')),
        findsOneWidget,
      );

      await ProfileService().setActiveProfileById(_alice);
      await pumpLibrary(tester);
      await tester.tap(toggle(3));
      await tester.pump();
      expect(inSection(3, find.text('Expanded')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('device-course-user_clean')),
        findsOneWidget,
      );
    });

    testWidgets('a hidden Course counts toward the Minimal total', (
      tester,
    ) async {
      await pumpLibrary(tester);
      for (var tap = 0; tap < 2; tap++) {
        await tester.tap(toggle(0));
        await tester.pump();
      }
      // The Edge Case demo has Draft content, so it is unavailable (three
      // bundled demos and the fixture since Build 259 Revision 6).
      expect(count(tester, 0), ' · 3 of 4 shown');
      await tester.tap(find.byKey(const Key('show-unavailable-courses')));
      await tester.pump();
      expect(count(tester, 0), ' · 4 of 4 shown');
      expect(
        find.byKey(
          const ValueKey(
            'device-course-course_50d68435-d2c2-4b63-9a0b-b23161357f1d',
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('an imported Course is shown even in a Minimal section', (
      tester,
    ) async {
      await CourseLibraryViewService().setView(
        _allCourses,
        CourseLibraryCategory.otherLocal,
        CourseLibraryView.minimal,
      );
      await pumpLibrary(tester, highlightCourseId: clean.courseId);
      expect(inSection(3, find.text('Expanded')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('device-course-user_clean')),
        findsOneWidget,
      );
      final saved = await CourseLibraryViewService().views(_allCourses);
      expect(
        saved[CourseLibraryCategory.otherLocal],
        CourseLibraryView.minimal,
      );

      // Choosing a view ends the exception.
      await tester.tap(toggle(3));
      await tester.pump();
      expect(inSection(3, find.text('Compact')), findsOneWidget);
      await tester.tap(toggle(3));
      await tester.pump();
      expect(inSection(3, find.text('Minimal')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('device-course-user_clean')),
        findsNothing,
      );
    });
  });

  testWidgets('Course Studio keeps its own saved views', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await CourseLibraryViewService().setView(
      _allCourses,
      CourseLibraryCategory.bundled,
      CourseLibraryView.minimal,
    );
    Future<void> showManager() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseProjectsScreen(
              currentCourse: null,
              editorService: _DeviceCourses(const []),
              embedded: true,
              showUnavailable: true,
            ),
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const ValueKey('manager-section-view-0'))
            .evaluate()
            .isNotEmpty,
      );
    }

    await showManager();
    final bundled = find.byKey(const ValueKey('manager-section-0'));
    expect(
      find.descendant(of: bundled, matching: find.text('Expanded')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('manager-section-view-0')));
    await tester.pump();
    expect(
      find.descendant(of: bundled, matching: find.text('Compact')),
      findsOneWidget,
    );

    await showManager();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('manager-section-0')),
        matching: find.text('Compact'),
      ),
      findsOneWidget,
    );
    final saved = await CourseLibraryViewService().views(_allCourses);
    expect(saved[CourseLibraryCategory.bundled], CourseLibraryView.minimal);
  });
}
