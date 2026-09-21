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

  Future<void> pumpLibrary(WidgetTester tester) async {
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

  test('every bundled Course is published and free of Draft content', () async {
    for (final code in CourseService.courseAssets.keys) {
      final course = await CourseService().loadCourse(code);
      expect(course.publicationState.isPublished, isTrue, reason: code);
      expect(CourseDraftStatus.courseHasDraft(course), isFalse, reason: code);
    }
  });
}
