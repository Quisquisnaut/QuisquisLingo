import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/world_flag_entity.dart';

class WorldFlagArt extends StatelessWidget {
  final WorldFlagEntity entity;
  final BoxFit fit;
  final String semanticsLabel;

  const WorldFlagArt({
    super.key,
    required this.entity,
    this.fit = BoxFit.contain,
    this.semanticsLabel = 'Flag to identify',
  });

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: semanticsLabel,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SvgPicture.asset(
          entity.assetPath,
          fit: fit,
          placeholderBuilder: (_) => const Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    ),
  );
}
