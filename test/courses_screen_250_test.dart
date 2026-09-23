import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_favorite_service.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _alice = '11111111-1111-4111-8111-111111111111';

class _DeviceCourses extends CourseEditorService {
  _DeviceCourses(this.courses);
  final List<Course> courses;

  @override
  Future<List<Course>> listUserCourses() async => courses;
}

Course _course({bool unpublished = false}) => Course(
  courseId: 'two_tabs',
  originType: CourseOriginType.custom,
  courseVersion: '3',
  publicationState: unpublished
      ? PublicationState.draft
      : PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Two Tabs Course',
  ttsLanguage: 'it-IT',
  lessons: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await ProfileService().setActiveProfileById(_alice);
  });

  testWidgets('one Courses screen shares the row and controls across tabs', (
    tester,
  ) async {
    final course = _course();
    await CourseLibraryService().add(course);
    await SettingsService().setCourseEditorUnlocked(true);
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: CoursesScreen(editorService: _DeviceCourses([course]))),
    );
    await tester.pumpUntilFileIoState(
      () => find.text('Bundled Courses').evaluate().isNotEmpty,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('device-course-two_tabs')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Courses'), findsOneWidget);
    expect(
      tester
          .widget<Switch>(find.byKey(const Key('show-unavailable-courses')))
          .value,
      isTrue,
    );
    expect(find.byKey(const Key('device-course-two_tabs')), findsOneWidget);
    await tester.tap(find.byKey(const Key('courses-tab-manager')));
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('manager-section-0')).evaluate().isNotEmpty,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('manager-course-two_tabs')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    final managerRow = find.byKey(const Key('manager-course-two_tabs'));
    expect(
      find.descendant(of: managerRow, matching: find.text('Two Tabs Course')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: managerRow, matching: find.text('English → Italian')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: managerRow, matching: find.text('Version: 3')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('show-unavailable-courses')), findsOneWidget);
  });

  testWidgets('locked Course Manager stays visible and explains its unlock', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CoursesScreen(editorService: _DeviceCourses([]))),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('courses-tab-manager')).evaluate().isNotEmpty,
    );
    await tester.tap(find.byKey(const Key('courses-tab-manager')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.textContaining('Tap Version in Settings ten times'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('courses-tab-all-selected')), findsOneWidget);
  });

  testWidgets('a library Course can be hidden and unhidden in its row menu', (
    tester,
  ) async {
    final course = _course();
    await CourseLibraryService().add(course);
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: CoursesScreen(editorService: _DeviceCourses([course]))),
    );
    await tester.pumpUntilFileIoState(
      () => find.text('Bundled Courses').evaluate().isNotEmpty,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('device-course-two_tabs')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pump();
    await tester.tap(find.byKey(const Key('all-course-actions-two_tabs')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide in Learner'));
    await tester.pumpUntilFileIoState(
      () => find.text('Hidden in Learner').evaluate().isNotEmpty,
    );
    expect(find.text('Hidden in Learner'), findsOneWidget);
    await tester.tap(find.byKey(const Key('all-course-actions-two_tabs')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unhide in Learner'));
    await tester.pumpUntilFileIoState(
      () => find.text('Hidden in Learner').evaluate().isEmpty,
    );
    expect(find.text('Hidden in Learner'), findsNothing);
  });

  testWidgets('Favorites is a filtered shortcut even outside the library', (
    tester,
  ) async {
    await CourseFavoriteService().setFavorite('two_tabs', true);
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CoursesScreen(editorService: _DeviceCourses([_course()])),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const Key('favorite-course-two_tabs'))
          .evaluate()
          .isNotEmpty,
    );
    final favorite = find.byKey(const Key('favorite-course-two_tabs'));
    expect(
      find.descendant(of: favorite, matching: find.text('Add to my courses')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('course-section-count-favorites')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('courses-search')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('courses-search-field')),
      'Spanish',
    );
    await tester.pump();
    expect(find.byKey(const Key('favorite-course-two_tabs')), findsNothing);
    expect(find.text(' · 0 of 1 shown'), findsWidgets);
  });

  testWidgets('Favorites popup keeps normal menu contrast', (tester) async {
    await CourseFavoriteService().setFavorite('two_tabs', true);
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CoursesScreen(editorService: _DeviceCourses([_course()])),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const Key('favorite-course-two_tabs'))
          .evaluate()
          .isNotEmpty,
    );
    final pageOnSurface = Theme.of(
      tester.element(find.byKey(const Key('courses-search'))),
    ).colorScheme.onSurface;
    await tester.tap(
      find.byKey(const Key('all-course-actions-two_tabs')).first,
    );
    await tester.pumpAndSettle();
    final menuOnSurface = Theme.of(
      tester.element(find.text('Course Info')),
    ).colorScheme.onSurface;
    expect(menuOnSurface, pageOnSurface);
  });

  testWidgets('Manager uses one Unpublished label with its Audit border', (
    tester,
  ) async {
    final course = _course(unpublished: true);
    await CourseLibraryService().add(course);
    await SettingsService().setCourseEditorUnlocked(true);
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: CoursesScreen(editorService: _DeviceCourses([course]))),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('courses-tab-manager')).evaluate().isNotEmpty,
    );
    await tester.tap(find.byKey(const Key('courses-tab-manager')));
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('manager-section-0')).evaluate().isNotEmpty,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('manager-course-two_tabs')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('course-manager-status-two_tabs')),
        matching: find.text('Unpublished'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('import return reveals and highlights an unavailable Course', (
    tester,
  ) async {
    final course = _course(unpublished: true);
    await tester.binding.setSurfaceSize(const Size(900, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: CoursesScreen(editorService: _DeviceCourses([course]))),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('courses-search')).evaluate().isNotEmpty,
    );
    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('courses-search')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('courses-search-field')),
      'Spanish',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('courses-import')));
    await tester.pumpUntilFileIoState(
      () => find.text('Course Import').evaluate().isNotEmpty,
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop(course);
    await tester.pumpUntilFileIoState(
      () =>
          find
              .byKey(const Key('courses-tab-all-selected'))
              .evaluate()
              .isNotEmpty &&
          tester
              .widget<Switch>(find.byKey(const Key('show-unavailable-courses')))
              .value,
    );
    expect(find.byKey(const Key('courses-search-field')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('device-course-two_tabs')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('device-course-two_tabs')), findsOneWidget);
  });
}
