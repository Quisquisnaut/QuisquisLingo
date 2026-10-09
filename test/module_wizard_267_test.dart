import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_wizard_screen.dart';
import 'package:quisquislingo_app/screens/guidebook_editor_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/guidebook_module_sample.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guidebook_fixtures.dart';

/// Build 267 Revision 10 (owner decisions of 9 October 2026): the Module
/// Wizard, a new module step by step (A Title, B Sentences, C Words &
/// Expressions, D Overview), in the Course Wizard's GuideBook step and as
/// Module Wizard on the Course Editor's GuideBook page; Next stops below
/// the size advice until the author continues anyway; Finish offers
/// another module.
void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [_profile.encode()],
      ProfileService.activeProfileIdKey: _profileId,
    }),
  );

  group('the Module Wizard', () {
    testWidgets('A to D: the title is needed, the sizes can be skipped', (
      tester,
    ) async {
      final result = await _openGuided(tester);
      expect(_step(tester), 'Step A of 4: Title');
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('guidebook-module-wizard-back')),
            )
            .onPressed,
        isNull,
      );
      // No Done: the module is kept only on Finish.
      expect(find.byKey(const Key('guidebook-module-done')), findsNothing);
      // A title is needed.
      await _next(tester);
      expect(_step(tester), 'Step A of 4: Title');
      expect(find.text('Give the module a title.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('guidebook-module-title')),
        'Al bar',
      );
      await _next(tester);
      expect(_step(tester), 'Step B of 4: Sentences');
      expect(find.byKey(const Key('guidebook-module-words')), findsNothing);
      // Below two Sentences Next asks; Add more stays.
      await _next(tester);
      expect(find.text('Fewer than 2 sentences'), findsOneWidget);
      await tester.tap(find.text('Add more'));
      await tester.pumpAndSettle();
      expect(_step(tester), 'Step B of 4: Sentences');
      await _addRow(
        tester,
        'sentence',
        0,
        'Il conto, per favore.',
        'The bill.',
      );
      await _next(tester);
      await tester.tap(
        find.byKey(const Key('guidebook-module-wizard-continue-anyway')),
      );
      await tester.pumpAndSettle();
      expect(_step(tester), 'Step C of 4: Words & Expressions');
      // A half row is a problem to fix, not a size to skip.
      await tester.tap(find.byKey(const ValueKey('guidebook-module-add-word')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('guidebook-module-word-0-target')),
        'il caffè',
      );
      await _next(tester);
      expect(
        find.byKey(const Key('guidebook-module-wizard-continue-anyway')),
        findsNothing,
      );
      expect(_step(tester), 'Step C of 4: Words & Expressions');
      await tester.enterText(
        find.byKey(const ValueKey('guidebook-module-word-0-source')),
        'espresso',
      );
      for (final (i, (target, source)) in const [
        ('il conto', 'the bill'),
        ('per favore', 'please'),
        ('buongiorno', 'good morning'),
        ('grazie', 'thank you'),
      ].indexed) {
        await _addRow(tester, 'word', i + 1, target, source);
      }
      // Five Words & Expressions: no question.
      await _next(tester);
      expect(_step(tester), 'Step D of 4: Overview');
      await tester.enterText(
        find.byKey(const Key('guidebook-module-overview')),
        'Coffee at the counter.',
      );
      // Back keeps what was written.
      await tester.tap(find.byKey(const Key('guidebook-module-wizard-back')));
      await tester.pumpAndSettle();
      expect(find.text('grazie'), findsOneWidget);
      await _next(tester);
      expect(find.widgetWithText(FilledButton, 'Finish'), findsOneWidget);
      // Fewer than ten words: a warning; Add more stays on the Overview.
      await _next(tester);
      expect(find.text('A short Overview'), findsOneWidget);
      expect(find.textContaining('The Overview has 4 words'), findsOneWidget);
      await tester.tap(find.text('Add more'));
      await tester.pumpAndSettle();
      expect(_step(tester), 'Step D of 4: Overview');
      expect(result(), isNull);
      await _next(tester);
      await tester.tap(
        find.byKey(const Key('guidebook-module-wizard-overview-anyway')),
      );
      await tester.pumpAndSettle();
      final module = result()!;
      expect(module.title, 'Al bar');
      expect(module.sentences, hasLength(1));
      expect(module.words.map((entry) => entry.target), [
        'il caffè',
        'il conto',
        'per favore',
        'buongiorno',
        'grazie',
      ]);
      expect(module.overview, 'Coffee at the counter.');
    });

    testWidgets('an empty Overview warns; ten words finish at once', (
      tester,
    ) async {
      final result = await _openGuided(tester);
      for (var step = 0; step < 3; step++) {
        await _fillAndNext(tester);
      }
      expect(_step(tester), 'Step D of 4: Overview');
      await tester.enterText(
        find.byKey(const Key('guidebook-module-overview')),
        '',
      );
      await _next(tester);
      expect(find.text('The Overview is empty'), findsOneWidget);
      await tester.tap(find.text('Add more'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('guidebook-module-overview')),
        'Italians drink coffee standing at the counter, then pay the bill.',
      );
      await _next(tester);
      expect(
        find.byKey(const Key('guidebook-module-wizard-overview-anyway')),
        findsNothing,
      );
      expect(result()!.overview, startsWith('Italians drink coffee'));
    });

    testWidgets('the rows name the Course\'s languages', (tester) async {
      _tall(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: GuidebookModuleEditorScreen(
            module: GuidebookModule(
              id: 'm',
              title: 'Al bar',
              sentences: [testEntry('s', 'Il conto, per favore. = The bill.')],
              words: [testEntry('w', 'il caffè = espresso')],
            ),
            course: _wizardCourse(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // One sentence and one word: each row shows both sides.
      expect(find.text('Target: Italian'), findsNWidgets(2));
      expect(find.text('Source: English'), findsNWidgets(2));
      // Without a Course the sides keep their bare names.
      await tester.pumpWidget(
        MaterialApp(
          home: GuidebookModuleEditorScreen(
            key: const ValueKey('no-course'),
            module: GuidebookModule(
              id: 'm',
              title: 'Al bar',
              words: [testEntry('w', 'il caffè = espresso')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Target'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);
    });

    testWidgets('leaving asks once something is written, and keeps nothing', (
      tester,
    ) async {
      var result = await _openGuided(tester);
      // A blank module leaves at once.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookModuleEditorScreen), findsNothing);
      expect(result(), isNull);

      result = await _openGuided(tester);
      await tester.enterText(
        find.byKey(const Key('guidebook-module-title')),
        'Al bar',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard this module?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookModuleEditorScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('guidebook-module-wizard-discard')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GuidebookModuleEditorScreen), findsNothing);
      expect(result(), isNull);
    });

    testWidgets('Fill and Clear all work on the step shown only', (
      tester,
    ) async {
      final result = await _openGuided(tester);
      await _fill(tester);
      await _next(tester);
      // Fill on A wrote the title only: Sentences are still empty.
      expect(_step(tester), 'Step B of 4: Sentences');
      expect(find.text('Il conto, per favore.'), findsNothing);
      await _fill(tester);
      expect(find.text('Il conto, per favore.'), findsOneWidget);
      // A filled step asks before Fill replaces it.
      await tester.tap(find.byKey(const Key('guidebook-module-fill-example')));
      await tester.pumpAndSettle();
      expect(find.text('Fill with an example?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await _next(tester);
      expect(_step(tester), 'Step C of 4: Words & Expressions');
      expect(find.text('espresso'), findsNothing);
      await _fill(tester);
      expect(find.text('espresso'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guidebook-module-clear-all')));
      await tester.pumpAndSettle();
      expect(find.text('Clear the Words & Expressions?'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('guidebook-module-clear-all-confirm')),
      );
      await tester.pumpAndSettle();
      expect(find.text('espresso'), findsNothing);
      // The other steps keep the example.
      await tester.tap(find.byKey(const Key('guidebook-module-wizard-back')));
      await tester.pumpAndSettle();
      expect(find.text('Il conto, per favore.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guidebook-module-wizard-back')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('guidebook-module-title')))
            .controller!
            .text,
        'Al bar',
      );
      expect(result(), isNull);
    });
  });

  testWidgets('the Course Editor\'s Module Wizard, then another module', (
    tester,
  ) async {
    _tall(tester);
    Guidebook? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<Guidebook>(
                MaterialPageRoute(
                  builder: (_) => GuidebookEditorScreen(
                    guidebook: testGuidebook(
                      moduleId: 'm0',
                      title: 'Saluti',
                      wordLines: const ['ciao = hi'],
                    ),
                    ids: _Ids(),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Module Wizard stands beside Add module.
    final add = tester.getTopLeft(
      find.byKey(const Key('guidebook-add-module')),
    );
    final wizard = tester.getTopLeft(
      find.byKey(const Key('guidebook-module-wizard')),
    );
    expect(wizard.dx, greaterThan(add.dx));
    await tester.tap(find.byKey(const Key('guidebook-module-wizard')));
    await tester.pumpAndSettle();
    expect(_step(tester), 'Step A of 4: Title');
    for (var step = 0; step < 4; step++) {
      await _fillAndNext(tester);
    }
    expect(find.text('Add another module?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('guidebook-another-module')));
    await tester.pumpAndSettle();
    // Another Module Wizard opens; leaving it blank adds nothing.
    expect(_step(tester), 'Step A of 4: Title');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guidebook-module-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('guidebook-module-2')), findsNothing);
    // Add module still opens the whole page.
    await tester.tap(find.byKey(const Key('guidebook-add-module')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guidebook-module-wizard-step')), findsNothing);
    expect(find.byKey(const Key('guidebook-module-done')), findsOneWidget);
    expect(saved, isNull);
  });

  testWidgets('the Course Wizard\'s GuideBook step uses the Module Wizard', (
    tester,
  ) async {
    _tall(tester);
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
            savedAtUtc: DateTime.utc(2026, 10, 9),
            lessonId: course.lessons.first.lessonId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('GuideBooks'), findsOneWidget);
    expect(
      find.textContaining(
        'Each module gives example sentences, words and fixed expressions, '
        'and an Overview of short explanations',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('A module is one short topic'), findsNothing);
    await tester.tap(find.byKey(const Key('course-wizard-add-module')));
    await tester.pumpAndSettle();
    expect(_step(tester), 'Step A of 4: Title');
    for (var step = 0; step < 4; step++) {
      await _fillAndNext(tester);
    }
    await tester.tap(find.byKey(const Key('guidebook-another-module-no')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('course-wizard-module-0')),
      findsOneWidget,
    );
    expect(
      find.text('1. ${course.lessons.first.title} · 1 module'),
      findsOneWidget,
    );
  });

  testWidgets('the GuideBook chips have the Course Editor\'s Audit outline', (
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
          words: [testEntry('w1', 'il caffè = espresso')],
        ),
      ],
      state: PublicationState.draft,
      now: _now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CourseWizardScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
          pause: CourseWizardPause(
            step: CourseWizardStep.guidebook,
            savedAtUtc: DateTime.utc(2026, 10, 9),
            lessonId: course.lessons.first.lessonId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    BorderSide? side(int index) => tester
        .widget<ChoiceChip>(
          find.byKey(ValueKey('course-wizard-guidebook-lesson-$index')),
        )
        .side;
    // A GuideBook with entries and nothing the Audit warns about: green.
    expect(side(0)?.color, const Color(0xFF00A83B));
    // An empty GuideBook is a Warning (LESSON_GUIDEBOOK_EMPTY): red.
    expect(side(1)?.color, const Color(0xFFC90000));
  });

  testWidgets('a GuideBook of fewer than three modules asks before ready', (
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
          words: [
            testEntry('w1', 'il caffè = espresso'),
            testEntry('w2', 'il conto = the bill'),
            testEntry('w3', 'per favore = please'),
          ],
        ),
        GuidebookModule(
          id: 'm2',
          title: 'Saluti',
          words: [testEntry('w4', 'ciao = hi')],
        ),
      ],
      state: PublicationState.draft,
      now: _now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CourseWizardScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
          pause: CourseWizardPause(
            step: CourseWizardStep.guidebook,
            savedAtUtc: DateTime.utc(2026, 10, 9),
            lessonId: course.lessons.first.lessonId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ready = find.byKey(const Key('course-wizard-guidebook-ready'));
    await tester.ensureVisible(ready);
    await tester.tap(ready);
    await tester.pumpAndSettle();
    expect(find.text('Fewer than 3 modules'), findsOneWidget);
    expect(
      find.textContaining('Lesson 1\'s GuideBook has 2 modules'),
      findsOneWidget,
    );
    expect(find.text('Ready anyway'), findsOneWidget);
    // Add modules: nothing is saved, the GuideBook stays a Draft.
    await tester.tap(find.text('Add modules'));
    await tester.pumpAndSettle();
    expect(find.text('Fewer than 3 modules'), findsNothing);
    expect(find.textContaining('Not approved yet'), findsOneWidget);
  });

  test(
    'the example orders an espresso; the words drop the two-meanings line',
    () {
      final module = GuidebookModuleSample.module(
        id: 'sample',
        ids: TimestampAuthoringIdGenerator(),
      );
      final caffe = module.words.firstWhere((e) => e.target == 'il caffè');
      expect(caffe.source, 'espresso');
      expect(caffe.picture?.asset, 'assets/exercise_images/espresso.webp');
      expect(
        module.sentences.map((e) => e.source),
        contains('I would like an espresso, please.'),
      );
      expect(CourseWizardSample.about.description, contains('an espresso'));
    },
  );

  testWidgets('the Words & Expressions text has no two-meanings line', (
    tester,
  ) async {
    _tall(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: GuidebookModuleEditorScreen(
          module: GuidebookModule(id: 'm', title: 'Al bar'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('A word with two meanings'), findsNothing);
    expect(find.textContaining('il conto = the account'), findsOneWidget);
  });
}

const _profileId = '12345678-1234-4234-9234-1234567890cd';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Module Author',
);
final _now = DateTime.utc(2026, 10, 9, 12);

class _Ids implements AuthoringIdGenerator {
  var _next = 0;
  @override
  String next(String kind) => '${kind}_${_next++}';
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Course _wizardCourse() =>
    CourseLibraryOperations(clock: () => _now).newWizardCourse(
      creator: _profile,
      title: 'Italian at the bar',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      sourceLanguageTag: 'en',
      targetLanguageTag: 'it',
    );

/// A Module Wizard on a new module; the result is what it returned.
Future<GuidebookModule? Function()> _openGuided(WidgetTester tester) async {
  _tall(tester);
  GuidebookModule? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await Navigator.of(context).push<GuidebookModule>(
              MaterialPageRoute(
                builder: (_) => GuidebookModuleEditorScreen(
                  module: GuidebookModule(id: 'new', title: ''),
                  ids: _Ids(),
                  lessonName: 'Lesson 1: At the bar',
                  guided: true,
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return () => result;
}

String? _step(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('guidebook-module-wizard-step')))
    .data;

/// Fill with an example on the step shown (Build 267 Revision 10: that step
/// only).
Future<void> _fill(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('guidebook-module-fill-example')));
  await tester.pumpAndSettle();
}

Future<void> _fillAndNext(WidgetTester tester) async {
  await _fill(tester);
  await _next(tester);
}

Future<void> _next(WidgetTester tester) async {
  final next = find.byKey(const Key('guidebook-module-wizard-next'));
  await tester.ensureVisible(next);
  await tester.tap(next);
  await tester.pumpAndSettle();
}

Future<void> _addRow(
  WidgetTester tester,
  String kind,
  int index,
  String target,
  String source,
) async {
  final add = find.byKey(ValueKey('guidebook-module-add-$kind'));
  await tester.ensureVisible(add);
  await tester.tap(add);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(ValueKey('guidebook-module-$kind-$index-target')),
    target,
  );
  await tester.enterText(
    find.byKey(ValueKey('guidebook-module-$kind-$index-source')),
    source,
  );
  await tester.pump();
}
