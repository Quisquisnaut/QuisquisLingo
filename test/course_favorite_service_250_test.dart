import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_favorite_service.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/learner_status_events.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
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
      ProfileService.activeProfileIdKey: _bob,
    });
  });

  test(
    'Favorite uses the confirmed learner key even outside the library',
    () async {
      final course = _custom('course/one');
      final favorites = CourseFavoriteService();
      final library = CourseLibraryService();
      final prefs = await SharedPreferences.getInstance();

      expect(await library.contains(course), isFalse);
      expect(await favorites.isFavorite(course.courseId), isFalse);
      await favorites.setFavorite(course.courseId, true);
      expect(
        prefs.getBool('learner_${_bob}_course_favorite_course%2Fone'),
        isTrue,
      );
      expect(await library.contains(course), isFalse);
      expect(await favorites.favoriteCourseIds(['course/one', 'another']), {
        'course/one',
      });

      await ProfileService().setActiveProfileById(_alice);
      expect(await library.contains(course), isTrue);
      expect(await favorites.isFavorite(course.courseId), isFalse);
      await favorites.setFavorite(course.courseId, true);
      expect(
        await favorites.isFavorite(course.courseId, profileId: _bob),
        isTrue,
      );

      await favorites.setFavorite(course.courseId, false);
      expect(
        prefs.containsKey('learner_${_alice}_course_favorite_course%2Fone'),
        isFalse,
      );
      expect(
        await favorites.isFavorite(course.courseId, profileId: _bob),
        isTrue,
      );
      expect(await library.contains(course), isTrue);
    },
  );

  test('writes publish Course metadata invalidation', () async {
    final favorites = CourseFavoriteService();
    final events = <LearnerStatusInvalidation>[];
    final subscription = LearnerStatusEvents.stream.listen(events.add);
    addTearDown(subscription.cancel);

    await favorites.setFavorite('one', true);
    await favorites.setFavorite('one', false);

    expect(events, [
      LearnerStatusInvalidation.courseMetadata,
      LearnerStatusInvalidation.courseMetadata,
    ]);
  });

  test(
    'without an active profile, reads default false and writes are refused',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ProfileService.activeProfileIdKey);
      final favorites = CourseFavoriteService();

      expect(await favorites.isFavorite('one'), isFalse);
      expect(await favorites.favoriteCourseIds(['one']), isEmpty);
      await expectLater(favorites.setFavorite('one', true), throwsStateError);
      expect(
        prefs.getKeys().where((key) => key.contains('course_favorite_')),
        isEmpty,
      );
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
