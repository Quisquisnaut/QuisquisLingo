import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/xp_service.dart';
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

  Future<Map<String, int>> currentBreakdown(String learner) async {
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

  test(
    'language XP and learner-global weekly XP persist with a course breakdown',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 24, 12));
      await addProfile('Alice');
      final service = XpService(now: clock.call);

      await service.addXp(20, courseCode: 'it', courseId: 'course_a');
      await service.addXp(5, courseCode: 'IT', courseId: 'course_a');
      await service.addXp(30, courseCode: 'DE', courseId: 'course_b');

      final reloaded = XpService(now: clock.call);
      expect(await reloaded.getXp(courseCode: 'IT'), 25);
      expect(await reloaded.getXp(courseCode: 'it'), 25);
      expect(await reloaded.getXp(courseCode: 'DE'), 30);
      expect(await reloaded.getWeeklyXp(), 55);
      expect(await currentBreakdown('Alice'), {'course_a': 25, 'course_b': 30});

      await addProfile('Bob');
      expect(await reloaded.getXp(courseCode: 'IT'), 0);
      expect(await reloaded.getWeeklyXp(), 0);
      expect(await currentBreakdown('Bob'), isEmpty);
    },
  );

  test('addXp rejects negatives and preserves the 203 integer cap', () async {
    final clock = _MutableClock(DateTime(2026, 8, 24, 12));
    await addProfile('Tester');
    final learnerPrefix = ProfileService.prefixForProfileId(
      (await ProfileService().getActiveProfileId())!,
    );
    final service = XpService(now: clock.call);
    final prefs = await SharedPreferences.getInstance();

    await service.getWeeklyXp();
    await prefs.setInt('${learnerPrefix}xp_IT', 2147483643);
    await prefs.setInt('${learnerPrefix}week_xp', 2147483642);
    await prefs.setString(
      '${learnerPrefix}week_xp_by_course',
      jsonEncode({'course_a': 2147483641}),
    );

    await expectLater(
      service.addXp(-1, courseCode: 'IT', courseId: 'course_a'),
      throwsArgumentError,
    );
    expect(await service.getXp(courseCode: 'IT'), 2147483643);
    expect(await service.getWeeklyXp(), 2147483642);
    expect(await currentBreakdown('Tester'), {'course_a': 2147483641});

    await service.addXp(10, courseCode: 'IT', courseId: 'course_a');
    expect(await service.getXp(courseCode: 'IT'), 2147483647);
    expect(await service.getWeeklyXp(), 2147483647);
    expect(await currentBreakdown('Tester'), {'course_a': 2147483647});
  });

  test(
    'Sunday rollover preserves previous-week total and course breakdown',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 22, 23, 59));
      await addProfile('Tester');
      final service = XpService(now: clock.call);

      await service.addXp(25, courseCode: 'IT', courseId: 'course_a');
      await service.addXp(30, courseCode: 'DE', courseId: 'course_b');
      clock.value = DateTime(2026, 8, 23);

      expect(await service.getWeeklyXp(), 0);
      expect(await service.getLastWeekXp(), 55);
      expect(await service.getLastWeekXpByCourse(), {
        'course_a': 25,
        'course_b': 30,
      });
      expect(await currentBreakdown('Tester'), isEmpty);
    },
  );

  test(
    'a skipped week clears last-week XP without erasing language XP',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 15, 12));
      await addProfile('Tester');
      final service = XpService(now: clock.call);

      await service.addXp(40, courseCode: 'IT', courseId: 'old_course');
      clock.value = DateTime(2026, 8, 23, 12);

      expect(await service.getWeeklyXp(), 0);
      expect(await service.getLastWeekXp(), 0);
      expect(await service.getLastWeekXpByCourse(), isEmpty);
      expect(await service.getXp(courseCode: 'IT'), 40);
    },
  );

  test(
    'XpService calculates leaderboard XP while ProgressService applies participation',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 22, 12));
      final profiles = ProfileService();
      final xp = XpService(now: clock.call);
      final progress = ProgressService(now: clock.call);

      await addProfile('Alice');
      await xp.addXp(10, courseCode: 'IT', courseId: 'alice_course');
      await addProfile('Bob');
      await xp.addXp(20, courseCode: 'DE', courseId: 'bob_course');
      await progress.setLocalLeaderboardParticipationEnabled(false);

      clock.value = DateTime(2026, 8, 23, 12);
      final allXpEntries = await xp.getLastWeekLocalLeaderboard();
      expect(allXpEntries.map((entry) => '${entry.learnerName}:${entry.xp}'), [
        'Bob:20',
        'Alice:10',
      ]);

      await profiles.setActiveProfile('Alice');
      final participating = await progress.getLastWeekLocalLeaderboard();
      expect(participating.map((entry) => '${entry.learnerName}:${entry.xp}'), [
        'Alice:10',
      ]);
      await profiles.setActiveProfile('Bob');
      expect(await progress.isLocalLeaderboardParticipationEnabled(), isFalse);
    },
  );

  test('weekly-goal celebration remains week- and profile-scoped', () async {
    final clock = _MutableClock(DateTime(2026, 8, 22, 23, 59));
    final profiles = ProfileService();
    await addProfile('Alice');
    final service = XpService(now: clock.call);

    await service.markWeeklyGoalCelebrated();
    expect(await service.isWeeklyGoalCelebrated(), isTrue);

    await addProfile('Bob');
    expect(await service.isWeeklyGoalCelebrated(), isFalse);
    await profiles.setActiveProfile('Alice');
    expect(await service.isWeeklyGoalCelebrated(), isTrue);

    clock.value = DateTime(2026, 8, 23);
    expect(await service.isWeeklyGoalCelebrated(), isFalse);
  });
}
