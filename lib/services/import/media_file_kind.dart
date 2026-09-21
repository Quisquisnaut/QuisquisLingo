import 'dart:convert';
import 'dart:typed_data';

import 'web_page_detector.dart';

/// Identifies familiar file signatures only. Validation still belongs to the
/// format-specific validator; this is for useful errors when names are wrong.
String? unexpectedMediaKind(Uint8List bytes) {
  if (webPageKind(bytes) != null) return 'web page';
  if (_starts(bytes, [0x50, 0x4b, 0x03, 0x04]) ||
      _starts(bytes, [0x50, 0x4b, 0x05, 0x06])) {
    return 'ZIP archive';
  }
  if (_starts(bytes, ascii.encode('%PDF-'))) return 'PDF document';
  if (_starts(bytes, [0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10])) {
    return 'PNG image';
  }
  if (_starts(bytes, [0xff, 0xd8, 0xff])) return 'JPEG image';
  if (bytes.length >= 12 &&
      _starts(bytes, ascii.encode('RIFF')) &&
      _startsAt(bytes, 8, ascii.encode('WEBP'))) {
    return 'WebP image';
  }
  if (_starts(bytes, ascii.encode('ID3')) ||
      (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] & 0xe0 == 0xe0)) {
    return 'MP3 recording';
  }
  return null;
}

bool _starts(Uint8List bytes, List<int> signature) =>
    _startsAt(bytes, 0, signature);

bool _startsAt(Uint8List bytes, int offset, List<int> signature) {
  if (bytes.length < offset + signature.length) return false;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[offset + i] != signature[i]) return false;
  }
  return true;
}
