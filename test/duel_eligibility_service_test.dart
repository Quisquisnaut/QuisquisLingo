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

Topic _topic(List<List<Exercise>> rounds) => Topic(
  id: 'topic',
  title: 'Topic',
  rounds: [
    for (var i = 0; i < rounds.length; i++) _round('round_$i', rounds[i]),
  ],
);

List<Exercise> _eligibleRange(int start, int count) => [
  for (var i = start; i < start + count; i++)
    _exercise('exercise_$i', prompt: 'Prompt $i'),
];

void main() {
  const service = DuelEligibilityService();

  test('more than 25 eligible exercises is available without pool capping', () {
    final result = service.evaluate(_topic([_eligibleRange(0, 30)]));

    expect(result.requiredCount, 25);
    expect(result.eligibleCount, 30);
    expect(result.candidates, hasLength(30));
    expect(result.isAvailable, isTrue);
  });

  test('exactly 25 eligible exercises is available', () {
    final result = service.evaluate(_topic([_eligibleRange(0, 25)]));

    expect(result.eligibleCount, 25);
    expect(result.isAvailable, isTrue);
  });

  test('fewer than 25 eligible exercises is unavailable', () {
    final result = service.evaluate(_topic([_eligibleRange(0, 24)]));

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
    final result = service.evaluate(_topic([_eligibleRange(0, 10), invalid]));

    expect(result.eligibleCount, 10);
    expect(result.isAvailable, isFalse);
  });

  test('fewer than six Rounds can still provide an available Duel', () {
    final result = service.evaluate(
      _topic([_eligibleRange(0, 13), _eligibleRange(13, 13)]),
    );

    expect(result.eligibleCount, 26);
    expect(result.isAvailable, isTrue);
  });

  test('six or more Rounds do not make an insufficient pool available', () {
    final result = service.evaluate(
      _topic([
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
      _topic([
        [for (var i = 0; i < 30; i++) duplicate],
      ]),
    );

    expect(result.eligibleCount, 1);
    expect(result.isAvailable, isFalse);
  });

  test('the existing seven supported exercise types remain eligible', () {
    final exercises = [
      for (final type in DuelEligibilityService.supportedExerciseTypes)
        _exercise(type, type: type),
    ];
    final result = service.evaluate(_topic([exercises]));

    expect(
      result.candidates.map((candidate) => candidate.exercise.type).toSet(),
      DuelEligibilityService.supportedExerciseTypes,
    );
    expect(result.candidates.map((candidate) => candidate.round.id).toSet(), {
      'round_0',
    });
  });
}
