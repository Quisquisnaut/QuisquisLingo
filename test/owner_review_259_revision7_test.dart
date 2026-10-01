import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';

/// Build 259 Revision 7 (owner review of 1 October 2026): Type and Build the
/// translation name the language of the answer (a "to source" exercise said
/// "Translate from English into Piedmontese"), and the standard lines no
/// longer repeat their exercise title.

Course _load(String file) => Course.fromJson(
  jsonDecode(File('assets/courses/$file').readAsStringSync())
      as Map<String, dynamic>,
);

final _piedmontese = _load('piedmontais_en.json');
final _mixed = _load('piedmontese_mixed_en.json');
final _laboratory = _load('exercise_laboratory_en_it.json');

Iterable<LearningContent> _contents(Course course) => course.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.content);

List<Exercise> _byPreset(Course course, String preset) => [
  for (final content in _contents(course))
    if (content.editorTemplate == preset) content.exercise!,
];

String _line(Course course, Exercise exercise) =>
    ExerciseCopyService.instructionForExercise(course, exercise);

void main() {
  group('2. Translations name the language of the answer', () {
    for (final course in [_piedmontese, _mixed]) {
      test('${course.title}: Type the translation, both directions', () {
        for (final exercise in _byPreset(
          course,
          'type_translation_to_source',
        )) {
          expect(_line(course, exercise), 'Translate into English.');
        }
        for (final exercise in _byPreset(
          course,
          'type_translation_to_target',
        )) {
          expect(_line(course, exercise), 'Translate into Piedmontese.');
        }
      });
    }

    test('Build the translation, both directions', () {
      for (final exercise in _byPreset(
        _piedmontese,
        'build_translation_to_source',
      )) {
        expect(
          _line(_piedmontese, exercise),
          'Translate into English with the word blocks.',
        );
      }
      for (final exercise in _byPreset(
        _piedmontese,
        'build_translation_to_target',
      )) {
        expect(
          _line(_piedmontese, exercise),
          'Translate into Piedmontese with the word blocks.',
        );
      }
    });

    test('without an exercise the line names the target language', () {
      expect(
        ExerciseCopyService.instruction(
          _laboratory,
          LearnerExerciseKind.inputTranslation,
        ),
        'Translate into Italian.',
      );
    });
  });

  group('3. Lines that no longer repeat their title', () {
    test('the approved English lines', () {
      final expected = {
        LearnerExerciseKind.select: 'Find the correct answer.',
        LearnerExerciseKind.selectImage: 'Find the matching picture.',
        LearnerExerciseKind.matchTranslation:
            'Pair each word with its translation.',
        LearnerExerciseKind.match: 'Pair the items that belong together.',
        LearnerExerciseKind.matchAudio: 'Pair each sound with its word.',
        LearnerExerciseKind.arrangeWord: 'Spell what the picture shows.',
        LearnerExerciseKind.inputPictureName: 'Type the name of the picture.',
        LearnerExerciseKind.arrangePictureName:
            'Put the blocks in order to name the picture.',
        LearnerExerciseKind.inputListenWrite: 'Type every word you hear.',
        LearnerExerciseKind.inputMissingWord:
            'The first letter is given: type the whole word.',
        LearnerExerciseKind.selectComplete: 'Pick the block that fits the gap.',
        LearnerExerciseKind.selectListen:
            'Find the answer that matches what you hear.',
      };
      for (final entry in expected.entries) {
        expect(
          ExerciseCopyService.instruction(_laboratory, entry.key),
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    test('the other learner languages follow', () {
      Course inLanguage(String source) =>
          Course.fromJson({..._laboratory.toJson(), 'sourceLanguage': source});
      expect(
        ExerciseCopyService.instruction(
          inLanguage('Italian'),
          LearnerExerciseKind.select,
        ),
        'Trova la risposta corretta.',
      );
      // The language name is the Course's own, as in Pick the translation.
      expect(
        ExerciseCopyService.instruction(
          inLanguage('Spanish'),
          LearnerExerciseKind.inputTranslation,
        ),
        'Traduce al Italian.',
      );
    });
  });
}
