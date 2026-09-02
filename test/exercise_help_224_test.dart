import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';

void main() {
  test(
    'every offered preset has exactly one Help entry and no stale entry',
    () {
      final presetIds = ExercisePresetRegistry.presets
          .map((preset) => preset.id)
          .toSet();
      expect(ExercisePresetRegistry.helpByPreset.keys.toSet(), presetIds);
      for (final text in ExercisePresetRegistry.helpByPreset.values) {
        expect(text.trim(), isNotEmpty);
      }
    },
  );

  test('author-facing Help does not contain engineering source labels', () {
    final authorHelp = [
      ...ExercisePresetRegistry.presets.map(
        (preset) => '${preset.name} ${preset.description}',
      ),
      ...ExercisePresetRegistry.helpByPreset.values,
    ].join('\n');
    for (final forbidden in [
      'PickOne',
      'ImagePick',
      'PickOneAudio',
      'SpellingPick',
      'WriteWords',
      'PickWords',
      'PickOneMeaning',
      'PickMissingWord',
    ]) {
      expect(authorHelp, isNot(contains(forbidden)));
    }
  });

  testWidgets(
    'Help renders every preset and answer/context guidance responsively',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: ExerciseHelpScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise-help-list')), findsOneWidget);
      expect(find.text('How do you say'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Answer variants'), 500);
      expect(find.text('Answer variants'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Contextual comprehension example'),
        500,
      );
      expect(find.text('Contextual comprehension example'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
