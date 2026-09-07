import 'package:flutter/material.dart';

import '../models/course_models.dart';

/// The canonical fallback shown only when a Lesson has no explicit theme icon.
class LessonFallbackIcon extends StatelessWidget {
  const LessonFallbackIcon({
    super.key,
    this.style,
    required this.number,
    this.size = 84,
    this.monochromeKey,
    this.coloredKey,
  });

  /// Retained so legacy callers and persisted values continue to load safely.
  /// All fallback Lessons now use the single theme-colored presentation.
  final LessonFallbackIconStyle? style;
  final int number;
  final double size;
  final Key? monochromeKey;
  final Key? coloredKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox.square(
      key: monochromeKey ?? coloredKey,
      dimension: size,
      child: CircleAvatar(
        backgroundColor: colors.primaryContainer,
        child: Text(
          '$number',
          style: TextStyle(
            color: colors.onPrimaryContainer,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
