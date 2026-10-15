import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/authoring_team.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_registry.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 273 Revision 8: the Team registry's read and verified write have
/// one owner, used by `TeamService` and by `ProfileService`'s learner
/// deletion. Their own cases (`course_ownership_team_229_r1_test`,
/// `team_shared_folder_255_test`, `deleting_a_course_271_test`,
/// `device_administration_239_test` and the others) pass before and after.
const _lead = '11111111-1111-4111-8111-111111111111';
const _member = '22222222-2222-4222-8222-222222222222';

AuthoringTeam _team(String id, String name) => AuthoringTeam(
  teamId: id,
  displayName: name,
  creatorProfileId: _lead,
  createdAtUtc: '2026-10-15T18:00:00.000Z',
  memberProfileIds: const [_lead, _member],
  leadProfileIds: const [_lead],
);

const _first = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _second = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the key is the one the Teams have always used', () {
    expect(TeamRegistry.storageKey, 'quisquislingo_authoring_teams_v1_2291');
    expect(TeamService.storageKey, TeamRegistry.storageKey);
  });

  test('nothing stored is no Team', () {
    expect(TeamRegistry.decode(null), isEmpty);
    expect(TeamRegistry.decode('   '), isEmpty);
  });

  test('a registry that is not a list of objects is refused', () {
    for (final raw in ['{}', '[1, 2]', '["team"]', '"x"']) {
      expect(
        () => TeamRegistry.decode(raw),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Stored authoring-team registry is invalid.',
          ),
        ),
        reason: raw,
      );
    }
  });

  test('Teams come in their stored order; a broken one only when reached', () {
    final raw = jsonEncode([
      _team(_second, 'Second').toJson(),
      _team(_first, 'First').toJson(),
      {'teamId': 'not a Team'},
    ]);
    final teams = TeamRegistry.decode(raw);
    expect(teams.take(2).map((t) => t.displayName), ['Second', 'First']);
    expect(() => teams.toList(), throwsFormatException);
  });

  test('a write is read back the same', () async {
    final prefs = await SharedPreferences.getInstance();
    final teams = [_team(_first, 'First'), _team(_second, 'Second')];
    await TeamRegistry.write(prefs, teams);
    expect(
      prefs.getString(TeamRegistry.storageKey),
      jsonEncode([for (final team in teams) team.toJson()]),
    );
    expect(TeamRegistry.readFrom(prefs).map((t) => t.teamId), [
      _first,
      _second,
    ]);
    await TeamRegistry.write(prefs, const []);
    expect(TeamRegistry.readFrom(prefs), isEmpty);
  });

  test('TeamService lists them sorted by name, as before', () async {
    final prefs = await SharedPreferences.getInstance();
    await TeamRegistry.write(prefs, [
      _team(_second, 'beta'),
      _team(_first, 'Alpha'),
    ]);
    expect((await TeamService().listTeams()).map((t) => t.displayName), [
      'Alpha',
      'beta',
    ]);
  });

  test('deleting a learner meets the Teams in stored order', () async {
    // The learner is the last Team Leader of the first Team; the second
    // entry is broken. Each Team is made and checked before the next, so
    // the refusal names the Team, as before: the broken entry is not
    // reached.
    final profiles = ProfileService();
    for (final (id, name) in [(_lead, 'Alice'), (_member, 'Bob')]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    final ledByBob = AuthoringTeam(
      teamId: _first,
      displayName: 'Editors',
      creatorProfileId: _member,
      createdAtUtc: '2026-10-15T18:00:00.000Z',
      memberProfileIds: const [_member],
      leadProfileIds: const [_member],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      TeamRegistry.storageKey,
      jsonEncode([
        ledByBob.toJson(),
        {'teamId': 'not a Team'},
      ]),
    );
    await expectLater(
      profiles.deleteProfileById(_member, actorProfileId: _lead),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('final Team Leader of Editors'),
        ),
      ),
    );
    expect(await profiles.getProfileById(_member), isNotNull);
  });
}
