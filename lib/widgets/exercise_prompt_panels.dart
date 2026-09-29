import 'package:flutter/material.dart';

import '../models/exercise_features.dart';
import 'portable_exercise_image.dart';

/// The panels a Select exercise shows above its question, drawn from the
/// prompt elements' roles: context audio (a button when [onPlayContextAudio]
/// is given), context text, dialogue turns, a passage or situation, and
/// character specimens. Shared by the Round and Duel screens so that both
/// present the same exercise the same way (Build 256, plan A.10).
class ExercisePromptPanels extends StatelessWidget {
  const ExercisePromptPanels({
    super.key,
    required this.features,
    required this.panelColor,
    this.onPlayContextAudio,
    this.onPlayDialogue,
  });

  final ExerciseFeatures features;
  final Color panelColor;

  /// Plays the context audio; null hides the button (for instance after the
  /// learner has answered).
  final VoidCallback? onPlayContextAudio;

  /// Reads the dialogue lines aloud (Read and answer, Build 256 Revision 7
  /// fourth follow-up); null hides the button.
  final VoidCallback? onPlayDialogue;

  @override
  Widget build(BuildContext context) {
    final f = features;
    final contextAudio = f.contextAudio.trim();
    final passage = f.passageText.trim().isNotEmpty
        ? f.passageText
        : f.situationText;
    BoxDecoration panel([double radius = 16]) => BoxDecoration(
      color: panelColor,
      borderRadius: BorderRadius.circular(radius),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (contextAudio.isNotEmpty) ...[
          FilledButton.tonalIcon(
            onPressed: onPlayContextAudio,
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Play context audio'),
          ),
          const SizedBox(height: 14),
        ],
        if (f.contextText.trim().isNotEmpty) ...[
          Container(
            key: const Key('contextual-comprehension-text'),
            padding: const EdgeInsets.all(14),
            decoration: panel(),
            child: Text(f.contextText),
          ),
          const SizedBox(height: 12),
        ],
        if (f.dialogueTurns.isNotEmpty) ...[
          if (onPlayDialogue != null) ...[
            FilledButton.tonalIcon(
              key: const Key('contextual-comprehension-dialogue-play'),
              onPressed: onPlayDialogue,
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Play dialogue'),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            key: const Key('contextual-comprehension-dialogue'),
            padding: const EdgeInsets.all(14),
            decoration: panel(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final turn in f.dialogueTurns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${turn.speaker}: ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: turn.text),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (passage.trim().isNotEmpty) ...[
          Container(
            key: const Key('exercise-passage'),
            padding: const EdgeInsets.all(14),
            decoration: panel(),
            child: Text(passage, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(height: 16),
        ],
        if (f.characterImages.isNotEmpty) ...[
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final image in f.characterImages)
                PortableExerciseImage(
                  asset: image.asset,
                  width: 128,
                  height: 128,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
