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
  incompletePhrase,
  readingPassage,
  dialogueSituation,
  transcript,
  listeningTranscript,
  audioText,
  pronunciationTts,
  optionalPhraseTts,
  hint,
  choices,
  responseOptions,
  correctAnswer,
  acceptedAnswers,
  acceptedTranslations,
  availableWordBlocks,
  availableTranslationBlocks,
  availableLetterBlocks,
  correctBlockOrder,
  correctWordOrder,
  correctTranslation,
  pairs,
  translationPairs,
  relatedPairs,
  soundMatches,
  iconKeys,
  missingWord,
  missingWords,
  contextMode,
  contextText,
  dialogue,
  image,
  scriptMode,
  scriptPrompt,
  scriptPromptImages,
  scriptTextOptions,
  scriptImageOptions,
  scriptCorrect,
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
      'generated sentence starts are capitalized.';

  static const expressionChecks =
      'At least one accepted answer is required. Malformed expressions are rejected. '
      'Expansion is deterministic, duplicate results are removed, and the combined '
      'limit is 128 answers; simplify an expression that exceeds it. '
      'Declare equivalent answers explicitly: syntax does not invent translations.';

  static ExerciseFieldHelp forEditorField(String presetId, String fieldKey) {
    if (presetId == 'type_missing_word' &&
        const {'prompt', 'accepted'}.contains(fieldKey)) {
      return const ExerciseFieldHelp(
        title: 'Type the missing word',
        purpose: 'Complete a missing word after its first letter is provided.',
        entryRules:
            'Enter a sentence with exactly one ___ gap and complete accepted words, one per line. The first Unicode grapheme is derived automatically; the learner types only the remainder.',
        validation:
            'All complete accepted words must share exactly the same first grapheme. The reconstructed response uses normal Input normalization and supported typo tolerance.',
        example:
            'I would like a ___. Answer: cappuccino. Learner sees c______ and types appuccino.',
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
      'flashcard' => ExerciseAuthoringField.wordOrExpression,
      'type_translation' ||
      'build_translation' => ExerciseAuthoringField.sourceText,
      'reading_comprehension' => ExerciseAuthoringField.readingPassage,
      'dialogue_response' => ExerciseAuthoringField.dialogueSituation,
      'listening_spelling' => ExerciseAuthoringField.listeningTranscript,
      'missing_word' => ExerciseAuthoringField.transcript,
      _ => ExerciseAuthoringField.instruction,
    },
    'question' => switch (presetId) {
      'flashcard' => ExerciseAuthoringField.translationMeaning,
      'gap_choice' => ExerciseAuthoringField.gapSentence,
      'fill_blank' => ExerciseAuthoringField.incompletePhrase,
      _ => ExerciseAuthoringField.question,
    },
    'tts' => switch (presetId) {
      'flashcard' => ExerciseAuthoringField.pronunciationTts,
      'fill_blank' => ExerciseAuthoringField.optionalPhraseTts,
      _ => ExerciseAuthoringField.audioText,
    },
    'hint' => ExerciseAuthoringField.hint,
    'answers' => switch (presetId) {
      'flashcard' => ExerciseAuthoringField.usageSentence,
      'dialogue_response' => ExerciseAuthoringField.responseOptions,
      _ => ExerciseAuthoringField.choices,
    },
    'correct' => ExerciseAuthoringField.correctAnswer,
    'accepted' =>
      presetId == 'type_translation'
          ? ExerciseAuthoringField.acceptedTranslations
          : ExerciseAuthoringField.acceptedAnswers,
    'tokens' => switch (presetId) {
      'image_word' => ExerciseAuthoringField.availableLetterBlocks,
      'build_translation' => ExerciseAuthoringField.availableTranslationBlocks,
      _ => ExerciseAuthoringField.availableWordBlocks,
    },
    'order' =>
      presetId == 'image_word'
          ? ExerciseAuthoringField.correctWordOrder
          : ExerciseAuthoringField.correctBlockOrder,
    'correctTranslation' => ExerciseAuthoringField.correctTranslation,
    'pairs' => switch (presetId) {
      'word_match' => ExerciseAuthoringField.translationPairs,
      'super_match' => ExerciseAuthoringField.relatedPairs,
      'audio_match' => ExerciseAuthoringField.soundMatches,
      _ => ExerciseAuthoringField.pairs,
    },
    'icons' => ExerciseAuthoringField.iconKeys,
    'missingWords' =>
      presetId == 'listening_spelling'
          ? ExerciseAuthoringField.missingWord
          : ExerciseAuthoringField.missingWords,
    'contextMode' => ExerciseAuthoringField.contextMode,
    'context' => ExerciseAuthoringField.contextText,
    'dialogue' => ExerciseAuthoringField.dialogue,
    'image' => ExerciseAuthoringField.image,
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
    ExerciseAuthoringField.scriptPromptImages => const ExerciseFieldHelp(
      title: 'Character prompt images',
      purpose:
          'Shows one or more representations of the same character or syllable.',
      entryRules:
          'Add printed forms, different fonts, handwriting or stylistic variants. Choose an Image Bank image or import a PNG, JPEG or WEBP from Documents/QuisquisLingo/Imports/Images. Imported bytes belong to the course and are retained in Course JSON; no absolute local path is saved.',
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
      example: 'Translate into Italian.',
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
          'Enter one target-language sentence and replace the missing word or expression with ___ (three underscores). Enter possible replacements as separate answer lines.',
      validation:
          'At least one ___ marker is required; more than one produces a warning. The sentence with the correct answer inserted must contain at least two words.',
      example: 'Vorrei un ___, per favore.',
    ),
    ExerciseAuthoringField.incompletePhrase => const ExerciseFieldHelp(
      title: 'Incomplete word / phrase',
      purpose: 'Shows the word or phrase that the learner completes by typing.',
      entryRules:
          'Enter one incomplete word or phrase using visible gap text where useful. In Accepted answers, enter the text the learner should type, not a list of answer choices.',
      validation:
          'Supply at least one accepted answer. This existing preset does not automatically reveal a first letter.',
      example: 'Vorrei un ___.\nAccepted answer: caffè',
    ),
    ExerciseAuthoringField.readingPassage => const ExerciseFieldHelp(
      title: 'Reading passage',
      purpose:
          'Provides the passage needed to answer the separate comprehension question.',
      entryRules:
          'Enter one passage in plain text. Multiple lines or paragraphs remain part of the passage.',
      validation:
          'A passage containing words is required. One or two lexical words produce a warning; at least three are recommended. The question should test comprehension.',
      example: 'Maria prende il treno. Va a Roma.',
    ),
    ExerciseAuthoringField.dialogueSituation => const ExerciseFieldHelp(
      title: 'Context sentence',
      purpose: 'Sets the situation for choosing the best dialogue response.',
      entryRules:
          'Enter one situation in the target language. Keep the question separate and provide exactly two response options.',
      validation:
          'Context, question and both responses must be non-empty. Choose one response as correct.',
      example: 'Un amico ti saluta al mattino.',
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
          'Enter one spoken text, not an MP3 filename or path. Multiple lines form the same passage. Course Audio Library selects System TTS, Recorded MP3 or Hybrid and maps recordings to exact words or expressions.',
      validation:
          'Listening exercises require non-empty audio text. For contextual comprehension, supply the text/audio context selected by Context mode. Preview playback and review missing recorded mappings in Audit.',
      example: 'Vorrei un caffè, per favore.',
    ),
    ExerciseAuthoringField.pronunciationTts => const ExerciseFieldHelp(
      title: 'Pronunciation TTS',
      purpose: 'Supplies spoken pronunciation for the Flashcard.',
      entryRules:
          'Enter the word or expression to pronounce as one text value. Do not enter a recording path; manage recordings in Course Audio Library.',
      validation:
          'Missing pronunciation text produces an Audit warning. Check that the selected course audio mode can play it.',
      example: 'buongiorno',
    ),
    ExerciseAuthoringField.optionalPhraseTts => const ExerciseFieldHelp(
      title: 'Complete phrase TTS (optional)',
      purpose: 'Supplies optional pronunciation text for the completed phrase.',
      entryRules:
          'Enter one complete phrase, including the missing answer, or leave blank. This is spoken text, not a recording filename.',
      validation:
          'Keep this text consistent with the incomplete phrase and accepted answers. Test the pronunciation in Preview.',
      example: 'Vorrei un caffè.',
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
    ExerciseAuthoringField.responseOptions => const ExerciseFieldHelp(
      title: 'Two response options',
      purpose: 'Provides the two possible responses to the dialogue situation.',
      entryRules:
          'Enter exactly two non-empty lines, both in the target language. Each line is one complete response; blank lines are ignored.',
      validation:
          'Set Correct response number to 1 or 2. The learner sees randomized display order, while the chosen correct response remains the same.',
      example: 'Buongiorno!\nBuonanotte!',
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
          'Enter one literal target-language block per line. Blank lines are ignored. Repeat a line when the answer needs another occurrence of that word or block.',
      validation:
          'Include every block occurrence used in Correct sentence. You may add 0, 1 or at most 2 unused distractor blocks. Keep block spelling and internal punctuation consistent with the correct order.',
      example: 'Io\nbevo\nun\ncaffè\ntè',
    ),
    ExerciseAuthoringField.availableTranslationBlocks => const ExerciseFieldHelp(
      title: 'Available target-language blocks',
      purpose:
          'Supplies the blocks used to construct the configured correct translations.',
      entryRules:
          'Enter one literal block per line. Blank lines are ignored. Include enough distinct occurrences to construct every correct translation; repeated words require repeated lines.',
      validation:
          'Every correct translation must be constructible from these blocks. At most 2 blocks may be unused by every correct translation. A block used by any configured answer is not an unused distractor. Answer-expression syntax is not expanded.',
      example: 'Io\nprendo\nvorrei\nun\ncaffè',
    ),
    ExerciseAuthoringField.availableLetterBlocks => const ExerciseFieldHelp(
      title: 'Available letter / syllable blocks',
      purpose: 'Supplies the pieces of the word shown in the image.',
      entryRules:
          'Enter one literal letter or syllable per line. Blank lines are ignored. Repeat a line if that piece occurs more than once in the word.',
      validation:
          'Include only the pieces needed for the answer: no distractors. Supply their order in Correct target-language word and select an Exercise image.',
      example: 'ca\nsa',
    ),
    ExerciseAuthoringField.correctBlockOrder => const ExerciseFieldHelp(
      title: 'Correct sentence',
      purpose: 'Defines the required order of the available word blocks.',
      entryRules:
          'Enter one block per line in the correct order, not the whole sentence on one line. Blocks are joined with spaces. Blank lines are ignored.',
      validation:
          'Each line must match an available block occurrence. Repeated words need separate available occurrences. This is one literal order; compact answer syntax is not expanded.',
      example: 'Io\nbevo\nun\ncaffè',
    ),
    ExerciseAuthoringField.correctWordOrder => const ExerciseFieldHelp(
      title: 'Correct target-language word',
      purpose: 'Defines the order of the letter or syllable blocks.',
      entryRules:
          'Enter one letter or syllable block per line in answer order. The pieces are joined without spaces to form one word; blank lines are ignored.',
      validation:
          'Use each required available occurrence once, leave no distractors and supply the matching Exercise image.',
      example: 'ca\nsa\nThese pieces form casa.',
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
    ExerciseAuthoringField.pairs => const ExerciseFieldHelp(
      title: 'Pairs',
      purpose: 'Defines items that the learner matches across two columns.',
      entryRules:
          'Enter one pair per line as left = right. The first equals sign separates the two sides. Blank lines are ignored.',
      validation:
          'At least one usable pair is required. Give both sides non-empty text and check every line contains its separator; fix incomplete lines before Preview or Save.',
      example: 'casa = house\npane = bread',
    ),
    ExerciseAuthoringField.translationPairs => const ExerciseFieldHelp(
      title: 'Three translation pairs',
      purpose:
          'Matches source-language words with their target-language translations.',
      entryRules:
          'Enter exactly three non-empty lines as source = target. The first equals sign separates the two sides. Blank lines are ignored.',
      validation:
          'All three pairs need both sides. Check unique, unambiguous matching and remove malformed lines; fix lines without a usable separator before Preview or Save.',
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
      title: 'Icons / image keys',
      purpose: 'Associates each Select the image answer with its visual.',
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
    ExerciseAuthoringField.contextMode => const ExerciseFieldHelp(
      title: 'Context mode',
      purpose: 'Chooses how the comprehension context is presented.',
      entryRules:
          'Select one mode: Text, Audio, or Text and audio. Text modes expose Context text and optional structured dialogue; audio modes expose Context audio text.',
      validation:
          'Supply usable text, audio or dialogue context plus a separate question and answer options. An image alone is not sufficient context. Preview the selected mode.',
    ),
    ExerciseAuthoringField.contextText => const ExerciseFieldHelp(
      title: 'Context text',
      purpose:
          'Provides the passage, announcement or situation needed to answer the question.',
      entryRules:
          'Enter one plain-text context, with paragraphs if useful. Use Structured dialogue for speaker-labelled turns. The question belongs in its own field.',
      validation:
          'At least one usable text, audio or dialogue context is required. When choosing Text and audio, check both representations convey the intended context.',
      example: 'The café closes at six. Maria arrives at five.',
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
    ExerciseAuthoringField.image => const ExerciseFieldHelp(
      title: 'Exercise image',
      purpose: 'Adds one image to the exercise prompt or context.',
      entryRules:
          'Choose a flat image, or place exactly one PNG, JPG, JPEG or WebP file in Documents/QuisquisLingo/Imports/Images and press Import custom image. Import copies the original bytes to local app storage; it does not resize, crop or change transparency.',
      validation:
          'Maximum 50 KB (51,200 bytes). 256 × 256 pixels and 15 KB or less are recommendations, not enforced dimensions. Image-prompt ordering requires an image; other current presets may omit it. Missing or multiple source files and oversized files are rejected. Preview checks that the image displays. Course JSON stores the image path, not these image bytes, so custom exercise images are not portable through course JSON alone.',
      example:
          'Bundled path: assets/exercise_images/house.webp\nCustom paths are selected and stored by the importer.',
    ),
  };
}
