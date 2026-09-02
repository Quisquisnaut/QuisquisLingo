import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';
import 'learner_status_events.dart';

class LocalLeaderboardEntry {
  final String learnerProfileId;
  final String learnerName;
  final int xp;

  const LocalLeaderboardEntry({
    required this.learnerProfileId,
    required this.learnerName,
    required this.xp,
  });
}

/// Stores learner XP totals and weekly XP accounting.
class XpService {
  final _profiles = ProfileService();
  final DateTime Function() _now;

  XpService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();
  Future<String> _k(String base) => _profiles.key(base);
  String _code(String courseCode) => courseCode.trim().toUpperCase();
  Future<String> _lk(String base, String courseCode) =>
      _k('${base}_${_code(courseCode)}');

  String _dayString(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _weekKey(DateTime now) {
    final sunday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday % 7));
    return _dayString(sunday);
  }

  Map<String, int> _decodeXpByCourse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, int>{};
      final result = <String, int>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is int && value >= 0) result[entry.key.toString()] = value;
      }
      return result;
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _ensureWeeklyRollover() async {
    final p = await _prefs;
    final now = _now();
    final currentWeek = _weekKey(now);
    final previousWeek = _weekKey(now.subtract(const Duration(days: 7)));
    final weekKey = await _k('week_xp_week');
    final totalKey = await _k('week_xp');
    final byCourseKey = await _k('week_xp_by_course');
    final storedWeek = p.getString(weekKey);
    if (storedWeek == currentWeek) return;

    final lastWeekKey = await _k('last_week_xp_week');
    final lastTotalKey = await _k('last_week_xp');
    final lastByCourseKey = await _k('last_week_xp_by_course');
    if (storedWeek == previousWeek) {
      await p.setString(lastWeekKey, previousWeek);
      await p.setInt(lastTotalKey, p.getInt(totalKey) ?? 0);
      await p.setString(lastByCourseKey, p.getString(byCourseKey) ?? '{}');
    } else {
      // If the app was not used during the immediately preceding week, that
      // completed week has no XP. Older activity must not be presented as last week.
      await p.setString(lastWeekKey, previousWeek);
      await p.setInt(lastTotalKey, 0);
      await p.setString(lastByCourseKey, '{}');
    }

    await p.setString(weekKey, currentWeek);
    await p.setInt(totalKey, 0);
    await p.setString(byCourseKey, '{}');
  }

  Future<void> _ensureWeeklyRolloverForProfile(
    SharedPreferences p,
    String learnerProfileId,
  ) async {
    final prefix = ProfileService.prefixForProfileId(learnerProfileId);
    final now = _now();
    final currentWeek = _weekKey(now);
    final previousWeek = _weekKey(now.subtract(const Duration(days: 7)));
    final storedWeek = p.getString('${prefix}week_xp_week');
    if (storedWeek == currentWeek) return;
    if (storedWeek == previousWeek) {
      await p.setString('${prefix}last_week_xp_week', previousWeek);
      await p.setInt(
        '${prefix}last_week_xp',
        p.getInt('${prefix}week_xp') ?? 0,
      );
      await p.setString(
        '${prefix}last_week_xp_by_course',
        p.getString('${prefix}week_xp_by_course') ?? '{}',
      );
    } else {
      await p.setString('${prefix}last_week_xp_week', previousWeek);
      await p.setInt('${prefix}last_week_xp', 0);
      await p.setString('${prefix}last_week_xp_by_course', '{}');
    }
    await p.setString('${prefix}week_xp_week', currentWeek);
    await p.setInt('${prefix}week_xp', 0);
    await p.setString('${prefix}week_xp_by_course', '{}');
  }

  Future<int> getXp({required String courseCode}) async {
    final p = await _prefs;
    return p.getInt(await _lk('xp', courseCode)) ?? 0;
  }

  Future<int> getWeeklyXp() async {
    await _ensureWeeklyRollover();
    final p = await _prefs;
    return p.getInt(await _k('week_xp')) ?? 0;
  }

  Future<int> getLastWeekXp() async {
    await _ensureWeeklyRollover();
    final p = await _prefs;
    return p.getInt(await _k('last_week_xp')) ?? 0;
  }

  Future<Map<String, int>> getLastWeekXpByCourse() async {
    await _ensureWeeklyRollover();
    final p = await _prefs;
    return _decodeXpByCourse(p.getString(await _k('last_week_xp_by_course')));
  }

  /// Returns last-week XP rankings before ProgressService applies the existing
  /// learner participation preference.
  Future<List<LocalLeaderboardEntry>> getLastWeekLocalLeaderboard() async {
    await _ensureWeeklyRollover();
    final p = await _prefs;
    final profiles = await _profiles.getProfileRecords();
    final entries = <LocalLeaderboardEntry>[];
    for (final profile in profiles) {
      await _ensureWeeklyRolloverForProfile(p, profile.learnerProfileId);
      final prefix = ProfileService.prefixForProfileId(
        profile.learnerProfileId,
      );
      final xp = p.getInt('${prefix}last_week_xp') ?? 0;
      entries.add(
        LocalLeaderboardEntry(
          learnerProfileId: profile.learnerProfileId,
          learnerName: profile.displayName,
          xp: xp,
        ),
      );
    }
    entries.sort((a, b) {
      final byXp = b.xp.compareTo(a.xp);
      if (byXp != 0) return byXp;
      final byName = a.learnerName.toLowerCase().compareTo(
        b.learnerName.toLowerCase(),
      );
      if (byName != 0) return byName;
      return a.learnerProfileId.compareTo(b.learnerProfileId);
    });
    return entries;
  }

  Future<bool> isWeeklyGoalCelebrated() async {
    final p = await _prefs;
    final wk = _weekKey(_now());
    return p.getString(await _k('week_goal_celebrated_week')) == wk;
  }

  Future<void> markWeeklyGoalCelebrated() async {
    final p = await _prefs;
    await p.setString(await _k('week_goal_celebrated_week'), _weekKey(_now()));
  }

  Future<void> addXp(
    int amount, {
    required String courseCode,
    required String courseId,
  }) async {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'XP cannot be negative');
    }
    final p = await _prefs;
    final k = await _lk('xp', courseCode);
    final current = p.getInt(k) ?? 0;
    // Keep the value inside a predictable range even if an editor/test produces
    // an unexpectedly large reward.
    await p.setInt(k, (current + amount).clamp(0, 2147483647).toInt());
    final weekCurrent = await getWeeklyXp();
    await p.setInt(
      await _k('week_xp'),
      (weekCurrent + amount).clamp(0, 2147483647).toInt(),
    );

    final stableCourseId = courseId.trim();
    final byCourseKey = await _k('week_xp_by_course');
    final byCourse = _decodeXpByCourse(p.getString(byCourseKey));
    final old = byCourse[stableCourseId] ?? 0;
    byCourse[stableCourseId] = (old + amount).clamp(0, 2147483647).toInt();
    await p.setString(byCourseKey, jsonEncode(byCourse));
    LearnerStatusEvents.publish(LearnerStatusInvalidation.xp);
  }
}
