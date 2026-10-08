import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/world_flag_entity.dart';
import 'enlarged_image_dialog.dart';

/// Opens [entity]'s flag enlarged (Build 255 Revision 6). During a Flag Game
/// question [showName] is false, so the enlargement never gives the answer
/// away; the reference lists show the name.
Future<void> showWorldFlagPreview(
  BuildContext context,
  WorldFlagEntity entity, {
  required bool showName,
}) => showEnlargedImage(
  context,
  dialogKey: const ValueKey('world-flag-preview'),
  closeKey: const ValueKey('world-flag-preview-close'),
  title: showName ? entity.displayNameEn : null,
  aspectRatio: 4 / 3,
  builder: (_, _) => WorldFlagArt(
    entity: entity,
    semanticsLabel: showName
        ? '${entity.displayNameEn} flag'
        : 'Flag to identify',
  ),
);

/// A flag that opens enlarged when tapped.
class EnlargeableWorldFlag extends StatelessWidget {
  const EnlargeableWorldFlag({
    super.key,
    required this.entity,
    required this.showName,
    required this.child,
  });

  final WorldFlagEntity entity;
  final bool showName;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Enlarge flag',
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showWorldFlagPreview(context, entity, showName: showName),
      child: child,
    ),
  );
}

class WorldFlagArt extends StatelessWidget {
  final WorldFlagEntity entity;
  final BoxFit fit;
  final String semanticsLabel;
  final bool showFrame;

  const WorldFlagArt({
    super.key,
    required this.entity,
    this.fit = BoxFit.contain,
    this.semanticsLabel = 'Flag to identify',
    this.showFrame = true,
  });

  @override
  Widget build(BuildContext context) {
    final art = SvgPicture.asset(
      entity.assetPath,
      fit: fit,
      placeholderBuilder: (_) => const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: semanticsLabel,
      child: showFrame
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: art,
              ),
            )
          : art,
    );
  }
}
