import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart'
    as course_editor;
import 'package:quisquislingo_app/screens/exercise_editor_screen.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';

/// Build 272 Revision 5: the exercise editor has its own file; the two
/// small rules it shared with the Course Editor file have owners.
void main() {
  test('the exercise editor is in its own file and still reachable from '
      'the Course Editor file', () {
    // Other screens and tests import the Course Editor file for it.
    expect(course_editor.ExerciseEditorScreen, ExerciseEditorScreen);
    final editor = File(
      'lib/screens/course_editor_screen.dart',
    ).readAsStringSync();
    expect(editor, isNot(contains('class ExerciseEditorScreen')));
    expect(
      File('lib/screens/exercise_editor_screen.dart').readAsStringSync(),
      contains('class ExerciseEditorScreen extends StatefulWidget'),
    );
  });

  group('a new exercise of a preset', () {
    test('is a Draft with the ID given, of that preset, for every preset', () {
      for (final preset in ExercisePresetRegistry.presets) {
        final blank = PresetRecipes.blankFor(preset.id, 'new-1');
        expect(blank.id, 'new-1', reason: preset.id);
        expect(
          blank.publicationState,
          PublicationState.draft,
          reason: preset.id,
        );
        expect(blank.editorTemplate, preset.id, reason: preset.id);
        // Its form can open it: the preset's own recipe reads it.
        expect(PresetRecipes.presetToEdit(blank), preset.id, reason: preset.id);
      }
    });

    test('of a recipe without an earlier shape is a presentation from the '
        'start', () {
      for (final presetId in PresetRecipes.canonicalOnly) {
        final blank = PresetRecipes.blankFor(presetId, 'new-2');
        expect(blank.id, 'new-2', reason: presetId);
        expect(blank.editorTemplate, presetId, reason: presetId);
      }
    });
  });

  test('the name an author reads for a preset ID', () {
    for (final preset in ExercisePresetRegistry.presets) {
      expect(ExercisePresetRegistry.nameOrId(preset.id), preset.name);
    }
    // A preset this version does not know keeps its ID, readable.
    expect(
      ExercisePresetRegistry.nameOrId('some_future_preset'),
      'some future preset',
    );
  });
}
