import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'import_result.dart';
import 'selected_external_file.dart';

/// One cancellation signal for a whole import.
class CancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const ImportCancelledException();
  }
}

class ImportCancelledException implements Exception {
  const ImportCancelledException();

  @override
  String toString() => 'The import was cancelled.';
}

/// More bytes arrived than [limit] allows. Counted while reading, never
/// taken from the size a source reports.
class ImportTooLargeException implements Exception {
  const ImportTooLargeException(this.displayName, this.limit);
  final String displayName;
  final int limit;

  @override
  String toString() => '$displayName is larger than the $limit-byte limit.';
}

class ImportEmptyException implements Exception {
  const ImportEmptyException(this.displayName);
  final String displayName;

  @override
  String toString() => '$displayName is empty.';
}

/// Local storage failed while staging (disk full, no permission).
class ImportStorageException implements Exception {
  const ImportStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// A file copied into QQL's private staging folder, with the byte count and
/// SHA-256 measured while it was read. The caller must [discard] it.
class StagedFile {
  StagedFile(this.file, this.displayName, this.length, this.sha256);

  final File file;
  final String displayName;
  final int length;
  final String sha256;

  Future<Uint8List> readBytes() => file.readAsBytes();

  /// Deletes the staged copy; never throws.
  Future<void> discard() async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// The first step of every external import: selection → bounded stream →
/// private staging file. Nothing reaches QQL's real storage from here; the
/// importer validates the staged bytes and commits them itself.
class ImportStager {
  ImportStager({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static const stagingDirectoryName = 'qql_import_staging';

  /// Batch limits for a multiple selection (owner decision).
  static const maxFilesPerBatch = 100;
  static const maxBytesPerBatch = 250 * 1024 * 1024;

  final Future<Directory> Function() _supportDirectory;
  static final Random _random = Random.secure();

  Future<Directory> stagingDirectory() async => Directory(
    '${(await _supportDirectory()).path}${Platform.pathSeparator}'
    '$stagingDirectoryName',
  );

  /// Streams [source] into a new staging file, counting bytes against
  /// [maxBytes] and hashing as it goes. The staging file is removed on any
  /// failure.
  Future<StagedFile> stage(
    SelectedExternalFile source, {
    required int maxBytes,
    CancellationToken? token,
  }) async {
    token?.throwIfCancelled();
    final File part;
    final IOSink sink;
    try {
      final directory = await stagingDirectory();
      await directory.create(recursive: true);
      part = File(
        '${directory.path}${Platform.pathSeparator}${_randomName()}.part',
      );
      sink = part.openWrite();
    } catch (_) {
      throw const ImportStorageException(
        'QQL could not prepare its import folder.',
      );
    }
    var closed = false;
    try {
      final digest = _DigestSink();
      final hasher = sha256.startChunkedConversion(digest);
      var count = 0;
      final stream = await source.openRead();
      try {
        await for (final chunk in stream) {
          token?.throwIfCancelled();
          count += chunk.length;
          if (count > maxBytes) {
            throw ImportTooLargeException(source.displayName, maxBytes);
          }
          hasher.add(chunk);
          sink.add(chunk);
        }
      } on ImportTooLargeException {
        rethrow;
      } on ImportCancelledException {
        rethrow;
      } catch (_) {
        // A vanished file, a disconnected provider, a read error: whatever
        // the source threw, the import could not read it to the end.
        throw ImportAccessException(
          '${source.displayName} could not be read to the end.',
        );
      }
      try {
        await sink.flush();
        await sink.close();
      } on FileSystemException {
        throw const ImportStorageException(
          'QQL could not write the file to its import folder.',
        );
      }
      closed = true;
      if (count == 0) throw ImportEmptyException(source.displayName);
      hasher.close();
      return StagedFile(part, source.displayName, count, '${digest.value}');
    } catch (_) {
      if (!closed) {
        try {
          await sink.close();
        } catch (_) {}
      }
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      rethrow;
    }
  }

  /// Stages several files, one at a time, within the batch limits: at most
  /// [maxFiles] files and [maxBatchBytes] actual bytes in total, each file at
  /// most [maxBytesPerFile]. Every selected file gets a result; successful
  /// ones carry a [StagedFile] the caller must discard.
  Future<ImportBatchResult> stageBatch(
    List<SelectedExternalFile> files, {
    required int maxBytesPerFile,
    int maxFiles = maxFilesPerBatch,
    int maxBatchBytes = maxBytesPerBatch,
    CancellationToken? token,
  }) async {
    final items = <ImportItemResult>[];
    var used = 0;
    var stopped = false;
    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      if (index >= maxFiles || stopped) {
        items.add(
          ImportItemResult(
            file.displayName,
            stopped && token?.isCancelled == true
                ? ImportItemOutcome.cancelled
                : ImportItemOutcome.notProcessedBatchLimit,
          ),
        );
        continue;
      }
      if (token?.isCancelled == true) {
        stopped = true;
        items.add(
          ImportItemResult(file.displayName, ImportItemOutcome.cancelled),
        );
        continue;
      }
      final remaining = maxBatchBytes - used;
      final limit = min(maxBytesPerFile, remaining);
      try {
        final staged = await stage(file, maxBytes: limit, token: token);
        used += staged.length;
        items.add(
          ImportItemResult(
            file.displayName,
            ImportItemOutcome.staged,
            staged: staged,
          ),
        );
      } on ImportTooLargeException {
        if (limit < maxBytesPerFile) {
          // The file itself may be fine; the batch has no room left.
          stopped = true;
          items.add(
            ImportItemResult(
              file.displayName,
              ImportItemOutcome.notProcessedBatchLimit,
            ),
          );
        } else {
          items.add(
            ImportItemResult(file.displayName, ImportItemOutcome.tooLarge),
          );
        }
      } on ImportEmptyException {
        items.add(
          ImportItemResult(
            file.displayName,
            ImportItemOutcome.malformed,
            message: '${file.displayName} is empty.',
          ),
        );
      } on ImportAccessException catch (error) {
        items.add(
          ImportItemResult(
            file.displayName,
            ImportItemOutcome.accessFailure,
            message: error.message,
          ),
        );
      } on ImportStorageException catch (error) {
        items.add(
          ImportItemResult(
            file.displayName,
            ImportItemOutcome.storageFailure,
            message: error.message,
          ),
        );
      } on ImportCancelledException {
        stopped = true;
        items.add(
          ImportItemResult(file.displayName, ImportItemOutcome.cancelled),
        );
      }
    }
    return ImportBatchResult(items);
  }

  /// Writes [bytes] (already checked, for example one entry of a Course
  /// package) to a new staging file and returns it. The caller deletes it;
  /// [removeLeftovers] removes any left behind.
  Future<File> stageBytes(List<int> bytes) async {
    try {
      final directory = await stagingDirectory();
      await directory.create(recursive: true);
      final file = File(
        '${directory.path}${Platform.pathSeparator}${_randomName()}.part',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      throw const ImportStorageException(
        'QQL could not prepare its import folder.',
      );
    }
  }

  /// Removes staging files left by an interrupted import; never throws.
  Future<void> removeLeftovers() async {
    try {
      final directory = await stagingDirectory();
      if (!await directory.exists()) return;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File && entity.path.endsWith('.part')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  static String _randomName() => List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
