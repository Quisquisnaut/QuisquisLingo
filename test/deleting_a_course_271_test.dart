import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/inventory_action_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';
import 'package:quisquislingo_app/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';
import 'support/test_directories.dart';
import 'support/unique_png.dart';

/// Build 271 Revision 1 (owner decisions of 10 and 11 October 2026):
/// deleting a Course names the other learners who have it and can also
/// reset the learner's own progress and delete its backups; a backup never
/// stops a save; the Course store cleans up after an interrupted save; a
/// Publisher update keeps the stored copy it could not open; the Inventory
/// deletes the media of a Course no longer on the device with one action.

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _carla = '33333333-3333-4333-8333-333333333333';
const _pin = '4826';

Course _course(
  String id, {
  String title = 'Italiano al bar',
  String maintainer = _alice,
  bool private = false,
  List<String> images = const [],
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: 'Maintainer',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-10-11T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  temporarySample: private,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  imageLibrary: [
    for (final image in images) CourseImageLibraryEntry(asset: image),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      updatedAt: DateTime.utc(2026, 10, 11),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileService profiles;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    profiles = ProfileService();
    for (final (id, name) in [
      (_alice, 'Alice'),
      (_bob, 'Bob'),
      (_carla, 'Carla'),
    ]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    await profiles.setActiveProfileById(_alice);
  });

  Future<void> as(String profileId, Future<void> Function() action) async {
    await profiles.setActiveProfileById(profileId);
    await action();
    await profiles.setActiveProfileById(_alice);
  }

  group('A backup never blocks a save', () {
    test('a stored file that no longer matches its name is a gap', () async {
      final media = CourseMediaStore();
      final good = await media.addBytes('damaged', uniquePng(1), 'png');
      final bad = await media.addBytes('damaged', uniquePng(2), 'png');
      // The file changed on disk: its bytes are no longer what its name says.
      await (await media.fileFor(
        'damaged',
        bad,
      )).writeAsBytes(const [1, 2, 3], flush: true);
      final logged = <String>[];
      final backups = CourseBackupService(
        mediaStore: media,
        log: (message) async => logged.add(message),
      );

      final record = await backups.createBackup(
        _course('damaged', images: [good, bad]),
        backedUpAt: DateTime.utc(2026, 10, 11, 10),
        reason: 'Pre-change Course Editor transaction backup',
      );

      final gap = record.assets.singleWhere((a) => a['missing'] == 'true');
      expect(gap['reference'], bad);
      expect(gap['damaged'], 'true');
      expect(gap.containsKey('backupRelativePath'), isFalse);
      expect(gap.containsKey('sha256'), isFalse);
      final copied = record.assets.singleWhere((a) => a['missing'] != 'true');
      expect(copied['reference'], good);
      expect(logged.single, contains(CourseMediaStore.fileNameOf(bad)));
      expect(logged.single, contains('no longer matches its name'));
      // The version is listed and restores what it holds.
      final listed = await backups.listBackups('damaged');
      expect(listed, hasLength(1));
      await media.deleteUnreferenced('damaged', const {});
      await backups.reinstateMedia(listed.single);
      expect(await media.existingFile('damaged', good), isNotNull);
      expect(await media.existingFile('damaged', bad), isNull);
    });

    test('a Course with a damaged file can still be saved', () async {
      final media = CourseMediaStore();
      final image = await media.addBytes('saveable', uniquePng(3), 'png');
      final editor = CourseEditorService();
      await editor.installImportedCustomCourse(
        _course('saveable', images: [image]),
      );
      await (await media.fileFor(
        'saveable',
        image,
      )).writeAsBytes(const [9], flush: true);
      final stored = (await editor.listUserCourses()).single;

      // Before Build 271 Revision 1 this threw "does not match its
      // reference" for every later save, also the one removing the picture.
      final result = await editor.confirmCourseTransaction(
        originalCourse: stored,
        workingCourse: Course.fromJson({
          ...stored.toJson(),
          'title': 'Saved again',
        }),
        languageCode: 'IT',
        versionNotes: 'A save after the picture was damaged',
      );
      expect(result.course.title, 'Saved again');
      expect((await editor.listUserCourses()).single.title, 'Saved again');
    });
  });

  group('The backups of a Course', () {
    late CourseBackupService backups;
    late CourseMediaStore media;

    setUp(() {
      media = CourseMediaStore();
      backups = CourseBackupService(mediaStore: media);
    });

    test('are counted, measured and deleted whole', () async {
      expect((await backups.summaryOf('kept')).isEmpty, isTrue);
      expect(await backups.deleteAllBackups('kept'), isTrue);

      final image = await media.addBytes('kept', uniquePng(4), 'png');
      final course = _course('kept', images: [image]);
      for (final hour in [10, 11, 12]) {
        await backups.createBackup(
          course,
          backedUpAt: DateTime.utc(2026, 10, 11, hour),
          reason: 'Pre-change Course Editor transaction backup',
        );
      }
      final folder = await backups.courseBackupDirectory('kept');
      // A file this version cannot read is one of its backups too.
      File(
        '${folder.path}${Platform.pathSeparator}QQL_bkp_EN_IT_kept_v0_old.json',
      ).writeAsStringSync('{"format": "QuisquisLingo Course Backup v11"}');
      // Another Course's backups stay.
      await backups.createBackup(
        _course('other'),
        backedUpAt: DateTime.utc(2026, 10, 11, 13),
        reason: 'Pre-change Course Editor transaction backup',
      );

      final summary = await backups.summaryOf('kept');
      expect(summary.versions, 4);
      expect(summary.bytes, greaterThan(uniquePng(4).length));
      expect(
        CourseLibraryReports.backupsHeld(summary),
        startsWith('4 saved versions in Backups/Courses ('),
      );

      expect(await backups.deleteAllBackups('kept'), isTrue);
      expect(folder.existsSync(), isFalse);
      expect((await backups.summaryOf('kept')).isEmpty, isTrue);
      expect(await backups.listBackups('other'), hasLength(1));
    });

    test('keep a stored copy this version cannot open', () async {
      final record = {
        'source': {'courseId': 'official', 'guidebook': 'an earlier shape'},
        'savedAt': '2026-09-01T00:00:00.000Z',
      };
      final kept = await backups.keepUnreadableCopy(
        'official',
        record,
        when: DateTime.utc(2026, 10, 11, 14),
        pair: 'EN_IT',
        reason: 'Replaced by an update',
      );
      final folder = await backups.courseBackupDirectory('official');
      expect(kept.parent.path, folder.path);
      expect(kept.uri.pathSegments.last, contains('_vunreadable_'));
      final decoded = jsonDecode(kept.readAsStringSync()) as Map;
      expect(decoded['format'], CourseBackupService.unreadableCopyFormat);
      expect(decoded['courseId'], 'official');
      expect(decoded['record'], record);
      // A second copy at the same moment gets a name of its own.
      final again = await backups.keepUnreadableCopy(
        'official',
        record,
        when: DateTime.utc(2026, 10, 11, 14),
        pair: 'EN_IT',
        reason: 'Replaced by an update',
      );
      expect(again.path, isNot(kept.path));
      // Version History names both among the files it cannot read.
      final skipped = <String>[];
      expect(await backups.listBackups('official', skipped: skipped), isEmpty);
      expect(skipped, hasLength(2));
      expect((await backups.summaryOf('official')).versions, 2);
    });
  });

  group('The Course store', () {
    test('removes the temporary files an interrupted save left', () async {
      final store = CourseFileStore();
      await store.write(CourseStoreKind.custom, 'kept', {
        'course': _course('kept').toJson(),
      });
      final custom = await store.directoryFor(CourseStoreKind.custom);
      final publisher = await store.directoryFor(
        CourseStoreKind.externalOfficial,
        create: true,
      );
      File inFolder(Directory folder, String name) =>
          File('${folder.path}${Platform.pathSeparator}$name')
            ..writeAsStringSync('x');
      final leftovers = [
        inFolder(custom, 'QQL_EN_IT_kept.json.4242.1760000000000000.0.tmp'),
        inFolder(custom, 'QQL_EN_IT_gone.json.17.1760000000000001.12.tmp'),
        inFolder(publisher, 'QQL_EN_IT_pub.json.99.1760000000000002.3.tmp'),
      ];
      final stays = [
        // This run of QQL may still be writing it.
        inFolder(custom, 'QQL_EN_IT_kept.json.$pid.1760000000000003.1.tmp'),
        // Not a staging name.
        inFolder(custom, 'notes.tmp'),
        inFolder(custom, 'QQL_EN_IT_kept.json.bak'),
      ];

      expect(await store.removeLeftoverTemporaryFiles(), 3);
      for (final file in leftovers) {
        expect(file.existsSync(), isFalse, reason: file.path);
      }
      for (final file in stays) {
        expect(file.existsSync(), isTrue, reason: file.path);
      }
      expect((await store.readReadable(CourseStoreKind.custom)).records.keys, [
        'kept',
      ]);
      expect(await store.removeLeftoverTemporaryFiles(), 0);
    });

    test('nothing to clean when the store does not exist yet', () async {
      expect(await CourseFileStore().removeLeftoverTemporaryFiles(), 0);
    });

    test('flushes the folder after a save and after a rename', () async {
      final flushed = <String>[];
      final before = CourseFileStore.syncDirectory;
      CourseFileStore.syncDirectory = (directory) async =>
          flushed.add(directory.path);
      addTearDown(() => CourseFileStore.syncDirectory = before);
      final store = CourseFileStore();
      final custom = await store.directoryFor(CourseStoreKind.custom);

      await store.write(CourseStoreKind.custom, 'flushed', {
        'course': _course('flushed').toJson(),
      });
      expect(flushed, [custom.path]);

      // A change of language pair renames the file, then writes it.
      flushed.clear();
      await store.write(CourseStoreKind.custom, 'flushed', {
        'course': {
          ..._course('flushed').toJson(),
          'targetLanguage': 'Welsh',
          'learningLanguage': 'Welsh',
          'targetLanguageTag': 'cy',
        },
      });
      expect(flushed, [custom.path, custom.path]);
    });

    test('the default flush does nothing on Windows', () async {
      // Linux and macOS call the system's `sync`; this PC cannot run that.
      await CourseFileStore.flushDirectory(Directory.systemTemp);
    }, skip: !Platform.isWindows);
  });

  group('A Publisher update over a copy this version cannot open', () {
    test('keeps that copy in the Course\'s backup folder', () async {
      final publisher = Course.fromJson(
        jsonDecode(
              File(
                'test/fixtures/publishers/dummy-signed-v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final editor = CourseEditorService(
        publisherVerification: fixtureVerifier(
          publisher.publisherId,
          publisher.publisherName,
        ),
      );
      await editor.installExternalOfficialUpdate(publisher);
      // The stored source takes a shape this version refuses.
      final store = CourseFileStore();
      final stored = await store.snapshot(
        CourseStoreKind.externalOfficial,
        publisher.courseId,
      );
      final record = Map<String, dynamic>.from(stored!.entry as Map);
      final source = Map<String, dynamic>.from(record['source'] as Map);
      (source['lessons'] as List).first['guidebook'] = {'content': []};
      record['source'] = source;
      await store.replaceIfUnchanged(
        CourseStoreKind.externalOfficial,
        publisher.courseId,
        record,
        expectedToken: stored.token,
      );

      final result = await editor.installExternalOfficialUpdate(publisher);

      expect(result.backupPath, isNotNull);
      final kept = File(result.backupPath!);
      expect(kept.existsSync(), isTrue);
      final decoded = jsonDecode(kept.readAsStringSync()) as Map;
      expect(decoded['format'], CourseBackupService.unreadableCopyFormat);
      expect(decoded['courseId'], publisher.courseId);
      expect(
        ((decoded['record'] as Map)['source']
            as Map)['lessons'][0]['guidebook'],
        {'content': []},
      );
      expect(
        kept.parent.path,
        (await editor.backupService.courseBackupDirectory(
          publisher.courseId,
        )).path,
      );
      // The update itself is installed and opens.
      final installed = (await editor.listUserCourses()).single;
      expect(installed.courseId, publisher.courseId);
    });
  });

  group('Deleting a Course', () {
    late CourseLibraryOperations ops;

    setUp(() {
      ops = CourseLibraryOperations(profiles: profiles);
    });

    test('names the other learners who have it in their courses', () async {
      final course = _course('shared');
      await ops.editor.installImportedCustomCourse(course);
      // Nobody else yet.
      expect((await ops.previewDelete(course)).otherLearners, isEmpty);
      expect(CourseLibraryReports.otherLearnersHave(const []), isNull);

      // Bob added it; Carla studied it before personal libraries existed.
      await as(_bob, () => CourseLibraryService().add(course));
      await as(
        _carla,
        () => ProgressService().completeRound(
          'round-1',
          courseId: 'shared',
          courseCode: 'IT',
        ),
      );
      final preview = await ops.previewDelete(course);
      expect(preview.otherLearners, ['Bob', 'Carla']);
      expect(
        CourseLibraryReports.otherLearnersHave(preview.otherLearners),
        'Bob and Carla have this Course in their courses. Delete it anyway?',
      );
      expect(
        CourseLibraryReports.otherLearnersHave(const ['Anna']),
        'Anna has this Course in their courses. Delete it anyway?',
      );
      expect(
        CourseLibraryReports.otherLearnersHave(const ['Anna', 'Bob', 'Carla']),
        'Anna, Bob and Carla have this Course in their courses. '
        'Delete it anyway?',
      );
      expect(preview.backups.isEmpty, isTrue);

      // A learner who removed it is not named.
      await as(_bob, () => CourseLibraryService().remove(course));
      expect((await ops.previewDelete(course)).otherLearners, ['Carla']);
    });

    test('a Private course is in nobody else\'s courses', () async {
      final course = _course('secret', private: true);
      await ops.editor.installImportedCustomCourse(course);
      await as(_bob, () => CourseLibraryService().add(course));
      expect((await ops.previewDelete(course)).otherLearners, isEmpty);
    });

    test('by itself leaves progress and backups alone', () async {
      final course = _course('plain');
      await ops.editor.installImportedCustomCourse(course);
      await ops.editor.backupService.createBackup(
        course,
        backedUpAt: DateTime.utc(2026, 10, 11, 10),
        reason: 'Pre-change Course Editor transaction backup',
      );
      await ProgressService().completeRound(
        'round-1',
        courseId: 'plain',
        courseCode: 'IT',
      );

      final result = await ops.deleteCourse(course);

      expect(await ops.editor.listUserCourses(), isEmpty);
      expect(result.progressReset, isFalse);
      expect(result.backupsDeleted, 0);
      expect(await ProgressService().getCompletedRounds(courseId: 'plain'), {
        'round-1',
      });
      expect((await ops.editor.backupService.summaryOf('plain')).versions, 1);
      expect(
        CourseLibraryReports.deleted(course, result),
        'Deleted “Italiano al bar”.',
      );
    });

    test('resets my progress and deletes its backups when asked', () async {
      final media = CourseMediaStore();
      final image = await media.addBytes('full', uniquePng(5), 'png');
      final course = _course('full', images: [image]);
      final other = _course('other', title: 'Another course');
      await ops.editor.installImportedCustomCourse(course);
      await ops.editor.installImportedCustomCourse(other);
      for (final hour in [10, 11]) {
        await ops.editor.backupService.createBackup(
          course,
          backedUpAt: DateTime.utc(2026, 10, 11, hour),
          reason: 'Pre-change Course Editor transaction backup',
        );
      }
      await ops.editor.backupService.createBackup(
        other,
        backedUpAt: DateTime.utc(2026, 10, 11, 12),
        reason: 'Pre-change Course Editor transaction backup',
      );
      final progress = ProgressService();
      await progress.completeRound(
        'round-1',
        courseId: 'full',
        courseCode: 'IT',
      );
      await progress.completeRound(
        'round-2',
        courseId: 'other',
        courseCode: 'IT',
      );
      await XpService().addXp(40, courseCode: 'IT', courseId: 'full');
      await as(
        _bob,
        () => ProgressService().completeRound(
          'round-1',
          courseId: 'full',
          courseCode: 'IT',
        ),
      );
      final preview = await ops.previewDelete(course);
      expect(preview.backups.versions, 2);
      expect(preview.otherLearners, ['Bob']);

      final result = await ops.deleteCourse(
        course,
        resetMyProgress: true,
        deleteBackups: true,
      );

      expect((await ops.editor.listUserCourses()).map((c) => c.courseId), [
        'other',
      ]);
      expect(result.progressReset, isTrue);
      expect(result.backupsDeleted, 2);
      expect(result.backupsLeft, isFalse);
      // My progress on this Course is gone; XP and the other Course stay.
      expect(await progress.getCompletedRounds(courseId: 'full'), isEmpty);
      expect(await progress.getCompletedRounds(courseId: 'other'), {'round-2'});
      expect(await XpService().getXp(courseCode: 'IT'), 40);
      // Another learner's progress is theirs.
      await profiles.setActiveProfileById(_bob);
      expect(await ProgressService().getCompletedRounds(courseId: 'full'), {
        'round-1',
      });
      await profiles.setActiveProfileById(_alice);
      // Its backups and media are gone; the other Course keeps its own.
      expect(
        (await ops.editor.backupService.summaryOf('full')).isEmpty,
        isTrue,
      );
      expect((await ops.editor.backupService.summaryOf('other')).versions, 1);
      expect(await media.existingFile('full', image), isNull);
      expect(
        CourseLibraryReports.deleted(course, result),
        'Deleted “Italiano al bar”, your progress on it and its 2 backups.',
      );
    });

    test('a Delete that fails changes nothing else', () async {
      final course = _course('bobs', maintainer: _bob);
      await as(_bob, () => ops.editor.installImportedCustomCourse(course));
      await ops.editor.backupService.createBackup(
        course,
        backedUpAt: DateTime.utc(2026, 10, 11, 10),
        reason: 'Pre-change Course Editor transaction backup',
      );
      await as(_carla, () async {
        await ProgressService().completeRound(
          'round-1',
          courseId: 'bobs',
          courseCode: 'IT',
        );
        // Carla is neither its Maintainer nor in its Team.
        await expectLater(
          ops.deleteCourse(course, resetMyProgress: true, deleteBackups: true),
          throwsA(isA<StateError>()),
        );
        expect(await ProgressService().getCompletedRounds(courseId: 'bobs'), {
          'round-1',
        });
      });
      expect((await ops.editor.backupService.summaryOf('bobs')).versions, 1);
    });

    test('says what it could not do', () {
      final course = _course('report');
      expect(
        CourseLibraryReports.deleted(
          course,
          const CourseDeleteResult(
            progressResetAsked: true,
            backupsAsked: true,
            backupsDeleted: 1,
            backupsLeft: true,
          ),
        ),
        'Deleted “Italiano al bar” and its 1 backup. Your progress on it '
        'could not be reset. Some of its backup files could not be deleted; '
        'they are still in Backups/Courses.',
      );
      expect(CourseLibraryReports.sizeText(512), '512 bytes');
      expect(CourseLibraryReports.sizeText(84 * 1024), '84 KB');
      expect(CourseLibraryReports.sizeText(3 * 1024 * 1024 + 500000), '3.5 MB');
      expect(CourseLibraryReports.sizeText(37 * 1024 * 1024), '37 MB');
    });
  });

  group('The Inventory', () {
    // Its actions need the admin's PIN.
    setUp(() => profiles.setOwnAccessPin(actorProfileId: _alice, pin: _pin));

    Future<Directory> mediaFolderOf(String courseId) async {
      final media = CourseMediaStore();
      await media.addBytes(courseId, uniquePng(courseId.hashCode), 'png');
      await media.addBytes(
        courseId,
        Uint8List.fromList(uniquePng(courseId.hashCode + 1)),
        'png',
      );
      return media.courseDirectory(courseId);
    }

    InventorySection courseMedia(List<InventorySection> sections) =>
        sections.firstWhere((section) => section.title == 'Course media');

    test('offers the whole folder of a Course no longer here', () async {
      final editor = CourseEditorService();
      await editor.installImportedCustomCourse(_course('here'));
      final owned = await mediaFolderOf('here');
      final orphan = await mediaFolderOf('gone');

      final section = courseMedia(
        await InventoryService(profiles: profiles).load(),
      );

      expect(section.count, 4, reason: 'the folders are not counted');
      final group = section.groups.single;
      expect(group.path, orphan.path);
      expect(group.name, endsWith('(whole folder)'));
      expect(group.note, startsWith('2 files'));
      expect(group.owner, 'A course no longer on this device');
      expect(group.action!.kind, InventoryActionKind.deleteCourseMediaFolder);
      expect(group.action!.label, 'Delete all');
      expect(group.action!.target, orphan.path);
      expect(owned.existsSync(), isTrue);
    });

    test('deletes it with the admin PIN and nothing else', () async {
      final editor = CourseEditorService();
      await editor.installImportedCustomCourse(_course('here'));
      final owned = await mediaFolderOf('here');
      final orphan = await mediaFolderOf('gone');
      final actions = InventoryActionService(profiles: profiles);
      InventoryAction deleteFolder(String path) => InventoryAction(
        InventoryActionKind.deleteCourseMediaFolder,
        path,
        label: 'Delete all',
        explanation: '',
      );
      Future<void> run(String path, {String pin = _pin}) =>
          actions.run(deleteFolder(path), actorProfileId: _alice, pin: pin);

      await expectLater(
        run(orphan.path, pin: '0000'),
        throwsA(isA<InventoryActionException>()),
      );
      expect(orphan.existsSync(), isTrue);
      // A folder a Course on this device uses stays.
      await expectLater(
        run(owned.path),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            contains('A Course on this device uses this folder'),
          ),
        ),
      );
      expect(owned.listSync(), hasLength(2));
      // So does any folder that is not a Course media folder.
      final elsewhere = Directory(
        '${testSupportDirectory.path}${Platform.pathSeparator}'
        '${CourseStorageNames.mediaFolderName('gone')}',
      )..createSync();
      await expectLater(
        run(elsewhere.path),
        throwsA(isA<InventoryActionException>()),
      );
      await expectLater(
        run((await CourseMediaStore().rootDirectory()).path),
        throwsA(isA<InventoryActionException>()),
      );
      expect(elsewhere.existsSync(), isTrue);

      await run(orphan.path);
      expect(orphan.existsSync(), isFalse);
      expect(owned.listSync(), hasLength(2));
      final section = courseMedia(
        await InventoryService(profiles: profiles).load(),
      );
      expect(section.groups, isEmpty);
      expect(section.count, 2);
    });
  });
}
