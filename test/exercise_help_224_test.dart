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
      // Phone width; tall enough to lay every section out at once (the
      // catalogue's 38 presets and the supplements), so nothing is scrolled.
      tester.view.physicalSize = const Size(320, 60000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: ExerciseHelpScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise-help-list')), findsOneWidget);
      expect(find.text('Type the translation (to target)'), findsOneWidget);
      expect(find.text('Answer variants'), findsOneWidget);
      expect(find.text('Read and answer example'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
