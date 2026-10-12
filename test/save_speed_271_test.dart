import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/course_saving.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unique_png.dart';

const _alice = '11111111-1111-4111-8111-111111111111';

Course _course(
  String id, {
  List<String> images = const [],
  String title = 'Speed',
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _alice,
    displayName: 'Alice',
  ),
  maintainer: const CourseMaintainer(_alice),
  originalCreatedAtUtc: '2026-10-12T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  imageLibrary: [
    for (final image in images) CourseImageLibraryEntry(asset: image),
  ],
  lessons: const [],
);

/// The same picture with one byte changed: another content, the same length.
Uint8List _changed(List<int> bytes) =>
    Uint8List.fromList(bytes)..[bytes.length ~/ 2] ^= 0xff;

// Build 271 Revision 3 (owner report of 12 October 2026: Save works, but it
// is slow and nothing shows the time it takes). A save's backup no longer
// reads every picture and recording three times, a save no longer reads
// every stored Course three times, and a window shows where the save is.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a backup does not read again what the backups hold', () {
    late Directory backupsRoot;
    late Directory support;
    late CourseMediaStore media;
    late CourseBackupService backups;
    late List<String> written;
    late List<String> logged;

    setUp(() async {
      backupsRoot = await Directory.systemTemp.createTemp('qql_271_backups_');
      support = await Directory.systemTemp.createTemp('qql_271_media_');
      media = CourseMediaStore(supportDirectory: () async => support);
      written = [];
      logged = [];
      backups = CourseBackupService(
        backupsDirectoryProvider: () async => backupsRoot,
        mediaStore: media,
        fileWriter: (file, bytes) async {
          written.add(file.uri.pathSegments.last);
          await file.writeAsBytes(bytes, flush: true);
        },
        log: (message) async => logged.add(message),
      );
    });

    tearDown(() async {
      for (final directory in [backupsRoot, support]) {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    });

    Future<String> stored(int seed) =>
        media.addBytes('speed', uniquePng(seed), 'png');

    Future<CourseBackupRecord> backUp(
      List<String> images,
      int hour, {
      void Function(int done, int total)? onProgress,
    }) => backups.createBackup(
      _course('speed', images: images),
      backedUpAt: DateTime.utc(2026, 10, 12, hour),
      reason: 'Pre-change Course Editor transaction backup',
      onProgress: onProgress,
    );

    File copyOf(CourseBackupRecord record, String reference) => File(
      '${record.manifestFile.parent.path}${Platform.pathSeparator}'
      '${CourseBackupService.sharedMediaFolderName}${Platform.pathSeparator}'
      '${CourseMediaStore.fileNameOf(reference)}',
    );

    test('the second version writes its own file only and names the copies '
        'the first one made', () async {
      final a = await stored(1);
      final b = await stored(2);
      final first = await backUp([a, b], 10);
      expect(
        written,
        unorderedEquals([
          CourseMediaStore.fileNameOf(a),
          CourseMediaStore.fileNameOf(b),
          first.manifestFile.uri.pathSegments.last,
        ]),
      );

      written.clear();
      final second = await backUp([a, b], 11);

      expect(written, [second.manifestFile.uri.pathSegments.last]);
      expect(second.assets, hasLength(2));
      for (final asset in second.assets) {
        final reference = asset['reference']!;
        expect(
          asset['backupRelativePath'],
          '${CourseBackupService.sharedMediaFolderName}/'
          '${CourseMediaStore.fileNameOf(reference)}',
        );
        expect(asset['sha256'], CourseMediaStore.digestOf(reference));
        expect(asset.containsKey('missing'), isFalse);
      }
      // Read on its own, with every file's content checked, it is whole.
      final checked = await backups.loadBackup(
        second.manifestFile,
        expectedCourseId: 'speed',
      );
      expect(checked.assets, second.assets);
    });

    test('a copy is told by its name and its length: neither it nor the '
        'stored file is read again', () async {
      final a = await stored(3);
      final first = await backUp([a], 10);
      // Both changed where a reading would notice and a length would not.
      final original = await copyOf(first, a).readAsBytes();
      final storedFile = await media.fileFor('speed', a);
      await storedFile.writeAsBytes(_changed(original), flush: true);
      await copyOf(first, a).writeAsBytes(_changed(original), flush: true);

      written.clear();
      final second = await backUp([a], 11);

      expect(written, [second.manifestFile.uri.pathSegments.last]);
      expect(second.assets.single['reference'], a);
      expect(second.assets.single.containsKey('missing'), isFalse);
      expect(logged, isEmpty);
      expect(await copyOf(first, a).readAsBytes(), _changed(original));
    });

    test('a stored file of another length is read, and is a gap when it is '
        'not what its name says', () async {
      final a = await stored(4);
      final b = await stored(5);
      await backUp([a, b], 10);
      final storedFile = await media.fileFor('speed', b);
      await storedFile.writeAsBytes(const [1, 2, 3], flush: true);

      final second = await backUp([a, b], 11);

      final gap = second.assets.singleWhere((a) => a['missing'] == 'true');
      expect(gap['reference'], b);
      expect(gap['damaged'], 'true');
      expect(logged.single, contains('no longer matches its name'));
      final kept = second.assets.singleWhere((a) => a['missing'] != 'true');
      expect(kept['reference'], a);
    });

    test('a copy of another length is written again', () async {
      final a = await stored(6);
      final first = await backUp([a], 10);
      final original = await copyOf(first, a).readAsBytes();
      await copyOf(first, a).writeAsBytes(const [1, 2, 3], flush: true);

      written.clear();
      await backUp([a], 11);

      expect(written, contains(CourseMediaStore.fileNameOf(a)));
      expect(await copyOf(first, a).readAsBytes(), original);
    });

    test('progress: none dealt with, then one more for each picture', () async {
      final images = [await stored(7), await stored(8), await stored(9)];
      final steps = <(int, int)>[];
      await backUp(
        images,
        10,
        onProgress: (done, total) {
          steps.add((done, total));
        },
      );
      expect(steps, [(0, 3), (1, 3), (2, 3), (3, 3)]);

      steps.clear();
      // The second time nothing is copied; it still counts every file.
      await backUp(
        images,
        11,
        onProgress: (done, total) {
          steps.add((done, total));
        },
      );
      expect(steps, [(0, 3), (1, 3), (2, 3), (3, 3)]);

      steps.clear();
      await backUp(
        const [],
        12,
        onProgress: (done, total) {
          steps.add((done, total));
        },
      );
      expect(steps, [(0, 0)]);
    });

    test('the list of versions looks whether the files are there; a restore '
        'checks what it puts back', () async {
      final a = await stored(10);
      final first = await backUp([a], 10);
      final original = await copyOf(first, a).readAsBytes();
      await copyOf(first, a).writeAsBytes(_changed(original), flush: true);

      // Listed: the file is there.
      final skipped = <String>[];
      final listed = await backups.listBackups('speed', skipped: skipped);
      expect(listed, hasLength(1));
      expect(skipped, isEmpty);
      // Read on its own, its content is checked.
      await expectLater(
        backups.loadBackup(first.manifestFile, expectedCourseId: 'speed'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A course backup asset failed integrity validation.',
          ),
        ),
      );
      // A restore puts nothing back that is not what the Course names.
      await media.deleteUnreferenced('speed', const {});
      await expectLater(
        backups.reinstateMedia(listed.single),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'A course backup asset failed integrity validation.',
          ),
        ),
      );
      expect(await media.storedReferences('speed'), isEmpty);

      // With the right content again, the restore puts it back.
      await copyOf(first, a).writeAsBytes(original, flush: true);
      await backups.reinstateMedia(listed.single);
      expect(await media.existingFile('speed', a), isNotNull);
    });

    test('a version whose file is gone is named, not listed', () async {
      final a = await stored(11);
      final b = await stored(12);
      final first = await backUp([a], 10);
      final second = await backUp([b], 11);
      await copyOf(first, a).delete();

      final skipped = <String>[];
      final listed = await backups.listBackups('speed', skipped: skipped);

      expect(listed.single.manifestFile.path, second.manifestFile.path);
      expect(skipped, [first.manifestFile.uri.pathSegments.last]);
      await expectLater(
        backups.listBackups('speed'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('a save finds its Course without reading the others', () {
    late Directory support;
    late CourseFileStore store;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('qql_271_store_');
      store = CourseFileStore(supportDirectory: () async => support);
    });

    tearDown(() async {
      if (await support.exists()) await support.delete(recursive: true);
    });

    Future<File> file(String name, String content) async {
      final directory = await store.directoryFor(
        CourseStoreKind.custom,
        create: true,
      );
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      await file.writeAsString(content, flush: true);
      return file;
    }

    test('the ID a stored file begins with', () async {
      Future<String?> leading(String content) async =>
          CourseFileStore.leadingCourseId(await file('probe.json', content));

      expect(await leading('{"courseId":"abc","entry":{"v":1}}'), 'abc');
      expect(
        await leading(jsonEncode({'courseId': 'a"b\\c é', 'entry': 1})),
        'a"b\\c é',
      );
      // What QQL writes, whatever follows.
      expect(await leading('{"courseId":"abc","entry":{ not json'), 'abc');
      // Any other shape is not told by its first bytes.
      expect(await leading('{\n  "courseId": "abc",\n  "entry": 1\n}'), isNull);
      expect(await leading('{"entry":1,"courseId":"abc"}'), isNull);
      expect(await leading('{"courseId":"abc"}'), isNull);
      expect(await leading('{"courseId":12,"entry":1}'), isNull);
      expect(await leading(''), isNull);
      expect(
        await leading(
          jsonEncode({
            'courseId': 'x' * (CourseFileStore.leadingBytes + 10),
            'entry': 1,
          }),
        ),
        isNull,
      );
      expect(
        await CourseFileStore.leadingCourseId(
          File('${support.path}${Platform.pathSeparator}missing.json'),
        ),
        isNull,
      );
    });

    test('what QQL wrote for a Course begins with its ID', () async {
      await store.write(CourseStoreKind.custom, 'course_"odd" é', {'v': 1});
      final directory = await store.directoryFor(CourseStoreKind.custom);
      final written = directory.listSync().whereType<File>().single;
      expect(await CourseFileStore.leadingCourseId(written), 'course_"odd" é');
    });

    test('another Course\'s file is passed over by its first bytes', () async {
      await store.write(CourseStoreKind.custom, 'wanted', {'v': 1});
      // Whole, this file could not be read; it begins as another Course's.
      await file('QQL_EN_IT_other.json', '{"courseId":"other","entry":{ no');

      final found = await store.snapshot(CourseStoreKind.custom, 'wanted');
      expect(found!.entry, {'v': 1});
      await store.write(CourseStoreKind.custom, 'wanted', {'v': 2});
      expect((await store.snapshot(CourseStoreKind.custom, 'wanted'))!.entry, {
        'v': 2,
      });
      expect(await store.snapshot(CourseStoreKind.custom, 'absent'), isNull);
    });

    test('a second file with the same ID is still refused, whatever its name '
        'and shape', () async {
      await store.write(CourseStoreKind.custom, 'wanted', {'v': 1});
      final copy = await file(
        'a copy.json',
        jsonEncode({
          'courseId': 'wanted',
          'entry': {'v': 9},
        }),
      );
      await expectLater(
        store.snapshot(CourseStoreKind.custom, 'wanted'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('Two stored Course records both claim'),
          ),
        ),
      );

      // Written by hand, with spaces and line breaks.
      await copy.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'courseId': 'wanted',
          'entry': {'v': 9},
        }),
        flush: true,
      );
      await expectLater(
        store.snapshot(CourseStoreKind.custom, 'wanted'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        store.write(CourseStoreKind.custom, 'wanted', {'v': 2}),
        throwsA(isA<FormatException>()),
      );

      // The same file holding another Course is no obstacle.
      await copy.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'courseId': 'someone-else',
          'entry': {'v': 9},
        }),
        flush: true,
      );
      expect((await store.snapshot(CourseStoreKind.custom, 'wanted'))!.entry, {
        'v': 1,
      });
    });

    test(
      'a file named for the Course that cannot be read is still refused',
      () async {
        await file('QQL_EN_IT_wanted.json', '{"courseId":"other","entry":{ no');
        await expectLater(
          store.snapshot(CourseStoreKind.custom, 'wanted'),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('a save says where it is', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final profiles = ProfileService();
      await profiles.createProfile(
        'Alice',
        learnerProfileId: _alice,
        generateScreenNameSuffix: false,
      );
      await profiles.setActiveProfileById(_alice);
    });

    test('the steps in words, and a bar that never goes back', () {
      const steps = [
        CourseSaveProgress(CourseSaveStep.checking),
        CourseSaveProgress(CourseSaveStep.backingUp),
        CourseSaveProgress(CourseSaveStep.backingUp, total: 4),
        CourseSaveProgress(CourseSaveStep.backingUp, done: 1, total: 4),
        CourseSaveProgress(CourseSaveStep.backingUp, done: 4, total: 4),
        CourseSaveProgress(CourseSaveStep.writing),
        CourseSaveProgress(CourseSaveStep.verifying),
      ];
      expect(
        [for (final step in steps) step.label],
        [
          'Checking the Course…',
          'Making the backup…',
          'Making the backup: 0 of 4 pictures and recordings',
          'Making the backup: 1 of 4 pictures and recordings',
          'Making the backup: 4 of 4 pictures and recordings',
          'Writing the Course…',
          'Checking what was written…',
        ],
      );
      final fractions = [for (final step in steps) step.fraction];
      expect(fractions, [...fractions]..sort());
      expect(fractions.first, greaterThan(0));
      expect(fractions.last, lessThan(1));
      expect(fractions[3], closeTo(.275, 1e-9));
    });

    test('a save reports checking, the backup file by file, writing and '
        'checking what was written', () async {
      final media = CourseMediaStore();
      final images = [
        await media.addBytes('says', uniquePng(21), 'png'),
        await media.addBytes('says', uniquePng(22), 'png'),
      ];
      final editor = CourseEditorService();
      await editor.installImportedCustomCourse(_course('says', images: images));
      final stored = (await editor.listUserCourses()).single;
      final steps = <(CourseSaveStep, int, int)>[];

      final result = await editor.confirmCourseTransaction(
        originalCourse: stored,
        workingCourse: Course.fromJson({
          ...stored.toJson(),
          'title': 'Saved again',
        }),
        languageCode: 'IT',
        versionNotes: 'Again',
        committedAt: DateTime.utc(2026, 10, 12, 10),
        onProgress: (progress) =>
            steps.add((progress.step, progress.done, progress.total)),
      );

      expect(result.course.title, 'Saved again');
      expect(steps, [
        (CourseSaveStep.checking, 0, 0),
        (CourseSaveStep.backingUp, 0, 0),
        (CourseSaveStep.backingUp, 0, 2),
        (CourseSaveStep.backingUp, 1, 2),
        (CourseSaveStep.backingUp, 2, 2),
        (CourseSaveStep.writing, 0, 0),
        (CourseSaveStep.verifying, 0, 0),
      ]);
    });

    test('a Course saved for the first time has no backup to make', () async {
      final editor = CourseEditorService();
      final course = _course('first-save');
      final steps = <CourseSaveStep>[];

      await editor.confirmCourseTransaction(
        originalCourse: course,
        workingCourse: course,
        languageCode: 'IT',
        versionNotes: 'Created',
        isNewCourse: true,
        committedAt: DateTime.utc(2026, 10, 12, 10),
        onProgress: (progress) => steps.add(progress.step),
      );

      expect(steps, [
        CourseSaveStep.checking,
        CourseSaveStep.writing,
        CourseSaveStep.verifying,
      ]);
    });

    test('a save with other Courses stored leaves them as they are and '
        'writes its own', () async {
      final editor = CourseEditorService();
      for (final id in ['one', 'two', 'three']) {
        await editor.installImportedCustomCourse(_course(id, title: id));
      }
      final stored = (await editor.listUserCourses()).firstWhere(
        (course) => course.courseId == 'two',
      );

      await editor.confirmCourseTransaction(
        originalCourse: stored,
        workingCourse: Course.fromJson({...stored.toJson(), 'title': 'Two!'}),
        languageCode: 'IT',
        versionNotes: 'Again',
        committedAt: DateTime.utc(2026, 10, 12, 10),
      );

      final after = {
        for (final course in await editor.listUserCourses())
          course.courseId: (course.title, course.courseVersion),
      };
      expect(after, {
        'one': ('one', '1'),
        'two': ('Two!', '2'),
        'three': ('three', '1'),
      });
    });
  });

  group('the window of a save', () {
    Future<void> pumpButton(
      WidgetTester tester,
      Future<void> Function(BuildContext context) onPressed,
    ) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => onPressed(context),
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      ),
    );

    const window = Key('course-saving');
    const bar = Key('course-saving-bar');
    const step = Key('course-saving-step');

    testWidgets('is there before the work starts, shows each step, stays '
        'through Back and a tap, and goes at the end', (tester) async {
      final work = Completer<String>();
      late void Function(CourseSaveProgress progress) report;
      var started = 0;
      bool? shownWhenStarted;
      String? result;
      await pumpButton(tester, (context) async {
        result = await CourseSaving.run<String>(context, (onProgress) {
          started++;
          shownWhenStarted = find.byKey(window).evaluate().isNotEmpty;
          report = onProgress;
          return work.future;
        });
      });

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();

      expect(started, 1);
      expect(shownWhenStarted, isTrue);
      expect(find.byKey(window), findsOneWidget);
      expect(find.text('Saving the Course…'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(step)).data,
        'Checking the Course…',
      );
      expect(
        tester.widget<LinearProgressIndicator>(find.byKey(bar)).value,
        .05,
      );

      report(
        const CourseSaveProgress(CourseSaveStep.backingUp, done: 1, total: 4),
      );
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(step)).data,
        'Making the backup: 1 of 4 pictures and recordings',
      );
      expect(
        tester.widget<LinearProgressIndicator>(find.byKey(bar)).value,
        closeTo(.275, 1e-9),
      );

      // Back and a tap on what is behind change nothing.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pump();
      expect(find.byKey(window), findsOneWidget);
      expect(started, 1);

      report(const CourseSaveProgress(CourseSaveStep.verifying));
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(step)).data,
        'Checking what was written…',
      );

      work.complete('saved');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(window), findsNothing);
      expect(result, 'saved');
    });

    testWidgets('a save never waits for a frame that does not come', (
      tester,
    ) async {
      // Frames stop while the app is hidden (a minimized window).
      final work = Completer<void>();
      var started = 0;
      await pumpButton(tester, (context) async {
        await CourseSaving.run<void>(context, (_) {
          started++;
          return work.future;
        });
      });

      await tester.tap(find.text('Save'));
      expect(started, 0);
      // Time passes before any frame is drawn.
      await tester.pump(CourseSaving.drawnWithin);
      expect(started, 1);

      work.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(window), findsNothing);
    });

    testWidgets('goes when the save fails, and the failure reaches the '
        'caller', (tester) async {
      Object? failure;
      await pumpButton(tester, (context) async {
        try {
          await CourseSaving.run<void>(
            context,
            (_) async => throw StateError('The disk is full.'),
          );
        } catch (error) {
          failure = error;
        }
      });

      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(failure, isA<StateError>());
      expect(find.byKey(window), findsNothing);
      // The page behind is in use again.
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byKey(window), findsOneWidget);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(window), findsNothing);
    });
  });
}
