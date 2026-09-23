import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_learner_visibility_service.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/learner_status_events.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alice = '12345678-1234-4234-9234-123456789abc';
const _bob = '87654321-4321-4321-8321-cba987654321';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _alice,
          displayName: 'Alice',
        ).encode(),
        const LearnerProfile(
          learnerProfileId: _bob,
          displayName: 'Bob',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _alice,
    });
  });

  test(
    'Hide uses the retired per-learner key without changing membership',
    () async {
      final course = _custom('course/one');
      final visibility = CourseLearnerVisibilityService();
      final library = CourseLibraryService();
      final prefs = await SharedPreferences.getInstance();

      expect(await visibility.isHidden(course.courseId), isFalse);
      expect(await library.contains(course), isTrue);
      await visibility.setHidden(course, true);
      expect(
        prefs.getBool('learner_${_alice}_course_hidden_course%2Fone'),
        isTrue,
      );
      expect(await library.contains(course), isTrue);
      expect(await visibility.hiddenCourseIds(['course/one', 'another']), {
        'course/one',
      });

      await ProfileService().setActiveProfileById(_bob);
      expect(await visibility.isHidden(course.courseId), isFalse);
      expect(await library.contains(course), isFalse);
      await expectLater(visibility.setHidden(course, true), throwsStateError);
      await library.add(course);
      await visibility.setHidden(course, true);
      expect(
        await visibility.isHidden(course.courseId, profileId: _alice),
        isTrue,
      );
      expect(
        await visibility.isHidden(course.courseId, profileId: _bob),
        isTrue,
      );

      await visibility.setHidden(course, false);
      expect(
        prefs.containsKey('learner_${_bob}_course_hidden_course%2Fone'),
        isFalse,
      );
      expect(
        await visibility.isHidden(course.courseId, profileId: _alice),
        isTrue,
      );
      expect(await library.contains(course), isTrue);
    },
  );

  test(
    'the selected Custom Course cannot be hidden, but can be unhidden',
    () async {
      final course = _custom('active');
      final visibility = CourseLearnerVisibilityService();
      await SettingsService().setLastSelectedCourseCode('custom:active');

      await expectLater(visibility.setHidden(course, true), throwsStateError);
      expect(await visibility.isHidden('active'), isFalse);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('learner_${_alice}_course_hidden_active', true);
      await visibility.setHidden(course, false);
      expect(await visibility.isHidden('active'), isFalse);
    },
  );

  test(
    'bundled Course code and explicit current ID also protect the active Course',
    () async {
      final bundled = await CourseService().loadCourse('IT');
      final other = _custom('other');
      final visibility = CourseLearnerVisibilityService();
      await SettingsService().setLastSelectedCourseCode('IT');

      await expectLater(visibility.setHidden(bundled, true), throwsStateError);
      await expectLater(
        visibility.setHidden(other, true, activeCourseId: other.courseId),
        throwsStateError,
      );
      expect(await visibility.isHidden(bundled.courseId), isFalse);
      expect(await visibility.isHidden(other.courseId), isFalse);
    },
  );

  test(
    'successful Hide and Unhide publish learner Course metadata invalidation',
    () async {
      final course = _custom('other');
      final visibility = CourseLearnerVisibilityService();
      final events = <LearnerStatusInvalidation>[];
      final subscription = LearnerStatusEvents.stream.listen(events.add);
      addTearDown(subscription.cancel);

      await visibility.setHidden(course, true);
      await visibility.setHidden(course, false);

      expect(events, [
        LearnerStatusInvalidation.courseMetadata,
        LearnerStatusInvalidation.courseMetadata,
      ]);
    },
  );
}

Course _custom(String id) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _alice,
    displayName: 'Alice',
  ),
  maintainer: const CourseMaintainer(_alice),
  originalCreatedAtUtc: '2026-09-23T00:00:00.000Z',
  courseVersion: '1',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course $id',
  ttsLanguage: 'it-IT',
  lessons: const [],
);
