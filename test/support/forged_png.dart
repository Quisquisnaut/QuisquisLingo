import 'dart:typed_data';
import 'dart:ui' as ui;

/// A structurally valid PNG whose IHDR declares [width] x [height] while the
/// file still carries only the pixels of a tiny image.
///
/// This exists to test dimension guards against a decompression bomb. Rendering
/// a real 20000 x 20000 image would cost the very 1.6 GB allocation the guards
/// exist to prevent, so the header is rewritten instead: IHDR width, height and
/// the chunk CRC. Everything after the header is untouched and valid, so a
/// decoder can still read the header and report the declared size — only an
/// actual decode would fail, which is precisely what a correct guard never
/// reaches.
///
/// Must be called with a live engine (inside `tester.runAsync`).
Future<Uint8List> pngDeclaringDimensions({
  required int width,
  required int height,
}) async {
  final bytes = Uint8List.fromList(await _tinyPng());
  // 0-7 signature, 8-11 IHDR length, 12-15 'IHDR', 16-19 width, 20-23 height,
  // 24-28 bit depth / colour / compression / filter / interlace, 29-32 CRC.
  final view = ByteData.sublistView(bytes);
  view.setUint32(16, width);
  view.setUint32(20, height);
  view.setUint32(29, _crc32(bytes.sublist(12, 29)));
  return bytes;
}

Future<Uint8List> _tinyPng() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 8, 8),
    ui.Paint()..color = const ui.Color(0xff336699),
  );
  final image = await recorder.endRecording().toImage(8, 8);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
