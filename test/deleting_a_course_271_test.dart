import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/screens/inventory_screen.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_learners.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/inventory_action_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';
import 'package:quisquislingo_app/services/xp_service.dart';
import 'package:quisquislingo_app/widgets/folder_opener.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';
import 'support/pump_file_io.dart';
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

  /// Alice's Access PIN once a test has set it.
  String? alicePin;

  setUp(() async {
    alicePin = null;
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
    await profiles.setActiveProfileById(_alice, accessPin: alicePin);
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
    test('replaces it and keeps no copy', () async {
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

      // Owner decision of 11 October 2026: the publisher's package is the
      // copy of a Publisher Course, so nothing QQL cannot open is kept.
      expect(result.backupPath, isNull);
      expect(
        (await editor.backupService.summaryOf(publisher.courseId)).isEmpty,
        isTrue,
      );
      final installed = (await editor.listUserCourses()).single;
      expect(installed.courseId, publisher.courseId);
    });
  });

  group('The learners of a Course', () {
    test('progress is found and reset learner by learner', () async {
      await as(
        _bob,
        () => ProgressService().completeRound(
          'round-1',
          courseId: 'shared',
          courseCode: 'IT',
        ),
      );
      await as(_carla, () async {
        // A recent Round alone is progress too.
        await ProgressService().recordRecentRound(
          'shared',
          'lesson-1',
          'round-2',
          errors: 1,
        );
        await ProgressService().completeRound(
          'round-9',
          courseId: 'other',
          courseCode: 'IT',
        );
      });
      final progress = ProgressService();
      expect(await progress.hasCourseProgress(_alice, 'shared'), isFalse);
      expect(await progress.hasCourseProgress(_bob, 'shared'), isTrue);
      expect(await progress.hasCourseProgress(_carla, 'shared'), isTrue);

      await progress.resetCourseForProfile(_bob, 'shared');
      expect(await progress.hasCourseProgress(_bob, 'shared'), isFalse);
      expect(await progress.hasCourseProgress(_carla, 'shared'), isTrue);

      await CourseLearnersService(profiles: profiles).resetEveryone('shared');
      expect(await progress.hasCourseProgress(_carla, 'shared'), isFalse);
      // Another Course's progress stays.
      expect(await progress.hasCourseProgress(_carla, 'other'), isTrue);
    });

    test('who has it, and who removed it but kept their progress', () async {
      final course = _course('shared');
      await CourseEditorService().installImportedCustomCourse(course);
      await as(_bob, () async {
        await CourseLibraryService().add(course);
        await ProgressService().completeRound(
          'round-1',
          courseId: 'shared',
          courseCode: 'IT',
        );
        // Bob removes it from his courses and keeps his progress.
        await CourseLibraryService().remove(course);
      });
      await as(_carla, () => CourseLibraryService().add(course));
      final service = CourseLearnersService(profiles: profiles);
      List<String> names(List<LearnerProfile> learners) => [
        for (final learner in learners) learner.displayName,
      ];

      final learners = await service.of('shared', course: course);
      expect(names(learners.inCourses), ['Alice', 'Carla']);
      expect(names(learners.keptProgress), ['Bob']);

      // A Course this version cannot open is known by its ID alone.
      final byId = await service.of('shared');
      expect(names(byId.inCourses), ['Alice', 'Carla']);
      expect(names(byId.keptProgress), ['Bob']);
      // A learner with progress who never removed it has it.
      await as(
        _bob,
        () => ProgressService().completeRound(
          'round-1',
          courseId: 'unlisted',
          courseCode: 'IT',
        ),
      );
      final unlisted = await service.of('unlisted');
      expect(names(unlisted.inCourses), ['Bob']);
      expect(unlisted.keptProgress, isEmpty);
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

    /// Stores a Course with one backup, then gives its stored copy a shape
    /// this version refuses.
    Future<void> storeUnopenable(String courseId) async {
      final course = _course(courseId);
      await ops.editor.installImportedCustomCourse(course);
      await ops.editor.backupService.createBackup(
        course,
        backedUpAt: DateTime.utc(2026, 10, 11, 10),
        reason: 'Pre-change Course Editor transaction backup',
      );
      final store = CourseFileStore();
      final stored = await store.snapshot(CourseStoreKind.custom, courseId);
      final entry = Map<String, dynamic>.from(stored!.entry as Map);
      final json = Map<String, dynamic>.from(entry['course'] as Map);
      (json['lessons'] as List).first['guidebook'] = {'content': []};
      entry['course'] = json;
      await store.replaceIfUnchanged(
        CourseStoreKind.custom,
        courseId,
        entry,
        expectedToken: stored.token,
      );
      expect(await ops.editor.unopenableCourse(courseId), isNotNull);
    }

    test('a Course this version cannot open goes with its backups', () async {
      await storeUnopenable('earlier');
      // Its backups are found by its ID.
      expect((await ops.backupsOf('earlier')).versions, 1);

      final result = await ops.removeUnopenableCourse(
        'earlier',
        deleteBackups: true,
      );

      expect(result.backupsDeleted, 1);
      expect(result.backupsLeft, isFalse);
      expect(await ops.editor.unopenableCourse('earlier'), isNull);
      expect((await ops.backupsOf('earlier')).isEmpty, isTrue);
      expect(
        CourseLibraryReports.unopenableRemoved(
          'QQL_EN_IT_earlier.json',
          result,
        ),
        'Removed QQL_EN_IT_earlier.json and its 1 backup.',
      );
    });

    test('removing it without the option keeps its backups', () async {
      await storeUnopenable('earlier');

      final result = await ops.removeUnopenableCourse('earlier');

      expect(result.backupsDeleted, 0);
      expect(await ops.editor.unopenableCourse('earlier'), isNull);
      expect((await ops.backupsOf('earlier')).versions, 1);
      expect(
        CourseLibraryReports.unopenableRemoved(
          'QQL_EN_IT_earlier.json',
          result,
        ),
        'Removed QQL_EN_IT_earlier.json.',
      );
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
    // Its actions need the admin's PIN. With a PIN, Alice is made active
    // again only with it, so each test sets it once its learners are ready.
    Future<void> setPin() async {
      await profiles.setOwnAccessPin(actorProfileId: _alice, pin: _pin);
      alicePin = _pin;
    }

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

    InventoryAction deleteCourse(String courseId) => InventoryAction(
      InventoryActionKind.deleteCourse,
      courseId,
      label: 'Delete',
      explanation: '',
    );

    Future<void> backUp(CourseEditorService editor, Course course) =>
        editor.backupService.createBackup(
          course,
          backedUpAt: DateTime.utc(2026, 10, 11, 10),
          reason: 'Pre-change Course Editor transaction backup',
        );

    Future<void> complete(String courseId) => ProgressService().completeRound(
      'round-1',
      courseId: courseId,
      courseCode: 'IT',
    );

    test('says who has a Course and who kept progress on it', () async {
      final editor = CourseEditorService();
      final course = _course('shared');
      await editor.installImportedCustomCourse(course);
      await backUp(editor, course);
      await as(_bob, () => CourseLibraryService().add(course));
      await as(_carla, () async {
        await CourseLibraryService().add(course);
        await complete('shared');
        await CourseLibraryService().remove(course);
      });
      await setPin();
      final actions = InventoryActionService(profiles: profiles);

      final preview = (await actions.previewCourse(
        deleteCourse('shared'),
        actorProfileId: _alice,
      ))!;

      expect(preview.haveIt, 'Bob and you have this Course in your courses.');
      expect(
        preview.keptIt,
        'Carla removed it from their courses but kept their progress on it.',
      );
      expect(preview.backups.versions, 1);
      expect(preview.publisher, isFalse);
      expect(preview.unopenable, isFalse);
      // Only a Course has this preview.
      expect(
        await actions.previewCourse(
          const InventoryAction(
            InventoryActionKind.deleteFile,
            'anything',
            label: 'Delete',
            explanation: '',
          ),
          actorProfileId: _alice,
        ),
        isNull,
      );

      InventoryCoursePreview with_(
        List<String> others, {
        bool you = false,
        List<String> kept = const [],
      }) => InventoryCoursePreview(
        courseId: 'x',
        publisher: false,
        unopenable: false,
        inCourses: others,
        includesYou: you,
        keptProgress: kept,
        backups: CourseBackupsSummary.none,
      );
      expect(with_(const []).haveIt, isNull);
      expect(with_(const []).keptIt, isNull);
      expect(
        with_(const [], you: true).haveIt,
        'You have this Course in your courses.',
      );
      expect(
        with_(const ['Anna']).haveIt,
        'Anna has this Course in their courses.',
      );
      expect(
        with_(const ['Anna', 'Marco']).haveIt,
        'Anna and Marco have this Course in their courses.',
      );
      expect(
        with_(const ['Anna', 'Marco'], you: true).haveIt,
        'Anna, Marco and you have this Course in your courses.',
      );
      expect(
        with_(const [], kept: const ['Carla', 'Dino']).keptIt,
        'Carla and Dino removed it from their courses but kept their '
        'progress on it.',
      );
    });

    test(
      'Delete resets everyone\'s progress and the backups when asked',
      () async {
        final editor = CourseEditorService();
        final course = _course('shared');
        final other = _course('other', title: 'Another course');
        await editor.installImportedCustomCourse(course);
        await editor.installImportedCustomCourse(other);
        await backUp(editor, course);
        await backUp(editor, other);
        await complete('shared');
        await XpService().addXp(40, courseCode: 'IT', courseId: 'shared');
        await as(_bob, () async {
          await CourseLibraryService().add(course);
          await complete('shared');
          await complete('other');
        });
        await as(_carla, () async {
          await CourseLibraryService().add(course);
          await complete('shared');
          // Carla removed it from her courses and kept her progress.
          await CourseLibraryService().remove(course);
        });
        await setPin();
        final actions = InventoryActionService(profiles: profiles);
        final progress = ProgressService();
        Future<String?> run({String pin = _pin}) => actions.run(
          deleteCourse('shared'),
          actorProfileId: _alice,
          pin: pin,
          resetEveryonesProgress: true,
          deleteBackups: true,
        );

        // A wrong PIN changes nothing.
        await expectLater(
          run(pin: '0000'),
          throwsA(isA<InventoryActionException>()),
        );
        expect((await editor.listUserCourses()).length, 2);
        expect(await progress.hasCourseProgress(_bob, 'shared'), isTrue);
        expect((await editor.backupService.summaryOf('shared')).versions, 1);

        expect(await run(), isNull);

        expect((await editor.listUserCourses()).map((c) => c.courseId), [
          'other',
        ]);
        for (final learner in [_alice, _bob, _carla]) {
          expect(
            await progress.hasCourseProgress(learner, 'shared'),
            isFalse,
            reason: learner,
          );
        }
        // The other Course, XP and its backups stay.
        expect(await progress.hasCourseProgress(_bob, 'other'), isTrue);
        expect(await XpService().getXp(courseCode: 'IT'), 40);
        expect(
          (await editor.backupService.summaryOf('shared')).isEmpty,
          isTrue,
        );
        expect((await editor.backupService.summaryOf('other')).versions, 1);
      },
    );

    test('without the options progress and backups stay', () async {
      final editor = CourseEditorService();
      final course = _course('shared');
      await editor.installImportedCustomCourse(course);
      await backUp(editor, course);
      await complete('shared');
      await setPin();

      await InventoryActionService(
        profiles: profiles,
      ).run(deleteCourse('shared'), actorProfileId: _alice, pin: _pin);

      expect(await editor.listUserCourses(), isEmpty);
      expect(
        await ProgressService().hasCourseProgress(_alice, 'shared'),
        isTrue,
      );
      expect((await editor.backupService.summaryOf('shared')).versions, 1);
    });

    test('a refused Delete resets nothing', () async {
      final editor = CourseEditorService();
      // Bob's Course: the admin is neither its Maintainer nor in its Team.
      final course = _course('bobs', maintainer: _bob);
      await as(_bob, () async {
        await editor.installImportedCustomCourse(course);
        await complete('bobs');
      });
      await backUp(editor, course);
      await setPin();

      await expectLater(
        InventoryActionService(profiles: profiles).run(
          deleteCourse('bobs'),
          actorProfileId: _alice,
          pin: _pin,
          resetEveryonesProgress: true,
          deleteBackups: true,
        ),
        throwsA(isA<InventoryActionException>()),
      );

      expect((await editor.listUserCourses()).single.courseId, 'bobs');
      expect(await ProgressService().hasCourseProgress(_bob, 'bobs'), isTrue);
      expect((await editor.backupService.summaryOf('bobs')).versions, 1);
    });

    test('the options go with a Course only', () async {
      await setPin();
      final file = File(
        '${testSupportDirectory.path}${Platform.pathSeparator}stray.txt',
      )..writeAsStringSync('x');

      await expectLater(
        InventoryActionService(profiles: profiles).run(
          InventoryAction(
            InventoryActionKind.deleteFile,
            file.path,
            label: 'Delete',
            explanation: '',
          ),
          actorProfileId: _alice,
          pin: _pin,
          deleteBackups: true,
        ),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            'Progress and backups go with a Course only.',
          ),
        ),
      );
      expect(file.existsSync(), isTrue);
    });

    test(
      'a Publisher Course keeps everything unless the admin says so',
      () async {
        final publisher = Course.fromJson(
          jsonDecode(
                File(
                  'test/fixtures/publishers/dummy-signed-v1.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>,
        );
        final id = publisher.courseId;
        final editor = CourseEditorService(
          publisherVerification: fixtureVerifier(
            publisher.publisherId,
            publisher.publisherName,
          ),
        );
        await editor.installExternalOfficialUpdate(publisher);
        await backUp(editor, publisher);
        await as(_bob, () async {
          await CourseLibraryService().add(publisher);
          await complete(id);
          // Bob removed it and kept his progress for a reinstallation.
          await CourseLibraryService().remove(publisher);
        });
        await setPin();
        final prefs = await SharedPreferences.getInstance();
        final carlaHasIt = profiles.keyForProfileId(
          _carla,
          '${CourseLibraryService.keyPrefix}${Uri.encodeComponent(id)}',
        );
        final actions = InventoryActionService(
          profiles: profiles,
          courses: editor,
        );
        final remove = InventoryAction(
          InventoryActionKind.deletePublisherCourse,
          id,
          label: 'Delete',
          explanation: '',
        );
        Future<String?> run() => actions.run(
          remove,
          actorProfileId: _alice,
          pin: _pin,
          resetEveryonesProgress: true,
          deleteBackups: true,
        );

        final preview = (await actions.previewCourse(
          remove,
          actorProfileId: _alice,
        ))!;
        expect(preview.publisher, isTrue);
        expect(preview.haveIt, 'You have this Course in your courses.');
        expect(
          preview.keptIt,
          'Bob removed it from their courses but kept their progress on it.',
        );

        // While another learner has it in their courses the removal is
        // refused, and then nothing is reset or deleted.
        await prefs.setBool(carlaHasIt, true);
        await expectLater(run(), throwsA(isA<InventoryActionException>()));
        expect((await editor.listUserCourses()).single.courseId, id);
        expect(await ProgressService().hasCourseProgress(_bob, id), isTrue);
        expect((await editor.backupService.summaryOf(id)).versions, 1);

        await prefs.setBool(carlaHasIt, false);
        expect(await run(), isNull);
        expect(await editor.listUserCourses(), isEmpty);
        expect(await ProgressService().hasCourseProgress(_bob, id), isFalse);
        expect((await editor.backupService.summaryOf(id)).isEmpty, isTrue);
      },
    );

    testWidgets('the dialog names the learners and asks again before a reset', (
      tester,
    ) async {
      final editor = CourseEditorService();
      final course = _course('shared');
      await tester.runAsync(() async {
        await editor.installImportedCustomCourse(course);
        await backUp(editor, course);
        await as(_bob, () async {
          await CourseLibraryService().add(course);
          await complete('shared');
        });
        await setPin();
      });
      FolderOpener.available = () => false;
      addTearDown(() => FolderOpener.available = () => true);
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(profileService: profiles)),
      );
      final delete = find.byKey(
        const Key('inventory-Custom and installed courses-0-action'),
      );
      await tester.pumpUntilFileIoState(() => delete.evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('inventory-course-learners'))
            .evaluate()
            .isNotEmpty,
      );

      expect(
        find.text('Bob and you have this Course in your courses.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 saved version in Backups/Courses ('),
        findsOneWidget,
      );
      CheckboxListTile box(String key) =>
          tester.widget<CheckboxListTile>(find.byKey(Key(key)));
      expect(box('inventory-course-reset-progress').value, isFalse);
      expect(box('inventory-course-delete-backups').value, isFalse);
      await tester.tap(
        find.byKey(const Key('inventory-course-reset-progress')),
      );
      await tester.tap(
        find.byKey(const Key('inventory-course-delete-backups')),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('inventory-action-pin')),
        _pin,
      );

      // Resetting everyone's progress is confirmed once more.
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-course-reset-confirm')),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep their progress'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-action-dialog')), findsOneWidget);
      expect(
        (await tester.runAsync(editor.listUserCourses))!.single.courseId,
        'shared',
      );

      await tester.tap(find.byKey(const Key('inventory-action-run')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('inventory-course-reset-confirm-run')),
      );
      // The message stays a few seconds, so it is looked for while the
      // files are being written and the list read again.
      final message = find.textContaining(
        'Everyone\'s progress on it was reset. Its backups were deleted.',
      );
      for (var i = 0; i < 300 && message.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(message, findsOneWidget);
      expect(find.byKey(const Key('inventory-action-dialog')), findsNothing);
      await tester.runAsync(() async {
        expect(await editor.listUserCourses(), isEmpty);
        expect(
          await ProgressService().hasCourseProgress(_bob, 'shared'),
          isFalse,
        );
        expect(
          (await editor.backupService.summaryOf('shared')).isEmpty,
          isTrue,
        );
      });
    });

    test('offers the whole folder of a Course no longer here', () async {
      await setPin();
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
      await setPin();
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
