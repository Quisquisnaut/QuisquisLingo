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
      case 'listening_answer_target':
      case 'listening_answer_source':
        // An opened exercise keeps its shape; a new one without a question
        // asks what was heard, with a question it asks about the passage.
        return switch (draft.audioRole) {
          'passage' => 'listening_comprehension',
          'primary' => 'listening_choice',
          _ =>
            draft.question.trim().isEmpty
                ? 'listening_choice'
                : 'listening_comprehension',
        };
      case 'reading_answer_target':
      case 'reading_answer_source':
        // Dialogue lines or audio need the context shape; otherwise an
        // opened exercise keeps its passage, situation or context shape and
        // a new one is a passage.
        if (draft.dialogue.trim().isNotEmpty || draft.tts.trim().isNotEmpty) {
          return 'contextual_comprehension';
        }
        return switch (draft.textRole) {
          'situation' => 'dialogue_response',
          'context' => 'contextual_comprehension',
          _ => 'reading_comprehension',
        };
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
    'spell_heard',
    'picture_choice',
    'picture_name',
    'spell_word',
    'picture_word_match',
    'note_card',
    'dialogue_line',
    'story_cover',
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
        presetId.startsWith('reading_answer')) {
      // Read and answer in the context shape: the text is the context and
      // the spoken text, when there is one, its audio.
      final hasText = draft.prompt.trim().isNotEmpty;
      final hasAudio = draft.tts.trim().isNotEmpty;
      return draft.copyWith(
        type: base,
        context: draft.prompt,
        contextMode: hasAudio && !hasText
            ? 'audio'
            : hasAudio
            ? 'textAndAudio'
            : 'text',
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
        return draft.copyWith(
          type: base,
          useInlineGaps: false,
          useMultiSelect: false,
          tts: '',
        );
      case 'gap_choice_inline':
        return draft.copyWith(type: base, useInlineGaps: true);
      case 'word_order':
      case 'build_translation_to_target':
      case 'build_translation_to_source':
      case 'sentence_order':
        return draft.copyWith(type: base, useInlineGaps: false);
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
      case 'picture_name':
        return _withPictureRole(exercise);
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
        return exercise.copyWith(
          promptElements: mark(
            exercise.promptElements,
            (e) =>
                (e.isText || e.isAudio) &&
                (e.role == 'primary' || e.role == 'question'),
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
      case 'reading_answer_source':
        return exercise.copyWith(
          promptElements: mark(
            exercise.promptElements,
            (e) => e.isText && e.role == 'question',
            TextLanguage.source,
          ),
          items: markItems(TextLanguage.source),
        );
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
