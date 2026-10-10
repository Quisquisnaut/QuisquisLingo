import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/import/bounded_zip_reader.dart';

Uint8List _zip(List<ArchiveFile> files) {
  final archive = Archive();
  for (final file in files) {
    archive.addFile(file);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

BoundedZipReader _open(Uint8List zip, {int maxEntries = 100}) =>
    BoundedZipReader.open(
      InputMemoryStream(zip),
      label: 'Test ZIP',
      maxEntries: maxEntries,
      maxTotalBytes: 1024 * 1024,
    );

int _find(Uint8List bytes, int signature, {bool last = false}) {
  final view = ByteData.sublistView(bytes);
  if (last) {
    for (var i = bytes.length - 4; i >= 0; i--) {
      if (view.getUint32(i, Endian.little) == signature) return i;
    }
  } else {
    for (var i = 0; i <= bytes.length - 4; i++) {
      if (view.getUint32(i, Endian.little) == signature) return i;
    }
  }
  return -1;
}

Matcher _refused(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

List<int> _text(int n) => List.generate(4000, (i) => 65 + (i * n) % 26);

// Build 270 Revision 4: the ZIP's own end record is checked before the
// archive library reads its directory; entries may not overlap; a local
// header must use the central directory's compression.
void main() {
  test('an ordinary ZIP still opens and reads', () {
    final reader = _open(
      _zip([
        ArchiveFile.bytes('a.txt', _text(1)),
        ArchiveFile.bytes('b/c.txt', _text(2)),
      ]),
    );
    expect(reader.entries.map((e) => e.name), ['a.txt', 'b/c.txt']);
    expect(reader.read(reader.entry('b/c.txt')!), _text(2));
  });

  test('the end record\'s entry count decides before parsing', () {
    final zip = _zip([
      for (var i = 0; i < 3; i++) ArchiveFile.bytes('f$i.txt', _text(i)),
    ]);
    expect(() => _open(zip, maxEntries: 2), _refused('too many entries'));
  });

  test('a central directory larger than the file is refused', () {
    final zip = _zip([ArchiveFile.bytes('a.txt', _text(1))]);
    final end = _find(zip, 0x06054b50, last: true);
    // Claim a directory of 2 MB in a file of a few kilobytes.
    ByteData.sublistView(
      zip,
    ).setUint32(end + 12, 2 * 1024 * 1024, Endian.little);
    expect(() => _open(zip), _refused('not a readable'));
  });

  test('a central directory too large for its entries is refused', () {
    // One entry may take 512 bytes of directory on average.
    final zip = _zip([ArchiveFile.bytes('${'n' * 600}.txt', _text(1))]);
    expect(() => _open(zip, maxEntries: 1), _refused('too many entries'));
    expect(_open(zip, maxEntries: 2).entries, hasLength(1));
  });

  test('entries whose stored data overlap are refused', () {
    final zip = _zip([
      ArchiveFile.bytes('a.txt', _text(1)),
      ArchiveFile.bytes('b.txt', _text(2)),
    ]);
    // Stretch the first entry's compressed size over the second entry.
    final central = _find(zip, 0x02014b50);
    final view = ByteData.sublistView(zip);
    final size = view.getUint32(central + 20, Endian.little);
    view.setUint32(central + 20, size + 40, Endian.little);
    expect(() => _open(zip), _refused('overlap'));
  });

  test('a local header with another compression is refused', () {
    final zip = _zip([ArchiveFile.bytes('a.txt', _text(1))]);
    // The local header says bzip2 (12); the central directory deflate.
    ByteData.sublistView(zip).setUint16(8, 12, Endian.little);
    expect(() => _open(zip), _refused('damaged'));
  });
}
