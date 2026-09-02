import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/world_flag_entity.dart';
import 'profile_service.dart';

class FlagGameScoreRecord {
  final String learnerProfileId;
  final FlagGameMode mode;
  final int score;
  final Duration elapsedTime;
  final DateTime achievedAt;

  const FlagGameScoreRecord({
    required this.learnerProfileId,
    required this.mode,
    required this.score,
    required this.elapsedTime,
    required this.achievedAt,
  });

  String encode() => jsonEncode({
    'learnerProfileId': learnerProfileId,
    'mode': mode.name,
    'score': score,
    'elapsedMilliseconds': elapsedTime.inMilliseconds,
    'achievedAt': achievedAt.toIso8601String(),
  });

  static FlagGameScoreRecord? decode(String? raw) {
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      final learnerProfileId = value['learnerProfileId'];
      final modeName = value['mode'];
      final score = value['score'];
      final elapsedMilliseconds = value['elapsedMilliseconds'];
      final achievedAt = DateTime.tryParse(
        value['achievedAt']?.toString() ?? '',
      );
      if (learnerProfileId is! String ||
          !ProfileService.isValidLearnerProfileId(learnerProfileId) ||
          modeName is! String ||
          score is! int ||
          score < 0 ||
          score > 12 ||
          elapsedMilliseconds is! int ||
          elapsedMilliseconds < 0 ||
          achievedAt == null) {
        return null;
      }
      final mode = FlagGameMode.values
          .where((value) => value.name == modeName)
          .firstOrNull;
      if (mode == null) return null;
      return FlagGameScoreRecord(
        learnerProfileId: learnerProfileId,
        mode: mode,
        score: score,
        elapsedTime: Duration(milliseconds: elapsedMilliseconds),
        achievedAt: achievedAt,
      );
    } catch (_) {
      return null;
    }
  }
}

class FlagGameScoreEntry {
  final String learnerProfileId;
  final String displayName;
  final int score;
  final Duration elapsedTime;
  final DateTime achievedAt;

  const FlagGameScoreEntry({
    required this.learnerProfileId,
    required this.displayName,
    required this.score,
    required this.elapsedTime,
    required this.achievedAt,
  });
}

class FlagGameScoreService {
  static const keyPrefix = 'flag_game_best_';

  final ProfileService _profiles;
  final DateTime Function() _now;

  FlagGameScoreService({
    ProfileService? profileService,
    DateTime Function()? now,
  }) : _profiles = profileService ?? ProfileService(),
       _now = now ?? DateTime.now;

  String _key(String learnerProfileId, FlagGameMode mode) =>
      _profiles.keyForProfileId(learnerProfileId, '$keyPrefix${mode.name}');

  static int compareRecords(
    FlagGameScoreRecord left,
    FlagGameScoreRecord right,
  ) {
    final byScore = right.score.compareTo(left.score);
    if (byScore != 0) return byScore;
    final byTime = left.elapsedTime.compareTo(right.elapsedTime);
    if (byTime != 0) return byTime;
    return left.achievedAt.compareTo(right.achievedAt);
  }

  Future<bool> recordResult({
    required FlagGameMode mode,
    required int score,
    required Duration elapsedTime,
    DateTime? achievedAt,
  }) async {
    if (score < 0 || score > 12) {
      throw ArgumentError.value(score, 'score', 'Score must be from 0 to 12');
    }
    if (elapsedTime.isNegative) {
      throw ArgumentError.value(elapsedTime, 'elapsedTime', 'Time is negative');
    }
    final learnerProfileId = await _profiles.getActiveProfileId();
    if (learnerProfileId == null) {
      throw StateError('No active learner profile');
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _key(learnerProfileId, mode);
    final candidate = FlagGameScoreRecord(
      learnerProfileId: learnerProfileId,
      mode: mode,
      score: score,
      elapsedTime: elapsedTime,
      achievedAt: achievedAt ?? _now(),
    );
    final existing = FlagGameScoreRecord.decode(prefs.getString(key));
    if (existing != null && compareRecords(candidate, existing) >= 0) {
      return false;
    }
    await prefs.setString(key, candidate.encode());
    return true;
  }

  Future<FlagGameScoreRecord?> getBestForActive(FlagGameMode mode) async {
    final learnerProfileId = await _profiles.getActiveProfileId();
    if (learnerProfileId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return FlagGameScoreRecord.decode(
      prefs.getString(_key(learnerProfileId, mode)),
    );
  }

  Future<List<FlagGameScoreEntry>> getTopPlayers(FlagGameMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = <FlagGameScoreEntry>[];
    for (final profile in await _profiles.getProfileRecords()) {
      final record = FlagGameScoreRecord.decode(
        prefs.getString(_key(profile.learnerProfileId, mode)),
      );
      if (record == null ||
          record.learnerProfileId != profile.learnerProfileId) {
        continue;
      }
      entries.add(
        FlagGameScoreEntry(
          learnerProfileId: profile.learnerProfileId,
          displayName: profile.displayName,
          score: record.score,
          elapsedTime: record.elapsedTime,
          achievedAt: record.achievedAt,
        ),
      );
    }
    entries.sort((left, right) {
      final byScore = right.score.compareTo(left.score);
      if (byScore != 0) return byScore;
      final byTime = left.elapsedTime.compareTo(right.elapsedTime);
      if (byTime != 0) return byTime;
      final byDate = left.achievedAt.compareTo(right.achievedAt);
      if (byDate != 0) return byDate;
      return left.learnerProfileId.compareTo(right.learnerProfileId);
    });
    return List.unmodifiable(entries.take(5));
  }

  Future<Map<FlagGameMode, List<FlagGameScoreEntry>>> getScorecard() async => {
    for (final mode in FlagGameMode.values) mode: await getTopPlayers(mode),
  };
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
