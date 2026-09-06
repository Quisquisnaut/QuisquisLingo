import 'package:flutter/material.dart';

import '../services/portable_exercise_image.dart';

class PortableExerciseImage extends StatelessWidget {
  const PortableExerciseImage({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;

  Widget _unavailable() => SizedBox(
    width: width,
    height: height,
    child: const Center(
      child: Tooltip(
        message: 'Exercise image is unavailable or invalid.',
        child: Icon(Icons.broken_image_outlined),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = PortableExerciseImageService.decode(asset);
      if (bytes == null) {
        return Image.asset(
          asset,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _unavailable(),
        );
      }
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _unavailable(),
      );
    } on FormatException {
      return _unavailable();
    }
  }
}
