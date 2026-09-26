import 'dart:convert';
import 'course_flag_service.dart';
import 'dart:io';
import 'dart:typed_data';

import '../models/course_models.dart';
import 'file_dialog_service.dart';
import 'course_package_service.dart';
import 'course_media_store.dart';
import 'course_image_usage.dart';
import 'portable_exercise_image.dart';
import 'publisher_verification_service.dart';
import 'import/import_stager.dart';
import 'import/selected_external_file.dart';
import 'import/json_limits.dart';
import 'import/image_validator.dart';
import 'storage/file_system_storage.dart';
import 'storage/qql_storage.dart';
import 'storage/course_storage_names.dart';

/// The exact bytes and base file name a course export produces, shared by the
/// Quick Export and the dialog-based Save as…
class CourseExportPayload {
  const CourseExportPayload(this.bytes, this.baseName);

  final Uint8List bytes;

  /// File name without extension, e.g. `quisquislingo_my_course`.
  final String baseName;

  String get fileName => '$baseName.zip';
}

class CustomCourseTransferService {
  CustomCourseTransferService({
    Future<Directory> Function()? directory,
    Future<Directory> Function()? importDirectory,
    Future<Directory> Function()? mergeDirectory,
    FileDialogService? fileDialogs,
    PublisherVerificationService? publisherVerification,
    CoursePackageService? packageService,
    QqlStorage? storage,
    ImportStager? stager,
  }) : _directory = directory,
       _importDirectory = importDirectory ?? directory,
       _mergeDirectory = mergeDirectory ?? directory,
       _fileDialogs = fileDialogs ?? FileDialogService(),
       _publisherVerification =
           publisherVerification ?? PublisherVerificationService(),
       _packages = packageService ?? CoursePackageService(),
       _storage = storage ?? QqlStorage(),
       _stager = stager ?? ImportStager();

  final PublisherVerificationService _publisherVerification;
  final CoursePackageService _packages;
  final QqlStorage _storage;
  final ImportStager _stager;

  static const int maxJsonBytes = 10 * 1024 * 1024;

  /// The file names Quick Import and Course Merge look for.
  static const importPackageName = 'import.zip';
  static const importJsonName = 'import.json';
  static const mergePackageName = 'merge.zip';
  static const mergeJsonName = 'merge.json';

  final FileDialogService _fileDialogs;

  /// False when the system dialog is unsupported; hide Save as… / Open from….
  bool get fileDialogsAvailable => _fileDialogs.isAvailable;
  final Future<Directory> Function()? _directory;
  final Future<Directory> Function()? _importDirectory;
  final Future<Directory> Function()? _mergeDirectory;

  /// A directory injected for tests replaces the platform folder of a role.
  static Future<Directory> _created(
    Future<Directory> Function() injected,
  ) async {
    final directory = await injected();
    await directory.create(recursive: true);
    return directory;
  }

  /// Quick Export destination for Course packages.
  Future<QuickExportFolder> exportFolder() async {
    final injected = _directory;
    return injected == null
        ? _storage.exportFolder(QqlStorageRole.courseExports)
        : FileSystemExportFolder(await _created(injected));
  }

  /// Quick Import source: `import.zip` or `import.json`.
  Future<QuickImportFolder> importFolder() async {
    final injected = _importDirectory;
    return injected == null
        ? _storage.importFolder(QqlStorageRole.courseImports)
        : FileSystemImportFolder(await _created(injected));
  }

  /// Course Merge source: `merge.zip` or `merge.json`.
  Future<QuickImportFolder> mergeFolder() async {
    final injected = _mergeDirectory;
    return injected == null
        ? _storage.importFolder(QqlStorageRole.mergeImports)
        : FileSystemImportFolder(await _created(injected));
  }

  Future<Course> importCourse() async =>
      _readCourse(await importFolder(), importJsonName);

  Future<Course> mergeCourse() async =>
      _readCourse(await mergeFolder(), mergeJsonName);

  /// The UI path carries validated media until the import decision is made.
  Future<CoursePackage> importCoursePackage() async => _readPackageOrJson(
    await importFolder(),
    importPackageName,
    importJsonName,
  );

  Future<CoursePackage> mergeCoursePackage() async => _readPackageOrJson(
    await mergeFolder(),
    mergePackageName,
    mergeJsonName,
  );

  static FormatException _notOrdinary(String name) => FormatException(
    '$name is not an ordinary file. Copy the file itself, not a link or '
    'folder, and try again.',
  );

  Future<CoursePackage> _readPackageOrJson(
    QuickImportFolder folder,
    String zipName,
    String jsonName,
  ) async {
    final zip = await folder.file(zipName);
    final json = await folder.file(jsonName);
    for (final file in [zip, json]) {
      if (file != null && !file.isOrdinaryFile) throw _notOrdinary(file.name);
    }
    if (zip != null && json != null) {
      throw FormatException(
        'Both $zipName and $jsonName are present. Keep only one Course file.',
      );
    }
    if (zip != null) {
      const tooLarge = FormatException(
        'Course package exceeds the 300 MB limit.',
      );
      if ((zip.reportedSize ?? 0) > CoursePackageService.maxPackageBytes) {
        throw tooLarge;
      }
      // Read from a private staged copy, piece by piece: the same path as
      // Open from…, whatever kind of folder the package came from.
      final StagedFile staged;
      try {
        staged = await _stager.stage(
          zip,
          maxBytes: CoursePackageService.maxPackageBytes,
        );
      } on ImportTooLargeException {
        throw tooLarge;
      } on ImportEmptyException {
        throw FormatException('${zip.displayName} is empty.');
      } on ImportAccessException catch (error) {
        throw FormatException(error.message);
      } on ImportStorageException catch (error) {
        throw FormatException(error.message);
      }
      try {
        return await _packages.parseFile(
          staged.file,
          courseFromBytes,
          archiveFileName: zip.name,
        );
      } finally {
        await staged.discard();
      }
    }
    if (json != null) {
      return _jsonPackage(await _readJson(json), json.name);
    }
    throw FormatException(
      'No Course file found. Copy $zipName or $jsonName to '
      '${folder.location}, then try again.',
    );
  }

  static Future<Uint8List> _readJson(QuickImportFile file) async {
    const tooLarge = FormatException(
      'Course JSON exceeds the 10 MB safety limit.',
    );
    if ((file.reportedSize ?? 0) > maxJsonBytes) throw tooLarge;
    try {
      return await readQuickImportFile(file, maxBytes: maxJsonBytes);
    } on ImportTooLargeException {
      throw tooLarge;
    } on ImportAccessException catch (error) {
      throw FormatException(error.message);
    }
  }

  Future<CoursePackage> _jsonPackage(Uint8List bytes, String fileName) async {
    final course = await courseFromBytes(bytes, fileName);
    if (CourseMediaStore.referencesOf(course).isNotEmpty) {
      throw const FormatException(
        'This Course uses images or recordings. Import its .zip package so the media arrive with it.',
      );
    }
    return CoursePackage(course, bytes, {});
  }

  Future<Course> _readCourse(QuickImportFolder folder, String fileName) async {
    final file = await folder.file(fileName);
    if (file == null) {
      throw FormatException(
        'No $fileName found. Copy the course file to '
        '${folder.locationOf(fileName)}, then try again.',
      );
    }
    if (!file.isOrdinaryFile) throw _notOrdinary(fileName);
    return courseFromBytes(await _readJson(file), fileName);
  }

  /// The one authoritative course-file validator. Both the fixed-folder
  /// import and Open from… end here.
  Future<Course> courseFromBytes(Uint8List bytes, String fileName) async {
    if (bytes.length > maxJsonBytes) {
      throw const FormatException(
        'Course JSON exceeds the 10 MB safety limit.',
      );
    }
    String raw;
    try {
      raw = utf8.decode(bytes);
    } catch (_) {
      throw FormatException('$fileName must be valid UTF-8 text.');
    }

    final decoded = JsonLimits.imports.decode(
      raw,
      what: fileName,
      invalidMessage: '$fileName is not valid JSON.',
    );
    if (decoded is! Map) {
      throw const FormatException('Course JSON root must be an object.');
    }
    CourseShapeLimits.check(decoded);

    final course = Course.fromJson(Map<String, dynamic>.from(decoded));
    await CourseFlagService().validateWorldFlag(course);

    if (course.flagImageBase64.length > 1024 * 1024) {
      throw const FormatException(
        'Embedded custom flag data exceed the 1 MB safety limit.',
      );
    }
    if (course.flagImageBase64.isNotEmpty) {
      late final Uint8List flagBytes;
      try {
        flagBytes = base64Decode(course.flagImageBase64);
      } catch (_) {
        throw const FormatException(
          'Embedded custom flag data are not valid Base64.',
        );
      }
      await ImageValidator.validate(flagBytes, ImageProfile.courseFlag);
    }
    // Course.fromJson checks the shape of embedded assets. Imported bytes
    // also need the same content check used when the Editor first picks them.
    for (final icon in course.lessonIconAssets) {
      await ImageValidator.validate(
        base64Decode(icon.base64Png),
        ImageProfile.lessonIcon,
      );
    }
    for (final asset in CourseImageUsage.usedAssets(course)) {
      if (!asset.startsWith('data:image/')) continue;
      final bytes = PortableExerciseImageService.decode(asset)!;
      await ImageValidator.validate(bytes, ImageProfile.exerciseImage);
    }
    if (course.originType == CourseOriginType.bundledOfficial) {
      throw const FormatException(
        'Bundled official courses are installed only with QuisquisLingo application builds.',
      );
    }
    if (course.originType == CourseOriginType.externalOfficial) {
      return _publisherVerification.requireVerified(course);
    }
    return course;
  }

  /// Builds the export bytes and base name. Shared by [exportCourse] and
  /// [exportCourseTo], so both write identical data. The name is
  /// `QQL_<pair>_<title>`; an earlier version from Version History passes its
  /// [historicalVersion] and is named `QQL_bkp_<pair>_<title>_v<version>`.
  Future<CourseExportPayload> buildCourseExport(
    Course course, {
    String? historicalVersion,
  }) async {
    final payload = const JsonEncoder.withIndent('  ').convert(course.toJson());
    final bytes = Uint8List.fromList(utf8.encode(payload));
    if (bytes.length > maxJsonBytes) {
      throw const FormatException(
        'Course JSON exceeds the 10 MB export safety limit.',
      );
    }
    return CourseExportPayload(
      await _packages.build(course, bytes),
      CourseStorageNames.exportBaseName(
        pair: CourseStorageNames.pairOfCourse(course),
        title: course.title,
        historicalVersion: historicalVersion,
      ),
    );
  }

  /// Save as…: the same export as [exportCourse], written wherever the user
  /// chooses in the system dialog. Additional to, not a replacement for, the
  /// Quick Export folder.
  Future<FileDialogResult> exportCourseTo(
    Course course, {
    String? historicalVersion,
  }) async {
    final payload = await buildCourseExport(
      course,
      historicalVersion: historicalVersion,
    );
    return _fileDialogs.saveBytes(
      bytes: payload.bytes,
      suggestedName: payload.fileName,
      extensions: const ['zip'],
      artifact: 'course',
    );
  }

  /// Open from…: lets the user pick a course file in the system dialog. The
  /// outcome carries the validated [Course] only when the file passed the same
  /// validation as an ordinary import.
  Future<({FileDialogResult dialog, Course? course})>
  importCourseFromDialog() => _courseFromDialog('course');

  Future<({FileDialogResult dialog, CoursePackage? package})>
  importPackageFromDialog() => _packageFromDialog('course');

  /// Merge From…: the same pick-and-validate as [importCourseFromDialog], for
  /// the second Course of a merge instead of `Merges/merge.json`.
  Future<({FileDialogResult dialog, Course? course})> mergeCourseFromDialog() =>
      _courseFromDialog('course-merge');

  Future<({FileDialogResult dialog, CoursePackage? package})>
  mergePackageFromDialog() => _packageFromDialog('course-merge');

  Future<({FileDialogResult dialog, CoursePackage? package})> _packageFromDialog(
    String artifact,
  ) async {
    // The file stays in staging and a ZIP is read from there piece by
    // piece: a 300 MB package is never held in memory whole.
    final picked = await _fileDialogs.openStaged(
      extensions: const ['zip', 'json'],
      maxBytes: CoursePackageService.maxPackageBytes,
      artifact: artifact,
    );
    final result = picked.dialog;
    if (result.outcome == FileDialogOutcome.tooLarge) {
      throw const FormatException('Course package exceeds the 300 MB limit.');
    }
    final staged = picked.staged;
    if (result.outcome != FileDialogOutcome.opened || staged == null) {
      return (dialog: result, package: null);
    }
    final name = result.displayName!;
    final sourceFileName = result.sourceFileName ?? name;
    final Uint8List bytes;
    try {
      if (sourceFileName.toLowerCase().endsWith('.zip')) {
        return (
          dialog: result,
          package: await _packages.parseFile(
            staged.file,
            courseFromBytes,
            archiveFileName: sourceFileName,
          ),
        );
      }
      if (!name.toLowerCase().endsWith('.json')) {
        throw const FormatException('Choose a Course .zip or .json file.');
      }
      if (staged.length > maxJsonBytes) {
        throw const FormatException(
          'Course JSON exceeds the 10 MB safety limit.',
        );
      }
      bytes = await staged.readBytes();
    } finally {
      await staged.discard();
    }
    return (
      dialog: result,
      package: await _jsonPackage(bytes, name),
    );
  }

  Future<({FileDialogResult dialog, Course? course})> _courseFromDialog(
    String artifact,
  ) async {
    final result = await _fileDialogs.openBytes(
      extensions: const ['json'],
      maxBytes: maxJsonBytes,
      artifact: artifact,
    );
    if (result.outcome == FileDialogOutcome.tooLarge) {
      throw const FormatException('Course JSON exceeds the 10 MB safety limit.');
    }
    if (result.outcome != FileDialogOutcome.opened) {
      return (dialog: result, course: null);
    }
    final course = await courseFromBytes(result.bytes!, result.displayName!);
    return (dialog: result, course: course);
  }

  Future<String> exportCourse(Course course, {String? historicalVersion}) async {
    final export = await buildCourseExport(
      course,
      historicalVersion: historicalVersion,
    );
    // Keep course exports independent from desktop file-picker/portal support.
    // They always go to one predictable Quick Export folder. (Save as… is a
    // separate, additional route: see exportCourseTo.)
    final written = await (await exportFolder()).write(
      baseName: export.baseName,
      extension: 'zip',
      bytes: export.bytes,
    );
    return written.location;
  }
}
