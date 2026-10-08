import '../models/course_models.dart';
import 'exercise_draft_builder.dart';

/// A working example of each primitive for the canonical editor's "Fill
/// with an example" (Build 261 Revision 5, owner decision of 2 October
/// 2026): it shows a creator what a complete exercise of that primitive
/// holds. The texts are English placeholders for the creator to replace;
/// they state no language. Select, Input, Arrange, Match, Assign and
/// Presentation examples play in this version; Speak, Ink and Submit have
/// definitions only.
abstract final class CanonicalExerciseSamples {
  static Exercise forPrimitive(
    ExercisePrimitive primitive, {
    required String id,
    required DateTime updatedAt,
  }) {
    PromptElement text(String value, [String role = 'primary']) =>
        PromptElement(type: 'text', text: value, role: role);
    ExerciseItem item(int index, String value, {MatchSide? side}) =>
        ExerciseItem(id: '${id}_i$index', content: [text(value)], side: side);
    Exercise canonical({
      Map<OptionKey, OptionValue> options = const {},
      List<PromptElement> prompt = const [],
      List<ExerciseItem> items = const [],
      required CanonicalEvaluation evaluation,
    }) => Exercise.canonical(
      id: id,
      publicationState: PublicationState.draft,
      updatedAt: updatedAt,
      primitive: primitive,
      options: PrimitiveOptions(options),
      promptElements: prompt,
      items: items,
      canonicalEvaluation: evaluation,
    );

    return switch (primitive) {
      ExercisePrimitive.select => canonical(
        prompt: [text('Which animal barks?', 'question')],
        items: [item(0, 'the dog'), item(1, 'the cat'), item(2, 'the fish')],
        evaluation: CanonicalEvaluation(
          mode: EvaluationMode.exactItem,
          correctItemIds: ['${id}_i0'],
        ),
      ),
      ExercisePrimitive.input => canonical(
        prompt: [text('What colour is the sky on a sunny day?', 'question')],
        evaluation: const CanonicalEvaluation(
          mode: EvaluationMode.acceptedTexts,
          answers: ['blue'],
        ),
      ),
      ExercisePrimitive.arrange => canonical(
        prompt: [text('Put the words in order.')],
        items: [
          item(0, 'The'),
          item(1, 'cat'),
          item(2, 'sleeps'),
          item(3, 'dog'),
        ],
        evaluation: CanonicalEvaluation(
          mode: EvaluationMode.acceptedOrders,
          correctOrders: [
            OrderedAnswer(
              text: 'The cat sleeps',
              itemIds: ['${id}_i0', '${id}_i1', '${id}_i2'],
            ),
          ],
        ),
      ),
      ExercisePrimitive.match => canonical(
        prompt: [text('Match each word with its opposite.', 'question')],
        items: [
          item(0, 'hot', side: MatchSide.left),
          item(1, 'big', side: MatchSide.left),
          item(2, 'cold', side: MatchSide.right),
          item(3, 'small', side: MatchSide.right),
        ],
        evaluation: CanonicalEvaluation(
          mode: EvaluationMode.exactRelations,
          relations: [
            ['${id}_i0', '${id}_i2'],
            ['${id}_i1', '${id}_i3'],
          ],
        ),
      ),
      // Groups need their names in the layout: the Sort into groups recipe
      // writes them, without its preset.
      ExercisePrimitive.assign => ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: Exercise.canonical(
            id: id,
            publicationState: PublicationState.draft,
            primitive: ExercisePrimitive.presentation,
            canonicalEvaluation: CanonicalEvaluation.none,
            updatedAt: updatedAt,
          ),
          type: 'sort_into_groups',
          publicationState: PublicationState.draft,
          prompt: 'Sort the words: animals or food?',
          groups: 'Animals: dog, cat\nFood: bread, apple',
        ),
      ).candidate!.copyWith(authoringMetadata: const {}),
      ExercisePrimitive.speak => canonical(
        options: {
          OptionKey.speechMode: const EnumOptionValue(SpeechMode.repeat),
        },
        prompt: [text('Good morning')],
        evaluation: const CanonicalEvaluation(
          mode: EvaluationMode.transcriptionMatch,
          answers: ['Good morning'],
        ),
      ),
      ExercisePrimitive.ink => canonical(
        options: {OptionKey.inkMode: const EnumOptionValue(InkMode.trace)},
        prompt: [text('Trace the letter a.')],
        evaluation: const CanonicalEvaluation(mode: EvaluationMode.none),
      ),
      ExercisePrimitive.submit => canonical(
        options: {
          OptionKey.submissionType: const EnumOptionValue(SubmissionType.audio),
        },
        prompt: [text('Record yourself saying good morning.')],
        evaluation: const CanonicalEvaluation(mode: EvaluationMode.presence),
      ),
      ExercisePrimitive.presentation => canonical(
        prompt: [
          text('Good morning', 'term'),
          text('A greeting said until early afternoon.', 'meaning'),
        ],
        evaluation: CanonicalEvaluation.none,
      ),
    };
  }
}
