import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/lesson_color_palette.dart';

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
  /// All fallback Lessons now use the single Lesson-colour presentation.
  final LessonFallbackIconStyle? style;

  /// The Lesson's one-based position in its Course: it also picks the
  /// Lesson's colour (Build 261 Revision 8).
  final int number;
  final double size;
  final Key? monochromeKey;
  final Key? coloredKey;

  @override
  Widget build(BuildContext context) {
    final colors = LessonColorPalette.of(
      number - 1,
      Theme.of(context).brightness,
    );
    return SizedBox.square(
      key: monochromeKey ?? coloredKey,
      dimension: size,
      child: CircleAvatar(
        backgroundColor: colors.solid,
        child: Text(
          '$number',
          style: TextStyle(
            color: colors.onSolid,
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
