import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
      'choice': ['prompt', 'question', 'answers', 'correct'],
      'gap_choice': ['question', 'answers', 'correct', 'hint'],
      'icon_choice': ['question', 'answers', 'correct', 'icons'],
      'listening_choice': ['tts', 'question', 'answers', 'correct'],
      'listening_comprehension': ['tts', 'question', 'answers', 'correct'],
      'reading_comprehension': ['prompt', 'question', 'answers', 'correct'],
      'dialogue_response': ['prompt', 'question', 'answers', 'correct'],
      'contextual_comprehension': [
        'contextMode',
        'context',
        'tts',
        'dialogue',
        'question',
        'answers',
        'correct',
      ],
      'type_translation': ['prompt', 'accepted', 'hint'],
      'type_missing_word': ['prompt', 'accepted', 'hint'],
      'script_recognition': [
        'scriptMode',
        'scriptPrompt',
        'scriptPromptImages',
        'scriptTextOptions',
        'scriptImageOptions',
        'scriptCorrect',
      ],
      'build_translation': ['prompt', 'tokens', 'correctTranslation'],
      'fill_blank': ['question', 'accepted', 'hint', 'tts'],
      'listening_spelling': ['prompt', 'tts', 'missingWords'],
      'missing_word': ['prompt', 'tts', 'missingWords'],
      'matching': ['prompt', 'pairs'],
      'word_match': ['prompt', 'pairs'],
      'super_match': ['prompt', 'pairs'],
      'audio_match': ['prompt', 'pairs'],
      'word_order': ['prompt', 'tokens', 'order'],
      'image_word': ['prompt', 'tokens', 'order'],
      'flashcard': ['prompt', 'question', 'tts', 'answers'],
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
    final prompt = help('choice', 'prompt');
    final question = help('choice', 'question');
    expect(
      prompt.purpose,
      'The instruction shown to the learner. Example: How do you say this in Italian?',
    );
    expect(prompt.example, 'How do you say this in Italian?');
    expect(
      question.purpose,
      'The word or phrase the learner must translate. Example: Good morning',
    );
    expect(question.example, 'Good morning');
    expect(prompt.text, contains('Example\nHow do you say this in Italian?'));
    expect(question.text, contains('Example\nGood morning'));
  });

  test('concise examples clarify common field formats', () {
    expect(help('choice', 'answers').example, 'caffè\nacqua\npane');
    expect(help('matching', 'pairs').example, 'casa = house\npane = bread');
    expect(
      help('reading_comprehension', 'prompt').example,
      contains('Maria prende il treno.'),
    );
    expect(
      help('type_translation', 'accepted').example,
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
    expect(help('listening_choice', 'tts').example, 'Buongiorno, come stai?');
    expect(
      help('listening_choice', 'tts').entryRules,
      contains('not an MP3 filename or path'),
    );
    expect(help('fill_blank', 'tts').title, contains('(optional)'));
  });

  test('accepted-answer Help examples run through the production parser', () {
    final definition = help('type_translation', 'accepted');
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
      help('type_translation', 'accepted'),
      help('fill_blank', 'accepted'),
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
      final sentence = help('build_translation', 'correctTranslation');
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
      expect(imageOrder.validation, contains('leave no distractors'));
    },
  );

  test('block Help explains the different actual distractor rules', () {
    expect(
      help('word_order', 'tokens').validation,
      contains('at most 2 unused distractor'),
    );
    final translation = help('build_translation', 'tokens');
    expect(
      translation.validation,
      contains('unused by every correct translation'),
    );
    expect(translation.validation, contains('used by any configured answer'));
    expect(
      translation.entryRules,
      contains('repeated words require repeated lines'),
    );
    expect(help('image_word', 'tokens').validation, contains('no distractors'));
  });

  test('matching Help preserves ordinary and specialized cardinalities', () {
    expect(
      help('matching', 'pairs').validation,
      contains('At least one usable pair'),
    );
    for (final preset in ['word_match', 'super_match']) {
      expect(help(preset, 'pairs').entryRules, contains('exactly three'));
    }
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
      help('choice', 'answers').entryRules,
      contains('one literal answer per line'),
    );
    expect(
      help('dialogue_response', 'answers').entryRules,
      contains('exactly two'),
    );
    expect(
      help('choice', 'correct').entryRules,
      contains('counting non-empty answer lines from 1'),
    );
  });

  test(
    'context Help separates mode, plain context, audio and speaker turns',
    () {
      expect(
        help('contextual_comprehension', 'contextMode').validation,
        contains('An image alone is not sufficient context'),
      );
      expect(
        help('contextual_comprehension', 'contextMode').purpose,
        contains('Text is a presentation mode'),
      );
      expect(
        help('contextual_comprehension', 'context').purpose,
        contains('passage or background'),
      );
      expect(
        help('contextual_comprehension', 'context').example,
        contains('Marta is describing her daily routine.'),
      );
      expect(
        help('contextual_comprehension', 'context').entryRules,
        contains('question belongs in its own field'),
      );
      final dialogue = help('contextual_comprehension', 'dialogue');
      expect(
        dialogue.entryRules,
        contains('one turn per line as Speaker: text'),
      );
      expect(
        dialogue.validation,
        contains('non-empty speaker and non-empty text'),
      );
      expect(
        help('contextual_comprehension', 'tts').entryRules,
        contains('not an MP3 filename or path'),
      );
    },
  );

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
      expect(() => help('choice', 'speakerVoice'), throwsArgumentError);
    },
  );

  test('MP3 Help distinguishes file storage from Course ownership', () {
    for (final path in [
      'lib/screens/editor_help_screen.dart',
      'docs/COURSE_EDITOR.md',
    ]) {
      final text = File(path).readAsStringSync();
      expect(text, contains('grouped by learning language'), reason: path);
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
