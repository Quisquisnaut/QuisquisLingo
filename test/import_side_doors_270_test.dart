import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/controllers/learner_status_controller.dart';
import 'package:quisquislingo_app/models/bundled_asset.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/xp_service.dart';
import 'package:quisquislingo_app/widgets/bundled_picture.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/synthetic_mp3.dart';
import 'support/test_directories.dart';

const _courseId = 'side-doors-270';
const _learner = '12345678-1234-4234-9234-123456789abc';

Course _course(List<CourseAudioClip> clips) => Course(
  courseId: _courseId,
  title: 'Side doors',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  audioMode: 'recorded',
  audioLibrary: clips,
  lessons: const [],
);

// Build 270 Revision 3: the ways around the import checks found by the
// audit (items 5 and 6, and learner backup values).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled files', () {
    test('a Course can name a file in the bundle, never one outside it', () {
      for (final path in [
        'assets/exercise_images/espresso.webp',
        'assets/world_flags/flags/it.svg',
        'assets/lesson_icons/coffee.png',
        'assets/avatars/anna.png',
        'assets/audio/en_sample/hello.mp3',
      ]) {
        expect(isBundledAsset(path), isTrue, reason: path);
        expect(Course.isValidImageReference(path), isTrue, reason: path);
      }
      for (final path in [
        'assets/../../secret.webp',
        'assets/exercise_images/../../x.png',
        'assets/./x.webp',
        'assets/.hidden.png',
        'assets//x.webp',
        r'assets/a\b.webp',
        'assets/',
        'assets/x y.webp',
        'Assets/x.webp',
      ]) {
        expect(isBundledAsset(path), isFalse, reason: path);
        expect(Course.isValidImageReference(path), isFalse, reason: path);
        expect(Course.isValidAudioReference(path), isFalse, reason: path);
      }
    });

    test('every file QQL ships matches', () {
      final files = Directory('assets')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => file.path.replaceAll(r'\', '/'));
      expect(files, isNotEmpty);
      for (final path in files) {
        expect(isBundledAsset(path), isTrue, reason: path);
      }
    });

    Map<String, dynamic> demo() =>
        jsonDecode(
              File(
                'assets/courses/english_from_italian_it_en.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    void replaceFirst(
      Object? node,
      bool Function(Map<String, dynamic>) where,
      void Function(Map<String, dynamic>) change,
    ) {
      var done = false;
      void visit(Object? value) {
        if (done) return;
        if (value is Map<String, dynamic>) {
          if (where(value)) {
            change(value);
            done = true;
            return;
          }
          value.values.forEach(visit);
        } else if (value is List) {
          value.forEach(visit);
        }
      }

      visit(node);
      expect(done, isTrue);
    }

    test('a Course naming a picture outside the bundle is refused', () {
      expect(() => Course.fromJson(demo()), returnsNormally);
      final picture = demo();
      replaceFirst(
        picture,
        (node) =>
            node['type'] == 'image' && '${node['asset']}'.startsWith('assets/'),
        (node) => node['asset'] = 'assets/../../secret.webp',
      );
      expect(() => Course.fromJson(picture), throwsFormatException);

      final iconKey = demo();
      replaceFirst(
        iconKey,
        (node) =>
            node['role'] == 'icon' && '${node['text']}'.startsWith('assets/'),
        (node) => node['text'] = 'assets/../../secret.webp',
      );
      expect(() => Course.fromJson(iconKey), throwsFormatException);
    });

    testWidgets('the app draws no file outside the bundle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BundledPicture(
            'assets/../../secret.png',
            errorBuilder: (_) => const Text('refused'),
          ),
        ),
      );
      expect(find.text('refused'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('Course Backups', () {
    late Directory backupsFolder;
    late Directory support;
    late CourseMediaStore media;
    late CourseBackupService backups;

    setUp(() async {
      backupsFolder = await Directory.systemTemp.createTemp('qql_270_bkp_');
      support = await Directory.systemTemp.createTemp('qql_270_media_');
      media = CourseMediaStore(supportDirectory: () async => support);
      backups = CourseBackupService(
        backupsDirectoryProvider: () async => backupsFolder,
        mediaStore: media,
      );
    });

    tearDown(() async {
      for (final directory in [backupsFolder, support]) {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    });

    Future<CourseBackupRecord> backupWith(List<int> clip) async {
      final reference = await media.addBytes(
        _courseId,
        Uint8List.fromList(clip),
        'mp3',
      );
      return backups.createBackup(
        _course([CourseAudioClip(id: 'a', text: 'uno', filePath: reference)]),
        backedUpAt: DateTime.utc(2026, 10, 10, 9),
        reason: 'Pre-change Course Editor transaction backup',
      );
    }

    test('an asset path leaving its folder is refused', () async {
      final record = await backupWith(syntheticMp3(seed: 7));
      final manifest =
          jsonDecode(await record.manifestFile.readAsString())
              as Map<String, dynamic>;
      final asset = (manifest['assets'] as List).single as Map;
      final relative = asset['backupRelativePath'] as String;
      final name = relative.split('/').last;
      // The same file one folder up, where `../` would find it.
      await File(
        '${record.manifestFile.parent.parent.path}${Platform.pathSeparator}$name',
      ).writeAsBytes(syntheticMp3(seed: 7));
      asset['backupRelativePath'] = '../$name';
      await record.manifestFile.writeAsString(jsonEncode(manifest));
      await expectLater(
        backups.loadBackup(record.manifestFile, expectedCourseId: _courseId),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('unsafe'),
          ),
        ),
      );
    });

    test('a file larger than any Course is not read', () async {
      final record = await backupWith(syntheticMp3(seed: 8));
      final big = await record.manifestFile.open(mode: FileMode.append);
      await big.setPosition(CourseBackupService.maxManifestBytes);
      await big.writeByte(32);
      await big.close();
      await expectLater(
        backups.loadBackup(record.manifestFile, expectedCourseId: _courseId),
        throwsFormatException,
      );
      final skipped = <String>[];
      expect(await backups.listBackups(_courseId, skipped: skipped), isEmpty);
      expect(skipped, hasLength(1));
    });

    test(
      'a restore puts back only media that pass the import checks',
      () async {
        // Not an MP3: the Course folder took it once, a restore does not.
        final record = await backupWith(const [1, 2, 3]);
        await media.deleteUnreferenced(_courseId, const {});
        final loaded = await backups.loadBackup(
          record.manifestFile,
          expectedCourseId: _courseId,
        );
        await expectLater(backups.reinstateMedia(loaded), throwsA(anything));
        final reference = loaded.course.audioLibrary.single.filePath;
        expect(await media.existingFile(_courseId, reference), isNull);

        final good = await backupWith(syntheticMp3(seed: 9));
        await media.deleteUnreferenced(_courseId, const {});
        final restored = await backups.loadBackup(
          good.manifestFile,
          expectedCourseId: _courseId,
        );
        await backups.reinstateMedia(restored);
        expect(
          await media.existingFile(
            _courseId,
            restored.course.audioLibrary.single.filePath,
          ),
          isNotNull,
        );
      },
    );
  });

  group('learner backups', () {
    List<int> backup(Map<String, Object?> data) => utf8.encode(
      jsonEncode({
        'format': LearnerBackupService.format,
        'schemaVersion': LearnerBackupService.schemaVersion,
        'learnerProfileId': _learner,
        'displayName': 'Ada',
        'exportedAt': '2026-10-10T09:00:00.000',
        'data': data,
      }),
    );

    test('a value QQL reads with a fixed type must have it', () {
      final service = LearnerBackupService();
      final good = service.decodeDocument(
        backup({
          'xp_IT': 120,
          'week_xp': 30,
          'streak_IT': 4,
          'last_active_IT': '2026-10-09',
          'study_days_all': ['2026-10-09'],
          'v4_completed_rounds_course_c': ['r1'],
          'skin_tone': 'light',
          'guidebook_availability_notice_seen': true,
          'anything_else': 1.5,
        }),
      );
      expect(good.data['xp_IT'], 120);
      for (final (suffix, value) in <(String, Object)>[
        ('xp_IT', '120'),
        ('week_xp', 30.5),
        ('streak_IT', true),
        ('last_active_IT', 20261009),
        ('study_days_all', 5),
        ('v4_perfect_rounds_course_c', 'r1'),
        ('skin_tone', 1),
        ('guidebook_availability_notice_seen', 'yes'),
      ]) {
        expect(
          () => service.decodeDocument(backup({suffix: value})),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains(suffix),
            ),
          ),
          reason: suffix,
        );
      }
    });
  });

  group('learner status', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      keepCrashLogUnavailable();
    });

    test(
      'one value that cannot be read keeps the bar and is reported',
      () async {
        final profiles = ProfileService();
        await profiles.addProfile('Ada');
        final id = (await profiles.getActiveProfileId())!;
        final prefs = await SharedPreferences.getInstance();
        // Written by hand, or by another version.
        await prefs.setString(profiles.keyForProfileId(id, 'week_xp'), 'oops');
        // This week, so no rollover replaces it.
        await prefs.setString(
          profiles.keyForProfileId(id, 'week_xp_week'),
          XpService().weekKeyFor(DateTime.now()),
        );
        final controller = LearnerStatusController(
          observeLifecycle: false,
          timerFactory: (_, callback) => Timer(Duration.zero, () {}),
        );
        addTearDown(controller.dispose);
        await controller.refresh();
        expect(
          prefs.getString('quisquislingo_diagnostic_log'),
          contains('The learner status could not be read.'),
        );
      },
    );
  });
}
