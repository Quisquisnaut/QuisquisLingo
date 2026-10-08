import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/course_wizard_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_authoring_session.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/course_wizard_memory.dart';
import 'package:quisquislingo_app/services/formal_name_policy.dart';
import 'package:quisquislingo_app/services/lesson_icon_catalog.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 267 Revision 0: the Course Wizard's frame (plan
/// `docs/267_COURSE_WIZARD_PLAN.md`, §2–§4 and §8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_profiles);

  group('the paused Wizard', () {
    test('its record reads back and names the step', () {
      final pause = CourseWizardPause(
        step: CourseWizardStep.credits,
        savedAtUtc: DateTime.utc(2026, 10, 8, 12),
      );
      final read = CourseWizardPause.fromJson(pause.toJson())!;
      expect(read.step, CourseWizardStep.credits);
      expect(read.savedAtUtc, pause.savedAtUtc);
      expect(read.lessonId, isNull);
      expect(pause.toJson(), {
        'step': 3,
        'savedAtUtc': '2026-10-08T12:00:00.000Z',
      });
      expect(
        pause.description,
        'Course Wizard paused: step 3 of 5 (Credits and rights)',
      );
      // Unusable records are ignored, never guessed.
      for (final raw in [
        'not json',
        '[]',
        '{"step": "3", "savedAtUtc": "2026-10-08T12:00:00Z"}',
        '{"step": 0, "savedAtUtc": "2026-10-08T12:00:00Z"}',
        '{"step": 3}',
        '{"step": 3, "savedAtUtc": "yesterday"}',
      ]) {
        expect(CourseWizardPause.decode(raw), isNull, reason: raw);
      }
      // A step of a later build reads as this build's last step.
      expect(CourseWizardStep.byNumber(8), CourseWizardStep.lessons);
    });

    test('the memory keeps one record per Course ID on the device', () async {
      final memory = CourseWizardMemory();
      final pause = CourseWizardPause(
        step: CourseWizardStep.options,
        savedAtUtc: DateTime.utc(2026, 10, 8),
      );
      await memory.remember('friend/course', pause);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('qql_course_wizard_friend%2Fcourse'),
        isNotNull,
      );
      expect((await memory.recall('friend/course'))!.step, pause.step);
      await preferences.setString('qql_course_wizard_broken', '{');
      expect((await memory.all()).keys, ['friend/course']);
      await memory.forget('friend/course');
      expect(await memory.recall('friend/course'), isNull);
    });
  });

  group('the steps change the Course', () {
    test('the first save is a Draft with no Lessons and the defaults', () {
      final course = _wizardCourse();
      expect(course.lessons, isEmpty);
      expect(course.publicationState, PublicationState.draft);
      expect(course.originType, CourseOriginType.custom);
      expect(course.maintainer!.profileId, _profileId);
      expect(course.originalCourseCreator.id, _profileId);
      expect(course.license, 'All rights reserved');
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.forbidden);
      expect(course.authors.single.name, 'Wizard Author');
      expect(course.authors.single.roles, ['Author']);
      expect(course.useGuidebook, isTrue);
      expect(course.languageVariant, 'Italian of Italy');
      expect(course.targetLanguageTag, 'it');
      expect(Course.fromJson(course.toJson()).toJson(), course.toJson());
    });

    test('About writes its fields and leaves out the cleared ones', () {
      const credit = CourseMediaAttribution(
        author: 'A. Painter',
        license: 'CC BY 4.0',
      );
      final about = CourseWizardAbout(
        description: '  Coffee and pastries.  ',
        startLevel: 'A1',
        targetLevel: 'A2',
        coverImage: 'media:${'a' * 64}.png',
        coverCredit: credit,
        studyHours: 4,
        minimumAge: 9,
        keywords: const ['bar', 'travel'],
        flag: CourseFlagSelection.builtIn('IT'),
      );
      final course = about.applyTo(_wizardCourse());
      expect(course.courseDescription, 'Coffee and pastries.');
      expect(course.estimatedStudyHours, 4);
      expect(course.minimumAge, 9);
      expect(course.keywords, ['bar', 'travel']);
      expect(course.coverImage, about.coverImage);
      expect(course.flagCode, 'IT');
      expect(course.mediaAttributions.single.author, 'A. Painter');
      // The same credit is never added twice.
      expect(about.applyTo(course).mediaAttributions, hasLength(1));
      final cleared = const CourseWizardAbout().applyTo(course);
      expect(cleared.toJson().containsKey('estimatedStudyHours'), isFalse);
      expect(cleared.toJson().containsKey('keywords'), isFalse);
      expect(cleared.coverImage, isEmpty);
      expect(cleared.flagCode, isEmpty);
      expect(CourseWizardAbout.studyHoursProblem('1001'), isNotNull);
      expect(CourseWizardAbout.studyHoursProblem('4.5'), isNotNull);
      expect(CourseWizardAbout.studyHoursProblem(''), isNull);
      expect(
        CourseWizardAbout.keywordsProblem(List.filled(21, 'x').join(',')),
        isNull,
        reason: 'repeats are dropped first',
      );
      expect(
        CourseWizardAbout.keywordsProblem(
          [for (var i = 0; i < 21; i++) 'k$i'].join(','),
        ),
        isNotNull,
      );
    });

    test('Credits and Course options', () {
      final credited = CourseWizardSample.credits(
        'Wizard Author',
      ).applyTo(_wizardCourse());
      expect(credited.license, 'CC BY 4.0');
      expect(credited.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      expect(credited.rightsHolders.single.name, 'Wizard Author');
      final cleared = const CourseWizardCredits().applyTo(credited);
      expect(cleared.authors, isEmpty);
      expect(cleared.license, 'All rights reserved');
      expect(cleared.derivativeWorksPolicy, DerivativeWorksPolicy.forbidden);

      final noGuidebook = Course.fromJson({
        ..._wizardCourse().toJson(),
        'useGuidebook': false,
      });
      const options = CourseWizardOptions(
        lessonNumbering: LessonNumberingMode.other,
        customLessonLabel: ' Unit ',
        roundNumbering: RoundNumberingMode.roundAndNumber,
        wordLookup: false,
        createDuels: false,
        pictureAnswers: PictureAnswerStyle.earlier,
        defaultTimedLimits: [120, 60],
      );
      final changed = options.applyTo(noGuidebook);
      // The Wizard builds Rounds from the GuideBook, so it stays on.
      expect(changed.useGuidebook, isTrue);
      expect(changed.customLessonLabel, 'Unit');
      expect(changed.roundNumberingMode, RoundNumberingMode.roundAndNumber);
      expect(changed.wordLookup, isFalse);
      expect(changed.createDuels, isFalse);
      expect(changed.pictureAnswers, PictureAnswerStyle.earlier);
      expect(changed.defaultTimedLimitsSeconds, [120, 60]);
      expect(CourseWizardOptions.of(changed).isDefault, isFalse);
      expect(
        CourseWizardOptions.of(
          CourseWizardOptions.defaults.applyTo(changed),
        ).isDefault,
        isTrue,
      );
      expect(
        const CourseWizardOptions(
          lessonNumbering: LessonNumberingMode.other,
        ).problem,
        isNotNull,
      );
    });

    test('Lessons are added, kept, renamed, moved and removed', () {
      final ids = _Ids();
      var course = CourseWizardLessons.applyTo(
        _wizardCourse(),
        CourseWizardSample.lessons,
        now: _now,
        ids: ids,
      );
      expect(course.lessons.map((lesson) => lesson.title), [
        'Coffee and pastries',
        'Paying the bill',
        'Back to the station',
      ]);
      for (final lesson in course.lessons) {
        expect(lesson.publicationState, PublicationState.draft);
        expect(lesson.provisionalDraft, isTrue);
        expect(lesson.rounds, isEmpty);
        expect(lesson.guidebook.modules, isEmpty);
      }
      expect(course.lessons.first.sectionName, 'At the bar');
      expect(course.lessons.last.sectionName, 'In town');
      expect(
        course.lessons.first.themeIconAsset,
        LessonIconCatalog.byId('coffee').assetPath,
      );

      // A Lesson with content keeps it through a rename and a move.
      final first = course.lessons.first;
      final withRound = Lesson.fromJson({
        ...first.toJson(),
        'rounds': [
          LearningRound(
            id: 'round_1',
            title: '',
            content: const [],
            updatedAt: _now,
          ).toJson(),
        ],
      });
      course = Course.fromJson({
        ...course.toJson(),
        'lessons': [
          withRound.toJson(),
          for (final lesson in course.lessons.skip(1)) lesson.toJson(),
        ],
      });
      final drafts = CourseWizardLessons.of(course);
      course = CourseWizardLessons.applyTo(
        course,
        [
          drafts[1],
          CourseWizardLessonDraft(
            lessonId: drafts[0].lessonId,
            title: 'Coffee, pastries and juice',
            iconAsset: null,
            sectionName: '',
          ),
        ],
        now: _now,
        ids: ids,
      );
      expect(course.lessons.map((lesson) => lesson.title), [
        'Paying the bill',
        'Coffee, pastries and juice',
      ]);
      final renamed = course.lessons.last;
      expect(renamed.lessonId, first.lessonId);
      expect(renamed.rounds.single.id, 'round_1');
      expect(renamed.section, isFalse);
      expect(renamed.themeIconAsset, isNull);
      // Removing it names what goes with it.
      expect(CourseWizardLessons.removedContent(course, const []), [
        'Removing Lesson 2 (Coffee, pastries and juice) removes its 1 Round.',
      ]);
      expect(
        CourseWizardLessons.problem(const [CourseWizardLessonDraft()]),
        'Lesson 1 needs a title.',
      );
    });

    test('the example fills one coherent Course', () {
      expect(
        FormalNamePolicy.validatePresentationLabel(
          CourseWizardSample.basics.title,
        ),
        CourseWizardSample.basics.title,
      );
      for (final lesson in CourseWizardSample.lessons) {
        expect(LessonIconCatalog.isApproved(lesson.iconAsset!), isTrue);
      }
      var course = CourseWizardSample.about.applyTo(_wizardCourse());
      course = CourseWizardSample.credits('Wizard Author').applyTo(course);
      course = CourseWizardSample.options.applyTo(course);
      course = CourseWizardLessons.applyTo(
        course,
        CourseWizardSample.lessons,
        now: _now,
      );
      expect(Course.fromJson(course.toJson()).toJson(), course.toJson());
      expect(course.lessons, hasLength(3));
      expect(course.keywords, contains('bar'));
    });
  });

  test('one session saves a new Course at every step', () async {
    final editor = CourseEditorService();
    final course = _wizardCourse();
    final session = CourseAuthoringSession(
      course: course,
      access: CourseAccessPolicy.evaluate(
        course,
        profileId: _profileId,
      ).copyForUnconfirmedCreator(),
      editorService: editor,
      isNewCourse: true,
    )..setEditorMode(CourseEditorMode.edit);
    final first = await session.confirm(
      languageCode: 'IT',
      versionNotes: 'Course Wizard: Basics',
    );
    expect(first.course.courseVersion, '1');
    expect(first.hadPreviousVersion, isFalse);
    session.stageCourse(
      CourseWizardSample.about.applyTo(session.workingCourse),
    );
    final second = await session.confirm(
      languageCode: 'IT',
      versionNotes: 'Course Wizard: About the Course',
    );
    expect(second.course.courseVersion, '2');
    expect(second.course.versionNotes, 'Course Wizard: About the Course');
    expect(second.backupPath, isNotNull);
    final stored = (await editor.listUserCourses()).single;
    expect(stored.courseDescription, CourseWizardSample.about.description);
  });

  test('deleting the Course forgets its paused Wizard', () async {
    final operations = CourseLibraryOperations();
    final stored = await _store(_wizardCourse());
    await operations.wizardMemory.remember(
      stored.courseId,
      CourseWizardPause(
        step: CourseWizardStep.options,
        savedAtUtc: DateTime.utc(2026, 10, 8),
      ),
    );
    final library = await operations.load();
    expect(library.pausedWizards.keys, [stored.courseId]);
    expect(
      library.entriesFor(stored).first.action,
      CourseManagerAction.continueCourseWizard,
    );
    expect(library.entriesFor(stored).first.available, isTrue);
    await operations.deleteCourse(stored);
    expect(await operations.wizardMemory.recall(stored.courseId), isNull);
  });

  test('Continue Course Wizard is greyed for someone who cannot edit', () {
    final course = _wizardCourse();
    final pause = CourseWizardPause(
      step: CourseWizardStep.credits,
      savedAtUtc: DateTime.utc(2026, 10, 8),
    );
    final outsider = CourseManagerLibrary(
      personalCourses: [course],
      activeProfileId: '87654321-4321-4321-8321-cba987654321',
      pausedWizards: {course.courseId: pause},
    ).entriesFor(course).first;
    expect(outsider.action, CourseManagerAction.continueCourseWizard);
    expect(outsider.available, isFalse);
    expect(outsider.unavailableReason, contains('continue its Course Wizard'));
    // Without a paused Wizard the entry is not shown at all.
    expect(
      CourseManagerLibrary(
        personalCourses: [course],
        activeProfileId: _profileId,
      ).entriesFor(course).map((entry) => entry.action),
      isNot(contains(CourseManagerAction.continueCourseWizard)),
    );
  });

  group('Course Studio', () {
    testWidgets('New Course opens the Wizard; Cancel creates nothing', (
      tester,
    ) async {
      await _openStudio(tester);
      await tester.tap(find.byKey(const Key('create-course-icon-action')));
      await tester.pumpAndSettle();
      expect(find.byType(CourseWizardScreen), findsOneWidget);
      expect(
        find.byKey(const Key('course-wizard-explanation')),
        findsOneWidget,
      );
      expect(find.text('Step 1 of 5: Basics'), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-continue')), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-manual')), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-can-wait-variant')), findsOne);
      // Nothing to save yet: no Save for now, no Continue by hand.
      expect(find.byKey(const Key('course-wizard-save-for-now')), findsNothing);
      await tester.tap(find.byKey(const Key('course-wizard-cancel')));
      await tester.pumpUntilFileIoState(
        () =>
            find.byType(CourseWizardScreen).evaluate().isEmpty &&
            find.byType(CircularProgressIndicator).evaluate().isEmpty,
      );
      expect(
        (await tester.runAsync(() => CourseEditorService().listUserCourses()))!,
        isEmpty,
      );
    });

    testWidgets('Create it myself opens New Course with these values', (
      tester,
    ) async {
      await _openStudio(tester);
      await tester.tap(find.byKey(const Key('create-course-icon-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-manual')));
      await tester.pumpAndSettle();
      expect(find.byType(CourseWizardScreen), findsNothing);
      expect(find.text('Create new course'), findsOneWidget);
      expect(_fieldText(tester, 'Course title *'), 'Italian at the bar');
      expect(_fieldText(tester, 'Source language *'), 'English');
      expect(_fieldText(tester, 'Target language *'), 'Italian');
      expect(_fieldText(tester, 'Language variant'), 'Italian of Italy');
    });

    testWidgets('the Wizard saves at each step, pauses and resumes', (
      tester,
    ) async {
      await _openStudio(tester);
      await tester.tap(find.byKey(const Key('create-course-icon-action')));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Course title *'), 'Italian at the bar');
      await tester.enterText(_field('Target language *'), 'Italian');
      await tester.pump();
      await tester.tap(find.byKey(const Key('course-wizard-continue')));
      await tester.pumpUntilFileIoState(
        () => find.text('Step 2 of 5: About the Course').evaluate().isNotEmpty,
      );
      var stored = (await tester.runAsync(
        () => CourseEditorService().listUserCourses(),
      ))!.single;
      expect(stored.courseVersion, '1');
      expect(stored.versionNotes, 'Course Wizard: Basics');
      expect(stored.lessons, isEmpty);
      expect(stored.publicationState, PublicationState.draft);
      expect(
        (await tester.runAsync(
          () => CourseWizardMemory().recall(stored.courseId),
        ))!.step,
        CourseWizardStep.about,
      );
      expect(find.byKey(const Key('course-wizard-step-done-1')), findsOne);

      // Fill with an example asks nothing on an empty step.
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('course-wizard-fill-example-confirm')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpUntilFileIoState(
        () =>
            find.text('Step 3 of 5: Credits and rights').evaluate().isNotEmpty,
      );
      stored = (await tester.runAsync(
        () => CourseEditorService().listUserCourses(),
      ))!.single;
      expect(stored.courseVersion, '2');
      expect(stored.versionNotes, 'Course Wizard: About the Course');
      expect(stored.courseDescription, CourseWizardSample.about.description);
      expect(stored.keywords, CourseWizardSample.about.keywords);

      // Save for now closes the Wizard; the row says where it stopped.
      await tester.tap(find.byKey(const Key('course-wizard-save-for-now')));
      final paused = find.byKey(
        ValueKey('course-wizard-paused-${stored.courseId}'),
      );
      await tester.pumpUntilFileIoState(() => paused.evaluate().isNotEmpty);
      expect(find.byType(CourseWizardScreen), findsNothing);
      expect(
        find.text('Course Wizard paused: step 3 of 5 (Credits and rights)'),
        findsOneWidget,
      );
      // No change on this step: no new version.
      stored = (await tester.runAsync(
        () => CourseEditorService().listUserCourses(),
      ))!.single;
      expect(stored.courseVersion, '2');

      // Continue Course Wizard starts the Course's menu.
      final actions = find.byKey(
        ValueKey('course-manager-actions-${stored.courseId}'),
      );
      await tester.ensureVisible(actions);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      final continueItem = find.text('Continue Course Wizard');
      expect(continueItem, findsOneWidget);
      expect(
        tester.getTopLeft(continueItem).dy,
        lessThan(tester.getTopLeft(find.text('Course Info')).dy),
      );
      await tester.tap(continueItem);
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 5: Credits and rights'), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-step-done-2')), findsOne);
    });

    testWidgets('Finish needs a Lesson, saves them and opens the Editor', (
      tester,
    ) async {
      final stored = (await tester.runAsync(() => _store(_wizardCourse())))!;
      await tester.runAsync(
        () => CourseWizardMemory().remember(
          stored.courseId,
          CourseWizardPause(
            step: CourseWizardStep.lessons,
            savedAtUtc: DateTime.utc(2026, 10, 8),
          ),
        ),
      );
      await _openStudio(tester);
      final actions = find.byKey(
        ValueKey('course-manager-actions-${stored.courseId}'),
      );
      await tester.ensureVisible(actions);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue Course Wizard'));
      await tester.pumpAndSettle();
      expect(find.text('Step 5 of 5: Lessons'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);

      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpAndSettle();
      expect(find.text('Add at least one Lesson.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-wizard-lesson-2')), findsOneWidget);
      // Clear all asks first, then removes every Lesson.
      await tester.tap(find.byKey(const Key('course-wizard-clear-all')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('course-wizard-clear-all-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-wizard-lesson-0')), findsNothing);
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      // A Lesson without its title cannot be saved.
      await tester.enterText(_field('Lesson title *').first, '');
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpAndSettle();
      expect(find.text('Lesson 1 needs a title.'), findsOneWidget);
      await tester.enterText(_field('Lesson title *').first, 'Coffee');
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );
      final saved = (await tester.runAsync(
        () => CourseEditorService().listUserCourses(),
      ))!.single;
      expect(saved.lessons.map((lesson) => lesson.title), [
        'Coffee',
        'Paying the bill',
        'Back to the station',
      ]);
      expect(saved.versionNotes, 'Course Wizard: Lessons');
      expect(
        await tester.runAsync(
          () => CourseWizardMemory().recall(stored.courseId),
        ),
        isNull,
      );
      // Finished: the Editor shows no paused line.
      expect(
        find.byKey(const Key('course-editor-wizard-paused')),
        findsNothing,
      );
    });

    testWidgets('the Course Editor shows the paused line and continues', (
      tester,
    ) async {
      final stored = (await tester.runAsync(() => _store(_wizardCourse())))!;
      await tester.runAsync(
        () => CourseWizardMemory().remember(
          stored.courseId,
          CourseWizardPause(
            step: CourseWizardStep.options,
            savedAtUtc: DateTime.utc(2026, 10, 8),
          ),
        ),
      );
      await _openStudio(tester);
      final row = find.widgetWithText(ListTile, 'Italian at the bar');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('course-editor-wizard-paused'))
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text('Course Wizard paused: step 4 of 5 (Course options)'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('course-editor-continue-wizard')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseWizardScreen).evaluate().isNotEmpty,
      );
      expect(find.text('Step 4 of 5: Course options'), findsOneWidget);
      expect(find.byType(CourseEditorScreen), findsNothing);

      // Continue by hand forgets the Wizard and opens the Editor.
      await tester.tap(find.byKey(const Key('course-wizard-by-hand')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );
      expect(
        await tester.runAsync(
          () => CourseWizardMemory().recall(stored.courseId),
        ),
        isNull,
      );
    });
  });

  testWidgets('leaving with a change asks to save it or leave it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stored = (await tester.runAsync(() => _store(_wizardCourse())))!;
    CourseWizardOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                outcome = await Navigator.of(context).push<CourseWizardOutcome>(
                  MaterialPageRoute(
                    builder: (_) => CourseWizardScreen(
                      course: stored,
                      access: CourseAccessPolicy.evaluate(
                        stored,
                        profileId: _profileId,
                      ),
                      pause: CourseWizardPause(
                        step: CourseWizardStep.about,
                        savedAtUtc: DateTime.utc(2026, 10, 8),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Course description'), 'Coffee first.');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('course-wizard-leave')), findsOneWidget);
    await tester.tap(find.byKey(const Key('course-wizard-leave-discard')));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseWizardScreen).evaluate().isEmpty,
    );
    expect(outcome, isA<CourseWizardPaused>());
    expect(find.textContaining('Course Wizard paused.'), findsOneWidget);
    final kept = (await tester.runAsync(
      () => CourseEditorService().listUserCourses(),
    ))!.single;
    expect(kept.courseDescription, isEmpty);
    expect(kept.courseVersion, '1');
    expect(
      (await tester.runAsync(
        () => CourseWizardMemory().recall(stored.courseId),
      ))!.step,
      CourseWizardStep.about,
    );
  });

  testWidgets('every step fits a 360-pixel window', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final course = CourseWizardLessons.applyTo(
      CourseWizardSample.options.applyTo(
        CourseWizardSample.credits(
          'Wizard Author',
        ).applyTo(CourseWizardSample.about.applyTo(_wizardCourse())),
      ),
      CourseWizardSample.lessons,
      now: _now,
    );
    for (final step in CourseWizardStep.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: CourseWizardScreen(
            key: ValueKey(step),
            course: course,
            access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
            pause: CourseWizardPause(
              step: step,
              savedAtUtc: DateTime.utc(2026, 10, 8),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Step ${step.number} of 5: ${step.title}'),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const Key('course-wizard-page')),
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: step.title);
    }
  });

  testWidgets('Use GuideBook off asks first and explains why', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final course = _wizardCourse();
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-editor-lock')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-lesson-options')));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('course-use-guidebook'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('course-use-guidebook-off-notice')),
      findsOneWidget,
    );
    expect(find.textContaining('The GuideBook is recommended.'), findsOne);
    expect(find.textContaining('are kept'), findsOne);
    await tester.tap(find.byKey(const Key('course-use-guidebook-keep')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-use-guidebook-turn-off')));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    // Turning it back on asks nothing.
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('course-use-guidebook-off-notice')),
      findsNothing,
    );
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Wizard Author',
);
final _now = DateTime.utc(2026, 10, 8, 12);

void _profiles() => SharedPreferences.setMockInitialValues({
  ProfileService.profilesKey: [_profile.encode()],
  ProfileService.activeProfileIdKey: _profileId,
});

Course _wizardCourse() =>
    CourseLibraryOperations(clock: () => _now).newWizardCourse(
      creator: _profile,
      title: 'Italian at the bar',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      sourceLanguageTag: 'en',
      targetLanguageTag: 'it',
      languageVariant: 'Italian of Italy',
    );

/// [course] saved as the Wizard's first step saves it.
Future<Course> _store(Course course) async {
  final session = CourseAuthoringSession(
    course: course,
    access: CourseAccessPolicy.evaluate(
      course,
      profileId: _profileId,
    ).copyForUnconfirmedCreator(),
    editorService: CourseEditorService(),
    isNewCourse: true,
  )..setEditorMode(CourseEditorMode.edit);
  return (await session.confirm(
    languageCode: 'IT',
    versionNotes: 'Course Wizard: Basics',
  )).course;
}

Future<void> _openStudio(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CourseProjectsScreen(
        currentCourse: Course(
          courseId: 'wizard-host',
          learningLanguage: 'Italian',
          interfaceLanguage: 'English',
          sourceLanguage: 'English',
          targetLanguage: 'Italian',
          title: 'Host',
          ttsLanguage: 'it-IT',
          lessons: const [],
        ),
      ),
    ),
  );
  await tester.pumpUntilFileIoState(
    () =>
        find
            .byKey(const Key('create-course-icon-action'))
            .evaluate()
            .isNotEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty,
  );
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

String _fieldText(WidgetTester tester, String label) =>
    tester.widget<TextField>(_field(label)).controller!.text;

class _Ids implements AuthoringIdGenerator {
  var _next = 0;
  @override
  String next(String kind) => '${kind}_${_next++}';
}
