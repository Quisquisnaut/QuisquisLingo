import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/preset_variants.dart';

/// Build 256 Session 4: presets as optional recipes. Decompose → rebuild →
/// semantically equal is what "the preset represents the exercise" means;
/// recognition never writes; near matches are not matches.
Course _load(String file) => Course.fromJson(
  jsonDecode(File('assets/courses/$file').readAsStringSync())
      as Map<String, dynamic>,
);

Iterable<LearningContent> _exerciseContent(Course course) sync* {
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final content in round.content) {
        if (content.exercise != null) yield content;
      }
    }
  }
}

void main() {
  test('the preset kinds are the Audit\'s and cover every preset', () {
    expect(PresetRecipes.kinds, CourseAuditService.presetKinds);
    expect(
      PresetRecipes.kinds.keys.toSet(),
      ExercisePresetRegistry.presets.map((preset) => preset.id).toSet(),
    );
    for (final preset in ExercisePresetRegistry.presets) {
      expect(
        PresetRecipes.defaultPresetFor(preset.primitive),
        isNotNull,
        reason: preset.id,
      );
    }
    for (final primitive in [
      ExercisePrimitive.assign,
      ExercisePrimitive.speak,
      ExercisePrimitive.ink,
      ExercisePrimitive.submit,
    ]) {
      expect(PresetRecipes.defaultPresetFor(primitive), isNull);
    }
  });

  test('the shape rule tells the presets of one recipe apart', () {
    final course = _load('exercise_laboratory_en_it.json');
    Exercise example(String id) =>
        _exerciseContent(course).firstWhere((c) => c.id == id).exercise!;
    final letters = example('qql_lab254_missing_letters');
    final word = example('qql_lab254_input_missing_one');
    final picture = example('qql_lab254_image_letters');
    expect(PresetVariants.hasInWordGap(letters), isTrue);
    expect(PresetVariants.hasInWordGap(word), isFalse);
    expect(PresetVariants.fits('missing_letters', letters), isTrue);
    expect(PresetVariants.fits('complete_text', letters), isFalse);
    expect(PresetVariants.fits('missing_letters', word), isFalse);
    expect(PresetVariants.fits('missing_word', word), isTrue);
    expect(PresetVariants.fits('image_word', picture), isTrue);
    expect(PresetVariants.fits('spell_heard', picture), isFalse);
    expect(PresetVariants.fits('spell_word', picture), isFalse);
  });

  group('every Laboratory example is represented by its own preset', () {
    final course = _load('exercise_laboratory_en_it.json');
    for (final content in _exerciseContent(course)) {
      final exercise = content.exercise!;
      test('${content.id} (${content.editorTemplate})', () {
        final presetId = content.editorTemplate;
        if (presetId.isEmpty) {
          // The Assign Lesson has no preset (Build 256 Revision 7): no
          // recipe represents it and recognition names none.
          expect(exercise.primitive, ExercisePrimitive.assign);
          expect(PresetRecipes.recognize(exercise), isNull);
          expect(PresetRecipes.presetToEdit(exercise), isNull);
          return;
        }
        expect(PresetRecipes.represents(exercise, presetId), isTrue);
        // Recognition finds the same preset once the metadata is gone.
        final stripped = exercise.withAuthoringMetadata(const {});
        expect(PresetRecipes.recognize(stripped), presetId);
        expect(PresetRecipes.presetToEdit(stripped), presetId);
        // Nothing was written.
        expect(stripped.editorTemplate, isEmpty);
      });
    }
  });

  test('a shape no recipe expresses is not recognized', () {
    final course = _load('exercise_laboratory_en_it.json');
    final plain = _exerciseContent(course)
        .firstWhere((content) => content.editorTemplate == 'choice_target')
        .exercise!
        .withAuthoringMetadata(const {});
    // A second, manual audio element is nothing the Choose form can show.
    final withExtraAudio = plain.copyWith(
      promptElements: [
        ...plain.promptElements,
        const PromptElement(type: 'audio', text: 'Extra spoken text'),
      ],
    );
    expect(PresetRecipes.recognize(withExtraAudio), isNull);
    expect(PresetRecipes.presetToEdit(withExtraAudio), 'choice_target');
    expect(ExerciseFeatures(withExtraAudio).kind, LearnerExerciseKind.select);
  });

  test('an exercise keeps opening in the preset it carries', () {
    final course = _load('exercise_laboratory_en_it.json');
    final wordMatch = _exerciseContent(
      course,
    ).firstWhere((content) => content.editorTemplate == 'word_match').exercise!;
    expect(PresetRecipes.presetToEdit(wordMatch), 'word_match');
    final asSuperMatch = wordMatch.withAuthoringMetadata(const {
      'presetId': 'super_match',
    });
    expect(PresetRecipes.presetToEdit(asSuperMatch), 'super_match');
    expect(PresetRecipes.represents(asSuperMatch, 'super_match'), isFalse);
  });
}
