import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'learner_status_events.dart';
import 'learning_activity_service.dart';
import 'profile_service.dart';
import 'xp_calculator.dart';
import 'xp_service.dart';

export 'xp_service.dart' show LocalLeaderboardEntry;

class RecentRoundEntry {
  final String courseId;
  final String topicId;
  final String roundId;
  final DateTime completedAt;
  final int errors;

  const RecentRoundEntry({
    required this.courseId,
    required this.topicId,
    required this.roundId,
    required this.completedAt,
    required this.errors,
  });

  String encode() => jsonEncode({
    'courseId': courseId,
    'topicId': topicId,
    'roundId': roundId,
    'completedAt': completedAt.toIso8601String(),
    'errors': errors,
  });

  static RecentRoundEntry? decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final courseId = decoded['courseId'];
      final topicId = decoded['topicId'];
      final roundId = decoded['roundId'];
      final completedAt = decoded['completedAt'];
      final errors = decoded['errors'];
      if (courseId is! String ||
          courseId.trim().isEmpty ||
          topicId is! String ||
          topicId.trim().isEmpty ||
          roundId is! String ||
          roundId.trim().isEmpty ||
          completedAt is! String ||
          errors is! int) {
        return null;
      }
      final parsedCompletedAt = DateTime.tryParse(completedAt);
      if (parsedCompletedAt == null) return null;
      return RecentRoundEntry(
        courseId: courseId,
        topicId: topicId,
        roundId: roundId,
        completedAt: parsedCompletedAt,
        errors: errors.clamp(0, 100000).toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Stores course-owned progress per learner and immutable Course ID.
///
/// Streak rule: a language streak increases only on days that language is
/// studied. Days spent studying another language freeze it. A full day with no
/// study in any language breaks every active language streak.
class ProgressService {
  static const _xpCalculator = XpCalculator();
  static const _completedRoundsKey = 'v4_completed_rounds';
  static const _perfectRoundsKey = 'v4_perfect_rounds';
  static const _ttsSkippedPerfectRoundsKey = 'v4_tts_skipped_perfect_rounds';
  static const _completedTopicsKey = 'v4_completed_topics';
  static const _wonDuelsKey = 'v4_won_duels';
  static const _seenGuidebooksKey = 'v4_seen_guidebooks';
  static const _recentRoundsKey = 'v4_recent_rounds';
  static const _courseProgressKeyBases = <String>[
    _completedRoundsKey,
    _perfectRoundsKey,
    _ttsSkippedPerfectRoundsKey,
    _completedTopicsKey,
    _wonDuelsKey,
    _seenGuidebooksKey,
  ];

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
    return (p.getStringList(await _ck(_completedRoundsKey, courseId)) ?? [])
        .toSet();
  }

  Future<void> completeRound(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    final p = await _prefs;
    final k = await _ck(_completedRoundsKey, courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(id);
    await p.setStringList(k, ids.toList());
    await registerLearningActivity(courseCode: courseCode);
  }

  /// Records the latest result for one distinct round. Review keeps at most
  /// 50 distinct rounds per learner and Course. The newest result
  /// replaces the previous one for prioritization.
  Future<void> recordRecentRound(
    String courseId,
    String topicId,
    String roundId, {
    required int errors,
  }) async {
    final p = await _prefs;
    final k = await _k(_recentRoundsKey);
    final existing = (p.getStringList(k) ?? [])
        .map(RecentRoundEntry.decode)
        .whereType<RecentRoundEntry>()
        .where((e) => !(e.courseId == courseId && e.roundId == roundId))
        .toList();
    existing.add(
      RecentRoundEntry(
        courseId: courseId,
        topicId: topicId,
        roundId: roundId,
        completedAt: _now(),
        errors: errors.clamp(0, 100000).toInt(),
      ),
    );

    // Keep up to 50 distinct rounds for each course, while preserving entries from other courses.
    final thisCourse = existing.where((e) => e.courseId == courseId).toList()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final keepIds = thisCourse.length <= 50
        ? thisCourse.map((e) => e.roundId).toSet()
        : thisCourse
              .sublist(thisCourse.length - 50)
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
    final k = await _k(_recentRoundsKey);
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
    return (p.getStringList(await _ck(_perfectRoundsKey, courseId)) ?? [])
        .toSet();
  }

  /// A laurel crown is permanent once earned.
  Future<bool> markPerfectRound(
    String roundId, {
    required String courseId,
  }) async {
    final p = await _prefs;
    final k = await _ck(_perfectRoundsKey, courseId);
    final ids = (p.getStringList(k) ?? []).toSet();
    final newlyEarned = ids.add(roundId);
    await p.setStringList(k, ids.toList());
    // A full perfect result supersedes the provisional TTS-skipped indicator.
    final skippedKey = await _ck(_ttsSkippedPerfectRoundsKey, courseId);
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
    return (p.getStringList(await _ck(_ttsSkippedPerfectRoundsKey, courseId)) ??
            [])
        .toSet();
  }

  Future<void> markTtsSkippedPerfectRound(
    String roundId, {
    required String courseId,
  }) async {
    if ((await getPerfectRounds(courseId: courseId)).contains(roundId)) return;
    final p = await _prefs;
    final k = await _ck(_ttsSkippedPerfectRoundsKey, courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(roundId);
    await p.setStringList(k, ids.toList());
  }

  Future<Set<String>> getCompletedTopics({required String courseId}) async {
    final p = await _prefs;
    return (p.getStringList(await _ck(_completedTopicsKey, courseId)) ?? [])
        .toSet();
  }

  Future<int> completeTopic(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    final p = await _prefs;
    final k = await _ck(_completedTopicsKey, courseId);
    final ids = (p.getStringList(k) ?? []).toSet();
    final isFirstCompletion = ids.add(id);
    await p.setStringList(k, ids.toList());
    await registerLearningActivity(courseCode: courseCode);
    final award = _xpCalculator.calculateTopicCompletionAward(
      isFirstCompletion: isFirstCompletion,
    );
    if (award > 0) {
      await addXp(award, courseCode: courseCode, courseId: courseId);
    }
    return award;
  }

  Future<Set<String>> getWonDuels({required String courseId}) async {
    final p = await _prefs;
    return (p.getStringList(await _ck(_wonDuelsKey, courseId)) ?? []).toSet();
  }

  Future<int> winDuel(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    final p = await _prefs;
    final k = await _ck(_wonDuelsKey, courseId);
    final ids = (p.getStringList(k) ?? []).toSet();
    final wasPreviouslyWon = !ids.add(id);
    await p.setStringList(k, ids.toList());
    await registerLearningActivity(courseCode: courseCode);
    final award = _xpCalculator.calculateDuelWinAward(
      wasPreviouslyWon: wasPreviouslyWon,
    );
    await addXp(award, courseCode: courseCode, courseId: courseId);
    return award;
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
    String topicId, {
    required String courseId,
  }) async {
    final p = await _prefs;
    final ids = (p.getStringList(await _ck(_seenGuidebooksKey, courseId)) ?? [])
        .toSet();
    return ids.contains(topicId);
  }

  Future<void> markGuidebookSeen(
    String topicId, {
    required String courseId,
  }) async {
    final p = await _prefs;
    final k = await _ck(_seenGuidebooksKey, courseId);
    final ids = (p.getStringList(k) ?? []).toSet()..add(topicId);
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
    for (final base in _courseProgressKeyBases) {
      await p.remove(await _ck(base, courseId));
    }

    final recentKey = await _k(_recentRoundsKey);
    final recent = (p.getStringList(recentKey) ?? [])
        .map(RecentRoundEntry.decode)
        .whereType<RecentRoundEntry>()
        .where((e) => e.courseId != courseId)
        .map((e) => e.encode())
        .toList();
    await p.setStringList(recentKey, recent);
  }
}
