import 'package:flutter/material.dart';

/// One image badge such as `QQL`, `DEVICE`, `COURSE` or `IN USE`, with the
/// explanation shown as its tooltip.
typedef ImageBadge = ({String label, String message});

/// Small, low-emphasis badges laid over an image's bottom-left corner, one row
/// per badge. The translucent backing keeps the text legible on any image
/// while letting the image show through.
class ImageBadges extends StatelessWidget {
  const ImageBadges(this.badges, {super.key, this.fontSize = 8});

  final List<ImageBadge> badges;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final badge in badges)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Tooltip(
              message: badge.message,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
