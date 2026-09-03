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
      '$file is native Course Model v5 with ordered Lesson Guidebooks and Duels',
      () async {
        final raw = await rootBundle.loadString('assets/courses/$file');
        final json = jsonDecode(raw) as Map<String, dynamic>;
        expect(json['formatVersion'], 5);
        expect(json.containsKey('topics'), isFalse);
        expect(json.containsKey('chapters'), isFalse);
        final course = Course.fromJson(json);
        expect(course.formatVersion, 5);
        expect(course.lessons, hasLength(9));
        expect(
          course.lessons.map((lesson) => lesson.lessonId).toSet(),
          hasLength(9),
        );
        final expectedRoundCount = file == 'italian_en.json' ? 4 : 2;
        for (final lesson in course.lessons) {
          expect(lesson.title.trim(), isNotEmpty);
          expect(
            (json['lessons'] as List).cast<Map<String, dynamic>>().every(
              (item) => !item.containsKey('imageAsset'),
            ),
            isTrue,
          );
          expect(lesson.guidebook.content, isNotEmpty);
          expect(lesson.rounds, hasLength(expectedRoundCount));
          expect(lesson.rounds.every((r) => r.content.isNotEmpty), isTrue);
          expect(lesson.rounds.first.content.first.role, 'lesson_intro');
          expect(lesson.duel.id.trim(), isNotEmpty);
        }
        final encoded = course.toJson();
        expect(encoded['formatVersion'], 5);
        expect(encoded.containsKey('chapters'), isFalse);
        expect(
          (encoded['lessons'] as List).map(
            (lesson) => (lesson as Map)['lessonId'],
          ),
          course.lessons.map((lesson) => lesson.lessonId),
        );
      },
    );
  }

  test('Course Model v5 rejects old formats and Chapter structures', () {
    final base = <String, dynamic>{
      'courseId': 'course',
      'learningLanguage': 'Italian',
      'interfaceLanguage': 'English',
      'sourceLanguage': 'English',
      'targetLanguage': 'Italian',
      'title': 'Course',
      'ttsLanguage': 'it-IT',
      'version': '1',
      'lessons': <Object>[],
    };
    expect(
      () => Course.fromJson({...base, 'formatVersion': 3}),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({...base, 'formatVersion': 4}),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({
        ...base,
        'formatVersion': 5,
        'chapters': <Object>[],
      }),
      throwsFormatException,
    );
  });

  test('Course Model v5 preserves Lesson and Round ordering', () {
    Lesson lesson(String id, List<String> rounds) => Lesson(
      lessonId: id,
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
      lessons: [
        lesson('t2', ['r3', 'r1']),
        lesson('t1', ['r2']),
      ],
    );
    final decoded = Course.fromJson(course.toJson());
    expect(decoded.lessons.map((lesson) => lesson.lessonId), ['t2', 't1']);
    expect(decoded.lessons.first.rounds.map((round) => round.id), ['r3', 'r1']);
  });

  test('Course Model v5 rejects obsolete Lesson hierarchy fields', () {
    final json = _strictV5Fixture();
    final lesson = (json['lessons'] as List).single as Map<String, dynamic>;
    lesson['role'] = 'learning';
    expect(() => Course.fromJson(json), throwsFormatException);

    lesson.remove('role');
    lesson['assessment'] = {
      'source': {'scope': 'chapter'},
      'selection': {'count': 25},
    };
    expect(() => Course.fromJson(json), throwsFormatException);
  });

  test('Course Model v5 rejects unsupported Duel fields', () {
    final json = _strictV5Fixture();
    final lesson = (json['lessons'] as List).single as Map<String, dynamic>;
    final duel = lesson['duel'] as Map<String, dynamic>;
    duel['selection'] = {'count': 25};
    expect(() => Course.fromJson(json), throwsFormatException);
  });

  test('Course Model v5 requires a supported Round visualType', () {
    final missing = _strictV5Fixture();
    final missingLesson =
        (missing['lessons'] as List).single as Map<String, dynamic>;
    final missingRound =
        (missingLesson['rounds'] as List).single as Map<String, dynamic>;
    missingRound.remove('visualType');
    expect(() => Course.fromJson(missing), throwsFormatException);

    final invalid = _strictV5Fixture();
    final invalidLesson =
        (invalid['lessons'] as List).single as Map<String, dynamic>;
    final invalidRound =
        (invalidLesson['rounds'] as List).single as Map<String, dynamic>;
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

  test('optional course flag metadata round-trips in Course Model v5', () {
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
      lessons: const [],
    );
    final decoded = Course.fromJson(course.toJson());
    expect(decoded.flagCode, 'DE');
    expect(decoded.flagImageBase64, 'aGVsbG8=');
  });

  test('Course Model v5 rejects legacy topics and Lesson id fields', () {
    final canonical = _strictV5Fixture();
    final lessons = canonical.remove('lessons');
    expect(
      () => Course.fromJson({...canonical, 'topics': lessons}),
      throwsFormatException,
    );

    final legacyIdentity = _strictV5Fixture();
    final lesson = (legacyIdentity['lessons'] as List).single as Map;
    lesson['id'] = lesson.remove('lessonId');
    expect(() => Course.fromJson(legacyIdentity), throwsFormatException);
  });

  test('Course Model v5 rejects the obsolete Lesson imageAsset field', () {
    final legacyImage = _strictV5Fixture();
    ((legacyImage['lessons'] as List).single as Map)['imageAsset'] =
        'assets/exercise_images/legacy.webp';
    expect(() => Course.fromJson(legacyImage), throwsFormatException);
  });

  test('Round titles remain optional without changing Round identity', () {
    final round = LearningRound.fromJson({
      'id': 'stable_untitled_round',
      'publicationState': 'published',
      'visualType': 'generic',
      'content': <Object>[],
    });

    expect(round.id, 'stable_untitled_round');
    expect(round.title, isEmpty);
    expect(round.toJson().containsKey('title'), isFalse);
    expect(LearningRound.fromJson(round.toJson()).id, 'stable_untitled_round');
  });

  test('Section metadata is canonical and rejects inconsistent values', () {
    final withSection = Lesson(
      lessonId: 'section_lesson',
      title: 'At the café',
      rounds: const [],
      section: true,
      sectionName: '  Everyday Life  ',
      themeIconAsset: 'assets/lesson_icons/coffee.png',
    );
    expect(withSection.sectionName, 'Everyday Life');
    expect(withSection.toJson()['section'], isTrue);
    expect(withSection.toJson()['sectionName'], 'Everyday Life');
    expect(
      withSection.toJson()['themeIconAsset'],
      'assets/lesson_icons/coffee.png',
    );

    final withoutSection = Lesson(
      lessonId: 'plain_lesson',
      title: 'Daily routine',
      rounds: const [],
    ).toJson();
    expect(withoutSection['section'], isFalse);
    expect(withoutSection.containsKey('sectionName'), isFalse);
    expect(withoutSection.containsKey('themeIconAsset'), isFalse);

    final missingName = _strictV5Fixture();
    ((missingName['lessons'] as List).single as Map)['section'] = true;
    expect(() => Course.fromJson(missingName), throwsFormatException);

    final meaninglessName = _strictV5Fixture();
    final inconsistent = (meaninglessName['lessons'] as List).single as Map;
    inconsistent['section'] = false;
    inconsistent['sectionName'] = 'Unused';
    expect(() => Course.fromJson(meaninglessName), throwsFormatException);
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

  test('lesson intro Content is not exposed as a runnable exercise', () {
    final round = LearningRound(
      id: 'r',
      title: 'Round',
      content: [
        const LearningContent(
          id: 'intro',
          kind: 'explanation',
          required: false,
          role: 'lesson_intro',
          text: 'Read the Lesson Guidebook for more.',
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

Map<String, dynamic> _strictV5Fixture() => Course(
  courseId: 'strict_v5',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Strict v5',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: [
        LearningRound(id: 'round', title: 'Round', visualType: 'generic'),
      ],
    ),
  ],
).toJson();
