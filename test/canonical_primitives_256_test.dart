import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/canonical/canonical.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';

void main() {
  test('exactly the nine intended primitives exist, in order', () {
    expect(ExercisePrimitive.values, hasLength(9));
    expect(ExercisePrimitive.serializedValues, [
      'select',
      'input',
      'arrange',
      'match',
      'assign',
      'speak',
      'ink',
      'submit',
      'presentation',
    ]);
    for (final primitive in ExercisePrimitive.values) {
      expect(primitive.label.trim(), isNotEmpty);
      expect(primitive.learnerAction.trim(), endsWith('.'));
      expect(primitive.serialized, primitive.serialized.toLowerCase());
    }
  });

  test('primitive parsing is strict', () {
    expect(ExercisePrimitive.tryParse('select'), ExercisePrimitive.select);
    expect(
      ExercisePrimitive.tryParse('presentation'),
      ExercisePrimitive.presentation,
    );
    for (final bad in [
      'Select',
      'SELECT',
      ' select',
      'select ',
      'story',
      'translation',
      'cloze',
      '',
      null,
      1,
      true,
    ]) {
      expect(ExercisePrimitive.tryParse(bad), isNull, reason: '$bad');
    }
    expect(
      () => ExercisePrimitive.parse('Story'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('Story'),
            contains('select'),
            contains('presentation'),
          ),
        ),
      ),
    );
  });

  test(
    'evaluation modes have unique stable identifiers and strict parsing',
    () {
      final ids = EvaluationMode.serializedValues;
      expect(ids.toSet(), hasLength(ids.length));
      expect(EvaluationMode.tryParse('exactSet'), EvaluationMode.exactSet);
      expect(EvaluationMode.tryParse('exactset'), isNull);
      expect(EvaluationMode.tryParse('ExactSet'), isNull);
      expect(EvaluationMode.tryParse(null), isNull);
      expect(() => EvaluationMode.parse('fuzzy'), throwsFormatException);
    },
  );

  test('every option key has a unique JSON name and a matching vocabulary', () {
    final names = OptionKey.values.map((key) => key.serialized).toList();
    expect(names.toSet(), hasLength(names.length));
    for (final key in OptionKey.values) {
      if (key.kind == OptionValueKind.enumeration) {
        expect(key.vocabulary, isNotEmpty, reason: key.serialized);
        final values = key.vocabulary.map((value) => value.serialized);
        expect(
          values.toSet(),
          hasLength(values.length),
          reason: key.serialized,
        );
      } else {
        expect(key.vocabulary, isEmpty, reason: key.serialized);
      }
      expect(OptionKey.tryParse(key.serialized), key);
    }
    expect(OptionKey.tryParse('SelectionMode'), isNull);
    expect(CompletionMode.proceed.serialized, 'continue');
  });

  test('invalid option values never become canonical values', () {
    expect(
      OptionValue.parse(OptionKey.selectionMode, 'single'),
      const EnumOptionValue(SelectionMode.single),
    );
    expect(OptionValue.parse(OptionKey.selectionMode, 'Single'), isNull);
    expect(OptionValue.parse(OptionKey.selectionMode, 'both'), isNull);
    expect(OptionValue.parse(OptionKey.selectionMode, 1), isNull);
    expect(OptionValue.parse(OptionKey.shuffleItems, 'true'), isNull);
    expect(OptionValue.parse(OptionKey.shuffleItems, 1), isNull);
    expect(
      OptionValue.parse(OptionKey.shuffleItems, false),
      const BoolOptionValue(false),
    );
    expect(OptionValue.parse(OptionKey.minimumSelections, 2.0), isNull);
    expect(OptionValue.parse(OptionKey.minimumSelections, '2'), isNull);
    expect(
      OptionValue.parse(OptionKey.minimumSelections, 2),
      const IntOptionValue(2),
    );
    expect(OptionValue.parse(OptionKey.language, ''), isNull);
    expect(OptionValue.parse(OptionKey.language, 'italian language'), isNull);
    expect(
      OptionValue.parse(OptionKey.language, 'pt-BR'),
      const LanguageOptionValue('pt-BR'),
    );
  });

  test('PrimitiveOptions is an immutable, order-independent value', () {
    final a = PrimitiveOptions({
      OptionKey.layout: const EnumOptionValue(LayoutValue.grid),
      OptionKey.selectionMode: const EnumOptionValue(SelectionMode.single),
    });
    final b = PrimitiveOptions({
      OptionKey.selectionMode: const EnumOptionValue(SelectionMode.single),
      OptionKey.layout: const EnumOptionValue(LayoutValue.grid),
    });
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toJson(), {'selectionMode': 'single', 'layout': 'grid'});
    expect(
      a.enumValue<SelectionMode>(OptionKey.selectionMode),
      SelectionMode.single,
    );
    expect(a.enumValue<LayoutValue>(OptionKey.selectionMode), isNull);
    expect(a.withEnum(OptionKey.layout, LayoutValue.list), isNot(a));
    expect(a.without(OptionKey.layout).keys, [OptionKey.selectionMode]);
    expect(
      () => a.values[OptionKey.joiner] = const EnumOptionValue(Joiner.none),
      throwsUnsupportedError,
    );
  });

  test('presets configure only executable primitives and never add one', () {
    final primitives = ExercisePresetRegistry.presets
        .map((preset) => preset.primitive)
        .toSet();
    // Build 256 Revision 7 follow-up: Assign plays and has two presets
    // (Sort into groups, Fill the slots).
    expect(primitives, ExercisePrimitive.executableToday.toSet());
    for (final preset in ExercisePresetRegistry.presets) {
      expect(ExercisePrimitive.values, contains(preset.primitive));
    }
  });
}
