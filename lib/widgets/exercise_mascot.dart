import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../models/exercise_features.dart';
import '../services/exercise_mascot_policy.dart';
import '../services/playback_on_request.dart';

/// The room a Round page has for the mascot of its exercise: beside which
/// sentence, and how large (Build 271 Revision 5; before, the Round screen
/// measured this and wrote the result down while it drew).
class ExerciseMascotRoom {
  const ExerciseMascotRoom({required this.anchor, required this.size});

  /// The sentence the mascot sits beside.
  final ExerciseMascotAnchor anchor;

  /// The mascot's width and height.
  final double size;

  /// The room the Round page in [context] has for [exercise]'s mascot, or
  /// null when it shows none. [ExerciseMascotPolicy.anchorFor] names the
  /// sentence (rules 1 and 2); rule 3 is measured here, with the text style
  /// and the margins the page gives that sentence: the mascot is drawn only
  /// when the sentence keeps room beside it on this screen.
  ///
  /// [promptAsInstruction]: the page draws the authored prompt as its
  /// instruction line. With [only], the answer is null at once unless the
  /// sentence is that one (a renderer asks about the sentence it draws).
  ///
  /// It reads [context] and changes nothing: the same page gives the same
  /// answer, however often it is asked.
  static ExerciseMascotRoom? of(
    BuildContext context,
    Exercise exercise, {
    required bool promptAsInstruction,
    ExerciseMascotAnchor? only,
    bool sameLanguage = false,
  }) {
    final anchor = ExerciseMascotPolicy.anchorFor(exercise);
    if (anchor == ExerciseMascotAnchor.none) return null;
    if (only != null && anchor != only) return null;
    final media = MediaQuery.of(context);
    // The Round body is a ListView with 20 pixels on each side.
    final contentWidth = media.size.width - media.padding.horizontal - 40;
    final size = ExerciseMascotPolicy.mascotSize(contentWidth);
    final text = Theme.of(context).textTheme;
    final (TextStyle? style, double reserved) = switch (anchor) {
      // A translation question keeps room for its audio button.
      ExerciseMascotAnchor.question => (
        text.headlineSmall,
        ExerciseFeatures(exercise).isTranslationChoice ? 48.0 : 0.0,
      ),
      // A sentence the learner may hear keeps room for its speaker (Build
      // 274 Revision 2, found by the independent review).
      ExerciseMascotAnchor.prompt => (
        promptAsInstruction
            ? text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
            : text.titleMedium,
        !promptAsInstruction &&
                PlaybackOnRequest.promptText(
                      ExerciseFeatures(exercise),
                      sameLanguage: sameLanguage,
                    ) !=
                    null
            ? 48.0
            : 0.0,
      ),
      // The gapped sentence sits in a panel with padding on both sides.
      ExerciseMascotAnchor.gappedText => (
        exercise.primitive == ExercisePrimitive.input
            ? text.bodyLarge
            : text.titleMedium,
        28.0,
      ),
      ExerciseMascotAnchor.playButton ||
      ExerciseMascotAnchor.none => (null, 0.0),
    };
    final textWidth = contentWidth - size - ExerciseMascotPolicy.gap - reserved;
    int? lines;
    final sentence = ExerciseMascotPolicy.sentenceAt(exercise, anchor);
    if (sentence != null) {
      if (textWidth <= 0) return null;
      final painter = TextPainter(
        text: TextSpan(text: sentence, style: style),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
      )..layout(maxWidth: textWidth);
      lines = painter.computeLineMetrics().length;
      painter.dispose();
    }
    if (!ExerciseMascotPolicy.fits(
      textWidth: textWidth,
      lines: lines,
      viewportHeight: media.size.height,
    )) {
      return null;
    }
    return ExerciseMascotRoom(anchor: anchor, size: size);
  }
}

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
