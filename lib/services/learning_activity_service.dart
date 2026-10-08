import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';
import 'learner_status_events.dart';
import 'learning_language_identity.dart';

class LanguageLearningStatistics {
  final String languageId;
  final int studyDays;
  final int currentStreak;
  final int maxStreak;

  const LanguageLearningStatistics({
    required this.languageId,
    required this.studyDays,
    required this.currentStreak,
    required this.maxStreak,
  });
}

class LearnerStatistics {
  final int totalStudyDays;
  final List<LanguageLearningStatistics> languages;

  const LearnerStatistics({
    required this.totalStudyDays,
    required this.languages,
  });
}

/// Stores learner activity and language-streak state.
class LearningActivityService {
  final _profiles = ProfileService();
  final DateTime Function() _now;

  LearningActivityService({required DateTime Function() now}) : _now = now;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();
  Future<String> _k(String base) => _profiles.key(base);
  String _code(String courseCode) =>
      LearningLanguageIdentity.storageId(courseCode);
  Future<String> _lk(String base, String courseCode) =>
      _k('${base}_${_code(courseCode)}');

  String _dayString(DateTime dt) {
    final d = DateTime(dt.year, dt.month, dt.day);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDay(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);

  Set<String> _validDayKeys(Iterable<String> values) {
    final valid = <String>{};
    for (final value in values) {
      final parsed = _parseDay(value);
      if (parsed != null && _dayString(parsed) == value) valid.add(value);
    }
    return valid;
  }

  int _storedStreak(SharedPreferences preferences, String key) =>
      (preferences.getInt(key) ?? 0).clamp(0, 2147483647).toInt();

  Future<Set<String>> _globalStudyDays() async {
    final p = await _prefs;
    return _validDayKeys(
      p.getStringList(await _k('study_days_all')) ?? const <String>[],
    );
  }

  Future<Set<String>> _languageStudyDays(String courseCode) async {
    final p = await _prefs;
    return _validDayKeys(
      p.getStringList(await _lk('study_days', courseCode)) ?? const <String>[],
    );
  }

  Future<int> getDaysStudied({required String courseCode}) async =>
      (await _languageStudyDays(courseCode)).length;

  Future<int> getTotalStudyDays() async => (await _globalStudyDays()).length;

  Future<LearnerStatistics> getStatistics() async {
    final p = await _prefs;
    final activeId = await _profiles.getActiveProfileId();
    if (activeId == null) {
      return const LearnerStatistics(totalStudyDays: 0, languages: []);
    }
    final prefix = ProfileService.prefixForProfileId(activeId);
    final studyDaysPrefix = '${prefix}study_days_';
    final daysByLanguage = <String, Set<String>>{};
    for (final key in p.getKeys()) {
      if (!key.startsWith(studyDaysPrefix) ||
          key == '${prefix}study_days_all') {
        continue;
      }
      final languageId = LearningLanguageIdentity.canonicalId(
        key.substring(studyDaysPrefix.length),
      );
      if (languageId.isEmpty) continue;
      daysByLanguage
          .putIfAbsent(languageId, () => <String>{})
          .addAll(_validDayKeys(p.getStringList(key) ?? const <String>[]));
    }

    final globalDays = await _globalStudyDays();
    final statistics = <LanguageLearningStatistics>[];
    for (final entry in daysByLanguage.entries) {
      final streaks = _deriveStreaks(
        languageDays: entry.value,
        globalDays: globalDays,
      );
      statistics.add(
        LanguageLearningStatistics(
          languageId: entry.key,
          studyDays: entry.value.length,
          currentStreak: streaks.$1,
          maxStreak: streaks.$2,
        ),
      );
    }
    statistics.sort(
      (a, b) => LearningLanguageIdentity.displayName(
        a.languageId,
      ).compareTo(LearningLanguageIdentity.displayName(b.languageId)),
    );
    return LearnerStatistics(
      totalStudyDays: globalDays.length,
      languages: List.unmodifiable(statistics),
    );
  }

  (int, int) _deriveStreaks({
    required Set<String> languageDays,
    required Set<String> globalDays,
  }) {
    final days = languageDays.map(_parseDay).whereType<DateTime>().toList()
      ..sort();
    if (days.isEmpty) return (0, 0);

    var run = 0;
    var maxRun = 0;
    DateTime? previous;
    for (final day in days) {
      final continues =
          previous != null &&
          _allIntermediateDaysStudied(previous, day, globalDays);
      run = continues ? run + 1 : 1;
      if (run > maxRun) maxRun = run;
      previous = day;
    }

    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _allIntermediateDaysStudied(days.last, today, globalDays)
        ? run
        : 0;
    return (current, maxRun);
  }

  bool _allIntermediateDaysStudied(
    DateTime from,
    DateTime to,
    Set<String> globalDays,
  ) {
    for (
      var day = from.add(const Duration(days: 1));
      day.isBefore(to);
      day = day.add(const Duration(days: 1))
    ) {
      if (!globalDays.contains(_dayString(day))) return false;
    }
    return true;
  }

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
    return _storedStreak(p, streakKey);
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
      if (today.isAfter(lastDay)) {
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
          uninterrupted ? _storedStreak(p, streakKey) + 1 : 1,
        );
      }
    }

    // A corrected device clock can move backward. Preserve the authoritative
    // latest activity boundary so a historical date cannot manufacture a
    // streak increment or make future consecutive-day checks run backward.
    if (last == null ||
        !today.isBefore(DateTime(last.year, last.month, last.day))) {
      await p.setString(lastKey, today.toIso8601String());
    }
    global.add(todayKey);
    await p.setStringList(await _k('study_days_all'), global.toList()..sort());
    final languageDays = await _languageStudyDays(code);
    languageDays.add(todayKey);
    await p.setStringList(
      await _lk('study_days', code),
      languageDays.toList()..sort(),
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activity);
  }
}
