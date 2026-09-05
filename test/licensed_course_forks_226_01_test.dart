import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_editor_transaction.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _otherProfileId = '87654321-4321-4321-8321-cba987654321';
final _forkTime = DateTime.utc(2026, 9, 5, 13, 25);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late CourseBackupService backups;
  late CourseEditorService service;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_forks_22601_');
    backups = CourseBackupService(
      documentsDirectoryProvider: () async => documents,
    );
    service = CourseEditorService(
      backupService: backups,
      clock: () => _forkTime,
    );
    _seedProfiles();
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  test('derivative policy is explicit and absent policy stays unspecified', () {
    final absent = _official().toJson()..remove('derivativeWorksPolicy');
    absent['license'] = 'Free educational content; see publisher for terms';
    expect(
      Course.fromJson(absent).derivativeWorksPolicy,
      DerivativeWorksPolicy.unspecified,
    );
    for (final policy in DerivativeWorksPolicy.values) {
      final course = _official(policy: policy);
      expect(Course.fromJson(course.toJson()).derivativeWorksPolicy, policy);
      expect(course.license, 'Test publisher derivative terms');
    }
    expect(
      () => Course.fromJson({...absent, 'derivativeWorksPolicy': 'probably'}),
      throwsFormatException,
    );
  });

  for (final origin in [
    CourseOriginType.bundledOfficial,
    CourseOriginType.externalOfficial,
  ]) {
    test('${origin.name} allows only an explicitly licensed fork', () async {
      for (final policy in [
        DerivativeWorksPolicy.forbidden,
        DerivativeWorksPolicy.unspecified,
      ]) {
        await expectLater(
          service.forkOfficialCourse(_official(origin: origin, policy: policy)),
          throwsStateError,
        );
      }
      expect(await service.listUserCourses(), isEmpty);

      final official = _official(origin: origin);
      final snapshot = jsonEncode(official.toJson());
      final fork = await service.forkOfficialCourse(official);
      expect(fork.originType, CourseOriginType.custom);
      expect(fork.courseId, isNot(official.courseId));
      expect(fork.courseVersion, isEmpty);
      expect(fork.parentCourseId, official.courseId);
      expect(fork.derivedFromVersion, '3');
      expect(fork.officialCourseVersion, isEmpty);
      expect(fork.publisherId, isEmpty);
      expect(fork.license, official.license);
      expect(
        CourseEditorTransaction(fork, isNewCourse: true).hasChanges,
        isTrue,
      );
      expect(await service.listUserCourses(), isEmpty);
      expect(await backups.listBackups(fork.courseId), isEmpty);
      expect(jsonEncode(official.toJson()), snapshot);
    });
  }

  test(
    'forking needs an active profile and custom duplication stays distinct',
    () async {
      final official = _official();
      expect(official.fork, throwsStateError);
      expect(
        () => AuthoringDuplicationService().duplicateCourse(
          official,
          title: 'Bypass',
        ),
        throwsStateError,
      );
      SharedPreferences.setMockInitialValues({});
      await expectLater(service.forkOfficialCourse(official), throwsStateError);
      expect(await service.listUserCourses(), isEmpty);

      _seedProfiles();
      final fork = await service.forkOfficialCourse(official);
      await expectLater(
        service.forkOfficialCourse(fork),
        throwsFormatException,
      );
      final copy = AuthoringDuplicationService().duplicateCourse(
        fork,
        title: 'Custom duplicate',
      );
      expect(copy.courseId, isNot(fork.courseId));
      expect(copy.originType, CourseOriginType.custom);
      expect(copy.forkProvenance!.toJson(), fork.forkProvenance!.toJson());
      expect(
        fork.fork().forkProvenance!.toJson(),
        fork.forkProvenance!.toJson(),
      );
    },
  );

  test('fork permission cannot bypass official package integrity', () async {
    final forbidden = _official(policy: DerivativeWorksPolicy.forbidden);
    final alteredPolicy = Course.fromJson({
      ...forbidden.toJson(),
      'derivativeWorksPolicy': 'allowed',
    });
    await expectLater(
      service.forkOfficialCourse(alteredPolicy),
      throwsFormatException,
    );
    final alteredTitle = Course.fromJson({
      ..._official().toJson(),
      'title': 'Unverified replacement content',
    });
    await expectLater(
      service.forkOfficialCourse(alteredTitle),
      throwsFormatException,
    );
    expect(await service.listUserCourses(), isEmpty);
  });

  test(
    'fork remaps every owned identity and keeps references within its new content',
    () async {
      final official = _official();
      final first = await service.forkOfficialCourse(official);
      final second = await service.forkOfficialCourse(official);
      final sourceIds = _ownedIds(official);
      final firstIds = _ownedIds(first);
      expect(firstIds.intersection(sourceIds), isEmpty);
      expect(firstIds.intersection(_ownedIds(second)), isEmpty);
      expect(firstIds, hasLength(sourceIds.length));

      final lesson = first.lessons.single;
      final content = lesson.rounds.single.content.single;
      expect(content.sourceRefs.single, lesson.guidebook.content.single.id);
      expect(
        content.exercise!.evaluation.correctItemIds.single,
        content.exercise!.interaction.items.first.id,
      );
      expect(
        content.exercise!.interaction.items.first.content.single.text,
        'Casa',
      );
      expect(official.lessons.single.rounds.single.content.single.sourceRefs, [
        'source-guide',
      ]);
    },
  );

  test('fork detaches nested JSON metadata from its official source', () async {
    final source = _official();
    source
        .lessons
        .single
        .rounds
        .single
        .content
        .single
        .exercise!
        .evaluation
        .normalization['metadata'] = {
      'notes': ['source'],
    };
    final official = Course.fromJson({
      ...source.toJson(),
      'officialChecksum': CourseBackupService.officialContentChecksum(source),
    });
    final before = jsonEncode(official.toJson());
    final fork = await service.forkOfficialCourse(official);
    final metadata =
        fork
                .lessons
                .single
                .rounds
                .single
                .content
                .single
                .exercise!
                .evaluation
                .normalization['metadata']
            as Map;
    (metadata['notes'] as List).add('fork only');
    expect(jsonEncode(official.toJson()), before);
    expect(
      CourseBackupService.officialContentChecksum(official),
      official.officialChecksum,
    );
  });

  test(
    'original authors and publisher are immutable snapshots separate from fork creator',
    () async {
      final roles = ['Author', 'Illustrator'];
      final authors = [CourseAuthor(name: 'Original Author', roles: roles)];
      final official = _official(authors: authors);
      final fork = await service.forkOfficialCourse(official);
      final provenance = fork.forkProvenance!;
      expect(provenance.toJson(), {
        'originalPublisherId': 'test.publisher',
        'originalPublisherName': 'Test Publisher',
        'originalCourseId': 'official-fork-source',
        'originalOfficialCourseVersion': '3',
        'originalOfficialChecksum': official.officialChecksum,
        'originalCourseTitle': 'Official v3',
        'originalAuthor': 'Legacy Original Author',
        'originalAuthors': [
          {
            'name': 'Original Author',
            'role': 'Author, Illustrator',
            'roles': ['Author', 'Illustrator'],
          },
        ],
        'forkCreatedByProfileId': _profileId,
        'forkCreatedByUsername': 'Fork Creator',
        'forkCreatedAtUtc': _forkTime.toIso8601String(),
      });
      expect(fork.author, 'Legacy Original Author');
      expect(fork.authors.single.name, 'Original Author');
      expect(
        fork.authors.any((author) => author.name == 'Fork Creator'),
        isFalse,
      );

      final officialSnapshot = jsonEncode(official.toJson());
      fork.authors.single.roles.add('Editor');
      expect(jsonEncode(official.toJson()), officialSnapshot);
      expect(
        CourseBackupService.officialContentChecksum(official),
        official.officialChecksum,
      );

      official.authors.single.roles.add('Editor');
      official.authors.clear();
      expect(provenance.originalAuthors.single.roles, [
        'Author',
        'Illustrator',
      ]);
      expect(() => provenance.originalAuthors.clear(), throwsUnsupportedError);
      expect(
        () => provenance.originalAuthors.single.roles.clear(),
        throwsUnsupportedError,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        ProfileService.activeProfileIdKey,
        _otherProfileId,
      );
      expect(provenance.forkCreatedByUsername, 'Fork Creator');
    },
  );

  test(
    'fork confirmation, rename and later version authors preserve original provenance',
    () async {
      final official = _official();
      final unconfirmed = await service.forkOfficialCourse(official);
      final provenance = unconfirmed.forkProvenance!.toJson();
      final first = await _confirm(
        service,
        unconfirmed,
        title: 'My study course',
        isNewCourse: true,
      );
      expect(first.course.courseVersion, '1');
      expect(first.backupPath, isNull);
      expect(first.course.createdByUsername, 'Fork Creator');

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        ProfileService.activeProfileIdKey,
        _otherProfileId,
      );
      final second = await _confirm(
        service,
        first.course,
        title: 'Renamed again',
      );
      expect(second.course.courseVersion, '2');
      expect(second.course.createdByUsername, 'Fork Creator');
      expect(second.course.lastModifiedByUsername, 'Later Contributor');
      expect(second.course.forkProvenance!.toJson(), provenance);
      expect(second.course.authors.map((author) => author.name), [
        'Original Author',
        'Original Reviewer',
      ]);

      final history = await backups.listBackups(second.course.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.courseVersion, '1');
      expect(history.single.course.forkProvenance!.toJson(), provenance);
      expect(await backups.listBackups(official.courseId), isEmpty);
    },
  );

  test(
    'export import and storage restart preserve the complete permanent fork record',
    () async {
      final unconfirmed = await service.forkOfficialCourse(_official());
      final confirmed = await _confirm(
        service,
        unconfirmed,
        title: 'Portable fork',
        isNewCourse: true,
      );
      final exported = await service.exportUserCourse(confirmed.course);
      final imported = Course.fromJson(
        Map<String, dynamic>.from(jsonDecode(exported) as Map),
      );
      expect(imported.toJson(), confirmed.course.toJson());

      _seedProfiles();
      await service.saveUserCourse(imported);
      final restarted = CourseEditorService(
        backupService: backups,
        clock: () => _forkTime,
      );
      final stored = (await restarted.listUserCourses()).single;
      expect(stored.toJson(), confirmed.course.toJson());
      expect(stored.courseId, confirmed.course.courseId);
      expect(stored.forkProvenance!.originalCourseId, 'official-fork-source');
    },
  );

  test(
    'confirmation and direct import cannot erase or replace saved fork provenance',
    () async {
      final unconfirmed = await service.forkOfficialCourse(_official());
      final saved = (await _confirm(
        service,
        unconfirmed,
        title: 'Protected fork',
        isNewCourse: true,
      )).course;
      final stripped = saved.toJson()..remove('forkProvenance');
      final rewritten = {
        ...saved.toJson(),
        'forkProvenance': {
          ...saved.forkProvenance!.toJson(),
          'originalCourseTitle': 'False attribution',
        },
      };
      for (final attempted in [stripped, rewritten]) {
        final altered = Course.fromJson(attempted);
        await expectLater(
          service.saveUserCourse(altered),
          throwsFormatException,
        );
        await expectLater(
          service.confirmCourseTransaction(
            originalCourse: saved,
            workingCourse: altered,
            languageCode: 'IT',
            versionNotes: 'must not erase attribution',
          ),
          throwsFormatException,
        );
        expect(
          (await service.listUserCourses()).single.toJson(),
          saved.toJson(),
        );
      }
      expect(await backups.listBackups(saved.courseId), isEmpty);
    },
  );

  test(
    'historical restore keeps original provenance and advances only custom history',
    () async {
      final unconfirmed = await service.forkOfficialCourse(_official());
      final first = (await _confirm(
        service,
        unconfirmed,
        title: 'Version one',
        isNewCourse: true,
      )).course;
      final second = (await _confirm(
        service,
        first,
        title: 'Version two',
      )).course;
      final record = (await backups.listBackups(first.courseId)).single;
      final verified = await backups.loadBackup(
        record.manifestFile,
        expectedCourseId: first.courseId,
      );
      final transaction = CourseEditorTransaction(second);
      transaction.loadHistoricalCourse(verified.course);
      expect(transaction.workingCourse.title, 'Version one');
      expect(transaction.workingCourse.courseVersion, '2');
      expect(transaction.workingCourse.restoredFromVersion, 1);
      expect(
        transaction.workingCourse.forkProvenance!.toJson(),
        first.forkProvenance!.toJson(),
      );

      final result = await service.confirmCourseTransaction(
        originalCourse: second,
        workingCourse: transaction.workingCourse,
        languageCode: 'IT',
        versionNotes: 'Restore earlier content',
      );
      expect(result.course.courseVersion, '3');
      expect(
        result.course.forkProvenance!.toJson(),
        first.forkProvenance!.toJson(),
      );
      expect(await backups.listBackups(first.courseId), hasLength(2));

      final strippedHistorical = first.toJson()..remove('forkProvenance');
      final restore = CourseEditorTransaction(result.course);
      restore.loadHistoricalCourse(Course.fromJson(strippedHistorical));
      expect(
        restore.workingCourse.forkProvenance!.toJson(),
        first.forkProvenance!.toJson(),
      );
    },
  );

  test(
    'publisher v4 replaces only official source while the v3 custom fork remains byte-identical',
    () async {
      final installed = await service.installExternalOfficialUpdate(
        _official(),
      );
      final unconfirmed = await service.forkOfficialCourse(
        installed.officialCourse,
      );
      final fork = (await _confirm(
        service,
        unconfirmed,
        title: 'Independent custom fork',
        isNewCourse: true,
      )).course;
      final forkSnapshot = jsonEncode(fork.toJson());
      final preferences = await SharedPreferences.getInstance();
      final customStorage = preferences.getString(
        CourseEditorService.userCoursesStorageKey,
      );

      final updated = await service.installExternalOfficialUpdate(
        _official(version: '4'),
      );
      expect(updated.officialCourse.officialCourseVersion, '4');
      expect(
        updated.officialCourse.publisherVerificationStatus,
        PublisherVerificationStatus.unverified,
      );
      expect(updated.backupPath, isNotNull);
      expect(
        preferences.getString(CourseEditorService.userCoursesStorageKey),
        customStorage,
      );
      final courses = await CourseEditorService(
        backupService: backups,
      ).listUserCourses();
      final storedFork = courses.singleWhere(
        (course) => course.courseId == fork.courseId,
      );
      expect(jsonEncode(storedFork.toJson()), forkSnapshot);
      expect(storedFork.forkProvenance!.originalOfficialCourseVersion, '3');
      expect(
        storedFork.forkProvenance!.originalOfficialChecksum,
        installed.officialCourse.officialChecksum,
      );
      expect(
        courses
            .singleWhere((course) => course.courseId == 'official-fork-source')
            .title,
        'Official v4',
      );
      expect(await backups.listBackups(fork.courseId), isEmpty);
      final officialHistory = await backups.listBackups('official-fork-source');
      expect(
        officialHistory.single.course.toJson(),
        installed.officialCourse.toJson(),
      );
    },
  );

  test(
    'official updates reject checksum, same or older version, publisher and custom identity collisions',
    () async {
      final installed = await service.installExternalOfficialUpdate(
        _official(),
      );
      final invalidChecksum = Course.fromJson({
        ..._official(version: '4').toJson(),
        'title': 'Tampered',
      });
      for (final update in [
        invalidChecksum,
        _official(version: '3'),
        _official(version: '2'),
        _official(version: '4', publisherId: 'other.publisher'),
      ]) {
        await expectLater(
          service.installExternalOfficialUpdate(update),
          throwsFormatException,
        );
        expect(
          (await service.listUserCourses()).single.toJson(),
          installed.officialCourse.toJson(),
        );
        expect(await backups.listBackups('official-fork-source'), isEmpty);
      }

      final unconfirmed = await service.forkOfficialCourse(
        installed.officialCourse,
      );
      final custom = (await _confirm(
        service,
        unconfirmed,
        title: 'Custom identity',
        isNewCourse: true,
      )).course;
      await expectLater(
        service.installExternalOfficialUpdate(
          _official(courseId: custom.courseId, version: '4'),
        ),
        throwsFormatException,
      );
      await expectLater(
        service.installExternalOfficialUpdate(
          _official(courseId: 'sample_it_en_it', version: '4'),
        ),
        throwsFormatException,
      );
      expect(
        (await service.listUserCourses())
            .singleWhere((course) => course.courseId == custom.courseId)
            .toJson(),
        custom.toJson(),
      );
    },
  );
}

void _seedProfiles() => SharedPreferences.setMockInitialValues({
  ProfileService.profilesKey: [
    const LearnerProfile(
      learnerProfileId: _profileId,
      displayName: 'Fork Creator',
    ).encode(),
    const LearnerProfile(
      learnerProfileId: _otherProfileId,
      displayName: 'Later Contributor',
    ).encode(),
  ],
  ProfileService.activeProfileIdKey: _profileId,
});

Future<CourseConfirmationResult> _confirm(
  CourseEditorService service,
  Course original, {
  required String title,
  bool isNewCourse = false,
}) => service.confirmCourseTransaction(
  originalCourse: original,
  workingCourse: Course.fromJson({...original.toJson(), 'title': title}),
  languageCode: 'IT',
  versionNotes: 'Focused fork regression',
  isNewCourse: isNewCourse,
);

Course _official({
  CourseOriginType origin = CourseOriginType.externalOfficial,
  DerivativeWorksPolicy policy = DerivativeWorksPolicy.allowed,
  String courseId = 'official-fork-source',
  String publisherId = 'test.publisher',
  String version = '3',
  List<CourseAuthor> authors = const [
    CourseAuthor(name: 'Original Author', roles: ['Author', 'Illustrator']),
    CourseAuthor(name: 'Original Reviewer', roles: ['Reviewer']),
  ],
}) {
  final provisional = Course(
    courseId: courseId,
    originType: origin,
    publisherId: publisherId,
    publisherName: 'Test Publisher',
    officialCourseVersion: version,
    officialReleaseDateUtc: '2026-09-04T10:00:00.000Z',
    officialChecksum: List.filled(64, '0').join(),
    distributionChannel: origin == CourseOriginType.bundledOfficial
        ? 'bundled'
        : 'file-import',
    publisherVerificationStatus: PublisherVerificationStatus.verified,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Official v$version',
    ttsLanguage: 'it-IT',
    version: version,
    author: 'Legacy Original Author',
    authors: authors,
    license: 'Test publisher derivative terms',
    derivativeWorksPolicy: policy,
    lessons: [
      Lesson(
        lessonId: 'source-lesson',
        title: 'Original lesson',
        updatedAt: DateTime.utc(2026, 9, 4, 10),
        guidebook: Guidebook(
          content: const [
            LearningContent(
              id: 'source-guide',
              kind: 'vocabulary',
              role: 'vocabulary',
              text: 'casa = house',
            ),
          ],
        ),
        duel: Duel(id: 'source-duel', title: 'Duel'),
        rounds: [
          LearningRound(
            id: 'source-round',
            title: 'Original round',
            updatedAt: DateTime.utc(2026, 9, 4, 10),
            content: [
              LearningContent(
                id: 'source-content',
                kind: 'exercise',
                editorTemplate: 'choice',
                sourceRefs: const ['source-guide'],
                exercise: Exercise.v2(
                  id: 'source-exercise',
                  updatedAt: DateTime.utc(2026, 9, 4, 10),
                  editorTemplate: 'choice',
                  promptElements: const [
                    PromptElement(type: 'text', text: 'Choose house'),
                  ],
                  interaction: const ExerciseInteraction(
                    kind: 'select',
                    items: [
                      ExerciseItem(
                        id: 'source-answer-a',
                        content: [PromptElement(type: 'text', text: 'Casa')],
                      ),
                      ExerciseItem(
                        id: 'source-answer-b',
                        content: [PromptElement(type: 'text', text: 'Cane')],
                      ),
                    ],
                  ),
                  evaluation: const ExerciseEvaluation(
                    kind: 'selected_items',
                    correctItemIds: ['source-answer-a'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return Course.fromJson({
    ...provisional.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(
      provisional,
    ),
  });
}

Set<String> _ownedIds(Course course) => {
  course.courseId,
  for (final lesson in course.lessons) ...{
    lesson.lessonId,
    lesson.duel.id,
    for (final content in lesson.guidebook.content) content.id,
    for (final round in lesson.rounds) ...{
      round.id,
      for (final content in round.content) ...{
        content.id,
        if (content.exercise != null) ...{
          content.exercise!.id,
          for (final item in content.exercise!.interaction.items) item.id,
        },
      },
    },
  },
};
