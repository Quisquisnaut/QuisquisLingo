import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';
import 'support/synthetic_mp3.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
final _when = DateTime.utc(2026, 9, 22, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late _PausingCourseFileStore store;
  late _PausingBackupService backups;
  late CourseEditorService service;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_245_storage_race_');
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Race Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
    });
    store = _PausingCourseFileStore(documents);
    backups = _PausingBackupService(documents);
    service = CourseEditorService(
      courseStore: store,
      backupService: backups,
      mediaStore: CourseMediaStore(supportDirectory: () async => documents),
      clock: () => _when,
    );
  });

  tearDown(() async {
    backups.release();
    store.release();
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  test('confirm A cannot delete B created while A backup is paused', () async {
    final a = _course('race-confirm-a', 'Course A');
    final b = _course('race-confirm-b', 'Course B');
    await service.saveUserCourse(a);
    backups.pauseNext();
    final pending = service.confirmCourseTransaction(
      originalCourse: a,
      workingCourse: _withTitle(a, 'Course A edited'),
      languageCode: 'IT',
      versionNotes: 'Edit A',
    );
    await backups.waitUntilPaused();
    await service.saveUserCourse(b);
    backups.release();
    await pending;

    final byId = {
      for (final course in await service.listUserCourses())
        course.courseId: course,
    };
    expect(byId.keys, containsAll([a.courseId, b.courseId]));
    expect(byId[a.courseId]!.title, 'Course A edited');
    expect(byId[b.courseId]!.title, 'Course B');
  });

  test('delete A cannot delete B created after its store snapshot', () async {
    final a = _course('race-delete-a', 'Course A');
    final b = _course('race-delete-b', 'Course B');
    await service.saveUserCourse(a);
    store.pauseNextCustomSnapshot(a.courseId);
    final pending = service.deleteUserCourse(a.courseId);
    await store.waitUntilPaused();
    await service.saveUserCourse(b);
    store.release();
    await pending;

    final byId = {
      for (final course in await service.listUserCourses())
        course.courseId: course,
    };
    expect(byId.keys, contains(b.courseId));
    expect(byId.keys, isNot(contains(a.courseId)));
    expect(byId[b.courseId]!.title, 'Course B');
  });

  test('confirm rejects a same-ID update made after its stale check', () async {
    final original = _course('race-same-id', 'Original');
    await service.saveUserCourse(original);
    backups.pauseNext();
    final pending = service.confirmCourseTransaction(
      originalCourse: original,
      workingCourse: _withTitle(original, 'Stale editor change'),
      languageCode: 'IT',
      versionNotes: 'Stale edit',
    );
    await backups.waitUntilPaused();

    // Simulate an external writer that does not participate in the Editor
    // service's per-Course lock. The record remains well formed. The ordinary
    // CourseFileStore.write path intentionally shares that lock.
    final newer = _withTitle(original, 'Newer writer change');
    final directory = await store.directoryFor(CourseStoreKind.custom);
    final target = File(
      '${directory.path}${Platform.pathSeparator}'
      '${CourseBackupService.sanitizedCourseId(original.courseId)}.json',
    );
    await target.writeAsString(
      jsonEncode({
        'courseId': original.courseId,
        'entry': {'savedAt': _when.toIso8601String(), 'course': newer.toJson()},
      }),
      flush: true,
    );
    backups.release();
    await expectLater(pending, throwsA(isA<StateError>()));

    final stored = (await service.listUserCourses()).single;
    expect(stored.title, 'Newer writer change');
    expect(stored.courseVersion, original.courseVersion);
  });

  test('late replacement error leaves a readable commit and backup', () async {
    final original = _course('race-late-error', 'Original');
    await service.saveUserCourse(original);
    store.throwAfterReplacement = true;

    await expectLater(
      service.confirmCourseTransaction(
        originalCourse: original,
        workingCourse: _withTitle(original, 'Committed before error'),
        languageCode: 'IT',
        versionNotes: 'Late failure',
      ),
      throwsA(isA<StateError>()),
    );

    final stored = (await service.listUserCourses()).single;
    expect(stored.title, 'Committed before error');
    expect(stored.courseVersion, '2');
    final history = await backups.listBackups(original.courseId);
    expect(history, hasLength(1));
    expect(history.single.course.toJson(), original.toJson());
  });

  test(
    'publisher package retains new media after postcommit cleanup error',
    () async {
      final verifier = fixtureVerifier(
        TrustedPublishers.dummy.publisherId,
        TrustedPublishers.dummy.publisherName,
      );
      final media = _FailingCleanupMediaStore(documents);
      final publisherService = CourseEditorService(
        courseStore: store,
        mediaStore: media,
        backupService: CourseBackupService(
          documentsDirectoryProvider: () async => documents,
          publisherVerification: verifier,
          mediaStore: media,
        ),
        publisherVerification: verifier,
        clock: () => _when,
      );
      final first = Course.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
                File(
                  'test/fixtures/publishers/dummy-signed-media.json',
                ).readAsStringSync(),
              )
              as Map,
        ),
      );
      final oldReference = first.audioLibrary.single.filePath;
      final firstPackage = CoursePackage(first, Uint8List(0), {
        oldReference: syntheticMp3(),
      }, mediaStore: media);
      await publisherService.installExternalOfficialUpdate(
        first,
        package: firstPackage,
      );

      final newBytes = syntheticMp3(seed: 7);
      final newReference = CourseMediaStore.referenceFor(newBytes, 'mp3');
      final second = await signFixture(
        Course.fromJson({
          ...first.toJson(),
          'officialCourseVersion': '2',
          'officialReleaseDateUtc': '2026-09-22T12:00:00.000Z',
          'title': 'Publisher update with new audio',
          'audioLibrary': [
            {'id': 'clip', 'text': 'ciao', 'filePath': newReference},
          ],
        }),
      );
      final secondPackage = CoursePackage(second, Uint8List(0), {
        newReference: newBytes,
      }, mediaStore: media);
      media.failCleanup = true;
      await expectLater(
        publisherService.installExternalOfficialUpdate(
          second,
          package: secondPackage,
        ),
        throwsA(isA<StateError>()),
      );

      final stored = await store.snapshot(
        CourseStoreKind.externalOfficial,
        first.courseId,
      );
      final entry = Map<String, dynamic>.from(stored!.entry as Map);
      final persisted = Course.fromJson(
        Map<String, dynamic>.from(entry['source'] as Map),
      );
      expect(persisted.officialCourseVersion, '2');
      expect(persisted.audioLibrary.single.filePath, newReference);
      expect(await media.existingFile(first.courseId, newReference), isNotNull);
    },
  );

  test(
    'partial Copy as New media failure removes destination folder',
    () async {
      final media = _FailAfterCopyMediaStore(documents);
      final copyService = CourseEditorService(
        courseStore: store,
        backupService: backups,
        mediaStore: media,
        clock: () => _when,
      );
      final base = _course('race-partial-copy', 'Source Course');
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final reference = await media.addBytes(base.courseId, bytes, 'png');
      final source = Course.fromJson({
        ...base.toJson(),
        'coverImage': reference,
      });
      await copyService.saveUserCourse(source);

      await expectLater(
        copyService.createCopyAsNewCourse(
          source: source,
          title: 'Independent copy',
        ),
        throwsA(isA<StateError>()),
      );

      final destinationId = media.lastDestinationCourseId;
      expect(destinationId, isNotNull);
      expect(media.copiedBeforeFailure, isTrue);
      expect(
        await media.courseDirectory(destinationId!).then((d) => d.exists()),
        isFalse,
      );
      expect(
        (await copyService.listUserCourses()).map((course) => course.courseId),
        [source.courseId],
      );
      expect(await media.existingFile(source.courseId, reference), isNotNull);
    },
  );

  test(
    'custom package retains media after a postcommit import error',
    () async {
      final media = CourseMediaStore(supportDirectory: () async => documents);
      final importedService = CourseEditorService(
        courseStore: store,
        backupService: backups,
        mediaStore: media,
        clock: () => _when,
      );
      final bytes = Uint8List.fromList([11, 22, 33, 44]);
      final reference = CourseMediaStore.referenceFor(bytes, 'png');
      final base = _course('race-import-postcommit', 'Imported Course');
      final course = Course.fromJson({
        ...base.toJson(),
        'coverImage': reference,
      });
      final package = CoursePackage(course, Uint8List(0), {
        reference: bytes,
      }, mediaStore: media);
      store.throwAfterCreateCourseId = course.courseId;

      await expectLater(
        CoursePackageImport(
          package,
          editor: importedService,
        ).installCustomCourse(),
        throwsA(isA<StateError>()),
      );

      final persisted = (await importedService.listUserCourses()).single;
      expect(persisted.courseId, course.courseId);
      expect(persisted.coverImage, reference);
      expect(await media.existingFile(course.courseId, reference), isNotNull);
    },
  );
}

Course _course(String id, String title) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Race Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: '2026-09-22T09:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      publicationState: PublicationState.draft,
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

Course _withTitle(Course course, String title) =>
    Course.fromJson({...course.toJson(), 'title': title});

class _PausingBackupService extends CourseBackupService {
  _PausingBackupService(Directory documents)
    : super(documentsDirectoryProvider: () async => documents);

  Completer<void>? _entered;
  Completer<void>? _resume;

  void pauseNext() {
    _entered = Completer<void>();
    _resume = Completer<void>();
  }

  Future<void> waitUntilPaused() =>
      _entered!.future.timeout(const Duration(seconds: 10));

  void release() {
    final resume = _resume;
    if (resume != null && !resume.isCompleted) resume.complete();
  }

  @override
  Future<CourseBackupRecord> createBackup(
    Course course, {
    required DateTime backedUpAt,
    required String reason,
  }) async {
    final entered = _entered;
    final resume = _resume;
    if (entered != null && resume != null && !entered.isCompleted) {
      entered.complete();
      await resume.future;
    }
    return super.createBackup(course, backedUpAt: backedUpAt, reason: reason);
  }
}

class _PausingCourseFileStore extends CourseFileStore {
  _PausingCourseFileStore(Directory documents)
    : super(supportDirectory: () async => documents);

  Completer<void>? _entered;
  Completer<void>? _resume;
  String? _pauseCustomCourseId;
  bool throwAfterReplacement = false;
  String? throwAfterCreateCourseId;

  void pauseNextCustomSnapshot(String courseId) {
    _pauseCustomCourseId = courseId;
    _entered = Completer<void>();
    _resume = Completer<void>();
  }

  Future<void> waitUntilPaused() =>
      _entered!.future.timeout(const Duration(seconds: 10));

  void release() {
    final resume = _resume;
    if (resume != null && !resume.isCompleted) resume.complete();
  }

  @override
  Future<CourseStoredRecord?> snapshot(
    CourseStoreKind kind,
    String courseId,
  ) async {
    final record = await super.snapshot(kind, courseId);
    if (kind == CourseStoreKind.custom && courseId == _pauseCustomCourseId) {
      _pauseCustomCourseId = null;
      _entered!.complete();
      await _resume!.future;
    }
    return record;
  }

  @override
  Future<void> replaceIfUnchanged(
    CourseStoreKind kind,
    String courseId,
    Object? entry, {
    required String expectedToken,
  }) async {
    await super.replaceIfUnchanged(
      kind,
      courseId,
      entry,
      expectedToken: expectedToken,
    );
    if (throwAfterReplacement) {
      throw StateError('simulated failure after file replacement');
    }
  }

  @override
  Future<void> createIfAbsent(
    CourseStoreKind kind,
    String courseId,
    Object? entry,
  ) async {
    await super.createIfAbsent(kind, courseId, entry);
    if (kind == CourseStoreKind.custom &&
        courseId == throwAfterCreateCourseId) {
      throw StateError('simulated failure after import file creation');
    }
  }
}

class _FailingCleanupMediaStore extends CourseMediaStore {
  _FailingCleanupMediaStore(Directory documents)
    : super(supportDirectory: () async => documents);

  bool failCleanup = false;

  @override
  Future<int> deleteUnreferenced(String courseId, Set<String> keep) {
    if (failCleanup) throw StateError('simulated postcommit cleanup failure');
    return super.deleteUnreferenced(courseId, keep);
  }
}

class _FailAfterCopyMediaStore extends CourseMediaStore {
  _FailAfterCopyMediaStore(Directory documents)
    : super(supportDirectory: () async => documents);

  String? lastDestinationCourseId;
  bool copiedBeforeFailure = false;

  @override
  Future<Set<String>> copyReferences(
    String fromCourseId,
    String toCourseId,
    Iterable<String> references,
  ) async {
    lastDestinationCourseId = toCourseId;
    final result = await super.copyReferences(
      fromCourseId,
      toCourseId,
      references,
    );
    copiedBeforeFailure =
        await existingFile(toCourseId, references.single) != null;
    if (result.isNotEmpty) {
      throw StateError('source media unexpectedly missing');
    }
    throw StateError('simulated partial media copy failure');
  }
}
