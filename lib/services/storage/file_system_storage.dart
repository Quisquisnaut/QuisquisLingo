import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../import/selected_external_file.dart';
import 'qql_storage.dart';

/// Windows, macOS, Linux and iOS: the QQL folders are ordinary directories
/// below `<Documents>/QuisquisLingo`, laid out by [QqlStorageLayout].
class FileSystemStorageBackend implements QqlStorageBackend {
  FileSystemStorageBackend({
    Future<Directory> Function()? documentsDirectory,
    this.layout = QqlStorageLayout.documents,
  }) : _documents = documentsDirectory ?? getApplicationDocumentsDirectory;

  static const rootFolderName = 'QuisquisLingo';

  final Future<Directory> Function() _documents;

  @override
  final QqlStorageLayout layout;

  Future<Directory> rootDirectory() async => Directory(
    '${(await _documents()).path}${Platform.pathSeparator}$rootFolderName',
  );

  /// The directory [role] resolves to; it may not exist yet.
  Future<Directory> directoryFor(QqlStorageRole role) async => Directory(
    [
      (await rootDirectory()).path,
      ...layout.segments(role),
    ].join(Platform.pathSeparator),
  );

  // An import folder is created when asked for, so people can see where to
  // put files, as the fixed folders always were. An export folder is
  // created by its first write, so naming it for a message writes nothing.
  @override
  Future<QuickImportFolder> importFolder(QqlStorageRole role) async {
    final directory = await directoryFor(role);
    await directory.create(recursive: true);
    return FileSystemImportFolder(directory);
  }

  @override
  Future<QuickExportFolder> exportFolder(QqlStorageRole role) async =>
      FileSystemExportFolder(await directoryFor(role));

  /// Ordinary folders need no permission.
  @override
  Future<bool> hasImportAccess() async => true;

  @override
  Future<QuickImportAccessResult> requestImportAccess() async =>
      QuickImportAccessResult.granted;

  @override
  Future<String?> importAccessSteps() async => null;

  /// Inventory and Reset already cover `<Documents>/QuisquisLingo`.
  @override
  QqlPublicFolders? get publicFolders => null;

  /// Ordinary folders need no permission.
  @override
  Future<Directory> courseBackupsDirectory() async => Directory(
    [
      (await rootDirectory()).path,
      ...QqlStorageLayout.courseBackupsSegments,
    ].join(Platform.pathSeparator),
  );
}

class FileSystemImportFolder implements QuickImportFolder {
  FileSystemImportFolder(this.directory);

  final Directory directory;

  @override
  String get location => directory.path;

  @override
  String locationOf(String fileName) =>
      '${directory.path}${Platform.pathSeparator}$fileName';

  @override
  Future<List<QuickImportFile>> files() async {
    if (!await directory.exists()) return const [];
    final out = <QuickImportFile>[];
    // Not following links: a link lists as a Link and is left out.
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      int? size;
      try {
        size = await entity.length();
      } catch (_) {}
      out.add(FileSystemQuickImportFile(entity.path, reportedSize: size));
    }
    return out;
  }

  @override
  Future<QuickImportFile?> file(String name) async {
    final path = locationOf(name);
    final FileSystemEntityType type;
    try {
      type = await FileSystemEntity.type(path, followLinks: false);
    } catch (_) {
      return null;
    }
    switch (type) {
      case FileSystemEntityType.file:
        int? size;
        try {
          size = await File(path).length();
        } catch (_) {}
        return FileSystemQuickImportFile(path, reportedSize: size);
      case FileSystemEntityType.link:
        return FileSystemQuickImportFile(path, isOrdinaryFile: false);
      default:
        return null;
    }
  }
}

class FileSystemQuickImportFile extends FileSystemSelectedFile
    implements QuickImportFile {
  FileSystemQuickImportFile(
    super.path, {
    super.reportedSize,
    this.isOrdinaryFile = true,
  });

  @override
  String get name => sourceFileName;

  @override
  final bool isOrdinaryFile;
}

class FileSystemExportFolder implements QuickExportFolder {
  FileSystemExportFolder(this.directory);

  final Directory directory;

  @override
  String get location => directory.path;

  @override
  String locationOf(String fileName) =>
      '${directory.path}${Platform.pathSeparator}$fileName';

  @override
  Future<QuickExportResult> write({
    required String baseName,
    required String extension,
    required List<int> bytes,
    bool replace = false,
  }) async {
    await directory.create(recursive: true);
    var fileName = '$baseName.$extension';
    if (!replace) {
      var suffix = 2;
      while (await File(locationOf(fileName)).exists()) {
        fileName = '${baseName}_$suffix.$extension';
        suffix++;
      }
    }
    final file = File(locationOf(fileName));
    await file.writeAsBytes(bytes, flush: true);
    return QuickExportResult(location: file.path, fileName: fileName);
  }
}
