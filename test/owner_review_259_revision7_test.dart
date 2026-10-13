import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';

/// Build 259 Revision 7 (owner review of 1 October 2026): Type and Build the
/// translation name the language of the answer (a "to source" exercise said
/// "Translate from English into Piedmontese"), and the standard lines no
/// longer repeat their exercise title. Build 262 Revision 0: the
/// Piedmontese demos left the bundle; the Laboratory and QQL Demo: English
/// from Italian showed the same lines. Build 272 Revision 15: QQL Demo:
/// English from Italian left the app and the repository too (owner decision
/// of 13 October 2026); the Edge Case fixture is the Course whose learners
/// read the lines in Italian.

Course _load(String path) => Course.fromJson(
  jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
);

final _laboratory = _load('assets/courses/exercise_laboratory_en_it.json');
final _edgeCase = _load('test/fixtures/v12/edge_case_it_en.json');

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
    for (final (course, toSourceFrom, source, target) in [
      (_laboratory, _laboratory, 'English', 'Italian'),
      // The Edge Case fixture has no "to source" Type the translation, so
      // the Laboratory's are read with the fixture's languages: the line
      // follows the Course's languages and the exercise's direction alone.
      (_edgeCase, _laboratory, 'italiano', 'inglese'),
    ]) {
      final english = course == _laboratory;
      test('${course.title}: Type the translation, both directions', () {
        final toSource = _byPreset(toSourceFrom, 'type_translation_to_source');
        final toTarget = _byPreset(course, 'type_translation_to_target');
        expect(toSource, isNotEmpty);
        expect(toTarget, isNotEmpty);
        for (final exercise in toSource) {
          expect(
            _line(course, exercise),
            english ? 'Translate into $source.' : 'Traduci in $source.',
          );
        }
        for (final exercise in toTarget) {
          expect(
            _line(course, exercise),
            english ? 'Translate into $target.' : 'Traduci in $target.',
          );
        }
      });
    }

    test('Build the translation, both directions', () {
      final toSource = _byPreset(_laboratory, 'build_translation_to_source');
      final toTarget = _byPreset(_laboratory, 'build_translation_to_target');
      expect(toSource, isNotEmpty);
      expect(toTarget, isNotEmpty);
      for (final exercise in toSource) {
        expect(
          _line(_laboratory, exercise),
          'Translate into English with the word blocks.',
        );
      }
      for (final exercise in toTarget) {
        expect(
          _line(_laboratory, exercise),
          'Translate into Italian with the word blocks.',
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
        LearnerExerciseKind.arrangeWord: 'Form the word the picture shows.',
        LearnerExerciseKind.inputPictureName: 'Write the name of the picture.',
        LearnerExerciseKind.arrangePictureName:
            'Put the blocks in order to name the picture.',
        LearnerExerciseKind.inputListenWrite: 'Transcribe every word you hear.',
        LearnerExerciseKind.inputMissingWord:
            'The first letter is given: type the whole word.',
        LearnerExerciseKind.selectComplete:
            'Choose the block that fits the gap.',
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
      // Build 260 Revision 0: the base language's tag decides first, so the
      // Laboratory's en-GB goes.
      Course inLanguage(String source) => Course.fromJson({
        ..._laboratory.toJson()..remove('sourceLanguageTag'),
        'sourceLanguage': source,
      });
      expect(
        ExerciseCopyService.instruction(
          inLanguage('Italian'),
          LearnerExerciseKind.select,
        ),
        'Trova la risposta corretta.',
      );
      // Build 260 Revision 0: the name is in the instruction language.
      expect(
        ExerciseCopyService.instruction(
          inLanguage('Spanish'),
          LearnerExerciseKind.inputTranslation,
        ),
        'Traduce al italiano.',
      );
    });
  });
}
