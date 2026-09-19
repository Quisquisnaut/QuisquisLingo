import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/course_models.dart';

/// Every short text value stored anywhere in the persisted Courses. A managed
/// media file is "referenced" when its path appears as one of those values, so
/// detection does not depend on which field holds the path.
///
/// Courses can share a file: Duplicate, Fork and Copy as New Course copy a
/// clip's `filePath` unchanged, so never delete a file without asking this
/// index first.
class MediaReferenceIndex {
  MediaReferenceIndex._(this._values, this.isComplete);

  /// [stores] are the decoded stored-course maps. When [isComplete] is false
  /// (some store could not be read) nothing may be deleted.
  factory MediaReferenceIndex.fromStoredJson(
    Iterable<Object?> stores, {
    bool isComplete = true,
  }) {
    final values = <String>{};
    void visit(Object? node) {
      if (node is String) {
        // Long values are embedded data (flags, portable images), not paths.
        if (node.length <= 1024 && !node.startsWith('data:')) {
          values.add(normalize(node));
        }
      } else if (node is Map) {
        node.values.forEach(visit);
      } else if (node is Iterable) {
        node.forEach(visit);
      }
    }

    stores.forEach(visit);
    return MediaReferenceIndex._(values, isComplete);
  }

  static String normalize(String path) =>
      path.replaceAll('\\', '/').toLowerCase();

  final Set<String> _values;
  final bool isComplete;

  bool references(String path) => _values.contains(normalize(path));

  /// Managed (app-copied) audio files a Course points at. Bundled `assets/`
  /// recordings are never managed files.
  static Set<String> audioPaths(Course course) => {
    for (final clip in course.audioLibrary)
      if (clip.filePath.trim().isNotEmpty &&
          !clip.filePath.startsWith('assets/'))
        clip.filePath,
  };
}

/// Deletes managed MP3 files that no persisted Course references any more.
///
/// Deliberately conservative: it deletes nothing when the reference index is
/// incomplete, only removes regular files (never links) inside QQL's own
/// `quisquislingo_audio` folder, and never throws.
class ManagedAudioCleanup {
  ManagedAudioCleanup({Future<Directory> Function()? supportDirectory})
    : _support = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _support;

  static String _canonical(String path) {
    final value = Uri.file(path).normalizePath().toFilePath();
    return Platform.isWindows ? value.toLowerCase() : value;
  }

  /// Returns how many files were deleted.
  Future<int> deleteUnreferenced(
    Iterable<String> candidates,
    MediaReferenceIndex index,
  ) async {
    if (!index.isComplete) return 0;
    var deleted = 0;
    try {
      final root = Directory(
        '${(await _support()).path}${Platform.pathSeparator}quisquislingo_audio',
      );
      final rootPrefix = '${_canonical(root.path)}${Platform.pathSeparator}';
      for (final candidate in candidates.toSet()) {
        try {
          if (index.references(candidate)) continue;
          if (!_canonical(candidate).startsWith(rootPrefix)) continue;
          if (FileSystemEntity.typeSync(candidate, followLinks: false) !=
              FileSystemEntityType.file) {
            continue;
          }
          await File(candidate).delete();
          deleted++;
          try {
            // Succeeds only when the course folder is now empty.
            await File(candidate).parent.delete();
          } catch (_) {}
        } catch (_) {}
      }
    } catch (_) {}
    return deleted;
  }
}
