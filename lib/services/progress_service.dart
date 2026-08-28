import 'package:shared_preferences/shared_preferences.dart';
import 'learner_status_events.dart';
import 'learning_activity_service.dart';
import 'profile_service.dart';
import 'xp_calculator.dart';
import 'xp_service.dart';

export 'xp_service.dart' show LocalLeaderboardEntry;

class RecentRoundEntry {
  final String courseId;
  final String roundId;
  final DateTime completedAt;
  final int errors;

  const RecentRoundEntry({
    required this.courseId,
    required this.roundId,
    required this.completedAt,
    required this.errors,
  });

  String encode() =>
      '${courseId.replaceAll('|', '')}|${roundId.replaceAll('|', '')}|${completedAt.toIso8601String()}|$errors';

  static RecentRoundEntry? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) return null;
    final dt = DateTime.tryParse(parts[2]);
    if (dt == null) return null;
    final errors = parts.length >= 4 ? int.tryParse(parts[3]) ?? 0 : 0;
    return RecentRoundEntry(
      courseId: parts[0],
      roundId: parts[1],
      completedAt: dt,
      errors: errors.clamp(0, 100000).toInt(),
    );
  }
}

/// Stores course-owned progress per learner and immutable Course ID.
///
/// Streak rule: a language streak increases only on days that language is
/// studied. Days spent studying another language freeze it. A full day with no
/// study in any language breaks every active language streak.
class ProgressService {
  static const _xpCalculator = XpCalculator();

  final _profiles = ProfileService();
  final DateTime Function() _now;
  final XpService _xp;
  final LearningActivityService _learningActivity;

  ProgressService({DateTime Function()? now}) : this._(now ?? DateTime.now);

  ProgressService._(DateTime Function() now)
    : _now = now,
      _xp = XpService(now: now),
      _learningActivity = LearningActivityService(now: now);

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();
  Future<String> _k(String base) => _profiles.key(base);
  Future<String> _ck(String base, String courseId) =>
      _k('${base}_course_${Uri.encodeComponent(courseId.trim())}');

  Future<int> getXp({required String courseCode}) =>
      _xp.getXp(courseCode: courseCode);

  Future<int> getWeeklyXp() => _xp.getWeeklyXp();

  Future<int> getLastWeekXp() => _xp.getLastWeekXp();

  Future<Map<String, int>> getLastWeekXpByCourse() =>
      _xp.getLastWeekXpByCourse();

  Future<bool> isLocalLeaderboardParticipationEnabled() async {
    final p = await _prefs;
    return p.getBool(await _k('local_leaderboard_participation')) ?? true;
  }

  Future<void> setLocalLeaderboardParticipationEnabled(bool enabled) async {
    final p = await _prefs;
    await p.setBool(await _k('local_leaderboard_participation'), enabled);
  }

  Future<List<LocalLeaderboardEntry>> getLastWeekLocalLeaderboard() async {
    final entries = await _xp.getLastWeekLocalLeaderboard();
    final p = await _prefs;
    final participating = <LocalLeaderboardEntry>[];
    for (final entry in entries) {
      final prefix = 'learner_${Uri.encodeComponent(entry.learnerName)}_';
      final participates =
          p.getBool('${prefix}local_leaderboard_participation') ?? true;
      if (!participates) continue;
      participating.add(entry);
    }
    return participating;
  }

  Future<bool> isWeeklyGoalCelebrated() => _xp.isWeeklyGoalCelebrated();

  Future<void> markWeeklyGoalCelebrated() => _xp.markWeeklyGoalCelebrated();

  Future<void> addXp(
    int amount, {
    required String courseCode,
    required String courseId,
  }) => _xp.addXp(amount, courseCode: courseCode, courseId: courseId);

  Future<int> getDaysStudied({required String courseCode}) =>
      _learningActivity.getDaysStudied(courseCode: courseCode);

  Future<int> getStreak({required String courseCode}) =>
      _learningActivity.getStreak(courseCode: courseCode);

  Future<void> registerLearningActivity({required String courseCode}) =>
      _learningActivity.registerLearningActivity(courseCode: courseCode);

  Future<Set<String>> getCompletedRounds({required String courseId}) async {
    final p = await _prefs;
    return (p.getStringList(await _ck('completed_rounds', courseId)) ?? [])
        .toSet();
  }

  Future<void> completeRound(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    final p = await _prefs;
    final k = await _ck('completed_rounds', courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(id);
    await p.setStringList(k, ids.toList());
    await registerLearningActivity(courseCode: courseCode);
  }

  /// Records the latest result for one distinct round. Review keeps at most
  /// 50 distinct rounds per learner and target language. The newest result
  /// replaces the previous one for prioritization.
  Future<void> recordRecentRound(
    String courseId,
    String roundId, {
    required int errors,
  }) async {
    final p = await _prefs;
    final k = await _k('recent_rounds');
    final existing = (p.getStringList(k) ?? [])
        .map(RecentRoundEntry.decode)
        .whereType<RecentRoundEntry>()
        .where((e) => !(e.courseId == courseId && e.roundId == roundId))
        .toList();
    existing.add(
      RecentRoundEntry(
        courseId: courseId,
        roundId: roundId,
        completedAt: _now(),
        errors: errors.clamp(0, 100000).toInt(),
      ),
    );

    // Keep up to 50 distinct rounds for each course, while preserving entries from other courses.
    final thisLanguage = existing.where((e) => e.courseId == courseId).toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final keepIds = thisLanguage.length <= 50
        ? thisLanguage.map((e) => e.roundId).toSet()
        : thisLanguage
              .sublist(thisLanguage.length - 50)
              .map((e) => e.roundId)
              .toSet();
    final kept = existing
        .where((e) => e.courseId != courseId || keepIds.contains(e.roundId))
        .toList();
    await p.setStringList(k, kept.map((e) => e.encode()).toList());
  }

  /// Returns up to [limit] distinct recent rounds, prioritized by the number
  /// of errors in the latest attempt. Ties are resolved by recency.
  Future<List<RecentRoundEntry>> getRecentRounds({
    String? courseId,
    int limit = 50,
  }) async {
    final p = await _prefs;
    final k = await _k('recent_rounds');
    var entries = (p.getStringList(k) ?? [])
        .map(RecentRoundEntry.decode)
        .whereType<RecentRoundEntry>()
        .toList();
    if (courseId != null && courseId.isNotEmpty) {
      entries = entries.where((e) => e.courseId == courseId).toList();
    }
    entries.sort((a, b) {
      final byErrors = b.errors.compareTo(a.errors);
      if (byErrors != 0) return byErrors;
      return b.completedAt.compareTo(a.completedAt);
    });
    if (entries.length > limit) entries = entries.sublist(0, limit);
    return entries;
  }

  Future<Set<String>> getPerfectRounds({required String courseId}) async {
    final p = await _prefs;
    return (p.getStringList(await _ck('perfect_rounds', courseId)) ?? [])
        .toSet();
  }

  /// A laurel crown is permanent once earned.
  Future<bool> markPerfectRound(
    String roundId, {
    required String courseId,
  }) async {
    final p = await _prefs;
    final k = await _ck('perfect_rounds', courseId);
    final ids = (p.getStringList(k) ?? []).toSet();
    final newlyEarned = ids.add(roundId);
    await p.setStringList(k, ids.toList());
    // A full perfect result supersedes the provisional TTS-skipped indicator.
    final skippedKey = await _ck('tts_skipped_perfect_rounds', courseId);
    final skipped = (p.getStringList(skippedKey) ?? []).toSet()
      ..remove(roundId);
    await p.setStringList(skippedKey, skipped.toList());
    if (newlyEarned) {
      LearnerStatusEvents.publish(LearnerStatusInvalidation.laurels);
    }
    return newlyEarned;
  }

  Future<Set<String>> getTtsSkippedPerfectRounds({
    required String courseId,
  }) async {
    final p = await _prefs;
    return (p.getStringList(
              await _ck('tts_skipped_perfect_rounds', courseId),
            ) ??
            [])
        .toSet();
  }

  Future<void> markTtsSkippedPerfectRound(
    String roundId, {
    required String courseId,
  }) async {
    if ((await getPerfectRounds(courseId: courseId)).contains(roundId)) return;
    final p = await _prefs;
    final k = await _ck('tts_skipped_perfect_rounds', courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(roundId);
    await p.setStringList(k, ids.toList());
  }

  Future<Set<String>> getCompletedTopics({required String courseId}) async {
    final p = await _prefs;
    return (p.getStringList(await _ck('completed_topics', courseId)) ?? [])
        .toSet();
  }

  Future<void> completeTopic(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    final p = await _prefs;
    final k = await _ck('completed_topics', courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(id);
    await p.setStringList(k, ids.toList());
    await registerLearningActivity(courseCode: courseCode);
    await addXp(
      _xpCalculator.calculateTopicCompletionAward(),
      courseCode: courseCode,
      courseId: courseId,
    );
  }

  Future<Set<String>> getWonDuels({required String courseId}) async {
    final p = await _prefs;
    return (p.getStringList(await _ck('won_duels', courseId)) ?? []).toSet();
  }

  Future<void> winDuel(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    final p = await _prefs;
    final k = await _ck('won_duels', courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(id);
    await p.setStringList(k, ids.toList());
    await registerLearningActivity(courseCode: courseCode);
    await addXp(
      _xpCalculator.calculateDuelWinAward(),
      courseCode: courseCode,
      courseId: courseId,
    );
  }

  /// One learner-level notice explains that every learning Topic has its own Guidebook.
  /// It is independent of language progress and is shown only once.
  Future<bool> hasSeenGuidebookAvailabilityNotice() async {
    final p = await _prefs;
    return p.getBool(await _k('guidebook_availability_notice_seen')) ?? false;
  }

  Future<void> markGuidebookAvailabilityNoticeSeen() async {
    final p = await _prefs;
    await p.setBool(await _k('guidebook_availability_notice_seen'), true);
  }

  Future<bool> hasSeenGuidebook(
    String chapterId, {
    required String courseId,
  }) async {
    final p = await _prefs;
    final ids = (p.getStringList(await _ck('seen_guidebooks', courseId)) ?? [])
        .toSet();
    return ids.contains(chapterId);
  }

  Future<void> markGuidebookSeen(
    String chapterId, {
    required String courseId,
  }) async {
    final p = await _prefs;
    final k = await _ck('seen_guidebooks', courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(chapterId);
    await p.setStringList(k, ids.toList());
  }

  /// Resets exactly one course without clearing language-scoped study history.
  ///
  /// Profile identity, avatar appearance, device settings and Course Editor
  /// overrides are deliberately untouched. Global study-day history is kept,
  /// because those days really did contain study and can legitimately freeze
  /// streaks in the learner's other languages.
  Future<void> resetCourse(String courseId) async {
    final p = await _prefs;
    final active = await _profiles.getActiveProfile() ?? 'default';
    final prefix = 'learner_${Uri.encodeComponent(active)}_';
    final suffix = '_course_${Uri.encodeComponent(courseId.trim())}';
    final keys = p
        .getKeys()
        .where((k) => k.startsWith(prefix) && k.endsWith(suffix))
        .toList();
    for (final key in keys) {
      await p.remove(key);
    }

    final recentKey = await _k('recent_rounds');
    final recent = (p.getStringList(recentKey) ?? [])
        .map(RecentRoundEntry.decode)
        .whereType<RecentRoundEntry>()
        .where((e) => e.courseId != courseId)
        .map((e) => e.encode())
        .toList();
    await p.setStringList(recentKey, recent);
  }
}
