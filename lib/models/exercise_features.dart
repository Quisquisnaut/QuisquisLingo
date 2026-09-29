import 'course_models.dart';

/// The learner-facing kind of an exercise, derived from canonical data only
/// (Build 256 Session 3, plan A.3). It keys the learner heading and
/// instruction and nothing else; grading, rendering and audio read the
/// features directly.
enum LearnerExerciseKind {
  /// Select with text items and no other distinguishing feature.
  select,

  /// Select whose question text contains a `___` blank.
  selectComplete,

  /// Select whose items are images or icons.
  selectImage,

  /// Select showing or offering character specimens (`character` images).
  selectCharacter,

  /// Select with an automatic `primary` audio prompt.
  selectListen,

  /// Select with an automatic `passage` audio prompt.
  selectListenPassage,

  /// Select with a written `passage`.
  selectRead,

  /// Select with a `situation` to respond to.
  selectDialogue,

  /// Select with `context` material (text, audio, image or dialogue turns).
  selectContext,

  /// Select whose question and items are in different languages.
  selectTranslation,

  /// One-field Input with nothing else distinguishing it.
  inputComplete,

  /// One-field Input whose prompt is in the source language.
  inputTranslation,

  /// One-field Input with an automatic audio prompt.
  inputListenWrite,

  /// Inline-gap Input with an automatic audio prompt.
  inputListenGaps,

  /// Inline-gap Input whose target reveals its first grapheme.
  inputMissingWord,

  /// One-field Input under a `picture` (Type what you see).
  inputPictureName,

  /// Arrange joining blocks with spaces.
  arrangeSentence,

  /// Arrange whose blocks are whole lines or sentences (Put the sentences in
  /// order): every block has three words or more, or ends a sentence.
  arrangeLines,

  /// Arrange whose prompt is in the source language.
  arrangeTranslation,

  /// Arrange joining blocks without spaces.
  arrangeWord,

  /// Arrange of word blocks under a `picture` (Name what you see).
  arrangePictureName,

  /// Match with text on both sides.
  match,

  /// Match whose left items carry audio.
  matchAudio,

  /// Match whose two sides are in different languages.
  matchTranslation,

  /// A presentation exercise.
  presentation,

  /// A Story dialogue line: a text and/or audio element with role `line`,
  /// said by the narrator or a character (Build 256 Revision 5).
  dialogueLine,

  /// A Story cover: a picture and an optional title line, no word and no
  /// meaning (Build 256 Revision 5).
  storyCover,

  /// Assign: items sorted into named groups (Build 256 Revision 7).
  assignGroups,

  /// Assign: one item per slot (Build 256 Revision 7).
  assignSlots,

  /// Assign: items placed into the gaps of a text (Build 256 Revision 7).
  assignGaps,

  /// A primitive today's runtime does not play.
  other,
}

/// Everything the learner runtime, the Duel and the Audit read about an
/// exercise's shape, derived from its canonical fields: primitive, effective
/// options, elements with their roles and attributes, items, targets, layout,
/// evaluation and feedback. Nothing here reads authoring metadata.
class ExerciseFeatures {
  ExerciseFeatures(this.exercise) : options = exercise.effectiveOptions;

  final Exercise exercise;

  /// The options with the registry defaults filled in.
  final PrimitiveOptions options;

  ExercisePrimitive get primitive => exercise.primitive;
  List<PromptElement> get prompt => exercise.promptElements;
  List<ExerciseItem> get items => exercise.items;
  CanonicalEvaluation get evaluation => exercise.canonicalEvaluation;

  // ---------------------------------------------------------------- elements

  Iterable<PromptElement> _texts(String role) =>
      prompt.where((e) => e.isText && e.role == role);
  Iterable<PromptElement> _audios(String role) =>
      prompt.where((e) => e.isAudio && e.role == role);

  /// The first text of [role], or an empty string.
  String textOf(String role) =>
      _texts(role).map((e) => e.text).firstOrNull ?? '';

  /// The first audio text of [role], or an empty string.
  String audioOf(String role) =>
      _audios(role).map((e) => e.text).firstOrNull ?? '';

  String get primaryText => textOf('primary');
  String get questionText => textOf('question');
  String get passageText => textOf('passage');
  String get situationText => textOf('situation');
  String get clueText => textOf('clue');
  String get contextText => textOf('context');
  String get contextAudio => audioOf('context');
  String get passageAudio => audioOf('passage');

  /// Dialogue turns (`dialogue_turn` texts with a speaker), in order.
  List<PromptElement> get dialogueTurns => prompt
      .where((e) => e.isText && e.role == 'dialogue_turn')
      .toList(growable: false);

  /// The read-aloud of the dialogue lines (Read and answer, Build 256
  /// Revision 7 fourth follow-up): one audio element per line, in order.
  List<PromptElement> get dialogueAudio => prompt
      .where((e) => e.isAudio && e.role == 'dialogue_turn')
      .toList(growable: false);

  /// Every audio element, in order.
  List<PromptElement> get audioElements =>
      prompt.where((e) => e.isAudio).toList(growable: false);

  /// The audio element that plays by itself when the exercise becomes
  /// active, or null.
  PromptElement? get automaticAudio => audioElements
      .where((e) => e.effectivePlayback == AudioPlayback.automatic)
      .firstOrNull;

  /// The audio elements the learner plays on request.
  List<PromptElement> get manualAudio => audioElements
      .where((e) => e.effectivePlayback == AudioPlayback.manual)
      .toList(growable: false);

  /// Whether the exercise cannot be solved without audio: any audio element
  /// (prompt or item content) that is required. Pick the translation's
  /// optional audio converts with `required: false`.
  bool get requiresAudio =>
      audioElements.any((e) => e.isRequired) ||
      items.any((item) => item.content.any((e) => e.isAudio && e.isRequired));

  /// Image elements shown as character specimens.
  List<PromptElement> get characterImages => prompt
      .where((e) => e.isImage && e.role == 'character')
      .toList(growable: false);

  /// Image elements that illustrate the prompt (any role but `character`
  /// and `avatar`).
  List<PromptElement> get illustrationImages => prompt
      .where((e) => e.isImage && e.role != 'character' && e.role != 'avatar')
      .toList(growable: false);

  /// Image elements that are the picture a picture preset names (role
  /// `picture`): Type what you see and Name what you see ask for its name.
  List<PromptElement> get pictureImages => prompt
      .where((e) => e.isImage && e.role == 'picture')
      .toList(growable: false);

  /// The first illustration image asset, or an empty string.
  String get illustrationAsset =>
      illustrationImages.map((e) => e.asset).firstOrNull ?? '';

  TextLanguage? _languageOf(Iterable<PromptElement> elements) =>
      elements.map((e) => e.language).whereType<TextLanguage>().firstOrNull;

  /// The language of the question text, when stated.
  TextLanguage? get questionLanguage => _languageOf(_texts('question'));

  /// The language of the primary or clue text, when stated.
  TextLanguage? get promptLanguage =>
      _languageOf(_texts('primary')) ?? _languageOf(_texts('clue'));

  /// A translation exercise: the text the learner translates has an
  /// explicit language, either way round (`clue` in the source language for
  /// "to target", in the target language for "to source"; a plain `primary`
  /// text in the source language counts too, as the v11 converter wrote).
  bool get isTranslationClue =>
      promptLanguage == TextLanguage.source ||
      ((clueText.isNotEmpty || primaryText.isNotEmpty) &&
          promptLanguage == TextLanguage.target);

  /// The language the learner answers in for a translation exercise: the
  /// other side of the clue.
  TextLanguage? get answerLanguage => !isTranslationClue
      ? null
      : promptLanguage == TextLanguage.source
      ? TextLanguage.target
      : TextLanguage.source;

  /// Whether any prompt text contains a `___` blank.
  bool get hasBlankInPrompt =>
      prompt.any((e) => e.isText && RegExp(r'_{3,}').hasMatch(e.text));

  // ------------------------------------------------------------------- items

  /// The language stated on the items' text, when all stated items agree.
  TextLanguage? get itemLanguage {
    final languages = {
      for (final item in items)
        for (final e in item.content)
          if (e.isText && e.language != null) e.language!,
    };
    return languages.length == 1 ? languages.single : null;
  }

  bool get hasImageItems =>
      items.any((item) => item.content.any((e) => e.isImage));
  bool get hasIconItems =>
      items.any((item) => item.content.any((e) => e.role == 'icon'));
  bool get hasCharacterItems => items.any(
    (item) => item.content.any((e) => e.isImage && e.role == 'character'),
  );

  /// Match items by side; an item without a side counts as left when it is
  /// the first of a relation, else right.
  List<ExerciseItem> get leftItems => _side(MatchSide.left);
  List<ExerciseItem> get rightItems => _side(MatchSide.right);
  List<ExerciseItem> _side(MatchSide side) {
    final lefts = {
      for (final r in evaluation.relations)
        if (r.isNotEmpty) r[0],
    };
    return [
      for (final item in items)
        if ((item.side ??
                (lefts.contains(item.id) ? MatchSide.left : MatchSide.right)) ==
            side)
          item,
    ];
  }

  /// Whether the left Match items carry audio (Listen and match).
  bool get leftItemsHaveAudio =>
      leftItems.isNotEmpty &&
      leftItems.every((item) => item.content.any((e) => e.isAudio));

  /// Whether the two Match sides state different languages.
  bool get sidesDifferByLanguage {
    TextLanguage? languageOfSide(List<ExerciseItem> side) {
      final languages = {
        for (final item in side)
          for (final e in item.content)
            if (e.isText && e.language != null) e.language!,
      };
      return languages.length == 1 ? languages.single : null;
    }

    final left = languageOfSide(leftItems);
    final right = languageOfSide(rightItems);
    return left != null && right != null && left != right;
  }

  // ----------------------------------------------------------------- options

  bool get multipleSelection =>
      primitive == ExercisePrimitive.select &&
      options.enumValue<SelectionMode>(OptionKey.selectionMode) ==
          SelectionMode.multiple;

  /// The fewest selections a multiple Select accepts (1 for a single one).
  int get minimumSelections {
    if (!multipleSelection) return 1;
    final minimum = options.intValue(OptionKey.minimumSelections) ?? 1;
    return minimum < 1 ? 1 : minimum;
  }

  /// The most selections a multiple Select accepts (1 for a single one;
  /// every item when the option is absent).
  int get maximumSelections {
    if (!multipleSelection) return 1;
    final maximum = options.intValue(OptionKey.maximumSelections);
    return maximum == null || maximum < 1 ? items.length : maximum;
  }

  /// Whether the exercise uses an inline layout with targets.
  bool get hasInlineTargets => exercise.layout.any((e) => e.isTarget);

  /// An Arrange whose blocks fill inline gaps.
  bool get arrangeInline =>
      primitive == ExercisePrimitive.arrange && hasInlineTargets;

  /// A Select whose options fill inline gaps.
  bool get selectInline =>
      primitive == ExercisePrimitive.select && hasInlineTargets;

  /// The inline gaps of an Input that each take a typed answer (Listen for
  /// missing words); empty for a one-field Input and for a gap that reveals
  /// its first grapheme, which the learner completes in one field.
  List<ExerciseTarget> get gapFieldTargets =>
      primitive == ExercisePrimitive.input &&
          hasInlineTargets &&
          revealTarget == null
      ? exercise.targets
      : const [];

  /// The text the exercise's audio speaks: the automatic element's, else
  /// the first audio element's; null when there is no audio or no text.
  String? get primaryAudioText {
    final element = automaticAudio ?? audioElements.firstOrNull;
    final text = element?.text.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  /// The language the element behind [primaryAudioText] states, or null:
  /// a "to source" preset's audio is in the source language and is spoken
  /// with the source voice.
  TextLanguage? get primaryAudioLanguage =>
      (automaticAudio ?? audioElements.firstOrNull)?.language;

  /// The language stated by the audio element, in the prompt or in an
  /// item, whose text is [text]; null when no element states one.
  TextLanguage? audioLanguageOf(String text) {
    final wanted = text.trim();
    for (final element in audioElements) {
      if (element.text.trim() == wanted) return element.language;
    }
    for (final item in items) {
      for (final element in item.content) {
        if (element.isAudio && element.text.trim() == wanted) {
          return element.language;
        }
      }
    }
    return null;
  }

  /// The inline layout as one sentence: a target that reveals its first
  /// grapheme reads `___`, any other target reads its first accepted answer.
  String get inlineSentence => [
    for (final element in exercise.layout)
      if (element.isText)
        element.text
      else if (exercise.targets
              .where((t) => t.id == element.targetId)
              .firstOrNull
              ?.reveal !=
          null)
        '___'
      else
        answersFor(element.targetId)?.answers.firstOrNull ?? '',
  ].join();

  /// The inline layout as one text with every gap's first accepted answer
  /// in square brackets (the Missing letters form): `dr[ink]`.
  String get bracketedSentence => [
    for (final element in exercise.layout)
      if (element.isText)
        element.text
      else
        '[${answersFor(element.targetId)?.answers.firstOrNull ?? ''}]',
  ].join();

  /// The first target that reveals its first grapheme, or null.
  ExerciseTarget? get revealTarget =>
      exercise.targets.where((t) => t.reveal != null).firstOrNull;

  /// Arrange: whether the blocks are lines or sentences rather than words:
  /// two or more, each with three words or more or ending a sentence.
  bool get isLineOrder =>
      items.length >= 2 &&
      items.every((item) {
        final text = item.text.trim();
        return text.split(RegExp(r'\s+')).length >= 3 ||
            RegExp(r'[.!?…]$').hasMatch(text);
      });

  /// Arrange: whether blocks join without a separator.
  bool get joinsWithoutSpaces =>
      options.enumValue<Joiner>(OptionKey.joiner) == Joiner.none;

  /// Input: whether small typos are tolerated.
  bool get toleratesTypos =>
      options.enumValue<TypoTolerance>(OptionKey.typoTolerance) ==
      TypoTolerance.conservative;

  /// Input: the answer engine's normalization rules from the options.
  Map<String, String> get normalization => {
    'case':
        options.enumValue<CaseHandling>(OptionKey.caseHandling) ==
            CaseHandling.exact
        ? 'preserve'
        : 'ignore',
    'punctuation':
        options.enumValue<PunctuationHandling>(OptionKey.punctuationHandling) ==
            PunctuationHandling.exact
        ? 'preserve'
        : 'ignore',
    'whitespace':
        options.enumValue<WhitespaceHandling>(OptionKey.whitespaceHandling) ==
            WhitespaceHandling.exact
        ? 'preserve'
        : 'normalize',
    'accents':
        options.enumValue<AccentHandling>(OptionKey.accentHandling) ==
            AccentHandling.ignore
        ? 'ignore'
        : 'preserve',
  };

  FeedbackAlternatives get showAlternatives =>
      exercise.feedback.showAlternatives;

  CompletionMode get completionMode =>
      options.enumValue<CompletionMode>(OptionKey.completionMode) ??
      CompletionMode.proceed;

  // ------------------------------------------------------------ Story lines

  /// The elements of a Story dialogue line (role `line`): its text and/or
  /// its audio (Build 256 Revision 5).
  List<PromptElement> get lineElements => prompt
      .where((e) => e.role == 'line' && (e.isText || e.isAudio))
      .toList(growable: false);

  /// The line's text; empty for an audio-only line.
  String get lineText =>
      lineElements.where((e) => e.isText).map((e) => e.text).firstOrNull ?? '';

  /// The line's audio element, or null for a text-only line.
  PromptElement? get lineAudio =>
      lineElements.where((e) => e.isAudio).firstOrNull;

  /// `text`, `audio` or `both`; empty when the exercise is not a line.
  String get lineMode {
    final text = lineElements.any((e) => e.isText);
    final audio = lineAudio != null;
    return text && audio
        ? 'both'
        : audio
        ? 'audio'
        : text
        ? 'text'
        : '';
  }

  /// The speaker of a line: empty for the narrator.
  String get speakerId => lineElements
      .map((e) => e.speakerId)
      .firstWhere((id) => id.isNotEmpty, orElse: () => '');

  /// `story` when the line's audio follows the Story's read-aloud default,
  /// else `automatic` or `manual`.
  String get lineReadAloud => switch (lineAudio?.playback) {
    AudioPlayback.automatic => 'automatic',
    AudioPlayback.manual => 'manual',
    null => 'story',
  };

  /// The language the line states (`source` or `target`), or empty for the
  /// speaker's language.
  String get lineLanguage =>
      lineElements
          .map((e) => e.language)
          .whereType<TextLanguage>()
          .map((language) => language.serialized)
          .firstOrNull ??
      '';

  /// When a presentation shows its text next to its audio.
  TextReveal get textReveal =>
      options.enumValue<TextReveal>(OptionKey.textReveal) ??
      TextReveal.immediate;

  /// A Story cover's title line (role `title`).
  String get coverTitle => textOf('title');

  // -------------------------------------------------------------- evaluation

  /// Target ID -> the one item it must hold (inline gap grading).
  Map<String, String> get targetAssignments => {
    for (final assignment in evaluation.assignments)
      if (assignment.itemIds.isNotEmpty)
        assignment.targetId: assignment.itemIds.first,
  };

  /// The accepted answers of a one-field Input, or of every inline gap in
  /// target order.
  List<String> get acceptedAnswers => evaluation.targetAnswers.isEmpty
      ? evaluation.answers
      : [
          for (final target in exercise.targets)
            ...evaluation.targetAnswers
                .where((a) => a.targetId == target.id)
                .expand((a) => a.answers),
        ];

  /// The verbatim answers of a one-field Input, or of every inline gap.
  List<String> get literalAnswers => evaluation.targetAnswers.isEmpty
      ? evaluation.literalAnswers
      : [
          for (final target in exercise.targets)
            ...evaluation.targetAnswers
                .where((a) => a.targetId == target.id)
                .expand((a) => a.literalAnswers),
        ];

  /// The accepted answers of one inline gap.
  TargetAnswers? answersFor(String targetId) =>
      evaluation.targetAnswers.where((a) => a.targetId == targetId).firstOrNull;

  /// Whether the answer to a single Select is one item that is a translation
  /// of the question (question and items in different stated languages).
  bool get isTranslationChoice =>
      primitive == ExercisePrimitive.select &&
      !multipleSelection &&
      !hasInlineTargets &&
      questionLanguage != null &&
      itemLanguage != null &&
      questionLanguage != itemLanguage;

  // -------------------------------------------------------------------- kind

  LearnerExerciseKind get kind {
    switch (primitive) {
      case ExercisePrimitive.select:
        if (isTranslationChoice) return LearnerExerciseKind.selectTranslation;
        if (characterImages.isNotEmpty || hasCharacterItems) {
          return LearnerExerciseKind.selectCharacter;
        }
        if (contextText.isNotEmpty ||
            contextAudio.isNotEmpty ||
            dialogueTurns.isNotEmpty) {
          return LearnerExerciseKind.selectContext;
        }
        final automatic = automaticAudio;
        if (automatic != null) {
          return automatic.role == 'passage'
              ? LearnerExerciseKind.selectListenPassage
              : LearnerExerciseKind.selectListen;
        }
        if (situationText.isNotEmpty) return LearnerExerciseKind.selectDialogue;
        if (passageText.isNotEmpty) return LearnerExerciseKind.selectRead;
        if (hasImageItems || hasIconItems) {
          return LearnerExerciseKind.selectImage;
        }
        if (!hasInlineTargets && hasBlankInPrompt) {
          return LearnerExerciseKind.selectComplete;
        }
        return LearnerExerciseKind.select;
      case ExercisePrimitive.input:
        if (hasInlineTargets) {
          // Gaps with audio are heard (Listen and fill the gaps); gaps
          // that reveal a letter are Type the missing word; other gaps are
          // completed from the text alone.
          if (automaticAudio != null) {
            return LearnerExerciseKind.inputListenGaps;
          }
          return revealTarget != null
              ? LearnerExerciseKind.inputMissingWord
              : LearnerExerciseKind.inputComplete;
        }
        if (automaticAudio != null) return LearnerExerciseKind.inputListenWrite;
        if (isTranslationClue) return LearnerExerciseKind.inputTranslation;
        if (pictureImages.isNotEmpty) {
          return LearnerExerciseKind.inputPictureName;
        }
        return LearnerExerciseKind.inputComplete;
      case ExercisePrimitive.arrange:
        if (joinsWithoutSpaces) return LearnerExerciseKind.arrangeWord;
        if (pictureImages.isNotEmpty) {
          return LearnerExerciseKind.arrangePictureName;
        }
        if (isTranslationClue) return LearnerExerciseKind.arrangeTranslation;
        if (isLineOrder) return LearnerExerciseKind.arrangeLines;
        return LearnerExerciseKind.arrangeSentence;
      case ExercisePrimitive.match:
        if (leftItemsHaveAudio) return LearnerExerciseKind.matchAudio;
        if (sidesDifferByLanguage) return LearnerExerciseKind.matchTranslation;
        return LearnerExerciseKind.match;
      case ExercisePrimitive.presentation:
        if (lineElements.isNotEmpty) return LearnerExerciseKind.dialogueLine;
        if (textOf('term').isEmpty &&
            textOf('meaning').isEmpty &&
            (coverTitle.isNotEmpty || illustrationImages.isNotEmpty)) {
          return LearnerExerciseKind.storyCover;
        }
        return LearnerExerciseKind.presentation;
      case ExercisePrimitive.assign:
        return switch (assignTargetMode) {
          AssignTargetMode.categories => LearnerExerciseKind.assignGroups,
          AssignTargetMode.slots => LearnerExerciseKind.assignSlots,
          AssignTargetMode.gaps => LearnerExerciseKind.assignGaps,
          AssignTargetMode.regions ||
          AssignTargetMode.cells => LearnerExerciseKind.other,
        };
      case ExercisePrimitive.speak:
      case ExercisePrimitive.ink:
      case ExercisePrimitive.submit:
        return LearnerExerciseKind.other;
    }
  }

  // ------------------------------------------------------------------ assign

  /// What an Assign's destinations are (Build 256 Revision 7).
  AssignTargetMode get assignTargetMode =>
      options.enumValue<AssignTargetMode>(OptionKey.targetMode) ??
      AssignTargetMode.categories;

  /// How many items one destination takes.
  TargetCapacity get targetCapacity =>
      options.enumValue<TargetCapacity>(OptionKey.targetCapacity) ??
      TargetCapacity.single;

  /// Whether an item may be placed more than once (it stays in the bank).
  bool get assignItemReuse =>
      (options.enumValue<ItemReuse>(OptionKey.itemReuse) ??
          ItemReuse.forbidden) !=
      ItemReuse.forbidden;

  /// Whether the item bank is shuffled.
  bool get shuffleItems => options.boolValue(OptionKey.shuffleItems) ?? true;

  /// The items each target must hold (exactAssignments), by target ID.
  Map<String, Set<String>> get assignmentsByTarget {
    final result = <String, Set<String>>{};
    for (final assignment in evaluation.assignments) {
      result
          .putIfAbsent(assignment.targetId, () => <String>{})
          .addAll(assignment.itemIds);
    }
    return result;
  }

  /// The label of a group or slot: the text run just before its target in
  /// the layout, without a trailing colon; empty when the layout has none.
  String targetLabel(String targetId) {
    final layout = exercise.layout;
    for (var i = 0; i < layout.length; i++) {
      if (!layout[i].isTarget || layout[i].targetId != targetId) continue;
      if (i == 0 || !layout[i - 1].isText) return '';
      return layout[i - 1].text
          .trim()
          .replaceAll(RegExp(r'[:：]\s*$'), '')
          .trim();
    }
    return '';
  }
}
