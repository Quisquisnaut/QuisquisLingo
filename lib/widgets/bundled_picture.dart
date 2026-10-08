import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Whether a picture is an SVG drawing: the World Flags the image library
/// offers (Build 264 Revision 1).
bool isSvgPicture(String asset) => asset.toLowerCase().endsWith('.svg');

/// A picture QQL ships under `assets/`: a WebP or PNG through `Image.asset`,
/// an SVG drawing through flutter_svg. A drawing is always shown whole
/// (`BoxFit.contain`), never cropped to fill a frame: a flag is not square.
class BundledPicture extends StatelessWidget {
  const BundledPicture(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.cacheWidth,
    this.cacheHeight,
    this.semanticLabel,
    this.errorBuilder,
  });

  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Decoding size of a raster picture; a drawing ignores it.
  final int? cacheWidth;
  final int? cacheHeight;
  final String? semanticLabel;

  /// What to show when the picture cannot be read.
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final onError = errorBuilder;
    if (isSvgPicture(asset)) {
      return SvgPicture.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        semanticsLabel: semanticLabel,
        errorBuilder: onError == null
            ? null
            : (context, _, _) => onError(context),
      );
    }
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      semanticLabel: semanticLabel,
      errorBuilder: onError == null
          ? null
          : (context, _, _) => onError(context),
    );
  }
}
