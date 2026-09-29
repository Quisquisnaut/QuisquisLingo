import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_governance_service.dart';
import 'package:quisquislingo_app/services/course_info_update_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _aliceId = '11111111-1111-4111-8111-111111111111';
const _bobId = '22222222-2222-4222-8222-222222222222';
const _teamId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'clears optional Course Info fields without changing other content',
    () async {
      final original = _course(
        estimatedStudyHours: 12,
        minimumAge: 13,
        keywords: const ['travel'],
        publisherContact: CoursePublisherContact(email: 'old@example.org'),
        minimumAppBuild: 1,
      );
      final result = await CourseInfoUpdateService().apply(
        original,
        _change(original, title: 'Edited course'),
        _aliceId,
      );

      final json = result.course.toJson();
      for (final field in const [
        'estimatedStudyHours',
        'minimumAge',
        'keywords',
        'publisherContact',
        'minimumAppBuild',
      ]) {
        expect(json.containsKey(field), isFalse, reason: field);
      }
      expect(result.course.title, 'Edited course');
      expect(result.course.courseVersion, '7');
      expect(result.course.lessons.single.lessonId, 'lesson-1');
      expect(result.course.originalCourseCreator.id, _aliceId);
      expect(result.governanceChanged, isFalse);
      expect(original.toJson().containsKey('estimatedStudyHours'), isTrue);
    },
  );

  // Build 258 Revision 4: learners may share, save and print Pages, on by
  // default; only the off state is stored.
  test('stores the page sharing setting', () async {
    final original = _course();
    expect(original.allowPageSharing, isTrue);
    final off = (await CourseInfoUpdateService().apply(
      original,
      _change(original, allowPageSharing: false),
      _aliceId,
    )).course;
    expect(off.allowPageSharing, isFalse);
    expect(off.toJson()['allowPageSharing'], isFalse);
    final on = (await CourseInfoUpdateService().apply(
      off,
      _change(off, allowPageSharing: true),
      _aliceId,
    )).course;
    expect(on.allowPageSharing, isTrue);
    expect(on.toJson().containsKey('allowPageSharing'), isFalse);
  });

  // Build 255 Revision 6: the Course Info Editor sets and removes the cover.
  test('stores and clears the cover', () async {
    final original = _course();
    final cover = 'media:${'b' * 64}.png';
    final withCover = (await CourseInfoUpdateService().apply(
      original,
      _change(original, coverImage: cover),
      _aliceId,
    )).course;
    expect(withCover.coverImage, cover);
    final cleared = (await CourseInfoUpdateService().apply(
      withCover,
      _change(withCover, coverImage: ''),
      _aliceId,
    )).course;
    expect(cleared.coverImage, isEmpty);
    expect(cleared.toJson().containsKey('coverImage'), isFalse);
  });

  test('assigns Team before transferring Maintainer in one edit', () async {
    final profiles = ProfileService();
    await profiles.createProfile('Alice', learnerProfileId: _aliceId);
    await profiles.createProfile('Bob', learnerProfileId: _bobId);
    await profiles.setActiveProfileById(_aliceId);
    final teams = TeamService(
      profileService: profiles,
      idGenerator: () => _teamId,
      clock: () => DateTime.utc(2026, 9, 22),
    );
    await teams.createTeam(
      creatorProfileId: _aliceId,
      displayName: 'Editing Team',
    );
    final original = _course();
    final service = CourseInfoUpdateService(
      governanceService: CourseGovernanceService(
        profileService: profiles,
        teamService: teams,
      ),
    );

    final result = await service.apply(
      original,
      _change(original, assignedTeamId: _teamId, maintainerProfileId: _bobId),
      _aliceId,
    );

    expect(result.course.assignedTeamId, _teamId);
    expect(result.course.maintainer!.profileId, _bobId);
    expect(result.course.originalCourseCreator.id, _aliceId);
    expect(result.governanceChanged, isTrue);
    expect(original.assignedTeamId, isNull);
    expect(original.maintainer!.profileId, _aliceId);
  });

  test(
    'rejects governance edits by another profile without changing source',
    () async {
      final profiles = ProfileService();
      await profiles.createProfile('Alice', learnerProfileId: _aliceId);
      await profiles.createProfile('Bob', learnerProfileId: _bobId);
      await profiles.setActiveProfileById(_aliceId);
      final teams = TeamService(
        profileService: profiles,
        idGenerator: () => _teamId,
        clock: () => DateTime.utc(2026, 9, 22),
      );
      await teams.createTeam(
        creatorProfileId: _aliceId,
        displayName: 'Editing Team',
      );
      final original = _course();
      final before = original.toJson();
      final service = CourseInfoUpdateService(
        governanceService: CourseGovernanceService(
          profileService: profiles,
          teamService: teams,
        ),
      );
      final denied = isA<StateError>().having(
        (error) => error.message,
        'authorization message',
        contains('Only the current Course Maintainer'),
      );

      await expectLater(
        service.apply(
          original,
          _change(original, assignedTeamId: _teamId),
          _bobId,
        ),
        throwsA(denied),
      );
      await expectLater(
        service.apply(
          original,
          _change(original, maintainerProfileId: _bobId),
          _bobId,
        ),
        throwsA(denied),
      );
      expect(original.toJson(), before);
    },
  );
}

Course _course({
  int? estimatedStudyHours,
  int? minimumAge,
  List<String> keywords = const [],
  CoursePublisherContact? publisherContact,
  int? minimumAppBuild,
}) => Course(
  courseId: 'course-info-update',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _aliceId,
    displayName: 'Alice',
  ),
  maintainer: const CourseMaintainer(_aliceId),
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Original course',
  ttsLanguage: 'it-IT',
  courseVersion: '7',
  license: 'All rights reserved',
  estimatedStudyHours: estimatedStudyHours,
  minimumAge: minimumAge,
  keywords: keywords,
  publisherContact: publisherContact,
  minimumAppBuild: minimumAppBuild,
  lessons: [Lesson(lessonId: 'lesson-1', title: 'First', rounds: const [])],
);

CourseInfoChange _change(
  Course course, {
  String? title,
  String? assignedTeamId,
  String? maintainerProfileId,
  String? coverImage,
  bool? allowPageSharing,
}) => (
  title: title ?? course.title,
  authors: course.authors,
  rightsHolders: course.rightsHolders,
  mediaAttributions: course.mediaAttributions,
  license: course.license,
  derivativePolicy: course.derivativeWorksPolicy,
  allowPageSharing: allowPageSharing ?? course.allowPageSharing,
  variant: course.languageVariant,
  startLevel: course.startLevel,
  targetLevel: course.targetLevel,
  description: course.courseDescription,
  buyACoffeeUrl: course.buyACoffeeUrl,
  estimatedStudyHours: null,
  minimumAge: null,
  keywords: <String>[],
  publisherContact: null,
  minimumAppBuild: null,
  flagCode: course.flagCode,
  flagImageBase64: course.flagImageBase64,
  worldFlagId: course.worldFlagId,
  coverImage: coverImage ?? course.coverImage,
  maintainerProfileId: maintainerProfileId ?? course.maintainer!.profileId,
  assignedTeamId: assignedTeamId ?? course.assignedTeamId,
);
