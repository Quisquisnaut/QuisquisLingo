import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_catalogs.dart';
import 'package:quisquislingo_app/localization/learner_panel/learner_panel_catalogs.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_language_pair.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/learner_panel_text.dart';
import 'package:quisquislingo_app/services/preset_examples.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

// Build 275 Revision 1 (owner decisions of 16 October 2026): in a Course in
// the same language the exercise titles, the instruction lines and the
// feedback say "word" and "meaning", never "translation"; no language is
// named. A translation Course reads as before. One switch:
// ExerciseCopyService and LearnerPanelText ask CourseLanguagePair.

const _profile = LearnerProfile(
  learnerProfileId: '27500000-0000-4000-8000-000000000101',
  displayName: 'Learner Copy',
);
final _operations = CourseLibraryOperations(
  clock: () => DateTime.utc(2026, 10, 17, 9),
);

/// A Course of [source] to [target] holding the Laboratory's Lessons, so
/// it has an exercise of every preset.
Course _withLaboratory(
  Course laboratory, {
  required String source,
  required String sourceTag,
  required String target,
  required String targetTag,
}) => Course.fromJson({
  ..._operations
      .newWizardCourse(
        creator: _profile,
        title: 'Words',
        sourceLanguage: source,
        targetLanguage: target,
        sourceLanguageTag: sourceTag,
        targetLanguageTag: targetTag,
        sameLanguage: source == target,
      )
      .toJson(),
  'lessons': laboratory.toJson()['lessons'],
});

Exercise _example(Course course, String presetId) {
  final id = PresetExamples.exampleIds[presetId]!;
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final exercise in round.exercises) {
        if (exercise.id == id) return exercise;
      }
    }
  }
  throw StateError('No example of $presetId');
}

/// The first word, in small letters and without accents (as the rule of
/// Build 263 Revision 0 compares them).
String _firstWord(String text) {
  final word =
      RegExp(r"[\p{L}\p{N}]+", unicode: true).firstMatch(text)?.group(0) ?? '';
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'è': 'e', 'é': 'e', //
    'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ò': 'o', //
    'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', //
    'ü': 'u', 'ç': 'c', 'ñ': 'n',
  };
  return word
      .toLowerCase()
      .split('')
      .map((letter) => accents[letter] ?? letter)
      .join();
}

/// Each new title with the line drawn under it.
const _titleLines = {
  'pick_the_word': 'selectWord',
  'pick_the_meaning': 'selectMeaning',
  'type_the_word': 'inputWord',
  'type_the_meaning': 'inputMeaning',
  'build_the_sentence': 'arrangeSentence',
  'build_the_meaning': 'arrangeMeaning',
  'match_words_and_meanings': 'matchTranslation',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the catalogs', () {
    test('every new text in the seven languages', () {
      expect(exerciseCopyCatalogs.keys.toSet(), {
        'en',
        'es',
        'it',
        'de',
        'pt',
        'nl',
        'fr',
      });
      for (final language in exerciseCopyCatalogs.keys) {
        final copy = exerciseCopyCatalogs[language]!;
        final panel = learnerPanelCatalogs[language]!;
        for (final MapEntry(key: slug, value: line) in _titleLines.entries) {
          final title = copy['title.$slug'];
          final instruction = copy['instruction.sameLanguage.$line'];
          expect(title, isNotNull, reason: '$language $slug');
          expect(instruction, isNotNull, reason: '$language $line');
          // No line opens with the first word of its title (Build 263).
          expect(
            _firstWord(instruction!),
            isNot(_firstWord(title!)),
            reason: '$language $slug: $title / $instruction',
          );
          expect(instruction.toLowerCase(), isNot(contains('{language}')));
        }
        for (final key in LearnerPanelText.sameLanguageKeys.values) {
          expect(panel[key]?.trim(), isNotEmpty, reason: '$language $key');
        }
      }
    });

    test('the names in a same-language Course: word and meaning', () {
      expect(ExercisePresetRegistry.sameLanguageNames, hasLength(7));
      for (final MapEntry(key: id, value: name)
          in ExercisePresetRegistry.sameLanguageNames.entries) {
        expect(ExercisePresetRegistry.byId(id), isNotNull, reason: id);
        expect(name.toLowerCase(), isNot(contains('translation')));
      }
    });
  });

  group('the titles and lines', () {
    late Course laboratory;
    late Course english;
    late Course italian;

    setUpAll(() async {
      laboratory = await CourseService().loadCourse('IT');
      english = _withLaboratory(
        laboratory,
        source: 'English',
        sourceTag: 'en',
        target: 'English',
        targetTag: 'en',
      );
      italian = _withLaboratory(
        laboratory,
        source: 'Italian',
        sourceTag: 'it',
        target: 'Italian',
        targetTag: 'it',
      );
    });

    test('the Courses are what the test means', () {
      expect(CourseLanguagePair.isSameLanguage(laboratory), isFalse);
      expect(CourseLanguagePair.isSameLanguage(english), isTrue);
      expect(CourseLanguagePair.isSameLanguage(italian), isTrue);
    });

    test('in English: each translation preset says word and meaning', () {
      for (final (preset, title, line) in [
        (
          'translation_choice_to_target',
          'PICK THE WORD',
          'Choose the word for this meaning.',
        ),
        (
          'translation_choice_to_source',
          'PICK THE MEANING',
          'Choose the correct meaning.',
        ),
        (
          'type_translation_to_target',
          'TYPE THE WORD',
          'Write the word for this meaning.',
        ),
        (
          'type_translation_to_source',
          'TYPE THE MEANING',
          'Write the meaning of this word.',
        ),
        (
          'build_translation_to_target',
          'BUILD THE SENTENCE',
          'Form the sentence for this meaning with the word blocks.',
        ),
        (
          'build_translation_to_source',
          'BUILD THE MEANING',
          'Form the meaning of this sentence with the word blocks.',
        ),
        (
          'word_match',
          'MATCH WORDS AND MEANINGS',
          'Pair each word with its meaning.',
        ),
      ]) {
        final exercise = _example(english, preset);
        expect(
          ExerciseCopyService.title(english, exercise),
          title,
          reason: preset,
        );
        expect(
          ExerciseCopyService.instructionForExercise(english, exercise),
          line,
          reason: preset,
        );
        // The translation Course reads as before.
        final translation = ExerciseCopyService.title(laboratory, exercise);
        expect(translation, isNot(title), reason: preset);
        expect(
          ExerciseCopyService.instructionForExercise(laboratory, exercise),
          isNot(line),
          reason: preset,
        );
      }
      expect(
        ExerciseCopyService.title(
          laboratory,
          _example(laboratory, 'translation_choice_to_target'),
        ),
        'PICK THE TRANSLATION',
      );
    });

    test('in Italian, from the Italian catalog', () {
      final pick = _example(italian, 'translation_choice_to_target');
      expect(ExerciseCopyService.title(italian, pick), 'SCEGLI LA PAROLA');
      expect(
        ExerciseCopyService.instructionForExercise(italian, pick),
        'Seleziona la parola che corrisponde a questo significato.',
      );
      final type = _example(italian, 'type_translation_to_source');
      expect(ExerciseCopyService.title(italian, type), 'SCRIVI IL SIGNIFICATO');
      expect(
        ExerciseCopyService.instructionForExercise(italian, type),
        'Inserisci il significato di questa parola.',
      );
    });

    test('every other preset keeps its title and line', () {
      for (final preset in ExercisePresetRegistry.presets) {
        if (ExercisePresetRegistry.sameLanguageNames.containsKey(preset.id)) {
          continue;
        }
        final id = PresetExamples.exampleIds[preset.id];
        if (id == null) continue;
        final exercise = _example(laboratory, preset.id);
        expect(
          ExerciseCopyService.title(english, exercise),
          ExerciseCopyService.title(laboratory, exercise),
          reason: preset.id,
        );
        final line = ExerciseCopyService.instructionForExercise(
          english,
          exercise,
        );
        expect(
          line.toLowerCase(),
          isNot(contains('translat')),
          reason: preset.id,
        );
      }
    });

    test('the feedback and Word Lookup say answers and meanings', () {
      for (final (key, same, translation) in [
        ('correctTranslations', 'Correct answers:', 'Correct translations:'),
        (
          'otherCorrectTranslations',
          'Other correct answers:',
          'Other correct translations:',
        ),
        (
          'somePossibleTranslations',
          'Some possible answers:',
          'Some possible translations:',
        ),
      ]) {
        expect(LearnerPanelText.of(english, key), same);
        expect(LearnerPanelText.of(laboratory, key), translation);
      }
      expect(
        LearnerPanelText.of(english, 'wordLookup.note'),
        'One possible meaning from this Course\'s GuideBook.',
      );
      expect(
        LearnerPanelText.of(english, 'wordLookup.notice'),
        contains('to see its meaning'),
      );
      expect(
        LearnerPanelText.of(italian, 'correctTranslations'),
        'Risposte corrette:',
      );
      // Other texts are untouched.
      expect(
        LearnerPanelText.of(english, 'wordLookup.action'),
        LearnerPanelText.of(laboratory, 'wordLookup.action'),
      );
    });
  });

  test(
    'the Round Wizard asks for no translation in a same-language Course',
    () {
      final guidebook = Guidebook(
        modules: CourseWizardSample.guidebook(_Ids()),
      );
      List<String> buildPrompts({required bool sameLanguage}) {
        final generator = GuidebookRoundGenerator(
          randomSeed: 1,
          draftIds: _Ids(),
          now: () => DateTime.utc(2026, 10, 17),
          sameLanguage: sameLanguage,
        );
        final plan = generator.plan(
          guidebook,
          roundCount: 6,
          exercisesPerRound: 8,
        );
        return [
          for (final round in generator.createDrafts(guidebook, plan))
            for (final exercise in round.exercises)
              if (exercise.authoringMetadata['presetId'] ==
                  'build_translation_to_target')
                ExerciseFeatures(exercise).primaryText,
        ];
      }

      final translation = buildPrompts(sameLanguage: false);
      final same = buildPrompts(sameLanguage: true);
      expect(translation, isNotEmpty);
      expect(same, hasLength(translation.length));
      expect(
        translation.every((p) => p.startsWith('Build the translation')),
        isTrue,
      );
      for (final prompt in same) {
        expect(prompt, startsWith('Build the sentence for “'));
        expect(prompt.toLowerCase(), isNot(contains('translation')));
      }
    },
  );

  testWidgets('a Round of a same-language Course shows the new title and '
      'line', (tester) async {
    final laboratory = (await tester.runAsync(
      () => CourseService().loadCourse('IT'),
    ))!;
    final english = _withLaboratory(
      laboratory,
      source: 'English',
      sourceTag: 'en',
      target: 'English',
      targetTag: 'en',
    );
    final exercise = _example(english, 'translation_choice_to_target');
    await tester.pumpWidget(
      MaterialApp(
        home: RoundScreen(
          course: english,
          lesson: english.lessons.first,
          round: LearningRound(
            id: 'same_language_preview',
            title: 'Preview',
            content: [LearningContent.fromExercise(exercise)],
          ),
          ttsLanguage: 'en-GB',
          roundIndex: 0,
          previewMode: true,
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('exercise-heading')).evaluate().isNotEmpty,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('exercise-heading'))).data,
      'PICK THE WORD',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('translation-choice-instruction')))
          .data,
      'Choose the word for this meaning.',
    );
  });
}

class _Ids implements AuthoringIdGenerator {
  static var _next = 0;

  @override
  String next(String kind) => '${kind}_same_${_next++}';
}
