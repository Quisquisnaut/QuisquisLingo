import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';
import 'exercise_draft_builder.dart';

/// How a catalogue preset reuses an older recipe (Build 256 Revision 4,
/// `docs/256_PRESET_CATALOGUE_PLAN.md`): the base recipe the draft builder
/// runs, the fields the form shows, and what the preset adds on top, such
/// as the source-language side of a twin or the first-letter hint.
///
/// A "to target" twin is exactly its base recipe, so every exercise built by
/// the old preset is still represented by the twin; a "to source" twin adds
/// `language: source` to the question and the answers. The rest of the
/// exercise (audio, passage, options) stays as the base recipe wrote it.
abstract final class PresetVariants {
  /// The recipe the builder runs for [presetId] with these [draft] fields.
  static String baseFor(String presetId, ExerciseDraftValues draft) {
    switch (presetId) {
      case 'listening_choose_target':
      case 'listening_choose_source':
        // Listen and choose: what was heard, no question (Build 259
        // Revision 2).
        return 'listening_choice';
      case 'listening_answer_target':
      case 'listening_answer_source':
        // An opened exercise keeps its shape; a new one asks its question
        // about the passage (the question is required since Build 259
        // Revision 2; Listen and choose asks what was heard).
        return switch (draft.audioRole) {
          'primary' => 'listening_choice',
          _ => 'listening_comprehension',
        };
      case 'reading_answer_target':
        // The text to read is context in the source language, followed by
        // the dialogue lines (Build 256 Revision 7 fourth follow-up).
        return 'contextual_comprehension';
      case 'word_match':
        // The former Matching shape (left target, right source) keeps its
        // sides; a new exercise pairs source words with their translations.
        return draft.matchSides == 'target_source' ? 'matching' : 'word_match';
      case 'type_missing_word':
        // With the first-letter hint off the exercise is the former Fill-in
        // shape: one field under the sentence, no inline target.
        return draft.revealFirstLetter ? 'type_missing_word' : 'fill_blank';
      default:
        return formBase(presetId);
    }
  }

  /// The recipe whose fields the form, Help and Search use for [presetId].
  static String formBase(String presetId) =>
      ExercisePresetRegistry.byId(presetId)?.base ?? presetId;

  /// The presets with a form of their own in the editor (Stage 3); the
  /// others show their base recipe's form.
  static const ownForms = <String>{
    'true_false',
    'gap_choice_inline',
    'complete_text',
    'missing_letters',
    'gap_blocks',
    'sentence_order',
    'listening_image_choice',
    'listening_choose_target',
    'listening_choose_source',
    'spell_heard',
    'picture_choice',
    'picture_name',
    'spell_word',
    'picture_word_match',
    'note_card',
    'dialogue_line',
    'story_cover',
    'before_you_start',
    'page',
    'sort_into_groups',
    'fill_the_slots',
  };

  /// The form the editor shows for [presetId]: its own or its base's.
  static String formFor(String presetId) =>
      ownForms.contains(presetId) ? presetId : formBase(presetId);

  /// Whether [value] names a picture: a bundled asset, a Course medium or a
  /// portable data URI.
  static bool isImageReference(String value) =>
      value.startsWith('assets/') ||
      value.startsWith('media:') ||
      value.startsWith('data:');

  /// The [draft] as the base recipe expects it.
  static ExerciseDraftValues draftFor(
    String presetId,
    ExerciseDraftValues draft,
  ) {
    final base = baseFor(presetId, draft);
    if (base == 'contextual_comprehension' &&
        presetId == 'reading_answer_target') {
      // Read and answer in the context shape: the text is the context; there
      // is no spoken text (the dialogue is read aloud instead).
      return draft.copyWith(
        type: base,
        context: draft.prompt,
        contextMode: 'text',
        tts: '',
      );
    }
    if (base == 'fill_blank' && presetId == 'type_missing_word') {
      // The Fill-in recipe reads the sentence from the question field.
      return draft.copyWith(type: base, question: draft.prompt);
    }
    switch (presetId) {
      case 'choice_target':
      case 'choice_source':
        // Inline gaps are their own preset (Pick the words for the gaps) and
        // a spoken statement belongs to True or false: the Choose form has
        // neither.
        return draft.copyWith(type: base, useInlineGaps: false, tts: '');
      case 'true_false':
        return draft.copyWith(
          type: base,
          useInlineGaps: false,
          useMultiSelect: false,
        );
      case 'picture_choice':
        // Its Instruction or context is the Choose recipe's primary text;
        // it has no question (Build 259).
        return draft.copyWith(
          type: base,
          useInlineGaps: false,
          useMultiSelect: false,
          tts: '',
          question: '',
        );
      case 'listening_image_choice':
      case 'picture_name':
      case 'listening_choose_target':
      case 'listening_choose_source':
        // Their base recipes read the text from the question field; `finish`
        // makes it the Instruction or context (Build 259).
        return draft.copyWith(type: base, question: draft.prompt);
      case 'gap_choice_inline':
        return draft.copyWith(type: base, useInlineGaps: true);
      case 'word_order':
      case 'build_translation_to_target':
      case 'build_translation_to_source':
        return draft.copyWith(type: base, useInlineGaps: false);
      case 'sentence_order':
        // Its own recipe (Build 259 Revision 1): the lines once, in order.
        return draft.copyWith(type: presetId, useInlineGaps: false);
      case 'gap_blocks':
        return draft.copyWith(type: base, useInlineGaps: true);
      case 'complete_text':
        return draft.copyWith(type: base, tts: '');
      case 'missing_letters':
        // The bracketed letters become the gaps of the text without them.
        final letters = <String>[];
        final text = draft.prompt.replaceAllMapped(RegExp(r'\[([^\[\]]+)\]'), (
          match,
        ) {
          letters.add(match.group(1)!);
          return match.group(1)!;
        });
        // Without brackets (a reopened exercise's plain text) the gaps stay
        // the ones the exercise already has.
        return letters.isEmpty
            ? draft.copyWith(type: base)
            : draft.copyWith(
                type: base,
                prompt: text,
                missingWords: letters.join('\n'),
              );
      case 'note_card':
        return draft.copyWith(type: base, tts: '', answers: '');
      default:
        return draft.copyWith(type: base);
    }
  }

  /// [candidate], built by the base recipe, finished as [presetId]: it
  /// carries the preset and the source-language side of a "to source" twin.
  static Exercise finish(
    String presetId,
    Exercise candidate,
    ExerciseDraftValues draft,
  ) {
    // The script controller's candidate is complete as it is.
    if (presetId == 'script_recognition') return candidate;
    var exercise = candidate;
    final preset = ExercisePresetRegistry.byId(presetId);
    if (preset != null && preset.direction == PresetDirection.toSource) {
      exercise = toSource(presetId, exercise);
    }
    exercise = _shape(presetId, exercise);
    if (presetId == 'reading_answer_target') {
      exercise = _readAndAnswer(exercise, draft.dialogueReadAloud);
    }
    if (presetId == 'complete_text') {
      exercise = _withInstruction(exercise, draft.question);
    }
    // A candidate the base recipe already finished (the script controller's
    // own candidate, for one) crosses unchanged.
    if (identical(exercise, candidate) && exercise.editorTemplate == presetId) {
      return candidate;
    }
    return exercise.withAuthoringMetadata({
      ...exercise.authoringMetadata,
      'presetId': presetId,
    });
  }

  /// Read and answer (Build 256 Revision 7 fourth follow-up; owner
  /// decisions of 29 September 2026): the text to read explains the
  /// situation in the source language and is never read aloud; when the
  /// dialogue is read aloud, each line is followed by its optional audio
  /// (automatic or on request), spoken in turn.
  static Exercise _readAndAnswer(Exercise exercise, String readAloud) {
    final playback = switch (readAloud) {
      'automatic' => AudioPlayback.automatic,
      'manual' => AudioPlayback.manual,
      _ => null,
    };
    return exercise.copyWith(
      promptElements: [
        for (final element in exercise.promptElements)
          if (element.isAudio && element.role == 'dialogue_turn')
            ...const <PromptElement>[]
          else if (element.isText && element.role == 'context')
            element.copyWith(language: TextLanguage.source)
          else if (element.isText &&
              element.role == 'dialogue_turn' &&
              playback != null) ...[
            element,
            PromptElement(
              role: 'dialogue_turn',
              type: 'audio',
              text: element.text,
              playback: playback,
              required: false,
            ),
          ] else
            element,
      ],
    );
  }

  /// What a Stage 3 preset adds to its base recipe's exercise: True or
  /// false answers in the source language, Spell the word's clue in the
  /// source language, a Picture flashcard's optional audio, Match picture to
  /// word's pictures on the left items.
  static Exercise _shape(String presetId, Exercise exercise) {
    switch (presetId) {
      case 'true_false':
        return exercise.copyWith(
          items: [
            for (final item in exercise.items)
              item.copyWith(
                content: [
                  for (final element in item.content)
                    if (element.isText)
                      element.copyWith(language: TextLanguage.source)
                    else
                      element,
                ],
              ),
          ],
        );
      case 'spell_word':
        return exercise.copyWith(
          promptElements: [
            for (final element in exercise.promptElements)
              if (element.isText && element.role == 'clue')
                element.copyWith(language: TextLanguage.source)
              else
                element,
          ],
        );
      case 'flashcard':
        // A Flashcard's read-aloud is an aid, never an audio exercise
        // (Build 256 Revision 7 follow-up, as the Picture flashcard).
        return exercise.copyWith(
          promptElements: [
            for (final element in exercise.promptElements)
              if (element.isAudio)
                element.copyWith(required: false)
              else
                element,
          ],
        );
      case 'picture_flashcard':
        return _withPictureRole(
          exercise.copyWith(
            promptElements: [
              for (final element in exercise.promptElements)
                if (element.isAudio)
                  element.copyWith(required: false)
                else
                  element,
            ],
          ),
        );
      case 'picture_choice':
        return _withPictureRole(exercise);
      case 'picture_name':
        return _withPictureRole(_questionAsInstruction(exercise));
      case 'listening_image_choice':
      case 'listening_choose_target':
      case 'listening_choose_source':
        return _questionAsInstruction(exercise);
      case 'note_card':
        // A Note card is read and left with Continue: no review.
        return exercise.copyWith(options: PrimitiveOptions.empty);
      case 'picture_word_match':
        final leftIds = {
          for (final relation in exercise.canonicalEvaluation.relations)
            if (relation.length == 2) relation[0],
        };
        return exercise.copyWith(
          items: [
            for (final item in exercise.items)
              if (leftIds.contains(item.id) && isImageReference(item.text))
                item.copyWith(
                  content: [PromptElement(type: 'image', asset: item.text)],
                )
              else
                item,
          ],
        );
      default:
        return exercise;
    }
  }

  /// Complete the text's Instruction or context (Build 259 Revision 1): a
  /// `clue` text with no language, first in the prompt. It is a clue, not a
  /// primary text, because the Listen-for-missing-words recipe reads its
  /// primary text as the passage.
  static Exercise _withInstruction(Exercise exercise, String instruction) {
    final text = instruction.trim();
    if (text.isEmpty) return exercise;
    return exercise.copyWith(
      promptElements: [
        PromptElement(role: 'clue', type: 'text', text: text),
        ...exercise.promptElements,
      ],
    );
  }

  /// The base recipe's question text as the Instruction or context: a
  /// primary text with no language (Build 259, owner decisions of
  /// 29 September 2026), for the presets whose form has no question.
  static Exercise _questionAsInstruction(Exercise exercise) =>
      exercise.copyWith(
        promptElements: [
          for (final element in exercise.promptElements)
            if (element.isText && element.role == 'question')
              element.copyWith(role: 'primary')
            else
              element,
        ],
      );

  /// The picture presets carry their picture as `picture`, not as the
  /// generic `clue` illustration, so their base recipes do not represent
  /// them.
  static Exercise _withPictureRole(Exercise exercise) => exercise.copyWith(
    promptElements: [
      for (final element in exercise.promptElements)
        if (element.isImage && element.role == 'clue')
          element.copyWith(role: 'picture')
        else
          element,
    ],
  );

  /// The source-language side of a "to source" twin: the question (or the
  /// main text the learner answers about) and every answer are in the
  /// source language; a translation's clue is in the target language.
  static Exercise toSource(String presetId, Exercise exercise) {
    List<PromptElement> mark(
      List<PromptElement> elements,
      bool Function(PromptElement) where,
      TextLanguage language,
    ) => [
      for (final element in elements)
        if (where(element)) element.copyWith(language: language) else element,
    ];
    List<ExerciseItem> markItems(TextLanguage language) => [
      for (final item in exercise.items)
        item.copyWith(content: mark(item.content, (e) => e.isText, language)),
    ];
    switch (presetId) {
      case 'choice_source':
        // The Instruction or context stays without a language (Build 259):
        // only the question and the answers are marked.
        return exercise.copyWith(
          promptElements: mark(
            exercise.promptElements,
            (e) => (e.isText || e.isAudio) && e.role == 'question',
            TextLanguage.source,
          ),
          items: markItems(TextLanguage.source),
        );
      case 'type_translation_to_source':
        return exercise.copyWith(
          promptElements: mark(
            exercise.promptElements,
            (e) => e.isText && (e.role == 'clue' || e.role == 'primary'),
            TextLanguage.target,
          ),
        );
      case 'build_translation_to_source':
        return exercise.copyWith(
          promptElements: mark(
            exercise.promptElements,
            (e) => e.isText && (e.role == 'clue' || e.role == 'primary'),
            TextLanguage.target,
          ),
          items: markItems(TextLanguage.source),
        );
      case 'listening_answer_source':
        return exercise.copyWith(
          promptElements: mark(
            exercise.promptElements,
            (e) => e.isText && e.role == 'question',
            TextLanguage.source,
          ),
          items: markItems(TextLanguage.source),
        );
      case 'listening_choose_source':
        // Its instruction states no language (Build 259 Revision 2).
        return exercise.copyWith(items: markItems(TextLanguage.source));
      default:
        return exercise;
    }
  }

  /// Whether [exercise] has the shape that tells [presetId] apart from the
  /// other presets of its recipe. Recognition asks before rebuilding,
  /// because two presets of one recipe rebuild the same exercise: Missing
  /// letters is the Input preset with a gap inside a word, Spell the word
  /// in the picture has the picture, Spell what you hear the automatic
  /// audio and Spell the word neither.
  static bool fits(String presetId, Exercise exercise) {
    final f = ExerciseFeatures(exercise);
    return switch (presetId) {
      'missing_letters' => hasInWordGap(exercise),
      'image_word' => f.illustrationImages.isNotEmpty,
      'spell_heard' => f.illustrationImages.isEmpty && f.automaticAudio != null,
      'spell_word' => f.illustrationImages.isEmpty && f.automaticAudio == null,
      'dialogue_line' => f.kind == LearnerExerciseKind.dialogueLine,
      'story_cover' => f.kind == LearnerExerciseKind.storyCover,
      'before_you_start' => f.kind == LearnerExerciseKind.roundIntro,
      'page' => f.kind == LearnerExerciseKind.page,
      // The Assign recipes (Build 256 Revision 7 follow-up).
      'sort_into_groups' => f.kind == LearnerExerciseKind.assignGroups,
      'fill_the_slots' => f.kind == LearnerExerciseKind.assignSlots,
      _ =>
        exercise.primitive != ExercisePrimitive.input ||
            !hasInWordGap(exercise),
    };
  }

  /// Whether a gap of the inline layout sits inside a word: a letter
  /// touches it on either side (`dr[ink] milk`).
  static bool hasInWordGap(Exercise exercise) {
    final layout = exercise.layout;
    final letter = RegExp(r'\p{L}', unicode: true);
    bool touches(int index, {required bool last}) {
      if (index < 0 || index >= layout.length || !layout[index].isText) {
        return false;
      }
      final text = layout[index].text;
      if (text.isEmpty) return false;
      return letter.hasMatch(last ? text[text.length - 1] : text[0]);
    }

    for (var i = 0; i < layout.length; i++) {
      if (layout[i].isTarget &&
          (touches(i - 1, last: true) || touches(i + 1, last: false))) {
        return true;
      }
    }
    return false;
  }
}
