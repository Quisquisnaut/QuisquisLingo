import 'package:flutter/material.dart';

/// The colours of one Lesson on the learner path (Build 261 Revision 8,
/// owner decision of 3 October 2026): its number circle and its Round
/// circles.
@immutable
class LessonColors {
  const LessonColors({
    required this.solid,
    required this.onSolid,
    required this.tint,
    required this.onTint,
  });

  /// The Lesson number circle and a completed Round's circle.
  final Color solid;

  /// The number or icon drawn on [solid].
  final Color onSolid;

  /// A Round's circle before it is completed, ringed with [solid].
  final Color tint;

  /// The icon drawn on [tint].
  final Color onTint;
}

/// QQL's own palette of eight Lesson colours, chosen by the Lesson's position
/// in the Course and repeating after eight. There is no green: green means
/// Perfect. Each colour has a light and a dark shade; numbers and icons have
/// at least 4.4:1 contrast with their circle. Nothing is stored.
abstract final class LessonColorPalette {
  static const count = 8;

  static const _light = <LessonColors>[
    // Indigo, purple, magenta, coral, gold, cyan, brown, slate.
    LessonColors(
      solid: Color(0xFF3B5BDB),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFE5EBFF),
      onTint: Color(0xFF2F49B0),
    ),
    LessonColors(
      solid: Color(0xFF7B3FC4),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFF1E7FC),
      onTint: Color(0xFF6230A0),
    ),
    LessonColors(
      solid: Color(0xFFC2255C),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFFCE4EC),
      onTint: Color(0xFFA01D4B),
    ),
    LessonColors(
      solid: Color(0xFFD0480C),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFFFE7DB),
      onTint: Color(0xFFA83A09),
    ),
    LessonColors(
      solid: Color(0xFFA86A0C),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFFDF1D3),
      onTint: Color(0xFF7F500A),
    ),
    LessonColors(
      solid: Color(0xFF0A7D99),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFDDF3F9),
      onTint: Color(0xFF07627A),
    ),
    LessonColors(
      solid: Color(0xFF8A5636),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFF4E7DE),
      onTint: Color(0xFF6E432A),
    ),
    LessonColors(
      solid: Color(0xFF4A6890),
      onSolid: Color(0xFFFFFFFF),
      tint: Color(0xFFE5ECF5),
      onTint: Color(0xFF3A5476),
    ),
  ];

  static const _dark = <LessonColors>[
    LessonColors(
      solid: Color(0xFF91A7FF),
      onSolid: Color(0xFF0F1A4D),
      tint: Color(0xFF1F2A5C),
      onTint: Color(0xFFB8C6FF),
    ),
    LessonColors(
      solid: Color(0xFFC9A2F7),
      onSolid: Color(0xFF2B0F4A),
      tint: Color(0xFF36205A),
      onTint: Color(0xFFDCC3FB),
    ),
    LessonColors(
      solid: Color(0xFFF49AB8),
      onSolid: Color(0xFF4A0C22),
      tint: Color(0xFF55182F),
      onTint: Color(0xFFF8C0D2),
    ),
    LessonColors(
      solid: Color(0xFFFFA27A),
      onSolid: Color(0xFF461500),
      tint: Color(0xFF57230F),
      onTint: Color(0xFFFFC6AC),
    ),
    LessonColors(
      solid: Color(0xFFF2C25A),
      onSolid: Color(0xFF3B2800),
      tint: Color(0xFF4A3710),
      onTint: Color(0xFFF8D995),
    ),
    LessonColors(
      solid: Color(0xFF72D2EB),
      onSolid: Color(0xFF032F3B),
      tint: Color(0xFF0F3E4B),
      onTint: Color(0xFFA9E5F4),
    ),
    LessonColors(
      solid: Color(0xFFD9AB8B),
      onSolid: Color(0xFF3A2212),
      tint: Color(0xFF45291A),
      onTint: Color(0xFFEBCDB8),
    ),
    LessonColors(
      solid: Color(0xFFA6BEDE),
      onSolid: Color(0xFF172539),
      tint: Color(0xFF24334A),
      onTint: Color(0xFFC8D7EA),
    ),
  ];

  /// The colours of the Lesson at zero-based [lessonIndex].
  static LessonColors of(int lessonIndex, Brightness brightness) {
    final colors = brightness == Brightness.dark ? _dark : _light;
    // Dart's % is never negative for a positive divisor.
    return colors[lessonIndex % count];
  }
}
