import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/xp_calculator.dart';

void main() {
  const calculator = XpCalculator();

  group('Round awards', () {
    test('normal first completion awards five XP per first-pass correct', () {
      expect(
        calculator.calculateRoundAward(
          const RoundXpAwardContext(
            errorsThisAttempt: 0,
            firstPassCorrect: 3,
            repeatCapExerciseCount: 7,
            wasCompletedAtStart: false,
          ),
        ),
        15,
      );
    });

    test('completion with errors uses first-pass-correct scoring', () {
      expect(
        calculator.calculateRoundAward(
          const RoundXpAwardContext(
            errorsThisAttempt: 2,
            firstPassCorrect: 2,
            repeatCapExerciseCount: 100,
            wasCompletedAtStart: false,
          ),
        ),
        10,
      );
    });

    test('imperfect repeat still uses first-pass-correct scoring', () {
      expect(
        calculator.calculateRoundAward(
          const RoundXpAwardContext(
            errorsThisAttempt: 1,
            firstPassCorrect: 5,
            repeatCapExerciseCount: 6,
            wasCompletedAtStart: true,
          ),
        ),
        25,
      );
    });

    test('perfect repeat halves the mutable queue cap and floors odd XP', () {
      expect(
        calculator.calculateRoundAward(
          const RoundXpAwardContext(
            errorsThisAttempt: 0,
            firstPassCorrect: 99,
            repeatCapExerciseCount: 3,
            wasCompletedAtStart: true,
          ),
        ),
        7,
      );
    });

    test('zero presented exercises awards zero XP', () {
      expect(
        calculator.calculateRoundAward(
          const RoundXpAwardContext(
            errorsThisAttempt: 0,
            firstPassCorrect: 0,
            repeatCapExerciseCount: 0,
            wasCompletedAtStart: false,
          ),
        ),
        0,
      );
    });
  });

  test('perfect potential preserves first and repeat display formulas', () {
    expect(
      calculator.calculatePerfectRoundPotential(
        exerciseCount: 6,
        wasCompletedAtStart: false,
      ),
      30,
    );
    expect(
      calculator.calculatePerfectRoundPotential(
        exerciseCount: 6,
        wasCompletedAtStart: true,
      ),
      15,
    );
  });

  test('Topic completion award remains 25 XP on every invocation', () {
    expect(calculator.calculateTopicCompletionAward(), 25);
    expect(calculator.calculateTopicCompletionAward(), 25);
  });

  test('Duel win award remains 50 XP on every invocation', () {
    expect(calculator.calculateDuelWinAward(), 50);
    expect(calculator.calculateDuelWinAward(), 50);
  });
}
