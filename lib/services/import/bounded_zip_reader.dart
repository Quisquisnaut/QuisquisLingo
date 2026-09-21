import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../bounded_archive_entry.dart';

/// One file listed in a ZIP that passed [BoundedZipReader]'s checks.
class BoundedZipEntry {
  const BoundedZipEntry._(this.name, this.size, this._header);

  /// The entry's path with `\` turned into `/`.
  final String name;

  /// The uncompressed size the central directory declares. [BoundedZipReader.read]
  /// refuses an entry whose content is not exactly this long.
  final int size;

  final ZipFileHeader _header;

  /// The last path segment.
  String get baseName => name.substring(name.lastIndexOf('/') + 1);
}

/// The only ZIP reader for imports (Image Banks and Course packages).
///
/// It reads the central directory and refuses the archive, before anything
/// is inflated, when it finds:
/// - more than `maxEntries` entries, or declared sizes adding up to more
///   than `maxTotalBytes` (a negative size included);
/// - a name that is absolute, has a drive letter, a `.` or `..` segment, an
///   empty segment or a control character;
/// - two names that are the same after `\`→`/` and case folding;
/// - a symbolic link, device, FIFO or socket;
/// - an encrypted entry, or compression other than stored or deflate;
/// - a nested archive (`.zip`, `.7z`, `.rar`, `.tar`, `.gz` and similar);
/// - a local header whose name differs from the central directory's.
/// Folders are accepted and not listed in [entries].
///
/// [read] then inflates one entry at a time, never past its declared size,
/// and checks its CRC-32.
class BoundedZipReader {
  BoundedZipReader._(this.entries, this._label);

  final List<BoundedZipEntry> entries;
  final String _label;

  static const nestedArchiveExtensions = {
    '7z',
    'apk',
    'bz2',
    'cab',
    'gz',
    'iso',
    'jar',
    'lz',
    'lzma',
    'rar',
    'tar',
    'tbz',
    'tgz',
    'txz',
    'xz',
    'z',
    'zip',
    'zst',
  };

  /// [label] names the archive in messages, for example "Image Bank ZIP".
  factory BoundedZipReader.open(
    InputStream input, {
    required String label,
    required int maxEntries,
    required int maxTotalBytes,
  }) {
    final unreadable = FormatException('This is not a readable $label. Create a fresh ZIP archive and try again.');
    final directory = ZipDirectory();
    try {
      directory.read(input);
    } catch (_) {
      throw unreadable;
    }
    final headers = directory.fileHeaders;
    if (headers.isEmpty) throw unreadable;
    if (headers.length > maxEntries) {
      throw FormatException('$label contains too many entries. Remove unnecessary files and make a new ZIP.');
    }
    final seen = <String>{};
    final entries = <BoundedZipEntry>[];
    var total = 0;
    for (final header in headers) {
      final raw = header.filename;
      final name = raw.replaceAll('\\', '/');
      final isFolder = name.endsWith('/');
      final path = isFolder ? name.substring(0, name.length - 1) : name;
      if (path.isEmpty ||
          path.startsWith('/') ||
          RegExp(r'^[A-Za-z]:').hasMatch(path) ||
          RegExp(r'[\x00-\x1f\x7f]').hasMatch(path) ||
          path.split('/').any((s) => s.isEmpty || s == '.' || s == '..')) {
        throw FormatException('$label contains an unsafe path: $raw. Put files in ordinary folders without parent-path segments and make a new ZIP.');
      }
      if (!seen.add(path.toLowerCase())) {
        throw FormatException('$label contains the same name twice: $raw. Give every file a unique name and make a new ZIP.');
      }
      final type = (header.externalFileAttributes >> 16) & 0xf000;
      if (type != 0 && type != 0x8000 && type != 0x4000) {
        throw FormatException(
          '$label contains a link or special file, which is not allowed: $raw. Replace it with an ordinary file and make a new ZIP.',
        );
      }
      if (header.generalPurposeBitFlag & 0x41 != 0) {
        throw FormatException('$label contains an encrypted entry: $raw. Make a ZIP without password protection.');
      }
      if (header.compressionMethod != 0 && header.compressionMethod != 8) {
        throw FormatException(
          '$label uses a compression method QQL does not read: $raw. Make a standard ZIP with stored or deflated files.',
        );
      }
      final size = header.uncompressedSize;
      total += size;
      if (size < 0 || total > maxTotalBytes) {
        throw FormatException(
          '$label expands beyond its ${_megabytes(maxTotalBytes)} limit. Remove files or shrink them and make a new ZIP.',
        );
      }
      if (isFolder || type == 0x4000) {
        if (size != 0) {
          throw FormatException('$label contains a damaged folder: $raw. Recreate the ZIP from the original files.');
        }
        continue;
      }
      final dot = path.lastIndexOf('.');
      if (dot > path.lastIndexOf('/') &&
          nestedArchiveExtensions.contains(
            path.substring(dot + 1).toLowerCase(),
          )) {
        throw FormatException(
          '$label contains another archive, which is not allowed: $raw. Unpack the inner archive and add its supported files directly.',
        );
      }
      if (header.compressionMethod == 0 && header.compressedSize != size) {
        throw FormatException('$label entry $raw is damaged. Recreate the ZIP from the original files.');
      }
      final local = header.file;
      if (local == null || local.filename != raw) {
        throw FormatException('$label entry $raw is damaged. Recreate the ZIP from the original files.');
      }
      entries.add(BoundedZipEntry._(path, size, header));
    }
    return BoundedZipReader._(List.unmodifiable(entries), label);
  }

  /// The entry named exactly [name], or null.
  BoundedZipEntry? entry(String name) {
    for (final entry in entries) {
      if (entry.name == name) return entry;
    }
    return null;
  }

  /// Inflates [entry], stopping as soon as the output would pass its
  /// declared size or [limit], whichever is smaller. The content must be
  /// exactly the declared size and match the stored CRC-32.
  Uint8List read(BoundedZipEntry entry, {int? limit}) {
    final damaged = FormatException('$_label entry ${entry.name} is damaged. Recreate the ZIP from the original files.');
    final cap = limit == null || limit > entry.size ? entry.size : limit;
    if (entry.size > cap) {
      throw FormatException('$_label entry ${entry.name} is too large. Shrink this file and make a new ZIP.');
    }
    final output = LimitedOutputStream(
      cap,
      overflowMessage:
          '$_label entry ${entry.name} expands beyond its '
          'declared size. Recreate the ZIP from the original files.',
    );
    try {
      entry._header.file!.decompress(output);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw damaged;
    }
    final bytes = output.getBytes();
    if (bytes.length != entry.size || getCrc32(bytes) != entry._header.crc32) {
      throw damaged;
    }
    return bytes;
  }

  static String _megabytes(int bytes) => '${bytes ~/ (1024 * 1024)} MB';
}
