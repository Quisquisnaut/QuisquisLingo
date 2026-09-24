import '../models/course_models.dart';
import 'answer_engine.dart';
import 'first_letter_answer_service.dart';
import 'translation_choice_service.dart';

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
    final result = _build(draft);
    final candidate = result.candidate;
    if (candidate == null || !draft.attachSelectedSharedSource) return result;
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

  static ExerciseDraftBuildResult _build(ExerciseDraftValues draft) {
    final original = draft.original;
    final type = draft.type;
    final publicationState = draft.publicationState;
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
        tts:
            const {
                  'flashcard',
                  'fill_blank',
                  'listening_choice',
                  'listening_comprehension',
                  'missing_word',
                  'listening_spelling',
                }.contains(type) &&
                draft.tts.trim().isNotEmpty
            ? draft.tts.trim()
            : null,
        accepted: const {'listening_spelling', 'missing_word'}.contains(type)
            ? _lines(draft.missingWords)
            : const {'fill_blank', 'type_translation'}.contains(type)
            ? _lines(draft.accepted)
            : const [],
        tokens:
            const {
              'word_order',
              'image_word',
              'build_translation',
            }.contains(type)
            ? _lines(draft.tokens)
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
    return ExerciseDraftBuildResult.success(candidate);
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

  static Exercise _withSelectedSharedSource(
    Exercise exercise,
    ExerciseDraftValues draft,
  ) => Exercise.v2(
    id: exercise.id,
    publicationState: exercise.publicationState,
    updatedAt: exercise.updatedAt,
    editorTemplate: exercise.editorTemplate,
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
          )
        else
          element,
    ],
    interaction: exercise.interaction,
    evaluation: exercise.evaluation,
    hint: exercise.hint,
    feedback: exercise.feedback,
    missingWords: exercise.missingWords,
  );
}
