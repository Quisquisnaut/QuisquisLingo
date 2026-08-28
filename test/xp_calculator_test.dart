import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/xp_calculator.dart';

void main() {
  const calculator = XpCalculator();

  group('Round awards', () {
    RoundXpResult award({
      required bool completed,
      required int correct,
      required int errors,
      required bool repeat,
      bool firstLaurel = false,
    }) => calculator.calculateRoundAward(
      RoundXpAwardContext(
        completed: completed,
        errorsThisAttempt: errors,
        firstPassCorrect: correct,
        wasCompletedAtStart: repeat,
        newlyEarnedLaurel: firstLaurel,
      ),
    );

    test('first completion partial awards five XP per first-pass correct', () {
      final result = award(
        completed: true,
        correct: 8,
        errors: 2,
        repeat: false,
      );

      expect(result.correctAnswerXp, 40);
      expect(result.perfectBonusXp, 0);
      expect(result.laurelBonusXp, 0);
      expect(result.totalXp, 40);
    });

    test('first completion perfect with first Laurel awards 80 XP', () {
      final result = award(
        completed: true,
        correct: 10,
        errors: 0,
        repeat: false,
        firstLaurel: true,
      );

      expect(result.correctAnswerXp, 50);
      expect(result.perfectBonusXp, 5);
      expect(result.laurelBonusXp, 25);
      expect(result.totalXp, 80);
    });

    test('repeat partial awards two XP per first-pass correct', () {
      expect(
        award(completed: true, correct: 8, errors: 2, repeat: true).totalXp,
        16,
      );
    });

    test('repeat perfect with an existing Laurel awards 25 XP', () {
      final result = award(
        completed: true,
        correct: 10,
        errors: 0,
        repeat: true,
      );

      expect(result.correctAnswerXp, 20);
      expect(result.perfectBonusXp, 5);
      expect(result.laurelBonusXp, 0);
      expect(result.totalXp, 25);
    });

    test('repeat perfect with first Laurel awards 50 XP', () {
      expect(
        award(
          completed: true,
          correct: 10,
          errors: 0,
          repeat: true,
          firstLaurel: true,
        ).totalXp,
        50,
      );
    });

    test('abandoned Round awards no XP or bonuses', () {
      final result = award(
        completed: false,
        correct: 10,
        errors: 0,
        repeat: false,
        firstLaurel: true,
      );

      expect(result.correctAnswerXp, 0);
      expect(result.perfectBonusXp, 0);
      expect(result.laurelBonusXp, 0);
      expect(result.totalXp, 0);
    });

    test('non-evaluable items add no base XP and do not break perfect', () {
      final first = award(
        completed: true,
        correct: 8,
        errors: 0,
        repeat: false,
        firstLaurel: true,
      );
      final repeat = award(
        completed: true,
        correct: 8,
        errors: 0,
        repeat: true,
      );

      expect(first.totalXp, 70);
      expect(repeat.totalXp, 21);
    });

    test('wrong then corrected counts only the other first-pass answers', () {
      expect(
        award(completed: true, correct: 5, errors: 1, repeat: true).totalXp,
        10,
      );
    });

    test(
      'a separately confirmed first Laurel adds 25 XP to a partial repeat',
      () {
        expect(
          award(
            completed: true,
            correct: 5,
            errors: 1,
            repeat: true,
            firstLaurel: true,
          ).totalXp,
          35,
        );
      },
    );

    test('Review partial always uses repeat scoring', () {
      expect(
        award(completed: true, correct: 8, errors: 2, repeat: true).totalXp,
        16,
      );
    });

    test(
      'Review perfect repeats the perfect bonus with no owned-Laurel bonus',
      () {
        expect(
          award(completed: true, correct: 10, errors: 0, repeat: true).totalXp,
          25,
        );
      },
    );

    test('Review can award the first Laurel', () {
      expect(
        award(
          completed: true,
          correct: 10,
          errors: 0,
          repeat: true,
          firstLaurel: true,
        ).totalXp,
        50,
      );
    });
  });

  test('Topic completion awards 25 XP only on first completion', () {
    expect(
      calculator.calculateTopicCompletionAward(isFirstCompletion: true),
      25,
    );
    expect(
      calculator.calculateTopicCompletionAward(isFirstCompletion: false),
      0,
    );
  });

  test('Duel victory awards 50 XP first and 10 XP on repeats', () {
    expect(calculator.calculateDuelWinAward(wasPreviouslyWon: false), 50);
    expect(calculator.calculateDuelWinAward(wasPreviouslyWon: true), 10);
  });
}
