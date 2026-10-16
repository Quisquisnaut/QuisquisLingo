import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/controllers/learner_status_controller.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/localization/start_page_text.dart';
import 'package:quisquislingo_app/localization/welcome_text.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_start_page.dart';
import 'package:quisquislingo_app/screens/course_wizard_screen.dart';
import 'package:quisquislingo_app/screens/courses_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/app_errors.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_categories.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_received_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/inventory_service.dart';
import 'package:quisquislingo_app/services/preset_examples.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/course_import_check_dialog.dart';
import 'package:quisquislingo_app/widgets/unified_learner_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/edge_case_fixture.dart';
import 'support/laboratory_fixture.dart';
import 'support/pump_file_io.dart';
import 'support/quick_folders.dart';

/// Build 272 Revision 17 (owner decisions of 13 October 2026): no Course
/// comes with the app. The Exercise Laboratory left it and is imported from
/// `demo_courses/`; its file stays in the app only for Fill with an example;
/// a learner without a Course starts on the start page.
///
/// Every test here runs without the bundled test Course of the other tests
/// (it is removed first), so the registry is the app's own: empty. The
/// notices the test configuration turns off for every test stay off, except
/// where a test turns one on.
const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';

Course _importable(String path) => Course.fromJson(
  Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map),
);

Course _draft(String id) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _alice,
    displayName: 'Alice',
  ),
  maintainer: const CourseMaintainer(_alice),
  originalCreatedAtUtc: '2026-10-13T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Mine $id',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      updatedAt: DateTime.utc(2026, 10, 13),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final profiles = ProfileService();

  setUp(() async {
    unregisterLaboratoryFixture();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await profiles.createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await profiles.setActiveProfileById(_alice);
  });

  Future<void> prepare(WidgetTester tester, {bool unlocked = false}) =>
      tester.runAsync(() async {
        final settings = SettingsService();
        await settings.completeWelcomeWizard();
        await settings.markOneTimeNoticeSeen(
          'welcome_${AppMetadata.technicalVersion}',
        );
        await settings.setAnimationsEnabled(false);
        if (unlocked) await settings.setCourseEditorUnlocked(true);
      });

  Future<void> openHome(WidgetTester tester, {bool unlocked = false}) async {
    await prepare(tester, unlocked: unlocked);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('course-start-page')).evaluate().isNotEmpty,
    );
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
  }

  String textOf(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  /// Lets a page that reads and writes Course files finish before the
  /// test's folder is deleted.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // A read of a stored Course goes on in steps: each needs real time and
    // then the test's own clock.
    for (var round = 0; round < 40; round++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('no Course comes with the app', () {
    test('the Bundled Courses section is drawn only for a Bundled Course', () {
      const rest = [
        CourseLibraryCategory.publisher,
        CourseLibraryCategory.myLocal,
        CourseLibraryCategory.otherLocal,
      ];
      expect(CourseLibraryCategories.shownFor(const []), rest);
      expect(CourseLibraryCategories.shownFor([_draft('a')]), rest);
      final bundled = _importable(CourseService.laboratoryAsset);
      expect(bundled.originType, CourseOriginType.bundledOfficial);
      expect(
        CourseLibraryCategories.shownFor([_draft('a'), bundled]),
        CourseLibraryCategories.standard,
      );
    });

    test('the registry is empty and discovery finds nothing', () async {
      expect(CourseService.courseAssets, isEmpty);
      expect(CourseService.bundledAssets, isEmpty);
      expect(CourseService.bundledCourseIds, isEmpty);
      expect(
        await CourseService().reconcileAvailableBundledCourseCodes(),
        isEmpty,
      );
      final library = await CourseLibraryOperations().load();
      expect(library.bundledCourses, isEmpty);
      expect(library.personalCourses, isEmpty);
    });

    test('the Laboratory cannot be opened as a Course', () async {
      expect(CourseService.hasCourse('IT'), isFalse);
      await expectLater(
        CourseService().loadCourse('IT'),
        throwsA(
          isA<AppException>().having(
            (error) => error.error,
            'error',
            AppErrorCode.courseFileMissing,
          ),
        ),
      );
    });

    test('a learner whose saved Course was the Laboratory has no current '
        'Course, and nothing fails', () async {
      await SettingsService().setLastSelectedCourseCode('IT');
      final controller = LearnerStatusController(observeLifecycle: false);
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.state.activeProfile, isNotNull);
      expect(controller.state.course, isNull);
      expect(controller.state.courseCode, isNull);
      expect(controller.state.streak, isNull);
    });

    test(
      'Fill with an example still has an example for every preset',
      () async {
        final laboratory = await PresetExamples.loadBundled();
        expect(laboratory.title, 'QQL Test: En-It Exercise Lab');
        for (final preset in PresetExamples.exampleIds.keys) {
          expect(
            await PresetExamples.forPreset(preset),
            isNotNull,
            reason: preset,
          );
        }
        // The file is in the app's assets, where the loader reads it.
        expect(
          (await rootBundle.load(CourseService.laboratoryAsset)).lengthInBytes,
          greaterThan(100000),
        );
      },
    );

    test('progress on the Laboratory is progress on a Course no longer '
        'here', () async {
      await ProgressService().completeRound(
        'qql_lab254_round_select_basics',
        courseId: laboratoryCourseId,
        courseCode: 'IT',
      );
      final sections = await InventoryService(profiles: profiles).load();
      final left = sections.firstWhere(
        (section) =>
            section.title == 'Progress on Courses no longer on this device',
      );
      expect(left.items.map((item) => item.name), [
        'Course ID $laboratoryCourseId',
      ]);
    });
  });

  group('the Courses to import', () {
    test('the Laboratory is a custom Course with its own identity', () async {
      final bytes = File(laboratoryImportPath).readAsBytesSync();
      final course = await CustomCourseTransferService().courseFromBytes(
        bytes,
        'import.json',
      );
      expect(course.title, 'QQL Test: En-It Exercise Lab');
      expect(course.originType, CourseOriginType.custom);
      expect(course.courseId, isNot(laboratoryCourseId));
      expect(course.courseId, 'course_5df44010-fd64-4c81-a2c8-deb49207f980');
      expect(course.maintainer?.profileId, isNotNull);
      // Version 2 since Build 274 Revision 3 added Listen and pick the
      // missing word: a device that has version 1 takes it as an update.
      expect(course.courseVersion, '2');
      expect(course.publicationState.isPublished, isTrue);
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      expect(course.lessons, hasLength(8));
      // The same exercises as the app's file.
      final inApp = await PresetExamples.loadBundled();
      List<String> ids(Course c) => [
        for (final lesson in c.lessons)
          for (final round in lesson.rounds)
            for (final content in round.content) content.id,
      ];
      expect(ids(course), ids(inApp));
      final audit = CourseAuditService().auditCourse(course);
      expect(audit.count(AuditSeverity.error), 0);
      // Its one warning: nobody was named as Rights Holder for it.
      expect(
        audit.issues
            .where((issue) => issue.severity == AuditSeverity.warning)
            .map((issue) => issue.code),
        ['LICENSE_RIGHTS_HOLDER_MISSING'],
      );
    });

    test('the Laboratory imports into an app without Courses, and whoever '
        'imports it can Fork it', () async {
      final editor = CourseEditorService();
      final course = _importable(laboratoryImportPath);
      await editor.installImportedCustomCourse(course);
      final stored = (await editor.listUserCourses()).single;
      expect(stored.title, 'QQL Test: En-It Exercise Lab');
      final fork = (await editor.createFork(source: stored)).course;
      expect(fork.courseId, isNot(stored.courseId));
      expect(fork.maintainer?.profileId, _alice);
      expect(fork.forkProvenance?.sourceCourseId, stored.courseId);
    });

    test('its bundled identity stays reserved', () async {
      final taken = Course.fromJson({
        ..._importable(laboratoryImportPath).toJson(),
        'courseId': laboratoryCourseId,
      });
      await expectLater(
        CourseEditorService().installImportedCustomCourse(taken),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('cannot replace an official course identity'),
          ),
        ),
      );
    });

    test('the Edge Case Course carries its new title in both files', () {
      expect(
        _importable(edgeCaseImportPath).title,
        'QQL Test: It-En Edge Case Course',
      );
      expect(
        (jsonDecode(File(edgeCaseFixturePath).readAsStringSync())
            as Map)['title'],
        'QQL Test: It-En Edge Case Course',
      );
    });

    test('a device that has the Edge Case Course under its earlier title '
        'takes the renamed file as an update', () async {
      final renamed = _importable(edgeCaseImportPath);
      expect(renamed.courseVersion, '2');
      // What was imported before the rename: version 1, the earlier title,
      // and the identity every earlier file had, written out here: a file
      // that changed its Maintainer, its creator or its date of creation
      // would be refused as an update, and this test would say so.
      const maintainer = 'afb065f8-701c-48d2-85f7-c80d44abecb9';
      final earlier = Course.fromJson({
        ...renamed.toJson(),
        'courseId': 'course_ef03d1b5-dccc-4fbb-88da-100473cddaad',
        'courseVersion': '1',
        'title': 'Temporary Demo: Edge Case Course',
        'modifiedAtUtc': '2026-09-28T00:00:00.000Z',
        'maintainer': {'profileId': maintainer},
        'originalCourseCreator': {
          'type': 'qqlUser',
          'id': maintainer,
          'displayName': 'QuisquisLingo',
        },
        'originalCreatedAtUtc': '2026-09-25T00:00:00.000Z',
      });
      final editor = CourseEditorService();
      await editor.installImportedCustomCourse(earlier);
      final received = CourseReceivedService();
      await received.recordNewImport(earlier);
      final stored = (await editor.listUserCourses()).single;
      expect(
        (await received.reviewUpdate(
          existing: stored,
          incoming: renamed,
        )).allowed,
        isTrue,
      );
      // The same version would have been refused as an update.
      expect(
        (await received.reviewUpdate(
          existing: stored,
          incoming: earlier,
        )).allowed,
        isFalse,
      );
    });
  });

  group('the start page', () {
    testWidgets('a learner without a Course starts there', (tester) async {
      await openHome(tester);
      expect(find.byType(UnifiedLearnerTopBar), findsNothing);
      expect(find.text('Start here'), findsOneWidget);
      for (final key in const [
        'start-import-course',
        'start-new-course',
        'start-all-courses',
        'empty-library-settings',
        'course-start-where',
        'course-start-import',
        'course-start-create',
        'course-start-device',
        'course-start-ten-taps',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      // Course Studio is locked for a new learner.
      expect(
        find.byKey(const Key('empty-library-course-manager')),
        findsNothing,
      );
      expect(
        textOf(tester, 'course-start-studio-state'),
        startPageText.lookup(AppLocale.english, 'create.off'),
      );
      expect(find.byKey(const Key('course-start-waiting')), findsNothing);
      // Nothing on the device to add: the card says so and comes last.
      expect(
        textOf(tester, 'course-start-device-text'),
        startPageText.lookup(AppLocale.english, 'device.none'),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('course-start-device'))).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const Key('course-start-create'))).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('New Course says how to turn Course Studio on; the ten taps '
        'in Settings turn it on', (tester) async {
      await openHome(tester);
      await tapVisible(tester, const Key('start-new-course'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('start-course-studio-locked')),
        findsOneWidget,
      );
      // The dialog and the page name the same row of Settings.
      expect(find.text(courseManagerUnlockMessage), findsOneWidget);
      expect(courseManagerUnlockMessage, contains('Version and Build'));
      await tester.tap(
        find.byKey(const Key('start-course-studio-locked-settings')),
      );
      await tester.pumpUntilFileIoState(
        () => find.text('Version and Build').evaluate().isNotEmpty,
      );
      expect(
        find.byTooltip('Tap x 10 times to unlock Course Studio'),
        findsOneWidget,
      );
      // The ten taps the page describes, then back: Course Studio is on.
      const row = Key('settings-version-build-area');
      await tester.ensureVisible(find.byKey(row));
      await tester.pump();
      for (var tap = 0; tap < 10; tap++) {
        await tester.tap(find.byKey(row));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpUntilFileIoState(
        () => find.text('Course Studio unlocked.').evaluate().isNotEmpty,
      );
      await tester.pageBack();
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('empty-library-course-manager'))
            .evaluate()
            .isNotEmpty,
      );
      expect(
        textOf(tester, 'course-start-studio-state'),
        startPageText.lookup(AppLocale.english, 'create.on'),
      );
    });

    testWidgets('with Course Studio on, New Course opens the Course Wizard', (
      tester,
    ) async {
      await openHome(tester, unlocked: true);
      expect(
        find.byKey(const Key('empty-library-course-manager')),
        findsOneWidget,
      );
      await tapVisible(tester, const Key('start-new-course'));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseWizardScreen).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('course-wizard-continue')), findsOneWidget);
    });

    testWidgets('Import a Course imports the Laboratory through Quick '
        'Import and its pop-up, and the Course opens for study', (
      tester,
    ) async {
      // The pop-up of an import is off for every test; this one answers it.
      CourseImportCheckDialog.enabled = true;
      addTearDown(() => CourseImportCheckDialog.enabled = false);
      await tester.runAsync(() async {
        final target = File(
          await CustomCourseTransferService().importFilePath(),
        );
        await target.parent.create(recursive: true);
        await File(laboratoryImportPath).copy(target.path);
      });
      await openHome(tester);
      await tapVisible(tester, const Key('start-import-course'));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('import-course-json-primary'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('Quick Import'), findsOneWidget);
      await tester.tap(find.byKey(const Key('import-course-json-primary')));
      await tester.pumpUntilFileIoState(
        () => find.byKey(const Key('import-anomalies')).evaluate().isNotEmpty,
      );
      // What the pop-up lists for this file: nobody named as Rights Holder.
      expect(find.textContaining('no Rights Holder is named'), findsOneWidget);
      expect(find.byKey(const Key('import-anomaly-1')), findsNothing);
      await tester.tap(find.byKey(const Key('import-anomalies-import')));
      await tester.pumpUntilFileIoState(
        () => find.byType(UnifiedLearnerTopBar).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('course-start-page')), findsNothing);
      expect(
        find.textContaining(
          'Imported “QQL Test: En-It Exercise Lab” and added to your courses.',
        ),
        findsOneWidget,
      );
      // The Course is already the one shown: nothing to switch to.
      expect(find.text('Study now'), findsNothing);
      expect(
        await tester.runAsync(SettingsService().getLastSelectedCourseCode),
        'custom:course_5df44010-fd64-4c81-a2c8-deb49207f980',
      );
      await close(tester);
    });

    testWidgets('a learner whose only Course is not published is told so', (
      tester,
    ) async {
      await tester.runAsync(
        () => CourseEditorService().installImportedCustomCourse(_draft('one')),
      );
      await openHome(tester, unlocked: true);
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byKey(const Key('course-start-waiting')),
                matching: find.byType(Text),
              ),
            )
            .data,
        startPageText.lookup(AppLocale.english, 'waiting.one'),
      );
    });

    testWidgets('a Course another learner imported is offered first, and '
        'adding it in All Courses opens it', (tester) async {
      await tester.runAsync(() async {
        await profiles.createProfile(
          'Bob',
          learnerProfileId: _bob,
          generateScreenNameSuffix: false,
        );
        await profiles.setActiveProfileById(_bob);
        final lab = _importable(laboratoryImportPath);
        await CourseEditorService().installImportedCustomCourse(lab);
        await CourseReceivedService().recordNewImport(lab);
        await profiles.setActiveProfileById(_alice);
        expect(await CourseLibraryService().contains(lab), isFalse);
      });
      await openHome(tester);
      expect(
        textOf(tester, 'course-start-device-text'),
        startPageText.lookup(AppLocale.english, 'device.some.one'),
      );
      // Before the explanations of importing.
      expect(
        tester.getTopLeft(find.byKey(const Key('course-start-device'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('course-start-where'))).dy,
        ),
      );
      await tapVisible(tester, const Key('start-all-courses'));
      const id = 'course_5df44010-fd64-4c81-a2c8-deb49207f980';
      const add = ValueKey('add-course-$id');
      // The Course is in the last section, below what the window shows.
      final offered = find.byKey(add, skipOffstage: false);
      await tester.pumpUntilFileIoState(() => offered.evaluate().isNotEmpty);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(offered);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(add));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const ValueKey('remove-course-$id'), skipOffstage: false)
            .evaluate()
            .isNotEmpty,
      );
      await tester.pageBack();
      await tester.pumpUntilFileIoState(
        () => find.byType(UnifiedLearnerTopBar).evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('course-start-page')), findsNothing);
      await close(tester);
    });

    testWidgets('with nobody logged in, it asks who is learning first and '
        'says nothing about anybody\'s Courses', (tester) async {
      await tester.runAsync(
        () => CourseEditorService().installImportedCustomCourse(_draft('one')),
      );
      await prepare(tester);
      await tester.runAsync(profiles.clearActiveProfile);
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpUntilFileIoState(
        () => find.textContaining('Learners on ').evaluate().isNotEmpty,
      );
      expect(find.byKey(const Key('course-start-page')), findsOneWidget);
      expect(find.textContaining('Alice'), findsWidgets);
      expect(find.byKey(const Key('course-start-waiting')), findsNothing);
      expect(
        textOf(tester, 'course-start-device-text'),
        startPageText.lookup(AppLocale.english, 'device.none'),
      );
    });

    testWidgets('All Courses and Course Studio draw no Bundled Courses '
        'section', (tester) async {
      // Owner decision of 14 October 2026: with no Course in the app, the
      // section would only say that it is empty.
      await openHome(tester, unlocked: true);
      await tapVisible(tester, const Key('start-all-courses'));
      await tester.pumpUntilFileIoState(
        () => find.text('Publisher Courses').evaluate().isNotEmpty,
      );
      expect(find.byKey(const ValueKey('course-section-0')), findsNothing);
      expect(find.textContaining('Bundled Courses'), findsNothing);
      for (final id in const ['1', '2', '3']) {
        expect(
          find.byKey(ValueKey('course-section-$id'), skipOffstage: false),
          findsOneWidget,
          reason: id,
        );
      }
      await tester.tap(find.byKey(const Key('courses-tab-manager')));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const ValueKey('manager-section-1'), skipOffstage: false)
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.byKey(const ValueKey('manager-section-0'), skipOffstage: false),
        findsNothing,
      );
      expect(find.textContaining('Bundled Courses'), findsNothing);
      for (final id in const ['2', '3']) {
        expect(
          find.byKey(ValueKey('manager-section-$id'), skipOffstage: false),
          findsOneWidget,
          reason: id,
        );
      }
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('Settings, Profile, Gamification and Statistics open without '
        'a Course', (tester) async {
      await openHome(tester);
      await tester.tap(find.byKey(const Key('empty-library-settings')));
      await tester.pumpUntilFileIoState(
        () => find.text('Audio Settings').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Profile'));
      await tester.pumpUntilFileIoState(
        () => find.text('Learner profiles').evaluate().isNotEmpty,
      );
      // A text of each page once it has read what it shows.
      const shown = {
        'Gamification': 'Weekly XP Target · All courses',
        'Statistics': 'Total Study Days',
      };
      for (final page in shown.keys) {
        await tester.scrollUntilVisible(find.text(page), 200);
        await tester.tap(find.text(page));
        await tester.pumpUntilFileIoState(
          () => find.text(shown[page]!).evaluate().isNotEmpty,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull, reason: page);
        await tester.pageBack();
        await tester.pumpUntilFileIoState(
          () => find.text('Learner profiles').evaluate().isNotEmpty,
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('it speaks the learner\'s Help Language', (tester) async {
      await tester.runAsync(() => LocaleService().write(AppLocale.italian));
      await openHome(tester);
      expect(find.text('Comincia da qui'), findsOneWidget);
      // Command names stay in English.
      expect(find.text('Import a Course'), findsOneWidget);
      expect(find.text('New Course'), findsOneWidget);
    });
  });

  group('the page by itself', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      required AppLocale locale,
      int waiting = 0,
      int addable = 0,
      bool unlocked = false,
      Size size = const Size(360, 640),
      double textScale = 1,
      Brightness brightness = Brightness.light,
      List<String>? taps,
    }) async {
      await tester.runAsync(() => LocaleService().write(locale));
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: CourseStartPage(
            editorUnlocked: unlocked,
            waitingCourses: waiting,
            addableCourses: addable,
            onImport: () => taps?.add('import'),
            onNewCourse: () => taps?.add('new'),
            onAllCourses: () => taps?.add('all'),
            onCourseStudio: () => taps?.add('studio'),
            onSettings: () => taps?.add('settings'),
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () =>
            textOf(tester, 'course-start-title') ==
            startPageText.lookup(locale, 'title'),
      );
    }

    Future<void> scrollToEnd(WidgetTester tester) async {
      await tester.drag(
        find.byKey(const Key('course-start-list')),
        const Offset(0, -9000),
      );
      await tester.pump();
    }

    for (final locale in AppLocale.values) {
      testWidgets('fits a 360-pixel phone in ${locale.name}, with the note, '
          'Courses to add and Course Studio on', (tester) async {
        await pumpPage(
          tester,
          locale: locale,
          waiting: 3,
          addable: 2,
          unlocked: true,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.text(
            startPageText.lookup(
              locale,
              'waiting.many',
              values: const {'count': '3'},
            ),
          ),
          findsOneWidget,
        );
        expect(
          textOf(tester, 'course-start-device-text'),
          startPageText.lookup(
            locale,
            'device.some.many',
            values: const {'count': '2'},
          ),
        );
        await scrollToEnd(tester);
        expect(tester.takeException(), isNull);
        // The other layout: nothing to add, the card last, Course Studio
        // locked.
        await pumpPage(tester, locale: locale);
        expect(
          textOf(tester, 'course-start-device-text'),
          startPageText.lookup(locale, 'device.none'),
        );
        expect(tester.takeException(), isNull);
        await scrollToEnd(tester);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('fits a 360-pixel phone with text twice as large, in the '
        'dark theme', (tester) async {
      for (final locale in AppLocale.values) {
        await pumpPage(
          tester,
          locale: locale,
          waiting: 1,
          addable: 1,
          unlocked: true,
          textScale: 2,
          brightness: Brightness.dark,
        );
        expect(tester.takeException(), isNull, reason: locale.name);
        await scrollToEnd(tester);
        expect(tester.takeException(), isNull, reason: locale.name);
      }
    });

    testWidgets('each button calls Home', (tester) async {
      final taps = <String>[];
      await pumpPage(
        tester,
        locale: AppLocale.english,
        unlocked: true,
        size: const Size(800, 1200),
        taps: taps,
      );
      for (final key in const [
        'start-import-course',
        'start-new-course',
        'start-all-courses',
        'empty-library-course-manager',
      ]) {
        await tapVisible(tester, Key(key));
      }
      await tester.tap(find.byKey(const Key('empty-library-settings')));
      expect(taps, ['import', 'new', 'all', 'studio', 'settings']);
    });
  });

  group('the words', () {
    Map<String, String> of(AppLocale locale) => switch (locale) {
      AppLocale.english => startPageText.english,
      AppLocale.italian => startPageText.italian,
      AppLocale.spanish => startPageText.spanish,
    };

    test('the three languages have the same keys, none empty', () {
      final keys = startPageText.english.keys.toSet();
      for (final locale in AppLocale.values) {
        expect(of(locale).keys.toSet(), keys, reason: locale.name);
        expect(
          of(locale).values.where((value) => value.trim().isEmpty),
          isEmpty,
        );
      }
    });

    test('the page names no Course, and keeps QQL\'s names in English', () {
      // The owner's rule: neither the Laboratory nor the Edge Case Course.
      final never = RegExp(
        r'\b(Lab|Laboratory|Laboratorio|Edge|Demo|QQL Test|Exercise Lab)\b',
      );
      for (final locale in AppLocale.values) {
        final all = of(locale).values.join('\n');
        expect(never.allMatches(all).map((m) => m.group(0)), isEmpty);
        for (final name in const [
          'Import a Course',
          'New Course',
          'Course Studio',
          'Course Editor',
          'Settings',
          'Version and Build',
          'Quick Import',
          'Open from…',
          'All Courses',
          'Add to my courses',
          'Publish',
          'import.zip',
        ]) {
          expect(all, contains(name), reason: '${locale.name} $name');
        }
        // The folder is named by the platform, never left as a placeholder.
        expect(
          startPageText.lookup(locale, 'import.step3'),
          isNot(contains('{')),
        );
      }
    });

    test('the Welcome Wizard sends a new learner to the start page', () {
      for (final locale in AppLocale.values) {
        expect(
          welcomeText.lookup(locale, 'step2.body'),
          contains('Import a Course'),
          reason: locale.name,
        );
      }
    });
  });
}
