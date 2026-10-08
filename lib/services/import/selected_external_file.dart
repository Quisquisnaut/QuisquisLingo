import 'dart:io';
import 'dart:typed_data';

import 'safe_file_name.dart';

/// Where a selected file came from. A document comes from a document
/// provider (Android's Storage Access Framework) as a content URI.
enum ExternalFileSource { filesystem, memory, document }

/// A file chosen outside QQL, read as a stream. No path crosses this
/// interface: document providers do not have one, and import code must not
/// depend on where the user keeps their files.
abstract class SelectedExternalFile {
  /// A sanitized name for display and logs only.
  String get displayName;

  /// Original final path segment for decisions requiring the exact filename.
  /// Never use this unsanitized value in UI, logs or storage paths.
  String get sourceFileName => displayName;

  /// The size the source reports, if any. Advisory only: limits are enforced
  /// against the bytes actually read.
  int? get reportedSize;

  ExternalFileSource get source;

  /// Opens the file's bytes. Throws [ImportAccessException] when the file
  /// cannot be read or is not an ordinary file.
  Future<Stream<List<int>>> openRead();
}

/// The file could not be read: it is not an ordinary file, it vanished, or
/// the provider refused.
class ImportAccessException implements Exception {
  const ImportAccessException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A file on a local filesystem (desktop dialogs return paths).
class FileSystemSelectedFile implements SelectedExternalFile {
  FileSystemSelectedFile(this._path, {this.reportedSize})
    : displayName = safeDisplayName(_path);

  final String _path;

  @override
  final String displayName;

  @override
  String get sourceFileName => _path.split(RegExp(r'[\\/]')).last;

  @override
  final int? reportedSize;

  @override
  ExternalFileSource get source => ExternalFileSource.filesystem;

  @override
  Future<Stream<List<int>>> openRead() async {
    // Checked without following links: a symlink, directory, pipe, socket or
    // device is refused even if it points at something readable.
    final FileSystemEntityType type;
    try {
      type = await FileSystemEntity.type(_path, followLinks: false);
    } catch (_) {
      throw ImportAccessException('$displayName could not be read.');
    }
    if (type == FileSystemEntityType.notFound) {
      throw ImportAccessException('$displayName is no longer there.');
    }
    if (type != FileSystemEntityType.file) {
      throw ImportAccessException('$displayName is not an ordinary file.');
    }
    return File(_path).openRead();
  }
}

/// Bytes already in memory (tests and in-app sources).
class MemorySelectedFile implements SelectedExternalFile {
  MemorySelectedFile(String name, this._bytes)
    : displayName = safeDisplayName(name),
      sourceFileName = name.split(RegExp(r'[\\/]')).last;

  final Uint8List _bytes;

  @override
  final String displayName;

  @override
  final String sourceFileName;

  @override
  int? get reportedSize => _bytes.length;

  @override
  ExternalFileSource get source => ExternalFileSource.memory;

  @override
  Future<Stream<List<int>>> openRead() async => Stream.value(_bytes);
}

/// Whether [path] is an ordinary file, not following links. Fixed-folder
/// imports check exact names such as `flag.png` or `import.json` with this.
Future<bool> isOrdinaryFile(String path) async {
  try {
    return await FileSystemEntity.type(path, followLinks: false) ==
        FileSystemEntityType.file;
  } catch (_) {
    return false;
  }
}
