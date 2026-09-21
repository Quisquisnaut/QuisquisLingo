import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart' show getCrc32;

import 'media_file_kind.dart';
import 'web_page_detector.dart';

/// The raster formats QQL imports. SVG is never imported.
enum ImageFormat {
  png('png', 'png'),
  jpeg('jpeg', 'jpg'),
  webp('webp', 'webp');

  const ImageFormat(this.mime, this.extension);

  /// The `image/<mime>` subtype.
  final String mime;

  /// The extension QQL stores the image under, chosen from the content.
  final String extension;
}

/// What one kind of import accepts.
class ImageProfile {
  const ImageProfile({
    required this.maxBytes,
    this.formats = const {ImageFormat.png, ImageFormat.jpeg, ImageFormat.webp},
  });

  /// Exercise, Shared Image Library, Image Bank and portable images.
  static const exerciseImage = ImageProfile(maxBytes: 50 * 1024);

  /// Custom Lesson icons (normalized to a 256 × 256 PNG afterwards).
  static const lessonIcon = ImageProfile(maxBytes: 2 * 1024 * 1024);

  /// Custom Course flags (normalized afterwards); PNG or JPEG only.
  static const courseFlag = ImageProfile(
    maxBytes: 2 * 1024 * 1024,
    formats: {ImageFormat.png, ImageFormat.jpeg},
  );

  /// A Course ZIP cover.
  static const courseCover = ImageProfile(maxBytes: 100 * 1024);

  final int maxBytes;
  final Set<ImageFormat> formats;
}

/// An image refused by [ImageValidator]. A [FormatException], so existing
/// import paths report it like any other invalid file.
class ImageValidationException extends FormatException {
  const ImageValidationException(super.message);
}

/// What the structural check learned without decoding pixels.
class ImageFacts {
  const ImageFacts(this.format, this.width, this.height, this.metadataBytes);

  final ImageFormat format;
  final int width;
  final int height;
  final int metadataBytes;
}

/// Image bytes that passed the full check. Only [ImageValidator.validate]
/// creates one, so storage that accepts only this type cannot receive
/// unchecked bytes.
class ValidatedImage {
  ValidatedImage._(this.bytes, this.facts);

  final Uint8List bytes;
  final ImageFacts facts;

  ImageFormat get format => facts.format;
  int get width => facts.width;
  int get height => facts.height;
}

/// The one authoritative check for every imported raster image.
abstract final class ImageValidator {
  static const maxDimension = 4096;

  /// Kept separate from [maxDimension] on purpose: 4096 × 4096 equals this
  /// today, and raising one must not silently raise the other.
  static const maxPixels = 16777216;
  static const maxMetadataBytes = 256 * 1024;
  static const maxProfileBytes = 128 * 1024;

  static const _damaged = ImageValidationException(
    'The image is damaged. Export it again as a still PNG, JPEG or WebP image and retry.',
  );
  static const _animated = ImageValidationException(
    'Animated images are not supported. Choose a still PNG, JPEG or WEBP image.',
  );

  /// The format the bytes actually are, whatever the file name says.
  static ImageFormat? sniff(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return ImageFormat.png;
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return ImageFormat.jpeg;
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return ImageFormat.webp;
    }
    return null;
  }

  /// The structural check, in pure Dart: no pixels are decoded, so it is
  /// cheap enough for every entry of an Image Bank.
  static ImageFacts inspect(Uint8List bytes, ImageProfile profile) {
    if (bytes.isEmpty) {
      throw const ImageValidationException('The image file is empty. Choose a picture that opens normally and try again.');
    }
    if (bytes.length > profile.maxBytes) {
      throw ImageValidationException(
        'The image is larger than ${_size(profile.maxBytes)}. Export a smaller picture and try again.',
      );
    }
    final format = sniff(bytes);
    if (format == null) {
      final kind = unexpectedMediaKind(bytes);
      final page = webPageKind(bytes);
      throw ImageValidationException(
        page != null
            ? 'This file is a web page, not an image. Download the actual picture and try again.'
            : kind == null
            ? 'This is not a readable PNG, JPEG or WebP image. Export the picture again and retry.'
            : 'This file is a $kind, not an image. Choose a real PNG, JPEG or WebP picture; changing its name will not convert it.',
      );
    }
    if (!profile.formats.contains(format)) {
      throw ImageValidationException(
        'This image format is not accepted here. Export it as ${profile.formats.map((f) => f.name.toUpperCase()).join(' or ')} and try again.',
      );
    }
    final facts = switch (format) {
      ImageFormat.png => _png(bytes),
      ImageFormat.jpeg => _jpeg(bytes),
      ImageFormat.webp => _webp(bytes),
    };
    if (facts.width < 1 || facts.height < 1) throw _damaged;
    if (facts.width > maxDimension || facts.height > maxDimension) {
      throw const ImageValidationException(
        'The image dimensions are too large. Resize it to at most 4096 pixels on either side and try again.',
      );
    }
    if (facts.width * facts.height > maxPixels) {
      throw const ImageValidationException('The image has too many pixels. Resize it and try again.');
    }
    if (facts.metadataBytes > maxMetadataBytes) {
      throw const ImageValidationException(
        'The image carries too much embedded metadata. Export it without extra metadata and try again.',
      );
    }
    return facts;
  }

  /// [inspect], then one bounded decode of the first frame: the size is known
  /// to be within limits before any pixels are allocated.
  static Future<ValidatedImage> validate(
    Uint8List bytes,
    ImageProfile profile,
  ) async {
    final facts = inspect(bytes, profile);
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width != facts.width ||
          descriptor.height != facts.height) {
        throw _damaged;
      }
      codec = await descriptor.instantiateCodec();
      if (codec.frameCount != 1) throw _animated;
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } on ImageValidationException {
      rethrow;
    } catch (_) {
      throw _damaged;
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
    return ValidatedImage._(Uint8List.fromList(bytes), facts);
  }

  static String _size(int bytes) => bytes >= 1024 * 1024
      ? '${bytes ~/ (1024 * 1024)} MB'
      : '${bytes ~/ 1024} KB';

  static String _type(Uint8List bytes, int offset) =>
      ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true);

  static const _pngDepths = {
    0: {1, 2, 4, 8, 16},
    2: {8, 16},
    3: {1, 2, 4, 8},
    4: {8, 16},
    6: {8, 16},
  };

  static ImageFacts _png(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    var offset = 8;
    var width = 0;
    var height = 0;
    var metadata = 0;
    var sawData = false;
    var first = true;
    while (offset + 12 <= bytes.length) {
      final length = data.getUint32(offset);
      if (length > bytes.length - offset - 12) throw _damaged;
      final type = _type(bytes, offset + 4);
      if (!RegExp(r'^[A-Za-z]{4}$').hasMatch(type)) throw _damaged;
      final crc = data.getUint32(offset + 8 + length);
      if (getCrc32(bytes.sublist(offset + 4, offset + 8 + length)) != crc) {
        throw _damaged;
      }
      final payload = offset + 8;
      if (first) {
        if (type != 'IHDR' || length != 13) throw _damaged;
        width = data.getUint32(payload);
        height = data.getUint32(payload + 4);
        final depth = bytes[payload + 8];
        final colour = bytes[payload + 9];
        if (!(_pngDepths[colour]?.contains(depth) ?? false) ||
            bytes[payload + 10] != 0 ||
            bytes[payload + 11] != 0 ||
            bytes[payload + 12] > 1) {
          throw _damaged;
        }
        first = false;
      } else if (type == 'IHDR') {
        throw _damaged;
      }
      if (type == 'acTL' || type == 'fcTL' || type == 'fdAT') throw _animated;
      if (type == 'IDAT' && length > 0) sawData = true;
      final ancillary = type.codeUnitAt(0) >= 0x61;
      if (!ancillary && !{'IHDR', 'PLTE', 'IDAT', 'IEND'}.contains(type)) {
        throw _damaged;
      }
      if (ancillary) {
        metadata += length;
        if (type == 'iCCP' && length > maxProfileBytes) {
          throw const ImageValidationException(
            'The image carries an oversized colour profile. Export it without the profile and try again.',
          );
        }
      }
      offset = payload + length + 4;
      if (type == 'IEND') {
        if (length != 0 || !sawData || offset != bytes.length) throw _damaged;
        return ImageFacts(ImageFormat.png, width, height, metadata);
      }
    }
    throw _damaged;
  }

  static const _sofMarkers = {
    0xc0,
    0xc1,
    0xc2,
    0xc3,
    0xc5,
    0xc6,
    0xc7,
    0xc9,
    0xca,
    0xcb,
    0xcd,
    0xce,
    0xcf,
  };

  static ImageFacts _jpeg(Uint8List bytes) {
    if (bytes.length < 4 ||
        bytes[bytes.length - 2] != 0xff ||
        bytes.last != 0xd9) {
      throw _damaged;
    }
    final data = ByteData.sublistView(bytes);
    var offset = 2;
    var width = 0;
    var height = 0;
    var metadata = 0;
    var profile = 0;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset++] != 0xff) throw _damaged;
      while (offset < bytes.length && bytes[offset] == 0xff) {
        offset++;
      }
      if (offset >= bytes.length) throw _damaged;
      final marker = bytes[offset++];
      // Nothing standalone (SOI, EOI, RST, TEM) belongs before the scan.
      if (marker == 0x00 ||
          marker == 0x01 ||
          marker == 0xd8 ||
          marker == 0xd9 ||
          (marker >= 0xd0 && marker <= 0xd7)) {
        throw _damaged;
      }
      if (offset + 2 > bytes.length) throw _damaged;
      final length = data.getUint16(offset);
      if (length < 2 || offset + length > bytes.length - 2) throw _damaged;
      if ((marker >= 0xe0 && marker <= 0xef) || marker == 0xfe) {
        metadata += length - 2;
        if (marker == 0xe2 &&
            length >= 14 &&
            ascii.decode(
                  bytes.sublist(offset + 2, offset + 14),
                  allowInvalid: true,
                ) ==
                'ICC_PROFILE\x00') {
          profile += length - 2;
          if (profile > maxProfileBytes) {
            throw const ImageValidationException(
              'The image carries an oversized colour profile. Export it without the profile and try again.',
            );
          }
        }
      }
      if (_sofMarkers.contains(marker)) {
        if (length < 8) throw _damaged;
        final precision = bytes[offset + 2];
        height = data.getUint16(offset + 3);
        width = data.getUint16(offset + 5);
        final components = bytes[offset + 7];
        if ((precision != 8 && precision != 12) ||
            height == 0 ||
            width == 0 ||
            components < 1 ||
            components > 4 ||
            length != 8 + 3 * components) {
          throw _damaged;
        }
      }
      if (marker == 0xda) {
        if (width == 0 || height == 0) throw _damaged;
        return ImageFacts(ImageFormat.jpeg, width, height, metadata);
      }
      offset += length;
    }
    throw _damaged;
  }

  static ImageFacts _webp(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    if (data.getUint32(4, Endian.little) != bytes.length - 8) throw _damaged;
    var offset = 12;
    var width = 0;
    var height = 0;
    var metadata = 0;
    var sawPixels = false;
    while (offset + 8 <= bytes.length) {
      final type = _type(bytes, offset);
      final length = data.getUint32(offset + 4, Endian.little);
      final payload = offset + 8;
      if (length > bytes.length - payload) throw _damaged;
      switch (type) {
        case 'VP8X':
          if (length != 10) throw _damaged;
          if (bytes[payload] & 0x02 != 0) throw _animated;
          width =
              1 +
              bytes[payload + 4] +
              (bytes[payload + 5] << 8) +
              (bytes[payload + 6] << 16);
          height =
              1 +
              bytes[payload + 7] +
              (bytes[payload + 8] << 8) +
              (bytes[payload + 9] << 16);
        case 'ANIM' || 'ANMF':
          throw _animated;
        case 'VP8 ':
          if (length < 10 ||
              bytes[payload + 3] != 0x9d ||
              bytes[payload + 4] != 0x01 ||
              bytes[payload + 5] != 0x2a) {
            throw _damaged;
          }
          if (width == 0) {
            width = data.getUint16(payload + 6, Endian.little) & 0x3fff;
            height = data.getUint16(payload + 8, Endian.little) & 0x3fff;
          }
          sawPixels = true;
        case 'VP8L':
          if (length < 5 || bytes[payload] != 0x2f) throw _damaged;
          if (width == 0) {
            final bits = data.getUint32(payload + 1, Endian.little);
            width = (bits & 0x3fff) + 1;
            height = ((bits >> 14) & 0x3fff) + 1;
          }
          sawPixels = true;
        case 'ALPH':
          break;
        case 'ICCP':
          if (length > maxProfileBytes) {
            throw const ImageValidationException(
              'The image carries an oversized colour profile. Export it without the profile and try again.',
            );
          }
          metadata += length;
        default:
          // EXIF, XMP and anything unknown count as metadata.
          metadata += length;
      }
      offset = payload + length + (length.isOdd ? 1 : 0);
    }
    if (!sawPixels || offset != bytes.length) throw _damaged;
    return ImageFacts(ImageFormat.webp, width, height, metadata);
  }
}
