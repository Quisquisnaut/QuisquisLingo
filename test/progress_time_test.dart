import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime call() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> addProfile(String name) => ProfileService().addProfile(name);

  Future<Map<String, int>> currentWeeklyXpByCourse(String learner) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      'learner_${Uri.encodeComponent(learner)}_week_xp_by_course',
    );
    if (raw == null) return <String, int>{};
    return Map<String, int>.from(jsonDecode(raw) as Map);
  }

  group('weekly XP clock behavior', () {
    test('same-week reads retain XP and its per-course breakdown', () async {
      final clock = _MutableClock(DateTime(2026, 8, 23, 0, 1));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);

      await service.addXp(12, courseCode: 'IT', courseId: 'course_a');
      clock.value = DateTime(2026, 8, 29, 23, 59);
      await service.addXp(8, courseCode: 'DE', courseId: 'course_b');

      expect(await service.getWeeklyXp(), 20);
      expect(await service.getLastWeekXp(), 0);
      expect(await service.getLastWeekXpByCourse(), isEmpty);
      expect(await currentWeeklyXpByCourse('Tester'), {
        'course_a': 12,
        'course_b': 8,
      });
    });

    test(
      'Sunday starts a new week and moves the prior total and course breakdown to last week',
      () async {
        final clock = _MutableClock(DateTime(2026, 8, 22, 23, 59));
        await addProfile('Tester');
        final service = ProgressService(now: clock.call);

        await service.addXp(25, courseCode: 'IT', courseId: 'course_a');
        await service.addXp(30, courseCode: 'DE', courseId: 'course_b');
        expect(await service.getWeeklyXp(), 55);

        clock.value = DateTime(2026, 8, 23);

        expect(await service.getWeeklyXp(), 0);
        expect(await service.getLastWeekXp(), 55);
        expect(await service.getLastWeekXpByCourse(), {
          'course_a': 25,
          'course_b': 30,
        });
        expect(await currentWeeklyXpByCourse('Tester'), isEmpty);

        await service.addXp(7, courseCode: 'IT', courseId: 'course_a');
        expect(await service.getWeeklyXp(), 7);
        expect(await service.getLastWeekXp(), 55);
        expect(await service.getLastWeekXpByCourse(), {
          'course_a': 25,
          'course_b': 30,
        });
      },
    );

    test('skipping a full week reports zero XP for last week', () async {
      final clock = _MutableClock(DateTime(2026, 8, 15, 12));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);

      await service.addXp(40, courseCode: 'IT', courseId: 'old_course');
      expect(await service.getXp(courseCode: 'IT'), 40);

      clock.value = DateTime(2026, 8, 23, 12);

      expect(await service.getWeeklyXp(), 0);
      expect(await service.getLastWeekXp(), 0);
      expect(await service.getLastWeekXpByCourse(), isEmpty);
      expect(await currentWeeklyXpByCourse('Tester'), isEmpty);
      expect(await service.getXp(courseCode: 'IT'), 40);
    });

    test(
      'weekly rollover and leaderboard totals remain isolated by profile',
      () async {
        final clock = _MutableClock(DateTime(2026, 8, 22, 12));
        final profiles = ProfileService();

        await addProfile('Alice');
        final service = ProgressService(now: clock.call);
        await service.addXp(10, courseCode: 'IT', courseId: 'alice_course');

        await addProfile('Bob');
        await service.addXp(20, courseCode: 'DE', courseId: 'bob_course');

        clock.value = DateTime(2026, 8, 23, 12);
        await profiles.setActiveProfile('Alice');
        final leaderboard = await service.getLastWeekLocalLeaderboard();

        expect(leaderboard.map((entry) => '${entry.learnerName}:${entry.xp}'), [
          'Bob:20',
          'Alice:10',
        ]);
        expect(await service.getLastWeekXp(), 10);
        expect(await service.getLastWeekXpByCourse(), {'alice_course': 10});

        await profiles.setActiveProfile('Bob');
        expect(await service.getLastWeekXp(), 20);
        expect(await service.getLastWeekXpByCourse(), {'bob_course': 20});
      },
    );

    test('weekly-goal celebration resets at the Sunday boundary', () async {
      final clock = _MutableClock(DateTime(2026, 8, 22, 23, 59));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);

      expect(await service.isWeeklyGoalCelebrated(), isFalse);
      await service.markWeeklyGoalCelebrated();
      expect(await service.isWeeklyGoalCelebrated(), isTrue);

      clock.value = DateTime(2026, 8, 23);
      expect(await service.isWeeklyGoalCelebrated(), isFalse);
    });
  });

  group('streak and study-day clock behavior', () {
    test('repeated activity on one day counts once', () async {
      final clock = _MutableClock(DateTime(2026, 1, 5, 8));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);

      await service.registerLearningActivity(courseCode: 'it');
      clock.value = DateTime(2026, 1, 5, 22);
      await service.registerLearningActivity(courseCode: 'IT');

      expect(await service.getStreak(courseCode: 'IT'), 1);
      expect(await service.getDaysStudied(courseCode: 'IT'), 1);
    });

    test(
      'other-language study freezes a streak, while an unstudied day breaks it',
      () async {
        final clock = _MutableClock(DateTime(2026, 1, 5, 8));
        await addProfile('Tester');
        final service = ProgressService(now: clock.call);

        await service.registerLearningActivity(courseCode: 'IT');
        clock.value = DateTime(2026, 1, 6, 8);
        await service.registerLearningActivity(courseCode: 'IT');
        expect(await service.getStreak(courseCode: 'IT'), 2);

        clock.value = DateTime(2026, 1, 7, 8);
        await service.registerLearningActivity(courseCode: 'DE');
        expect(await service.getStreak(courseCode: 'IT'), 2);

        clock.value = DateTime(2026, 1, 8, 8);
        await service.registerLearningActivity(courseCode: 'IT');
        expect(await service.getStreak(courseCode: 'IT'), 3);
        expect(await service.getDaysStudied(courseCode: 'IT'), 3);
        expect(await service.getDaysStudied(courseCode: 'DE'), 1);

        clock.value = DateTime(2026, 1, 10, 8);
        expect(await service.getStreak(courseCode: 'IT'), 0);

        await service.registerLearningActivity(courseCode: 'IT');
        expect(await service.getStreak(courseCode: 'IT'), 1);
        expect(await service.getDaysStudied(courseCode: 'IT'), 4);
      },
    );

    test('streaks and study days remain isolated by profile', () async {
      final clock = _MutableClock(DateTime(2026, 1, 5, 8));
      final profiles = ProfileService();

      await addProfile('Alice');
      final service = ProgressService(now: clock.call);
      await service.registerLearningActivity(courseCode: 'IT');

      await addProfile('Bob');
      expect(await service.getStreak(courseCode: 'IT'), 0);
      expect(await service.getDaysStudied(courseCode: 'IT'), 0);
      await service.registerLearningActivity(courseCode: 'IT');
      clock.value = DateTime(2026, 1, 6, 8);
      await service.registerLearningActivity(courseCode: 'IT');
      expect(await service.getStreak(courseCode: 'IT'), 2);
      expect(await service.getDaysStudied(courseCode: 'IT'), 2);

      await profiles.setActiveProfile('Alice');
      expect(await service.getStreak(courseCode: 'IT'), 1);
      expect(await service.getDaysStudied(courseCode: 'IT'), 1);
    });
  });

  test('Review recency uses the injected time', () async {
    final clock = _MutableClock(DateTime(2026, 2, 1, 8));
    await addProfile('Tester');
    final service = ProgressService(now: clock.call);

    await service.recordRecentRound('course_a', 'older', errors: 2);
    clock.value = DateTime(2026, 2, 1, 9);
    await service.recordRecentRound('course_a', 'newer', errors: 2);

    final recent = await service.getRecentRounds(courseId: 'course_a');
    expect(recent.map((entry) => entry.roundId), ['newer', 'older']);
    expect(recent[0].completedAt, DateTime(2026, 2, 1, 9));
    expect(recent[1].completedAt, DateTime(2026, 2, 1, 8));
  });
}
