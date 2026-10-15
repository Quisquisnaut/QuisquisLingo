import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/answer_grader.dart';
import 'package:quisquislingo_app/services/correct_answer_text.dart';

/// Build 273 Revision 2: `AnswerGrader` and `CorrectAnswerText`, the
/// grading and the right answer the Round screen worked out inside its
/// widget. The screen's own cases stay in the Round screen tests
/// (match_repeated_values_265_test,
/// select_gap_fill_238_test, arrange_gap_fill_238_test,
/// first_letter_226_03_test, runtime_canonical_256_test and the others),
/// which pass before and after; these pin each rule on the owner.
final Course _lab = Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Exercise _ex(String id) => _lab.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.content)
    .firstWhere((content) => content.id == id)
    .exercise!;

String _text(String key, [Map<String, Object> values = const {}]) =>
    values.isEmpty ? '<$key>' : '<$key ${values.values.join(',')}>';

void main() {
  const grader = AnswerGrader();
  const answers = CorrectAnswerText(_text);

  group('typed', () {
    test('an accepted expression, with ranked alternatives', () {
      final ex = _ex('qql_lab254_input_alternatives');
      final f = ExerciseFeatures(ex);
      final right = grader.typed(f, 'il bimbo è contento');
      expect(right.isCorrect, isTrue);
      expect(right.displayedCorrection, isNotEmpty);
      // Four accepted answers: the matched one aside, two more are shown
      // after a right answer and three after a wrong one, each time with
      // more left unshown.
      expect(right.alternatives, hasLength(2));
      expect(right.alternativesPartial, isTrue);
      final wrong = grader.typed(f, 'il cane è felice');
      expect(wrong.isCorrect, isFalse);
      expect(wrong.alternatives, hasLength(3));
      expect(wrong.alternativesPartial, isTrue);
    });

    test('a doubled letter is forgiven with the exercise tolerance', () {
      final f = ExerciseFeatures(_ex('qql_lab254_type_source_literal'));
      expect(f.toleratesTypos, isTrue);
      expect(grader.typed(f, 'thannk you').isCorrect, isTrue);
      // Another kind of typo is not forgiven.
      expect(grader.typed(f, 'thsnk you').isCorrect, isFalse);
    });

    test('a literal answer is taken word for word; no alternatives', () {
      final f = ExerciseFeatures(_ex('qql_lab254_input_listen_word'));
      expect(f.showAlternatives, isNot(FeedbackAlternatives.ranked));
      final grade = grader.typed(f, 'Grazie.');
      expect(grade.isCorrect, isTrue);
      expect(grade.alternatives, isNull);
      expect(grader.typed(f, 'Prego.').isCorrect, isFalse);
    });
  });

  test('order: blocks joined read as one of the correct orders', () {
    final ex = _ex('qql_lab254_build_multiple');
    final f = ExerciseFeatures(ex);
    expect(grader.order(ex, f, ['mangio', 'pane']), isTrue);
    expect(grader.order(ex, f, ['Io', 'mangio', 'pane']), isTrue);
    expect(grader.order(ex, f, ['pane', 'mangio']), isFalse);
    expect(AnswerGrader.joinBlocks(f, ['Io', 'mangio']), 'Io mangio');
  });

  test('missingWords: every gap, as many fields as gaps, no typos', () {
    final f = ExerciseFeatures(_ex('qql_lab254_input_missing_many'));
    expect(grader.missingWords(f, ['legge', 'libro', 'giardino']), isTrue);
    expect(grader.missingWords(f, ['legge', 'libro', 'giardini']), isFalse);
    // A doubled letter, which a typed answer may forgive, is not forgiven.
    expect(grader.missingWords(f, ['legge', 'libro', 'giarddino']), isFalse);
    expect(grader.missingWords(f, ['legge', 'libro']), isFalse);
    expect(
      grader.missingWords(f, ['legge', 'libro', 'giardino', 'x']),
      isFalse,
    );
  });

  group('gaps', () {
    final ex = _ex('qql_lab254_arrange_gap_repeat');
    final f = ExerciseFeatures(ex);
    const first = 'qql_lab254_arrange_gap_repeat_item_0';
    const second = 'qql_lab254_arrange_gap_repeat_item_1';

    test('blocks: two identical blocks fill either gap', () {
      expect(
        grader.arrangeGaps(ex, f, {'gap_1': first, 'gap_2': second}),
        isTrue,
      );
      expect(
        grader.arrangeGaps(ex, f, {'gap_1': second, 'gap_2': first}),
        isTrue,
      );
      expect(
        grader.arrangeGaps(ex, f, {
          'gap_1': 'qql_lab254_arrange_gap_repeat_item_2',
          'gap_2': second,
        }),
        isFalse,
      );
      expect(
        grader.arrangeGaps(ex, f, {'gap_1': first, 'gap_2': null}),
        isFalse,
      );
    });

    test('chosen options are compared by ID (a difference kept)', () {
      expect(grader.selectGaps(f, {'gap_1': first, 'gap_2': second}), isTrue);
      expect(grader.selectGaps(f, {'gap_1': second, 'gap_2': first}), isFalse);
      expect(grader.selectGaps(f, {'gap_1': first, 'gap_2': null}), isFalse);
    });
  });

  test('multiChoice: exactly the correct answers', () {
    final ex = _ex('qql_lab254_select_multiple');
    const red = 'qql_lab254_select_multiple_item_0';
    const blue = 'qql_lab254_select_multiple_item_1';
    expect(grader.multiChoice(ex, {red, blue}), isTrue);
    expect(grader.multiChoice(ex, {red}), isFalse);
    expect(
      grader.multiChoice(ex, {red, blue, 'qql_lab254_select_multiple_item_2'}),
      isFalse,
    );
  });

  test('assign: every group holds exactly its items, in any order', () {
    final ex = _ex('qql_lab254_assign_groups');
    final f = ExerciseFeatures(ex);
    const animals = 'qql_lab254_assign_groups_animals';
    const plants = 'qql_lab254_assign_groups_plants';
    String item(String word) => 'qql_lab254_assign_groups_$word';
    expect(
      grader.assign(ex, f, {
        animals: [item('cane'), item('gatto')],
        plants: [item('pino'), item('rosa')],
      }),
      isTrue,
    );
    expect(
      grader.assign(ex, f, {
        animals: [item('cane'), item('gatto'), item('rosa')],
        plants: [item('pino')],
      }),
      isFalse,
    );
    expect(grader.assign(ex, f, const {}), isFalse);
  });

  group('matching', () {
    const rows = [
      MatchRow(leftId: 'l1', leftLabel: 'Ciao', rightId: 'r1'),
      MatchRow(leftId: 'l2', leftLabel: 'Ciao', rightId: 'r2'),
      MatchRow(leftId: 'l3', leftLabel: 'Grazie', rightId: 'r3'),
    ];
    const choices = [
      MatchChoice('r1', 'Hi'),
      MatchChoice('r2', 'Bye'),
      MatchChoice('r3', 'Thanks'),
    ];

    test('two identical rows take either of their answers', () {
      expect(
        grader.matching(rows, choices, {'l1': 'r1', 'l2': 'r2', 'l3': 'r3'}),
        isTrue,
      );
      expect(
        grader.matching(rows, choices, {'l1': 'r2', 'l2': 'r1', 'l3': 'r3'}),
        isTrue,
      );
    });

    test('the same answer twice is wrong; a row without one is wrong', () {
      expect(
        grader.matching(rows, choices, {'l1': 'r1', 'l2': 'r1', 'l3': 'r3'}),
        isFalse,
      );
      expect(grader.matching(rows, choices, {'l1': 'r1', 'l3': 'r3'}), isFalse);
    });

    test('a plural picture is not the same row as the picture alone', () {
      const pictures = [
        MatchRow(
          leftId: 'p1',
          leftLabel: '',
          leftImage: 'assets/x.webp',
          rightId: 'one',
        ),
        MatchRow(
          leftId: 'p2',
          leftLabel: '',
          leftImage: 'assets/x.webp',
          leftPlural: true,
          rightId: 'many',
        ),
      ];
      const words = [MatchChoice('one', 'cat'), MatchChoice('many', 'cats')];
      expect(
        grader.matching(pictures, words, {'p1': 'many', 'p2': 'one'}),
        isFalse,
      );
    });

    test(
      'no rows read as right (Listen and match has no guard of its own)',
      () {
        expect(grader.matching(const [], const [], const {}), isTrue);
      },
    );
  });

  group('CorrectAnswerText', () {
    test('firstVariant keeps a gap\'s small first letter', () {
      expect(answers.firstVariant('[il|un] gatto'), 'il gatto');
      expect(answers.firstVariant('Ciao'), 'Ciao');
      expect(answers.firstVariant('[unclosed'), '[unclosed');
    });

    test('the right answer of each kind', () {
      String of(String id, {String displayed = ''}) {
        final ex = _ex(id);
        return answers.of(
          ex,
          ExerciseFeatures(ex),
          displayedCorrection: displayed,
        );
      }

      expect(of('qql_lab254_match_single'), 'ciao = hello');
      expect(of('qql_lab254_arrange_zero'), 'Il gatto dorme');
      expect(of('qql_lab254_build_multiple'), 'mangio pane / Io mangio pane');
      expect(of('qql_lab254_select_multiple'), 'rosso / blu');
      expect(of('qql_lab254_input_missing_many'), 'legge / libro / giardino');
      expect(of('qql_lab254_input_listen_word'), 'Grazie.');
      expect(
        of('qql_lab254_type_source_literal', displayed: 'thanks'),
        'thanks',
      );
      expect(of('qql_lab254_card_minimal'), '<reviewTheFlashcard>');
      expect(
        of('qql_lab254_assign_groups'),
        'Animals: gatto, cane · Plants: rosa, pino',
      );
    });

    test('assign text and the fallback label of a target', () {
      final ex = _ex('qql_lab254_assign_slots');
      final f = ExerciseFeatures(ex);
      expect(answers.targetFallbackLabel(f, 1), '<slotNumber 2>');
      expect(answers.assignText(ex, const {}), '');
    });
  });
}
