import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/exercise_image_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';
import 'package:quisquislingo_app/services/storage/qql_earlier_private_folders.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

/// Build 255 Revision 4: QQL_ names in private storage, and the Course's
/// language pair, source then target, in every per-Course name.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sep = Platform.pathSeparator;

  group('language codes and pairs', () {
    test('the tag wins, then the name table, then the name itself', () {
      expect(CourseStorageNames.languageCode(tag: 'it-IT'), 'IT');
      expect(CourseStorageNames.languageCode(tag: 'nap'), 'NAP');
      expect(CourseStorageNames.languageCode(tag: 'x', name: 'English'), 'EN');
      expect(CourseStorageNames.languageCode(name: 'Neapolitan'), 'NAP');
      expect(CourseStorageNames.languageCode(name: 'Piemontèis'), 'PMS');
      expect(CourseStorageNames.languageCode(name: ' welsh '), 'CY');
      expect(CourseStorageNames.languageCode(name: 'Klingon'), 'KLINGON');
      expect(
        CourseStorageNames.languageCode(name: 'Old High German of the hills'),
        'OLDHIGHGERMANOFT',
      );
      expect(CourseStorageNames.languageCode(name: '  '), 'UNKNOWN');
    });

    test('a pair is source then target', () {
      expect(
        CourseStorageNames.pair(
          sourceLanguage: 'Italian',
          targetLanguage: 'Neapolitan',
        ),
        'IT_NAP',
      );
      expect(
        CourseStorageNames.pair(
          sourceLanguage: 'English',
          targetLanguage: 'Italian',
          targetLanguageTag: 'it-IT',
        ),
        'EN_IT',
      );
      // Without a target language, the learning language names it.
      expect(
        CourseStorageNames.pair(
          sourceLanguage: 'English',
          targetLanguage: '',
          learningLanguage: 'Welsh',
        ),
        'EN_CY',
      );
      expect(
        CourseStorageNames.pairOfJson(const {
          'sourceLanguage': 'Italian',
          'targetLanguage': 'Neapolitan',
          'targetLanguageTag': 'nap-IT',
        }),
        'IT_NAP',
      );
    });
  });

  group('names', () {
    test('stored Course files carry the pair and the ID once', () {
      expect(
        CourseStorageNames.courseFileName('course_ab12', 'EN_IT'),
        'QQL_EN_IT_ab12.json',
      );
      expect(
        CourseStorageNames.courseFileName(
          'quisquislingo.bundled.italian',
          'EN_IT',
        ),
        'QQL_EN_IT_quisquislingo.bundled.italian.json',
      );
      expect(
        CourseStorageNames.courseFileName('a/b c', 'IT_NAP'),
        'QQL_IT_NAP_a_b_c.json',
      );
      expect(
        CourseStorageNames.idPartOfCourseFile('QQL_IT_NAP_ab_12.json'),
        'ab_12',
      );
      expect(CourseStorageNames.idPartOfCourseFile('course_ab.json'), isNull);
    });

    test('media folders end with the ID hash, with or without a pair', () {
      final hash = CourseStorageNames.hashOf('course_ab');
      expect(CourseStorageNames.mediaFolderName('course_ab'), 'QQL_$hash');
      expect(
        CourseStorageNames.mediaFolderName('course_ab', pair: 'EN_IT'),
        'QQL_EN_IT_$hash',
      );
      expect(CourseStorageNames.hashOfMediaFolder('QQL_$hash'), hash);
      expect(CourseStorageNames.hashOfMediaFolder('QQL_EN_IT_$hash'), hash);
      expect(CourseStorageNames.hashOfMediaFolder('course_$hash'), isNull);
    });

    test('backups and exports', () {
      expect(
        CourseStorageNames.backupFolderName('course_ab', 'EN_IT'),
        'QQL_bkp_EN_IT_ab',
      );
      expect(
        CourseStorageNames.idPartOfBackupFolder('QQL_bkp_IT_NAP_ab'),
        'ab',
      );
      expect(
        CourseStorageNames.backupVersionName(
          'course_ab',
          'EN_IT',
          version: '',
          stamp: '20260926T120000000Z',
        ),
        'QQL_bkp_EN_IT_ab_v0_20260926T120000000Z',
      );
      expect(
        CourseStorageNames.backupVersionName(
          'course_ab',
          'EN_IT',
          version: '1.2',
          stamp: 'S',
        ),
        'QQL_bkp_EN_IT_ab_v1.2_S',
      );
      expect(
        CourseStorageNames.exportBaseName(pair: 'EN_IT', title: 'My Course!'),
        'QQL_EN_IT_my_course',
      );
      expect(
        CourseStorageNames.exportBaseName(
          pair: 'IT_NAP',
          title: 'My Course!',
          historicalVersion: '3',
        ),
        'QQL_bkp_IT_NAP_my_course_v3',
      );
      expect(
        CourseStorageNames.exportBaseName(pair: 'EN_IT', title: '  '),
        'QQL_EN_IT_custom_course',
      );
    });
  });

  group('stores', () {
    late Directory support;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('qql_255_r4_names_');
    });

    tearDown(() async {
      if (await support.exists()) await support.delete(recursive: true);
    });

    List<String> names(String folder) => [
      for (final entity in Directory(folder).listSync())
        entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
    ]..sort();

    Map<String, Object?> custom(String target, String tag) => {
      'course': {
        'sourceLanguage': 'Italian',
        'targetLanguage': target,
        'targetLanguageTag': tag,
      },
    };

    test('a stored file is renamed in place when the languages change', () async {
      final store = CourseFileStore(supportDirectory: () async => support);
      await store.write(
        CourseStoreKind.custom,
        'course_ab',
        custom('English', 'en'),
      );
      await store.write(
        CourseStoreKind.externalOfficial,
        'pub.one',
        const {
          'source': {'sourceLanguage': 'English', 'targetLanguage': 'Welsh'},
        },
      );
      final customFolder = (await store.directoryFor(
        CourseStoreKind.custom,
      )).path;
      expect(names(customFolder), ['QQL_IT_EN_ab.json']);
      expect(
        names((await store.directoryFor(CourseStoreKind.externalOfficial)).path),
        ['QQL_EN_CY_pub.one.json'],
      );

      final stored = await store.snapshot(CourseStoreKind.custom, 'course_ab');
      await store.replaceIfUnchanged(
        CourseStoreKind.custom,
        'course_ab',
        custom('Neapolitan', 'nap'),
        expectedToken: stored!.token,
      );
      expect(names(customFolder), ['QQL_IT_NAP_ab.json']);
      await store.write(
        CourseStoreKind.custom,
        'course_ab',
        custom('Sicilian', ''),
      );
      expect(names(customFolder), ['QQL_IT_SCN_ab.json']);
      expect(
        (await store.readAll(CourseStoreKind.custom))['course_ab'],
        custom('Sicilian', ''),
      );
      expect(await store.contains(CourseStoreKind.custom, 'course_ab'), isTrue);
    });

    test('a file is found by the ID inside it, whatever its name says', () async {
      final store = CourseFileStore(supportDirectory: () async => support);
      await store.write(
        CourseStoreKind.custom,
        'course_ab',
        custom('English', 'en'),
      );
      final folder = (await store.directoryFor(CourseStoreKind.custom)).path;
      await File(
        '$folder${sep}QQL_IT_EN_ab.json',
      ).rename('$folder${sep}QQL_XX_YY_ab.json');

      final found = await store.snapshot(CourseStoreKind.custom, 'course_ab');
      expect(found, isNotNull);
      await store.write(
        CourseStoreKind.custom,
        'course_ab',
        custom('English', 'en'),
      );
      expect(names(folder), ['QQL_IT_EN_ab.json']);
    });

    test('a file named for the Course but holding another is kept', () async {
      final store = CourseFileStore(supportDirectory: () async => support);
      await store.write(
        CourseStoreKind.custom,
        'course_ab',
        custom('English', 'en'),
      );
      await store.write(CourseStoreKind.custom, 'ab', custom('Welsh', 'cy'));
      final folder = (await store.directoryFor(CourseStoreKind.custom)).path;
      // `course_ab` and `ab` share the ID part `ab` in their names.
      expect(names(folder), ['QQL_IT_CY_ab.json', 'QQL_IT_EN_ab.json']);
      final other = File('$folder${sep}QQL_IT_CY_ab.json');
      final before = await other.readAsString();

      await expectLater(
        store.write(CourseStoreKind.custom, 'course_ab', custom('Welsh', 'cy')),
        throwsFormatException,
      );
      expect(await other.readAsString(), before);
      expect(names(folder), ['QQL_IT_CY_ab.json', 'QQL_IT_EN_ab.json']);
    });

    test('a confirmed language change renames the file, the media folder and '
        'the backup folder', () async {
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: _profileId,
            displayName: 'Author',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: _profileId,
      });
      final media = CourseMediaStore(supportDirectory: () async => support);
      final backups = CourseBackupService(
        supportDirectoryProvider: () async => support,
        mediaStore: media,
      );
      final service = CourseEditorService(
        courseStore: CourseFileStore(supportDirectory: () async => support),
        backupService: backups,
        mediaStore: media,
        clock: () => DateTime.utc(2026, 9, 26, 12),
      );
      const id = 'course_1234abcd';
      final hash = CourseStorageNames.hashOf(id);
      final reference = await media.addBytes(
        id,
        Uint8List.fromList(const [1, 2, 3]),
        'mp3',
      );
      // A new Course's media folder is neutral until the Course is stored.
      expect(names('${support.path}${sep}QQL_CourseMedia'), ['QQL_$hash']);

      final course = _course(id, reference);
      await service.saveUserCourse(course);
      expect(names('${support.path}${sep}QQL_Courses${sep}Custom'), [
        'QQL_EN_IT_1234abcd.json',
      ]);
      expect(names('${support.path}${sep}QQL_CourseMedia'), [
        'QQL_EN_IT_$hash',
      ]);

      final stored = (await service.listUserCourses()).single;
      await service.confirmCourseTransaction(
        originalCourse: stored,
        workingCourse: Course.fromJson({
          ...stored.toJson(),
          'targetLanguage': 'Neapolitan',
          'targetLanguageTag': 'nap',
          'learningLanguage': 'Neapolitan',
        }),
        languageCode: 'NAP',
        versionNotes: 'Now Neapolitan',
      );

      expect(names('${support.path}${sep}QQL_Courses${sep}Custom'), [
        'QQL_EN_NAP_1234abcd.json',
      ]);
      expect(names('${support.path}${sep}QQL_CourseMedia'), [
        'QQL_EN_NAP_$hash',
      ]);
      expect(names('${support.path}${sep}QQL_CourseBackups'), [
        'QQL_bkp_EN_NAP_1234abcd',
      ]);
      expect((await service.listUserCourses()).single.targetLanguage,
          'Neapolitan');
      expect(await media.existingFile(id, reference), isNotNull);
      // The version saved before the change keeps the languages it had.
      final history = await backups.listBackups(id);
      expect(history, hasLength(1));
      expect(
        history.single.manifestFile.uri.pathSegments.last,
        startsWith('QQL_bkp_EN_IT_1234abcd_v1_'),
      );
      expect(history.single.course.targetLanguage, 'Italian');
    });
  });

  group('earlier private folders', () {
    late Directory support;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('qql_255_r4_earlier_');
    });

    tearDown(() async {
      if (await support.exists()) await support.delete(recursive: true);
    });

    List<String> names() => [
      for (final entity in support.listSync())
        entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
    ]..sort();

    test('qql_logs becomes QQL_Logs only where case is ignored', () async {
      final earlier = Directory('${support.path}${sep}qql_logs')..createSync();
      File('${earlier.path}${sep}old.log').writeAsStringSync('kept');
      // Where case is ignored, the new name reaches the same folder.
      final caseIgnored = Directory(
        '${support.path}${sep}QQL_Logs',
      ).existsSync();

      await QqlEarlierPrivateFolders.giveCurrentCase(support, 'QQL_Logs');

      expect(names(), [caseIgnored ? 'QQL_Logs' : 'qql_logs']);
      expect(
        File(
          '${support.path}$sep${caseIgnored ? 'QQL_Logs' : 'qql_logs'}'
          '${sep}old.log',
        ).readAsStringSync(),
        'kept',
      );
      expect(
        await QqlEarlierPrivateFolders.presentIn(support, const [
          'qql_logs',
        ], current: const ['QQL_Logs']),
        caseIgnored ? isEmpty : ['qql_logs'],
      );
    });

    test('Android cloud backup leaves out every bulk media folder', () {
      // The 25 MB Auto Backup quota: see docs/SECURITY_AND_ROBUSTNESS.md.
      for (final rules in [
        'android/app/src/main/res/xml/backup_rules.xml',
        'android/app/src/main/res/xml/data_extraction_rules.xml',
      ]) {
        final xml = File(rules).readAsStringSync();
        for (final folder in [
          ExerciseImageService.sharedImagesDirectoryName,
          ImageBankService.banksDirectoryName,
          CourseMediaStore.rootDirectoryName,
          QqlEarlierPrivateFolders.sharedImages,
          QqlEarlierPrivateFolders.imageBanks,
          QqlEarlierPrivateFolders.courseMedia,
        ]) {
          expect(
            xml,
            matches(
              RegExp(
                '<exclude\\s+domain="file"\\s+path="'
                '${RegExp.escape(folder)}/"\\s*/>',
              ),
            ),
            reason: '$rules must exclude $folder',
          );
        }
      }
    });

    test('earlier folders are matched by their exact names', () async {
      Directory('${support.path}${sep}qql_courses_v2').createSync();
      Directory('${support.path}${sep}QQL_Courses').createSync();
      File('${support.path}${sep}qql_import_staging').writeAsStringSync('x');

      expect(
        await QqlEarlierPrivateFolders.presentIn(
          support,
          QqlEarlierPrivateFolders.retired,
        ),
        ['qql_courses_v2'],
      );
    });
  });
}

Course _course(String id, String reference) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: '2026-09-26T09:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  targetLanguageTag: 'it-IT',
  title: 'Pairs',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  audioMode: 'recorded',
  audioLibrary: [CourseAudioClip(id: 'a', text: 'uno', filePath: reference)],
  lessons: const [],
);
