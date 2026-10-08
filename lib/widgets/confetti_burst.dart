import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A short burst of confetti over the whole screen, fired from the two lower
/// corners (Build 261 Revision 0, owner decision of 1 October 2026: when the
/// weekly XP goal is reached; Build 264 Revision 3 adds a won Duel and a
/// passed Test Round). It has its own painter and no package,
/// never takes a tap and is hidden from screen readers. Callers show it only
/// when [allowed]: Animations are on in Do Not Disturb and the system does
/// not ask for reduced motion.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.duration = const Duration(seconds: 2),
    this.pieces = 90,
    this.seed = 261,
  });

  final Duration duration;
  final int pieces;

  /// The same seed draws the same burst, so tests see a fixed picture.
  final int seed;

  static bool allowed(
    BuildContext context, {
    required bool animationsEnabled,
  }) =>
      animationsEnabled &&
      MediaQuery.maybeOf(context)?.disableAnimations != true;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final List<_Piece> _pieces = _Piece.burst(widget.pieces, widget.seed);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfettiPainter(
            pieces: _pieces,
            progress: _controller,
            seconds: widget.duration.inMilliseconds / 1000,
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
}

const _confettiColors = [
  Color(0xFFE53935),
  Color(0xFFFFB300),
  Color(0xFF43A047),
  Color(0xFF1E88E5),
  Color(0xFF8E24AA),
  Color(0xFFFF7043),
  Color(0xFF00ACC1),
];

/// One piece of paper. Speeds are fractions of the screen per second, so the
/// burst looks the same on a phone and on a desktop window.
class _Piece {
  const _Piece({
    required this.fromLeft,
    required this.speedX,
    required this.speedY,
    required this.width,
    required this.height,
    required this.turn,
    required this.spin,
    required this.flip,
    required this.wobble,
    required this.color,
  });

  final bool fromLeft;
  final double speedX;
  final double speedY;
  final double width;
  final double height;
  final double turn;
  final double spin;
  final double flip;
  final double wobble;
  final Color color;

  static List<_Piece> burst(int count, int seed) {
    final random = math.Random(seed);
    double between(double low, double high) =>
        low + random.nextDouble() * (high - low);
    return List.generate(
      count,
      (index) => _Piece(
        fromLeft: index.isEven,
        speedX: between(.25, .75),
        speedY: between(.9, 1.5),
        width: between(7, 12),
        height: between(4, 7),
        turn: between(0, math.pi * 2),
        spin: between(-8, 8),
        flip: between(4, 10),
        wobble: between(0, math.pi * 2),
        color: _confettiColors[random.nextInt(_confettiColors.length)],
      ),
      growable: false,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.seconds,
  }) : super(repaint: progress);

  final List<_Piece> pieces;
  final Animation<double> progress;
  final double seconds;

  static const _gravity = 1.3;
  static const _drag = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final s = t * seconds;
    final opacity = t < .7 ? 1.0 : 1 - (t - .7) / .3;
    final travel = (1 - math.exp(-_drag * s)) / _drag;
    final paint = Paint()..style = PaintingStyle.fill;
    for (final piece in pieces) {
      final dx = piece.speedX * travel * size.width;
      final x =
          (piece.fromLeft ? dx : size.width - dx) +
          math.sin(s * 3 + piece.wobble) * 6;
      final y =
          size.height -
          piece.speedY * s * size.height +
          _gravity / 2 * s * s * size.height;
      if (y > size.height + 20) continue;
      paint.color = piece.color.withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(piece.turn + piece.spin * s)
        ..scale(1, math.cos(piece.flip * s))
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.width,
            height: piece.height,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.pieces != pieces || oldDelegate.progress != progress;
}
