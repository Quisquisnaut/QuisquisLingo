import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/authoring_team.dart';
import 'package:quisquislingo_app/models/team_shared_folder_link.dart';
import 'package:quisquislingo_app/screens/team_manager_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _id = '1AbCdEfGhIjKlMnOpQrStUvWxYz012345';
const _folder = 'https://drive.google.com/drive/folders/$_id';

/// Build 255 Revision 6: a Team may name its shared Google Drive folder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TeamSharedFolderLink', () {
    test('accepts Google Drive folder links in one stored form', () {
      final accepted = {
        _folder: _folder,
        '  $_folder?usp=sharing  ': _folder,
        '$_folder?usp=drive_link': _folder,
        '$_folder/': _folder,
        'https://drive.google.com/drive/u/0/folders/$_id?usp=sharing': _folder,
        'https://drive.google.com/drive/u/12/folders/$_id': _folder,
        'https://DRIVE.GOOGLE.COM/drive/folders/$_id': _folder,
        '$_folder?resourcekey=0-abcDEF_12': '$_folder?resourcekey=0-abcDEF_12',
      };
      for (final entry in accepted.entries) {
        expect(
          TeamSharedFolderLink.normalize(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      expect(TeamSharedFolderLink.isStored(_folder), isTrue);
      expect(TeamSharedFolderLink.isStored('$_folder?usp=sharing'), isFalse);
    });

    test('refuses every other kind of link', () {
      for (final link in [
        '',
        '   ',
        'http://drive.google.com/drive/folders/$_id',
        'drive.google.com/drive/folders/$_id',
        'https://drive.google.com.evil.example/drive/folders/$_id',
        'https://drive.google.com@evil.example/drive/folders/$_id',
        'https://user:pass@drive.google.com/drive/folders/$_id',
        'https://evil.example/drive.google.com/drive/folders/$_id',
        'https://drive.google.com:8080/drive/folders/$_id',
        'https://drive.google.com/file/d/$_id/view?usp=sharing',
        'https://drive.google.com/uc?export=download&id=$_id',
        'https://drive.google.com/open?id=$_id',
        'https://drive.google.com/drive/my-drive',
        'https://drive.google.com/drive/folders/short',
        'https://drive.google.com/drive/folders/../../evil',
        'https://drive.google.com/drive/folders/%2e%2e',
        '$_folder?usp=sharing&next=https://evil.example',
        '$_folder?usp=sharing&usp=drive_link',
        '$_folder#top',
        '$_folder ?usp=sharing',
        'https://docs.google.com/document/d/$_id/edit',
        'https://goo.gl/abcdef',
        'https://bit.ly/abcdef',
        'javascript:alert(1)',
        'file:///C:/Users/folder',
        '$_folder${'a' * 500}',
      ]) {
        expect(
          () => TeamSharedFolderLink.normalize(link),
          throwsA(same(TeamSharedFolderLink.refusal)),
          reason: link,
        );
      }
    });
  });

  group('Teams', () {
    late TeamService teams;
    late AuthoringTeam team;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final profiles = ProfileService();
      await profiles.createProfile(
        'Alice',
        learnerProfileId: _alice,
        generateScreenNameSuffix: false,
      );
      await profiles.createProfile(
        'Bob',
        learnerProfileId: _bob,
        generateScreenNameSuffix: false,
      );
      teams = TeamService(profileService: profiles);
      team = await teams.createTeam(
        creatorProfileId: _alice,
        displayName: 'Authors',
      );
      team = await teams.addMember(
        teamId: team.teamId,
        actorProfileId: _alice,
        memberProfileId: _bob,
      );
    });

    test('earlier registries read unchanged; the link is saved only when '
        'set', () async {
      expect(team.sharedFolderUrl, isEmpty);
      expect(team.toJson().containsKey('sharedFolderUrl'), isFalse);
      final linked = team.copyWith(sharedFolderUrl: _folder);
      final json = jsonDecode(jsonEncode(linked.toJson()));
      expect(json['sharedFolderUrl'], _folder);
      expect(AuthoringTeam.fromJson(json).sharedFolderUrl, _folder);
      expect(
        () => AuthoringTeam.fromJson({
          ...team.toJson(),
          'sharedFolderUrl': 'https://evil.example/',
        }),
        throwsFormatException,
      );
      expect(
        () => AuthoringTeam.fromJson({...team.toJson(), 'sharedFolderUrl': 7}),
        throwsFormatException,
      );
    });

    test('only a Team Leader sets or removes the link', () async {
      final set = await teams.setSharedFolderUrl(
        teamId: team.teamId,
        actorProfileId: _alice,
        url: '$_folder?usp=sharing',
      );
      expect(set.sharedFolderUrl, _folder);
      expect((await teams.teamById(team.teamId))!.sharedFolderUrl, _folder);
      await expectLater(
        teams.setSharedFolderUrl(
          teamId: team.teamId,
          actorProfileId: _bob,
          url: '',
        ),
        throwsStateError,
      );
      expect(
        () => teams.setSharedFolderUrl(
          teamId: team.teamId,
          actorProfileId: _alice,
          url: 'https://drive.google.com/file/d/$_id/view',
        ),
        throwsA(same(TeamSharedFolderLink.refusal)),
      );
      final cleared = await teams.setSharedFolderUrl(
        teamId: team.teamId,
        actorProfileId: _alice,
        url: '',
      );
      expect(cleared.sharedFolderUrl, isEmpty);
    });

    Future<List<Uri>> showTeam(WidgetTester tester, String viewer) async {
      await ProfileService().setActiveProfileById(viewer);
      final opened = <Uri>[];
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: TeamDetailScreen(
            teamId: team.teamId,
            teamService: teams,
            profileService: ProfileService(),
            launchExternal: (uri) async {
              opened.add(uri);
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('a Team Leader adds the link; a wrong one is explained', (
      tester,
    ) async {
      await showTeam(tester, _alice);
      expect(find.text('No shared folder yet'), findsOneWidget);
      expect(find.byKey(const Key('team-shared-folder-open')), findsNothing);

      await tester.tap(find.byKey(const Key('team-shared-folder-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('team-shared-folder-field')),
        'https://drive.google.com/uc?export=download&id=$_id',
      );
      await tester.tap(find.byKey(const Key('team-shared-folder-save')));
      await tester.pumpAndSettle();
      expect(find.text(TeamSharedFolderLink.refusal.message), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('team-shared-folder-field')),
        '$_folder?usp=sharing',
      );
      await tester.tap(find.byKey(const Key('team-shared-folder-save')));
      await tester.pumpAndSettle();
      expect(find.text(_folder), findsOneWidget);
      expect((await teams.teamById(team.teamId))!.sharedFolderUrl, _folder);
      expect(
        find.byKey(const Key('team-shared-folder-remove')),
        findsOneWidget,
      );
    });

    testWidgets('a member opens the folder only after the download warning', (
      tester,
    ) async {
      await teams.setSharedFolderUrl(
        teamId: team.teamId,
        actorProfileId: _alice,
        url: _folder,
      );
      final opened = await showTeam(tester, _bob);
      expect(find.byKey(const Key('team-shared-folder-edit')), findsNothing);
      expect(find.byKey(const Key('team-shared-folder-remove')), findsNothing);

      await tester.tap(find.byKey(const Key('team-shared-folder-open')));
      await tester.pumpAndSettle();
      final warning = find.byKey(const Key('team-shared-folder-warning'));
      expect(warning, findsOneWidget);
      expect(
        find.descendant(
          of: warning,
          matching: find.textContaining('Download only files whose origin'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(opened, isEmpty);

      await tester.tap(find.byKey(const Key('team-shared-folder-open')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('team-shared-folder-open-confirm')),
      );
      await tester.pumpAndSettle();
      expect(opened, [Uri.parse(_folder)]);
    });
  });
}
