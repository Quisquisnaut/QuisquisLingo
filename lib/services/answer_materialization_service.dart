import 'answer_engine.dart';

class AnswerMaterialization {
  const AnswerMaterialization({
    required this.answers,
    required this.generated,
    required this.added,
  });
  final List<String> answers;
  final int generated;
  final int added;
  int get alreadyPresent => generated - added;
}

/// An explicit, atomic authoring action. No link to the source is retained.
abstract final class AnswerMaterializationService {
  static List<String> expand(
    Iterable<String> expressions, {
    Map<String, dynamic> normalization = const {},
  }) => const AnswerEngine().distinctAnswers(
    AnswerExpressionParser.expandAll(expressions),
    normalization: normalization,
  );

  static AnswerMaterialization materialize({
    required Iterable<String> expressions,
    required List<String> existing,
    Map<String, dynamic> normalization = const {},
  }) {
    const engine = AnswerEngine();
    final generated = expand(expressions, normalization: normalization);
    // Only explicit entries count as already materialized. An expression's
    // answers must remain independently editable after its removal.
    final keys = <String>{
      for (final answer in existing)
        if (!RegExp(r'[{}\[\]()]|<>').hasMatch(answer))
          engine.normalizedAnswer(answer, normalization: normalization),
    };
    final additions = [
      for (final answer in generated)
        if (keys.add(
          engine.normalizedAnswer(answer, normalization: normalization),
        ))
          answer,
    ];
    final candidate = [...existing, ...additions];
    // Validate the complete result before returning anything to the Editor.
    AnswerExpressionParser.expandAll(candidate);
    return AnswerMaterialization(
      answers: List.unmodifiable(candidate),
      generated: generated.length,
      added: additions.length,
    );
  }
}
