import '../models/course_models.dart';
import '../models/preset_successors.dart';
import 'answer_engine.dart';
import 'first_letter_answer_service.dart';
import 'translation_choice_service.dart';
import 'plural_pictures.dart';
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
    this.slots = '',
    this.extraWords = '',
    this.slotReuse = false,
    this.guidebookButton = false,
    this.pageBlocks = const [],
    this.cardReadAloud = 'manual',
    this.dialogueReadAloud = 'none',
    this.pictureSize = 'course',
    this.pictureShape = 'course',
    this.picturesPerRow = 'course',
    this.pictureBorder = 'course',
    Set<String> pluralPictures = const {},
  }) : correctTranslations = List.unmodifiable(correctTranslations),
       pluralPictures = Set.unmodifiable(pluralPictures);

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
  /// as `Name: word, word` (every word belongs to a group since the third
  /// follow-up of 29 September 2026).
  final String groups;

  /// Fill the slots: one slot per line as `what the learner sees = word`,
  /// the extra words that fill no slot, and whether a word may fill
  /// several slots.
  final String slots;

  final String extraWords;

  final bool slotReuse;

  /// Before you start (Build 257): whether the card offers an Open
  /// GuideBook button.
  final bool guidebookButton;

  /// Page (Build 258 Revision 2): the Page's blocks in order.
  final List<PromptElement> pageBlocks;

  /// A Flashcard's read-aloud: `none`, `manual` (on request) or
  /// `automatic`; the spoken text is the word itself.
  final String cardReadAloud;

  /// Read and answer's dialogue read-aloud (Build 256 Revision 7 fourth
  /// follow-up): `none`, `manual` (on request) or `automatic`; each line is
  /// spoken in turn.
  final String dialogueReadAloud;

  /// The look of picture answers (Build 263 Revision 2): the serialized
  /// values of the Select options `pictureSize`, `pictureShape` and
  /// `picturesPerRow`; `course` follows the Course's Lesson Options.
  final String pictureSize;
  final String pictureShape;
  final String picturesPerRow;

  /// The Select option `pictureBorder` (Build 267 Revision 7).
  final String pictureBorder;

  /// The pictures the form marks Plural (Build 265 Revision 11): the
  /// exercise picture's or an answer picture's asset, or a QQL picture's
  /// icon key.
  final Set<String> pluralPictures;

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
    slots: slots,
    extraWords: extraWords,
    slotReuse: slotReuse,
    guidebookButton: guidebookButton,
    pageBlocks: pageBlocks,
    cardReadAloud: cardReadAloud,
    dialogueReadAloud: dialogueReadAloud,
    pictureSize: pictureSize,
    pictureShape: pictureShape,
    picturesPerRow: picturesPerRow,
    pictureBorder: pictureBorder,
    pluralPictures: pluralPictures,
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
  order,
  question,
  prompt,
  missingWords,
  image,
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
  nameBlocksRequired,

  /// A required question or sentence is empty; the detail is its label.
  textRequired,

  /// Put the sentences in order needs at least two lines (Build 259
  /// Revision 1).
  linesRequired,

  /// What is in the picture needs its picture (Build 259 Revision 3).
  pictureRequired,

  /// Complete the text has no ___ gap (Build 259 Revision 3).
  gapsRequired,

  /// Complete the text's gaps and Missing words lines differ in number; the
  /// detail says both (Build 259 Revision 3).
  gapCountMismatch,

  /// One word fills all has fewer than two ___ gaps (Build 259 Revision 4).
  blanksTooFew,

  /// Match pictures to words has fewer than two words (Build 259
  /// Revision 5).
  wordsTooFew,

  /// A spelling exercise has fewer than two blocks (Build 265 Revision 11,
  /// owner report of 7 October 2026: one block is no puzzle).
  blocksTooFew,
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
  /// The question or sentence each preset's form requires, with the form
  /// field that holds it and its label (Build 259, owner decisions of
  /// 29 September 2026: a question or sentence is never optional). A
  /// Published save refuses it empty.
  static const requiredTexts = <String, (ExerciseDraftField, String)>{
    'choice_target': (ExerciseDraftField.question, 'Question or sentence'),
    'choice_source': (ExerciseDraftField.question, 'Question or sentence'),
    'icon_choice': (ExerciseDraftField.question, 'Question or sentence'),
    'gap_choice': (ExerciseDraftField.question, 'Sentence'),
    'one_word_fills_all': (ExerciseDraftField.question, 'Sentences'),
    'true_false': (ExerciseDraftField.question, 'Sentence'),
    'translation_choice_to_target': (ExerciseDraftField.question, 'Sentence'),
    'translation_choice_to_source': (ExerciseDraftField.question, 'Sentence'),
    'reading_answer_target': (ExerciseDraftField.question, 'Question'),
    // Listen and answer's question (Build 259 Revision 2).
    'listening_answer_target': (ExerciseDraftField.question, 'Question'),
    'listening_answer_source': (ExerciseDraftField.question, 'Question'),
    'type_missing_word': (ExerciseDraftField.prompt, 'Sentence'),
    'type_translation_to_target': (ExerciseDraftField.prompt, 'Sentence'),
    'type_translation_to_source': (ExerciseDraftField.prompt, 'Sentence'),
    'build_translation_to_target': (ExerciseDraftField.prompt, 'Sentence'),
    'build_translation_to_source': (ExerciseDraftField.prompt, 'Sentence'),
    'spell_word': (ExerciseDraftField.prompt, 'Clue (source language)'),
  };

  static ExerciseDraftBuildResult build(ExerciseDraftValues draft) {
    final required = requiredTexts[draft.type];
    if (required != null && _strict(draft)) {
      final (field, label) = required;
      final value = field == ExerciseDraftField.question
          ? draft.question
          : draft.prompt;
      if (value.trim().isEmpty) {
        return _failure(
          field,
          ExerciseDraftErrorCode.textRequired,
          detail: label,
        );
      }
    }
    // A catalogue preset runs its base recipe and is finished as itself
    // (Build 256 Revision 4, PresetVariants).
    // The picture presets need their picture (What is in the picture since
    // Build 259 Revision 3, Type and Name what you see since Revision 4).
    if (const {
          'picture_choice',
          'picture_name',
          'picture_blocks',
        }.contains(draft.type) &&
        _strict(draft) &&
        draft.imageAsset.trim().isEmpty) {
      return _failure(
        ExerciseDraftField.image,
        ExerciseDraftErrorCode.pictureRequired,
      );
    }
    // Match pictures to words needs two words or more (Build 259
    // Revision 5). The form sends one "picture = word" line per word.
    if (draft.type == 'picture_word_match' &&
        _strict(draft) &&
        _lines(draft.pairs)
                .where(
                  (line) =>
                      line.contains('=') &&
                      line.substring(line.indexOf('=') + 1).trim().isNotEmpty,
                )
                .length <
            2) {
      return _failure(
        ExerciseDraftField.answers,
        ExerciseDraftErrorCode.wordsTooFew,
      );
    }
    // Spell the word in the picture, Spell the word and Spell what you hear
    // need two blocks or more, as their Help says (Build 265 Revision 11).
    if ((presetRecipeBaseOf[draft.type] ?? draft.type) == 'image_word' &&
        _strict(draft) &&
        _lines(draft.order).length < 2) {
      return _failure(
        ExerciseDraftField.order,
        ExerciseDraftErrorCode.blocksTooFew,
      );
    }
    // One word fills all needs two gaps or more (Build 259 Revision 4).
    if (draft.type == 'one_word_fills_all' &&
        _strict(draft) &&
        RegExp(r'_{3,}').allMatches(draft.question).length < 2) {
      return _failure(
        ExerciseDraftField.question,
        ExerciseDraftErrorCode.blanksTooFew,
      );
    }
    final result = _build(PresetVariants.draftFor(draft.type, draft));
    var candidate = result.candidate;
    if (candidate == null) return result;
    candidate = PresetVariants.finish(draft.type, candidate, draft);
    candidate = _withPictureLook(draft.type, candidate, draft);
    // Build 265 Revision 11: the pictures the form marks Plural, and only
    // those, carry the mark.
    candidate = PluralPictures.withMarks(candidate, draft.pluralPictures);
    if (!draft.attachSelectedSharedSource) {
      return ExerciseDraftBuildResult.success(candidate);
    }
    return ExerciseDraftBuildResult.success(
      _withSelectedSharedSource(candidate, draft),
    );
  }

  /// The presets whose answers are pictures; their form chooses the look
  /// of those pictures (Build 263 Revision 2).
  static const picturePresets = {'icon_choice', 'listening_image_choice'};

  /// [candidate] with the picture look the form chose: an option for each
  /// value other than `course`, none for `course` (which follows the
  /// Course). Other presets keep the options they have.
  static Exercise _withPictureLook(
    String type,
    Exercise candidate,
    ExerciseDraftValues draft,
  ) {
    if (!picturePresets.contains(type)) return candidate;
    final options = Map<OptionKey, OptionValue>.of(candidate.options.values)
      ..remove(OptionKey.pictureSize)
      ..remove(OptionKey.pictureShape)
      ..remove(OptionKey.picturesPerRow)
      ..remove(OptionKey.pictureBorder);
    void set<T extends OptionEnumValue>(
      OptionKey key,
      List<T> values,
      String chosen,
    ) {
      for (final value in values) {
        if (value.serialized == chosen && chosen != 'course') {
          options[key] = EnumOptionValue(value);
        }
      }
    }

    set(OptionKey.pictureSize, PictureSize.values, draft.pictureSize);
    set(OptionKey.pictureShape, PictureShape.values, draft.pictureShape);
    set(OptionKey.picturesPerRow, PicturesPerRow.values, draft.picturesPerRow);
    set(OptionKey.pictureBorder, PictureBorder.values, draft.pictureBorder);
    return candidate.copyWith(options: PrimitiveOptions(options));
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

  /// A Before you start card (Build 257): the note shown before the Round
  /// starts and, when asked, an Open GuideBook button.
  static ExerciseDraftBuildResult _buildBeforeYouStart(
    ExerciseDraftValues draft,
  ) {
    final original = draft.original;
    return ExerciseDraftBuildResult.success(
      Exercise.beforeYouStart(
        id: original.id,
        publicationState: draft.publicationState,
        updatedAt: original.updatedAt,
        text: draft.prompt.trim(),
        guidebookButton: draft.guidebookButton,
        feedback: original.feedback,
        authoringMetadata: original.authoringMetadata,
      ),
    );
  }

  /// A Page (Build 258 Revision 2): its blocks in order, each with role
  /// `block`. A new Page with no blocks yet starts with an empty heading and
  /// paragraph, so it is a Page from the start.
  static ExerciseDraftBuildResult _buildPage(ExerciseDraftValues draft) {
    final original = draft.original;
    final blocks = draft.pageBlocks.isEmpty
        ? pageStarterBlocks
        : draft.pageBlocks;
    return ExerciseDraftBuildResult.success(
      Exercise.canonical(
        id: original.id,
        publicationState: draft.publicationState,
        updatedAt: original.updatedAt,
        primitive: ExercisePrimitive.presentation,
        promptElements: [
          for (final block in blocks) block.copyWith(role: 'block'),
        ],
        canonicalEvaluation: CanonicalEvaluation.none,
        feedback: original.feedback,
        authoringMetadata: original.authoringMetadata,
      ),
    );
  }

  /// The blocks a new Page starts with: an empty heading and paragraph.
  static const pageStarterBlocks = [
    PromptElement(
      role: 'block',
      type: 'text',
      textStyle: BlockTextStyle.heading1,
    ),
    PromptElement(role: 'block', type: 'text'),
  ];

  static ExerciseDraftBuildResult _build(ExerciseDraftValues draft) {
    final original = draft.original;
    final type = draft.type;
    final publicationState = draft.publicationState;
    if (type == 'dialogue_line') return _buildDialogueLine(draft);
    if (type == 'story_cover') return _buildStoryCover(draft);
    if (type == 'before_you_start') return _buildBeforeYouStart(draft);
    if (type == 'page') return _buildPage(draft);
    if (type == 'sort_into_groups') return _buildSortIntoGroups(draft);
    if (type == 'picture_blocks') return _buildPictureBlocks(draft);
    if (type == 'fill_the_slots') return _buildFillTheSlots(draft);
    if (type == 'sentence_order') return _buildSentenceOrder(draft);
    if (type == 'complete_text') return _buildCompleteText(draft);
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
              // Pick the missing word and One word fills all: an optional
              // Instruction or context (Build 260 Revision 3).
              'gap_choice',
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
            ? _cardSpokenText(draft)
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
            // you hear offer the blocks of the word and the optional Extra
            // blocks (Build 265 Revision 11, owner decision; none before).
            : type == 'image_word'
            ? [..._lines(draft.order), ..._lines(draft.extraWords)]
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

  /// What a Flashcard's read-aloud speaks: the Pronunciation TTS text when
  /// the author gave one (if different), else the word or expression
  /// itself; nothing when read-aloud is off.
  static String? _cardSpokenText(ExerciseDraftValues draft) {
    if (draft.cardReadAloud == 'none') return null;
    final own = draft.tts.trim();
    if (own.isNotEmpty) return own;
    final word = draft.prompt.trim();
    return word.isEmpty ? null : word;
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

  /// Sort into groups (Build 256 Revision 7 follow-up): an optional
  /// Instruction or context (Build 259; a question before) and one
  /// group per line as `Name: word, word, …` (at least two; the words that
  /// belong to no group were removed on 29 September 2026). Canonical: an
  /// Assign with categories of unlimited capacity, each group's name before
  /// its target in the layout, exact assignments.
  /// Name what you see (Build 256 Revision 7 fourth follow-up; owner
  /// decisions of 29 September 2026): the picture, an optional Instruction
  /// or context (Build 259; a question before), the blocks of the name in order and up to two extra blocks. Canonical: an
  /// Arrange of word blocks under a `picture` with one exact order; the extra
  /// blocks stay in the bank. Item IDs are kept by text.
  static ExerciseDraftBuildResult _buildPictureBlocks(
    ExerciseDraftValues draft,
  ) {
    final blocks = _lines(draft.order);
    final extras = _lines(draft.extraWords);
    if (_strict(draft) && blocks.isEmpty) {
      return _failure(
        ExerciseDraftField.order,
        ExerciseDraftErrorCode.nameBlocksRequired,
      );
    }
    final original = draft.original;
    final originalItems = original.primitive == ExercisePrimitive.arrange
        ? original.items
        : const <ExerciseItem>[];
    final usedIds = <String>{};
    String fresh() {
      var n = 0;
      while (!usedIds.add('item_$n')) {
        n++;
      }
      return 'item_$n';
    }

    final items = <ExerciseItem>[];
    for (final word in [...blocks, ...extras]) {
      final kept = originalItems
          .where((item) => !usedIds.contains(item.id) && item.value == word)
          .firstOrNull;
      final id = kept == null ? fresh() : kept.id;
      usedIds.add(id);
      items.add(
        ExerciseItem(
          id: id,
          content: [PromptElement(role: 'primary', type: 'text', text: word)],
        ),
      );
    }
    return ExerciseDraftBuildResult.success(
      Exercise.canonical(
        id: original.id,
        publicationState: draft.publicationState,
        updatedAt: original.updatedAt,
        primitive: ExercisePrimitive.arrange,
        promptElements: [
          // Its optional Instruction or context (Build 259): no question.
          if (draft.prompt.trim().isNotEmpty)
            PromptElement(type: 'text', text: draft.prompt.trim()),
          if (draft.imageAsset.trim().isNotEmpty)
            PromptElement(
              role: 'picture',
              type: 'image',
              asset: draft.imageAsset.trim(),
            ),
        ],
        items: items,
        canonicalEvaluation: CanonicalEvaluation(
          mode: EvaluationMode.exactOrder,
          correctOrders: [
            if (blocks.isNotEmpty)
              OrderedAnswer(
                text: blocks.join(' '),
                itemIds: [
                  for (final item in items.take(blocks.length)) item.id,
                ],
              ),
          ],
        ),
        hint: draft.hint.trim(),
        feedback: original.feedback,
        authoringMetadata: original.authoringMetadata,
      ),
    );
  }

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
    // Every word belongs to a group, so one group would ask nothing (owner,
    // 29 September 2026: no words that belong nowhere).
    if (_strict(draft) && groups.length < 2) {
      return _failure(
        ExerciseDraftField.groups,
        ExerciseDraftErrorCode.groupsRequired,
      );
    }
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
    return ExerciseDraftBuildResult.success(
      _assignExercise(
        draft,
        mode: AssignTargetMode.categories,
        options: {
          OptionKey.targetCapacity: const EnumOptionValue(
            TargetCapacity.unlimited,
          ),
        },
        words: [for (final group in groups) ...group.$2],
        targets: groups,
      ),
    );
  }

  /// Fill the slots (Build 256 Revision 7 follow-up): an optional
  /// Instruction or context (Build 259; a question before), one slot per line as `what the learner sees = word`, the extra words that
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

  /// Put the sentences in order (Build 259 Revision 1, owner decisions of
  /// 29 September 2026): the optional Instruction or context, the lines in
  /// the correct order, up to two extra lines and an optional hint.
  /// Canonical: an Arrange of line items with one exact order under the
  /// `clue` instruction. Item IDs are kept by text and the items keep their
  /// stored order (new lines go at the end), so an unchanged exercise
  /// rebuilds equal to itself; the runtime shuffles them anyway.
  static ExerciseDraftBuildResult _buildSentenceOrder(
    ExerciseDraftValues draft,
  ) {
    final lines = _lines(draft.order);
    final extras = _lines(draft.extraWords);
    if (_strict(draft) && lines.length < 2) {
      return _failure(
        ExerciseDraftField.order,
        ExerciseDraftErrorCode.linesRequired,
      );
    }
    final original = draft.original;
    final originalItems = original.primitive == ExercisePrimitive.arrange
        ? original.items
        : const <ExerciseItem>[];
    final wanted = [...lines, ...extras];
    final ids = List<String?>.filled(wanted.length, null);
    final usedIds = <String>{};
    for (var i = 0; i < wanted.length; i++) {
      final kept = originalItems
          .where(
            (item) => !usedIds.contains(item.id) && item.value == wanted[i],
          )
          .firstOrNull;
      if (kept != null) {
        ids[i] = kept.id;
        usedIds.add(kept.id);
      }
    }
    for (var i = 0; i < wanted.length; i++) {
      if (ids[i] != null) continue;
      var n = 0;
      while (!usedIds.add('item_$n')) {
        n++;
      }
      ids[i] = 'item_$n';
    }
    final position = {
      for (var i = 0; i < originalItems.length; i++) originalItems[i].id: i,
    };
    final order = List<int>.generate(wanted.length, (i) => i)
      ..sort((a, b) {
        final pa = position[ids[a]];
        final pb = position[ids[b]];
        if (pa != null && pb != null) return pa.compareTo(pb);
        if (pa != null) return -1;
        if (pb != null) return 1;
        return a.compareTo(b);
      });
    return ExerciseDraftBuildResult.success(
      Exercise.canonical(
        id: original.id,
        publicationState: draft.publicationState,
        updatedAt: original.updatedAt,
        primitive: ExercisePrimitive.arrange,
        promptElements: [
          if (draft.prompt.trim().isNotEmpty)
            PromptElement(
              role: 'clue',
              type: 'text',
              text: draft.prompt.trim(),
            ),
          if (draft.imageAsset.trim().isNotEmpty)
            PromptElement(
              role: 'clue',
              type: 'image',
              asset: draft.imageAsset.trim(),
            ),
        ],
        items: [
          for (final i in order)
            ExerciseItem(
              id: ids[i]!,
              content: [PromptElement(type: 'text', text: wanted[i])],
            ),
        ],
        canonicalEvaluation: CanonicalEvaluation(
          mode: EvaluationMode.exactOrder,
          correctOrders: [
            if (lines.isNotEmpty)
              OrderedAnswer(
                text: lines.join(' '),
                itemIds: [for (var i = 0; i < lines.length; i++) ids[i]!],
              ),
          ],
        ),
        hint: draft.hint.trim(),
        feedback: original.feedback,
        authoringMetadata: original.authoringMetadata,
      ),
    );
  }

  /// Complete the text (Build 259 Revision 3, owner decision of
  /// 30 September 2026): the text marks each gap with ___ and Missing words
  /// gives one line per gap, in order; a line may use the answer syntax,
  /// such as [il|un] gatto. Canonical: an Input with inline gap targets
  /// gap_1, gap_2, … (as the Listen-for-missing-words recipe writes them),
  /// the optional Instruction or context as a `clue` text with no language,
  /// and the optional hint. A draft keeps text without gaps as its layout.
  static ExerciseDraftBuildResult _buildCompleteText(
    ExerciseDraftValues draft,
  ) {
    final pieces = draft.prompt.trim().split(RegExp(r'_{3,}'));
    final gaps = pieces.length - 1;
    final answers = _lines(draft.missingWords);
    if (_strict(draft)) {
      if (gaps == 0) {
        return _failure(
          ExerciseDraftField.prompt,
          ExerciseDraftErrorCode.gapsRequired,
        );
      }
      if (answers.length != gaps) {
        String count(int n, String noun) => n == 1 ? '1 $noun' : '$n ${noun}s';
        return _failure(
          ExerciseDraftField.missingWords,
          ExerciseDraftErrorCode.gapCountMismatch,
          detail:
              'The text has ${count(gaps, 'gap')} and Missing words has '
              '${count(answers.length, 'line')}',
        );
      }
      for (var i = 0; i < answers.length; i++) {
        try {
          AnswerExpressionParser.expand(answers[i]);
        } on AnswerExpressionException catch (error) {
          return _failure(
            ExerciseDraftField.missingWords,
            ExerciseDraftErrorCode.answerExpression,
            detail: 'Missing words line ${i + 1}: ${error.message}',
            line: i + 1,
          );
        }
      }
    }
    final original = draft.original;
    return ExerciseDraftBuildResult.success(
      Exercise.canonical(
        id: original.id,
        publicationState: draft.publicationState,
        updatedAt: original.updatedAt,
        primitive: ExercisePrimitive.input,
        options: PrimitiveOptions({
          OptionKey.cardinality: const EnumOptionValue(Cardinality.multiple),
          OptionKey.layout: const EnumOptionValue(LayoutValue.inlineGaps),
        }),
        promptElements: [
          if (draft.question.trim().isNotEmpty)
            PromptElement(
              role: 'clue',
              type: 'text',
              text: draft.question.trim(),
            ),
          if (draft.imageAsset.trim().isNotEmpty)
            PromptElement(
              role: 'clue',
              type: 'image',
              asset: draft.imageAsset.trim(),
            ),
        ],
        targets: [
          for (var i = 0; i < gaps; i++) ExerciseTarget(id: 'gap_${i + 1}'),
        ],
        layout: [
          for (var i = 0; i < pieces.length; i++) ...[
            if (pieces[i].isNotEmpty) LayoutElement.text(pieces[i]),
            if (i < gaps) LayoutElement.target('gap_${i + 1}'),
          ],
        ],
        canonicalEvaluation: CanonicalEvaluation(
          mode: EvaluationMode.expression,
          targetAnswers: [
            for (var i = 0; i < gaps; i++)
              TargetAnswers(
                targetId: 'gap_${i + 1}',
                answers: [if (i < answers.length) answers[i]],
              ),
          ],
        ),
        hint: draft.hint.trim(),
        feedback: original.feedback,
        authoringMetadata: original.authoringMetadata,
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
        // The optional Instruction or context (Build 259): no question.
        if (draft.prompt.trim().isNotEmpty)
          PromptElement(type: 'text', text: draft.prompt.trim()),
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

  /// A gap in a sentence with gaps: `_answer_` (Build 259 Revision 4,
  /// owner decision; `{answer}` before, which the answer syntax also uses).
  static final RegExp _gapBracePattern = RegExp(r'_([^_\n]+)_');

  static bool _gapBraceCountsBalance(String text) =>
      !text.replaceAll(_gapBracePattern, '').contains('_');

  static ExerciseDraftBuildResult _buildArrangeGapCandidate(
    ExerciseDraftValues draft,
  ) {
    final text = draft.gapLayout;
    if (text.contains('_') && !_gapBraceCountsBalance(text)) {
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
    if (text.contains('_') && !_gapBraceCountsBalance(text)) {
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
