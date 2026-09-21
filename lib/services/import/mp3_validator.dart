import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'web_page_detector.dart';

/// An MP3 refused by [Mp3Validator]. A [FormatException], so existing import
/// paths report it like any other invalid file.
class Mp3ValidationException extends FormatException {
  const Mp3ValidationException(super.message);
}

/// The MP3's tags exceed [Mp3Validator.maxMetadataBytes].
class Mp3MetadataTooLargeException extends Mp3ValidationException {
  const Mp3MetadataTooLargeException()
    : super('The MP3 file carries more than 2 MB of tags or metadata.');
}

/// What the check measured.
class Mp3Facts {
  const Mp3Facts({
    required this.frames,
    required this.durationMs,
    required this.metadataBytes,
  });

  final int frames;
  final int durationMs;
  final int metadataBytes;
}

/// The one authoritative MP3 check, used by every route that brings an MP3
/// into QQL: the fixed folder, Open from…, a Course ZIP's recordings and
/// (later) generated audio.
///
/// It walks the file's structure without decoding any audio:
/// - an optional ID3v2 tag at the start, whose declared sizes must fit and
///   whose frames must be well formed; embedded artwork (`APIC`, or `PIC` in
///   ID3v2.2) is refused (owner decision);
/// - MPEG-1, 2 or 2.5 Layer III frames only, with no reserved or free-format
///   values, at least [minFrames] of them back to back, each starting exactly
///   where the previous one ends (variable bit rate is fine);
/// - after the last frame, nothing but an ID3v1 or APEv2 tag;
/// - at most [maxMetadataBytes] of tags in total.
/// Duration comes from the frames walked, never from values the file claims.
abstract final class Mp3Validator {
  static const maxBytes = 50 * 1024 * 1024;
  static const maxMetadataBytes = 2 * 1024 * 1024;
  static const minFrames = 4;

  /// A failsafe on top of the structural limits, not a substitute for them.
  static const watchdog = Duration(seconds: 30);

  static const _damaged = Mp3ValidationException(
    'This is not a valid MP3 file (MPEG audio Layer III).',
  );

  /// [inspect] off the UI isolate, under [watchdog].
  static Future<Mp3Facts> validate(Uint8List bytes) async {
    try {
      return await Isolate.run(() => inspect(bytes)).timeout(watchdog);
    } on Mp3ValidationException {
      rethrow;
    } on FormatException catch (error) {
      throw Mp3ValidationException(error.message);
    } catch (_) {
      throw const Mp3ValidationException('The MP3 file could not be checked.');
    }
  }

  static Mp3Facts inspect(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const Mp3ValidationException('The MP3 file is empty.');
    }
    if (bytes.length > maxBytes) {
      throw const Mp3ValidationException(
        'MP3 files larger than 50 MB are not accepted.',
      );
    }
    switch (webPageKind(bytes)) {
      case WebPageKind.downloadPage:
        throw const Mp3ValidationException(
          'This is not a recording. The file is named .mp3, but it is a '
          'website’s download page: the real download did not happen. '
          'Download the file again and check that it is the audio itself.',
        );
      case WebPageKind.page:
        throw const Mp3ValidationException(
          'This is not a recording. The file is named .mp3, but it is a web '
          'page, probably saved by mistake. Download the audio file again.',
        );
      case null:
        break;
    }
    var offset = 0;
    var metadata = 0;
    if (bytes.length >= 10 && _ascii(bytes, 0, 3) == 'ID3') {
      final tag = _id3v2(bytes);
      offset = tag;
      metadata += tag;
    }
    // Some encoders pad the tag with zeros beyond its declared size.
    while (offset < bytes.length && bytes[offset] == 0) {
      offset++;
      metadata++;
    }

    // Trailing tags are measured first, so the frame walk knows where the
    // audio ends.
    var end = bytes.length;
    if (end - offset >= 128 && _ascii(bytes, end - 128, 3) == 'TAG') {
      end -= 128;
      metadata += 128;
    }
    if (end - offset >= 32 && _ascii(bytes, end - 32, 8) == 'APETAGEX') {
      final data = ByteData.sublistView(bytes);
      final size = data.getUint32(end - 32 + 12, Endian.little);
      final flags = data.getUint32(end - 32 + 20, Endian.little);
      final hasHeader = flags & 0x80000000 != 0;
      final total = size + (hasHeader ? 32 : 0);
      if (size < 32 || total > end - offset) throw _damaged;
      end -= total;
      metadata += total;
    }
    if (metadata > maxMetadataBytes) {
      throw const Mp3MetadataTooLargeException();
    }

    var frames = 0;
    var samples = 0;
    int? version;
    int? sampleRate;
    while (offset < end) {
      final header = _frame(bytes, offset);
      if (header == null) throw _damaged;
      if (version != null &&
          (header.version != version || header.sampleRate != sampleRate)) {
        throw _damaged;
      }
      version = header.version;
      sampleRate = header.sampleRate;
      if (offset + header.length > end) throw _damaged;
      offset += header.length;
      frames++;
      samples += header.samples;
    }
    if (frames < minFrames) throw _damaged;
    return Mp3Facts(
      frames: frames,
      durationMs: samples * 1000 ~/ sampleRate!,
      metadataBytes: metadata,
    );
  }

  static String _ascii(Uint8List bytes, int offset, int length) =>
      ascii.decode(bytes.sublist(offset, offset + length), allowInvalid: true);

  static int _synchsafe(Uint8List bytes, int offset) {
    var value = 0;
    for (var i = 0; i < 4; i++) {
      final byte = bytes[offset + i];
      if (byte & 0x80 != 0) throw _damaged;
      value = (value << 7) | byte;
    }
    return value;
  }

  /// Checks the ID3v2 tag at the start and returns its total length.
  static int _id3v2(Uint8List bytes) {
    final major = bytes[3];
    if (major < 2 || major > 4 || bytes[4] == 0xff) throw _damaged;
    final flags = bytes[5];
    final size = _synchsafe(bytes, 6);
    final total = 10 + size + (major == 4 && flags & 0x10 != 0 ? 10 : 0);
    if (total > bytes.length) throw _damaged;
    if (total > maxMetadataBytes) {
      throw const Mp3MetadataTooLargeException();
    }
    final data = ByteData.sublistView(bytes);
    var offset = 10;
    final tagEnd = 10 + size;
    if (flags & 0x40 != 0 && major >= 3) {
      // Extended header: v2.3 counts the size without itself, v2.4 with.
      final extended = major == 3
          ? data.getUint32(offset) + 4
          : _synchsafe(bytes, offset);
      if (extended < 6 || offset + extended > tagEnd) throw _damaged;
      offset += extended;
    }
    // Unsynchronised tags change frame bytes; their frames are not walked,
    // but the artwork rule still applies by name.
    if (flags & 0x80 != 0) {
      final body = _ascii(bytes, offset, tagEnd - offset);
      if (body.contains('APIC') || (major == 2 && body.contains('PIC'))) {
        throw _artwork;
      }
      return total;
    }
    final idLength = major == 2 ? 3 : 4;
    final headerLength = major == 2 ? 6 : 10;
    while (offset + headerLength <= tagEnd) {
      if (bytes[offset] == 0) break; // Padding.
      final id = _ascii(bytes, offset, idLength);
      if (!RegExp(
        major == 2 ? r'^[A-Z0-9]{3}$' : r'^[A-Z0-9]{4}$',
      ).hasMatch(id)) {
        throw _damaged;
      }
      final frameSize = switch (major) {
        2 =>
          (bytes[offset + 3] << 16) |
              (bytes[offset + 4] << 8) |
              bytes[offset + 5],
        3 => data.getUint32(offset + 4),
        _ => _synchsafe(bytes, offset + 4),
      };
      if (offset + headerLength + frameSize > tagEnd) throw _damaged;
      if (id == 'APIC' || id == 'PIC') throw _artwork;
      offset += headerLength + frameSize;
    }
    return total;
  }

  static const _artwork = Mp3ValidationException(
    'MP3 files with embedded artwork are not accepted. Remove the cover '
    'image from the file and try again.',
  );

  static const _mpeg1Rates = [
    0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, //
  ];
  static const _mpeg2Rates = [
    0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, //
  ];
  static const _sampleRates = {
    3: [44100, 48000, 32000], // MPEG-1
    2: [22050, 24000, 16000], // MPEG-2
    0: [11025, 12000, 8000], // MPEG-2.5
  };

  /// The Layer III frame header at [offset], or null when there is none.
  static ({int version, int sampleRate, int length, int samples})? _frame(
    Uint8List bytes,
    int offset,
  ) {
    if (offset + 4 > bytes.length) return null;
    if (bytes[offset] != 0xff || bytes[offset + 1] & 0xe0 != 0xe0) return null;
    final version = (bytes[offset + 1] >> 3) & 0x3;
    final layer = (bytes[offset + 1] >> 1) & 0x3;
    final bitrateIndex = bytes[offset + 2] >> 4;
    final rateIndex = (bytes[offset + 2] >> 2) & 0x3;
    final padding = (bytes[offset + 2] >> 1) & 0x1;
    // Reserved version, not Layer III, free-format or bad bit rate, reserved
    // sample rate.
    if (version == 1 ||
        layer != 1 ||
        bitrateIndex == 0 ||
        bitrateIndex == 15 ||
        rateIndex == 3) {
      return null;
    }
    final mpeg1 = version == 3;
    final bitrate = (mpeg1 ? _mpeg1Rates : _mpeg2Rates)[bitrateIndex] * 1000;
    final sampleRate = _sampleRates[version]![rateIndex];
    final length = (mpeg1 ? 144 : 72) * bitrate ~/ sampleRate + padding;
    if (length < 4) return null;
    return (
      version: version,
      sampleRate: sampleRate,
      length: length,
      samples: mpeg1 ? 1152 : 576,
    );
  }
}
