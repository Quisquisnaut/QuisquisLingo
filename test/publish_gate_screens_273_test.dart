import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guidebook_fixtures.dart';

/// Build 273 Revision 1: the publish gate as the editor's pages show it.
/// Written on the screens before `PublishGate` existed; they must pass
/// before and after (no behaviour change). One group per copy of the gate:
/// the Course's Publish, the Lessons page's menu, the Lesson editor's
/// Apply, the Rounds page's menu, the Round editor's Apply and its exercise
/// list's menu, and Apply in the two exercise forms (the preset form and
/// the canonical editor: the errors listed, the warnings asked about).
final _stamp = DateTime.utc(2026, 10, 15);

Exercise _choice(String id, {bool draft = false, int correct = 0}) => Exercise(
  id: id,
  publicationState: draft ? PublicationState.draft : PublicationState.published,
  updatedAt: _stamp,
  type: 'choice',
  prompt: 'Choose the greeting.',
  question: 'How are you in exercise $id?',
  answers: const ['well', 'badly'],
  correct: correct,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

/// A Course whose Lesson and Round are Draft (the Round Published with
/// [roundPublished], as a Lesson needs it). With [broken], one Published
/// exercise of the Round has an answer that does not exist: an Audit error
/// learners would meet once the Round and the Lesson are Published.
Course _course({required bool broken, bool roundPublished = false}) => Course(
  courseId: 'publish-gate-273',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Publish gate course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: 'gate-lesson',
      title: 'Gate lesson',
      publicationState: PublicationState.draft,
      updatedAt: _stamp,
      guidebook: testGuidebook(
        moduleId: 'gate_module',
        overview: 'Reviewed overview.',
        words: [testEntry('gate_word', 'casa = house')],
      ),
      rounds: [
        LearningRound(
          id: 'gate-round',
          title: 'Gate round',
          publicationState: roundPublished
              ? PublicationState.published
              : PublicationState.draft,
          updatedAt: _stamp,
          exercises: [
            _choice('gate-first'),
            _choice('gate-second', correct: broken ? 9 : 1),
            _choice('gate-draft', draft: true, correct: broken ? 9 : 0),
          ],
        ),
      ],
    ),
  ],
);

/// A Page whose link is not https: an Audit error (PAGE_LINK_INVALID).
/// With [warningOnly] the link is right and a mark is left open instead:
/// an Audit warning (PAGE_MARK_UNMATCHED) and no error.
Exercise _page({required bool warningOnly}) => Exercise.canonical(
  id: 'gate-page',
  updatedAt: _stamp,
  primitive: ExercisePrimitive.presentation,
  promptElements: [
    PromptElement(
      role: 'block',
      type: 'text',
      text: warningOnly ? 'A **bold start' : 'A page',
    ),
    PromptElement(
      role: 'block',
      type: 'link',
      text: 'Example',
      url: warningOnly ? 'https://example.org' : 'http://example.org',
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation.none,
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _menu(WidgetTester tester, Key menu, String item) async {
  await tester.tap(find.byKey(menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Course Editor, Publish', () {
    Course whole({required bool broken}) {
      final course = _course(broken: broken, roundPublished: true);
      return Course.fromJson({
        ...course.toJson(),
        'lessons': [
          {
            ...course.lessons.single.toJson(),
            'publicationState': PublicationState.published.name,
          },
        ],
      });
    }

    for (final broken in [true, false]) {
      testWidgets(broken ? 'an error refuses it' : 'no error publishes it', (
        tester,
      ) async {
        _viewport(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: CourseEditorScreen(
              course: whole(broken: broken),
              userCourse: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('course-editor-lock')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        final publish = find.widgetWithText(TextButton, 'Publish');
        await tester.ensureVisible(publish);
        await tester.tap(publish);
        await tester.pumpAndSettle();
        if (broken) {
          expect(
            find.textContaining(
              RegExp(r'^Course cannot be published: \d+ blocking errors?\.$'),
            ),
            findsOneWidget,
          );
          expect(find.text('Not published'), findsOneWidget);
        } else {
          expect(find.textContaining('cannot be published'), findsNothing);
          expect(find.widgetWithText(TextButton, 'Unpublish'), findsOneWidget);
        }
      });
    }
  });

  group('Lessons page, Apply from the menu', () {
    for (final broken in [true, false]) {
      testWidgets(broken ? 'an error refuses it' : 'no error applies it', (
        tester,
      ) async {
        _viewport(tester);
        Course? adopted;
        await tester.pumpWidget(
          MaterialApp(
            home: LessonManagementScreen(
              course: _course(broken: broken, roundPublished: true),
              initiallyLocked: false,
              adoptCourse: (course, {previous, usePrevious}) =>
                  adopted = course,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _menu(
          tester,
          const ValueKey('lesson-actions-gate-lesson'),
          'Apply',
        );
        if (broken) {
          expect(
            find.text(
              'Lesson cannot be applied as normal content: 1 blocking error.',
            ),
            findsOneWidget,
          );
          expect(adopted, isNull);
        } else {
          expect(find.textContaining('cannot be applied'), findsNothing);
          expect(
            adopted?.lessons.single.publicationState,
            PublicationState.published,
          );
        }
      });
    }
  });

  group('Lesson editor, Apply', () {
    for (final broken in [true, false]) {
      testWidgets(broken ? 'an error refuses it' : 'no error applies it', (
        tester,
      ) async {
        _viewport(tester);
        final course = _course(broken: broken, roundPublished: true);
        Course? adopted;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push<Lesson>(
                      MaterialPageRoute(
                        builder: (_) => LessonEditorScreen(
                          course: course,
                          lesson: course.lessons.single,
                          adoptCourse: (course, {previous, usePrevious}) =>
                              adopted = course,
                        ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('save-lesson')));
        await tester.tap(find.byKey(const Key('save-lesson')));
        await tester.pumpAndSettle();
        if (broken) {
          expect(
            find.text(
              'Lesson cannot be applied as normal content: 1 blocking error.',
            ),
            findsOneWidget,
          );
          expect(find.byType(LessonEditorScreen), findsOneWidget);
        } else {
          expect(find.textContaining('cannot be applied'), findsNothing);
          expect(find.byType(LessonEditorScreen), findsNothing);
          expect(
            adopted?.lessons.single.publicationState,
            PublicationState.published,
          );
        }
      });
    }
  });

  group('Rounds page, Apply from the menu', () {
    for (final broken in [true, false]) {
      testWidgets(broken ? 'an error refuses it' : 'no error applies it', (
        tester,
      ) async {
        _viewport(tester);
        final course = _course(broken: broken);
        Course? adopted;
        await tester.pumpWidget(
          MaterialApp(
            home: LessonRoundsScreen(
              course: course,
              lesson: course.lessons.single,
              adoptCourse: (course, {previous, usePrevious}) =>
                  adopted = course,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _menu(
          tester,
          const ValueKey('round-actions-gate-round'),
          'Apply',
        );
        if (broken) {
          expect(
            find.text(
              'Round cannot be applied as normal content: 1 blocking error.',
            ),
            findsOneWidget,
          );
          expect(adopted, isNull);
        } else {
          expect(find.textContaining('cannot be applied'), findsNothing);
          expect(
            adopted?.lessons.single.rounds.single.publicationState,
            PublicationState.published,
          );
        }
      });
    }
  });

  group('Round editor', () {
    Future<void> open(WidgetTester tester, Course course) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push<LearningRound>(
                    MaterialPageRoute(
                      builder: (_) => RoundEditorScreen(
                        course: course,
                        lesson: course.lessons.single,
                        round: course.lessons.single.rounds.single,
                        roundIndex: 0,
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Apply with Draft exercises names them instead', (
      tester,
    ) async {
      _viewport(tester);
      await open(tester, _course(broken: true));
      await tester.tap(find.byKey(const Key('round-save')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('round-draft-exercises-notice')),
        findsOneWidget,
      );
      expect(
        find.textContaining('One Exercise is still Draft'),
        findsOneWidget,
      );
    });

    testWidgets('Apply without Draft exercises counts the errors', (
      tester,
    ) async {
      _viewport(tester);
      final broken = _course(broken: true);
      final round = broken.lessons.single.rounds.single;
      final withoutDraft = Course.fromJson({
        ...broken.toJson(),
        'lessons': [
          Lesson.fromJson({
            ...broken.lessons.single.toJson(),
            'rounds': [
              LearningRound(
                id: round.id,
                title: round.title,
                publicationState: PublicationState.draft,
                updatedAt: _stamp,
                exercises: round.exercises.take(2).toList(),
              ).toJson(),
            ],
          }).toJson(),
        ],
      });
      await open(tester, withoutDraft);
      await tester.tap(find.byKey(const Key('round-save')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Round cannot be applied as normal content: 1 blocking error.',
        ),
        findsOneWidget,
      );
      expect(find.byType(RoundEditorScreen), findsOneWidget);
    });

    testWidgets('an exercise with an error cannot be applied from its menu', (
      tester,
    ) async {
      _viewport(tester);
      await open(tester, _course(broken: true));
      await _menu(
        tester,
        const ValueKey('exercise-actions-gate-draft'),
        'Apply',
      );
      expect(
        find.text(
          'Exercise cannot be applied as normal content until its Errors are fixed.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an exercise without errors is applied from its menu', (
      tester,
    ) async {
      _viewport(tester);
      await open(tester, _course(broken: false));
      await _menu(
        tester,
        const ValueKey('exercise-actions-gate-draft'),
        'Apply',
      );
      expect(find.textContaining('cannot be applied'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('exercise-actions-gate-draft')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Apply as draft'), findsWidgets);
    });
  });

  group('The two exercise forms, Apply', () {
    Future<Exercise?> apply(
      WidgetTester tester, {
      required bool canonical,
      required bool warningOnly,
      required String answer,
    }) async {
      _viewport(tester);
      tester.view.physicalSize = const Size(1400, 3600);
      Exercise? saved;
      final exercise = _page(warningOnly: warningOnly);
      await tester.pumpWidget(
        MaterialApp(
          home: canonical
              ? PrimitiveEditorScreen(
                  exercise: exercise,
                  title: 'Page',
                  isNew: false,
                  onExerciseSaved: (e) => saved = e,
                )
              : ExerciseEditorScreen(
                  exercise: exercise,
                  title: 'Page',
                  isNew: false,
                  onExerciseSaved: (e) => saved = e,
                ),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.byKey(
        Key(canonical ? 'primitive-save' : 'exercise-save'),
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      if (warningOnly) {
        expect(find.text('Exercise audit: 1 warnings'), findsOneWidget);
        expect(
          find.textContaining('WARNING [PAGE_MARK_UNMATCHED]: '),
          findsOneWidget,
        );
      } else {
        expect(find.text('Exercise audit: 1 errors'), findsOneWidget);
        expect(find.textContaining('PAGE_LINK_INVALID: '), findsOneWidget);
      }
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
      expect(find.textContaining('Exercise audit:'), findsNothing);
      return saved;
    }

    for (final canonical in [false, true]) {
      final form = canonical ? 'canonical editor' : 'preset form';
      testWidgets('$form: an error is listed and nothing is applied', (
        tester,
      ) async {
        final saved = await apply(
          tester,
          canonical: canonical,
          warningOnly: false,
          answer: 'Keep editing',
        );
        expect(saved, isNull);
      });

      testWidgets('$form: a warning asks; Keep editing applies nothing', (
        tester,
      ) async {
        final saved = await apply(
          tester,
          canonical: canonical,
          warningOnly: true,
          answer: 'Keep editing',
        );
        expect(saved, isNull);
      });

      testWidgets('$form: a warning asks; Use anyway applies it', (
        tester,
      ) async {
        final saved = await apply(
          tester,
          canonical: canonical,
          warningOnly: true,
          answer: 'Use anyway',
        );
        expect(saved?.publicationState, PublicationState.published);
      });
    }
  });
}
