enum ImportabilityStatus { direct, configurationMapping, lossy, unsupported }

class InteroperabilityMapping {
  const InteroperabilityMapping({
    required this.sourcePattern,
    required this.status,
    required this.canonicalModel,
    this.presetId,
    this.needsNewCanonicalModel = false,
    this.needsNewPreset = false,
  });

  final String sourcePattern;
  final ImportabilityStatus status;
  final String canonicalModel;
  final String? presetId;
  final bool needsNewCanonicalModel;
  final bool needsNewPreset;
}

/// Engineering-only interoperability catalog. These source labels are never
/// rendered by the Course Editor or learner runtime.
abstract final class ExerciseInteroperabilityCatalog {
  static const externalSetA = <String>[
    'PickOne',
    'ImagePick',
    'FlashCard',
    'PickOneAudio',
    'SpellingPick',
    'Match',
    'AudioMatch',
    'WriteWords',
    'PickWords',
    'PickOneMeaning',
    'PickMissingWord',
  ];

  static const externalSetB = <String>[
    'Rich Text',
    'Multiple Choice',
    'Fill Blank',
    'Word Order',
    'Listen & Tap',
    'Match Pairs',
    'Select Image',
  ];

  static const broaderPatterns = <String>[
    'translate/type an answer',
    'translate using word tiles',
    'tap what you hear',
    'type what you hear',
    'listen for a missing word',
    'type a missing word',
    'multiple choice',
    'choose a grammatical form',
    'select image',
    'listen and choose',
    'matching pairs',
    'audio matching',
    'comprehension checks',
    'dialogue response',
    'speaking/repeat',
    'spoken response',
    'flashcard/vocabulary presentation',
    'Story-based comprehension',
  ];

  static const mappings = <InteroperabilityMapping>[
    InteroperabilityMapping(
      sourcePattern: 'PickOne',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'ImagePick',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'icon_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'FlashCard',
      status: ImportabilityStatus.direct,
      canonicalModel: 'presentation',
      presetId: 'flashcard',
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickOneAudio',
      status: ImportabilityStatus.unsupported,
      canonicalModel: 'unknown',
    ),
    InteroperabilityMapping(
      sourcePattern: 'SpellingPick',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'listening_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Match',
      status: ImportabilityStatus.direct,
      canonicalModel: 'match',
      presetId: 'matching',
    ),
    InteroperabilityMapping(
      sourcePattern: 'AudioMatch',
      status: ImportabilityStatus.direct,
      canonicalModel: 'match',
      presetId: 'audio_match',
    ),
    InteroperabilityMapping(
      sourcePattern: 'WriteWords',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'input',
      presetId: 'type_translation',
      needsNewPreset: true,
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickWords',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'arrange',
      presetId: 'build_translation',
      needsNewPreset: true,
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickOneMeaning',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'contextual_comprehension',
      needsNewPreset: true,
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickMissingWord',
      status: ImportabilityStatus.direct,
      canonicalModel: 'select',
      presetId: 'gap_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Rich Text',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'presentation',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Multiple Choice',
      status: ImportabilityStatus.direct,
      canonicalModel: 'select',
      presetId: 'choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Fill Blank',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select/input',
      presetId: 'gap_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Word Order',
      status: ImportabilityStatus.direct,
      canonicalModel: 'arrange',
      presetId: 'word_order',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Listen & Tap',
      status: ImportabilityStatus.direct,
      canonicalModel: 'select',
      presetId: 'listening_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Match Pairs',
      status: ImportabilityStatus.direct,
      canonicalModel: 'match',
      presetId: 'matching',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Select Image',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'icon_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'translate/type an answer',
      status: ImportabilityStatus.direct,
      canonicalModel: 'input',
      presetId: 'type_translation',
    ),
    InteroperabilityMapping(
      sourcePattern: 'translate using word tiles',
      status: ImportabilityStatus.direct,
      canonicalModel: 'arrange',
      presetId: 'build_translation',
    ),
    InteroperabilityMapping(
      sourcePattern: 'tap what you hear',
      status: ImportabilityStatus.direct,
      canonicalModel: 'select',
      presetId: 'listening_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'type what you hear',
      status: ImportabilityStatus.direct,
      canonicalModel: 'input',
      presetId: 'listening_spelling',
    ),
    InteroperabilityMapping(
      sourcePattern: 'listen for a missing word',
      status: ImportabilityStatus.direct,
      canonicalModel: 'input',
      presetId: 'missing_word',
    ),
    InteroperabilityMapping(
      sourcePattern: 'type a missing word',
      status: ImportabilityStatus.direct,
      canonicalModel: 'input',
      presetId: 'fill_blank',
    ),
    InteroperabilityMapping(
      sourcePattern: 'multiple choice',
      status: ImportabilityStatus.direct,
      canonicalModel: 'select',
      presetId: 'choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'choose a grammatical form',
      status: ImportabilityStatus.direct,
      canonicalModel: 'select',
      presetId: 'gap_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'select image',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'icon_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'listen and choose',
      status: ImportabilityStatus.direct,
      canonicalModel: 'select',
      presetId: 'listening_comprehension',
    ),
    InteroperabilityMapping(
      sourcePattern: 'matching pairs',
      status: ImportabilityStatus.direct,
      canonicalModel: 'match',
      presetId: 'matching',
    ),
    InteroperabilityMapping(
      sourcePattern: 'audio matching',
      status: ImportabilityStatus.direct,
      canonicalModel: 'match',
      presetId: 'audio_match',
    ),
    InteroperabilityMapping(
      sourcePattern: 'comprehension checks',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'contextual_comprehension',
    ),
    InteroperabilityMapping(
      sourcePattern: 'dialogue response',
      status: ImportabilityStatus.configurationMapping,
      canonicalModel: 'select',
      presetId: 'contextual_comprehension',
    ),
    InteroperabilityMapping(
      sourcePattern: 'speaking/repeat',
      status: ImportabilityStatus.unsupported,
      canonicalModel: 'future speech',
    ),
    InteroperabilityMapping(
      sourcePattern: 'spoken response',
      status: ImportabilityStatus.unsupported,
      canonicalModel: 'future speech',
    ),
    InteroperabilityMapping(
      sourcePattern: 'flashcard/vocabulary presentation',
      status: ImportabilityStatus.direct,
      canonicalModel: 'presentation',
      presetId: 'flashcard',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Story-based comprehension',
      status: ImportabilityStatus.lossy,
      canonicalModel: 'ordered content sequence',
    ),
  ];
}
