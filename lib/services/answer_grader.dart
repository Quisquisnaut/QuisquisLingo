import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'answer_engine.dart';

/// One row of a Match as the learner sees it: the left item (its text, its
/// picture and whether the picture shows several) and the right item that
/// belongs to it.
class MatchRow {
  const MatchRow({
    required this.leftId,
    required this.leftLabel,
    this.leftImage = '',
    this.leftPlural = false,
    required this.rightId,
  });

  final String leftId;
  final String leftLabel;
  final String leftImage;

  /// Whether the left picture shows several (Build 265 Revision 11).
  final bool leftPlural;
  final String rightId;
}

/// One answer a Match row can take, as the learner sees it.
class MatchChoice {
  const MatchChoice(this.id, this.label);

  final String id;
  final String label;
}

/// What a typed answer earned: whether it is right, the accepted answer it
/// matched (shown as the correction), the small differences that were
/// forgiven, and the other accepted answers to show when the exercise shows
/// ranked alternatives (null when it does not).
class TypedAnswerGrade {
  const TypedAnswerGrade({
    required this.isCorrect,
    this.displayedCorrection = '',
    this.acceptedDifferences = const [],
    this.alternatives,
    this.alternativesPartial = false,
  });

  final bool isCorrect;
  final String displayedCorrection;
  final List<String> acceptedDifferences;
  final List<String>? alternatives;
  final bool alternativesPartial;
}

/// Whether a learner's answer is right (Build 273 Revision 2): the one owner
/// of the grading the Round screen did inside its widget. No screen and no
/// storage: an exercise, its features and what the learner did in; a
/// verdict out. The screen keeps what it shows and when; the Duel grades
/// its own single choice.
class AnswerGrader {
  const AnswerGrader([this._engine = const AnswerEngine()]);

  final AnswerEngine _engine;

  /// The text of the item [itemId] of [ex] (its label), or '' when there is
  /// no such item.
  static String itemValue(Exercise ex, String? itemId) {
    if (itemId == null) return '';
    return ex.items
            .where((item) => item.id == itemId)
            .map((item) => item.label)
            .firstOrNull ??
        '';
  }

  /// Blocks joined as the learner built them: without spaces for a word
  /// built from letters, with spaces otherwise.
  static String joinBlocks(ExerciseFeatures f, List<String> blocks) =>
      blocks.join(f.joinsWithoutSpaces ? '' : ' ');

  /// A typed answer ([entered], already trimmed and not empty): an accepted
  /// expression (with the exercise's typo tolerance and normalization),
  /// else a literal answer taken word for word.
  TypedAnswerGrade typed(ExerciseFeatures f, String entered) {
    final accepted = <String>{...f.acceptedAnswers};
    final normalization = f.normalization;
    var evaluation = _engine.evaluate(
      entered,
      accepted,
      normalization: normalization,
      typoTolerance: f.toleratesTypos,
    );
    // Literal answers (a spoken phrase, for instance) are accepted verbatim,
    // never parsed as author expressions.
    if (!evaluation.isCorrect) {
      for (final literal in f.literalAnswers) {
        if (literal.trim().isEmpty) continue;
        final result = _engine.evaluateLiteral(
          entered,
          literal,
          normalization: normalization,
        );
        if (result.isCorrect || accepted.isEmpty) evaluation = result;
        if (result.isCorrect) break;
      }
    }
    List<String>? alternatives;
    var partial = false;
    if (f.showAlternatives == FeedbackAlternatives.ranked) {
      final ranked = _engine.rankedAnswers(
        entered,
        accepted,
        normalization: normalization,
      );
      final matched = _engine.normalizedAnswer(
        evaluation.matchedAcceptedAnswer,
        normalization: normalization,
      );
      final remaining = evaluation.isCorrect
          ? ranked
                .where(
                  (answer) =>
                      _engine.normalizedAnswer(
                        answer,
                        normalization: normalization,
                      ) !=
                      matched,
                )
                .toList()
          : ranked;
      final limit = evaluation.isCorrect ? 2 : 3;
      alternatives = remaining.take(limit).toList();
      partial = remaining.length > limit;
    }
    return TypedAnswerGrade(
      isCorrect: evaluation.isCorrect,
      displayedCorrection: evaluation.matchedAcceptedAnswer,
      acceptedDifferences: evaluation.acceptedDifferences,
      alternatives: alternatives,
      alternativesPartial: partial,
    );
  }

  /// Blocks put in order: right when, joined, they read as one of the
  /// exercise's correct orders.
  bool order(Exercise ex, ExerciseFeatures f, List<String> blocks) {
    final built = joinBlocks(f, blocks);
    return ex.canonicalEvaluation.correctOrders.any(
      (order) => _engine.evaluateLiteral(built, order.text).isCorrect,
    );
  }

  /// Missing words typed into one field per gap ([typed], in the gaps'
  /// order): every gap accepts its text, and there are as many fields as
  /// gaps. Each gap's text is trimmed, as one typed answer is, and
  /// follows the exercise's options for capitals, punctuation, spaces and
  /// accents, and never forgives a typo (Build 273 Revision 3, owner
  /// decision: Missing letters tests spelling); a gap has no literal answers
  /// of its own.
  bool missingWords(ExerciseFeatures f, List<String> typed) {
    final targets = f.gapFieldTargets;
    var correct = typed.length == targets.length;
    for (var i = 0; i < typed.length && i < targets.length; i++) {
      final answers = f.answersFor(targets[i].id);
      if (answers == null ||
          !_engine.accepts(
            typed[i].trim(),
            answers.answers,
            normalization: f.normalization,
            typoTolerance: false,
          )) {
        correct = false;
      }
    }
    return correct;
  }

  /// Gaps filled by choosing an option: every gap holds the item assigned
  /// to it (compared by ID).
  bool selectGaps(ExerciseFeatures f, Map<String, String?> fill) {
    final assignments = f.targetAssignments;
    if (assignments.isEmpty || fill.values.any((v) => v == null)) {
      return false;
    }
    return assignments.entries.every((entry) => fill[entry.key] == entry.value);
  }

  /// Gaps filled with blocks: blocks with the same content are
  /// interchangeable, so a gap is right when its block reads like the one
  /// assigned to it (Build 256, plan A.11).
  bool arrangeGaps(Exercise ex, ExerciseFeatures f, Map<String, String?> fill) {
    final assignments = f.targetAssignments;
    if (assignments.isEmpty || fill.values.any((v) => v == null)) {
      return false;
    }
    return assignments.entries.every(
      (entry) => itemValue(ex, fill[entry.key]) == itemValue(ex, entry.value),
    );
  }

  /// Several answers chosen: exactly the correct ones.
  bool multiChoice(Exercise ex, Set<String> selectedIds) {
    final correctIds = ex.canonicalEvaluation.correctItemIds.toSet();
    return selectedIds.length == correctIds.length &&
        selectedIds.containsAll(correctIds);
  }

  /// exactAssignments: every target holds exactly the items authored for it
  /// (order does not matter); a target with no authored items stays empty.
  bool assign(
    Exercise ex,
    ExerciseFeatures f,
    Map<String, List<String>> placements,
  ) {
    final expected = f.assignmentsByTarget;
    if (expected.isEmpty) return false;
    for (final target in ex.targets) {
      final placed = (placements[target.id] ?? const <String>[]).toSet();
      final wanted = expected[target.id] ?? const <String>{};
      if (placed.length != wanted.length || !placed.containsAll(wanted)) {
        return false;
      }
    }
    return true;
  }

  /// Whether the learner's pairs read as the expected pairs, for Match and
  /// Listen and match alike. A Match may repeat a value (Ciao = Hi, Ciao =
  /// Bye; owner decision of 6 October 2026, Build 265 Revision 4): two rows,
  /// two sounds or two answers then look or sound the same, so whichever of
  /// the identical ones was used is right. Each side is compared as the
  /// learner sees it: a row by its text and picture, an answer by its text;
  /// an item with neither is told apart by its ID.
  bool matching(
    List<MatchRow> rows,
    List<MatchChoice> choices,
    Map<String, String> selections,
  ) {
    final rightLabels = {for (final choice in choices) choice.id: choice.label};
    String leftKey(MatchRow row) =>
        row.leftLabel.isNotEmpty || row.leftImage.isNotEmpty
        // A plural picture looks unlike the same picture alone.
        ? '${row.leftLabel}\u0000${row.leftImage}\u0000${row.leftPlural}'
        : row.leftId;
    String rightKey(String id) {
      final label = rightLabels[id] ?? '';
      return label.isNotEmpty ? label : id;
    }

    final expected = <String, int>{};
    final made = <String, int>{};
    for (final row in rows) {
      final selected = selections[row.leftId];
      if (selected == null) return false;
      final wanted = '${leftKey(row)}\u0001${rightKey(row.rightId)}';
      final given = '${leftKey(row)}\u0001${rightKey(selected)}';
      expected[wanted] = (expected[wanted] ?? 0) + 1;
      made[given] = (made[given] ?? 0) + 1;
    }
    return expected.length == made.length &&
        expected.entries.every((entry) => made[entry.key] == entry.value);
  }
}
