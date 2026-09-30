/// The one authoritative description of what each primitive can do
/// (Course Model v12, Build 256).
///
/// For every primitive it holds: the options it accepts with their legal
/// values, defaults and required ones; the evaluation modes it may use; the
/// rules that make a combination illegal (option against option, evaluation
/// mode against option); and the runtime-support table that says which
/// legal configurations this version of QQL can actually play. The Course
/// Audit, the Course Editor, import and the learner runtime all derive
/// legality from here and never keep a second matrix.
library;

import 'evaluation_mode.dart';
import 'exercise_primitive.dart';
import 'primitive_options.dart';

/// One option as one primitive accepts it.
final class OptionDefinition {
  const OptionDefinition({
    required this.key,
    this.legalValues = const [],
    this.defaultValue,
    this.required = false,
    this.minimum,
    this.description = '',
  });

  final OptionKey key;

  /// For an enumeration: the values this primitive accepts, a non-empty
  /// subset of [OptionKey.vocabulary].
  final List<OptionEnumValue> legalValues;

  /// What an omitted option means. Null when the option is [required] or
  /// when absence is itself meaningful (no upper limit, no duration cap, the
  /// Course language).
  final OptionValue? defaultValue;
  final bool required;

  /// For an integer: the smallest legal value.
  final int? minimum;
  final String description;

  /// True when [value] is of the right kind and, for an enumeration or an
  /// integer, within the legal range.
  bool accepts(OptionValue value) {
    switch (key.kind) {
      case OptionValueKind.enumeration:
        return value is EnumOptionValue && legalValues.contains(value.value);
      case OptionValueKind.boolean:
        return value is BoolOptionValue;
      case OptionValueKind.integer:
        return value is IntOptionValue &&
            (minimum == null || value.value >= minimum!);
      case OptionValueKind.language:
        return value is LanguageOptionValue;
    }
  }
}

/// Why a configuration is not legal. Shared by the Audit, the editor and
/// import, which map these to their own messages and severities.
enum CapabilityViolationCode {
  unknownPrimitive,
  unknownOption,
  optionNotApplicable,
  illegalOptionValue,
  missingRequiredOption,
  illegalCombination,
  missingEvaluationMode,
  illegalEvaluationMode,
  evaluationRequiresOption,
  selectionLimitsImpossible,
}

final class CapabilityViolation {
  const CapabilityViolation({
    required this.code,
    required this.message,
    this.primitive,
    this.key,
    this.evaluationMode,
    this.ruleId,
  });

  final CapabilityViolationCode code;
  final String message;
  final ExercisePrimitive? primitive;
  final OptionKey? key;
  final EvaluationMode? evaluationMode;

  /// The registry rule that fired, for illegal combinations and evaluation
  /// implications.
  final String? ruleId;

  CapabilityViolation forPrimitive(ExercisePrimitive primitive) =>
      CapabilityViolation(
        code: code,
        message: message,
        primitive: primitive,
        key: key,
        evaluationMode: evaluationMode,
        ruleId: ruleId,
      );

  @override
  String toString() =>
      'CapabilityViolation(${code.name}${ruleId == null ? '' : ' $ruleId'}: $message)';
}

/// A coded rule over the effective options and the evaluation mode.
sealed class CapabilityRule {
  const CapabilityRule({required this.id, required this.description});

  /// Stable, e.g. `select.single.limits`.
  final String id;
  final String description;

  /// The violation, or null when the rule holds. [effective] has defaults
  /// filled in and illegal values removed.
  CapabilityViolation? check(PrimitiveOptions effective, EvaluationMode? mode);
}

/// When [key] holds one of [when], [requiredKey] must hold one of [allowed].
/// An absent [requiredKey] passes (absence is never a value).
final class OptionImplication extends CapabilityRule {
  const OptionImplication({
    required super.id,
    required super.description,
    required this.key,
    required this.when,
    required this.requiredKey,
    required this.allowed,
  });

  final OptionKey key;
  final List<OptionEnumValue> when;
  final OptionKey requiredKey;
  final List<OptionEnumValue> allowed;

  @override
  CapabilityViolation? check(PrimitiveOptions effective, EvaluationMode? mode) {
    final trigger = effective[key];
    if (trigger is! EnumOptionValue || !when.contains(trigger.value)) {
      return null;
    }
    final actual = effective[requiredKey];
    if (actual == null) return null;
    if (actual is EnumOptionValue && allowed.contains(actual.value)) {
      return null;
    }
    return CapabilityViolation(
      code: CapabilityViolationCode.illegalCombination,
      key: requiredKey,
      ruleId: id,
      message:
          '${key.serialized} ${trigger.value.serialized} requires '
          '${requiredKey.serialized} to be '
          '${allowed.map((value) => value.serialized).join(' or ')}, not '
          '${actual.serialized}.',
    );
  }
}

/// When [key] holds one of [when], the integer [integerKey], if present,
/// must be one of [allowed].
final class OptionRequiresIntegers extends CapabilityRule {
  const OptionRequiresIntegers({
    required super.id,
    required super.description,
    required this.key,
    required this.when,
    required this.integerKey,
    required this.allowed,
  });

  final OptionKey key;
  final List<OptionEnumValue> when;
  final OptionKey integerKey;
  final List<int> allowed;

  @override
  CapabilityViolation? check(PrimitiveOptions effective, EvaluationMode? mode) {
    final trigger = effective[key];
    if (trigger is! EnumOptionValue || !when.contains(trigger.value)) {
      return null;
    }
    final actual = effective.intValue(integerKey);
    if (actual == null || allowed.contains(actual)) return null;
    return CapabilityViolation(
      code: CapabilityViolationCode.illegalCombination,
      key: integerKey,
      ruleId: id,
      message:
          '${key.serialized} ${trigger.value.serialized} allows '
          '${integerKey.serialized} ${allowed.join(' or ')} only, not $actual.',
    );
  }
}

/// When the evaluation mode is one of [modes], [key] must hold one of
/// [allowed].
final class EvaluationImplication extends CapabilityRule {
  const EvaluationImplication({
    required super.id,
    required super.description,
    required this.modes,
    required this.key,
    required this.allowed,
  });

  final List<EvaluationMode> modes;
  final OptionKey key;
  final List<OptionEnumValue> allowed;

  @override
  CapabilityViolation? check(PrimitiveOptions effective, EvaluationMode? mode) {
    if (mode == null || !modes.contains(mode)) return null;
    final actual = effective[key];
    if (actual == null) return null;
    if (actual is EnumOptionValue && allowed.contains(actual.value)) {
      return null;
    }
    return CapabilityViolation(
      code: CapabilityViolationCode.evaluationRequiresOption,
      key: key,
      evaluationMode: mode,
      ruleId: id,
      message:
          'Evaluation ${mode.serialized} requires ${key.serialized} to be '
          '${allowed.map((value) => value.serialized).join(' or ')}, not '
          '${actual.serialized}.',
    );
  }
}

/// When [key] holds one of [when], the evaluation mode must be one of
/// [allowedModes].
final class OptionEvaluationImplication extends CapabilityRule {
  const OptionEvaluationImplication({
    required super.id,
    required super.description,
    required this.key,
    required this.when,
    required this.allowedModes,
  });

  final OptionKey key;
  final List<OptionEnumValue> when;
  final List<EvaluationMode> allowedModes;

  @override
  CapabilityViolation? check(PrimitiveOptions effective, EvaluationMode? mode) {
    final trigger = effective[key];
    if (mode == null ||
        trigger is! EnumOptionValue ||
        !when.contains(trigger.value) ||
        allowedModes.contains(mode)) {
      return null;
    }
    return CapabilityViolation(
      code: CapabilityViolationCode.illegalCombination,
      key: key,
      evaluationMode: mode,
      ruleId: id,
      message:
          '${key.serialized} ${trigger.value.serialized} allows evaluation '
          '${allowedModes.map((value) => value.serialized).join(' or ')} '
          'only, not ${mode.serialized}.',
    );
  }
}

/// [lowerKey] must not exceed [upperKey] when both are present.
final class IntegerOrderRule extends CapabilityRule {
  const IntegerOrderRule({
    required super.id,
    required super.description,
    required this.lowerKey,
    required this.upperKey,
  });

  final OptionKey lowerKey;
  final OptionKey upperKey;

  @override
  CapabilityViolation? check(PrimitiveOptions effective, EvaluationMode? mode) {
    final lower = effective.intValue(lowerKey);
    final upper = effective.intValue(upperKey);
    if (lower == null || upper == null || lower <= upper) return null;
    return CapabilityViolation(
      code: CapabilityViolationCode.illegalCombination,
      key: upperKey,
      ruleId: id,
      message:
          '${lowerKey.serialized} ($lower) must not exceed '
          '${upperKey.serialized} ($upper).',
    );
  }
}

/// Everything one primitive accepts.
final class PrimitiveCapability {
  const PrimitiveCapability({
    required this.primitive,
    required this.options,
    required this.evaluationModes,
    required this.defaultEvaluationMode,
    this.rules = const [],
    required this.usesItems,
    required this.usesTargets,
    this.notes = '',
  });

  final ExercisePrimitive primitive;
  final List<OptionDefinition> options;
  final List<EvaluationMode> evaluationModes;
  final EvaluationMode defaultEvaluationMode;
  final List<CapabilityRule> rules;

  /// Whether exercises of this primitive carry items (choices, blocks,
  /// peers, things to assign).
  final bool usesItems;

  /// Whether exercises of this primitive may carry targets (gaps, regions,
  /// cells, slots, categories) that a neutral layout can reference.
  final bool usesTargets;
  final String notes;

  OptionDefinition? optionDefinition(OptionKey key) {
    for (final definition in options) {
      if (definition.key == key) return definition;
    }
    return null;
  }

  List<OptionKey> get optionKeys =>
      options.map((definition) => definition.key).toList(growable: false);
}

/// One legal configuration family this version of QQL can play. An exercise
/// is executable when some configuration of its primitive lists its
/// evaluation mode and every listed option holds one of the listed values.
/// Every enumeration option of the primitive must be listed, so a value the
/// runtime does not handle can never be executable by omission; integers and
/// booleans may be left out (unconstrained).
final class SupportedConfiguration {
  const SupportedConfiguration({
    required this.primitive,
    required this.description,
    required this.evaluationModes,
    required this.values,
  });

  final ExercisePrimitive primitive;
  final String description;
  final List<EvaluationMode> evaluationModes;
  final Map<OptionKey, List<OptionEnumValue>> values;

  bool covers(PrimitiveOptions effective, EvaluationMode mode) {
    if (!evaluationModes.contains(mode)) return false;
    for (final entry in values.entries) {
      final actual = effective[entry.key];
      if (actual is! EnumOptionValue || !entry.value.contains(actual.value)) {
        return false;
      }
    }
    return true;
  }
}

/// The four support states of an exercise (Part D of the Build 256 plan).
/// [invalid] and [unsupportedModelVersion] are decided by validation and by
/// the Course's format, not by the runtime table.
enum ExerciseSupportState {
  executable,
  readableButNotExecutable,
  invalid,
  unsupportedModelVersion,
}

final class ExerciseRuntimeSupport {
  const ExerciseRuntimeSupport({
    required this.state,
    required this.reason,
    this.configuration,
    this.violations = const [],
  });

  final ExerciseSupportState state;
  final String reason;

  /// The configuration that covers the exercise when it is executable.
  final SupportedConfiguration? configuration;
  final List<CapabilityViolation> violations;

  bool get isExecutable => state == ExerciseSupportState.executable;
}

/// Options parsed from JSON together with what could not be parsed. Illegal
/// or unknown entries are reported and dropped, never coerced or defaulted.
final class ParsedOptions {
  const ParsedOptions({required this.options, required this.violations});
  final PrimitiveOptions options;
  final List<CapabilityViolation> violations;
}

abstract final class PrimitiveCapabilityRegistry {
  static const List<PrimitiveCapability> capabilities = [
    _select,
    _input,
    _arrange,
    _match,
    _assign,
    _speak,
    _ink,
    _submit,
    _presentation,
  ];

  static PrimitiveCapability capabilityOf(ExercisePrimitive primitive) {
    for (final capability in capabilities) {
      if (capability.primitive == primitive) return capability;
    }
    throw StateError('No capability for ${primitive.serialized}.');
  }

  static OptionDefinition? optionDefinition(
    ExercisePrimitive primitive,
    OptionKey key,
  ) => capabilityOf(primitive).optionDefinition(key);

  /// The values [primitive] accepts for the enumeration [key]; empty when the
  /// key does not apply or is not an enumeration.
  static List<OptionEnumValue> legalValues(
    ExercisePrimitive primitive,
    OptionKey key,
  ) => optionDefinition(primitive, key)?.legalValues ?? const [];

  /// The default of [key] for [primitive], or null when there is none.
  static OptionValue? defaultOf(ExercisePrimitive primitive, OptionKey key) =>
      optionDefinition(primitive, key)?.defaultValue;

  /// [options] with every legal given value kept, every illegal or
  /// inapplicable one dropped, and every absent option that has a default
  /// filled in.
  static PrimitiveOptions effectiveOptions(
    ExercisePrimitive primitive,
    PrimitiveOptions options,
  ) {
    final capability = capabilityOf(primitive);
    final values = <OptionKey, OptionValue>{};
    for (final definition in capability.options) {
      final given = options[definition.key];
      if (given != null && definition.accepts(given)) {
        values[definition.key] = given;
      } else if (definition.defaultValue != null) {
        values[definition.key] = definition.defaultValue!;
      }
    }
    return PrimitiveOptions(values);
  }

  /// Parses an `options` JSON object for [primitive]. Unknown keys, keys the
  /// primitive does not accept and values that are not exactly legal are
  /// reported and left out of the result.
  static ParsedOptions parseOptions(
    ExercisePrimitive primitive,
    Map<String, Object?> json,
  ) {
    final capability = capabilityOf(primitive);
    final values = <OptionKey, OptionValue>{};
    final violations = <CapabilityViolation>[];
    for (final entry in json.entries) {
      final key = OptionKey.tryParse(entry.key);
      if (key == null) {
        violations.add(
          CapabilityViolation(
            code: CapabilityViolationCode.unknownOption,
            primitive: primitive,
            message: 'Unknown option “${entry.key}”.',
          ),
        );
        continue;
      }
      final definition = capability.optionDefinition(key);
      if (definition == null) {
        violations.add(
          CapabilityViolation(
            code: CapabilityViolationCode.optionNotApplicable,
            primitive: primitive,
            key: key,
            message:
                'Option ${key.serialized} does not apply to ${primitive.label}.',
          ),
        );
        continue;
      }
      final value = OptionValue.parse(key, entry.value);
      if (value == null || !definition.accepts(value)) {
        violations.add(
          CapabilityViolation(
            code: CapabilityViolationCode.illegalOptionValue,
            primitive: primitive,
            key: key,
            message: _illegalValueMessage(primitive, definition, entry.value),
          ),
        );
        continue;
      }
      values[key] = value;
    }
    return ParsedOptions(
      options: PrimitiveOptions(values),
      violations: violations,
    );
  }

  static String _illegalValueMessage(
    ExercisePrimitive primitive,
    OptionDefinition definition,
    Object? raw,
  ) {
    final key = definition.key;
    switch (key.kind) {
      case OptionValueKind.enumeration:
        return '${key.serialized} “${raw ?? 'null'}” is not one of '
            '${definition.legalValues.map((value) => value.serialized).join(', ')} '
            'for ${primitive.label}.';
      case OptionValueKind.boolean:
        return '${key.serialized} must be true or false, not “${raw ?? 'null'}”.';
      case OptionValueKind.integer:
        return '${key.serialized} must be a whole number'
            '${definition.minimum == null ? '' : ' of at least ${definition.minimum}'}, '
            'not “${raw ?? 'null'}”.';
      case OptionValueKind.language:
        return '${key.serialized} must be a language tag such as it or pt-BR, '
            'not “${raw ?? 'null'}”.';
    }
  }

  /// Every way [options] and [evaluationMode] fail [primitive]'s rules.
  /// An empty list means the configuration is legal (which says nothing about
  /// whether this version can play it; see [runtimeSupport]).
  static List<CapabilityViolation> validate({
    required ExercisePrimitive primitive,
    required PrimitiveOptions options,
    required EvaluationMode? evaluationMode,
  }) {
    final capability = capabilityOf(primitive);
    final out = <CapabilityViolation>[];
    for (final key in options.keys) {
      final definition = capability.optionDefinition(key);
      final value = options[key]!;
      if (definition == null) {
        out.add(
          CapabilityViolation(
            code: CapabilityViolationCode.optionNotApplicable,
            primitive: primitive,
            key: key,
            message:
                'Option ${key.serialized} does not apply to ${primitive.label}.',
          ),
        );
      } else if (!definition.accepts(value)) {
        out.add(
          CapabilityViolation(
            code: CapabilityViolationCode.illegalOptionValue,
            primitive: primitive,
            key: key,
            message: _illegalValueMessage(
              primitive,
              definition,
              value.serialized,
            ),
          ),
        );
      }
    }
    for (final definition in capability.options) {
      if (definition.required && options[definition.key] == null) {
        out.add(
          CapabilityViolation(
            code: CapabilityViolationCode.missingRequiredOption,
            primitive: primitive,
            key: definition.key,
            message:
                '${primitive.label} requires the option ${definition.key.serialized}.',
          ),
        );
      }
    }
    if (evaluationMode == null) {
      out.add(
        CapabilityViolation(
          code: CapabilityViolationCode.missingEvaluationMode,
          primitive: primitive,
          message: '${primitive.label} requires an evaluation mode.',
        ),
      );
    } else if (!capability.evaluationModes.contains(evaluationMode)) {
      out.add(
        CapabilityViolation(
          code: CapabilityViolationCode.illegalEvaluationMode,
          primitive: primitive,
          evaluationMode: evaluationMode,
          message:
              '${primitive.label} cannot use evaluation '
              '${evaluationMode.serialized}; it accepts '
              '${capability.evaluationModes.map((mode) => mode.serialized).join(', ')}.',
        ),
      );
    }
    final effective = effectiveOptions(primitive, options);
    final legalMode =
        evaluationMode != null &&
            capability.evaluationModes.contains(evaluationMode)
        ? evaluationMode
        : null;
    for (final rule in capability.rules) {
      final violation = rule.check(effective, legalMode);
      if (violation != null) out.add(violation.forPrimitive(primitive));
    }
    return out;
  }

  /// The selection-limit invariants that need the exercise's items: for
  /// exactSet, minimumSelections ≤ correctCount ≤ maximumSelections ≤
  /// itemCount; for every Select mode at least one correct item that exists
  /// among the items, and never more required selections than items.
  static List<CapabilityViolation> checkSelectionLimits({
    required PrimitiveOptions options,
    required EvaluationMode evaluationMode,
    required int correctCount,
    required int itemCount,
  }) {
    final effective = effectiveOptions(ExercisePrimitive.select, options);
    final minimum = effective.intValue(OptionKey.minimumSelections) ?? 1;
    final maximum = effective.intValue(OptionKey.maximumSelections);
    final out = <CapabilityViolation>[];
    void add(String message) => out.add(
      CapabilityViolation(
        code: CapabilityViolationCode.selectionLimitsImpossible,
        primitive: ExercisePrimitive.select,
        evaluationMode: evaluationMode,
        message: message,
      ),
    );
    if (correctCount < 1) {
      add('At least one correct item is required.');
    }
    if (correctCount > itemCount) {
      add('There are $correctCount correct items but only $itemCount items.');
    }
    if (minimum > itemCount) {
      add(
        'minimumSelections ($minimum) exceeds the number of items ($itemCount).',
      );
    }
    if (maximum != null && maximum > itemCount) {
      add(
        'maximumSelections ($maximum) exceeds the number of items ($itemCount).',
      );
    }
    switch (evaluationMode) {
      case EvaluationMode.exactItem:
        if (correctCount > 1) {
          add('exactItem needs exactly one correct item, not $correctCount.');
        }
      case EvaluationMode.exactSet:
        if (minimum > correctCount) {
          add(
            'minimumSelections ($minimum) exceeds the number of correct items ($correctCount); the learner could never select an exact set.',
          );
        }
        if (maximum != null && maximum < correctCount) {
          add(
            'maximumSelections ($maximum) is below the number of correct items ($correctCount); the learner could never select the whole set.',
          );
        }
      case EvaluationMode.subset:
      case EvaluationMode.orderedSelections:
      case EvaluationMode.perSelection:
        break;
      default:
        break;
    }
    return out;
  }

  /// The configurations this version of QQL can play (Part A.2 of the plan:
  /// exactly today's behaviors; Assign joined in Session 8, Build 256
  /// Revision 7: groups, slots and gaps by tapping). Never stored in
  /// Course data.
  static const List<SupportedConfiguration> runtimeSupportTable = [
    SupportedConfiguration(
      primitive: ExercisePrimitive.select,
      description: 'One choice among listed items, checked at once.',
      evaluationModes: [EvaluationMode.exactItem],
      values: {
        OptionKey.selectionMode: [SelectionMode.single],
        OptionKey.selectionTarget: [SelectionTarget.items],
        OptionKey.itemReuse: [ItemReuse.forbidden],
        OptionKey.layout: [LayoutValue.list, LayoutValue.grid],
        OptionKey.evaluationTiming: [EvaluationTiming.immediate],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.select,
      description: 'Several choices among listed items, checked on Check.',
      evaluationModes: [EvaluationMode.exactSet],
      values: {
        OptionKey.selectionMode: [SelectionMode.multiple],
        OptionKey.selectionTarget: [SelectionTarget.items],
        OptionKey.itemReuse: [ItemReuse.forbidden],
        OptionKey.layout: [LayoutValue.list, LayoutValue.grid],
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.select,
      description:
          'Items chosen into inline gaps, one item per gap, checked on Check.',
      evaluationModes: [EvaluationMode.exactItem],
      values: {
        OptionKey.selectionMode: [SelectionMode.single],
        OptionKey.selectionTarget: [SelectionTarget.items],
        OptionKey.itemReuse: [
          ItemReuse.forbidden,
          ItemReuse.allowed,
          ItemReuse.unlimited,
        ],
        OptionKey.layout: [LayoutValue.inline],
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.input,
      description: 'One typed text answer, in a field or one inline gap.',
      evaluationModes: [
        EvaluationMode.exactText,
        EvaluationMode.acceptedTexts,
        EvaluationMode.expression,
      ],
      values: {
        OptionKey.inputMode: [InputMode.text],
        OptionKey.cardinality: [Cardinality.single],
        OptionKey.layout: [LayoutValue.field, LayoutValue.inlineGaps],
        OptionKey.caseHandling: CaseHandling.values,
        OptionKey.punctuationHandling: PunctuationHandling.values,
        OptionKey.whitespaceHandling: WhitespaceHandling.values,
        OptionKey.accentHandling: AccentHandling.values,
        OptionKey.typoTolerance: TypoTolerance.values,
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.input,
      description: 'Several typed text answers, one per inline gap.',
      evaluationModes: [
        EvaluationMode.exactText,
        EvaluationMode.acceptedTexts,
        EvaluationMode.expression,
      ],
      values: {
        OptionKey.inputMode: [InputMode.text],
        OptionKey.cardinality: [Cardinality.multiple],
        OptionKey.layout: [LayoutValue.inlineGaps],
        OptionKey.caseHandling: CaseHandling.values,
        OptionKey.punctuationHandling: PunctuationHandling.values,
        OptionKey.whitespaceHandling: WhitespaceHandling.values,
        OptionKey.accentHandling: AccentHandling.values,
        OptionKey.typoTolerance: TypoTolerance.values,
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.arrange,
      description: 'Blocks placed into one wrapped sequence.',
      evaluationModes: [
        EvaluationMode.exactOrder,
        EvaluationMode.acceptedOrders,
      ],
      values: {
        OptionKey.placementMode: [PlacementMode.sequence],
        OptionKey.itemReuse: [ItemReuse.forbidden],
        OptionKey.unusedItems: UnusedItems.values,
        OptionKey.layout: [LayoutValue.wrapped],
        OptionKey.joiner: Joiner.values,
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.arrange,
      description: 'Blocks placed into inline gaps.',
      evaluationModes: [EvaluationMode.gapAssignments],
      values: {
        OptionKey.placementMode: [PlacementMode.inlineGaps],
        OptionKey.itemReuse: [ItemReuse.forbidden],
        OptionKey.unusedItems: UnusedItems.values,
        OptionKey.layout: [LayoutValue.inline],
        OptionKey.joiner: Joiner.values,
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.match,
      description: 'One-to-one pairs chosen from a dropdown per left item.',
      evaluationModes: [EvaluationMode.exactRelations],
      values: {
        OptionKey.relationship: [MatchRelationship.oneToOne],
        OptionKey.interactionStyle: [MatchInteractionStyle.dropdown],
        OptionKey.itemReuse: [ItemReuse.forbidden],
        OptionKey.layout: [LayoutValue.columns],
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.presentation,
      description: 'A single page of material with a completion action.',
      evaluationModes: [EvaluationMode.none],
      values: {
        OptionKey.completionMode: [
          CompletionMode.proceed,
          CompletionMode.acknowledge,
          CompletionMode.understoodReview,
        ],
        OptionKey.navigation: [PresentationNavigation.singlePage],
        OptionKey.mediaPlayback: MediaPlayback.values,
        OptionKey.textReveal: TextReveal.values,
        OptionKey.scoring: [Scoring.none],
        OptionKey.evaluationTiming: [EvaluationTiming.none],
      },
    ),
    // Build 256 Revision 7: Assign plays by tapping an item, then its
    // destination. Groups (categories) and slots in columns, gaps in a
    // text; drag placement, picture regions and grid cells wait for a
    // later version.
    SupportedConfiguration(
      primitive: ExercisePrimitive.assign,
      description: 'Sort items into groups, checked on Check.',
      evaluationModes: [EvaluationMode.exactAssignments],
      values: {
        OptionKey.targetMode: [AssignTargetMode.categories],
        OptionKey.targetCapacity: TargetCapacity.values,
        OptionKey.itemReuse: ItemReuse.values,
        OptionKey.placementMode: [
          PlacementMode.tapTarget,
          PlacementMode.selectTarget,
        ],
        OptionKey.layout: [LayoutValue.columns],
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.assign,
      description: 'Fill slots with items, checked on Check.',
      evaluationModes: [EvaluationMode.exactAssignments],
      values: {
        OptionKey.targetMode: [AssignTargetMode.slots],
        OptionKey.targetCapacity: [TargetCapacity.single],
        OptionKey.itemReuse: ItemReuse.values,
        OptionKey.placementMode: [
          PlacementMode.tapTarget,
          PlacementMode.selectTarget,
        ],
        OptionKey.layout: [LayoutValue.columns],
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
    SupportedConfiguration(
      primitive: ExercisePrimitive.assign,
      description: 'Fill the gaps of a text with items, checked on Check.',
      evaluationModes: [EvaluationMode.exactAssignments],
      values: {
        OptionKey.targetMode: [AssignTargetMode.gaps],
        OptionKey.targetCapacity: [TargetCapacity.single],
        OptionKey.itemReuse: ItemReuse.values,
        OptionKey.placementMode: [
          PlacementMode.tapTarget,
          PlacementMode.selectTarget,
        ],
        OptionKey.layout: [LayoutValue.inline],
        OptionKey.evaluationTiming: [EvaluationTiming.explicit],
      },
    ),
  ];

  /// Whether this version of QQL can play the configuration. A configuration
  /// with violations is [ExerciseSupportState.invalid]; a legal one that no
  /// [runtimeSupportTable] entry covers is readable but not executable.
  static ExerciseRuntimeSupport runtimeSupport({
    required ExercisePrimitive primitive,
    required PrimitiveOptions options,
    required EvaluationMode? evaluationMode,
  }) {
    final violations = validate(
      primitive: primitive,
      options: options,
      evaluationMode: evaluationMode,
    );
    if (violations.isNotEmpty || evaluationMode == null) {
      return ExerciseRuntimeSupport(
        state: ExerciseSupportState.invalid,
        reason: violations.map((violation) => violation.message).join(' '),
        violations: violations,
      );
    }
    final effective = effectiveOptions(primitive, options);
    for (final configuration in runtimeSupportTable) {
      if (configuration.primitive == primitive &&
          configuration.covers(effective, evaluationMode)) {
        return ExerciseRuntimeSupport(
          state: ExerciseSupportState.executable,
          reason: configuration.description,
          configuration: configuration,
        );
      }
    }
    return ExerciseRuntimeSupport(
      state: ExerciseSupportState.readableButNotExecutable,
      reason:
          'This version of QQL cannot play this ${primitive.label} '
          'configuration (evaluation ${evaluationMode.serialized}, options '
          '${effective.toJson()}). It is kept, editable and exported unchanged.',
    );
  }

  // ---------------------------------------------------------------------
  // Select
  // ---------------------------------------------------------------------

  static const _select = PrimitiveCapability(
    primitive: ExercisePrimitive.select,
    usesItems: true,
    usesTargets: true,
    notes:
        'Items are reusable when configured; an inline layout lets one item '
        'fill several gaps. Regions are normalized rectangles on one '
        'referenced image; cells are the cells of a grid.',
    options: [
      OptionDefinition(
        key: OptionKey.selectionMode,
        legalValues: SelectionMode.values,
        defaultValue: EnumOptionValue(SelectionMode.single),
        description: 'How many selections the learner makes.',
      ),
      OptionDefinition(
        key: OptionKey.selectionTarget,
        legalValues: SelectionTarget.values,
        defaultValue: EnumOptionValue(SelectionTarget.items),
        description: 'What is selectable.',
      ),
      OptionDefinition(
        key: OptionKey.minimumSelections,
        defaultValue: IntOptionValue(1),
        minimum: 1,
        description: 'Fewest selections before the answer can be checked.',
      ),
      OptionDefinition(
        key: OptionKey.maximumSelections,
        minimum: 1,
        description: 'Most selections allowed at once; absent means all items.',
      ),
      OptionDefinition(
        key: OptionKey.itemReuse,
        legalValues: ItemReuse.values,
        defaultValue: EnumOptionValue(ItemReuse.forbidden),
        description: 'Whether one item may fill more than one target.',
      ),
      OptionDefinition(
        key: OptionKey.layout,
        legalValues: [
          LayoutValue.list,
          LayoutValue.grid,
          LayoutValue.inline,
          LayoutValue.overlay,
        ],
        defaultValue: EnumOptionValue(LayoutValue.list),
        description:
            'A list or grid of choices, inline gaps in text, or an overlay '
            'on an image (regions).',
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [
          EvaluationTiming.immediate,
          EvaluationTiming.explicit,
          EvaluationTiming.onCompletion,
        ],
        defaultValue: EnumOptionValue(EvaluationTiming.immediate),
      ),
      OptionDefinition(
        key: OptionKey.shuffleItems,
        defaultValue: BoolOptionValue(true),
      ),
    ],
    evaluationModes: [
      EvaluationMode.exactItem,
      EvaluationMode.exactSet,
      EvaluationMode.subset,
      EvaluationMode.orderedSelections,
      EvaluationMode.perSelection,
    ],
    defaultEvaluationMode: EvaluationMode.exactItem,
    rules: [
      OptionRequiresIntegers(
        id: 'select.single.minimum',
        description: 'A single selection needs no minimum other than 1.',
        key: OptionKey.selectionMode,
        when: [SelectionMode.single],
        integerKey: OptionKey.minimumSelections,
        allowed: [1],
      ),
      OptionRequiresIntegers(
        id: 'select.single.maximum',
        description: 'A single selection needs no maximum other than 1.',
        key: OptionKey.selectionMode,
        when: [SelectionMode.single],
        integerKey: OptionKey.maximumSelections,
        allowed: [1],
      ),
      IntegerOrderRule(
        id: 'select.limits.order',
        description: 'minimumSelections must not exceed maximumSelections.',
        lowerKey: OptionKey.minimumSelections,
        upperKey: OptionKey.maximumSelections,
      ),
      OptionImplication(
        id: 'select.items.layout',
        description: 'Listed items are shown in a list, a grid or inline.',
        key: OptionKey.selectionTarget,
        when: [SelectionTarget.items],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.list, LayoutValue.grid, LayoutValue.inline],
      ),
      OptionImplication(
        id: 'select.textSpans.layout',
        description: 'Text spans are selected inside inline text.',
        key: OptionKey.selectionTarget,
        when: [SelectionTarget.textSpans],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.inline],
      ),
      OptionImplication(
        id: 'select.regions.layout',
        description: 'Regions are selected on an image overlay.',
        key: OptionKey.selectionTarget,
        when: [SelectionTarget.regions],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.overlay],
      ),
      OptionImplication(
        id: 'select.cells.layout',
        description: 'Cells are selected in a grid.',
        key: OptionKey.selectionTarget,
        when: [SelectionTarget.cells],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.grid],
      ),
      OptionImplication(
        id: 'select.reuse.inline',
        description:
            'Reusing an item only means something when items fill inline gaps.',
        key: OptionKey.itemReuse,
        when: [ItemReuse.allowed, ItemReuse.unlimited],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.inline],
      ),
      OptionImplication(
        id: 'select.reuse.items',
        description: 'Only listed items can be reused.',
        key: OptionKey.itemReuse,
        when: [ItemReuse.allowed, ItemReuse.unlimited],
        requiredKey: OptionKey.selectionTarget,
        allowed: [SelectionTarget.items],
      ),
      EvaluationImplication(
        id: 'select.exactItem.single',
        description: 'exactItem grades one selection.',
        modes: [EvaluationMode.exactItem],
        key: OptionKey.selectionMode,
        allowed: [SelectionMode.single],
      ),
      EvaluationImplication(
        id: 'select.set.multiple',
        description:
            'Set, ordered and per-selection grading need several selections.',
        modes: [
          EvaluationMode.exactSet,
          EvaluationMode.subset,
          EvaluationMode.orderedSelections,
          EvaluationMode.perSelection,
        ],
        key: OptionKey.selectionMode,
        allowed: [SelectionMode.multiple],
      ),
      EvaluationImplication(
        id: 'select.set.timing',
        description:
            'A set is graded when the learner checks or completes, not on each tap.',
        modes: [
          EvaluationMode.exactSet,
          EvaluationMode.subset,
          EvaluationMode.orderedSelections,
        ],
        key: OptionKey.evaluationTiming,
        allowed: [EvaluationTiming.explicit, EvaluationTiming.onCompletion],
      ),
      EvaluationImplication(
        id: 'select.perSelection.timing',
        description: 'Per-selection grading answers each tap at once.',
        modes: [EvaluationMode.perSelection],
        key: OptionKey.evaluationTiming,
        allowed: [EvaluationTiming.immediate],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------

  static const _input = PrimitiveCapability(
    primitive: ExercisePrimitive.input,
    usesItems: false,
    usesTargets: true,
    notes:
        'An inline layout turns each target into a field. QQL answer '
        'expressions are the expression evaluation mode.',
    options: [
      OptionDefinition(
        key: OptionKey.inputMode,
        legalValues: InputMode.values,
        defaultValue: EnumOptionValue(InputMode.text),
      ),
      OptionDefinition(
        key: OptionKey.cardinality,
        legalValues: Cardinality.values,
        defaultValue: EnumOptionValue(Cardinality.single),
        description: 'One answer, or one answer per target.',
      ),
      OptionDefinition(
        key: OptionKey.layout,
        legalValues: [
          LayoutValue.field,
          LayoutValue.inlineGaps,
          LayoutValue.grid,
          LayoutValue.multiline,
        ],
        defaultValue: EnumOptionValue(LayoutValue.field),
      ),
      OptionDefinition(
        key: OptionKey.caseHandling,
        legalValues: CaseHandling.values,
        defaultValue: EnumOptionValue(CaseHandling.ignore),
      ),
      OptionDefinition(
        key: OptionKey.punctuationHandling,
        legalValues: PunctuationHandling.values,
        defaultValue: EnumOptionValue(PunctuationHandling.ignore),
      ),
      OptionDefinition(
        key: OptionKey.whitespaceHandling,
        legalValues: WhitespaceHandling.values,
        defaultValue: EnumOptionValue(WhitespaceHandling.normalize),
      ),
      OptionDefinition(
        key: OptionKey.accentHandling,
        legalValues: AccentHandling.values,
        defaultValue: EnumOptionValue(AccentHandling.missingAccentsAccepted),
      ),
      OptionDefinition(
        key: OptionKey.typoTolerance,
        legalValues: TypoTolerance.values,
        defaultValue: EnumOptionValue(TypoTolerance.none),
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.explicit, EvaluationTiming.onCompletion],
        defaultValue: EnumOptionValue(EvaluationTiming.explicit),
      ),
    ],
    evaluationModes: [
      EvaluationMode.exactText,
      EvaluationMode.acceptedTexts,
      EvaluationMode.expression,
      EvaluationMode.numericExact,
      EvaluationMode.numericRange,
      EvaluationMode.numericTolerance,
      EvaluationMode.regex,
      EvaluationMode.manual,
    ],
    defaultEvaluationMode: EvaluationMode.expression,
    rules: [
      OptionImplication(
        id: 'input.multiple.layout',
        description: 'Several answers need one field per target.',
        key: OptionKey.cardinality,
        when: [Cardinality.multiple],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.inlineGaps, LayoutValue.grid],
      ),
      OptionImplication(
        id: 'input.grid.multiple',
        description: 'A grid of fields holds several answers.',
        key: OptionKey.layout,
        when: [LayoutValue.grid],
        requiredKey: OptionKey.cardinality,
        allowed: [Cardinality.multiple],
      ),
      OptionImplication(
        id: 'input.typo.text',
        description: 'Typo tolerance applies to text only.',
        key: OptionKey.typoTolerance,
        when: [TypoTolerance.conservative],
        requiredKey: OptionKey.inputMode,
        allowed: [InputMode.text],
      ),
      EvaluationImplication(
        id: 'input.numeric.mode',
        description: 'Numeric grading needs a number.',
        modes: [
          EvaluationMode.numericExact,
          EvaluationMode.numericRange,
          EvaluationMode.numericTolerance,
        ],
        key: OptionKey.inputMode,
        allowed: [InputMode.number],
      ),
      EvaluationImplication(
        id: 'input.expression.text',
        description: 'QQL answer expressions grade text.',
        modes: [EvaluationMode.expression],
        key: OptionKey.inputMode,
        allowed: [InputMode.text],
      ),
      EvaluationImplication(
        id: 'input.regex.mode',
        description: 'A regular expression grades text or code.',
        modes: [EvaluationMode.regex],
        key: OptionKey.inputMode,
        allowed: [InputMode.text, InputMode.code],
      ),
      EvaluationImplication(
        id: 'input.texts.mode',
        description: 'Literal texts grade text, dates, formulas and code.',
        modes: [EvaluationMode.exactText, EvaluationMode.acceptedTexts],
        key: OptionKey.inputMode,
        allowed: [
          InputMode.text,
          InputMode.date,
          InputMode.formula,
          InputMode.code,
        ],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Arrange
  // ---------------------------------------------------------------------

  static const _arrange = PrimitiveCapability(
    primitive: ExercisePrimitive.arrange,
    usesItems: true,
    usesTargets: true,
    notes:
        'Arrange consumes item occurrences: a word used twice needs two '
        'blocks. Reuse is never allowed; reusable choices belong to Select or '
        'Assign.',
    options: [
      OptionDefinition(
        key: OptionKey.placementMode,
        legalValues: [
          PlacementMode.sequence,
          PlacementMode.inlineGaps,
          PlacementMode.grid,
        ],
        defaultValue: EnumOptionValue(PlacementMode.sequence),
      ),
      OptionDefinition(
        key: OptionKey.itemReuse,
        legalValues: [ItemReuse.forbidden],
        defaultValue: EnumOptionValue(ItemReuse.forbidden),
      ),
      OptionDefinition(
        key: OptionKey.unusedItems,
        legalValues: UnusedItems.values,
        defaultValue: EnumOptionValue(UnusedItems.allowed),
        description: 'Whether blocks may be left over (distractors).',
      ),
      OptionDefinition(
        key: OptionKey.layout,
        legalValues: [
          LayoutValue.horizontal,
          LayoutValue.vertical,
          LayoutValue.wrapped,
          LayoutValue.inline,
          LayoutValue.grid,
        ],
        defaultValue: EnumOptionValue(LayoutValue.wrapped),
      ),
      OptionDefinition(
        key: OptionKey.shuffleItems,
        defaultValue: BoolOptionValue(true),
      ),
      OptionDefinition(
        key: OptionKey.joiner,
        legalValues: Joiner.values,
        defaultValue: EnumOptionValue(Joiner.space),
        description:
            'How placed blocks join into the compared text: with spaces or '
            'without (letters building one word).',
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.explicit, EvaluationTiming.onCompletion],
        defaultValue: EnumOptionValue(EvaluationTiming.explicit),
      ),
    ],
    evaluationModes: [
      EvaluationMode.exactOrder,
      EvaluationMode.acceptedOrders,
      EvaluationMode.gapAssignments,
    ],
    defaultEvaluationMode: EvaluationMode.exactOrder,
    rules: [
      OptionImplication(
        id: 'arrange.inlineGaps.layout',
        description: 'Inline gaps live in inline text.',
        key: OptionKey.placementMode,
        when: [PlacementMode.inlineGaps],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.inline],
      ),
      OptionImplication(
        id: 'arrange.grid.layout',
        description: 'Grid placement uses a grid.',
        key: OptionKey.placementMode,
        when: [PlacementMode.grid],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.grid],
      ),
      OptionImplication(
        id: 'arrange.sequence.layout',
        description: 'A sequence runs horizontally, vertically or wrapped.',
        key: OptionKey.placementMode,
        when: [PlacementMode.sequence],
        requiredKey: OptionKey.layout,
        allowed: [
          LayoutValue.horizontal,
          LayoutValue.vertical,
          LayoutValue.wrapped,
        ],
      ),
      EvaluationImplication(
        id: 'arrange.gapAssignments.placement',
        description: 'Gap grading needs inline gaps.',
        modes: [EvaluationMode.gapAssignments],
        key: OptionKey.placementMode,
        allowed: [PlacementMode.inlineGaps],
      ),
      EvaluationImplication(
        id: 'arrange.order.placement',
        description: 'Order grading needs a sequence or a grid.',
        modes: [EvaluationMode.exactOrder, EvaluationMode.acceptedOrders],
        key: OptionKey.placementMode,
        allowed: [PlacementMode.sequence, PlacementMode.grid],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Match
  // ---------------------------------------------------------------------

  static const _match = PrimitiveCapability(
    primitive: ExercisePrimitive.match,
    usesItems: true,
    usesTargets: false,
    notes:
        'Items carry an explicit side (left or right). Relationships other '
        'than one-to-one need reusable items.',
    options: [
      OptionDefinition(
        key: OptionKey.relationship,
        legalValues: MatchRelationship.values,
        defaultValue: EnumOptionValue(MatchRelationship.oneToOne),
      ),
      OptionDefinition(
        key: OptionKey.interactionStyle,
        legalValues: MatchInteractionStyle.values,
        defaultValue: EnumOptionValue(MatchInteractionStyle.dropdown),
      ),
      OptionDefinition(
        key: OptionKey.itemReuse,
        legalValues: [ItemReuse.forbidden, ItemReuse.allowed],
        defaultValue: EnumOptionValue(ItemReuse.forbidden),
      ),
      OptionDefinition(
        key: OptionKey.layout,
        legalValues: [LayoutValue.columns, LayoutValue.cards, LayoutValue.free],
        defaultValue: EnumOptionValue(LayoutValue.columns),
      ),
      OptionDefinition(
        key: OptionKey.shuffleLeft,
        defaultValue: BoolOptionValue(true),
      ),
      OptionDefinition(
        key: OptionKey.shuffleRight,
        defaultValue: BoolOptionValue(true),
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.explicit, EvaluationTiming.onCompletion],
        defaultValue: EnumOptionValue(EvaluationTiming.explicit),
      ),
    ],
    evaluationModes: [
      EvaluationMode.exactRelations,
      EvaluationMode.requiredRelations,
      EvaluationMode.partialRelations,
    ],
    defaultEvaluationMode: EvaluationMode.exactRelations,
    rules: [
      OptionImplication(
        id: 'match.memory.layout',
        description: 'A memory game turns cards.',
        key: OptionKey.interactionStyle,
        when: [MatchInteractionStyle.memory],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.cards],
      ),
      OptionImplication(
        id: 'match.dropdown.layout',
        description: 'Dropdowns sit beside a column of left items.',
        key: OptionKey.interactionStyle,
        when: [MatchInteractionStyle.dropdown],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.columns],
      ),
      OptionImplication(
        id: 'match.pair.layout',
        description: 'Tap-to-pair works on columns or cards.',
        key: OptionKey.interactionStyle,
        when: [MatchInteractionStyle.pair],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.columns, LayoutValue.cards],
      ),
      OptionImplication(
        id: 'match.connect.layout',
        description: 'Lines are drawn between columns or freely placed items.',
        key: OptionKey.interactionStyle,
        when: [MatchInteractionStyle.connect],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.columns, LayoutValue.free],
      ),
      OptionImplication(
        id: 'match.oneToOne.reuse',
        description: 'One-to-one relations use every item once.',
        key: OptionKey.relationship,
        when: [MatchRelationship.oneToOne],
        requiredKey: OptionKey.itemReuse,
        allowed: [ItemReuse.forbidden],
      ),
      OptionImplication(
        id: 'match.many.reuse',
        description: 'Relations with a many side reuse items.',
        key: OptionKey.relationship,
        when: [
          MatchRelationship.oneToMany,
          MatchRelationship.manyToOne,
          MatchRelationship.manyToMany,
        ],
        requiredKey: OptionKey.itemReuse,
        allowed: [ItemReuse.allowed],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Assign
  // ---------------------------------------------------------------------

  static const _assign = PrimitiveCapability(
    primitive: ExercisePrimitive.assign,
    usesItems: true,
    usesTargets: true,
    notes:
        'Items are placed into explicit destinations: categories, slots, '
        'gaps in text, regions of an image or cells of a grid.',
    options: [
      OptionDefinition(
        key: OptionKey.targetMode,
        legalValues: AssignTargetMode.values,
        required: true,
        description: 'What the destinations are.',
      ),
      OptionDefinition(
        key: OptionKey.targetCapacity,
        legalValues: TargetCapacity.values,
        defaultValue: EnumOptionValue(TargetCapacity.single),
      ),
      OptionDefinition(
        key: OptionKey.itemReuse,
        legalValues: ItemReuse.values,
        defaultValue: EnumOptionValue(ItemReuse.forbidden),
      ),
      OptionDefinition(
        key: OptionKey.placementMode,
        legalValues: [
          PlacementMode.drag,
          PlacementMode.selectTarget,
          PlacementMode.tapTarget,
        ],
        defaultValue: EnumOptionValue(PlacementMode.tapTarget),
      ),
      OptionDefinition(
        key: OptionKey.layout,
        legalValues: [
          LayoutValue.inline,
          LayoutValue.columns,
          LayoutValue.overlay,
          LayoutValue.grid,
          LayoutValue.free,
        ],
        defaultValue: EnumOptionValue(LayoutValue.columns),
      ),
      OptionDefinition(
        key: OptionKey.shuffleItems,
        defaultValue: BoolOptionValue(true),
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.explicit, EvaluationTiming.onCompletion],
        defaultValue: EnumOptionValue(EvaluationTiming.explicit),
      ),
    ],
    evaluationModes: [
      EvaluationMode.exactAssignments,
      EvaluationMode.acceptedTargets,
      EvaluationMode.categoryMembership,
      EvaluationMode.partialAssignments,
    ],
    defaultEvaluationMode: EvaluationMode.exactAssignments,
    rules: [
      OptionImplication(
        id: 'assign.gaps.layout',
        description: 'Gaps live in inline text.',
        key: OptionKey.targetMode,
        when: [AssignTargetMode.gaps],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.inline],
      ),
      OptionImplication(
        id: 'assign.regions.layout',
        description: 'Regions are drawn over an image.',
        key: OptionKey.targetMode,
        when: [AssignTargetMode.regions],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.overlay],
      ),
      OptionImplication(
        id: 'assign.cells.layout',
        description: 'Cells belong to a grid.',
        key: OptionKey.targetMode,
        when: [AssignTargetMode.cells],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.grid],
      ),
      OptionImplication(
        id: 'assign.categories.layout',
        description: 'Categories are columns or freely placed groups.',
        key: OptionKey.targetMode,
        when: [AssignTargetMode.categories],
        requiredKey: OptionKey.layout,
        allowed: [LayoutValue.columns, LayoutValue.free],
      ),
      OptionImplication(
        id: 'assign.slots.layout',
        description: 'Slots are never an image overlay.',
        key: OptionKey.targetMode,
        when: [AssignTargetMode.slots],
        requiredKey: OptionKey.layout,
        allowed: [
          LayoutValue.inline,
          LayoutValue.columns,
          LayoutValue.grid,
          LayoutValue.free,
        ],
      ),
      OptionImplication(
        id: 'assign.gaps.capacity',
        description: 'A gap holds one item.',
        key: OptionKey.targetMode,
        when: [AssignTargetMode.gaps],
        requiredKey: OptionKey.targetCapacity,
        allowed: [TargetCapacity.single],
      ),
      EvaluationImplication(
        id: 'assign.categoryMembership.mode',
        description: 'Category membership grades categories.',
        modes: [EvaluationMode.categoryMembership],
        key: OptionKey.targetMode,
        allowed: [AssignTargetMode.categories],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Speak
  // ---------------------------------------------------------------------

  static const _speak = PrimitiveCapability(
    primitive: ExercisePrimitive.speak,
    usesItems: false,
    usesTargets: false,
    notes:
        'The learner produces speech; a spoken prompt is media, not Speak. '
        'No recognition or pronunciation runtime exists yet.',
    options: [
      OptionDefinition(
        key: OptionKey.speechMode,
        legalValues: SpeechMode.values,
        defaultValue: EnumOptionValue(SpeechMode.repeat),
      ),
      OptionDefinition(
        key: OptionKey.captureMode,
        legalValues: CaptureMode.values,
        defaultValue: EnumOptionValue(CaptureMode.microphone),
      ),
      OptionDefinition(
        key: OptionKey.language,
        description:
            'The language spoken; absent means the Course target language.',
      ),
      OptionDefinition(
        key: OptionKey.transcription,
        legalValues: TranscriptionMode.values,
        defaultValue: EnumOptionValue(TranscriptionMode.optional),
      ),
      OptionDefinition(
        key: OptionKey.playback,
        legalValues: SpeakPlayback.values,
        defaultValue: EnumOptionValue(SpeakPlayback.allowed),
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.explicit, EvaluationTiming.onCompletion],
        defaultValue: EnumOptionValue(EvaluationTiming.explicit),
      ),
      OptionDefinition(
        key: OptionKey.maxDurationSeconds,
        minimum: 1,
        description: 'Recording limit; absent means none.',
      ),
    ],
    evaluationModes: [
      EvaluationMode.transcriptionMatch,
      EvaluationMode.acceptedTranscriptions,
      EvaluationMode.pronunciation,
      EvaluationMode.combined,
      EvaluationMode.manual,
      EvaluationMode.none,
    ],
    defaultEvaluationMode: EvaluationMode.transcriptionMatch,
    rules: [
      EvaluationImplication(
        id: 'speak.transcription.needed',
        description: 'Grading a transcription needs one.',
        modes: [
          EvaluationMode.transcriptionMatch,
          EvaluationMode.acceptedTranscriptions,
          EvaluationMode.combined,
        ],
        key: OptionKey.transcription,
        allowed: [TranscriptionMode.optional, TranscriptionMode.required],
      ),
      OptionEvaluationImplication(
        id: 'speak.freeResponse.evaluation',
        description:
            'A free response has no expected text to grade automatically.',
        key: OptionKey.speechMode,
        when: [SpeechMode.freeResponse],
        allowedModes: [EvaluationMode.manual, EvaluationMode.none],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Ink
  // ---------------------------------------------------------------------

  static const _ink = PrimitiveCapability(
    primitive: ExercisePrimitive.ink,
    usesItems: false,
    usesTargets: false,
    notes: 'Handwriting, tracing and character writing; no runtime yet.',
    options: [
      OptionDefinition(
        key: OptionKey.inkMode,
        legalValues: InkMode.values,
        defaultValue: EnumOptionValue(InkMode.freehand),
      ),
      OptionDefinition(
        key: OptionKey.inputDevice,
        legalValues: InputDevice.values,
        defaultValue: EnumOptionValue(InputDevice.any),
      ),
      OptionDefinition(
        key: OptionKey.strokeOrder,
        legalValues: StrokeOrder.values,
        defaultValue: EnumOptionValue(StrokeOrder.ignored),
      ),
      OptionDefinition(
        key: OptionKey.templateVisible,
        defaultValue: BoolOptionValue(false),
      ),
      OptionDefinition(
        key: OptionKey.eraseAllowed,
        defaultValue: BoolOptionValue(true),
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.explicit, EvaluationTiming.onCompletion],
        defaultValue: EnumOptionValue(EvaluationTiming.explicit),
      ),
    ],
    evaluationModes: [
      EvaluationMode.recognition,
      EvaluationMode.strokeMatch,
      EvaluationMode.shapeSimilarity,
      EvaluationMode.manual,
      EvaluationMode.none,
    ],
    defaultEvaluationMode: EvaluationMode.recognition,
    rules: [
      OptionImplication(
        id: 'ink.strokeOrder.mode',
        description: 'Stroke order exists only against a template.',
        key: OptionKey.strokeOrder,
        when: [StrokeOrder.checked],
        requiredKey: OptionKey.inkMode,
        allowed: [InkMode.trace, InkMode.character],
      ),
      EvaluationImplication(
        id: 'ink.strokeMatch.mode',
        description: 'Stroke matching needs a traced or character template.',
        modes: [EvaluationMode.strokeMatch],
        key: OptionKey.inkMode,
        allowed: [InkMode.trace, InkMode.character],
      ),
      EvaluationImplication(
        id: 'ink.recognition.mode',
        description:
            'Recognition reads handwriting or characters, not diagrams.',
        modes: [EvaluationMode.recognition],
        key: OptionKey.inkMode,
        allowed: [InkMode.freehand, InkMode.trace, InkMode.character],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------

  static const _submit = PrimitiveCapability(
    primitive: ExercisePrimitive.submit,
    usesItems: false,
    usesTargets: false,
    notes:
        'An artifact QQL stores for review. A recording QQL analyses is '
        'Speak, not Submit. No runtime yet.',
    options: [
      OptionDefinition(
        key: OptionKey.submissionType,
        legalValues: SubmissionType.values,
        required: true,
      ),
      OptionDefinition(
        key: OptionKey.cardinality,
        legalValues: Cardinality.values,
        defaultValue: EnumOptionValue(Cardinality.single),
      ),
      OptionDefinition(
        key: OptionKey.captureSource,
        legalValues: CaptureSource.values,
        defaultValue: EnumOptionValue(CaptureSource.either),
      ),
      OptionDefinition(
        key: OptionKey.reviewMode,
        legalValues: ReviewMode.values,
        defaultValue: EnumOptionValue(ReviewMode.self),
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.none, EvaluationTiming.onCompletion],
        defaultValue: EnumOptionValue(EvaluationTiming.onCompletion),
      ),
    ],
    evaluationModes: [
      EvaluationMode.presence,
      EvaluationMode.manual,
      EvaluationMode.none,
    ],
    defaultEvaluationMode: EvaluationMode.presence,
    rules: [
      OptionEvaluationImplication(
        id: 'submit.noTiming.evaluation',
        description: 'Without an evaluation moment nothing is evaluated.',
        key: OptionKey.evaluationTiming,
        when: [EvaluationTiming.none],
        allowedModes: [EvaluationMode.none],
      ),
      EvaluationImplication(
        id: 'submit.evaluated.timing',
        description: 'Presence and manual review happen on completion.',
        modes: [EvaluationMode.presence, EvaluationMode.manual],
        key: OptionKey.evaluationTiming,
        allowed: [EvaluationTiming.onCompletion],
      ),
      OptionImplication(
        id: 'submit.device.type',
        description:
            'A device captures audio, video, images or typed text, not files.',
        key: OptionKey.captureSource,
        when: [CaptureSource.device],
        requiredKey: OptionKey.submissionType,
        allowed: [
          SubmissionType.audio,
          SubmissionType.video,
          SubmissionType.image,
          SubmissionType.textDocument,
        ],
      ),
    ],
  );

  // ---------------------------------------------------------------------
  // Presentation
  // ---------------------------------------------------------------------

  static const _presentation = PrimitiveCapability(
    primitive: ExercisePrimitive.presentation,
    usesItems: false,
    usesTargets: false,
    notes:
        'Flashcards, explanations, examples, vocabulary presentations and '
        'other unscored material. Never scored, never evaluated.',
    options: [
      OptionDefinition(
        key: OptionKey.completionMode,
        legalValues: CompletionMode.values,
        defaultValue: EnumOptionValue(CompletionMode.proceed),
      ),
      OptionDefinition(
        key: OptionKey.navigation,
        legalValues: PresentationNavigation.values,
        defaultValue: EnumOptionValue(PresentationNavigation.singlePage),
      ),
      OptionDefinition(
        key: OptionKey.mediaPlayback,
        legalValues: MediaPlayback.values,
        defaultValue: EnumOptionValue(MediaPlayback.manual),
      ),
      OptionDefinition(
        key: OptionKey.textReveal,
        legalValues: TextReveal.values,
        defaultValue: EnumOptionValue(TextReveal.immediate),
      ),
      // Build 257: the first card action beyond Continue. The learner sees
      // the button only while the Course uses GuideBooks and the Lesson's
      // GuideBook is published.
      OptionDefinition(
        key: OptionKey.guidebookButton,
        defaultValue: BoolOptionValue(false),
      ),
      OptionDefinition(
        key: OptionKey.scoring,
        legalValues: Scoring.values,
        defaultValue: EnumOptionValue(Scoring.none),
      ),
      OptionDefinition(
        key: OptionKey.evaluationTiming,
        legalValues: [EvaluationTiming.none],
        defaultValue: EnumOptionValue(EvaluationTiming.none),
      ),
    ],
    evaluationModes: [EvaluationMode.none],
    defaultEvaluationMode: EvaluationMode.none,
  );
}
