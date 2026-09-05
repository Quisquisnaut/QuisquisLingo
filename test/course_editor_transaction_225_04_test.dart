import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_editor_transaction.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
final _when = DateTime.utc(2026, 9, 4, 14, 35);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late CourseBackupService backups;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_22504_');
    backups = CourseBackupService(
      documentsDirectoryProvider: () async => documents,
    );
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Author Ω',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
    });
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  test('working copy is independent and restored values become clean', () {
    final original = _customCourse(title: 'Original', version: '4');
    final transaction = CourseEditorTransaction(original);
    transaction.replaceWorkingCourse(
      Course.fromJson({
        ...transaction.workingCourse.toJson(),
        'title': 'Changed',
        'lessons': [
          {
            ...original.lessons.single.toJson(),
            'updatedAt': '2026-09-04T15:00:00.000Z',
          },
        ],
      }),
    );
    expect(transaction.hasChanges, isTrue);
    expect(transaction.originalCourse.title, 'Original');

    transaction.replaceWorkingCourse(
      Course.fromJson({
        ...original.toJson(),
        'lessons': [
          {
            ...original.lessons.single.toJson(),
            'updatedAt': '2026-09-04T16:00:00.000Z',
          },
        ],
      }),
    );
    expect(transaction.hasChanges, isFalse);
  });

  test(
    'new custom confirmation creates version 1 without fictitious backup',
    () async {
      final source = _customCourse(title: 'New', version: '');
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      final result = await service.confirmCourseTransaction(
        originalCourse: source,
        workingCourse: Course.fromJson({
          ...source.toJson(),
          'title': 'New saved',
        }),
        languageCode: 'ZZ',
        versionNotes: '  First line\nSecond line  ',
        isNewCourse: true,
      );

      expect(result.course.courseVersion, '1');
      expect(result.course.createdByProfileId, _profileId);
      expect(result.course.createdByUsername, 'Author Ω');
      expect(result.course.createdAtUtc, _when.toIso8601String());
      expect(result.course.lastModifiedByUsername, 'Author Ω');
      expect(result.course.versionNotes, 'First line\nSecond line');
      expect(result.backupPath, isNull);
      expect(await backups.listBackups(source.courseId), isEmpty);
      expect((await service.listUserCourses()).single.title, 'New saved');
    },
  );

  test('confirmation is blocked without an active local QQL profile', () async {
    SharedPreferences.setMockInitialValues({});
    final blocked = CourseEditorService(
      backupService: backups,
      clock: () => _when,
    );
    final original = _customCourse(title: 'Unsaved', version: '');
    final working = Course.fromJson({
      ...original.toJson(),
      'title': 'Still in the working copy',
    });
    await expectLater(
      blocked.confirmCourseTransaction(
        originalCourse: original,
        workingCourse: working,
        languageCode: 'IT',
        versionNotes: 'blocked',
        isNewCourse: true,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await blocked.listUserCourses(), isEmpty);
    expect(await backups.listBackups(original.courseId), isEmpty);
  });

  test(
    'existing custom confirmation backs up, verifies and increments once',
    () async {
      final source = _customCourse(title: 'Version one', version: '1');
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      await service.saveUserCourse(source);

      final result = await service.confirmCourseTransaction(
        originalCourse: source,
        workingCourse: Course.fromJson({
          ...source.toJson(),
          'title': 'Version two',
        }),
        languageCode: 'ZZ',
        versionNotes: 'Second version',
      );

      expect(result.course.courseVersion, '2');
      expect(result.course.title, 'Version two');
      expect(result.backupPath, isNotNull);
      expect(
        result.backupPath,
        contains(
          '${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Exports'
          '${Platform.pathSeparator}Course Backups${Platform.pathSeparator}'
          '${source.courseId}${Platform.pathSeparator}',
        ),
      );
      final history = await backups.listBackups(source.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.title, 'Version one');
      expect(history.single.course.courseVersion, '1');
      expect(
        history.single.checksum,
        CourseBackupService.courseChecksum(source),
      );
    },
  );

  test(
    'backup filenames are collision-safe and course folders are isolated',
    () async {
      final first = _customCourse(title: 'First', version: '2');
      final second = _customCourse(
        title: 'Second',
        version: '3',
        courseId: 'another-course',
      );
      final a = await backups.createBackup(
        first,
        backedUpAt: _when,
        reason: 'test',
      );
      final b = await backups.createBackup(
        first,
        backedUpAt: _when,
        reason: 'test',
      );
      final c = await backups.createBackup(
        second,
        backedUpAt: _when,
        reason: 'test',
      );
      expect(a.manifestFile.path, isNot(b.manifestFile.path));
      expect(a.manifestFile.parent.path, b.manifestFile.parent.path);
      expect(c.manifestFile.parent.path, isNot(a.manifestFile.parent.path));
      final sanitizedTraversal = CourseBackupService.sanitizedCourseId('../..');
      expect(sanitizedTraversal, isNot(contains('..')));
      expect(sanitizedTraversal, isNot(contains('/')));
      expect(sanitizedTraversal, isNot(contains(r'\')));
    },
  );

  test('backup copies and verifies course-owned audio assets', () async {
    final audio = File('${documents.path}${Platform.pathSeparator}voice.ogg');
    await audio.writeAsBytes(const [1, 2, 3, 4], flush: true);
    final source = Course.fromJson({
      ..._customCourse(title: 'Audio', version: '4').toJson(),
      'audioLibrary': [
        {'id': 'voice', 'text': 'Ciao', 'filePath': audio.path},
      ],
    });
    final record = await backups.createBackup(
      source,
      backedUpAt: _when,
      reason: 'asset integrity',
    );
    expect(record.assets, hasLength(1));
    final relative = record.assets.single['backupRelativePath']!;
    final asset = File(
      '${record.manifestFile.parent.path}${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}',
    );
    expect(await asset.readAsBytes(), const [1, 2, 3, 4]);
    await asset.writeAsBytes(const [9], flush: true);
    await expectLater(
      backups.loadBackup(
        record.manifestFile,
        expectedCourseId: source.courseId,
      ),
      throwsFormatException,
    );
  });

  test(
    'missing course-owned audio blocks the backup and transaction',
    () async {
      final source = Course.fromJson({
        ..._customCourse(title: 'Missing audio', version: '2').toJson(),
        'audioLibrary': [
          {
            'id': 'missing-voice',
            'text': 'Ciao',
            'filePath': '${documents.path}${Platform.pathSeparator}missing.ogg',
          },
        ],
      });
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      await service.saveUserCourse(source);

      await expectLater(
        service.confirmCourseTransaction(
          originalCourse: source,
          workingCourse: Course.fromJson({
            ...source.toJson(),
            'title': 'Must not persist',
          }),
          languageCode: 'ZZ',
          versionNotes: 'blocked with the working copy',
        ),
        throwsA(isA<StateError>()),
      );
      expect((await service.listUserCourses()).single.title, 'Missing audio');
    },
  );

  test('corrupt, missing and wrong-course backups are rejected', () async {
    final source = _customCourse(title: 'Source', version: '2');
    final record = await backups.createBackup(
      source,
      backedUpAt: _when,
      reason: 'test',
    );
    expect(
      () => backups.loadBackup(
        record.manifestFile,
        expectedCourseId: 'wrong-course',
      ),
      throwsA(isA<FormatException>()),
    );
    final decoded = jsonDecode(await record.manifestFile.readAsString()) as Map;
    decoded['courseChecksumSha256'] = List.filled(64, '0').join();
    await record.manifestFile.writeAsString(jsonEncode(decoded), flush: true);
    expect(
      () => backups.loadBackup(
        record.manifestFile,
        expectedCourseId: source.courseId,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => backups.loadBackup(
        File('${record.manifestFile.path}.missing'),
        expectedCourseId: source.courseId,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'backup failure and persistence failure leave original live course unchanged',
    () async {
      final source = _customCourse(title: 'Original', version: '1');
      final seed = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      await seed.saveUserCourse(source);

      final failingBackup = CourseEditorService(
        backupService: CourseBackupService(
          documentsDirectoryProvider: () async => documents,
          fileWriter: (_, _) async => throw FileSystemException('disk full'),
        ),
        clock: () => _when,
      );
      await expectLater(
        failingBackup.confirmCourseTransaction(
          originalCourse: source,
          workingCourse: Course.fromJson({
            ...source.toJson(),
            'title': 'No backup',
          }),
          languageCode: 'ZZ',
          versionNotes: 'kept by UI',
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect((await seed.listUserCourses()).single.title, 'Original');

      final failingPersistence = CourseEditorService(
        backupService: backups,
        preferenceWriter: (_, key, _) async =>
            key != CourseEditorService.userCoursesStorageKey,
        clock: () => _when,
      );
      await expectLater(
        failingPersistence.confirmCourseTransaction(
          originalCourse: source,
          workingCourse: Course.fromJson({
            ...source.toJson(),
            'title': 'No write',
          }),
          languageCode: 'ZZ',
          versionNotes: 'kept by UI',
        ),
        throwsA(isA<StateError>()),
      );
      expect((await seed.listUserCourses()).single.title, 'Original');
      expect(await backups.listBackups(source.courseId), isNotEmpty);
    },
  );

  test(
    'official local versions remain separate from publisher version',
    () async {
      final official = _officialCourse(
        origin: CourseOriginType.bundledOfficial,
        officialVersion: '3',
      );
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      final first = await service.confirmCourseTransaction(
        originalCourse: official,
        workingCourse: Course.fromJson({
          ...official.toJson(),
          'title': 'Local title',
        }),
        languageCode: 'IT',
        versionNotes: 'Local notes',
      );
      expect(first.course.officialCourseVersion, '3');
      expect(first.course.localCourseVersion, 1);
      expect(first.course.baseOfficialCourseVersion, '3');
      expect(first.course.baseOfficialChecksum, official.officialChecksum);
      expect(first.course.localAuthorUsername, 'Author Ω');
      expect(first.course.localVersionNotes, 'Local notes');

      final second = await service.confirmCourseTransaction(
        originalCourse: first.course,
        workingCourse: Course.fromJson({
          ...first.course.toJson(),
          'title': 'Local title 2',
        }),
        languageCode: 'IT',
        versionNotes: '',
      );
      expect(second.course.officialCourseVersion, '3');
      expect(second.course.localCourseVersion, 2);
    },
  );

  test('legacy custom version advances monotonically as an integer', () async {
    final source = _customCourse(title: 'Legacy version', version: '7.4.2');
    final service = CourseEditorService(
      backupService: backups,
      clock: () => _when,
    );
    await service.saveUserCourse(source);
    final result = await service.confirmCourseTransaction(
      originalCourse: source,
      workingCourse: Course.fromJson({
        ...source.toJson(),
        'title': 'Next integer version',
      }),
      languageCode: 'ZZ',
      versionNotes: '',
    );
    expect(result.course.courseVersion, '8');
  });

  test(
    'external official update archives local state and refuses publisher collision',
    () async {
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      final v3 = _officialCourse(
        origin: CourseOriginType.externalOfficial,
        officialVersion: '3',
      );
      final installed = await service.installExternalOfficialUpdate(v3);
      expect(
        installed.officialCourse.publisherVerificationStatus,
        PublisherVerificationStatus.unverified,
      );
      final local = await service.confirmCourseTransaction(
        originalCourse: installed.officialCourse,
        workingCourse: Course.fromJson({
          ...installed.officialCourse.toJson(),
          'title': 'Local v3',
        }),
        languageCode: 'IT',
        versionNotes: 'Work on v3',
      );
      expect(local.course.localCourseVersion, 1);

      final v4 = _officialCourse(
        origin: CourseOriginType.externalOfficial,
        officialVersion: '4',
        title: 'Official v4',
      );
      final updated = await service.installExternalOfficialUpdate(v4);
      expect(updated.archivedLocalChanges, isTrue);
      expect(updated.backupPath, isNotNull);
      final active = (await service.listUserCourses()).single;
      expect(active.title, 'Official v4');
      expect(active.officialCourseVersion, '4');
      expect(active.localCourseVersion, 0);

      final attacker = _officialCourse(
        origin: CourseOriginType.externalOfficial,
        officialVersion: '5',
        publisherId: 'different.publisher',
      );
      await expectLater(
        service.installExternalOfficialUpdate(attacker),
        throwsA(isA<FormatException>()),
      );
      expect(
        (await service.listUserCourses()).single.officialCourseVersion,
        '4',
      );
    },
  );

  test(
    'bundled official update archives the exact active course and does not merge',
    () async {
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      final v3 = _officialCourse(
        origin: CourseOriginType.bundledOfficial,
        officialVersion: '3',
      );
      final localV3 = Course.fromJson({
        ...v3.toJson(),
        'title': 'Local changes on v3',
        'baseCourseId': v3.courseId,
        'basePublisherId': v3.publisherId,
        'baseOfficialCourseVersion': v3.officialCourseVersion,
        'baseOfficialChecksum': v3.officialChecksum,
        'localCourseVersion': 4,
      });
      await service.saveCourse(languageCode: 'IT', course: localV3);
      final v4 = _officialCourse(
        origin: CourseOriginType.bundledOfficial,
        officialVersion: '4',
        title: 'Exact official v4',
      );

      final loaded = Course.fromJson(
        await service.applyToCourse('IT', v4.toJson()),
      );
      expect(loaded.title, 'Exact official v4');
      expect(loaded.officialCourseVersion, '4');
      expect(loaded.localCourseVersion, 0);
      final history = await backups.listBackups(v3.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.title, 'Local changes on v3');
      final notice = await service.consumeOfficialUpdateNotice(v3.courseId);
      expect(notice?['officialCourseVersion'], '4');
      expect(notice?['backupPath'], history.single.manifestFile.path);
      expect(await service.consumeOfficialUpdateNotice(v3.courseId), isNull);
    },
  );

  test(
    'origin collisions require a genuinely separate custom identity',
    () async {
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      final official = _officialCourse(
        origin: CourseOriginType.externalOfficial,
        officialVersion: '1',
      );
      await service.installExternalOfficialUpdate(official);
      final collidingCustom = _customCourse(
        title: 'Collision',
        version: '1',
        courseId: official.courseId,
      );
      await expectLater(
        service.saveUserCourse(collidingCustom),
        throwsA(isA<FormatException>()),
      );

      final separate = collidingCustom.fork();
      expect(separate.originType, CourseOriginType.custom);
      expect(separate.courseId, isNot(official.courseId));
      expect(separate.parentCourseId, official.courseId);
      expect(separate.publisherId, isEmpty);
      await service.saveUserCourse(separate);
      expect(await service.listUserCourses(), hasLength(2));
    },
  );

  test(
    'restore is monotonic and rejects a historical official base mismatch',
    () {
      final current = _customCourse(title: 'Current', version: '6');
      final historical = _customCourse(title: 'Historical', version: '3');
      final transaction = CourseEditorTransaction(current);
      transaction.loadHistoricalCourse(historical);
      expect(transaction.workingCourse.title, 'Historical');
      expect(transaction.workingCourse.courseVersion, '6');
      expect(transaction.workingCourse.restoredFromVersion, 3);

      final official3 = _officialCourse(
        origin: CourseOriginType.bundledOfficial,
        officialVersion: '3',
      );
      final official4 = _officialCourse(
        origin: CourseOriginType.bundledOfficial,
        officialVersion: '4',
      );
      expect(
        () =>
            CourseEditorTransaction(official4).loadHistoricalCourse(official3),
        throwsFormatException,
      );
    },
  );
}

Course _customCourse({
  required String title,
  required String version,
  String courseId = 'custom-transaction-course',
}) => Course(
  courseId: courseId,
  originType: CourseOriginType.custom,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: version,
  lessons: [_lesson()],
);

Course _officialCourse({
  required CourseOriginType origin,
  required String officialVersion,
  String title = 'Official course',
  String publisherId = 'team.example',
}) {
  final provisional = Course(
    courseId: 'official-course',
    originType: origin,
    publisherId: publisherId,
    publisherName: 'Team Example',
    officialCourseVersion: officialVersion,
    officialReleaseDateUtc: '2026-09-04T12:00:00.000Z',
    officialChecksum: List.filled(64, '0').join(),
    officialReleaseNotes: 'Publisher notes',
    distributionChannel: origin == CourseOriginType.bundledOfficial
        ? 'bundled'
        : 'file-import',
    publisherVerificationStatus: PublisherVerificationStatus.verified,
    publicationState: PublicationState.published,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: title,
    ttsLanguage: 'it-IT',
    version: officialVersion,
    lessons: [_lesson()],
  );
  return Course.fromJson({
    ...provisional.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(
      provisional,
    ),
  });
}

Lesson _lesson() => Lesson(
  lessonId: 'lesson',
  publicationState: PublicationState.draft,
  updatedAt: DateTime.utc(2026, 9, 4, 10),
  title: 'Lesson',
  rounds: [
    LearningRound(
      id: 'round',
      publicationState: PublicationState.draft,
      updatedAt: DateTime.utc(2026, 9, 4, 10),
      title: 'Round',
      exercises: [
        Exercise(
          id: 'exercise',
          publicationState: PublicationState.draft,
          updatedAt: DateTime.utc(2026, 9, 4, 10),
          type: 'choice',
          prompt: 'Prompt',
          question: 'Question',
          answers: const ['One', 'Two'],
          correct: 0,
          tts: null,
          accepted: const [],
          tokens: const [],
          orderAnswer: const [],
          pairs: const [],
          hint: '',
          icons: const [],
        ),
      ],
    ),
  ],
);
