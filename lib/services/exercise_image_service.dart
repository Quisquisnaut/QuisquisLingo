import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../models/exercise_image_metadata.dart';
import 'exercise_image_metadata_service.dart';
import 'file_dialog_service.dart';
import 'import/image_validator.dart';
import 'import/import_result.dart';
import 'import/import_stager.dart';
import 'import/safe_file_name.dart';
import 'import/selected_external_file.dart';

/// An image read from outside QQL that passed [ImageValidator], with the
/// sanitized name it came under. Nothing has been stored yet.
class PickedImage {
  const PickedImage(this.image, this.sourceName);

  final ValidatedImage image;

  /// Display and provenance only; never a storage name.
  final String sourceName;
}

/// The image is already in the Shared Image Library, byte for byte.
class DuplicateImageException implements Exception {
  const DuplicateImageException(this.existing);

  final ExerciseImageMetadata existing;

  @override
  String toString() =>
      'This picture is already in Shared Images as '
      '“${existing.label}”.';
}

/// One file of a multiple image selection.
class PickedImageResult {
  const PickedImageResult(this.name, this.outcome, {this.message, this.picked});

  final String name;
  final ImportItemOutcome outcome;
  final String? message;
  final PickedImage? picked;
}

/// Reads exercise images from the fixed import folder or the system dialog,
/// always through the same staging and [ImageValidator] check, and stores
/// Shared Image Library images under names QQL generates.
class ExerciseImageService {
  ExerciseImageService({
    FileDialogService? fileDialogs,
    Future<Directory> Function()? supportDirectory,
    ImportStager? stager,
  }) : _fileDialogs = fileDialogs ?? FileDialogService(),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _stager = stager ?? ImportStager(supportDirectory: supportDirectory);

  static const int maxImageBytes = 50 * 1024;
  static const int recommendedImageBytes = 15 * 1024;
  static const int recommendedPixels = 256;
  static const Set<String> supportedExtensions = {'png', 'jpg', 'jpeg', 'webp'};

  final FileDialogService _fileDialogs;
  final Future<Directory> Function() _supportDirectory;
  final ImportStager _stager;

  /// False when the system dialog is unsupported; hide Open from….
  bool get fileDialogsAvailable => _fileDialogs.isAvailable;

  Future<Directory> fixedImportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Imports${Platform.pathSeparator}Images',
    );
    await dir.create(recursive: true);
    return dir;
  }

  /// The one image in the fixed import folder, checked.
  Future<PickedImage> readImage() async {
    final importDir = await fixedImportDirectory();
    final candidates = await importDir
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => _supportedName(file.path))
        .toList();
    candidates.sort(
      (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
    );
    if (candidates.isEmpty) {
      throw StateError(
        'No image found in ${importDir.path}. Copy one PNG, JPG, JPEG or WEBP image there and try again.',
      );
    }
    if (candidates.length > 1) {
      throw StateError(
        'More than one image was found in ${importDir.path}. Keep only the image you want to import, then try again.',
      );
    }
    final source = FileSystemSelectedFile(candidates.single.path);
    final StagedFile staged;
    try {
      staged = await _stager.stage(source, maxBytes: maxImageBytes);
    } on ImportTooLargeException {
      throw StateError(_tooLarge);
    } on ImportEmptyException {
      throw StateError('${source.displayName} is empty. Choose a picture that opens normally and try again.');
    } on ImportAccessException catch (error) {
      throw StateError(error.message);
    }
    try {
      return PickedImage(
        await ImageValidator.validate(
          await staged.readBytes(),
          ImageProfile.exerciseImage,
        ),
        source.displayName,
      );
    } finally {
      await staged.discard();
    }
  }

  /// Open from…: one image, through the same check as [readImage]. The image
  /// is null when the user cancelled or the dialog failed; see the dialog
  /// result.
  Future<({FileDialogResult dialog, PickedImage? picked})>
  readImageFromDialog() async {
    final result = await _fileDialogs.openBytes(
      extensions: supportedExtensions.toList(),
      maxBytes: maxImageBytes,
      artifact: 'exercise-image',
    );
    if (result.outcome == FileDialogOutcome.tooLarge) {
      throw StateError(_tooLarge);
    }
    if (result.outcome != FileDialogOutcome.opened) {
      return (dialog: result, picked: null);
    }
    final name = result.displayName!;
    if (!_supportedName(name)) {
      throw StateError('The selected file name is not PNG, JPG, JPEG or WebP. Select a picture in one of those formats.');
    }
    return (
      dialog: result,
      picked: PickedImage(
        await ImageValidator.validate(
          result.bytes!,
          ImageProfile.exerciseImage,
        ),
        name,
      ),
    );
  }

  /// Open image files from…: up to 100 images in one selection, each staged
  /// and checked on its own. Every file gets a result.
  Future<({FileDialogResult dialog, List<PickedImageResult> items})>
  readImagesFromDialog({CancellationToken? token}) async {
    final picked = await _fileDialogs.openFiles(
      extensions: supportedExtensions.toList(),
      maxBytesPerFile: maxImageBytes,
      artifact: 'exercise-images',
      token: token,
    );
    final batch = picked.batch;
    if (batch == null) {
      return (dialog: picked.dialog, items: const <PickedImageResult>[]);
    }
    final items = <PickedImageResult>[];
    try {
      for (final item in batch.items) {
        final staged = item.staged;
        if (staged == null) {
          items.add(
            PickedImageResult(
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
          items.add(
            PickedImageResult(item.displayName, ImportItemOutcome.cancelled),
          );
          continue;
        }
        if (!_supportedName(item.displayName)) {
          items.add(
            PickedImageResult(
              item.displayName,
              ImportItemOutcome.invalidType,
              message: 'Choose a PNG, JPG, JPEG or WEBP image.',
            ),
          );
          continue;
        }
        try {
          final image = await ImageValidator.validate(
            await staged.readBytes(),
            ImageProfile.exerciseImage,
          );
          items.add(
            PickedImageResult(
              item.displayName,
              ImportItemOutcome.staged,
              picked: PickedImage(image, item.displayName),
            ),
          );
        } on FormatException catch (error) {
          items.add(
            PickedImageResult(
              item.displayName,
              ImportItemOutcome.malformed,
              message: error.message,
            ),
          );
        }
      }
    } finally {
      await batch.discardAll();
    }
    return (dialog: picked.dialog, items: items);
  }

  /// Stores [picked] in the Shared Image Library. The Admin check comes
  /// first, so nothing is written for anyone else; the file and its record
  /// are committed together, and the file is removed if the record fails.
  Future<ExerciseImageMetadata> addToSharedLibrary({
    required String actorProfileId,
    required PickedImage picked,
    required ExerciseImageMetadataService metadata,
  }) async {
    await metadata.requireAdmin(actorProfileId);
    // The same picture already in the library (QQL's or this device's) is
    // skipped: a duplicate is decided by content, never by file name.
    final hash = sha256.convert(picked.image.bytes).toString();
    final existing = (await metadata.contentIndex(
      actorProfileId: actorProfileId,
    ))[hash];
    if (existing != null) throw DuplicateImageException(existing);
    final now = DateTime.now();
    final id = 'local_${now.microsecondsSinceEpoch}';
    final dir = Directory(
      '${(await _supportDirectory()).path}${Platform.pathSeparator}exercise_images',
    );
    await dir.create(recursive: true);
    // QQL chooses the name and the extension (from the content), never the
    // external file.
    final target = File(
      '${dir.path}${Platform.pathSeparator}image_$id.${picked.image.format.extension}',
    );
    final temporary = File('${target.path}.part');
    try {
      await temporary.writeAsBytes(picked.image.bytes, flush: true);
      await temporary.rename(target.path);
      final label = _labelFor(picked.sourceName);
      final record = ExerciseImageMetadata(
        id: id,
        label: label,
        category: 'other',
        tags: [label.toLowerCase()],
        assetPath: target.path,
        origin: 'local',
        provenance: ImageProvenance(
          sha256: hash,
          byteLength: picked.image.bytes.length,
          detectedFormat: picked.image.format.extension,
          sourceName: safeDisplayName(picked.sourceName),
          source: ImageProvenance.singleImport,
          importedBy: actorProfileId,
          importedAtUtc: now.toUtc(),
        ),
      );
      await metadata.addLocalRecord(actorProfileId: actorProfileId, record: record);
      return record;
    } catch (_) {
      for (final file in [temporary, target]) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  static String _labelFor(String sourceName) {
    final stem = safeDisplayName(sourceName)
        .replaceFirst(RegExp(r'\.[^.]+$'), '')
        .replaceAll('_', ' ')
        .trim();
    return stem.isEmpty ? 'Imported image' : stem;
  }

  static bool _supportedName(String path) =>
      supportedExtensions.contains(path.toLowerCase().split('.').last);

  static const String _tooLarge =
      'Image is larger than the 50 KB maximum. Compress or resize it before importing.';
}
