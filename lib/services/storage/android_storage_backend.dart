import 'dart:io';

import 'android_file_dialog_backend.dart';
import 'android_storage_bridge.dart';
import 'file_system_storage.dart';
import 'qql_storage.dart';

/// Android: the QQL user folders are public, in `Download/QuisquisLingo`,
/// where file managers, browser downloads and cable copies reach them.
///
/// * Android 10 and later: Quick Export writes through MediaStore, with no
///   permission and no dialog. Quick Import reads through one persisted
///   folder permission on exactly `Download/QuisquisLingo`, which covers
///   both Import and ToBeMerged.
/// * Android 7–9: both use ordinary files in the Download folder once the
///   storage permission is granted; Android asks for it once.
///
/// Nothing falls back to app-private storage: without access, Quick Import
/// reports [QuickImportAccessRequired] and Quick Export reports
/// [QuickExportAccessDenied].
class AndroidStorageBackend implements QqlStorageBackend {
  AndroidStorageBackend({
    AndroidStorageBridge bridge = const AndroidStorageBridge(),
  }) : _bridge = bridge;

  final AndroidStorageBridge _bridge;
  Future<AndroidStorageInfo>? _info;

  @override
  QqlStorageLayout get layout => QqlStorageLayout.androidPublic;

  Future<AndroidStorageInfo> _storageInfo() =>
      _info ??= _bridge.storageInfo();

  /// The folder the Quick Import permission is for.
  String get _accessLabel => layout.rootLabel;

  Directory _legacyDirectory(AndroidStorageInfo info, List<String> segments) =>
      Directory([info.downloadsPath, 'QuisquisLingo', ...segments].join('/'));

  /// The Import and ToBeMerged folders QQL creates once it may read the
  /// QuisquisLingo folder, so people see where to put files.
  List<String> get importFolderPaths => {
    for (final role in QqlStorageRole.values)
      if (role.direction == QqlTransferDirection.imports)
        layout.segments(role).join('/'),
  }.toList();

  @override
  Future<QuickExportFolder> exportFolder(QqlStorageRole role) async {
    final info = await _storageInfo();
    final label = layout.folderLabel(role);
    if (info.scopedStorage) {
      // The label is also MediaStore's relative path: Download/QuisquisLingo/…
      return AndroidDownloadsExportFolder(_bridge, label);
    }
    return AndroidLegacyExportFolder(
      _bridge,
      _legacyDirectory(info, layout.segments(role)),
      label,
    );
  }

  @override
  Future<QuickImportFolder> importFolder(QqlStorageRole role) async {
    final info = await _storageInfo();
    final label = layout.folderLabel(role);
    if (!await _bridge.hasImportAccess()) {
      throw QuickImportAccessRequired(_accessLabel);
    }
    if (!info.scopedStorage) {
      final directory = _legacyDirectory(info, layout.segments(role));
      await directory.create(recursive: true);
      return LabelledImportFolder(FileSystemImportFolder(directory), label);
    }
    // The permission is for the QuisquisLingo folder; the role's folder is
    // below it.
    return AndroidTreeImportFolder(
      _bridge,
      layout.segments(role),
      label,
      _accessLabel,
    );
  }

  @override
  Future<bool> hasImportAccess() => _bridge.hasImportAccess();

  @override
  Future<QuickImportAccessResult> requestImportAccess() =>
      _bridge.requestImportAccess(folders: importFolderPaths);

  @override
  Future<String?> importAccessSteps() async =>
      (await _storageInfo()).scopedStorage
      ? 'On the next screen Android opens $_accessLabel. Tap Use this '
            'folder, then Allow.'
      : 'On the next screen Android asks whether QuisquisLingo may use '
            'files on this device. Tap Allow.';

  @override
  QqlPublicFolders get publicFolders => AndroidPublicFolders(this);
}

/// Quick Export on Android 7–9 needs the storage permission, and it was not
/// given.
class QuickExportAccessDenied implements Exception {
  const QuickExportAccessDenied(this.folder);

  final String folder;

  @override
  String toString() =>
      'QQL needs permission to save in $folder. Allow it when Android asks, '
      'or use Save as….';
}

/// An import folder that names itself by its label, so messages show
/// `Download/QuisquisLingo/Import/…` rather than a device path.
class LabelledImportFolder implements QuickImportFolder {
  LabelledImportFolder(this._inner, this.location);

  final QuickImportFolder _inner;

  @override
  final String location;

  @override
  String locationOf(String fileName) => '$location/$fileName';

  @override
  Future<List<QuickImportFile>> files() => _inner.files();

  @override
  Future<QuickImportFile?> file(String name) => _inner.file(name);
}

/// Android 10 and later: a Quick Import folder below
/// `Download/QuisquisLingo`, read through the folder permission.
class AndroidTreeImportFolder implements QuickImportFolder {
  AndroidTreeImportFolder(
    this._bridge,
    this._segments,
    this.location,
    this._accessLabel,
  );

  final AndroidStorageBridge _bridge;

  /// Folder names below the QuisquisLingo folder, e.g. `Import`, `Courses`.
  final List<String> _segments;
  final String _accessLabel;

  @override
  final String location;

  @override
  String locationOf(String fileName) => '$location/$fileName';

  @override
  Future<List<QuickImportFile>> files() async {
    try {
      return [
        for (final document in await _bridge.listImports(_segments))
          AndroidQuickImportFile(document, _bridge),
      ];
    } on AndroidImportAccessMissing {
      throw QuickImportAccessRequired(_accessLabel);
    }
  }

  @override
  Future<QuickImportFile?> file(String name) async {
    for (final file in await files()) {
      if (file.name == name) return file;
    }
    return null;
  }
}

/// A file in a Quick Import folder on Android 10 and later. Documents from a
/// folder are always ordinary files: links are not exposed.
class AndroidQuickImportFile extends AndroidDocumentFile
    implements QuickImportFile {
  AndroidQuickImportFile(super.document, super.bridge);

  @override
  String get name => document.name;

  @override
  bool get isOrdinaryFile => true;
}

/// Android 10 and later: Quick Export to `Download/QuisquisLingo/Export/…`
/// and `Download/QuisquisLingo/Logs` through MediaStore.
class AndroidDownloadsExportFolder implements QuickExportFolder {
  AndroidDownloadsExportFolder(this._bridge, this.location);

  final AndroidStorageBridge _bridge;

  @override
  final String location;

  @override
  String locationOf(String fileName) => '$location/$fileName';

  @override
  Future<QuickExportResult> write({
    required String baseName,
    required String extension,
    required List<int> bytes,
    bool replace = false,
  }) async {
    final name = await _bridge.writeDownload(
      relativeFolder: location,
      baseName: baseName,
      extension: extension,
      mimeType: AndroidFileDialogBackend.mimeTypeFor('$baseName.$extension'),
      bytes: bytes,
      replace: replace,
    );
    return QuickExportResult(location: locationOf(name), fileName: name);
  }
}

/// Android 7–9: Quick Export as ordinary files in the Download folder, once
/// the storage permission is granted.
class AndroidLegacyExportFolder implements QuickExportFolder {
  AndroidLegacyExportFolder(this._bridge, this._directory, this.location);

  final AndroidStorageBridge _bridge;
  final Directory _directory;

  @override
  final String location;

  @override
  String locationOf(String fileName) => '$location/$fileName';

  @override
  Future<QuickExportResult> write({
    required String baseName,
    required String extension,
    required List<int> bytes,
    bool replace = false,
  }) async {
    if (!await _bridge.requestLegacyWriteAccess()) {
      throw QuickExportAccessDenied(location);
    }
    final written = await FileSystemExportFolder(_directory).write(
      baseName: baseName,
      extension: extension,
      bytes: bytes,
      replace: replace,
    );
    try {
      await _bridge.scanFile(written.location);
    } catch (_) {
      // Only makes the file show up sooner in the Downloads app.
    }
    return QuickExportResult(
      location: locationOf(written.fileName),
      fileName: written.fileName,
    );
  }
}

/// Inventory and Wipe everything for Android's public QQL folders.
class AndroidPublicFolders implements QqlPublicFolders {
  AndroidPublicFolders(this._backend);

  final AndroidStorageBackend _backend;

  AndroidStorageBridge get _bridge => _backend._bridge;

  @override
  String label(QqlTopFolder folder) => _backend.layout.topFolderLabel(folder);

  String _relativePrefix(QqlTopFolder folder) => '${label(folder)}/';

  Directory _legacyRoot(AndroidStorageInfo info, QqlTopFolder folder) =>
      _backend._legacyDirectory(info, [folder.folderName]);

  /// Import and ToBeMerged hold files people put there, read through the
  /// folder permission; Export and Logs hold QQL's own Download entries.
  static bool _peoplesFiles(QqlTopFolder folder) =>
      folder == QqlTopFolder.import || folder == QqlTopFolder.toBeMerged;

  @override
  Future<List<QqlPublicFile>> list(QqlTopFolder folder) async {
    final info = await _backend._storageInfo();
    if (!info.scopedStorage) {
      if (!await _bridge.hasImportAccess()) return const [];
      return _legacyFiles(_legacyRoot(info, folder));
    }
    if (!_peoplesFiles(folder)) {
      return _bridge.listOwnDownloads(_relativePrefix(folder));
    }
    if (!await _bridge.hasImportAccess()) return const [];
    return _bridge.listTree([folder.folderName]);
  }

  @override
  Future<int> delete(QqlTopFolder folder) async {
    final info = await _backend._storageInfo();
    if (!info.scopedStorage) {
      if (!await _bridge.hasImportAccess()) return 0;
      final root = _legacyRoot(info, folder);
      final count = (await _legacyFiles(root)).length;
      if (await root.exists()) await root.delete(recursive: true);
      return count;
    }
    if (!_peoplesFiles(folder)) {
      return _bridge.deleteOwnDownloads(_relativePrefix(folder));
    }
    if (!await _bridge.hasImportAccess()) return 0;
    return _bridge.deleteTree([folder.folderName]);
  }

  @override
  Future<void> releaseImportAccess() async {
    if ((await _backend._storageInfo()).scopedStorage) {
      await _bridge.releaseImportAccess();
    }
  }

  static Future<List<QqlPublicFile>> _legacyFiles(Directory root) async {
    if (!await root.exists()) return const [];
    final out = <QqlPublicFile>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      out.add(
        QqlPublicFile(
          entity.path
              .substring(root.path.length + 1)
              .replaceAll(Platform.pathSeparator, '/'),
          size: stat.size,
          modified: stat.modified,
        ),
      );
    }
    return out;
  }
}
