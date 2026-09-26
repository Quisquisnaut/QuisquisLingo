import 'dart:io';

/// Names QQL's private storage (the platform's application-support directory)
/// used before Build 255 Revision 4 gave every private folder a `QQL_` name.
///
/// The app no longer reads them, with one exception: Shared Image Library
/// images and Image Banks added earlier keep opening from their old folders,
/// because their records hold full paths. Inventory lists these folders and
/// Wipe everything removes them; a one-off tool moves the owner's earlier
/// Courses, media and backups to the new names.
class QqlEarlierPrivateFolders {
  const QqlEarlierPrivateFolders._();

  static const courses = 'qql_courses_v2';
  static const courseMedia = 'quisquislingo_course_media';
  static const courseBackups = 'qql_course_backups_v11';
  static const importStaging = 'qql_import_staging';
  static const logs = 'qql_logs';
  static const sharedImages = 'exercise_images';
  static const imageBanks = 'image_banks';

  /// The earlier folders QQL no longer reads at all. The earlier [logs] are
  /// apart because they follow the Logs choice of Wipe everything, and
  /// [sharedImages] and [imageBanks] because their files are still in use.
  static const retired = <String>[
    courses,
    courseMedia,
    courseBackups,
    importStaging,
  ];

  /// Those of [names] that are folders in [support], by their exact names.
  /// On a system that ignores case (Windows, macOS) `qql_logs` and
  /// `QQL_Logs` reach one folder, so a folder that is one of the [current]
  /// folders under another case is not an earlier one.
  static Future<List<String>> presentIn(
    Directory support,
    Iterable<String> names, {
    Iterable<String> current = const [],
  }) async {
    if (!await support.exists()) return const [];
    final listed = <String>{
      await for (final entity in support.list(followLinks: false))
        if (entity is Directory) _nameOf(entity),
    };
    final present = <String>[];
    for (final name in names) {
      if (!listed.contains(name)) continue;
      var isCurrent = false;
      for (final other in current) {
        if (other == name || other.toLowerCase() != name.toLowerCase()) {
          continue;
        }
        final path = '${support.path}${Platform.pathSeparator}';
        try {
          if (await Directory('$path$other').exists() &&
              await FileSystemEntity.identical('$path$name', '$path$other')) {
            isCurrent = true;
          }
        } on FileSystemException {
          // Cannot tell: treat it as the earlier folder it is named as.
        }
      }
      if (!isCurrent) present.add(name);
    }
    return present;
  }

  /// Gives the folder [current] in [parent] exactly that name when it has it
  /// only in another case. On a system that ignores case (Windows, macOS)
  /// Revision 3's `qql_logs` is the folder `QQL_Logs` reaches, and would keep
  /// its lowercase name. On a system that tells case apart it is another
  /// folder and stays untouched. A folder that cannot be renamed keeps
  /// working under its earlier case.
  static Future<void> giveCurrentCase(Directory parent, String current) async {
    try {
      final target = Directory(
        '${parent.path}${Platform.pathSeparator}$current',
      );
      if (!await target.exists()) return;
      Directory? other;
      await for (final entity in parent.list(followLinks: false)) {
        final name = _nameOf(entity);
        if (name == current) return;
        if (entity is Directory &&
            name.toLowerCase() == current.toLowerCase()) {
          other = entity;
        }
      }
      if (other == null ||
          !await FileSystemEntity.identical(other.path, target.path)) {
        return;
      }
      await other.rename(target.path);
    } catch (_) {
      // Only a name: the folder keeps working under its earlier case.
    }
  }

  static String _nameOf(FileSystemEntity entity) => entity.path
      .split(RegExp(r'[\\/]'))
      .lastWhere((part) => part.isNotEmpty);
}
