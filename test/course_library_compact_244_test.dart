import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/course_library_fixtures.dart';
import 'support/pump_file_io.dart';

const _alice = '11111111-1111-4111-8111-111111111111';

class _DeviceCourses extends CourseEditorService {
  final List<Course> courses;
  _DeviceCourses(this.courses);
  @override
  Future<List<Course>> listUserCourses() async => courses;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final clean = draftStatusCourse(courseId: 'user_clean', title: 'Clean');
  final withDraft = draftStatusCourse(
    courseId: 'user_with_draft',
    title: 'With Draft',
    exercise: PublicationState.draft,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await ProfileService().setActiveProfileById(_alice);
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    Size size = const Size(800, 8000),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AvailableCoursesScreen(
          editorService: _DeviceCourses([clean, withDraft]),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.text('Bundled Courses').evaluate().isNotEmpty,
    );
  }

  Finder section(int index) => find.byKey(ValueKey('course-section-$index'));
  Finder inSection(int index, Finder matching) =>
      find.descendant(of: section(index), matching: matching);
  Finder toggle(int index) =>
      find.byKey(ValueKey('course-section-view-$index'));

  testWidgets('every section starts Expanded', (tester) async {
    await pumpLibrary(tester);
    for (var i = 0; i < 4; i++) {
      expect(inSection(i, find.text('Expanded')), findsOneWidget);
    }
    expect(inSection(0, find.textContaining('Maintainer: ')), findsWidgets);
    expect(inSection(3, find.textContaining('Maintainer: ')), findsWidgets);
  });

  testWidgets('Compact applies to its own section only and reverts', (
    tester,
  ) async {
    await pumpLibrary(tester);
    await tester.tap(toggle(3));
    await tester.pump();
    expect(inSection(3, find.text('Compact')), findsOneWidget);
    for (final prefix in ['Maintainer: ', 'Last edited: ', 'Version: ']) {
      expect(inSection(3, find.textContaining(prefix)), findsNothing);
    }
    expect(inSection(3, find.text('English → Italian')), findsOneWidget);
    expect(inSection(3, find.text('Add to my courses')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('course-artwork-user_clean'))),
      const Size(40, 40),
    );
    // Other sections are unaffected.
    expect(inSection(0, find.text('Expanded')), findsOneWidget);
    expect(inSection(0, find.textContaining('Maintainer: ')), findsWidgets);

    await tester.tap(toggle(0));
    await tester.pump();
    expect(inSection(0, find.textContaining('Maintainer: ')), findsNothing);

    await tester.tap(toggle(3));
    await tester.pump();
    expect(inSection(3, find.textContaining('Maintainer: ')), findsWidgets);
    expect(inSection(0, find.textContaining('Maintainer: ')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('course-artwork-user_clean'))),
      const Size(64, 64),
    );
  });

  testWidgets('status labels stay visible in Compact rows', (tester) async {
    await pumpLibrary(tester);
    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    await tester.tap(toggle(3));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(ValueKey('device-course-${withDraft.courseId}')),
        matching: find.text('Draft'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('narrow Compact and Expanded sections do not overflow', (
    tester,
  ) async {
    await pumpLibrary(tester, size: const Size(320, 8000));
    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.tap(toggle(i));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });
}
