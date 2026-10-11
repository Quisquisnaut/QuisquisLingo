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
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/inventory_action_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';
import 'package:quisquislingo_app/services/stored_course_reader.dart';
import 'package:quisquislingo_app/services/team_service.dart';
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

    // Second follow-up (owner decision of 11 October 2026): the admin can
    // clean up anything, after a warning, the word DELETE and the PIN.
    test(
      'the admin removes a Publisher Course others have, with DELETE',
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
        await as(_bob, () async {
          await CourseLibraryService().add(publisher);
          await complete(id);
        });
        await as(_carla, () => CourseLibraryService().add(publisher));
        await setPin();
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
        Future<String?> run({
          String word = '',
          String pin = _pin,
          bool override = true,
        }) => actions.run(
          remove,
          actorProfileId: _alice,
          pin: pin,
          adminOverride: override,
          typedWord: word,
        );
        Future<void> expectKept() async {
          expect((await editor.listUserCourses()).single.courseId, id);
          expect(await ProgressService().hasCourseProgress(_bob, id), isTrue);
        }

        final preview = (await actions.previewCourse(
          remove,
          actorProfileId: _alice,
        ))!;
        expect(preview.othersBlockRemoval, isTrue);
        expect(preview.others, 'Bob and Carla');
        expect(
          preview.haveIt,
          'Bob, Carla and you have this Course in your courses.',
        );

        // Without the override it is refused, as before.
        await expectLater(
          run(override: false),
          throwsA(isA<InventoryActionException>()),
        );
        await expectKept();
        // The override needs the word, exactly, and the PIN.
        for (final wrong in ['', 'delete', 'DELETE IT', 'REMOVE']) {
          await expectLater(
            run(word: wrong),
            throwsA(
              isA<InventoryActionException>().having(
                (e) => e.message,
                'message',
                contains('Type DELETE in capital letters'),
              ),
            ),
            reason: wrong,
          );
        }
        await expectLater(
          run(word: 'DELETE', pin: '0000'),
          throwsA(isA<InventoryActionException>()),
        );
        await expectKept();

        expect(await run(word: ' DELETE '), isNull);

        expect(await editor.listUserCourses(), isEmpty);
        // Nothing else was asked: their progress stays for a reinstallation.
        expect(await ProgressService().hasCourseProgress(_bob, id), isTrue);
      },
    );

    test('the admin deletes another learner\'s Course, with DELETE', () async {
      final editor = CourseEditorService();
      // Bob's custom Course: the admin is neither its Maintainer nor in its
      // Team.
      final course = _course('bobs', title: 'Bob\'s course', maintainer: _bob);
      await as(_bob, () async {
        await editor.installImportedCustomCourse(course);
        await complete('bobs');
      });
      await backUp(editor, course);
      await setPin();
      final actions = InventoryActionService(profiles: profiles);
      Future<String?> run({String word = '', bool override = true}) =>
          actions.run(
            deleteCourse('bobs'),
            actorProfileId: _alice,
            pin: _pin,
            adminOverride: override,
            typedWord: word,
          );

      final preview = (await actions.previewCourse(
        deleteCourse('bobs'),
        actorProfileId: _alice,
      ))!;
      expect(preview.notYours, isTrue);
      expect(preview.needsOverride, isTrue);
      expect(preview.othersBlockRemoval, isFalse);
      expect(preview.maintainer, 'Bob');
      expect(
        preview.overrideWarning,
        'Bob maintains this Course, not you: deleting it removes their work '
        'from this device. Its saved versions stay in Backups/Courses unless '
        'you tick “Also delete all its backups” below, and the learners\' '
        'progress on it stays unless you tick “Also reset everyone\'s '
        'progress on this Course”.',
      );
      expect(preview.overrideTitle, 'Delete another learner\'s Course?');
      expect(preview.overrideButton, 'Delete it anyway');
      expect(
        preview.overrideQuestion(
          'Bob\'s course',
          resetProgress: false,
          deleteBackups: false,
        ),
        'Bob maintains “Bob\'s course”, not you. Deleting it removes their '
        'work from this device. Its saved versions stay in Backups/Courses. '
        'To delete them too, choose Keep the Course and tick “Also delete '
        'all its backups”. The learners\' progress on it stays. To reset it '
        'too, choose Keep the Course and tick “Also reset everyone\'s '
        'progress on this Course”. This cannot be undone.',
      );
      expect(
        preview.overrideQuestion(
          'Bob\'s course',
          resetProgress: true,
          deleteBackups: true,
        ),
        allOf(
          contains('Its backups will be deleted too, as you chose'),
          contains('progress on it will be reset too, as you chose'),
        ),
      );
      // The admin's own Course needs no override.
      final own = _course('mine');
      await editor.installImportedCustomCourse(own);
      final ownPreview = (await actions.previewCourse(
        deleteCourse('mine'),
        actorProfileId: _alice,
      ))!;
      expect(ownPreview.needsOverride, isFalse);
      expect(ownPreview.overrideWarning, isNull);

      // Without the override it is refused, as before; with it, the word.
      await expectLater(
        run(override: false),
        throwsA(isA<InventoryActionException>()),
      );
      await expectLater(
        run(word: 'delete'),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            contains('Type DELETE in capital letters'),
          ),
        ),
      );
      expect(
        (await editor.listUserCourses()).map((c) => c.courseId),
        contains('bobs'),
      );

      expect(await run(word: 'DELETE'), isNull);

      expect((await editor.listUserCourses()).map((c) => c.courseId), ['mine']);
      // Nothing else was asked: backups and progress stay.
      expect((await editor.backupService.summaryOf('bobs')).versions, 1);
      expect(await ProgressService().hasCourseProgress(_bob, 'bobs'), isTrue);
    });

    test('a learner who is not an admin cannot force a Delete', () async {
      final editor = CourseEditorService();
      final course = _course('mine');
      await editor.installImportedCustomCourse(course);
      // Bob tries the service's override on Alice's Course.
      await profiles.setActiveProfileById(_bob);
      await expectLater(
        editor.deleteUserCourse('mine', adminOverride: true),
        throwsA(isA<StateError>()),
      );
      await profiles.setActiveProfileById(_alice);
      expect((await editor.listUserCourses()).single.courseId, 'mine');
    });

    test('only the Delete of a Course can be forced', () async {
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
          adminOverride: true,
          typedWord: 'DELETE',
        ),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            'Only the Delete of a Course, of a learner or of a Team can be '
                'forced here.',
          ),
        ),
      );
      expect(file.existsSync(), isTrue);
    });

    test(
      'progress left by Courses no longer here is listed and reset',
      () async {
        final editor = CourseEditorService();
        final course = _course('gone');
        final kept = _course('kept', title: 'Still here');
        await editor.installImportedCustomCourse(course);
        await editor.installImportedCustomCourse(kept);
        await complete('gone');
        await complete('kept');
        // A bundled Course is on this device.
        await complete(CourseService.bundledCourseIds.first);
        await XpService().addXp(40, courseCode: 'IT', courseId: 'gone');
        await as(_bob, () async {
          await ProgressService().recordRecentRound(
            'gone',
            'lesson-1',
            'round-2',
            errors: 0,
          );
          await complete('never-here');
        });
        await setPin();
        final progress = ProgressService();
        expect(await progress.courseIdsWithProgress(_alice), {
          'gone',
          'kept',
          CourseService.bundledCourseIds.first,
        });
        expect(await progress.courseIdsWithProgress(_bob), {
          'gone',
          'never-here',
        });
        InventorySection left(List<InventorySection> sections) =>
            sections.firstWhere(
              (section) =>
                  section.title ==
                  'Progress on Courses no longer on this device',
            );
        final actions = InventoryActionService(profiles: profiles);

        // While the Course is here its progress is not listed.
        var section = left(await InventoryService(profiles: profiles).load());
        expect(section.items.map((item) => item.name), [
          'Course ID never-here',
        ]);
        // And the Reset refuses a Course that is on this device.
        await expectLater(
          actions.run(
            const InventoryAction(
              InventoryActionKind.resetCourseProgress,
              'kept',
              label: 'Reset',
              explanation: '',
            ),
            actorProfileId: _alice,
            pin: _pin,
          ),
          throwsA(
            isA<InventoryActionException>().having(
              (e) => e.message,
              'message',
              contains('This Course is on this device again'),
            ),
          ),
        );
        expect(await progress.hasCourseProgress(_alice, 'kept'), isTrue);

        // The Course is deleted without the reset: its progress stays, and is
        // now listed with the learners who have it.
        await actions.run(
          deleteCourse('gone'),
          actorProfileId: _alice,
          pin: _pin,
        );
        section = left(await InventoryService(profiles: profiles).load());
        expect(section.items.map((item) => item.name), [
          'Course ID gone',
          'Course ID never-here',
        ]);
        final gone = section.items.first;
        expect(gone.note, 'Progress kept by: Alice, Bob.');
        expect(gone.action!.kind, InventoryActionKind.resetCourseProgress);
        expect(gone.action!.label, 'Reset');
        expect(gone.action!.target, 'gone');

        await expectLater(
          actions.run(gone.action!, actorProfileId: _alice, pin: '0000'),
          throwsA(isA<InventoryActionException>()),
        );
        expect(await progress.hasCourseProgress(_bob, 'gone'), isTrue);

        await actions.run(gone.action!, actorProfileId: _alice, pin: _pin);

        expect(await progress.hasCourseProgress(_alice, 'gone'), isFalse);
        expect(await progress.hasCourseProgress(_bob, 'gone'), isFalse);
        // Everything else stays: the other Courses' progress, XP.
        expect(await progress.hasCourseProgress(_alice, 'kept'), isTrue);
        expect(await progress.hasCourseProgress(_bob, 'never-here'), isTrue);
        expect(await XpService().getXp(courseCode: 'IT'), 40);
        section = left(await InventoryService(profiles: profiles).load());
        expect(section.items.map((item) => item.name), [
          'Course ID never-here',
        ]);
      },
    );

    test('the Courses that come with the app are known by their IDs', () {
      final ids = {
        for (final asset in CourseService.courseAssets.values)
          (jsonDecode(File(asset).readAsStringSync()) as Map)['courseId'],
      };
      expect(CourseService.bundledCourseIds, ids);
    });

    testWidgets(
      'another learner\'s Course asks for DELETE and says whose it is',
      (tester) async {
        final editor = CourseEditorService();
        final course = _course(
          'bobs',
          title: 'Bob\'s course',
          maintainer: _bob,
        );
        await tester.runAsync(() async {
          await as(_bob, () => editor.installImportedCustomCourse(course));
          await backUp(editor, course);
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
        const warning = Key('inventory-course-override-warning');
        await tester.pumpUntilFileIoState(
          () => find.byKey(warning).evaluate().isNotEmpty,
        );

        // 1. The warning and the choices: no PIN and no word yet.
        expect(
          tester.widget<Text>(find.byKey(warning)).data,
          startsWith('Bob maintains this Course, not you'),
        );
        const pinField = Key('inventory-action-pin');
        const wordField = Key('inventory-action-word');
        expect(find.byKey(pinField), findsNothing);
        expect(find.byKey(wordField), findsNothing);
        await tester.tap(
          find.byKey(const Key('inventory-course-delete-backups')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('inventory-action-continue')));
        await tester.pumpAndSettle();

        expect(find.text('Delete another learner\'s Course?'), findsOneWidget);
        expect(
          find.textContaining('Its backups will be deleted too, as you chose'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'The learners\' progress on it stays. To reset it too, choose Keep '
            'the Course and tick',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Delete it anyway'));
        await tester.pumpAndSettle();

        // 2. The PIN, then 3. the word DELETE.
        const pinDialog = Key('inventory-action-pin-dialog');
        expect(find.byKey(pinDialog), findsOneWidget);
        expect(find.byKey(const Key('inventory-action-dialog')), findsNothing);
        expect(
          find.text('Then, to delete it anyway, type DELETE.'),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(find.byKey(wordField)).dy,
          greaterThan(tester.getTopLeft(find.byKey(pinField)).dy),
          reason: 'the word is typed after the PIN',
        );
        await tester.enterText(find.byKey(pinField), _pin);
        await tester.enterText(find.byKey(wordField), 'DELETE');
        await tester.tap(find.byKey(const Key('inventory-action-run')));
        await tester.pumpUntilFileIoState(
          () => find.byKey(pinDialog).evaluate().isEmpty,
        );
        await tester.runAsync(() async {
          expect(await editor.listUserCourses(), isEmpty);
          expect(
            (await editor.backupService.summaryOf('bobs')).isEmpty,
            isTrue,
          );
        });
      },
    );

    testWidgets('the override asks for DELETE, then confirms once more', (
      tester,
    ) async {
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
      await tester.runAsync(() async {
        await editor.installExternalOfficialUpdate(publisher);
        await as(_bob, () async {
          await CourseLibraryService().add(publisher);
          await complete(id);
        });
        await setPin();
      });
      FolderOpener.available = () => false;
      addTearDown(() => FolderOpener.available = () => true);
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryScreen(
            profileService: profiles,
            actionService: InventoryActionService(
              profiles: profiles,
              courses: editor,
            ),
          ),
        ),
      );
      final delete = find.byKey(
        const Key('inventory-Custom and installed courses-0-action'),
      );
      await tester.pumpUntilFileIoState(() => delete.evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      const warningKey = Key('inventory-course-override-warning');
      await tester.pumpUntilFileIoState(
        () => find.byKey(warningKey).evaluate().isNotEmpty,
      );

      expect(
        find.text('Bob and you have this Course in your courses.'),
        findsOneWidget,
      );
      // 1. The warning says what they lose and where their progress is
      // reset; the PIN and the word come afterwards.
      final warning = tester.widget<Text>(find.byKey(warningKey)).data!;
      expect(warning, contains('takes it out of their courses'));
      expect(
        warning,
        contains(
          'to reset it too, tick “Also reset everyone\'s progress on this '
          'Course” below',
        ),
      );
      const pinDialog = Key('inventory-action-pin-dialog');
      const pinField = Key('inventory-action-pin');
      expect(find.byKey(pinField), findsNothing);

      // A second confirmation says where the progress goes; Keep the Course
      // goes back to the choices.
      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-override-confirm')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'The learners\' progress on it stays. To reset it too, choose '
          'Keep the Course and tick “Also reset everyone\'s progress on '
          'this Course”.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep the Course'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-action-dialog')), findsOneWidget);
      expect(find.byKey(pinDialog), findsNothing);
      expect(
        (await tester.runAsync(editor.listUserCourses))!.single.courseId,
        id,
      );

      // Ticked, the second confirmation says so, and the reset is confirmed.
      await tester.tap(
        find.byKey(const Key('inventory-course-reset-progress')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('progress on it will be reset too, as you chose'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('inventory-override-confirm-run')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-course-reset-confirm')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('inventory-course-reset-confirm-run')),
      );
      await tester.pumpAndSettle();

      // 2. The PIN, then 3. the word: without the word nothing happens,
      // whatever the PIN.
      expect(find.byKey(pinDialog), findsOneWidget);
      expect(
        find.text('Then, to remove it anyway, type DELETE.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(pinField), _pin);
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('inventory-action-error')))
            .data,
        contains('Type DELETE in capital letters'),
      );
      expect(
        (await tester.runAsync(editor.listUserCourses))!.single.courseId,
        id,
      );
      await tester.enterText(
        find.byKey(const Key('inventory-action-word')),
        'DELETE',
      );
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      final message = find.textContaining(
        'Everyone\'s progress on it was reset.',
      );
      for (var i = 0; i < 300 && message.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(message, findsOneWidget);
      await tester.runAsync(() async {
        expect(await editor.listUserCourses(), isEmpty);
        expect(await ProgressService().hasCourseProgress(_bob, id), isFalse);
      });
    });

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

      // Resetting everyone's progress is confirmed once more, before the
      // PIN is asked.
      const pinDialog = Key('inventory-action-pin-dialog');
      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-course-reset-confirm')),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep their progress'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-action-dialog')), findsOneWidget);
      expect(find.byKey(pinDialog), findsNothing);
      expect(
        (await tester.runAsync(editor.listUserCourses))!.single.courseId,
        'shared',
      );

      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('inventory-course-reset-confirm-run')),
      );
      await tester.pumpAndSettle();
      // Nothing the service refuses: the PIN alone, no word.
      expect(find.byKey(pinDialog), findsOneWidget);
      expect(find.byKey(const Key('inventory-action-word')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('inventory-action-pin')),
        _pin,
      );
      await tester.tap(find.byKey(const Key('inventory-action-run')));
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

    // Build 271 Revision 2 follow-up (owner decision of 11 October 2026):
    // the admin may delete a learner who maintains Courses, after the
    // warning, the word DELETE, a second confirmation and the PIN. Their
    // Courses stay on the device without a Maintainer.
    InventoryAction deleteLearner(String id) => InventoryAction(
      InventoryActionKind.deleteLearner,
      id,
      label: 'Delete',
      explanation: '',
    );

    Future<void> bobMaintainsTwo(CourseEditorService editor) => as(
      _bob,
      () async {
        await editor.installImportedCustomCourse(
          _course('bobs', title: 'Verbi', maintainer: _bob),
        );
        await editor.installImportedCustomCourse(
          _course('secret', title: 'Segreto', maintainer: _bob, private: true),
        );
        await complete('bobs');
      },
    );

    test('the admin deletes a learner who maintains Courses, with DELETE; '
        'the Courses stay without a Maintainer', () async {
      final editor = CourseEditorService();
      await bobMaintainsTwo(editor);
      await editor.installImportedCustomCourse(_course('mine'));
      await setPin();
      final actions = InventoryActionService(profiles: profiles);
      Future<String?> run({
        String word = '',
        bool override = true,
        String pin = _pin,
      }) => actions.run(
        deleteLearner(_bob),
        actorProfileId: _alice,
        pin: pin,
        adminOverride: override,
        typedWord: word,
      );

      final preview = (await actions.previewLearner(deleteLearner(_bob)))!;
      expect(preview.name, 'Bob');
      expect(preview.needsOverride, isTrue);
      expect(
        preview.maintained.map((course) => course.courseId),
        unorderedEquals(['bobs', 'secret']),
      );
      expect(
        preview.overrideWarning,
        allOf(
          startsWith('Bob maintains '),
          contains('“Verbi”'),
          contains('“Segreto” (a Private course)'),
          contains(
            'Deleting Bob leaves these Courses on this device without a '
            'Maintainer.',
          ),
          contains(
            'Without a Maintainer, a Course can be edited only by the '
            'members of a Team already assigned to it, nobody can change '
            'its Maintainer or its Team, and a Private course is seen only '
            'by that Team.',
          ),
          contains(
            'These Courses stay under Custom and installed courses in this '
            'Inventory, where you can delete them.',
          ),
          contains(
            'Bob can first change the Course Maintainer in Course Info '
            'Editor.',
          ),
        ),
      );
      expect(preview.overrideTitle, 'Delete a learner who maintains Courses?');
      expect(
        preview.overrideQuestion,
        allOf(
          contains(
            'These Courses will stay on this device without a Maintainer.',
          ),
          contains('Bob\'s progress and settings will be deleted.'),
          endsWith('This cannot be undone.'),
        ),
      );

      // A learner who maintains nothing needs no warning and no word.
      final carla = (await actions.previewLearner(deleteLearner(_carla)))!;
      expect(carla.needsOverride, isFalse);
      expect(carla.overrideWarning, isNull);
      expect(await actions.previewLearner(deleteCourse('mine')), isNull);

      // Without the override the Delete is refused as before, and the
      // refusal says where an admin can go on.
      await expectLater(
        run(override: false),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('This profile maintains'),
              contains(
                'An admin can delete the profile anyway in Advanced '
                '(Admin) › Inventory, after a warning.',
              ),
            ),
          ),
        ),
      );
      for (final word in ['', 'delete', 'DELETE BOB']) {
        await expectLater(
          run(word: word),
          throwsA(isA<InventoryActionException>()),
          reason: 'word "$word"',
        );
      }
      await expectLater(
        run(word: 'DELETE', pin: '0000'),
        throwsA(isA<InventoryActionException>()),
      );
      expect(await profiles.getProfileById(_bob), isNotNull);

      expect(await run(word: 'DELETE'), isNull);
      expect(await profiles.getProfileById(_bob), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where(
          (key) => key.startsWith(ProfileService.prefixForProfileId(_bob)),
        ),
        isEmpty,
        reason: 'his progress and settings went with him',
      );
      // His Courses stay, still naming him; the others are untouched.
      final stored = {
        for (final entry in (await CourseFileStore().readAll(
          CourseStoreKind.custom,
        )).entries)
          StoredCourseReader.open(
            entry.key,
            entry.value,
          ).course!.courseId: StoredCourseReader.open(
            entry.key,
            entry.value,
          ).course!.maintainer!.profileId,
      };
      expect(stored, {'bobs': _bob, 'secret': _bob, 'mine': _alice});
      expect(await profiles.getProfileById(_carla), isNotNull);

      // The Inventory still deletes such a Course, with its own override.
      final orphan = (await actions.previewCourse(
        deleteCourse('bobs'),
        actorProfileId: _alice,
      ))!;
      expect(orphan.notYours, isTrue);
      expect(orphan.maintainer, 'A learner no longer on this device');
      await actions.run(
        deleteCourse('bobs'),
        actorProfileId: _alice,
        pin: _pin,
        adminOverride: true,
        typedWord: 'DELETE',
      );
      expect(
        (await CourseFileStore().readAll(CourseStoreKind.custom)).length,
        2,
      );
    });

    test('only an admin can force it, and the other rules stay', () async {
      final editor = CourseEditorService();
      await bobMaintainsTwo(editor);
      await editor.installImportedCustomCourse(_course('mine'));
      // Bob may delete his own profile, but not while he maintains Courses,
      // and the override is the admin's.
      await expectLater(
        profiles.deleteProfileById(
          _bob,
          actorProfileId: _bob,
          adminOverride: true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Only an admin may delete a learner who maintains Courses.',
          ),
        ),
      );
      await expectLater(
        profiles.deleteProfileById(
          _bob,
          actorProfileId: _carla,
          adminOverride: true,
        ),
        throwsA(isA<StateError>()),
      );
      // The only admin stays, override or not.
      await expectLater(
        profiles.deleteProfileById(
          _alice,
          actorProfileId: _alice,
          adminOverride: true,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'QQL must always have at least one admin.',
          ),
        ),
      );
      expect(await profiles.getProfileById(_bob), isNotNull);
      expect(await profiles.getProfileById(_alice), isNotNull);
    });

    test('a stored file nobody can read: the admin is told and may go '
        'ahead', () async {
      final editor = CourseEditorService();
      await editor.installImportedCustomCourse(_course('mine'));
      final folder = Directory(
        '${testSupportDirectory.path}${Platform.pathSeparator}'
        '${CourseFileStore.rootDirectoryName}${Platform.pathSeparator}'
        '${CourseStoreKind.custom.directoryName}',
      );
      File(
        '${folder.path}${Platform.pathSeparator}QQL_EN_IT_broken.json',
      ).writeAsStringSync('{ this is not a Course record');
      await setPin();
      final actions = InventoryActionService(profiles: profiles);
      final preview = (await actions.previewLearner(deleteLearner(_carla)))!;
      expect(preview.maintained, isEmpty);
      expect(preview.unknown, isTrue);
      expect(preview.needsOverride, isTrue);
      expect(
        preview.overrideWarning,
        'A stored Course file cannot be read, so QQL cannot tell whether '
        'Carla maintains it. If so, deleting Carla leaves that Course on '
        'this device without a Maintainer.',
      );
      expect(preview.overrideTitle, 'Delete this learner anyway?');
      await expectLater(
        actions.run(deleteLearner(_carla), actorProfileId: _alice, pin: _pin),
        throwsA(isA<InventoryActionException>()),
      );
      await actions.run(
        deleteLearner(_carla),
        actorProfileId: _alice,
        pin: _pin,
        adminOverride: true,
        typedWord: 'DELETE',
      );
      expect(await profiles.getProfileById(_carla), isNull);
    });

    testWidgets('the dialog warns about the Courses, asks for DELETE and '
        'confirms once more', (tester) async {
      final editor = CourseEditorService();
      await tester.runAsync(() async {
        await bobMaintainsTwo(editor);
        await setPin();
      });
      FolderOpener.available = () => false;
      addTearDown(() => FolderOpener.available = () => true);
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: InventoryScreen(
            profileService: profiles,
            actionService: InventoryActionService(
              profiles: profiles,
              courses: editor,
            ),
          ),
        ),
      );
      // Alice, Bob, Carla: Bob is the second learner.
      final delete = find.byKey(const Key('inventory-Learners-1-action'));
      await tester.pumpUntilFileIoState(() => delete.evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      const warningKey = Key('inventory-learner-override-warning');
      await tester.pumpUntilFileIoState(
        () => find.byKey(warningKey).evaluate().isNotEmpty,
      );
      final warning = tester.widget<Text>(find.byKey(warningKey)).data!;
      expect(warning, contains('Bob maintains'));
      expect(warning, contains('without a Maintainer'));
      const pinDialog = Key('inventory-action-pin-dialog');
      const pinField = Key('inventory-action-pin');
      expect(find.byKey(pinField), findsNothing);

      // 1. The warning, then a second confirmation; Keep the learner goes
      // back to it.
      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('inventory-override-confirm')),
        findsOneWidget,
      );
      expect(
        find.text('Delete a learner who maintains Courses?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep the learner'));
      await tester.pumpAndSettle();
      expect(find.byKey(pinDialog), findsNothing);
      expect(
        await tester.runAsync(() => profiles.getProfileById(_bob)),
        isNotNull,
      );

      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-override-confirm-run')));
      await tester.pumpAndSettle();

      // 2. The PIN, then 3. the word DELETE: without it nothing happens.
      expect(find.byKey(pinDialog), findsOneWidget);
      expect(
        find.text('Then, to delete Bob anyway, type DELETE.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(pinField), _pin);
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('inventory-action-error')))
            .data,
        contains('Type DELETE in capital letters'),
      );
      expect(
        await tester.runAsync(() => profiles.getProfileById(_bob)),
        isNotNull,
      );
      await tester.enterText(
        find.byKey(const Key('inventory-action-word')),
        'DELETE',
      );
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      final message = find.textContaining('Delete: “Bob” done.');
      for (var i = 0; i < 300 && message.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(message, findsOneWidget);
      await tester.runAsync(() async {
        expect(await profiles.getProfileById(_bob), isNull);
        expect(
          (await CourseFileStore().readAll(CourseStoreKind.custom)).length,
          2,
          reason: 'his two Courses stay on the device',
        );
      });
    });

    // Build 271 Revision 2 second follow-up (owner decisions of 11 October
    // 2026): the admin may delete the last Team Leader of a Team (the member
    // added first takes over; a Team with nobody left goes) and may delete a
    // Team, both with the usual strong warning: a second confirmation, the
    // PIN, then the word DELETE.
    InventoryAction deleteTeam(String teamId) => InventoryAction(
      InventoryActionKind.deleteTeam,
      teamId,
      label: 'Delete',
      explanation: '',
    );

    test('a Team without one of its members: the first other member leads '
        'when its last Team Leader goes', () async {
      final teams = TeamService(profileService: profiles);
      final team = await teams.createTeam(
        creatorProfileId: _bob,
        displayName: 'Editors',
      );
      final three = await teams.addMember(
        teamId: team.teamId,
        actorProfileId: _bob,
        memberProfileId: _carla,
      );
      final all = await teams.addMember(
        teamId: three.teamId,
        actorProfileId: _bob,
        memberProfileId: _alice,
      );
      expect(all.isLastLead(_bob), isTrue);
      expect(all.isLastLead(_carla), isFalse);
      expect(all.successorOf(_bob), _carla, reason: 'Carla was added first');
      expect(all.successorOf(_carla), isNull);
      final withoutBob = all.without(_bob)!;
      expect(withoutBob.memberProfileIds, [_carla, _alice]);
      expect(withoutBob.leadProfileIds, [_carla]);
      // A member who is not its last Team Leader just leaves.
      final withoutCarla = all.without(_carla)!;
      expect(withoutCarla.memberProfileIds, [_bob, _alice]);
      expect(withoutCarla.leadProfileIds, [_bob]);
      // Nobody left: no Team.
      expect(team.without(_bob), isNull);
      expect(team.successorOf(_bob), isNull);
    });

    test('the admin deletes the last Team Leader, with DELETE; the Team '
        'gets a new one, or goes when nobody is left', () async {
      final teams = TeamService(profileService: profiles);
      final editors = await teams.createTeam(
        creatorProfileId: _bob,
        displayName: 'Editors',
      );
      await teams.addMember(
        teamId: editors.teamId,
        actorProfileId: _bob,
        memberProfileId: _carla,
      );
      final solo = await teams.createTeam(
        creatorProfileId: _bob,
        displayName: 'Solo',
      );
      await setPin();
      final actions = InventoryActionService(profiles: profiles);
      final delete = InventoryAction(
        InventoryActionKind.deleteLearner,
        _bob,
        label: 'Delete',
        explanation: '',
      );

      final preview = (await actions.previewLearner(delete))!;
      expect(preview.maintained, isEmpty);
      expect(preview.needsOverride, isTrue);
      expect(
        {for (final team in preview.teams) team.name: team.successor},
        {'Editors': 'Carla', 'Solo': null},
      );
      expect(
        preview.overrideWarning,
        allOf(
          contains(
            'Bob is the last Team Leader of “Editors”: Carla, the member '
            'who was added first, becomes its Team Leader.',
          ),
          contains(
            'Bob is the only member of the Team “Solo”: the Team is '
            'removed, and the Courses assigned to it are no longer shared '
            'through it.',
          ),
        ),
      );
      expect(preview.overrideTitle, 'Delete the last Team Leader?');
      expect(
        preview.overrideQuestion,
        allOf(
          contains('Carla will become Team Leader of “Editors”.'),
          contains('The Team “Solo” will be removed.'),
          endsWith(
            'Bob\'s progress and settings will be deleted. This cannot be '
            'undone.',
          ),
        ),
      );

      // Refused without the override, with where an admin can go on.
      await expectLater(
        actions.run(delete, actorProfileId: _alice, pin: _pin),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('final Team Leader of'),
              contains('An admin can delete the profile anyway'),
            ),
          ),
        ),
      );
      expect((await teams.listTeams()).length, 2);

      await actions.run(
        delete,
        actorProfileId: _alice,
        pin: _pin,
        adminOverride: true,
        typedWord: 'DELETE',
      );
      expect(await profiles.getProfileById(_bob), isNull);
      final left = await teams.listTeams();
      expect(left.map((team) => team.displayName), ['Editors']);
      expect(left.single.memberProfileIds, [_carla]);
      expect(left.single.leadProfileIds, [_carla]);
      expect(await teams.teamById(solo.teamId), isNull);
    });

    test('the admin deletes a Team, with DELETE; its members and the '
        'Courses assigned to it stay', () async {
      final teams = TeamService(profileService: profiles);
      final team = await teams.createTeam(
        creatorProfileId: _bob,
        displayName: 'Editors',
      );
      await teams.addMember(
        teamId: team.teamId,
        actorProfileId: _bob,
        memberProfileId: _carla,
      );
      final editor = CourseEditorService();
      await as(
        _bob,
        () => editor.installImportedCustomCourse(
          Course.fromJson({
            ..._course('shared', title: 'Verbi', maintainer: _bob).toJson(),
            'assignedTeamId': team.teamId,
          }),
        ),
      );
      await setPin();
      final actions = InventoryActionService(profiles: profiles);

      // The Inventory lists it, with its Delete.
      final section = (await InventoryService(
        profiles: profiles,
      ).load()).firstWhere((section) => section.title == 'Teams');
      final item = section.items.single;
      expect(item.name, 'Editors');
      expect(item.owner, 'Team Leader: Bob');
      expect(item.note, startsWith('2 members · assigned to 1 Course.'));
      expect(item.action!.kind, InventoryActionKind.deleteTeam);
      expect(item.action!.target, team.teamId);

      final preview = (await actions.previewTeam(deleteTeam(team.teamId)))!;
      expect(preview.members, ['Bob', 'Carla']);
      expect(preview.courses, ['Verbi']);
      expect(
        preview.overrideWarning,
        'Deleting this Team cannot be undone. Its members (Bob and Carla) '
        'lose the access it gave them to the Course assigned to it: '
        '“Verbi”. The Courses stay with their Maintainers, who can assign '
        'another Team in Course Info Editor; until then only their '
        'Maintainers can edit them. The learners themselves stay.',
      );
      expect(preview.overrideTitle, 'Delete the Team “Editors”?');
      expect(
        preview.overrideQuestion,
        'The Team “Editors” will be deleted. Its members (Bob and Carla) '
        'lose the access it gave them to the Courses assigned to it; the '
        'Courses stay with their Maintainers. This cannot be undone.',
      );
      expect(await actions.previewTeam(deleteCourse('shared')), isNull);

      // Never without the word, whatever the PIN; never with a wrong PIN.
      await expectLater(
        actions.run(deleteTeam(team.teamId), actorProfileId: _alice, pin: _pin),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            startsWith('A Team is deleted only with the word DELETE'),
          ),
        ),
      );
      for (final word in ['', 'delete', 'DELETE TEAM']) {
        await expectLater(
          actions.run(
            deleteTeam(team.teamId),
            actorProfileId: _alice,
            pin: _pin,
            adminOverride: true,
            typedWord: word,
          ),
          throwsA(isA<InventoryActionException>()),
          reason: 'word "$word"',
        );
      }
      await expectLater(
        actions.run(
          deleteTeam(team.teamId),
          actorProfileId: _alice,
          pin: '0000',
          adminOverride: true,
          typedWord: 'DELETE',
        ),
        throwsA(isA<InventoryActionException>()),
      );
      // Only an admin may, also through the service.
      await expectLater(
        teams.deleteTeamAsAdmin(teamId: team.teamId, actorProfileId: _bob),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Only an admin may delete a Team.',
          ),
        ),
      );
      expect((await teams.listTeams()).single.teamId, team.teamId);

      await actions.run(
        deleteTeam(team.teamId),
        actorProfileId: _alice,
        pin: _pin,
        adminOverride: true,
        typedWord: 'DELETE',
      );
      expect(await teams.listTeams(), isEmpty);
      expect(await profiles.getProfileById(_bob), isNotNull);
      expect(await profiles.getProfileById(_carla), isNotNull);
      final stored = (await CourseFileStore().readAll(
        CourseStoreKind.custom,
      )).entries.single;
      expect(
        StoredCourseReader.open(
          stored.key,
          stored.value,
        ).course!.assignedTeamId,
        team.teamId,
        reason: 'the Course is not rewritten; the ID names no Team now',
      );
      // A Team no Course is assigned to: nobody loses access to a Course.
      final empty = await teams.createTeam(
        creatorProfileId: _carla,
        displayName: 'Readers',
      );
      expect(
        (await actions.previewTeam(deleteTeam(empty.teamId)))!.overrideWarning,
        'Deleting this Team cannot be undone. No Course is assigned to it, '
        'so nobody loses access to a Course. Its only member (Carla) stays '
        'as a learner.',
      );
    });

    testWidgets('deleting a Team: the warning, a second confirmation, the '
        'PIN, then the word DELETE', (tester) async {
      late final String teamId;
      await tester.runAsync(() async {
        final teams = TeamService(profileService: profiles);
        final team = await teams.createTeam(
          creatorProfileId: _bob,
          displayName: 'Editors',
        );
        await teams.addMember(
          teamId: team.teamId,
          actorProfileId: _bob,
          memberProfileId: _carla,
        );
        teamId = team.teamId;
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
      final delete = find.byKey(const Key('inventory-Teams-0-action'));
      await tester.pumpUntilFileIoState(() => delete.evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      const warningKey = Key('inventory-team-override-warning');
      await tester.pumpUntilFileIoState(
        () => find.byKey(warningKey).evaluate().isNotEmpty,
      );

      // 1. The warning; no PIN and no word yet.
      expect(
        tester.widget<Text>(find.byKey(warningKey)).data,
        allOf(
          startsWith('Deleting this Team cannot be undone.'),
          contains('Its members (Bob and Carla) stay as learners.'),
        ),
      );
      const pinDialog = Key('inventory-action-pin-dialog');
      const pinField = Key('inventory-action-pin');
      const wordField = Key('inventory-action-word');
      expect(find.byKey(pinField), findsNothing);
      expect(find.byKey(wordField), findsNothing);

      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Delete the Team “Editors”?'), findsOneWidget);
      await tester.tap(find.text('Keep the Team'));
      await tester.pumpAndSettle();
      expect(find.byKey(pinDialog), findsNothing);

      await tester.tap(find.byKey(const Key('inventory-action-continue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('inventory-override-confirm-run')));
      await tester.pumpAndSettle();

      // 2. The PIN, then 3. the word.
      expect(find.byKey(pinDialog), findsOneWidget);
      expect(
        find.text('Then, to delete the Team, type DELETE.'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.byKey(wordField)).dy,
        greaterThan(tester.getTopLeft(find.byKey(pinField)).dy),
      );
      await tester.enterText(find.byKey(pinField), _pin);
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('inventory-action-error')))
            .data,
        contains('Type DELETE in capital letters'),
      );
      expect(
        (await tester.runAsync(
          () => TeamService(profileService: profiles).listTeams(),
        ))!.single.teamId,
        teamId,
      );
      await tester.enterText(find.byKey(wordField), 'DELETE');
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      final message = find.textContaining('Delete: “Editors” done.');
      for (var i = 0; i < 300 && message.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 1)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(message, findsOneWidget);
      expect(
        await tester.runAsync(
          () => TeamService(profileService: profiles).listTeams(),
        ),
        isEmpty,
      );
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
