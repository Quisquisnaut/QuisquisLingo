import 'translation_choice_service.dart';
import 'storage/qql_storage.dart';

/// Shared meanings for the fields that the current Exercise Editor exposes.
/// These definitions describe authoring; they do not implement validation.
enum ExerciseAuthoringField {
  instruction,
  sourceText,
  wordOrExpression,
  translationMeaning,
  usageSentence,
  question,
  gapSentence,
  readingPassage,
  transcript,
  listeningTranscript,
  audioText,
  cardReadAloud,
  pronunciationTts,
  hint,
  choices,
  correctAnswer,
  acceptedAnswers,
  acceptedTranslations,
  availableWordBlocks,
  availableTranslationBlocks,
  correctBlockOrder,
  correctWordOrder,
  correctTranslation,
  translationPairs,
  relatedPairs,
  soundMatches,
  iconKeys,
  missingWord,
  missingWords,
  dialogue,
  image,
  scriptMode,
  scriptPrompt,
  scriptPromptImages,
  scriptTextOptions,
  scriptImageOptions,
  scriptCorrect,
  gapLayout,
  selectRequiredSelections,
  revealFirstLetter,
  statement,
  textToComplete,
  bracketedText,
  distractorBlocks,
  lines,
  correctLineOrder,
  spokenWord,
  clue,
  acceptedNames,
  pairWords,
  noteTitle,
  noteText,
  speaker,
  dialogueLine,
  lineMode,
  lineReadAloud,
  lineTextReveal,
  lineLanguage,
  coverTitle,
  coverImage,
  groups,
  leftoverWords,
  slots,
  extraWords,
  slotReuse,
}

class ExerciseFieldHelp {
  const ExerciseFieldHelp({
    required this.title,
    required this.purpose,
    required this.entryRules,
    required this.validation,
    this.example,
  });

  final String title;
  final String purpose;
  final String entryRules;
  final String validation;
  final String? example;

  String get text => [
    purpose,
    'What to enter\n$entryRules',
    'Checks\n$validation',
    if (example != null) 'Example\n$example',
  ].join('\n\n');
}

abstract final class ExerciseFieldHelpRegistry {
  /// The existing Input parser accepts these expressions. Arrange answers are
  /// literal and deliberately do not use this syntax.
  static const answerSyntax =
      'Enter complete equivalent answers on separate lines. Blank lines are ignored. '
      'Optional text: {Io} prendo un cappuccino. Alternatives: [prendo|vorrei] un cappuccino. '
      'Linked alternatives: [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] pairs alternatives by position; '
      'use at least two linked groups with equal alternative counts. '
      'Scoped reordering: (non arrivo <> oggi). Without parentheses, a casa <> domani '
      'reorders the whole expression. Terminal punctuation stays at the sentence end; '
      'generated sentence starts are capitalized. Use lowercase except for proper names.';

  static const expressionChecks =
      'At least one accepted answer is required. Malformed expressions are rejected. '
      'Expansion is deterministic, duplicate results are removed, and the combined '
      'limit is 128 answers; simplify an expression that exceeds it. '
      'Declare equivalent answers explicitly: syntax does not invent translations.';

  /// Field keys from the displayed Editor forms, including conditional modes.
  /// Shared Help search uses this inventory rather than indexing unrelated fields.
  static List<String> editorFieldKeys(String presetId) {
    const fields = <String, List<String>>{
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
      'sort_into_groups': ['question', 'groups', 'leftover'],
      'fill_the_slots': ['question', 'slots', 'extraWords', 'slotReuse'],
    };
    final selected = fields[presetId];
    if (selected == null) {
      throw ArgumentError.value(
        presetId,
        'presetId',
        'Unknown Exercise preset',
      );
    }
    return [...selected, if (presetId != 'script_recognition') 'image'];
  }

  /// The two Choose the answer twins share one form.
  static bool _isChoice(String presetId) =>
      presetId == 'choice_target' ||
      presetId == 'choice_source' ||
      presetId == 'gap_choice_inline';

  static ExerciseFieldHelp forEditorField(String presetId, String fieldKey) {
    if (_isChoice(presetId) && fieldKey == 'prompt') {
      return const ExerciseFieldHelp(
        title: 'Prompt (optional)',
        purpose:
            'An optional line above the question: an instruction or some context. Example: Pick the verb form that fits.',
        entryRules:
            'One line, or nothing. In a Round it takes the place of the standard “Choose the correct answer.” line under the CHOOSE heading; leave it empty to keep that line. The question or sentence goes in its own field.',
        validation:
            'Optional. Keep it consistent with the question and the answers.',
        example: 'Pick the verb form that fits.',
      );
    }
    if (_isChoice(presetId) && fieldKey == 'question') {
      return const ExerciseFieldHelp(
        title: 'Question or sentence to complete',
        purpose:
            'What the learner answers: a question, or a sentence with a gap the answers complete. Example: Which article goes with casa?',
        entryRules:
            'Enter one question, or one sentence with ___ where the answer fits; an instruction or context goes in Prompt.',
        validation:
            'Required. Provide matching answers and mark the correct one (or several with Multiple correct answers).',
        example: 'Which article goes with casa?',
      );
    }
    if ((presetId.startsWith('listening_answer') ||
            presetId == 'listening_image_choice') &&
        fieldKey == 'tts') {
      return ExerciseFieldHelp(
        title: 'Spoken text',
        purpose:
            'Enter exactly what the learner should hear. On-Device TTS sends this text to the device’s native text-to-speech engine; no audio file is required in that mode. Example: Buongiorno, come stai?',
        entryRules:
            'Playback follows the Course Audio Library mode. Recorded MP3 resolves this text against Course recordings; Hybrid tries a complete recording sequence before native TTS. Enter spoken words, not an MP3 filename or path. For MP3, open Course Editor > Audio Library, place files in ${QqlStorageLayout.current.folderLabel(QqlStorageRole.audioImports)}, press Import MP3, then Associate recording and enter its Word or expression. Select Recorded MP3 only or Hybrid. Exercises use these text mappings; there is no per-exercise file attachment.',
        validation:
            'Recordings are stored physically by learning language; metadata and references belong to the Course. Verified Course backups copy referenced recordings. Course JSON does not contain MP3 bytes and JSON alone does not transfer recordings.',
        example: 'Buongiorno, come stai?',
      );
    }
    if (_isChoice(presetId) && fieldKey == 'correct') {
      return const ExerciseFieldHelp(
        title: 'Correct answer number',
        purpose:
            'Identifies the correct option or options from the answer list.',
        entryRules:
            'Enter one whole number, counting non-empty answer lines from '
            '1. When Multiple correct answers is enabled, enter every '
            'correct number separated by commas, e.g. 1, 3.',
        validation:
            'Every number must be between 1 and the number of answers. '
            'Recheck it after reordering or deleting answer lines.',
        example: '2 selects the second non-empty answer line.',
      );
    }
    if (_isChoice(presetId) && fieldKey == 'gapLayout') {
      return const ExerciseFieldHelp(
        title: 'Sentence with gaps',
        purpose:
            'Shows the fixed sentence with one or more inline blanks the '
            'learner fills, in order, by tapping options from a list.',
        entryRules:
            'Write the sentence and put each answer word or phrase '
            'directly inside braces: {answer}. Example: I {am} going {to} '
            'London. Each tap fills the first remaining empty blank, '
            'whichever option is tapped — placement does not check '
            'correctness, so the right words in the wrong blanks are '
            'still marked incorrect. If the same word answers more than '
            'one gap, write it inside each of those braces: {Was} she '
            'happy? {Was} he late? — the learner taps it once per blank '
            'it needs to fill. Extra options that are not the answer to '
            'any gap go in Distractor options (optional).',
        validation:
            'At least one {…} gap is required, and every gap must contain '
            'non-empty text. Literal { or } characters cannot appear '
            'anywhere else in the sentence.',
        example: 'I {am} going {to} London.',
      );
    }
    if (_isChoice(presetId) && fieldKey == 'tokens') {
      return const ExerciseFieldHelp(
        title: 'Distractor options (optional)',
        purpose:
            'Adds options the learner can select that are not the answer '
            'to any gap.',
        entryRules:
            'One extra option per line. Include 0, 1 or at most 2 '
            'distractors.',
        validation: 'Distractor options must not repeat any gap answer text.',
        example: 'perhaps',
      );
    }
    if (presetId == 'translation_choice_to_target' ||
        presetId == 'translation_choice_to_source') {
      final toTarget = presetId == 'translation_choice_to_target';
      final textLanguage = toTarget ? 'source' : 'target';
      final answerLanguage = toTarget ? 'target' : 'source';
      final languageLabel = toTarget ? 'Target' : 'Source';
      switch (fieldKey) {
        case 'question':
          return ExerciseFieldHelp(
            title: 'Text to translate',
            purpose:
                'The $textLanguage-language word or phrase the learner translates.',
            entryRules:
                'Enter one $textLanguage-language word, phrase or sentence. '
                'Do not write an instruction: QQL adds “Pick the correct '
                '[$languageLabel language] translation” automatically. '
                '${toTarget ? 'Line breaks stay part of the same text.' : 'The learner can play this text with text-to-speech when it is available; the exercise stays fully solvable without audio.'}',
            validation:
                'Required. Provide $answerLanguage-language answer options and '
                'mark exactly one correct.',
          );
        case 'answers':
          return ExerciseFieldHelp(
            title: 'Answer options',
            purpose:
                'The $answerLanguage-language translations the learner chooses from.',
            entryRules:
                'Enter one complete $answerLanguage-language translation per '
                'line, from 2 to ${TranslationChoice.maxAnswers} options. '
                'Blank lines are ignored. Options are shown in random order.',
            validation:
                'Between 2 and ${TranslationChoice.maxAnswers} options, none '
                'blank and no phrase repeated (ignoring case, extra spaces '
                'and final punctuation), and exactly one correct. Keep '
                'distractors plausible but clearly wrong.',
          );
        case 'correct':
          return const ExerciseFieldHelp(
            title: 'Correct answer number',
            purpose: 'Identifies the one correct option.',
            entryRules:
                'Enter one whole number, counting non-empty answer lines '
                'from 1.',
            validation:
                'Must be between 1 and the number of answers. Recheck it '
                'after reordering or deleting lines.',
          );
        case 'image':
          final base = forField(ExerciseAuthoringField.image);
          return ExerciseFieldHelp(
            title: base.title,
            purpose: base.purpose,
            entryRules: base.entryRules,
            validation: base.validation,
          );
      }
    }
    if (presetId == 'type_missing_word' &&
        const {'prompt', 'accepted'}.contains(fieldKey)) {
      return const ExerciseFieldHelp(
        title: 'Type the missing word',
        purpose:
            'Enter the complete missing word. The first letter is shown as a hint when Show the first letter is on.',
        entryRules:
            'Enter a sentence with exactly one ___ gap and complete accepted words, one per line. The first Unicode grapheme is derived automatically; the learner enters the complete word, including that first grapheme.',
        validation:
            'With Show the first letter on, all complete accepted words must share exactly the same first grapheme; off, they may start with different letters. The complete word entered uses normal Input normalization and supported typo tolerance; the hint is not prepended to the response.',
        example:
            'Je vais à l’___. Answer: école. Learner sees é______ and enters école, not cole.',
      );
    }
    if ((presetId == 'type_translation_to_source' ||
            presetId == 'build_translation_to_source') &&
        fieldKey == 'prompt') {
      return const ExerciseFieldHelp(
        title: 'Text to translate',
        purpose:
            'Supplies the target-language text the learner translates into the source language.',
        entryRules:
            'Enter one target-language sentence or passage. Line breaks belong to the same prompt; accepted answers or correct translations go in their own fields.',
        validation:
            'Provide non-empty target-language text and complete equivalent source-language answers. Keep the intended meaning unambiguous.',
        example: 'Vorrei un caffè.',
      );
    }
    if (presetId == 'type_translation_to_source' && fieldKey == 'accepted') {
      return const ExerciseFieldHelp(
        title: 'Accepted translations',
        purpose:
            'Defines complete source-language translations accepted for the target-language text.',
        entryRules: answerSyntax,
        validation: expressionChecks,
        example: 'I would like a coffee.\nI’d like a coffee.',
      );
    }
    if ((presetId == 'sort_into_groups' || presetId == 'fill_the_slots') &&
        fieldKey == 'question') {
      final groups = presetId == 'sort_into_groups';
      return ExerciseFieldHelp(
        title: 'Question',
        purpose: groups
            ? 'What the learner is asked to sort. Example: Sort the words: animals or food?'
            : 'What the learner is asked to fill. Example: Which article goes with each noun?',
        entryRules:
            'One line, in the language you prefer. The groups or slots below are what the learner sees under it.',
        validation: 'Required.',
        example: groups
            ? 'Sort the words: animals or food?'
            : 'Which article goes with each noun?',
      );
    }
    return forField(fieldForEditor(presetId, fieldKey));
  }

  /// Keys correspond to existing form values, never user-visible field labels.
  static ExerciseAuthoringField fieldForEditor(
    String presetId,
    String fieldKey,
  ) => switch (fieldKey) {
    'prompt' => switch (presetId) {
      'flashcard' ||
      'picture_flashcard' => ExerciseAuthoringField.wordOrExpression,
      'complete_text' => ExerciseAuthoringField.textToComplete,
      'missing_letters' => ExerciseAuthoringField.bracketedText,
      'spell_word' => ExerciseAuthoringField.clue,
      'note_card' => ExerciseAuthoringField.noteTitle,
      'dialogue_line' => ExerciseAuthoringField.dialogueLine,
      'story_cover' => ExerciseAuthoringField.coverTitle,
      'type_translation_to_target' ||
      'type_translation_to_source' ||
      'build_translation_to_target' ||
      'build_translation_to_source' => ExerciseAuthoringField.sourceText,
      'reading_answer_target' ||
      'reading_answer_source' => ExerciseAuthoringField.readingPassage,
      'listening_spelling' => ExerciseAuthoringField.listeningTranscript,
      'missing_word' => ExerciseAuthoringField.transcript,
      _ => ExerciseAuthoringField.instruction,
    },
    'question' => switch (presetId) {
      'flashcard' ||
      'picture_flashcard' => ExerciseAuthoringField.translationMeaning,
      'true_false' => ExerciseAuthoringField.statement,
      'note_card' => ExerciseAuthoringField.noteText,
      'gap_choice' => ExerciseAuthoringField.gapSentence,
      _ => ExerciseAuthoringField.question,
    },
    'tts' => switch (presetId) {
      'flashcard' ||
      'picture_flashcard' => ExerciseAuthoringField.pronunciationTts,
      'spell_heard' => ExerciseAuthoringField.spokenWord,
      _ => ExerciseAuthoringField.audioText,
    },
    'hint' => ExerciseAuthoringField.hint,
    'answers' => switch (presetId) {
      'flashcard' ||
      'picture_flashcard' => ExerciseAuthoringField.usageSentence,
      'picture_word_match' => ExerciseAuthoringField.pairWords,
      _ => ExerciseAuthoringField.choices,
    },
    'correct' => ExerciseAuthoringField.correctAnswer,
    'accepted' => switch (presetId) {
      'type_translation_to_target' || 'type_translation_to_source' =>
        ExerciseAuthoringField.acceptedTranslations,
      'picture_name' => ExerciseAuthoringField.acceptedNames,
      _ => ExerciseAuthoringField.acceptedAnswers,
    },
    'tokens' => switch (presetId) {
      'sentence_order' => ExerciseAuthoringField.lines,
      'gap_blocks' => ExerciseAuthoringField.distractorBlocks,
      'build_translation_to_target' || 'build_translation_to_source' =>
        ExerciseAuthoringField.availableTranslationBlocks,
      _ => ExerciseAuthoringField.availableWordBlocks,
    },
    'order' => switch (presetId) {
      'image_word' ||
      'spell_heard' ||
      'spell_word' => ExerciseAuthoringField.correctWordOrder,
      'sentence_order' => ExerciseAuthoringField.correctLineOrder,
      _ => ExerciseAuthoringField.correctBlockOrder,
    },
    'correctTranslation' => ExerciseAuthoringField.correctTranslation,
    'gapLayout' => ExerciseAuthoringField.gapLayout,
    'revealFirstLetter' => ExerciseAuthoringField.revealFirstLetter,
    'requiredSelections' => ExerciseAuthoringField.selectRequiredSelections,
    'pairs' => switch (presetId) {
      'word_match' => ExerciseAuthoringField.translationPairs,
      'super_match' => ExerciseAuthoringField.relatedPairs,
      'audio_match' => ExerciseAuthoringField.soundMatches,
      _ => ExerciseAuthoringField.translationPairs,
    },
    'icons' => ExerciseAuthoringField.iconKeys,
    'missingWords' =>
      presetId == 'listening_spelling'
          ? ExerciseAuthoringField.missingWord
          : ExerciseAuthoringField.missingWords,
    'dialogue' => ExerciseAuthoringField.dialogue,
    'speaker' => ExerciseAuthoringField.speaker,
    'lineMode' => ExerciseAuthoringField.lineMode,
    'readAloud' => switch (presetId) {
      'flashcard' ||
      'picture_flashcard' => ExerciseAuthoringField.cardReadAloud,
      _ => ExerciseAuthoringField.lineReadAloud,
    },
    'groups' => ExerciseAuthoringField.groups,
    'leftover' => ExerciseAuthoringField.leftoverWords,
    'slots' => ExerciseAuthoringField.slots,
    'extraWords' => ExerciseAuthoringField.extraWords,
    'slotReuse' => ExerciseAuthoringField.slotReuse,
    'textReveal' => ExerciseAuthoringField.lineTextReveal,
    'language' => ExerciseAuthoringField.lineLanguage,
    'image' => switch (presetId) {
      'story_cover' => ExerciseAuthoringField.coverImage,
      _ => ExerciseAuthoringField.image,
    },
    'scriptMode' => ExerciseAuthoringField.scriptMode,
    'scriptPrompt' => ExerciseAuthoringField.scriptPrompt,
    'scriptPromptImages' => ExerciseAuthoringField.scriptPromptImages,
    'scriptTextOptions' => ExerciseAuthoringField.scriptTextOptions,
    'scriptImageOptions' => ExerciseAuthoringField.scriptImageOptions,
    'scriptCorrect' => ExerciseAuthoringField.scriptCorrect,
    _ => throw ArgumentError.value(
      fieldKey,
      'fieldKey',
      'Unknown editor field',
    ),
  };

  static ExerciseFieldHelp forField(
    ExerciseAuthoringField field,
  ) => switch (field) {
    ExerciseAuthoringField.scriptMode => const ExerciseFieldHelp(
      title: 'Recognition mode',
      purpose: 'Choose how the learner recognizes a character or syllable.',
      entryRules:
          'Image to text shows one or more prompt images with text answer options. Text to image shows a text prompt with image answer options. Switching modes retains both sets of fields during this editing session; saving uses the selected mode.',
      validation:
          'Both modes use normal Select with at least two options and exactly one correct option. Mode changes do not create a different learner engine.',
      example:
          'Show several handwritten forms of 가 and ask the learner to choose ga.',
    ),
    ExerciseAuthoringField.scriptPrompt => const ExerciseFieldHelp(
      title: 'Character text prompt',
      purpose: 'Supplies the text that the learner matches to an image.',
      entryRules:
          'Enter the character, syllable, sound transcription or instruction as plain text. Keep the image answers in their separate option fields.',
      validation:
          'Text to image requires a nonempty text prompt, at least two image-only options and exactly one correct option.',
      example: 'Choose the character pronounced ga.',
    ),
    ExerciseAuthoringField.scriptPromptImages => ExerciseFieldHelp(
      title: 'Character prompt images',
      purpose:
          'Shows one or more representations of the same character or syllable.',
      entryRules:
          'Add printed forms, different fonts, handwriting or stylistic variants. Choose an Image Bank image or import a PNG, JPEG or WEBP from ${QqlStorageLayout.current.folderLabel(QqlStorageRole.imageImports)}. Imported bytes belong to the course and are retained in Course JSON; no absolute local path is saved.',
      validation:
          'Image to text requires at least one readable prompt image and at least two text options. Each imported image must be at most 50 KB (51,200 bytes) and no more than 4096 pixels in either dimension. Invalid image data blocks Save and Preview.',
      example:
          'Show a printed 가 and a handwritten 가 above the options ga and na.',
    ),
    ExerciseAuthoringField.scriptTextOptions => const ExerciseFieldHelp(
      title: 'Character text options',
      purpose: 'Provides the possible readings of the prompt images.',
      entryRules:
          'Enter one literal reading or label in each option field. Add or remove options with the adjacent controls. Reordering keeps the same option identity and correct-answer selection.',
      validation:
          'Image to text requires at least two nonempty text-only options and exactly one correct option. Answer-expression syntax is not expanded for Select options.',
      example: 'Option 1: ga\nOption 2: na',
    ),
    ExerciseAuthoringField.scriptImageOptions => const ExerciseFieldHelp(
      title: 'Character image options',
      purpose: 'Provides the images from which the learner selects an answer.',
      entryRules:
          'Choose one portable Image Bank or imported PNG, JPEG or WEBP image for each option. Imported bytes are stored with the course. Reordering keeps the image option identity and correct-answer selection.',
      validation:
          'Text to image requires at least two readable image-only options and exactly one correct option. Imported images must be at most 50 KB (51,200 bytes) and 4096 pixels in either dimension. Absolute local paths and invalid image data are rejected.',
      example: 'For the prompt ga, offer an image of 가 and an image of 나.',
    ),
    ExerciseAuthoringField.scriptCorrect => const ExerciseFieldHelp(
      title: 'Correct character option',
      purpose: 'Identifies the single option that answers the prompt.',
      entryRules:
          'Select the circle beside the correct option. Selecting a different circle replaces the previous correct choice. Reordering an option keeps its correct-answer status; deleting it requires choosing another correct option.',
      validation:
          'Exactly one existing option must be correct. A Draft may remain incomplete; Preview and Published Save require a valid correct choice.',
      example: 'Mark ga correct for an image of 가.',
    ),
    ExerciseAuthoringField.instruction => const ExerciseFieldHelp(
      title: 'Prompt / instruction',
      purpose: 'The instruction or context shown to the learner.',
      entryRules:
          'Enter one instruction or prompt as plain text. Line breaks remain part of that text; they do not create separate answers. Use the course source language for operational instructions.',
      validation:
          'Keep it consistent with the selected exercise and the separately entered question, pairs or blocks. For Match related words, state the relationship in the target language.',
      example: 'Build the sentence.',
    ),
    ExerciseAuthoringField.sourceText => const ExerciseFieldHelp(
      title: 'Source text',
      purpose: 'Supplies the text that the learner translates.',
      entryRules:
          'Enter one source-language sentence or passage. Line breaks belong to the same prompt; accepted answers or correct translations go in their own fields.',
      validation:
          'Provide non-empty source text and complete equivalent target-language answers. Keep the intended meaning unambiguous.',
      example: 'I would like a coffee.',
    ),
    ExerciseAuthoringField.wordOrExpression => const ExerciseFieldHelp(
      title: 'Word / expression',
      purpose: 'Shows the target-language material on a Flashcard.',
      entryRules:
          'Enter one word or expression. Put its meaning, pronunciation text and usage example in the separate fields.',
      validation:
          'A target word or phrase is required. Flashcard content is presentation and supplies no ordinary scored answer.',
      example: 'buongiorno',
    ),
    ExerciseAuthoringField.translationMeaning => const ExerciseFieldHelp(
      title: 'Translation / meaning',
      purpose: 'Explains the Flashcard word or expression.',
      entryRules:
          'Enter one plain-text meaning or translation. Multiple lines remain one explanation.',
      validation:
          'An empty meaning produces an Audit warning. Check that it matches the displayed word.',
      example: 'good morning',
    ),
    ExerciseAuthoringField.usageSentence => const ExerciseFieldHelp(
      title: 'Usage sentence and optional translation',
      purpose: 'Shows the Flashcard word in context.',
      entryRules:
          'First non-empty line: usage sentence. Optional second non-empty line: its translation. The learner view adds “Usage:” automatically. Blank lines are ignored.',
      validation:
          'A missing usage sentence produces an Audit warning. These lines are presentation content, not answer options.',
      example: 'Buongiorno, Maria!\nGood morning, Maria!',
    ),
    ExerciseAuthoringField.question => const ExerciseFieldHelp(
      title: 'Question',
      purpose: 'The concrete content to which the learner responds.',
      entryRules:
          'Enter one question as plain text, separately from the reading, audio or dialogue context. Line breaks do not create separate questions.',
      validation:
          'Contextual comprehension requires a separate question. For Dialogue response, use the target language. Match the question to the declared correct answer.',
      example: 'How are you?',
    ),
    ExerciseAuthoringField.gapSentence => const ExerciseFieldHelp(
      title: 'Target-language sentence with one gap',
      purpose: 'Shows the sentence the learner completes by choosing a block.',
      entryRules:
          'Use ___ (3 underscores) for the missing word. Example: The cat ___ black. Enter one target-language sentence with the missing word or expression replaced by that gap. Enter possible replacements as separate answer lines.',
      validation:
          'At least one ___ marker is required; more than one produces a warning. The sentence with the correct answer inserted must contain at least two words.',
      example: 'Vorrei un ___, per favore.',
    ),
    ExerciseAuthoringField.readingPassage => const ExerciseFieldHelp(
      title: 'Text to read',
      purpose:
          'Provides the text, situation or context the learner reads before answering the separate question. Example: Maria prende il treno. Va a Roma.',
      entryRules:
          'Enter one passage, situation or short text in the target language. Multiple lines or paragraphs remain part of the text. With dialogue lines, this text is the context shown before them and may stay short.',
      validation:
          'A text containing words, or dialogue lines, is required; punctuation alone is insufficient. One or two lexical words produce a warning; at least three are recommended. The question should test comprehension.',
      example: 'Maria prende il treno. Va a Roma.',
    ),
    ExerciseAuthoringField.transcript => const ExerciseFieldHelp(
      title: 'Passage transcript',
      purpose:
          'Supplies the complete text from which the learner view creates listening gaps.',
      entryRules:
          'Enter one complete transcript including the word or expressions to hide. Use ordinary text, not pre-inserted dots or underscores. Line breaks remain part of the passage.',
      validation:
          'For Listen for missing words, every missing entry must occur in the transcript. Match Audio text to what the learner should hear.',
      example: 'Vorrei un caffè, per favore.\nMissing word: caffè',
    ),
    ExerciseAuthoringField.listeningTranscript => const ExerciseFieldHelp(
      title: 'Passage transcript',
      purpose: 'Supplies the visible prompt text for Type what you hear.',
      entryRules:
          'Enter one text value. This preset displays the text as entered; it does not automatically remove the accepted answer from the transcript. Audio text controls what the learner hears.',
      validation:
          'Preview the prompt to make sure it does not reveal the answer you want the learner to type. Put accepted typed responses in Missing word.',
      example: 'Listen and type the word you hear.',
    ),
    ExerciseAuthoringField.audioText => const ExerciseFieldHelp(
      title: 'Audio text',
      purpose: 'Defines the word or passage that the learner hears.',
      entryRules:
          'Enter one spoken text, not an MP3 filename or path. Multiple lines form the same passage. Course Audio Library selects On-Device TTS, Recorded MP3 or Hybrid and maps recordings to exact words or expressions.',
      validation:
          'Listening exercises require non-empty audio text. For contextual comprehension, supply the text/audio context selected by Context mode. Preview playback and review missing recorded mappings in Audit.',
      example: 'Vorrei un caffè, per favore.',
    ),
    ExerciseAuthoringField.pronunciationTts => const ExerciseFieldHelp(
      title: 'Pronunciation TTS (if different)',
      purpose:
          'What the read-aloud speaks when it should differ from the word or expression.',
      entryRules:
          'Leave empty: the read-aloud speaks the word or expression above. Enter a text only when the spoken form differs, for example an abbreviation read in full. No recording path; recordings are managed in Course Audio Library.',
      validation:
          'Optional. When given, the Course audio mode must be able to play it.',
      example: 'dottore (for the abbreviation Dott.)',
    ),
    ExerciseAuthoringField.cardReadAloud => const ExerciseFieldHelp(
      title: 'Read aloud',
      purpose: 'Whether and when the word or expression is spoken.',
      entryRules:
          'Automatically (when the card appears), On request (the learner taps the speaker) or No read-aloud. The spoken text is the word or expression itself, unless Pronunciation TTS (if different) says otherwise, played with the Course audio mode (On-Device TTS, Recorded MP3 or Hybrid).',
      validation:
          'None. Read-aloud never makes the card an audio exercise: the card is shown when Audio Exercises are off.',
      example: 'On request',
    ),
    ExerciseAuthoringField.hint => const ExerciseFieldHelp(
      title: 'Hint',
      purpose: 'Gives the learner a useful clue.',
      entryRules:
          'Enter one optional plain-text clue. Leave blank if the exercise needs no hint. Line breaks remain part of the same clue.',
      validation:
          'A hint must not reveal a canonical correct answer. Merely repeating the prompt produces a warning.',
      example: 'Think of a hot drink served in a small cup.',
    ),
    ExerciseAuthoringField.choices => const ExerciseFieldHelp(
      title: 'Answers / options',
      purpose: 'Defines the alternatives presented to the learner.',
      entryRules:
          'Enter one literal answer per line, with at least two non-empty lines. Blank lines are ignored. The first non-empty line is answer 1. Compact accepted-answer syntax does not create choices.',
      validation:
          'Select one valid Correct answer number. Avoid duplicate answers and make distractors plausible but unambiguously wrong. Select the image also needs one icon/image key per answer in the same order.',
      example: 'caffè\nacqua\npane',
    ),
    ExerciseAuthoringField.correctAnswer => const ExerciseFieldHelp(
      title: 'Correct answer number',
      purpose: 'Identifies the one correct option from the answer list.',
      entryRules:
          'Enter one whole number, counting non-empty answer lines from 1. Do not paste the answer text or a JSON index.',
      validation:
          'The number must be between 1 and the number of answers. Dialogue response accepts 1 or 2. Recheck it after reordering or deleting answer lines.',
      example: '2 selects the second non-empty answer line.',
    ),
    ExerciseAuthoringField.acceptedAnswers => const ExerciseFieldHelp(
      title: 'Accepted answers',
      purpose:
          'Defines the complete text the learner may type to complete the gap.',
      entryRules: answerSyntax,
      validation: expressionChecks,
      example: 'caffè\nun caffè',
    ),
    ExerciseAuthoringField.acceptedTranslations => const ExerciseFieldHelp(
      title: 'Accepted translations',
      purpose:
          'Defines complete target-language translations accepted for the source text.',
      entryRules: answerSyntax,
      validation: expressionChecks,
      example: '{Io} [prendo|vorrei] un cappuccino',
    ),
    ExerciseAuthoringField.availableWordBlocks => const ExerciseFieldHelp(
      title: 'Available word blocks',
      purpose: 'Supplies the blocks the learner puts into sentence order.',
      entryRules:
          'Enter one literal target-language block per line. Blank lines are ignored. Repeat a line when the answer needs another occurrence of that word or block. When Inline gaps is enabled, this field is relabeled Extra distractor blocks: the gap answers themselves come from the {answer} braces in Sentence with gaps, and this field only adds optional unused distractors.',
      validation:
          'Include every block occurrence used in Correct sentence. You may add 0, 1 or at most 2 unused distractor blocks. Keep block spelling and internal punctuation consistent with the correct order.',
      example: 'Io\nbevo\nun\ncaffè\ntè',
    ),
    ExerciseAuthoringField.availableTranslationBlocks => const ExerciseFieldHelp(
      title: 'Available target-language blocks',
      purpose:
          'Supplies the blocks used to construct the configured correct translations.',
      entryRules:
          'Enter one literal block per line. Blank lines are ignored. Include enough distinct occurrences to construct every correct translation; repeated words require repeated lines. When Inline gaps is enabled, this field is relabeled Extra distractor blocks: the gap answers themselves come from the {answer} braces in Target sentence with gaps, and this field only adds optional unused distractors.',
      validation:
          'Every correct translation must be constructible from these blocks. At most 2 blocks may be unused by every correct translation. A block used by any configured answer is not an unused distractor. Answer-expression syntax is not expanded.',
      example: 'Io\nprendo\nvorrei\nun\ncaffè',
    ),
    ExerciseAuthoringField.correctBlockOrder => const ExerciseFieldHelp(
      title: 'Correct sentence',
      purpose: 'Defines the required order of the available word blocks.',
      entryRules:
          'Enter one block per line in the correct order, not the whole sentence on one line. Blocks are joined with spaces. Blank lines are ignored. Not used when Inline gaps is enabled: gap answers are written directly inside braces in Sentence with gaps instead.',
      validation:
          'Each line must match an available block occurrence. Repeated words need separate available occurrences. This is one literal order; compact answer syntax is not expanded.',
      example: 'Io\nbevo\nun\ncaffè',
    ),
    ExerciseAuthoringField.correctWordOrder => const ExerciseFieldHelp(
      title: 'Blocks of the word, in order',
      purpose:
          'The letter or syllable blocks that spell the word, in the right order; the learner gets exactly these blocks, shuffled.',
      entryRules:
          'Enter one letter or syllable per line, in answer order. The blocks are joined without spaces to form the word; repeat a line for a letter that occurs twice. Blank lines are ignored.',
      validation:
          'At least two blocks and no distractors: a spelling exercise offers only the blocks of its word. Spell the word in the picture also needs an Exercise image.',
      example: 'ca\nsa\nThese blocks form casa.',
    ),
    ExerciseAuthoringField.gapLayout => const ExerciseFieldHelp(
      title: 'Sentence with gaps',
      purpose:
          'Shows the fixed sentence text with one or more inline blanks the learner fills with word or phrase tiles.',
      entryRules:
          'Write the fixed sentence and put each answer word or phrase directly inside braces: {answer}. Example: I {am} going {to} London. Each {…} segment is both the gap and its correct answer, so no separate Correct answers / Correct sentence field is needed in this mode. Extra distractor blocks that are not used by any gap still go in Available word blocks / Extra distractor blocks (optional).',
      validation:
          'At least one {…} gap is required, and every gap must contain non-empty text. Literal { or } characters cannot appear anywhere else in the sentence — every { must be paired with a matching } directly around one answer. Existing whole-sentence Arrange exercises are unaffected unless Inline gaps is enabled.',
      example: 'I {am} going {to} London.',
    ),
    ExerciseAuthoringField.selectRequiredSelections => const ExerciseFieldHelp(
      title: 'Required selections',
      purpose:
          'Sets the minimum number of options the learner must select before checking a multiple-selection Choice exercise.',
      entryRules:
          'Enter a whole number between 1 and the number of answers, or leave blank to default to the number of correct answers.',
      validation:
          'The Check button stays disabled until at least this many options are selected. This does not cap how many options may be selected; correctness always requires an exact match of the selected set to the correct set.',
      example: '2',
    ),
    ExerciseAuthoringField.revealFirstLetter => const ExerciseFieldHelp(
      title: 'Show the first letter',
      purpose:
          'Decides whether the gap reveals the first letter of the missing word as a hint.',
      entryRules:
          'On: the learner sees the first letter followed by a blank and types the whole word. '
          'Off: the gap is empty and the learner types the word without help. '
          'Either way, enter the complete word among the accepted answers.',
      validation:
          'With the hint on, every accepted word must start with the same first letter. '
          'The setting changes the exercise, so the Audit reads it from the exercise itself.',
      example: 'On: é______ for école. Off: ______ for école.',
    ),
    ExerciseAuthoringField.statement => const ExerciseFieldHelp(
      title: 'Statement',
      purpose:
          'The sentence in the target language the learner judges true or false.',
      entryRules:
          'Enter one statement as plain text. Make it clearly true or clearly false; an optional spoken statement reads it aloud.',
      validation:
          'Required. The two answers below are the words for true and false; the correct number is 1 when the statement is true, 2 when it is false.',
      example: 'Roma è la capitale d’Italia.',
    ),
    ExerciseAuthoringField.textToComplete => const ExerciseFieldHelp(
      title: 'Text with the words to hide',
      purpose: 'The complete text; the missing words listed below become gaps.',
      entryRules:
          'Write the whole text including the words to hide, as plain text. Several sentences are fine.',
      validation:
          'Every missing word must occur in the text, in order; the first occurrence after the previous gap is hidden.',
      example: 'Anna beve un caffè al bar. Poi prende il treno.',
    ),
    ExerciseAuthoringField.bracketedText => const ExerciseFieldHelp(
      title: 'Text with the missing letters in brackets',
      purpose:
          'The complete text with the missing letters marked inside square brackets.',
      entryRules:
          'Write the complete text and put the letters to hide inside [ and ], one bracket per gap: My cat doesn’t dr[ink] milk. Several gaps are fine.',
      validation:
          'At least one bracket is required and no bracket may be empty. The learner sees one underscore per hidden letter and types the letters.',
      example: 'Il ga[tt]o dor[me] sul divano.',
    ),
    ExerciseAuthoringField.distractorBlocks => const ExerciseFieldHelp(
      title: 'Extra distractor blocks (optional)',
      purpose: 'Blocks that fill no gap, offered beside the answers.',
      entryRules:
          'One extra block per line. Include 0, 1 or at most 2 distractors.',
      validation: 'A distractor must not repeat the text of any gap answer.',
      example: 'sempre',
    ),
    ExerciseAuthoringField.lines => const ExerciseFieldHelp(
      title: 'Sentences or lines',
      purpose: 'The lines of the story or dialogue the learner puts in order.',
      entryRules:
          'One sentence or line per line, in any order. You may add 0, 1 or at most 2 extra lines that belong nowhere.',
      validation:
          'Every line of the correct order must be listed here; at most two lines may stay unused.',
      example: 'Anna entra nel bar.\nOrdina un caffè.\nPaga e saluta.',
    ),
    ExerciseAuthoringField.correctLineOrder => const ExerciseFieldHelp(
      title: 'Correct order',
      purpose: 'The lines in the right order.',
      entryRules:
          'One line per line, exactly as written above, in the correct order.',
      validation: 'Each line must match one of the listed lines.',
      example: 'Anna entra nel bar.\nOrdina un caffè.\nPaga e saluta.',
    ),
    ExerciseAuthoringField.spokenWord => const ExerciseFieldHelp(
      title: 'Spoken word',
      purpose: 'The word the learner hears and spells from the tiles.',
      entryRules:
          'Enter the word as text; it is read aloud with the target-language voice or matched to a Course recording.',
      validation: 'Required. The tiles below must spell exactly this word.',
      example: 'gatto',
    ),
    ExerciseAuthoringField.clue => const ExerciseFieldHelp(
      title: 'Clue',
      purpose:
          'What names the word to spell: the word itself or a definition in the source language.',
      entryRules: 'Enter one short clue in the source language.',
      validation: 'Required unless a picture or a spoken word names the word.',
      example: 'cat (the animal)',
    ),
    ExerciseAuthoringField.acceptedNames => const ExerciseFieldHelp(
      title: 'Accepted answers',
      purpose: 'The names of what the picture shows that the learner may type.',
      entryRules: ExerciseFieldHelpRegistry.answerSyntax,
      validation: ExerciseFieldHelpRegistry.expressionChecks,
      example: '[il|un] gatto\ngatto',
    ),
    ExerciseAuthoringField.pairWords => const ExerciseFieldHelp(
      title: 'Words',
      purpose: 'The words of the pairs; each gets a picture below.',
      entryRules: 'One word per line, in the target language. At least two.',
      validation: 'Every word needs its picture; words must be unique.',
      example: 'gatto\ncane\ncasa',
    ),
    ExerciseAuthoringField.noteTitle => const ExerciseFieldHelp(
      title: 'Title',
      purpose: 'The heading of the note card.',
      entryRules: 'One short title, in the language you prefer.',
      validation: 'Required.',
      example: 'Tu or Lei?',
    ),
    ExerciseAuthoringField.noteText => const ExerciseFieldHelp(
      title: 'Note',
      purpose: 'The tip, grammar or cultural note the learner reads.',
      entryRules: 'Plain text; several paragraphs are fine.',
      validation:
          'Required. There is no answer and no score; Continue closes the card.',
      example: 'Use Lei with people you do not know well.',
    ),
    ExerciseAuthoringField.speaker => const ExerciseFieldHelp(
      title: 'Speaker',
      purpose: 'Who says the line.',
      entryRules:
          "The narrator or one of the Course's Story characters (Course Editor › Story characters).",
      validation:
          'A character must exist in the Course; the Audit reports a missing one.',
      example: 'Anna',
    ),
    ExerciseAuthoringField.dialogueLine => const ExerciseFieldHelp(
      title: 'Line',
      purpose: 'The line itself.',
      entryRules:
          "One line of dialogue, in the speaker's language. It is shown, spoken or both, as the mode says.",
      validation: 'Required.',
      example: 'Buongiorno! Un caffè, per favore.',
    ),
    ExerciseAuthoringField.lineMode => const ExerciseFieldHelp(
      title: 'Mode',
      purpose: 'Whether the learner reads the line, hears it, or both.',
      entryRules:
          'Text and audio, Text only, or Audio only. Audio only makes the line a listening step; when audio is unavailable the text is shown instead.',
      validation: 'None.',
      example: 'Text and audio',
    ),
    ExerciseAuthoringField.lineReadAloud => const ExerciseFieldHelp(
      title: 'Read-aloud',
      purpose: "When the line's audio plays.",
      entryRules:
          "Story default (the Round's Read-aloud option), Automatic (plays when the line appears) or On request (the learner taps).",
      validation: 'None.',
      example: 'Story default',
    ),
    ExerciseAuthoringField.lineTextReveal => const ExerciseFieldHelp(
      title: 'Show text',
      purpose: 'Whether the text waits for the audio.',
      entryRules:
          'Immediately, or After listening: the text appears once the audio has played (only with text and audio).',
      validation: 'None.',
      example: 'Immediately',
    ),
    ExerciseAuthoringField.lineLanguage => const ExerciseFieldHelp(
      title: 'Language',
      purpose: 'The language the line is in.',
      entryRules:
          "The speaker's language (default), or Target / Source to override it for this line.",
      validation: 'None.',
      example: "Speaker's",
    ),
    ExerciseAuthoringField.coverTitle => const ExerciseFieldHelp(
      title: 'Title line',
      purpose: 'An optional title line on the cover.',
      entryRules:
          "A short line; the Story's title (Round options) is shown above the cover anyway.",
      validation: 'Optional.',
      example: 'At the café',
    ),
    ExerciseAuthoringField.groups => const ExerciseFieldHelp(
      title: 'Groups',
      purpose: 'The groups and the words each one takes.',
      entryRules:
          'One group per line: the group name, a colon, then its words separated by commas. At least one group (usually two or more), each with at least one word.',
      validation:
          'A word can be in one group only. A line without a name or without words is refused before Preview or Save.',
      example: 'Animals: gatto, cane\nFood: mela, pane',
    ),
    ExerciseAuthoringField.leftoverWords => const ExerciseFieldHelp(
      title: 'Words that belong nowhere',
      purpose:
          'Words offered with the others that belong to no group; the learner must leave them in the bank.',
      entryRules: 'One word per line. Optional.',
      validation: 'A word listed here cannot also be in a group.',
      example: 'tavolo',
    ),
    ExerciseAuthoringField.slots => const ExerciseFieldHelp(
      title: 'Slots',
      purpose: 'The slots and the word that fills each one.',
      entryRules:
          'One slot per line: what the learner sees, an equals sign, then the word. Use … or ___ for the missing part. At least one slot.',
      validation:
          'Every line needs both sides. The same word in two slots needs “A word may fill more than one slot”.',
      example: '… gatto = il\n… casa = la',
    ),
    ExerciseAuthoringField.extraWords => const ExerciseFieldHelp(
      title: 'Extra words',
      purpose: 'Words offered that fill no slot.',
      entryRules: 'One word per line. Optional.',
      validation: 'An extra word cannot repeat a slot word.',
      example: 'lo',
    ),
    ExerciseAuthoringField.slotReuse => const ExerciseFieldHelp(
      title: 'A word may fill more than one slot',
      purpose: 'Whether one word can be the answer of several slots.',
      entryRules:
          'Off: each word is offered once and fills one slot. On: a word stays in the bank after each use.',
      validation: 'None.',
      example: 'On, for “… cane = il” and “… libro = il”',
    ),
    ExerciseAuthoringField.coverImage => const ExerciseFieldHelp(
      title: 'Cover picture',
      purpose: 'The cover picture.',
      entryRules:
          'A picture from the Course, the Shared Image Library or a bundled image.',
      validation:
          'Recommended; a cover without a picture shows the title only.',
      example: 'A café terrace',
    ),
    ExerciseAuthoringField.correctTranslation => const ExerciseFieldHelp(
      title: 'Correct translation',
      purpose: 'Defines one complete literal answer for Build the translation.',
      entryRules:
          'Each separate answer entry holds one complete target-language sentence. Use Add correct translation for another answer and the drag handle to reorder answers.',
      validation:
          'At least one non-empty answer is required. Answers must be unique after case, spacing and terminal-punctuation normalization, and constructible from distinct available block occurrences. Internal punctuation is preserved. No optional, alternative or reorder expressions, similarity matching or typo acceptance are applied.',
      example: 'Io vorrei un caffè.',
    ),
    ExerciseAuthoringField.translationPairs => const ExerciseFieldHelp(
      title: 'Translation pairs',
      purpose:
          'Matches source-language words with their target-language translations.',
      entryRules:
          'Enter at least two non-empty lines as source = target; three is the usual number. The first equals sign separates the two sides. Blank lines are ignored.',
      validation:
          'Every pair needs both sides. Check unique, unambiguous matching and remove malformed lines; fix lines without a usable separator before Preview or Save.',
      example: 'house = casa\nbread = pane\nwater = acqua',
    ),
    ExerciseAuthoringField.relatedPairs => const ExerciseFieldHelp(
      title: 'Three target-language pairs',
      purpose: 'Matches related words, such as synonyms or opposites.',
      entryRules:
          'Enter exactly three non-empty lines as left = right, with both sides in the target language. State the relationship in Match type / instruction.',
      validation:
          'All three pairs need both sides and a usable equals separator. Check that every pair follows the stated relationship and that matching is unambiguous.',
      example: 'grande = piccolo\ncaldo = freddo\naperto = chiuso',
    ),
    ExerciseAuthoringField.soundMatches => const ExerciseFieldHelp(
      title: 'Three sound matches',
      purpose:
          'Matches three spoken target-language items to their visible texts.',
      entryRules:
          'Enter exactly three lines as audio text = visible text. Visible text may be target-language text or its translation. The three right sides become the three visible choices; there is no separate distractor field.',
      validation:
          'Both sides are required. Avoid duplicate sounds and visible choices, including punctuation-only or capitalization-only differences. No distractors are permitted. Use Course Audio Library for recording mappings.',
      example: 'casa = house\npane = bread\nacqua = water',
    ),
    ExerciseAuthoringField.iconKeys => const ExerciseFieldHelp(
      title: 'Pictures and icon keys',
      purpose:
          'Associates each answer with its picture: the pickers above choose one picture per answer; this list shows the result and also accepts named icon keys.',
      entryRules:
          'Enter one icon key or existing bundled assets/ image path per line, in the same order as the answer options. Blank lines are ignored. Keys include water, home, coffee, person, hello, sun, moon, thanks, tree, flower, bread, train, bus, bike, shirt, book, food and shop.',
      validation:
          'The number of keys must equal the number of answers. An unknown key shows the generic image icon, so Preview every choice. A custom Exercise image below the form is a separate shared prompt image, not an option image.',
      example: 'coffee\nwater\nassets/exercise_images/house.webp',
    ),
    ExerciseAuthoringField.missingWord => const ExerciseFieldHelp(
      title: 'Missing word',
      purpose: 'Defines accepted typed responses for Type what you hear.',
      entryRules:
          'Despite the compact field label, each entry is a complete accepted word or passage, not an instruction to remove text from the transcript. $answerSyntax',
      validation:
          '$expressionChecks Match the accepted responses to Audio text and check the visible prompt in Preview.',
      example: 'caffè',
    ),
    ExerciseAuthoringField.missingWords => const ExerciseFieldHelp(
      title: 'Missing word(s)',
      purpose:
          'Selects the words or expressions hidden in the listening transcript.',
      entryRules:
          'Enter one literal word or expression per line. Multiple lines select multiple gaps, not alternative complete answers. Blank lines are ignored; do not insert gap markers in the transcript.',
      validation:
          'At least one entry is required and each entry must occur in Passage transcript, ignoring case. Duplicate entries produce a warning. Answer-expression syntax is not expanded for this list.',
      example: 'caffè\nper favore',
    ),
    ExerciseAuthoringField.dialogue => const ExerciseFieldHelp(
      title: 'Structured dialogue (optional)',
      purpose: 'Presents context as a sequence of named speaker turns.',
      entryRules:
          'Enter one turn per line as Speaker: text. The first colon separates the speaker from the spoken text. Blank lines are ignored. Leave blank for ordinary non-dialogue context.',
      validation:
          'Every entered turn needs both a non-empty speaker and non-empty text. Speaker labels do not create separate voice settings.',
      example: 'Jane: Are you coming?\nJim: I changed my mind.',
    ),
    ExerciseAuthoringField.image => ExerciseFieldHelp(
      title: 'Exercise image',
      purpose: 'Adds one image to the exercise prompt or context.',
      entryRules:
          'Choose a flat image from the shared image library (managed by admins), or place exactly one PNG, JPG, JPEG or WebP file in ${QqlStorageLayout.current.folderLabel(QqlStorageRole.imageImports)} and press Import custom image. Any course editor can import a custom image; it is not added to the shared library. Import copies the original bytes to local app storage; it does not resize, crop or change transparency.',
      validation:
          'Maximum 50 KB (51,200 bytes). 256 × 256 pixels and 15 KB or less are recommendations, not enforced dimensions. Image-prompt ordering requires an image; other current presets may omit it. Missing or multiple source files and oversized files are rejected. Preview checks that the image displays. Course JSON stores the image path, not these image bytes, so custom exercise images are not portable through course JSON alone.',
      example:
          'Bundled path: assets/exercise_images/house.webp\nCustom paths are selected and stored by the importer.',
    ),
  };
}
