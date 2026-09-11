import 'dart:convert';
import 'dart:io';

/// Shared size boundaries for persistent diagnostic text.
abstract final class BoundedLogWriter {
  static const truncationMarker = '[Earlier log entries were removed.]\n';
  static final Map<String, Future<void>> _fileWrites = {};

  static String appendString({
    required String current,
    required String entry,
    required int maximumCharacters,
  }) {
    if (maximumCharacters <= 0) return '';
    final combined = '$current$entry';
    if (combined.length <= maximumCharacters) return combined;
    final available = maximumCharacters - truncationMarker.length;
    if (available <= 0) {
      return truncationMarker.substring(0, maximumCharacters);
    }
    var start = combined.length - available;
    if (start < combined.length &&
        _isLowSurrogate(combined.codeUnitAt(start))) {
      start += 1;
    }
    return '$truncationMarker${combined.substring(start)}';
  }

  static Future<void> appendFile(
    File target,
    String entry, {
    required int maximumBytes,
  }) {
    final key = target.absolute.path;
    final previous = _fileWrites[key];
    final ready = previous == null
        ? Future<void>.value()
        : previous.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    final operation = ready.then(
      (_) => _appendFileOnce(target, entry, maximumBytes: maximumBytes),
    );
    late final Future<void> guarded;
    guarded = operation.whenComplete(() {
      if (identical(_fileWrites[key], guarded)) _fileWrites.remove(key);
    });
    _fileWrites[key] = guarded;
    return guarded;
  }

  static Future<void> _appendFileOnce(
    File target,
    String entry, {
    required int maximumBytes,
  }) async {
    if (maximumBytes <= 0) return;
    await target.parent.create(recursive: true);
    final incoming = utf8.encode(entry);
    final marker = utf8.encode(truncationMarker);
    if (maximumBytes <= marker.length) {
      await target.writeAsBytes(marker.sublist(0, maximumBytes), flush: true);
      return;
    }
    if (incoming.length + marker.length >= maximumBytes) {
      final keep = maximumBytes - marker.length;
      final tail = _validUtf8Tail(incoming, maximumLength: keep);
      await target.writeAsBytes([...marker, ...tail], flush: true);
      return;
    }
    final existingLength = await target.exists() ? await target.length() : 0;
    if (existingLength + incoming.length <= maximumBytes) {
      await target.writeAsBytes(incoming, mode: FileMode.append, flush: true);
      return;
    }

    final keep = maximumBytes - marker.length - incoming.length;
    final file = await target.open(mode: FileMode.read);
    List<int> tail;
    try {
      await file.setPosition(
        (existingLength - keep).clamp(0, existingLength).toInt(),
      );
      tail = _dropLeadingUtf8ContinuationBytes(await file.read(keep));
    } finally {
      await file.close();
    }
    await target.writeAsBytes([...marker, ...tail, ...incoming], flush: true);
  }

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xdc00 && codeUnit <= 0xdfff;

  static List<int> _validUtf8Tail(
    List<int> bytes, {
    required int maximumLength,
  }) {
    final retainedLength = maximumLength.clamp(0, bytes.length).toInt();
    return _dropLeadingUtf8ContinuationBytes(
      bytes.sublist(bytes.length - retainedLength),
    );
  }

  static List<int> _dropLeadingUtf8ContinuationBytes(List<int> bytes) {
    var start = 0;
    while (start < bytes.length && (bytes[start] & 0xc0) == 0x80) {
      start += 1;
    }
    return start == 0 ? bytes : bytes.sublist(start);
  }
}
