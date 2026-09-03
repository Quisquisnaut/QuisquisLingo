import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({'sentinel': 'keep'}));

  testWidgets(
    'cancelling the Guidebook generator leaves the Lesson and preferences unchanged',
    (tester) async {
      final fixture = _generatorFixture();
      final originalLessonJson = fixture.lesson.toJson();
      final originalCourseJson = fixture.course.toJson();
      final routeResults = <Lesson?>[];
      await _openLessonEditor(tester, fixture, routeResults: routeResults);

      await tester.tap(find.byKey(const Key('guidebook-round-generator')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('guidebook-generator-configure')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('generator-total')), findsOneWidget);
      expect(
        find.text('6 Rounds × 8 exercises = 48 exercises'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('generator-review-plan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guidebook-generator-plan')), findsOneWidget);
      expect(find.byKey(const Key('guidebook-generator-drafts')), findsNothing);
      await _scrollToKey(tester, 'generator-cancel');
      await tester.tap(find.byKey(const Key('generator-cancel')));
      await tester.pumpAndSettle();
      await _tapAndSettle(tester, 'Save');

      expect(routeResults, hasLength(1));
      expect(routeResults.single?.toJson(), originalLessonJson);
      expect(fixture.lesson.toJson(), originalLessonJson);
      expect(fixture.course.toJson(), originalCourseJson);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'sentinel'});
      expect(prefs.getString('sentinel'), 'keep');
    },
  );

  testWidgets(
    'approval appends six reviewed Rounds derived from the Lesson GuideBook',
    (tester) async {
      final fixture = _generatorFixture();
      final originalLessonJson = fixture.lesson.toJson();
      final originalCourseJson = fixture.course.toJson();
      final routeResults = <Lesson?>[];
      await _openLessonEditor(tester, fixture, routeResults: routeResults);

      await tester.tap(find.byKey(const Key('guidebook-round-generator')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('generator-review-plan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guidebook-generator-plan')), findsOneWidget);
      expect(fixture.lesson.toJson(), originalLessonJson);
      await _scrollToKey(tester, 'generator-generate');
      await tester.tap(find.byKey(const Key('generator-generate')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guidebook-generator-drafts')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('generated-draft-1')), findsNothing);
      await _scrollToKey(tester, 'generator-approve');
      await tester.tap(find.byKey(const Key('generator-approve')));
      await tester.pumpAndSettle();
      await _tapAndSettle(tester, 'Save');

      expect(routeResults, hasLength(1));
      final updated = routeResults.single!;
      expect(updated.lessonId, fixture.lesson.lessonId);
      expect(updated.title, fixture.lesson.title);
      expect(updated.duel.toJson(), fixture.lesson.duel.toJson());
      expect(updated.guidebook.toJson(), fixture.lesson.guidebook.toJson());
      expect(updated.rounds, hasLength(7));
      expect(updated.rounds.first.id, 'existing_round');
      expect(updated.rounds.first.visualType, 'story');
      expect(
        updated.rounds.skip(1).map((round) => round.title),
        everyElement(isNotEmpty),
      );
      expect(
        updated.rounds.skip(1).map((round) => round.exercises.length),
        everyElement(8),
      );
      expect(
        updated.rounds.skip(1).map((round) => round.visualType),
        everyElement('generic'),
      );

      final generatedContent = updated.rounds
          .skip(1)
          .expand((round) => round.content)
          .toList();
      final generatedExercises = updated.rounds
          .skip(1)
          .expand((round) => round.exercises)
          .toList();
      final generatedTypes = generatedExercises
          .map((exercise) => exercise.type)
          .toSet();
      expect(
        generatedTypes,
        containsAll({
          'choice',
          'word_match',
          'audio_match',
          'listening_choice',
          'word_order',
          'gap_choice',
          'contextual_comprehension',
          'type_translation',
          'build_translation',
        }),
      );
      final intro = generatedContent.singleWhere(
        (content) => content.role == 'lesson_intro',
      );
      expect(intro.text, contains('Before you start'));
      expect(intro.sourceRefs, isNotEmpty);

      final generatedIds = generatedContent
          .map((content) => content.id)
          .toList();
      expect(generatedIds.toSet(), hasLength(generatedIds.length));
      expect(generatedIds, isNot(contains('existing_exercise')));
      final allIds = <String>{};
      for (final round in updated.rounds.skip(1)) {
        expect(allIds.add(round.id), isTrue);
        for (final exercise in round.exercises) {
          expect(allIds.add(exercise.id), isTrue);
        }
      }

      expect(fixture.lesson.toJson(), originalLessonJson);
      expect(fixture.course.toJson(), originalCourseJson);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'sentinel'});
      expect(prefs.getString('sentinel'), 'keep');
    },
  );
}

class _GeneratorFixture {
  final Course course;
  final Lesson lesson;

  const _GeneratorFixture({required this.course, required this.lesson});
}

_GeneratorFixture _generatorFixture() {
  final guidebook = Guidebook(
    overview: 'Common places and useful everyday objects.',
    vocabulary: const [
      'casa = house',
      'pane = bread',
      'acqua = water',
      'libro = book',
    ],
    examples: const [
      'La casa è molto grande.',
      'Il pane è sul tavolo.',
      'Bevo acqua ogni mattina.',
      'Il libro è nella borsa.',
    ],
  );
  final existingRound = LearningRound(
    id: 'existing_round',
    title: 'Existing Round',
    visualType: 'story',
    exercises: [_choiceExercise('existing_exercise')],
  );
  final lesson = Lesson(
    lessonId: 'lesson_identity',
    title: 'Everyday language',
    rounds: [existingRound],
    guidebook: guidebook,
  );
  final course = Course(
    courseId: 'course_identity',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Generator Characterization Course',
    ttsLanguage: 'it-IT',
    version: '1.0.0',
    lessons: [lesson],
  );
  return _GeneratorFixture(course: course, lesson: lesson);
}

Exercise _choiceExercise(String id) => Exercise(
  id: id,
  type: 'choice',
  prompt: 'Choose the existing answer.',
  question: '',
  answers: const ['Correct', 'Incorrect'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Future<void> _openLessonEditor(
  WidgetTester tester,
  _GeneratorFixture fixture, {
  required List<Lesson?> routeResults,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                routeResults.add(
                  await Navigator.of(context).push<Lesson>(
                    MaterialPageRoute(
                      builder: (_) => LessonEditorScreen(
                        course: fixture.course,
                        lesson: fixture.lesson,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open Lesson Editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Lesson Editor'));
  await tester.pumpAndSettle();
  expect(find.byType(LessonEditorScreen), findsOneWidget);
}

Future<void> _tapAndSettle(WidgetTester tester, String label) async {
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollToKey(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(key)),
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}
