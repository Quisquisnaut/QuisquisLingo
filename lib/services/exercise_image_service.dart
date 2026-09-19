import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

import 'file_dialog_service.dart';

class ExerciseImageService {
  ExerciseImageService({
    FileDialogService? fileDialogs,
    Future<Directory> Function()? supportDirectory,
  }) : _fileDialogs = fileDialogs ?? FileDialogService(),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static const int maxImageBytes = 50 * 1024;
  static const int recommendedImageBytes = 15 * 1024;
  static const int recommendedPixels = 256;
  static const Set<String> supportedExtensions = {'png', 'jpg', 'jpeg', 'webp'};

  // Memory guard for Open from… only; larger files reach the ordinary 50 KB
  // check and get its standard message.
  static const int _dialogReadCap = 8 * 1024 * 1024;

  final FileDialogService _fileDialogs;
  final Future<Directory> Function() _supportDirectory;

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

  Future<String?> importImage() async {
    final importDir = await fixedImportDirectory();
    final candidates = await importDir
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) {
          final ext = file.path.toLowerCase().split('.').last;
          return supportedExtensions.contains(ext);
        })
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
    final source = candidates.single;
    if (await source.length() > maxImageBytes) {
      throw StateError(_tooLarge);
    }
    final target = await _managedTarget(source.uri.pathSegments.last);
    await source.copy(target.path);
    return target.path;
  }

  /// Open from…: pick one image in the system dialog and store it exactly as
  /// [importImage] does (same extension and 50 KB checks, same managed
  /// folder). The path is null when the user cancelled or the dialog failed;
  /// see the dialog result.
  Future<({FileDialogResult dialog, String? path})>
  importImageFromDialog() async {
    final picked = await _fileDialogs.openBytes(
      extensions: supportedExtensions.toList(),
      maxBytes: _dialogReadCap,
      artifact: 'exercise-image',
    );
    if (picked.outcome != FileDialogOutcome.opened) {
      return (dialog: picked, path: null);
    }
    final name = picked.displayName!;
    if (!supportedExtensions.contains(name.toLowerCase().split('.').last)) {
      throw StateError('Choose a PNG, JPG, JPEG or WEBP image.');
    }
    final Uint8List bytes = picked.bytes!;
    if (bytes.length > maxImageBytes) throw StateError(_tooLarge);
    final target = await _managedTarget(name);
    await target.writeAsBytes(bytes, flush: true);
    return (dialog: picked, path: target.path);
  }

  static const String _tooLarge =
      'Image is larger than the 50 KB maximum. Compress or resize it before importing.';

  Future<File> _managedTarget(String pickedName) async {
    final dir = Directory(
      '${(await _supportDirectory()).path}${Platform.pathSeparator}exercise_images',
    );
    await dir.create(recursive: true);
    final safe = pickedName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return File(
      '${dir.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}_$safe',
    );
  }

  Future<({int width, int height, int bytes})> inspect(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final result = (
      width: frame.image.width,
      height: frame.image.height,
      bytes: bytes.length,
    );
    frame.image.dispose();
    codec.dispose();
    return result;
  }
}
