import 'dart:typed_data';

/// A structurally valid MP3 for tests: [frames] MPEG-1 Layer III frames at
/// 128 kbps, 44.1 kHz (header `FF FB 90 00`, 417 bytes each). The frame
/// bodies are filled with [seed], so different seeds give different content
/// (and different `media:` references). [id3] prepends an ID3v2.3 tag holding
/// those raw frame bytes.
Uint8List syntheticMp3({int frames = 8, int seed = 0, List<int>? id3}) {
  const frameLength = 417;
  final out = BytesBuilder(copy: false);
  if (id3 != null) out.add(id3v2Tag(id3));
  for (var i = 0; i < frames; i++) {
    final frame = Uint8List(frameLength)
      ..fillRange(4, frameLength, (seed + i) & 0x7f);
    frame.setAll(0, const [0xff, 0xfb, 0x90, 0x00]);
    out.add(frame);
  }
  return out.toBytes();
}

/// An ID3v2.3 tag around [frames] (already encoded ID3 frames), with a
/// correct synchsafe size.
Uint8List id3v2Tag(List<int> frames) {
  final size = frames.length;
  return Uint8List.fromList([
    ...'ID3'.codeUnits,
    3,
    0,
    0,
    (size >> 21) & 0x7f,
    (size >> 14) & 0x7f,
    (size >> 7) & 0x7f,
    size & 0x7f,
    ...frames,
  ]);
}

/// One ID3v2.3 frame with a plain 32-bit size.
List<int> id3v23Frame(String id, List<int> body) => [
  ...id.codeUnits,
  (body.length >> 24) & 0xff,
  (body.length >> 16) & 0xff,
  (body.length >> 8) & 0xff,
  body.length & 0xff,
  0,
  0,
  ...body,
];
