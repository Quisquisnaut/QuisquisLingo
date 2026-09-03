import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../models/course_models.dart';

class ImportedLessonIcon {
  final CourseLessonIconAsset asset;
  final int sourceWidth;
  final int sourceHeight;

  const ImportedLessonIcon({
    required this.asset,
    required this.sourceWidth,
    required this.sourceHeight,
  });
}

class LessonIconService {
  static const int canvasSize = 256;
  static const int maxInputBytes = 2 * 1024 * 1024;
  static const int maxSourceDimension = 8192;

  static ui.Rect containDestination(int sourceWidth, int sourceHeight) {
    final scale =
        canvasSize / (sourceWidth > sourceHeight ? sourceWidth : sourceHeight);
    final width = sourceWidth * scale;
    final height = sourceHeight * scale;
    return ui.Rect.fromLTWH(
      (canvasSize - width) / 2,
      (canvasSize - height) / 2,
      width,
      height,
    );
  }

  Future<Directory> iconImportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo'
      '${Platform.pathSeparator}Imports${Platform.pathSeparator}Lesson Icons',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<ImportedLessonIcon> importPreparedIcon() async {
    final directory = await iconImportDirectory();
    final candidates = await directory
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) {
          final extension = file.path.toLowerCase().split('.').last;
          return const {'png', 'jpg', 'jpeg', 'webp'}.contains(extension);
        })
        .toList();
    candidates.sort(
      (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
    );
    if (candidates.isEmpty) {
      throw StateError(
        'No icon image found in ${directory.path}. Copy one PNG, JPG, JPEG or WEBP image there and try again.',
      );
    }
    if (candidates.length > 1) {
      throw StateError(
        'More than one image was found in ${directory.path}. Keep only the icon you want to import, then try again.',
      );
    }
    final file = candidates.single;
    if (await file.length() > maxInputBytes) {
      throw const FormatException(
        'Lesson icon image exceeds the 2 MB safety limit.',
      );
    }
    return prepareIcon(
      await file.readAsBytes(),
      assetId: 'custom_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  Future<ImportedLessonIcon> prepareIcon(
    Uint8List bytes, {
    required String assetId,
  }) async {
    if (bytes.isEmpty || bytes.length > maxInputBytes) {
      throw const FormatException(
        'Lesson icon must be a readable image no larger than 2 MB.',
      );
    }
    ui.Codec codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
    } catch (_) {
      throw const FormatException(
        'The selected Lesson icon is not a supported image.',
      );
    }
    final frame = await codec.getNextFrame();
    final source = frame.image;
    codec.dispose();
    final sourceWidth = source.width;
    final sourceHeight = source.height;
    if (sourceWidth <= 0 ||
        sourceHeight <= 0 ||
        sourceWidth > maxSourceDimension ||
        sourceHeight > maxSourceDimension) {
      source.dispose();
      throw const FormatException(
        'Lesson icon dimensions must be between 1 and 8192 pixels.',
      );
    }

    final destination = containDestination(sourceWidth, sourceHeight);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      source,
      ui.Rect.fromLTWH(0, 0, sourceWidth.toDouble(), sourceHeight.toDouble()),
      destination,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    source.dispose();
    final image = await recorder.endRecording().toImage(canvasSize, canvasSize);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      throw const FormatException(
        'The Lesson icon could not be converted to PNG.',
      );
    }
    final png = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final asset = CourseLessonIconAsset(
      assetId: assetId,
      base64Png: base64Encode(png),
    );
    CourseLessonIconAsset.validateCanonicalPng(asset.base64Png);
    return ImportedLessonIcon(
      asset: asset,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
    );
  }
}
