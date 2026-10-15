import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/course_import_check_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/korean_fixture.dart';
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
    'Course Info',
    'Edit',
    'View (read only)',
    'Fork',
    'Copy as New Course',
    'Merge',
    'Audit',
    'Export Course',
    'Export as Publisher Course',
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
    testWidgets('Course Info opens read-only details from the Studio menu', (
      tester,
    ) async {
      await setUpDevice(tester);
      final course = _course('mine', title: 'Mine');
      await install(tester, course);
      await pumpManager(tester);

      await openMenu(tester, actionsOf(course.courseId));
      await choose(tester, 'Course Info');
      expect(find.byType(CourseInfoScreen), findsOneWidget);
      expect(find.text('Course Info'), findsOneWidget);

      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      expect(find.byKey(actionsOf(course.courseId)), findsOneWidget);
      expect(await stored(tester), hasLength(1));
    });

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
      // A bundled Course that forbids derivative works, so Fork is greyed:
      // the Korean fixture. QQL Demo: English from Italian, used here until
      // then, left the app and the repository in Build 272 Revision 15
      // (owner decision of 13 October 2026).
      registerKoreanFixture();
      final bundled = (await tester.runAsync(
        () => CourseService().loadCourse('KO'),
      ))!;
      expect(bundled.derivativeWorksPolicy, DerivativeWorksPolicy.forbidden);
      await pumpManager(tester, current: bundled);

      expect(await menuEntries(tester, actionsOf('mine')), [
        'Remove from my courses',
        'Course Info',
        'Edit',
        'Fork (greyed)',
        'Copy as New Course',
        'Merge',
        'Audit',
        'Export Course',
        'Export as Publisher Course',
        'Delete course',
      ]);
      expect(await menuEntries(tester, actionsOf('theirs')), [
        'Remove from my courses',
        'Course Info',
        'View (read only)',
        'Fork',
        'Copy as New Course (greyed)',
        'Merge (greyed)',
        'Audit',
        'Export Course (greyed)',
        'Export as Publisher Course (greyed)',
        'Delete course (greyed)',
      ]);
      expect(await menuEntries(tester, actionsOf(publisher.courseId)), [
        'Remove from my courses',
        'Remove Publisher Course from device',
        'Course Info',
        'View (read only)',
        'Fork',
        'Audit',
        'Export Course',
      ]);
      expect(
        await menuEntries(tester, const Key('course-manager-actions-current')),
        [
          'Remove from my courses',
          'Course Info',
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

    // Build 271 Revision 1 (owner decisions of 10 and 11 October 2026).
    testWidgets(
      'names the other learners and, when asked, deletes progress and backups',
      (tester) async {
        await setUpDevice(tester);
        final course = _course('mine', title: 'Mine');
        await install(tester, course);
        await addToLibrary(tester, course, profileId: _bob);
        await tester.runAsync(() async {
          await editor.backupService.createBackup(
            course,
            backedUpAt: DateTime.utc(2026, 10, 11, 10),
            reason: 'Pre-change Course Editor transaction backup',
          );
          await ProgressService().completeRound(
            'round-1',
            courseId: 'mine',
            courseCode: 'IT',
          );
        });
        await pumpManager(tester);

        await openMenu(tester, actionsOf('mine'));
        await choose(tester, 'Delete course');
        await tester.pumpUntilFileIoState(
          () => find
              .byKey(const Key('course-delete-other-learners'))
              .evaluate()
              .isNotEmpty,
        );
        expect(
          find.text('Bob has this Course in their courses. Delete it anyway?'),
          findsOneWidget,
        );
        expect(
          find.textContaining('1 saved version in Backups/Courses ('),
          findsOneWidget,
        );
        // Both are off until the learner ticks them.
        CheckboxListTile box(String key) =>
            tester.widget<CheckboxListTile>(find.byKey(Key(key)));
        expect(box('course-delete-reset-progress').value, isFalse);
        expect(box('course-delete-backups').value, isFalse);
        await tester.tap(find.byKey(const Key('course-delete-reset-progress')));
        await tester.tap(find.byKey(const Key('course-delete-backups')));
        await tester.pump();
        expect(box('course-delete-reset-progress').value, isTrue);
        expect(box('course-delete-backups').value, isTrue);

        await choose(tester, 'Continue');
        expect(find.text('• the Course “Mine”'), findsOneWidget);
        expect(find.text('• your progress on it'), findsOneWidget);
        expect(find.textContaining('• its 1 backup ('), findsOneWidget);
        await choose(tester, 'Delete permanently');
        await tester.pumpUntilFileIoState(
          () => find.byKey(const Key('course-deleted')).evaluate().isNotEmpty,
        );

        expect(
          find.text('Deleted “Mine”, your progress on it and its 1 backup.'),
          findsOneWidget,
        );
        expect(await stored(tester), isEmpty);
        await tester.runAsync(() async {
          expect(
            await ProgressService().getCompletedRounds(courseId: 'mine'),
            isEmpty,
          );
          expect(
            (await editor.backupService.summaryOf('mine')).isEmpty,
            isTrue,
          );
        });
      },
    );

    testWidgets('a Course without backups offers none to delete', (
      tester,
    ) async {
      await setUpDevice(tester);
      await install(tester, _course('mine', title: 'Mine'));
      await pumpManager(tester);

      await openMenu(tester, actionsOf('mine'));
      await choose(tester, 'Delete course');
      await tester.pumpUntilFileIoState(
        () => find.text('It has no backups.').evaluate().isNotEmpty,
      );
      expect(
        find.byKey(const Key('course-delete-other-learners')),
        findsNothing,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('course-delete-backups')),
            )
            .onChanged,
        isNull,
      );
      await choose(tester, 'Continue');
      expect(find.text('• the Course “Mine”'), findsOneWidget);
      expect(find.text('• your progress on it'), findsNothing);
      await choose(tester, 'Delete permanently');
      await tester.pumpUntilFileIoState(
        () => find.byKey(const Key('course-deleted')).evaluate().isNotEmpty,
      );
      expect(find.text('Deleted “Mine”.'), findsOneWidget);
    });

    // Build 271 Revision 1 follow-up (owner decisions of 11 October 2026).
    testWidgets(
      'a Course this version cannot open offers its backups, with a caution',
      (tester) async {
        await setUpDevice(tester);
        final course = _course('mine', title: 'Mine');
        await install(tester, course);
        await tester.runAsync(() async {
          await editor.backupService.createBackup(
            course,
            backedUpAt: DateTime.utc(2026, 10, 11, 10),
            reason: 'Pre-change Course Editor transaction backup',
          );
          // The stored copy takes a shape this version refuses.
          final stored = await store.snapshot(CourseStoreKind.custom, 'mine');
          final entry = Map<String, dynamic>.from(stored!.entry as Map);
          final json = Map<String, dynamic>.from(entry['course'] as Map);
          (json['lessons'] as List).first['guidebook'] = {'content': []};
          entry['course'] = json;
          await store.replaceIfUnchanged(
            CourseStoreKind.custom,
            'mine',
            entry,
            expectedToken: stored.token,
          );
        });
        await pumpManager(tester);

        final remove = find.byKey(
          const Key('course-manager-unreadable-remove-0'),
        );
        await tester.ensureVisible(remove);
        await tester.tap(remove);
        await tester.pumpUntilFileIoState(
          () => find
              .textContaining('1 saved version in Backups/Courses (')
              .evaluate()
              .isNotEmpty,
        );
        expect(
          find.textContaining(
            'its backups may be the last copies that can still be read',
          ),
          findsOneWidget,
        );
        const backupsBox = Key('course-manager-unreadable-remove-backups');
        expect(
          tester.widget<CheckboxListTile>(find.byKey(backupsBox)).value,
          isFalse,
        );
        await tester.tap(find.byKey(backupsBox));
        await tester.pump();
        const confirm = Key('course-manager-unreadable-remove-confirm');
        await tester.tap(find.byKey(confirm));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.textContaining('and its 1 backup ('), findsOneWidget);
        await tester.tap(find.byKey(confirm));
        await tester.pumpUntilFileIoState(
          () => find
              .byKey(const Key('course-manager-unreadable-removed'))
              .evaluate()
              .isNotEmpty,
        );

        await tester.runAsync(() async {
          expect(await editor.unopenableCourse('mine'), isNull);
          expect(
            (await editor.backupService.summaryOf('mine')).isEmpty,
            isTrue,
          );
        });
      },
    );

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
    expect(
      path,
      contains(
        '${Platform.pathSeparator}Export${Platform.pathSeparator}Courses'
        '${Platform.pathSeparator}QQL_',
      ),
    );
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

    /// The buttons of the open Matching Course ID dialog, then closes it.
    Future<List<String>> dialogChoices(WidgetTester tester) async {
      final dialog = find.byType(AlertDialog);
      final offered = <String>[];
      for (final choice in [
        'Cancel',
        'Close',
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
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data == 'Cancel' || widget.data == 'Close'),
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isEmpty,
      );
      return offered;
    }

    Future<List<String>> collisionChoices(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isNotEmpty,
      );
      return dialogChoices(tester);
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

      // Fork is greyed: she maintains it (Copy as New Course is hers).
      expect(await collisionChoices(tester), [
        'Cancel',
        'Copy as New Course',
        'Fork (greyed)',
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

      // Copy as New Course is greyed: only Bob and his Team may copy it.
      expect(await collisionChoices(tester), [
        'Cancel',
        'Copy as New Course (greyed)',
        'Fork',
        'Replace / update (greyed)',
      ]);
    });

    testWidgets('nothing usable: no question, every action greyed with '
        'its reason, and Close (Build 272 Revision 17 follow-up)', (
      tester,
    ) async {
      // The owner's case of 15 October 2026: a Course received from an
      // author who is not on this device, not among Alice's courses, a
      // newer version of it, and Course Studio locked.
      await setUpDevice(tester);
      const carol = '33333333-3333-4333-8333-333333333333';
      final received = _course(
        'same',
        title: 'Installed',
        maintainer: carol,
        derivatives: DerivativeWorksPolicy.allowed,
      );
      await install(tester, received);
      await tester.runAsync(() => CourseLibraryService().remove(received));
      final newer = Course.fromJson({
        ...received.toJson(),
        'title': 'Incoming',
        'courseVersion': '2',
      });
      final imports = await importsHolding(tester, newer);
      await pumpManager(tester, importOnly: true, imports: imports);

      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isNotEmpty,
      );
      final text = tester
          .widget<Text>(find.byKey(const Key('import-matching-course-id')))
          .data!;
      expect(
        text,
        'A custom Course with ID “same” already exists: “Installed”. This '
        'file cannot be imported now.',
      );
      String reason(int index) => tester
          .widget<Text>(find.byKey(ValueKey('import-matching-reason-$index')))
          .data!;
      expect(reason(0), startsWith('Replace / update: To update it with '));
      expect(reason(0), contains('Add to my courses'));
      expect(
        reason(1),
        'Copy as New Course: ${CourseLibraryReports.copyOnlyInside}',
      );
      expect(reason(2), 'Fork: ${CourseLibraryReports.unlockCourseStudio}');
      expect(
        find.byKey(const ValueKey('import-matching-reason-3')),
        findsNothing,
      );
      expect(await dialogChoices(tester), [
        'Close',
        'Copy as New Course (greyed)',
        'Fork (greyed)',
        'Replace / update (greyed)',
      ]);
      // Close leaves everything as it was.
      expect((await stored(tester)).single.title, 'Installed');

      // Added to her courses, the same file is an update.
      await addToLibrary(tester, received);
      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isNotEmpty,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('import-matching-course-id')))
            .data,
        'A newer version of the received Custom Course “Installed” is '
        'available. Update it to version 2, or cancel?',
      );
      expect(
        find.widgetWithText(FilledButton, 'Update to version 2'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isEmpty,
      );
    });
  });

  testWidgets('Merge names the result "<title> merged"', (tester) async {
    await setUpDevice(tester);
    await install(tester, _course('left', title: 'Mine'));
    await tester.runAsync(() async {
      final merges = Directory(
        '${documents.path}/QuisquisLingo/ToBeMerged/Courses',
      );
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

  testWidgets('Merge shows the check of its second Course before it takes '
      'it (Build 272 Revision 13)', (tester) async {
    // Off for every test (`flutter_test_config.dart`); this one is about it.
    CourseImportCheckDialog.enabled = true;
    addTearDown(() => CourseImportCheckDialog.enabled = false);
    await setUpDevice(tester);
    await install(tester, _course('left', title: 'Mine'));
    await tester.runAsync(() async {
      final merges = Directory(
        '${documents.path}/QuisquisLingo/ToBeMerged/Courses',
      );
      await merges.create(recursive: true);
      await File(
        '${merges.path}/merge.json',
      ).writeAsString(jsonEncode(_course('right', title: 'Mine').toJson()));
    });
    await pumpManager(tester);

    await openMenu(tester, actionsOf('left'));
    await choose(tester, 'Merge');
    await tester.tap(find.byKey(const Key('merge-course-json-primary')));
    final popUp = find.byWidgetPredicate(
      (widget) =>
          widget.key == const Key('import-anomalies') ||
          widget.key == const Key('import-checked'),
    );
    await tester.pumpUntilFileIoState(() => popUp.evaluate().isNotEmpty);
    expect(find.text('Select all Left'), findsNothing);
    // The words of a Merge.
    expect(
      find.widgetWithText(FilledButton, 'Continue anyway').evaluate().length +
          find.widgetWithText(FilledButton, 'Continue').evaluate().length,
      1,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpUntilFileIoState(() => popUp.evaluate().isEmpty);
    expect(find.text('Select all Left'), findsNothing);
    expect(find.byType(CourseMergeScreen), findsOneWidget);
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
