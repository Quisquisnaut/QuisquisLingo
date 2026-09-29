/// The machine-readable description of the capability registry (Build 256
/// Revision 6, plan A.13): every primitive with its options (type, legal
/// values, default, required, minimum), evaluation modes, rules and the
/// runtime-support table of this version. `tools/export_capabilities.dart`
/// writes it to `docs/capabilities_v12.json`; a test pins the file to this
/// code, and the Python tools (`tools/qql_capabilities.py`) read the file
/// instead of keeping tables of their own.
library;

import 'dart:convert';

import 'evaluation_mode.dart';
import 'exercise_primitive.dart';
import 'primitive_capability_registry.dart';
import 'primitive_options.dart';

/// The description as JSON data, in a stable order.
Map<String, Object?> capabilityDescription() => {
  'formatVersion': 12,
  'generatedBy': 'tools/export_capabilities.dart',
  'optionKeys': [for (final key in OptionKey.values) key.serialized],
  'primitives': [
    for (final primitive in ExercisePrimitive.values)
      _primitive(PrimitiveCapabilityRegistry.capabilityOf(primitive)),
  ],
};

/// The description as pretty JSON with a trailing newline.
String capabilityDescriptionJson() =>
    '${const JsonEncoder.withIndent('  ').convert(capabilityDescription())}\n';

Map<String, Object?> _primitive(PrimitiveCapability capability) => {
  'id': capability.primitive.serialized,
  'label': capability.primitive.label,
  'learnerAction': capability.primitive.learnerAction,
  'usesItems': capability.usesItems,
  'usesTargets': capability.usesTargets,
  'notes': capability.notes,
  'options': [for (final option in capability.options) _option(option)],
  'evaluationModes': [
    for (final mode in capability.evaluationModes) mode.serialized,
  ],
  'defaultEvaluationMode': capability.defaultEvaluationMode.serialized,
  'rules': [for (final rule in capability.rules) _rule(rule)],
  'runtimeSupport': [
    for (final configuration in PrimitiveCapabilityRegistry.runtimeSupportTable)
      if (configuration.primitive == capability.primitive)
        _configuration(configuration),
  ],
};

Map<String, Object?> _option(OptionDefinition option) => {
  'key': option.key.serialized,
  'type': option.key.kind.name,
  if (option.key.kind == OptionValueKind.enumeration)
    'values': [for (final value in option.legalValues) value.serialized],
  'default': option.defaultValue?.serialized,
  'required': option.required,
  if (option.minimum != null) 'minimum': option.minimum,
  'description': option.description,
};

Map<String, Object?> _rule(CapabilityRule rule) => {
  'id': rule.id,
  'kind': switch (rule) {
    OptionImplication() => 'optionImplication',
    OptionRequiresIntegers() => 'optionRequiresIntegers',
    EvaluationImplication() => 'evaluationImplication',
    OptionEvaluationImplication() => 'optionEvaluationImplication',
    IntegerOrderRule() => 'integerOrder',
  },
  'description': rule.description,
  ...switch (rule) {
    OptionImplication(
      :final key,
      when: final whenValues,
      :final requiredKey,
      :final allowed,
    ) =>
      {
        'key': key.serialized,
        'when': [for (final value in whenValues) value.serialized],
        'requiredKey': requiredKey.serialized,
        'allowed': [for (final value in allowed) value.serialized],
      },
    OptionRequiresIntegers(
      :final key,
      when: final whenValues,
      :final integerKey,
      :final allowed,
    ) =>
      {
        'key': key.serialized,
        'when': [for (final value in whenValues) value.serialized],
        'integerKey': integerKey.serialized,
        'allowed': allowed,
      },
    EvaluationImplication(:final modes, :final key, :final allowed) => {
      'modes': [for (final mode in modes) mode.serialized],
      'key': key.serialized,
      'allowed': [for (final value in allowed) value.serialized],
    },
    OptionEvaluationImplication(
      :final key,
      when: final whenValues,
      :final allowedModes,
    ) =>
      {
        'key': key.serialized,
        'when': [for (final value in whenValues) value.serialized],
        'allowedModes': [for (final mode in allowedModes) mode.serialized],
      },
    IntegerOrderRule(:final lowerKey, :final upperKey) => {
      'lowerKey': lowerKey.serialized,
      'upperKey': upperKey.serialized,
    },
  },
};

Map<String, Object?> _configuration(SupportedConfiguration configuration) => {
  'description': configuration.description,
  'evaluationModes': [
    for (final mode in configuration.evaluationModes) mode.serialized,
  ],
  'values': {
    for (final entry in configuration.values.entries)
      entry.key.serialized: [for (final value in entry.value) value.serialized],
  },
};

/// The evaluation modes of the whole vocabulary, for tools that need them
/// independently of a primitive.
List<String> get allEvaluationModes => EvaluationMode.serializedValues;
