import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/canonical/capability_description.dart';
import 'package:quisquislingo_app/models/course_models.dart';

/// Build 256 Revision 6 (plan A.13): the committed capability description
/// `docs/capabilities_v12.json` is exactly what the registry describes, so
/// the Python tools that read it cannot drift from the Dart registry. Run
/// `dart run tools/export_capabilities.dart` after a registry change.
void main() {
  test('docs/capabilities_v12.json matches the registry', () {
    final file = File('docs/capabilities_v12.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'run tools/export_capabilities.dart',
    );
    final committed = file.readAsStringSync().replaceAll('\r\n', '\n');
    expect(
      committed,
      capabilityDescriptionJson(),
      reason:
          'docs/capabilities_v12.json is stale: run dart run tools/export_capabilities.dart',
    );
  });

  test('the description carries what the Python tools read', () {
    final description = capabilityDescription();
    expect(description['formatVersion'], 12);
    final keys = (description['optionKeys'] as List).cast<String>();
    expect(keys, [for (final key in OptionKey.values) key.serialized]);
    final primitives = (description['primitives'] as List)
        .cast<Map<String, Object?>>();
    expect(
      primitives.map((primitive) => primitive['id']),
      ExercisePrimitive.serializedValues,
    );
    for (final primitive in primitives) {
      final options = (primitive['options'] as List)
          .cast<Map<String, Object?>>();
      expect(options, isNotEmpty, reason: '${primitive['id']}');
      for (final option in options) {
        expect(keys, contains(option['key']));
        final type = option['type'] as String;
        expect([
          'enumeration',
          'boolean',
          'integer',
          'language',
        ], contains(type));
        if (type == 'enumeration') {
          expect((option['values'] as List), isNotEmpty);
        } else {
          expect(option.containsKey('values'), isFalse);
        }
      }
      final modes = (primitive['evaluationModes'] as List).cast<String>();
      expect(modes, isNotEmpty);
      expect(modes, contains(primitive['defaultEvaluationMode']));
      for (final mode in modes) {
        expect(EvaluationMode.serializedValues, contains(mode));
      }
      for (final configuration
          in (primitive['runtimeSupport'] as List)
              .cast<Map<String, Object?>>()) {
        final values = configuration['values'] as Map<String, Object?>;
        for (final key in values.keys) {
          expect(
            options.map((option) => option['key']),
            contains(key),
            reason: '${primitive['id']} runtime support names $key',
          );
        }
      }
    }
    // The JSON is valid and round-trips.
    expect(jsonDecode(capabilityDescriptionJson()), description);
  });
}
