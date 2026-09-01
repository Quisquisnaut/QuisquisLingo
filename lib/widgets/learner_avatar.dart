import 'package:flutter/material.dart';

import '../services/status_service.dart';

/// The authoritative programmatic learner avatar used across profile surfaces.
class LearnerAvatar extends StatelessWidget {
  final int level;
  final String skinTone;
  final String hairTone;

  const LearnerAvatar({
    super.key,
    this.level = 0,
    required this.skinTone,
    required this.hairTone,
  });

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: LearnerAvatarPainter(level, skinTone, hairTone));
}

/// One painter covers all Status ranks and the six profile appearances.
class LearnerAvatarPainter extends CustomPainter {
  final int level;
  final String skinTone;
  final String hairTone;

  const LearnerAvatarPainter(this.level, this.skinTone, this.hairTone);

  @override
  void paint(Canvas canvas, Size size) {
    final skinColor =
        {
          'light': const Color(0xFFF2C7A5),
          'medium': const Color(0xFFC98D62),
          'dark': const Color(0xFF7A4A31),
        }[skinTone] ??
        const Color(0xFFC98D62);
    final hairColor = hairTone == 'light'
        ? const Color(0xFFD6B56C)
        : const Color(0xFF4A3428);
    final robe = Paint()
      ..color = Color.lerp(
        const Color(0xFF718447),
        const Color(0xFF5B477C),
        level / (StatusService.names.length - 1),
      )!;
    final center = Offset(size.width / 2, size.height * .42);
    canvas.drawCircle(center, size.width * .22, Paint()..color = skinColor);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * .23),
      3.2,
      3.0,
      false,
      Paint()
        ..color = hairColor
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .22,
          size.height * .58,
          size.width * .56,
          size.height * .34,
        ),
        const Radius.circular(14),
      ),
      robe,
    );
    if (level >= 2) {
      canvas.drawLine(
        Offset(size.width * .78, size.height * .44),
        Offset(size.width * .84, size.height * .9),
        Paint()
          ..color = const Color(0xFF795548)
          ..strokeWidth = 4,
      );
    }
    if (level >= 4) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width * .30, size.height * .25)
          ..lineTo(size.width * .50, size.height * .05)
          ..lineTo(size.width * .70, size.height * .25)
          ..close(),
        Paint()
          ..color = level >= 6
              ? const Color(0xFF66528A)
              : const Color(0xFF8B6B45),
      );
    }
    if (level >= 8) {
      canvas.drawCircle(
        Offset(size.width * .50, size.height * .10),
        5,
        Paint()..color = const Color(0xFFD5A927),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LearnerAvatarPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.skinTone != skinTone ||
      oldDelegate.hairTone != hairTone;
}
