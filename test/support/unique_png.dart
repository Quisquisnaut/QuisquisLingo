import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// A small valid PNG (4 x 4, RGB) whose pixels depend on [seed], so each seed
/// gives a different picture: distinct content for duplicate tests, and never
/// one of QQL's own images. Pure Dart; needs no engine.
Uint8List uniquePng(int seed) {
  const size = 4;
  final raw = BytesBuilder();
  for (var y = 0; y < size; y++) {
    raw.addByte(0); // No filter.
    for (var x = 0; x < size; x++) {
      raw.add([
        (seed * 37 + x) & 0xff,
        (seed * 11 + y) & 0xff,
        seed >> 8 & 0xff,
      ]);
    }
  }
  Uint8List chunk(String type, List<int> data) {
    final body = Uint8List.fromList([...type.codeUnits, ...data]);
    final out = ByteData(12 + data.length);
    out.setUint32(0, data.length);
    final bytes = out.buffer.asUint8List()..setAll(4, body);
    out.setUint32(8 + data.length, getCrc32(body));
    return bytes;
  }

  final header = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8) // Bit depth.
    ..setUint8(9, 2); // RGB.
  return Uint8List.fromList([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
    ...chunk('IHDR', header.buffer.asUint8List()),
    ...chunk('IDAT', ZLibCodec().encode(raw.toBytes())),
    ...chunk('IEND', const []),
  ]);
}
