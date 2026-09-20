import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/course_models.dart';
import 'audio_diagnostic_service.dart';
import 'file_dialog_service.dart';

/// Manages creator-supplied recorded speech. Imported MP3 files are copied into
/// app-owned storage so moving or deleting the creator's original file does not
/// break the local course. Course packaging can later export this directory as
/// an optional audio pack.
class RecordedAudioService {
  RecordedAudioService({
    FileDialogService? fileDialogs,
    Future<Directory> Function()? supportDirectory,
  }) : _fileDialogs = fileDialogs ?? FileDialogService(),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static const int maxMp3Bytes = 50 * 1024 * 1024;

  // Memory guard for Open from… only; larger files reach the ordinary 50 MB
  // check and get its standard message.
  static const int _dialogReadCap = 128 * 1024 * 1024;

  final FileDialogService _fileDialogs;
  final Future<Directory> Function() _supportDirectory;

  /// False when the system dialog is unsupported; hide Open from….
  bool get fileDialogsAvailable => _fileDialogs.isAvailable;

  static final RegExp _nonWordBoundary = RegExp(
    r'^[^\p{L}\p{M}\p{N}]+|[^\p{L}\p{M}\p{N}]+$',
    unicode: true,
  );

  static String _segmentKey(String value) => value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(_nonWordBoundary, '')
      .toLowerCase();

  static String storageDirectoryForCourseId(String courseId) {
    final value = courseId.trim();
    if (value.isEmpty) {
      throw ArgumentError.value(courseId, 'courseId', 'Course ID is required');
    }
    return 'course_${sha256.convert(utf8.encode(value))}';
  }

  Future<Directory> fixedImportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Imports${Platform.pathSeparator}Audio',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<List<CourseAudioClip>> importMp3Files(String courseId) async {
    final importDir = await fixedImportDirectory();
    final sources = await importDir
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => file.path.toLowerCase().endsWith('.mp3'))
        .toList();
    sources.sort(
      (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
    );
    if (sources.isEmpty) {
      throw StateError(
        'No MP3 files found in ${importDir.path}. Copy the MP3 files you want to import there and try again.',
      );
    }
    final dir = await _courseAudioDirectory(courseId);
    final out = <CourseAudioClip>[];
    final batchStamp = DateTime.now().microsecondsSinceEpoch;
    for (var index = 0; index < sources.length; index++) {
      final source = sources[index];
      final size = await source.length();
      if (size > maxMp3Bytes) throw StateError(_tooLarge);
      final reserved = await _reserveClip(
        dir,
        batchStamp,
        index,
        source.uri.pathSegments.last,
      );
      await source.copy(reserved.path);
      out.add(
        CourseAudioClip(id: reserved.id, text: '', filePath: reserved.path),
      );
    }
    return out;
  }

  /// Open from…: pick one MP3 in the system dialog and store it exactly as
  /// [importMp3Files] stores a folder file (same 50 MB check, same course
  /// audio folder, same clip naming). The clip is null when the user cancelled
  /// or the dialog failed; see the dialog result. Import one file at a time.
  Future<({FileDialogResult dialog, CourseAudioClip? clip})>
  importMp3FromDialog(String courseId) async {
    final picked = await _fileDialogs.openBytes(
      extensions: const ['mp3'],
      maxBytes: _dialogReadCap,
      artifact: 'mp3',
    );
    if (picked.outcome != FileDialogOutcome.opened) {
      return (dialog: picked, clip: null);
    }
    final name = picked.displayName!;
    if (!name.toLowerCase().endsWith('.mp3')) {
      throw StateError('Choose an MP3 file.');
    }
    final bytes = picked.bytes!;
    if (bytes.length > maxMp3Bytes) throw StateError(_tooLarge);
    final dir = await _courseAudioDirectory(courseId);
    final reserved = await _reserveClip(
      dir,
      DateTime.now().microsecondsSinceEpoch,
      0,
      name,
    );
    await File(reserved.path).writeAsBytes(bytes, flush: true);
    return (
      dialog: picked,
      clip: CourseAudioClip(id: reserved.id, text: '', filePath: reserved.path),
    );
  }

  static const String _tooLarge =
      'MP3 files larger than 50 MB are not accepted.';

  Future<Directory> _courseAudioDirectory(String courseId) async {
    final root = await _supportDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}quisquislingo_audio${Platform.pathSeparator}${storageDirectoryForCourseId(courseId)}',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<({String id, String path})> _reserveClip(
    Directory dir,
    int batchStamp,
    int index,
    String sourceName,
  ) async {
    final safeName = sourceName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final baseClipId = 'audio_${batchStamp}_$index';
    var clipId = baseClipId;
    var destination = '${dir.path}${Platform.pathSeparator}${clipId}_$safeName';
    var collision = 2;
    while (await File(destination).exists()) {
      clipId = '${baseClipId}_$collision';
      destination = '${dir.path}${Platform.pathSeparator}${clipId}_$safeName';
      collision += 1;
    }
    return (id: clipId, path: destination);
  }

  List<CourseAudioClip> orphaned(Course course) =>
      course.audioLibrary.where((c) => c.text.trim().isEmpty).toList();

  /// Longest-match segmentation prevents a single-word recording from taking
  /// precedence over an available multi-word expression.
  List<CourseAudioClip>? segment(String text, List<CourseAudioClip> library) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return const [];
    final byText = {
      for (final c in library)
        if (_segmentKey(c.text).isNotEmpty) _segmentKey(c.text): c,
    };
    final out = <CourseAudioClip>[];
    var i = 0;
    while (i < words.length) {
      CourseAudioClip? found;
      int foundLen = 0;
      for (var len = words.length - i; len >= 1; len--) {
        final raw = _segmentKey(words.sublist(i, i + len).join(' '));
        if (byText.containsKey(raw)) {
          found = byText[raw];
          foundLen = len;
          break;
        }
      }
      if (found == null) return null;
      out.add(found);
      i += foundLen;
    }
    return out;
  }

  Source? sourceForClip(CourseAudioClip clip) {
    final path = clip.filePath.trim();
    if (path.isEmpty) return null;
    // Bundled course recordings are Flutter assets, not normal filesystem
    // files on Android/iOS. AssetSource expects the path below assets/.
    if (path.startsWith('assets/')) {
      return AssetSource(path.substring('assets/'.length));
    }
    final file = File(path);
    if (!file.existsSync()) return null;
    return DeviceFileSource(path);
  }

  /// Resolves only sources that exist, without creating an audio player.
  Future<Source?> resolveSourceForClip(CourseAudioClip clip) async {
    final path = clip.filePath.trim();
    if (path.isEmpty) return null;
    if (path.startsWith('assets/')) {
      try {
        await rootBundle.load(path);
        return AssetSource(path.substring('assets/'.length));
      } catch (_) {
        return null;
      }
    }
    final file = File(path);
    return await file.exists() ? DeviceFileSource(path) : null;
  }

  Future<bool> playConcatenated(
    String text,
    List<CourseAudioClip> library, {
    Duration gap = const Duration(milliseconds: 90),
    bool enableDiagnostics = true,
  }) async {
    final lifecycle = AudioDiagnosticLifecycle.start(
      kind: 'recorded',
      enabled: enableDiagnostics,
    );
    AudioPlayer? player;
    var disposalOutcome = 'not_initialized';
    try {
      final clips = segment(text, library);
      final sources = <Source>[];
      if (clips != null) {
        for (final clip in clips) {
          final source = await resolveSourceForClip(clip);
          if (source == null) {
            sources.clear();
            break;
          }
          sources.add(source);
        }
      }
      final resolved =
          clips != null && clips.isNotEmpty && sources.length == clips.length;
      await lifecycle.event(
        'source_resolution',
        outcome: resolved ? 'resolved' : 'unavailable',
        backend: 'audioplayers',
        count: clips?.length ?? 0,
      );
      if (!resolved) return false;
      await lifecycle.event(
        'initialization',
        outcome: 'started',
        backend: 'audioplayers',
      );
      player = AudioPlayer();
      disposalOutcome = 'pending';
      await lifecycle.event(
        'initialization',
        outcome: 'completed',
        backend: 'audioplayers',
      );
      await lifecycle.event(
        'playback',
        outcome: 'started',
        backend: 'audioplayers',
        count: sources.length,
      );
      for (final source in sources) {
        await player.play(source);
        await player.onPlayerComplete.first.timeout(const Duration(minutes: 5));
        await Future<void>.delayed(gap);
      }
      await lifecycle.event(
        'playback',
        outcome: 'completed',
        backend: 'audioplayers',
        count: sources.length,
      );
      return true;
    } catch (error) {
      await lifecycle.event(
        'failure',
        outcome: 'failed',
        backend: 'audioplayers',
        failureType: error.runtimeType.toString(),
      );
      return false;
    } finally {
      if (player != null) {
        try {
          await player.dispose();
          disposalOutcome = 'completed';
        } catch (_) {
          disposalOutcome = 'failed';
        }
      }
      await lifecycle.dispose(outcome: disposalOutcome);
    }
  }
}
