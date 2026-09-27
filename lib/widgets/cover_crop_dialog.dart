import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Chooses the square of a picture that becomes a Course cover (Build 255
/// Revision 7).
///
/// The square starts centred and as large as the picture allows, which is
/// what a cover shows when nobody crops it. Drag the square to move it; drag
/// its corner, or use Size, to make it smaller or larger. Returns the square
/// in the picture's own pixels, or null when the author cancels.
Future<Rect?> showCoverCropDialog(
  BuildContext context, {
  required Uint8List bytes,
  required int width,
  required int height,
}) => showDialog<Rect>(
  context: context,
  builder: (_) => CoverCropDialog(bytes: bytes, width: width, height: height),
);

class CoverCropDialog extends StatefulWidget {
  const CoverCropDialog({
    super.key,
    required this.bytes,
    required this.width,
    required this.height,
  });

  /// The picture, as read.
  final Uint8List bytes;

  /// Its size in pixels.
  final int width;
  final int height;

  @override
  State<CoverCropDialog> createState() => _CoverCropDialogState();
}

class _CoverCropDialogState extends State<CoverCropDialog> {
  /// The largest square: the picture's shorter side.
  late final double _maxSide = math.min(widget.width, widget.height).toDouble();

  /// Up to five times closer than the whole picture.
  late final double _minSide = math.max(1.0, _maxSide / 5);

  late Rect _square = _centred();

  Rect _centred() => Rect.fromLTWH(
    (widget.width - _maxSide) / 2,
    (widget.height - _maxSide) / 2,
    _maxSide,
    _maxSide,
  );

  /// A square of [side] at [topLeft], kept inside the picture.
  Rect _within(Offset topLeft, double side) {
    final size = side.clamp(_minSide, _maxSide);
    return Rect.fromLTWH(
      topLeft.dx.clamp(0.0, widget.width - size),
      topLeft.dy.clamp(0.0, widget.height - size),
      size,
      size,
    );
  }

  void _move(Offset delta) =>
      setState(() => _square = _within(_square.topLeft + delta, _square.width));

  /// Size keeps the square's centre.
  void _resize(double side) => setState(
    () => _square = _within(_square.center - Offset(side / 2, side / 2), side),
  );

  /// The corner keeps the opposite corner where it is.
  void _stretch(double grow) =>
      setState(() => _square = _within(_square.topLeft, _square.width + grow));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The dialog never scrolls, or scrolling would take the square's drags:
    // the picture gets the height the window leaves.
    final pictureHeight = (MediaQuery.sizeOf(context).height - 360).clamp(
      120.0,
      300.0,
    );
    return AlertDialog(
      key: const Key('cover-crop-dialog'),
      title: const Text('Crop the cover'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Drag the square to choose what the cover shows. Make it '
              'smaller to zoom in.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.min(
                  constraints.maxWidth / widget.width,
                  pictureHeight / widget.height,
                );
                final shown = Size(widget.width * scale, widget.height * scale);
                final square = Rect.fromLTWH(
                  _square.left * scale,
                  _square.top * scale,
                  _square.width * scale,
                  _square.height * scale,
                );
                final decodeWidth =
                    (shown.width * MediaQuery.devicePixelRatioOf(context))
                        .ceil();
                return Center(
                  child: SizedBox.fromSize(
                    size: shown,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.memory(
                            widget.bytes,
                            fit: BoxFit.fill,
                            // Bound decoding to the size shown.
                            cacheWidth: decodeWidth < widget.width
                                ? decodeWidth
                                : null,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) =>
                                ColoredBox(
                                  color: scheme.surfaceContainerHighest,
                                ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: _OutsideShade(square)),
                          ),
                        ),
                        Positioned.fromRect(
                          rect: square,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.move,
                            child: GestureDetector(
                              key: const Key('cover-crop-square'),
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) =>
                                  _move(details.delta / scale),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: square.right - 24,
                          top: square.bottom - 24,
                          width: 24,
                          height: 24,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeDownRight,
                            child: GestureDetector(
                              key: const Key('cover-crop-corner'),
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) => _stretch(
                                (details.delta.dx + details.delta.dy) /
                                    2 /
                                    scale,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: scheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.open_in_full,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Size'),
                Expanded(
                  child: Slider(
                    key: const Key('cover-crop-size'),
                    min: _minSide,
                    max: _maxSide,
                    value: _square.width.clamp(_minSide, _maxSide),
                    onChanged: _minSide < _maxSide ? _resize : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cover-crop-reset'),
          onPressed: () => setState(() => _square = _centred()),
          child: const Text('Reset'),
        ),
        TextButton(
          key: const Key('cover-crop-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('cover-crop-confirm'),
          onPressed: () => Navigator.pop(context, _square),
          child: const Text('Use this square'),
        ),
      ],
    );
  }
}

/// Dims the picture outside the square.
class _OutsideShade extends CustomPainter {
  const _OutsideShade(this.square);

  final Rect square;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(square),
      Paint()..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(_OutsideShade oldDelegate) => oldDelegate.square != square;
}
