import 'dart:math';

import '../models/course_models.dart';

/// One answer of a Test Round, for its results page: right or wrong, and
/// the right answer when it was wrong.
typedef TestResult = ({bool correct, String correction});

/// A Test Round's score: the share of right answers, rounded, and whether
/// the Test is passed (its threshold reached, or, without one, every answer
/// right).
typedef TestScore = ({int percent, bool passed});

/// One attempt at a Round (Build 273 Revision 4 of the plan, Revision 5 of
/// Build 273): which exercises come and in which order, where the learner
/// is, the review of the mistakes of the first pass, and what the attempt
/// counts for its completion (errors, right answers at the first try and
/// their difficulty, a Test's results).
///
/// No Flutter: the Round screen asks it what comes next and tells it each
/// answer; the dialogs, the Timed clock and the completion are the
/// screen's. Shuffles use the [Random] the screen gives it, so they draw
/// from the same source as the screen's other shuffles.
class RoundAttempt {
  RoundAttempt(this._random);

  final Random _random;
  List<int> _queue = [];
  int _position = 0;
  bool _reviewPhase = false;
  final Set<int> _wrongFirstPass = {};
  int _firstPassCorrect = 0;
  int _firstPassDifficulty = 0;
  int _errors = 0;
  final List<TestResult> _testResults = [];

  /// The exercises still to come in this pass, by their index in the
  /// Round, in the order they are played.
  List<int> get queue => List.unmodifiable(_queue);

  /// How many exercises this pass holds.
  int get length => _queue.length;

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;

  /// The place of the exercise shown in this pass.
  int get position => _position;

  /// The index in the Round of the exercise shown.
  int get exerciseIndex => _queue[_position];

  /// The second pass, over the mistakes of the first.
  bool get reviewPhase => _reviewPhase;

  /// Wrong answers in this attempt, review included.
  int get errors => _errors;

  /// Right answers at the first try.
  int get firstPassCorrect => _firstPassCorrect;

  /// The difficulty of the exercises answered right at the first try,
  /// summed (Build 260 Revision 6).
  int get firstPassDifficulty => _firstPassDifficulty;

  /// Some exercise was answered wrong at the first try.
  bool get hasMistakes => _wrongFirstPass.isNotEmpty;

  /// A Test Round's results, one per answer, in order.
  List<TestResult> get testResults => List.unmodifiable(_testResults);

  /// The exercises of the attempt, in the order given ([queue] as the
  /// Round screen filtered it).
  void start(List<int> queue) {
    _queue = [...queue];
    _position = 0;
  }

  /// Plays the exercises in a random order (a practice Round, a Test
  /// without fixed order).
  void shuffle() => _shuffle(_queue);

  /// Nothing is played (the Round could not be prepared).
  void clear() => _queue = [];

  /// Another exercise follows in this pass.
  bool get hasNext => _position + 1 < _queue.length;

  /// The next exercise of this pass.
  void advance() => _position++;

  /// The answer to the exercise shown: right or wrong. At the first try a
  /// right answer counts with its [difficulty] and a wrong one is reviewed
  /// later. A [testCorrection] (Test Rounds only) records the answer for
  /// the results: empty when right, the right answer when wrong.
  void record({
    required bool correct,
    required int difficulty,
    String? testCorrection,
  }) {
    if (!correct) _errors++;
    if (!_reviewPhase) {
      if (correct) {
        _firstPassCorrect++;
        _firstPassDifficulty += difficulty;
      } else {
        _wrongFirstPass.add(exerciseIndex);
      }
    }
    if (testCorrection != null) {
      _testResults.add((correct: correct, correction: testCorrection));
    }
  }

  /// The answer just given is the attempt's last: no exercise follows and
  /// no review of mistakes will.
  bool get answeredLast =>
      _position + 1 == _queue.length &&
      (_reviewPhase || _wrongFirstPass.isEmpty);

  /// The exercise shown comes again at the end of this pass (a Flashcard
  /// the learner wants to see again).
  void againLater() => _queue.add(exerciseIndex);

  /// After the first pass, its mistakes are played again: never in a Round
  /// played in order (a Story, a sequence) or a Test.
  bool reviewsMistakes({required bool playsInOrder, required RoundType type}) =>
      !_reviewPhase &&
      _wrongFirstPass.isNotEmpty &&
      !playsInOrder &&
      type != RoundType.test;

  /// The exercise shown is the first pass's last and mistakes will be
  /// reviewed after it.
  bool get reviewFollows =>
      !_reviewPhase &&
      _position + 1 == _queue.length &&
      _wrongFirstPass.isNotEmpty;

  /// The second pass starts: the first pass's mistakes, in a random order.
  void startReview() {
    _reviewPhase = true;
    _queue = _wrongFirstPass.toList();
    _shuffle(_queue);
    _position = 0;
  }

  /// A Test Round's score with its passing [threshold] (a percentage, or
  /// none).
  TestScore testScore(int? threshold) {
    final percent = _testResults.isEmpty
        ? 0
        : (100 *
                  _testResults.where((r) => r.correct).length /
                  _testResults.length)
              .round();
    final passed =
        _testResults.isNotEmpty &&
        (threshold == null
            ? _testResults.every((r) => r.correct)
            : percent >= threshold);
    return (percent: percent, passed: passed);
  }

  void _shuffle(List<int> values) {
    if (values.length < 2) return;
    // A valid random shuffle may legitimately reproduce the source order.
    values.shuffle(_random);
  }
}
