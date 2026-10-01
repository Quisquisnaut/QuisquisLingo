import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

/// Build 260 Revision 3 (owner review of 1 October 2026): Pick the missing
/// word and One word fills all take an Instruction or context, the
/// Piedmontese demo's exercises are all represented by their presets (it
/// showcases them), and the QQL Demo Courses keep a Before you start card on
/// the first Round of each Lesson only.

final _stamp = DateTime.utc(2026, 10, 1);

Course _load(String file) => Course.fromJson(
  jsonDecode(File('assets/courses/$file').readAsStringSync())
      as Map<String, dynamic>,
);

const _bundled = [
  'exercise_laboratory_en_it.json',
  'piedmontais_en.json',
  'piedmontese_mixed_en.json',
  'english_from_italian_it_en.json',
];

Exercise _built(String presetId, {required String prompt}) {
  final result = ExerciseDraftBuilder.build(
    ExerciseDraftValues(
      original: Exercise(
        id: 'blank-$presetId',
        publicationState: PublicationState.draft,
        updatedAt: _stamp,
        type: ExercisePresetRegistry.byId(presetId)!.base,
        prompt: '',
        question: '',
        answers: const [],
        correct: null,
        tts: null,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      ),
      type: presetId,
      publicationState: PublicationState.published,
      prompt: prompt,
      question: presetId == 'gap_choice'
          ? 'ël ___'
          : 'I l’hai ___ gat e ___ can.',
      answers: 'pan\ncan\npom',
      correct: '2',
    ),
  );
  expect(result.error, isNull, reason: '$presetId: ${result.error?.code}');
  return result.candidate!;
}

void main() {
  group('Pick the missing word and One word fills all', () {
    for (final presetId in ['gap_choice', 'one_word_fills_all']) {
      test('$presetId keeps an Instruction or context', () {
        expect(
          ExerciseFieldHelpRegistry.editorFieldKeys(presetId).first,
          'prompt',
        );
        final exercise = _built(
          presetId,
          prompt: 'Complete the phrase meaning the dog.',
        );
        final features = ExerciseFeatures(exercise);
        expect(features.primaryText, 'Complete the phrase meaning the dog.');
        expect(
          features.authoredInstruction,
          'Complete the phrase meaning the dog.',
        );
        expect(PresetRecipes.represents(exercise, presetId), isTrue);
        expect(
          PresetRecipes.decompose(exercise, presetId).prompt,
          'Complete the phrase meaning the dog.',
        );
        // Without one, nothing is stored.
        expect(
          ExerciseFeatures(_built(presetId, prompt: '')).primaryText,
          isEmpty,
        );
      });
    }
  });

  test('every exercise of the bundled Courses is represented', () {
    for (final file in _bundled) {
      final course = _load(file);
      final unrepresented = [
        for (final lesson in course.lessons)
          for (final round in lesson.rounds)
            for (final content in round.content)
              if (content.exercise != null &&
                  content.editorTemplate.isNotEmpty &&
                  !PresetRecipes.represents(
                    content.exercise!,
                    content.editorTemplate,
                  ))
                content.id,
      ];
      expect(unrepresented, isEmpty, reason: file);
    }
  });

  group('the Piedmontese demo', () {
    final course = _load('piedmontais_en.json');
    Iterable<Exercise> byPreset(String preset) => [
      for (final lesson in course.lessons)
        for (final round in lesson.rounds)
          for (final content in round.content)
            if (content.editorTemplate == preset) content.exercise!,
    ];

    test('Pick the missing word keeps its instructions', () {
      expect(
        byPreset(
          'gap_choice',
        ).map((exercise) => ExerciseFeatures(exercise).authoredInstruction),
        [
          'Complete the phrase meaning the dog.',
          'Complete the phrase meaning the house.',
          'Complete the greeting meaning good morning.',
        ],
      );
    });

    test('Listen and answer (to source) marks its answers source', () {
      for (final exercise in byPreset('listening_answer_source')) {
        expect(
          ExerciseFeatures(exercise).itemLanguage,
          TextLanguage.source,
          reason: exercise.id,
        );
      }
    });

    test('Spell the word in the picture stores the blocks in order', () {
      for (final exercise in byPreset('image_word')) {
        expect(exercise.canonicalEvaluation.correctOrders.single.itemIds, [
          for (final item in exercise.items) item.id,
        ], reason: exercise.id);
      }
    });
  });

  test('the QQL Demo Courses open only each Lesson\'s first Round with a '
      'card', () {
    for (final file in [
      'piedmontese_mixed_en.json',
      'english_from_italian_it_en.json',
    ]) {
      final course = _load(file);
      for (final lesson in course.lessons) {
        for (final (index, round) in lesson.rounds.indexed) {
          expect(
            RoundPlayabilityService().introFor(round) != null,
            index == 0,
            reason: '$file ${round.id}',
          );
        }
      }
    }
  });
}
