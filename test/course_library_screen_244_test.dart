import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_draft_status.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/course_library_fixtures.dart';
import 'support/pump_file_io.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _draft = PublicationState.draft;

class _DeviceCourses extends CourseEditorService {
  final List<Course> courses;
  _DeviceCourses(this.courses);
  @override
  Future<List<Course>> listUserCourses() async => courses;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Course unverified;

  final clean = draftStatusCourse(
    courseId: 'user_clean',
    title: 'Clean Course',
  );
  final unpublished = draftStatusCourse(
    courseId: 'user_unpublished',
    title: 'Unpublished Course',
    course: _draft,
  );
  final withDraft = draftStatusCourse(
    courseId: 'user_with_draft',
    title: 'Course with Draft',
    exercise: _draft,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await ProfileService().setActiveProfileById(_alice);
    final signed = Course.fromJson(
      jsonDecode(
            await File(
              'test/fixtures/publishers/dummy-signed-v1.json',
            ).readAsString(),
          )
          as Map<String, dynamic>,
    );
    unverified = Course.fromJson({
      ...signed.toJson(),
      'publisherVerificationStatus': 'unverified',
    });
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    Uri? webSite,
    Future<bool> Function(Uri)? launch,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: AvailableCoursesScreen(
          editorService: _DeviceCourses([
            clean,
            unpublished,
            withDraft,
            unverified,
          ]),
          courseWebSite: webSite,
          launchWebSite: launch,
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.text('Bundled Courses').evaluate().isNotEmpty,
    );
  }

  Finder row(Course course) =>
      find.byKey(ValueKey('device-course-${course.courseId}'));

  testWidgets('the page is called Course Library', (tester) async {
    await pumpLibrary(tester);
    expect(find.text('Course Library'), findsOneWidget);
    expect(find.text('Available on this device'), findsNothing);
    expect(find.text('Show unavailable'), findsOneWidget);
  });

  testWidgets('by default unavailable and Draft Courses are hidden', (
    tester,
  ) async {
    await pumpLibrary(tester);
    expect(row(clean), findsOneWidget);
    expect(row(unpublished), findsNothing);
    expect(row(withDraft), findsNothing);
    expect(row(unverified), findsNothing);
    final show = tester.widget<Switch>(
      find.byKey(const Key('show-unavailable-courses')),
    );
    expect(show.value, isFalse);
  });

  testWidgets('the switch reveals each hidden Course with its badges', (
    tester,
  ) async {
    await pumpLibrary(tester);
    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    expect(row(clean), findsOneWidget);
    Finder badge(Course course, String label) =>
        find.descendant(of: row(course), matching: find.text(label));
    expect(badge(unpublished, 'Unpublished'), findsOneWidget);
    expect(badge(unpublished, 'Draft'), findsNothing);
    expect(badge(withDraft, 'Draft'), findsOneWidget);
    expect(badge(withDraft, 'Unpublished'), findsNothing);
    expect(badge(unverified, 'Verification required'), findsOneWidget);
    for (final label in ['Draft', 'Unpublished', 'Verification required']) {
      expect(badge(clean, label), findsNothing);
    }

    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    expect(row(unpublished), findsNothing);
  });

  testWidgets('the switch never changes membership or Course state', (
    tester,
  ) async {
    final library = CourseLibraryService();
    final all = [clean, unpublished, withDraft, unverified];
    final before = await tester.runAsync(
      () async => (await library.included(all)).map((c) => c.courseId).toSet(),
    );
    final jsonBefore = [for (final c in all) jsonEncode(c.toJson())];
    await pumpLibrary(tester);
    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    final after = await tester.runAsync(
      () async => (await library.included(all)).map((c) => c.courseId).toSet(),
    );
    expect(after, before);
    expect([for (final c in all) jsonEncode(c.toJson())], jsonBefore);
  });

  String count(WidgetTester tester, int section) => tester
      .widget<Text>(find.byKey(ValueKey('course-section-count-$section')))
      .data!;

  testWidgets('four separate sections in fixed order with counts', (
    tester,
  ) async {
    await pumpLibrary(tester);
    final tops = [
      for (var i = 0; i < 4; i++)
        tester.getTopLeft(find.byKey(ValueKey('course-section-$i'))).dy,
    ];
    expect(tops, [...tops]..sort());
    for (final (i, label) in [
      'Bundled Courses',
      'Publisher Courses',
      'My Local Courses',
      'Other Local Courses',
    ].indexed) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('course-section-$i')),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
    final bundled = CourseService.courseAssets.length;
    expect(count(tester, 0), ' · $bundled');
    expect(count(tester, 1), ' · 0 of 1 shown');
    expect(count(tester, 2), ' · 0');
    // Detached test Courses belong to no local profile: Other Local Courses.
    expect(count(tester, 3), ' · 1 of 3 shown');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('course-section-1')),
        matching: find.textContaining(
          'No Courses are shown in this section. Turn on Show unavailable to see them.',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('course-section-2')),
        matching: find.text('No courses in this section.'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('show-unavailable-courses')));
    await tester.pump();
    expect(count(tester, 1), ' · 1');
    expect(count(tester, 3), ' · 3');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('course-section-3')),
        matching: find.byKey(ValueKey('device-course-${withDraft.courseId}')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Find Courses on the web stays hidden without a web site', (
    tester,
  ) async {
    await pumpLibrary(tester);
    expect(find.byKey(const Key('course-library-web-band')), findsNothing);
    expect(find.text('Find Courses on the web'), findsNothing);
  });

  testWidgets('with a web site the first section opens it', (tester) async {
    final site = Uri.parse('https://courses.example.test/');
    final opened = <Uri>[];
    await pumpLibrary(
      tester,
      webSite: site,
      launch: (uri) async {
        opened.add(uri);
        return false;
      },
    );
    final band = tester.getTopLeft(
      find.byKey(const Key('course-library-web-band')),
    );
    final bundled = tester.getTopLeft(
      find.byKey(const ValueKey('course-section-0')),
    );
    expect(band.dy, lessThan(bundled.dy));
    await tester.tap(find.byKey(const Key('find-courses-on-the-web')));
    await tester.pump();
    expect(opened, [site]);
    expect(
      find.text('The Course web site could not be opened.'),
      findsOneWidget,
    );
  });

  test('Help explains device scope, imports and sources without selling', () {
    expect(
      availableCoursesHelp,
      startsWith(
        'Courses on this device\n\nAll Courses shows every Course installed or stored on this QQL device, including Courses outside your personal library.',
      ),
    );
    for (final phrase in [
      'a friend can send you a Course they created',
      'a publisher may distribute or sell you a Publisher Course',
      'it does not sell or license Courses itself',
      'Other Local Courses: Custom Courses created by another profile or imported from somebody else.',
      'Showing them does not make them playable or verified.',
      'It does not copy the Course or give you editing rights.',
      'Removing it from your courses does not remove it from the device.',
      'Publisher Courses remain subject to Publisher verification.',
      'Sort by orders the Courses inside each section',
      'Show unavailable starts on',
      'Course Studio',
    ]) {
      expect(availableCoursesHelp, contains(phrase));
    }
    // The web site section stays unmentioned while it is hidden.
    expect(availableCoursesHelp, isNot(contains('on the web')));
    expect(availableCoursesHelp, isNot(contains('Course Manager')));
  });

  test('every bundled Course is published and free of Draft content', () async {
    for (final code in CourseService.courseAssets.keys) {
      final course = await CourseService().loadCourse(code);
      expect(course.publicationState.isPublished, isTrue, reason: code);
      expect(CourseDraftStatus.courseHasDraft(course), isFalse, reason: code);
    }
  });
}
