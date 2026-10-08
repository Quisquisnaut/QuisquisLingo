import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 248 Revision 3: Fork was the third Course Editor action running on the
/// unconfirmed working copy. Revision 2 removed export and Copy as New Course
/// and missed this one.
const _maintainerId = '12345678-1234-4234-9234-123456789abc';
const _outsiderId = '87654321-4321-4321-9321-cba987654321';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the Course Editor offers no Fork of the working copy', (
    tester,
  ) async {
    _signInOutsider();
    final course = _forkableCourse();
    final access = CourseAccessPolicy.evaluate(course, profileId: _outsiderId);
    expect(
      access.canFork,
      isTrue,
      reason: 'The fixture must be one an outsider may fork.',
    );

    await tester.pumpWidget(
      MaterialApp(home: CourseEditorScreen(course: course, access: access)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-editor-fork-course')), findsNothing);
    expect(find.text('Fork'), findsNothing);
  });

  test('the fork capability itself is unchanged', () {
    // The Editor's entry point goes; who may fork does not. Course Manager's
    // menu is gated on this same capability and passes the stored Course.
    final course = _forkableCourse();

    expect(
      CourseAccessPolicy.evaluate(course, profileId: _outsiderId).canFork,
      isTrue,
      reason: 'An outsider may still fork where derivatives are allowed.',
    );
    expect(
      CourseAccessPolicy.evaluate(course, profileId: _maintainerId).canFork,
      isFalse,
      reason: 'The Maintainer edits or copies instead; Fork is for outsiders.',
    );
    expect(
      CourseAccessPolicy.evaluate(course, profileId: null).canFork,
      isFalse,
      reason: 'Forking assigns a Maintainer, so it needs a signed-in profile.',
    );
  });
}

void _signInOutsider({String active = _outsiderId}) {
  SharedPreferences.setMockInitialValues({
    ProfileService.profilesKey: [
      const LearnerProfile(
        learnerProfileId: _maintainerId,
        displayName: 'Maintainer',
      ).encode(),
      const LearnerProfile(
        learnerProfileId: _outsiderId,
        displayName: 'Outsider',
      ).encode(),
    ],
    ProfileService.activeProfileIdKey: active,
  });
}

Course _forkableCourse() => Course(
  courseId: 'fork_source',
  originType: CourseOriginType.custom,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _maintainerId,
    displayName: 'Maintainer',
  ),
  maintainer: const CourseMaintainer(_maintainerId),
  originalCreatedAtUtc: '2026-09-12T09:00:00.000Z',
  derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Forkable Course',
  ttsLanguage: 'it-IT',
  lessons: [Lesson(lessonId: 'lesson', title: 'Lesson', rounds: const [])],
);
