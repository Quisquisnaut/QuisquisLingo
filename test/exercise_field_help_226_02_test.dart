import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/editor_help_content.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';

void main() {
  ExerciseFieldHelp help(String preset, String field) =>
      ExerciseFieldHelpRegistry.forEditorField(preset, field);

  test('current preset fields have purpose, entry rules and checks', () {
    // Inventory of the real form values, including fields visible only in one
    // context mode. Widget tests separately check their direct Help controls.
    const fieldsByPreset = <String, List<String>>{
      'translation_choice_to_target': ['question', 'answers', 'correct'],
      'translation_choice_to_source': ['question', 'answers', 'correct'],
      'type_translation_to_target': ['prompt', 'accepted', 'hint'],
      'type_translation_to_source': ['prompt', 'accepted', 'hint'],
      'build_translation_to_target': [
        'prompt',
        'tokens',
        'correctTranslation',
        'gapLayout',
        'tts',
      ],
      'build_translation_to_source': [
        'prompt',
        'tokens',
        'correctTranslation',
        'gapLayout',
        'tts',
      ],
      'word_match': ['prompt', 'pairs'],
      'super_match': ['prompt', 'pairs'],
      'flashcard': ['prompt', 'question', 'readAloud', 'tts', 'answers'],
      'choice_target': [
        'prompt',
        'question',
        'answers',
        'correct',
        'requiredSelections',
        'gapLayout',
        'tokens',
        'tts',
      ],
      'choice_source': [
        'prompt',
        'question',
        'answers',
        'correct',
        'requiredSelections',
        'gapLayout',
        'tokens',
        'tts',
      ],
      'gap_choice': ['question', 'answers', 'correct', 'hint'],
      'type_missing_word': ['revealFirstLetter', 'prompt', 'accepted', 'hint'],
      'word_order': ['prompt', 'gapLayout', 'tokens', 'order', 'tts'],
      'listening_answer_target': ['tts', 'question', 'answers', 'correct'],
      'listening_answer_source': ['tts', 'question', 'answers', 'correct'],
      'listening_spelling': ['prompt', 'tts', 'missingWords'],
      'missing_word': ['prompt', 'tts', 'missingWords'],
      'audio_match': ['prompt', 'pairs'],
      'reading_answer_target': [
        'prompt',
        'tts',
        'dialogue',
        'question',
        'answers',
        'correct',
      ],
      'reading_answer_source': [
        'prompt',
        'tts',
        'dialogue',
        'question',
        'answers',
        'correct',
      ],
      'icon_choice': ['question', 'answers', 'correct', 'icons'],
      'script_recognition': [
        'scriptMode',
        'scriptPrompt',
        'scriptPromptImages',
        'scriptTextOptions',
        'scriptImageOptions',
        'scriptCorrect',
      ],
      'image_word': ['prompt', 'order'],
      'picture_flashcard': [
        'prompt',
        'question',
        'readAloud',
        'tts',
        'answers',
      ],
      'true_false': ['question', 'tts', 'answers', 'correct'],
      'gap_choice_inline': ['prompt', 'gapLayout', 'tokens', 'tts'],
      'complete_text': ['prompt', 'missingWords'],
      'missing_letters': ['prompt', 'tts', 'hint'],
      'gap_blocks': ['prompt', 'gapLayout', 'tokens', 'tts'],
      'sentence_order': ['prompt', 'tokens', 'order'],
      'listening_image_choice': [
        'tts',
        'question',
        'answers',
        'correct',
        'icons',
      ],
      'spell_heard': ['tts', 'order'],
      'picture_choice': ['question', 'answers', 'correct'],
      'picture_name': ['question', 'accepted', 'hint'],
      'spell_word': ['prompt', 'order'],
      'picture_word_match': ['prompt', 'answers', 'icons'],
      'note_card': ['prompt', 'question'],
      'dialogue_line': [
        'speaker',
        'prompt',
        'lineMode',
        'readAloud',
        'textReveal',
        'language',
      ],
      'story_cover': ['prompt', 'image'],
      // The Assign presets (Build 256 Revision 7 follow-up).
      'sort_into_groups': ['question', 'groups', 'leftover'],
      'fill_the_slots': ['question', 'slots', 'extraWords', 'slotReuse'],
    };
    expect(
      fieldsByPreset.keys.toSet(),
      ExercisePresetRegistry.presets.map((preset) => preset.id).toSet(),
    );
    final covered = <ExerciseAuthoringField>{};
    for (final preset in fieldsByPreset.entries) {
      for (final key in [
        ...preset.value,
        if (preset.key != 'script_recognition') 'image',
      ]) {
        final definition = help(preset.key, key);
        expect(definition.title, isNotEmpty, reason: '${preset.key}/$key');
        expect(definition.purpose, isNotEmpty, reason: '${preset.key}/$key');
        expect(definition.entryRules, isNotEmpty, reason: '${preset.key}/$key');
        expect(definition.validation, isNotEmpty, reason: '${preset.key}/$key');
        covered.add(ExerciseFieldHelpRegistry.fieldForEditor(preset.key, key));
      }
    }
    expect(covered, ExerciseAuthoringField.values.toSet());
  });

  test('Prompt and Question have distinct concrete examples', () {
    final prompt = help('choice_target', 'prompt');
    final question = help('choice_target', 'question');
    expect(
      prompt.purpose,
      'An optional line above the question: an instruction or some context. Example: Pick the verb form that fits.',
    );
    expect(prompt.example, 'Pick the verb form that fits.');
    expect(
      question.purpose,
      'What the learner answers: a question, or a sentence with a gap the answers complete. Example: Which article goes with casa?',
    );
    expect(question.example, 'Which article goes with casa?');
    expect(prompt.text, contains('Example\nPick the verb form that fits.'));
    expect(question.text, contains('Example\nWhich article goes with casa?'));
  });

  test('concise examples clarify common field formats', () {
    expect(help('choice_target', 'answers').example, 'caffè\nacqua\npane');
    expect(
      help('word_match', 'pairs').example,
      'house = casa\nbread = pane\nwater = acqua',
    );
    expect(
      help('reading_answer_target', 'prompt').example,
      contains('Maria prende il treno.'),
    );
    expect(
      help('type_translation_to_target', 'accepted').example,
      contains('[prendo|vorrei]'),
    );
    expect(
      help('icon_choice', 'icons').example,
      contains('assets/exercise_images/house.webp'),
    );
    expect(
      help('image_word', 'image').example,
      contains('Bundled path: assets/exercise_images/house.webp'),
    );
    expect(
      help('listening_answer_target', 'tts').example,
      'Buongiorno, come stai?',
    );
    expect(
      help('listening_answer_target', 'tts').entryRules,
      contains('not an MP3 filename or path'),
    );
  });

  test('accepted-answer Help examples run through the production parser', () {
    final definition = help('type_translation_to_target', 'accepted');
    expect(AnswerExpressionParser.expand(definition.example!), [
      'Prendo un cappuccino',
      'Vorrei un cappuccino',
      'Io prendo un cappuccino',
      'Io vorrei un cappuccino',
    ]);
    expect(
      definition.entryRules,
      contains('[*:il|i] [*:tuo|tuoi] [*:denaro|soldi]'),
    );
    expect(
      AnswerExpressionParser.expand('[*:il|i] [*:tuo|tuoi] [*:denaro|soldi]'),
      ['Il tuo denaro', 'I tuoi soldi'],
    );
    expect(
      definition.validation,
      contains('${AnswerExpressionParser.expansionLimit} answers'),
    );
    expect(definition.entryRules, contains('separate lines'));
    expect(definition.entryRules, contains('equal alternative counts'));
    expect(definition.entryRules, contains('(non arrivo <> oggi)'));
    expect(definition.entryRules, contains('a casa <> domani'));
  });

  test('typed-answer fields share syntax while listening gaps are literal', () {
    for (final definition in [
      help('type_translation_to_target', 'accepted'),
      help('type_translation_to_source', 'accepted'),
      help('listening_spelling', 'missingWords'),
    ]) {
      expect(
        definition.entryRules,
        contains(ExerciseFieldHelpRegistry.answerSyntax),
      );
      expect(
        definition.validation,
        contains('Malformed expressions are rejected'),
      );
    }
    final gaps = help('missing_word', 'missingWords');
    expect(gaps.entryRules, contains('Multiple lines select multiple gaps'));
    expect(
      gaps.validation,
      contains('each entry must occur in Passage transcript'),
    );
    expect(gaps.validation, contains('syntax is not expanded'));
  });

  test(
    'Arrange Help distinguishes answer rows, word lines and letter lines',
    () {
      final sentence = help(
        'build_translation_to_target',
        'correctTranslation',
      );
      expect(sentence.entryRules, contains('Each separate answer entry'));
      expect(
        sentence.entryRules,
        contains('one complete target-language sentence'),
      );
      expect(
        sentence.validation,
        contains('distinct available block occurrences'),
      );
      expect(
        sentence.validation,
        contains('unique after case, spacing and terminal-punctuation'),
      );
      expect(
        sentence.validation,
        contains('Internal punctuation is preserved'),
      );
      expect(
        sentence.validation,
        contains('No optional, alternative or reorder expressions'),
      );
      final wordOrder = help('word_order', 'order');
      expect(wordOrder.entryRules, contains('one block per line'));
      expect(wordOrder.entryRules, contains('joined with spaces'));
      final imageOrder = help('image_word', 'order');
      expect(imageOrder.entryRules, contains('joined without spaces'));
      expect(imageOrder.validation, contains('no distractors'));
    },
  );

  test('block Help explains the different actual distractor rules', () {
    expect(
      help('word_order', 'tokens').validation,
      contains('at most 2 unused distractor'),
    );
    final translation = help('build_translation_to_target', 'tokens');
    expect(
      translation.validation,
      contains('unused by every correct translation'),
    );
    expect(translation.validation, contains('used by any configured answer'));
    expect(
      translation.entryRules,
      contains('repeated words require repeated lines'),
    );
    // The spelling presets have one field (Build 256 Revision 7 follow-up).
    expect(help('image_word', 'order').validation, contains('no distractors'));
  });

  test('matching Help preserves ordinary and specialized cardinalities', () {
    // Build 256 Revision 4: Match the words absorbs Matching and takes any
    // number of pairs from two; Match by meaning keeps three.
    expect(help('word_match', 'pairs').entryRules, contains('at least two'));
    expect(help('super_match', 'pairs').entryRules, contains('exactly three'));
    final audio = help('audio_match', 'pairs');
    expect(audio.entryRules, contains('exactly three lines'));
    expect(audio.entryRules, contains('audio text = visible text'));
    expect(audio.entryRules, contains('three visible choices'));
    expect(audio.validation, contains('No distractors are permitted'));
  });

  test('presentation fields do not reuse answer-choice Help', () {
    final usage = help('flashcard', 'answers');
    expect(usage.entryRules, contains('First non-empty line: usage sentence'));
    expect(
      usage.entryRules,
      contains('second non-empty line: its translation'),
    );
    expect(usage.validation, contains('presentation content'));
    expect(
      help('choice_target', 'answers').entryRules,
      contains('one literal answer per line'),
    );
    expect(
      help('choice_target', 'correct').entryRules,
      contains('counting non-empty answer lines from 1'),
    );
  });

  test('Read and answer Help covers the text, its audio and speaker turns', () {
    final text = help('reading_answer_target', 'prompt');
    expect(text.title, 'Text to read');
    expect(text.purpose, contains('situation or context'));
    expect(text.example, contains('Maria prende il treno.'));
    final dialogue = help('reading_answer_target', 'dialogue');
    expect(dialogue.entryRules, contains('one turn per line as Speaker: text'));
    expect(
      dialogue.validation,
      contains('non-empty speaker and non-empty text'),
    );
    expect(
      help('reading_answer_target', 'tts').entryRules,
      contains('not an MP3 filename or path'),
    );
  });

  test('image Help separates imported prompt image from choice icon keys', () {
    final image = help('image_word', 'image');
    expect(image.entryRules, contains('exactly one PNG, JPG, JPEG or WebP'));
    expect(image.entryRules, contains('copies the original bytes'));
    expect(image.validation, contains('50 KB (51,200 bytes)'));
    expect(
      image.validation,
      contains('recommendations, not enforced dimensions'),
    );
    expect(
      image.validation,
      contains('Image-prompt ordering requires an image'),
    );
    expect(
      image.validation,
      contains('not portable through course JSON alone'),
    );
    final icons = help('icon_choice', 'icons');
    expect(icons.entryRules, contains('same order as the answer options'));
    expect(
      icons.validation,
      contains('unknown key shows the generic image icon'),
    );
    expect(icons.validation, contains('not an option image'));
  });

  test('listening Help does not promise unimplemented automatic gaps', () {
    expect(
      help('listening_spelling', 'prompt').entryRules,
      contains('does not automatically remove the accepted answer'),
    );
    expect(
      help('listening_spelling', 'missingWords').purpose,
      contains('accepted typed responses'),
    );
    expect(
      help('missing_word', 'prompt').entryRules,
      contains('including the word or expressions to hide'),
    );
  });

  test(
    'unknown field keys cannot silently acquire irrelevant generic Help',
    () {
      expect(() => help('choice_target', 'speakerVoice'), throwsArgumentError);
    },
  );

  test('MP3 Help distinguishes file storage from Course ownership', () {
    final helpText = editorHelpSections(
      HelpLanguage.english,
    ).singleWhere((section) => section.title == 'Audio Library').body;
    for (final entry in {
      'Audio Library Help': helpText,
      'docs/COURSE_EDITOR.md': File('docs/COURSE_EDITOR.md').readAsStringSync(),
    }.entries) {
      final path = entry.key;
      final text = entry.value;
      expect(text, contains('derived from the stable Course ID'), reason: path);
      expect(
        text,
        contains('metadata and references belong to the Course'),
        reason: path,
      );
      expect(
        text,
        contains('Verified course-version backups copy referenced'),
        reason: path,
      );
      expect(text, contains('not MP3 bytes'), reason: path);
      expect(
        text,
        isNot(contains('course-scoped local app storage')),
        reason: path,
      );
      expect(
        text,
        isNot(contains('course-scoped local support storage')),
        reason: path,
      );
    }
  });
}
