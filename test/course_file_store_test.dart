import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  Future<Directory> supportDirectory() async => support;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('qql_course_store_');
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test('an empty store reads as empty rather than failing', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    expect(await store.readAll(CourseStoreKind.custom), isEmpty);
    expect(await store.readAll(CourseStoreKind.externalOfficial), isEmpty);
    expect(await store.contains(CourseStoreKind.custom, 'nothing'), isFalse);
  });

  test('a Course round-trips and keeps the two kinds separate', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);

    await store.write(CourseStoreKind.custom, 'course-a', {'title': 'A'});
    await store.write(CourseStoreKind.externalOfficial, 'course-a', {
      'title': 'Official A',
    });

    expect(await store.readAll(CourseStoreKind.custom), {
      'course-a': {'title': 'A'},
    });
    expect(await store.readAll(CourseStoreKind.externalOfficial), {
      'course-a': {'title': 'Official A'},
    });
    expect(await store.contains(CourseStoreKind.custom, 'course-a'), isTrue);
  });

  test('saving one Course leaves the others untouched', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.write(CourseStoreKind.custom, 'a', {'v': 1});
    await store.write(CourseStoreKind.custom, 'b', {'v': 1});

    final directory = await store.directoryFor(CourseStoreKind.custom);
    final before = await File(
      '${directory.path}${Platform.pathSeparator}b.json',
    ).lastModified();

    await store.write(CourseStoreKind.custom, 'a', {'v': 2});

    final after = await File(
      '${directory.path}${Platform.pathSeparator}b.json',
    ).lastModified();
    expect(after, before, reason: 'an unrelated Course file was rewritten');
    expect(await store.readAll(CourseStoreKind.custom), {
      'a': {'v': 2},
      'b': {'v': 1},
    });
  });

  test('strict readAll refuses the store while a file is unreadable', () async {
    // readAll is for callers that must see every Course; listing and saving use
    // readReadable, which returns the others (unreadable_stored_courses_243).
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.write(CourseStoreKind.custom, 'good', {'v': 1});
    final directory = await store.directoryFor(CourseStoreKind.custom);
    final broken = File('${directory.path}${Platform.pathSeparator}bad.json');
    await broken.writeAsString('{ not json');

    await expectLater(
      store.readAll(CourseStoreKind.custom),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('bad.json'), contains('preserved')),
        ),
      ),
    );

    // The damaged file is left exactly as it was, and the good one still reads.
    expect(await broken.readAsString(), '{ not json');
    await broken.delete();
    expect(await store.readAll(CourseStoreKind.custom), {
      'good': {'v': 1},
    });
  });

  test('the Course ID comes from the record, not the file name', () async {
    // Sanitizing for the filesystem is lossy, so the file name cannot be the
    // authority for identity.
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.write(CourseStoreKind.custom, 'weird id/with:chars', {'v': 1});

    final directory = await store.directoryFor(CourseStoreKind.custom);
    final files = await directory.list().toList();
    expect(files, hasLength(1));
    expect(files.single.path, isNot(contains('/with:')));

    expect(await store.readAll(CourseStoreKind.custom), {
      'weird id/with:chars': {'v': 1},
    });
  });

  test('a failed write leaves no temporary file and no target', () async {
    final store = CourseFileStore(
      supportDirectory: supportDirectory,
      fileWriter: (target, contents) async =>
          throw const FileSystemException('disk full'),
    );

    await expectLater(
      store.write(CourseStoreKind.custom, 'a', {'v': 1}),
      throwsA(isA<FileSystemException>()),
    );

    final directory = await store.directoryFor(CourseStoreKind.custom);
    expect(await directory.list().toList(), isEmpty);
    expect(await store.readAll(CourseStoreKind.custom), isEmpty);
  });

  test('a failed write cannot damage the Course already stored', () async {
    var failing = false;
    final store = CourseFileStore(
      supportDirectory: supportDirectory,
      fileWriter: (target, contents) async {
        if (failing) throw const FileSystemException('disk full');
        await target.writeAsString(contents, flush: true);
      },
    );
    await store.write(CourseStoreKind.custom, 'a', {'v': 1});

    failing = true;
    await expectLater(
      store.write(CourseStoreKind.custom, 'a', {'v': 2}),
      throwsA(isA<FileSystemException>()),
    );

    // Temp-then-rename means the previous version is still intact.
    expect(await store.readAll(CourseStoreKind.custom), {
      'a': {'v': 1},
    });
  });

  test('a Course above the size limit is refused', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    final huge = 'x' * (CourseFileStore.maxCourseBytes + 1);

    await expectLater(
      store.write(CourseStoreKind.custom, 'a', {'blob': huge}),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('10 MB'),
        ),
      ),
    );
    expect(await store.readAll(CourseStoreKind.custom), isEmpty);
  });

  test('remove deletes one Course and tolerates a missing one', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.write(CourseStoreKind.custom, 'a', {'v': 1});
    await store.write(CourseStoreKind.custom, 'b', {'v': 1});

    await store.remove(CourseStoreKind.custom, 'a');
    expect(await store.readAll(CourseStoreKind.custom), {
      'b': {'v': 1},
    });

    await store.remove(CourseStoreKind.custom, 'a');
    await store.remove(CourseStoreKind.custom, 'never-existed');
    expect(await store.readAll(CourseStoreKind.custom), {
      'b': {'v': 1},
    });
  });

  test('records are plain JSON on disk under a versioned root', () async {
    final store = CourseFileStore(supportDirectory: supportDirectory);
    await store.write(CourseStoreKind.custom, 'a', {'title': 'A'});

    final root = await store.rootDirectory();
    expect(root.path, endsWith(CourseFileStore.rootDirectoryName));

    final file = File(
      '${root.path}${Platform.pathSeparator}custom${Platform.pathSeparator}a.json',
    );
    expect(jsonDecode(await file.readAsString()), {
      'courseId': 'a',
      'entry': {'title': 'A'},
    });
  });
}
