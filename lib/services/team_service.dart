import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/authoring_team.dart';
import 'formal_name_policy.dart';
import 'profile_service.dart';

/// Offline authoring-team membership and administration.
///
/// Teams reference opaque local learner-profile IDs. Credits and course JSON
/// author strings are never consulted for membership or authorization.
class TeamService {
  static const storageKey = AuthoringTeam.storageKey;

  TeamService({
    ProfileService? profileService,
    String Function()? idGenerator,
    DateTime Function()? clock,
  }) : _profiles = profileService ?? ProfileService(),
       _idGenerator = idGenerator ?? _generateUuidV4,
       _clock = clock ?? DateTime.now;

  final ProfileService _profiles;
  final String Function() _idGenerator;
  final DateTime Function() _clock;

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  Future<List<AuthoringTeam>> listTeams() async {
    final raw = (await SharedPreferences.getInstance()).getString(storageKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((item) => item is! Map)) {
      throw const FormatException('Stored authoring-team registry is invalid.');
    }
    final ids = <String>{};
    final teams = decoded
        .map(
          (item) =>
              AuthoringTeam.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    if (teams.any((team) => !ids.add(team.teamId))) {
      throw const FormatException('Stored authoring-team IDs must be unique.');
    }
    teams.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return teams;
  }

  Future<List<AuthoringTeam>> teamsForProfile(String profileId) async =>
      (await listTeams()).where((team) => team.hasMember(profileId)).toList();

  Future<AuthoringTeam?> teamById(String teamId) async {
    for (final team in await listTeams()) {
      if (team.teamId == teamId) return team;
    }
    return null;
  }

  Future<bool> hasDuplicateTeamName(
    String displayName, {
    String? excludingTeamId,
  }) async {
    final key = FormalNamePolicy.comparisonKey(displayName);
    return (await listTeams()).any(
      (team) =>
          team.teamId != excludingTeamId &&
          FormalNamePolicy.comparisonKey(team.displayName) == key,
    );
  }

  Future<void> _save(List<AuthoringTeam> teams) async {
    final encoded = jsonEncode(teams.map((team) => team.toJson()).toList());
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(storageKey, encoded) ||
        prefs.getString(storageKey) != encoded) {
      throw StateError('Verified authoring-team storage write failed.');
    }
  }

  Future<AuthoringTeam> createTeam({
    required String creatorProfileId,
    required String displayName,
  }) async {
    if (await _profiles.getProfileById(creatorProfileId) == null) {
      throw StateError('The Team creator must be an existing local profile.');
    }
    final name = FormalNamePolicy.validatePresentationLabel(
      displayName,
      parameterName: 'displayName',
    );
    final teams = await listTeams();
    final teamId = _idGenerator();
    if (teams.any((team) => team.teamId == teamId)) {
      throw StateError('The generated Team ID is already in use.');
    }
    final team = AuthoringTeam(
      teamId: teamId,
      displayName: name,
      creatorProfileId: creatorProfileId,
      createdAtUtc: _clock().toUtc().toIso8601String(),
      memberProfileIds: [creatorProfileId],
      leadProfileIds: [creatorProfileId],
    );
    await _save([...teams, team]);
    return team;
  }

  Future<AuthoringTeam> renameTeam({
    required String teamId,
    required String actorProfileId,
    required String displayName,
  }) async {
    final name = FormalNamePolicy.validatePresentationLabel(
      displayName,
      parameterName: 'displayName',
    );
    return _update(
      teamId,
      actorProfileId,
      (team) => team.copyWith(displayName: name),
    );
  }

  Future<AuthoringTeam> addMember({
    required String teamId,
    required String actorProfileId,
    required String memberProfileId,
  }) async {
    if (await _profiles.getProfileById(memberProfileId) == null) {
      throw StateError('Only an existing local learner profile can be added.');
    }
    return _update(teamId, actorProfileId, (team) {
      if (team.hasMember(memberProfileId)) return team;
      return team.copyWith(
        memberProfileIds: [...team.memberProfileIds, memberProfileId],
      );
    });
  }

  Future<AuthoringTeam> removeMember({
    required String teamId,
    required String actorProfileId,
    required String memberProfileId,
  }) => _update(teamId, actorProfileId, (team) {
    if (!team.hasMember(memberProfileId)) return team;
    if (team.hasLead(memberProfileId) && team.leadProfileIds.length == 1) {
      throw StateError('A Team must always have at least one Team Leader.');
    }
    return team.copyWith(
      memberProfileIds: team.memberProfileIds.where(
        (id) => id != memberProfileId,
      ),
      leadProfileIds: team.leadProfileIds.where((id) => id != memberProfileId),
    );
  });

  /// Removes the active profile's own ordinary Team membership.
  ///
  /// Team Leaders remain subject to Team administration so this self-service
  /// path can never leave the Team without a Lead.
  Future<AuthoringTeam> leaveTeam({required String teamId}) async {
    final profileId = await _profiles.getActiveProfileId();
    if (profileId == null) {
      throw StateError('Select a learner profile before leaving a Team.');
    }
    final teams = await listTeams();
    final index = teams.indexWhere((team) => team.teamId == teamId);
    if (index < 0) throw StateError('The Team is unavailable.');
    final current = teams[index];
    if (!current.hasMember(profileId)) {
      throw StateError('You are not a member of this Team.');
    }
    if (current.hasLead(profileId)) {
      throw StateError(
        'A Team Leader cannot leave directly. Another Team Leader must demote you first.',
      );
    }
    final updated = current.copyWith(
      memberProfileIds: current.memberProfileIds.where((id) => id != profileId),
    );
    teams[index] = updated;
    await _save(teams);
    return updated;
  }

  Future<AuthoringTeam> promoteToLead({
    required String teamId,
    required String actorProfileId,
    required String memberProfileId,
  }) => _update(teamId, actorProfileId, (team) {
    if (!team.hasMember(memberProfileId)) {
      throw StateError('Only a Team member can become a Team Leader.');
    }
    if (team.hasLead(memberProfileId)) return team;
    return team.copyWith(
      leadProfileIds: [...team.leadProfileIds, memberProfileId],
    );
  });

  Future<AuthoringTeam> demoteLead({
    required String teamId,
    required String actorProfileId,
    required String leadProfileId,
  }) => _update(teamId, actorProfileId, (team) {
    if (!team.hasLead(leadProfileId)) return team;
    if (team.leadProfileIds.length == 1) {
      throw StateError('The final Team Leader cannot be demoted.');
    }
    return team.copyWith(
      leadProfileIds: team.leadProfileIds.where((id) => id != leadProfileId),
    );
  });

  Future<AuthoringTeam> _update(
    String teamId,
    String actorProfileId,
    AuthoringTeam Function(AuthoringTeam team) change,
  ) async {
    final teams = await listTeams();
    final index = teams.indexWhere((team) => team.teamId == teamId);
    if (index < 0) throw StateError('The Team is unavailable.');
    final current = teams[index];
    if (!current.hasLead(actorProfileId)) {
      throw StateError(
        'Only a Team Leader can manage Team membership and roles.',
      );
    }
    final updated = change(current);
    teams[index] = updated;
    await _save(teams);
    return updated;
  }
}
