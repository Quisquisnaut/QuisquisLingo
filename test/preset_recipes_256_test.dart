import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';

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

  group('every Laboratory example is represented by its own preset', () {
    final course = _load('exercise_laboratory_en_it.json');
    for (final content in _exerciseContent(course)) {
      final exercise = content.exercise!;
      test('${content.id} (${content.editorTemplate})', () {
        final presetId = content.editorTemplate;
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
        .firstWhere((content) => content.editorTemplate == 'choice')
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
    expect(PresetRecipes.presetToEdit(withExtraAudio), 'choice');
    expect(ExerciseFeatures(withExtraAudio).kind, LearnerExerciseKind.select);
  });

  test('an exercise keeps opening in the preset it carries', () {
    final course = _load('exercise_laboratory_en_it.json');
    final matching = _exerciseContent(
      course,
    ).firstWhere((content) => content.editorTemplate == 'matching').exercise!;
    expect(PresetRecipes.presetToEdit(matching), 'matching');
    final asWordMatch = matching.withAuthoringMetadata(const {
      'presetId': 'word_match',
    });
    expect(PresetRecipes.presetToEdit(asWordMatch), 'word_match');
    expect(PresetRecipes.represents(asWordMatch, 'word_match'), isFalse);
  });
}
