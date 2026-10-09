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
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
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
        step: CourseWizardStep.about,
        savedAtUtc: DateTime.utc(2026, 10, 8, 12),
      );
      final read = CourseWizardPause.fromJson(pause.toJson())!;
      expect(read.step, CourseWizardStep.about);
      expect(read.savedAtUtc, pause.savedAtUtc);
      expect(read.lessonId, isNull);
      expect(pause.toJson(), {
        'step': 3,
        'savedAtUtc': '2026-10-08T12:00:00.000Z',
      });
      expect(
        pause.description,
        'Course Wizard paused: step 3 of 7 (About the Course)',
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
      expect(CourseWizardStep.byNumber(8), CourseWizardStep.rounds);
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
      expect(course.languageVariant, isEmpty);
      expect(course.targetLanguageTag, 'it');
      expect(Course.fromJson(course.toJson()).toJson(), course.toJson());
    });

    test('the flag, the cover and About write their fields', () {
      const credit = CourseMediaAttribution(
        author: 'A. Painter',
        license: 'CC BY 4.0',
      );
      final picture = CourseWizardPicture(
        coverImage: 'media:${'a' * 64}.png',
        coverCredit: credit,
        flag: CourseFlagSelection.builtIn('IT'),
      );
      var course = picture.applyTo(_wizardCourse());
      expect(course.coverImage, picture.coverImage);
      expect(course.flagCode, 'IT');
      expect(course.mediaAttributions.single.author, 'A. Painter');
      // The same credit is never added twice.
      expect(picture.applyTo(course).mediaAttributions, hasLength(1));
      final noPicture = const CourseWizardPicture().applyTo(course);
      expect(noPicture.coverImage, isEmpty);
      expect(noPicture.flagCode, isEmpty);

      const about = CourseWizardAbout(
        description: '  Coffee and pastries.  ',
        startLevel: 'A1',
        targetLevel: 'A2',
        studyHours: 4,
        minimumAge: 9,
        keywords: ['bar', 'travel'],
      );
      course = about.applyTo(course);
      expect(course.courseDescription, 'Coffee and pastries.');
      expect(course.estimatedStudyHours, 4);
      expect(course.minimumAge, 9);
      expect(course.keywords, ['bar', 'travel']);
      expect(course.coverImage, picture.coverImage);
      final cleared = const CourseWizardAbout().applyTo(course);
      expect(cleared.toJson().containsKey('estimatedStudyHours'), isFalse);
      expect(cleared.toJson().containsKey('keywords'), isFalse);
      expect(cleared.courseDescription, isEmpty);
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

  test('the GuideBook step: modules, approval and the Rounds that follow', () {
    final ids = _Ids();
    var course = CourseWizardLessons.applyTo(
      _wizardCourse(),
      CourseWizardSample.lessons,
      now: _now,
      ids: ids,
    );
    final lesson = course.lessons.first;
    expect(CourseWizardGuidebook.isReady(lesson), isFalse);
    expect(
      CourseWizardGuidebook.problem(lesson, 0),
      contains('needs a module with at least 3'),
    );
    final modules = CourseWizardSample.guidebook(ids);
    course = CourseWizardGuidebook.withModules(
      course,
      lesson.lessonId,
      modules,
      state: PublicationState.draft,
      now: _now,
    );
    var written = course.lessons.first;
    expect(written.guidebook.publicationState, PublicationState.draft);
    expect(CourseWizardGuidebook.hasUsableModule(written), isTrue);
    expect(CourseWizardGuidebook.isReady(written), isFalse);
    expect(
      CourseWizardGuidebook.problem(written, 0),
      contains('GuideBook is ready'),
    );
    expect(CourseWizardGuidebook.firstProblem(course)!.index, 0);
    course = CourseWizardGuidebook.withModules(
      course,
      lesson.lessonId,
      modules,
      state: PublicationState.published,
      now: _now,
    );
    expect(CourseWizardGuidebook.isReady(course.lessons.first), isTrue);
    expect(CourseWizardGuidebook.firstProblem(course)!.index, 1);
    expect(
      Course.fromJson(
        course.toJson(),
      ).lessons.first.guidebook.modules.single.words,
      hasLength(modules.single.words.length),
    );

    // A Round focusing on a module loses the link when the module goes.
    written = course.lessons.first;
    final focused = Lesson.fromJson({
      ...written.toJson(),
      'rounds': [
        LearningRound(
          id: 'round_1',
          title: '',
          content: const [],
          updatedAt: _now,
          focusModuleId: modules.single.id,
        ).toJson(),
      ],
    });
    course = Course.fromJson({
      ...course.toJson(),
      'lessons': [
        focused.toJson(),
        for (final other in course.lessons.skip(1)) other.toJson(),
      ],
    });
    expect(
      CourseWizardGuidebook.roundsNote(course.lessons.first, 0, 'Clearing'),
      'Lesson 1 has 1 Round. Clearing its modules does not remove it, but 1 '
      'loses its focus module.',
    );
    course = CourseWizardGuidebook.withModules(
      course,
      focused.lessonId,
      const [],
      state: PublicationState.draft,
      now: _now,
    );
    expect(course.lessons.first.rounds.single.focusModuleId, isNull);
    expect(
      CourseWizardGuidebook.roundsNote(course.lessons.first, 0, 'Clearing'),
      isNull,
    );

    // The paused line names the Lesson of the GuideBook step.
    final pause = CourseWizardPause(
      step: CourseWizardStep.guidebook,
      savedAtUtc: DateTime.utc(2026, 10, 8),
      lessonId: course.lessons[1].lessonId,
    );
    expect(
      pause.describe(course),
      'Course Wizard paused: step 6 of 7 (GuideBook, Lesson 2)',
    );
    expect(pause.description, 'Course Wizard paused: step 6 of 7 (GuideBook)');
  });

  test('the Round Wizard makes untitled Rounds on request', () {
    final ids = _Ids();
    final modules = CourseWizardSample.guidebook(ids);
    final guidebook = Guidebook(modules: modules);
    final generator = GuidebookRoundGenerator(
      randomSeed: 1,
      draftIds: ids,
      now: () => _now,
    );
    final plan = generator.plan(
      guidebook,
      focusModuleId: null,
      roundCount: 3,
      exercisesPerRound: 8,
    );
    final titled = generator.createDrafts(guidebook, plan);
    expect(titled.every((round) => round.title.isNotEmpty), isTrue);
    final untitled = generator.createDrafts(
      guidebook,
      plan,
      roundTitles: false,
    );
    expect(untitled, hasLength(titled.length));
    expect(untitled.every((round) => round.title.isEmpty), isTrue);

    // The Rounds step: a Lesson without Rounds is not done.
    var course = CourseWizardLessons.applyTo(
      _wizardCourse(),
      CourseWizardSample.lessons,
      now: _now,
      ids: ids,
    );
    expect(CourseWizardRounds.firstProblem(course)!.index, 0);
    course = CourseWizardRounds.withRounds(
      course,
      course.lessons.first.lessonId,
      untitled,
      now: _now,
    );
    expect(course.lessons.first.rounds, hasLength(untitled.length));
    expect(CourseWizardRounds.firstProblem(course)!.index, 1);
    final duel = CourseWizardRounds.duelCount(course.lessons.first);
    expect(duel.questions + duel.audio, greaterThan(0));
    course = CourseWizardRounds.withRounds(
      course,
      course.lessons.first.lessonId,
      const [],
      now: _now,
      replace: true,
    );
    expect(course.lessons.first.rounds, isEmpty);
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
      step: CourseWizardStep.about,
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
      expect(find.text('Step 1 of 7: Basics'), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-continue')), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-manual')), findsOneWidget);
      // The variant is optional and says so; the long explanation is hidden.
      expect(_field('Language variant (optional)'), findsOneWidget);
      expect(_field('Source language *'), findsOneWidget);
      expect(find.textContaining('American English'), findsWidgets);
      expect(find.textContaining('Italian of Italy'), findsNothing);
      expect(find.text('Tell me more'), findsOneWidget);
      expect(
        find.textContaining('Continue with the Course Wizard saves'),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('course-wizard-explanation-more')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Continue with the Course Wizard saves'),
        findsOne,
      );
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
      // The example leaves the optional variant empty.
      expect(_fieldText(tester, 'Language variant'), isEmpty);
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
        () =>
            find.text('Step 2 of 7: Flag or cover image').evaluate().isNotEmpty,
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
        CourseWizardStep.flag,
      );
      expect(find.byKey(const Key('course-wizard-step-done-1')), findsOne);

      // The flag step: nothing changed, Next saves nothing.
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpUntilFileIoState(
        () => find.text('Step 3 of 7: About the Course').evaluate().isNotEmpty,
      );
      // Description and Authors in view; the rest behind Advanced.
      expect(_field('Course description (optional)'), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-credit-0')), findsOneWidget);
      expect(_field('Starting level'), findsNothing);
      expect(_field('Course content license'), findsNothing);
      await tester.tap(find.byKey(const Key('course-wizard-advanced')));
      await tester.pumpAndSettle();
      expect(_field('Starting level'), findsOneWidget);
      expect(
        find.byKey(const Key('course-wizard-advanced-note')),
        findsOneWidget,
      );

      // Fill with an example: the step holds the creator's credit, so it
      // asks first.
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('course-wizard-fill-example-confirm')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpUntilFileIoState(
        () => find.text('Step 4 of 7: Course options').evaluate().isNotEmpty,
      );
      stored = (await tester.runAsync(
        () => CourseEditorService().listUserCourses(),
      ))!.single;
      expect(stored.courseVersion, '2');
      expect(stored.versionNotes, 'Course Wizard: About the Course');
      expect(stored.courseDescription, CourseWizardSample.about.description);
      expect(stored.keywords, CourseWizardSample.about.keywords);
      expect(stored.license, 'CC BY 4.0');
      // Course options: nothing but Advanced.
      expect(find.byKey(const Key('course-wizard-advanced')), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-create-duels')), findsNothing);

      // Save for now closes the Wizard; the row says where it stopped.
      await tester.tap(find.byKey(const Key('course-wizard-save-for-now')));
      final paused = find.byKey(
        ValueKey('course-wizard-paused-${stored.courseId}'),
      );
      await tester.pumpUntilFileIoState(() => paused.evaluate().isNotEmpty);
      expect(find.byType(CourseWizardScreen), findsNothing);
      expect(
        find.text('Course Wizard paused: step 4 of 7 (Course options)'),
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
      expect(find.text('Step 4 of 7: Course options'), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-step-done-3')), findsOne);
    });

    testWidgets('Lessons, then each GuideBook approved, then the Rounds', (
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
      expect(find.text('Step 5 of 7: Lessons'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

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
        () => find.text('Step 6 of 7: GuideBook').evaluate().isNotEmpty,
      );
      var saved = (await tester.runAsync(
        () => CourseEditorService().listUserCourses(),
      ))!.single;
      expect(saved.lessons.map((lesson) => lesson.title), [
        'Coffee',
        'Paying the bill',
        'Back to the station',
      ]);
      expect(saved.versionNotes, 'Course Wizard: Lessons');
      expect(
        (await tester.runAsync(
          () => CourseWizardMemory().recall(stored.courseId),
        ))!.lessonId,
        saved.lessons.first.lessonId,
      );
      expect(find.text('Next'), findsOneWidget);

      // Next needs every Lesson's GuideBook.
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Lesson 1 (Coffee) needs a module with at least 3 Words & '
          'Expressions.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      // The example opens on the module page; Done keeps it.
      expect(find.byKey(const Key('guidebook-module-title')), findsOneWidget);
      await tester.tap(find.byKey(const Key('guidebook-module-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-wizard-module-0')), findsOneWidget);
      expect(find.textContaining('Not approved yet'), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('press “This Lesson\'s GuideBook is ready”'),
        findsWidgets,
      );

      for (var lesson = 1; lesson <= 3; lesson++) {
        if (lesson > 1) {
          await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('guidebook-module-done')));
          await tester.pumpAndSettle();
        }
        final ready = find.byKey(const Key('course-wizard-guidebook-ready'));
        await tester.ensureVisible(ready);
        await tester.tap(ready);
        await tester.pumpUntilFileIoState(
          () => find
              .textContaining('Lesson $lesson\'s GuideBook is ready')
              .evaluate()
              .isNotEmpty,
        );
        saved = (await tester.runAsync(
          () => CourseEditorService().listUserCourses(),
        ))!.single;
        expect(saved.versionNotes, 'Course Wizard: GuideBook, Lesson $lesson');
        final guidebook = saved.lessons[lesson - 1].guidebook;
        expect(guidebook.publicationState, PublicationState.published);
        expect(guidebook.modules.single.title, 'Al bar');
      }

      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpUntilFileIoState(
        () => find.text('Step 7 of 7: Rounds').evaluate().isNotEmpty,
      );
      expect(find.text('Finish'), findsOneWidget);
      // Save for now remembers the Lesson of the Rounds step.
      await tester.tap(find.byKey(const Key('course-wizard-save-for-now')));
      await tester.pumpUntilFileIoState(
        () => find
            .text('Course Wizard paused: step 7 of 7 (Rounds, Lesson 1)')
            .evaluate()
            .isNotEmpty,
      );
    });

    testWidgets('the Rounds step makes Rounds with the Round Wizard', (
      tester,
    ) async {
      final ids = _Ids();
      var course = CourseWizardLessons.applyTo(
        _wizardCourse(),
        [CourseWizardSample.lessons.first],
        now: _now,
        ids: ids,
      );
      course = CourseWizardGuidebook.withModules(
        course,
        course.lessons.single.lessonId,
        CourseWizardSample.guidebook(ids),
        state: PublicationState.published,
        now: _now,
      );
      final stored = (await tester.runAsync(() => _store(course)))!;
      await tester.runAsync(
        () => CourseWizardMemory().remember(
          stored.courseId,
          CourseWizardPause(
            step: CourseWizardStep.rounds,
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
      expect(find.text('Step 7 of 7: Rounds'), findsOneWidget);
      expect(find.text('No Rounds yet.'), findsOneWidget);
      expect(find.text('Duel: 0 questions (25 needed)'), findsOneWidget);
      // What the Round Wizard does stands beside Make Rounds (owner,
      // 9 October 2026).
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('course-wizard-rounds-explanation')),
            )
            .data,
        contains('A Duel needs 25 questions'),
      );

      // Finish needs Rounds in every Lesson.
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Lesson 1 (Coffee and pastries) has no Rounds yet: make them with '
          'the Round Wizard.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('course-wizard-make-rounds')));
      await tester.pumpAndSettle();
      expect(find.text('Generate Rounds'), findsOneWidget);
      // From the Course Wizard the Rounds are untitled by default (owner,
      // 9 October 2026: keep it simple), and no Listen Round is planned.
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('generator-round-titles')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('generator-listen-round')),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('generator-review-plan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('generator-duel-count')), findsOneWidget);
      expect(find.textContaining('(25 needed)'), findsWidgets);
      final generate = find.byKey(const Key('generator-generate'));
      await tester.ensureVisible(generate);
      await tester.tap(generate);
      await tester.pumpAndSettle();
      final approve = find.byKey(const Key('generator-approve'));
      await tester.ensureVisible(approve);
      await tester.tap(approve);
      await tester.pumpUntilFileIoState(
        () => find
            .textContaining('Rounds added to Lesson 1')
            .evaluate()
            .isNotEmpty,
      );
      final saved = (await tester.runAsync(
        () => CourseEditorService().listUserCourses(),
      ))!.single;
      expect(saved.versionNotes, 'Course Wizard: Rounds, Lesson 1');
      final rounds = saved.lessons.single.rounds;
      expect(rounds, isNotEmpty);
      expect(rounds.every((round) => round.title.isEmpty), isTrue);
      expect(
        rounds.every((round) => round.publicationState.isPublished),
        isFalse,
      );
      expect(find.byKey(const Key('course-wizard-round-2')), findsOneWidget);

      // Finish congratulates, says what is still red, where to change the
      // Course and when to Publish (owner, 9 October 2026).
      await tester.tap(find.byKey(const Key('course-wizard-next')));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('course-wizard-finished'))
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('Congratulations!'), findsOneWidget);
      expect(
        find.byKey(const Key('course-wizard-finished-red')).evaluate().length +
            find
                .byKey(const Key('course-wizard-finished-clean'))
                .evaluate()
                .length,
        1,
      );
      expect(find.textContaining('switch it to Edit mode'), findsOneWidget);
      expect(find.textContaining('press Publish'), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-wizard-finished-ok')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );
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

    testWidgets('a paused row opens the Wizard; the Editor continues it', (
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
      // A tap on the row opens the paused Wizard where it stopped (owner,
      // 9 October 2026).
      final row = find.widgetWithText(ListTile, 'Italian at the bar');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseWizardScreen).evaluate().isNotEmpty,
      );
      expect(find.text('Step 4 of 7: Course options'), findsOneWidget);
      expect(find.byType(CourseEditorScreen), findsNothing);
      await tester.tap(find.byKey(const Key('course-wizard-save-for-now')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseWizardScreen).evaluate().isEmpty,
      );

      // The menu's Edit opens the Course Editor, with the paused line.
      final actions = find.byKey(
        ValueKey('course-manager-actions-${stored.courseId}'),
      );
      await tester.ensureVisible(actions);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('course-editor-wizard-paused'))
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.text('Course Wizard paused: step 4 of 7 (Course options)'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('course-editor-continue-wizard')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseWizardScreen).evaluate().isNotEmpty,
      );
      expect(find.text('Step 4 of 7: Course options'), findsOneWidget);
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
    await tester.enterText(
      _field('Course description (optional)'),
      'Coffee first.',
    );
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

  testWidgets('the GuideBook step adds, moves and removes modules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final course = CourseWizardLessons.applyTo(
      _wizardCourse(),
      CourseWizardSample.lessons,
      now: _now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CourseWizardScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
          pause: CourseWizardPause(
            step: CourseWizardStep.guidebook,
            savedAtUtc: DateTime.utc(2026, 10, 8),
            lessonId: course.lessons[1].lessonId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The paused Lesson is shown.
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey('course-wizard-guidebook-lesson-1')),
          )
          .selected,
      isTrue,
    );
    expect(find.textContaining('Needs a module'), findsOneWidget);
    // The module details stand above the modules (owner, 9 October 2026).
    expect(
      find.byKey(const Key('course-wizard-module-explanation')),
      findsOneWidget,
    );
    await _addModule(
      tester,
      title: 'Il conto',
      words: const [
        ('il conto', 'the bill'),
        ('pagare', 'to pay'),
        ('lo scontrino', 'the receipt'),
      ],
    );
    expect(find.text('Step 6 of 7: GuideBook'), findsOneWidget);
    expect(find.text('Il conto'), findsOneWidget);
    expect(find.text('0 sentences · 3 words'), findsOneWidget);
    expect(find.textContaining('Not approved yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
    await tester.pumpAndSettle();
    // The Lesson holds a module: Fill asks first.
    await tester.tap(
      find.byKey(const Key('course-wizard-fill-example-confirm')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('guidebook-module-done')));
    await tester.pumpAndSettle();
    expect(find.text('Al bar'), findsOneWidget);
    expect(find.text('Il conto'), findsNothing);
    await _addModule(
      tester,
      title: 'Saluti',
      words: const [('ciao', 'hi'), ('buongiorno', 'good morning')],
    );
    await tester.tap(find.byKey(const ValueKey('course-wizard-module-up-1')));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Saluti')).dy,
      lessThan(tester.getTopLeft(find.text('Al bar')).dy),
    );
    await tester.tap(
      find.byKey(const ValueKey('course-wizard-module-remove-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('course-wizard-module-remove-confirm')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saluti'), findsNothing);
    expect(find.byKey(const ValueKey('course-wizard-module-0')), findsOne);
    expect(tester.takeException(), isNull);
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
        find.text('Step ${step.number} of 7: ${step.title}'),
        findsOneWidget,
      );
      // The step shown is in view in the step bar.
      expect(
        tester
            .getRect(find.byKey(ValueKey('course-wizard-step-${step.number}')))
            .right,
        lessThanOrEqualTo(360),
      );
      // The long explanation and the Advanced fields fit too.
      await tester.tap(find.byKey(const Key('course-wizard-explanation-more')));
      await tester.pumpAndSettle();
      final advanced = find.byKey(const Key('course-wizard-advanced'));
      if (advanced.evaluate().isNotEmpty) {
        await tester.ensureVisible(advanced);
        await tester.pumpAndSettle();
        await tester.tap(advanced);
        await tester.pumpAndSettle();
      }
      await tester.drag(
        find.byKey(const Key('course-wizard-page')),
        const Offset(0, -4000),
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

/// Add a module on the Wizard's GuideBook step: the module page, its
/// [title] and [words], then Done.
Future<void> _addModule(
  WidgetTester tester, {
  required String title,
  List<(String, String)> words = const [],
}) async {
  Future<void> tapKey(Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  Future<void> type(Key key, String text) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.enterText(find.byKey(key), text);
    await tester.pumpAndSettle();
  }

  await tapKey(const Key('course-wizard-add-module'));
  await type(const Key('guidebook-module-title'), title);
  for (var i = 0; i < words.length; i++) {
    await tapKey(const ValueKey('guidebook-module-add-word'));
    await type(ValueKey('guidebook-module-word-$i-target'), words[i].$1);
    await type(ValueKey('guidebook-module-word-$i-source'), words[i].$2);
  }
  await tester.tap(find.byKey(const Key('guidebook-module-done')));
  await tester.pumpAndSettle();
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
