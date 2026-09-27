import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import 'course_media_store.dart';
import 'course_package_service.dart';
import 'exercise_image_service.dart';
import 'file_dialog_service.dart';
import 'import/image_validator.dart';

/// A picture read to become a Course cover, and the name it came with.
typedef CoverSource = ({Uint8List bytes, String name});

/// Makes a Course cover from any picture (Build 255 Revision 6).
///
/// A ready 512 × 512 picture up to [CourseMediaStore.maxCoverBytes] is kept as
/// it is. Any other picture is cropped to a square, the one its author chose
/// (Revision 7) or else its centred square, and scaled to a 512 × 512 PNG.
/// Every cover made here passes [CoursePackageService.checkCover], the check
/// an imported Course package applies, so an exported cover always imports
/// again.
class CourseCoverService {
  CourseCoverService({
    CourseMediaStore? mediaStore,
    ExerciseImageService? images,
  }) : _media = mediaStore ?? CourseMediaStore(),
       _images = images ?? ExerciseImageService();

  static const size = 512;

  final CourseMediaStore _media;
  final ExerciseImageService _images;

  /// False when the system file dialog is unsupported; hide Open from….
  bool get fileDialogsAvailable => _images.fileDialogsAvailable;

  /// Prepares [source] and stores it in [courseId]'s own media folder.
  /// Returns the cover's `media:` reference.
  Future<String> store(
    String courseId,
    Uint8List source, {
    ui.Rect? crop,
  }) async {
    final cover = await prepare(source, crop: crop);
    return _media.addBytes(courseId, cover.bytes, cover.extension, cover: true);
  }

  /// The cover's bytes and file extension for [source]. [crop] is the square
  /// the cover shows, in the picture's own pixels; null means its centred
  /// square.
  static Future<({Uint8List bytes, String extension})> prepare(
    Uint8List source, {
    ui.Rect? crop,
  }) async {
    final picture = await ImageValidator.validate(
      source,
      ImageProfile.courseCoverSource,
    );
    final whole =
        crop == null ||
        (crop.left <= 0.5 &&
            crop.top <= 0.5 &&
            crop.right >= picture.width - 0.5 &&
            crop.bottom >= picture.height - 0.5);
    final ready =
        whole &&
        picture.width == size &&
        picture.height == size &&
        picture.bytes.length <= CourseMediaStore.maxCoverBytes;
    final cover = ready
        ? (bytes: picture.bytes, extension: picture.format.extension)
        : (bytes: await _squarePng(picture.bytes, crop), extension: 'png');
    if (cover.bytes.length > CourseMediaStore.maxCoverBytes) {
      throw const FormatException(
        'This picture is too detailed for a cover of at most 1 MB. Choose a '
        'simpler picture, or a 512 × 512 JPEG of at most 1 MB.',
      );
    }
    await CoursePackageService.checkCover(
      CourseMediaStore.referenceFor(cover.bytes, cover.extension),
      cover.bytes,
    );
    return cover;
  }

  static Future<Uint8List> _squarePng(Uint8List bytes, ui.Rect? crop) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final ui.Image source;
    try {
      source = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
    try {
      final shorter = math.min(source.width, source.height).toDouble();
      // The square asked for, kept inside the picture as decoded.
      final side = crop == null
          ? shorter
          : math.min(shorter, math.max(1.0, math.min(crop.width, crop.height)));
      final left = crop == null
          ? (source.width - side) / 2
          : crop.left.clamp(0.0, source.width - side);
      final top = crop == null
          ? (source.height - side) / 2
          : crop.top.clamp(0.0, source.height - side);
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        source,
        ui.Rect.fromLTWH(left, top, side, side),
        ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final image = await recorder.endRecording().toImage(size, size);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) {
          throw const FormatException(
            'The cover could not be made. Choose another picture.',
          );
        }
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        image.dispose();
      }
    } finally {
      source.dispose();
    }
  }

  /// The one picture in the Quick Import folder for images.
  Future<CoverSource> readQuickImport() async {
    final picked = await _images.readImage(
      maxBytes: ImageProfile.courseCoverSource.maxBytes,
      profile: ImageProfile.courseCoverSource,
    );
    return (bytes: picked.image.bytes, name: picked.sourceName);
  }

  /// Open from…: the picture is null when the user cancelled or the dialog
  /// failed; see the dialog result.
  Future<({FileDialogResult dialog, CoverSource? source})>
  readFromDialog() async {
    final result = await _images.readImageFromDialog(
      maxBytes: ImageProfile.courseCoverSource.maxBytes,
      profile: ImageProfile.courseCoverSource,
      artifact: 'course-cover',
    );
    final picked = result.picked;
    return (
      dialog: result.dialog,
      source: picked == null
          ? null
          : (bytes: picked.image.bytes, name: picked.sourceName),
    );
  }

  /// A picture chosen in the image library: a QQL image (`assets/…`), one of
  /// [courseId]'s own images (`media:…`) or a Shared Image Library file.
  Future<Uint8List> readLibraryImage(String courseId, String asset) async {
    if (asset.startsWith('assets/')) {
      final data = await rootBundle.load(asset);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    if (CourseMediaStore.isReference(asset)) {
      final file = await _media.existingFile(courseId, asset);
      if (file == null) {
        throw const FormatException(
          'This Course image is missing. Choose another picture.',
        );
      }
      return file.readAsBytes();
    }
    if (asset.startsWith('data:')) {
      throw const FormatException(
        'This picture cannot become a cover. Choose another picture.',
      );
    }
    final file = File(asset);
    if (!await file.exists()) {
      throw const FormatException(
        'The picture file is missing. Choose another picture.',
      );
    }
    if (await file.length() > ImageProfile.courseCoverSource.maxBytes) {
      throw const FormatException(
        'This picture is larger than the 10 MB maximum. Choose a smaller one.',
      );
    }
    return file.readAsBytes();
  }
}
