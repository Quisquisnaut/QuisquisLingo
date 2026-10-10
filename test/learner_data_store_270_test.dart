import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/storage/atomic_preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

// Build 270 Revision 0: learner data on Windows and Linux is written so that
// an interrupted write can never leave a file QQL cannot start with.
void main() {
  late Directory directory;
  late List<LearnerDataProblem> problems;

  AtomicPreferencesStore store() => AtomicPreferencesStore(
    directory: () async => directory,
    onProblem: problems.add,
    renameRetryDelays: const [],
  );

  File file(String name) =>
      File('${directory.path}${Platform.pathSeparator}$name');

  Map<String, dynamic> stored() =>
      jsonDecode(file(AtomicPreferencesStore.fileName).readAsStringSync())
          as Map<String, dynamic>;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qql_learner_data_');
    problems = [];
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('keeps the plugin file, its place and its JSON', () async {
    // What shared_preferences_windows wrote before this revision.
    file(AtomicPreferencesStore.fileName).writeAsStringSync(
      jsonEncode({
        'flutter.xp_IT': 120,
        'flutter.name': 'Ada',
        'flutter.flag': true,
        'flutter.rate': 0.5,
        'flutter.days': ['2026-10-09', '2026-10-10'],
      }),
    );
    final first = store();
    expect(await first.getAll(), {
      'flutter.xp_IT': 120,
      'flutter.name': 'Ada',
      'flutter.flag': true,
      'flutter.rate': 0.5,
      'flutter.days': ['2026-10-09', '2026-10-10'],
    });
    expect(await first.setValue('Int', 'flutter.xp_IT', 125), isTrue);
    expect(await first.remove('flutter.flag'), isTrue);
    expect(stored(), {
      'flutter.xp_IT': 125,
      'flutter.name': 'Ada',
      'flutter.rate': 0.5,
      'flutter.days': ['2026-10-09', '2026-10-10'],
    });
    expect(await store().getAll(), stored());
    expect(problems, isEmpty);
    expect(first.recovery, isNull);
  });

  test('a burst of changes is saved whole and each call reports it', () async {
    final preferences = store();
    final results = await Future.wait([
      for (var i = 0; i < 50; i++)
        preferences.setValue('Int', 'flutter.n$i', i),
    ]);
    expect(results, everyElement(isTrue));
    expect(stored().length, 50);
    expect(file(AtomicPreferencesStore.temporaryFileName).existsSync(), false);
  });

  test('works under the shared_preferences API', () async {
    final original = SharedPreferencesStorePlatform.instance;
    addTearDown(() {
      SharedPreferencesStorePlatform.instance = original;
      SharedPreferences.resetStatic();
    });
    SharedPreferencesStorePlatform.instance = store();
    SharedPreferences.resetStatic();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList('days', ['a', 'b']);
    await preferences.setInt('xp', 7);
    expect(stored(), {
      'flutter.days': ['a', 'b'],
      'flutter.xp': 7,
    });
    SharedPreferencesStorePlatform.instance = store();
    SharedPreferences.resetStatic();
    final again = await SharedPreferences.getInstance();
    expect(again.getStringList('days'), ['a', 'b']);
    expect(again.getInt('xp'), 7);
  });

  test('a successful start-up leaves a last good copy', () async {
    file(
      AtomicPreferencesStore.fileName,
    ).writeAsStringSync(jsonEncode({'flutter.xp': 3}));
    await store().getAll();
    expect(
      jsonDecode(
        file(AtomicPreferencesStore.lastGoodFileName).readAsStringSync(),
      ),
      {'flutter.xp': 3},
    );
  });

  for (final (label, content) in [
    ('empty', ''),
    ('cut off', '{"flutter.xp": 12, "flutter.na'),
    ('not an object', '[1, 2]'),
  ]) {
    test('an $label file is kept and the last good copy is used', () async {
      file(
        AtomicPreferencesStore.lastGoodFileName,
      ).writeAsStringSync(jsonEncode({'flutter.xp': 10}));
      file(AtomicPreferencesStore.fileName).writeAsStringSync(content);
      final preferences = store();
      expect(await preferences.getAll(), {'flutter.xp': 10});
      // The file is good again, and the damaged one was not overwritten.
      expect(stored(), {'flutter.xp': 10});
      final recovery = preferences.recovery!;
      expect(recovery.kind, LearnerDataProblemKind.restoredLastGood);
      expect(File(recovery.damagedCopy!).readAsStringSync(), content);
      expect(recovery.lastGoodSavedAt, isNotNull);
      expect(problems.single, same(recovery));
    });
  }

  test('without a copy QQL starts empty and keeps the damaged file', () async {
    file(AtomicPreferencesStore.fileName).writeAsStringSync('{"flutter.x');
    final preferences = store();
    expect(await preferences.getAll(), isEmpty);
    final recovery = preferences.recovery!;
    expect(recovery.kind, LearnerDataProblemKind.startedEmpty);
    expect(File(recovery.damagedCopy!).readAsStringSync(), '{"flutter.x');
    // Learner data can be written again.
    expect(await preferences.setValue('Int', 'flutter.xp', 1), isTrue);
    expect(stored(), {'flutter.xp': 1});
    expect(
      (await AtomicPreferencesStore.safetyCopiesIn(
        directory,
      )).map((copy) => copy.uri.pathSegments.last),
      contains(startsWith(AtomicPreferencesStore.damagedFilePrefix)),
    );
  });

  test('a missing file is a first start unless a copy exists', () async {
    expect(await store().getAll(), isEmpty);
    expect(problems, isEmpty);

    // Reading writes nothing: the file is still missing.
    expect(file(AtomicPreferencesStore.fileName).existsSync(), isFalse);
    file(
      AtomicPreferencesStore.lastGoodFileName,
    ).writeAsStringSync(jsonEncode({'flutter.xp': 4}));
    final preferences = store();
    expect(await preferences.getAll(), {'flutter.xp': 4});
    expect(preferences.recovery!.kind, LearnerDataProblemKind.restoredLastGood);
    expect(preferences.recovery!.damagedCopy, isNull);
  });

  test('a temporary file left by a crash is removed', () async {
    file(
      AtomicPreferencesStore.fileName,
    ).writeAsStringSync(jsonEncode({'flutter.xp': 5}));
    file(AtomicPreferencesStore.temporaryFileName).writeAsStringSync('{"flu');
    expect(await store().getAll(), {'flutter.xp': 5});
    expect(file(AtomicPreferencesStore.temporaryFileName).existsSync(), false);
  });

  test('a failed write is reported and returns false', () async {
    final preferences = store();
    await preferences.getAll();
    // A folder where the temporary file must go makes every write fail.
    Directory(file(AtomicPreferencesStore.temporaryFileName).path).createSync();
    expect(await preferences.setValue('Int', 'flutter.xp', 9), isFalse);
    expect(problems.single.kind, LearnerDataProblemKind.writeFailed);
    // The change is kept in memory and saved by the next write that works.
    Directory(file(AtomicPreferencesStore.temporaryFileName).path).deleteSync();
    expect(await preferences.setValue('Int', 'flutter.other', 1), isTrue);
    expect(stored(), {'flutter.xp': 9, 'flutter.other': 1});
  });

  test('a read that fails can be tried again', () async {
    var fail = true;
    final preferences = AtomicPreferencesStore(
      directory: () async {
        if (fail) throw const FileSystemException('not yet');
        return directory;
      },
    );
    await expectLater(
      preferences.getAll(),
      throwsA(isA<FileSystemException>()),
    );
    fail = false;
    expect(await preferences.getAll(), isEmpty);
  });
}
