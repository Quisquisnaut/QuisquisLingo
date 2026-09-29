import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/services/exercise_creation_planner.dart';

void main() {
  const planner = ExerciseCreationPlanner();

  test('count validation rejects zero and the documented upper overflow', () {
    expect(
      () =>
          planner.create(count: 0, criterion: ExerciseWizardCriterion.balanced),
      throwsArgumentError,
    );
    expect(
      () => planner.create(
        count: ExerciseCreationPlanner.maximumExerciseCount + 1,
        criterion: ExerciseWizardCriterion.balanced,
      ),
      throwsArgumentError,
    );
  });

  test(
    'Balanced mix has exactly N registered entries without adjacent repeats',
    () {
      final plan = planner.create(
        count: 30,
        criterion: ExerciseWizardCriterion.balanced,
      );
      expect(plan.presetIds, hasLength(30));
      expect(
        plan.presetIds,
        everyElement(
          predicate<String>((id) => ExercisePresetRegistry.byId(id) != null),
        ),
      );
      for (var i = 1; i < plan.presetIds.length; i++) {
        expect(plan.presetIds[i], isNot(plan.presetIds[i - 1]));
      }
    },
  );

  test('Random mix is reproducible for a seed', () {
    ExerciseCreationPlan make(int seed) => planner.create(
      count: 20,
      criterion: ExerciseWizardCriterion.random,
      randomSeed: seed,
    );
    expect(make(17).presetIds, make(17).presetIds);
    expect(make(17).presetIds, isNot(make(18).presetIds));
  });

  test(
    'category, selected-type and repeated-pattern criteria use the registry',
    () {
      final category = planner.create(
        count: 9,
        criterion: ExerciseWizardCriterion.byCategory,
        categories: const [ExerciseCategory.vocabulary],
      );
      expect(category.presetIds.toSet(), {
        'translation_choice_to_target',
        'translation_choice_to_source',
        'type_translation_to_target',
        'type_translation_to_source',
        'build_translation_to_target',
        'build_translation_to_source',
        'word_match',
        'super_match',
        'flashcard',
      });

      final selected = planner.create(
        count: 5,
        criterion: ExerciseWizardCriterion.selectedTypes,
        presetIds: const ['choice_target', 'word_match'],
      );
      expect(selected.presetIds, [
        'choice_target',
        'word_match',
        'choice_target',
        'word_match',
        'choice_target',
      ]);

      final pattern = planner.create(
        count: 7,
        criterion: ExerciseWizardCriterion.repeatPattern,
        pattern: const [
          'choice_target',
          'type_translation_to_target',
          'word_match',
        ],
      );
      expect(pattern.presetIds, [
        'choice_target',
        'type_translation_to_target',
        'word_match',
        'choice_target',
        'type_translation_to_target',
        'word_match',
        'choice_target',
      ]);
    },
  );
}
