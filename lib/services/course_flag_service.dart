import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

class ImportedCourseFlag {
  final String base64Png;
  final int sourceWidth;
  final int sourceHeight;
  final int outputWidth;
  final int outputHeight;

  const ImportedCourseFlag({
    required this.base64Png,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.outputWidth,
    required this.outputHeight,
  });
}

class CourseFlagService {
  static const int maxInputBytes = 2 * 1024 * 1024;
  static const int minWidth = 64;
  static const int minHeight = 40;
  static const int maxSourceDimension = 8192;
  static const int maxOutputDimension = 256;

  static const Map<String, String> builtInFlags = {
    'IT': 'Italy',
    'DE': 'Germany',
    'ES': 'Spain',
    'EN': 'United Kingdom / English',
    'CY': 'Wales',
    'NL': 'Netherlands',
    'PT': 'Portugal',
    'FI': 'Finland',
  };

  String codeForLanguage(String language) {
    switch (language.trim().toLowerCase()) {
      case 'italian': return 'IT';
      case 'german': return 'DE';
      case 'spanish': return 'ES';
      case 'english': return 'EN';
      case 'welsh': return 'CY';
      case 'dutch': return 'NL';
      case 'portuguese': return 'PT';
      case 'finnish': return 'FI';
      default: return '';
    }
  }

  Future<Directory> flagImportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Exports',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<ImportedCourseFlag> importPreparedFlag() async {
    final directory = await flagImportDirectory();
    const names = ['flag.png', 'flag.jpg', 'flag.jpeg'];
    File? source;
    for (final name in names) {
      final candidate = File('${directory.path}${Platform.pathSeparator}$name');
      if (await candidate.exists()) {
        source = candidate;
        break;
      }
    }
    if (source == null) {
      throw FormatException(
        'No flag image found. Copy flag.png, flag.jpg, or flag.jpeg to ${directory.path}, then press Import flag again.',
      );
    }
    if (await source.length() > maxInputBytes) {
      throw const FormatException('Flag image exceeds the 2 MB safety limit.');
    }
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('The flag image could not be read.');
    }
    return prepareFlag(bytes);
  }

  Future<ImportedCourseFlag> prepareFlag(Uint8List bytes) async {
    if (bytes.length > maxInputBytes) {
      throw const FormatException('Flag image exceeds the 2 MB safety limit.');
    }
    final isPng=bytes.length>=8&&bytes[0]==0x89&&bytes[1]==0x50&&bytes[2]==0x4E&&bytes[3]==0x47&&bytes[4]==0x0D&&bytes[5]==0x0A&&bytes[6]==0x1A&&bytes[7]==0x0A;
    final isJpeg=bytes.length>=3&&bytes[0]==0xFF&&bytes[1]==0xD8&&bytes[2]==0xFF;
    if(!isPng&&!isJpeg){
      throw const FormatException('Flag file must contain a PNG or JPEG image.');
    }

    ui.Codec sourceCodec;
    try {
      sourceCodec = await ui.instantiateImageCodec(bytes);
    } catch (_) {
      throw const FormatException('The selected file is not a supported PNG or JPEG image.');
    }
    final sourceFrame = await sourceCodec.getNextFrame();
    final source = sourceFrame.image;
    final width = source.width;
    final height = source.height;
    source.dispose();
    sourceCodec.dispose();

    if (width < minWidth || height < minHeight) {
      throw FormatException('Flag resolution is too small. Minimum: ${minWidth}x$minHeight pixels.');
    }
    if (width > maxSourceDimension || height > maxSourceDimension) {
      throw const FormatException('Flag resolution is too large. Maximum source dimension: 8192 pixels.');
    }

    final scale = maxOutputDimension / (width > height ? width : height);
    final targetWidth = scale < 1 ? (width * scale).round().clamp(1, maxOutputDimension).toInt() : width;
    final targetHeight = scale < 1 ? (height * scale).round().clamp(1, maxOutputDimension).toInt() : height;

    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
    if (data == null) throw const FormatException('The flag image could not be converted to PNG.');
    final png = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    return ImportedCourseFlag(
      base64Png: base64Encode(png),
      sourceWidth: width,
      sourceHeight: height,
      outputWidth: targetWidth,
      outputHeight: targetHeight,
    );
  }
}
