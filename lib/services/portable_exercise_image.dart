import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Portable images live in the Course JSON's existing prompt/item asset field.
/// Importing reads and validates the source without writing a managed file.
abstract final class PortableExerciseImageService {
  static const maxImageBytes = 50 * 1024;
  static const maxImageDimension = 4096;
  static final _bundled = RegExp(
    r'^assets/exercise_images/(?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_-]+\.(?:png|jpg|jpeg|webp)$',
  );
  static final _embedded = RegExp(
    r'^data:image/(png|jpeg|webp);base64,([A-Za-z0-9+/]+={0,2})$',
  );

  static bool isPortable(String asset) {
    try {
      decode(asset);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Decodes bounded embedded bytes, or returns null for a safe bundled path.
  /// Actual image decoding is performed during import and by the image widget.
  static Uint8List? decode(String asset) {
    if (_bundled.hasMatch(asset)) return null;
    // Bound work before matching or allocating decoded bytes.
    if (asset.length > ((maxImageBytes + 2) ~/ 3) * 4 + 32) {
      throw const FormatException('Exercise images must not exceed 50 KB.');
    }
    final match = _embedded.firstMatch(asset);
    if (match == null) {
      throw const FormatException(
        'Use a bundled exercise image or an imported portable PNG, JPEG or WEBP image. Absolute paths are not supported.',
      );
    }
    final encoded = match.group(2)!;
    final bytes = base64Decode(encoded);
    if (bytes.isEmpty || bytes.length > maxImageBytes) {
      throw const FormatException('Exercise images must be 1 byte to 50 KB.');
    }
    if (base64Encode(bytes) != encoded || _mime(bytes) != match.group(1)) {
      throw const FormatException(
        'Exercise image data or image format is invalid.',
      );
    }
    final dimensions = _dimensions(bytes, match.group(1)!);
    if (dimensions.$1 < 1 ||
        dimensions.$2 < 1 ||
        dimensions.$1 > maxImageDimension ||
        dimensions.$2 > maxImageDimension) {
      throw const FormatException(
        'Exercise image dimensions must be between 1 and 4096 pixels.',
      );
    }
    return bytes;
  }

  static Future<String> fromFile(File source) async {
    if (await source.length() > maxImageBytes) {
      throw const FormatException('Exercise images must not exceed 50 KB.');
    }
    final bytes = await source.readAsBytes();
    final mime = _mime(bytes);
    if (mime == null) {
      throw const FormatException('Choose a readable PNG, JPEG or WEBP image.');
    }
    final asset = 'data:image/$mime;base64,${base64Encode(bytes)}';
    await validate(asset);
    return asset;
  }

  /// Validates the compressed pixel stream at an asynchronous authoring gate.
  /// [decode] checks the bounded container synchronously for Audit/rendering.
  static Future<void> validate(String asset) async {
    final bytes = decode(asset);
    if (bytes == null) return;
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > maxImageDimension ||
          descriptor.height > maxImageDimension) {
        throw const FormatException(
          'Exercise image dimensions must not exceed 4096 pixels.',
        );
      }
      codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Choose a readable PNG, JPEG or WEBP image.');
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  static (int, int) _dimensions(Uint8List bytes, String mime) {
    const invalid = FormatException(
      'Exercise image data are truncated or malformed.',
    );
    final data = ByteData.sublistView(bytes);
    if (mime == 'png') {
      var offset = 8;
      var width = 0;
      var height = 0;
      var hasPixels = false;
      while (offset + 12 <= bytes.length) {
        final length = data.getUint32(offset);
        if (length > bytes.length - offset - 12) throw invalid;
        final type = ascii.decode(
          bytes.sublist(offset + 4, offset + 8),
          allowInvalid: true,
        );
        if (offset == 8) {
          if (type != 'IHDR' || length != 13) throw invalid;
          width = data.getUint32(offset + 8);
          height = data.getUint32(offset + 12);
        } else if (type == 'IHDR') {
          throw invalid;
        }
        if (type == 'IDAT' && length > 0) hasPixels = true;
        offset += length + 12;
        if (type == 'IEND') {
          if (length != 0 || !hasPixels || offset != bytes.length) {
            throw invalid;
          }
          return (width, height);
        }
      }
      throw invalid;
    }
    if (mime == 'jpeg') {
      if (bytes[bytes.length - 2] != 255 || bytes.last != 217) throw invalid;
      var offset = 2;
      var width = 0;
      var height = 0;
      while (offset + 4 <= bytes.length) {
        if (bytes[offset++] != 255) throw invalid;
        while (offset < bytes.length && bytes[offset] == 255) {
          offset++;
        }
        if (offset >= bytes.length) throw invalid;
        final marker = bytes[offset++];
        if (marker == 0 || marker == 216 || marker == 217) throw invalid;
        if (offset + 2 > bytes.length) throw invalid;
        final length = data.getUint16(offset);
        if (length < 2 || offset + length > bytes.length - 2) throw invalid;
        if (const {
          192,
          193,
          194,
          195,
          197,
          198,
          199,
          201,
          202,
          203,
          205,
          206,
          207,
        }.contains(marker)) {
          if (length < 8) throw invalid;
          height = data.getUint16(offset + 3);
          width = data.getUint16(offset + 5);
        }
        if (marker == 218) {
          if (width == 0 ||
              height == 0 ||
              offset + length >= bytes.length - 2) {
            throw invalid;
          }
          return (width, height);
        }
        offset += length;
      }
      throw invalid;
    }
    if (data.getUint32(4, Endian.little) != bytes.length - 8) throw invalid;
    var offset = 12;
    var width = 0;
    var height = 0;
    var hasPixels = false;
    while (offset + 8 <= bytes.length) {
      final type = ascii.decode(
        bytes.sublist(offset, offset + 4),
        allowInvalid: true,
      );
      final length = data.getUint32(offset + 4, Endian.little);
      final payload = offset + 8;
      if (length > bytes.length - payload) throw invalid;
      if (type == 'VP8X') {
        if (length != 10) throw invalid;
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
      } else if (type == 'VP8 ') {
        if (length < 10 ||
            bytes[payload + 3] != 157 ||
            bytes[payload + 4] != 1 ||
            bytes[payload + 5] != 42) {
          throw invalid;
        }
        if (width == 0) {
          width = data.getUint16(payload + 6, Endian.little) & 16383;
          height = data.getUint16(payload + 8, Endian.little) & 16383;
        }
        hasPixels = true;
      } else if (type == 'VP8L') {
        if (length < 5 || bytes[payload] != 47) throw invalid;
        if (width == 0) {
          final bits = data.getUint32(payload + 1, Endian.little);
          width = (bits & 16383) + 1;
          height = ((bits >> 14) & 16383) + 1;
        }
        hasPixels = true;
      } else if (type == 'ANMF') {
        if (length < 24) throw invalid;
        hasPixels = true;
      }
      offset = payload + length + (length.isOdd ? 1 : 0);
    }
    if (!hasPixels || offset != bytes.length) throw invalid;
    return (width, height);
  }

  static String? _mime(Uint8List bytes) {
    if (bytes.length >= 24 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10) {
      return 'png';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      return 'jpeg';
    }
    if (bytes.length >= 16 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'webp';
    }
    return null;
  }
}
