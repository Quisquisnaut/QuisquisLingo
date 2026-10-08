import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/debug_screen.dart';
import 'package:quisquislingo_app/screens/inventory_screen.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/crash_log_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/inventory_action_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publisher_export_memory.dart';
import 'package:quisquislingo_app/services/stored_course_reader.dart';
import 'package:quisquislingo_app/widgets/folder_opener.dart';
import 'package:quisquislingo_app/widgets/reported_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/test_directories.dart';

/// Build 266 Revision 2 (owner, 8 October 2026: "test extensively edge
/// cases, that is, special situations that can cause issues"). A stored
/// Course this version cannot open, or a stored file it cannot read, must
/// never stop a feature, must be named, logged and removable in the app.
///
/// The stored files: a Course whose GuideBook has the shape before Build
/// 266 (the owner's case), a Course of an unsupported formatVersion, a
/// Course with a field of the wrong type, broken JSON, an empty file, JSON
/// without a Course ID, and two files claiming one Course ID; next to them
/// one ordinary Course.

const _admin = '11111111-1111-4111-8111-111111111111';
const _bea = '22222222-2222-4222-8222-222222222222';
const _carl = '33333333-3333-4333-8333-333333333333';
const _pin = '4321';

Course _course(String id, String maintainer, {String? title}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: 'Author',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-10-01T09:00:00.000Z',
  modifiedAtUtc: '2026-10-01T09:00:00.000Z',
  lastVersionEditorProfileId: maintainer,
  lastVersionEditorDisplayName: 'Author',
  publicationState: PublicationState.published,
  courseVersion: '1',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title ?? 'Course $id',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.published,
      updatedAt: DateTime.utc(2026, 10, 1),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

Future<Directory> _customFolder() =>
    CourseFileStore().directoryFor(CourseStoreKind.custom, create: true);

Future<File> _writeRaw(String name, String contents) async {
  final file = File(
    '${(await _customFolder()).path}${Platform.pathSeparator}$name',
  );
  await file.writeAsString(contents);
  return file;
}

/// [course] stored as a file, with [change] applied to its Course JSON.
Future<File> _store(
  Course course, {
  void Function(Map<String, dynamic> json)? change,
  String? fileName,
}) async {
  final json = course.toJson();
  change?.call(json);
  return _writeRaw(
    fileName ?? 'QQL_EN_IT_${course.courseId}.json',
    jsonEncode({
      'courseId': course.courseId,
      'entry': {'savedAt': '2026-10-08T09:00:00.000Z', 'course': json},
    }),
  );
}

/// The owner's case: a GuideBook in the shape before Build 266.
void _earlierGuidebook(Map<String, dynamic> json) {
  ((json['lessons'] as List).first as Map)['guidebook'] = {
    'content': <Object>[],
    'insights': <Object>[],
  };
}

Future<String> _diagnosticLog() async =>
    utf8.decode(await DiagnosticLogService().exportBytes() ?? const []);

void main() {
  late ProfileService profiles;

  /// Every kind of stored file this version cannot use, beside one ordinary
  /// Course; returns the files that are not Courses at all.
  Future<List<File>> storeEdgeCases() async {
    await _store(_course('good', _admin, title: 'Ordinary'));
    await _store(
      _course('earlier', _bea, title: 'Earlier GuideBook'),
      change: _earlierGuidebook,
    );
    await _store(
      _course('v11', _carl, title: 'Old format'),
      change: (json) => json['formatVersion'] = 11,
    );
    await _store(
      _course('wrong-type', _carl, title: 'Wrong type'),
      change: (json) => json['lessons'] = 'not a list',
    );
    return [
      await _writeRaw('QQL_broken.json', '{"courseId": "broken", "entry": '),
      await _writeRaw('QQL_empty.json', ''),
      await _writeRaw('QQL_no_id.json', '{"entry": {}}'),
      await _writeRaw('QQL_twin_a.json', '{"courseId": "twin", "entry": {}}'),
      await _writeRaw('QQL_twin_b.json', '{"courseId": "twin", "entry": {}}'),
    ];
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    StoredCourseReader.resetLogForTests();
    profiles = ProfileService();
    for (final (id, name) in [
      (_admin, 'Admin'),
      (_bea, 'Bea'),
      (_carl, 'Carl'),
    ]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    await profiles.setActiveProfileById(_admin);
    await profiles.setOwnAccessPin(actorProfileId: _admin, pin: _pin);
  });

  group('StoredCourseReader', () {
    test('opens a Course, or says what its JSON still names', () {
      final good = _course('good', _admin);
      final entry = {'course': good.toJson()};
      expect(StoredCourseReader.open('good', entry).course?.title, isNotNull);

      final earlier = good.toJson();
      _earlierGuidebook(earlier);
      final read = StoredCourseReader.open('good', {'course': earlier});
      expect(read.course, isNull);
      expect(read.unopenable!.maintainerProfileId, _admin);
      expect(read.unopenable!.title, 'Course good');
      expect(read.unopenable!.reason, contains('earlier shape'));

      for (final broken in <Object?>[
        null,
        'text',
        {'course': 'text'},
        {'course': {}},
        {
          'course': {...good.toJson(), 'lessons': 3},
        },
        {
          'course': {...good.toJson(), 'title': 7},
        },
      ]) {
        final result = StoredCourseReader.open('x', broken);
        expect(result.course, isNull, reason: '$broken');
        expect(result.unopenable!.courseId, 'x');
      }
    });
  });

  group('every reader of stored Courses keeps working', () {
    test('the Course list names each file and logs once', () async {
      await storeEdgeCases();
      final editor = CourseEditorService();
      final courses = await editor.listUserCourses();
      expect(courses.map((course) => course.courseId), ['good']);
      final unreadable = editor.unreadableCourseFiles;
      expect(
        unreadable.map((file) => file.fileName),
        containsAll([
          'QQL_EN_IT_earlier.json',
          'QQL_EN_IT_v11.json',
          'QQL_EN_IT_wrong-type.json',
          'QQL_broken.json',
          'QQL_empty.json',
          'QQL_no_id.json',
          'QQL_twin_a.json',
          'QQL_twin_b.json',
        ]),
      );
      expect(
        {
          for (final file in unreadable)
            if (file.isRemovableCustomCourse) file.courseId,
        },
        {'earlier', 'v11', 'wrong-type'},
      );
      // Listed twice, logged once per session.
      await editor.listUserCourses();
      await Future<void>.delayed(Duration.zero);
      final log = await _diagnosticLog();
      expect(log, contains('COURSE-002'));
      expect('“Earlier GuideBook”'.allMatches(log), hasLength(1));
      expect(log, contains('QQL_EN_IT_earlier.json'));
    });

    test('the reset preview completes and counts their Maintainers', () async {
      await storeEdgeCases();
      final preview = await AppResetService(profiles: profiles).preview();
      expect(preview.hasCustomCourses, isTrue);
      expect(
        preview.coursesMaintainedByNonAdmins,
        containsAll([
          '“Earlier GuideBook” (which this version cannot open)',
          '“Old format” (which this version cannot open)',
        ]),
      );
    });

    test('Remove custom courses removes them all', () async {
      await storeEdgeCases();
      await AppResetService(
        profiles: profiles,
      ).reset(AppResetScope.customCourses, actorProfileId: _admin, pin: _pin);
      expect(await (await _customFolder()).list().toList(), isEmpty);
      expect(await CourseEditorService().listUserCourses(), isEmpty);
    });

    test('a learner who maintains one is not deleted; others are', () async {
      final notCourses = await storeEdgeCases();
      // While a file cannot be read at all, QQL cannot tell who maintains
      // it: the deletion is refused and says where to remove the file.
      await expectLater(
        profiles.deleteProfileById(_carl, actorProfileId: _admin),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Inventory'),
          ),
        ),
      );
      final actions = InventoryActionService(profiles: profiles);
      for (final file in notCourses) {
        await actions.run(
          InventoryAction(
            InventoryActionKind.deleteFile,
            file.path,
            label: 'Delete',
            explanation: '',
          ),
          actorProfileId: _admin,
          pin: _pin,
        );
      }
      await expectLater(
        profiles.deleteProfileById(_bea, actorProfileId: _admin),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('“Earlier GuideBook”, which this version cannot open'),
          ),
        ),
      );
      // Carl maintains two Courses this version cannot open.
      await CourseEditorService().deleteUserCourse('v11');
      await CourseEditorService().deleteUserCourse('wrong-type');
      await profiles.deleteProfileById(_carl, actorProfileId: _admin);
      expect(await profiles.getProfileById(_carl), isNull);
    });
  });

  group('a Course this version cannot open can be removed or replaced', () {
    test('by its Maintainer or an admin, nobody else', () async {
      await _store(_course('earlier', _bea), change: _earlierGuidebook);
      final media = CourseMediaStore();
      final mediaFolder = await media.courseDirectory('earlier', create: true);
      await File(
        '${mediaFolder.path}${Platform.pathSeparator}a.mp3',
      ).writeAsBytes(const [1, 2, 3]);

      await profiles.setActiveProfileById(_carl);
      await expectLater(
        CourseEditorService().deleteUserCourse('earlier'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Only its Maintainer, a member of its Team or an admin'),
          ),
        ),
      );
      await profiles.setActiveProfileById(_admin, accessPin: _pin);
      await CourseEditorService().deleteUserCourse('earlier');
      expect(await CourseEditorService().unopenableCourse('earlier'), isNull);
      expect(await mediaFolder.exists(), isFalse);
    });

    test('the import review offers Replace to its Maintainer only', () async {
      await _store(
        _course('earlier', _bea, title: 'Old'),
        change: _earlierGuidebook,
      );
      Future<CourseImportReview> review() async {
        final editor = CourseEditorService();
        final ops = CourseLibraryOperations(editor: editor);
        final library = await ops.load(importOnly: true);
        final attempt = CoursePackageImport(
          CoursePackage(
            _course('earlier', _bea, title: 'Regenerated'),
            Uint8List(0),
            const {},
          ),
          editor: editor,
        );
        try {
          return await ops.reviewImport(attempt, library);
        } finally {
          await attempt.close();
        }
      }

      await profiles.setActiveProfileById(_bea);
      final mine = await review();
      expect(mine.existing, isNull);
      expect(mine.existingUnopenable?.title, 'Old');
      expect(mine.choices, contains(CourseImportChoice.replace));
      await profiles.setActiveProfileById(_carl);
      final theirs = await review();
      expect(theirs.choices, isNot(contains(CourseImportChoice.replace)));
      expect(theirs.replaceUnavailableReason, contains('Maintainer'));
    });

    test('importing it again with the same ID replaces it', () async {
      await _store(
        _course('earlier', _bea, title: 'Old'),
        change: _earlierGuidebook,
      );
      final regenerated = _course('earlier', _bea, title: 'Regenerated');
      await profiles.setActiveProfileById(_carl);
      await expectLater(
        CourseEditorService().installImportedCustomCourse(regenerated),
        throwsA(isA<StateError>()),
      );
      await profiles.setActiveProfileById(_bea);
      await CourseEditorService().installImportedCustomCourse(regenerated);
      final listed = await CourseEditorService().listUserCourses();
      expect(listed.single.title, 'Regenerated');
    });
  });

  group('the Inventory', () {
    test('every stored file has its action', () async {
      await storeEdgeCases();
      final sections = await InventoryService(profiles: profiles).load();
      final stored = sections.firstWhere(
        (section) => section.title == 'Custom and installed courses',
      );
      InventoryAction? actionOf(String fileName) => stored.items
          .firstWhere((item) => item.path!.endsWith(fileName))
          .action;
      expect(
        actionOf('QQL_EN_IT_good.json')!.kind,
        InventoryActionKind.deleteCourse,
      );
      expect(
        actionOf('QQL_EN_IT_earlier.json')!.kind,
        InventoryActionKind.deleteCourse,
      );
      expect(actionOf('QQL_EN_IT_earlier.json')!.target, 'earlier');
      expect(actionOf('QQL_broken.json')!.kind, InventoryActionKind.deleteFile);
      for (final item in stored.items) {
        expect(item.folder, isNotNull);
      }
      final learners = sections.firstWhere((s) => s.title == 'Learners');
      expect(
        learners.items.map((item) => item.action?.kind),
        everyElement(InventoryActionKind.deleteLearner),
      );
    });

    test('Delete and Forget need the PIN and stay in QQL\'s folders', () async {
      final actions = InventoryActionService(profiles: profiles);
      final outside = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'qql_outside_${DateTime.now().microsecondsSinceEpoch}.txt',
      )..writeAsStringSync('keep me');
      addTearDown(() {
        if (outside.existsSync()) outside.deleteSync();
      });
      Future<void> run(InventoryAction action, {String pin = _pin}) =>
          actions.run(action, actorProfileId: _admin, pin: pin);
      InventoryAction deleteFile(String path) => InventoryAction(
        InventoryActionKind.deleteFile,
        path,
        label: 'Delete',
        explanation: '',
      );

      await expectLater(
        run(deleteFile(outside.path), pin: '0000'),
        throwsA(
          isA<InventoryActionException>().having(
            (e) => e.message,
            'message',
            'Incorrect PIN. Nothing was changed.',
          ),
        ),
      );
      await expectLater(
        run(deleteFile(outside.path)),
        throwsA(isA<InventoryActionException>()),
      );
      expect(outside.existsSync(), isTrue);
      final crashLog = File(
        '${testSupportDirectory.path}${Platform.pathSeparator}'
        '${DiagnosticLogService.logsDirectoryName}${Platform.pathSeparator}'
        'QQL_crash.log',
      )..createSync(recursive: true);
      await expectLater(
        run(deleteFile(crashLog.path)),
        throwsA(isA<InventoryActionException>()),
      );
      expect(crashLog.existsSync(), isTrue);

      final prefs = await SharedPreferences.getInstance();
      final remembered = '${PublisherExportMemory.keyPrefix}course';
      await prefs.setString(remembered, '{}');
      await prefs.setString('something_else', 'x');
      InventoryAction forget(String key) => InventoryAction(
        InventoryActionKind.forget,
        key,
        label: 'Forget',
        explanation: '',
      );
      await expectLater(
        run(forget('something_else')),
        throwsA(isA<InventoryActionException>()),
      );
      await run(forget(remembered));
      expect(prefs.containsKey(remembered), isFalse);
      expect(prefs.getString('something_else'), 'x');
    });

    testWidgets('Forget asks for the PIN, then lists again', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final key = '${PublisherExportMemory.keyPrefix}remembered';
      await prefs.setString(
        key,
        jsonEncode({'publisherId': 'org.example', 'publisherName': 'Example'}),
      );
      FolderOpener.available = () => false;
      addTearDown(() => FolderOpener.available = () => true);
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: InventoryScreen(profileService: profiles)),
      );
      final forget = find.byKey(
        const Key('inventory-Remembered publishers-0-action'),
      );
      await tester.pumpUntilFileIoState(() => forget.evaluate().isNotEmpty);
      await tester.pumpAndSettle();
      await tester.ensureVisible(forget);
      await tester.tap(forget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inventory-action-dialog')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('inventory-action-pin')),
        '0000',
      );
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('inventory-action-error'))
            .evaluate()
            .isNotEmpty,
      );
      expect(prefs.containsKey(key), isTrue);
      await tester.enterText(
        find.byKey(const Key('inventory-action-pin')),
        _pin,
      );
      await tester.tap(find.byKey(const Key('inventory-action-run')));
      await tester.pumpUntilFileIoState(
        () =>
            find.byKey(const Key('inventory-action-dialog')).evaluate().isEmpty,
      );
      await tester.pumpAndSettle();
      expect(prefs.containsKey(key), isFalse);
      // No Open folder where the system cannot open folders.
      expect(find.textContaining('Open folder'), findsNothing);
    });
  });

  group('errors reach the person and the Diagnostic Log', () {
    testWidgets('runReported shows and logs what failed', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      final result = await tester.runAsync(
        () => runReported<int>(
          context,
          'The test action',
          () async => throw StateError('the store is locked'),
        ),
      );
      await tester.pump();
      expect(result, isNull);
      expect(
        find.text('The test action could not finish: the store is locked'),
        findsOneWidget,
      );
      final log = await tester.runAsync(_diagnosticLog);
      expect(log, contains('APP-001'));
      expect(log, contains('The test action could not finish.'));
      expect(readableError(const FormatException('bad')), 'bad');
      expect(readableError(ArgumentError('worse')), 'worse');
    });

    test('an unhandled error also gets a short Diagnostic Log entry', () async {
      await CrashLogService.instance.recordUnhandled(
        StateError('nobody caught this'),
        StackTrace.current,
        source: 'test',
      );
      final log = await _diagnosticLog();
      expect(log, contains('Unhandled error (test)'));
      expect(log, contains('nobody caught this'));
      expect(log, contains('Crash Log'));
    });

    testWidgets('Save&Open saves a fresh copy and opens its folder', (
      tester,
    ) async {
      final opened = <String>[];
      FolderOpener.available = () => true;
      FolderOpener.open = (folder) async {
        opened.add(folder);
        return true;
      };
      addTearDown(() {
        FolderOpener.open = (folder) async => false;
      });
      await tester.runAsync(
        () => DiagnosticLogService().logInfo('something to send'),
      );
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: DebugScreen()));
      final button = find.byKey(const Key('save-open-diagnostic-log'));
      await tester.pumpUntilFileIoState(
        () =>
            button.evaluate().isNotEmpty &&
            tester.widget<TextButton>(button).onPressed != null,
      );
      expect(find.text('Save&Open'), findsWidgets);
      await tester.tap(button);
      await tester.pumpUntilFileIoState(() => opened.isNotEmpty);
      await tester.pumpAndSettle();
      expect(opened.single, endsWith('Logs'));
      final copy = Directory(opened.single).listSync().whereType<File>().single;
      expect(copy.readAsStringSync(), contains('something to send'));
      expect(find.textContaining('its folder is open'), findsOneWidget);
    });
  });
}
