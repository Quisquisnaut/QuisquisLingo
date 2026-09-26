import 'dart:typed_data';

import '../import/import_stager.dart';
import '../import/selected_external_file.dart';
import 'android_storage_backend.dart';
import 'file_system_storage.dart';
import 'qql_storage_layout.dart';
import 'qql_storage_role.dart';

export 'qql_storage_layout.dart';
export 'qql_storage_role.dart';

/// A folder QQL reads user files from without a dialog (Quick Import).
abstract class QuickImportFolder {
  /// Where the folder is, for messages: a full path where the platform has
  /// one, otherwise the folder's label.
  String get location;

  /// Where a file named [fileName] would be, for messages.
  String locationOf(String fileName);

  /// The ordinary files directly in the folder. Subfolders, links and
  /// special files are left out.
  Future<List<QuickImportFile>> files();

  /// The entry named exactly [name], or null when there is none. A link or
  /// special file with that name comes back with
  /// [QuickImportFile.isOrdinaryFile] false, so the caller can refuse it.
  Future<QuickImportFile?> file(String name);
}

/// One file found in a [QuickImportFolder]. It is read as a stream, like a
/// file chosen with Open from…, so no caller depends on where it is kept.
abstract class QuickImportFile implements SelectedExternalFile {
  /// The exact file name, for matching only; show [displayName] instead.
  String get name;

  /// False for a link or special file, which QQL refuses to read.
  bool get isOrdinaryFile;
}

/// Where a Quick Export wrote its file.
class QuickExportResult {
  const QuickExportResult({required this.location, required this.fileName});

  /// For messages: a full path where the platform has one, otherwise the
  /// file's label.
  final String location;

  final String fileName;
}

/// A folder QQL writes user files to without a dialog (Quick Export).
abstract class QuickExportFolder {
  /// Where the folder is, for messages.
  String get location;

  /// Where a file named [fileName] would be, for messages.
  String locationOf(String fileName);

  /// Writes [bytes] as `baseName.extension`. When that name is taken and
  /// [replace] is false, `baseName_2.extension`, `baseName_3.extension` and
  /// so on are used instead; [replace] overwrites the existing file.
  Future<QuickExportResult> write({
    required String baseName,
    required String extension,
    required List<int> bytes,
    bool replace = false,
  });
}

/// What happened when QQL asked for access to the Quick Import folders.
enum QuickImportAccessResult {
  granted,

  /// Android's folder screen returned a different folder; QQL kept nothing.
  wrongFolder,

  /// The person refused the permission.
  denied,
  cancelled,
}

/// Quick Import cannot read its folders: the platform has not given, or no
/// longer gives, QQL access to them. Nothing falls back to private storage.
class QuickImportAccessRequired implements Exception {
  const QuickImportAccessRequired(this.folder);

  /// The folder that needs access, as people see it.
  final String folder;

  @override
  String toString() =>
      'Quick Import needs permission to read $folder. Choose Quick Import '
      'again to allow it, or use Open from….';
}

/// One file found in a public QQL folder, for Inventory.
class QqlPublicFile {
  const QqlPublicFile(this.name, {this.size, this.modified});

  /// Path below its top folder (Import, Export, Logs or ToBeMerged), with
  /// `/` separators.
  final String name;
  final int? size;
  final DateTime? modified;
}

/// Public QQL folders outside the documents QuisquisLingo folder (Android's
/// `Download/QuisquisLingo`), for Inventory and Wipe everything.
abstract class QqlPublicFolders {
  /// [folder] as people see it.
  String label(QqlTopFolder folder);

  /// The files QQL can see in [folder]: in Export and Logs, the ones it
  /// wrote itself; in Import and ToBeMerged, all of them while it holds
  /// access.
  Future<List<QqlPublicFile>> list(QqlTopFolder folder);

  /// Deletes what [list] shows. Returns how many files were deleted.
  Future<int> delete(QqlTopFolder folder);

  /// Gives back the Quick Import folder permission, if QQL holds one.
  Future<void> releaseImportAccess();
}

/// How one platform reaches the QQL user folders.
abstract class QqlStorageBackend {
  /// The layout this backend resolves roles with; message labels use it.
  QqlStorageLayout get layout;

  Future<QuickImportFolder> importFolder(QqlStorageRole role);

  Future<QuickExportFolder> exportFolder(QqlStorageRole role);

  /// Whether Quick Import can read its folders now, without asking.
  Future<bool> hasImportAccess();

  /// Asks once for access to the Quick Import folders.
  Future<QuickImportAccessResult> requestImportAccess();

  /// What the platform will show when access is requested, to explain it
  /// beforehand; null where no access is ever needed.
  Future<String?> importAccessSteps();

  /// Public folders outside the documents QuisquisLingo folder, or null.
  QqlPublicFolders? get publicFolders;
}

/// The one door from feature code to the QQL user folders. Callers ask for
/// a logical role, such as [QqlStorageRole.courseImports]; the platform
/// backend decides what that folder is and how it is reached.
class QqlStorage {
  QqlStorage({QqlStorageBackend? backend})
    : _backend = backend ?? defaultBackend();

  final QqlStorageBackend _backend;

  static QqlStorageBackend defaultBackend() =>
      QqlStoragePlatform.current == QqlStoragePlatform.android
      ? AndroidStorageBackend()
      : FileSystemStorageBackend();

  QqlStorageLayout get layout => _backend.layout;

  Future<QuickImportFolder> importFolder(QqlStorageRole role) =>
      _backend.importFolder(role);

  Future<QuickExportFolder> exportFolder(QqlStorageRole role) =>
      _backend.exportFolder(role);

  /// The folder as people see it, e.g. `Documents/QuisquisLingo/Import/Courses`.
  String label(QqlStorageRole role) => layout.folderLabel(role);

  String fileLabel(QqlStorageRole role, String fileName) =>
      layout.fileLabel(role, fileName);

  /// The folder Quick Import needs access to, as people see it: the whole
  /// QuisquisLingo folder, e.g. `Download/QuisquisLingo`, so one permission
  /// covers Import and ToBeMerged.
  String get importAccessLabel => layout.rootLabel;

  Future<bool> hasImportAccess() => _backend.hasImportAccess();

  Future<QuickImportAccessResult> requestImportAccess() =>
      _backend.requestImportAccess();

  Future<String?> importAccessSteps() => _backend.importAccessSteps();

  QqlPublicFolders? get publicFolders => _backend.publicFolders;
}

/// Reads all of [file] into memory, refusing more than [maxBytes] with
/// [ImportTooLargeException] as soon as the limit is passed. An empty file
/// gives empty bytes. [ImportAccessException] when the file is not an
/// ordinary file or cannot be read to the end.
Future<Uint8List> readQuickImportFile(
  QuickImportFile file, {
  required int maxBytes,
}) async {
  if (!file.isOrdinaryFile) {
    throw ImportAccessException('${file.displayName} is not an ordinary file.');
  }
  final builder = BytesBuilder(copy: false);
  final stream = await file.openRead();
  try {
    await for (final chunk in stream) {
      if (builder.length + chunk.length > maxBytes) {
        throw ImportTooLargeException(file.displayName, maxBytes);
      }
      builder.add(chunk);
    }
  } on ImportTooLargeException {
    rethrow;
  } on ImportAccessException {
    rethrow;
  } catch (_) {
    throw ImportAccessException(
      '${file.displayName} could not be read to the end.',
    );
  }
  return builder.takeBytes();
}
