import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/learning_activity_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/storage/atomic_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Build 270 Revision 5: a group of learner-data changes (a Round's or a
// Duel's completion) reaches the disk in one write; a streak read writes
// nothing; activity registered at the same moment counts once.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('groups of changes', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('qql_270_groups_');
    });

    tearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    Map<String, dynamic> onDisk() {
      final file = File(
        '${directory.path}${Platform.pathSeparator}${AtomicPreferencesStore.fileName}',
      );
      if (!file.existsSync()) return const {};
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    test('changes made while held reach the disk together', () async {
      final store = AtomicPreferencesStore(directory: () async => directory);
      await store.setValue('Int', 'flutter.before', 1);
      expect(onDisk(), {'flutter.before': 1});
      final result = await store.hold(() async {
        expect(await store.setValue('Int', 'flutter.round', 1), isTrue);
        expect(await store.setValue('Int', 'flutter.xp', 25), isTrue);
        // A crash now leaves neither.
        expect(onDisk(), {'flutter.before': 1});
        return 'done';
      });
      expect(result, 'done');
      expect(onDisk(), {
        'flutter.before': 1,
        'flutter.round': 1,
        'flutter.xp': 25,
      });
    });

    test('a write already queued when a hold starts waits for it', () async {
      final store = AtomicPreferencesStore(directory: () async => directory);
      await store.getAll();
      // Queued, not yet written, when the hold begins.
      final queued = store.setValue('Int', 'flutter.a', 1);
      await store.hold(() async {
        await store.setValue('Int', 'flutter.b', 2);
        expect(await queued, isTrue);
        expect(onDisk().containsKey('flutter.b'), isFalse);
      });
      expect(onDisk(), {'flutter.a': 1, 'flutter.b': 2});
    });

    test('nested groups write once, at the end of the outer one', () async {
      final store = AtomicPreferencesStore(directory: () async => directory);
      await store.hold(() async {
        await store.hold(() async {
          await store.setValue('Int', 'flutter.inner', 1);
        });
        expect(onDisk(), isEmpty);
        await store.setValue('Int', 'flutter.outer', 2);
      });
      expect(onDisk(), {'flutter.inner': 1, 'flutter.outer': 2});
    });

    test('without the store installed a group simply runs', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AtomicPreferencesStore.group(() async => 7), 7);
    });
  });

  group('streaks', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProfileService().addProfile('Streak learner');
    });

    test('reading a broken streak writes nothing', () async {
      final day1 = LearningActivityService(now: () => DateTime(2026, 10, 1, 9));
      await day1.registerLearningActivity(courseCode: 'IT');
      await LearningActivityService(
        now: () => DateTime(2026, 10, 2, 9),
      ).registerLearningActivity(courseCode: 'IT');
      final later = LearningActivityService(
        now: () => DateTime(2026, 10, 5, 9),
      );
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      expect(await later.getStreak(courseCode: 'IT'), 0);
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      // The next study day starts again from 1.
      await later.registerLearningActivity(courseCode: 'IT');
      expect(await later.getStreak(courseCode: 'IT'), 1);
    });

    test('two sessions registered at the same moment add one day', () async {
      await LearningActivityService(
        now: () => DateTime(2026, 10, 1, 9),
      ).registerLearningActivity(courseCode: 'IT');
      final next = LearningActivityService(now: () => DateTime(2026, 10, 2, 9));
      await Future.wait([
        next.registerLearningActivity(courseCode: 'IT'),
        next.registerLearningActivity(courseCode: 'IT'),
      ]);
      expect(await next.getStreak(courseCode: 'IT'), 2);
    });
  });
}
