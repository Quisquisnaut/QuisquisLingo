import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'answer_engine.dart';
import 'answer_grader.dart';

/// A text of the learner panel by its key, in the Course's language
/// (`LearnerPanelText.of` on the screen).
typedef PanelText = String Function(String key, [Map<String, Object> values]);

/// The right answer as the Round screen writes it after a wrong answer, in
/// a Test Round's results, and under a typed answer (Build 273 Revision 2).
/// No screen and no storage: an exercise and its features in, a text out;
/// the few words of its own come from [text] (the learner panel).
class CorrectAnswerText {
  const CorrectAnswerText(this.text, [this._engine = const AnswerEngine()]);

  final PanelText text;
  final AnswerEngine _engine;

  /// The first answer an answer expression accepts, else the expression.
  /// The expansion capitalizes a sentence start; a gap keeps the author's
  /// small first letter.
  String firstVariant(String expression) => variantOf(expression, _engine);

  /// [firstVariant] without a learner panel (Build 274 Revision 2: the
  /// answer a learner may hear, `PlaybackOnRequest`).
  static String variantOf(
    String expression, [
    AnswerEngine engine = const AnswerEngine(),
  ]) {
    String variant;
    try {
      variant = engine.validAnswers([expression]).firstOrNull ?? expression;
    } on AnswerExpressionException {
      return expression;
    }
    final letter = RegExp(r'\p{L}', unicode: true);
    final authored = letter.firstMatch(expression)?.group(0);
    final first = letter.firstMatch(variant);
    if (authored == null ||
        first == null ||
        authored != authored.toLowerCase()) {
      return variant;
    }
    return variant.replaceRange(
      first.start,
      first.end,
      first.group(0)!.toLowerCase(),
    );
  }

  /// The right answer to [ex], whose features are [f]. [displayedCorrection]
  /// is the accepted answer a typed answer matched, shown in place of the
  /// first accepted answer.
  String of(
    Exercise ex,
    ExerciseFeatures f, {
    String displayedCorrection = '',
  }) {
    switch (ex.primitive) {
      case ExercisePrimitive.select:
        if (f.hasInlineTargets) return _gapAnswerText(ex, f);
        if (f.multipleSelection) return _selectMultiAnswerText(ex);
        final value = AnswerGrader.itemValue(
          ex,
          ex.canonicalEvaluation.correctItemIds.firstOrNull,
        );
        return value.isEmpty ? text('seeCourseAnswer') : value;
      case ExercisePrimitive.presentation:
        return text('reviewTheFlashcard');
      case ExercisePrimitive.input:
        if (f.gapFieldTargets.isNotEmpty) {
          // The first answer each gap accepts, written out: a gap answer
          // may use the answer syntax, such as [il|un] gatto (Build 259
          // Revision 3).
          final words = [
            for (final target in f.gapFieldTargets)
              ...?f.answersFor(target.id)?.answers.take(1).map(firstVariant),
          ];
          if (words.isNotEmpty) return words.join(' / ');
          break;
        }
        if (displayedCorrection.isNotEmpty) return displayedCorrection;
        // Written from audio: the authored answer first, then the spoken
        // text; otherwise the spoken text is the fuller answer.
        final candidates = f.kind == LearnerExerciseKind.inputListenWrite
            ? [...f.acceptedAnswers, ...f.literalAnswers]
            : [...f.literalAnswers, ...f.acceptedAnswers];
        final first = candidates
            .map((answer) => answer.trim())
            .where((answer) => answer.isNotEmpty)
            .firstOrNull;
        if (first != null) return first;
        break;
      case ExercisePrimitive.arrange:
        if (f.hasInlineTargets) return _gapAnswerText(ex, f);
        final orders = ex.canonicalEvaluation.correctOrders;
        if (orders.isEmpty) break;
        if (f.showAlternatives == FeedbackAlternatives.all) {
          return orders.map((order) => order.text).join(' / ');
        }
        final joined = orderText(ex, f, orders.first);
        if (joined.isNotEmpty) return joined;
        break;
      case ExercisePrimitive.match:
        final pairs = pairTexts(ex);
        if (pairs.isNotEmpty) {
          return pairs.map((pair) => '${pair[0]} = ${pair[1]}').join('; ');
        }
        break;
      case ExercisePrimitive.assign:
        final answer = assignText(ex, {
          for (final entry in f.assignmentsByTarget.entries)
            entry.key: entry.value.toList(),
        });
        if (answer.isNotEmpty) return answer;
        break;
      case ExercisePrimitive.speak:
      case ExercisePrimitive.ink:
      case ExercisePrimitive.submit:
        break;
    }
    return text('seeCourseAnswer');
  }

  /// An ordered answer as the learner would build it: its blocks joined
  /// with the exercise's joiner.
  static String orderText(
    Exercise ex,
    ExerciseFeatures f,
    OrderedAnswer order,
  ) => AnswerGrader.joinBlocks(f, [
    for (final id in order.itemIds)
      if (AnswerGrader.itemValue(ex, id) case final value when value.isNotEmpty)
        value,
  ]);

  /// The Match relations as [left value, right value] pairs.
  static List<List<String>> pairTexts(Exercise ex) => [
    for (final pair in ex.canonicalEvaluation.relations)
      if (pair.length == 2)
        [
          AnswerGrader.itemValue(ex, pair[0]),
          AnswerGrader.itemValue(ex, pair[1]),
        ],
  ];

  String _gapAnswerText(Exercise ex, ExerciseFeatures f) {
    final assignments = f.targetAssignments;
    if (assignments.isEmpty) return text('seeCourseAnswer');
    return assignments.entries
        .map((entry) => AnswerGrader.itemValue(ex, entry.value))
        .where((value) => value.isNotEmpty)
        .join(' ');
  }

  String _selectMultiAnswerText(Exercise ex) {
    final correctIds = ex.canonicalEvaluation.correctItemIds.toSet();
    final values = ex.items
        .where((item) => correctIds.contains(item.id))
        .map((item) => item.value)
        .where((value) => value.isNotEmpty)
        .toList();
    return values.isEmpty ? text('seeCourseAnswer') : values.join(' / ');
  }

  /// "Animals: gatto, cane · Plants: rosa" for the given placements; targets
  /// are named by their layout label, else by their position.
  String assignText(Exercise ex, Map<String, List<String>> placements) {
    final f = ExerciseFeatures(ex);
    final parts = <String>[];
    for (var i = 0; i < ex.targets.length; i++) {
      final target = ex.targets[i];
      final items = (placements[target.id] ?? const <String>[])
          .map((id) => AnswerGrader.itemValue(ex, id))
          .where((value) => value.isNotEmpty)
          .toList();
      if (items.isEmpty) continue;
      final label = f.targetLabel(target.id);
      parts.add(
        '${label.isEmpty ? targetFallbackLabel(f, i) : label}: ${items.join(', ')}',
      );
    }
    return parts.join(' · ');
  }

  /// A target without a label of its own: "Slot 2", "Gap 2", "Group 2".
  String targetFallbackLabel(ExerciseFeatures f, int index) =>
      switch (f.assignTargetMode) {
        AssignTargetMode.slots => text('slotNumber', {'n': index + 1}),
        AssignTargetMode.gaps => text('gapNumber', {'n': index + 1}),
        _ => text('groupNumber', {'n': index + 1}),
      };
}
