import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';
import '../widgets/script_recognition_editor.dart';
import 'exercise_draft_builder.dart';

/// Presets are optional authoring recipes over the canonical exercise
/// (Build 256 Session 4, plan A.13). A recipe is the preset's form: the
/// fields it shows, decomposed here from canonical data, and the exercise
/// the draft builder rebuilds from them. A preset never changes what plays;
/// nothing here writes.
abstract final class PresetRecipes {
  /// The learner kind each preset's recipe produces.
  static const kinds = <String, LearnerExerciseKind>{
    'choice': LearnerExerciseKind.select,
    'gap_choice': LearnerExerciseKind.selectComplete,
    'icon_choice': LearnerExerciseKind.selectImage,
    'script_recognition': LearnerExerciseKind.selectCharacter,
    'listening_choice': LearnerExerciseKind.selectListen,
    'listening_comprehension': LearnerExerciseKind.selectListenPassage,
    'reading_comprehension': LearnerExerciseKind.selectRead,
    'dialogue_response': LearnerExerciseKind.selectDialogue,
    'contextual_comprehension': LearnerExerciseKind.selectContext,
    'translation_choice_to_target': LearnerExerciseKind.selectTranslation,
    'translation_choice_to_source': LearnerExerciseKind.selectTranslation,
    'fill_blank': LearnerExerciseKind.inputComplete,
    'type_translation': LearnerExerciseKind.inputTranslation,
    'listening_spelling': LearnerExerciseKind.inputListenWrite,
    'missing_word': LearnerExerciseKind.inputListenGaps,
    'type_missing_word': LearnerExerciseKind.inputMissingWord,
    'word_order': LearnerExerciseKind.arrangeSentence,
    'build_translation': LearnerExerciseKind.arrangeTranslation,
    'image_word': LearnerExerciseKind.arrangeWord,
    'matching': LearnerExerciseKind.matchTranslation,
    'word_match': LearnerExerciseKind.matchTranslation,
    'super_match': LearnerExerciseKind.match,
    'audio_match': LearnerExerciseKind.matchAudio,
    'flashcard': LearnerExerciseKind.presentation,
  };

  /// The plainest recipe of [primitive], for an exercise that carries no
  /// preset that fits it; null for the primitives no preset configures
  /// (Assign, Speak, Ink, Submit), which only the canonical editor edits.
  static String? defaultPresetFor(ExercisePrimitive primitive) =>
      switch (primitive) {
        ExercisePrimitive.select => 'choice',
        ExercisePrimitive.input => 'fill_blank',
        ExercisePrimitive.arrange => 'word_order',
        ExercisePrimitive.match => 'matching',
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
    final valueById = {for (final item in items) item.id: item.value};
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
    final prompt = presentation
        ? f.textOf('term')
        : f.primitive == ExercisePrimitive.input && f.hasInlineTargets
        ? f.inlineSentence
        : [
            f.contextText,
            f.passageText,
            f.situationText,
            f.primaryText,
            f.clueText,
          ].firstWhere((text) => text.isNotEmpty, orElse: () => '');
    final question = presentation ? f.textOf('meaning') : f.questionText;
    final tts = presentation ? f.audioOf('audio') : (f.primaryAudioText ?? '');
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
              ? '{${valueById[assignments[element.targetId]] ?? ''}}'
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
    final state = publicationState ?? exercise.publicationState;
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
      publicationState: state,
      requireValidAnswer: requireValidAnswer,
      useInlineGaps: inline,
      useMultiSelect: multiple,
      prompt: prompt,
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
    );
  }

  /// [exercise] rebuilt by the [presetId] form from its own fields alone
  /// (a blank original, so nothing the form cannot express survives), or
  /// null when the form refuses the fields.
  static Exercise? rebuild(Exercise exercise, String presetId) {
    if (ExercisePresetRegistry.byId(presetId) == null) return null;
    final blank = Exercise(
      id: exercise.id,
      publicationState: exercise.publicationState,
      updatedAt: exercise.updatedAt,
      type: presetId,
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
    final draft = decompose(exercise, presetId, original: blank);
    return ExerciseDraftBuilder.build(draft).candidate;
  }

  /// Whether the [presetId] form can represent [exercise] with nothing
  /// lost: decompose, rebuild, compare semantically. Item order counts;
  /// item IDs are compared by position, because a form keeps the IDs of
  /// the items it edits and mints new ones only for items it creates;
  /// authoring metadata, timestamps and publication state never count.
  static bool represents(Exercise exercise, String presetId) {
    final rebuilt = rebuild(exercise, presetId);
    return rebuilt != null &&
        _comparable(rebuilt).semanticallyEquals(_comparable(exercise));
  }

  /// [exercise] in the form recognition compares: items renamed `item_0`,
  /// `item_1`, … in order with every reference rewritten; prompt elements
  /// in a stable order by role and type (a form lays its fields out in its
  /// own order; the order of same-role elements, such as dialogue turns,
  /// still counts); image captions blank (a form keeps them but has no
  /// field for them).
  static Exercise _comparable(Exercise exercise) {
    final rename = {
      for (var i = 0; i < exercise.items.length; i++)
        exercise.items[i].id: 'item_$i',
    };
    String map(String id) => rename[id] ?? id;
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
      canonicalEvaluation: CanonicalEvaluation(
        mode: e.mode,
        correctItemIds: e.correctItemIds.map(map).toList(),
        assignments: [
          for (final assignment in e.assignments)
            TargetAssignment(
              targetId: assignment.targetId,
              itemIds: assignment.itemIds.map(map).toList(),
            ),
        ],
        answers: e.answers,
        literalAnswers: e.literalAnswers,
        targetAnswers: e.targetAnswers,
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
              targetIds: target.targetIds,
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
        if (preset.id != own && kinds[preset.id] == kind) preset.id,
    ];
    for (final presetId in candidates) {
      if (represents(exercise, presetId)) return presetId;
    }
    return null;
  }
}
