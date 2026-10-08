import 'dart:math';

import '../models/world_flag_entity.dart';
import 'world_flag_repository.dart';

class FlagGameQuestion {
  final WorldFlagEntity target;
  final List<WorldFlagEntity> options;

  const FlagGameQuestion({required this.target, required this.options});

  int get correctOptionIndex =>
      options.indexWhere((option) => option.id == target.id);
}

class FlagGameEngine {
  static const questionCount = 12;
  static const optionCount = 5;

  final Random _random;

  FlagGameEngine({Random? random}) : _random = random ?? Random.secure();

  List<FlagGameQuestion> createGame({
    required List<WorldFlagEntity> entities,
    required FlagGameMode mode,
    List<String> previousTargetOrder = const [],
  }) {
    final pool = WorldFlagRepository.poolFor(entities, mode);
    if (pool.length < questionCount || pool.length < optionCount) {
      throw StateError('Flag Game pool is too small');
    }
    final targets = [...pool]..shuffle(_random);
    var selected = targets.take(questionCount).toList();
    if (_matchesPrevious(selected, previousTargetOrder) &&
        pool.length > questionCount) {
      selected = [...selected.skip(1), targets[questionCount]];
    }
    return List.unmodifiable([
      for (final target in selected)
        FlagGameQuestion(
          target: target,
          options: _optionsFor(target: target, pool: pool),
        ),
    ]);
  }

  bool _matchesPrevious(
    List<WorldFlagEntity> selected,
    List<String> previousTargetOrder,
  ) =>
      previousTargetOrder.length == selected.length &&
      List.generate(
        selected.length,
        (index) => selected[index].id == previousTargetOrder[index],
      ).every((same) => same);

  List<WorldFlagEntity> _optionsFor({
    required WorldFlagEntity target,
    required List<WorldFlagEntity> pool,
  }) {
    final allowed = pool
        .where(
          (candidate) =>
              candidate.id != target.id &&
              !target.avoidAsDistractorWith.contains(candidate.id) &&
              !candidate.avoidAsDistractorWith.contains(target.id),
        )
        .toList();
    allowed.shuffle(_random);
    allowed.sort((left, right) {
      final bySimilarity = _similarity(
        target,
        right,
      ).compareTo(_similarity(target, left));
      return bySimilarity;
    });
    final distractors = allowed.take(optionCount - 1).toList();
    if (distractors.length != optionCount - 1) {
      throw StateError('Not enough fair Flag Game distractors');
    }
    final options = <WorldFlagEntity>[...distractors];
    options.insert(_random.nextInt(optionCount), target);
    return List.unmodifiable(options);
  }

  int similarityScore(WorldFlagEntity left, WorldFlagEntity right) =>
      _similarity(left, right);

  int _similarity(WorldFlagEntity left, WorldFlagEntity right) {
    var score = 0;
    for (final tag in left.distractorTags) {
      if (!right.distractorTags.contains(tag)) continue;
      score += tag.startsWith('rir:') || tag.startsWith('region:') ? 3 : 1;
    }
    return score;
  }
}
