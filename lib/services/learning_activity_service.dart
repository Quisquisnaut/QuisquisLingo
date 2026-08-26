import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';

/// Stores learner activity and language-streak state.
class LearningActivityService {
  final _profiles = ProfileService();
  final DateTime Function() _now;

  LearningActivityService({required DateTime Function() now}) : _now = now;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();
  Future<String> _k(String base) => _profiles.key(base);
  String _code(String courseCode) => courseCode.trim().toUpperCase();
  Future<String> _lk(String base, String courseCode) =>
      _k('${base}_${_code(courseCode)}');

  String _dayString(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDay(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  Future<Set<String>> _globalStudyDays() async {
    final p = await _prefs;
    return (p.getStringList(await _k('study_days_all')) ?? []).toSet();
  }

  Future<Set<String>> _languageStudyDays(String courseCode) async {
    final p = await _prefs;
    return (p.getStringList(await _lk('study_days', courseCode)) ?? []).toSet();
  }

  Future<int> getDaysStudied({required String courseCode}) async =>
      (await _languageStudyDays(courseCode)).length;

  Future<int> getStreak({required String courseCode}) async {
    final p = await _prefs;
    final streakKey = await _lk('streak', courseCode);
    final lastKey = await _lk('last_active', courseCode);
    final last = _parseDay(p.getString(lastKey));
    if (last == null) return 0;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final global = await _globalStudyDays();
    // Only completed days can break a streak. Today is allowed to be unfinished.
    for (
      var d = last.add(const Duration(days: 1));
      d.isBefore(today);
      d = d.add(const Duration(days: 1))
    ) {
      if (!global.contains(_dayString(d))) {
        await p.setInt(streakKey, 0);
        return 0;
      }
    }
    return p.getInt(streakKey) ?? 0;
  }

  Future<void> registerLearningActivity({required String courseCode}) async {
    final p = await _prefs;
    final code = _code(courseCode);
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dayString(today);
    final streakKey = await _lk('streak', code);
    final lastKey = await _lk('last_active', code);
    final last = _parseDay(p.getString(lastKey));
    final global = await _globalStudyDays();

    if (last == null) {
      await p.setInt(streakKey, 1);
    } else {
      final lastDay = DateTime(last.year, last.month, last.day);
      if (lastDay != today) {
        var uninterrupted = true;
        for (
          var d = lastDay.add(const Duration(days: 1));
          d.isBefore(today);
          d = d.add(const Duration(days: 1))
        ) {
          if (!global.contains(_dayString(d))) {
            uninterrupted = false;
            break;
          }
        }
        await p.setInt(
          streakKey,
          uninterrupted ? (p.getInt(streakKey) ?? 0) + 1 : 1,
        );
      }
    }

    await p.setString(lastKey, today.toIso8601String());
    global.add(todayKey);
    await p.setStringList(await _k('study_days_all'), global.toList()..sort());
    final languageDays = await _languageStudyDays(code);
    languageDays.add(todayKey);
    await p.setStringList(
      await _lk('study_days', code),
      languageDays.toList()..sort(),
    );
  }
}
