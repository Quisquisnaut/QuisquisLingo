import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late CourseBackupService backups;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_v9_backups_');
    backups = CourseBackupService(
      documentsDirectoryProvider: () async => documents,
    );
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  test('v9 history ignores and preserves the former backup directory', () async {
    final legacyDirectory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo'
      '${Platform.pathSeparator}Exports${Platform.pathSeparator}Course Backups'
      '${Platform.pathSeparator}backup-clean-cut',
    );
    await legacyDirectory.create(recursive: true);
    final legacyManifest = File(
      '${legacyDirectory.path}${Platform.pathSeparator}legacy-v8.json',
    );
    const legacyBytes = 'opaque Course Model v8 backup bytes';
    await legacyManifest.writeAsString(legacyBytes, flush: true);

    expect(await backups.listBackups('backup-clean-cut'), isEmpty);
    expect(await legacyManifest.readAsString(), legacyBytes);
    expect(
      (await backups.backupRoot()).path,
      endsWith(
        '${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Exports'
        '${Platform.pathSeparator}Course Backups v9',
      ),
    );

    await expectLater(
      backups.loadBackup(legacyManifest, expectedCourseId: 'backup-clean-cut'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Unsafe Course Backup manifest path'),
        ),
      ),
    );
    expect(await legacyManifest.readAsString(), legacyBytes);
  });

  test(
    'v9 backup format reads canonical course data without duplicate metadata',
    () async {
      final course = _course();
      final record = await backups.createBackup(
        course,
        backedUpAt: DateTime.utc(2026, 9, 12, 12),
        reason: 'Course Model v9 clean cut',
      );

      final manifest =
          jsonDecode(await record.manifestFile.readAsString()) as Map;
      expect(manifest['format'], 'QuisquisLingo Course Backup v9');
      expect(manifest, isNot(contains('authorProfileId')));
      expect(manifest, isNot(contains('authorUsername')));
      expect(manifest, isNot(contains('versionCreatedAtUtc')));
      expect((manifest['course'] as Map)['formatVersion'], 9);

      final history = await backups.listBackups(course.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.toJson(), course.toJson());
    },
  );

  test(
    'v9 history does not recognize obsolete local-variant manifests',
    () async {
      final directory = await backups.courseBackupDirectory(
        'obsolete-local-variant',
        create: true,
      );
      final manifest = File(
        '${directory.path}${Platform.pathSeparator}obsolete.json',
      );
      const raw =
          '{"course":{"localCourseVersion":99,"title":"Old local content"}}';
      await manifest.writeAsString(raw, flush: true);

      await expectLater(
        backups.listOfficialBackups('obsolete-local-variant'),
        throwsFormatException,
      );
      expect(await manifest.readAsString(), raw);
    },
  );
}

Course _course() => Course(
  courseId: 'backup-clean-cut',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: '2026-09-01T09:00:00.000Z',
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Last Editor',
  modifiedAtUtc: '2026-09-12T11:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Backup clean cut',
  ttsLanguage: 'it-IT',
  courseVersion: '4',
  lessons: const [],
);
