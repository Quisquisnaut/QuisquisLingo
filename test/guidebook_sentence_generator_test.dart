import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({'sentinel': 'keep'}));

  testWidgets(
    'cancelling the Guidebook generator leaves the Topic and preferences unchanged',
    (tester) async {
      final fixture = _generatorFixture();
      final originalTopicJson = fixture.topic.toJson();
      final originalCourseJson = fixture.course.toJson();
      final routeResults = <Topic?>[];
      await _openTopicEditor(tester, fixture, routeResults: routeResults);

      await tester.tap(find.byTooltip('Generate 3 Rounds from Guidebook'));
      await tester.pumpAndSettle();

      expect(find.text('Review 3 generated Rounds'), findsOneWidget);
      expect(
        find.textContaining(
          'Nothing is created until you approve this preview.',
        ),
        findsOneWidget,
      );
      expect(find.text('Approve and create 3 Rounds'), findsOneWidget);
      await _tapAndSettle(tester, 'Cancel');
      await _tapAndSettle(tester, 'Save');

      expect(routeResults, hasLength(1));
      expect(routeResults.single?.toJson(), originalTopicJson);
      expect(fixture.topic.toJson(), originalTopicJson);
      expect(fixture.course.toJson(), originalCourseJson);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'sentinel'});
      expect(prefs.getString('sentinel'), 'keep');
    },
  );

  testWidgets(
    'approval appends three reviewed Rounds derived from the Topic Guidebook',
    (tester) async {
      final fixture = _generatorFixture();
      final originalTopicJson = fixture.topic.toJson();
      final originalCourseJson = fixture.course.toJson();
      final guidebookIds = fixture.topic.guidebook.content
          .map((content) => content.id)
          .toSet();
      final routeResults = <Topic?>[];
      await _openTopicEditor(tester, fixture, routeResults: routeResults);

      await tester.tap(find.byTooltip('Generate 3 Rounds from Guidebook'));
      await tester.pumpAndSettle();
      final approve = find.text('Approve and create 3 Rounds');
      expect(approve, findsOneWidget);
      await tester.ensureVisible(approve);
      await tester.tap(approve);
      await tester.pumpAndSettle();
      await _tapAndSettle(tester, 'Save');

      expect(routeResults, hasLength(1));
      final updated = routeResults.single!;
      expect(updated.id, fixture.topic.id);
      expect(updated.title, fixture.topic.title);
      expect(updated.duel.toJson(), fixture.topic.duel.toJson());
      expect(updated.guidebook.toJson(), fixture.topic.guidebook.toJson());
      expect(updated.rounds, hasLength(4));
      expect(updated.rounds.first.id, 'existing_round');
      expect(updated.rounds.first.visualType, 'story');
      expect(updated.rounds.skip(1).map((round) => round.title), [
        'Round 1',
        'Round 2',
        'Round 3',
      ]);
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
          'flashcard',
          'word_match',
          'audio_match',
          'listening_choice',
          'listening_spelling',
          'word_order',
          'gap_choice',
          'reading_comprehension',
        }),
      );
      final intro = generatedContent.singleWhere(
        (content) => content.role == 'topic_intro',
      );
      expect(intro.text, contains('Read this Topic Guidebook for more'));
      expect(intro.sourceRefs, isNotEmpty);
      expect(intro.sourceRefs, everyElement(isIn(guidebookIds)));

      final generatedIds = generatedContent
          .map((content) => content.id)
          .toList();
      expect(generatedIds.toSet(), hasLength(generatedIds.length));
      expect(generatedIds, isNot(contains('existing_exercise')));

      expect(fixture.topic.toJson(), originalTopicJson);
      expect(fixture.course.toJson(), originalCourseJson);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'sentinel'});
      expect(prefs.getString('sentinel'), 'keep');
    },
  );
}

class _GeneratorFixture {
  final Course course;
  final Topic topic;

  const _GeneratorFixture({
    required this.course,
    required this.topic,
  });
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
  final topic = Topic(
    id: 'topic_identity',
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
    topics: [topic],
  );
  return _GeneratorFixture(course: course, topic: topic);
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

Future<void> _openTopicEditor(
  WidgetTester tester,
  _GeneratorFixture fixture, {
  required List<Topic?> routeResults,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                routeResults.add(
                  await Navigator.of(context).push<Topic>(
                    MaterialPageRoute(
                      builder: (_) => TopicEditorScreen(
                        course: fixture.course,
                        topic: fixture.topic,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open Topic Editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Topic Editor'));
  await tester.pumpAndSettle();
  expect(find.byType(TopicEditorScreen), findsOneWidget);
}

Future<void> _tapAndSettle(WidgetTester tester, String label) async {
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
