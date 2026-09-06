import 'package:flutter/widgets.dart' show StringCharacters;
import 'answer_engine.dart';

/// The revealed grapheme is derived from complete canonical answers; this
/// service assembles a response and delegates all correctness decisions.
abstract final class FirstLetterAnswerService {
  static String initial(Iterable<String> expressions) {
    final answers = AnswerExpressionParser.expandAll(expressions);
    final first = answers.first.trim().characters.first;
    if (answers.any((answer) => answer.trim().characters.first != first)) {
      throw const AnswerExpressionException(
        'All accepted words must share the same first letter (Unicode grapheme). These answers cannot share one pre-revealed first letter.',
      );
    }
    if (answers.any((answer) => RegExp(r'\s').hasMatch(answer.trim()))) {
      throw const AnswerExpressionException(
        'Enter complete words, not phrases, for Type the missing word.',
      );
    }
    return first;
  }

  static String display(String sentence, Iterable<String> expressions) {
    if (RegExp(r'_{3,}').allMatches(sentence).length != 1) {
      throw const AnswerExpressionException(
        'Use exactly one ___ gap in the sentence. The first letter is supplied automatically.',
      );
    }
    return sentence.replaceFirst(
      RegExp(r'_{3,}'),
      '${initial(expressions)}______',
    );
  }

  static String response(String remainder, Iterable<String> expressions) =>
      '${initial(expressions)}${remainder.trim()}';
}
