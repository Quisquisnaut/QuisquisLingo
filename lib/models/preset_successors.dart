/// The successor of every exercise preset the Build 256 Revision 4 catalogue
/// retired (`docs/256_PRESET_CATALOGUE_PLAN.md`). Plain Dart, so the v11
/// converter can record the successor while the registry, the Audit, the
/// editor and Search resolve a retired ID found in a stored Course through
/// the same map. Recognition still decides by content, never by this map
/// alone.
const presetSuccessorOf = <String, String>{
  'choice': 'choice_target',
  'fill_blank': 'type_missing_word',
  'matching': 'word_match',
  'listening_choice': 'listening_answer_target',
  'listening_comprehension': 'listening_answer_target',
  'reading_comprehension': 'reading_answer_target',
  'contextual_comprehension': 'reading_answer_target',
  'dialogue_response': 'reading_answer_target',
  'type_translation': 'type_translation_to_target',
  'build_translation': 'build_translation_to_target',
};

/// The older recipe a catalogue preset is built on (`ExercisePreset.base`),
/// for the presets whose ID is not itself a v11 type: the v11 converter and
/// the v11-shaped `type` view read the recipe's type from it.
const presetRecipeBaseOf = <String, String>{
  'choice_target': 'choice',
  'choice_source': 'choice',
  'listening_answer_target': 'listening_comprehension',
  'listening_answer_source': 'listening_comprehension',
  'reading_answer_target': 'reading_comprehension',
  'reading_answer_source': 'reading_comprehension',
  'type_translation_to_target': 'type_translation',
  'type_translation_to_source': 'type_translation',
  'build_translation_to_target': 'build_translation',
  'build_translation_to_source': 'build_translation',
  'picture_flashcard': 'flashcard',
  'true_false': 'choice',
  'gap_choice_inline': 'choice',
  'complete_text': 'missing_word',
  'missing_letters': 'missing_word',
  'gap_blocks': 'word_order',
  'sentence_order': 'word_order',
  'listening_image_choice': 'icon_choice',
  'spell_heard': 'image_word',
  'picture_choice': 'choice',
  'picture_name': 'fill_blank',
  'spell_word': 'image_word',
  'picture_word_match': 'word_match',
  'note_card': 'flashcard',
};
