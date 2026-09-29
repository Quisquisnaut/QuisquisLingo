/// Engineering-only interoperability catalog (Build 256 Revision 6, plan
/// Part B item 7): how the exercise types of external tools map to QQL's
/// canonical semantics. Each mapping names the primitive, the explicitly set
/// options, the evaluation mode and the layout shape; the preset is only a
/// hint, what QQL's editor would call the result when its recipe represents
/// it. These source labels are never rendered by the Course Editor or the
/// learner runtime, and nothing here changes how an imported exercise plays:
/// the canonical data decides.
library;

import 'canonical/canonical.dart';

enum ImportabilityStatus { direct, configurationMapping, lossy, unsupported }

/// The canonical configuration an external exercise type maps to.
final class CanonicalConfiguration {
  const CanonicalConfiguration({
    required this.primitive,
    this.options = const {},
    required this.evaluationMode,
    this.layout = 'no layout',
  });

  final ExercisePrimitive primitive;

  /// The options set explicitly; everything else is the registry default.
  final Map<OptionKey, OptionValue> options;
  final EvaluationMode evaluationMode;

  /// The layout shape in words (documentation only): the neutral layout is
  /// built from the source's content.
  final String layout;

  PrimitiveOptions get primitiveOptions => PrimitiveOptions(options);

  /// The registry's verdict on the configuration itself.
  List<CapabilityViolation> validate() => PrimitiveCapabilityRegistry.validate(
    primitive: primitive,
    options: primitiveOptions,
    evaluationMode: evaluationMode,
  );

  /// Whether this version of QQL plays the configuration.
  ExerciseRuntimeSupport get runtimeSupport =>
      PrimitiveCapabilityRegistry.runtimeSupport(
        primitive: primitive,
        options: primitiveOptions,
        evaluationMode: evaluationMode,
      );
}

class InteroperabilityMapping {
  const InteroperabilityMapping({
    required this.sourcePattern,
    required this.status,
    this.configuration,
    this.presetHint,
    this.flow = false,
    this.notes = '',
  });

  final String sourcePattern;
  final ImportabilityStatus status;

  /// The canonical target; null for an unsupported pattern and for one that
  /// maps to a content [flow] rather than to one exercise.
  final CanonicalConfiguration? configuration;

  /// The catalogue preset that could represent the result: a hint for the
  /// editor, never a requirement.
  final String? presetHint;

  /// True when the pattern maps to a Round with a content flow (a Story).
  final bool flow;
  final String notes;
}

const _select = CanonicalConfiguration(
  primitive: ExercisePrimitive.select,
  evaluationMode: EvaluationMode.exactItem,
  layout: 'a list of items',
);

const _input = CanonicalConfiguration(
  primitive: ExercisePrimitive.input,
  evaluationMode: EvaluationMode.acceptedTexts,
  layout: 'one field',
);

const _inputGaps = CanonicalConfiguration(
  primitive: ExercisePrimitive.input,
  options: {OptionKey.layout: EnumOptionValue(LayoutValue.inlineGaps)},
  evaluationMode: EvaluationMode.acceptedTexts,
  layout: 'text runs with one field gap',
);

const _arrange = CanonicalConfiguration(
  primitive: ExercisePrimitive.arrange,
  evaluationMode: EvaluationMode.acceptedOrders,
  layout: 'wrapped tiles',
);

const _match = CanonicalConfiguration(
  primitive: ExercisePrimitive.match,
  evaluationMode: EvaluationMode.exactRelations,
  layout: 'two columns',
);

const _flashcard = CanonicalConfiguration(
  primitive: ExercisePrimitive.presentation,
  options: {
    OptionKey.completionMode: EnumOptionValue(CompletionMode.understoodReview),
  },
  evaluationMode: EvaluationMode.none,
  layout: 'a card',
);

const _note = CanonicalConfiguration(
  primitive: ExercisePrimitive.presentation,
  evaluationMode: EvaluationMode.none,
  layout: 'a card',
);

const _repeat = CanonicalConfiguration(
  primitive: ExercisePrimitive.speak,
  options: {OptionKey.speechMode: EnumOptionValue(SpeechMode.repeat)},
  evaluationMode: EvaluationMode.transcriptionMatch,
  layout: 'a recording control',
);

const _spokenResponse = CanonicalConfiguration(
  primitive: ExercisePrimitive.speak,
  options: {OptionKey.speechMode: EnumOptionValue(SpeechMode.freeResponse)},
  evaluationMode: EvaluationMode.manual,
  layout: 'a recording control',
);

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
      configuration: _select,
      presetHint: 'choice_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'ImagePick',
      status: ImportabilityStatus.configurationMapping,
      configuration: _select,
      presetHint: 'icon_choice',
      notes: 'The items are image elements.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'FlashCard',
      status: ImportabilityStatus.direct,
      configuration: _flashcard,
      presetHint: 'flashcard',
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickOneAudio',
      status: ImportabilityStatus.unsupported,
      notes: 'Items that are audio clips have no Select renderer yet.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'SpellingPick',
      status: ImportabilityStatus.configurationMapping,
      configuration: _select,
      presetHint: 'listening_answer_target',
      notes: 'The prompt audio plays automatically and is required.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Match',
      status: ImportabilityStatus.direct,
      configuration: _match,
      presetHint: 'word_match',
    ),
    InteroperabilityMapping(
      sourcePattern: 'AudioMatch',
      status: ImportabilityStatus.direct,
      configuration: _match,
      presetHint: 'audio_match',
      notes: 'The left items carry audio.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'WriteWords',
      status: ImportabilityStatus.configurationMapping,
      configuration: _input,
      presetHint: 'type_translation_to_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickWords',
      status: ImportabilityStatus.configurationMapping,
      configuration: _arrange,
      presetHint: 'build_translation_to_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickOneMeaning',
      status: ImportabilityStatus.configurationMapping,
      configuration: _select,
      presetHint: 'reading_answer_target',
      notes: 'The text read is a passage element.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'PickMissingWord',
      status: ImportabilityStatus.direct,
      configuration: _select,
      presetHint: 'gap_choice',
      notes: 'The sentence with its blank is the question text.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Rich Text',
      status: ImportabilityStatus.configurationMapping,
      configuration: _note,
      presetHint: 'note_card',
      notes: 'Formatting is lost; the text is kept.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Multiple Choice',
      status: ImportabilityStatus.direct,
      configuration: _select,
      presetHint: 'choice_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Fill Blank',
      status: ImportabilityStatus.configurationMapping,
      configuration: _inputGaps,
      presetHint: 'type_missing_word',
      notes:
          'A typed blank; a blank filled from choices maps to the Select of PickMissingWord.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Word Order',
      status: ImportabilityStatus.direct,
      configuration: _arrange,
      presetHint: 'word_order',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Listen & Tap',
      status: ImportabilityStatus.direct,
      configuration: _select,
      presetHint: 'listening_answer_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Match Pairs',
      status: ImportabilityStatus.direct,
      configuration: _match,
      presetHint: 'word_match',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Select Image',
      status: ImportabilityStatus.configurationMapping,
      configuration: _select,
      presetHint: 'icon_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'translate/type an answer',
      status: ImportabilityStatus.direct,
      configuration: _input,
      presetHint: 'type_translation_to_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'translate using word tiles',
      status: ImportabilityStatus.direct,
      configuration: _arrange,
      presetHint: 'build_translation_to_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'tap what you hear',
      status: ImportabilityStatus.direct,
      configuration: _select,
      presetHint: 'listening_answer_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'type what you hear',
      status: ImportabilityStatus.direct,
      configuration: _input,
      presetHint: 'listening_spelling',
      notes: 'The prompt is an automatic, required audio element.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'listen for a missing word',
      status: ImportabilityStatus.direct,
      configuration: _inputGaps,
      presetHint: 'missing_word',
    ),
    InteroperabilityMapping(
      sourcePattern: 'type a missing word',
      status: ImportabilityStatus.direct,
      configuration: _inputGaps,
      presetHint: 'type_missing_word',
    ),
    InteroperabilityMapping(
      sourcePattern: 'multiple choice',
      status: ImportabilityStatus.direct,
      configuration: _select,
      presetHint: 'choice_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'choose a grammatical form',
      status: ImportabilityStatus.direct,
      configuration: _select,
      presetHint: 'gap_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'select image',
      status: ImportabilityStatus.configurationMapping,
      configuration: _select,
      presetHint: 'icon_choice',
    ),
    InteroperabilityMapping(
      sourcePattern: 'listen and choose',
      status: ImportabilityStatus.direct,
      configuration: _select,
      presetHint: 'listening_answer_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'matching pairs',
      status: ImportabilityStatus.direct,
      configuration: _match,
      presetHint: 'word_match',
    ),
    InteroperabilityMapping(
      sourcePattern: 'audio matching',
      status: ImportabilityStatus.direct,
      configuration: _match,
      presetHint: 'audio_match',
    ),
    InteroperabilityMapping(
      sourcePattern: 'comprehension checks',
      status: ImportabilityStatus.configurationMapping,
      configuration: _select,
      presetHint: 'reading_answer_target',
    ),
    InteroperabilityMapping(
      sourcePattern: 'dialogue response',
      status: ImportabilityStatus.configurationMapping,
      configuration: _select,
      presetHint: 'reading_answer_target',
      notes: 'The situation is a situation text element.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'speaking/repeat',
      status: ImportabilityStatus.configurationMapping,
      configuration: _repeat,
      notes:
          'Readable but not executable: kept, editable and exported unchanged until Speak plays.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'spoken response',
      status: ImportabilityStatus.configurationMapping,
      configuration: _spokenResponse,
      notes:
          'Readable but not executable: kept, editable and exported unchanged until Speak plays.',
    ),
    InteroperabilityMapping(
      sourcePattern: 'flashcard/vocabulary presentation',
      status: ImportabilityStatus.direct,
      configuration: _flashcard,
      presetHint: 'flashcard',
    ),
    InteroperabilityMapping(
      sourcePattern: 'Story-based comprehension',
      status: ImportabilityStatus.direct,
      flow: true,
      notes:
          'A Round with a linear content flow: dialogue lines and covers as presentation nodes, questions as exercise nodes.',
    ),
  ];
}
