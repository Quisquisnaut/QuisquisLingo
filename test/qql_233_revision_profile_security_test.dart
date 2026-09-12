import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/formal_name_policy.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _aliceId = '10000000-0000-4000-8000-000000000001';
const _bobId = '20000000-0000-4000-8000-000000000002';
const _charlieId = '30000000-0000-4000-8000-000000000003';
const _teamId = '40000000-0000-4000-8000-000000000004';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileService.beginAccessSession();
  });

  test('Screen Name textual rules accept safe Latin names only', () {
    expect(
      FormalNamePolicy.validateUserScreenName("Élodie O'Neil-Smith_"),
      "Élodie O'Neil-Smith_",
    );
    const decomposed = 'Elodie\u0301';
    expect(FormalNamePolicy.validateUserScreenName(decomposed), decomposed);
    expect(
      FormalNamePolicy.comparisonKey(decomposed),
      FormalNamePolicy.comparisonKey('Elodié'),
    );
    for (final invalid in <String>[
      'A',
      List.filled(33, 'A').join(),
      ' Mario',
      'Mario ',
      'Mario  Rossi',
      'Mario2',
      'Mario@home',
      'Mario/Rossi',
      'Mario\nRossi',
      'Mario\tRossi',
      'Mario😀',
      '--__',
      'Mario\u200BRossi',
    ]) {
      expect(
        () => FormalNamePolicy.validateUserScreenName(invalid),
        throwsArgumentError,
        reason: invalid,
      );
    }
  });

  test('Team and Course label rules allow digits but reject unsafe input', () {
    expect(
      FormalNamePolicy.validatePresentationLabel('Italian Team 2'),
      'Italian Team 2',
    );
    expect(FormalNamePolicy.validatePresentationLabel('A'), 'A');
    expect(
      FormalNamePolicy.validatePresentationLabel('日本語 Course 2'),
      '日本語 Course 2',
    );
    for (final invalid in [' Team', 'Team  Name', 'Team|Name', 'Team😀']) {
      expect(
        () => FormalNamePolicy.validatePresentationLabel(invalid),
        throwsArgumentError,
      );
    }
  });

  test(
    'Team persistence applies the shared policy and reports duplicates',
    () async {
      final profiles = _threeProfiles();
      await profiles.createProfile('Alice Smith');
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => _teamId,
      );
      await teams.createTeam(
        creatorProfileId: _aliceId,
        displayName: 'Italian Team 2',
      );
      expect(await teams.hasDuplicateTeamName('italian team 2'), isTrue);
      await expectLater(
        teams.renameTeam(
          teamId: _teamId,
          actorProfileId: _aliceId,
          displayName: 'Unsafe/Team',
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'Discord validation is warning-only data and normalization adds one @',
    () {
      expect(ProfileService.isFormallyValidDiscordUsername('testuser'), isTrue);
      expect(
        ProfileService.isFormallyValidDiscordUsername('@testuser'),
        isTrue,
      );
      expect(
        ProfileService.isFormallyValidDiscordUsername('test..test'),
        isFalse,
      );
      expect(
        ProfileService.isFormallyValidDiscordUsername('test@user'),
        isFalse,
      );
      expect(
        ProfileService.isFormallyValidDiscordUsername('@@testuser'),
        isFalse,
      );
      expect(ProfileService.normalizeDiscordHandle('testuser'), '@testuser');
      expect(ProfileService.normalizeDiscordHandle('@testuser'), '@testuser');
      expect(ProfileService.normalizeDiscordHandle('@@testuser'), '@testuser');
      expect(ProfileService.normalizeDiscordHandle(''), isNull);
    },
  );

  test(
    'new profiles receive a collision-safe five-digit retained suffix',
    () async {
      final ids = [_aliceId, _bobId].iterator;
      final suffixes = [12345, 12345, 54321].iterator;
      final profiles = ProfileService(
        idGenerator: () {
          ids.moveNext();
          return ids.current;
        },
        numericSuffixGenerator: () {
          suffixes.moveNext();
          return suffixes.current;
        },
        randomIndex: (_) => 0,
      );

      final alice = await profiles.createProfile('Mario Rossi');
      final bob = await profiles.createProfile('Mario Rossi');
      expect(alice.displayName, 'Mario Rossi 12345');
      expect(alice.screenNameSuffix, '12345');
      expect(bob.displayName, 'Mario Rossi 54321');

      await profiles.renameProfileText(
        learnerProfileId: _aliceId,
        screenNameText: 'Aldo Bianchi',
        discordHandle: 'aldo',
      );
      final renamed = await profiles.getProfileById(_aliceId);
      expect(renamed!.displayName, 'Aldo Bianchi 12345');
      expect(renamed.learnerProfileId, _aliceId);
      expect(renamed.discordHandle, '@aldo');
      expect(
        await profiles.hasDuplicateScreenName(
          renamed.displayName,
          excludingProfileId: _aliceId,
        ),
        isFalse,
      );
    },
  );

  test(
    'duplicate complete Screen Names are detected but remain legal',
    () async {
      final profiles = _threeProfiles();
      final first = await profiles.createProfile('Same Learner');
      final second = await profiles.createProfile('Other Learner');
      await profiles.replaceProfileRecord(
        LearnerProfile(
          learnerProfileId: second.learnerProfileId,
          displayName: first.displayName,
        ),
      );

      expect(
        await profiles.hasDuplicateScreenName(
          first.displayName,
          excludingProfileId: first.learnerProfileId,
        ),
        isTrue,
      );
      expect(
        await profiles.hasDuplicateScreenName(
          first.displayName,
          excludingProfileId: second.learnerProfileId,
        ),
        isTrue,
      );
      expect(
        (await profiles.getProfileRecords()).where(
          (profile) => profile.displayName == first.displayName,
        ),
        hasLength(2),
      );
    },
  );

  test(
    'first profile is admin and zero-admin transitions are blocked',
    () async {
      final profiles = _threeProfiles();
      await profiles.createProfile('Alice Smith');
      await profiles.createProfile('Bob Jones');
      await profiles.createProfile('Charlie Brown');

      expect(await profiles.isAdmin(_aliceId), isTrue);
      expect(await profiles.isAdmin(_bobId), isFalse);
      await profiles.promoteToAdmin(
        actorProfileId: _aliceId,
        targetProfileId: _bobId,
      );
      expect(await profiles.isAdmin(_bobId), isTrue);
      await profiles.relinquishAdmin(_aliceId);
      expect(await profiles.isAdmin(_aliceId), isFalse);
      expect(() => profiles.relinquishAdmin(_bobId), throwsStateError);
      expect(
        () => profiles.promoteToAdmin(
          actorProfileId: _charlieId,
          targetProfileId: _charlieId,
        ),
        throwsStateError,
      );
    },
  );

  test(
    'normal users delete only themselves while admins may delete others',
    () async {
      final profiles = _threeProfiles();
      await profiles.createProfile('Alice Smith');
      await profiles.createProfile('Bob Jones');
      await profiles.createProfile('Charlie Brown');

      await expectLater(
        profiles.deleteProfileById(_charlieId, actorProfileId: _bobId),
        throwsStateError,
      );
      await profiles.deleteProfileById(_charlieId, actorProfileId: _aliceId);
      expect(await profiles.getProfileById(_charlieId), isNull);
      await profiles.deleteProfileById(_bobId, actorProfileId: _bobId);
      expect(await profiles.getProfileById(_bobId), isNull);
    },
  );

  test(
    'PIN protects switching and supports change, removal and admin reset',
    () async {
      final profiles = _threeProfiles();
      await profiles.createProfile('Alice Smith');
      await profiles.createProfile('Bob Jones');
      await profiles.createProfile('Charlie Brown');
      await profiles.setOwnAccessPin(actorProfileId: _bobId, pin: '1234');

      expect(await profiles.hasAccessPin(_bobId), isTrue);
      final prefs = await SharedPreferences.getInstance();
      final verifierKey = prefs.getKeys().singleWhere(
        (key) => key.endsWith('access_pin_verifier_v1'),
      );
      expect(prefs.getString(verifierKey), startsWith('v1:'));
      expect(prefs.getString(verifierKey), isNot(contains('1234')));
      expect(await profiles.verifyAccessPin(_bobId, '1234'), isTrue);
      expect(await profiles.verifyAccessPin(_bobId, '0000'), isFalse);
      await expectLater(
        profiles.setActiveProfileById(_bobId, accessPin: '0000'),
        throwsA(isA<ProfilePinException>()),
      );
      await profiles.setActiveProfileById(_bobId, accessPin: '1234');
      expect(await profiles.getActiveProfileId(), _bobId);

      await profiles.setOwnAccessPin(actorProfileId: _bobId, pin: '5678');
      expect(await profiles.verifyAccessPin(_bobId, '1234'), isFalse);
      expect(await profiles.verifyAccessPin(_bobId, '5678'), isTrue);
      await profiles.setOwnAccessPin(actorProfileId: _bobId, pin: null);
      expect(await profiles.hasAccessPin(_bobId), isFalse);

      await profiles.setOwnAccessPin(actorProfileId: _charlieId, pin: '9999');
      await profiles.resetAccessPinAsAdmin(
        actorProfileId: _aliceId,
        targetProfileId: _charlieId,
      );
      expect(await profiles.hasAccessPin(_charlieId), isFalse);
      await profiles.setActiveProfileById(_charlieId);
      expect(await profiles.getActiveProfileId(), _charlieId);
    },
  );

  test('only admins can change the descriptive device name', () async {
    final profiles = _threeProfiles(systemDeviceName: () => 'DESKTOP-7A3K2');
    await profiles.createProfile('Alice Smith');
    await profiles.createProfile('Bob Jones');
    expect(await profiles.getDeviceDisplayName(), 'DESKTOP-7A3K2');
    await expectLater(
      profiles.setDeviceDisplayName(
        actorProfileId: _bobId,
        displayName: 'Studio PC',
      ),
      throwsStateError,
    );
    await profiles.setDeviceDisplayName(
      actorProfileId: _aliceId,
      displayName: 'Studio PC',
    );
    expect(await profiles.getDeviceDisplayName(), 'Studio PC');
  });

  test(
    'renaming changes presentation only and retains every ID relationship',
    () async {
      final profiles = _threeProfiles();
      final alice = await profiles.createProfile('Alice Smith');
      await profiles.createProfile('Bob Jones');
      await profiles.setActiveProfileById(_aliceId);
      await profiles.setOwnAccessPin(actorProfileId: _aliceId, pin: '1234');
      final progress = ProgressService(now: () => DateTime(2026, 9, 12));
      await progress.addXp(31, courseCode: 'IT', courseId: 'identity-course');
      await progress.completeRound(
        'round-one',
        courseId: 'identity-course',
        courseCode: 'IT',
      );
      await progress.recordRecentRound(
        'identity-course',
        'lesson-one',
        'round-one',
        errors: 2,
      );
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => _teamId,
        clock: () => DateTime.utc(2026, 9, 12),
      );
      await teams.createTeam(
        creatorProfileId: _aliceId,
        displayName: 'Identity Team',
      );
      final course = Course(
        courseId: 'identity-course',
        originalCourseCreator: CourseProvenanceIdentity.qqlUser(
          profileId: _aliceId,
          displayName: 'Original Course Creator',
        ),
        maintainer: const CourseMaintainer(_aliceId),
        assignedTeamId: _teamId,
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Identity Course',
        ttsLanguage: 'it-IT',
        lessons: const [],
      );

      final renamed = await profiles.renameProfileText(
        learnerProfileId: alice.learnerProfileId,
        screenNameText: 'Alicia Smith',
        discordHandle: 'alicia',
      );

      expect(renamed.learnerProfileId, _aliceId);
      expect(renamed.screenNameSuffix, alice.screenNameSuffix);
      expect(course.originalCourseCreator.id, _aliceId);
      expect(course.maintainer!.profileId, _aliceId);
      expect(course.assignedTeamId, _teamId);
      final team = await teams.teamById(_teamId);
      expect(team!.memberProfileIds, contains(_aliceId));
      expect(team.leadProfileIds, contains(_aliceId));
      expect(await profiles.isAdmin(_aliceId), isTrue);
      expect(await profiles.verifyAccessPin(_aliceId, '1234'), isTrue);
      expect(await progress.getXp(courseCode: 'IT'), 31);
      expect(
        await progress.getCompletedRounds(courseId: 'identity-course'),
        contains('round-one'),
      );
      expect(
        (await progress.getRecentRounds(
          courseId: 'identity-course',
        )).single.roundId,
        'round-one',
      );
    },
  );
}

ProfileService _threeProfiles({String Function()? systemDeviceName}) {
  final ids = [_aliceId, _bobId, _charlieId].iterator;
  var suffix = 10000;
  return ProfileService(
    idGenerator: () {
      ids.moveNext();
      return ids.current;
    },
    numericSuffixGenerator: () => suffix++,
    randomIndex: (_) => 0,
    systemDeviceName: systemDeviceName,
  );
}
