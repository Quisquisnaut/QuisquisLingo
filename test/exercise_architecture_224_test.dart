import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_interoperability.dart';
import 'package:quisquislingo_app/models/normalized_import_exercise.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  test('every active QQL type is registered and maps to a canonical model', () {
    expect(
      ExercisePresetRegistry.presets.map((preset) => preset.id).toSet(),
      CourseAuditService.supportedTypes,
    );
    expect(
      ExercisePresetRegistry.presets.map((preset) => preset.model).toSet(),
      CanonicalExerciseModel.values.toSet(),
    );
    expect(
      ExercisePresetRegistry.presets
          .where((preset) => preset.model == CanonicalExerciseModel.select)
          .length,
      greaterThan(1),
    );
    expect(
      ExercisePresetRegistry.presets
          .where((preset) => preset.model == CanonicalExerciseModel.arrange)
          .map((preset) => preset.id),
      containsAll(['word_order', 'build_translation', 'image_word']),
    );
  });

  test(
    'presets are grouped and author names do not expose canonical names',
    () {
      expect(ExerciseCategory.values, hasLength(6));
      for (final preset in ExercisePresetRegistry.presets) {
        expect(preset.name.toLowerCase(), isNot(preset.model.name));
        expect(preset.description.trim(), isNotEmpty);
      }
    },
  );

  test('all required interoperability survey patterns have mappings', () {
    final mapped = ExerciseInteroperabilityCatalog.mappings
        .map((mapping) => mapping.sourcePattern)
        .toSet();
    expect(mapped, containsAll(ExerciseInteroperabilityCatalog.externalSetA));
    expect(mapped, containsAll(ExerciseInteroperabilityCatalog.externalSetB));
    expect(
      mapped,
      containsAll(ExerciseInteroperabilityCatalog.broaderPatterns),
    );
    expect(
      ExerciseInteroperabilityCatalog.mappings
          .where((mapping) => mapping.sourcePattern == 'PickOneAudio')
          .single
          .status,
      ImportabilityStatus.unsupported,
    );
  });

  test('normalized imports stop source taxonomy before canonical runtime', () {
    const normalized = NormalizedImportExercise(
      sourceType: 'source-specific-select',
      presetId: 'choice',
      prompt: [PromptElement(type: 'text', text: 'Question')],
      interaction: ExerciseInteraction(
        kind: 'select',
        items: [
          ExerciseItem(
            id: 'answer_a',
            content: [PromptElement(type: 'text', text: 'A')],
          ),
          ExerciseItem(
            id: 'answer_b',
            content: [PromptElement(type: 'text', text: 'B')],
          ),
        ],
      ),
      evaluation: ExerciseEvaluation(
        kind: 'selected_items',
        correctItemIds: ['answer_a'],
      ),
    );
    final exercise = normalized.toExercise(
      stableId: 'stable_external_id',
      updatedAt: DateTime.utc(2026, 9, 4),
    );
    expect(exercise.id, 'stable_external_id');
    expect(exercise.interaction.kind, 'select');
    expect(
      exercise.toJson().toString(),
      isNot(contains(normalized.sourceType)),
    );
  });

  test(
    'structured content sequence composes presentation and assessment blocks',
    () {
      final presentation = LearningContent(
        id: 'narration',
        kind: 'presentation',
        presentation: const Presentation(
          content: [
            PromptElement(
              role: 'narration',
              type: 'text',
              text: 'A story begins.',
            ),
          ],
        ),
      );
      final assessment = LearningContent.fromExercise(
        Exercise(
          id: 'question',
          type: 'choice',
          prompt: 'What happened?',
          question: '',
          answers: const ['A', 'B'],
          correct: 0,
          tts: null,
          accepted: const [],
          tokens: const [],
          orderAnswer: const [],
          pairs: const [],
          hint: '',
          icons: const [],
        ),
      );
      final round = LearningRound(
        id: 'story_sequence',
        title: 'Sequence',
        visualType: 'story',
        content: [presentation, assessment],
      );
      expect(round.content.map((content) => content.id), [
        'narration',
        'question',
      ]);
      expect(
        round.exercises
            .where((exercise) => exercise.type != 'flashcard')
            .single
            .id,
        'question',
      );
      expect(LearningRound.fromJson(round.toJson()).content, hasLength(2));
    },
  );
}
