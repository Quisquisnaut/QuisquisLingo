import '../models/course_models.dart';
import 'course_audit_service.dart';
import 'preset_recipes.dart';

/// A mutable, form-shaped copy of one canonical exercise for the Generic
/// Primitive Editor (Build 256 Session 4): every canonical field as
/// editable state, an [Exercise] built from them, and what the capability
/// registry and the Audit refuse. Pure Dart, testable without widgets.
class CanonicalExerciseDraft {
  CanonicalExerciseDraft._({
    required this.id,
    required this.primitive,
    required Map<OptionKey, OptionValue> options,
    required List<PromptElement> prompt,
    required List<ExerciseItem> items,
    required List<ExerciseTarget> targets,
    required List<LayoutElement> layout,
    required this.evaluation,
    required this.feedback,
    required this.hint,
    required this.authoringMetadata,
    required this.original,
  }) : options = Map.of(options),
       prompt = List.of(prompt),
       items = List.of(items),
       targets = List.of(targets),
       layout = List.of(layout);

  /// The draft of an existing exercise.
  factory CanonicalExerciseDraft.fromExercise(Exercise exercise) =>
      CanonicalExerciseDraft._(
        id: exercise.id,
        primitive: exercise.primitive,
        options: {
          for (final key in exercise.options.keys) key: exercise.options[key]!,
        },
        prompt: exercise.promptElements,
        items: exercise.items,
        targets: exercise.targets,
        layout: exercise.layout,
        evaluation: exercise.canonicalEvaluation,
        feedback: exercise.feedback,
        hint: exercise.hint,
        authoringMetadata: Map.of(exercise.authoringMetadata),
        original: exercise,
      );

  /// A new exercise of [primitive] with the registry's default evaluation
  /// mode, its required options set and no content.
  factory CanonicalExerciseDraft.blank(
    ExercisePrimitive primitive, {
    required String id,
  }) => CanonicalExerciseDraft._(
    id: id,
    primitive: primitive,
    options: requiredOptionDefaults(primitive),
    prompt: const [],
    items: const [],
    targets: const [],
    layout: const [],
    evaluation: CanonicalEvaluation(
      mode: PrimitiveCapabilityRegistry.capabilityOf(
        primitive,
      ).defaultEvaluationMode,
    ),
    feedback: ExerciseFeedback.empty,
    hint: '',
    authoringMetadata: const {},
    original: null,
  );

  /// The options a new exercise of [primitive] must carry to be legal: every
  /// required option at its default, else at its first legal value (Assign
  /// needs `targetMode`, Submit `submissionType`). Without them the registry
  /// refuses the empty draft before the creator has touched anything.
  static Map<OptionKey, OptionValue> requiredOptionDefaults(
    ExercisePrimitive primitive,
  ) {
    final values = <OptionKey, OptionValue>{};
    for (final definition in PrimitiveCapabilityRegistry.capabilityOf(
      primitive,
    ).options) {
      if (!definition.required) continue;
      final value =
          definition.defaultValue ??
          (definition.legalValues.isEmpty
              ? null
              : EnumOptionValue(definition.legalValues.first));
      if (value != null) values[definition.key] = value;
    }
    return values;
  }

  /// A new, empty exercise of [primitive] as the Generic Primitive Editor
  /// opens it: no content, the registry's default evaluation mode and
  /// required options, no preset and no other authoring metadata.
  static Exercise blankExercise(
    ExercisePrimitive primitive, {
    required String id,
    required DateTime updatedAt,
  }) => Exercise.canonical(
    id: id,
    publicationState: PublicationState.draft,
    updatedAt: updatedAt,
    primitive: primitive,
    options: PrimitiveOptions(requiredOptionDefaults(primitive)),
    promptElements: const [],
    items: const [],
    targets: const [],
    layout: const [],
    canonicalEvaluation: CanonicalEvaluation(
      mode: PrimitiveCapabilityRegistry.capabilityOf(
        primitive,
      ).defaultEvaluationMode,
    ),
    feedback: ExerciseFeedback.empty,
    hint: '',
    authoringMetadata: const {},
  );

  final String id;

  /// The exercise this draft started from; null for a new one.
  final Exercise? original;

  /// Locked once the exercise exists (plan A.13); a new draft may change it
  /// through [changePrimitive].
  ExercisePrimitive primitive;

  /// Explicitly set options only; an absent key means the registry default.
  final Map<OptionKey, OptionValue> options;
  final List<PromptElement> prompt;
  final List<ExerciseItem> items;
  final List<ExerciseTarget> targets;
  final List<LayoutElement> layout;
  CanonicalEvaluation evaluation;
  ExerciseFeedback feedback;
  String hint;

  /// Carried from the original and kept as long as the content still
  /// matches its preset (see [toExercise]).
  final Map<String, Object?> authoringMetadata;

  PrimitiveCapability get capability =>
      PrimitiveCapabilityRegistry.capabilityOf(primitive);

  /// Changes the primitive of a new draft, keeping the content that still
  /// applies and resetting the evaluation to the primitive's default mode.
  void changePrimitive(ExercisePrimitive next) {
    if (next == primitive) return;
    primitive = next;
    options.removeWhere((key, _) => capability.optionDefinition(key) == null);
    for (final entry in requiredOptionDefaults(next).entries) {
      options.putIfAbsent(entry.key, () => entry.value);
    }
    evaluation = CanonicalEvaluation(mode: capability.defaultEvaluationMode);
    if (!capability.usesItems) items.clear();
    if (!capability.usesTargets) {
      targets.clear();
      layout.clear();
    }
  }

  /// Replaces the content with [sample]'s, a working example of this
  /// primitive (Build 261 Revision 5): options, prompt, items, targets,
  /// layout, evaluation, feedback and hint. The ID and primitive stay.
  void fillFrom(Exercise sample) {
    options
      ..clear()
      ..addAll({
        for (final key in sample.options.keys) key: sample.options[key]!,
      });
    prompt
      ..clear()
      ..addAll(sample.promptElements);
    items
      ..clear()
      ..addAll(sample.items);
    targets
      ..clear()
      ..addAll(sample.targets);
    layout
      ..clear()
      ..addAll(sample.layout);
    evaluation = sample.canonicalEvaluation;
    feedback = sample.feedback;
    hint = sample.hint;
  }

  /// The next unused item ID in this exercise's own naming.
  String nextItemId() => _nextId('item', items.map((item) => item.id));

  /// The next unused target ID.
  String nextTargetId() => _nextId('gap', targets.map((target) => target.id));

  String _nextId(String stem, Iterable<String> taken) {
    final used = taken.toSet();
    for (var i = 0; ; i++) {
      final candidate = '${id}_${stem}_$i';
      if (!used.contains(candidate)) return candidate;
    }
  }

  /// Sets or clears one option.
  void setOption(OptionKey key, OptionValue? value) {
    if (value == null) {
      options.remove(key);
    } else {
      options[key] = value;
    }
  }

  /// The registry's objections to the options and the evaluation mode.
  List<CapabilityViolation> get violations =>
      PrimitiveCapabilityRegistry.validate(
        primitive: primitive,
        options: PrimitiveOptions(options),
        evaluationMode: evaluation.mode,
      );

  /// The exercise these fields describe. The preset named by the carried
  /// metadata stays only when its recipe still represents the result;
  /// otherwise recognition may name another preset, and every other
  /// authoring key is dropped once the content changed (plan A.13).
  Exercise toExercise({
    required PublicationState publicationState,
    required DateTime updatedAt,
  }) {
    final built = Exercise.canonical(
      id: id,
      publicationState: publicationState,
      updatedAt: updatedAt,
      primitive: primitive,
      options: PrimitiveOptions(options),
      promptElements: List.unmodifiable(prompt),
      items: List.unmodifiable(items),
      targets: List.unmodifiable(targets),
      layout: List.unmodifiable(layout),
      canonicalEvaluation: evaluation,
      feedback: feedback,
      hint: hint,
      authoringMetadata: authoringMetadata,
    );
    final source = original;
    final unchanged = source != null && built.semanticallyEquals(source);
    final presetId = PresetRecipes.recognize(built);
    final metadata = <String, Object?>{
      if (unchanged) ...authoringMetadata,
      if (presetId != null) 'presetId': presetId,
    };
    if (presetId == null) metadata.remove('presetId');
    return built.withAuthoringMetadata(metadata);
  }

  /// The Audit's findings for the exercise as it stands, for Preview and
  /// Save decisions.
  List<CourseAuditIssue> audit({CourseAuditService? service}) =>
      (service ?? CourseAuditService()).auditExercise(
        toExercise(
          publicationState:
              original?.publicationState ?? PublicationState.draft,
          updatedAt: original?.updatedAt ?? DateTime.now().toUtc(),
        ),
      );
}
