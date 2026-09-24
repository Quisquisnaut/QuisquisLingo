import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_favorite_service.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

class _DeviceCourses extends CourseEditorService {
  _DeviceCourses(this.courses);

  final List<Course> courses;

  @override
  Future<List<Course>> listUserCourses() async => courses;
}

Course _course(
  String id,
  String title, {
  String source = 'English',
  String target = 'Italian',
  bool published = true,
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  courseVersion: '3',
  publicationState: published
      ? PublicationState.published
      : PublicationState.draft,
  learningLanguage: target,
  interfaceLanguage: source,
  sourceLanguage: source,
  targetLanguage: target,
  title: title,
  ttsLanguage: 'it-IT',
  lessons: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    final profiles = ProfileService();
    await profiles.createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await profiles.createProfile(
      'Bob',
      learnerProfileId: _bob,
      generateScreenNameSuffix: false,
    );
    await profiles.setActiveProfileById(_alice);
  });

  Future<void> showManager(
    WidgetTester tester,
    List<Course> courses, {
    bool showUnavailable = true,
  }) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseProjectsScreen(
            currentCourse: null,
            editorService: _DeviceCourses(courses),
            embedded: true,
            showUnavailable: showUnavailable,
          ),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('manager-section-0')).evaluate().isNotEmpty,
    );
  }

  testWidgets('Favorites contains only this learner’s library Courses', (
    tester,
  ) async {
    final amber = _course('amber', 'Amber Path');
    final blue = _course('blue', 'Blue Trail');
    final outside = _course('outside', 'Outside Course');
    await CourseLibraryService().add(amber);
    await CourseLibraryService().add(blue);
    await CourseFavoriteService().setFavorite(amber.courseId, true);
    await CourseFavoriteService().setFavorite(outside.courseId, true);
    await ProfileService().setActiveProfileById(_bob);
    await CourseFavoriteService().setFavorite(blue.courseId, true);
    await ProfileService().setActiveProfileById(_alice);

    await showManager(tester, [amber, blue, outside]);

    expect(find.byKey(const Key('manager-section-favorites')), findsOneWidget);
    expect(find.byKey(const Key('manager-favorite-amber')), findsOneWidget);
    expect(find.byKey(const Key('manager-favorite-blue')), findsNothing);
    expect(find.byKey(const Key('manager-favorite-outside')), findsNothing);
    expect(find.byKey(const Key('manager-course-amber')), findsOneWidget);
    expect(find.byKey(const Key('manager-course-blue')), findsOneWidget);
    expect(find.byKey(const Key('manager-course-outside')), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('manager-section-favorites'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('manager-section-0'))).dy,
      ),
    );
  });

  testWidgets(
    'Favorite duplicates keep status and actions, with own view mode',
    (tester) async {
      final amber = _course('amber', 'Amber Path', published: false);
      await CourseLibraryService().add(amber);
      await CourseFavoriteService().setFavorite(amber.courseId, true);
      await showManager(tester, [amber]);

      final favorite = find.byKey(const Key('manager-favorite-amber'));
      final ordinary = find.byKey(const Key('manager-course-amber'));
      expect(
        find.descendant(of: favorite, matching: find.text('Unpublished')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: ordinary, matching: find.text('Unpublished')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: favorite, matching: find.text('Version: 3')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('manager-section-view-favorites')));
      await tester.pump();
      expect(
        find.descendant(of: favorite, matching: find.text('Version: 3')),
        findsNothing,
      );
      expect(
        find.descendant(of: ordinary, matching: find.text('Version: 3')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('course-manager-actions-favorite-amber')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hide in Learner'), findsOneWidget);
      expect(find.text('Audit'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-manager-actions-amber')));
      await tester.pumpAndSettle();
      expect(find.text('Hide in Learner'), findsOneWidget);
      expect(find.text('Audit'), findsOneWidget);
    },
  );

  testWidgets('Show unavailable filters Favorite and ordinary copies', (
    tester,
  ) async {
    final amber = _course('amber', 'Amber Path', published: false);
    await CourseLibraryService().add(amber);
    await CourseFavoriteService().setFavorite(amber.courseId, true);
    await showManager(tester, [amber], showUnavailable: false);

    expect(find.byKey(const Key('manager-section-favorites')), findsOneWidget);
    expect(find.byKey(const Key('manager-favorite-amber')), findsNothing);
    expect(find.byKey(const Key('manager-course-amber')), findsNothing);
    expect(find.textContaining('0 of 1 shown'), findsNWidgets(2));
  });

  testWidgets('Favorites Compact survives a Course Studio data reload', (
    tester,
  ) async {
    final amber = _course('amber', 'Amber Path');
    await CourseLibraryService().add(amber);
    await CourseFavoriteService().setFavorite(amber.courseId, true);
    await showManager(tester, [amber]);

    final favorite = find.byKey(const Key('manager-favorite-amber'));
    await tester.tap(find.byKey(const Key('manager-section-view-favorites')));
    await tester.pump();
    expect(
      find.descendant(of: favorite, matching: find.text('Version: 3')),
      findsNothing,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseProjectsScreen(
            currentCourse: null,
            editorService: _DeviceCourses([amber]),
            embedded: true,
            refreshToken: 1,
          ),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(() => favorite.evaluate().isNotEmpty);
    expect(
      find.descendant(of: favorite, matching: find.text('Version: 3')),
      findsNothing,
    );
  });

  testWidgets(
    'Search filters Manager Favorites and sections by language and title',
    (tester) async {
      final amber = _course('amber', 'Amber Path', target: 'Italian');
      final blue = _course(
        'blue',
        'Blue Trail',
        source: 'Spanish',
        target: 'French',
      );
      final cobalt = _course(
        'cobalt',
        'Cobalt Path',
        source: 'Italian',
        target: 'Portuguese',
      );
      for (final course in [amber, blue, cobalt]) {
        await CourseLibraryService().add(course);
      }
      await CourseFavoriteService().setFavorite(amber.courseId, true);
      await SettingsService().setCourseEditorUnlocked(true);
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CoursesScreen(
            editorService: _DeviceCourses([amber, blue, cobalt]),
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.byKey(const Key('courses-search')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('courses-search')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('courses-search-field')),
        ' iTaLiAn ',
      );
      await tester.tap(find.byKey(const Key('courses-tab-manager')));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('manager-section-favorites'))
            .evaluate()
            .isNotEmpty,
      );

      expect(find.byKey(const Key('manager-favorite-amber')), findsOneWidget);
      expect(find.byKey(const Key('manager-course-amber')), findsOneWidget);
      expect(find.byKey(const Key('manager-course-cobalt')), findsOneWidget);
      expect(find.byKey(const Key('manager-course-blue')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('courses-search-field')),
        ' bLuE ',
      );
      await tester.pump();
      expect(find.byKey(const Key('manager-favorite-amber')), findsNothing);
      expect(find.byKey(const Key('manager-course-amber')), findsNothing);
      expect(find.byKey(const Key('manager-course-cobalt')), findsNothing);
      expect(find.byKey(const Key('manager-course-blue')), findsOneWidget);
    },
  );
}
