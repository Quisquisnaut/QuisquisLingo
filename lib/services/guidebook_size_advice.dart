import '../models/course_models.dart';

/// The GuideBook size that suits the Round Wizard (Build 267 Revision 5,
/// owner decisions of 9 October 2026): advice, never a rule. The Round
/// Wizard needs only three Words & Expressions in a module
/// ([GuidebookRoundGenerator.minimumWords]); these numbers come from how it
/// builds Rounds: three Rounds per module reach about 14 entries of each
/// list, review starts with a Lesson's second module, and an exercise type
/// never asks the same thing twice in a Round.
abstract final class GuidebookSizeAdvice {
  static const minimumModules = 3;
  static const bestModules = 4;
  static const maximumModules = 6;
  static const minimumWords = 5;
  static const bestWords = 8;
  static const maximumWords = 10;
  static const minimumSentences = 2;
  static const maximumSentences = 5;

  /// More entries than this in one list and the default Rounds may leave
  /// some without an exercise.
  static const splitAbove = 12;

  /// The best size, in one sentence.
  static const best =
      'Best: 4 modules per Lesson, each with about 8 Words & Expressions and '
      '3–4 Sentences that use them.';

  /// The modules that have entries: an empty module has its own Warning.
  static int moduleCount(Iterable<GuidebookModule> modules) =>
      modules.where((module) => !module.hasNoEntries).length;

  /// The hint for a Lesson's modules, or null when their number suits.
  static String? lessonHint(Iterable<GuidebookModule> modules) {
    final count = moduleCount(modules);
    if (count == 0) return null;
    if (count == 1) {
      return '1 module: the Rounds will have no review of earlier modules. '
          'Best: 4 modules.';
    }
    if (count < minimumModules) {
      return '$count modules: the Rounds will have little review. Best: 4 '
          'modules.';
    }
    if (count > maximumModules) {
      return '$count modules make a long Lesson: consider splitting it into '
          'two Lessons.';
    }
    return null;
  }

  /// The hint for one module, or null when its size suits.
  static String? moduleHint(GuidebookModule module) => module.hasNoEntries
      ? null
      : hintFor(
          title: module.title,
          words: module.words.length,
          sentences: module.sentences.length,
        );

  /// The hint for a module of [words] Words & Expressions and [sentences]
  /// Sentences (the module page counts them as they are written).
  static String? hintFor({
    required String title,
    required int words,
    required int sentences,
  }) {
    if (words + sentences == 0) return null;
    final name = title.trim().isEmpty ? 'This module' : '“${title.trim()}”';
    if (words > splitAbove || sentences > splitAbove) {
      final what = words > splitAbove
          ? _many(words, 'word')
          : _many(sentences, 'sentence');
      return '$name has $what: some may not get an exercise. Consider '
          'splitting it into two modules.';
    }
    if (words < minimumWords || sentences < minimumSentences) {
      return '$name has ${_many(words, 'word')} and '
          '${_many(sentences, 'sentence')}: some Rounds may repeat '
          'exercises. Best: about 8 words and 3–4 sentences.';
    }
    return null;
  }

  /// Fewer words than this in the Overview: the Module Wizard warns before
  /// Finish (Build 267 Revision 10, owner decision of 9 October 2026).
  static const minimumOverviewWords = 10;

  static final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Words in [text]: pieces between spaces with a letter or a digit.
  static int wordCount(String text) =>
      text.split(RegExp(r'\s+')).where(_letterOrDigit.hasMatch).length;

  /// "8 Words & Expressions · 3 Sentences".
  static String countLine({required int words, required int sentences}) =>
      '$words Words & Expressions · ${_many(sentences, 'Sentence')}';

  static String _many(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';
}
