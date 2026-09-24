import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';

Exercise _choice() => Exercise(
  id: 'stable-exercise',
  updatedAt: DateTime.utc(2026, 9, 20),
  type: 'choice',
  prompt: 'Good morning',
  question: '',
  answers: const ['Buongiorno', 'Buonanotte'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

void main() {
  test(
    'Draft keeps an unset answer; Published and Preview return a typed field error',
    () {
      for (final state in PublicationState.values) {
        final result = ExerciseDraftBuilder.build(
          ExerciseDraftValues(
            original: _choice(),
            type: 'choice',
            publicationState: state,
            prompt: 'Good morning',
            answers: 'Buongiorno\nBuonanotte',
            correct: '9',
          ),
        );
        if (state.isPublished) {
          expect(result.candidate, isNull);
          expect(result.error?.field, ExerciseDraftField.correct);
          expect(
            result.error?.code,
            ExerciseDraftErrorCode.correctAnswerNumber,
          );
        } else {
          expect(result.error, isNull);
          expect(result.candidate?.correct, isNull);
          expect(result.candidate?.id, 'stable-exercise');
        }
      }

      final preview = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _choice(),
          type: 'choice',
          publicationState: PublicationState.draft,
          answers: 'Buongiorno\nBuonanotte',
          correct: '9',
          requireValidAnswer: true,
        ),
      );
      expect(preview.error?.code, ExerciseDraftErrorCode.correctAnswerNumber);
    },
  );

  test(
    'inline Arrange uses the established deterministic item and gap IDs',
    () {
      final result = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _choice(),
          type: 'word_order',
          publicationState: PublicationState.draft,
          useInlineGaps: true,
          gapLayout: 'I {go} to {school}.',
          tokens: 'went',
          prompt: 'Build the sentence',
        ),
      );
      expect(result.error, isNull);
      final candidate = result.candidate!;
      expect(candidate.interaction.kind, 'arrange');
      expect(candidate.interaction.items.map((item) => item.id), [
        'item_0',
        'item_1',
        'item_2',
      ]);
      expect(candidate.evaluation.gapAssignments, {
        'gap_1': 'item_0',
        'gap_2': 'item_1',
      });
      expect(candidate.updatedAt, _choice().updatedAt);
    },
  );

  test(
    'multi-select Draft and Published retain their existing answer rules',
    () {
      final draft = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _choice(),
          type: 'choice',
          publicationState: PublicationState.draft,
          useMultiSelect: true,
          answers: 'one\ntwo',
        ),
      );
      expect(draft.error, isNull);
      expect(draft.candidate?.evaluation.correctItemIds, isEmpty);
      expect(draft.candidate?.interaction.minSelections, 1);

      final published = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _choice(),
          type: 'choice',
          publicationState: PublicationState.published,
          useMultiSelect: true,
          answers: 'one\ntwo',
        ),
      );
      expect(published.error?.field, ExerciseDraftField.correct);
      expect(
        published.error?.code,
        ExerciseDraftErrorCode.multiCorrectRequired,
      );
    },
  );

  test(
    'literal translations and pair lines return typed errors with locations',
    () {
      final duplicates = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _choice(),
          type: 'build_translation',
          publicationState: PublicationState.draft,
          correctTranslations: const ['Ciao!', '', ' ciao. '],
        ),
      );
      expect(duplicates.error?.field, ExerciseDraftField.correctTranslations);
      expect(
        duplicates.error?.code,
        ExerciseDraftErrorCode.correctTranslationsDuplicate,
      );
      expect(duplicates.error?.indexes, {0, 2});

      final pair = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _choice(),
          type: 'matching',
          publicationState: PublicationState.draft,
          pairs: 'a = b\nincomplete',
        ),
      );
      expect(pair.error?.field, ExerciseDraftField.pairs);
      expect(pair.error?.code, ExerciseDraftErrorCode.pairLine);
      expect(pair.error?.line, 2);
    },
  );

  test('Save provenance is attached while Preview keeps the raw candidate', () {
    const source = SharedImageSource(
      id: 'image_local_1',
      label: 'cat',
      category: 'animals',
      tags: ['cat'],
      origin: 'device',
    );
    final original = Exercise.v2(
      id: 'typed-image',
      updatedAt: DateTime.utc(2026, 9, 20),
      editorTemplate: 'type_translation',
      promptElements: const [
        PromptElement(role: 'primary', type: 'text', text: 'old'),
        PromptElement(type: 'image', asset: 'old.png'),
      ],
      interaction: const ExerciseInteraction(kind: 'input'),
      evaluation: const ExerciseEvaluation(kind: 'text_match'),
    );
    ExerciseDraftValues values({required bool attach}) => ExerciseDraftValues(
      original: original,
      type: 'type_translation',
      publicationState: PublicationState.draft,
      prompt: 'new',
      accepted: 'cat',
      imageAsset: 'new.png',
      selectedSharedSource: source,
      attachSelectedSharedSource: attach,
    );
    final preview = ExerciseDraftBuilder.build(
      values(attach: false),
    ).candidate!;
    final saved = ExerciseDraftBuilder.build(values(attach: true)).candidate!;
    expect(preview.promptElements.last.sharedImageSource, isNull);
    expect(saved.promptElements.last.sharedImageSource?.id, source.id);
    expect(original.promptElements.last.asset, 'old.png');
  });

  test(
    'script-recognition controller candidate crosses the result boundary unchanged',
    () {
      final original = _choice();
      final result = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: original,
          type: 'script_recognition',
          publicationState: PublicationState.draft,
          scriptCandidate: original,
        ),
      );
      expect(identical(result.candidate, original), isTrue);
      expect(result.error, isNull);
    },
  );

  test('missing script snapshot returns a typed field error', () {
    final result = ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: _choice(),
        type: 'script_recognition',
        publicationState: PublicationState.draft,
      ),
    );
    expect(result.candidate, isNull);
    expect(result.error?.field, ExerciseDraftField.scriptOptions);
    expect(result.error?.code, ExerciseDraftErrorCode.scriptCandidateMissing);
  });
}
