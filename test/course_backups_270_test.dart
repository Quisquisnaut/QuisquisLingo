import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_backup_retention.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';
import 'package:quisquislingo_app/widgets/course_backup_purge.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/synthetic_mp3.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _courseId = 'backups-270';
const _deniedFolder = 'Download/QuisquisLingo/Backups/Courses';

Course _course(List<CourseAudioClip> clips, {String title = 'Backups'}) =>
    Course(
      courseId: _courseId,
      originType: CourseOriginType.custom,
      originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
        profileId: _alice,
        displayName: 'Alice',
      ),
      maintainer: const CourseMaintainer(_alice),
      originalCreatedAtUtc: '2026-10-10T09:00:00.000Z',
      courseVersion: '1',
      publicationState: PublicationState.draft,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: title,
      ttsLanguage: 'it-IT',
      audioLibrary: clips,
      lessons: const [],
    );

/// A backup service whose older backups are a list in memory.
class _ListedBackups extends CourseBackupService {
  _ListedBackups(this.records)
    : super(backupsDirectoryProvider: () async => Directory.systemTemp);

  List<CourseBackupRecord> records;
  final deleted = <CourseBackupRecord>[];

  @override
  Future<List<CourseBackupRecord>> olderThanNewest(
    String courseId,
    int keep,
  ) async => records.length <= keep ? const [] : records.sublist(keep);

  @override
  Future<int> deleteBackups(
    String courseId,
    List<CourseBackupRecord> older,
  ) async {
    deleted.addAll(older);
    records = [
      for (final record in records)
        if (!older.contains(record)) record,
    ];
    return older.length;
  }
}

CourseBackupRecord _record(int day) => CourseBackupRecord(
  manifestFile: File('backup_$day.json'),
  course: _course(const []),
  checksum: '',
  backedUpAtUtc: DateTime.utc(2026, 10, day),
  reason: 'test',
  assets: const [],
);

// Build 270 Revision 9 (owner decisions of 10 October 2026): a Course's
// backups keep each picture and recording once; older backups are deleted
// only when the learner agrees, after a save, and only then are media no
// backup names removed; a change QQL may not back up (Android 7-10 with the
// storage permission refused) is saved without its backup and told.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('backups on disk', () {
    late Directory backupsRoot;
    late Directory support;
    late CourseMediaStore media;
    late CourseBackupService backups;

    setUp(() async {
      backupsRoot = await Directory.systemTemp.createTemp('qql_270_backups_');
      support = await Directory.systemTemp.createTemp('qql_270_media_');
      media = CourseMediaStore(supportDirectory: () async => support);
      backups = CourseBackupService(
        backupsDirectoryProvider: () async => backupsRoot,
        mediaStore: media,
      );
    });

    tearDown(() async {
      for (final directory in [backupsRoot, support]) {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    });

    Future<String> stored(int seed) => media.addBytes(
      _courseId,
      Uint8List.fromList(syntheticMp3(seed: seed)),
      'mp3',
    );

    CourseAudioClip clip(String id, String reference) =>
        CourseAudioClip(id: id, text: id, filePath: reference);

    Future<CourseBackupRecord> backUp(
      List<CourseAudioClip> clips,
      int hour, {
      CourseBackupService? service,
    }) => (service ?? backups).createBackup(
      _course(clips),
      backedUpAt: DateTime.utc(2026, 10, 10, hour),
      reason: 'Pre-change Course Editor transaction backup',
    );

    Directory folderOf(CourseBackupRecord record) => record.manifestFile.parent;

    Directory sharedFolder(CourseBackupRecord record) => Directory(
      '${folderOf(record).path}${Platform.pathSeparator}'
      '${CourseBackupService.sharedMediaFolderName}',
    );

    List<String> namesIn(Directory directory) =>
        directory
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toList()
          ..sort();

    List<String> foldersIn(Directory directory) =>
        directory
            .listSync()
            .whereType<Directory>()
            .map(
              (folder) =>
                  folder.uri.pathSegments.where((s) => s.isNotEmpty).last,
            )
            .toList()
          ..sort();

    test('two versions keep a shared recording once and both load', () async {
      final a = await stored(1);
      final b = await stored(2);
      final first = await backUp([clip('a', a)], 10);
      final second = await backUp([clip('a', a), clip('b', b)], 11);

      expect(
        namesIn(sharedFolder(second)),
        [CourseMediaStore.fileNameOf(a), CourseMediaStore.fileNameOf(b)]
          ..sort(),
      );
      expect(foldersIn(folderOf(first)), [
        CourseBackupService.sharedMediaFolderName,
      ]);
      for (final record in [first, second]) {
        for (final asset in record.assets) {
          expect(
            asset['backupRelativePath'],
            startsWith('${CourseBackupService.sharedMediaFolderName}/'),
          );
        }
        final loaded = await backups.loadBackup(
          record.manifestFile,
          expectedCourseId: _courseId,
        );
        expect(loaded.assets, hasLength(record.assets.length));
      }

      // A restore still puts a recording back from the shared folder.
      await media.deleteUnreferenced(_courseId, const {});
      await backups.reinstateMedia(
        await backups.loadBackup(
          first.manifestFile,
          expectedCourseId: _courseId,
        ),
      );
      expect(await media.existingFile(_courseId, a), isNotNull);
    });

    test('a shared file QQL may not write goes to the version\'s own '
        'folder', () async {
      final a = await stored(6);
      final guarded = CourseBackupService(
        backupsDirectoryProvider: () async => backupsRoot,
        mediaStore: media,
        fileWriter: (file, bytes) async {
          if (file.path.contains(CourseBackupService.sharedMediaFolderName)) {
            throw FileSystemException('Permission denied', file.path);
          }
          await file.writeAsBytes(bytes, flush: true);
        },
      );
      final record = await backUp([clip('a', a)], 10, service: guarded);
      expect(
        record.assets.single['backupRelativePath'],
        endsWith('_assets/${CourseMediaStore.fileNameOf(a)}'),
      );
      final loaded = await guarded.loadBackup(
        record.manifestFile,
        expectedCourseId: _courseId,
      );
      expect(loaded.assets.single['reference'], a);
    });

    test(
      'a backup removes nothing: media are only swept after a purge',
      () async {
        final a = await stored(7);
        final first = await backUp([clip('a', a)], 10);
        final stray = File(
          '${sharedFolder(first).path}${Platform.pathSeparator}stray.mp3',
        );
        await stray.writeAsBytes([1, 2, 3]);
        await backUp([clip('a', a)], 11);
        expect(await stray.exists(), isTrue);
      },
    );

    test('a purge keeps the newest backups and removes the media only the '
        'older ones held, with their own folders', () async {
      final a = await stored(3);
      final b = await stored(4);
      // The oldest version keeps its media in a folder of its own, as
      // before this revision.
      final own = await backUp(
        [clip('a', a)],
        9,
        service: CourseBackupService(
          backupsDirectoryProvider: () async => backupsRoot,
          mediaStore: media,
          fileWriter: (file, bytes) async {
            if (file.path.contains(CourseBackupService.sharedMediaFolderName)) {
              throw FileSystemException('Permission denied', file.path);
            }
            await file.writeAsBytes(bytes, flush: true);
          },
        ),
      );
      await backUp([clip('a', a)], 10);
      await backUp([clip('b', b)], 11);
      final newest = await backUp([clip('b', b)], 12);

      final older = await backups.olderThanNewest(_courseId, 2);
      expect(older.map((record) => record.backedUpAtUtc.hour), [10, 9]);
      expect(await backups.deleteBackups(_courseId, older), 2);

      final left = await backups.listBackups(_courseId);
      expect(left.map((record) => record.backedUpAtUtc.hour), [12, 11]);
      expect(namesIn(sharedFolder(newest)), [CourseMediaStore.fileNameOf(b)]);
      expect(foldersIn(folderOf(own)), [
        CourseBackupService.sharedMediaFolderName,
      ], reason: 'the oldest version\'s own folder went with it');
      expect(await backups.olderThanNewest(_courseId, 2), isEmpty);
    });

    test('nothing shared is removed while a manifest cannot be read; a '
        'later purge removes what nothing names', () async {
      final a = await stored(5);
      await backUp([clip('a', a)], 10);
      final newest = await backUp([clip('a', a)], 11);
      final stray = File(
        '${sharedFolder(newest).path}${Platform.pathSeparator}stray.mp3',
      );
      await stray.writeAsBytes([1, 2, 3]);
      final broken = File(
        '${folderOf(newest).path}${Platform.pathSeparator}broken.json',
      );
      await broken.writeAsString('not a backup');

      final older = await backups.olderThanNewest(_courseId, 1);
      expect(older, hasLength(1), reason: 'an unreadable file is not offered');
      await backups.deleteBackups(_courseId, older);
      expect(await stray.exists(), isTrue);
      expect(await broken.exists(), isTrue);

      await broken.delete();
      await backups.deleteBackups(_courseId, const []);
      expect(await stray.exists(), isFalse);
      expect(namesIn(sharedFolder(newest)), [CourseMediaStore.fileNameOf(a)]);
    });
  });

  group('the setting on this device', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('kept per Course, none by default, forgotten on request', () async {
      final retention = CourseBackupRetention();
      expect(await retention.keepFor(_courseId), isNull);
      await retention.setKeep(_courseId, 10);
      expect(await retention.keepFor(_courseId), 10);
      expect(await retention.keepFor('another'), isNull);
      expect(
        () => retention.setKeep(_courseId, 7),
        throwsA(isA<ArgumentError>()),
      );
      await retention.setKeep(_courseId, null);
      expect(await retention.keepFor(_courseId), isNull);
      await retention.setKeep(_courseId, 5);
      await retention.forget(_courseId);
      expect(await retention.keepFor(_courseId), isNull);
    });

    test('a value that is not one of the choices is ignored', () async {
      SharedPreferences.setMockInitialValues({
        CourseBackupRetention.keyForCourseId(_courseId): 3,
      });
      expect(await CourseBackupRetention().keepFor(_courseId), isNull);
    });
  });

  group('the question after a save', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> pumpSave(WidgetTester tester, _ListedBackups backups) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => CourseBackupPurge.offer(
                    context,
                    _course(const []),
                    backups: backups,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        );

    testWidgets('nothing is asked while every backup is kept', (tester) async {
      final backups = _ListedBackups([for (var d = 1; d <= 9; d++) _record(d)]);
      await pumpSave(tester, backups);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-backup-purge')), findsNothing);
    });

    testWidgets('Not now deletes nothing and asks again; Delete deletes the '
        'older ones', (tester) async {
      await CourseBackupRetention().setKeep(_courseId, 5);
      final backups = _ListedBackups([for (var d = 1; d <= 7; d++) _record(d)]);
      await pumpSave(tester, backups);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-backup-purge')), findsOneWidget);
      expect(find.text('Delete 2 backups'), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-backup-purge-not-now')));
      await tester.pumpAndSettle();
      expect(backups.deleted, isEmpty);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-backup-purge-delete')));
      await tester.pumpAndSettle();
      expect(backups.deleted.map((record) => record.backedUpAtUtc.day), [6, 7]);
      expect(
        find.byKey(const Key('course-backup-purge-result')),
        findsOneWidget,
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-backup-purge')), findsNothing);
    });

    testWidgets('Course Info sets the number and the Course Editor\'s save '
        'asks', (tester) async {
      final course = _course(const []);
      final profiles = ProfileService();
      await profiles.createProfile('Alice', learnerProfileId: _alice);
      await profiles.setActiveProfileById(_alice);
      await SettingsService().markAudioOrphanCheckRun('IT');
      await SettingsService().setCourseEditorMode(
        course.courseId,
        CourseEditorMode.edit,
      );
      await tester.runAsync(() async {
        await CourseEditorService().saveUserCourse(course);
        final backups = CourseBackupService();
        for (var day = 1; day <= 5; day++) {
          await backups.createBackup(
            course,
            backedUpAt: DateTime.utc(2020, 1, day),
            reason: 'Earlier save',
          );
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CourseEditorScreen(
                    course: course,
                    access: CourseAccessPolicy.evaluate(
                      course,
                      profileId: _alice,
                    ),
                  ),
                ),
              ),
              child: const Text('Open Course'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Course'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Course Info Editor'));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('course-info-backups-kept'))
            .evaluate()
            .isNotEmpty,
      );
      final kept = find.byKey(const Key('course-info-backups-kept'));
      await tester.ensureVisible(kept);
      await tester.tap(kept);
      await tester.pumpAndSettle();
      await tester.tap(find.text('The newest 5').last);
      await tester.pumpAndSettle();
      // A change to the Course too, so that leaving asks to confirm it.
      final hours = find.byKey(const Key('course-info-estimated-hours'));
      await tester.ensureVisible(hours);
      await tester.enterText(hours, '12');
      await tester.pump();
      final save = find.byKey(const Key('course-info-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpUntilFileIoState(() => save.evaluate().isEmpty);
      expect(await CourseBackupRetention().keepFor(course.courseId), 5);

      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-course-changes')));
      await tester.pumpUntilFileIoState(
        () =>
            find.byKey(const Key('course-backup-purge')).evaluate().isNotEmpty,
      );
      expect(find.text('Delete 1 backup'), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-backup-purge-delete')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isEmpty,
      );
      final left = await tester.runAsync(
        () => CourseBackupService().listBackups(course.courseId),
      );
      expect(left, hasLength(5));
      expect(
        left!.where((record) => record.reason == 'Earlier save'),
        hasLength(4),
      );
      expect(
        left.map((record) => record.backedUpAtUtc),
        isNot(contains(DateTime.utc(2020, 1, 1))),
        reason: 'only the oldest backup went',
      );
    });
  });

  group('Android 7-10 without the storage permission', () {
    late Directory root;
    late CourseEditorService editor;
    var deny = false;
    final skipped = <String>[];
    final previousHandler = CourseEditorService.backupSkipped;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      ProfileService.beginAccessSession();
      await ProfileService().createProfile(
        'Alice',
        learnerProfileId: _alice,
        generateScreenNameSuffix: false,
      );
      root = await Directory.systemTemp.createTemp('qql_270_denied_');
      final store = CourseMediaStore(supportDirectory: () async => root);
      deny = false;
      skipped.clear();
      CourseEditorService.backupSkipped = skipped.add;
      editor = CourseEditorService(
        courseStore: CourseFileStore(supportDirectory: () async => root),
        mediaStore: store,
        backupService: CourseBackupService(
          backupsDirectoryProvider: () async {
            if (deny) throw const CourseBackupsAccessDenied(_deniedFolder);
            return root;
          },
          mediaStore: store,
        ),
        clock: () => DateTime.utc(2026, 10, 10, 9),
      );
    });

    tearDown(() async {
      CourseEditorService.backupSkipped = previousHandler;
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('a change is saved without its backup, and the app is told', () async {
      final created = await editor.confirmCourseTransaction(
        originalCourse: _course(const []),
        workingCourse: _course(const []),
        languageCode: 'IT',
        versionNotes: '',
        isNewCourse: true,
      );
      expect(created.backupSkippedFolder, isNull);

      deny = true;
      final changed = await editor.confirmCourseTransaction(
        originalCourse: created.course,
        workingCourse: Course.fromJson({
          ...created.course.toJson(),
          'title': 'Saved anyway',
        }),
        languageCode: 'IT',
        versionNotes: '',
      );
      expect(changed.course.title, 'Saved anyway');
      expect(changed.backupPath, isNull);
      expect(changed.backupSkippedFolder, _deniedFolder);
      expect(skipped, [_deniedFolder]);

      // With the permission back, the next change is backed up again.
      deny = false;
      final later = await editor.confirmCourseTransaction(
        originalCourse: changed.course,
        workingCourse: Course.fromJson({
          ...changed.course.toJson(),
          'title': 'Backed up',
        }),
        languageCode: 'IT',
        versionNotes: '',
      );
      expect(later.backupPath, isNotNull);
      expect(later.backupSkippedFolder, isNull);
      expect(skipped, hasLength(1));
    });
  });
}
