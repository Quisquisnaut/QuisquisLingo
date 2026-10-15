import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/round_attempt.dart';

/// Build 273 Revision 5: one attempt at a Round has an owner. The Round
/// screen's own cases (`test_round_attempt_test`,
/// `round_xp_completion_regression_test`, `timed_round_261_test`,
/// `timed_round_screen_272_test`, `celebrations_264_test`,
/// `difficulty_bonus_260_test` and the others) pass before and after; these
/// pin each rule on the owner.
void main() {
  RoundAttempt attempt([List<int> queue = const [0, 1, 2]]) =>
      RoundAttempt(Random(7))..start(queue);

  test('the exercises come in the order given, one after another', () {
    final a = attempt();
    expect(a.length, 3);
    expect(a.position, 0);
    expect(a.exerciseIndex, 0);
    expect(a.hasNext, isTrue);
    a.advance();
    a.advance();
    expect(a.exerciseIndex, 2);
    expect(a.hasNext, isFalse);
    expect(a.queue, [0, 1, 2]);
    expect(() => a.queue.add(9), throwsUnsupportedError);
  });

  test('start again replaces the order and goes back to the first', () {
    final a = attempt()..advance();
    a.start([2, 0]);
    expect(a.queue, [2, 0]);
    expect(a.position, 0);
  });

  test('a shuffle draws from the Random it was given, as the screen did', () {
    final source = List.generate(12, (i) => i);
    final a = attempt(source)..shuffle();
    // The Round screen shuffled its queue with `values.shuffle(_random)`.
    expect(a.queue, List.of(source)..shuffle(Random(7)));
    expect(a.queue.toSet(), Set.of(source));
    a.clear();
    expect(a.isEmpty, isTrue);
  });

  test('a first pass counts right answers, their difficulty and errors', () {
    final a = attempt();
    a.record(correct: true, difficulty: 3);
    a.advance();
    a.record(correct: false, difficulty: 4);
    a.advance();
    a.record(correct: true, difficulty: 1);
    expect(a.firstPassCorrect, 2);
    expect(a.firstPassDifficulty, 4);
    expect(a.errors, 1);
    expect(a.hasMistakes, isTrue);
    expect(a.testResults, isEmpty);
  });

  test(
    'the review replays the first pass\'s mistakes and counts errors only',
    () {
      final a = attempt([5, 6, 7]);
      a.record(correct: false, difficulty: 2);
      a.advance();
      a.record(correct: true, difficulty: 2);
      a.advance();
      a.record(correct: false, difficulty: 2);
      expect(a.answeredLast, isFalse);
      expect(a.reviewFollows, isTrue);
      expect(
        a.reviewsMistakes(playsInOrder: false, type: RoundType.practice),
        isTrue,
      );
      a.startReview();
      expect(a.reviewPhase, isTrue);
      expect(a.position, 0);
      expect(a.queue.toSet(), {5, 7});
      a.record(correct: false, difficulty: 9);
      a.advance();
      a.record(correct: true, difficulty: 9);
      expect(a.firstPassCorrect, 1);
      expect(a.firstPassDifficulty, 2);
      expect(a.errors, 3);
      expect(a.answeredLast, isTrue);
      expect(a.reviewFollows, isFalse);
      expect(
        a.reviewsMistakes(playsInOrder: false, type: RoundType.practice),
        isFalse,
      );
    },
  );

  test('no review in a Round played in order or a Test', () {
    final a = attempt([0])..record(correct: false, difficulty: 1);
    expect(
      a.reviewsMistakes(playsInOrder: true, type: RoundType.practice),
      isFalse,
    );
    expect(
      a.reviewsMistakes(playsInOrder: false, type: RoundType.test),
      isFalse,
    );
    expect(
      a.reviewsMistakes(playsInOrder: false, type: RoundType.timed),
      isTrue,
    );
  });

  test('the last answer of an attempt without mistakes', () {
    final a = attempt([0, 1]);
    a.record(correct: true, difficulty: 1);
    expect(a.answeredLast, isFalse);
    a.advance();
    a.record(correct: true, difficulty: 1);
    expect(a.answeredLast, isTrue);
  });

  test('a card seen again comes back at the end of the pass', () {
    final a = attempt([0, 1]);
    a.againLater();
    expect(a.queue, [0, 1, 0]);
    expect(a.hasNext, isTrue);
  });

  group('a Test', () {
    TestScore score(List<bool> answers, int? threshold) {
      final a = attempt(List.generate(answers.length, (i) => i));
      for (final correct in answers) {
        a.record(
          correct: correct,
          difficulty: 1,
          testCorrection: correct ? '' : 'the answer',
        );
        if (a.hasNext) a.advance();
      }
      return a.testScore(threshold);
    }

    test('keeps its results in order, with the right answer when wrong', () {
      final a = attempt([0, 1]);
      a.record(correct: true, difficulty: 1, testCorrection: '');
      a.advance();
      a.record(correct: false, difficulty: 1, testCorrection: 'il gatto');
      expect(a.testResults, [
        (correct: true, correction: ''),
        (correct: false, correction: 'il gatto'),
      ]);
    });

    test('without a threshold it is passed only with every answer right', () {
      expect(score([true, true], null), (percent: 100, passed: true));
      expect(score([true, false], null), (percent: 50, passed: false));
    });

    test('with a threshold the rounded percentage decides', () {
      expect(score([true, true, false], 67), (percent: 67, passed: true));
      expect(score([true, true, false], 70), (percent: 67, passed: false));
    });

    test('no answer, no pass', () {
      expect(attempt([]).testScore(null), (percent: 0, passed: false));
      expect(attempt([]).testScore(0), (percent: 0, passed: false));
    });
  });
}
