import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/course_models.dart';
import 'world_flag_repository.dart';

@immutable
class FlagColorSample {
  final Color color;
  final double weight;

  const FlagColorSample(this.color, [this.weight = 1]);
}

@immutable
class FlagBackgroundPalette {
  final Color tinted;
  final Color softStart;
  final Color softEnd;

  const FlagBackgroundPalette({
    required this.tinted,
    required this.softStart,
    required this.softEnd,
  });
}

enum CourseFlagPaletteSource { worldFlag, customImage, builtIn, safeFallback }

@immutable
class CourseFlagPaletteResult {
  final FlagBackgroundPalette palette;
  final CourseFlagPaletteSource source;
  final bool usedFallback;

  const CourseFlagPaletteResult({
    required this.palette,
    required this.source,
    required this.usedFallback,
  });
}

/// Deterministically turns representative flag colors into quiet learner-page
/// surfaces. Both inspired modes use this one adaptation path.
class FlagBackgroundPaletteService {
  static const _lightBase = Color(0xFFF7F3E8);
  static const _darkBase = Color(0xFF080B09);

  const FlagBackgroundPaletteService();

  FlagBackgroundPalette derive(
    Iterable<FlagColorSample> samples, {
    required Brightness brightness,
  }) {
    final buckets = _bucket(samples);
    if (buckets.isEmpty) {
      return _neutralPalette(brightness);
    }

    final chromatic = buckets
        .where((entry) => HSLColor.fromColor(entry.color).saturation >= .12)
        .toList(growable: false);
    final primary = _ranked(chromatic.isEmpty ? buckets : chromatic).first;
    final alternatives = buckets
        .where((entry) => !identical(entry, primary))
        .toList(growable: false);
    final secondary = alternatives.isEmpty
        ? primary
        : (_ranked(alternatives, distanceFrom: primary.color).first);

    final tinted = _adapt(primary.color, brightness, strength: .20);
    final softStart = _adapt(primary.color, brightness, strength: .28);
    var softEnd = _adapt(secondary.color, brightness, strength: .24);
    if (_distance(softStart, softEnd) < .035) {
      softEnd = Color.lerp(
        softStart,
        brightness == Brightness.light ? _lightBase : _darkBase,
        .22,
      )!;
    }
    return FlagBackgroundPalette(
      tinted: tinted,
      softStart: softStart,
      softEnd: softEnd,
    );
  }

  static List<FlagColorSample> builtInColors(String code) =>
      switch (code.trim().toUpperCase()) {
        'DE' => const [
          FlagColorSample(Color(0xFF000000)),
          FlagColorSample(Color(0xFFDD0000)),
          FlagColorSample(Color(0xFFFFCE00)),
        ],
        'IT' => const [
          FlagColorSample(Color(0xFF009246)),
          FlagColorSample(Color(0xFFFFFFFF)),
          FlagColorSample(Color(0xFFCE2B37)),
        ],
        'ES' => const [
          FlagColorSample(Color(0xFFAA151B), .5),
          FlagColorSample(Color(0xFFF1BF00), .5),
        ],
        'PT' => const [
          FlagColorSample(Color(0xFF046A38), .4),
          FlagColorSample(Color(0xFFDA291C), .6),
          FlagColorSample(Color(0xFFFFC72C), .06),
        ],
        'NL' => const [
          FlagColorSample(Color(0xFFAE1C28)),
          FlagColorSample(Color(0xFFFFFFFF)),
          FlagColorSample(Color(0xFF21468B)),
        ],
        'FI' => const [
          FlagColorSample(Color(0xFFFFFFFF), .72),
          FlagColorSample(Color(0xFF003580), .28),
        ],
        'CY' => const [
          FlagColorSample(Color(0xFFFFFFFF), .45),
          FlagColorSample(Color(0xFF00AB39), .45),
          FlagColorSample(Color(0xFFD30731), .10),
        ],
        'EN' || 'UK' => const [
          FlagColorSample(Color(0xFF012169), .5),
          FlagColorSample(Color(0xFFFFFFFF), .3),
          FlagColorSample(Color(0xFFC8102E), .2),
        ],
        'KO' || 'KR' => const [
          FlagColorSample(Color(0xFFFFFFFF), .75),
          FlagColorSample(Color(0xFFCD2E3A), .09),
          FlagColorSample(Color(0xFF0047A0), .09),
          FlagColorSample(Color(0xFF000000), .07),
        ],
        _ => const [],
      };

  static List<FlagColorSample> colorsFromSvg(String svg) {
    // SVG path counts describe drawing complexity rather than visible area. Keep
    // each explicit color once so a detailed crest cannot outweigh the flag's
    // field colors merely because it contains many small paths.
    final colors = <int, FlagColorSample>{};
    final attributes = RegExp(
      r'''(fill|stroke|stop-color)\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    );
    for (final match in attributes.allMatches(svg)) {
      final color = _parseSvgColor(match.group(2)!);
      if (color == null) continue;
      final attribute = match.group(1)!.toLowerCase();
      final sample = FlagColorSample(
        color,
        attribute == 'stroke'
            ? .25
            : attribute == 'stop-color'
            ? .7
            : 1,
      );
      final key = color.toARGB32();
      final existing = colors[key];
      if (existing == null || sample.weight > existing.weight) {
        colors[key] = sample;
      }
    }
    return List.unmodifiable(colors.values);
  }

  static Color? _parseSvgColor(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty ||
        value == 'none' ||
        value == 'transparent' ||
        value.startsWith('url(')) {
      return null;
    }
    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 3) {
        final expanded = hex.split('').map((digit) => '$digit$digit').join();
        final parsed = int.tryParse(expanded, radix: 16);
        return parsed == null ? null : Color(0xFF000000 | parsed);
      }
      if (hex.length == 6 || hex.length == 8) {
        final parsed = int.tryParse(hex.substring(0, 6), radix: 16);
        return parsed == null ? null : Color(0xFF000000 | parsed);
      }
      return null;
    }
    final rgb = RegExp(
      r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$',
    ).firstMatch(value);
    if (rgb != null) {
      final channels = [
        int.parse(rgb.group(1)!),
        int.parse(rgb.group(2)!),
        int.parse(rgb.group(3)!),
      ];
      if (channels.any((channel) => channel > 255)) return null;
      return Color.fromARGB(255, channels[0], channels[1], channels[2]);
    }
    return switch (value) {
      'black' => const Color(0xFF000000),
      'white' => const Color(0xFFFFFFFF),
      'red' => const Color(0xFFFF0000),
      'green' => const Color(0xFF008000),
      'blue' => const Color(0xFF0000FF),
      'yellow' => const Color(0xFFFFFF00),
      'gold' => const Color(0xFFFFD700),
      'gray' || 'grey' => const Color(0xFF808080),
      'maroon' => const Color(0xFF800000),
      'olive' => const Color(0xFF808000),
      'purple' => const Color(0xFF800080),
      _ => null,
    };
  }

  List<_ColorBucket> _bucket(Iterable<FlagColorSample> samples) {
    final buckets = <String, _ColorAccumulator>{};
    for (final sample in samples) {
      if (!sample.weight.isFinite ||
          sample.weight <= 0 ||
          sample.color.a < .1) {
        continue;
      }
      final hsl = HSLColor.fromColor(sample.color);
      final key = hsl.saturation < .10
          ? 'n:${(hsl.lightness * 5).floor().clamp(0, 4)}'
          : 'c:${(hsl.hue / 24).floor()}:${(hsl.saturation * 3).floor().clamp(0, 2)}:${(hsl.lightness * 4).floor().clamp(0, 3)}';
      buckets.putIfAbsent(key, _ColorAccumulator.new).add(sample);
    }
    return buckets.values.map((bucket) => bucket.finish()).toList();
  }

  List<_ColorBucket> _ranked(List<_ColorBucket> source, {Color? distanceFrom}) {
    final ranked = [...source];
    ranked.sort((left, right) {
      double score(_ColorBucket bucket) {
        final hsl = HSLColor.fromColor(bucket.color);
        final chroma = hsl.saturation < .12 ? .16 : .65 + hsl.saturation;
        final extreme = hsl.lightness < .04 || hsl.lightness > .96 ? .45 : 1;
        final distance = distanceFrom == null
            ? 1
            : .18 + _distance(bucket.color, distanceFrom);
        return bucket.weight * chroma * extreme * distance;
      }

      final byScore = score(right).compareTo(score(left));
      if (byScore != 0) return byScore;
      return left.color.toARGB32().compareTo(right.color.toARGB32());
    });
    return ranked;
  }

  FlagBackgroundPalette _neutralPalette(Brightness brightness) {
    final base = brightness == Brightness.light
        ? const Color(0xFFE4E1DA)
        : const Color(0xFF1B211E);
    final end = brightness == Brightness.light
        ? const Color(0xFFECE8DE)
        : const Color(0xFF202522);
    return FlagBackgroundPalette(tinted: base, softStart: base, softEnd: end);
  }

  Color _adapt(
    Color source,
    Brightness brightness, {
    required double strength,
  }) {
    final hsl = HSLColor.fromColor(source);
    final isNeutral = hsl.saturation < .10;
    final saturation = isNeutral
        ? .035
        : hsl.saturation.clamp(.14, brightness == Brightness.light ? .34 : .30);
    final targetLightness = brightness == Brightness.light ? .84 : .18;
    var adapted = hsl
        .withSaturation(saturation)
        .withLightness(targetLightness)
        .toColor();
    final base = brightness == Brightness.light ? _lightBase : _darkBase;
    adapted = Color.lerp(base, adapted, strength)!;
    final blendedHsl = HSLColor.fromColor(adapted);
    if (isNeutral) {
      if (blendedHsl.saturation > .36) {
        adapted = blendedHsl.withSaturation(.36).toColor();
      }
    } else {
      // RGB blending against the warm learner-page base can shift a quiet blue
      // or purple toward red. Retain the representative flag hue while using
      // the blend only to determine the restrained saturation and lightness.
      adapted = HSLColor.fromAHSL(
        1,
        hsl.hue,
        blendedHsl.saturation.clamp(.08, .36),
        blendedHsl.lightness,
      ).toColor();
    }

    if (brightness == Brightness.light) {
      while (adapted.computeLuminance() < .62) {
        adapted = Color.lerp(adapted, const Color(0xFFFFFFFF), .08)!;
      }
    } else {
      while (adapted.computeLuminance() > .10) {
        adapted = Color.lerp(adapted, const Color(0xFF000000), .10)!;
      }
      if (adapted.computeLuminance() < .012) {
        adapted = Color.lerp(adapted, const Color(0xFFFFFFFF), .06)!;
      }
    }
    return adapted;
  }

  static double _distance(Color left, Color right) {
    final dr = left.r - right.r;
    final dg = left.g - right.g;
    final db = left.b - right.b;
    return math.sqrt(dr * dr + dg * dg + db * db) / math.sqrt(3);
  }
}

class CourseFlagPaletteResolver {
  final AssetBundle _bundle;
  final WorldFlagRepository _worldFlags;
  final FlagBackgroundPaletteService _paletteService;

  CourseFlagPaletteResolver({
    AssetBundle? bundle,
    WorldFlagRepository? worldFlagRepository,
    FlagBackgroundPaletteService paletteService =
        const FlagBackgroundPaletteService(),
  }) : _bundle = bundle ?? rootBundle,
       _worldFlags =
           worldFlagRepository ??
           WorldFlagRepository(bundle: bundle ?? rootBundle),
       _paletteService = paletteService;

  Future<CourseFlagPaletteResult> resolve(
    Course course, {
    required String fallbackCode,
    required Brightness brightness,
  }) async {
    final worldFlagId = course.worldFlagId.trim();
    if (worldFlagId.isNotEmpty) {
      try {
        final entity = await _worldFlags.findById(worldFlagId);
        if (entity != null) {
          final samples = FlagBackgroundPaletteService.colorsFromSvg(
            await _bundle.loadString(entity.assetPath),
          );
          if (samples.isNotEmpty) {
            return CourseFlagPaletteResult(
              palette: _paletteService.derive(samples, brightness: brightness),
              source: CourseFlagPaletteSource.worldFlag,
              usedFallback: false,
            );
          }
        }
      } catch (_) {
        // The derived background alone falls back to the built-in flag colors.
      }
      return _builtIn(
        course,
        fallbackCode: fallbackCode,
        brightness: brightness,
        usedFallback: true,
      );
    }

    final encoded = course.flagImageBase64.trim();
    if (encoded.isNotEmpty) {
      try {
        final samples = await _colorsFromRaster(base64Decode(encoded));
        if (samples.isNotEmpty) {
          return CourseFlagPaletteResult(
            palette: _paletteService.derive(samples, brightness: brightness),
            source: CourseFlagPaletteSource.customImage,
            usedFallback: false,
          );
        }
      } catch (_) {
        // Keep the learner page usable through the existing built-in source.
      }
      return _builtIn(
        course,
        fallbackCode: fallbackCode,
        brightness: brightness,
        usedFallback: true,
      );
    }

    return _builtIn(
      course,
      fallbackCode: fallbackCode,
      brightness: brightness,
      usedFallback: false,
    );
  }

  CourseFlagPaletteResult _builtIn(
    Course course, {
    required String fallbackCode,
    required Brightness brightness,
    required bool usedFallback,
  }) {
    final code = course.flagCode.trim().isEmpty
        ? fallbackCode
        : course.flagCode;
    final samples = FlagBackgroundPaletteService.builtInColors(code);
    final hasKnownColors = samples.isNotEmpty;
    return CourseFlagPaletteResult(
      palette: _paletteService.derive(samples, brightness: brightness),
      source: hasKnownColors
          ? CourseFlagPaletteSource.builtIn
          : CourseFlagPaletteSource.safeFallback,
      usedFallback: usedFallback || !hasKnownColors,
    );
  }

  static Future<List<FlagColorSample>> _colorsFromRaster(
    Uint8List bytes,
  ) async {
    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 48,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return const [];
      final rgba = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final result = <FlagColorSample>[];
      for (var offset = 0; offset + 3 < rgba.length; offset += 4) {
        final alpha = rgba[offset + 3];
        if (alpha < 26) continue;
        result.add(
          FlagColorSample(
            Color.fromARGB(
              255,
              rgba[offset],
              rgba[offset + 1],
              rgba[offset + 2],
            ),
            alpha / 255,
          ),
        );
      }
      return result;
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }
}

class _ColorAccumulator {
  double red = 0;
  double green = 0;
  double blue = 0;
  double weight = 0;

  void add(FlagColorSample sample) {
    red += sample.color.r * sample.weight;
    green += sample.color.g * sample.weight;
    blue += sample.color.b * sample.weight;
    weight += sample.weight;
  }

  _ColorBucket finish() => _ColorBucket(
    Color.from(
      alpha: 1,
      red: red / weight,
      green: green / weight,
      blue: blue / weight,
      colorSpace: ui.ColorSpace.sRGB,
    ),
    weight,
  );
}

class _ColorBucket {
  final Color color;
  final double weight;

  const _ColorBucket(this.color, this.weight);
}
