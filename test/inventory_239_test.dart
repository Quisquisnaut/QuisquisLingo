import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/device_administration_screen.dart';
import 'package:quisquislingo_app/screens/inventory_screen.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _course = Course(
  courseId: 'qql-239-inventory-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Inventory Course',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory documents;
  late Directory support;
  late ProfileService profiles;
  late String adminId;
  late InventoryService service;
  final sep = Platform.pathSeparator;

  File touch(String path, [String content = 'x']) {
    final file = File(path);
    file.createSync(recursive: true);
    file.writeAsStringSync(content);
    return file;
  }

  String qql(String relative) =>
      '${documents.path}${sep}QuisquisLingo$sep${relative.replaceAll('/', sep)}';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('qql_inventory_');
    documents = Directory('${root.path}${sep}docs')..createSync();
    support = Directory('${root.path}${sep}support')..createSync();
    profiles = ProfileService();
    adminId = (await profiles.createProfile(
      'Admin One',
      generateScreenNameSuffix: false,
    )).learnerProfileId;
    service = InventoryService(
      profiles: profiles,
      documentsDirectory: () async => documents,
      supportDirectory: () async => support,
      courses: () async => [_course],
      teams: () async => const [],
    );
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // Windows may briefly retain a handle.
    }
  });

  InventorySection sectionOf(List<InventorySection> all, String title) =>
      all.firstWhere((s) => s.title == title);

  test(
    'lists learners as records and courses with their actual files',
    () async {
      final store = CourseFileStore(supportDirectory: () async => support);
      await store.write(CourseStoreKind.custom, _course.courseId, {
        'course': _course.toJson(),
      });
      final all = await service.load();
      final learners = sectionOf(all, 'Learners');
      expect(learners.items.single.name, 'Admin One');
      expect(learners.items.single.owner, 'Admin One (admin)');
      expect(learners.items.single.path, isNull);

      final courses = sectionOf(all, 'Custom and installed courses');
      expect(courses.items.single.name, 'Inventory Course');
      final item = courses.items.single;
      expect(item.path, isNotNull);
      final file = File(item.path!);
      expect(file.existsSync(), isTrue);
      expect(item.sizeBytes, file.lengthSync());
      expect(item.modified, file.statSync().modified);
      expect(courses.totalBytes, file.lengthSync());
      expect(courses.location, endsWith('qql_courses_v2'));
      expect(courses.items.single.owner, isNotNull);
    },
  );

  test('lists device-level received Custom Course flags', () async {
    const key = 'quisquislingo_received_custom_course_friend%2Fcourse';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);

    final all = await service.load();
    final received = sectionOf(all, 'Received Custom Courses');
    expect(received.count, 1);
    expect(received.items.single.name, 'friend/course');
    expect(received.items.single.path, isNull);
  });

  test('lists active learner Course Favorite flags with their owner', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'learner_${adminId}_course_favorite_friend%2Fcourse%201',
      true,
    );
    await prefs.setBool(
      'learner_${adminId}_course_favorite_not-favorite',
      false,
    );

    final favorites = sectionOf(await service.load(), 'Course Favorites');
    expect(favorites.count, 1);
    expect(favorites.items.single.name, 'friend/course 1');
    expect(favorites.items.single.owner, 'Admin One');
    expect(favorites.items.single.path, isNull);
  });

  test(
    'inventory lists unreadable course files without altering them',
    () async {
      final file = touch(
        '${support.path}${sep}qql_courses_v2${sep}custom${sep}broken.json',
        'broken-json',
      );
      final actual = InventoryService(
        profiles: profiles,
        documentsDirectory: () async => documents,
        supportDirectory: () async => support,
      );
      final courses = sectionOf(
        await actual.load(),
        'Custom and installed courses',
      );
      expect(courses.items.single.path, file.path);
      expect(courses.items.single.sizeBytes, file.lengthSync());
      expect(courses.description, contains('could not be read'));
      expect(file.readAsStringSync(), 'broken-json');
    },
  );

  test(
    'finds exports, imports, logs, media and outside files with owners',
    () async {
      touch(
        qql('Exports/quisquislingo_admin_one_backup.json'),
        jsonEncode({'learnerProfileId': adminId, 'displayName': 'Admin One'}),
      );
      touch(
        qql('Exports/gone.user-recovery-key.json'),
        jsonEncode({
          'learnerProfileId': '11111111-1111-4111-8111-111111111111',
          'displayName': 'Old Learner',
        }),
      );
      touch(
        qql('Exports/Course Backups v11/c_1_2026.json'),
        jsonEncode({'reason': 'Pre-change Course Editor transaction backup'}),
      );
      touch(qql('Imports/Audio/word.mp3'));
      touch(qql('Merges/merge.json'));
      touch(qql('Logs/quislingo_crash.log'));
      touch(qql('notes.txt'));
      touch(qql('Stuff/inner.bin'));
      touch('${support.path}${sep}exercise_images${sep}a.png');
      touch('${support.path}${sep}image_banks${sep}bank_1${sep}manifest.json');
      final hash = CourseMediaStore.folderNameFor(_course.courseId);
      touch(
        '${support.path}${sep}quisquislingo_course_media$sep$hash$sep${'a' * 64}.mp3',
      );
      touch(
        '${support.path}${sep}quisquislingo_course_media${sep}course_unknown$sep${'b' * 64}.png',
      );

      final all = await service.load();

      final exports = sectionOf(all, 'Exports and backups');
      expect(exports.count, 3);
      InventoryItem byName(String part) =>
          exports.items.firstWhere((i) => i.name.contains(part));
      expect(byName('admin_one_backup').owner, 'Admin One');
      expect(byName('admin_one_backup').note, 'Learner backup');
      expect(
        byName('gone.user-recovery-key').owner,
        'Old Learner (no longer on this device)',
      );
      expect(byName('gone.user-recovery-key').note, 'User Recovery Key');
      expect(
        byName('c_1_2026').note,
        'Automatic course backup (made before a change)',
      );
      expect(
        exports.items.every((i) => i.path!.contains('QuisquisLingo')),
        isTrue,
      );

      expect(sectionOf(all, 'Imports').count, 1);
      expect(sectionOf(all, 'Merges').count, 1);
      expect(sectionOf(all, 'Logs').count, 1);
      expect(sectionOf(all, 'Imported images').count, 1);
      expect(sectionOf(all, 'Image banks').count, 1);

      final media = sectionOf(all, 'Course media');
      expect(media.count, 2);
      final known = media.items.firstWhere((i) => i.name.startsWith(hash));
      expect(known.owner, contains('Inventory Course'));
      expect(known.note, 'Course recording (MP3).');
      final unknown = media.items.firstWhere(
        (i) => i.name.startsWith('course_unknown'),
      );
      expect(unknown.owner, 'A course no longer on this device');
      expect(unknown.note, 'Course image.');

      final other = sectionOf(all, 'Other files in the QQL folder');
      expect(other.count, 2);
      expect(
        other.items.map((i) => i.name),
        containsAll(['notes.txt', 'Stuff${sep}inner.bin']),
      );
      expect(other.items.first.note, contains('added to the QQL folder'));
    },
  );

  test('reports sizes and never lists media bundled with the app', () async {
    touch(qql('Imports/a.bin'), 'x' * 2048);
    final all = await service.load();
    expect(sectionOf(all, 'Imports').totalBytes, 2048);
    expect(
      all
          .expand((s) => s.items)
          .where((i) => (i.path ?? '').contains('assets')),
      isEmpty,
    );
  });

  test(
    'a very large folder lists only the newest files and counts the rest',
    () async {
      for (var i = 0; i < InventoryService.maxListedPerSection + 3; i++) {
        touch(qql('Imports/f$i.txt'));
      }
      final imports = sectionOf(await service.load(), 'Imports');
      expect(imports.items.length, InventoryService.maxListedPerSection);
      expect(imports.hiddenCount, 3);
      expect(imports.count, InventoryService.maxListedPerSection + 3);
    },
  );

  testWidgets('the Inventory screen shows selectable paths, owners and notes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    touch(qql('Imports/Audio/word.mp3'));
    touch(qql('notes.txt'));

    await tester.pumpWidget(
      MaterialApp(home: InventoryScreen(service: service)),
    );
    // The load uses real file-system calls, so give them real time.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-summary')), findsOneWidget);
    expect(find.textContaining('Files found: 2'), findsOneWidget);
    expect(find.textContaining('Imports (1)'), findsOneWidget);
    expect(find.textContaining('Added from outside QQL.'), findsWidgets);
    expect(
      find.textContaining('Belongs to: Admin One (admin)'),
      findsOneWidget,
    );
    expect(find.byType(SelectableText), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SelectableText &&
            (w.data ?? '').contains('word.mp3') &&
            (w.data ?? '').contains('QuisquisLingo'),
      ),
      findsOneWidget,
    );
    expect(find.text('Nothing found.'), findsWidgets);
  });

  testWidgets('Device Administration shows Inventory before Reset', (
    tester,
  ) async {
    await profiles.setActiveProfileById(adminId);
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DeviceAdministrationScreen(
          course: _course,
          onManageLearners: (_) async {},
          profileService: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inventory = find.byKey(const Key('admin-inventory'));
    expect(inventory, findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(
      tester.getTopLeft(inventory).dy,
      lessThan(tester.getTopLeft(find.text('Reset')).dy),
    );
    // The explanation is visible text, not a tooltip.
    expect(
      find.textContaining('automatic course backups and logs'),
      findsOneWidget,
    );
  });
}
