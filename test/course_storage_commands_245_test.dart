import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  Future<Directory> supportDirectory() async => support;

  /// The file the store keeps [courseId] in: these entries name no
  /// languages, so their pair is UNKNOWN_UNKNOWN (Build 255 Revision 4).
  String fileOf(String courseId) =>
      CourseStorageNames.courseFileName(courseId, 'UNKNOWN_UNKNOWN');

  setUp(() async {
    support = await Directory.systemTemp.createTemp('qql_245_store_');
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test(
    'create and snapshot keep the existing per-Course JSON format',
    () async {
      final store = CourseFileStore(supportDirectory: supportDirectory);

      expect(await store.snapshot(CourseStoreKind.custom, 'a'), isNull);
      await store.createIfAbsent(CourseStoreKind.custom, 'a', {'value': 1});
      final stored = await store.snapshot(CourseStoreKind.custom, 'a');

      expect(stored, isNotNull);
      expect(stored!.entry, {'value': 1});
      expect(stored.token, isNotEmpty);
      expect(await store.readAll(CourseStoreKind.custom), {
        'a': {'value': 1},
      });
      final directory = await store.directoryFor(CourseStoreKind.custom);
      expect(
        await File(
          '${directory.path}${Platform.pathSeparator}${fileOf('a')}',
        ).readAsString(),
        '{"courseId":"a","entry":{"value":1}}',
      );
    },
  );

  test('stale replace and remove tokens preserve both Courses', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.createIfAbsent(CourseStoreKind.custom, 'a', {'value': 1});
    await store.createIfAbsent(CourseStoreKind.custom, 'b', {'value': 1});
    final old = (await store.snapshot(CourseStoreKind.custom, 'a'))!;
    final directory = await store.directoryFor(CourseStoreKind.custom);
    final unrelated = File(
      '${directory.path}${Platform.pathSeparator}${fileOf('b')}',
    );
    final unrelatedBytes = await unrelated.readAsBytes();
    final unrelatedModified = await unrelated.lastModified();

    await store.replaceIfUnchanged(CourseStoreKind.custom, 'a', {
      'value': 2,
    }, expectedToken: old.token);
    final current = (await store.snapshot(CourseStoreKind.custom, 'a'))!;
    expect(current.token, isNot(old.token));
    await expectLater(
      store.replaceIfUnchanged(CourseStoreKind.custom, 'a', {
        'value': 3,
      }, expectedToken: old.token),
      throwsStateError,
    );
    await expectLater(
      store.removeIfUnchanged(
        CourseStoreKind.custom,
        'a',
        expectedToken: old.token,
      ),
      throwsStateError,
    );
    expect((await store.snapshot(CourseStoreKind.custom, 'a'))!.entry, {
      'value': 2,
    });
    expect(await unrelated.readAsBytes(), unrelatedBytes);
    expect(await unrelated.lastModified(), unrelatedModified);

    await store.removeIfUnchanged(
      CourseStoreKind.custom,
      'a',
      expectedToken: current.token,
    );
    expect(await store.snapshot(CourseStoreKind.custom, 'a'), isNull);
    expect((await store.snapshot(CourseStoreKind.custom, 'b'))!.entry, {
      'value': 1,
    });
  });

  test('an out-of-band edit is never removed by a stale token', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.createIfAbsent(CourseStoreKind.custom, 'a', {'v': 1});
    final old = (await store.snapshot(CourseStoreKind.custom, 'a'))!;
    final directory = await store.directoryFor(CourseStoreKind.custom);
    final target = File(
      '${directory.path}${Platform.pathSeparator}${fileOf('a')}',
    );
    await target.writeAsString('{"courseId":"a","entry":{"v":9}}');

    await expectLater(
      store.removeIfUnchanged(
        CourseStoreKind.custom,
        'a',
        expectedToken: old.token,
      ),
      throwsStateError,
    );
    expect((await store.snapshot(CourseStoreKind.custom, 'a'))!.entry, {
      'v': 9,
    });
  });

  test('an alias and a duplicate Course ID are refused', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.createIfAbsent(CourseStoreKind.custom, 'course/a', {'v': 1});
    await expectLater(
      store.createIfAbsent(CourseStoreKind.custom, 'course:a', {'v': 2}),
      throwsFormatException,
    );
    expect((await store.snapshot(CourseStoreKind.custom, 'course/a'))!.entry, {
      'v': 1,
    });

    final directory = await store.directoryFor(CourseStoreKind.custom);
    final canonical = File(
      '${directory.path}${Platform.pathSeparator}${fileOf('course/a')}',
    );
    await canonical.copy(
      '${directory.path}${Platform.pathSeparator}duplicate.json',
    );
    await expectLater(
      store.snapshot(CourseStoreKind.custom, 'course/a'),
      throwsFormatException,
    );
    await expectLater(
      store.replaceIfUnchanged(CourseStoreKind.custom, 'course/a', {
        'v': 3,
      }, expectedToken: 'stale'),
      throwsFormatException,
    );
    expect(await canonical.exists(), isTrue);
  });

  test(
    'a corrupt canonical file is preserved while another Course works',
    () async {
      final store = CourseFileStore(supportDirectory: supportDirectory);
      await store.createIfAbsent(CourseStoreKind.custom, 'healthy', {'v': 1});
      final directory = await store.directoryFor(
        CourseStoreKind.custom,
        create: true,
      );
      final corrupt = File(
        '${directory.path}${Platform.pathSeparator}${fileOf('bad')}',
      );
      await corrupt.writeAsString('{ truncated');

      await expectLater(
        store.snapshot(CourseStoreKind.custom, 'bad'),
        throwsFormatException,
      );
      await expectLater(
        store.createIfAbsent(CourseStoreKind.custom, 'bad', {'v': 2}),
        throwsFormatException,
      );
      expect(await corrupt.readAsString(), '{ truncated');
      expect((await store.snapshot(CourseStoreKind.custom, 'healthy'))!.entry, {
        'v': 1,
      });
    },
  );

  test('a truncated writer result leaves the previous Course intact', () async {
    final good = CourseFileStore(supportDirectory: supportDirectory);
    await good.createIfAbsent(CourseStoreKind.custom, 'a', {'v': 1});
    final old = (await good.snapshot(CourseStoreKind.custom, 'a'))!;
    final directory = await good.directoryFor(CourseStoreKind.custom);
    final target = File(
      '${directory.path}${Platform.pathSeparator}${fileOf('a')}',
    );
    final originalBytes = await target.readAsBytes();
    final broken = CourseFileStore(
      supportDirectory: supportDirectory,
      fileWriter: (temporary, contents) async {
        await temporary.writeAsString(
          contents.substring(0, contents.length - 1),
          flush: true,
        );
      },
    );

    await expectLater(
      broken.replaceIfUnchanged(CourseStoreKind.custom, 'a', {
        'v': 2,
      }, expectedToken: old.token),
      throwsStateError,
    );
    expect(await target.readAsBytes(), originalBytes);
    expect(await File('${target.path}.tmp').exists(), isFalse);
  });

  test(
    'an external replacement during staging defeats a stale token',
    () async {
      final good = CourseFileStore(supportDirectory: supportDirectory);
      await good.createIfAbsent(CourseStoreKind.custom, 'a', {'v': 1});
      final original = (await good.snapshot(CourseStoreKind.custom, 'a'))!;
      final directory = await good.directoryFor(CourseStoreKind.custom);
      final target = File(
      '${directory.path}${Platform.pathSeparator}${fileOf('a')}',
    );
      final staged = Completer<void>();
      final release = Completer<void>();
      final delayed = CourseFileStore(
        supportDirectory: supportDirectory,
        fileWriter: (temporary, contents) async {
          await temporary.writeAsString(contents, flush: true);
          staged.complete();
          await release.future;
        },
      );

      final replacement = delayed.replaceIfUnchanged(
        CourseStoreKind.custom,
        'a',
        {'v': 2},
        expectedToken: original.token,
      );
      await staged.future;
      await target.writeAsString('{"courseId":"a","entry":{"v":9}}');
      release.complete();

      await expectLater(replacement, throwsStateError);
      expect((await good.snapshot(CourseStoreKind.custom, 'a'))!.entry, {
        'v': 9,
      });
      expect(
        (await directory.list().toList()).whereType<File>().where(
          (file) => file.path.endsWith('.tmp'),
        ),
        isEmpty,
      );
    },
  );

  test('an external create during staging is never overwritten', () async {
    final staged = Completer<void>();
    final release = Completer<void>();
    final delayed = CourseFileStore(
      supportDirectory: supportDirectory,
      fileWriter: (temporary, contents) async {
        await temporary.writeAsString(contents, flush: true);
        staged.complete();
        await release.future;
      },
    );

    final creation = delayed.createIfAbsent(CourseStoreKind.custom, 'a', {
      'v': 1,
    });
    await staged.future;
    final directory = await delayed.directoryFor(CourseStoreKind.custom);
    final target = File(
      '${directory.path}${Platform.pathSeparator}${fileOf('a')}',
    );
    await target.writeAsString('{"courseId":"a","entry":{"v":9}}');
    release.complete();

    await expectLater(creation, throwsStateError);
    expect((await delayed.snapshot(CourseStoreKind.custom, 'a'))!.entry, {
      'v': 9,
    });
  });

  test('Course lock is shared across instances and kinds', () async {
    final first = CourseFileStore(supportDirectory: supportDirectory);
    final second = CourseFileStore(supportDirectory: supportDirectory);
    final entered = Completer<void>();
    final release = Completer<void>();
    var secondStarted = false;

    final firstAction = first.withCourseLock('course/a', () async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final secondAction = second.withCourseLock('course:a', () async {
      secondStarted = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(secondStarted, isFalse);

    release.complete();
    await Future.wait([firstAction, secondAction]);
    expect(secondStarted, isTrue);
    await first.withCourseLock('course/a', () async {
      await first.createIfAbsent(CourseStoreKind.custom, 'course/a', {'v': 1});
    });
  });

  test('Windows case aliases share the canonical file lock', () async {
    final first = CourseFileStore(supportDirectory: supportDirectory);
    final second = CourseFileStore(supportDirectory: supportDirectory);
    final entered = Completer<void>();
    final release = Completer<void>();
    var secondStarted = false;

    final firstAction = first.withCourseLock('Case', () async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final secondAction = second.withCourseLock('case', () async {
      secondStarted = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final startedBeforeRelease = secondStarted;
    release.complete();
    await Future.wait([firstAction, secondAction]);

    expect(startedBeforeRelease, isFalse);
    expect(secondStarted, isTrue);
  }, skip: !Platform.isWindows);

  test('a delayed child cannot reuse a released lock owner', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    final wakeChild = Completer<void>();
    final childEntered = Completer<void>();
    final blockerEntered = Completer<void>();
    final releaseBlocker = Completer<void>();
    var childAcquired = false;
    late Future<void> child;

    await store.withCourseLock('a', () async {
      child = () async {
        await wakeChild.future;
        childEntered.complete();
        await store.withCourseLock('a', () async {
          childAcquired = true;
        });
      }();
    });
    final blocker = store.withCourseLock('a', () async {
      blockerEntered.complete();
      await releaseBlocker.future;
    });
    await blockerEntered.future;
    wakeChild.complete();
    await childEntered.future;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final acquiredWhileBlocked = childAcquired;
    releaseBlocker.complete();
    await Future.wait([blocker, child]);

    expect(acquiredWhileBlocked, isFalse);
    expect(childAcquired, isTrue);
  });
}
