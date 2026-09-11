import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/review_round_resolver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile(
      'Resolver learner',
      skinTone: 'light',
      hairTone: 'dark',
    );
  });

  test(
    'firstPending skips stale records and session exclusions without re-sorting',
    () async {
      var now = DateTime.utc(2026, 9, 1, 9);
      final progress = ProgressService(now: () => now);
      await progress.recordRecentRound(
        'course-review',
        'missing-lesson',
        'stale-round',
        errors: 9,
      );
      now = DateTime.utc(2026, 9, 1, 10);
      await progress.recordRecentRound(
        'course-review',
        'lesson-a',
        'highest-errors',
        errors: 5,
      );
      now = DateTime.utc(2026, 9, 1, 11);
      await progress.recordRecentRound(
        'course-review',
        'lesson-b',
        'oldest-equal-errors',
        errors: 3,
      );
      now = DateTime.utc(2026, 9, 1, 12);
      await progress.recordRecentRound(
        'course-review',
        'lesson-b',
        'newest-equal-errors',
        errors: 3,
      );

      final course = _course();
      final resolver = ReviewRoundResolver(progress: progress);
      final first = await resolver.firstPending(course);
      expect(first!.round.id, 'highest-errors');

      final location = await resolver.firstPending(
        course,
        excludedRoundIds: {'highest-errors'},
      );
      expect(location, isNotNull);
      expect(location!.entry.errors, 3);
      expect(location.round.id, 'oldest-equal-errors');
      expect(location.lesson.lessonId, 'lesson-b');
      expect(location.lessonIndex, 1);
      expect(location.roundIndex, 0);
    },
  );

  test('firstPending returns null when no stored Round resolves', () async {
    final progress = ProgressService();
    await progress.recordRecentRound(
      'course-review',
      'missing',
      'missing',
      errors: 1,
    );

    expect(
      await ReviewRoundResolver(progress: progress).firstPending(_course()),
      isNull,
    );
  });
}

Course _course() => Course(
  courseId: 'course-review',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Resolver course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson-a',
      title: 'First lesson',
      rounds: [
        LearningRound(
          id: 'highest-errors',
          title: 'Highest',
          exercises: const [],
        ),
      ],
    ),
    Lesson(
      lessonId: 'lesson-b',
      title: 'Second lesson',
      rounds: [
        LearningRound(
          id: 'oldest-equal-errors',
          title: 'Oldest',
          exercises: const [],
        ),
        LearningRound(
          id: 'newest-equal-errors',
          title: 'Newest',
          exercises: const [],
        ),
      ],
    ),
  ],
);
