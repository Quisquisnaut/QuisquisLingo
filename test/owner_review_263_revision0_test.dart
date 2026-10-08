import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_catalogs.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/exercise_title.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 263 Revision 0 (owner review of 4 October 2026): no standard line
/// opens with the first word of the title above it (PICK THE TRANSLATION
/// said "Pick the correct … translation"); a picture answer never shows its
/// word (a Course picture of an apple showed "mela" under it); Select the
/// image and Listen and pick the image have no Exercise image.

/// The standard lines a learner can see under each preset's title: the
/// line of every kind the preset's recipe can produce, with its variants.
const _presetLines = <String, List<String>>{
  'translation_choice_to_target': ['selectTranslation'],
  'translation_choice_to_source': ['selectTranslation'],
  'type_translation_to_target': ['inputTranslation'],
  'type_translation_to_source': ['inputTranslation'],
  'build_translation_to_target': ['arrangeTranslation'],
  'build_translation_to_source': ['arrangeTranslation'],
  'word_match': ['matchTranslation'],
  'super_match': ['match'],
  'flashcard': ['presentation'],
  'picture_flashcard': ['presentation'],
  'choice_target': [
    'select',
    'select_opposite',
    'selectListen',
    'selectListenQuestion',
  ],
  'choice_source': [
    'select',
    'select_opposite',
    'selectListen',
    'selectListenQuestion',
  ],
  'gap_choice': ['selectComplete'],
  'type_missing_word': [
    'inputMissingWord',
    'inputComplete',
    'inputCompleteOne',
    'inputCompleteLetters',
  ],
  'word_order': ['arrangeSentence'],
  'true_false': ['select', 'selectListen', 'selectListenQuestion'],
  'gap_blocks': ['arrangeGaps'],
  'one_word_fills_all': ['selectCompleteAll'],
  'complete_text': [
    'inputComplete',
    'inputCompleteOne',
    'inputCompleteLetters',
  ],
  'missing_letters': ['inputCompleteLetters', 'inputListenGaps'],
  'sentence_order': ['arrangeLines', 'arrangeSentence'],
  'sort_into_groups': ['assignGroups'],
  'fill_the_slots': ['assignSlots'],
  'listening_choose_target': ['selectListenHeard'],
  'listening_choose_source': ['selectListenMeaning'],
  'listening_answer_target': ['selectListenQuestion'],
  'listening_answer_source': ['selectListenQuestion'],
  'listening_spelling': ['inputListenWrite'],
  'missing_word': ['inputListenGaps'],
  'audio_match': ['matchAudio'],
  'listening_image_choice': ['selectListen'],
  'spell_heard': ['arrangeWordHeard'],
  'reading_answer_target': ['selectContext'],
  'icon_choice': ['selectImage'],
  'script_recognition': ['selectCharacter'],
  'image_word': ['arrangeWord'],
  'picture_choice': ['selectPicture'],
  'picture_name': ['inputPictureName'],
  'picture_blocks': ['arrangePictureName'],
  'spell_word': ['arrangeWordClue'],
  'picture_word_match': ['match', 'matchTranslation'],
  'note_card': ['presentation'],
  'story_cover': ['storyCover'],
};

/// The heading of an exercise no preset represents is its kind's.
const _kindLines = <String, List<String>>{
  'select': ['select', 'select_opposite'],
  'selectListen': [
    'selectListen',
    'selectListenQuestion',
    'selectListenHeard',
    'selectListenMeaning',
  ],
  'selectListenPassage': ['selectListenPassage', 'selectListenQuestion'],
  'selectRead': ['selectRead'],
  'selectDialogue': ['selectDialogue'],
  'selectImage': ['selectImage'],
  'selectComplete': ['selectComplete'],
  'selectCompleteAll': ['selectCompleteAll'],
  'selectContext': ['selectContext'],
  'selectCharacter': ['selectCharacter'],
  'selectPicture': ['selectPicture'],
  'presentation': ['presentation'],
  'storyCover': ['storyCover'],
  'inputComplete': [
    'inputComplete',
    'inputCompleteOne',
    'inputCompleteLetters',
  ],
  'inputMissingWord': ['inputMissingWord'],
  'inputPictureName': ['inputPictureName'],
  'inputListenGaps': ['inputListenGaps'],
  'inputListenWrite': ['inputListenWrite'],
  'inputTranslation': ['inputTranslation'],
  'arrangeSentence': ['arrangeSentence', 'arrangeGaps'],
  'arrangeLines': ['arrangeLines'],
  'arrangeWord': ['arrangeWord', 'arrangeWordHeard', 'arrangeWordClue'],
  'arrangePictureName': ['arrangePictureName'],
  'arrangeTranslation': ['arrangeTranslation'],
  'matchTranslation': ['matchTranslation'],
  'match': ['match'],
  'matchAudio': ['matchAudio'],
  'assignGroups': ['assignGroups'],
  'assignSlots': ['assignSlots'],
  'assignGaps': ['assignGaps'],
};

/// The first word, in small letters and without accents.
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

final _stamp = DateTime.utc(2026, 10, 4);

PromptElement _text(String text, [String role = 'primary']) =>
    PromptElement(type: 'text', text: text, role: role);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. No standard line opens with its title’s first word', () {
    final english = exerciseCopyCatalogs['en']!;

    test('the table names every preset with a title', () {
      final titled = {
        for (final preset in ExercisePresetRegistry.presets)
          if (!const {
            'dialogue_line',
            'before_you_start',
            'page',
          }.contains(preset.id))
            preset.id,
      };
      expect(_presetLines.keys.toSet(), titled);
    });

    for (final MapEntry(key: language, value: catalog)
        in exerciseCopyCatalogs.entries) {
      String line(String key) =>
          catalog['instruction.$key'] ?? english['instruction.$key']!;

      test('$language: preset titles', () {
        for (final preset in ExercisePresetRegistry.presets) {
          final keys = _presetLines[preset.id];
          if (keys == null) continue;
          final slug = ExerciseTitle.slugOfName(preset.name);
          final title = catalog['title.$slug'] ?? english['title.$slug']!;
          for (final key in keys) {
            expect(
              _firstWord(line(key)),
              isNot(_firstWord(title)),
              reason: '$language ${preset.id}: $title / ${line(key)}',
            );
          }
        }
      });

      test('$language: the headings of exercises no preset represents', () {
        for (final MapEntry(key: kind, value: keys) in _kindLines.entries) {
          final heading =
              catalog['type.$kind'] ??
              english['type.$kind'] ??
              catalog['type.default']!;
          for (final key in keys) {
            expect(
              _firstWord(line(key)),
              isNot(_firstWord(heading)),
              reason: '$language $kind: $heading / ${line(key)}',
            );
          }
        }
      });
    }

    test('Pick the translation chooses (owner request)', () {
      expect(
        english['instruction.selectTranslation'],
        'Choose the correct {language} translation',
      );
      expect(
        exerciseCopyCatalogs['it']!['instruction.selectTranslation'],
        'Seleziona la traduzione corretta in {language}',
      );
    });
  });

  group('2. A picture answer shows no word', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Revision 0 263 learner');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async {
              if (call.method == 'getApplicationSupportDirectory') {
                return testSupportDirectory.path;
              }
              throw PlatformException(code: 'test-storage');
            },
          );
      keepCrashLogUnavailable();
    });

    Future<void> pumpExercise(WidgetTester tester, Exercise exercise) async {
      final round = LearningRound(
        id: 'round-${exercise.id}',
        updatedAt: _stamp,
        title: '',
        exercises: [exercise],
      );
      final lesson = Lesson(
        lessonId: 'lesson-${exercise.id}',
        updatedAt: _stamp,
        title: 'Pictures',
        rounds: [round],
      );
      final course = Course(
        courseId: 'pictures-263-course',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Pictures 263',
        ttsLanguage: 'it-IT',
        lessons: [lesson],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: lesson,
            round: round,
            ttsLanguage: course.ttsLanguage,
            roundIndex: 0,
            previewMode: true,
          ),
        ),
      );
      for (var frame = 0; frame < 80; frame++) {
        await tester.pump(const Duration(milliseconds: 25));
        if (find
            .byKey(const Key('exercise-renderer-select'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
    }

    testWidgets('a Course picture hides its word; a named icon keeps it', (
      tester,
    ) async {
      final exercise = Exercise.canonical(
        id: 'pictures-263',
        updatedAt: _stamp,
        primitive: ExercisePrimitive.select,
        promptElements: [_text('Which one is red?', 'question')],
        items: [
          ExerciseItem(
            id: 'apple',
            content: [
              _text('mela'),
              const PromptElement(
                type: 'image',
                asset:
                    'media:0000000000000000000000000000000000000000000000000000000000000000.png',
              ),
            ],
          ),
          ExerciseItem(
            id: 'sun',
            content: [_text('sole'), _text('sun', 'icon')],
          ),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactItem,
          correctItemIds: ['apple'],
        ),
      );
      await pumpExercise(tester, exercise);
      expect(find.byKey(const Key('exercise-renderer-select')), findsOneWidget);
      expect(find.text('mela'), findsNothing);
      expect(find.text('sole'), findsOneWidget);
    });
  });

  group('3. Picture answers have no Exercise image', () {
    for (final preset in ['icon_choice', 'listening_image_choice']) {
      test('$preset has only the pictures of its answers', () {
        final keys = ExerciseFieldHelpRegistry.editorFieldKeys(preset);
        expect(keys, isNot(contains('image')));
        expect(keys, contains('icons'));
      });
    }
  });
}
