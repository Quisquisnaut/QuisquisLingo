import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';
import '../widgets/script_recognition_editor.dart';
import 'exercise_draft_builder.dart';
import 'preset_variants.dart';

/// Presets are optional authoring recipes over the canonical exercise
/// (Build 256 Session 4, plan A.13). A recipe is the preset's form: the
/// fields it shows, decomposed here from canonical data, and the exercise
/// the draft builder rebuilds from them. A preset never changes what plays;
/// nothing here writes.
abstract final class PresetRecipes {
  /// The presets whose recipe has no v11 shape (Build 256 Revision 5), or
  /// whose own recipe builds their exercise (Name what you see, which still
  /// converts from the Put the words in order shape): a blank exercise for
  /// them is what the recipe builds from empty fields.
  static const canonicalOnly = <String>{
    'dialogue_line',
    'story_cover',
    // The Assign presets (Build 256 Revision 7 follow-up).
    'sort_into_groups',
    'fill_the_slots',
    // Name what you see (Revision 7 fourth follow-up).
    'picture_blocks',
    // Before you start (Build 257).
    'before_you_start',
    // Page (Build 258 Revision 2).
    'page',
    // Put the sentences in order builds its lines and extra lines itself
    // (Build 259 Revision 1); it still converts from the Word order shape.
    'sentence_order',
    // Complete the text reads its gaps from ___ (Build 259 Revision 3); it
    // still converts from the Listen-for-missing-words shape.
    'complete_text',
  };

  /// The learner kind each preset's recipe produces; the first is the one
  /// whose standard instruction the form quotes (Build 259).
  static const kinds = <String, Set<LearnerExerciseKind>>{
    'translation_choice_to_target': {LearnerExerciseKind.selectTranslation},
    'translation_choice_to_source': {LearnerExerciseKind.selectTranslation},
    'type_translation_to_target': {LearnerExerciseKind.inputTranslation},
    'type_translation_to_source': {LearnerExerciseKind.inputTranslation},
    'build_translation_to_target': {LearnerExerciseKind.arrangeTranslation},
    'build_translation_to_source': {LearnerExerciseKind.arrangeTranslation},
    'word_match': {LearnerExerciseKind.matchTranslation},
    'super_match': {LearnerExerciseKind.match},
    'flashcard': {LearnerExerciseKind.presentation},
    'choice_target': {
      LearnerExerciseKind.select,
      LearnerExerciseKind.selectListen,
    },
    'choice_source': {
      LearnerExerciseKind.select,
      LearnerExerciseKind.selectListen,
    },
    'gap_choice': {LearnerExerciseKind.selectComplete},
    'type_missing_word': {
      LearnerExerciseKind.inputMissingWord,
      LearnerExerciseKind.inputComplete,
    },
    'word_order': {LearnerExerciseKind.arrangeSentence},
    'listening_choose_target': {LearnerExerciseKind.selectListen},
    'listening_choose_source': {LearnerExerciseKind.selectListen},
    'listening_answer_target': {
      LearnerExerciseKind.selectListen,
      LearnerExerciseKind.selectListenPassage,
    },
    'listening_answer_source': {
      LearnerExerciseKind.selectListen,
      LearnerExerciseKind.selectListenPassage,
    },
    'listening_spelling': {LearnerExerciseKind.inputListenWrite},
    'missing_word': {LearnerExerciseKind.inputListenGaps},
    'audio_match': {LearnerExerciseKind.matchAudio},
    'reading_answer_target': {LearnerExerciseKind.selectContext},
    'icon_choice': {LearnerExerciseKind.selectImage},
    'script_recognition': {LearnerExerciseKind.selectCharacter},
    'image_word': {LearnerExerciseKind.arrangeWord},
    'picture_flashcard': {LearnerExerciseKind.presentation},
    'true_false': {
      LearnerExerciseKind.select,
      LearnerExerciseKind.selectListen,
    },
    // One word fills all (Build 259 Revision 4).
    'one_word_fills_all': {LearnerExerciseKind.selectCompleteAll},
    'complete_text': {LearnerExerciseKind.inputComplete},
    'missing_letters': {
      LearnerExerciseKind.inputComplete,
      LearnerExerciseKind.inputListenGaps,
    },
    'gap_blocks': {LearnerExerciseKind.arrangeSentence},
    'sentence_order': {
      LearnerExerciseKind.arrangeLines,
      LearnerExerciseKind.arrangeSentence,
    },
    'listening_image_choice': {LearnerExerciseKind.selectListen},
    'spell_heard': {LearnerExerciseKind.arrangeWord},
    'picture_choice': {LearnerExerciseKind.selectPicture},
    'picture_name': {LearnerExerciseKind.inputPictureName},
    'picture_blocks': {LearnerExerciseKind.arrangePictureName},
    'spell_word': {LearnerExerciseKind.arrangeWord},
    'picture_word_match': {
      LearnerExerciseKind.match,
      LearnerExerciseKind.matchTranslation,
    },
    'note_card': {LearnerExerciseKind.presentation},
    'dialogue_line': {LearnerExerciseKind.dialogueLine},
    'story_cover': {LearnerExerciseKind.storyCover},
    'before_you_start': {LearnerExerciseKind.roundIntro},
    'page': {LearnerExerciseKind.page},
    'sort_into_groups': {LearnerExerciseKind.assignGroups},
    'fill_the_slots': {LearnerExerciseKind.assignSlots},
  };

  /// The plainest recipe of [primitive], for an exercise that carries no
  /// preset that fits it; null for the primitives no preset configures
  /// (Assign, Speak, Ink, Submit), which only the canonical editor edits.
  static String? defaultPresetFor(ExercisePrimitive primitive) =>
      switch (primitive) {
        ExercisePrimitive.select => 'choice_target',
        ExercisePrimitive.input => 'type_missing_word',
        ExercisePrimitive.arrange => 'word_order',
        ExercisePrimitive.match => 'word_match',
        ExercisePrimitive.presentation => 'flashcard',
        ExercisePrimitive.assign ||
        ExercisePrimitive.speak ||
        ExercisePrimitive.ink ||
        ExercisePrimitive.submit => null,
      };

  /// The preset [exercise] opens in: the one it carries when it exists,
  /// else the first recipe that represents it exactly, else the plainest
  /// recipe of its primitive. Null when no preset can edit its primitive.
  static String? presetToEdit(Exercise exercise) {
    final own = exercise.editorTemplate;
    if (own.isNotEmpty && ExercisePresetRegistry.byId(own) != null) return own;
    // A retired preset (Revision 4 catalogue) opens in its successor when
    // the successor still represents the exercise exactly.
    final successor = ExercisePresetRegistry.successorOf[own];
    if (successor != null && represents(exercise, successor)) return successor;
    return recognize(exercise) ?? defaultPresetFor(exercise.primitive);
  }

  /// The author fields of the [presetId] form, read from [exercise]'s
  /// canonical data. [original] is the exercise the draft builder patches
  /// (the exercise itself while editing; a blank one for recognition).
  static ExerciseDraftValues decompose(
    Exercise exercise,
    String presetId, {
    Exercise? original,
    PublicationState? publicationState,
    bool requireValidAnswer = false,
    bool attachSelectedSharedSource = false,
  }) {
    final f = ExerciseFeatures(exercise);
    final items = exercise.items;
    final evaluation = exercise.canonicalEvaluation;
    final assignments = f.targetAssignments;
    // A picture item (Match pictures to words) is named by its picture.
    final valueById = {
      for (final item in items)
        item.id: item.value.isNotEmpty ? item.value : item.image,
    };
    final inline =
        f.hasInlineTargets &&
        (f.primitive == ExercisePrimitive.select ||
            f.primitive == ExercisePrimitive.arrange);
    final multiple = f.multipleSelection;
    final correctIds = evaluation.correctItemIds;
    final correctIndex = correctIds.isEmpty
        ? -1
        : items.indexWhere((item) => item.id == correctIds.first);
    final correct = multiple
        ? [
            for (var i = 0; i < items.length; i++)
              if (correctIds.contains(items[i].id)) '${i + 1}',
          ].join(', ')
        : correctIndex >= 0
        ? '${correctIndex + 1}'
        : presetId.startsWith('translation_choice')
        ? '1'
        : '';
    final presentation = f.primitive == ExercisePrimitive.presentation;
    // The main text of the form: context, passage, situation, primary text,
    // then clue; a Presentation shows its term and an Input with inline gaps
    // its sentence.
    final prompt = presetId == 'dialogue_line'
        ? (f.lineText.isNotEmpty ? f.lineText : (f.lineAudio?.text ?? ''))
        : presetId == 'story_cover'
        ? f.coverTitle
        : presetId == 'before_you_start'
        ? f.introText
        : presetId == 'page'
        ? ''
        : presentation
        ? f.textOf('term')
        : presetId == 'missing_letters' && f.hasInlineTargets
        ? f.markedSentence
        // Complete the text shows each gap as ___ (Build 259 Revision 3).
        : presetId == 'complete_text' && exercise.layout.isNotEmpty
        ? [
            for (final element in exercise.layout)
              element.isTarget ? '___' : element.text,
          ].join()
        : f.primitive == ExercisePrimitive.input && f.hasInlineTargets
        ? f.inlineSentence
        : [
            f.contextText,
            f.passageText,
            f.situationText,
            f.primaryText,
            f.clueText,
          ].firstWhere((text) => text.isNotEmpty, orElse: () => '');
    final story =
        presetId == 'dialogue_line' ||
        presetId == 'story_cover' ||
        presetId == 'before_you_start' ||
        presetId == 'page';
    final question = story
        ? ''
        : presentation
        ? f.textOf('meaning')
        // Complete the text keeps its Instruction or context in the form's
        // question value (Build 259 Revision 1).
        : presetId == 'complete_text'
        ? f.authoredInstruction
        : f.questionText;
    // (A Note card keeps its body as the meaning.)
    // The former Fill-in shape keeps its sentence in the question field; the
    // Type the missing word form shows it as the sentence.
    final sentence =
        prompt.isEmpty &&
            presetId == 'type_missing_word' &&
            f.primitive == ExercisePrimitive.input
        ? question
        : prompt;
    // A Flashcard's Pronunciation TTS (if different) stays empty while the
    // spoken text is the word itself (Build 256 Revision 7 follow-up).
    final tts = story
        ? ''
        : presentation
        ? (f.audioOf('audio').trim() == f.textOf('term').trim()
              ? ''
              : f.audioOf('audio'))
        : (f.primaryAudioText ?? '');
    final rightValues = [
      for (final relation in evaluation.relations)
        if (relation.length == 2) valueById[relation[1]] ?? '',
    ];
    final List<String> answers;
    if (presentation) {
      answers = [
        if (f.textOf('usage').isNotEmpty) f.textOf('usage'),
        if (f.textOf('usage_translation').isNotEmpty)
          f.textOf('usage_translation'),
      ];
    } else if (f.primitive == ExercisePrimitive.match) {
      answers = f.leftItemsHaveAudio
          ? rightValues.where((value) => value.isNotEmpty).toList()
          : const [];
    } else {
      answers = [
        for (final item in items)
          if (item.value.isNotEmpty) item.value,
      ];
    }
    final accepted = f.acceptedAnswers;
    final tokens = inline
        ? [
            for (final item in items)
              if (!assignments.values.contains(item.id)) item.value,
          ]
        : [
            for (final item in items)
              if (item.value.isNotEmpty) item.value,
          ];
    final orders = evaluation.correctOrders;
    final order = orders.isEmpty
        ? const <String>[]
        : [
            for (final id in orders.first.itemIds)
              if ((valueById[id] ?? '').isNotEmpty) valueById[id]!,
          ];
    final gapLayout = exercise.layout
        .map(
          (element) => element.isTarget
              // A gap is _word_ (Build 259 Revision 4; {word} before).
              ? '_${valueById[assignments[element.targetId]] ?? ''}_'
              : element.text,
        )
        .join(' ');
    final pairs = [
      for (final relation in evaluation.relations)
        if (relation.length == 2)
          '${valueById[relation[0]] ?? relation[0]} = ${valueById[relation[1]] ?? relation[1]}',
    ];
    final icons = [
      for (final item in items)
        item.image.isNotEmpty
            ? item.image
            : item.content
                      .where((element) => element.role == 'icon')
                      .map((element) => element.text)
                      .firstOrNull ??
                  '',
    ];
    final missingWords = presetId == 'listening_spelling'
        ? accepted
        : [
            for (final target in f.gapFieldTargets)
              ...?f.answersFor(target.id)?.answers.take(1),
          ];
    final hasContextText =
        f.contextText.isNotEmpty || f.dialogueTurns.isNotEmpty;
    final hasContextAudio = f.contextAudio.isNotEmpty;
    final contextMode = hasContextText && hasContextAudio
        ? 'textAndAudio'
        : hasContextAudio
        ? 'audio'
        : 'text';
    final translations = orders.map((answer) => answer.text).toList();
    final imageAsset = f.illustrationAsset;
    final selectedSharedSource = exercise.promptElements
        .where((element) => element.isImage && element.asset == imageAsset)
        .firstOrNull
        ?.sharedImageSource;
    // Assign (Build 256 Revision 7 follow-up): the groups or the slots of
    // the form, each target named by the layout text before it and holding
    // its words in the answer's order; the words in no target stay in the
    // bank (Fill the slots' Extra words).
    final isAssign = f.primitive == ExercisePrimitive.assign;
    final byTarget = f.assignmentsByTarget;
    final assignedIds = {for (final ids in byTarget.values) ...ids};
    String wordOf(String id) => valueById[id] ?? id;
    String targetWords(String targetId) =>
        (byTarget[targetId] ?? const <String>{}).map(wordOf).join(', ');
    final groups = !isAssign
        ? ''
        : [
            for (final target in exercise.targets)
              '${f.targetLabel(target.id)}: ${targetWords(target.id)}',
          ].join('\n');
    final slots = !isAssign
        ? ''
        : [
            for (final target in exercise.targets)
              '${f.targetLabel(target.id)} = ${targetWords(target.id)}',
          ].join('\n');
    // Name what you see and Put the sentences in order: the blocks outside
    // the answer are its extra blocks (lines).
    final nameIds = orders.isEmpty
        ? const <String>{}
        : orders.first.itemIds.toSet();
    final extraBlocks = [
      for (final item in items)
        if (!nameIds.contains(item.id) && item.value.isNotEmpty) item.value,
    ].join('\n');
    final unassigned = !isAssign
        ? ''
        : [
            for (final item in items)
              if (!assignedIds.contains(item.id)) wordOf(item.id),
          ].join('\n');
    // Read and answer's dialogue read-aloud (fourth follow-up): none when
    // the lines have no audio, else as the first line's audio plays.
    final dialogueAudio = f.dialogueAudio;
    final dialogueReadAloud = dialogueAudio.isEmpty
        ? 'none'
        : dialogueAudio.first.effectivePlayback.serialized;
    // A Flashcard's read-aloud (Build 256 Revision 7 follow-up): none when
    // the card has no audio, else as its playback says; a blank card (no
    // term yet) starts on request.
    final cardAudio = presentation
        ? f.audioElements.where((e) => e.role == 'audio').firstOrNull
        : null;
    final cardReadAloud = !presentation
        ? 'manual'
        : cardAudio != null
        ? (cardAudio.effectivePlayback == AudioPlayback.automatic
              ? 'automatic'
              : 'manual')
        : f.textOf('term').isEmpty
        ? 'manual'
        : 'none';
    final state = publicationState ?? exercise.publicationState;
    final leftLanguage = f.leftItems.isEmpty
        ? null
        : f.leftItems.first.content
              .where((e) => e.isText && e.language != null)
              .map((e) => e.language)
              .firstOrNull;
    Exercise? scriptCandidate;
    if (presetId == 'script_recognition') {
      final controller = ScriptRecognitionController(exercise);
      try {
        scriptCandidate = controller.build(state);
      } finally {
        controller.dispose();
      }
    }
    return ExerciseDraftValues(
      original: original ?? exercise,
      type: presetId,
      speakerId: f.speakerId,
      lineMode: f.lineMode.isEmpty ? 'both' : f.lineMode,
      lineReadAloud: f.lineReadAloud,
      lineTextReveal: f.textReveal == TextReveal.afterAudio
          ? 'afterAudio'
          : 'immediate',
      lineLanguage: f.lineLanguage,
      groups: groups,
      slots: slots,
      extraWords: presetId == 'picture_blocks' || presetId == 'sentence_order'
          ? extraBlocks
          : unassigned,
      slotReuse: isAssign && f.assignItemReuse,
      guidebookButton: f.guidebookButton,
      pageBlocks: presetId == 'page' ? f.pageBlocks : const [],
      cardReadAloud: cardReadAloud,
      dialogueReadAloud: dialogueReadAloud,
      publicationState: state,
      requireValidAnswer: requireValidAnswer,
      useInlineGaps: inline,
      useMultiSelect: multiple,
      prompt: sentence,
      question: question,
      tts: tts,
      hint: exercise.hint,
      answers: answers.join('\n'),
      correct: correct,
      accepted: accepted.join('\n'),
      tokens: tokens.join('\n'),
      order: order.join('\n'),
      gapLayout: gapLayout,
      pairs: pairs.join('\n'),
      icons: icons.join('\n'),
      missingWords: missingWords.join('\n'),
      context: f.contextText,
      dialogue: f.dialogueTurns
          .map((turn) => '${turn.speaker}: ${turn.text}')
          .join('\n'),
      requiredSelections: multiple ? '${f.minimumSelections}' : '',
      correctTranslations: translations.isEmpty ? const [''] : translations,
      contextMode: contextMode,
      imageAsset: imageAsset,
      selectedSharedSource: selectedSharedSource,
      attachSelectedSharedSource: attachSelectedSharedSource,
      scriptCandidate: scriptCandidate,
      revealFirstLetter:
          f.primitive != ExercisePrimitive.input ||
          (f.hasInlineTargets && f.revealTarget != null),
      textRole: f.situationText.isNotEmpty
          ? 'situation'
          : hasContextText || hasContextAudio
          ? 'context'
          : f.passageText.isNotEmpty
          ? 'passage'
          : '',
      audioRole: f.automaticAudio?.role ?? '',
      matchSides: f.primitive != ExercisePrimitive.match || items.isEmpty
          ? ''
          : leftLanguage == TextLanguage.target
          ? 'target_source'
          : leftLanguage == TextLanguage.source
          ? 'source_target'
          : 'none',
    );
  }

  /// [exercise] rebuilt by the [presetId] form from its own fields alone
  /// (a blank original, so nothing the form cannot express survives), or
  /// null when the form refuses the fields.
  static Exercise? rebuild(Exercise exercise, String presetId) {
    final preset = ExercisePresetRegistry.byId(presetId);
    if (preset == null) return null;
    // The blank has the recipe's own v11 type, so the builder's original
    // carries the recipe's primitive and nothing else.
    final blank = Exercise(
      id: exercise.id,
      publicationState: exercise.publicationState,
      updatedAt: exercise.updatedAt,
      type: preset.base,
      prompt: '',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    ).copyWith(feedback: exercise.feedback);
    // Put the sentences in order also borrows the stored items (Build 259
    // Revision 1): its form keeps their IDs and order but does not show the
    // order, which the former "in any order" field let an author choose.
    final original = presetId == 'sentence_order'
        ? blank.copyWith(items: exercise.items)
        : blank;
    final draft = decompose(exercise, presetId, original: original);
    return ExerciseDraftBuilder.build(draft).candidate;
  }

  /// Whether the [presetId] form can represent [exercise] with nothing
  /// lost: decompose, rebuild, compare semantically. Item order counts;
  /// item IDs are compared by position, because a form keeps the IDs of
  /// the items it edits and mints new ones only for items it creates;
  /// authoring metadata, timestamps and publication state never count.
  static bool represents(Exercise exercise, String presetId) {
    if (!PresetVariants.fits(presetId, exercise)) return false;
    final rebuilt = rebuild(exercise, presetId);
    return rebuilt != null &&
        _comparable(rebuilt).semanticallyEquals(_comparable(exercise));
  }

  /// [exercise] in the form recognition compares: items renamed `item_0`,
  /// `item_1`, … and targets `target_0`, `target_1`, … in order with every
  /// reference rewritten (a form keeps the IDs it edits and mints the rest;
  /// Build 256 Revision 7 follow-up: targets too, for the Assign recipes);
  /// prompt elements in a stable order by role and type (a form lays its
  /// fields out in its own order; the order of same-role elements, such as
  /// dialogue turns, still counts); image captions blank (a form keeps them
  /// but has no field for them).
  static Exercise _comparable(Exercise exercise) {
    final rename = {
      for (var i = 0; i < exercise.items.length; i++)
        exercise.items[i].id: 'item_$i',
    };
    String map(String id) => rename[id] ?? id;
    final renameTarget = {
      for (var i = 0; i < exercise.targets.length; i++)
        exercise.targets[i].id: 'target_$i',
    };
    String mapTarget(String id) => renameTarget[id] ?? id;
    List<PromptElement> neutral(List<PromptElement> elements) {
      final indexed = elements.indexed.toList()
        ..sort((a, b) {
          final byRole = a.$2.role.compareTo(b.$2.role);
          if (byRole != 0) return byRole;
          final byType = a.$2.type.compareTo(b.$2.type);
          return byType != 0 ? byType : a.$1.compareTo(b.$1);
        });
      return [
        for (final (_, element) in indexed)
          element.isImage ? element.copyWith(text: '') : element,
      ];
    }

    final e = exercise.canonicalEvaluation;
    return exercise.copyWith(
      promptElements: neutral(exercise.promptElements),
      items: [
        for (final item in exercise.items)
          item.copyWith(id: map(item.id), content: neutral(item.content)),
      ],
      targets: [
        for (final target in exercise.targets)
          ExerciseTarget(
            id: mapTarget(target.id),
            reveal: target.reveal,
            region: target.region,
          ),
      ],
      layout: [
        for (final element in exercise.layout)
          element.isTarget
              ? LayoutElement.target(mapTarget(element.targetId))
              : element,
      ],
      canonicalEvaluation: CanonicalEvaluation(
        mode: e.mode,
        correctItemIds: e.correctItemIds.map(map).toList(),
        assignments: [
          for (final assignment in e.assignments)
            TargetAssignment(
              targetId: mapTarget(assignment.targetId),
              itemIds: assignment.itemIds.map(map).toList(),
            ),
        ],
        answers: e.answers,
        literalAnswers: e.literalAnswers,
        targetAnswers: [
          for (final answers in e.targetAnswers)
            TargetAnswers(
              targetId: mapTarget(answers.targetId),
              answers: answers.answers,
              literalAnswers: answers.literalAnswers,
            ),
        ],
        numeric: e.numeric,
        pattern: e.pattern,
        correctOrders: [
          for (final order in e.correctOrders)
            OrderedAnswer(
              text: order.text,
              itemIds: order.itemIds.map(map).toList(),
            ),
        ],
        relations: [
          for (final relation in e.relations) relation.map(map).toList(),
        ],
        acceptedTargets: [
          for (final target in e.acceptedTargets)
            AcceptedTarget(
              itemId: map(target.itemId),
              targetIds: target.targetIds.map(mapTarget).toList(),
            ),
        ],
      ),
    );
  }

  /// The preset whose recipe represents [exercise] exactly: its own first,
  /// then every preset producing the same learner kind in registry order.
  /// Null when none does. Near matches are not matches.
  static String? recognize(Exercise exercise) {
    final own = exercise.editorTemplate;
    final kind = ExerciseFeatures(exercise).kind;
    final candidates = [
      if (own.isNotEmpty && ExercisePresetRegistry.byId(own) != null) own,
      for (final preset in ExercisePresetRegistry.presets)
        if (preset.id != own && (kinds[preset.id]?.contains(kind) ?? false))
          preset.id,
    ];
    for (final presetId in candidates) {
      if (represents(exercise, presetId)) return presetId;
    }
    return null;
  }
}
