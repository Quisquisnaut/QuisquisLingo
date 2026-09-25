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

/// Where each [QqlStorageRole] lives below a platform's QQL root. Pure data:
/// it names folders for messages and for backends, and never touches
/// storage. Backends decide how a folder is reached.
class QqlStorageLayout {
  const QqlStorageLayout._(this.rootLabel);

  /// Windows, macOS, Linux and iOS: one QuisquisLingo folder in the
  /// platform's documents directory. Courses have their own Imports and
  /// Exports subfolders; every other folder keeps its earlier place.
  static const documents = QqlStorageLayout._('Documents/QuisquisLingo');

  /// How the QQL root is named to people, with `/` separators.
  final String rootLabel;

  static QqlStorageLayout forPlatform(QqlStoragePlatform platform) =>
      switch (platform) {
        QqlStoragePlatform.windows ||
        QqlStoragePlatform.macos ||
        QqlStoragePlatform.linux ||
        QqlStoragePlatform.ios ||
        QqlStoragePlatform.android ||
        QqlStoragePlatform.unsupported => documents,
      };

  /// Replaces [current] in tests that check another platform's wording.
  @visibleForTesting
  static QqlStorageLayout? debugOverride;

  static QqlStorageLayout get current =>
      debugOverride ?? forPlatform(QqlStoragePlatform.current);

  /// Folder names from the QQL root to [role]'s folder.
  List<String> segments(QqlStorageRole role) {
    final top = role.direction == QqlTransferDirection.imports
        ? 'Imports'
        : 'Exports';
    return switch (role.category) {
      QqlFileCategory.courses => [top, 'Courses'],
      QqlFileCategory.merges => const ['Merges'],
      QqlFileCategory.learnerData || QqlFileCategory.recoveryKeys => [top],
      QqlFileCategory.audio => const ['Imports', 'Audio'],
      QqlFileCategory.images => const ['Imports', 'Images'],
      QqlFileCategory.lessonIcons => const ['Imports', 'Lesson Icons'],
      // Upload custom flag has always read flag.png from Exports on desktop.
      QqlFileCategory.courseFlags => const ['Exports'],
      QqlFileCategory.auditReports => const ['Exports'],
      QqlFileCategory.diagnosticLogs => const ['Logs'],
    };
  }

  /// The folder as people see it, e.g. `Documents/QuisquisLingo/Imports/Courses`.
  String folderLabel(QqlStorageRole role) =>
      [rootLabel, ...segments(role)].join('/');

  /// One file in [role]'s folder, e.g.
  /// `Documents/QuisquisLingo/Imports/learner_import.json`.
  String fileLabel(QqlStorageRole role, String fileName) =>
      '${folderLabel(role)}/$fileName';

  /// Help texts name folders through placeholders such as
  /// `{folderCourseImports}`, so they always show this platform's folders.
  static Map<String, String> helpValues() => {
    for (final role in QqlStorageRole.values)
      role.placeholder: current.folderLabel(role),
  };
}
