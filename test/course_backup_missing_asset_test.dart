import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

/// A referenced recording can disappear from disk: the admin reset removes
/// imported media, or the creator deletes the file outside QQL. The pre-change
/// backup reads the *persisted* Course, so refusing to back up a course with a
/// missing file made every later save fail — including the edit that would have
/// removed the broken reference. The backup now records the gap instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late Directory media;
  late CourseBackupService backups;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_backup_missing_');
    media = await Directory.systemTemp.createTemp('qql_backup_media_');
    backups = CourseBackupService(
      documentsDirectoryProvider: () async => documents,
    );
  });

  tearDown(() async {
    for (final directory in [documents, media]) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  });

  File mediaFile(String name) =>
      File('${media.path}${Platform.pathSeparator}$name');

  test('a backup succeeds and records the gap when a clip file is gone', () async {
    final present = mediaFile('present.mp3');
    await present.writeAsBytes(const [1, 2, 3], flush: true);
    final absent = mediaFile('gone.mp3');

    final record = await backups.createBackup(
      _course([
        CourseAudioClip(id: 'a', text: 'uno', filePath: present.path),
        CourseAudioClip(id: 'b', text: 'due', filePath: absent.path),
      ]),
      backedUpAt: DateTime.utc(2026, 9, 20, 10),
      reason: 'Pre-change Course Editor transaction backup',
    );

    expect(record.assets, hasLength(2));
    final gap = record.assets.singleWhere((a) => a['missing'] == 'true');
    expect(gap['originalPath'], absent.absolute.path);
    expect(gap.containsKey('backupRelativePath'), isFalse);
    expect(gap.containsKey('sha256'), isFalse);

    final copied = record.assets.singleWhere((a) => a['missing'] != 'true');
    expect(copied['sha256'], isNotNull);
    expect(
      File(
        '${record.manifestFile.parent.path}${Platform.pathSeparator}'
        '${copied['backupRelativePath']!.replaceAll('/', Platform.pathSeparator)}',
      ).existsSync(),
      isTrue,
    );
  });

  test('restore remaps the copied clip and leaves the missing one alone', () async {
    final present = mediaFile('present.mp3');
    await present.writeAsBytes(const [4, 5, 6], flush: true);
    final absent = mediaFile('gone.mp3');

    final created = await backups.createBackup(
      _course([
        CourseAudioClip(id: 'a', text: 'uno', filePath: present.path),
        CourseAudioClip(id: 'b', text: 'due', filePath: absent.path),
      ]),
      backedUpAt: DateTime.utc(2026, 9, 20, 11),
      reason: 'Pre-change Course Editor transaction backup',
    );

    final loaded = await backups.loadBackup(
      created.manifestFile,
      expectedCourseId: 'backup-missing-asset',
    );
    final clips = {
      for (final clip in loaded.course.audioLibrary) clip.id: clip.filePath,
    };
    expect(clips['a'], isNot(present.path));
    expect(clips['a'], contains('_assets'));
    expect(clips['b'], absent.path, reason: 'a gap must not be remapped');
  });

  test('an asset that claims a path is still validated strictly', () async {
    final present = mediaFile('present.mp3');
    await present.writeAsBytes(const [7, 8, 9], flush: true);
    final created = await backups.createBackup(
      _course([CourseAudioClip(id: 'a', text: 'uno', filePath: present.path)]),
      backedUpAt: DateTime.utc(2026, 9, 20, 12),
      reason: 'Pre-change Course Editor transaction backup',
    );

    final manifest = jsonDecode(await created.manifestFile.readAsString())
        as Map<String, dynamic>;
    final assets = (manifest['assets'] as List).cast<Map<String, dynamic>>();
    assets.single['sha256'] = 'deadbeef';
    await created.manifestFile.writeAsString(jsonEncode(manifest), flush: true);

    await expectLater(
      backups.loadBackup(
        created.manifestFile,
        expectedCourseId: 'backup-missing-asset',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('failed integrity validation'),
        ),
      ),
    );
  });

  test('a gap marker cannot smuggle an unvalidated asset past the checks', () async {
    final present = mediaFile('present.mp3');
    await present.writeAsBytes(const [1], flush: true);
    final created = await backups.createBackup(
      _course([CourseAudioClip(id: 'a', text: 'uno', filePath: present.path)]),
      backedUpAt: DateTime.utc(2026, 9, 20, 13),
      reason: 'Pre-change Course Editor transaction backup',
    );

    final manifest = jsonDecode(await created.manifestFile.readAsString())
        as Map<String, dynamic>;
    final assets = (manifest['assets'] as List).cast<Map<String, dynamic>>();
    // Claims to be a gap while still naming a file: must not be trusted.
    assets.single['missing'] = 'true';
    assets.single['sha256'] = 'deadbeef';
    await created.manifestFile.writeAsString(jsonEncode(manifest), flush: true);

    await expectLater(
      backups.loadBackup(
        created.manifestFile,
        expectedCourseId: 'backup-missing-asset',
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Course _course(List<CourseAudioClip> clips) => Course(
  courseId: 'backup-missing-asset',
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
