import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_metadata_options.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/official_course_inspection_screen.dart';
import 'package:quisquislingo_app/screens/team_manager_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_editor_transaction.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const aliceId = '11111111-1111-4111-8111-111111111111';
const bobId = '22222222-2222-4222-8222-222222222222';
const charlieId = '33333333-3333-4333-8333-333333333333';
const teamId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

Future<ProfileService> _profiles({bool includeCharlie = true}) async {
  final profiles = ProfileService();
  await profiles.createProfile('Alice', learnerProfileId: aliceId);
  await profiles.createProfile('Bob', learnerProfileId: bobId);
  if (includeCharlie) {
    await profiles.createProfile('Charlie', learnerProfileId: charlieId);
  }
  await profiles.setActiveProfileById(aliceId);
  return profiles;
}

Course _custom({
  String ownerId = aliceId,
  CourseOwnerType ownerType = CourseOwnerType.individual,
  DerivativeWorksPolicy policy = DerivativeWorksPolicy.forbidden,
  String title = 'Owned course',
}) => Course(
  courseId: 'course-owned-${ownerType.name}-$ownerId',
  creatorProfileId: aliceId,
  ownership: CourseOwnership(type: ownerType, id: ownerId),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  authors: const [
    CourseAuthor(name: 'Visible Author', roles: ['Course Creator']),
    CourseAuthor(name: 'Contributor Person', roles: ['Contributor']),
    CourseAuthor(name: 'Illustrator Person', roles: ['Illustrator']),
  ],
  license: policy == DerivativeWorksPolicy.allowed
      ? 'CC BY 4.0'
      : 'All rights reserved',
  derivativeWorksPolicy: policy,
  lessons: const [],
);

Course _official(DerivativeWorksPolicy policy) {
  final provisional = Course(
    courseId: 'official-course',
    originType: CourseOriginType.bundledOfficial,
    publisherId: 'org.quisquislingo',
    publisherName: 'QuisquisLingo',
    officialCourseVersion: '1.0.0',
    officialReleaseDateUtc: '2026-09-09T00:00:00.000Z',
    officialChecksum:
        '0000000000000000000000000000000000000000000000000000000000000000',
    distributionChannel: 'bundled',
    publisherVerificationStatus: PublisherVerificationStatus.verified,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Official course',
    ttsLanguage: 'it-IT',
    version: '1.0.0',
    derivativeWorksPolicy: policy,
    authors: const [
      CourseAuthor(name: 'Official Author', roles: ['Course Creator']),
    ],
    lessons: const [],
  );
  return Course.fromJson({
    ...provisional.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(
      provisional,
    ),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Course Model v7 requires explicit custom Creator and Owner JSON', () {
    final json = _custom().toJson();
    expect(json['formatVersion'], 7);
    expect(json['creatorProfileId'], aliceId);
    expect(json['ownership'], {'type': 'individual', 'id': aliceId});
    expect(Course.fromJson(json).ownership!.id, aliceId);

    expect(
      () => Course.fromJson({...json}..remove('creatorProfileId')),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({...json}..remove('ownership')),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({...json, 'formatVersion': 6}),
      throwsFormatException,
    );
  });

  test('Owner rights and outsider derivative rights are distinct', () {
    final restricted = _custom();
    final owner = CourseAccessPolicy.evaluate(restricted, profileId: aliceId);
    expect(owner.canEditOriginal, isTrue);
    expect(owner.canDuplicate, isTrue);
    expect(owner.canFork, isFalse);

    final outsider = CourseAccessPolicy.evaluate(restricted, profileId: bobId);
    expect(outsider.canEditOriginal, isFalse);
    expect(outsider.canDuplicate, isFalse);
    expect(outsider.canFork, isFalse);

    final permissive = CourseAccessPolicy.evaluate(
      _custom(policy: DerivativeWorksPolicy.allowed),
      profileId: bobId,
    );
    expect(permissive.canEditOriginal, isFalse);
    expect(permissive.canDuplicate, isFalse);
    expect(permissive.canFork, isTrue);
  });

  test(
    'Team members edit regardless of license and removed members do not',
    () {
      final course = _custom(ownerId: teamId, ownerType: CourseOwnerType.team);
      final member = CourseAccessPolicy.evaluate(
        course,
        profileId: bobId,
        memberTeamIds: {teamId},
      );
      expect(member.canEditOriginal, isTrue);
      expect(member.canDuplicate, isTrue);
      expect(member.canFork, isFalse);

      final removed = CourseAccessPolicy.evaluate(course, profileId: bobId);
      expect(removed.canEditOriginal, isFalse);
      expect(removed.canDuplicate, isFalse);
      expect(removed.canFork, isFalse);
    },
  );

  test(
    'Team administration supports multiple Leads and protects final Lead',
    () async {
      final profiles = await _profiles();
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => teamId,
        clock: () => DateTime.utc(2026, 9, 9),
      );
      var team = await teams.createTeam(
        creatorProfileId: aliceId,
        displayName: 'Local Authors',
      );
      expect(team.creatorProfileId, aliceId);
      expect(team.leadProfileIds, [aliceId]);

      team = await teams.addMember(
        teamId: teamId,
        actorProfileId: aliceId,
        memberProfileId: bobId,
      );
      expect(team.memberProfileIds, containsAll([aliceId, bobId]));
      await expectLater(
        teams.addMember(
          teamId: teamId,
          actorProfileId: bobId,
          memberProfileId: charlieId,
        ),
        throwsStateError,
      );

      team = await teams.promoteToLead(
        teamId: teamId,
        actorProfileId: aliceId,
        memberProfileId: bobId,
      );
      expect(team.leadProfileIds, containsAll([aliceId, bobId]));
      team = await teams.renameTeam(
        teamId: teamId,
        actorProfileId: bobId,
        displayName: 'Renamed Authors',
      );
      expect(team.teamId, teamId);
      final teamCourse = _custom(
        ownerId: team.teamId,
        ownerType: CourseOwnerType.team,
      );
      team = await teams.demoteLead(
        teamId: teamId,
        actorProfileId: aliceId,
        leadProfileId: aliceId,
      );
      expect(team.leadProfileIds, [bobId]);
      await expectLater(
        teams.demoteLead(
          teamId: teamId,
          actorProfileId: bobId,
          leadProfileId: bobId,
        ),
        throwsStateError,
      );
      team = await teams.removeMember(
        teamId: teamId,
        actorProfileId: bobId,
        memberProfileId: aliceId,
      );
      expect(team.hasMember(aliceId), isFalse);
      expect(team.creatorProfileId, aliceId);
      expect(teamCourse.ownership!.id, team.teamId);
      expect(
        CourseAccessPolicy.evaluate(
          teamCourse,
          profileId: bobId,
          memberTeamIds: {team.teamId},
        ).canEditOriginal,
        isTrue,
      );
    },
  );

  test('Team creation rejects a generated ID collision', () async {
    final profiles = await _profiles(includeCharlie: false);
    final teams = TeamService(
      profileService: profiles,
      idGenerator: () => teamId,
      clock: () => DateTime.utc(2026, 9, 11),
    );

    await teams.createTeam(
      creatorProfileId: aliceId,
      displayName: 'First Team',
    );
    await expectLater(
      teams.createTeam(
        creatorProfileId: aliceId,
        displayName: 'Colliding Team',
      ),
      throwsStateError,
    );
    expect((await teams.listTeams()).map((team) => team.displayName), [
      'First Team',
    ]);
  });

  test(
    'Profile deletion preserves Team membership and final-Lead invariants',
    () async {
      final profiles = await _profiles(includeCharlie: false);
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => teamId,
        clock: () => DateTime.utc(2026, 9, 9),
      );
      await teams.createTeam(
        creatorProfileId: aliceId,
        displayName: 'Durable Team',
      );
      await expectLater(profiles.deleteProfileById(aliceId), throwsStateError);
      expect(await profiles.getProfileById(aliceId), isNotNull);

      await teams.addMember(
        teamId: teamId,
        actorProfileId: aliceId,
        memberProfileId: bobId,
      );
      await teams.promoteToLead(
        teamId: teamId,
        actorProfileId: aliceId,
        memberProfileId: bobId,
      );
      await profiles.deleteProfileById(aliceId);
      final team = await teams.teamById(teamId);
      expect(team!.hasMember(aliceId), isFalse);
      expect(team.hasLead(bobId), isTrue);
      expect(team.creatorProfileId, aliceId);
    },
  );

  test(
    'Profile deletion cannot orphan an individually owned custom course',
    () async {
      final profiles = await _profiles(includeCharlie: false);
      final courses = CourseEditorService(profileService: profiles);
      final course = _custom(title: 'Alice owned course');
      await courses.saveUserCourse(course);

      await expectLater(profiles.deleteProfileById(aliceId), throwsStateError);
      expect(await profiles.getProfileById(aliceId), isNotNull);
      expect(await profiles.getActiveProfileId(), aliceId);
      expect((await courses.listUserCourses()).map((value) => value.courseId), [
        course.courseId,
      ]);

      await courses.deleteUserCourse(course.courseId);
      await profiles.deleteProfileById(aliceId);
      expect(await profiles.getProfileById(aliceId), isNull);
      expect(await profiles.getActiveProfileId(), bobId);
    },
  );

  test(
    'Duplicate and Fork are persisted clean baselines but real edits are dirty',
    () async {
      final profiles = await _profiles(includeCharlie: false);
      final service = CourseEditorService(
        profileService: profiles,
        clock: () => DateTime.utc(2026, 9, 9, 12),
      );
      final source = _custom();
      await service.saveUserCourse(source);

      final duplicate = await service.createDuplicate(
        source: source,
        title: 'Owned course copy',
      );
      expect(duplicate.course.ownership!.id, aliceId);
      expect(duplicate.course.creatorProfileId, aliceId);
      expect(CourseEditorTransaction(duplicate.course).hasChanges, isFalse);

      final edited = Course.fromJson({
        ...duplicate.course.toJson(),
        'title': 'A real edit',
      });
      final transaction = CourseEditorTransaction(duplicate.course)
        ..replaceWorkingCourse(edited);
      expect(transaction.hasChanges, isTrue);

      final fork = await service.createFork(
        source: _official(DerivativeWorksPolicy.allowed),
      );
      expect(fork.course.parentCourseId, 'official-course');
      expect(fork.course.forkProvenance, isNotNull);
      expect(CourseEditorTransaction(fork.course).hasChanges, isFalse);
    },
  );

  testWidgets(
    'persisted Duplicate and Fork close cleanly while a real edit still prompts',
    (tester) async {
      final profiles = await _profiles(includeCharlie: false);
      final service = CourseEditorService(profileService: profiles);
      final source = _custom();
      await service.saveUserCourse(source);
      final duplicate = (await service.createDuplicate(
        source: source,
        title: 'Clean duplicate',
      )).course;
      final fork = (await service.createFork(
        source: _official(DerivativeWorksPolicy.allowed),
      )).course;
      late Course selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              key: const Key('open-generated-course'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CourseEditorScreen(
                    course: selected,
                    access: CourseAccessPolicy.evaluate(
                      selected,
                      profileId: aliceId,
                    ),
                    editorService: service,
                  ),
                ),
              ),
              child: const Text('Open generated course'),
            ),
          ),
        ),
      );

      for (final course in [duplicate, fork]) {
        selected = course;
        await tester.tap(find.byKey(const Key('open-generated-course')));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('course-transaction-confirmation')),
          findsNothing,
        );
        expect(find.byKey(const Key('open-generated-course')), findsOneWidget);
      }

      selected = duplicate;
      await SettingsService().setCourseEditorMode(
        duplicate.courseId,
        CourseEditorMode.edit,
      );
      await tester.tap(find.byKey(const Key('open-generated-course')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-editor-course-info')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('course-info-title')),
        'Actually edited',
      );
      await tester.tap(find.byKey(const Key('course-info-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsOneWidget,
      );
    },
  );

  test('Course metadata survives confirmation and reopen', () async {
    final profiles = await _profiles(includeCharlie: false);
    final service = CourseEditorService(
      profileService: profiles,
      backupService: _MemoryBackupService(),
    );
    final source = _custom();
    await service.saveUserCourse(source);
    final authors = [
      CourseAuthor(
        name: 'All Credits',
        roles: CourseMetadataOptions.standardRoles,
      ),
    ];
    final working = Course.fromJson({
      ...source.toJson(),
      'authors': authors.map((author) => author.toJson()).toList(),
      'author': 'All Credits',
      'license': 'CC BY-SA 4.0',
      'derivativeWorksPolicy': DerivativeWorksPolicy.allowed.name,
      'languageVariant': 'Regional variant',
      'startLevel': 'A1',
      'targetLevel': 'B1',
      'lastUpdated': '2026-09-09',
      'courseDescription': 'Preserved description',
      'buyACoffeeUrl': 'https://example.com/support',
    });
    await service.confirmCourseTransaction(
      originalCourse: source,
      workingCourse: working,
      languageCode: 'it-IT',
      versionNotes: 'Metadata restored',
    );
    final reopened = (await service.listUserCourses()).single;
    expect(reopened.license, 'CC BY-SA 4.0');
    expect(reopened.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
    expect(reopened.authors.single.roles, CourseMetadataOptions.standardRoles);
    expect(reopened.languageVariant, 'Regional variant');
    expect(reopened.startLevel, 'A1');
    expect(reopened.targetLevel, 'B1');
    expect(reopened.lastUpdated, '2026-09-09');
    expect(reopened.courseDescription, 'Preserved description');
    expect(reopened.buyACoffeeUrl, 'https://example.com/support');
  });

  test(
    'services prevent Duplicate license bypass and permit licensed Fork',
    () async {
      final profiles = await _profiles(includeCharlie: false);
      final service = CourseEditorService(profileService: profiles);
      final restricted = _custom();
      await service.saveUserCourse(restricted);
      await profiles.setActiveProfileById(bobId);
      await expectLater(
        service.createDuplicate(source: restricted, title: 'Bypass'),
        throwsStateError,
      );
      await expectLater(
        service.createFork(source: restricted),
        throwsStateError,
      );
      final licensed = _custom(
        policy: DerivativeWorksPolicy.allowed,
        title: 'Licensed source',
      );
      final fork = await service.createFork(source: licensed);
      expect(fork.course.ownership!.id, bobId);
      expect(fork.course.creatorProfileId, bobId);
      expect(fork.course.parentCourseId, licensed.courseId);
    },
  );

  test(
    'Team duplicate preserves Team ownership and creator is duplicator',
    () async {
      final profiles = await _profiles(includeCharlie: false);
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => teamId,
        clock: () => DateTime.utc(2026, 9, 9),
      );
      await teams.createTeam(
        creatorProfileId: aliceId,
        displayName: 'Team One',
      );
      await teams.addMember(
        teamId: teamId,
        actorProfileId: aliceId,
        memberProfileId: bobId,
      );
      final source = _custom(ownerId: teamId, ownerType: CourseOwnerType.team);
      final aliceStorage = CourseEditorService(
        profileService: profiles,
        teamService: teams,
      );
      await aliceStorage.saveUserCourse(source);
      await profiles.setActiveProfileById(bobId);
      final duplicate = await aliceStorage.createDuplicate(
        source: source,
        title: 'Team copy',
      );
      expect(duplicate.course.ownership!.type, CourseOwnerType.team);
      expect(duplicate.course.ownership!.id, teamId);
      expect(duplicate.course.creatorProfileId, bobId);

      await profiles.setActiveProfileById(aliceId);
      await teams.removeMember(
        teamId: teamId,
        actorProfileId: aliceId,
        memberProfileId: bobId,
      );
      await profiles.setActiveProfileById(bobId);
      await expectLater(
        aliceStorage.createDuplicate(source: source, title: 'Blocked copy'),
        throwsStateError,
      );
    },
  );

  testWidgets('Course Info separates Owner, Creator, license and credits', (
    tester,
  ) async {
    final profiles = await _profiles(includeCharlie: false);
    final teams = TeamService(
      profileService: profiles,
      idGenerator: () => teamId,
      clock: () => DateTime.utc(2026, 9, 9),
    );
    await teams.createTeam(
      creatorProfileId: aliceId,
      displayName: 'Renamable Team',
    );
    final course = _custom(ownerId: teamId, ownerType: CourseOwnerType.team);
    await tester.pumpWidget(
      MaterialApp(
        home: CourseInfoScreen(
          course: course,
          profileService: profiles,
          teamService: teams,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Owner: Renamable Team (Team)'), findsOneWidget);
    expect(find.textContaining('Creator: Alice'), findsOneWidget);
    expect(find.textContaining('Visible Author'), findsOneWidget);
    expect(
      find.textContaining('Contributors: Contributor Person'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Illustrators: Illustrator Person'),
      findsOneWidget,
    );
    expect(find.textContaining('All rights reserved'), findsWidgets);
  });

  testWidgets(
    'New Course restores license, every credit role and Team ownership choice',
    (tester) async {
      final profiles = await _profiles(includeCharlie: false);
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => teamId,
        clock: () => DateTime.utc(2026, 9, 9),
      );
      await teams.createTeam(
        creatorProfileId: aliceId,
        displayName: 'Creation Team',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseProjectsScreen(
            currentCourse: _official(DerivativeWorksPolicy.allowed),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('create-course-icon-action')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('new-course-license')), findsOneWidget);
      expect(find.byKey(const Key('new-course-owner')), findsOneWidget);
      expect(find.byKey(const Key('new-course-last-updated')), findsOneWidget);
      expect(find.text('Course Creator'), findsOneWidget);
      for (final role in CourseMetadataOptions.standardRoles) {
        expect(find.text(role), findsOneWidget);
      }
      await tester.ensureVisible(find.byKey(const Key('new-course-owner')));
      await tester.tap(find.byKey(const Key('new-course-owner')));
      await tester.pump();
      expect(find.text('Creation Team'), findsOneWidget);
      await tester.tap(find.text('Creation Team'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  );

  testWidgets('unified Editor surface is capability-driven', (tester) async {
    await _profiles(includeCharlie: false);
    final official = _official(DerivativeWorksPolicy.allowed);
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: official,
          access: CourseAccessPolicy.evaluate(official, profileId: aliceId),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(OfficialCourseInspectionScreen), findsNothing);
    expect(
      find.byKey(const Key('course-editor-read-only-notice')),
      findsOneWidget,
    );
    expect(find.text('Course Info'), findsOneWidget);
    expect(find.byKey(const Key('course-editor-fork-course')), findsOneWidget);

    // Dispose the first editor before mounting a different course. In the app,
    // each editor is a separate route; replacing MaterialApp.home directly
    // would otherwise reuse the private state solely because its type matches.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final own = _custom();
    await SettingsService().setCourseEditorMode(
      own.courseId,
      CourseEditorMode.edit,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: own,
          access: CourseAccessPolicy.evaluate(own, profileId: aliceId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('course-editor-read-only-notice')),
      findsNothing,
    );
    expect(find.text('Course Info Editor'), findsOneWidget);
    expect(
      find.byKey(const Key('course-editor-duplicate-course')),
      findsOneWidget,
    );
  });

  testWidgets('Course Manager opens separate Team Manager page', (
    tester,
  ) async {
    await _profiles(includeCharlie: false);
    await tester.pumpWidget(
      MaterialApp(
        home: CourseProjectsScreen(
          currentCourse: _official(DerivativeWorksPolicy.allowed),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('team-manager-entry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(TeamManagerScreen), findsOneWidget);
    expect(find.text('Team Manager'), findsWidgets);
    expect(find.byKey(const Key('create-team')), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  });
}

class _MemoryBackupService extends CourseBackupService {
  @override
  Future<CourseBackupRecord> createBackup(
    Course course, {
    required DateTime backedUpAt,
    required String reason,
  }) async => CourseBackupRecord(
    manifestFile: File('${Directory.systemTemp.path}/${course.courseId}.json'),
    course: course,
    checksum: CourseBackupService.courseChecksum(course),
    backedUpAtUtc: backedUpAt.toUtc(),
    reason: reason,
    assets: const [],
  );
}
