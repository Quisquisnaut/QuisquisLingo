import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/course_models.dart';
import 'audio_diagnostic_service.dart';
import 'course_media_store.dart';
import 'file_dialog_service.dart';
import 'import/import_result.dart';
import 'import/import_stager.dart';
import 'import/mp3_validator.dart';
import 'import/selected_external_file.dart';

/// Manages creator-supplied recorded speech. Imported MP3 files are copied into
/// the Course's own media folder and named by content (`media:<sha256>.mp3`,
/// see [CourseMediaStore]), so moving or deleting the creator's original file
/// does not break the Course and the reference is the same on every device.
class RecordedAudioService {
  RecordedAudioService({
    FileDialogService? fileDialogs,
    Future<Directory> Function()? supportDirectory,
    ImportStager? stager,
  }) : _fileDialogs = fileDialogs ?? FileDialogService(),
       _media = CourseMediaStore(supportDirectory: supportDirectory),
       _stager = stager ?? ImportStager(supportDirectory: supportDirectory);

  static const int maxMp3Bytes = 50 * 1024 * 1024;

  final FileDialogService _fileDialogs;
  final CourseMediaStore _media;
  final ImportStager _stager;

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

  Future<Directory> fixedImportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Imports${Platform.pathSeparator}Audio',
    );
    await dir.create(recursive: true);
    return dir;
  }

  /// Imports every MP3 in the fixed folder. Each is staged under the 50 MB
  /// limit and checked by [Mp3Validator] before any is stored, so one bad
  /// file stores nothing. Recordings in [existingReferences] are skipped.
  Future<List<CourseAudioClip>> importMp3Files(
    String courseId, {
    Set<String> existingReferences = const {},
  }) async {
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
    // Checked copies wait in staging, not in memory, until all have passed.
    final checked = <StagedFile>[];
    try {
      for (final source in sources) {
        final selected = FileSystemSelectedFile(source.path);
        final StagedFile staged;
        try {
          staged = await _stager.stage(selected, maxBytes: maxMp3Bytes);
        } on ImportTooLargeException {
          throw StateError(_tooLarge);
        } on ImportEmptyException {
          throw StateError('${selected.displayName} is empty.');
        } on ImportAccessException catch (error) {
          throw StateError(error.message);
        }
        checked.add(staged);
        try {
          await Mp3Validator.validate(await staged.readBytes());
        } on Mp3ValidationException catch (error) {
          throw StateError('${selected.displayName}: ${error.message}');
        }
      }
      final out = <CourseAudioClip>[];
      final batchStamp = DateTime.now().microsecondsSinceEpoch;
      final seen = {...existingReferences};
      for (var index = 0; index < checked.length; index++) {
        final bytes = await checked[index].readBytes();
        if (!seen.add(CourseMediaStore.referenceFor(bytes, 'mp3'))) continue;
        final reference = await _media.addBytes(courseId, bytes, 'mp3');
        out.add(
          CourseAudioClip(
            id: _clipId(batchStamp, index),
            text: '',
            filePath: reference,
          ),
        );
      }
      return out;
    } finally {
      for (final staged in checked) {
        await staged.discard();
      }
    }
  }

  /// Open from…: pick one MP3 in the system dialog and store it exactly as
  /// [importMp3Files] stores a folder file (same 50 MB check, same course
  /// audio folder, same clip naming). The clip is null when the user cancelled
  /// or the dialog failed; see the dialog result. Import one file at a time.
  Future<({FileDialogResult dialog, CourseAudioClip? clip})>
  importMp3FromDialog(String courseId) async {
    final picked = await _fileDialogs.openBytes(
      extensions: const ['mp3'],
      maxBytes: maxMp3Bytes,
      artifact: 'mp3',
    );
    if (picked.outcome == FileDialogOutcome.tooLarge) {
      throw StateError(_tooLarge);
    }
    if (picked.outcome != FileDialogOutcome.opened) {
      return (dialog: picked, clip: null);
    }
    final name = picked.displayName!;
    if (!name.toLowerCase().endsWith('.mp3')) {
      throw StateError('Choose an MP3 file.');
    }
    final bytes = picked.bytes!;
    if (bytes.length > maxMp3Bytes) throw StateError(_tooLarge);
    await Mp3Validator.validate(bytes);
    final reference = await _media.addBytes(courseId, bytes, 'mp3');
    return (
      dialog: picked,
      clip: CourseAudioClip(
        id: _clipId(DateTime.now().microsecondsSinceEpoch, 0),
        text: '',
        filePath: reference,
      ),
    );
  }

  /// Open from… with a multiple selection: up to 100 MP3s and 250 MB, each
  /// staged and checked on its own. A recording the Course already has (same
  /// content) is skipped. Every file gets a result.
  Future<
    ({
      FileDialogResult dialog,
      List<CourseAudioClip> clips,
      List<ImportItemResult> results,
    })
  >
  importMp3sFromDialog(
    String courseId, {
    Set<String> existingReferences = const {},
    CancellationToken? token,
  }) async {
    final picked = await _fileDialogs.openFiles(
      extensions: const ['mp3'],
      maxBytesPerFile: maxMp3Bytes,
      artifact: 'mp3-files',
      token: token,
    );
    final batch = picked.batch;
    final clips = <CourseAudioClip>[];
    final results = <ImportItemResult>[];
    if (batch == null) {
      return (dialog: picked.dialog, clips: clips, results: results);
    }
    final seen = {...existingReferences};
    final batchStamp = DateTime.now().microsecondsSinceEpoch;
    try {
      for (final item in batch.items) {
        final staged = item.staged;
        if (staged == null) {
          results.add(
            ImportItemResult(
              item.displayName,
              item.outcome,
              message: item.outcome == ImportItemOutcome.tooLarge
                  ? _tooLarge
                  : item.message,
            ),
          );
          continue;
        }
        if (token?.isCancelled == true) {
          results.add(
            ImportItemResult(item.displayName, ImportItemOutcome.cancelled),
          );
          continue;
        }
        if (!item.displayName.toLowerCase().endsWith('.mp3')) {
          results.add(
            ImportItemResult(
              item.displayName,
              ImportItemOutcome.invalidType,
              message: 'Choose an MP3 file.',
            ),
          );
          continue;
        }
        try {
          final bytes = await staged.readBytes();
          await Mp3Validator.validate(bytes);
          if (!seen.add(CourseMediaStore.referenceFor(bytes, 'mp3'))) {
            results.add(
              ImportItemResult(
                item.displayName,
                ImportItemOutcome.duplicateSkipped,
              ),
            );
            continue;
          }
          final reference = await _media.addBytes(courseId, bytes, 'mp3');
          clips.add(
            CourseAudioClip(
              id: _clipId(batchStamp, clips.length),
              text: '',
              filePath: reference,
            ),
          );
          results.add(
            ImportItemResult(item.displayName, ImportItemOutcome.imported),
          );
        } on Mp3MetadataTooLargeException catch (error) {
          results.add(
            ImportItemResult(
              item.displayName,
              ImportItemOutcome.metadataTooLarge,
              message: error.message,
            ),
          );
        } on FormatException catch (error) {
          results.add(
            ImportItemResult(
              item.displayName,
              ImportItemOutcome.malformed,
              message: error.message,
            ),
          );
        } catch (error) {
          results.add(
            ImportItemResult(
              item.displayName,
              ImportItemOutcome.storageFailure,
              message: '$error',
            ),
          );
        }
      }
    } finally {
      await batch.discardAll();
    }
    return (dialog: picked.dialog, clips: clips, results: results);
  }

  static final Random _random = Random.secure();

  /// Identical recordings now share one stored file, so the file name no
  /// longer makes a clip ID unique; a random suffix does.
  static String _clipId(int batchStamp, int index) =>
      'audio_${batchStamp}_${index}_'
      '${_random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0')}';

  static const String _tooLarge =
      'MP3 files larger than 50 MB are not accepted.';

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

  /// Resolves only sources that exist, without creating an audio player.
  /// Course media is looked up in [courseId]'s folder.
  Future<Source?> resolveSourceForClip(
    CourseAudioClip clip, {
    required String courseId,
  }) async {
    final path = clip.filePath.trim();
    if (path.isEmpty) return null;
    // Bundled course recordings are Flutter assets, not normal filesystem
    // files on Android/iOS. AssetSource expects the path below assets/.
    if (path.startsWith('assets/')) {
      try {
        await rootBundle.load(path);
        return AssetSource(path.substring('assets/'.length));
      } catch (_) {
        return null;
      }
    }
    final file = await _media.existingFile(courseId, path);
    return file == null ? null : DeviceFileSource(file.path);
  }

  Future<bool> playConcatenated(
    String text,
    List<CourseAudioClip> library, {
    required String courseId,
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
          final source = await resolveSourceForClip(clip, courseId: courseId);
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
