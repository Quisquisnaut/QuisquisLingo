import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_editor_storage.dart';
import 'package:quisquislingo_app/services/course_governance_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _aliceId = '11111111-1111-4111-8111-111111111111';
const _bobId = '22222222-2222-4222-8222-222222222222';
const _charlieId = '33333333-3333-4333-8333-333333333333';
final _now = DateTime.utc(2026, 9, 12, 14, 30);
final _later = DateTime.utc(2026, 9, 12, 15, 45);

Course _source({CourseForkProvenance? forkProvenance}) => Course(
  courseId: 'course-source',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _aliceId,
    displayName: 'Alice',
  ),
  maintainer: const CourseMaintainer(_bobId),
  assignedTeamId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  originalCreatedAtUtc: '2026-08-01T08:00:00.000Z',
  lastVersionEditorProfileId: _bobId,
  lastVersionEditorDisplayName: 'Bob',
  modifiedAtUtc: '2026-09-01T09:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Source',
  ttsLanguage: 'it-IT',
  authors: const [
    CourseAuthor(name: 'Credited Author', roles: ['Author']),
  ],
  rightsHolders: const [
    CourseRightsHolder(
      type: CourseRightsHolderType.organization,
      name: 'Rights Organisation',
    ),
  ],
  license: 'CC BY 4.0',
  derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
  forkProvenance: forkProvenance,
  courseVersion: '3',
  lessons: const [],
);

Future<ProfileService> _profiles({String active = _aliceId}) async {
  final profiles = ProfileService();
  await profiles.createProfile('Alice', learnerProfileId: _aliceId);
  await profiles.createProfile('Bob', learnerProfileId: _bobId);
  await profiles.createProfile('Charlie', learnerProfileId: _charlieId);
  await profiles.setActiveProfileById(active);
  return profiles;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'v9 namespace ignores and preserves v8 storage without fallback',
    () async {
      final v8Custom = jsonEncode({
        'legacy': {
          'savedAt': '2026-09-01T00:00:00.000Z',
          'course': {'formatVersion': 8},
        },
      });
      final v8Official = jsonEncode({
        'legacy-official': {
          'savedAt': '2026-09-01T00:00:00.000Z',
          'course': {'formatVersion': 8},
        },
      });
      const v8CorruptBackup = 'legacy corrupt v8 bytes';
      const v8BundledCodes = ['legacy_v8_code'];
      SharedPreferences.setMockInitialValues({
        'quisquislingo_user_courses_v8_233030': v8Custom,
        'quisquislingo_external_official_courses_v8_233030': v8Official,
        'quisquislingo_course_editor_corrupt_backup_v8_233030': v8CorruptBackup,
        'quisquislingo_bundled_course_codes_v8_233030': v8BundledCodes,
      });
      final profiles = await _profiles();
      final service = CourseEditorService(profileService: profiles);

      expect(await service.listUserCourses(), isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('quisquislingo_user_courses_v8_233030'),
        v8Custom,
      );
      expect(preferences.getString(CourseEditorStorage.userCoursesKey), isNull);
      expect(
        preferences.getString(
          'quisquislingo_external_official_courses_v8_233030',
        ),
        v8Official,
      );
      expect(
        preferences.getString(
          'quisquislingo_course_editor_corrupt_backup_v8_233030',
        ),
        v8CorruptBackup,
      );
      expect(
        preferences.getString(CourseEditorStorage.externalOfficialCoursesKey),
        isNull,
      );
      expect(
        preferences.getString(CourseEditorStorage.corruptBackupKey),
        isNull,
      );

      final bundledCodes = await CourseService()
          .reconcileAvailableBundledCourseCodes();
      expect(bundledCodes, isNot(contains('legacy_v8_code')));
      expect(
        preferences.getStringList(
          'quisquislingo_bundled_course_codes_v8_233030',
        ),
        v8BundledCodes,
      );
      expect(
        preferences.getStringList(CourseService.bundledCourseIndexStorageKey),
        bundledCodes,
      );

      final ownCourse = Course.fromJson(
        {
          ..._source().toJson(),
          'maintainer': const CourseMaintainer(_aliceId).toJson(),
          'assignedTeamId': null,
        }..remove('assignedTeamId'),
      );
      await service.saveUserCourse(ownCourse);

      expect(
        preferences.getString(CourseEditorStorage.userCoursesKey),
        isNotNull,
      );
      expect(
        preferences.getString('quisquislingo_user_courses_v8_233030'),
        v8Custom,
      );
    },
  );

  test('Copy as New Course starts an independent lineage', () async {
    final profiles = await _profiles(active: _bobId);
    final service = CourseEditorService(
      profileService: profiles,
      clock: () => _now,
    );
    await service.saveUserCourse(_source());

    final copy = (await service.createCopyAsNewCourse(
      source: _source(),
      title: 'Independent Course',
    )).course;

    expect(copy.courseId, isNot(_source().courseId));
    expect(copy.title, 'Independent Course');
    expect(copy.originalCourseCreator.id, _bobId);
    expect(copy.originalCreatedAtUtc, _now.toIso8601String());
    expect(copy.maintainer!.profileId, _bobId);
    expect(copy.assignedTeamId, isNull);
    expect(copy.forkProvenance, isNull);
    expect(copy.authors.single.name, 'Credited Author');
    expect(copy.rightsHolders.single.name, 'Rights Organisation');
    expect(copy.license, 'CC BY 4.0');
    expect(copy.lastVersionEditorProfileId, _bobId);
    expect(copy.modifiedAtUtc, _now.toIso8601String());
    expect(copy.versionNotes, 'Created as a new independent Course.');
    expect(jsonEncode(copy.toJson()), isNot(contains(_source().courseId)));
  });

  test('Fork preserves lineage and records its immediate source', () async {
    final profiles = await _profiles(active: _charlieId);
    final service = CourseEditorService(
      profileService: profiles,
      clock: () => _now,
    );

    final fork = (await service.createFork(source: _source())).course;

    expect(fork.originalCourseCreator.id, _aliceId);
    expect(fork.originalCreatedAtUtc, '2026-08-01T08:00:00.000Z');
    expect(fork.maintainer!.profileId, _charlieId);
    expect(fork.assignedTeamId, isNull);
    expect(fork.authors.single.name, 'Credited Author');
    expect(fork.rightsHolders.single.name, 'Rights Organisation');
    expect(fork.license, 'CC BY 4.0');
    expect(fork.lastVersionEditorProfileId, _charlieId);
    expect(fork.modifiedAtUtc, _now.toIso8601String());
    expect(fork.forkProvenance!.sourceCourseId, _source().courseId);
    expect(fork.forkProvenance!.sourceCourseVersion, '3');
    expect(fork.forkProvenance!.forkCreatedByProfileId, _charlieId);
    expect(fork.forkProvenance!.forkCreatedAtUtc, _now.toIso8601String());
  });

  test(
    'fork of a fork preserves root lineage and records immediate source',
    () async {
      final profiles = await _profiles(active: _charlieId);
      final firstFork = (await CourseEditorService(
        profileService: profiles,
        clock: () => _now,
      ).createFork(source: _source())).course;
      await profiles.setActiveProfileById(_bobId);

      final secondFork = (await CourseEditorService(
        profileService: profiles,
        clock: () => _later,
      ).createFork(source: firstFork)).course;

      expect(secondFork.originalCourseCreator.id, _aliceId);
      expect(secondFork.originalCreatedAtUtc, '2026-08-01T08:00:00.000Z');
      expect(secondFork.forkProvenance!.sourceCourseId, firstFork.courseId);
      expect(
        secondFork.forkProvenance!.sourceCourseId,
        isNot(_source().courseId),
      );
      expect(secondFork.forkProvenance!.forkCreatedByProfileId, _bobId);
      expect(
        secondFork.forkProvenance!.forkCreatedAtUtc,
        _later.toIso8601String(),
      );
    },
  );

  test('Fork rejects provenance that does not match its immediate source', () {
    final source = _source();
    final falseProvenance = CourseForkProvenance(
      sourceCourseId: source.courseId,
      sourceCourseTitle: 'Not the source title',
      sourceCourseVersion: source.courseVersion,
      sourceOriginType: source.originType,
      sourceAuthors: source.authors,
      forkCreatedByProfileId: _charlieId,
      forkCreatedByDisplayName: 'Charlie',
      forkCreatedAtUtc: _now.toIso8601String(),
    );

    expect(
      () => AuthoringDuplicationService().forkCustomCourse(
        source,
        provenance: falseProvenance,
        maintainer: const CourseMaintainer(_charlieId),
      ),
      throwsStateError,
    );
  });

  test(
    'Maintainer transfer preserves provenance and Rights Holder metadata',
    () async {
      final profiles = await _profiles(active: _bobId);
      final governance = CourseGovernanceService(profileService: profiles);
      final source = _source();

      final transferred = await governance.transferMaintainer(
        course: source,
        actorProfileId: _bobId,
        newMaintainerProfileId: _charlieId,
        editMode: true,
      );

      expect(transferred.maintainer!.profileId, _charlieId);
      expect(
        transferred.originalCourseCreator.toJson(),
        source.originalCourseCreator.toJson(),
      );
      expect(transferred.originalCreatedAtUtc, source.originalCreatedAtUtc);
      expect(transferred.rightsHolders.single.name, 'Rights Organisation');
    },
  );

  test(
    'provenance identities do not retain access after Maintainer transfer',
    () async {
      final profiles = await _profiles(active: _charlieId);
      final fork = (await CourseEditorService(
        profileService: profiles,
        clock: () => _now,
      ).createFork(source: _source())).course;
      final transferred =
          await CourseGovernanceService(
            profileService: profiles,
          ).transferMaintainer(
            course: fork,
            actorProfileId: _charlieId,
            newMaintainerProfileId: _bobId,
            editMode: true,
          );

      expect(
        CourseAccessPolicy.evaluate(
          transferred,
          profileId: _aliceId,
        ).canEditOriginal,
        isFalse,
      );
      expect(
        CourseAccessPolicy.evaluate(
          transferred,
          profileId: _charlieId,
        ).canEditOriginal,
        isFalse,
      );
      expect(
        CourseAccessPolicy.evaluate(
          transferred,
          profileId: _bobId,
        ).canEditOriginal,
        isTrue,
      );
    },
  );

  test('Rights Holder metadata never grants QQL editing permission', () {
    final namedAsRightsHolder = Course.fromJson({
      ..._source().toJson(),
      'rightsHolders': [
        {'type': 'person', 'name': _charlieId},
      ],
    });

    final access = CourseAccessPolicy.evaluate(
      namedAsRightsHolder,
      profileId: _charlieId,
    );
    expect(access.canEditOriginal, isFalse);
    expect(access.canTransferMaintainership, isFalse);
  });

  test(
    'assigned Team editor updates current-version metadata without rewriting lineage',
    () async {
      final profiles = await _profiles(active: _charlieId);
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        clock: () => _now,
      );
      await teams.createTeam(
        creatorProfileId: _aliceId,
        displayName: 'Course Team',
      );
      await teams.addMember(
        teamId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        actorProfileId: _aliceId,
        memberProfileId: _charlieId,
      );
      final service = CourseEditorService(
        profileService: profiles,
        teamService: teams,
        backupService: _MemoryBackupService(),
        clock: () => _now,
      );
      final source = _source();
      await service.saveUserCourse(source);
      final working = Course.fromJson({
        ...source.toJson(),
        'title': 'Edited by assigned Team member',
        'rightsHolders': const [
          {'type': 'organization', 'name': 'Updated Rights Organisation'},
        ],
      });

      final result = await service.confirmCourseTransaction(
        originalCourse: source,
        workingCourse: working,
        languageCode: 'it-IT',
        versionNotes: 'Team edit',
      );

      expect(
        result.course.originalCourseCreator.toJson(),
        source.originalCourseCreator.toJson(),
      );
      expect(result.course.originalCreatedAtUtc, source.originalCreatedAtUtc);
      expect(result.course.maintainer!.profileId, _bobId);
      expect(
        result.course.assignedTeamId,
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      );
      expect(result.course.lastVersionEditorProfileId, _charlieId);
      expect(
        result.course.lastVersionEditorDisplayName,
        (await profiles.getProfileById(_charlieId))!.displayName,
      );
      expect(result.course.modifiedAtUtc, _now.toIso8601String());
      expect(
        result.course.rightsHolders.single.name,
        'Updated Rights Organisation',
      );
    },
  );
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
