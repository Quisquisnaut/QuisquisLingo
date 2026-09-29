import '../models/course_models.dart';
import 'answer_engine.dart';
import 'first_letter_answer_service.dart';
import 'translation_choice_service.dart';
import 'preset_variants.dart';

/// A detached snapshot of the Exercise form. It holds no controllers or Course
/// working copy, and building it has no effect on the authoring session.
class ExerciseDraftValues {
  ExerciseDraftValues({
    required this.original,
    required this.type,
    required this.publicationState,
    this.requireValidAnswer = false,
    this.useInlineGaps = false,
    this.useMultiSelect = false,
    this.prompt = '',
    this.question = '',
    this.tts = '',
    this.hint = '',
    this.answers = '',
    this.correct = '',
    this.accepted = '',
    this.tokens = '',
    this.order = '',
    this.gapLayout = '',
    this.pairs = '',
    this.icons = '',
    this.missingWords = '',
    this.context = '',
    this.dialogue = '',
    this.requiredSelections = '',
    List<String> correctTranslations = const [],
    this.contextMode = 'text',
    this.imageAsset = '',
    this.selectedSharedSource,
    this.attachSelectedSharedSource = false,
    this.scriptCandidate,
    this.revealFirstLetter = true,
    this.textRole = '',
    this.audioRole = '',
    this.matchSides = '',
    this.speakerId = '',
    this.lineMode = 'both',
    this.lineReadAloud = 'story',
    this.lineTextReveal = 'immediate',
    this.lineLanguage = '',
    this.groups = '',
    this.leftover = '',
    this.slots = '',
    this.extraWords = '',
    this.slotReuse = false,
    this.cardReadAloud = 'manual',
  }) : correctTranslations = List.unmodifiable(correctTranslations);

  final Exercise original;
  final String type;
  final PublicationState publicationState;
  final bool requireValidAnswer;
  final bool useInlineGaps;
  final bool useMultiSelect;
  final String prompt;
  final String question;
  final String tts;
  final String hint;
  final String answers;
  final String correct;
  final String accepted;
  final String tokens;
  final String order;
  final String gapLayout;
  final String pairs;
  final String icons;
  final String missingWords;
  final String context;
  final String dialogue;
  final String requiredSelections;
  final List<String> correctTranslations;
  final String contextMode;
  final String imageAsset;
  final SharedImageSource? selectedSharedSource;
  final bool attachSelectedSharedSource;

  /// Type the missing word: whether the gap reveals its first letter.
  final bool revealFirstLetter;

  /// Read and answer: the role the exercise's text had when it was opened
  /// (`passage`, `situation` or `context`), so saving it unchanged keeps
  /// its shape; empty for a new exercise.
  final String textRole;

  /// Listen and answer: the role its automatic audio had (`primary` or
  /// `passage`); empty for a new exercise.
  final String audioRole;

  /// Match the words: the languages of the opened exercise's sides,
  /// `source_target` (Match the words) or `target_source` (the former
  /// Matching), `none` when they state none, empty for a new exercise.
  final String matchSides;

  /// Dialogue line (Build 256 Revision 5): the speaking character's id
  /// (empty for the narrator).
  final String speakerId;

  /// Dialogue line: `text`, `audio` or `both`.
  final String lineMode;

  /// Dialogue line: `story` (the Round's read-aloud option), `automatic` or
  /// `manual`.
  final String lineReadAloud;

  /// Dialogue line: `immediate` or `afterAudio`.
  final String lineTextReveal;

  /// Dialogue line: `source`, `target` or empty for the speaker's language.
  final String lineLanguage;

  /// Sort into groups (Build 256 Revision 7 follow-up): one group per line
  /// as `Name: word, word`, and the words that belong to no group.
  final String groups;

  final String leftover;

  /// Fill the slots: one slot per line as `what the learner sees = word`,
  /// the extra words that fill no slot, and whether a word may fill
  /// several slots.
  final String slots;

  final String extraWords;

  final bool slotReuse;

  /// A Flashcard's read-aloud: `none`, `manual` (on request) or
  /// `automatic`; the spoken text is the word itself.
  final String cardReadAloud;

  ExerciseDraftValues copyWith({
    String? type,
    bool? useInlineGaps,
    bool? useMultiSelect,
    String? prompt,
    String? question,
    String? tts,
    String? answers,
    String? missingWords,
    String? context,
    String? contextMode,
    String? speakerId,
    String? lineMode,
    String? lineReadAloud,
    String? lineTextReveal,
    String? lineLanguage,
  }) => ExerciseDraftValues(
    original: original,
    type: type ?? this.type,
    publicationState: publicationState,
    requireValidAnswer: requireValidAnswer,
    useInlineGaps: useInlineGaps ?? this.useInlineGaps,
    useMultiSelect: useMultiSelect ?? this.useMultiSelect,
    prompt: prompt ?? this.prompt,
    question: question ?? this.question,
    tts: tts ?? this.tts,
    hint: hint,
    answers: answers ?? this.answers,
    correct: correct,
    accepted: accepted,
    tokens: tokens,
    order: order,
    gapLayout: gapLayout,
    pairs: pairs,
    icons: icons,
    missingWords: missingWords ?? this.missingWords,
    context: context ?? this.context,
    dialogue: dialogue,
    requiredSelections: requiredSelections,
    correctTranslations: correctTranslations,
    contextMode: contextMode ?? this.contextMode,
    imageAsset: imageAsset,
    selectedSharedSource: selectedSharedSource,
    attachSelectedSharedSource: attachSelectedSharedSource,
    scriptCandidate: scriptCandidate,
    revealFirstLetter: revealFirstLetter,
    textRole: textRole,
    audioRole: audioRole,
    matchSides: matchSides,
    speakerId: speakerId ?? this.speakerId,
    lineMode: lineMode ?? this.lineMode,
    lineReadAloud: lineReadAloud ?? this.lineReadAloud,
    lineTextReveal: lineTextReveal ?? this.lineTextReveal,
    lineLanguage: lineLanguage ?? this.lineLanguage,
    groups: groups,
    leftover: leftover,
    slots: slots,
    extraWords: extraWords,
    slotReuse: slotReuse,
    cardReadAloud: cardReadAloud,
  );

  /// Script recognition already owns its canonical Select construction and
  /// stable option identities in ScriptRecognitionController. The widget
  /// supplies that candidate to the same result boundary.
  final Exercise? scriptCandidate;
}

enum ExerciseDraftField {
  answers,
  accepted,
  correctTranslations,
  pairs,
  correct,
  gapLayout,
  tokens,
  requiredSelections,
  scriptOptions,
  groups,
  slots,
}

enum ExerciseDraftErrorCode {
  translationChoiceAnswers,
  answerExpression,
  correctTranslationsRequired,
  correctTranslationsDuplicate,
  pairLine,
  correctAnswerNumber,
  arrangeGapBraces,
  arrangeGapMissing,
  arrangeGapEmpty,
  arrangeGapConflict,
  multiAnswersMissing,
  multiCorrectNumbers,
  multiCorrectRequired,
  multiRequiredSelections,
  selectGapBraces,
  selectGapMissing,
  selectGapEmpty,
  scriptCandidateMissing,
  groupLine,
  groupsRequired,
  groupWordRepeated,
  slotLine,
  slotsRequired,
  slotWordRepeated,
}

class ExerciseDraftFieldError {
  ExerciseDraftFieldError(
    this.field,
    this.code, {
    this.detail,
    this.line,
    Set<int> indexes = const {},
  }) : indexes = Set.unmodifiable(indexes);

  final ExerciseDraftField field;
  final ExerciseDraftErrorCode code;
  final String? detail;
  final int? line;
  final Set<int> indexes;
}

class ExerciseDraftBuildResult {
  const ExerciseDraftBuildResult._(this.candidate, this.error);

  final Exercise? candidate;
  final ExerciseDraftFieldError? error;

  static ExerciseDraftBuildResult success(Exercise candidate) =>
      ExerciseDraftBuildResult._(candidate, null);

  static ExerciseDraftBuildResult failure(ExerciseDraftFieldError error) =>
      ExerciseDraftBuildResult._(null, error);
}

/// The screen's former candidate construction, without UI feedback or writes.
abstract final class ExerciseDraftBuilder {
  static ExerciseDraftBuildResult build(ExerciseDraftValues draft) {
    // A catalogue preset runs its base recipe and is finished as itself
    // (Build 256 Revision 4, PresetVariants).
    final result = _build(PresetVariants.draftFor(draft.type, draft));
    var candidate = result.candidate;
    if (candidate == null) return result;
    candidate = PresetVariants.finish(draft.type, candidate, draft);
    if (!draft.attachSelectedSharedSource) {
      return ExerciseDraftBuildResult.success(candidate);
    }
    return ExerciseDraftBuildResult.success(
      _withSelectedSharedSource(candidate, draft),
    );
  }

  static ExerciseDraftBuildResult _failure(
    ExerciseDraftField field,
    ExerciseDraftErrorCode code, {
    String? detail,
    int? line,
    Set<int> indexes = const {},
  }) => ExerciseDraftBuildResult.failure(
    ExerciseDraftFieldError(
      field,
      code,
      detail: detail,
      line: line,
      indexes: indexes,
    ),
  );

  static List<String> _lines(String text) => text
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  static List<List<String>> _pairLines(String text) {
    final out = <List<String>>[];
    for (final line in _lines(text)) {
      final separator = line.indexOf('=');
      if (separator > 0 && separator < line.length - 1) {
        out.add([
          line.substring(0, separator).trim(),
          line.substring(separator + 1).trim(),
        ]);
      }
    }
    return out;
  }

  static List<PromptElement> _dialogueTurns(String text) {
    final turns = <PromptElement>[];
    for (final line in _lines(text)) {
      final separator = line.indexOf(':');
      if (separator <= 0 || separator >= line.length - 1) {
        turns.add(
          PromptElement(role: 'dialogue_turn', type: 'text', text: line),
        );
      } else {
        turns.add(
          PromptElement(
            role: 'dialogue_turn',
            type: 'text',
            speaker: line.substring(0, separator).trim(),
            text: line.substring(separator + 1).trim(),
          ),
        );
      }
    }
    return turns;
  }

  static const _choices = {
    'choice',
    'gap_choice',
    'icon_choice',
    'listening_choice',
    'listening_comprehension',
    'reading_comprehension',
    'dialogue_response',
    'contextual_comprehension',
    'translation_choice_to_target',
    'translation_choice_to_source',
  };

  static List<String> _literalCorrectTranslations(List<String> values) => values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);

  static String _normalizedLiteralTranslation(String value) => value
      .trim()
      .replaceAll(RegExp(r'[.!?…]+$'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();

  /// A Story dialogue line (Build 256 Revision 5): the line as text, audio
  /// or both, said by the narrator or a character. Built canonically: its
  /// speaker, language, playback and text reveal have no v11 shape.
  static ExerciseDraftBuildResult _buildDialogueLine(
    ExerciseDraftValues draft,
  ) {
    final original = draft.original;
    final line = draft.prompt.trim();
    final hasText = draft.lineMode != 'audio';
    final hasAudio = draft.lineMode != 'text';
    final language = TextLanguage.tryParse(draft.lineLanguage);
    final playback = switch (draft.lineReadAloud) {
      'automatic' => AudioPlayback.automatic,
      'manual' => AudioPlayback.manual,
      _ => null,
    };
    final speakerId = draft.speakerId.trim();
    return ExerciseDraftBuildResult.success(
      Exercise.canonical(
        id: original.id,
        publicationState: draft.publicationState,
        updatedAt: original.updatedAt,
        primitive: ExercisePrimitive.presentation,
        options: PrimitiveOptions({
          if (hasText && hasAudio && draft.lineTextReveal == 'afterAudio')
            OptionKey.textReveal: const EnumOptionValue(TextReveal.afterAudio),
        }),
        promptElements: [
          if (hasText)
            PromptElement(
              role: 'line',
              type: 'text',
              text: line,
              speakerId: speakerId,
              language: language,
            ),
          if (hasAudio)
            PromptElement(
              role: 'line',
              type: 'audio',
              text: line,
              speakerId: speakerId,
              language: language,
              playback: playback,
              // Optional next to the text; indispensable for an audio-only
              // line (absent means required).
              required: hasText ? false : null,
            ),
        ],
        canonicalEvaluation: CanonicalEvaluation.none,
        hint: draft.hint.trim(),
        feedback: original.feedback,
        authoringMetadata: original.authoringMetadata,
      ),
    );
  }

  /// A Story cover (Build 256 Revision 5): the cover picture and an
  /// optional title line.
  static ExerciseDraftBuildResult _buildStoryCover(ExerciseDraftValues draft) {
    final original = draft.original;
    final title = draft.prompt.trim();
    final picture = draft.imageAsset.trim();
    return ExerciseDraftBuildResult.success(
      Exercise.canonical(
        id: original.id,
        publicationState: draft.publicationState,
        updatedAt: original.updatedAt,
        primitive: ExercisePrimitive.presentation,
        promptElements: [
          if (picture.isNotEmpty)
            PromptElement(role: 'picture', type: 'image', asset: picture),
          if (title.isNotEmpty)
            PromptElement(role: 'title', type: 'text', text: title),
        ],
        canonicalEvaluation: CanonicalEvaluation.none,
        hint: draft.hint.trim(),
        feedback: original.feedback,
        authoringMetadata: original.authoringMetadata,
      ),
    );
  }

  static ExerciseDraftBuildResult _build(ExerciseDraftValues draft) {
    final original = draft.original;
    final type = draft.type;
    final publicationState = draft.publicationState;
    if (type == 'dialogue_line') return _buildDialogueLine(draft);
    if (type == 'story_cover') return _buildStoryCover(draft);
    if (type == 'sort_into_groups') return _buildSortIntoGroups(draft);
    if (type == 'fill_the_slots') return _buildFillTheSlots(draft);
    if (type == 'script_recognition') {
      final candidate = draft.scriptCandidate;
      return candidate == null
          ? _failure(
              ExerciseDraftField.scriptOptions,
              ExerciseDraftErrorCode.scriptCandidateMissing,
            )
          : ExerciseDraftBuildResult.success(candidate);
    }
    if (const {'word_order', 'build_translation'}.contains(type) &&
        draft.useInlineGaps) {
      return _buildArrangeGapCandidate(draft);
    }
    if (type == 'choice' && draft.useInlineGaps) {
      return _buildSelectGapCandidate(draft);
    }
    if (type == 'choice' && draft.useMultiSelect) {
      return _buildSelectMultiCandidate(draft);
    }
    if (TranslationChoice.isTranslationChoice(type)) {
      final problem = TranslationChoice.answersProblem(_lines(draft.answers));
      if (problem != null) {
        return _failure(
          ExerciseDraftField.answers,
          ExerciseDraftErrorCode.translationChoiceAnswers,
          detail: problem,
        );
      }
    }
    if (type == 'type_translation' || type == 'type_missing_word') {
      final accepted = _lines(draft.accepted);
      try {
        if (accepted.isNotEmpty) AnswerExpressionParser.expandAll(accepted);
        if (type == 'type_missing_word' && accepted.isNotEmpty) {
          FirstLetterAnswerService.display(draft.prompt.trim(), accepted);
        }
      } on AnswerExpressionException catch (error) {
        return _failure(
          ExerciseDraftField.accepted,
          ExerciseDraftErrorCode.answerExpression,
          detail: error.message,
        );
      }
      var replaced = false;
      var imageReplaced = false;
      final imageChanged = draft.imageAsset != original.imageAsset;
      final prompt = <PromptElement>[];
      for (final element in original.promptElements) {
        if (imageChanged && !imageReplaced && element.type == 'image') {
          imageReplaced = true;
          if (draft.imageAsset.isNotEmpty) {
            prompt.add(
              PromptElement(
                role: element.role,
                type: element.type,
                text: element.text,
                asset: draft.imageAsset,
                speaker: element.speaker,
              ),
            );
          }
        } else if (!replaced &&
            element.role == 'primary' &&
            element.type == 'text') {
          prompt.add(
            PromptElement(
              role: element.role,
              type: element.type,
              text: draft.prompt.trim(),
              asset: element.asset,
              speaker: element.speaker,
            ),
          );
          replaced = true;
        } else {
          prompt.add(element);
        }
      }
      if (!replaced) {
        prompt.add(PromptElement(type: 'text', text: draft.prompt.trim()));
      }
      if (imageChanged && !imageReplaced && draft.imageAsset.isNotEmpty) {
        prompt.add(PromptElement(type: 'image', asset: draft.imageAsset));
      }
      return ExerciseDraftBuildResult.success(
        Exercise.v2(
          id: original.id,
          publicationState: publicationState,
          updatedAt: original.updatedAt,
          editorTemplate: type,
          promptElements: prompt,
          interaction: original.type == type
              ? original.interaction
              : const ExerciseInteraction(kind: 'input'),
          evaluation: ExerciseEvaluation(
            kind: 'text_match',
            accepted: accepted,
            correctItemIds: original.type == type
                ? original.evaluation.correctItemIds
                : const [],
            correctOrders: original.type == type
                ? original.evaluation.correctOrders
                : const [],
            pairs: original.type == type ? original.evaluation.pairs : const [],
            normalization: original.evaluation.normalization,
          ),
          hint: draft.hint.trim(),
          feedback: original.feedback,
          missingWords: original.missingWords,
        ),
      );
    }
    if (type == 'build_translation') {
      final translations = _literalCorrectTranslations(
        draft.correctTranslations,
      );
      if (translations.isEmpty) {
        return _failure(
          ExerciseDraftField.correctTranslations,
          ExerciseDraftErrorCode.correctTranslationsRequired,
          indexes: const {0},
        );
      }
      final normalizedByIndex = <int, String>{
        for (var index = 0; index < draft.correctTranslations.length; index++)
          if (draft.correctTranslations[index].trim().isNotEmpty)
            index: _normalizedLiteralTranslation(
              draft.correctTranslations[index],
            ),
      };
      if (normalizedByIndex.values.toSet().length != normalizedByIndex.length) {
        final duplicateIndexes = <int>{};
        for (final entry in normalizedByIndex.entries) {
          if (normalizedByIndex.values
                  .where((value) => value == entry.value)
                  .length >
              1) {
            duplicateIndexes.add(entry.key);
          }
        }
        return _failure(
          ExerciseDraftField.correctTranslations,
          ExerciseDraftErrorCode.correctTranslationsDuplicate,
          indexes: duplicateIndexes,
        );
      }
    }
    if (const {
      'matching',
      'audio_match',
      'word_match',
      'super_match',
    }.contains(type)) {
      final invalidLine = _lines(draft.pairs).indexWhere((line) {
        final separator = line.indexOf('=');
        return separator < 0 ||
            line.substring(0, separator).trim().isEmpty ||
            line.substring(separator + 1).trim().isEmpty;
      });
      if (invalidLine >= 0) {
        return _failure(
          ExerciseDraftField.pairs,
          ExerciseDraftErrorCode.pairLine,
          line: invalidLine + 1,
        );
      }
    }
    final answers = type == 'flashcard'
        ? _lines(draft.answers)
        : type == 'audio_match'
        ? _pairLines(draft.pairs).map((pair) => pair[1]).toList()
        : _choices.contains(type)
        ? _lines(draft.answers)
        : <String>[];
    int? correct;
    if (_choices.contains(type)) {
      final parsed = int.tryParse(draft.correct.trim());
      if (parsed == null || parsed < 1 || parsed > answers.length) {
        if (!publicationState.isPublished && !draft.requireValidAnswer) {
          correct = null;
        } else {
          return _failure(
            ExerciseDraftField.correct,
            ExerciseDraftErrorCode.correctAnswerNumber,
          );
        }
      } else {
        correct = parsed - 1;
      }
    }
    final Exercise candidate;
    if (type == 'contextual_comprehension') {
      final items = <ExerciseItem>[
        for (var i = 0; i < answers.length; i++)
          ExerciseItem(
            id: i < original.interaction.items.length
                ? original.interaction.items[i].id
                : 'item_$i',
            content: [PromptElement(type: 'text', text: answers[i])],
          ),
      ];
      candidate = Exercise.v2(
        id: original.id,
        publicationState: publicationState,
        updatedAt: original.updatedAt,
        editorTemplate: type,
        promptElements: [
          if (draft.contextMode != 'audio' && draft.context.trim().isNotEmpty)
            PromptElement(
              role: 'context',
              type: 'text',
              text: draft.context.trim(),
            ),
          if (draft.contextMode != 'text' && draft.tts.trim().isNotEmpty)
            PromptElement(
              role: 'context',
              type: 'audio',
              text: draft.tts.trim(),
            ),
          if (draft.imageAsset.isNotEmpty)
            PromptElement(
              role: 'context',
              type: 'image',
              asset: draft.imageAsset,
            ),
          ..._dialogueTurns(draft.dialogue),
          PromptElement(
            role: 'question',
            type: 'text',
            text: draft.question.trim(),
          ),
        ],
        interaction: ExerciseInteraction(kind: 'select', items: items),
        evaluation: ExerciseEvaluation(
          kind: 'selected_items',
          correctItemIds: correct == null ? const [] : [items[correct].id],
        ),
        hint: '',
      );
    } else {
      candidate = Exercise(
        id: original.id,
        publicationState: publicationState,
        updatedAt: original.updatedAt,
        type: type,
        prompt:
            const {
              'flashcard',
              'word_order',
              'build_translation',
              'type_translation',
              'image_word',
              'matching',
              'audio_match',
              'word_match',
              'super_match',
              'reading_comprehension',
              'choice',
              'missing_word',
              'listening_spelling',
              'dialogue_response',
            }.contains(type)
            ? draft.prompt.trim()
            : '',
        question:
            const {
              'flashcard',
              'fill_blank',
              'icon_choice',
              'listening_choice',
              'listening_comprehension',
              'reading_comprehension',
              'choice',
              'gap_choice',
              'dialogue_response',
              'translation_choice_to_target',
              'translation_choice_to_source',
            }.contains(type)
            ? draft.question.trim()
            : '',
        answers: answers,
        correct: correct,
        // A Flashcard's read-aloud speaks the word itself (Build 256
        // Revision 7 follow-up): no separate pronunciation text.
        tts: type == 'flashcard'
            ? (draft.cardReadAloud != 'none' && draft.prompt.trim().isNotEmpty
                  ? draft.prompt.trim()
                  : null)
            : const {
                    'fill_blank',
                    'listening_choice',
                    'listening_comprehension',
                    'missing_word',
                    'listening_spelling',
                    // Listen and pick the image, Spell what you hear, True
                    // or false (Build 256 Revision 4).
                    'icon_choice',
                    'image_word',
                    'choice',
                  }.contains(type) &&
                  draft.tts.trim().isNotEmpty
            ? draft.tts.trim()
            : null,
        accepted: const {'listening_spelling', 'missing_word'}.contains(type)
            ? _lines(draft.missingWords)
            : const {'fill_blank', 'type_translation'}.contains(type)
            ? _lines(draft.accepted)
            : const [],
        tokens: const {'word_order', 'build_translation'}.contains(type)
            ? _lines(draft.tokens)
            // Spell the word in the picture, Spell the word and Spell what
            // you hear offer exactly the blocks of the word (Build 256
            // Revision 7 follow-up): one field, no distractors.
            : type == 'image_word'
            ? _lines(draft.order)
            : const [],
        orderAnswer: const {'word_order', 'image_word'}.contains(type)
            ? _lines(draft.order)
            : const [],
        correctTranslations: type == 'build_translation'
            ? _literalCorrectTranslations(draft.correctTranslations)
            : const [],
        pairs:
            const {
              'matching',
              'audio_match',
              'word_match',
              'super_match',
            }.contains(type)
            ? _pairLines(draft.pairs)
            : const [],
        hint:
            const {
              'gap_choice',
              'fill_blank',
              'type_translation',
              // Missing letters (Build 256 Revision 4).
              'missing_word',
            }.contains(type)
            ? draft.hint.trim()
            : '',
        icons: type == 'icon_choice' ? _lines(draft.icons) : const [],
        imageAsset: draft.imageAsset,
        missingWords: type == 'missing_word'
            ? _lines(draft.missingWords)
            : const [],
      );
    }
    return ExerciseDraftBuildResult.success(
      type == 'flashcard' && draft.cardReadAloud == 'automatic'
          ? _withAutomaticCardAudio(candidate)
          : candidate,
    );
  }

  /// [candidate] with its read-aloud playing when the card appears (a
  /// Flashcard's Read aloud: Automatically).
  static Exercise _withAutomaticCardAudio(Exercise candidate) =>
      candidate.copyWith(
        promptElements: [
          for (final element in candidate.promptElements)
            if (element.isAudio)
              element.copyWith(playback: AudioPlayback.automatic)
            else
              element,
        ],
      );

  /// Sort into groups (Build 256 Revision 7 follow-up): the question, one
  /// group per line as `Name: word, word, …` (at least one) and the words
  /// that belong to no group. Canonical: an Assign with categories of unlimited capacity,
  /// each group's name before its target in the layout, exact assignments.
  static ExerciseDraftBuildResult _buildSortIntoGroups(
    ExerciseDraftValues draft,
  ) {
    final groups = <(String, List<String>)>[];
    final lines = _lines(draft.groups);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final separator = line.indexOf(':');
      final label = separator < 0 ? '' : line.substring(0, separator).trim();
      final words = separator < 0
          ? const <String>[]
          : line
                .substring(separator + 1)
                .split(',')
                .map((word) => word.trim())
                .where((word) => word.isNotEmpty)
                .toList();
      if (label.isEmpty || words.isEmpty) {
        return _failure(
          ExerciseDraftField.groups,
          ExerciseDraftErrorCode.groupLine,
          line: i + 1,
        );
      }
      groups.add((label, words));
    }
    // One group is enough when words that belong nowhere give the learner
    // something to leave out (the Laboratory's leftover example).
    if (_strict(draft) && groups.isEmpty) {
      return _failure(
        ExerciseDraftField.groups,
        ExerciseDraftErrorCode.groupsRequired,
      );
    }
    final leftover = _lines(draft.leftover);
    final seen = <String>{};
    for (var i = 0; i < groups.length; i++) {
      for (final word in groups[i].$2) {
        if (!seen.add(word)) {
          return _failure(
            ExerciseDraftField.groups,
            ExerciseDraftErrorCode.groupWordRepeated,
            line: i + 1,
            detail: word,
          );
        }
      }
    }
    for (final word in leftover) {
      if (!seen.add(word)) {
        return _failure(
          ExerciseDraftField.groups,
          ExerciseDraftErrorCode.groupWordRepeated,
          detail: word,
        );
      }
    }
    return ExerciseDraftBuildResult.success(
      _assignExercise(
        draft,
        mode: AssignTargetMode.categories,
        options: {
          OptionKey.targetCapacity: const EnumOptionValue(
            TargetCapacity.unlimited,
          ),
        },
        words: [for (final group in groups) ...group.$2, ...leftover],
        targets: groups,
      ),
    );
  }

  /// Fill the slots (Build 256 Revision 7 follow-up): the question, one
  /// slot per line as `what the learner sees = word`, the extra words that
  /// fill no slot, and whether a word may fill several slots. Canonical:
  /// an Assign with slots (one item each), each slot's text before its
  /// target in the layout, item reuse allowed when asked, exact assignments.
  static ExerciseDraftBuildResult _buildFillTheSlots(
    ExerciseDraftValues draft,
  ) {
    final slots = <(String, String)>[];
    final lines = _lines(draft.slots);
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final separator = line.indexOf('=');
      final label = separator < 0 ? '' : line.substring(0, separator).trim();
      final word = separator < 0 ? '' : line.substring(separator + 1).trim();
      if (label.isEmpty || word.isEmpty) {
        return _failure(
          ExerciseDraftField.slots,
          ExerciseDraftErrorCode.slotLine,
          line: i + 1,
        );
      }
      slots.add((label, word));
    }
    if (_strict(draft) && slots.isEmpty) {
      return _failure(
        ExerciseDraftField.slots,
        ExerciseDraftErrorCode.slotsRequired,
      );
    }
    // The words offered: each slot word once, then the extra words.
    final words = <String>[];
    for (var i = 0; i < slots.length; i++) {
      final word = slots[i].$2;
      if (!words.contains(word)) {
        words.add(word);
      } else if (!draft.slotReuse) {
        return _failure(
          ExerciseDraftField.slots,
          ExerciseDraftErrorCode.slotWordRepeated,
          line: i + 1,
          detail: word,
        );
      }
    }
    for (final word in _lines(draft.extraWords)) {
      if (words.contains(word)) {
        return _failure(
          ExerciseDraftField.slots,
          ExerciseDraftErrorCode.slotWordRepeated,
          detail: word,
        );
      }
      words.add(word);
    }
    return ExerciseDraftBuildResult.success(
      _assignExercise(
        draft,
        mode: AssignTargetMode.slots,
        options: {
          if (draft.slotReuse)
            OptionKey.itemReuse: const EnumOptionValue(ItemReuse.allowed),
        },
        words: words,
        targets: [
          for (final slot in slots) (slot.$1, [slot.$2]),
        ],
      ),
    );
  }

  /// Whether empty answers are refused: a Published save, or a Preview
  /// that asks for a valid answer.
  static bool _strict(ExerciseDraftValues draft) =>
      draft.publicationState.isPublished || draft.requireValidAnswer;

  /// An Assign exercise of [draft]: the [words] as items, one target per
  /// destination of [targets] (its label, then the words it takes) with the
  /// label before the target in the layout, and the exact assignments. An
  /// item keeps the original's ID when the original has that word, a target
  /// keeps the ID at its position; the rest are minted, so an unchanged
  /// exercise rebuilds equal to itself.
  static Exercise _assignExercise(
    ExerciseDraftValues draft, {
    required AssignTargetMode mode,
    Map<OptionKey, OptionValue> options = const {},
    required List<String> words,
    required List<(String, List<String>)> targets,
  }) {
    final original = draft.original;
    final isAssign = original.primitive == ExercisePrimitive.assign;
    final originalItems = isAssign ? original.items : const <ExerciseItem>[];
    final originalTargets = isAssign
        ? original.targets
        : const <ExerciseTarget>[];
    final usedIds = <String>{};
    String fresh(String prefix) {
      var n = 0;
      while (!usedIds.add('${prefix}_$n')) {
        n++;
      }
      return '${prefix}_$n';
    }

    final itemIdOf = <String, String>{};
    final items = <ExerciseItem>[];
    for (final word in words) {
      final kept = originalItems
          .where((item) => !usedIds.contains(item.id) && item.value == word)
          .firstOrNull;
      final id = kept == null ? fresh('item') : kept.id;
      usedIds.add(id);
      itemIdOf[word] = id;
      items.add(
        ExerciseItem(
          id: id,
          content: [PromptElement(type: 'text', text: word)],
        ),
      );
    }
    final targetIds = <String>[];
    for (var i = 0; i < targets.length; i++) {
      final kept = i < originalTargets.length ? originalTargets[i].id : null;
      final id = kept == null || !usedIds.add(kept) ? fresh('target') : kept;
      targetIds.add(id);
    }
    return Exercise.canonical(
      id: original.id,
      publicationState: draft.publicationState,
      updatedAt: original.updatedAt,
      primitive: ExercisePrimitive.assign,
      options: PrimitiveOptions({
        OptionKey.targetMode: EnumOptionValue(mode),
        ...options,
      }),
      promptElements: [
        if (draft.question.trim().isNotEmpty)
          PromptElement(
            role: 'question',
            type: 'text',
            text: draft.question.trim(),
          ),
        if (draft.imageAsset.trim().isNotEmpty)
          PromptElement(
            role: 'picture',
            type: 'image',
            asset: draft.imageAsset.trim(),
          ),
      ],
      items: items,
      targets: [for (final id in targetIds) ExerciseTarget(id: id)],
      layout: [
        for (var i = 0; i < targets.length; i++) ...[
          LayoutElement.text(targets[i].$1),
          LayoutElement.target(targetIds[i]),
        ],
      ],
      canonicalEvaluation: CanonicalEvaluation(
        mode: EvaluationMode.exactAssignments,
        assignments: [
          for (var i = 0; i < targets.length; i++)
            TargetAssignment(
              targetId: targetIds[i],
              itemIds: [for (final word in targets[i].$2) itemIdOf[word]!],
            ),
        ],
      ),
      feedback: original.feedback,
      authoringMetadata: original.authoringMetadata,
    );
  }

  static final RegExp _gapBracePattern = RegExp(r'\{([^{}]*)\}');

  static bool _gapBraceCountsBalance(String text) =>
      !text.replaceAll(_gapBracePattern, '').contains(RegExp(r'[{}]'));

  static ExerciseDraftBuildResult _buildArrangeGapCandidate(
    ExerciseDraftValues draft,
  ) {
    final text = draft.gapLayout;
    if (text.contains('{') && !_gapBraceCountsBalance(text)) {
      return _failure(
        ExerciseDraftField.gapLayout,
        ExerciseDraftErrorCode.arrangeGapBraces,
      );
    }
    final matches = _gapBracePattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return _failure(
        ExerciseDraftField.gapLayout,
        ExerciseDraftErrorCode.arrangeGapMissing,
      );
    }
    final gapAnswers = <String>[];
    for (final match in matches) {
      final answer = (match.group(1) ?? '').trim();
      if (answer.isEmpty) {
        return _failure(
          ExerciseDraftField.gapLayout,
          ExerciseDraftErrorCode.arrangeGapEmpty,
        );
      }
      gapAnswers.add(answer);
    }
    final distractors = _lines(draft.tokens);
    final tokens = [...gapAnswers, ...distractors];
    final itemIds = Exercise.resolveOrderedItemIds(tokens, gapAnswers);
    if (itemIds.length != gapAnswers.length) {
      return _failure(
        ExerciseDraftField.tokens,
        ExerciseDraftErrorCode.arrangeGapConflict,
      );
    }
    final gapIds = [for (var i = 0; i < gapAnswers.length; i++) 'gap_${i + 1}'];
    final layout = <PromptElement>[];
    var cursor = 0;
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final fixedText = text.substring(cursor, match.start).trim();
      if (fixedText.isNotEmpty) {
        layout.add(PromptElement(type: 'text', text: fixedText));
      }
      layout.add(PromptElement(type: 'gap', text: gapIds[i]));
      cursor = match.end;
    }
    final trailingText = text.substring(cursor).trim();
    if (trailingText.isNotEmpty) {
      layout.add(PromptElement(type: 'text', text: trailingText));
    }
    final items = [
      for (var i = 0; i < tokens.length; i++)
        ExerciseItem(
          id: 'item_$i',
          content: [PromptElement(type: 'text', text: tokens[i])],
        ),
    ];
    return ExerciseDraftBuildResult.success(
      Exercise.v2(
        id: draft.original.id,
        publicationState: draft.publicationState,
        updatedAt: draft.original.updatedAt,
        editorTemplate: draft.type,
        promptElements: Exercise.legacyPromptElements(
          draft.type,
          draft.prompt.trim(),
          '',
          draft.tts.trim().isEmpty ? null : draft.tts.trim(),
          draft.imageAsset,
        ),
        interaction: ExerciseInteraction(
          kind: 'arrange',
          items: items,
          layout: layout,
        ),
        evaluation: ExerciseEvaluation(
          kind: 'ordered_items',
          gapAssignments: {
            for (var i = 0; i < gapIds.length; i++) gapIds[i]: itemIds[i],
          },
        ),
        hint: '',
        feedback: draft.original.feedback,
        missingWords: draft.original.missingWords,
      ),
    );
  }

  static ExerciseDraftBuildResult _buildSelectMultiCandidate(
    ExerciseDraftValues draft,
  ) {
    final answerLines = _lines(draft.answers);
    if (answerLines.isEmpty) {
      return _failure(
        ExerciseDraftField.answers,
        ExerciseDraftErrorCode.multiAnswersMissing,
      );
    }
    final numberTexts = draft.correct
        .split(RegExp(r'[,\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final correctIndexes = <int>{};
    for (final numberText in numberTexts) {
      final parsed = int.tryParse(numberText);
      if (parsed == null || parsed < 1 || parsed > answerLines.length) {
        return _failure(
          ExerciseDraftField.correct,
          ExerciseDraftErrorCode.multiCorrectNumbers,
        );
      }
      correctIndexes.add(parsed - 1);
    }
    if (correctIndexes.isEmpty && draft.publicationState.isPublished) {
      return _failure(
        ExerciseDraftField.correct,
        ExerciseDraftErrorCode.multiCorrectRequired,
      );
    }
    final requiredText = draft.requiredSelections.trim();
    final required = requiredText.isEmpty
        ? (correctIndexes.isEmpty ? 1 : correctIndexes.length)
        : int.tryParse(requiredText);
    if (required == null || required < 1 || required > answerLines.length) {
      return _failure(
        ExerciseDraftField.requiredSelections,
        ExerciseDraftErrorCode.multiRequiredSelections,
      );
    }
    final items = [
      for (var i = 0; i < answerLines.length; i++)
        ExerciseItem(
          id: 'item_$i',
          content: [PromptElement(type: 'text', text: answerLines[i])],
        ),
    ];
    return ExerciseDraftBuildResult.success(
      Exercise.v2(
        id: draft.original.id,
        publicationState: draft.publicationState,
        updatedAt: draft.original.updatedAt,
        editorTemplate: draft.type,
        promptElements: Exercise.legacyPromptElements(
          draft.type,
          draft.prompt.trim(),
          draft.question.trim(),
          null,
          draft.imageAsset,
        ),
        interaction: ExerciseInteraction(
          kind: 'select',
          items: items,
          minSelections: required,
          maxSelections: items.length,
        ),
        evaluation: ExerciseEvaluation(
          kind: 'selected_items',
          correctItemIds: [for (final i in correctIndexes) items[i].id],
        ),
        hint: '',
        feedback: draft.original.feedback,
        missingWords: draft.original.missingWords,
      ),
    );
  }

  static ExerciseDraftBuildResult _buildSelectGapCandidate(
    ExerciseDraftValues draft,
  ) {
    final text = draft.gapLayout;
    if (text.contains('{') && !_gapBraceCountsBalance(text)) {
      return _failure(
        ExerciseDraftField.gapLayout,
        ExerciseDraftErrorCode.selectGapBraces,
      );
    }
    final matches = _gapBracePattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return _failure(
        ExerciseDraftField.gapLayout,
        ExerciseDraftErrorCode.selectGapMissing,
      );
    }
    final gapAnswers = <String>[];
    for (final match in matches) {
      final answer = (match.group(1) ?? '').trim();
      if (answer.isEmpty) {
        return _failure(
          ExerciseDraftField.gapLayout,
          ExerciseDraftErrorCode.selectGapEmpty,
        );
      }
      gapAnswers.add(answer);
    }
    final distractors = _lines(draft.tokens);
    final optionTexts = <String>[];
    for (final answer in [...gapAnswers, ...distractors]) {
      if (!optionTexts.contains(answer)) optionTexts.add(answer);
    }
    final idByText = {
      for (var i = 0; i < optionTexts.length; i++) optionTexts[i]: 'item_$i',
    };
    final gapIds = [for (var i = 0; i < gapAnswers.length; i++) 'gap_${i + 1}'];
    final layout = <PromptElement>[];
    var cursor = 0;
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final fixedText = text.substring(cursor, match.start).trim();
      if (fixedText.isNotEmpty) {
        layout.add(PromptElement(type: 'text', text: fixedText));
      }
      layout.add(PromptElement(type: 'gap', text: gapIds[i]));
      cursor = match.end;
    }
    final trailingText = text.substring(cursor).trim();
    if (trailingText.isNotEmpty) {
      layout.add(PromptElement(type: 'text', text: trailingText));
    }
    final items = [
      for (final optionText in optionTexts)
        ExerciseItem(
          id: idByText[optionText]!,
          content: [PromptElement(type: 'text', text: optionText)],
        ),
    ];
    return ExerciseDraftBuildResult.success(
      Exercise.v2(
        id: draft.original.id,
        publicationState: draft.publicationState,
        updatedAt: draft.original.updatedAt,
        editorTemplate: draft.type,
        promptElements: Exercise.legacyPromptElements(
          draft.type,
          draft.prompt.trim(),
          '',
          draft.tts.trim().isEmpty ? null : draft.tts.trim(),
          draft.imageAsset,
        ),
        interaction: ExerciseInteraction(
          kind: 'select',
          items: items,
          layout: layout,
        ),
        evaluation: ExerciseEvaluation(
          kind: 'selected_items',
          gapAssignments: {
            for (var i = 0; i < gapIds.length; i++)
              gapIds[i]: idByText[gapAnswers[i]]!,
          },
        ),
        hint: '',
        feedback: draft.original.feedback,
        missingWords: draft.original.missingWords,
      ),
    );
  }

  /// Course Model v12: a canonical copy with the image's provenance replaced,
  /// never a rebuild through the v11 views (which would drop an inline
  /// layout). A null selection clears the provenance on purpose.
  static Exercise _withSelectedSharedSource(
    Exercise exercise,
    ExerciseDraftValues draft,
  ) => exercise.copyWith(
    promptElements: [
      for (final element in exercise.promptElements)
        if (element.type == 'image' && element.asset == draft.imageAsset)
          PromptElement(
            role: element.role,
            type: element.type,
            text: element.text,
            asset: element.asset,
            speaker: element.speaker,
            sharedImageSource: draft.selectedSharedSource,
            language: element.language,
            playback: element.playback,
            required: element.required,
          )
        else
          element,
    ],
  );
}
