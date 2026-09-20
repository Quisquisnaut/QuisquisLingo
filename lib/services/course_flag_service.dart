import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

import '../models/course_models.dart';
import '../models/world_flag_entity.dart';
import 'course_language_resolver.dart';
import 'language_flag_catalog.dart';
import 'world_flag_repository.dart';

enum ResolvedCourseFlagKind { worldFlag, customImage, builtIn, neutral }

class ResolvedCourseFlag {
  final ResolvedCourseFlagKind kind;
  final String identifier;
  final bool isExplicit;

  const ResolvedCourseFlag({
    required this.kind,
    required this.identifier,
    required this.isExplicit,
  });
}

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

  static Map<String, String> get builtInFlags =>
      LanguageFlagCatalog.builtInLabelsByPainterCase;

  static Set<String> get renderableBuiltInCodes =>
      LanguageFlagCatalog.renderablePainterCases;

  static bool hasExplicitFlag(Course course) =>
      course.worldFlagId.trim().isNotEmpty ||
      course.flagImageBase64.trim().isNotEmpty ||
      course.flagCode.trim().isNotEmpty;

  /// The established recovery source when explicit raster flag data cannot be
  /// decoded, or when a derived palette cannot load its selected asset.
  static String builtInRecoveryCode(
    Course course, {
    required String fallbackCode,
  }) {
    final configured = course.flagCode.trim().toUpperCase();
    return configured.isEmpty ? fallbackCode.trim().toUpperCase() : configured;
  }

  /// Shared source precedence for Course Info, selectors, learner surfaces and
  /// the Course Entry Animation. Invalid explicit sources remain explicit so
  /// consumers can render the established neutral fallback rather than
  /// silently substituting an automatic flag.
  static ResolvedCourseFlag resolve(Course course, {String? fallbackCode}) {
    final worldFlagId = course.worldFlagId.trim();
    if (worldFlagId.isNotEmpty) {
      return ResolvedCourseFlag(
        kind: ResolvedCourseFlagKind.worldFlag,
        identifier: worldFlagId,
        isExplicit: true,
      );
    }
    final customImage = course.flagImageBase64.trim();
    if (customImage.isNotEmpty) {
      return ResolvedCourseFlag(
        kind: ResolvedCourseFlagKind.customImage,
        identifier: customImage,
        isExplicit: true,
      );
    }
    final explicitCode = course.flagCode.trim().toUpperCase();
    if (explicitCode.isNotEmpty) {
      return ResolvedCourseFlag(
        kind: ResolvedCourseFlagKind.builtIn,
        identifier: explicitCode,
        isExplicit: true,
      );
    }
    final language = CourseLanguageResolver.learning(course);
    final painterFlag = LanguageFlagCatalog.qqlFlagFor(
      languageTag: language.code ?? fallbackCode,
      languageName: language.name,
    );
    if (painterFlag != null) {
      return ResolvedCourseFlag(
        kind: ResolvedCourseFlagKind.builtIn,
        identifier: painterFlag.painterCode,
        isExplicit: false,
      );
    }
    final automaticWorldFlagId = LanguageFlagCatalog.primaryWorldFlagId(
      languageTag: language.code ?? fallbackCode,
      languageName: language.name,
    );
    if (automaticWorldFlagId != null) {
      return ResolvedCourseFlag(
        kind: ResolvedCourseFlagKind.worldFlag,
        identifier: automaticWorldFlagId,
        isExplicit: false,
      );
    }
    return const ResolvedCourseFlag(
      kind: ResolvedCourseFlagKind.neutral,
      identifier: '',
      isExplicit: false,
    );
  }

  String codeForLanguage(String language) =>
      LanguageFlagCatalog.qqlFlagFor(languageName: language)?.painterCode ?? '';

  Future<WorldFlagEntity?> resolveWorldFlag(
    Course course, {
    WorldFlagRepository? repository,
  }) async {
    final id = course.worldFlagId.trim();
    if (id.isEmpty) return null;
    return (repository ?? WorldFlagRepository()).findById(id);
  }

  Future<void> validateWorldFlag(
    Course course, {
    WorldFlagRepository? repository,
  }) async {
    final id = course.worldFlagId.trim();
    if (id.isEmpty) return;
    final entity = await resolveWorldFlag(course, repository: repository);
    if (entity == null) {
      throw FormatException(
        'World Flag "$id" is unavailable in this QuisquisLingo installation. '
        'Choose an available World Flag or another course flag source.',
      );
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
    final isPng =
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A;
    final isJpeg =
        bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
    if (!isPng && !isJpeg) {
      throw const FormatException(
        'Flag file must contain a PNG or JPEG image.',
      );
    }

    // Read the declared dimensions from the header instead of rasterizing the
    // source. The full-size frame was only ever used to learn width and height
    // before being disposed, and the real decode below already asks for the
    // scaled target, so decoding twice risked an allocation the size checks
    // exist to prevent.
    int width;
    int height;
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      width = descriptor.width;
      height = descriptor.height;
    } catch (_) {
      throw const FormatException(
        'The selected file is not a supported PNG or JPEG image.',
      );
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }

    if (width < minWidth || height < minHeight) {
      throw FormatException(
        'Flag resolution is too small. Minimum: ${minWidth}x$minHeight pixels.',
      );
    }
    if (width > maxSourceDimension || height > maxSourceDimension) {
      throw const FormatException(
        'Flag resolution is too large. Maximum source dimension: 8192 pixels.',
      );
    }

    final scale = maxOutputDimension / (width > height ? width : height);
    final targetWidth = scale < 1
        ? (width * scale).round().clamp(1, maxOutputDimension).toInt()
        : width;
    final targetHeight = scale < 1
        ? (height * scale).round().clamp(1, maxOutputDimension).toInt()
        : height;

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
    if (data == null) {
      throw const FormatException(
        'The flag image could not be converted to PNG.',
      );
    }
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
