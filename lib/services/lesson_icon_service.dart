import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../models/course_models.dart';
import 'file_dialog_service.dart';
import 'import/image_validator.dart';

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
  LessonIconService({FileDialogService? fileDialogs})
    : _fileDialogs = fileDialogs ?? FileDialogService();

  static const int canvasSize = 256;
  static const int maxInputBytes = 2 * 1024 * 1024;
  static const int maxSourceDimension = 4096;

  final FileDialogService _fileDialogs;

  /// False when the system dialog is unsupported; hide Open from….
  bool get fileDialogsAvailable => _fileDialogs.isAvailable;

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

  /// Open from…: pick one icon image in the system dialog. It goes through
  /// the same [prepareIcon] (2 MB limit, decoding, 256 x 256 PNG) as the
  /// fixed-folder import; the icon is null when the user cancelled or the
  /// dialog failed.
  Future<({FileDialogResult dialog, ImportedLessonIcon? icon})>
  importPreparedIconFromDialog() async {
    final picked = await _fileDialogs.openBytes(
      extensions: const ['png', 'jpg', 'jpeg', 'webp'],
      maxBytes: maxInputBytes,
      artifact: 'lesson-icon',
    );
    if (picked.outcome == FileDialogOutcome.tooLarge) {
      throw const FormatException(
        'Lesson icon must be a readable image no larger than 2 MB.',
      );
    }
    if (picked.outcome != FileDialogOutcome.opened) {
      return (dialog: picked, icon: null);
    }
    final icon = await prepareIcon(
      picked.bytes!,
      assetId: 'custom_${DateTime.now().microsecondsSinceEpoch}',
    );
    return (dialog: picked, icon: icon);
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
    // The decoded image is needed below for drawImageRect, so this cannot skip
    // rasterizing entirely — but the dimension limit is checked against the
    // header first, so an image that declares more than maxSourceDimension is
    // rejected before any pixels are allocated.
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    final ui.Image source;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width <= 0 ||
          descriptor.height <= 0 ||
          descriptor.width > maxSourceDimension ||
          descriptor.height > maxSourceDimension) {
        throw const FormatException(
          'Lesson icon dimensions must be between 1 and 4096 pixels.',
        );
      }
      ImageValidator.inspect(bytes, ImageProfile.lessonIcon);
      codec = await descriptor.instantiateCodec();
      source = (await codec.getNextFrame()).image;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'The selected Lesson icon is not a supported image.',
      );
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
    final sourceWidth = source.width;
    final sourceHeight = source.height;

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
