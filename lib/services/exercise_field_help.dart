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
  gapAnswers,
  allGapsSentence,
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
  correctLineOrder,
  extraLines,
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
  introText,
  guidebookButton,
  pageBlocks,
  groups,
  slots,
  extraWords,
  slotReuse,
  nameBlocks,
  extraNameBlocks,
  extraSpellingBlocks,
  dialogueReadAloud,
  pictureAnswers,
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
      'gap_choice': ['prompt', 'question', 'answers', 'correct', 'hint'],
      'type_missing_word': ['revealFirstLetter', 'prompt', 'accepted', 'hint'],
      'word_order': ['prompt', 'gapLayout', 'tokens', 'order', 'tts'],
      'listening_choose_target': ['tts', 'prompt', 'answers', 'correct'],
      'listening_choose_source': ['tts', 'prompt', 'answers', 'correct'],
      'listening_answer_target': ['tts', 'question', 'answers', 'correct'],
      'listening_answer_source': ['tts', 'question', 'answers', 'correct'],
      'listening_spelling': ['prompt', 'tts', 'missingWords'],
      'missing_word': ['prompt', 'tts', 'missingWords'],
      'audio_match': ['prompt', 'pairs'],
      'reading_answer_target': [
        'prompt',
        'dialogue',
        'dialogueReadAloud',
        'question',
        'answers',
        'correct',
      ],
      'icon_choice': [
        'question',
        'answers',
        'correct',
        'icons',
        'pictureSize',
        'pictureShape',
        'picturesPerRow',
        'pictureBorder',
      ],
      'script_recognition': [
        'scriptMode',
        'scriptPrompt',
        'scriptPromptImages',
        'scriptTextOptions',
        'scriptImageOptions',
        'scriptCorrect',
      ],
      'image_word': ['prompt', 'order', 'extraWords'],
      'picture_flashcard': [
        'prompt',
        'question',
        'readAloud',
        'tts',
        'answers',
      ],
      'true_false': ['question', 'tts', 'answers', 'correct'],
      'one_word_fills_all': [
        'prompt',
        'question',
        'answers',
        'correct',
        'hint',
      ],
      'complete_text': ['question', 'prompt', 'missingWords', 'hint'],
      'missing_letters': ['prompt', 'tts', 'hint'],
      'gap_blocks': ['prompt', 'gapLayout', 'tokens', 'tts'],
      'sentence_order': ['prompt', 'order', 'extraWords', 'hint'],
      'listening_image_choice': [
        'tts',
        'prompt',
        'answers',
        'correct',
        'icons',
        'pictureSize',
        'pictureShape',
        'picturesPerRow',
        'pictureBorder',
      ],
      'spell_heard': ['tts', 'order', 'extraWords'],
      'picture_choice': ['prompt', 'answers', 'correct'],
      'picture_name': ['prompt', 'accepted', 'hint'],
      'picture_blocks': ['prompt', 'order', 'extraWords', 'hint'],
      'spell_word': ['prompt', 'order', 'extraWords'],
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
      'before_you_start': ['prompt', 'guidebookButton'],
      'page': ['blocks'],
      'sort_into_groups': ['prompt', 'groups'],
      'fill_the_slots': ['prompt', 'slots', 'extraWords', 'slotReuse'],
    };
    final selected = fields[presetId];
    if (selected == null) {
      throw ArgumentError.value(
        presetId,
        'presetId',
        'Unknown Exercise preset',
      );
    }
    // A Before you start card has no picture (Build 257); Match pictures to
    // words has only the pictures of its words (Build 259 Revision 5), and
    // Select the image and Listen and pick the image only the pictures of
    // their answers (Build 263 Revision 0).
    return [
      ...selected,
      if (presetId != 'script_recognition' &&
          presetId != 'before_you_start' &&
          presetId != 'page' &&
          presetId != 'picture_word_match' &&
          presetId != 'icon_choice' &&
          presetId != 'listening_image_choice')
        'image',
    ];
  }

  /// The two Choose the answer twins share one form.
  static bool _isChoice(String presetId) =>
      presetId == 'choice_target' || presetId == 'choice_source';

  static ExerciseFieldHelp forEditorField(String presetId, String fieldKey) {
    if ((_isChoice(presetId) || presetId == 'icon_choice') &&
        fieldKey == 'question') {
      final choice = presetId != 'icon_choice';
      return ExerciseFieldHelp(
        title: 'Question or sentence',
        purpose: choice
            ? 'What the learner answers: a question, or a sentence with a gap the answers complete. Example: Which article goes with casa?'
            : 'What the learner looks for among the pictures: a question, or a sentence naming it. Example: Select ‘gatto’.',
        entryRules: choice
            ? 'Enter one question, or one sentence with ___ where the answer fits. An instruction or context goes in Instruction or context.'
            : 'Enter one question or sentence that names the word the right picture shows. An instruction or context has no field here.',
        validation: choice
            ? 'Required: a Published save refuses it empty. Provide matching answers and mark the correct one (or several with Multiple correct answers).'
            : 'Required: a Published save refuses it empty. Give every answer its picture and mark the correct one.',
        example: choice ? 'Which article goes with casa?' : 'Select ‘gatto’.',
      );
    }
    if (presetId.startsWith('listening_answer') && fieldKey == 'question') {
      return const ExerciseFieldHelp(
        title: 'Question',
        purpose:
            'The question the learner answers about what they hear. Example: Dove fa la spesa Maria?',
        entryRules:
            'Enter one question about the recording: who, what, where, how many. Listen and answer (to source) asks it in the source language. To let the learner simply pick what was heard, use Listen and choose.',
        validation:
            'Required: a Published save refuses it empty. Make the recording long enough to answer it, and mark the correct answer.',
        example: 'Dove fa la spesa Maria?',
      );
    }
    if ((presetId.startsWith('listening_answer') ||
            presetId.startsWith('listening_choose') ||
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
            'between underscores: _answer_. Example: I _am_ going _to_ '
            'London. Each tap fills the first remaining empty blank, '
            'whichever option is tapped — placement does not check '
            'correctness, so the right words in the wrong blanks are '
            'still marked incorrect. Extra options that are not the '
            'answer to any gap go in Distractor options (optional).',
        validation:
            'At least one _…_ gap is required, and every gap must contain '
            'non-empty text. A lone _ cannot appear anywhere else in the '
            'sentence.',
        example: 'I _am_ going _to_ London.',
      );
    }
    if (_isChoice(presetId) && fieldKey == 'tokens') {
      return const ExerciseFieldHelp(
        title: 'Distractor options (optional)',
        purpose:
            'Adds options the learner can select that are not the answer '
            'to any gap.',
        entryRules:
            'One extra option per line. Few distractors work best: 0, 1 '
            'or 2 are recommended, fewer in the first Rounds of a Lesson.',
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
            title: 'Sentence',
            purpose:
                'The $textLanguage-language word or phrase the learner translates.',
            entryRules:
                'Enter one $textLanguage-language word, phrase or sentence. '
                'Do not write an instruction: QQL adds “Choose the correct '
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
    if (presetId == 'type_missing_word' && fieldKey == 'prompt') {
      return const ExerciseFieldHelp(
        title: 'Sentence',
        purpose:
            'The target-language sentence the learner completes, with one ___ gap where the word goes.',
        entryRules:
            'Enter one sentence with exactly one ___ gap. The complete accepted words go in their own field; the first letter, when shown, is derived from them.',
        validation:
            'Required: a Published save refuses it empty. With Show the first letter on, the sentence needs its ___ gap.',
        example: 'Je vais à l’___.',
      );
    }
    if (presetId == 'type_missing_word' && fieldKey == 'accepted') {
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
        title: 'Sentence',
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
      'before_you_start' => ExerciseAuthoringField.introText,
      'type_translation_to_target' ||
      'type_translation_to_source' ||
      'build_translation_to_target' ||
      'build_translation_to_source' => ExerciseAuthoringField.sourceText,
      'reading_answer_target' => ExerciseAuthoringField.readingPassage,
      'missing_word' => ExerciseAuthoringField.transcript,
      _ => ExerciseAuthoringField.instruction,
    },
    'question' => switch (presetId) {
      'flashcard' ||
      'picture_flashcard' => ExerciseAuthoringField.translationMeaning,
      // Complete the text keeps its instruction there (Build 259 Revision 1).
      'complete_text' => ExerciseAuthoringField.instruction,
      'true_false' => ExerciseAuthoringField.statement,
      'note_card' => ExerciseAuthoringField.noteText,
      'gap_choice' => ExerciseAuthoringField.gapSentence,
      // One word fills all (Build 259 Revision 4).
      'one_word_fills_all' => ExerciseAuthoringField.allGapsSentence,
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
      'picture_blocks' => ExerciseAuthoringField.nameBlocks,
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
    'missingWords' => switch (presetId) {
      'listening_spelling' => ExerciseAuthoringField.missingWord,
      // Complete the text: one line per ___ gap (Build 259 Revision 3).
      'complete_text' => ExerciseAuthoringField.gapAnswers,
      _ => ExerciseAuthoringField.missingWords,
    },
    'dialogue' => ExerciseAuthoringField.dialogue,
    'dialogueReadAloud' => ExerciseAuthoringField.dialogueReadAloud,
    'speaker' => ExerciseAuthoringField.speaker,
    'lineMode' => ExerciseAuthoringField.lineMode,
    'readAloud' => switch (presetId) {
      'flashcard' ||
      'picture_flashcard' => ExerciseAuthoringField.cardReadAloud,
      _ => ExerciseAuthoringField.lineReadAloud,
    },
    'groups' => ExerciseAuthoringField.groups,
    'slots' => ExerciseAuthoringField.slots,
    'extraWords' => switch (presetId) {
      'picture_blocks' => ExerciseAuthoringField.extraNameBlocks,
      'image_word' ||
      'spell_heard' ||
      'spell_word' => ExerciseAuthoringField.extraSpellingBlocks,
      'sentence_order' => ExerciseAuthoringField.extraLines,
      _ => ExerciseAuthoringField.extraWords,
    },
    'slotReuse' => ExerciseAuthoringField.slotReuse,
    'pictureSize' ||
    'pictureShape' ||
    'picturesPerRow' ||
    'pictureBorder' => ExerciseAuthoringField.pictureAnswers,
    'guidebookButton' => ExerciseAuthoringField.guidebookButton,
    'blocks' => ExerciseAuthoringField.pageBlocks,
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
      title: 'Question or sentence',
      purpose:
          'Names the character the learner finds among the images: a question or a sentence.',
      entryRules:
          'Enter the character, syllable or sound transcription, as a question or a sentence. Keep the image answers in their separate option fields.',
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
      title: 'Instruction or context (optional)',
      purpose:
          'An optional line in the learners’ language: what to do, the situation, or the meaning the exercise needs. Example: Put the dialogue at the bar in order.',
      entryRules:
          'Write one line in the learners’ language, or nothing. In a Round it takes the place of the standard instruction line under the heading; leave it empty to keep that line. It may set the scene (Anna goes to the market in the morning) or give the meaning (Anna reads a book). The question, the sentence and the answers go in their own fields.',
      validation:
          'Optional. It is stored without a language, so it never turns the exercise into a translation. Keep it consistent with the rest of the exercise, and do not give the answer away.',
      example: 'Put the dialogue at the bar in order.',
    ),
    ExerciseAuthoringField.sourceText => const ExerciseFieldHelp(
      title: 'Sentence',
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
    ExerciseAuthoringField.allGapsSentence => const ExerciseFieldHelp(
      title: 'Sentences, with ___ for each gap',
      purpose:
          'The sentences the learner completes with one word that fits every gap. Example: ___ gatto dorme. ___ cane mangia.',
      entryRules:
          'Write the sentences in the target language with ___ (3 underscores) wherever the same word goes; at least two gaps. The chosen word appears in every gap.',
      validation:
          'Required: a Published save refuses it without two or more gaps. For one gap, use Pick the missing word.',
      example: '___ gatto dorme. ___ cane mangia.',
    ),
    ExerciseAuthoringField.gapSentence => const ExerciseFieldHelp(
      title: 'Sentence',
      purpose: 'Shows the sentence the learner completes by choosing a block.',
      entryRules:
          'Use ___ (3 underscores) for the missing word. Example: The cat ___ black. Enter one target-language sentence with the missing word or expression replaced by that gap. Enter possible replacements as separate answer lines.',
      validation:
          'At least one ___ marker is required; more than one produces a warning. The sentence with the correct answer inserted must contain at least two words.',
      example: 'Vorrei un ___, per favore.',
    ),
    ExerciseAuthoringField.readingPassage => const ExerciseFieldHelp(
      title: 'Text to read (source language)',
      purpose:
          'Explains the situation in the learners’ own language before the dialogue and the question; it is never read aloud. Example: Anna and Luca are in the kitchen after lunch.',
      entryRules:
          'Enter a short text in the source language. Multiple lines or paragraphs remain part of the text. The dialogue lines, the question and the answers are in the target language.',
      validation:
          'A text containing words, or dialogue lines, is required; punctuation alone is insufficient.',
      example: 'Anna and Luca are in the kitchen after lunch.',
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
          'Enter one literal target-language block per line. Blank lines are ignored. Repeat a line when the answer needs another occurrence of that word or block. When Inline gaps is enabled, this field is relabeled Extra distractor blocks: the gap answers themselves come from the _answer_ markers in Sentence with gaps, and this field only adds optional unused distractors.',
      validation:
          'Include every block occurrence used in Correct sentence. Few distractors work best: 0, 1 or 2 unused distractor blocks are recommended, fewer in the first Rounds of a Lesson; more are allowed. Keep block spelling and internal punctuation consistent with the correct order.',
      example: 'Io\nbevo\nun\ncaffè\ntè',
    ),
    ExerciseAuthoringField.availableTranslationBlocks => const ExerciseFieldHelp(
      title: 'Available target-language blocks',
      purpose:
          'Supplies the blocks used to construct the configured correct translations.',
      entryRules:
          'Enter one literal block per line. Blank lines are ignored. Include enough distinct occurrences to construct every correct translation; repeated words require repeated lines. When Inline gaps is enabled, this field is relabeled Extra distractor blocks: the gap answers themselves come from the _answer_ markers in Target sentence with gaps, and this field only adds optional unused distractors.',
      validation:
          'Every correct translation must be constructible from these blocks. Few distractors work best: at most 2 blocks unused by every correct translation are recommended, fewer in the first Rounds of a Lesson; more are allowed. A block used by any configured answer is not an unused distractor. Answer-expression syntax is not expanded.',
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
          'The letter or syllable blocks that spell the word, in the right order; the learner gets these blocks, shuffled, with any Extra blocks.',
      entryRules:
          'Enter one letter or syllable per line, in answer order. The blocks are joined without spaces to form the word; repeat a line for a letter that occurs twice. Blank lines are ignored.',
      validation:
          'At least two blocks. Blocks that are not in the word go in Extra blocks (Build 265 Revision 11). Spell the word in the picture also needs an Exercise image.',
      example: 'ca\nsa\nThese blocks form casa.',
    ),
    ExerciseAuthoringField.gapLayout => const ExerciseFieldHelp(
      title: 'Sentence with gaps',
      purpose:
          'Shows the fixed sentence text with one or more inline blanks the learner fills with word or phrase tiles.',
      entryRules:
          'Write the fixed sentence and put each answer word or phrase between underscores: _answer_. Example: I _am_ going _to_ London. Each _…_ segment is both the gap and its correct answer, and each word fills one gap. Extra distractor words that fill no gap go in Extra distractor words (optional).',
      validation:
          'At least one _…_ gap is required, and every gap must contain non-empty text. A lone _ cannot appear anywhere else in the sentence. Existing whole-sentence Arrange exercises are unaffected.',
      example: 'I _am_ going _to_ London.',
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
      title: 'Sentence',
      purpose:
          'The sentence in the target language the learner judges true or false.',
      entryRules:
          'Enter one statement as plain text. Make it clearly true or clearly false; an optional spoken statement reads it aloud.',
      validation:
          'Required. The two answers below are the words for true and false; the correct number is 1 when the statement is true, 2 when it is false.',
      example: 'Roma è la capitale d’Italia.',
    ),
    ExerciseAuthoringField.textToComplete => const ExerciseFieldHelp(
      title: 'Text, with ___ for each gap',
      purpose:
          'The text the learner completes; each ___ is a gap. Example: Anna beve un ___ al bar.',
      entryRules:
          'Write the text and put ___ (three underscores) where each missing word or phrase goes. Several sentences are fine.',
      validation:
          'At least one gap, and as many gaps as lines in Missing words.',
      example: 'Anna beve un ___ al bar. Poi prende ___.',
    ),
    ExerciseAuthoringField.gapAnswers => const ExerciseFieldHelp(
      title: 'Missing words',
      purpose: 'What goes into each gap, in order. Example: caffè',
      entryRules:
          'One line per ___ gap, in the order the gaps appear. A line may accept several answers: [il|un] gatto accepts il gatto and un gatto; {il} gatto accepts gatto with or without il.',
      validation:
          'As many lines as gaps. Malformed alternatives are rejected. Answers are checked with the normal Input normalization.',
      example: 'caffè\n[il|un] treno',
    ),
    ExerciseAuthoringField.bracketedText => const ExerciseFieldHelp(
      title: 'Text with the missing letters between underscores',
      purpose:
          'The complete text with the missing letters marked between underscores. Example: dr_ink_',
      entryRules:
          'Write the complete text and put the letters to hide between underscores, one pair per gap: My cat doesn’t dr_ink_ milk. Several gaps are fine.',
      validation:
          'At least one gap is required and none may be empty. The learner sees one underscore per hidden letter and types the letters.',
      example: 'Il ga_tt_o dor_me_ sul divano.',
    ),
    ExerciseAuthoringField.distractorBlocks => const ExerciseFieldHelp(
      title: 'Extra distractor blocks (optional)',
      purpose: 'Blocks that fill no gap, offered beside the answers.',
      entryRules:
          'One extra block per line. Few distractors work best: 0, 1 or 2 are recommended, fewer in the first Rounds of a Lesson.',
      validation: 'A distractor must not repeat the text of any gap answer.',
      example: 'sempre',
    ),
    ExerciseAuthoringField.correctLineOrder => const ExerciseFieldHelp(
      title: 'Lines, in the correct order',
      purpose:
          'The lines of the story or dialogue, in the order the learner must find. Example: Anna entra nel bar.',
      entryRules:
          'One sentence or line per line, in the correct order; the learner gets them shuffled. Lines that belong nowhere go in Extra lines.',
      validation:
          'At least two lines to publish. The same text twice is two lines.',
      example: 'Anna entra nel bar.\nOrdina un caffè.\nPaga e saluta.',
    ),
    ExerciseAuthoringField.extraLines => const ExerciseFieldHelp(
      title: 'Extra lines (optional)',
      purpose:
          'Lines offered with the others that belong nowhere; the learner must leave them out.',
      entryRules:
          'One line per line. Few work best: 0, 1 or 2 are recommended.',
      validation: 'Optional. Keep them plausible but clearly out of place.',
      example: 'Il treno parte alle nove.',
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
      title: 'Clue (source language)',
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
          'One group per line: the group name, a colon, then its words separated by commas. At least two groups, each with at least one word; every word belongs to one group.',
      validation:
          'A word can be in one group only. A line without a name or without words is refused before Preview or Save.',
      example: 'Animals: gatto, cane\nPlants: rosa, pino',
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
    ExerciseAuthoringField.nameBlocks => const ExerciseFieldHelp(
      title: 'Blocks of the name, in order',
      purpose:
          'The name of what the picture shows, as the word blocks the learner puts in order.',
      entryRules:
          'One word per line, in the right order. The learner gets these blocks shuffled, with any extra blocks.',
      validation:
          'Required, with the Exercise image. The blocks joined with spaces are the answer.',
      example: 'il\npane',
    ),
    ExerciseAuthoringField.extraNameBlocks => const ExerciseFieldHelp(
      title: 'Extra blocks',
      purpose: 'Words offered with the name that are not part of it.',
      entryRules:
          'One word per line. Optional; few work best: two at most are recommended.',
      validation:
          'More than two extra blocks is allowed; Course Audit lists it as Info.',
      example: 'la',
    ),
    // Build 265 Revision 11 (owner, 7 October 2026): distractors in the
    // spelling exercises, with a note.
    ExerciseAuthoringField.extraSpellingBlocks => const ExerciseFieldHelp(
      title: 'Extra blocks',
      purpose:
          'Blocks offered with the word that are not part of it: distractors.',
      entryRules:
          'One letter or syllable per line. Optional: only the blocks of the word are recommended; add extra blocks deliberately, fewer in a Lesson\'s first Rounds.',
      validation:
          'Allowed; Course Audit lists them as Info. The learner must leave them out.',
      example: 'e',
    ),
    ExerciseAuthoringField.dialogueReadAloud => const ExerciseFieldHelp(
      title: 'Read the dialogue aloud',
      purpose:
          'Whether the dialogue lines are spoken: automatically when the exercise appears, on request with the Play dialogue button, or not at all.',
      entryRules:
          'Choose Automatically, On request or No read-aloud. Each line is spoken in turn with a short pause, in the target language.',
      validation:
          'Read-aloud is optional: the exercise is never an audio exercise and stays silent with Audio Exercises or Text-to-speech off.',
      example: 'Automatically, line by line',
    ),
    ExerciseAuthoringField.introText => const ExerciseFieldHelp(
      title: 'Note',
      purpose:
          'What the learner reads before the Round starts: what the Round practises, a tip, a reminder.',
      entryRules:
          'A few sentences in the language your learners read best. The learner reads it on its own page and presses Continue to Round.',
      validation: 'Required: an empty card is an Audit error.',
      example:
          'This Round practises greetings. Say buongiorno until the afternoon.',
    ),
    ExerciseAuthoringField.guidebookButton => const ExerciseFieldHelp(
      title: 'Open GuideBook button',
      purpose: 'Whether the card offers the Lesson’s GuideBook.',
      entryRules:
          'On: the card shows Open GuideBook. Learners see the button only while the Course uses GuideBooks (Lesson Options) and the Lesson’s GuideBook is published; Preview shows it for a Draft GuideBook too.',
      validation: 'Greyed out while the Course does not use GuideBooks.',
      example: 'On, when the GuideBook explains the Round’s grammar.',
    ),
    ExerciseAuthoringField.pageBlocks => const ExerciseFieldHelp(
      title: 'Page blocks',
      purpose:
          'The blocks of the Page, top to bottom: headings, paragraphs, quotes, lists, pictures, audio and video links.',
      entryRules:
          'Add blocks with Add block and order them with the arrows. In paragraphs, quotes and lists write **bold** and *italic* (the toolbar wraps the selection; \\* shows a star); a list takes one item per line. Choose an alignment and a colour per text block, a size and a caption per picture, the spoken text of an audio block, and the label and https address of a video link. The preview shows the Page as the learner sees it.',
      validation:
          'A Page with no content is an Audit error; an unmatched mark is a warning; a link must be an https address.',
      example:
          'Heading 1: Greetings\nParagraph: Say **buongiorno** until *noon*.\nVideo link: https://example.org/greetings',
    ),
    ExerciseAuthoringField.pictureAnswers => const ExerciseFieldHelp(
      title: 'Picture answers',
      purpose:
          'How the pictures the learner chooses from look: their size, their '
          'shape and how many stand in a row.',
      entryRules:
          'Without a choice the pictures are large squares, two per row. As '
          'in Lesson Options follows the Course (Course Editor › Lesson '
          'Options › Picture answers); any other value is this exercise’s '
          'own. Square shows each picture cropped to a square: Crop square '
          'under a picture chooses the part and the zoom and stores the '
          'cropped copy in the Course.',
      validation: 'None.',
      example: 'Large, Square, 2 per row',
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
      title: 'Other accepted spellings (optional)',
      purpose:
          'Other ways to write what the learner hears; the Audio text itself is always accepted. Example: alle 9 for alle nove.',
      entryRules:
          'Leave it empty when the Audio text is the only way to write it. Otherwise enter one complete spelling per line: the whole text heard, not a single missing word. Alternatives inside a line: alle [9|nove]. Capitals, punctuation and spacing are ignored anyway.',
      validation:
          'Optional. Every line must be the same words the learner hears; do not accept words that are not heard. Malformed alternatives are rejected.',
      example: 'arrivo alle 8',
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
          'Choose a flat image from the shared image library (managed by admins), or place exactly one PNG, JPG, JPEG or WebP file in ${QqlStorageLayout.current.folderLabel(QqlStorageRole.imageImports)} and press Import custom image. Any course editor can import a custom image; it is not added to the shared library. Import copies the original bytes to local app storage; it does not resize, crop or change transparency. Tick Plural when the picture stands for several things (gatti, cats): the learner sees stacked copies of it, no number and no word.',
      validation:
          'Maximum 300 KB (307,200 bytes). 256 × 256 pixels and 15 KB or less are recommendations, not enforced dimensions. Image-prompt ordering requires an image; other current presets may omit it. Missing or multiple source files and oversized files are rejected. Preview checks that the image displays. Course JSON stores the image path, not these image bytes, so custom exercise images are not portable through course JSON alone.',
      example:
          'Bundled path: assets/exercise_images/house.webp\nCustom paths are selected and stored by the importer.',
    ),
  };
}
