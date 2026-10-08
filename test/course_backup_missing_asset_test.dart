import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _courseId = 'backup-missing-asset';

/// A referenced recording can disappear from disk: the admin reset removes
/// imported media, or a file is deleted outside QQL. The pre-change backup
/// reads the *persisted* Course, so refusing to back up a course with a
/// missing file made every later save fail — including the edit that would
/// have removed the broken reference. The backup records the gap instead.
///
/// Build 243: recordings are course media (`media:<sha256>.mp3`), so a backup
/// copies them by content and a restore puts them back in the Course folder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late Directory support;
  late CourseMediaStore media;
  late CourseBackupService backups;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_backup_missing_');
    support = await Directory.systemTemp.createTemp('qql_backup_media_');
    media = CourseMediaStore(supportDirectory: () async => support);
    backups = CourseBackupService(
      backupsDirectoryProvider: () async => documents,
      mediaStore: media,
    );
  });

  tearDown(() async {
    for (final directory in [documents, support]) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  });

  Future<String> stored(List<int> bytes) =>
      media.addBytes(_courseId, Uint8List.fromList(bytes), 'mp3');

  final absent = CourseMediaStore.referenceFor(const [9, 9, 9], 'mp3');

  test(
    'a backup succeeds and records the gap when a clip file is gone',
    () async {
      final present = await stored(const [1, 2, 3]);

      final record = await backups.createBackup(
        _course([
          CourseAudioClip(id: 'a', text: 'uno', filePath: present),
          CourseAudioClip(id: 'b', text: 'due', filePath: absent),
        ]),
        backedUpAt: DateTime.utc(2026, 9, 20, 10),
        reason: 'Pre-change Course Editor transaction backup',
      );

      expect(record.assets, hasLength(2));
      final gap = record.assets.singleWhere((a) => a['missing'] == 'true');
      expect(gap['reference'], absent);
      expect(gap.containsKey('backupRelativePath'), isFalse);
      expect(gap.containsKey('sha256'), isFalse);

      final copied = record.assets.singleWhere((a) => a['missing'] != 'true');
      expect(copied['reference'], present);
      expect(copied['sha256'], CourseMediaStore.digestOf(present));
      expect(
        File(
          '${record.manifestFile.parent.path}${Platform.pathSeparator}'
          '${copied['backupRelativePath']!.replaceAll('/', Platform.pathSeparator)}',
        ).existsSync(),
        isTrue,
      );
    },
  );

  test('restore puts the copied clip back and leaves the gap alone', () async {
    final present = await stored(const [4, 5, 6]);
    final created = await backups.createBackup(
      _course([
        CourseAudioClip(id: 'a', text: 'uno', filePath: present),
        CourseAudioClip(id: 'b', text: 'due', filePath: absent),
      ]),
      backedUpAt: DateTime.utc(2026, 9, 20, 11),
      reason: 'Pre-change Course Editor transaction backup',
    );
    // A later confirmed change removed the clip from the Course folder.
    await media.deleteUnreferenced(_courseId, const {});
    expect(await media.existingFile(_courseId, present), isNull);

    final loaded = await backups.loadBackup(
      created.manifestFile,
      expectedCourseId: _courseId,
    );
    final clips = {
      for (final clip in loaded.course.audioLibrary) clip.id: clip.filePath,
    };
    expect(clips['a'], present, reason: 'references need no remapping');
    expect(clips['b'], absent);

    await backups.reinstateMedia(loaded);
    final restored = await media.existingFile(_courseId, present);
    expect(await restored!.readAsBytes(), const [4, 5, 6]);
    expect(await media.existingFile(_courseId, absent), isNull);
  });

  test('an asset that claims a file is still validated strictly', () async {
    final present = await stored(const [7, 8, 9]);
    final created = await backups.createBackup(
      _course([CourseAudioClip(id: 'a', text: 'uno', filePath: present)]),
      backedUpAt: DateTime.utc(2026, 9, 20, 12),
      reason: 'Pre-change Course Editor transaction backup',
    );

    final manifest =
        jsonDecode(await created.manifestFile.readAsString())
            as Map<String, dynamic>;
    final assets = (manifest['assets'] as List).cast<Map<String, dynamic>>();
    // The copied bytes no longer match the reference they claim.
    final copy = File(
      '${created.manifestFile.parent.path}${Platform.pathSeparator}'
      '${(assets.single['backupRelativePath'] as String).replaceAll('/', Platform.pathSeparator)}',
    );
    await copy.writeAsBytes(const [0], flush: true);

    await expectLater(
      backups.loadBackup(created.manifestFile, expectedCourseId: _courseId),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('failed integrity validation'),
        ),
      ),
    );
  });

  test('a record whose checksum and reference disagree is refused', () async {
    final present = await stored(const [3, 1, 4]);
    final created = await backups.createBackup(
      _course([CourseAudioClip(id: 'a', text: 'uno', filePath: present)]),
      backedUpAt: DateTime.utc(2026, 9, 20, 12, 30),
      reason: 'Pre-change Course Editor transaction backup',
    );
    final manifest =
        jsonDecode(await created.manifestFile.readAsString())
            as Map<String, dynamic>;
    final assets = (manifest['assets'] as List).cast<Map<String, dynamic>>();
    assets.single['reference'] = absent;
    await created.manifestFile.writeAsString(jsonEncode(manifest), flush: true);

    await expectLater(
      backups.loadBackup(created.manifestFile, expectedCourseId: _courseId),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'a gap marker cannot smuggle an unvalidated asset past the checks',
    () async {
      final present = await stored(const [1]);
      final created = await backups.createBackup(
        _course([CourseAudioClip(id: 'a', text: 'uno', filePath: present)]),
        backedUpAt: DateTime.utc(2026, 9, 20, 13),
        reason: 'Pre-change Course Editor transaction backup',
      );

      final manifest =
          jsonDecode(await created.manifestFile.readAsString())
              as Map<String, dynamic>;
      final assets = (manifest['assets'] as List).cast<Map<String, dynamic>>();
      // Claims to be a gap while still naming a file: must not be trusted.
      assets.single['missing'] = 'true';
      assets.single['sha256'] = 'deadbeef';
      await created.manifestFile.writeAsString(
        jsonEncode(manifest),
        flush: true,
      );

      await expectLater(
        backups.loadBackup(created.manifestFile, expectedCourseId: _courseId),
        throwsA(isA<FormatException>()),
      );
    },
  );
}

Course _course(List<CourseAudioClip> clips) => Course(
  courseId: _courseId,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: '2026-09-01T09:00:00.000Z',
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Last Editor',
  modifiedAtUtc: '2026-09-20T11:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Backup missing asset',
  ttsLanguage: 'it-IT',
  courseVersion: '2',
  audioMode: 'recorded',
  audioLibrary: clips,
  lessons: const [],
);
