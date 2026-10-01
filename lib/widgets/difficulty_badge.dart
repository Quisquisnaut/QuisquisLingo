import 'package:flutter/material.dart';

import '../services/exercise_difficulty.dart';

/// A small badge with an exercise's difficulty level (Build 260 Revision 5):
/// four bars, as many filled as the level, and the level's name in the
/// tooltip. A Round shows the average of its exercises instead
/// ([DifficultyBadge.average]).
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required DifficultyLevel this.level})
    : average = null;

  const DifficultyBadge.average({super.key, required double this.average})
    : level = null;

  final DifficultyLevel? level;
  final double? average;

  String get _tooltip => level != null
      ? 'Difficulty ${level!.value} of 4: ${level!.label}'
      : 'Average difficulty ${average!.toStringAsFixed(1)} of 4';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = level?.value ?? average!.round();
    return Tooltip(
      message: _tooltip,
      child: Semantics(
        label: _tooltip,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var bar = 1; bar <= 4; bar++)
                Container(
                  width: 4,
                  height: 4.0 + bar * 3,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: bar <= filled
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              if (average != null) ...[
                const SizedBox(width: 4),
                Text(
                  average!.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
