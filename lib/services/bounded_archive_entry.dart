import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Inflates [entry] into memory, producing at most [limit] bytes.
///
/// A ZIP entry's declared size is attacker-controlled, and `readBytes()`
/// inflates the whole payload before anyone can look at its length. Writing
/// through [LimitedOutputStream] stops decompression as soon as the output
/// would pass [limit], so a small entry cannot expand into a large allocation.
/// The result must also be exactly [entry]'s declared size, so the per-archive
/// total checked from the central directory bounds the real output too.
///
/// Throws [FormatException] with [overflowMessage] when the entry expands past
/// [limit], and with [damagedMessage] when it cannot be inflated or ends short.
Uint8List readBoundedEntry(
  ArchiveFile entry,
  int limit, {
  required String overflowMessage,
  required String damagedMessage,
}) {
  final output = LimitedOutputStream(limit, overflowMessage: overflowMessage);
  try {
    entry.decompress(output);
  } on FormatException {
    rethrow;
  } catch (_) {
    throw FormatException(damagedMessage);
  }
  final bytes = output.getBytes();
  if (bytes.length != entry.size) throw FormatException(damagedMessage);
  return bytes;
}

/// An in-memory output stream that refuses to grow past [limit] bytes.
class LimitedOutputStream extends OutputStream {
  LimitedOutputStream(this.limit, {required this.overflowMessage})
    : _output = OutputMemoryStream(size: limit),
      super(byteOrder: ByteOrder.littleEndian);

  final int limit;
  final String overflowMessage;
  final OutputMemoryStream _output;

  @override
  int get length => _output.length;

  void _check(int additional) {
    if (additional < 0 || length + additional > limit) {
      throw FormatException(overflowMessage);
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    _output.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    _output.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    _output.writeStream(stream);
  }

  @override
  void clear() => _output.clear();

  @override
  void flush() => _output.flush();

  @override
  Uint8List subset(int start, [int? end]) => _output.subset(start, end);
}
