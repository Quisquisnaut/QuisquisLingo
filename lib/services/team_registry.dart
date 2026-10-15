import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/authoring_team.dart';

/// The device's registry of authoring Teams, as stored (Build 273 Revision
/// 8): one JSON list under [storageKey], read with its shape checked and
/// written with a read-back check. `TeamService` (Team administration) and
/// `ProfileService` (a learner's deletion takes them out of their Teams)
/// both use it, so neither writes the registry on its own. `TeamService`
/// uses `ProfileService`, so by design the profile service does not call
/// `TeamService` back.
class TeamRegistry {
  TeamRegistry._();

  static const storageKey = AuthoringTeam.storageKey;

  /// The Teams stored in [raw], in their stored order, made one by one as
  /// they are read (so a fault in a later Team surfaces only when reached).
  /// Nothing stored is no Team; a value that is not a list of objects is a
  /// [FormatException].
  static Iterable<AuthoringTeam> decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List || decoded.any((item) => item is! Map)) {
      throw const FormatException('Stored authoring-team registry is invalid.');
    }
    return decoded.map(
      (item) => AuthoringTeam.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  /// The Teams stored in [prefs] ([decode]).
  static Iterable<AuthoringTeam> readFrom(SharedPreferences prefs) =>
      decode(prefs.getString(storageKey));

  /// Stores [teams] in [prefs] and checks that they were written; a write
  /// that did not land is a [StateError].
  static Future<void> write(
    SharedPreferences prefs,
    List<AuthoringTeam> teams,
  ) async {
    final encoded = jsonEncode(teams.map((team) => team.toJson()).toList());
    if (!await prefs.setString(storageKey, encoded) ||
        prefs.getString(storageKey) != encoded) {
      throw StateError('Verified authoring-team storage write failed.');
    }
  }
}
