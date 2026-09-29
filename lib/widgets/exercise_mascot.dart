import 'package:flutter/material.dart';

import '../services/exercise_mascot_policy.dart';

/// A mascot beside the sentence of a learner exercise (Build 256
/// Revision 9): decoration only, invisible to screen readers and to taps.
class ExerciseMascot extends StatelessWidget {
  const ExerciseMascot({super.key, required this.asset, required this.size});

  /// Test seam: the suite turns mascots off in
  /// `test/flutter_test_config.dart`, so that no other test depends on a
  /// random picture; the mascot tests turn them on.
  static bool enabled = true;

  final String asset;
  final double size;

  /// [child] with the mascot on its leading side, vertically centred.
  static Widget beside({
    required String asset,
    required double size,
    required Widget child,
  }) => Row(
    key: const Key('exercise-mascot-row'),
    children: [
      ExerciseMascot(asset: asset, size: size),
      const SizedBox(width: ExerciseMascotPolicy.gap),
      Expanded(child: child),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // The pictures are up to 1254 pixels wide: decode them at the size
    // shown, as the Welcome Wizard does.
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const Key('exercise-mascot'),
          dimension: size,
          child: Image.asset(
            asset,
            key: ValueKey('exercise-mascot-$asset'),
            fit: BoxFit.contain,
            cacheWidth: cacheWidth,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
