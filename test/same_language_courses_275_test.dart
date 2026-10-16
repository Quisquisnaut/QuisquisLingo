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
import 'package:quisquislingo_app/services/course_info_update_service.dart';
import 'package:quisquislingo_app/services/course_language_pair.dart';
import 'package:quisquislingo_app/services/course_language_resolver.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/course_kind_choice.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Build 275 Revision 0 (owner decisions of 16 October 2026): a Course can
// teach a language in that same language. The kind is derived from the two
// languages (CourseLanguagePair), chosen first in the Course Wizard and in
// New Course's form, and never stored.

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
}) => _operations.newWizardCourse(
  creator: _profile,
  title: 'Kinds',
  sourceLanguage: source,
  targetLanguage: target,
  sourceLanguageTag: sourceTag,
  targetLanguageTag: targetTag,
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
    test('two tags: the language, then the region and the script', () {
      for (final (a, b, same) in [
        ('es', 'es', true),
        ('en', 'en-US', true),
        ('en-GB', 'en-US', false),
        ('sr-Latn', 'sr-Cyrl', false),
        ('sr-Latn', 'sr-RS', true),
        ('zh-Hant', 'zh-Hans', false),
        ('en', 'it', false),
        ('EN_us', 'en-US', true),
      ]) {
        expect(CourseLanguagePair.sameTags(a, b), same, reason: '$a / $b');
        expect(CourseLanguagePair.sameTags(b, a), same, reason: '$b / $a');
      }
    });

    test('a language typed by hand is compared by its name', () {
      bool same(String a, String b) => CourseLanguagePair.sameLanguages(
        ResolvedCourseLanguage(name: a, code: null),
        ResolvedCourseLanguage(name: b, code: null),
      );
      expect(same('Viterbese', 'viterbèse'), isTrue);
      expect(same('Viterbese', 'Romanesco'), isFalse);
      expect(same('', ''), isFalse);
      // A name of a listed language takes its tag: an earlier Course may
      // name one language in two ways.
      expect(same('Français', 'French'), isTrue);
      expect(same('Deutsch', 'French'), isFalse);
      // Two variants typed by hand with their tags are two languages.
      expect(
        CourseLanguagePair.sameChoices(
          learningName: 'English (US)',
          learningTag: 'en-US',
          baseName: 'English (UK)',
          baseTag: 'en-GB',
        ),
        isFalse,
      );
    });

    test("a Course's kind, from its stored languages", () {
      final english = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en',
        targetTag: 'en',
      );
      expect(CourseLanguagePair.isSameLanguage(english), isTrue);
      expect(CourseLanguagePair.kindOf(english), CourseKind.sameLanguage);
      // A region on one side only is the same language.
      final american = _course(
        source: 'English',
        target: 'English',
        targetTag: 'en-US',
      );
      expect(CourseLanguagePair.isSameLanguage(american), isTrue);
      // Two variants translate between them (owner decision 3).
      final variants = _course(
        source: 'English',
        target: 'English',
        sourceTag: 'en-GB',
        targetTag: 'en-US',
      );
      expect(CourseLanguagePair.isSameLanguage(variants), isFalse);
      final italian = _course(
        source: 'English',
        target: 'Italian',
        sourceTag: 'en',
        targetTag: 'it',
      );
      expect(CourseLanguagePair.kindOf(italian), CourseKind.otherLanguage);
      // Two languages typed by hand, by name.
      final byHand = _course(source: 'Viterbese', target: 'Viterbese');
      expect(CourseLanguagePair.isSameLanguage(byHand), isTrue);
    });

    test('Course Info never gives a tag that changes the kind', () {
      // A language typed by hand, without a tag, beside Italian: a
      // translation Course. Calling it Italian would make it same-language.
      final byHand = _course(
        source: 'Viterbese',
        target: 'Italian',
        targetTag: 'it',
      );
      expect(CourseLanguagePair.isSameLanguage(byHand), isFalse);
      expect(
        CourseInfoUpdateService.keepsKind(
          byHand,
          sourceTag: 'it',
          targetTag: 'it',
        ),
        isFalse,
      );
      // A tag of its own keeps it a translation Course.
      expect(
        CourseInfoUpdateService.keepsKind(
          byHand,
          sourceTag: 'vit',
          targetTag: 'it',
        ),
        isTrue,
      );
    });

    test('two languages as a form holds them', () {
      expect(
        CourseLanguagePair.sameChoices(
          learningName: 'English',
          learningTag: 'en',
          baseName: 'English',
          baseTag: 'en',
        ),
        isTrue,
      );
      expect(
        CourseLanguagePair.sameChoices(
          learningName: 'Italian',
          learningTag: 'it',
          baseName: 'English',
          baseTag: 'en',
        ),
        isFalse,
      );
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
          ),
          true,
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
