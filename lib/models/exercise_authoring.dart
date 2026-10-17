import 'canonical/exercise_primitive.dart';
import 'preset_successors.dart';

/// The skill groups of the preset picker and Exercise Help (Build 256
/// Revision 4, `docs/256_PRESET_CATALOGUE_PLAN.md`). Course creators think
/// in skills; the action a preset asks for (Choose, Type, …) is written on
/// its tile instead. `comingLater` holds only [ExercisePresetRegistry.comingLater].
enum ExerciseCategory {
  vocabulary('Vocabulary'),
  grammarAndSentences('Grammar and sentences'),
  listening('Listening'),
  readingAndDialogue('Reading and dialogue'),
  picturesAndCharacters('Pictures and characters'),
  cardsAndNotes('Cards and notes'),
  comingLater('Coming later');

  const ExerciseCategory(this.label);
  final String label;
}

/// Which language the learner produces or recognizes in a preset. The
/// picker filters on it; some presets exist twice (to target / to source)
/// so that QQL knows which language to read aloud.
enum PresetDirection {
  toTarget('To target'),
  toSource('To source'),
  both('Both languages'),
  none('');

  const PresetDirection(this.label);
  final String label;
}

/// A preset the picker lists greyed out because this version cannot play
/// it yet. It has no recipe and is never written to a Course.
class ComingLaterPreset {
  const ComingLaterPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.reason,
    required this.action,
  });

  final String id;
  final String name;
  final String description;

  /// Why it waits, shown as "In a later version: …".
  final String reason;

  /// The action word on the tile (Speak, Write, Sort, …).
  final String action;
}

/// An authoring recipe over one canonical primitive. A preset never adds a
/// primitive or hidden runtime semantics: everything it sets up is ordinary
/// canonical exercise data (Build 256).
class ExercisePreset {
  const ExercisePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.primitive,
    this.direction = PresetDirection.toTarget,
    this.audioEssentialCandidate = false,
    this.readingEssentialCandidate = false,
    this.flashcardCandidate = false,
    String? base,
  }) : base = base ?? id;

  final String id;
  final String name;
  final String description;
  final ExerciseCategory category;

  /// The primitive this recipe configures.
  final ExercisePrimitive primitive;

  /// The language side the learner works in (picker filter).
  final PresetDirection direction;

  /// A recipe may offer this capability; the resulting canonical exercise
  /// must still pass the Round-type check after the author edits its fields.
  final bool audioEssentialCandidate;
  final bool readingEssentialCandidate;
  final bool flashcardCandidate;

  bool get evaluatableCandidate =>
      primitive != ExercisePrimitive.presentation &&
      primitive != ExercisePrimitive.speak &&
      primitive != ExercisePrimitive.ink &&
      primitive != ExercisePrimitive.submit;

  /// The recipe this preset is built on: its own ID, or the ID of the older
  /// recipe it reuses with a direction applied (`choice_source` is built on
  /// `choice` with the question and the answers in the source language).
  final String base;

  /// The twin of a paired preset (to target / to source), else null.
  String? get twin => switch (id) {
    'choice_target' => 'choice_source',
    'choice_source' => 'choice_target',
    'type_translation_to_target' => 'type_translation_to_source',
    'type_translation_to_source' => 'type_translation_to_target',
    'build_translation_to_target' => 'build_translation_to_source',
    'build_translation_to_source' => 'build_translation_to_target',
    'listening_choose_target' => 'listening_choose_source',
    'listening_choose_source' => 'listening_choose_target',
    'listening_answer_target' => 'listening_answer_source',
    'listening_answer_source' => 'listening_answer_target',
    'translation_choice_to_target' => 'translation_choice_to_source',
    'translation_choice_to_source' => 'translation_choice_to_target',
    _ => null,
  };

  /// The action word written on the picker tile, from the primitive.
  String get action => actionOf(primitive);

  static String actionOf(ExercisePrimitive primitive) => switch (primitive) {
    ExercisePrimitive.select => 'Choose',
    ExercisePrimitive.input => 'Type',
    ExercisePrimitive.arrange => 'Arrange',
    ExercisePrimitive.match => 'Match',
    ExercisePrimitive.assign => 'Sort',
    ExercisePrimitive.speak => 'Speak',
    ExercisePrimitive.ink => 'Write',
    ExercisePrimitive.submit => 'Submit',
    ExercisePrimitive.presentation => 'Card',
  };
}

/// The single authoring registry used by the picker, Help and validation.
///
/// Presets describe a useful teaching workflow. Several presets deliberately
/// share one canonical runtime model.
abstract final class ExercisePresetRegistry {
  static const presets = <ExercisePreset>[
    // ---------------------------------------------------------- Vocabulary
    ExercisePreset(
      id: 'translation_choice_to_target',
      name: 'Pick the translation (to target)',
      description:
          'Select: learner sees source-language text and picks its target-language translation.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.select,
    ),
    ExercisePreset(
      id: 'translation_choice_to_source',
      name: 'Pick the translation (to source)',
      description:
          'Select: learner sees target-language text and picks its source-language translation.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.select,
      direction: PresetDirection.toSource,
    ),
    ExercisePreset(
      id: 'type_translation_to_target',
      name: 'Type the translation (to target)',
      description:
          'Learner reads source-language text and types its translation in the target language.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.input,
      base: 'type_translation',
    ),
    ExercisePreset(
      id: 'type_translation_to_source',
      name: 'Type the translation (to source)',
      description:
          'Learner reads target-language text and types its translation in the source language.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.input,
      direction: PresetDirection.toSource,
      base: 'type_translation',
    ),
    ExercisePreset(
      id: 'build_translation_to_target',
      name: 'Build the translation (to target)',
      description:
          'Learner reads source-language text and arranges target-language blocks into its translation.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.arrange,
      base: 'build_translation',
    ),
    ExercisePreset(
      id: 'build_translation_to_source',
      name: 'Build the translation (to source)',
      description:
          'Learner reads target-language text and arranges source-language blocks into its translation.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.arrange,
      direction: PresetDirection.toSource,
      base: 'build_translation',
    ),
    ExercisePreset(
      id: 'word_match',
      name: 'Match the words',
      description:
          'Learner matches target-language words with their source-language meanings.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.match,
      direction: PresetDirection.both,
    ),
    ExercisePreset(
      id: 'super_match',
      name: 'Match by meaning',
      description:
          'Learner matches related target-language items: synonyms, opposites, word and definition.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.match,
    ),
    ExercisePreset(
      id: 'flashcard',
      name: 'Flashcard',
      description:
          'Learner reviews a term, its meaning, an optional usage example and optional audio.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.presentation,
      direction: PresetDirection.none,
      flashcardCandidate: true,
    ),
    ExercisePreset(
      id: 'picture_flashcard',
      name: 'Picture flashcard',
      description:
          'Learner reviews a picture with its word, meaning, an optional usage example and optional read-aloud; never an audio exercise.',
      category: ExerciseCategory.vocabulary,
      primitive: ExercisePrimitive.presentation,
      direction: PresetDirection.none,
      flashcardCandidate: true,
      base: 'flashcard',
    ),
    // ------------------------------------------------ Grammar and sentences
    ExercisePreset(
      id: 'choice_target',
      name: 'Choose the answer (to target)',
      description:
          'Learner answers a target-language question by choosing: grammar, culture or meaning, not only translations.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.select,
      base: 'choice',
    ),
    ExercisePreset(
      id: 'choice_source',
      name: 'Choose the answer (to source)',
      description:
          'Learner answers a source-language question by choosing: grammar, culture or meaning explained in their own language.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.select,
      direction: PresetDirection.toSource,
      base: 'choice',
    ),
    ExercisePreset(
      id: 'gap_choice',
      name: 'Pick the missing word',
      description: 'Learner selects the missing word or expression.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.select,
    ),
    ExercisePreset(
      id: 'type_missing_word',
      name: 'Type the missing word',
      description:
          'Learner types the word missing from a sentence; the first letter can be shown as a hint.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.input,
    ),
    ExercisePreset(
      id: 'word_order',
      name: 'Word order',
      description:
          'Learner arranges target-language blocks into the correct sentence.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.arrange,
    ),
    ExercisePreset(
      id: 'true_false',
      name: 'True or false',
      description:
          'Learner reads (or hears) a statement in the target language and answers true or false in the source language.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.select,
      base: 'choice',
    ),
    // Pick the words for the gaps (Build 259 Revision 4): the former Drag
    // the blocks into the gaps, each word filling one gap; the Select-based
    // gap_choice_inline is retired to it.
    ExercisePreset(
      id: 'gap_blocks',
      name: 'Pick the words for the gaps',
      description:
          'Learner fills the gaps of a fixed sentence by tapping words; each word fills one gap.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.arrange,
      base: 'word_order',
    ),
    ExercisePreset(
      id: 'one_word_fills_all',
      name: 'One word fills all',
      description:
          'Learner picks the one word that fills every gap of the sentences.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.select,
      base: 'gap_choice',
    ),
    ExercisePreset(
      id: 'complete_text',
      name: 'Complete the text',
      description:
          'Learner types the words missing from a text with several gaps marked ___; no audio, an optional instruction and hint.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.input,
      base: 'missing_word',
    ),
    ExercisePreset(
      id: 'missing_letters',
      name: 'Missing letters',
      description:
          'Learner types the letters missing inside words (dr__); optional spoken text or picture.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.input,
      base: 'missing_word',
    ),
    ExercisePreset(
      id: 'sentence_order',
      name: 'Put the sentences in order',
      description:
          'Learner puts the lines of a story or a dialogue in the right order.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.arrange,
      base: 'word_order',
    ),
    // The two Assign presets (Build 256 Revision 7 follow-up, owner request
    // of 29 September 2026): recipes over canonical data with no v11 shape.
    ExercisePreset(
      id: 'sort_into_groups',
      name: 'Sort into groups',
      description:
          'Learner sorts words into groups, such as masculine and feminine or animals and plants.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.assign,
      direction: PresetDirection.none,
    ),
    ExercisePreset(
      id: 'fill_the_slots',
      name: 'Fill the slots',
      description:
          'Learner puts the right word into each slot, such as the article before each noun.',
      category: ExerciseCategory.grammarAndSentences,
      primitive: ExercisePrimitive.assign,
      direction: PresetDirection.none,
    ),
    // ------------------------------------------------------------ Listening
    // Listen and choose has no question; Listen and answer's question is
    // required (Build 259 Revision 2, owner decisions of 29 September 2026).
    ExercisePreset(
      id: 'listening_choose_target',
      name: 'Listen and choose (to target)',
      description:
          'Learner listens to a word or a sentence and chooses what was heard among target-language answers; no question.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.select,
      audioEssentialCandidate: true,
      base: 'listening_choice',
    ),
    ExercisePreset(
      id: 'listening_choose_source',
      name: 'Listen and choose (to source)',
      description:
          'Learner listens to a word or a sentence and chooses its meaning among source-language answers; no question.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.select,
      direction: PresetDirection.toSource,
      audioEssentialCandidate: true,
      base: 'listening_choice',
    ),
    ExercisePreset(
      id: 'listening_answer_target',
      name: 'Listen and answer (to target)',
      description:
          'Learner listens to a word, a sentence or a passage and answers a question about it among target-language answers.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.select,
      audioEssentialCandidate: true,
      base: 'listening_comprehension',
    ),
    ExercisePreset(
      id: 'listening_answer_source',
      name: 'Listen and answer (to source)',
      description:
          'Learner listens to a word, a sentence or a passage and answers a source-language question about it among source-language answers.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.select,
      direction: PresetDirection.toSource,
      audioEssentialCandidate: true,
      base: 'listening_comprehension',
    ),
    ExercisePreset(
      id: 'listening_spelling',
      name: 'Type what you hear',
      description: 'Learner listens and types the heard word or passage.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.input,
      audioEssentialCandidate: true,
    ),
    ExercisePreset(
      id: 'missing_word',
      name: 'Listen and fill the gaps',
      description:
          'Learner listens and types the words missing from the transcript.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.input,
      audioEssentialCandidate: true,
    ),
    ExercisePreset(
      id: 'audio_match',
      name: 'Listen and match',
      description: 'Learner matches audio with the corresponding item.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.match,
      audioEssentialCandidate: true,
    ),
    ExercisePreset(
      id: 'listening_image_choice',
      name: 'Listen and pick the image',
      description:
          'Learner hears a word or a sentence and picks the matching picture.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.select,
      audioEssentialCandidate: true,
      base: 'icon_choice',
    ),
    // Build 274 Revision 3 (the owner's point 7 of 13 October 2026).
    ExercisePreset(
      id: 'listening_pick_missing_word',
      name: 'Listen and pick the missing word',
      description:
          'Learner hears a whole sentence, sees it with a gap and picks the sound that fills the gap; each answer shows its word once answered.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.select,
      audioEssentialCandidate: true,
    ),
    ExercisePreset(
      id: 'spell_heard',
      name: 'Spell what you hear',
      description:
          'Learner hears a word and spells it from letter or syllable tiles.',
      category: ExerciseCategory.listening,
      primitive: ExercisePrimitive.arrange,
      base: 'image_word',
    ),
    // ------------------------------------------------- Reading and dialogue
    // Read and answer keeps only its "to target" preset (owner decisions,
    // 29 September 2026): the text to read explains the situation in the
    // source language; the dialogue lines, the question and the answers are
    // in the target language, and the dialogue may be read aloud.
    ExercisePreset(
      id: 'reading_answer_target',
      name: 'Read and answer (to target)',
      description:
          'Learner reads a situation in the source language and dialogue lines in the target language, then answers a target-language question.',
      category: ExerciseCategory.readingAndDialogue,
      primitive: ExercisePrimitive.select,
      readingEssentialCandidate: true,
      base: 'reading_comprehension',
    ),
    // -------------------------------------------- Pictures and characters
    ExercisePreset(
      id: 'icon_choice',
      name: 'Select the image',
      description: 'Learner chooses the image corresponding to the prompt.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.select,
    ),
    ExercisePreset(
      id: 'script_recognition',
      name: 'Recognize characters',
      description:
          'Learner matches character images with their text, or text with the right character image.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.select,
    ),
    ExercisePreset(
      id: 'image_word',
      name: 'Spell the word in the picture',
      description: 'Learner builds the word represented by an image.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.arrange,
    ),
    ExercisePreset(
      id: 'picture_choice',
      name: 'What is in the picture',
      description:
          'Learner sees a picture and picks the word or sentence that names it.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.select,
      base: 'choice',
    ),
    // The typed preset keeps its ID and is called Type what you see; Name
    // what you see builds the name from word blocks (owner decisions, 29
    // September 2026, Build 256 Revision 7 fourth follow-up).
    ExercisePreset(
      id: 'picture_name',
      name: 'Type what you see',
      description:
          'Learner sees a picture and types its name; several accepted answers, the same engine as typed translations.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.input,
      base: 'fill_blank',
    ),
    ExercisePreset(
      id: 'picture_blocks',
      name: 'Name what you see',
      description:
          'Learner sees a picture and builds its name from word blocks; up to two extra blocks.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.arrange,
    ),
    ExercisePreset(
      id: 'spell_word',
      name: 'Spell the word',
      description:
          'Learner spells a word from letter or syllable tiles after a clue in the source language.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.arrange,
      base: 'image_word',
    ),
    ExercisePreset(
      id: 'picture_word_match',
      name: 'Match pictures to words',
      description: 'Learner matches pictures with their words.',
      category: ExerciseCategory.picturesAndCharacters,
      primitive: ExercisePrimitive.match,
      base: 'word_match',
    ),
    // ------------------------------------------------------ Cards and notes
    ExercisePreset(
      id: 'note_card',
      name: 'Note card',
      description:
          'A tip, a grammar or a cultural note; the learner reads it and continues.',
      category: ExerciseCategory.cardsAndNotes,
      primitive: ExercisePrimitive.presentation,
      direction: PresetDirection.none,
      base: 'flashcard',
    ),
    ExercisePreset(
      id: 'dialogue_line',
      name: 'Dialogue line',
      description:
          'One line of a Story, said by the narrator or a character as text, audio or both; the learner reads or listens and continues.',
      category: ExerciseCategory.cardsAndNotes,
      primitive: ExercisePrimitive.presentation,
      direction: PresetDirection.none,
    ),
    ExercisePreset(
      id: 'story_cover',
      name: 'Story cover',
      description:
          'The opening card of a Story: its picture and an optional title line; the learner continues.',
      category: ExerciseCategory.cardsAndNotes,
      primitive: ExercisePrimitive.presentation,
      direction: PresetDirection.none,
    ),
    // Build 257: the note shown before a Round starts, now an ordinary card
    // of the Round (owner decisions of 29 September 2026).
    ExercisePreset(
      id: 'before_you_start',
      name: 'Before you start',
      description:
          'A note shown before the Round starts, with an optional Open GuideBook button; never shown in Review.',
      category: ExerciseCategory.cardsAndNotes,
      primitive: ExercisePrimitive.presentation,
      direction: PresetDirection.none,
    ),
    // Build 258 Revision 2: a textbook-like page of formatted blocks
    // (owner decisions of 29 September 2026, docs/258_PAGE_CARD_PLAN.md).
    ExercisePreset(
      id: 'page',
      name: 'Page',
      description:
          'A textbook-like page: headings, paragraphs with bold and italic, quotes, lists, pictures, audio and video links, with alignment and colours; the learner reads it and continues.',
      category: ExerciseCategory.cardsAndNotes,
      primitive: ExercisePrimitive.presentation,
      direction: PresetDirection.none,
    ),
  ];

  /// The successor of every preset retired by the Build 256 Revision 4
  /// catalogue ([presetSuccessorOf]). The v11 converter records the
  /// successor, an exercise still carrying a retired ID opens in its
  /// successor's form (recognition decides by content, never by this map
  /// alone) and the bundled Courses were regenerated with the successors.
  static const successorOf = presetSuccessorOf;

  /// [id] itself when it is a current preset, else its successor, else
  /// null.
  static String? currentIdFor(String id) =>
      byId(id) != null ? id : successorOf[id];

  /// What the translation presets are called in a Course in the same
  /// language (Build 275, owner decisions of 16 October 2026): "word" and
  /// "meaning", never "translation". The stored preset IDs never change.
  static const sameLanguageNames = <String, String>{
    'translation_choice_to_target': 'Pick the word',
    'translation_choice_to_source': 'Pick the meaning',
    'type_translation_to_target': 'Type the word',
    'type_translation_to_source': 'Type the meaning',
    'build_translation_to_target': 'Build the sentence',
    'build_translation_to_source': 'Build the meaning',
    'word_match': 'Match words and meanings',
  };

  /// The name an author reads for a preset ID: the preset's name, else the
  /// ID with its underscores as spaces (a preset this version does not know).
  static String nameOrId(String id) =>
      byId(id)?.name ?? id.replaceAll('_', ' ');

  /// Build 275 Revision 4: in a Course in the same language, the "to target"
  /// presets whose "to source" twin is not offered keep their name without
  /// the direction.
  static const _sameLanguageWithoutDirection = <String, String>{
    'choice_target': 'Choose the answer',
    'listening_choose_target': 'Listen and choose',
    'listening_answer_target': 'Listen and answer',
    'reading_answer_target': 'Read and answer',
  };

  /// The "to source" twins a Course in the same language does not offer for
  /// new exercises: there they would do exactly what their "to target" twin
  /// does. An exercise made with one still opens and plays.
  static const notInSameLanguage = <String>{
    'choice_source',
    'listening_choose_source',
    'listening_answer_source',
  };

  /// The one owner of the name an author reads for a preset (Build 275
  /// Revision 4): in a Course in the same language ([sameLanguage], from
  /// `CourseLanguagePair.isSameLanguage`), the translation presets speak of
  /// words and meanings ([sameLanguageNames]) and the "to target" presets
  /// above lose their direction; elsewhere [nameOrId].
  static String nameIn(String id, {required bool sameLanguage}) {
    if (sameLanguage) {
      // A retired ID still stored on an exercise is named as its successor.
      final current = currentIdFor(id) ?? id;
      final name =
          sameLanguageNames[current] ?? _sameLanguageWithoutDirection[current];
      if (name != null) return name;
    }
    return nameOrId(id);
  }

  /// What the presets [nameIn] renames do in a Course in the same language
  /// (Build 275 Revision 4): words and meanings, no translation and no
  /// source or target language.
  static const _sameLanguageDescriptions = <String, String>{
    'translation_choice_to_target':
        'Select: learner reads a meaning and picks the word it describes.',
    'translation_choice_to_source':
        'Select: learner reads a word and picks its meaning.',
    'type_translation_to_target':
        'Learner reads a meaning and types the word or sentence it describes.',
    'type_translation_to_source':
        'Learner reads a word or sentence and types its meaning, such as a synonym.',
    'build_translation_to_target':
        'Learner reads a meaning and arranges blocks into the sentence it describes.',
    'build_translation_to_source':
        'Learner reads a sentence and arranges blocks into its meaning.',
    'word_match': 'Learner matches words with their meanings.',
    'choice_target':
        'Learner answers a question by choosing: grammar, culture or meaning.',
    'listening_choose_target':
        'Learner listens to a word or a sentence and chooses what was heard; no question.',
    'listening_answer_target':
        'Learner listens to a word, a sentence or a passage and answers a question about it.',
    'reading_answer_target':
        'Learner reads a situation and dialogue lines, then answers a question.',
  };

  /// The description an author reads for a preset in a Course of that kind
  /// (Build 275 Revision 4), empty for an ID this version does not know.
  static String descriptionIn(String id, {required bool sameLanguage}) {
    final current = currentIdFor(id) ?? id;
    if (sameLanguage) {
      final description = _sameLanguageDescriptions[current];
      if (description != null) return description;
    }
    return byId(current)?.description ?? '';
  }

  /// The direction of [preset] in a Course of that kind (Build 275
  /// Revision 4): in a Course in the same language the presets that lose
  /// their direction there ([nameIn]) belong to both directions, so the
  /// picker lists them under every filter and names no direction beside
  /// them.
  static PresetDirection directionOfIn(
    ExercisePreset preset, {
    required bool sameLanguage,
  }) => sameLanguage && _sameLanguageWithoutDirection.containsKey(preset.id)
      ? PresetDirection.both
      : preset.direction;

  /// Whether the preset [id] is offered for a new exercise in a Course of
  /// that kind.
  static bool offeredIn(String id, {required bool sameLanguage}) =>
      !sameLanguage || !notInSameLanguage.contains(id);

  /// The direction an author reads beside a preset: in a Course in the same
  /// language, "To the word" and "To the meaning" (Build 275 Revision 4).
  static String directionIn(
    PresetDirection direction, {
    required bool sameLanguage,
  }) => !sameLanguage
      ? direction.label
      : switch (direction) {
          PresetDirection.toTarget => 'To the word',
          PresetDirection.toSource => 'To the meaning',
          _ => direction.label,
        };

  static ExercisePreset? byId(String id) {
    for (final preset in presets) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  static List<ExercisePreset> inCategory(ExerciseCategory category) => presets
      .where((preset) => preset.category == category)
      .toList(growable: false);

  /// Presets a later version will play, listed greyed out by the picker and
  /// Exercise Help (`docs/256_PRESET_CATALOGUE_PLAN.md`). They are not in
  /// [presets]: no recipe, no Help fields, never written to a Course.
  static const comingLater = <ComingLaterPreset>[
    ComingLaterPreset(
      id: 'say_it',
      name: 'Say it / Read aloud',
      description: 'Learner repeats a sentence or reads a text aloud.',
      reason: 'needs speech recognition (Speak).',
      action: 'Speak',
    ),
    ComingLaterPreset(
      id: 'write_by_hand',
      name: 'Write the character / Write by hand',
      description: 'Learner writes a character or word with a finger or pen.',
      reason: 'needs the handwriting runtime (Ink).',
      action: 'Write',
    ),
    ComingLaterPreset(
      id: 'label_the_picture',
      name: 'Label the picture',
      description: 'Learner drags labels onto regions of a picture.',
      reason: 'needs the sorting runtime with picture regions (Assign).',
      action: 'Sort',
    ),
    ComingLaterPreset(
      id: 'free_writing',
      name: 'Answer in your own words / Describe the picture',
      description: 'Learner writes freely and checks a model answer.',
      reason: 'needs the free-answer runtime (Submit).',
      action: 'Submit',
    ),
    ComingLaterPreset(
      id: 'picture_sound_match',
      name: 'Match picture to sound',
      description: 'Learner pairs pictures with what they hear.',
      reason: 'needs a tap-to-pair Match layout that can hold audio.',
      action: 'Match',
    ),
    ComingLaterPreset(
      id: 'adventure',
      name: 'Adventure (branching story)',
      description:
          'A Round whose next step depends on the answer. New Story already builds a linear story.',
      reason: 'branching flows are stored and checked but not playable yet.',
      action: 'Story',
    ),
  ];

  /// Practical author-facing guidance. Keeping keys beside the preset registry
  /// makes missing and stale Help entries mechanically testable.
  static const helpByPreset = <String, String>{
    'translation_choice_to_target':
        'Select · single answer, checked immediately. Direction, languages and the learner instruction are set by this type.\n\nThe learner sees source-language text and picks its correct target-language translation. QQL generates the only learner instruction, “Choose the correct [Target language] translation”, from the course languages, so you never write it. Provide the text to translate, two to five different target-language answers and one correct answer. Text is supported, with an optional image. A wrong choice reveals the correct answer. After answering, the learner can play the correct answer with text-to-speech when it is available; the exercise never depends on audio. Keep distractors plausible but unambiguously wrong. Example (for an English → Italian course): “I am going to London” with Vado a Londra. / Sono andato a Londra. / Vengo da Londra.',
    'translation_choice_to_source':
        'Select · single answer, checked immediately. Direction, languages and the learner instruction are set by this type.\n\nThe learner sees target-language text and picks its correct source-language translation. QQL generates the only learner instruction, “Choose the correct [Source language] translation”, from the course languages, so you never write it. Provide the text to translate, two to five different source-language answers and one correct answer. Text is supported, with an optional image. A wrong choice reveals the correct answer. The learner can play the target-language text with text-to-speech when it is available; the exercise never depends on audio. Keep distractors plausible but unambiguously wrong. Example (for an English → Italian course): “Vado a Londra.” with I am going to London. / I went to London. / I am coming from London.',
    'type_translation_to_target':
        'The learner reads source-language text and types its target-language translation. Provide the source text, one or more correct translations (separate lines; the answer syntax expands variants) and an optional hint.',
    'type_translation_to_source':
        'The learner reads target-language text and types its source-language translation. Provide the target text, one or more correct translations in the source language and an optional hint.',
    'build_translation_to_target':
        'The learner reads source-language text and builds its target-language translation from word blocks. Provide the source text, the blocks (one per line, at most two distractors recommended) and one or more correct block orders.',
    'build_translation_to_source':
        'The learner reads target-language text and builds its source-language translation from word blocks. Provide the target text, the blocks in the source language and one or more correct block orders.',
    'word_match':
        'The learner matches target-language words (left) with their source-language meanings (right). Provide at least two text pairs, one per line as left = right, with a short instruction.',
    'super_match':
        'The learner matches related target-language items such as synonyms, opposites or a word and its definition. Provide 2 to 5 text pairs (three is usual), one per line as left = right, and an optional instruction or context naming the relationship, in the learners’ language.',
    'flashcard':
        'The learner sees a target-language word or expression, its source-language translation and an optional usage example, hears the word when read-aloud is on, then chooses Got it or Review again. Choose Automatically, On request or No read-aloud; the spoken text is the word itself unless Pronunciation TTS (if different) says otherwise. Read-aloud never makes the card an audio exercise.',
    'choice_target':
        'The learner reads a question, or a sentence to complete, and chooses the right answer among target-language text alternatives: a grammar form, a cultural fact, a meaning, a translation. Provide the question, at least two answers and the correct answer number (a new exercise starts with 1); an optional Instruction or context line, in the learners’ language, is shown instead of the standard “Find the correct answer.” line; an optional picture or spoken text may support the question.',
    'choice_source':
        'The learner reads a question, or a sentence to complete, written in the source language and chooses the right answer among source-language text alternatives: grammar, culture or meaning explained in their own language. Provide the question, at least two answers and the correct answer number (a new exercise starts with 1); an optional Instruction or context line is shown instead of the standard “Find the correct answer.” line.',
    'gap_choice':
        'The learner sees a sentence containing ___ and chooses the missing word or expression. Provide one text gap, answer blocks and one correct answer. Use exactly one gap where possible and make only one option grammatically and semantically correct.',
    'type_missing_word':
        'Enter a sentence with one ___ gap and the complete accepted words for it. Show the first letter turns the gap into a hint that reveals the first letter; off, the learner types the whole word without help.',
    'word_order':
        'The learner rearranges target-language blocks into their correct order. Provide the available text blocks and the correct order; at most two distractor blocks are recommended.',
    'listening_choose_target':
        'The learner hears a word or a sentence and chooses what was heard among target-language answers. Provide the spoken text, an optional instruction or context, at least two answers and the correct answer number.',
    'listening_choose_source':
        'The learner hears a target-language word or sentence and chooses its meaning among source-language answers. Provide the spoken text, an optional instruction or context, at least two source-language answers and the correct answer number.',
    'listening_answer_target':
        'The learner hears a word, a sentence or a passage and answers a question about it among target-language answers. Provide the spoken text, the question, at least two answers and the correct answer number.',
    'listening_answer_source':
        'The learner hears a word, a sentence or a passage and answers a question in the source language among source-language answers. Provide the spoken text, the question in the source language, at least two source-language answers and the correct answer number.',
    'listening_spelling':
        'The learner hears audio and types what was heard. Provide the audio text, which is always accepted, and optionally other accepted spellings of the same words.',
    'missing_word':
        'The learner hears audio while reading a transcript with one or more gaps, then types each missing word. Provide the transcript with ___ gaps and the missing words in order.',
    'audio_match':
        'The learner plays audio items and matches each one to visible text. Provide 2 to 5 audio-text pairs (three is usual) with distinct texts.',
    'reading_answer_target':
        'The learner reads a short text in the source language that explains the situation, and dialogue lines in the target language written as Speaker: text, then answers a target-language question by choosing. Provide the text, the dialogue or both, the dialogue\'s read-aloud (no, on request or automatic: each line is spoken in turn), the question, at least two answers and the correct answer number. The text to read is never read aloud; the read-aloud is optional, so the exercise also plays with Audio Exercises off.',
    'icon_choice':
        'The learner sees a question and image choices, then selects the matching image. Provide the question or sentence (it names what to find), the answers, the correct answer number and one icon or image key per answer in the same order.',
    'script_recognition':
        'Each item pairs a character image with its corresponding text.\n\nImage to text: learners see a character image and choose the matching text.\n\nText to image: learners see the text and choose the matching character image.\n\nThe text can be the character’s name, sound, pronunciation, transliteration or another identifying label.\n\nProvide at least two options; exactly one is correct. Multiple prompt images may show print, handwriting or different fonts. Use bundled images or portable imported images, never absolute local paths. Preview uses the normal Select learner behavior.',
    'image_word':
        'The learner sees an image and orders letter or syllable blocks to form its word. Provide an image and the blocks of the word in order, one per line; the learner gets exactly those blocks, shuffled.',
    'picture_flashcard':
        'The learner sees a picture with its target-language word and source-language translation, an optional usage example with its translation, and hears the word when read-aloud is on. The picture is required; the read-aloud (Automatically, On request or none) speaks the word itself, or Pronunciation TTS (if different), and never makes the card an audio exercise.',
    'true_false':
        'The learner reads a statement in the target language, optionally hears it, and answers true or false. Provide the statement, the two answers in the source language (prefilled True and False) and the correct one.',
    'complete_text':
        'The learner types the words missing from a text with several gaps. Write the text with ___ for each gap and give one line per gap in Missing words, in order ([il|un] gatto accepts both); an optional instruction or context and an optional hint. No audio.',
    'missing_letters':
        'The learner types the letters missing inside words. Write the complete text and put the missing letters between underscores: My cat doesn’t dr_ink_ milk. The learner sees dr___ milk. Optional spoken text, picture or hint.',
    'gap_blocks':
        'The learner fills the gaps of a fixed sentence by tapping words; each word fills one gap. Write the sentence with each answer between underscores, _answer_, add 0 to 2 distractor words and an optional spoken prompt.',
    'sentence_order':
        'The learner puts the lines of a story or a dialogue in order. Enter the lines once, in the correct order, extra lines (0, 1 or 2 recommended), an optional instruction or context and an optional hint.',
    'sort_into_groups':
        'The learner taps a word, then the group it belongs to, and checks when every word is placed. Enter an optional instruction or context and one group per line as “Group name: word, word, …” (at least two groups; every word belongs to one).',
    'fill_the_slots':
        'The learner taps a word, then the slot it fills, and checks when every slot is filled. Enter an optional instruction or context and one slot per line as “what the learner sees = the word”, for example “… gatto = il”. Extra words that fill no slot are optional; a switch lets one word fill more than one slot.',
    'listening_image_choice':
        'The learner hears a word or a sentence and picks the matching picture. Provide the spoken text, an optional instruction or context, the answer labels and one picture per answer, and the correct answer.',
    'listening_pick_missing_word':
        'The learner hears the whole sentence, sees it with one ___ gap and plays the answers, which are sounds: a tap plays one and chooses it, Check grades. Provide the spoken sentence, the sentence with the gap, an optional instruction or context, at least two answers (each a word the voice reads, or a recording of the Audio Library in a Course with recordings, with an optional text shown once answered), the correct answer number and an optional hint.',
    'spell_heard':
        'The learner hears a word and spells it from letter or syllable tiles. Provide the spoken word and its tiles in order, one per line (split the word into letters or syllables as you like). No picture is needed.',
    'one_word_fills_all':
        'The learner reads sentences with two or more ___ gaps and picks the one word that fills them all; it then appears in every gap. Write the sentences with ___ for each gap, the answer words and the correct answer number.',
    'picture_choice':
        'The learner sees a picture and picks the word or sentence that names it. Provide the picture (required), an optional instruction or context, at least two answers and the correct one.',
    'picture_blocks':
        'The learner sees a picture and builds its name by tapping word blocks in order. Provide the picture (Exercise image, required), an optional instruction or context such as What is this?, the blocks of the name in order (one word per line) and up to two extra blocks that are not part of the name, plus an optional hint.',
    'picture_name':
        'The learner sees a picture and types its name. Provide the picture (required), an optional instruction or context, one or more accepted answers (the same syntax as Type the translation) and an optional hint.',
    'spell_word':
        'The learner spells a word from letter or syllable tiles after a clue in the source language: the word itself or a definition. Provide the clue and the tiles of the word in order, one per line; a picture is optional.',
    'picture_word_match':
        'The learner matches pictures with their words. Provide one picture and one word per pair; at least two pairs.',
    'note_card':
        'A card the learner reads and continues: a tip, a grammar or a cultural note. Provide a title and the note; there is no answer and no score.',
    'dialogue_line':
        'One line of a Story. Choose who speaks (the narrator or a Story character of the Course), write the line, and choose whether the learner reads it, hears it or both; read-aloud follows the Story unless the line overrides it. A line is never skipped: without audio the learner reads it. No answer, no score; Continue moves on.',
    'story_cover':
        'The first card of a Story: the cover picture and an optional title line under the Story title. Continue moves on. Build Stories with New Story on the Rounds page.',
    'page':
        'A page the learner reads and continues, built from blocks: headings, paragraphs, quotes or examples, bulleted or numbered lists, pictures, audio and video links. Write **bold** and *italic* in body text (the toolbar wraps the selection); choose each block’s alignment (start, center, end, justify for body text) and colour from a palette that stays readable in light and dark themes; a text block may offer a read-aloud button. Pictures come small, medium, large or full width with a caption; a video link opens an https address in the browser. No answer, no score.',
    'before_you_start':
        'The note the learner reads before the Round starts, on its own page with Continue to Round. Write the note; turn on Open GuideBook button to offer the Lesson’s GuideBook from the card (the button appears only while the Course uses GuideBooks and the GuideBook is published). One card per Round, placed first; it is never shown in Review, has no answer and no score.',
  };
}
