enum ExerciseCategory {
  multipleChoice('Multiple choice'),
  translation('Translation'),
  textInput('Text input'),
  matching('Matching'),
  ordering('Ordering'),
  presentation('Presentation');

  const ExerciseCategory(this.label);
  final String label;
}

enum CanonicalExerciseModel { select, input, arrange, match, presentation }

class ExercisePreset {
  const ExercisePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.model,
  });

  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;
  final CanonicalExerciseModel model;
}

/// The single authoring registry used by the picker, Help and validation.
///
/// Presets describe a useful teaching workflow. Several presets deliberately
/// share one canonical runtime model.
abstract final class ExercisePresetRegistry {
  static const presets = <ExercisePreset>[
    ExercisePreset(
      id: 'choice',
      name: 'How do you say',
      description: 'Learner chooses the correct translation from alternatives.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'gap_choice',
      name: 'Fill in the blank',
      description: 'Learner selects the missing word or expression.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'icon_choice',
      name: 'Select the image',
      description: 'Learner chooses the image corresponding to the prompt.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'listening_choice',
      name: 'What do you hear',
      description: 'Learner listens and chooses the matching written answer.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'listening_comprehension',
      name: 'Listen and choose',
      description:
          'Learner listens to a passage and selects the correct answer.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'reading_comprehension',
      name: 'Reading comprehension',
      description: 'Learner reads a passage and selects the correct answer.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'dialogue_response',
      name: 'Dialogue response',
      description: 'Learner reads a situation and selects the best response.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'contextual_comprehension',
      name: 'Contextual comprehension',
      description:
          'Learner reads and/or listens to context and answers a separate question.',
      category: ExerciseCategory.multipleChoice,
      model: CanonicalExerciseModel.select,
    ),
    ExercisePreset(
      id: 'type_translation',
      name: 'Type the translation',
      description: 'Learner types a translation in the target language.',
      category: ExerciseCategory.translation,
      model: CanonicalExerciseModel.input,
    ),
    ExercisePreset(
      id: 'build_translation',
      name: 'Build the translation',
      description:
          'Learner constructs a translation using provided word blocks.',
      category: ExerciseCategory.translation,
      model: CanonicalExerciseModel.arrange,
    ),
    ExercisePreset(
      id: 'fill_blank',
      name: 'Type a missing word',
      description: 'Learner types the text missing from a word or phrase.',
      category: ExerciseCategory.textInput,
      model: CanonicalExerciseModel.input,
    ),
    ExercisePreset(
      id: 'listening_spelling',
      name: 'Type what you hear',
      description: 'Learner listens and types the heard word or passage.',
      category: ExerciseCategory.textInput,
      model: CanonicalExerciseModel.input,
    ),
    ExercisePreset(
      id: 'missing_word',
      name: 'Listen for missing words',
      description:
          'Learner listens and completes one or more gaps in a transcript.',
      category: ExerciseCategory.textInput,
      model: CanonicalExerciseModel.input,
    ),
    ExercisePreset(
      id: 'matching',
      name: 'Match the pairs',
      description: 'Learner matches corresponding textual items.',
      category: ExerciseCategory.matching,
      model: CanonicalExerciseModel.match,
    ),
    ExercisePreset(
      id: 'word_match',
      name: 'Match the words',
      description: 'Learner matches words with their translations.',
      category: ExerciseCategory.matching,
      model: CanonicalExerciseModel.match,
    ),
    ExercisePreset(
      id: 'super_match',
      name: 'Match related words',
      description: 'Learner matches related target-language items.',
      category: ExerciseCategory.matching,
      model: CanonicalExerciseModel.match,
    ),
    ExercisePreset(
      id: 'audio_match',
      name: 'Listen and match',
      description: 'Learner matches audio with the corresponding item.',
      category: ExerciseCategory.matching,
      model: CanonicalExerciseModel.match,
    ),
    ExercisePreset(
      id: 'word_order',
      name: 'Word order',
      description:
          'Learner restores target-language blocks to the correct order.',
      category: ExerciseCategory.ordering,
      model: CanonicalExerciseModel.arrange,
    ),
    ExercisePreset(
      id: 'image_word',
      name: 'Image-prompt ordering',
      description: 'Learner builds the word represented by an image.',
      category: ExerciseCategory.ordering,
      model: CanonicalExerciseModel.arrange,
    ),
    ExercisePreset(
      id: 'flashcard',
      name: 'Flashcard',
      description:
          'Presents learning material without an ordinary scored answer.',
      category: ExerciseCategory.presentation,
      model: CanonicalExerciseModel.presentation,
    ),
  ];

  static ExercisePreset? byId(String id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  static List<ExercisePreset> inCategory(ExerciseCategory category) => presets
      .where((preset) => preset.category == category)
      .toList(growable: false);

  /// Practical author-facing guidance. Keeping keys beside the preset registry
  /// makes missing and stale Help entries mechanically testable.
  static const helpByPreset = <String, String>{
    'choice':
        'The learner sees a source-language prompt and text alternatives, then chooses the correct target-language translation. Provide a clear prompt, at least two text answers and one correct answer. Text is supported; optional prompt audio or an image can supplement it. Keep distractors plausible but unambiguously wrong. Example: “How do you say good morning?”',
    'gap_choice':
        'The learner sees a sentence containing ___ and chooses the missing word or expression. Provide one text gap, answer blocks and one correct answer. Text is supported. Use exactly one gap where possible and make only one option grammatically and semantically correct.',
    'icon_choice':
        'The learner sees a question and image choices, then selects the matching image. Provide one answer and image/icon entry per option plus the correct answer number. Text and images are supported. Every option needs a corresponding visual.',
    'listening_choice':
        'The learner hears audio and chooses the matching written answer. Provide audio text, written alternatives and one correct answer. Audio and text are supported. Avoid visible text that gives away the audio.',
    'listening_comprehension':
        'The learner listens to a passage and selects the correct answer to a separate question. Provide audio text, the question, alternatives and one correct answer. Audio and text are supported. The answer should require understanding the passage.',
    'reading_comprehension':
        'The learner reads a passage and selects the answer to a separate question. Provide context text, the question, alternatives and one correct answer. Text is supported, with optional exercise imagery. Keep the passage long enough to test comprehension.',
    'dialogue_response':
        'The learner reads a situation and question, then chooses the best of two responses. Provide target-language context, a question, exactly two responses and one correct answer. Text is supported. Display order is randomized.',
    'contextual_comprehension':
        'The learner reads and/or listens to context and answers a separate multiple-choice question. Provide a question, text or audio context (or both), answers and one correct answer. Dialogue is optional: enter one “Speaker: text” turn per line. Text and audio are supported, and an exercise image may supplement the context. Example: ask what a speaker means after a short exchange.',
    'type_translation':
        'The learner sees source text and freely types a target-language translation. Provide the source, one or more complete accepted translations, and an optional hint. Accepted lines may use optional {}, independent [a|b], linked [*:a|b] groups with equal counts, and valid <> reorder scopes. Correct feedback shows the nearest canonical answer and only differences actually used. One omitted or duplicated repeated letter is tolerated conservatively, but substitutions and missing or extra words are not.',
    'build_translation':
        'The learner sees source text and constructs its target-language translation from word blocks. Provide source text, available literal blocks and one or more complete literal correct translations. Answers can be added, removed and reordered; each must be constructible from distinct block occurrences. Repeated words require repeated blocks, and no more than two blocks may remain unused. Type-the-translation syntax, typo tolerance and similarity matching do not apply.',
    'fill_blank':
        'The learner sees an incomplete word or phrase and types the missing text. Provide the prompt, one or more accepted answers, an optional non-revealing hint and optional complete-phrase audio. Text and audio are supported. Accepted lines may use answer variants.',
    'listening_spelling':
        'The learner hears audio and types what was heard. Provide the audio text and accepted transcription. Audio and text are supported. Return or Enter submits the answer.',
    'missing_word':
        'The learner hears audio while reading a transcript with one or more gaps, then types each missing word. Provide the complete transcript/audio and every missing item in order. Audio and text are supported. Every missing item must occur in the transcript.',
    'matching':
        'The learner sees two shuffled columns and matches corresponding text items. Provide non-empty left = right pairs. Text is supported. Pair relationships, not display positions, define correctness.',
    'word_match':
        'The learner matches source-language words with their target-language translations. Provide exactly three text pairs. Text is supported. Each visible item must be unique after ordinary normalization.',
    'super_match':
        'The learner matches related target-language items such as synonyms or opposites. Provide exactly three text pairs and an instruction naming the relationship. Text is supported. Do not mix unrelated relationship rules.',
    'audio_match':
        'The learner plays audio items and matches each one to visible text. Provide exactly three audio-text pairs with no distractors. Audio and text are supported. Each audio and visible answer must be unique.',
    'word_order':
        'The learner rearranges target-language blocks into their correct order. Provide the available text blocks and correct order. Text is supported. Use no more than two distinct distractors; this preset tests ordering rather than translation.',
    'image_word':
        'The learner sees an image and orders letter or syllable blocks to form its word. Provide an image, instruction, blocks and correct order. Image and text are supported. Include only blocks used by the answer; distractors are not allowed.',
    'flashcard':
        'The learner sees a term, meaning, optional usage and optional pronunciation audio, then chooses Understood or Review later. Provide the learning material rather than a scored answer. Text and audio are supported, with optional imagery. Presentation content does not earn base correct-answer XP.',
  };
}
