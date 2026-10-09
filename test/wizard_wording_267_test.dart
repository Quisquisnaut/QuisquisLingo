import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/course_wizard_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/guidebook_module_sample.dart';
import 'package:quisquislingo_app/services/guidebook_paste_list.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/language_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guidebook_fixtures.dart';
import 'support/pump_file_io.dart';

/// Build 267 Revision 9 (owner decisions of 9 October 2026): the Course
/// Wizard's texts, Course languages that start empty and ignore capitals,
/// Lesson icons always in view, module counts and the Lesson on the module
/// page, the example module's fixed expressions, and Editor notes read-only
/// in Inspection.
void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [_profile.encode()],
      ProfileService.activeProfileIdKey: _profileId,
    }),
  );

  group('Course languages', () {
    test('capitals never matter; a language by hand starts with one', () {
      final field = LanguageFieldController(name: 'en');
      expect(field.normalize(), isTrue);
      expect(field.text.text, 'English');
      field.text.text = 'ITALIAN';
      expect(field.normalize(), isTrue);
      expect(field.text.text, 'Italian');
      expect(field.normalize(), isFalse);
      field.text.text = 'viterbese';
      // The stored name has its capital even before the field is left.
      expect(field.choice!.name, 'Viterbese');
      expect(field.normalize(), isTrue);
      expect(field.text.text, 'Viterbese');
      field.text.text = '';
      expect(field.normalize(), isFalse);
      field.dispose();
    });

    testWidgets('leaving the field shows the language as it is stored', (
      tester,
    ) async {
      final field = LanguageFieldController();
      addTearDown(field.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LanguageField(
                  controller: field,
                  label: 'Source language *',
                  keyPrefix: 'source',
                ),
                const TextField(key: Key('elsewhere')),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('source')), 'en');
      await tester.pump();
      expect(field.text.text, 'en');
      await tester.tap(find.byKey(const Key('elsewhere')));
      await tester.pump();
      expect(field.text.text, 'English');
    });
  });

  group('the Course Wizard', () {
    testWidgets('the first screen: Source empty, the new line and buttons', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(const MaterialApp(home: CourseWizardScreen()));
      await tester.pumpAndSettle();
      expect(_text(tester, 'course-wizard-source-language'), isEmpty);
      expect(
        find.text(
          'Set a title for your Course and insert the learner\'s language '
          '(Source) and the language to be studied (Target). Use the full '
          'language name (e.g. English) or its code (en). Capitals don\'t '
          'matter.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Continue with Wizard'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Continue by hand'),
        findsOneWidget,
      );
      expect(find.text('Create it myself'), findsNothing);
      // Only the example writes English.
      await tester.tap(find.byKey(const Key('course-wizard-fill-example')));
      await tester.pumpAndSettle();
      expect(_text(tester, 'course-wizard-source-language'), 'English');
    });

    testWidgets('Course options and Lessons: the short lines; icons in view', (
      tester,
    ) async {
      _tall(tester);
      final course = CourseWizardLessons.applyTo(
        _wizardCourse(),
        CourseWizardSample.lessons,
        now: _now,
      );
      await _pumpAt(tester, course, CourseWizardStep.lessons);
      expect(
        find.text(
          'Give each Lesson a title and an icon. Add or remove lessons. Open '
          'Advanced if you want to group the lessons in sections.',
        ),
        findsOneWidget,
      );
      // The icon shows without Advanced; the section waits under it.
      expect(
        find.byKey(const ValueKey('course-wizard-lesson-icon-0')),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Section'), findsNothing);
      await tester.tap(find.byKey(const Key('course-wizard-back')));
      await tester.pumpAndSettle();
      expect(
        find.text('Open Advanced if you want to change some Course Options.'),
        findsOneWidget,
      );
    });

    testWidgets('the GuideBook step counts modules and opens an empty one', (
      tester,
    ) async {
      _tall(tester);
      var course = CourseWizardLessons.applyTo(
        _wizardCourse(),
        CourseWizardSample.lessons,
        now: _now,
      );
      course = CourseWizardGuidebook.withModules(
        course,
        course.lessons.first.lessonId,
        [
          GuidebookModule(
            id: 'm1',
            title: 'Al bar',
            words: [testEntry('w1', 'il caffè = coffee')],
          ),
          GuidebookModule(
            id: 'm2',
            title: 'Il conto',
            words: [testEntry('w2', 'il conto = the bill')],
          ),
        ],
        state: PublicationState.draft,
        now: _now,
      );
      await _pumpAt(tester, course, CourseWizardStep.guidebook);
      expect(
        find.textContaining(
          'turns into Rounds of exercises you can use in your Course.',
        ),
        findsOneWidget,
      );
      final first = course.lessons.first;
      final second = course.lessons[1];
      expect(find.text('1. ${first.title} · 2 modules'), findsOneWidget);
      expect(find.text('2. ${second.title}'), findsOneWidget);
      // A Lesson with no modules opens a new one at once.
      await tester.tap(
        find.byKey(const ValueKey('course-wizard-guidebook-lesson-1')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookModuleEditorScreen), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('guidebook-module-lesson')))
            .data,
        'Lesson 2: ${second.title}',
      );
    });
  });

  testWidgets('New Course\'s form starts with Source empty', (tester) async {
    _tall(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: CourseProjectsScreen(
          currentCourse: Course(
            courseId: 'wording-host',
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
    await tester.tap(find.byKey(const Key('create-course-icon-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-wizard-manual')));
    await tester.pumpAndSettle();
    expect(find.text('Create new course'), findsOneWidget);
    expect(_text(tester, 'new-course-source-language'), isEmpty);
  });

  testWidgets('the Course Editor\'s GuideBook names the Lesson on a module', (
    tester,
  ) async {
    _tall(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: GuidebookEditorScreen(
          guidebook: testGuidebook(
            moduleId: 'm',
            title: 'Al bar',
            wordLines: const ['il caffè = coffee'],
          ),
          lessonName: GuidebookModuleEditorScreen.lessonNameFor(3, 'Al bar'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guidebook-module-0')));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 3: Al bar'), findsOneWidget);
    expect(GuidebookModuleEditorScreen.lessonNameFor(4, '  '), 'Lesson 4');
  });

  test('the example module: fixed expressions, no sentence among words', () {
    final module = GuidebookModuleSample.module(
      id: 'sample',
      ids: TimestampAuthoringIdGenerator(),
    );
    final words = module.words.map((entry) => entry.target).toList();
    expect(words, containsAll(['buongiorno', 'come stai?']));
    expect(words, isNot(contains('{io} sono stanco')));
    expect(
      GuidebookPasteList.exampleLines,
      isNot(contains('{io} sono stanco = I am tired')),
    );
  });

  testWidgets('Editor notes are read-only in Inspection', (tester) async {
    _tall(tester);
    final exercise = Exercise.canonical(
      id: 'inspect-notes',
      updatedAt: _now,
      primitive: ExercisePrimitive.select,
      promptElements: [
        PromptElement(type: 'text', text: 'Pick ‘ciao’.', role: 'question'),
      ],
      items: [
        ExerciseItem(
          id: 'a',
          content: [PromptElement(type: 'text', text: 'hello')],
        ),
        ExerciseItem(
          id: 'b',
          content: [PromptElement(type: 'text', text: 'goodbye')],
        ),
      ],
      canonicalEvaluation: const CanonicalEvaluation(
        mode: EvaluationMode.exactItem,
        correctItemIds: ['a'],
      ),
      authoringMetadata: const {'presetId': 'choice_target'},
      editorNotes: 'A note',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: exercise,
          title: 'Notes',
          isNew: false,
          onExerciseSaved: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    EditableText notes() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('exercise-editor-notes')),
        matching: find.byType(EditableText),
      ),
    );
    expect(notes().readOnly, isFalse);
    final toggle = find.byKey(const Key('exercise-inspection-toggle'));
    await tester.ensureVisible(toggle);
    await tester.pump();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(notes().readOnly, isTrue);
    expect(notes().controller.text, 'A note');
  });
}

const _profileId = '12345678-1234-4234-9234-1234567890ab';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Wording Author',
);
final _now = DateTime.utc(2026, 10, 9, 12);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).controller!.text;

Course _wizardCourse() =>
    CourseLibraryOperations(clock: () => _now).newWizardCourse(
      creator: _profile,
      title: 'Italian at the bar',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      sourceLanguageTag: 'en',
      targetLanguageTag: 'it',
    );

Future<void> _pumpAt(
  WidgetTester tester,
  Course course,
  CourseWizardStep step,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CourseWizardScreen(
        course: course,
        access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
        pause: CourseWizardPause(
          step: step,
          savedAtUtc: DateTime.utc(2026, 10, 9),
          lessonId: course.lessons.first.lessonId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
