import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_audit_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_import_check.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/course_import_check_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/test_directories.dart';
import 'support/unique_png.dart';

const _authorId = '12345678-1234-4234-9234-123456789abc';

/// A read package that counts how often it is let go.
class _CountedPackage extends CoursePackage {
  _CountedPackage(Course course) : super(course, Uint8List(0), const {});

  int discards = 0;

  @override
  Future<void> discard() async => discards++;
}

class _PackageMergeService extends CourseMergeService {
  _PackageMergeService(this.package);

  final CoursePackage package;

  @override
  Future<CoursePackage> readMergePackage() async => package;

  @override
  bool get fileDialogsAvailable => false;
}

/// Build 272 Revision 13: the pop-up of a Course import (and of a Merge's
/// second Course) stays until answered. With anomalies, going on uses the
/// file exactly as without the pop-up and Cancel stores nothing; without
/// anomalies it says so and tells about the Course.
void main() {
  late Directory imports;
  late CourseEditorService editor;

  setUp(() {
    // Off for the import tests written before the pop-up
    // (`test/flutter_test_config.dart`); this file is about it.
    CourseImportCheckDialog.enabled = true;
    keepCrashLogUnavailable();
  });
  tearDown(() => CourseImportCheckDialog.enabled = false);

  Future<List<String>> stagedFiles() async {
    final directory = Directory(
      '${testSupportDirectory.path}/${ImportStager.stagingDirectoryName}',
    );
    if (!await directory.exists()) return const [];
    return [
      await for (final entity in directory.list(recursive: true))
        if (entity is File) entity.path,
    ];
  }

  Future<void> writeJson(Map<String, dynamic> json) => File(
    '${imports.path}/import.json',
  ).writeAsString(jsonEncode(json), flush: true);

  /// Course Studio, with [incoming] waiting in the import folder and
  /// [installed] already stored. [importOnly] is the learner's Import page,
  /// pushed over another page as the app pushes it.
  Future<List<Object?>> openImport(
    WidgetTester tester, {
    Map<String, dynamic>? incoming,
    Uint8List? incomingZip,
    Course? installed,
    bool importOnly = false,
  }) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _authorId,
          displayName: 'Import Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _authorId,
    });
    editor = CourseEditorService();
    await tester.runAsync(() async {
      imports = await Directory.systemTemp.createTemp('qql_272_r13_imports_');
      if (installed != null) {
        await editor.installImportedCustomCourse(installed);
      }
      if (incoming != null) await writeJson(incoming);
      if (incomingZip != null) {
        await File(
          '${imports.path}/import.zip',
        ).writeAsBytes(incomingZip, flush: true);
      }
    });
    addTearDown(() async {
      if (await imports.exists()) await imports.delete(recursive: true);
    });
    final returned = <Object?>[];
    Widget studio() => CourseProjectsScreen(
      currentCourse: null,
      importOnly: importOnly,
      editorService: editor,
      transferService: CustomCourseTransferService(
        importDirectory: () async => imports,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: importOnly
            ? Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async => returned.add(
                      await Navigator.of(context).push<Object?>(
                        MaterialPageRoute(builder: (_) => studio()),
                      ),
                    ),
                    child: const Text('open import'),
                  ),
                ),
              )
            : studio(),
      ),
    );
    if (importOnly) {
      await tester.tap(find.text('open import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('import-course-json-primary'))
            .evaluate()
            .isNotEmpty,
      );
    } else {
      await tester.pumpUntilFileIoState(
        () => find.byTooltip('Course Import').evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Course Import'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    return returned;
  }

  Future<void> quickImport(WidgetTester tester, Finder until) async {
    await tester.tap(find.byKey(const Key('import-course-json-primary')));
    await tester.pumpUntilFileIoState(() => until.evaluate().isNotEmpty);
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  List<String> anomalyLines(WidgetTester tester) {
    final lines = <String>[];
    while (find
        .byKey(Key('import-anomaly-${lines.length}'))
        .evaluate()
        .isNotEmpty) {
      lines.add(textOf(tester, 'import-anomaly-${lines.length}'));
    }
    return lines;
  }

  final anomalies = find.byKey(const Key('import-anomalies'));
  final checked = find.byKey(const Key('import-checked'));
  final imported = find.textContaining('Imported “Incoming”');

  Map<String, dynamic> jsonOf(Course course) =>
      jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>;

  group('a file with anomalies', () {
    testWidgets('asks before anything is stored, and stays', (tester) async {
      await openImport(tester, incoming: jsonOf(_course(id: 'new')));
      await quickImport(tester, anomalies);

      expect(find.text('Check this Course before importing'), findsOneWidget);
      expect(find.text('The file names no author.'), findsOneWidget);
      expect(
        find.text(
          'A license is stated (All rights reserved) but no Rights Holder is '
          'named.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lessons without Rounds: 1.'), findsOneWidget);
      // The intro counts what is listed.
      final listed = anomalyLines(tester).length;
      expect(listed, greaterThanOrEqualTo(3));
      expect(
        textOf(tester, 'import-anomalies-intro'),
        'QuisquisLingo checked “Incoming” and found $listed things to look '
        'at before importing:',
      );
      expect(
        textOf(tester, 'import-check-reminder-0'),
        'The Course has no recordings: QuisquisLingo will use the device’s '
        'voice. Please check that Text-to-speech is set up correctly for '
        'Italian (Settings › Audio Settings).',
      );
      expect(
        textOf(tester, 'import-anomalies-outcome'),
        'Import anyway goes on with the import of the Course as it is. '
        'Cancel changes nothing on this device.',
      );
      expect(
        find.widgetWithText(FilledButton, 'Import anyway'),
        findsOneWidget,
      );
      expect(checked, findsNothing);
      expect(imported, findsNothing);
      final stored = await tester.runAsync(editor.listUserCourses);
      expect(stored, isEmpty, reason: 'nothing is stored while it asks');

      // It stays: time passing and a tap outside do not answer it.
      await tester.pump(const Duration(seconds: 30));
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(anomalies, findsOneWidget);
    });

    testWidgets('an empty Lesson is said once: in words, not again among the '
        'Audit warnings', (tester) async {
      final course = _course(id: 'new');
      final warnings = CourseAuditService()
          .auditCourse(Course.fromJson(jsonOf(course)))
          .issues
          .where((issue) => issue.severity.name == 'warning')
          .toList();
      // Said in words: the empty Lesson and the missing Rights Holder.
      final others = warnings
          .where(
            (issue) =>
                issue.code != 'LESSON_ROUNDS_EMPTY' &&
                issue.code != 'LICENSE_RIGHTS_HOLDER_MISSING',
          )
          .length;
      expect(warnings.length - others, 2);

      await openImport(tester, incoming: jsonOf(course));
      await quickImport(tester, anomalies);
      final audit = anomalyLines(
        tester,
      ).where((line) => line.startsWith('The Course Audit has'));
      if (others == 0) {
        expect(audit, isEmpty);
      } else {
        expect(
          audit.single,
          startsWith('The Course Audit has $others other warning'),
        );
      }
    });

    testWidgets('what the file leaves out is read from the file as written', (
      tester,
    ) async {
      final json = jsonOf(_cleanCourse(id: 'new'))..remove('license');
      await openImport(tester, incoming: json);
      await quickImport(tester, anomalies);
      expect(
        anomalyLines(tester),
        contains(
          'The file states no license: QuisquisLingo reads it as “All rights '
          'reserved”.',
        ),
      );
    });

    testWidgets('Cancel stores nothing, says nothing and lets the read file '
        'go', (tester) async {
      // A package with a picture: reading it stages the picture.
      late Uint8List zip;
      await tester.runAsync(() async {
        final bytes = uniquePng(72);
        final picture = CourseMediaStore.referenceFor(bytes, 'png');
        final course = _course(id: 'new', picture: picture);
        zip = await CoursePackageService().build(
          course,
          Uint8List.fromList(utf8.encode(jsonEncode(course.toJson()))),
          suppliedMedia: {picture: bytes},
        );
      });
      await openImport(tester, incomingZip: zip);
      await quickImport(tester, anomalies);
      expect(await tester.runAsync(stagedFiles), hasLength(1));

      await tester.tap(find.byKey(const Key('import-anomalies-cancel')));
      await tester.pumpUntilFileIoState(() => anomalies.evaluate().isEmpty);
      await tester.pump(const Duration(milliseconds: 400));

      expect(imported, findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      final state = await tester.runAsync(
        () async => (
          courses: await editor.listUserCourses(),
          staged: await stagedFiles(),
          source: await File('${imports.path}/import.zip').exists(),
        ),
      );
      expect(state!.courses, isEmpty);
      expect(state.staged, isEmpty);
      expect(state.source, isTrue, reason: 'the file to import stays');
    });

    testWidgets('Import anyway imports the file exactly as an import without '
        'the pop-up', (tester) async {
      // The same file twice, under two Course IDs: once without the pop-up
      // (as before this revision), once through Import anyway.
      CourseImportCheckDialog.enabled = false;
      await openImport(tester, incoming: jsonOf(_course(id: 'plain')));
      await quickImport(tester, imported);
      expect(anomalies, findsNothing);

      CourseImportCheckDialog.enabled = true;
      await tester.runAsync(() => writeJson(jsonOf(_course(id: 'asked'))));
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).removeCurrentSnackBar();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(imported, findsNothing);
      await quickImport(tester, anomalies);
      await tester.tap(find.byKey(const Key('import-anomalies-import')));
      await tester.pumpUntilFileIoState(() => imported.evaluate().isNotEmpty);
      expect(anomalies, findsNothing);

      final stored = await tester.runAsync(editor.listUserCourses);
      String written(String id) => jsonEncode(
        stored!.singleWhere((course) => course.courseId == id).toJson(),
      );
      expect(stored, hasLength(2));
      expect(written('asked').replaceAll('asked', 'plain'), written('plain'));
    });

    testWidgets('a second tap on the button while it asks reads nothing and '
        'asks nothing more', (tester) async {
      await openImport(tester, incoming: jsonOf(_course(id: 'new')));
      // Two taps before the file is read.
      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.pumpUntilFileIoState(() => anomalies.evaluate().isNotEmpty);
      await tester.pump(const Duration(seconds: 2));
      expect(anomalies, findsOneWidget);

      await tester.tap(find.byKey(const Key('import-anomalies-import')));
      await tester.pumpUntilFileIoState(() => imported.evaluate().isNotEmpty);
      await tester.pump(const Duration(seconds: 2));
      expect(anomalies, findsNothing);
      expect(find.text('Matching Course ID'), findsNothing);
      final stored = await tester.runAsync(editor.listUserCourses);
      expect(stored, hasLength(1));

      // The next import is not shut out.
      await tester.runAsync(() => writeJson(jsonOf(_course(id: 'next'))));
      await quickImport(tester, anomalies);
      expect(anomalies, findsOneWidget);
    });

    testWidgets('comes before the question about a Course ID already in '
        'use', (tester) async {
      await openImport(
        tester,
        incoming: jsonOf(_course(id: 'same')),
        installed: _course(id: 'same', title: 'Installed'),
      );
      await quickImport(tester, anomalies);
      expect(find.text('Matching Course ID'), findsNothing);

      await tester.tap(find.byKey(const Key('import-anomalies-import')));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isNotEmpty,
      );
      expect(anomalies, findsNothing);
      final stored = await tester.runAsync(editor.listUserCourses);
      expect(stored!.single.title, 'Installed', reason: 'not replaced yet');
    });

    testWidgets('Cancel before a Course ID already in use never asks about '
        'it', (tester) async {
      await openImport(
        tester,
        incoming: jsonOf(_course(id: 'same')),
        installed: _course(id: 'same', title: 'Installed'),
      );
      await quickImport(tester, anomalies);
      await tester.tap(find.byKey(const Key('import-anomalies-cancel')));
      await tester.pumpUntilFileIoState(() => anomalies.evaluate().isEmpty);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Matching Course ID'), findsNothing);
      final stored = await tester.runAsync(editor.listUserCourses);
      expect(stored!.single.title, 'Installed');
    });

    testWidgets('See the Audit opens the Course Audit of the file and '
        'stores nothing; Back returns to the pop-up, which still waits', (
      tester,
    ) async {
      await openImport(tester, incoming: jsonOf(_course(id: 'new')));
      await quickImport(tester, anomalies);

      await tester.tap(find.byKey(const Key('import-check-audit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CourseAuditScreen), findsOneWidget);
      expect(find.text('Course Audit of the file'), findsOneWidget);
      expect(
        tester
            .widget<CourseAuditScreen>(find.byType(CourseAuditScreen))
            .course
            .courseId,
        'new',
      );
      expect(await tester.runAsync(editor.listUserCourses), isEmpty);

      // The page under the pop-up has a Back button too.
      await tester.tap(find.byTooltip('Back').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CourseAuditScreen), findsNothing);
      expect(anomalies, findsOneWidget);

      await tester.tap(find.byKey(const Key('import-anomalies-cancel')));
      await tester.pumpUntilFileIoState(() => anomalies.evaluate().isEmpty);
      expect(await tester.runAsync(editor.listUserCourses), isEmpty);
    });

    testWidgets('the learner’s Import page asks too, and hands the Course '
        'back after Import anyway', (tester) async {
      final returned = await openImport(
        tester,
        incoming: jsonOf(_course(id: 'new')),
        importOnly: true,
      );
      await quickImport(tester, anomalies);
      expect(returned, isEmpty);
      await tester.tap(find.byKey(const Key('import-anomalies-import')));
      await tester.pumpUntilFileIoState(() => returned.isNotEmpty);
      expect((returned.single! as Course).courseId, 'new');
    });
  });

  testWidgets('a file whose Audit has errors is refused as before, without '
      'either pop-up', (tester) async {
    await openImport(
      tester,
      incoming: jsonOf(_course(id: 'new', broken: true)),
    );
    await quickImport(tester, find.text('Course import blocked'));
    expect(anomalies, findsNothing);
    expect(checked, findsNothing);

    // Every finding of the refused file, not only the first eight errors.
    await tester.tap(find.byKey(const Key('import-blocked-audit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final audit = tester.widget<CourseAuditScreen>(
      find.byType(CourseAuditScreen),
    );
    expect(audit.course.courseId, 'new');
    expect(
      audit.result.issues.where((issue) => issue.severity.name == 'error'),
      isNotEmpty,
    );
    expect(find.text('Course Audit of the file'), findsOneWidget);
    await tester.tap(find.byTooltip('Back').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CourseAuditScreen), findsNothing);
    expect(find.text('Course import blocked'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpUntilFileIoState(
      () => find.text('Course import blocked').evaluate().isEmpty,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(anomalies, findsNothing);
    expect(checked, findsNothing);
    final stored = await tester.runAsync(editor.listUserCourses);
    expect(stored, isEmpty);
  });

  group('a file without anomalies', () {
    test('the fixture is one', () {
      final course = Course.fromJson(jsonOf(_cleanCourse(id: 'clean')));
      final audit = CourseAuditService().auditCourse(course);
      expect([
        for (final issue in audit.issues)
          if (issue.severity.name != 'info') '${issue.code}: ${issue.message}',
      ], isEmpty);
      expect(
        CourseImportCheck.of(course, fileJson: course.toJson()).hasAnomalies,
        isFalse,
      );
    });

    testWidgets('says it was checked, tells about the Course and waits', (
      tester,
    ) async {
      await openImport(tester, incoming: jsonOf(_cleanCourse(id: 'clean')));
      await quickImport(tester, checked);

      expect(anomalies, findsNothing);
      expect(find.text('Course checked: no anomalies'), findsOneWidget);
      expect(
        textOf(tester, 'import-checked-intro'),
        'QuisquisLingo checked “Incoming” for anomalies and found none.',
      );
      expect(
        textOf(tester, 'import-checked-fact-authors'),
        'Authors: Ada (Author)',
      );
      expect(
        textOf(tester, 'import-checked-fact-maintainer'),
        'Maintainer: Import Author',
        reason: 'the Maintainer is a learner of this device',
      );
      expect(textOf(tester, 'import-checked-fact-team'), 'Team: None');
      expect(
        textOf(tester, 'import-checked-fact-last-edited'),
        startsWith('Last edited: '),
      );
      expect(
        textOf(tester, 'import-checked-fact-last-edited'),
        endsWith(', by Ada'),
      );
      expect(
        textOf(tester, 'import-checked-fact-license'),
        'License: CC BY 4.0 · Rights Holder: Ada',
      );
      expect(
        textOf(tester, 'import-checked-fact-content'),
        'Lessons: 1 · Rounds: 1 · Exercises: 2',
      );
      expect(
        textOf(tester, 'import-check-reminder-0'),
        contains('QuisquisLingo will use the device’s voice'),
      );
      expect(find.widgetWithText(FilledButton, 'Import'), findsOneWidget);
      final stored = await tester.runAsync(editor.listUserCourses);
      expect(stored, isEmpty, reason: 'nothing is stored while it waits');

      await tester.pump(const Duration(seconds: 30));
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(checked, findsOneWidget);
    });

    testWidgets('Import imports it', (tester) async {
      await openImport(tester, incoming: jsonOf(_cleanCourse(id: 'clean')));
      await quickImport(tester, checked);
      await tester.tap(find.byKey(const Key('import-checked-import')));
      await tester.pumpUntilFileIoState(() => imported.evaluate().isNotEmpty);

      expect(checked, findsNothing);
      expect(find.text('Imported “Incoming”.'), findsOneWidget);
      final stored = await tester.runAsync(editor.listUserCourses);
      expect(stored!.single.courseId, 'clean');
    });

    testWidgets('Cancel stores nothing', (tester) async {
      await openImport(tester, incoming: jsonOf(_cleanCourse(id: 'clean')));
      await quickImport(tester, checked);
      await tester.tap(find.byKey(const Key('import-checked-cancel')));
      await tester.pumpUntilFileIoState(() => checked.evaluate().isEmpty);
      await tester.pump(const Duration(milliseconds: 400));

      expect(imported, findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      final stored = await tester.runAsync(editor.listUserCourses);
      expect(stored, isEmpty);
    });
  });

  final facts = CourseImportFacts(
    authors: 'Ada (Author)',
    maintainerLabel: 'Maintainer',
    maintainer: 'Ada (not a learner on this device)',
    team: CourseImportFacts.teamNotHere,
    lastEdited: DateTime(2026, 10, 12, 15, 30),
    lastEditor: 'Ada',
    license: 'CC BY 4.0 · Rights Holder: Ada',
    content: 'Unità: 4 · Tappa: 12 · Exercises: 96',
  );
  const reminder = 'QuisquisLingo will use the device’s voice.';
  final clean = CourseImportCheck(facts: facts, reminders: const [reminder]);
  final two = CourseImportCheck(
    facts: facts,
    anomalies: const [
      CourseImportAnomaly(
        CourseImportAnomalyKind.noAuthor,
        'The file names no author.',
      ),
      CourseImportAnomaly(
        CourseImportAnomalyKind.auditWarnings,
        'The Course Audit has 7 warnings.',
      ),
    ],
    reminders: const [reminder],
  );

  group('the pop-up itself', () {
    /// Opens the pop-up for [check] and returns the answers given so far.
    Future<List<bool>> open(
      WidgetTester tester,
      CourseImportCheck check, {
      CourseFileUse use = CourseFileUse.import,
      Size viewport = const Size(800, 900),
      String title = 'Incoming',
    }) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final answers = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => answers.add(
                  await confirmCourseFile(
                    context,
                    course: _course(id: 'new', title: title),
                    check: check,
                    use: use,
                  ),
                ),
                child: const Text('import'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('import'));
      await tester.pumpAndSettle();
      return answers;
    }

    testWidgets('with anomalies it lists each one and the reminders, and '
        'not the facts', (tester) async {
      await open(tester, two);
      expect(anomalies, findsOneWidget);
      expect(checked, findsNothing);
      expect(
        textOf(tester, 'import-anomalies-intro'),
        'QuisquisLingo checked “Incoming” and found 2 things to look at '
        'before importing:',
      );
      expect(anomalyLines(tester), [
        'The file names no author.',
        'The Course Audit has 7 warnings.',
      ]);
      expect(textOf(tester, 'import-check-reminder-0'), reminder);
      expect(
        find.byKey(const Key('import-checked-fact-authors')),
        findsNothing,
      );
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Import anyway'),
        findsOneWidget,
      );
    });

    testWidgets('one anomaly is "one thing"', (tester) async {
      await open(
        tester,
        CourseImportCheck(
          facts: facts,
          anomalies: const [
            CourseImportAnomaly(
              CourseImportAnomalyKind.noAuthor,
              'The file names no author.',
            ),
          ],
        ),
      );
      expect(
        textOf(tester, 'import-anomalies-intro'),
        'QuisquisLingo checked “Incoming” and found one thing to look at '
        'before importing:',
      );
    });

    testWidgets('without anomalies it tells the six facts, with the Course’s '
        'own labels and the date as Course Info writes it', (tester) async {
      await open(tester, clean);
      expect(checked, findsOneWidget);
      expect(anomalies, findsNothing);
      expect(
        textOf(tester, 'import-checked-fact-authors'),
        'Authors: Ada (Author)',
      );
      expect(
        textOf(tester, 'import-checked-fact-maintainer'),
        'Maintainer: Ada (not a learner on this device)',
      );
      expect(
        textOf(tester, 'import-checked-fact-team'),
        'Team: A Team that is not on this device',
      );
      expect(
        textOf(tester, 'import-checked-fact-last-edited'),
        'Last edited: Monday, October 12, 2026 · 3:30 PM, by Ada',
      );
      expect(
        textOf(tester, 'import-checked-fact-license'),
        'License: CC BY 4.0 · Rights Holder: Ada',
      );
      expect(
        textOf(tester, 'import-checked-fact-content'),
        'Unità: 4 · Tappa: 12 · Exercises: 96',
      );
      expect(textOf(tester, 'import-check-reminder-0'), reminder);
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Import'), findsOneWidget);
    });

    testWidgets('a Publisher Course: no Team line; a last edit the file '
        'does not record, by nobody named', (tester) async {
      await open(
        tester,
        CourseImportCheck(
          facts: CourseImportFacts(
            authors: facts.authors,
            maintainerLabel: 'Publisher',
            maintainer: 'Example Courses',
            team: null,
            lastEdited: null,
            lastEditor: '',
            license: facts.license,
            content: facts.content,
          ),
        ),
      );
      expect(
        textOf(tester, 'import-checked-fact-maintainer'),
        'Publisher: Example Courses',
      );
      expect(find.byKey(const Key('import-checked-fact-team')), findsNothing);
      expect(
        textOf(tester, 'import-checked-fact-last-edited'),
        'Last edited: Not recorded',
      );
      expect(find.byKey(const Key('import-check-reminder-0')), findsNothing);
    });

    testWidgets('for a Merge it speaks of merging and its buttons say '
        'Continue', (tester) async {
      await open(tester, two, use: CourseFileUse.merge);
      expect(find.text('Check this Course before merging'), findsOneWidget);
      expect(
        textOf(tester, 'import-anomalies-intro'),
        'QuisquisLingo checked “Incoming” and found 2 things to look at '
        'before merging:',
      );
      expect(
        textOf(tester, 'import-anomalies-outcome'),
        'Continue anyway goes on with the Merge, with this Course as it is. '
        'Cancel leaves the Merge as it was.',
      );
      expect(
        find.widgetWithText(FilledButton, 'Continue anyway'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('import-anomalies-cancel')));
      await tester.pumpAndSettle();

      await open(tester, clean, use: CourseFileUse.merge);
      expect(find.text('Course checked: no anomalies'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    });

    testWidgets('the answers reach the caller: the two buttons of each '
        'pop-up, and the system’s Back', (tester) async {
      final answers = await open(tester, two);
      await tester.tap(find.byKey(const Key('import-anomalies-import')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('import'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-anomalies-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('import'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(answers, [true, false, false]);
      expect(anomalies, findsNothing);

      final others = await open(tester, clean);
      await tester.tap(find.byKey(const Key('import-checked-import')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('import'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import-checked-cancel')));
      await tester.pumpAndSettle();
      expect(others, [true, false]);
      expect(checked, findsNothing);
    });

    testWidgets('each fits a phone, with a long title and a long list', (
      tester,
    ) async {
      await open(
        tester,
        CourseImportCheck(
          facts: facts,
          anomalies: [
            for (var n = 0; n < 12; n++)
              CourseImportAnomaly(
                CourseImportAnomalyKind.auditWarnings,
                'The Course Audit has ${n + 1} warnings: Course Studio (⋮ › '
                'Audit) lists them after the import.',
              ),
          ],
        ),
        viewport: const Size(320, 568),
        title: 'T' * 3000,
      );
      expect(tester.takeException(), isNull);
      expect(
        textOf(tester, 'import-anomalies-intro'),
        startsWith('QuisquisLingo checked “${'T' * 80}…” and found 12 things'),
      );
      expect(
        find.byKey(const Key('import-anomalies-import')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import-anomalies-cancel')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('import-anomalies-cancel')));
      await tester.pumpAndSettle();

      await open(tester, clean, viewport: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('import-checked-import')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('import-checked-cancel')).hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('both pop-ups have See the Audit; the answer is still to be '
        'given when the Audit is closed', (tester) async {
      for (final check in [two, clean]) {
        final answers = await open(tester, check);
        await tester.tap(find.byKey(const Key('import-check-audit')));
        await tester.pumpAndSettle();
        expect(find.byType(CourseAuditScreen), findsOneWidget);
        expect(answers, isEmpty);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(CourseAuditScreen), findsNothing);
        expect(
          check.hasAnomalies ? anomalies : checked,
          findsOneWidget,
          reason: 'the pop-up is still there',
        );
        expect(answers, isEmpty);
        await tester.tap(
          find.byKey(
            Key(
              check.hasAnomalies
                  ? 'import-anomalies-cancel'
                  : 'import-checked-cancel',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(answers, [false]);
      }
    });

    testWidgets('switched off for the tests written before it, it answers '
        'yes at once and shows nothing', (tester) async {
      CourseImportCheckDialog.enabled = false;
      expect(await open(tester, two), [true]);
      expect(anomalies, findsNothing);
      expect(await open(tester, clean), [true]);
      expect(checked, findsNothing);
    });
  });

  group('the second Course of a Merge', () {
    late _CountedPackage package;

    Future<void> openMerge(
      WidgetTester tester, {
      CourseImportCheck? check,
      bool checkFails = false,
    }) async {
      package = _CountedPackage(_mergeCourse('right', 'Right Lesson'));
      tester.view.physicalSize = const Size(1400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseMergeScreen(
            leftCourse: _mergeCourse('left', 'Left Lesson'),
            mergeService: _PackageMergeService(package),
            onMerge: (course, chosen, given) async {},
            checkCourse: check == null && !checkFails
                ? null
                : (read) async {
                    expect(read.course.courseId, 'right');
                    return check;
                  },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('merge-course-json-primary')));
      await tester.pumpAndSettle();
    }

    final loaded = find.textContaining('Right Lesson');

    testWidgets('with anomalies: the pop-up before the Course is taken; '
        'Cancel leaves the Merge as it was', (tester) async {
      await openMerge(tester, check: two);
      expect(find.text('Check this Course before merging'), findsOneWidget);
      expect(loaded, findsNothing);

      await tester.tap(find.byKey(const Key('import-anomalies-cancel')));
      await tester.pumpAndSettle();
      expect(anomalies, findsNothing);
      expect(loaded, findsNothing);
      expect(package.discards, 1, reason: 'the read file is let go');
      // The page is ready for another file.
      await tester.tap(find.byKey(const Key('merge-course-json-primary')));
      await tester.pumpAndSettle();
      expect(anomalies, findsOneWidget);
    });

    testWidgets('Continue anyway takes the Course', (tester) async {
      await openMerge(tester, check: two);
      await tester.tap(find.byKey(const Key('import-anomalies-import')));
      await tester.pumpAndSettle();
      expect(anomalies, findsNothing);
      expect(loaded, findsWidgets);
      expect(package.discards, 0, reason: 'the Merge keeps the read file');
    });

    testWidgets('a check that could not be made never stops the Merge: the '
        'Course is taken at once', (tester) async {
      await openMerge(tester, checkFails: true);
      expect(anomalies, findsNothing);
      expect(checked, findsNothing);
      expect(loaded, findsWidgets);
      expect(package.discards, 0);
    });

    testWidgets('without anomalies: it says so, and Continue takes the '
        'Course', (tester) async {
      await openMerge(tester, check: clean);
      expect(find.text('Course checked: no anomalies'), findsOneWidget);
      expect(loaded, findsNothing);
      await tester.tap(find.byKey(const Key('import-checked-import')));
      await tester.pumpAndSettle();
      expect(checked, findsNothing);
      expect(loaded, findsWidgets);
    });

    testWidgets('a Merge page that is given no check takes the Course at '
        'once', (tester) async {
      await openMerge(tester);
      expect(anomalies, findsNothing);
      expect(checked, findsNothing);
      expect(loaded, findsWidgets);
    });
  });
}

final _time = DateTime.utc(2026, 9, 20, 9);

/// A custom Course with anomalies: no author, no Rights Holder for its
/// license, a Lesson without Rounds. [broken] gives its Audit an error;
/// [picture] gives it a picture of its own.
Course _course({
  required String id,
  String title = 'Incoming',
  bool broken = false,
  String? picture,
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _authorId,
    displayName: 'Import Author',
  ),
  maintainer: const CourseMaintainer(_authorId),
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  imageLibrary: [if (picture != null) CourseImageLibraryEntry(asset: picture)],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      updatedAt: _time,
      title: 'Lesson',
      rounds: const [],
    ),
    if (broken)
      Lesson(
        lessonId: 'lesson-$id',
        publicationState: PublicationState.draft,
        updatedAt: _time,
        title: 'The same Lesson ID again',
        rounds: const [],
      ),
  ],
);

Exercise _exercise(String id, String prompt, List<String> blocks) => Exercise(
  id: id,
  publicationState: PublicationState.published,
  updatedAt: _time,
  type: 'build_translation',
  prompt: prompt,
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: blocks,
  orderAnswer: const [],
  correctTranslations: [blocks.join(' ')],
  pairs: const [],
  hint: '',
  icons: const [],
);

/// A custom Course with nothing missing: an author, a license with its
/// Rights Holder, a Lesson with a Round with two exercises, no Audit
/// warning.
Course _cleanCourse({required String id}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _authorId,
    displayName: 'Import Author',
  ),
  maintainer: const CourseMaintainer(_authorId),
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  modifiedAtUtc: '2026-10-12T15:30:00.000Z',
  lastVersionEditorProfileId: _authorId,
  lastVersionEditorDisplayName: 'Ada',
  courseVersion: '1',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Incoming',
  ttsLanguage: 'it-IT',
  useGuidebook: false,
  createDuels: false,
  authors: const [
    CourseAuthor(name: 'Ada', roles: ['Author']),
  ],
  license: 'CC BY 4.0',
  rightsHolders: const [
    CourseRightsHolder(type: CourseRightsHolderType.person, name: 'Ada'),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.published,
      updatedAt: _time,
      title: 'At the bar',
      rounds: [
        LearningRound(
          id: 'round-$id',
          publicationState: PublicationState.published,
          updatedAt: _time,
          title: '',
          exercises: [
            _exercise('one-$id', 'How are you?', const ['Come', 'stai']),
            _exercise('two-$id', 'Good morning', const ['Buon', 'giorno']),
          ],
        ),
      ],
    ),
  ],
);

/// One of the two Courses of a Merge, as the Merge page's own tests make
/// them.
Course _mergeCourse(String id, String lesson) => Course(
  courseId: id,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Italian, first steps',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: '$id-1',
      updatedAt: DateTime.utc(2026, 10, 13),
      title: lesson,
      rounds: const [],
    ),
  ],
);
