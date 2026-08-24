import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';

class ExerciseImageService {
  static const int maxImageBytes = 50 * 1024;
  static const int recommendedImageBytes = 15 * 1024;
  static const int recommendedPixels = 256;
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
          return const {'png', 'jpg', 'jpeg', 'webp'}.contains(ext);
        })
        .toList();
    candidates.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    if (candidates.isEmpty) {
      throw StateError('No image found in ${importDir.path}. Copy one PNG, JPG, JPEG or WEBP image there and try again.');
    }
    if (candidates.length > 1) {
      throw StateError('More than one image was found in ${importDir.path}. Keep only the image you want to import, then try again.');
    }
    final source = candidates.single;
    if (await source.length() > maxImageBytes) {
      throw StateError('Image is larger than the 50 KB maximum. Compress or resize it before importing.');
    }
    final dir=Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}exercise_images');
    await dir.create(recursive:true);
    final pickedName = source.uri.pathSegments.last;
    final safe=pickedName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'),'_');
    final target=File('${dir.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}_$safe');
    await source.copy(target.path);
    return target.path;
  }

  Future<({int width,int height,int bytes})> inspect(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final result = (width: frame.image.width, height: frame.image.height, bytes: bytes.length);
    frame.image.dispose();
    codec.dispose();
    return result;
  }
}
