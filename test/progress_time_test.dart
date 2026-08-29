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
    test(
      'first activity preserves normalized raw keys, types, and re-instantiation',
      () async {
        final clock = _MutableClock(DateTime(2026, 3, 14, 17, 45));
        await addProfile('Tester');
        final service = ProgressService(now: clock.call);
        final prefs = await SharedPreferences.getInstance();
        final activityKeyPattern = RegExp(
          r'^learner_Tester_(streak_|last_active_|study_days_)',
        );

        expect(await service.getStreak(courseCode: ' it '), 0);
        expect(await service.getDaysStudied(courseCode: ' it '), 0);
        expect(prefs.getKeys().where(activityKeyPattern.hasMatch), isEmpty);

        await service.registerLearningActivity(courseCode: ' it ');

        const streakKey = 'learner_Tester_streak_IT';
        const lastActiveKey = 'learner_Tester_last_active_IT';
        const languageDaysKey = 'learner_Tester_study_days_IT';
        const globalDaysKey = 'learner_Tester_study_days_all';
        expect(prefs.getKeys().where(activityKeyPattern.hasMatch).toSet(), {
          streakKey,
          lastActiveKey,
          languageDaysKey,
          globalDaysKey,
        });
        expect(prefs.get(streakKey), isA<int>());
        expect(prefs.get(lastActiveKey), isA<String>());
        expect(prefs.get(languageDaysKey), isA<List<String>>());
        expect(prefs.get(globalDaysKey), isA<List<String>>());
        expect(prefs.getInt(streakKey), 1);
        expect(prefs.getString(lastActiveKey), '2026-03-14T00:00:00.000');
        expect(prefs.getStringList(languageDaysKey), ['2026-03-14']);
        expect(prefs.getStringList(globalDaysKey), ['2026-03-14']);

        final reloaded = ProgressService(now: clock.call);
        expect(await reloaded.getStreak(courseCode: 'IT'), 1);
        expect(await reloaded.getDaysStudied(courseCode: 'IT'), 1);
      },
    );

    test(
      'reads deduplicate stored day lists logically but registration sorts and rewrites them',
      () async {
        const languageDaysKey = 'learner_Tester_study_days_IT';
        const globalDaysKey = 'learner_Tester_study_days_all';
        final languageDays = ['2026-01-02', '2026-01-01', '2026-01-02'];
        final globalDays = ['2026-01-02', '2026-01-01', '2026-01-02'];
        SharedPreferences.setMockInitialValues({
          'learner_profiles': <String>['Tester'],
          'active_learner': 'Tester',
          'learner_Tester_streak_IT': 4,
          'learner_Tester_last_active_IT': '2026-01-02T00:00:00.000',
          languageDaysKey: languageDays,
          globalDaysKey: globalDays,
        });
        final clock = _MutableClock(DateTime(2026, 1, 2, 18));
        final service = ProgressService(now: clock.call);
        final prefs = await SharedPreferences.getInstance();

        expect(await service.getDaysStudied(courseCode: 'IT'), 2);
        expect(await service.getStreak(courseCode: 'IT'), 4);
        expect(prefs.getStringList(languageDaysKey), languageDays);
        expect(prefs.getStringList(globalDaysKey), globalDays);

        clock.value = DateTime(2026, 1, 3, 9);
        await service.registerLearningActivity(courseCode: 'IT');

        expect(prefs.getStringList(languageDaysKey), [
          '2026-01-01',
          '2026-01-02',
          '2026-01-03',
        ]);
        expect(prefs.getStringList(globalDaysKey), [
          '2026-01-01',
          '2026-01-02',
          '2026-01-03',
        ]);
        expect(prefs.getInt('learner_Tester_streak_IT'), 5);
      },
    );

    test('getStreak gives one-day grace then lazily persists zero', () async {
      final clock = _MutableClock(DateTime(2026, 1, 5, 8));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);
      final prefs = await SharedPreferences.getInstance();

      await service.registerLearningActivity(courseCode: 'IT');
      clock.value = DateTime(2026, 1, 6, 20);
      expect(await service.getStreak(courseCode: 'IT'), 1);
      expect(prefs.getInt('learner_Tester_streak_IT'), 1);

      clock.value = DateTime(2026, 1, 7, 8);
      expect(await service.getStreak(courseCode: 'IT'), 0);
      expect(prefs.getInt('learner_Tester_streak_IT'), 0);
    });

    test(
      'direct registration after a blank day restarts at one and retains history',
      () async {
        final clock = _MutableClock(DateTime(2026, 1, 5, 8));
        await addProfile('Tester');
        final service = ProgressService(now: clock.call);
        final prefs = await SharedPreferences.getInstance();

        await service.registerLearningActivity(courseCode: 'IT');
        clock.value = DateTime(2026, 1, 7, 8);
        await service.registerLearningActivity(courseCode: 'IT');

        expect(await service.getStreak(courseCode: 'IT'), 1);
        expect(await service.getDaysStudied(courseCode: 'IT'), 2);
        expect(
          prefs.getString('learner_Tester_last_active_IT'),
          '2026-01-07T00:00:00.000',
        );
        expect(prefs.getStringList('learner_Tester_study_days_IT'), [
          '2026-01-05',
          '2026-01-07',
        ]);
        expect(prefs.getStringList('learner_Tester_study_days_all'), [
          '2026-01-05',
          '2026-01-07',
        ]);
      },
    );

    test(
      'same-day languages retain separate state and one global date',
      () async {
        final clock = _MutableClock(DateTime(2026, 2, 10, 8));
        await addProfile('Tester');
        final service = ProgressService(now: clock.call);
        final prefs = await SharedPreferences.getInstance();

        await service.registerLearningActivity(courseCode: ' it ');
        await service.registerLearningActivity(courseCode: 'de');
        await service.registerLearningActivity(courseCode: 'IT');

        expect(await service.getStreak(courseCode: 'it'), 1);
        expect(await service.getStreak(courseCode: ' DE '), 1);
        expect(await service.getDaysStudied(courseCode: 'IT'), 1);
        expect(await service.getDaysStudied(courseCode: 'DE'), 1);
        expect(prefs.getStringList('learner_Tester_study_days_IT'), [
          '2026-02-10',
        ]);
        expect(prefs.getStringList('learner_Tester_study_days_DE'), [
          '2026-02-10',
        ]);
        expect(prefs.getStringList('learner_Tester_study_days_all'), [
          '2026-02-10',
        ]);
        expect(
          prefs.getKeys().where((key) => key.contains('streak_it')),
          isEmpty,
        );
      },
    );

    test(
      'automatic cross-language freeze spans multiple days but increments once on return',
      () async {
        final clock = _MutableClock(DateTime(2026, 4, 1, 8));
        await addProfile('Tester');
        final service = ProgressService(now: clock.call);
        final prefs = await SharedPreferences.getInstance();

        await service.registerLearningActivity(courseCode: 'IT');
        clock.value = DateTime(2026, 4, 2, 8);
        await service.registerLearningActivity(courseCode: 'DE');
        clock.value = DateTime(2026, 4, 3, 8);
        await service.registerLearningActivity(courseCode: 'DE');
        clock.value = DateTime(2026, 4, 4, 8);
        await service.registerLearningActivity(courseCode: 'IT');

        expect(await service.getStreak(courseCode: 'IT'), 2);
        expect(await service.getStreak(courseCode: 'DE'), 2);
        expect(prefs.getStringList('learner_Tester_study_days_IT'), [
          '2026-04-01',
          '2026-04-04',
        ]);
        expect(prefs.getStringList('learner_Tester_study_days_all'), [
          '2026-04-01',
          '2026-04-02',
          '2026-04-03',
          '2026-04-04',
        ]);
        expect(
          prefs.getKeys().where((key) => key.toLowerCase().contains('freeze')),
          isEmpty,
        );
      },
    );

    test('blank dates reset each language lazily and independently', () async {
      final clock = _MutableClock(DateTime(2026, 5, 1, 8));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);
      final prefs = await SharedPreferences.getInstance();

      await service.registerLearningActivity(courseCode: 'IT');
      await service.registerLearningActivity(courseCode: 'DE');
      clock.value = DateTime(2026, 5, 2, 8);
      await service.registerLearningActivity(courseCode: 'IT');
      await service.registerLearningActivity(courseCode: 'DE');
      expect(prefs.getInt('learner_Tester_streak_IT'), 2);
      expect(prefs.getInt('learner_Tester_streak_DE'), 2);

      clock.value = DateTime(2026, 5, 4, 8);
      expect(prefs.getInt('learner_Tester_streak_IT'), 2);
      expect(prefs.getInt('learner_Tester_streak_DE'), 2);

      expect(await service.getStreak(courseCode: 'IT'), 0);
      expect(prefs.getInt('learner_Tester_streak_IT'), 0);
      expect(prefs.getInt('learner_Tester_streak_DE'), 2);

      expect(await service.getStreak(courseCode: 'DE'), 0);
      expect(prefs.getInt('learner_Tester_streak_DE'), 0);
    });

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

    test(
      'missing and malformed last-active values currently hide stored streaks without rewriting them',
      () async {
        const missingLanguageDays = ['not-a-date', '2026-01-01', '2026-01-01'];
        const malformedLanguageDays = ['2026-01-02', 'also-not-a-date'];
        SharedPreferences.setMockInitialValues({
          'learner_profiles': <String>['Tester'],
          'active_learner': 'Tester',
          'learner_Tester_streak_IT': 7,
          'learner_Tester_study_days_IT': missingLanguageDays,
          'learner_Tester_streak_DE': -3,
          'learner_Tester_last_active_DE': 'not-an-iso-date',
          'learner_Tester_study_days_DE': malformedLanguageDays,
          'learner_Tester_study_days_all': <String>['not-a-date', '2026-01-01'],
        });
        final service = ProgressService(now: () => DateTime(2026, 1, 10));
        final prefs = await SharedPreferences.getInstance();

        expect(await service.getStreak(courseCode: 'IT'), 0);
        expect(await service.getStreak(courseCode: 'DE'), 0);
        expect(await service.getDaysStudied(courseCode: 'IT'), 2);
        expect(await service.getDaysStudied(courseCode: 'DE'), 2);
        expect(prefs.getInt('learner_Tester_streak_IT'), 7);
        expect(prefs.getInt('learner_Tester_streak_DE'), -3);
        expect(prefs.containsKey('learner_Tester_last_active_IT'), isFalse);
        expect(
          prefs.getString('learner_Tester_last_active_DE'),
          'not-an-iso-date',
        );
        expect(
          prefs.getStringList('learner_Tester_study_days_IT'),
          missingLanguageDays,
        );
        expect(
          prefs.getStringList('learner_Tester_study_days_DE'),
          malformedLanguageDays,
        );
      },
    );

    test(
      'KNOWN CURRENT wall-clock behavior increments and rewrites last-active backwards',
      () async {
        final clock = _MutableClock(DateTime(2026, 6, 10, 8));
        await addProfile('Tester');
        final service = ProgressService(now: clock.call);
        final prefs = await SharedPreferences.getInstance();

        await service.registerLearningActivity(courseCode: 'IT');
        clock.value = DateTime(2026, 6, 5, 8);
        await service.registerLearningActivity(courseCode: 'IT');

        expect(await service.getStreak(courseCode: 'IT'), 2);
        expect(
          prefs.getString('learner_Tester_last_active_IT'),
          '2026-06-05T00:00:00.000',
        );
        expect(prefs.getStringList('learner_Tester_study_days_IT'), [
          '2026-06-05',
          '2026-06-10',
        ]);
        expect(prefs.getStringList('learner_Tester_study_days_all'), [
          '2026-06-05',
          '2026-06-10',
        ]);
      },
    );

    test('activity remains consecutive across a month boundary', () async {
      final clock = _MutableClock(DateTime(2026, 1, 31, 23, 59));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);

      await service.registerLearningActivity(courseCode: 'IT');
      clock.value = DateTime(2026, 2, 1);
      await service.registerLearningActivity(courseCode: 'IT');

      expect(await service.getStreak(courseCode: 'IT'), 2);
      expect(await service.getDaysStudied(courseCode: 'IT'), 2);
    });

    test('activity remains consecutive across a year boundary', () async {
      final clock = _MutableClock(DateTime(2025, 12, 31, 23, 59));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);

      await service.registerLearningActivity(courseCode: 'IT');
      clock.value = DateTime(2026, 1, 1);
      await service.registerLearningActivity(courseCode: 'IT');

      expect(await service.getStreak(courseCode: 'IT'), 2);
      expect(await service.getDaysStudied(courseCode: 'IT'), 2);
    });

    test('activity remains consecutive through leap day', () async {
      final clock = _MutableClock(DateTime(2028, 2, 28, 23, 59));
      await addProfile('Tester');
      final service = ProgressService(now: clock.call);

      await service.registerLearningActivity(courseCode: 'IT');
      clock.value = DateTime(2028, 2, 29, 12);
      await service.registerLearningActivity(courseCode: 'IT');
      clock.value = DateTime(2028, 3, 1);
      await service.registerLearningActivity(courseCode: 'IT');

      expect(await service.getStreak(courseCode: 'IT'), 3);
      expect(await service.getDaysStudied(courseCode: 'IT'), 3);
    });
  });

  test('Review recency uses the injected time', () async {
    final clock = _MutableClock(DateTime(2026, 2, 1, 8));
    await addProfile('Tester');
    final service = ProgressService(now: clock.call);

    await service.recordRecentRound('course_a', 'topic_a', 'older', errors: 2);
    clock.value = DateTime(2026, 2, 1, 9);
    await service.recordRecentRound('course_a', 'topic_a', 'newer', errors: 2);

    final recent = await service.getRecentRounds(courseId: 'course_a');
    expect(recent.map((entry) => entry.roundId), ['newer', 'older']);
    expect(recent[0].completedAt, DateTime(2026, 2, 1, 9));
    expect(recent[1].completedAt, DateTime(2026, 2, 1, 8));
  });
}
