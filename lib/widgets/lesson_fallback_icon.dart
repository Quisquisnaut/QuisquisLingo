import 'package:flutter/material.dart';

import '../models/course_models.dart';

/// The canonical fallback shown only when a Lesson has no explicit theme icon.
class LessonFallbackIcon extends StatelessWidget {
  const LessonFallbackIcon({
    super.key,
    required this.style,
    required this.number,
    this.size = 84,
    this.monochromeKey,
    this.coloredKey,
  });

  final LessonFallbackIconStyle style;
  final int number;
  final double size;
  final Key? monochromeKey;
  final Key? coloredKey;

  static const originalColors = [
    Color(0xFF2F6F8F),
    Color(0xFF7A5C99),
    Color(0xFF2F7D68),
    Color(0xFF9A5D35),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (style == LessonFallbackIconStyle.monochrome) {
      return SizedBox.square(
        key: monochromeKey,
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
    return SizedBox.square(
      key: coloredKey,
      dimension: size,
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                for (var row = 0; row < 2; row++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var column = 0; column < 2; column++)
                          Expanded(
                            child: ColoredBox(
                              color:
                                  originalColors[(number +
                                          row * 2 +
                                          column -
                                          1) %
                                      originalColors.length],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
