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
  String originalCreatorId = aliceId,
  String maintainerId = aliceId,
  String? assignedTeamId,
  String id = 'course-qql-233',
}) => Course(
  courseId: id,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: originalCreatorId,
    displayName: 'Original Course Creator',
  ),
  maintainer: CourseMaintainer(maintainerId),
  assignedTeamId: assignedTeamId,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'QQL 233 course',
  ttsLanguage: 'it-IT',
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

  test('Course Model v9 permits only an individual Maintainer', () {
    final json = course().toJson();
    expect(json['formatVersion'], 9);
    expect(json['maintainer'], {'profileId': aliceId});
    expect(json.containsKey('ownership'), isFalse);
    expect(Course.fromJson(json).maintainer!.profileId, aliceId);
    expect(
      () => Course.fromJson({
        ...json,
        'maintainer': {'profileId': teamId, 'type': 'team'},
      }),
      throwsFormatException,
    );
  });

  test('Team assignment is separate and survives Course JSON round-trip', () {
    final value = course(assignedTeamId: teamId);
    final json = value.toJson();
    expect(json['maintainer'], {'profileId': aliceId});
    expect(json['assignedTeamId'], teamId);
    final restored = Course.fromJson(json);
    expect(restored.maintainer!.profileId, aliceId);
    expect(restored.assignedTeamId, teamId);
    expect(restored.originalCourseCreator.id, aliceId);
  });

  test('Maintainer and assigned Team management powers stay independent', () {
    final value = course(assignedTeamId: teamId);
    final owner = CourseAccessPolicy.evaluate(value, profileId: aliceId);
    expect(owner.canEditOriginal, isTrue);
    expect(owner.canTransferMaintainership, isTrue);
    expect(owner.canAssignTeam, isTrue);

    final assignedMember = CourseAccessPolicy.evaluate(
      value,
      profileId: charlieId,
      memberTeamIds: {teamId},
    );
    expect(assignedMember.canEditOriginal, isTrue);
    expect(assignedMember.canTransferMaintainership, isFalse);
    expect(assignedMember.canAssignTeam, isFalse);

    final unrelatedTeamLeader = CourseAccessPolicy.evaluate(
      course(),
      profileId: charlieId,
      memberTeamIds: {teamId},
    );
    expect(unrelatedTeamLeader.canEditOriginal, isFalse);
    expect(unrelatedTeamLeader.canTransferMaintainership, isFalse);
  });

  test('Maintainer transfer preserves Original Course Creator', () async {
    final people = await localPeople();
    final governance = CourseGovernanceService(
      profileService: people.profiles,
      teamService: people.teams,
    );
    final transferred = await governance.transferMaintainer(
      course: course(),
      actorProfileId: aliceId,
      newMaintainerProfileId: bobId,
      editMode: true,
    );
    expect(transferred.originalCourseCreator.id, aliceId);
    expect(transferred.maintainer!.profileId, bobId);
    expect(
      (await people.profiles.getProfileById(bobId))!.presentationName,
      '@bob_words',
    );
  });

  test(
    'Original creator can confirm another individual as initial Maintainer',
    () async {
      final people = await localPeople();
      final service = CourseEditorService(
        profileService: people.profiles,
        teamService: people.teams,
        clock: () => DateTime.utc(2026, 9, 12),
      );
      final value = course(maintainerId: bobId);

      await service.confirmCourseTransaction(
        originalCourse: value,
        workingCourse: value,
        languageCode: 'IT',
        versionNotes: '',
        isNewCourse: true,
      );

      final persisted = (await service.listUserCourses()).single;
      expect(persisted.originalCourseCreator.id, aliceId);
      expect(persisted.maintainer!.profileId, bobId);
    },
  );

  test(
    'non-maintainer and non-Edit Maintainer transfers are blocked',
    () async {
      final people = await localPeople();
      final governance = CourseGovernanceService(
        profileService: people.profiles,
        teamService: people.teams,
      );
      await expectLater(
        governance.transferMaintainer(
          course: course(),
          actorProfileId: bobId,
          newMaintainerProfileId: charlieId,
          editMode: true,
        ),
        throwsStateError,
      );
      await expectLater(
        governance.transferMaintainer(
          course: course(),
          actorProfileId: aliceId,
          newMaintainerProfileId: bobId,
          editMode: false,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'Team leadership and Course maintenance grant no powers over each other',
    () async {
      final people = await localPeople();
      final governance = CourseGovernanceService(
        profileService: people.profiles,
        teamService: people.teams,
      );

      await expectLater(
        governance.assignTeam(
          course: course(maintainerId: bobId),
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

  test(
    'Maintainer alone assigns and revokes a Team after confirmation',
    () async {
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
      expect(assigned.maintainer!.profileId, aliceId);
      expect(assigned.originalCourseCreator.id, aliceId);

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
      expect(revoked.maintainer!.profileId, aliceId);
    },
  );

  test(
    'one Team can manage Courses with different creators and Maintainers',
    () {
      final first = course(assignedTeamId: teamId);
      final second = course(
        id: 'course-qql-233-two',
        originalCreatorId: charlieId,
        maintainerId: bobId,
        assignedTeamId: teamId,
      );
      expect(first.assignedTeamId, second.assignedTeamId);
      expect(
        first.originalCourseCreator.id,
        isNot(second.originalCourseCreator.id),
      );
      expect(first.maintainer!.profileId, isNot(second.maintainer!.profileId));
    },
  );
}
