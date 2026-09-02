import 'course_models.dart';

/// Import-only boundary between a source format and the canonical QQL model.
/// Source-specific labels stop here and never enter learner runtime dispatch.
class NormalizedImportExercise {
  const NormalizedImportExercise({
    required this.sourceType,
    required this.presetId,
    this.prompt = const [],
    required this.interaction,
    required this.evaluation,
    this.hint = '',
  });

  final String sourceType;
  final String presetId;
  final List<PromptElement> prompt;
  final ExerciseInteraction interaction;
  final ExerciseEvaluation evaluation;
  final String hint;

  Exercise toExercise({required String stableId}) => Exercise.v2(
    id: stableId,
    editorTemplate: presetId,
    promptElements: prompt,
    interaction: interaction,
    evaluation: evaluation,
    hint: hint,
  );
}
