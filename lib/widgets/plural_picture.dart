import 'package:flutter/widgets.dart';

/// Build 265 Revision 11 (owner decision of 7 October 2026, look A): a
/// picture marked Plural shows several things, "cats" rather than "cat". It
/// is drawn three times in the space of one: two faded copies behind, at the
/// top left and the top right, and the picture in front, lower in the
/// middle. No digit or word, so it never reads as a number.
///
/// Without [plural] it is [child] unchanged. [child] is drawn three times,
/// so it must not carry a GlobalKey.
class PluralPicture extends StatelessWidget {
  const PluralPicture({super.key, required this.plural, required this.child});

  final bool plural;
  final Widget child;

  /// [child] drawn as several when [plural], else [child] itself: a picture
  /// that is not plural keeps its widget tree unchanged.
  static Widget wrap({required bool plural, required Widget child}) =>
      plural ? PluralPicture(plural: true, child: child) : child;

  /// The size of each copy, as a share of the picture's box.
  static const copyScale = .68;

  /// How visible the copies behind are.
  static const copyOpacity = .45;

  @override
  Widget build(BuildContext context) {
    if (!plural) return child;
    Widget behind(Alignment alignment) => Positioned.fill(
      child: Opacity(
        opacity: copyOpacity,
        child: Transform.scale(
          scale: copyScale,
          alignment: alignment,
          child: child,
        ),
      ),
    );
    return Stack(
      key: const Key('plural-picture'),
      // Not directional: the copies sit the same way in every language.
      alignment: Alignment.topLeft,
      children: [
        behind(Alignment.topLeft),
        behind(Alignment.topRight),
        // The front copy gives the Stack its size: the picture's own box.
        Transform.scale(
          scale: copyScale + .06,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ],
    );
  }
}
