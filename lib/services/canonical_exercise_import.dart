import '../models/course_models.dart';
import '../models/normalized_import_exercise.dart';
import 'preset_recipes.dart';

/// What adopting one normalized exercise produced (Build 256 Revision 6).
final class CanonicalImportResult {
  const CanonicalImportResult({
    required this.exercise,
    required this.violations,
    required this.support,
    this.presetId,
    this.hintRejected = false,
  });

  /// The canonical exercise, with `authoringMetadata.presetId` only when the
  /// hint was confirmed.
  final Exercise exercise;

  /// The registry's objections; an exercise with any is invalid.
  final List<CapabilityViolation> violations;

  /// Whether this version of QQL plays it (never stored).
  final ExerciseRuntimeSupport support;

  /// The preset recorded, if any.
  final String? presetId;

  /// True when the source named a preset QQL's recipe does not represent
  /// the result with: the exercise is kept without preset metadata.
  final bool hintRejected;

  bool get isValid => violations.isEmpty;
}

/// Adopts external exercises expressed in canonical terms (plan Part D:
/// presets as hints only). The exercise is built from the normalized data
/// alone; the registry validates it; the preset hint is recorded only when
/// `PresetRecipes.represents` confirms that the preset's form can hold the
/// exercise with nothing lost. Recognition never changes the content.
class CanonicalExerciseImport {
  const CanonicalExerciseImport();

  CanonicalImportResult adopt(
    NormalizedImportExercise normalized, {
    required String stableId,
    required DateTime updatedAt,
  }) {
    final exercise = normalized.toExercise(
      stableId: stableId,
      updatedAt: updatedAt,
    );
    final violations = PrimitiveCapabilityRegistry.validate(
      primitive: exercise.primitive,
      options: exercise.options,
      evaluationMode: exercise.canonicalEvaluation.mode,
    );
    final hint = normalized.presetHint?.trim();
    final confirmed =
        hint != null &&
        hint.isNotEmpty &&
        violations.isEmpty &&
        PresetRecipes.represents(exercise, hint);
    return CanonicalImportResult(
      exercise: confirmed
          ? exercise.copyWith(authoringMetadata: {'presetId': hint})
          : exercise,
      violations: violations,
      support: exercise.runtimeSupport,
      presetId: confirmed ? hint : null,
      hintRejected: hint != null && hint.isNotEmpty && !confirmed,
    );
  }
}
