import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/learner_panel/learner_panel_catalogs.dart';
import 'package:quisquislingo_app/services/xp_calculator.dart';

/// Build 260 Revision 6 (owner decisions of 1 October 2026): on a Round's
/// first completion, each exercise answered correctly at the first attempt
/// adds 1 XP per difficulty level; repeats and Review add none.

void main() {
  const calculator = XpCalculator();

  RoundXpResult award({
    bool completed = true,
    required int correct,
    int errors = 0,
    bool repeat = false,
    bool firstLaurel = false,
    int? evaluable,
    required int difficulty,
  }) => calculator.calculateRoundAward(
    RoundXpAwardContext(
      completed: completed,
      errorsThisAttempt: errors,
      firstPassCorrect: correct,
      wasCompletedAtStart: repeat,
      newlyEarnedLaurel: firstLaurel,
      evaluableExerciseCount: evaluable,
      firstPassDifficulty: difficulty,
    ),
  );

  test('the first completion adds 1 XP per level of the right answers', () {
    // Six exercises of levels 1, 2, 3, 4, 2 and 1, all right the first time.
    final result = award(correct: 6, difficulty: 13, firstLaurel: true);
    expect(result.correctAnswerXp, 30);
    expect(result.perfectBonusXp, 5);
    expect(result.laurelBonusXp, 25);
    expect(result.difficultyBonusXp, 13);
    expect(result.totalXp, 73);
  });

  test('only the right answers count, as their caller sums them', () {
    // Two of the six were wrong: their levels are not in the sum.
    final result = award(correct: 4, errors: 2, difficulty: 8);
    expect(result.difficultyBonusXp, 8);
    expect(result.totalXp, 28);
  });

  test('repeats and Review add no Difficulty bonus', () {
    final result = award(correct: 6, repeat: true, difficulty: 13);
    expect(result.difficultyBonusXp, 0);
    expect(result.totalXp, 6 * 2 + 5);
  });

  test('an unfinished Round or one without a scored exercise adds none', () {
    expect(
      award(completed: false, correct: 3, difficulty: 6).difficultyBonusXp,
      0,
    );
    expect(award(correct: 0, evaluable: 0, difficulty: 0).difficultyBonusXp, 0);
  });

  test('a caller that states no difficulty gets the earlier awards', () {
    final result = calculator.calculateRoundAward(
      const RoundXpAwardContext(
        completed: true,
        errorsThisAttempt: 0,
        firstPassCorrect: 6,
        wasCompletedAtStart: false,
        newlyEarnedLaurel: false,
      ),
    );
    expect(result.difficultyBonusXp, 0);
    expect(result.totalXp, 35);
  });

  test('the summary line exists in the seven learner panel languages', () {
    for (final catalog in learnerPanelCatalogs.values) {
      expect(catalog['summary.difficultyBonus'], contains('+{xp} XP'));
    }
  });
}
