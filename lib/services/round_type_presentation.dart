import 'package:flutter/material.dart';

import '../models/course_models.dart';

/// Learner-facing identity for a Round. The order number is presentation only.
abstract final class RoundTypePresentation {
  static String label(RoundType type) => switch (type) {
    RoundType.discover => 'Discover',
    RoundType.practice => 'Practice',
    RoundType.sequence => 'Sequence',
    RoundType.listening => 'Listen',
    RoundType.reading => 'Read',
    RoundType.story => 'Story',
    RoundType.flashcard => 'FlashCard',
    RoundType.test => 'Test',
    RoundType.timed => 'Timed',
    RoundType.speak => 'Speak',
  };

  static IconData icon(RoundType type) => switch (type) {
    RoundType.discover => Icons.lightbulb_outline,
    RoundType.practice => Icons.school_outlined,
    RoundType.sequence => Icons.linear_scale_outlined,
    RoundType.listening => Icons.headphones_outlined,
    RoundType.reading => Icons.description_outlined,
    RoundType.story => Icons.forum_outlined,
    RoundType.flashcard => Icons.style_outlined,
    RoundType.test => Icons.fact_check_outlined,
    RoundType.timed => Icons.timer_outlined,
    RoundType.speak => Icons.mic_none_outlined,
  };

  static String description(RoundType type) => switch (type) {
    RoundType.discover =>
      'Introduce words, concepts, examples or explanations; mix in guided exercises if useful.',
    RoundType.practice =>
      'Practise familiar material in a normally random order, with immediate feedback.',
    RoundType.sequence => 'Play content in the exact order you define.',
    RoundType.listening =>
      'Every required exercise must depend on audio. Only compatible choices can be published.',
    RoundType.reading =>
      'Every required exercise must depend on reading. Only compatible choices can be published.',
    RoundType.story =>
      'Build an ordered narrative with dialogue, content and comprehension exercises.',
    RoundType.flashcard =>
      'Use cards only, one at a time, without correctness grading.',
    RoundType.test =>
      'Answer every question before seeing feedback and results.',
    RoundType.timed =>
      'Complete the exercises before the countdown ends to earn an On Time bonus.',
    RoundType.speak => 'Coming soon. Spoken production will be essential.',
  };

  static String prefix(
    RoundType type,
    int oneBasedPosition,
    RoundNumberingMode mode, {
    String customPrefix = '',
  }) {
    final typeLabel = label(type);
    return switch (mode) {
      RoundNumberingMode.off => typeLabel,
      RoundNumberingMode.roundAndNumber =>
        'Round $oneBasedPosition · $typeLabel',
      RoundNumberingMode.numberOnly => '$oneBasedPosition · $typeLabel',
      RoundNumberingMode.customAndNumber =>
        '${customPrefix.trim()} $oneBasedPosition · $typeLabel',
    };
  }

  static String title(
    LearningRound round,
    int oneBasedPosition,
    RoundNumberingMode mode, {
    String customPrefix = '',
  }) {
    final base = prefix(
      round.roundType,
      oneBasedPosition,
      mode,
      customPrefix: customPrefix,
    );
    final authored = authoredTitle(round);
    return authored.isEmpty ? base : '$base · $authored';
  }

  static String authoredTitle(LearningRound round) {
    if (round.isStory || round.isSequence) return round.storyTitle;
    return round.title.trim();
  }
}
