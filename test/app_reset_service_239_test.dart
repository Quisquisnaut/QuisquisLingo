import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/course_editor_storage.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory documents;
  late Directory support;
  late ProfileService profiles;
  late AppResetService service;
  late String adminId;
  late String learnerId;
  final sep = Platform.pathSeparator;

  File touch(String path) {
    final file = File(path);
    file.createSync(recursive: true);
    file.writeAsStringSync('x');
    return file;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('qql_reset_');
    documents = Directory('${root.path}${sep}docs')..createSync();
    support = Directory('${root.path}${sep}support')..createSync();
    profiles = ProfileService();
    adminId = (await profiles.createProfile('Admin One')).learnerProfileId;
    learnerId = (await profiles.createProfile('Learner Two')).learnerProfileId;
    await profiles.setOwnAccessPin(actorProfileId: adminId, pin: '4321');
    service = AppResetService(
      profiles: profiles,
      documentsDirectory: () async => documents,
      supportDirectory: () async => support,
    );
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a handle.
    }
  });

  Future<void> seedProgress(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = ProfileService.prefixForProfileId(id);
    await prefs.setStringList('${prefix}v4_completed_rounds', ['r1']);
    await prefs.setInt('${prefix}xp_it', 40);
    await prefs.setString('${prefix}theme_mode', 'dark');
  }

  test('an admin without a PIN cannot reset anything', () async {
    await profiles.setOwnAccessPin(actorProfileId: adminId, pin: null);
    await expectLater(
      service.reset(
        AppResetScope.learnerProgress,
        actorProfileId: adminId,
        pin: '',
      ),
      throwsA(isA<AppResetException>()),
    );
  });

  test('a non-admin and a wrong PIN are refused and change nothing', () async {
    await seedProgress(learnerId);
    await expectLater(
      service.reset(
        AppResetScope.everything,
        actorProfileId: learnerId,
        pin: '4321',
      ),
      throwsA(isA<AppResetException>()),
    );
    await expectLater(
      service.reset(
        AppResetScope.everything,
        actorProfileId: adminId,
        pin: '0000',
      ),
      throwsA(isA<AppResetException>()),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey('${ProfileService.prefixForProfileId(learnerId)}xp_it'),
      isTrue,
    );
    expect((await profiles.getProfileRecords()), hasLength(2));
  });

  test(
    'learner progress removes progress but keeps profiles and settings',
    () async {
      await seedProgress(learnerId);
      await service.reset(
        AppResetScope.learnerProgress,
        actorProfileId: adminId,
        pin: '4321',
      );
      final prefs = await SharedPreferences.getInstance();
      final prefix = ProfileService.prefixForProfileId(learnerId);
      expect(prefs.containsKey('${prefix}v4_completed_rounds'), isFalse);
      expect(prefs.containsKey('${prefix}xp_it'), isFalse);
      expect(prefs.getString('${prefix}theme_mode'), 'dark');
      expect(await profiles.getProfileRecords(), hasLength(2));
      expect(await profiles.hasAccessPin(adminId), isTrue);
    },
  );

  test('a non-everything reset leaves the admin logged in', () async {
    for (final scope in [
      AppResetScope.learnerProgress,
      AppResetScope.nonAdminLearners,
      AppResetScope.importedMedia,
      AppResetScope.customCourses,
    ]) {
      await profiles.setActiveProfileById(adminId, accessPin: '4321');
      await service.reset(scope, actorProfileId: adminId, pin: '4321');
      expect(
        await profiles.getActiveProfileId(),
        adminId,
        reason: '$scope must not log the admin out',
      );
    }
  });

  test('non-admin learners are removed and admins are kept', () async {
    await seedProgress(learnerId);
    await service.reset(
      AppResetScope.nonAdminLearners,
      actorProfileId: adminId,
      pin: '4321',
    );
    final remaining = await profiles.getProfileRecords();
    expect(remaining.map((p) => p.learnerProfileId), [adminId]);
    final prefs = await SharedPreferences.getInstance();
    final prefix = ProfileService.prefixForProfileId(learnerId);
    expect(prefs.getKeys().where((k) => k.startsWith(prefix)), isEmpty);
    expect(await profiles.hasAccessPin(adminId), isTrue);
  });

  test('imported media removes only the media folders and keys', () async {
    touch('${support.path}${sep}exercise_images${sep}a.png');
    touch(
      '${support.path}${sep}quisquislingo_course_media${sep}c$sep${'a' * 64}.mp3',
    );
    final other = touch('${support.path}${sep}shared_preferences.json');
    await service.reset(
      AppResetScope.importedMedia,
      actorProfileId: adminId,
      pin: '4321',
    );
    expect(
      Directory('${support.path}${sep}exercise_images').existsSync(),
      isFalse,
    );
    expect(
      Directory('${support.path}${sep}quisquislingo_course_media').existsSync(),
      isFalse,
    );
    expect(other.existsSync(), isTrue);
  });

  test('imported media never touches the media bundled with the app', () async {
    final prefs = await SharedPreferences.getInstance();
    // A stored copy of the catalog (the admin's edits) is removed, and the
    // built-in catalog from the app assets is what remains.
    await prefs.setString(
      'quisquislingo_exercise_image_metadata_v2',
      '{"unused":true}',
    );
    await service.reset(
      AppResetScope.importedMedia,
      actorProfileId: adminId,
      pin: '4321',
    );
    expect(
      prefs.containsKey('quisquislingo_exercise_image_metadata_v2'),
      isFalse,
    );
    final catalog = await ExerciseImageMetadataService().loadCatalog();
    expect(catalog, isNotEmpty);
    expect(catalog.every((record) => record.origin == 'bundled'), isTrue);
    // Bundled files are Flutter assets inside the app package and are still
    // loadable after the reset.
    final asset = catalog.first.assetPath;
    expect(await rootBundle.load(asset), isNotNull);
  });

  test('imported media can remove only images or only audio', () async {
    File images() => File('${support.path}${sep}exercise_images${sep}a.png');
    File banks() => File('${support.path}${sep}image_banks${sep}b${sep}m.json');
    // Course media holds both kinds; the reset separates them by file type.
    File courseImage() => File(
      '${support.path}${sep}quisquislingo_course_media${sep}c$sep${'b' * 64}.png',
    );
    File audio() => File(
      '${support.path}${sep}quisquislingo_course_media${sep}c$sep${'a' * 64}.mp3',
    );
    void seed() {
      touch(images().path);
      touch(banks().path);
      touch(courseImage().path);
      touch(audio().path);
    }

    seed();
    await service.reset(
      AppResetScope.importedMedia,
      actorProfileId: adminId,
      pin: '4321',
      removeImages: true,
      removeAudio: false,
    );
    expect(images().existsSync(), isFalse);
    expect(banks().existsSync(), isFalse);
    expect(courseImage().existsSync(), isFalse);
    expect(audio().existsSync(), isTrue);

    seed();
    await service.reset(
      AppResetScope.importedMedia,
      actorProfileId: adminId,
      pin: '4321',
      removeImages: false,
      removeAudio: true,
    );
    expect(audio().existsSync(), isFalse);
    expect(images().existsSync(), isTrue);
    expect(banks().existsSync(), isTrue);
    expect(courseImage().existsSync(), isTrue);
  });

  test('imported media with nothing chosen is refused', () async {
    touch('${support.path}${sep}exercise_images${sep}a.png');
    await expectLater(
      service.reset(
        AppResetScope.importedMedia,
        actorProfileId: adminId,
        pin: '4321',
        removeImages: false,
        removeAudio: false,
      ),
      throwsA(isA<AppResetException>()),
    );
    expect(
      File('${support.path}${sep}exercise_images${sep}a.png').existsSync(),
      isTrue,
    );
  });

  test('custom courses also removes imported images and audio', () async {
    touch('${support.path}${sep}exercise_images${sep}a.png');
    touch(
      '${support.path}${sep}quisquislingo_course_media${sep}c$sep${'a' * 64}.mp3',
    );
    await service.reset(
      AppResetScope.customCourses,
      actorProfileId: adminId,
      pin: '4321',
    );
    expect(
      Directory('${support.path}${sep}exercise_images').existsSync(),
      isFalse,
    );
    expect(
      Directory('${support.path}${sep}quisquislingo_course_media').existsSync(),
      isFalse,
    );
  });

  for (final scope in AppResetScope.values) {
    test('course files follow the ${scope.name} reset scope', () async {
      final courseRoot = '${support.path}${sep}qql_courses_v2';
      touch('$courseRoot${sep}custom${sep}draft.json');
      touch('$courseRoot${sep}external_official${sep}official.json');
      touch('$courseRoot${sep}custom${sep}interrupted.json.tmp');
      final unrelated = '${support.path}${sep}unrelated${sep}keep.txt';
      touch(unrelated);
      await service.reset(scope, actorProfileId: adminId, pin: '4321');
      final removesCourses =
          scope == AppResetScope.customCourses ||
          scope == AppResetScope.everything;
      expect(Directory(courseRoot).existsSync(), !removesCourses);
      expect(File(unrelated).existsSync(), isTrue);
    });
  }

  test('preview detects course files without preference records', () async {
    expect((await service.preview()).hasCustomCourses, isFalse);
    touch(
      '${support.path}${sep}qql_courses_v2${sep}external_official${sep}broken.json',
    );
    expect((await service.preview()).hasCustomCourses, isTrue);
  });

  test('received Custom Course flags follow the custom-course reset', () async {
    const key = 'quisquislingo_received_custom_course_friend%2Fcourse';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    expect((await service.preview()).hasCustomCourses, isTrue);

    for (final scope in [
      AppResetScope.learnerProgress,
      AppResetScope.importedMedia,
      AppResetScope.nonAdminLearners,
    ]) {
      await service.reset(scope, actorProfileId: adminId, pin: '4321');
      expect(prefs.getBool(key), isTrue);
    }

    await service.reset(
      AppResetScope.customCourses,
      actorProfileId: adminId,
      pin: '4321',
    );
    expect(prefs.containsKey(key), isFalse);
  });

  test('custom courses removes courses and teams but keeps learners', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CourseEditorStorage.userCoursesKey, '[]');
    await prefs.setString('quisquislingo_authoring_teams_v1_2291', '[]');
    await service.reset(
      AppResetScope.customCourses,
      actorProfileId: adminId,
      pin: '4321',
    );
    expect(prefs.containsKey(CourseEditorStorage.userCoursesKey), isFalse);
    expect(prefs.containsKey('quisquislingo_authoring_teams_v1_2291'), isFalse);
    expect(await profiles.getProfileRecords(), hasLength(2));
  });

  test(
    'everything wipes preferences and files, keeping ticked folders',
    () async {
      touch('${documents.path}${sep}QuisquisLingo${sep}Exports${sep}b.json');
      touch('${documents.path}${sep}QuisquisLingo${sep}Logs${sep}crash.log');
      touch('${documents.path}${sep}QuisquisLingo${sep}Imports${sep}i.json');
      touch('${support.path}${sep}image_banks${sep}b${sep}m.json');
      await service.reset(
        AppResetScope.everything,
        actorProfileId: adminId,
        pin: '4321',
      );
      final qql = '${documents.path}${sep}QuisquisLingo$sep';
      expect(File('${qql}Exports${sep}b.json').existsSync(), isTrue);
      expect(File('${qql}Logs${sep}crash.log').existsSync(), isTrue);
      expect(
        File('${qql}Imports${sep}i.json').existsSync(),
        isTrue,
        reason: 'Imports is kept by default',
      );
      expect(
        Directory('${support.path}${sep}image_banks').existsSync(),
        isFalse,
      );
      expect(await profiles.getProfileRecords(), isEmpty);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    },
  );

  test(
    'everything can also remove exports, logs and imports when asked',
    () async {
      touch('${documents.path}${sep}QuisquisLingo${sep}Imports${sep}i.json');
      touch('${documents.path}${sep}QuisquisLingo${sep}Exports${sep}b.json');
      touch('${documents.path}${sep}QuisquisLingo${sep}Logs${sep}crash.log');
      await service.reset(
        AppResetScope.everything,
        actorProfileId: adminId,
        pin: '4321',
        keepExports: false,
        keepLogs: false,
        keepImports: false,
      );
      final qql = Directory('${documents.path}${sep}QuisquisLingo');
      expect(qql.listSync(), isEmpty);
    },
  );

  test('preview counts learners, media files and courses', () async {
    touch('${support.path}${sep}exercise_images${sep}a.png');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CourseEditorStorage.userCoursesKey, '[]');
    final preview = await service.preview();
    expect(preview.learnerCount, 2);
    expect(preview.nonAdminLearnerCount, 1);
    expect(preview.imageFileCount, 1);
    expect(preview.audioFileCount, 0);
    expect(preview.mediaFileCount, 1);
    expect(preview.hasCustomCourses, isTrue);
  });
}
