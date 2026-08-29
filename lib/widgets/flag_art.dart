import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/course_models.dart';

/// Shared flag artwork used by selectors, course/Lesson backdrops and short
/// transition animations. Keeping one painter avoids visual drift between the
/// same language in different parts of the app.
class FlagBadge extends StatelessWidget {
  final String code;
  final double width;
  final double height;

  const FlagBadge(this.code, {super.key, this.width = 44, this.height = 31});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(blurRadius: 3, color: Color(0x22000000))],
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(painter: FlagPainter(code)),
      );
}

class FlagBackdrop extends StatelessWidget {
  final String code;
  final double opacity;

  const FlagBackdrop({super.key, required this.code, this.opacity = .82});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: CustomPaint(
            painter: FlagPainter(code),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

class FlagPainter extends CustomPainter {
  final String code;
  const FlagPainter(this.code);

  void _fill(Canvas c, Size s, Color color) {
    c.drawRect(Offset.zero & s, Paint()..color = color);
  }

  @override
  void paint(Canvas c, Size s) {
    final normalized = code.trim().toUpperCase();
    final p = Paint()..style = PaintingStyle.fill;

    switch (normalized) {
      case 'DE':
        final h = s.height / 3;
        for (final stripe in [
          (Colors.black, 0.0),
          (const Color(0xFFDD0000), 1.0),
          (const Color(0xFFFFCE00), 2.0),
        ]) {
          p.color = stripe.$1;
          c.drawRect(Rect.fromLTWH(0, h * stripe.$2, s.width, h), p);
        }
        break;
      case 'IT':
        final w = s.width / 3;
        for (final stripe in [
          (const Color(0xFF009246), 0.0),
          (Colors.white, 1.0),
          (const Color(0xFFCE2B37), 2.0),
        ]) {
          p.color = stripe.$1;
          c.drawRect(Rect.fromLTWH(w * stripe.$2, 0, w, s.height), p);
        }
        break;
      case 'ES':
        _fill(c, s, const Color(0xFFAA151B));
        p.color = const Color(0xFFF1BF00);
        c.drawRect(Rect.fromLTWH(0, s.height * .25, s.width, s.height * .5), p);
        break;
      case 'PT':
        p.color = const Color(0xFF046A38);
        c.drawRect(Rect.fromLTWH(0, 0, s.width * .4, s.height), p);
        p.color = const Color(0xFFDA291C);
        c.drawRect(Rect.fromLTWH(s.width * .4, 0, s.width * .6, s.height), p);
        p.color = const Color(0xFFFFC72C);
        c.drawCircle(Offset(s.width * .4, s.height * .5), s.height * .14, p);
        break;
      case 'NL':
        final h = s.height / 3;
        for (final stripe in [
          (const Color(0xFFAE1C28), 0.0),
          (Colors.white, 1.0),
          (const Color(0xFF21468B), 2.0),
        ]) {
          p.color = stripe.$1;
          c.drawRect(Rect.fromLTWH(0, h * stripe.$2, s.width, h), p);
        }
        break;
      case 'FI':
        _fill(c, s, Colors.white);
        p.color = const Color(0xFF003580);
        c.drawRect(Rect.fromLTWH(s.width * .27, 0, s.width * .16, s.height), p);
        c.drawRect(Rect.fromLTWH(0, s.height * .40, s.width, s.height * .20), p);
        break;
      case 'CY':
        _paintWelsh(c, s);
        break;
      case 'EN':
      case 'UK':
        _paintUnionJack(c, s);
        break;
      default:
        _fill(c, s, const Color(0xFFE9E2CF));
    }
  }

  void _paintUnionJack(Canvas c, Size s) {
    _fill(c, s, const Color(0xFF012169));
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = s.height * .22;
    final redDiagonal = Paint()
      ..color = const Color(0xFFC8102E)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = s.height * .09;

    c.drawLine(Offset(0, 0), Offset(s.width, s.height), white);
    c.drawLine(Offset(s.width, 0), Offset(0, s.height), white);
    c.drawLine(Offset(0, 0), Offset(s.width, s.height), redDiagonal);
    c.drawLine(Offset(s.width, 0), Offset(0, s.height), redDiagonal);

    final p = Paint()..style = PaintingStyle.fill;
    p.color = Colors.white;
    c.drawRect(Rect.fromLTWH(s.width * .40, 0, s.width * .20, s.height), p);
    c.drawRect(Rect.fromLTWH(0, s.height * .34, s.width, s.height * .32), p);
    p.color = const Color(0xFFC8102E);
    c.drawRect(Rect.fromLTWH(s.width * .455, 0, s.width * .09, s.height), p);
    c.drawRect(Rect.fromLTWH(0, s.height * .43, s.width, s.height * .14), p);
  }

  void _paintWelsh(Canvas c, Size s) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = Colors.white;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height * .5), p);
    p.color = const Color(0xFF00AB39);
    c.drawRect(Rect.fromLTWH(0, s.height * .5, s.width, s.height * .5), p);

    // Compact red-dragon silhouette. It is intentionally schematic at badge
    // size but keeps the long body, raised wing, head and tail recognizable.
    p.color = const Color(0xFFD30731);
    final dragon = Path()
      ..moveTo(s.width * .18, s.height * .61)
      ..quadraticBezierTo(s.width * .30, s.height * .46, s.width * .42, s.height * .58)
      ..lineTo(s.width * .48, s.height * .36)
      ..lineTo(s.width * .57, s.height * .51)
      ..lineTo(s.width * .68, s.height * .34)
      ..lineTo(s.width * .65, s.height * .55)
      ..lineTo(s.width * .82, s.height * .50)
      ..lineTo(s.width * .72, s.height * .63)
      ..lineTo(s.width * .84, s.height * .72)
      ..lineTo(s.width * .66, s.height * .69)
      ..lineTo(s.width * .59, s.height * .83)
      ..lineTo(s.width * .52, s.height * .68)
      ..lineTo(s.width * .38, s.height * .73)
      ..lineTo(s.width * .31, s.height * .88)
      ..lineTo(s.width * .28, s.height * .68)
      ..quadraticBezierTo(s.width * .18, s.height * .77, s.width * .08, s.height * .67)
      ..quadraticBezierTo(s.width * .14, s.height * .67, s.width * .18, s.height * .61)
      ..close();
    c.drawPath(dragon, p);
    c.drawCircle(Offset(s.width * .76, s.height * .48), s.height * .035, p);
  }

  @override
  bool shouldRepaint(covariant FlagPainter oldDelegate) => oldDelegate.code != code;
}

/// Course-aware flag badge. A custom imported flag takes precedence over the
/// built-in flag code. The JSON stores only the resized PNG so exported custom
/// courses remain portable and do not depend on the original image path.
class CourseFlagBadge extends StatelessWidget {
  final Course course;
  final String fallbackCode;
  final double width;
  final double height;

  const CourseFlagBadge({
    super.key,
    required this.course,
    required this.fallbackCode,
    this.width = 44,
    this.height = 31,
  });

  @override
  Widget build(BuildContext context) {
    final encoded = course.flagImageBase64.trim();
    if (encoded.isNotEmpty) {
      try {
        final bytes = base64Decode(encoded);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(blurRadius: 3, color: Color(0x22000000))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
        );
      } catch (_) {
        // Fall back to the built-in flag if imported data are damaged.
      }
    }
    final code = course.flagCode.trim().isEmpty
        ? fallbackCode
        : course.flagCode;
    return FlagBadge(code, width: width, height: height);
  }
}

class CourseFlagBackdrop extends StatelessWidget {
  final Course course;
  final String fallbackCode;
  final double opacity;

  const CourseFlagBackdrop({
    super.key,
    required this.course,
    required this.fallbackCode,
    this.opacity = .82,
  });

  @override
  Widget build(BuildContext context) {
    final encoded = course.flagImageBase64.trim();
    if (encoded.isNotEmpty) {
      try {
        final bytes = base64Decode(encoded);
        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: SizedBox.expand(child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)),
          ),
        );
      } catch (_) {
        // Fall back to the built-in flag if imported data are damaged.
      }
    }
    final code = course.flagCode.trim().isEmpty
        ? fallbackCode
        : course.flagCode;
    return FlagBackdrop(code: code, opacity: opacity);
  }
}
