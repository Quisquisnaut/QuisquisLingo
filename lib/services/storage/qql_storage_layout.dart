import 'dart:io';

import 'package:flutter/foundation.dart';

import 'qql_storage_role.dart';

/// The platforms whose storage layouts QQL knows.
enum QqlStoragePlatform {
  windows,
  macos,
  linux,
  ios,
  android,
  unsupported;

  static QqlStoragePlatform get current {
    if (kIsWeb) return unsupported;
    if (Platform.isWindows) return windows;
    if (Platform.isMacOS) return macos;
    if (Platform.isLinux) return linux;
    if (Platform.isIOS) return ios;
    if (Platform.isAndroid) return android;
    return unsupported;
  }
}

/// The four folders directly in the QuisquisLingo folder, the same on every
/// system.
enum QqlTopFolder {
  /// Files people put in for Quick Import, one subfolder per kind.
  import('Import'),

  /// Files Quick Export writes, one subfolder per kind.
  export('Export'),

  /// Copies of the Crash Log and the Diagnostic Log.
  logs('Logs'),

  /// The second Course of a Course Merge.
  toBeMerged('ToBeMerged');

  const QqlTopFolder(this.folderName);

  /// The folder's name on disk.
  final String folderName;

  /// Name of its Help text placeholder, `{folderExport}` and so on.
  String get placeholder => 'folder$folderName';

  /// Folders earlier versions used, by the folder that replaced them. They
  /// are never read; Inventory lists them and Wipe everything treats them
  /// like their replacements.
  static const earlierFolders = <String, QqlTopFolder>{
    'Imports': import,
    'Exports': export,
    'Merges': toBeMerged,
  };
}

/// Where each [QqlStorageRole] lives below a platform's QQL root. Pure data:
/// it names folders for messages and for backends, and never touches
/// storage. Backends decide how a folder is reached.
///
/// Every system uses the same folders below its QuisquisLingo folder; only
/// where that folder is differs.
class QqlStorageLayout {
  const QqlStorageLayout._(this.rootLabel);

  /// Windows, macOS, Linux and iOS: the QuisquisLingo folder in the
  /// platform's documents directory.
  static const documents = QqlStorageLayout._('Documents/QuisquisLingo');

  /// Android: the QuisquisLingo folder in the shared Download folder.
  static const androidPublic = QqlStorageLayout._('Download/QuisquisLingo');

  /// How the QQL root is named to people, with `/` separators.
  final String rootLabel;

  static QqlStorageLayout forPlatform(QqlStoragePlatform platform) =>
      switch (platform) {
        QqlStoragePlatform.android => androidPublic,
        QqlStoragePlatform.windows ||
        QqlStoragePlatform.macos ||
        QqlStoragePlatform.linux ||
        QqlStoragePlatform.ios ||
        QqlStoragePlatform.unsupported => documents,
      };

  /// Replaces [current] in tests that check another platform's wording.
  @visibleForTesting
  static QqlStorageLayout? debugOverride;

  static QqlStorageLayout get current =>
      debugOverride ?? forPlatform(QqlStoragePlatform.current);

  /// The top folder [role]'s folder is in: Import or Export by direction,
  /// except the Merge input (ToBeMerged) and the log copies (Logs).
  static QqlTopFolder topFolder(QqlStorageRole role) => switch (role.category) {
    QqlFileCategory.merges => QqlTopFolder.toBeMerged,
    QqlFileCategory.diagnosticLogs => QqlTopFolder.logs,
    _ =>
      role.direction == QqlTransferDirection.imports
          ? QqlTopFolder.import
          : QqlTopFolder.export,
  };

  /// Folder names from the QQL root to [role]'s folder, the same on every
  /// system.
  List<String> segments(QqlStorageRole role) => [
    topFolder(role).folderName,
    ...switch (role.category) {
      QqlFileCategory.courses || QqlFileCategory.merges => const ['Courses'],
      QqlFileCategory.learnerData => const ['UserData'],
      QqlFileCategory.recoveryKeys => const ['RecoveryKeys'],
      QqlFileCategory.audio => const ['Audio'],
      QqlFileCategory.images => const ['Images'],
      QqlFileCategory.lessonIcons => const ['LessonIcons'],
      QqlFileCategory.courseFlags => const ['Flags'],
      QqlFileCategory.auditReports => const ['AuditReports'],
      QqlFileCategory.diagnosticLogs => const <String>[],
    },
  ];

  /// The folder as people see it, e.g. `Documents/QuisquisLingo/Import/Courses`.
  String folderLabel(QqlStorageRole role) =>
      [rootLabel, ...segments(role)].join('/');

  /// A top folder as people see it, e.g. `Download/QuisquisLingo/Export`.
  String topFolderLabel(QqlTopFolder folder) =>
      '$rootLabel/${folder.folderName}';

  /// One file in [role]'s folder, e.g.
  /// `Documents/QuisquisLingo/Import/UserData/learner_import.json`.
  String fileLabel(QqlStorageRole role, String fileName) =>
      '${folderLabel(role)}/$fileName';

  /// Help texts name folders through placeholders such as
  /// `{folderCourseImports}`, `{folderExport}` or `{folderRoot}`, so they
  /// always show this platform's folders.
  static Map<String, String> helpValues() => {
    for (final role in QqlStorageRole.values)
      role.placeholder: current.folderLabel(role),
    for (final folder in QqlTopFolder.values)
      folder.placeholder: current.topFolderLabel(folder),
    rootPlaceholder: current.rootLabel,
  };

  /// Help placeholder for the QuisquisLingo folder itself.
  static const rootPlaceholder = 'folderRoot';
}
