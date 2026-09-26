import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shows a picture enlarged in a dialog with a Close button, fitted to the
/// window. Course images in Courses and Course Info and the flags of the Flag
/// Game all open through it.
///
/// [builder] draws the picture into a box [aspectRatio] wide per unit of
/// height; it receives that box's width. [closeTooltip] defaults to the
/// Material "Close" of the dialog; a caller with its own language (Course
/// Info) passes its own.
Future<void> showEnlargedImage(
  BuildContext context, {
  required Key dialogKey,
  required Key closeKey,
  required Widget Function(BuildContext context, double width) builder,
  String? title,
  double aspectRatio = 1,
  String? closeTooltip,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) {
    final viewport = MediaQuery.sizeOf(dialogContext);
    final width = math.max(
      96.0,
      math.min(
        520.0,
        math.min(viewport.width - 80, (viewport.height - 180) * aspectRatio),
      ),
    );
    return Dialog(
      key: dialogKey,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width,
              child: Row(
                children: [
                  Expanded(
                    child: title == null
                        ? const SizedBox.shrink()
                        : Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              dialogContext,
                            ).textTheme.titleMedium,
                          ),
                  ),
                  IconButton(
                    key: closeKey,
                    tooltip:
                        closeTooltip ??
                        MaterialLocalizations.of(
                          dialogContext,
                        ).closeButtonTooltip,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: width,
              height: width / aspectRatio,
              child: builder(dialogContext, width),
            ),
          ],
        ),
      ),
    );
  },
);
