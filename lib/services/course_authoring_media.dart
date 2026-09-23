import 'dart:async';

import 'course_media_store.dart';

/// Owns the lifetime of the media files created while one Course is edited.
///
/// The Course Editor writes a recording into the Course's own media folder as
/// soon as it is imported, long before the single top-level Course
/// confirmation, so between those two moments nothing knows whether the file
/// will be used. This owner records what the folder already held when the
/// editing session opened — which is what separates a file this session
/// created from one that was already there — and removes exactly the
/// session's own unused recordings when the session ends without confirming
/// a Course.
///
/// A confirmed Course still tidies up inside the confirmation itself, through
/// [CourseMediaStore.deleteUnreferenced]; this owner covers the other way out.
class CourseAuthoringMedia {
  CourseAuthoringMedia({
    required this.courseId,
    required Future<Set<String>?> Function() persistedReferences,
    CourseMediaStore? mediaStore,
  }) : _persistedReferences = persistedReferences,
       _media = mediaStore ?? CourseMediaStore() {
    // Taken now, not on first use: an import can only happen after the session
    // is open, so this is the folder as the session found it.
    _openingFiles = _media.storedReferences(courseId);
    // Observe a failed listing here so it cannot surface as an unhandled
    // asynchronous error before the session ends and awaits it.
    unawaited(_openingFiles.catchError((Object _) => const <String>{}));
  }

  /// Every kind of media a Course owns: recordings and pictures alike. Both
  /// are written into the Course folder before the confirmation, so both are
  /// this session's to clean up. Anything `CourseMediaStore` does not
  /// recognise as Course media is never listed, and so is never touched.
  static const Set<String> ownedExtensions = {
    ...CourseMediaStore.audioExtensions,
    ...CourseMediaStore.imageExtensions,
  };

  final String courseId;
  final Future<Set<String>?> Function() _persistedReferences;
  final CourseMediaStore _media;

  late final Future<Set<String>> _openingFiles;
  Future<int>? _discarded;

  /// Completes once the folder's opening contents have been recorded.
  Future<void> get ready async {
    try {
      await _openingFiles;
    } catch (_) {}
  }

  /// Removes the recordings this editing session created that no persisted
  /// Course uses, and reports how many files went.
  ///
  /// Nothing is removed when the opening contents or the persisted Course
  /// cannot be read: a failed read cannot prove that saving failed, so the
  /// media stay for recovery. No stored Course means nothing persisted uses
  /// them, which is the never-confirmed new Course. Safe to call more than
  /// once; only the first call does the work.
  Future<int> discardUnconfirmedMedia() => _discarded ??= _discard();

  Future<int> _discard() async {
    final Set<String> candidates;
    try {
      final opening = await _openingFiles;
      candidates = {
        for (final reference in await _media.storedReferences(courseId))
          if (ownedExtensions.contains(
                CourseMediaStore.extensionOf(reference),
              ) &&
              !opening.contains(reference))
            reference,
      };
    } catch (_) {
      return 0;
    }
    // The usual session imports nothing, so it never reads the stored Course.
    if (candidates.isEmpty) return 0;
    final Set<String>? persisted;
    try {
      persisted = await _persistedReferences();
    } catch (_) {
      return 0;
    }
    var removed = 0;
    for (final reference in candidates) {
      if (persisted != null && persisted.contains(reference)) continue;
      if (await _media.deleteStored(courseId, reference)) removed++;
    }
    return removed;
  }
}
