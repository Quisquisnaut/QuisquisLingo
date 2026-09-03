import 'dart:math';

import '../models/exercise_authoring.dart';

enum ExerciseWizardCriterion {
  balanced('Balanced mix'),
  random('Random mix'),
  byCategory('By category'),
  selectedTypes('Selected exercise types'),
  repeatPattern('Repeat a pattern');

  const ExerciseWizardCriterion(this.label);
  final String label;
}

class ExerciseCreationPlan {
  const ExerciseCreationPlan(this.presetIds);

  final List<String> presetIds;

  List<ExercisePreset> get presets => [
    for (final id in presetIds) ExercisePresetRegistry.byId(id)!,
  ];
}

class ExerciseCreationPlanner {
  const ExerciseCreationPlanner();

  static const int maximumExerciseCount = 30;

  ExerciseCreationPlan create({
    required int count,
    required ExerciseWizardCriterion criterion,
    List<ExerciseCategory> categories = const [],
    List<String> presetIds = const [],
    List<String> pattern = const [],
    int randomSeed = 0,
  }) {
    if (count < 1 || count > maximumExerciseCount) {
      throw ArgumentError.value(
        count,
        'count',
        'Choose between 1 and $maximumExerciseCount exercises.',
      );
    }
    final selected = switch (criterion) {
      ExerciseWizardCriterion.balanced => _balanced(count),
      ExerciseWizardCriterion.random => _random(count, randomSeed),
      ExerciseWizardCriterion.byCategory => _cycle(
        count,
        _presetsForCategories(categories),
        'Choose at least one category.',
      ),
      ExerciseWizardCriterion.selectedTypes => _cycle(
        count,
        _validatedPresets(presetIds),
        'Choose at least one exercise type.',
      ),
      ExerciseWizardCriterion.repeatPattern => _cycle(
        count,
        _validatedPresets(pattern),
        'Build a pattern containing at least one exercise type.',
      ),
    };
    return ExerciseCreationPlan(List.unmodifiable(selected));
  }

  List<String> _balanced(int count) {
    final categories = ExerciseCategory.values;
    final offsets = <ExerciseCategory, int>{};
    final out = <String>[];
    for (var i = 0; i < count; i++) {
      final category = categories[i % categories.length];
      final options = ExercisePresetRegistry.inCategory(category);
      final offset = offsets[category] ?? 0;
      var id = options[offset % options.length].id;
      offsets[category] = offset + 1;
      if (out.isNotEmpty && out.last == id && options.length > 1) {
        id = options[(offset + 1) % options.length].id;
        offsets[category] = offset + 2;
      }
      out.add(id);
    }
    return out;
  }

  List<String> _random(int count, int seed) {
    final random = Random(seed);
    final pool = ExercisePresetRegistry.presets;
    final out = <String>[];
    for (var i = 0; i < count; i++) {
      var index = random.nextInt(pool.length);
      if (out.isNotEmpty && pool.length > 1 && pool[index].id == out.last) {
        index = (index + 1) % pool.length;
      }
      out.add(pool[index].id);
    }
    return out;
  }

  List<String> _presetsForCategories(List<ExerciseCategory> categories) {
    final unique = categories.toSet();
    return [
      for (final category in ExerciseCategory.values)
        if (unique.contains(category))
          for (final preset in ExercisePresetRegistry.inCategory(category))
            preset.id,
    ];
  }

  List<String> _validatedPresets(List<String> ids) {
    final out = <String>[];
    for (final id in ids) {
      if (ExercisePresetRegistry.byId(id) == null) {
        throw ArgumentError.value(id, 'presetIds', 'Unknown exercise preset.');
      }
      out.add(id);
    }
    return out;
  }

  List<String> _cycle(int count, List<String> source, String emptyMessage) {
    if (source.isEmpty) throw ArgumentError(emptyMessage);
    return [for (var i = 0; i < count; i++) source[i % source.length]];
  }
}
