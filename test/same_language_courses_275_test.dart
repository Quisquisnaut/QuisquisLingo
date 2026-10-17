import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/controllers/new_course_form.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/course_wizard_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/screens/new_course_dialog.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/course_language_pair.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_minimum_build.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/course_kind_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Build 275 Revision 0 (owner decisions of 16 October 2026): a Course can
// teach a language in that same language, chosen first in the Course Wizard
// and in New Course's form. Revision 2 (owner decision of 17 October 2026):
// the choice is stored in the Course (`sameLanguage`) and never derived.

const _profileId = '27500000-0000-4000-8000-000000000001';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Kind Author',
);
final _now = DateTime.utc(2026, 10, 16, 12);
final _operations = CourseLibraryOperations(clock: () => _now);

Course _course({
  required String source,
  required String target,
  String sourceTag = '',
  String targetTag = '',
  bool sameLanguage = false,
}) => _operations.newWizardCourse(
  creator: _profile,
  title: 'Kinds',
  sourceLanguage: source,
  targetLanguage: target,
  sourceLanguageTag: sourceTag,
  targetLanguageTag: targetTag,
  sameLanguage: sameLanguage,
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).controller!.text;

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the rule', () {
    test('the kind is what the creator chose, stored in the Course', () {
      final english = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
        sameLanguage: true,
      );
      expect(CourseLanguagePair.isSameLanguage(english), isTrue);
      expect(CourseLanguagePair.kindOf(english), CourseKind.sameLanguage);
      expect(english.toJson()['sameLanguage'], isTrue);
      final again = Course.fromJson(english.toJson());
      expect(again.sameLanguage, isTrue);
      // Never derived from the languages: the same two languages without
      // the choice are a translation Course.
      final translation = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
      );
      expect(CourseLanguagePair.kindOf(translation), CourseKind.otherLanguage);
      expect(translation.toJson().containsKey('sameLanguage'), isFalse);
      // A dialect typed by hand beside its language is the creator's call
      // too: Viterbese through Italian translates.
      final viterbese = _course(
        source: 'Italian',
        target: 'Viterbese',
        sourceTag: 'it',
      );
      expect(CourseLanguagePair.isSameLanguage(viterbese), isFalse);
    });

    test('the field is strict, and a Course without it reads as before', () {
      final json = _course(source: 'English', target: 'Italian').toJson();
      expect(Course.fromJson(json).sameLanguage, isFalse);
      expect(
        () => Course.fromJson({...json, 'sameLanguage': 'yes'}),
        throwsFormatException,
      );
      expect(
        () => Course.fromJson({...json, 'sameLanguage': null}),
        throwsFormatException,
      );
      expect(
        Course.fromJson({...json, 'sameLanguage': false}).sameLanguage,
        isFalse,
      );
    });

    test(
      'Through another language refuses only one language written twice',
      () {
        bool identical(String a, String aTag, String b, String bTag) =>
            CourseLanguagePair.identicalChoices(
              learningName: a,
              learningTag: aTag,
              baseName: b,
              baseTag: bTag,
            );
        expect(identical('English', 'en', 'English', 'en'), isTrue);
        expect(identical('english', 'EN', 'English', 'en'), isTrue);
        expect(identical('Viterbèse', '', 'Viterbese', ''), isTrue);
        expect(identical('', '', '', ''), isFalse);
        // Any difference of name or tag is two languages.
        expect(
          identical('English (US)', 'en-US', 'English (UK)', 'en-GB'),
          isFalse,
        );
        expect(identical('English (UK)', 'en', 'English', 'en'), isFalse);
        expect(identical('English', 'en-US', 'English', 'en-GB'), isFalse);
        expect(identical('English', 'en_US', 'English', 'en-us'), isTrue);
        expect(identical('Italian', 'it', 'English', 'en'), isFalse);
        expect(identical('Viterbese', '', 'Italian', 'it'), isFalse);
        // The agreed rule, word for word: the same name with a tag on one
        // side only is two languages.
        expect(identical('Viterbese', '', 'Viterbese', 'vit'), isFalse);
      },
    );

    test('a Course in the same language asks for this build or later', () {
      final english = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
        sameLanguage: true,
      );
      final stamped = CourseMinimumBuild.stamp(english);
      expect(stamped.minimumAppBuild, CourseLanguagePair.minimumAppBuild);
      expect(stamped.sameLanguage, isTrue);
      // Stamped once: a Course already asking for it is left as it is.
      expect(CourseLanguagePair.withMinimumAppBuild(stamped), same(stamped));
      final translation = _course(source: 'English', target: 'Italian');
      // A translation Course is not raised for it (a new Course already
      // asks for the picture border's build).
      expect(
        CourseMinimumBuild.stamp(translation).minimumAppBuild,
        lessThan(CourseLanguagePair.minimumAppBuild),
      );
    });

    test('two Courses of different kinds are never merged, either way', () {
      final english = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
        sameLanguage: true,
      );
      final translation = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
      );
      final merge = CourseMergeService();
      for (final (left, right) in [
        (english, translation),
        (translation, english),
      ]) {
        expect(
          () => merge.validateCompatibility(left, right),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              CourseMergeService.sameLanguageMismatch,
            ),
          ),
        );
      }
    });

    test('Copy as New Course, a Fork and a copied Round keep the kind', () {
      final form = NewCourseForm(creator: _profile)
        ..kind = CourseKind.sameLanguage
        ..title.text = 'Kinds';
      addTearDown(form.dispose);
      form.target.text.text = 'English';
      final english =
          (form.submit('Kinds', _operations) as NewCourseAccepted).course;
      expect(english.sameLanguage, isTrue);
      // Copy as New Course and a Fork share one copy of the Course.
      final copy = AuthoringDuplicationService().copyCourseAsNew(
        english,
        title: 'A copy',
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: _profileId,
          displayName: 'Kind Author',
        ),
        maintainer: const CourseMaintainer(_profileId),
      );
      expect(copy.sameLanguage, isTrue);
      final moved = CourseAuthoringTransferService().copyRound(
        english,
        sourceLessonId: english.lessons.first.lessonId,
        roundId: english.lessons.first.rounds.first.id,
        destinationLessonId: english.lessons.last.lessonId,
      );
      expect(moved.sameLanguage, isTrue);
    });
  });

  group('a save', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('qql_275_kind_');
      ProfileService.beginAccessSession();
      await ProfileService().createProfile(
        'Kind Author',
        learnerProfileId: _profileId,
        generateScreenNameSuffix: false,
      );
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('stores the kind and the build that reads it', () async {
      final media = CourseMediaStore(supportDirectory: () async => root);
      final editor = CourseEditorService(
        courseStore: CourseFileStore(supportDirectory: () async => root),
        mediaStore: media,
        backupService: CourseBackupService(
          backupsDirectoryProvider: () async => root,
          mediaStore: media,
        ),
        clock: () => _now,
      );
      final english = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
        sameLanguage: true,
      );
      final saved = await editor.confirmCourseTransaction(
        originalCourse: english,
        workingCourse: english,
        languageCode: 'EN',
        versionNotes: '',
        isNewCourse: true,
      );
      expect(saved.course.sameLanguage, isTrue);
      expect(saved.course.minimumAppBuild, CourseLanguagePair.minimumAppBuild);
      // Read back as the app lists stored Courses.
      final again = (await editor.listUserCourses()).singleWhere(
        (course) => course.courseId == english.courseId,
      );
      expect(again.sameLanguage, isTrue);
      expect(again.minimumAppBuild, CourseLanguagePair.minimumAppBuild);
    });
  });

  group('the Course Wizard', () {
    testWidgets('neither kind is chosen at first, and Continue says so', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(const MaterialApp(home: CourseWizardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('What kind of Course?'), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-kind-other')), findsOneWidget);
      expect(find.byKey(const Key('course-wizard-kind-same')), findsOneWidget);
      // No language field before a kind.
      expect(_field('Source language *'), findsNothing);
      expect(_field('Language *'), findsNothing);
      await tester.enterText(_field('Course title *'), 'Kinds');
      await tester.tap(find.byKey(const Key('course-wizard-continue')));
      await tester.pump();
      expect(find.text(CourseKindChoice.missing), findsOneWidget);
    });

    testWidgets('In the same language: one Language field, written on both '
        'sides', (tester) async {
      _tall(tester);
      CourseWizardOutcome? outcome;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                outcome = await Navigator.of(context).push<CourseWizardOutcome>(
                  MaterialPageRoute(builder: (_) => const CourseWizardScreen()),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-kind-same')));
      await tester.pump();
      expect(_field('Source language *'), findsNothing);
      expect(_field('Target language *'), findsNothing);
      expect(find.byKey(const Key('course-wizard-language')), findsOneWidget);
      await tester.enterText(_field('Course title *'), 'English words');
      await tester.enterText(
        find.byKey(const Key('course-wizard-language')),
        'english',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('course-wizard-manual')));
      await tester.pumpAndSettle();
      final basics = (outcome! as CourseWizardCreateManually).basics;
      expect(basics.kind, CourseKind.sameLanguage);
      expect(basics.title, 'English words');
      expect(basics.sourceLanguage, 'English');
      expect(basics.sourceLanguageTag, 'en');
      expect(basics.targetLanguage, 'English');
      expect(basics.targetLanguageTag, 'en');
    });

    testWidgets('Continue with Wizard In the same language makes the Course '
        'with one language on both sides', (tester) async {
      _tall(tester);
      final profiles = ProfileService();
      await profiles.createProfile('Kind Author', learnerProfileId: _profileId);
      await profiles.setActiveProfileById(_profileId);
      await tester.pumpWidget(const MaterialApp(home: CourseWizardScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-kind-same')));
      await tester.pump();
      await tester.enterText(_field('Course title *'), 'English words');
      await tester.enterText(
        find.byKey(const Key('course-wizard-language')),
        'English',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('course-wizard-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 8: Flag or cover image'), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-wizard-back')));
      await tester.pumpAndSettle();
      // Basics reads the kind stored in the Course just made.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('course-wizard-kind-shown')))
            .data,
        'In the same language: English',
      );
    });

    testWidgets('Fill on a resumed Wizard follows the Course\'s kind', (
      tester,
    ) async {
      _tall(tester);
      final course = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
        sameLanguage: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseWizardScreen(
            course: course,
            access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
            pause: CourseWizardPause(
              step: CourseWizardStep.basics,
              savedAtUtc: DateTime.utc(2026, 10, 16),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('course-wizard-fill-example-confirm')),
          matching: find.text('Fill'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_field('Course title *')).controller!.text,
        CourseWizardSample.sameLanguageBasics.title,
      );
    });

    testWidgets('Through another language refuses one language twice', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(const MaterialApp(home: CourseWizardScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-kind-other')));
      await tester.pump();
      await tester.enterText(_field('Course title *'), 'Kinds');
      await tester.enterText(_field('Source language *'), 'English');
      await tester.enterText(_field('Target language *'), 'en');
      await tester.pump();
      await tester.tap(find.byKey(const Key('course-wizard-continue')));
      await tester.pump();
      expect(
        find.text(CourseKindChoice.sameLanguageTwice('English')),
        findsOneWidget,
      );
    });

    testWidgets('Through another language takes two variants of one language', (
      tester,
    ) async {
      _tall(tester);
      final profiles = ProfileService();
      await profiles.createProfile('Kind Author', learnerProfileId: _profileId);
      await profiles.setActiveProfileById(_profileId);
      await tester.pumpWidget(const MaterialApp(home: CourseWizardScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-kind-other')));
      await tester.pump();
      await tester.enterText(_field('Course title *'), 'Lift and elevator');
      await tester.enterText(_field('Source language *'), 'English (UK)');
      await tester.enterText(_field('Target language *'), 'English (US)');
      await tester.pump();
      await tester.tap(find.byKey(const Key('course-wizard-continue')));
      await tester.pumpAndSettle();
      expect(
        find.text(CourseKindChoice.sameLanguageTwice('English (US)')),
        findsNothing,
      );
      expect(find.text('Step 2 of 8: Flag or cover image'), findsOneWidget);
    });

    testWidgets('Fill with an example follows the kind', (tester) async {
      _tall(tester);
      await tester.pumpWidget(const MaterialApp(home: CourseWizardScreen()));
      await tester.pumpAndSettle();
      // With none chosen: Through another language's example.
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      expect(_text(tester, 'course-wizard-source-language'), 'English');
      expect(_text(tester, 'course-wizard-target-language'), 'Italian');
      expect(
        tester.widget<CourseKindChoice>(find.byType(CourseKindChoice)).kind,
        CourseKind.otherLanguage,
      );
      // In the same language: its own example (the owner's default e).
      await tester.tap(find.byKey(const Key('course-wizard-kind-same')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      // The step holds something: the example asks first.
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('course-wizard-fill-example-confirm')),
          matching: find.text('Fill'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_text(tester, 'course-wizard-language'), 'English');
      expect(
        tester
            .widget<TextField>(
              find.byWidgetPredicate(
                (w) =>
                    w is TextField &&
                    w.decoration?.labelText == 'Course title *',
              ),
            )
            .controller!
            .text,
        CourseWizardSample.sameLanguageBasics.title,
      );
      expect(
        tester.widget<CourseKindChoice>(find.byType(CourseKindChoice)).kind,
        CourseKind.sameLanguage,
      );
    });

    test('the later steps\' examples follow the kind', () {
      expect(
        CourseWizardSample.aboutFor(CourseKind.sameLanguage).description,
        contains('explained in English'),
      );
      expect(
        CourseWizardSample.aboutFor(CourseKind.otherLanguage),
        same(CourseWizardSample.about),
      );
      expect(
        CourseWizardSample.lessonsFor(
          CourseKind.sameLanguage,
        ).first.sectionName,
        'At the café',
      );
      expect(
        CourseWizardSample.lessonsFor(CourseKind.otherLanguage),
        same(CourseWizardSample.lessons),
      );
    });

    testWidgets('once the Course exists, Basics shows its kind', (
      tester,
    ) async {
      _tall(tester);
      final course = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
        sameLanguage: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseWizardScreen(
            course: course,
            access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
            pause: CourseWizardPause(
              step: CourseWizardStep.basics,
              savedAtUtc: DateTime.utc(2026, 10, 16),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('course-wizard-kind-shown')))
            .data,
        'In the same language: English',
      );
      expect(find.byType(CourseKindChoice), findsNothing);
    });

    testWidgets('Which should I choose? opens the answer', (tester) async {
      _tall(tester);
      await tester.pumpWidget(const MaterialApp(home: CourseWizardScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-wizard-kind-help')));
      await tester.pumpAndSettle();
      expect(find.byType(EditorHelpScreen), findsOneWidget);
      expect(
        tester.widget<EditorHelpScreen>(find.byType(EditorHelpScreen)).question,
        'courseKind',
      );
      expect(
        find
            .byKey(const ValueKey('editor-help-answer-courseKind'))
            .hitTestable(),
        findsOneWidget,
      );
    });
  });

  group("New Course's form", () {
    testWidgets('prefilled In the same language: one field, both languages '
        'written', (tester) async {
      _tall(tester);
      Course? created;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  created = await showNewCourseDialog(
                    context,
                    creator: _profile,
                    maintainers: const [_profile],
                    operations: _operations,
                    titleTaken: (_) => false,
                    prefill: CourseWizardSample.sameLanguageBasics,
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
      expect(
        tester.widget<CourseKindChoice>(find.byType(CourseKindChoice)).kind,
        CourseKind.sameLanguage,
      );
      expect(find.byKey(const Key('new-course-kind-help')), findsOneWidget);
      expect(_text(tester, 'new-course-language'), 'English');
      expect(find.byKey(const Key('new-course-source-language')), findsNothing);
      final create = find.widgetWithText(FilledButton, 'Continue to Editor');
      await tester.ensureVisible(create);
      await tester.pump();
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(created, isNotNull);
      expect(created!.sourceLanguage, 'English');
      expect(created!.targetLanguage, 'English');
      expect(created!.sourceLanguageTag, 'en');
      expect(created!.targetLanguageTag, 'en');
      expect(CourseLanguagePair.isSameLanguage(created!), isTrue);
    });

    test('the form refuses one language twice, and writes one language '
        'on both sides in the same language', () {
      final form = NewCourseForm(creator: _profile)
        ..kind = CourseKind.otherLanguage
        ..title.text = 'Kinds';
      addTearDown(form.dispose);
      form.source.text.text = 'English';
      form.target.text.text = 'english';
      expect(form.kindProblem, CourseKindChoice.sameLanguageTwice('English'));
      expect(
        (form.submit('Kinds', _operations) as NewCourseRefused).message,
        CourseKindChoice.sameLanguageTwice('English'),
      );
      // In the same language the hidden Source field is not read.
      form
        ..kind = CourseKind.sameLanguage
        ..source.text.text = 'Italian';
      expect(form.kindProblem, isNull);
      expect(form.languagesChosen, isTrue);
      final course =
          (form.submit('Kinds', _operations) as NewCourseAccepted).course;
      expect(course.sourceLanguage, 'English');
      expect(course.targetLanguage, 'English');
      expect(course.sameLanguage, isTrue);
      // Through another language stores no kind.
      form
        ..kind = CourseKind.otherLanguage
        ..source.text.text = 'English (UK)'
        ..target.text.text = 'English (US)';
      expect(form.kindProblem, isNull);
      final variants =
          (form.submit('Kinds', _operations) as NewCourseAccepted).course;
      expect(variants.sameLanguage, isFalse);
    });

    testWidgets('a kind switched before Continue to Editor writes what the '
        'field shows', (tester) async {
      _tall(tester);
      Course? created;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  created = await showNewCourseDialog(
                    context,
                    creator: _profile,
                    maintainers: const [_profile],
                    operations: _operations,
                    titleTaken: (_) => false,
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
      await tester.tap(find.byKey(const Key('new-course-kind-other')));
      await tester.pump();
      await tester.enterText(_field('Course title *'), 'Kinds');
      await tester.enterText(_field('Source language *'), 'English');
      await tester.enterText(_field('Target language *'), 'Italian');
      await tester.pump();
      await tester.tap(find.byKey(const Key('new-course-kind-same')));
      await tester.pump();
      // The one Language field is the target's.
      expect(_text(tester, 'new-course-language'), 'Italian');
      final create = find.widgetWithText(FilledButton, 'Continue to Editor');
      await tester.ensureVisible(create);
      await tester.pump();
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(created!.sourceLanguage, 'Italian');
      expect(created!.targetLanguage, 'Italian');
      expect(CourseLanguagePair.isSameLanguage(created!), isTrue);
    });

    testWidgets('without a kind, Continue to Editor says so', (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showNewCourseDialog(
                  context,
                  creator: _profile,
                  maintainers: const [_profile],
                  operations: _operations,
                  titleTaken: (_) => false,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(_field('Source language *'), findsNothing);
      await tester.enterText(_field('Course title *'), 'Kinds');
      final create = find.widgetWithText(FilledButton, 'Continue to Editor');
      await tester.ensureVisible(create);
      await tester.pump();
      await tester.tap(create);
      await tester.pump();
      expect(find.text(CourseKindChoice.missing), findsOneWidget);
    });
  });

  group('Course Info', () {
    testWidgets('a same-language Course says so; another does not', (
      tester,
    ) async {
      for (final (course, shown) in [
        (
          _course(
            source: 'English',
            target: 'English',
            sourceTag: 'en',
            targetTag: 'en',
            sameLanguage: true,
          ),
          true,
        ),
        // The same languages without the choice: a translation Course.
        (
          _course(
            source: 'English',
            target: 'English',
            sourceTag: 'en',
            targetTag: 'en',
          ),
          false,
        ),
        (
          _course(
            source: 'English',
            target: 'Italian',
            sourceTag: 'en',
            targetTag: 'it',
          ),
          false,
        ),
      ]) {
        await tester.pumpWidget(
          MaterialApp(home: CourseInfoScreen(course: course)),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            const Key('course-info-same-language'),
            skipOffstage: false,
          ),
          shown ? findsOneWidget : findsNothing,
          reason: course.targetLanguage,
        );
      }
    });
  });

  group('the Help', () {
    test('the question, its place and its three languages', () {
      final topic = editorHelpQuestionsByTopic['courseSettings']!;
      expect(topic.indexOf('courseKind'), topic.indexOf('courseLanguages') + 1);
      for (final locale in [
        AppLocale.english,
        AppLocale.italian,
        AppLocale.spanish,
      ]) {
        for (final key in [
          'editorHelp.qa.courseKind.q',
          'editorHelp.qa.courseKind.a',
          'courseInfo.sameLanguage',
        ]) {
          final text = helpText.lookup(locale, key);
          expect(text, isNot(key), reason: '$locale $key');
          expect(text.trim(), isNotEmpty, reason: '$locale $key');
        }
        // The two answers that point to it.
        final question = helpText.lookup(locale, 'editorHelp.qa.courseKind.q');
        for (final key in [
          'editorHelp.qa.courseLanguages.a',
          'editorHelp.qa.courseWizard.a',
        ]) {
          expect(
            helpText.lookup(locale, key),
            contains(question),
            reason: '$locale $key',
          );
        }
      }
      // The Italian and Spanish answers are their own, not English.
      final english = helpText.lookup(
        AppLocale.english,
        'editorHelp.qa.courseKind.a',
      );
      for (final locale in [AppLocale.italian, AppLocale.spanish]) {
        expect(
          helpText.lookup(locale, 'editorHelp.qa.courseKind.a'),
          isNot(english),
        );
      }
    });
  });
}
