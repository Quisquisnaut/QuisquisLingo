import 'course_models.dart';

/// Import-only boundary between a source format and the canonical QQL model
/// (Build 256 Revision 6): an external exercise already expressed as
/// primitive, options, prompt, items, targets, layout, evaluation and
/// feedback. Source-specific labels stop here and never enter learner
/// runtime dispatch; a preset is at most a hint, recorded by
/// `CanonicalExerciseImport` only when QQL's recipe represents the result.
class NormalizedImportExercise {
  const NormalizedImportExercise({
    required this.sourceType,
    required this.primitive,
    this.options = const {},
    this.prompt = const [],
    this.items = const [],
    this.targets = const [],
    this.layout = const [],
    required this.evaluation,
    this.feedback = ExerciseFeedback.empty,
    this.hint = '',
    this.presetHint,
  });

  final String sourceType;
  final ExercisePrimitive primitive;
  final Map<OptionKey, OptionValue> options;
  final List<PromptElement> prompt;
  final List<ExerciseItem> items;
  final List<ExerciseTarget> targets;
  final List<LayoutElement> layout;
  final CanonicalEvaluation evaluation;
  final ExerciseFeedback feedback;
  final String hint;

  /// What the source tool would call the exercise in QQL's catalogue, if
  /// anything; never required.
  final String? presetHint;

  /// The canonical exercise: no source label and no preset survive here.
  Exercise toExercise({
    required String stableId,
    required DateTime updatedAt,
  }) => Exercise.canonical(
    id: stableId,
    updatedAt: updatedAt,
    primitive: primitive,
    options: PrimitiveOptions(options),
    promptElements: prompt,
    items: items,
    targets: targets,
    layout: layout,
    canonicalEvaluation: evaluation,
    feedback: feedback,
    hint: hint,
  );
}
