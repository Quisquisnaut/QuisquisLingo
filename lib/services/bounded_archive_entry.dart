import 'dart:typed_data';

import 'package:archive/archive.dart';

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
