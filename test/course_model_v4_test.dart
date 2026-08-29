import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const samples = [
    'italian_en.json',
    'german_en.json',
    'spanish_en.json',
    'english_es.json',
    'portuguese_en.json',
    'dutch_en.json',
    'welsh_en.json',
    'finnish_en.json',
  ];

  for (final file in samples) {
    test(
      '$file is native Course Model v4 with ordered Topic Guidebooks and Duels',
      () async {
        final raw = await rootBundle.loadString('assets/courses/$file');
        final json = jsonDecode(raw) as Map<String, dynamic>;
        expect(json['formatVersion'], 4);
        expect(json.containsKey('chapters'), isFalse);
        final course = Course.fromJson(json);
        expect(course.formatVersion, 4);
        expect(course.topics, hasLength(9));
        expect(course.topics.map((topic) => topic.id).toSet(), hasLength(9));
        for (final topic in course.topics) {
          expect(topic.title.trim(), isNotEmpty);
          expect(topic.imageAsset.trim(), isNotEmpty);
          expect(topic.guidebook.content, isNotEmpty);
          expect(topic.rounds, hasLength(2));
          expect(topic.rounds.every((r) => r.content.isNotEmpty), isTrue);
          expect(topic.rounds.first.content.first.role, 'topic_intro');
          expect(topic.duel.id.trim(), isNotEmpty);
        }
        final encoded = course.toJson();
        expect(encoded['formatVersion'], 4);
        expect(encoded.containsKey('chapters'), isFalse);
        expect(
          (encoded['topics'] as List).map((topic) => (topic as Map)['id']),
          course.topics.map((topic) => topic.id),
        );
      },
    );
  }

  test('Course Model v4 rejects old formats and Chapter structures', () {
    final base = <String, dynamic>{
      'courseId': 'course',
      'learningLanguage': 'Italian',
      'interfaceLanguage': 'English',
      'sourceLanguage': 'English',
      'targetLanguage': 'Italian',
      'title': 'Course',
      'ttsLanguage': 'it-IT',
      'version': '1',
      'topics': <Object>[],
    };
    expect(
      () => Course.fromJson({...base, 'formatVersion': 3}),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({
        ...base,
        'formatVersion': 4,
        'chapters': <Object>[],
      }),
      throwsFormatException,
    );
  });

  test('Course Model v4 preserves Topic and Round ordering', () {
    Topic topic(String id, List<String> rounds) => Topic(
      id: id,
      title: id,
      rounds: [
        for (final round in rounds) LearningRound(id: round, title: round),
      ],
    );
    final course = Course(
      courseId: 'ordered',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Ordered',
      ttsLanguage: 'it-IT',
      version: '1',
      topics: [
        topic('t2', ['r3', 'r1']),
        topic('t1', ['r2']),
      ],
    );
    final decoded = Course.fromJson(course.toJson());
    expect(decoded.topics.map((topic) => topic.id), ['t2', 't1']);
    expect(decoded.topics.first.rounds.map((round) => round.id), ['r3', 'r1']);
  });

  test('Course Model v4 rejects obsolete Topic hierarchy fields', () {
    final json = _strictV4Fixture();
    final topic = (json['topics'] as List).single as Map<String, dynamic>;
    topic['role'] = 'learning';
    expect(() => Course.fromJson(json), throwsFormatException);

    topic.remove('role');
    topic['assessment'] = {
      'source': {'scope': 'chapter'},
      'selection': {'count': 25},
    };
    expect(() => Course.fromJson(json), throwsFormatException);
  });

  test('Course Model v4 rejects unsupported Duel fields', () {
    final json = _strictV4Fixture();
    final topic = (json['topics'] as List).single as Map<String, dynamic>;
    final duel = topic['duel'] as Map<String, dynamic>;
    duel['selection'] = {'count': 25};
    expect(() => Course.fromJson(json), throwsFormatException);
  });

  test('Course Model v4 requires a supported Round visualType', () {
    final missing = _strictV4Fixture();
    final missingTopic =
        (missing['topics'] as List).single as Map<String, dynamic>;
    final missingRound =
        (missingTopic['rounds'] as List).single as Map<String, dynamic>;
    missingRound.remove('visualType');
    expect(() => Course.fromJson(missing), throwsFormatException);

    final invalid = _strictV4Fixture();
    final invalidTopic =
        (invalid['topics'] as List).single as Map<String, dynamic>;
    final invalidRound =
        (invalidTopic['rounds'] as List).single as Map<String, dynamic>;
    invalidRound['visualType'] = 'chapter_assessment';
    expect(() => Course.fromJson(invalid), throwsFormatException);
  });

  test(
    'text_match reads acceptedAnswers and legacy accepted, then writes acceptedAnswers',
    () {
      ExerciseEvaluation read(Map<String, dynamic> json) =>
          ExerciseEvaluation.fromJson(json);
      expect(
        read({
          'kind': 'text_match',
          'acceptedAnswers': ['ecco'],
        }).accepted,
        ['ecco'],
      );
      expect(
        read({
          'kind': 'text_match',
          'accepted': ['ciao'],
        }).accepted,
        ['ciao'],
      );
      final encoded = read({
        'kind': 'text_match',
        'acceptedAnswers': ['ecco'],
      }).toJson();
      expect(encoded['acceptedAnswers'], ['ecco']);
      expect(encoded.containsKey('accepted'), isFalse);
    },
  );

  test('optional course flag metadata round-trips in Course Model v4', () {
    final course = Course(
      courseId: 'user_flag_test',
      learningLanguage: 'German',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'German',
      title: 'German',
      ttsLanguage: 'de-DE',
      version: '1',
      flagCode: 'DE',
      flagImageBase64: 'aGVsbG8=',
      topics: const [],
    );
    final decoded = Course.fromJson(course.toJson());
    expect(decoded.flagCode, 'DE');
    expect(decoded.flagImageBase64, 'aGVsbG8=');
  });

  test('choice correctness is stored by stable Item ID', () {
    final ex = Exercise(
      id: 'x',
      type: 'choice',
      prompt: '',
      question: 'Q',
      answers: const ['a', 'b'],
      correct: 1,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
    expect(ex.interaction.kind, 'select');
    expect(ex.evaluation.kind, 'selected_items');
    expect(ex.evaluation.correctItemIds, [ex.interaction.items[1].id]);
  });

  test('topic intro Content is not exposed as a runnable exercise', () {
    final round = LearningRound(
      id: 'r',
      title: 'Round',
      content: [
        const LearningContent(
          id: 'intro',
          kind: 'explanation',
          required: false,
          role: 'topic_intro',
          text: 'Read the Topic Guidebook for more.',
        ),
        LearningContent.fromExercise(
          Exercise(
            id: 'x',
            type: 'choice',
            prompt: '',
            question: 'Q',
            answers: const ['a', 'b'],
            correct: 0,
            tts: null,
            accepted: const [],
            tokens: const [],
            orderAnswer: const [],
            pairs: const [],
            hint: '',
            icons: const [],
          ),
        ),
      ],
    );
    expect(round.content, hasLength(2));
    expect(round.exercises, hasLength(1));
    expect(round.exercises.single.id, 'x');
  });

  test('flashcard serializes as Presentation Content', () {
    final ex = Exercise(
      id: 'f',
      type: 'flashcard',
      prompt: 'ciao',
      question: 'hello',
      answers: const [],
      correct: null,
      tts: 'ciao',
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
    final content = LearningContent.fromExercise(ex);
    expect(content.kind, 'presentation');
    expect(
      content.presentation?.actions,
      containsAll(['understood', 'review_later']),
    );
  });
}

Map<String, dynamic> _strictV4Fixture() => Course(
  courseId: 'strict_v4',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Strict v4',
  ttsLanguage: 'it-IT',
  version: '1',
  topics: [
    Topic(
      id: 'topic',
      title: 'Topic',
      rounds: [
        LearningRound(id: 'round', title: 'Round', visualType: 'generic'),
      ],
    ),
  ],
).toJson();
