import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
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

  Future<ProgressService> progress({
    String learner = 'Tester',
    DateTime Function()? now,
  }) async {
    await ProfileService().addProfile(
      learner,
      skinTone: 'light',
      hairTone: 'dark',
    );
    return ProgressService(now: now);
  }

  Future<Map<String, int>> currentWeeklyXpByCourse(String learner) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = (await ProfileService().getProfileRecords()).firstWhere(
      (value) => value.displayName == learner,
    );
    final raw = prefs.getString(
      ProfileService().keyForProfileId(
        profile.learnerProfileId,
        'week_xp_by_course',
      ),
    );
    if (raw == null) return <String, int>{};
    return Map<String, int>.from(jsonDecode(raw) as Map);
  }

  Future<String> activePrefix() async => ProfileService.prefixForProfileId(
    (await ProfileService().getActiveProfileId())!,
  );

  group('course-owned progress', () {
    test(
      'completed rounds, Lessons, laurels, skipped-TTS results, Duels, and Review history are isolated by course ID',
      () async {
        final service = await progress();

        await service.completeRound(
          'shared_round',
          courseId: 'course_a',
          courseCode: 'IT',
        );
        await service.completeLesson(
          'shared_lesson',
          courseId: 'course_a',
          courseCode: 'IT',
        );
        await service.markPerfectRound('laurel_round', courseId: 'course_a');
        await service.markTtsSkippedPerfectRound(
          'tts_round',
          courseId: 'course_a',
        );
        await service.winDuel(
          'shared_duel',
          courseId: 'course_a',
          courseCode: 'IT',
        );
        await service.recordRecentRound(
          'course_a',
          'shared_lesson',
          'shared_round',
          errors: 4,
        );

        expect(await service.getCompletedRounds(courseId: 'course_a'), {
          'shared_round',
        });
        expect(await service.getCompletedLessons(courseId: 'course_a'), {
          'shared_lesson',
        });
        expect(await service.getPerfectRounds(courseId: 'course_a'), {
          'laurel_round',
        });
        expect(await service.getTtsSkippedPerfectRounds(courseId: 'course_a'), {
          'tts_round',
        });
        expect(await service.getWonDuels(courseId: 'course_a'), {
          'shared_duel',
        });
        expect(
          await service.getRecentRounds(courseId: 'course_a'),
          hasLength(1),
        );
        final recent = (await service.getRecentRounds(
          courseId: 'course_a',
        )).single;
        expect(recent.lessonId, 'shared_lesson');
        expect(recent.roundId, 'shared_round');

        expect(await service.getCompletedRounds(courseId: 'course_b'), isEmpty);
        expect(
          await service.getCompletedLessons(courseId: 'course_b'),
          isEmpty,
        );
        expect(await service.getPerfectRounds(courseId: 'course_b'), isEmpty);
        expect(
          await service.getTtsSkippedPerfectRounds(courseId: 'course_b'),
          isEmpty,
        );
        expect(await service.getWonDuels(courseId: 'course_b'), isEmpty);
        expect(await service.getRecentRounds(courseId: 'course_b'), isEmpty);
      },
    );

    test(
      'a permanent laurel replaces a TTS-skipped perfect mark and remains permanent',
      () async {
        final service = await progress();

        await service.markTtsSkippedPerfectRound(
          'round_1',
          courseId: 'course_a',
        );
        expect(await service.getTtsSkippedPerfectRounds(courseId: 'course_a'), {
          'round_1',
        });
        expect(await service.getPerfectRounds(courseId: 'course_a'), isEmpty);

        expect(
          await service.markPerfectRound('round_1', courseId: 'course_a'),
          isTrue,
        );
        expect(await service.getPerfectRounds(courseId: 'course_a'), {
          'round_1',
        });
        expect(
          await service.getTtsSkippedPerfectRounds(courseId: 'course_a'),
          isEmpty,
        );

        expect(
          await service.markPerfectRound('round_1', courseId: 'course_a'),
          isFalse,
        );
        await service.markTtsSkippedPerfectRound(
          'round_1',
          courseId: 'course_a',
        );
        expect(await service.getPerfectRounds(courseId: 'course_a'), {
          'round_1',
        });
        expect(
          await service.getTtsSkippedPerfectRounds(courseId: 'course_a'),
          isEmpty,
        );
      },
    );

    test(
      'Review keeps the latest result per course and prioritizes errors',
      () async {
        final service = await progress();
        await service.recordRecentRound(
          'course_a',
          'lesson_a',
          'r1',
          errors: 5,
        );
        await service.recordRecentRound(
          'course_b',
          'lesson_b',
          'r1',
          errors: 9,
        );
        await service.recordRecentRound(
          'course_a',
          'lesson_a',
          'r2',
          errors: 2,
        );
        await service.recordRecentRound(
          'course_a',
          'lesson_a',
          'r1',
          errors: 1,
        );

        final courseA = await service.getRecentRounds(
          courseId: 'course_a',
          limit: 50,
        );
        expect(courseA.map((entry) => entry.roundId), ['r2', 'r1']);
        expect(courseA.map((entry) => entry.lessonId), [
          'lesson_a',
          'lesson_a',
        ]);
        expect(courseA.map((entry) => entry.errors), [2, 1]);

        final courseB = await service.getRecentRounds(courseId: 'course_b');
        expect(courseB, hasLength(1));
        expect(courseB.single.roundId, 'r1');
        expect(courseB.single.errors, 9);
      },
    );
  });

  test(
    'two courses with one normalized language share activity but not course progress',
    () async {
      final clock = _MutableClock(DateTime(2026, 3, 1, 8));
      final service = await progress(now: clock.call);
      final prefs = await SharedPreferences.getInstance();

      await service.completeRound(
        'round_a',
        courseId: 'course_a',
        courseCode: ' it ',
      );
      clock.value = DateTime(2026, 3, 2, 8);
      await service.completeRound(
        'round_b',
        courseId: 'course_b',
        courseCode: 'IT',
      );

      expect(await service.getStreak(courseCode: 'it'), 2);
      expect(await service.getDaysStudied(courseCode: ' IT '), 2);
      expect(await service.getCompletedRounds(courseId: 'course_a'), {
        'round_a',
      });
      expect(await service.getCompletedRounds(courseId: 'course_b'), {
        'round_b',
      });
      expect(prefs.getKeys().where((key) => key.contains('streak_')).toSet(), {
        '${await activePrefix()}streak_IT',
      });
      expect(
        prefs.getKeys().where(
          (key) => key.contains('study_days') && key.contains('course_'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'Round, Lesson, and Duel composite methods each record their current activity step',
    () async {
      final clock = _MutableClock(DateTime(2026, 3, 10, 8));
      final service = await progress(now: clock.call);
      final prefs = await SharedPreferences.getInstance();

      await service.completeRound(
        'round_1',
        courseId: 'course_a',
        courseCode: 'IT',
      );
      expect(await service.getStreak(courseCode: 'IT'), 1);

      clock.value = DateTime(2026, 3, 11, 8);
      await service.completeLesson(
        'lesson_1',
        courseId: 'course_a',
        courseCode: 'IT',
      );
      expect(await service.getStreak(courseCode: 'IT'), 2);

      clock.value = DateTime(2026, 3, 12, 8);
      await service.winDuel('duel_1', courseId: 'course_a', courseCode: 'IT');

      expect(await service.getStreak(courseCode: 'IT'), 3);
      expect(await service.getDaysStudied(courseCode: 'IT'), 3);
      expect(prefs.getStringList('${await activePrefix()}study_days_IT'), [
        '2026-03-10',
        '2026-03-11',
        '2026-03-12',
      ]);
      expect(await service.getCompletedRounds(courseId: 'course_a'), {
        'round_1',
      });
      expect(await service.getCompletedLessons(courseId: 'course_a'), {
        'lesson_1',
      });
      expect(await service.getWonDuels(courseId: 'course_a'), {'duel_1'});
      expect(await service.getXp(courseCode: 'IT'), 75);
      expect(await service.getWeeklyXp(), 75);
    },
  );

  test(
    'Lesson and Duel awards are independent, one-time state survives reload, and Duel repeats award 10 XP',
    () async {
      final service = await progress();

      expect(
        await service.completeLesson(
          'lesson_1',
          courseId: 'course_a',
          courseCode: 'IT',
        ),
        25,
      );
      expect(await service.getWonDuels(courseId: 'course_a'), isEmpty);
      expect(
        await service.completeLesson(
          'lesson_1',
          courseId: 'course_a',
          courseCode: 'IT',
        ),
        0,
      );

      expect(
        await service.winDuel('duel_1', courseId: 'course_a', courseCode: 'IT'),
        50,
      );
      expect(await service.getCompletedLessons(courseId: 'course_a'), {
        'lesson_1',
      });

      final reloaded = ProgressService();
      expect(
        await reloaded.completeLesson(
          'lesson_1',
          courseId: 'course_a',
          courseCode: 'IT',
        ),
        0,
      );
      expect(
        await reloaded.winDuel(
          'duel_1',
          courseId: 'course_a',
          courseCode: 'IT',
        ),
        10,
      );
      expect(
        await reloaded.winDuel(
          'duel_1',
          courseId: 'course_a',
          courseCode: 'IT',
        ),
        10,
      );
      expect(await reloaded.getXp(courseCode: 'IT'), 95);
      expect(await reloaded.getWeeklyXp(), 95);
    },
  );

  test('winning a Duel does not mark its learning Lesson completed', () async {
    final service = await progress();

    expect(
      await service.winDuel('duel_1', courseId: 'course_a', courseCode: 'IT'),
      50,
    );

    expect(await service.getCompletedLessons(courseId: 'course_a'), isEmpty);
    expect(await service.getWonDuels(courseId: 'course_a'), {'duel_1'});
  });

  test(
    'all progress and XP scopes are isolated between learner profiles',
    () async {
      final profiles = ProfileService();
      final alice = await progress(learner: 'Alice Example');
      await alice.completeRound(
        'alice_round',
        courseId: 'shared_course',
        courseCode: 'IT',
      );
      await alice.completeLesson(
        'alice_lesson',
        courseId: 'shared_course',
        courseCode: 'IT',
      );
      await alice.markPerfectRound('alice_laurel', courseId: 'shared_course');
      await alice.markTtsSkippedPerfectRound(
        'alice_tts',
        courseId: 'shared_course',
      );
      await alice.winDuel(
        'alice_duel',
        courseId: 'shared_course',
        courseCode: 'IT',
      );
      await alice.recordRecentRound(
        'shared_course',
        'alice_lesson',
        'alice_round',
        errors: 3,
      );
      await alice.addXp(11, courseCode: 'DE', courseId: 'german_course');
      final aliceWeeklyXp = await alice.getWeeklyXp();

      final bob = await progress(learner: 'Bob Example');
      expect(await bob.getCompletedRounds(courseId: 'shared_course'), isEmpty);
      expect(await bob.getCompletedLessons(courseId: 'shared_course'), isEmpty);
      expect(await bob.getPerfectRounds(courseId: 'shared_course'), isEmpty);
      expect(
        await bob.getTtsSkippedPerfectRounds(courseId: 'shared_course'),
        isEmpty,
      );
      expect(await bob.getWonDuels(courseId: 'shared_course'), isEmpty);
      expect(await bob.getRecentRounds(courseId: 'shared_course'), isEmpty);
      expect(await bob.getXp(courseCode: 'IT'), 0);
      expect(await bob.getXp(courseCode: 'DE'), 0);
      expect(await bob.getWeeklyXp(), 0);

      await bob.completeRound(
        'bob_round',
        courseId: 'shared_course',
        courseCode: 'IT',
      );
      await bob.addXp(7, courseCode: 'IT', courseId: 'shared_course');

      await profiles.setActiveProfile('Alice Example');
      final reloadedAlice = ProgressService();
      expect(
        await reloadedAlice.getCompletedRounds(courseId: 'shared_course'),
        {'alice_round'},
      );
      expect(
        await reloadedAlice.getCompletedLessons(courseId: 'shared_course'),
        {'alice_lesson'},
      );
      expect(await reloadedAlice.getPerfectRounds(courseId: 'shared_course'), {
        'alice_laurel',
      });
      expect(
        await reloadedAlice.getTtsSkippedPerfectRounds(
          courseId: 'shared_course',
        ),
        {'alice_tts'},
      );
      expect(await reloadedAlice.getWonDuels(courseId: 'shared_course'), {
        'alice_duel',
      });
      expect(
        (await reloadedAlice.getRecentRounds(
          courseId: 'shared_course',
        )).single.roundId,
        'alice_round',
      );
      expect(await reloadedAlice.getXp(courseCode: 'IT'), 75);
      expect(await reloadedAlice.getXp(courseCode: 'DE'), 11);
      expect(await reloadedAlice.getWeeklyXp(), aliceWeeklyXp);

      await profiles.setActiveProfile('Bob Example');
      final reloadedBob = ProgressService();
      expect(await reloadedBob.getCompletedRounds(courseId: 'shared_course'), {
        'bob_round',
      });
      expect(await reloadedBob.getXp(courseCode: 'IT'), 7);
      expect(await reloadedBob.getWeeklyXp(), 7);
    },
  );

  test(
    'language XP stays language-scoped while weekly XP is learner-global with a course breakdown',
    () async {
      final service = await progress();

      await service.addXp(20, courseCode: 'it', courseId: 'course_a');
      await service.addXp(5, courseCode: 'IT', courseId: 'course_a');
      await service.addXp(30, courseCode: 'DE', courseId: 'course_b');

      expect(await service.getXp(courseCode: 'IT'), 25);
      expect(await service.getXp(courseCode: 'it'), 25);
      expect(await service.getXp(courseCode: 'DE'), 30);
      expect(await service.getWeeklyXp(), 55);
      expect(await currentWeeklyXpByCourse('Tester'), {
        'course_a': 25,
        'course_b': 30,
      });

      final reloaded = ProgressService();
      expect(await reloaded.getXp(courseCode: 'IT'), 25);
      expect(await reloaded.getXp(courseCode: 'DE'), 30);
      expect(await reloaded.getWeeklyXp(), 55);
      expect(await currentWeeklyXpByCourse('Tester'), {
        'course_a': 25,
        'course_b': 30,
      });
    },
  );

  test('last-week XP preserves the learner-global course breakdown', () async {
    final now = DateTime(2026, 8, 19, 12);
    final currentSunday = DateTime(2026, 8, 16);
    final previousSunday = currentSunday.subtract(const Duration(days: 7));
    String day(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';

    const learnerId = '00000000-0000-4000-8000-000000000001';
    final learnerPrefix = ProfileService.prefixForProfileId(learnerId);
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: <String>[
        const LearnerProfile(
          learnerProfileId: learnerId,
          displayName: 'Tester',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: learnerId,
      '${learnerPrefix}week_xp_week': day(previousSunday),
      '${learnerPrefix}week_xp': 55,
      '${learnerPrefix}week_xp_by_course': jsonEncode({
        'course_a': 25,
        'course_b': 30,
      }),
    });

    final service = ProgressService(now: () => now);
    expect(await service.getLastWeekXp(), 55);
    expect(await service.getLastWeekXpByCourse(), {
      'course_a': 25,
      'course_b': 30,
    });
    expect(await service.getWeeklyXp(), 0);
    expect(await currentWeeklyXpByCourse('Tester'), isEmpty);

    final reloaded = ProgressService(now: () => now);
    expect(await reloaded.getLastWeekXp(), 55);
    expect(await reloaded.getLastWeekXpByCourse(), {
      'course_a': 25,
      'course_b': 30,
    });
  });

  test('course progress survives ProgressService re-instantiation', () async {
    final service = await progress();
    await service.completeRound(
      'round_1',
      courseId: 'course_a',
      courseCode: 'IT',
    );
    await service.completeLesson(
      'lesson_1',
      courseId: 'course_a',
      courseCode: 'IT',
    );
    await service.markPerfectRound('perfect_1', courseId: 'course_a');
    await service.markTtsSkippedPerfectRound('tts_1', courseId: 'course_a');
    await service.winDuel('duel_1', courseId: 'course_a', courseCode: 'IT');
    await service.recordRecentRound(
      'course_a',
      'lesson_1',
      'round_1',
      errors: 6,
    );

    final reloaded = ProgressService();
    expect(await reloaded.getCompletedRounds(courseId: 'course_a'), {
      'round_1',
    });
    expect(await reloaded.getCompletedLessons(courseId: 'course_a'), {
      'lesson_1',
    });
    expect(await reloaded.getPerfectRounds(courseId: 'course_a'), {
      'perfect_1',
    });
    expect(await reloaded.getTtsSkippedPerfectRounds(courseId: 'course_a'), {
      'tts_1',
    });
    expect(await reloaded.getWonDuels(courseId: 'course_a'), {'duel_1'});
    final recent = await reloaded.getRecentRounds(courseId: 'course_a');
    expect(recent, hasLength(1));
    expect(recent.single.lessonId, 'lesson_1');
    expect(recent.single.roundId, 'round_1');
    expect(recent.single.errors, 6);
    expect(await reloaded.getXp(courseCode: 'IT'), 75);
    expect(await reloaded.getWeeklyXp(), 75);
  });

  test(
    'resetCourse clears only the active learner\'s selected course progress',
    () async {
      final profiles = ProfileService();
      final service = await progress(learner: 'Alice');

      await service.completeRound(
        'round_a',
        courseId: 'course_a',
        courseCode: 'IT',
      );
      await service.completeLesson(
        'lesson_a',
        courseId: 'course_a',
        courseCode: 'IT',
      );
      await service.markPerfectRound('perfect_a', courseId: 'course_a');
      await service.markTtsSkippedPerfectRound('tts_a', courseId: 'course_a');
      await service.winDuel('duel_a', courseId: 'course_a', courseCode: 'IT');
      await service.recordRecentRound(
        'course_a',
        'lesson_a',
        'round_a',
        errors: 5,
      );
      await service.addXp(9, courseCode: 'DE', courseId: 'course_a');

      await service.completeRound(
        'round_b',
        courseId: 'course_b',
        courseCode: 'IT',
      );
      await service.completeLesson(
        'lesson_b',
        courseId: 'course_b',
        courseCode: 'IT',
      );
      await service.markPerfectRound('perfect_b', courseId: 'course_b');
      await service.markTtsSkippedPerfectRound('tts_b', courseId: 'course_b');
      await service.winDuel('duel_b', courseId: 'course_b', courseCode: 'IT');
      await service.recordRecentRound(
        'course_b',
        'lesson_b',
        'round_b',
        errors: 2,
      );

      final languageXpBefore = await service.getXp(courseCode: 'IT');
      final otherLanguageXpBefore = await service.getXp(courseCode: 'DE');
      final weeklyXpBefore = await service.getWeeklyXp();
      final weeklyByCourseBefore = await currentWeeklyXpByCourse('Alice');

      await progress(learner: 'Bob');
      final bob = ProgressService();
      await bob.completeRound(
        'bob_round_a',
        courseId: 'course_a',
        courseCode: 'IT',
      );
      await bob.markPerfectRound('bob_perfect_a', courseId: 'course_a');
      await bob.recordRecentRound(
        'course_a',
        'bob_lesson_a',
        'bob_round_a',
        errors: 8,
      );

      await profiles.setActiveProfile('Alice');
      await ProgressService().resetCourse('course_a');
      final reloadedAlice = ProgressService();

      expect(
        await reloadedAlice.getCompletedRounds(courseId: 'course_a'),
        isEmpty,
      );
      expect(
        await reloadedAlice.getCompletedLessons(courseId: 'course_a'),
        isEmpty,
      );
      expect(
        await reloadedAlice.getPerfectRounds(courseId: 'course_a'),
        isEmpty,
      );
      expect(
        await reloadedAlice.getTtsSkippedPerfectRounds(courseId: 'course_a'),
        isEmpty,
      );
      expect(await reloadedAlice.getWonDuels(courseId: 'course_a'), isEmpty);
      expect(
        await reloadedAlice.getRecentRounds(courseId: 'course_a'),
        isEmpty,
      );

      expect(await reloadedAlice.getCompletedRounds(courseId: 'course_b'), {
        'round_b',
      });
      expect(await reloadedAlice.getCompletedLessons(courseId: 'course_b'), {
        'lesson_b',
      });
      expect(await reloadedAlice.getPerfectRounds(courseId: 'course_b'), {
        'perfect_b',
      });
      expect(
        await reloadedAlice.getTtsSkippedPerfectRounds(courseId: 'course_b'),
        {'tts_b'},
      );
      expect(await reloadedAlice.getWonDuels(courseId: 'course_b'), {'duel_b'});
      expect(
        (await reloadedAlice.getRecentRounds(
          courseId: 'course_b',
        )).single.roundId,
        'round_b',
      );

      expect(await reloadedAlice.getXp(courseCode: 'IT'), languageXpBefore);
      expect(
        await reloadedAlice.getXp(courseCode: 'DE'),
        otherLanguageXpBefore,
      );
      expect(await reloadedAlice.getWeeklyXp(), weeklyXpBefore);
      expect(await currentWeeklyXpByCourse('Alice'), weeklyByCourseBefore);

      await reloadedAlice.completeRound(
        'round_a',
        courseId: 'course_a',
        courseCode: 'IT',
      );
      expect(await reloadedAlice.getCompletedRounds(courseId: 'course_a'), {
        'round_a',
      });

      await profiles.setActiveProfile('Bob');
      final reloadedBob = ProgressService();
      expect(await reloadedBob.getCompletedRounds(courseId: 'course_a'), {
        'bob_round_a',
      });
      expect(await reloadedBob.getPerfectRounds(courseId: 'course_a'), {
        'bob_perfect_a',
      });
      expect(
        (await reloadedBob.getRecentRounds(
          courseId: 'course_a',
        )).single.roundId,
        'bob_round_a',
      );
    },
  );

  test(
    'resetCourse preserves exact language and global activity state',
    () async {
      final clock = _MutableClock(DateTime(2026, 4, 5, 8));
      final service = await progress(now: clock.call);
      final prefs = await SharedPreferences.getInstance();

      await service.completeRound(
        'round_a',
        courseId: 'course_a',
        courseCode: 'IT',
      );
      await service.markPerfectRound('round_a', courseId: 'course_a');
      clock.value = DateTime(2026, 4, 6, 8);
      await service.registerLearningActivity(courseCode: 'DE');

      final learnerPrefix = await activePrefix();

      final activityKeys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith('${learnerPrefix}streak_') ||
                key.startsWith('${learnerPrefix}last_active_') ||
                key.startsWith('${learnerPrefix}study_days_'),
          )
          .toSet();
      final activityBefore = <String, Object?>{
        for (final key in activityKeys) key: prefs.get(key),
      };

      await service.resetCourse('course_a');

      expect(await service.getCompletedRounds(courseId: 'course_a'), isEmpty);
      expect(await service.getPerfectRounds(courseId: 'course_a'), isEmpty);
      expect(<String, Object?>{
        for (final key in activityKeys) key: prefs.get(key),
      }, activityBefore);
      expect(await service.getStreak(courseCode: 'IT'), 1);
      expect(await service.getDaysStudied(courseCode: 'IT'), 1);
      expect(await service.getStreak(courseCode: 'DE'), 1);
      expect(await service.getDaysStudied(courseCode: 'DE'), 1);
      expect(prefs.getStringList('${learnerPrefix}study_days_all'), [
        '2026-04-05',
        '2026-04-06',
      ]);
    },
  );

  test(
    'profile deletion removes all activity families and recreation starts at zero',
    () async {
      final clock = _MutableClock(DateTime(2026, 5, 1, 8));
      final profiles = ProfileService();
      final service = await progress(learner: 'Solo', now: clock.call);
      final prefs = await SharedPreferences.getInstance();

      await service.registerLearningActivity(courseCode: 'IT');
      await service.registerLearningActivity(courseCode: 'DE');
      final learnerPrefix = await activePrefix();
      final activityKeys = prefs
          .getKeys()
          .where(
            (key) =>
                key.startsWith('${learnerPrefix}streak_') ||
                key.startsWith('${learnerPrefix}last_active_') ||
                key.startsWith('${learnerPrefix}study_days_'),
          )
          .toSet();
      expect(activityKeys, hasLength(7));

      await profiles.deleteProfile('Solo');

      expect(activityKeys.where(prefs.containsKey), isEmpty);
      await profiles.addProfile('Solo');
      final recreated = ProgressService(now: clock.call);
      expect(await recreated.getStreak(courseCode: 'IT'), 0);
      expect(await recreated.getDaysStudied(courseCode: 'IT'), 0);
      expect(await recreated.getStreak(courseCode: 'DE'), 0);
      expect(await recreated.getDaysStudied(courseCode: 'DE'), 0);
    },
  );

  test('opaque profile IDs prevent A and A_B prefix collisions', () async {
    final clock = _MutableClock(DateTime(2026, 5, 2, 8));
    final profiles = ProfileService();
    await profiles.addProfile('A');
    final learnerAId = (await profiles.getActiveProfileId())!;
    final service = ProgressService(now: clock.call);
    await service.registerLearningActivity(courseCode: 'IT');
    await profiles.addProfile('A_B');
    final learnerBId = (await profiles.getActiveProfileId())!;
    await service.registerLearningActivity(courseCode: 'DE');
    final prefs = await SharedPreferences.getInstance();
    final learnerBPrefix = ProfileService.prefixForProfileId(learnerBId);
    expect(prefs.getInt('${learnerBPrefix}streak_DE'), 1);

    await profiles.setActiveProfile('A');
    final exported = await LearnerBackupService().exportActiveProfile();
    final data = Map<String, dynamic>.from(exported['data'] as Map);

    expect(data['streak_IT'], 1);
    expect(data.keys.where((key) => key.startsWith('B_')), isEmpty);

    await profiles.deleteProfileById(learnerAId);

    expect(prefs.getInt('${learnerBPrefix}streak_DE'), 1);
    expect(
      prefs.getString('${learnerBPrefix}last_active_DE'),
      '2026-05-02T00:00:00.000',
    );
    expect(prefs.getStringList('${learnerBPrefix}study_days_DE'), [
      '2026-05-02',
    ]);
    final remainingLearner = ProgressService(now: clock.call);
    expect(await remainingLearner.getStreak(courseCode: 'DE'), 1);
    expect(await remainingLearner.getDaysStudied(courseCode: 'DE'), 1);
  });

  test(
    'clean-cut progress uses Lesson keys without reading Topic state',
    () async {
      final service = await progress(learner: 'Test Learner');
      const courseId = 'course/a';
      final prefs = await SharedPreferences.getInstance();
      const legacyPrefix = 'learner_Test%20Learner_';
      final prefix = await activePrefix();
      const suffix = '_course_course%2Fa';
      await prefs.setStringList('${legacyPrefix}completed_rounds$suffix', [
        'legacy_round',
      ]);
      await prefs.setStringList('${legacyPrefix}recent_rounds', [
        'course/a|legacy_round|2026-01-01T00:00:00.000|3',
      ]);
      await prefs.setStringList('${prefix}v4_completed_topics$suffix', [
        'legacy_topic',
      ]);
      await prefs.setStringList('${prefix}v4_recent_rounds', [
        jsonEncode({
          'courseId': courseId,
          'topicId': 'legacy_topic',
          'roundId': 'legacy_round',
          'completedAt': '2026-01-01T00:00:00.000',
          'errors': 3,
        }),
      ]);

      expect(await service.getCompletedRounds(courseId: courseId), isEmpty);
      expect(await service.getCompletedLessons(courseId: courseId), isEmpty);
      expect(await service.getRecentRounds(courseId: courseId), isEmpty);

      await service.completeRound(
        'round_1',
        courseId: courseId,
        courseCode: 'it',
      );
      await service.completeLesson(
        'lesson_1',
        courseId: courseId,
        courseCode: 'it',
      );
      await service.markPerfectRound('perfect_1', courseId: courseId);
      await service.markTtsSkippedPerfectRound('tts_1', courseId: courseId);
      await service.winDuel('duel_1', courseId: courseId, courseCode: 'it');
      await service.markGuidebookSeen('lesson_1', courseId: courseId);
      await service.recordRecentRound(
        courseId,
        'lesson_1',
        'round_1',
        errors: 1,
      );

      expect(prefs.getStringList('${prefix}v4_completed_rounds$suffix'), [
        'round_1',
      ]);
      expect(prefs.getStringList('${prefix}v4_completed_lessons$suffix'), [
        'lesson_1',
      ]);
      expect(prefs.getStringList('${prefix}v4_perfect_rounds$suffix'), [
        'perfect_1',
      ]);
      expect(
        prefs.getStringList('${prefix}v4_tts_skipped_perfect_rounds$suffix'),
        ['tts_1'],
      );
      expect(prefs.getStringList('${prefix}v4_won_duels$suffix'), ['duel_1']);
      expect(prefs.getStringList('${prefix}v4_seen_guidebooks$suffix'), [
        'lesson_1',
      ]);
      expect(prefs.getInt('${prefix}xp_IT'), 75);
      expect(prefs.getInt('${prefix}week_xp'), 75);
      expect(jsonDecode(prefs.getString('${prefix}week_xp_by_course')!), {
        courseId: 75,
      });
      final encodedReview = prefs.getStringList('${prefix}v4_recent_rounds')!;
      expect(encodedReview, hasLength(1));
      final reviewJson =
          jsonDecode(encodedReview.single) as Map<String, dynamic>;
      expect(reviewJson['courseId'], courseId);
      expect(reviewJson['lessonId'], 'lesson_1');
      expect(reviewJson['roundId'], 'round_1');
      expect(reviewJson['errors'], 1);
      expect(DateTime.tryParse(reviewJson['completedAt'] as String), isNotNull);
      expect(prefs.getStringList('${prefix}v4_completed_topics$suffix'), [
        'legacy_topic',
      ]);

      final exported = await LearnerBackupService().exportActiveProfile();
      expect(exported['schemaVersion'], 2);
      final backupData = Map<String, dynamic>.from(exported['data'] as Map);
      expect(backupData['v4_completed_lessons$suffix'], ['lesson_1']);
      expect(backupData['v4_completed_topics$suffix'], ['legacy_topic']);
      expect(backupData['v4_recent_rounds'], encodedReview);
      expect(
        (jsonDecode((backupData['v4_recent_rounds'] as List).single as String)
            as Map<String, dynamic>)['lessonId'],
        'lesson_1',
      );

      expect(prefs.getStringList('${legacyPrefix}completed_rounds$suffix'), [
        'legacy_round',
      ]);
      expect(prefs.getStringList('${legacyPrefix}recent_rounds'), [
        'course/a|legacy_round|2026-01-01T00:00:00.000|3',
      ]);
    },
  );

  test('finishing a Round alone does not award XP', () async {
    final service = await progress();

    await service.completeRound(
      'round_1',
      courseId: 'course_a',
      courseCode: 'IT',
    );

    expect(await service.getCompletedRounds(courseId: 'course_a'), {'round_1'});
    expect(await service.getXp(courseCode: 'IT'), 0);
    expect(await service.getWeeklyXp(), 0);
    expect(await currentWeeklyXpByCourse('Tester'), isEmpty);
  });
}
