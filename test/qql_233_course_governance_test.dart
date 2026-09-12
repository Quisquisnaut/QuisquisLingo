import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_governance_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const aliceId = '11111111-1111-4111-8111-111111111111';
const bobId = '22222222-2222-4222-8222-222222222222';
const charlieId = '33333333-3333-4333-8333-333333333333';
const teamId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

Course course({
  String creatorId = aliceId,
  String ownerId = aliceId,
  String? assignedTeamId,
  String id = 'course-qql-233',
}) => Course(
  courseId: id,
  creatorProfileId: creatorId,
  ownership: CourseOwnership.individual(ownerId),
  assignedTeamId: assignedTeamId,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'QQL 233 course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  lessons: const [],
);

Future<({ProfileService profiles, TeamService teams})> localPeople() async {
  final profiles = ProfileService();
  await profiles.createProfile('Alice', learnerProfileId: aliceId);
  await profiles.createProfile(
    'Bob',
    learnerProfileId: bobId,
    discordHandle: 'bob_words',
  );
  await profiles.createProfile('Charlie', learnerProfileId: charlieId);
  await profiles.setActiveProfileById(aliceId);
  final teams = TeamService(
    profileService: profiles,
    idGenerator: () => teamId,
    clock: () => DateTime.utc(2026, 9, 12),
  );
  await teams.createTeam(
    creatorProfileId: aliceId,
    displayName: 'Independent Team',
  );
  await teams.addMember(
    teamId: teamId,
    actorProfileId: aliceId,
    memberProfileId: charlieId,
  );
  return (profiles: profiles, teams: teams);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Course Model v8 permits only an individual Owner', () {
    final json = course().toJson();
    expect(json['formatVersion'], 8);
    expect(json['ownership'], {'type': 'individual', 'id': aliceId});
    expect(Course.fromJson(json).ownership!.id, aliceId);
    expect(
      () => Course.fromJson({
        ...json,
        'ownership': {'type': 'team', 'id': teamId},
      }),
      throwsFormatException,
    );
  });

  test('Team assignment is separate and survives Course JSON round-trip', () {
    final value = course(assignedTeamId: teamId);
    final json = value.toJson();
    expect(json['ownership'], {'type': 'individual', 'id': aliceId});
    expect(json['assignedTeamId'], teamId);
    final restored = Course.fromJson(json);
    expect(restored.ownership!.id, aliceId);
    expect(restored.assignedTeamId, teamId);
    expect(restored.creatorProfileId, aliceId);
  });

  test('Owner and assigned Team management powers stay independent', () {
    final value = course(assignedTeamId: teamId);
    final owner = CourseAccessPolicy.evaluate(value, profileId: aliceId);
    expect(owner.canEditOriginal, isTrue);
    expect(owner.canTransferOwnership, isTrue);
    expect(owner.canAssignTeam, isTrue);

    final assignedMember = CourseAccessPolicy.evaluate(
      value,
      profileId: charlieId,
      memberTeamIds: {teamId},
    );
    expect(assignedMember.canEditOriginal, isTrue);
    expect(assignedMember.canTransferOwnership, isFalse);
    expect(assignedMember.canAssignTeam, isFalse);

    final unrelatedTeamLeader = CourseAccessPolicy.evaluate(
      course(),
      profileId: charlieId,
      memberTeamIds: {teamId},
    );
    expect(unrelatedTeamLeader.canEditOriginal, isFalse);
    expect(unrelatedTeamLeader.canTransferOwnership, isFalse);
  });

  test('Owner transfers ownership without changing Creator', () async {
    final people = await localPeople();
    final governance = CourseGovernanceService(
      profileService: people.profiles,
      teamService: people.teams,
    );
    final transferred = await governance.transferOwnership(
      course: course(),
      actorProfileId: aliceId,
      newOwnerProfileId: bobId,
      editMode: true,
    );
    expect(transferred.creatorProfileId, aliceId);
    expect(transferred.ownership!.id, bobId);
    expect(
      (await people.profiles.getProfileById(bobId))!.presentationName,
      '@bob_words',
    );
  });

  test(
    'Creator can confirm another individual as initial Course Owner',
    () async {
      final people = await localPeople();
      final service = CourseEditorService(
        profileService: people.profiles,
        teamService: people.teams,
        clock: () => DateTime.utc(2026, 9, 12),
      );
      final value = course(ownerId: bobId);

      await service.confirmCourseTransaction(
        originalCourse: value,
        workingCourse: value,
        languageCode: 'IT',
        versionNotes: '',
        isNewCourse: true,
      );

      final persisted = (await service.listUserCourses()).single;
      expect(persisted.creatorProfileId, aliceId);
      expect(persisted.ownership!.id, bobId);
      expect(persisted.ownership!.type, CourseOwnerType.individual);
    },
  );

  test('non-owner and non-Edit ownership transfers are blocked', () async {
    final people = await localPeople();
    final governance = CourseGovernanceService(
      profileService: people.profiles,
      teamService: people.teams,
    );
    await expectLater(
      governance.transferOwnership(
        course: course(),
        actorProfileId: bobId,
        newOwnerProfileId: charlieId,
        editMode: true,
      ),
      throwsStateError,
    );
    await expectLater(
      governance.transferOwnership(
        course: course(),
        actorProfileId: aliceId,
        newOwnerProfileId: bobId,
        editMode: false,
      ),
      throwsStateError,
    );
  });

  test(
    'Team leadership and Course ownership grant no powers over each other',
    () async {
      final people = await localPeople();
      final governance = CourseGovernanceService(
        profileService: people.profiles,
        teamService: people.teams,
      );

      await expectLater(
        governance.assignTeam(
          course: course(ownerId: bobId),
          actorProfileId: aliceId,
          teamId: teamId,
          editMode: true,
          assignmentConfirmed: true,
        ),
        throwsStateError,
      );
      await expectLater(
        people.teams.addMember(
          teamId: teamId,
          actorProfileId: bobId,
          memberProfileId: bobId,
        ),
        throwsStateError,
      );
    },
  );

  test('Owner alone assigns and revokes a Team after confirmation', () async {
    final people = await localPeople();
    final governance = CourseGovernanceService(
      profileService: people.profiles,
      teamService: people.teams,
    );
    await expectLater(
      governance.assignTeam(
        course: course(),
        actorProfileId: aliceId,
        teamId: teamId,
        editMode: true,
        assignmentConfirmed: false,
      ),
      throwsStateError,
    );
    final assigned = await governance.assignTeam(
      course: course(),
      actorProfileId: aliceId,
      teamId: teamId,
      editMode: true,
      assignmentConfirmed: true,
    );
    expect(assigned.assignedTeamId, teamId);
    expect(assigned.ownership!.id, aliceId);
    expect(assigned.creatorProfileId, aliceId);

    await expectLater(
      governance.assignTeam(
        course: course(),
        actorProfileId: charlieId,
        teamId: teamId,
        editMode: true,
        assignmentConfirmed: true,
      ),
      throwsStateError,
    );
    final revoked = await governance.assignTeam(
      course: assigned,
      actorProfileId: aliceId,
      teamId: null,
      editMode: true,
    );
    expect(revoked.assignedTeamId, isNull);
    expect(revoked.ownership!.id, aliceId);
  });

  test('one Team can manage Courses with different Creators and Owners', () {
    final first = course(assignedTeamId: teamId);
    final second = course(
      id: 'course-qql-233-two',
      creatorId: charlieId,
      ownerId: bobId,
      assignedTeamId: teamId,
    );
    expect(first.assignedTeamId, second.assignedTeamId);
    expect(first.creatorProfileId, isNot(second.creatorProfileId));
    expect(first.ownership!.id, isNot(second.ownership!.id));
  });
}
