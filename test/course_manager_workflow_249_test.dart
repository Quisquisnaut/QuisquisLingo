import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';
import 'support/pump_file_io.dart';
import 'support/test_directories.dart';
import 'support/unique_png.dart';

/// Build 249 characterization: the Course Manager workflow, driven through the
/// real screen over the real Course store and media folder. Written against
/// the unchanged screen before the library operations owner was extracted;
/// every test here must pass unchanged after the extraction.

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

/// The real store, with a storage failure that a test can switch on.
class _FaultyCourseStore extends CourseFileStore {
  bool failCreate = false;
  bool failRemove = false;

  @override
  Future<void> createIfAbsent(
    CourseStoreKind kind,
    String courseId,
    Object? entry,
  ) {
    if (failCreate && kind == CourseStoreKind.custom) {
      throw StateError('simulated storage failure on create');
    }
    return super.createIfAbsent(kind, courseId, entry);
  }

  @override
  Future<void> removeIfUnchanged(
    CourseStoreKind kind,
    String courseId, {
    required String expectedToken,
  }) {
    if (failRemove) throw StateError('simulated storage failure on delete');
    return super.removeIfUnchanged(
      kind,
      courseId,
      expectedToken: expectedToken,
    );
  }
}

void main() {
  late _FaultyCourseStore store;
  late CourseEditorService editor;
  late Course publisher;
  late Directory documents;
  final profiles = ProfileService();

  Future<void> setUpDevice(WidgetTester tester) async {
    // Tall enough that the lazy list builds the Local courses below the ten
    // Bundled Courses.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    documents = Directory('${testSupportDirectory.parent.path}/documents');
    await tester.runAsync(() async {
      // Alice is created first, so she is the device admin.
      await profiles.createProfile(
        'Alice',
        learnerProfileId: _alice,
        generateScreenNameSuffix: false,
      );
      await profiles.createProfile(
        'Bob',
        learnerProfileId: _bob,
        generateScreenNameSuffix: false,
      );
      await profiles.setActiveProfileById(_alice);
      publisher = Course.fromJson(
        jsonDecode(
              await File(
                'test/fixtures/publishers/dummy-signed-v1.json',
              ).readAsString(),
            )
            as Map<String, dynamic>,
      );
    });
    store = _FaultyCourseStore();
    editor = CourseEditorService(
      courseStore: store,
      publisherVerification: fixtureVerifier(
        publisher.publisherId,
        publisher.publisherName,
      ),
    );
  }

  Future<void> install(WidgetTester tester, Course course) =>
      tester.runAsync(() async {
        if (course.originType == CourseOriginType.externalOfficial) {
          await editor.installExternalOfficialUpdate(course);
        } else {
          await editor.installImportedCustomCourse(course);
        }
      });

  Future<void> addToLibrary(
    WidgetTester tester,
    Course course, {
    String profileId = _alice,
  }) => tester.runAsync(() async {
    await profiles.setActiveProfileById(profileId);
    await CourseLibraryService().add(course);
    await profiles.setActiveProfileById(_alice);
  });

  Future<List<Course>> stored(WidgetTester tester) async =>
      (await tester.runAsync(editor.listUserCourses))!;

  Future<void> pumpManager(
    WidgetTester tester, {
    Course? current,
    bool importOnly = false,
    Directory? imports,
    ValueChanged<Course?>? onImported,
  }) async {
    final manager = CourseProjectsScreen(
      currentCourse: current,
      importOnly: importOnly,
      editorService: editor,
      transferService: CustomCourseTransferService(
        importDirectory: imports == null ? null : () async => imports,
        publisherVerification: fixtureVerifier(
          publisher.publisherId,
          publisher.publisherName,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: onImported == null
            ? manager
            : Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      final imported = await Navigator.of(context).push<Course>(
                        MaterialPageRoute(builder: (_) => manager),
                      );
                      onImported(imported);
                    },
                    child: const Text('Open Course Import'),
                  ),
                ),
              ),
      ),
    );
    if (onImported != null) {
      await tester.tap(find.text('Open Course Import'));
      await tester.pump();
    }
    await tester.pumpUntilFileIoState(
      () => importOnly
          ? find
                .byKey(const Key('import-course-json-primary'))
                .evaluate()
                .isNotEmpty
          : find.text('Local courses').evaluate().isNotEmpty,
    );
  }

  Future<void> openMenu(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> closeMenu(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> choose(WidgetTester tester, String entry) async {
    await tester.tap(find.text(entry).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  const everyEntry = [
    'Remove from my courses',
    'Remove Publisher Course from device',
    'Edit',
    'View (read only)',
    'Fork',
    'Copy as New Course',
    'Merge',
    'Audit',
    'Export Course',
    'Delete course',
  ];

  /// The entries the menu shows; since Build 249 Revision 1 an entry that
  /// cannot be used is shown greyed out, marked here as `(greyed)`.
  Future<List<String>> menuEntries(WidgetTester tester, Key key) async {
    await openMenu(tester, key);
    final offered = <String>[];
    for (final entry in everyEntry) {
      final text = find.text(entry);
      if (text.evaluate().isEmpty) continue;
      final item =
          tester.widget(
                find
                    .ancestor(
                      of: text.last,
                      matching: find.byWidgetPredicate(
                        (widget) => widget is PopupMenuItem,
                      ),
                    )
                    .first,
              )
              as PopupMenuItem;
      offered.add(item.enabled ? entry : '$entry (greyed)');
    }
    await closeMenu(tester);
    return offered;
  }

  Key actionsOf(String courseId) =>
      ValueKey('course-manager-actions-$courseId');

  group('which actions are offered', () {
    testWidgets('per Course kind, rights and admin status', (tester) async {
      await setUpDevice(tester);
      final mine = _course('mine', title: 'Mine');
      final theirs = _course(
        'theirs',
        title: 'Theirs',
        maintainer: _bob,
        derivatives: DerivativeWorksPolicy.allowed,
      );
      await install(tester, mine);
      await install(tester, theirs);
      await addToLibrary(tester, theirs);
      await install(tester, publisher);
      final bundled = (await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      ))!;
      await pumpManager(tester, current: bundled);

      expect(await menuEntries(tester, actionsOf('mine')), [
        'Remove from my courses',
        'Edit',
        'Fork (greyed)',
        'Copy as New Course',
        'Merge',
        'Audit',
        'Export Course',
        'Delete course',
      ]);
      expect(await menuEntries(tester, actionsOf('theirs')), [
        'Remove from my courses',
        'View (read only)',
        'Fork',
        'Copy as New Course (greyed)',
        'Merge (greyed)',
        'Audit',
        'Export Course (greyed)',
        'Delete course (greyed)',
      ]);
      expect(await menuEntries(tester, actionsOf(publisher.courseId)), [
        'Remove from my courses',
        'Remove Publisher Course from device',
        'View (read only)',
        'Fork',
        'Audit',
        'Export Course',
      ]);
      expect(
        await menuEntries(tester, const Key('course-manager-actions-current')),
        [
          'Remove from my courses',
          'View (read only)',
          'Fork (greyed)',
          'Audit',
          'Export Course',
        ],
      );
    });

    testWidgets('a non-admin sees Publisher removal greyed out', (
      tester,
    ) async {
      await setUpDevice(tester);
      await install(tester, publisher);
      await addToLibrary(tester, publisher, profileId: _bob);
      await tester.runAsync(() => profiles.setActiveProfileById(_bob));
      await pumpManager(tester);

      expect(
        await menuEntries(tester, actionsOf(publisher.courseId)),
        contains('Remove Publisher Course from device (greyed)'),
      );
    });

    testWidgets('a greyed-out entry says why and does nothing when tapped', (
      tester,
    ) async {
      await setUpDevice(tester);
      final theirs = _course(
        'theirs',
        title: 'Theirs',
        maintainer: _bob,
        derivatives: DerivativeWorksPolicy.forbidden,
      );
      await install(tester, theirs);
      await addToLibrary(tester, theirs);
      await pumpManager(tester);

      await openMenu(tester, actionsOf('theirs'));
      expect(
        find.text(
          'Only the Maintainer or assigned Team can delete this Course.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('The license does not allow derivative works.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Delete course'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Delete course?'), findsNothing);
      expect((await stored(tester)).map((c) => c.courseId), ['theirs']);
    });
  });

  group('Copy as New Course', () {
    testWidgets('stores "<title> copy", reports it and opens the copy', (
      tester,
    ) async {
      await setUpDevice(tester);
      await install(tester, _course('mine', title: 'Mine'));
      await pumpManager(tester);

      await openMenu(tester, actionsOf('mine'));
      await choose(tester, 'Copy as New Course');
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );

      final opened = tester
          .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
          .course;
      expect(opened.title, 'Mine copy');
      expect(opened.courseId, isNot('mine'));
      expect(opened.maintainer?.profileId, _alice);
      expect(find.textContaining('Course changes confirmed.'), findsOneWidget);
      expect((await stored(tester)).map((c) => c.title).toSet(), {
        'Mine',
        'Mine copy',
      });
    });

    testWidgets('counts past a copy title already listed', (tester) async {
      await setUpDevice(tester);
      await install(tester, _course('mine', title: 'Mine'));
      await install(tester, _course('earlier', title: 'Mine copy'));
      await pumpManager(tester);

      await openMenu(tester, actionsOf('mine'));
      await choose(tester, 'Copy as New Course');
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );

      expect(
        tester
            .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
            .course
            .title,
        'Mine copy 2',
      );
    });

    testWidgets(
      'avoids only titles in the personal library (recorded known limit)',
      (tester) async {
        await setUpDevice(tester);
        await install(tester, _course('mine', title: 'Mine'));
        final earlier = _course('earlier', title: 'Mine copy');
        await install(tester, earlier);
        await tester.runAsync(() => CourseLibraryService().remove(earlier));
        await pumpManager(tester);

        await openMenu(tester, actionsOf('mine'));
        await choose(tester, 'Copy as New Course');
        await tester.pumpUntilFileIoState(
          () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
        );

        expect(
          tester
              .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
              .course
              .title,
          'Mine copy',
        );
      },
    );

    testWidgets('a storage failure is reported and stores nothing', (
      tester,
    ) async {
      await setUpDevice(tester);
      await install(tester, _course('mine', title: 'Mine'));
      await pumpManager(tester);
      store.failCreate = true;

      await openMenu(tester, actionsOf('mine'));
      await choose(tester, 'Copy as New Course');
      await tester.pumpUntilFileIoState(
        () => find
            .textContaining('simulated storage failure on create')
            .evaluate()
            .isNotEmpty,
      );

      expect(find.byType(CourseEditorScreen), findsNothing);
      expect((await stored(tester)).map((c) => c.courseId), ['mine']);
    });
  });

  group('Fork', () {
    testWidgets('of an outsider\'s Custom Course records its source', (
      tester,
    ) async {
      await setUpDevice(tester);
      final theirs = _course(
        'theirs',
        title: 'Theirs',
        maintainer: _bob,
        derivatives: DerivativeWorksPolicy.allowed,
      );
      await install(tester, theirs);
      await addToLibrary(tester, theirs);
      await pumpManager(tester);

      await openMenu(tester, actionsOf('theirs'));
      await choose(tester, 'Fork');
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );

      final fork = (await stored(
        tester,
      )).singleWhere((c) => c.courseId != 'theirs');
      expect(fork.forkProvenance?.sourceCourseId, 'theirs');
      expect(fork.maintainer?.profileId, _alice);
      expect(
        tester
            .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
            .course
            .courseId,
        fork.courseId,
      );
    });

    testWidgets('of a Publisher Course forks the stored signed source', (
      tester,
    ) async {
      await setUpDevice(tester);
      await install(tester, publisher);
      await pumpManager(tester);

      await openMenu(tester, actionsOf(publisher.courseId));
      await choose(tester, 'Fork');
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );

      final fork = (await stored(
        tester,
      )).singleWhere((c) => c.originType == CourseOriginType.custom);
      expect(fork.forkProvenance?.sourceCourseId, publisher.courseId);
      expect(
        fork.forkProvenance?.sourceCourseVersion,
        publisher.officialCourseVersion,
      );
      expect(fork.maintainer?.profileId, _alice);
    });
  });

  group('Delete', () {
    testWidgets('asks twice and removes the record and its media', (
      tester,
    ) async {
      await setUpDevice(tester);
      final image = (await tester.runAsync(
        () => CourseMediaStore().addBytes('mine', uniquePng(249), 'png'),
      ))!;
      await install(tester, _course('mine', title: 'Mine', image: image));
      await pumpManager(tester);

      await openMenu(tester, actionsOf('mine'));
      await choose(tester, 'Delete course');
      expect(find.text('Delete course?'), findsOneWidget);
      await choose(tester, 'Cancel');
      expect((await stored(tester)).map((c) => c.courseId), ['mine']);

      await openMenu(tester, actionsOf('mine'));
      await choose(tester, 'Delete course');
      await choose(tester, 'Continue');
      expect(find.text('Confirm permanent deletion'), findsOneWidget);
      await choose(tester, 'Keep course');
      expect((await stored(tester)).map((c) => c.courseId), ['mine']);

      await openMenu(tester, actionsOf('mine'));
      await choose(tester, 'Delete course');
      await choose(tester, 'Continue');
      await choose(tester, 'Delete permanently');
      await tester.pumpUntilFileIoState(
        () => find.byKey(actionsOf('mine')).evaluate().isEmpty,
      );

      expect(await stored(tester), isEmpty);
      expect(
        await tester.runAsync(
          () => CourseMediaStore().existingFile('mine', image),
        ),
        isNull,
      );
    });

    testWidgets(
      'a storage failure is reported and keeps the Course listed',
      (tester) async {
        await setUpDevice(tester);
        await install(tester, _course('mine', title: 'Mine'));
        await pumpManager(tester);
        store.failRemove = true;

        await openMenu(tester, actionsOf('mine'));
        await choose(tester, 'Delete course');
        await choose(tester, 'Continue');
        await choose(tester, 'Delete permanently');
        await tester.pumpUntilFileIoState(
          () => find
              .textContaining('simulated storage failure on delete')
              .evaluate()
              .isNotEmpty,
        );

        expect(find.byKey(actionsOf('mine')), findsOneWidget);
        expect((await stored(tester)).map((c) => c.courseId), ['mine']);
      },
      // Failed on Build 248 and on Build 249 Revisions 0 and 1: the error
      // escaped the menu callback and nothing was shown. Revision 2's proof.
    );
  });

  testWidgets('Export writes the package and reports its path', (tester) async {
    await setUpDevice(tester);
    await install(tester, _course('mine', title: 'Mine'));
    await pumpManager(tester);

    await openMenu(tester, actionsOf('mine'));
    await choose(tester, 'Export Course');
    await tester.tap(find.byKey(const Key('export-course-zip-primary')));
    await tester.pumpUntilFileIoState(
      () => find.textContaining('Exported “Mine” to ').evaluate().isNotEmpty,
    );

    final text = tester
        .widget<Text>(find.textContaining('Exported “Mine” to '))
        .data!;
    final path = text.replaceFirst('Exported “Mine” to ', '').split(' ').first;
    expect(await tester.runAsync(() => File(path).exists()), isTrue);
    expect(path, contains('${Platform.pathSeparator}Exports'));
  });

  group('Remove Publisher Course from device', () {
    testWidgets('is refused while another profile uses it', (tester) async {
      await setUpDevice(tester);
      await install(tester, publisher);
      await addToLibrary(tester, publisher, profileId: _bob);
      await pumpManager(tester);

      await openMenu(tester, actionsOf(publisher.courseId));
      await choose(tester, 'Remove Publisher Course from device');
      await choose(tester, 'Remove from device');
      await tester.pumpUntilFileIoState(
        () => find
            .textContaining('Another profile still has this course')
            .evaluate()
            .isNotEmpty,
      );

      expect(find.byKey(actionsOf(publisher.courseId)), findsOneWidget);
    });

    testWidgets('removes it when nobody else uses it', (tester) async {
      await setUpDevice(tester);
      await install(tester, publisher);
      await pumpManager(tester);

      await openMenu(tester, actionsOf(publisher.courseId));
      await choose(tester, 'Remove Publisher Course from device');
      await choose(tester, 'Remove from device');
      await tester.pumpUntilFileIoState(
        () => find.byKey(actionsOf(publisher.courseId)).evaluate().isEmpty,
      );

      expect(await stored(tester), isEmpty);
    });
  });

  group('Import', () {
    Future<Directory> importsHolding(WidgetTester tester, Course course) async {
      final imports = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('qql_249_imports_'),
      ))!;
      addTearDown(() => imports.delete(recursive: true));
      await tester.runAsync(
        () => File(
          '${imports.path}/import.json',
        ).writeAsString(jsonEncode(course.toJson())),
      );
      return imports;
    }

    Future<List<String>> collisionChoices(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isNotEmpty,
      );
      final dialog = find.byType(AlertDialog);
      final offered = <String>[];
      for (final choice in [
        'Cancel',
        'Copy as New Course',
        'Fork',
        'Replace / update',
      ]) {
        final label = find.descendant(of: dialog, matching: find.text(choice));
        if (label.evaluate().isEmpty) continue;
        final button = tester.widget<ButtonStyleButton>(
          find
              .ancestor(
                of: label,
                matching: find.byWidgetPredicate(
                  (widget) => widget is ButtonStyleButton,
                ),
              )
              .first,
        );
        offered.add(button.onPressed == null ? '$choice (greyed)' : choice);
      }
      await tester.tap(find.text('Cancel'));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isEmpty,
      );
      return offered;
    }

    testWidgets('a new Course is installed and returned to its opener', (
      tester,
    ) async {
      await setUpDevice(tester);
      final imports = await importsHolding(
        tester,
        _course('fresh', title: 'Fresh'),
      );
      Course? returned;
      await pumpManager(
        tester,
        importOnly: true,
        imports: imports,
        onImported: (course) => returned = course,
      );

      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.pumpUntilFileIoState(() => returned != null);

      final imported = returned!;
      expect(imported.courseId, 'fresh');
      expect(imported.title, 'Fresh');
      expect(find.text('Open Course Import'), findsOneWidget);
      expect((await stored(tester)).map((c) => c.courseId), ['fresh']);
    });

    testWidgets('the Maintainer\'s own matching ID offers Copy and Replace', (
      tester,
    ) async {
      await setUpDevice(tester);
      await install(tester, _course('same', title: 'Installed'));
      final imports = await importsHolding(
        tester,
        _course('same', title: 'Incoming'),
      );
      await tester.runAsync(
        () => SettingsService().setCourseEditorUnlocked(true),
      );
      await pumpManager(tester, importOnly: true, imports: imports);

      expect(await collisionChoices(tester), [
        'Cancel',
        'Copy as New Course',
        'Replace / update',
      ]);
    });

    testWidgets('locked import-only mode shows disabled Copy and Fork', (
      tester,
    ) async {
      await setUpDevice(tester);
      await install(tester, _course('same', title: 'Installed'));
      final imports = await importsHolding(
        tester,
        _course('same', title: 'Incoming'),
      );
      await pumpManager(tester, importOnly: true, imports: imports);

      expect(await collisionChoices(tester), [
        'Cancel',
        'Copy as New Course (greyed)',
        'Fork (greyed)',
        'Replace / update',
      ]);
    });

    testWidgets('an outsider\'s matching ID offers Fork but not Replace', (
      tester,
    ) async {
      await setUpDevice(tester);
      final theirs = _course(
        'same',
        title: 'Installed',
        maintainer: _bob,
        derivatives: DerivativeWorksPolicy.allowed,
      );
      await install(tester, theirs);
      final imports = await importsHolding(
        tester,
        _course(
          'same',
          title: 'Incoming',
          maintainer: _bob,
          derivatives: DerivativeWorksPolicy.allowed,
        ),
      );
      await tester.runAsync(
        () => SettingsService().setCourseEditorUnlocked(true),
      );
      await pumpManager(tester, importOnly: true, imports: imports);

      expect(await collisionChoices(tester), [
        'Cancel',
        'Fork',
        'Replace / update (greyed)',
      ]);
    });
  });

  testWidgets('Merge names the result "<title> merged"', (tester) async {
    await setUpDevice(tester);
    await install(tester, _course('left', title: 'Mine'));
    await tester.runAsync(() async {
      final merges = Directory('${documents.path}/QuisquisLingo/Merges');
      await merges.create(recursive: true);
      await File(
        '${merges.path}/merge.json',
      ).writeAsString(jsonEncode(_course('right', title: 'Mine').toJson()));
    });
    await pumpManager(tester);

    await openMenu(tester, actionsOf('left'));
    await choose(tester, 'Merge');
    await tester.tap(find.byKey(const Key('merge-course-json-primary')));
    await tester.pumpUntilFileIoState(
      () => find.text('Select all Left').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('Select all Left'));
    await tester.pump();
    final doMerge = find.widgetWithText(FilledButton, 'DO MERGE!');
    await tester.ensureVisible(doMerge);
    await tester.pump();
    await tester.tap(doMerge);
    await tester.pumpUntilFileIoState(
      () =>
          find.text('Continue').evaluate().isNotEmpty ||
          find.byType(CourseMergeScreen).evaluate().isEmpty,
    );
    if (find.text('Continue').evaluate().isNotEmpty) {
      await tester.tap(find.text('Continue'));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseMergeScreen).evaluate().isEmpty,
      );
    }

    final merged = (await stored(
      tester,
    )).singleWhere((c) => c.courseId != 'left');
    expect(merged.title, 'Mine merged');
    expect(find.textContaining('Course changes confirmed.'), findsOneWidget);
  });
}

Course _course(
  String id, {
  required String title,
  String maintainer = _alice,
  DerivativeWorksPolicy derivatives = DerivativeWorksPolicy.unspecified,
  String? image,
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: maintainer == _alice ? 'Alice' : 'Bob',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  derivativeWorksPolicy: derivatives,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  imageLibrary: [if (image != null) CourseImageLibraryEntry(asset: image)],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      updatedAt: DateTime.utc(2026, 9, 20),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);
