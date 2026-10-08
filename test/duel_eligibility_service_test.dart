import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';

Exercise _exercise(
  String id, {
  String type = 'choice',
  List<String> answers = const ['Correct', 'Wrong'],
  int? correct = 0,
  String prompt = 'Prompt',
  String question = 'Question',
  String? tts,
}) => Exercise(
  id: id,
  type: type,
  prompt: prompt,
  question: question,
  answers: answers,
  correct: correct,
  tts: tts,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

LearningRound _round(String id, List<Exercise> exercises) =>
    LearningRound(id: id, title: id, exercises: exercises);

Lesson _lesson(List<List<Exercise>> rounds) => Lesson(
  lessonId: 'lesson',
  title: 'Lesson',
  rounds: [
    for (var i = 0; i < rounds.length; i++) _round('round_$i', rounds[i]),
  ],
);

Course _course(Lesson lesson) => Course(
  courseId: 'duel-audio-course',
  title: 'Duel audio course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [lesson],
);

List<Exercise> _eligibleRange(int start, int count) => [
  for (var i = start; i < start + count; i++)
    _exercise('exercise_$i', prompt: 'Prompt $i'),
];

void main() {
  const service = DuelEligibilityService();

  test('more than 25 eligible exercises is available without pool capping', () {
    final result = service.evaluate(_lesson([_eligibleRange(0, 30)]));

    expect(result.requiredCount, 25);
    expect(result.eligibleCount, 30);
    expect(result.candidates, hasLength(30));
    expect(result.isAvailable, isTrue);
  });

  test('exactly 25 eligible exercises is available', () {
    final result = service.evaluate(_lesson([_eligibleRange(0, 25)]));

    expect(result.eligibleCount, 25);
    expect(result.isAvailable, isTrue);
  });

  test('fewer than 25 eligible exercises is unavailable', () {
    final result = service.evaluate(_lesson([_eligibleRange(0, 24)]));

    expect(result.eligibleCount, 24);
    expect(result.isAvailable, isFalse);
  });

  test('many total exercises do not help when most are ineligible', () {
    final invalid = <Exercise>[
      for (var i = 0; i < 20; i++)
        _exercise('unsupported_$i', type: 'fill_blank'),
      for (var i = 0; i < 10; i++)
        _exercise('one_answer_$i', answers: const ['Only']),
      for (var i = 0; i < 10; i++) _exercise('no_correct_$i', correct: null),
    ];
    final result = service.evaluate(_lesson([_eligibleRange(0, 10), invalid]));

    expect(result.eligibleCount, 10);
    expect(result.isAvailable, isFalse);
  });

  test('fewer than six Rounds can still provide an available Duel', () {
    final result = service.evaluate(
      _lesson([_eligibleRange(0, 13), _eligibleRange(13, 13)]),
    );

    expect(result.eligibleCount, 26);
    expect(result.isAvailable, isTrue);
  });

  test('six or more Rounds do not make an insufficient pool available', () {
    final result = service.evaluate(
      _lesson([
        _eligibleRange(0, 4),
        _eligibleRange(4, 4),
        _eligibleRange(8, 4),
        _eligibleRange(12, 4),
        _eligibleRange(16, 4),
        _eligibleRange(20, 4),
      ]),
    );

    expect(result.eligibleCount, 24);
    expect(result.isAvailable, isFalse);
  });

  test('duplicate-key exercises count only once', () {
    final duplicate = _exercise('duplicate');
    final result = service.evaluate(
      _lesson([
        [for (var i = 0; i < 30; i++) duplicate],
      ]),
    );

    expect(result.eligibleCount, 1);
    expect(result.isAvailable, isFalse);
  });

  test('eligibility comes from canonical data, not from the preset', () {
    // Every single-answer Select whose items are shown as choices qualifies
    // (Build 256, plan A.10), whichever preset authored it.
    final singles = [
      _exercise('plain'),
      _exercise(
        'gap',
        type: 'gap_choice',
        question: 'Il gatto ___ sul divano.',
      ),
      _exercise('listen', type: 'listening_choice', tts: 'Buongiorno'),
      _exercise(
        'passage',
        type: 'listening_comprehension',
        tts: 'Maria compra',
      ),
      _exercise(
        'read',
        type: 'reading_comprehension',
        prompt: 'Anna abita a Roma.',
      ),
      _exercise(
        'dialogue',
        type: 'dialogue_response',
        prompt: 'Un amico ti offre acqua.',
      ),
      _exercise(
        'context',
        type: 'contextual_comprehension',
        prompt: 'Marco entra in un bar.',
      ),
      _exercise('icons', type: 'icon_choice'),
      _exercise('to-target', type: 'translation_choice_to_target'),
      _exercise('to-source', type: 'translation_choice_to_source'),
      Exercise(
        id: 'characters',
        type: 'script_recognition',
        prompt: 'Select the character shown.',
        question: '',
        answers: const ['A', 'E'],
        correct: 0,
        tts: null,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
        imageAsset: 'assets/exercise_images/apple.webp',
      ),
    ];
    for (final exercise in singles) {
      expect(
        DuelEligibilityService.isEligible(exercise),
        isTrue,
        reason: exercise.id,
      );
    }
    final result = service.evaluate(_lesson([singles]));
    expect(result.candidates.map((c) => c.exercise.id).toSet(), {
      for (final exercise in singles) exercise.id,
    });
    expect(result.candidates.map((c) => c.round.id).toSet(), {'round_0'});

    // A multiple-answer Choose, an inline-gap Select and every other
    // primitive stay out of the pool.
    final multiple = Exercise.canonical(
      id: 'multiple',
      primitive: ExercisePrimitive.select,
      options: PrimitiveOptions({
        OptionKey.selectionMode: const EnumOptionValue(SelectionMode.multiple),
        OptionKey.maximumSelections: const IntOptionValue(2),
        OptionKey.evaluationTiming: const EnumOptionValue(
          EvaluationTiming.explicit,
        ),
      }),
      promptElements: const [PromptElement(type: 'text', text: 'Choose two.')],
      items: const [
        ExerciseItem(
          id: 'a',
          content: [PromptElement(type: 'text', text: 'a')],
        ),
        ExerciseItem(
          id: 'b',
          content: [PromptElement(type: 'text', text: 'b')],
        ),
        ExerciseItem(
          id: 'c',
          content: [PromptElement(type: 'text', text: 'c')],
        ),
      ],
      canonicalEvaluation: const CanonicalEvaluation(
        mode: EvaluationMode.exactSet,
        correctItemIds: ['a', 'b'],
      ),
    );
    expect(DuelEligibilityService.isEligible(multiple), isFalse);
    expect(
      DuelEligibilityService.isEligible(
        _exercise('typed', type: 'type_translation'),
      ),
      isFalse,
    );
    expect(
      service
          .evaluate(
            _lesson([
              [multiple],
            ]),
          )
          .eligibleCount,
      0,
    );
  });

  test(
    'Audio On retains available audio exercises in the effective pool',
    () async {
      final lesson = _lesson([
        [
          ..._eligibleRange(0, 24),
          _exercise('audio_24', type: 'listening_choice', tts: 'Ascolta'),
        ],
      ]);

      final result = await service.evaluateEffective(
        _course(lesson),
        lesson,
        audioExercisesEnabled: true,
        ttsEnabled: true,
      );

      expect(result.eligibleCount, 25);
      expect(result.isAvailable, isTrue);
    },
  );

  test(
    'Audio Off keeps Duel available when 25 non-audio exercises remain',
    () async {
      final lesson = _lesson([
        [
          ..._eligibleRange(0, 25),
          _exercise('audio_25', type: 'listening_choice', tts: 'Ascolta'),
        ],
      ]);

      final result = await service.evaluateEffective(
        _course(lesson),
        lesson,
        audioExercisesEnabled: false,
        ttsEnabled: false,
      );

      expect(result.eligibleCount, 25);
      expect(result.isAvailable, isTrue);
    },
  );

  test(
    'Audio Off makes Duel unavailable when filtering leaves only 24',
    () async {
      final lesson = _lesson([
        [
          ..._eligibleRange(0, 24),
          _exercise('audio_24', type: 'listening_choice', tts: 'Ascolta'),
        ],
      ]);

      final result = await service.evaluateEffective(
        _course(lesson),
        lesson,
        audioExercisesEnabled: false,
        ttsEnabled: false,
      );

      expect(result.eligibleCount, 24);
      expect(result.isAvailable, isFalse);
      expect(result.isStructurallyAvailable, isTrue);
    },
  );
}
