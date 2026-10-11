import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_pin_gate.dart';
import 'course_backup_service.dart';
import 'course_editor_service.dart';
import 'course_learners.dart';
import 'course_media_store.dart';
import 'course_service.dart';
import 'storage/course_storage_names.dart';
import 'course_favorite_service.dart';
import 'course_received_service.dart';
import 'diagnostic_log_service.dart';
import 'exercise_image_metadata_service.dart';
import 'image_bank_service.dart';
import 'inventory_service.dart';
import 'profile_service.dart';
import 'publisher_export_memory.dart';
import 'course_wizard_memory.dart';
import 'course_backup_retention.dart';

/// Refused, with the reason people read; nothing was changed.
class InventoryActionException implements Exception {
  const InventoryActionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What the Inventory shows before it deletes a Course (Build 271 Revision 1
/// follow-up, owner decisions of 11 October 2026): who has it, who kept
/// progress on it after removing it, and what its backup folder holds.
class InventoryCoursePreview {
  const InventoryCoursePreview({
    required this.courseId,
    required this.publisher,
    required this.unopenable,
    required this.inCourses,
    required this.includesYou,
    required this.keptProgress,
    required this.backups,
    this.notYours = false,
    this.maintainerName,
  });

  final String courseId;

  /// A custom Course the admin may not delete without the override: they
  /// are neither its Maintainer nor a member of its Team.
  final bool notYours;

  /// Its Maintainer's name when [notYours], or null when that learner is
  /// no longer on this device.
  final String? maintainerName;

  /// Remove Publisher Course from device: its progress, media and backups
  /// stay for a reinstallation unless the admin chooses otherwise.
  final bool publisher;

  /// A stored Course this version cannot open.
  final bool unopenable;

  /// The other learners whose Course list shows the Course, by name.
  final List<String> inCourses;

  /// Whether the admin's own Course list shows it.
  final bool includesYou;

  /// The learners who removed it from their courses and kept their
  /// progress on it, by name.
  final List<String> keptProgress;

  final CourseBackupsSummary backups;

  static String _joined(List<String> names) => names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';

  /// Whether removing it would be refused because other learners have it:
  /// a Publisher Course in someone else's courses.
  bool get othersBlockRemoval => publisher && inCourses.isNotEmpty;

  /// Whether the Delete is one the service refuses to the admin, who may
  /// still do it with the word [InventoryActionService.overrideWord] and a
  /// second confirmation (Build 271 Revision 1 second follow-up, owner
  /// decision of 11 October 2026: the admin can clean up anything, after a
  /// warning): a Publisher Course other learners have, or a custom Course
  /// the admin neither maintains nor shares through its Team.
  bool get needsOverride => othersBlockRemoval || notYours;

  /// "Anna and Marco", for the texts of the override.
  String get others => _joined(inCourses);

  /// Who maintains a Course that is not the admin's.
  String get maintainer =>
      maintainerName ?? 'A learner no longer on this device';

  /// What the admin is told before overriding, with where each consequence
  /// is decided; null when no override is needed.
  String? get overrideWarning {
    if (othersBlockRemoval) {
      return 'Removing it takes it out of their courses until it is '
          'installed again, and a learner studying it will find another '
          'Course selected. Their progress on it stays; to reset it too, '
          'tick “Also reset everyone\'s progress on this Course” below.';
    }
    if (notYours) {
      return '$maintainer maintains this Course, not you: deleting it '
          'removes their work from this device. Its saved versions stay in '
          'Backups/Courses unless you tick “Also delete all its backups” '
          'below, and the learners\' progress on it stays unless you tick '
          '“Also reset everyone\'s progress on this Course”.';
    }
    return null;
  }

  /// The title of the second confirmation of an override.
  String get overrideTitle => othersBlockRemoval
      ? 'Remove it from everyone?'
      : 'Delete another learner\'s Course?';

  /// The button of the second confirmation of an override.
  String get overrideButton =>
      othersBlockRemoval ? 'Remove it anyway' : 'Delete it anyway';

  /// The second confirmation of an override: what goes, and what the admin
  /// chose for progress and backups, with where to change it.
  String overrideQuestion(
    String title, {
    required bool resetProgress,
    required bool deleteBackups,
  }) {
    final progress = resetProgress
        ? 'The learners\' progress on it will be reset too, as you chose '
              'with “Also reset everyone\'s progress on this Course”.'
        : 'The learners\' progress on it stays. To reset it too, choose '
              'Keep the Course and tick “Also reset everyone\'s progress '
              'on this Course”.';
    if (othersBlockRemoval) {
      return '$others ${inCourses.length == 1 ? 'has' : 'have'} “$title” in '
          'their courses. It will be gone for them until it is installed '
          'again. $progress This cannot be undone.';
    }
    final backups = deleteBackups
        ? 'Its backups will be deleted too, as you chose with “Also delete '
              'all its backups”: nothing of it will be left on this device.'
        : 'Its saved versions stay in Backups/Courses. To delete them too, '
              'choose Keep the Course and tick “Also delete all its '
              'backups”.';
    return '$maintainer maintains “$title”, not you. Deleting it removes '
        'their work from this device. $backups $progress This cannot be '
        'undone.';
  }

  /// "Anna, Marco and you have this Course in your courses.", or null when
  /// nobody has it.
  String? get haveIt {
    final names = [...inCourses, if (includesYou) 'you'];
    if (names.isEmpty) return null;
    if (inCourses.isEmpty) return 'You have this Course in your courses.';
    return '${_joined(names)} ${names.length == 1 ? 'has' : 'have'} this '
        'Course in ${includesYou ? 'your' : 'their'} courses.';
  }

  /// "Carla removed it from their courses but kept their progress on it.",
  /// or null when nobody did.
  String? get keptIt => keptProgress.isEmpty
      ? null
      : '${_joined(keptProgress)} removed it from their courses but kept '
            'their progress on it.';
}

/// Runs an Inventory item's Delete or Forget (Build 266 Revision 2, owner
/// decisions of 8 October 2026: "yes to all"). Every action needs the
/// admin's PIN, like the resets, and goes through the rules the rest of QQL
/// applies: a learner through ProfileService, a Course through
/// CourseEditorService, an image or a bank through the Shared Image
/// Library's own removals. A file is deleted only inside QQL's own folders,
/// never the live Crash Log or session marker.
class InventoryActionService {
  InventoryActionService({
    ProfileService? profiles,
    CourseEditorService? courses,
    ExerciseImageMetadataService? images,
    ImageBankService? banks,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? supportDirectory,
  }) : _profiles = profiles ?? ProfileService(),
       _coursesOverride = courses,
       _imagesOverride = images,
       _banksOverride = banks,
       _documents = documentsDirectory ?? getApplicationDocumentsDirectory,
       _support = supportDirectory ?? getApplicationSupportDirectory;

  final ProfileService _profiles;
  final CourseEditorService? _coursesOverride;
  final ExerciseImageMetadataService? _imagesOverride;
  final ImageBankService? _banksOverride;
  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _support;

  CourseEditorService get _courses =>
      _coursesOverride ?? CourseEditorService(profileService: _profiles);
  ExerciseImageMetadataService get _images =>
      _imagesOverride ??
      ExerciseImageMetadataService(profileService: _profiles);
  ImageBankService get _banks => _banksOverride ?? ImageBankService();

  /// The settings keys Forget may remove: the records the Inventory lists.
  static bool isForgettable(String key) =>
      key.startsWith(CourseReceivedService.keyPrefix) ||
      key.startsWith(PublisherExportMemory.keyPrefix) ||
      key.startsWith(CourseWizardMemory.keyPrefix) ||
      key.startsWith(CourseBackupRetention.keyPrefix) ||
      (key.startsWith('learner_') &&
          key.contains('_${CourseFavoriteService.keyPrefix}'));

  /// Whether [action] deletes a stored Course (custom, Publisher, or one
  /// this version cannot open): its target is the Course ID.
  static bool isCourseAction(InventoryAction action) =>
      action.kind == InventoryActionKind.deleteCourse ||
      action.kind == InventoryActionKind.deletePublisherCourse;

  /// What the dialog shows before a Course goes (Build 271 Revision 1
  /// follow-up); null for any other action.
  Future<InventoryCoursePreview?> previewCourse(
    InventoryAction action, {
    required String actorProfileId,
  }) async {
    if (!isCourseAction(action)) return null;
    final courseId = action.target;
    final courses = _courses;
    final course = (await courses.listUserCourses())
        .where((candidate) => candidate.courseId == courseId)
        .firstOrNull;
    final learners = await CourseLearnersService(
      profiles: _profiles,
    ).of(courseId, course: course);
    final notYours =
        course != null &&
        action.kind == InventoryActionKind.deleteCourse &&
        !await courses.mayDeleteUserCourse(course);
    final maintainerId = course?.maintainer?.profileId;
    final maintainer = notYours && maintainerId != null
        ? await _profiles.getProfileById(maintainerId)
        : null;
    return InventoryCoursePreview(
      notYours: notYours,
      maintainerName: maintainer?.displayName,
      courseId: courseId,
      publisher: action.kind == InventoryActionKind.deletePublisherCourse,
      unopenable: course == null,
      inCourses: [
        for (final learner in learners.inCourses)
          if (learner.learnerProfileId != actorProfileId) learner.displayName,
      ],
      includesYou: learners.inCourses.any(
        (learner) => learner.learnerProfileId == actorProfileId,
      ),
      keptProgress: [
        for (final learner in learners.keptProgress) learner.displayName,
      ],
      backups: await courses.backupService.summaryOf(courseId),
    );
  }

  /// The word the admin types to go ahead with a Delete the service
  /// refuses otherwise (owner decision of 11 October 2026).
  static const overrideWord = 'DELETE';

  /// Runs [action]. For a Course, once it is gone, [resetEveryonesProgress]
  /// resets every learner's progress on it and [deleteBackups] deletes its
  /// backup folder (Build 271 Revision 1 follow-up); a refused Delete throws
  /// and neither happens. Returns what could not be done, or null.
  ///
  /// [adminOverride] goes ahead with a Delete that is otherwise refused: a
  /// Publisher Course other learners have in their courses, or a custom
  /// Course the admin neither maintains nor shares through its Team. It
  /// needs [typedWord] to be [overrideWord], besides the PIN.
  Future<String?> run(
    InventoryAction action, {
    required String actorProfileId,
    required String pin,
    bool resetEveryonesProgress = false,
    bool deleteBackups = false,
    bool adminOverride = false,
    String typedWord = '',
  }) async {
    final problem = await AdminPinGate(
      _profiles,
    ).problem(actorProfileId, pin, what: 'delete what the Inventory lists');
    if (problem != null) throw InventoryActionException(problem);
    final course = isCourseAction(action);
    if (!course && (resetEveryonesProgress || deleteBackups)) {
      throw const InventoryActionException(
        'Progress and backups go with a Course only.',
      );
    }
    if (adminOverride) {
      if (!course) {
        throw const InventoryActionException(
          'Only the Delete of a Course can be forced here.',
        );
      }
      if (typedWord.trim() != overrideWord) {
        throw const InventoryActionException(
          'Type DELETE in capital letters to go ahead. Nothing was changed.',
        );
      }
    }
    final courses = _courses;
    try {
      await _run(action, actorProfileId, adminOverride: adminOverride);
    } on InventoryActionException {
      rethrow;
    } catch (error) {
      throw InventoryActionException(_readable(error));
    }
    final notes = <String>[];
    if (resetEveryonesProgress) {
      try {
        await CourseLearnersService(
          profiles: _profiles,
        ).resetEveryone(action.target);
      } catch (_) {
        notes.add('The progress on it could not be reset.');
      }
    }
    if (deleteBackups &&
        !await courses.backupService.deleteAllBackups(action.target)) {
      notes.add(
        'Some of its backup files could not be deleted; they are still in '
        'Backups/Courses.',
      );
    }
    await DiagnosticLogService().logInfo(
      'Inventory: ${action.label} ${action.kind.name} ${action.target}'
      '${adminOverride ? ', with the admin override' : ''}'
      '${resetEveryonesProgress ? ', everyone\'s progress on it reset' : ''}'
      '${deleteBackups ? ', its backups deleted' : ''}',
    );
    return notes.isEmpty ? null : notes.join(' ');
  }

  Future<void> _run(
    InventoryAction action,
    String actor, {
    bool adminOverride = false,
  }) async {
    switch (action.kind) {
      case InventoryActionKind.deleteLearner:
        await _profiles.deleteProfileById(action.target, actorProfileId: actor);
      case InventoryActionKind.forget:
        if (!isForgettable(action.target)) {
          throw const InventoryActionException(
            'This record is not one the Inventory can forget.',
          );
        }
        await (await SharedPreferences.getInstance()).remove(action.target);
      case InventoryActionKind.deleteCourse:
        await _courses.deleteUserCourse(
          action.target,
          adminOverride: adminOverride,
        );
      case InventoryActionKind.deletePublisherCourse:
        final course = (await _courses.listUserCourses())
            .where((candidate) => candidate.courseId == action.target)
            .firstOrNull;
        if (course == null) {
          throw const InventoryActionException(
            'This Publisher Course is no longer on this device.',
          );
        }
        await _courses.removePublisherCourseFromDevice(
          course,
          evenIfOthersHaveIt: adminOverride,
        );
      case InventoryActionKind.deleteFile:
        final file = File(action.target);
        await _requireOwnFile(file);
        if (await file.exists()) await file.delete();
      case InventoryActionKind.deleteDeviceImage:
        final file = File(action.target);
        await _requireOwnFile(file);
        final records = await _images.loadCatalog();
        final ids = {
          for (final record in records)
            if (record.origin != 'bundled' &&
                File(record.assetPath).absolute.path == file.absolute.path)
              record.id,
        };
        if (ids.isNotEmpty) {
          await _images.removeLocalRecords(
            actorProfileId: actor,
            imageIds: ids,
          );
        }
        if (await file.exists()) await file.delete();
      case InventoryActionKind.deleteCourseMediaFolder:
        await _deleteCourseMediaFolder(Directory(action.target));
      case InventoryActionKind.resetCourseProgress:
        final courses = _courses;
        final onDevice = <String>{
          ...CourseService.bundledCourseIds,
          for (final course in await courses.listUserCourses()) course.courseId,
          for (final file in courses.unreadableCourseFiles)
            if (file.courseId case final id?) id,
        };
        if (onDevice.contains(action.target)) {
          throw const InventoryActionException(
            'This Course is on this device again. Its progress can be reset '
            'when the Course is deleted here, or by each learner with '
            'Remove from my courses.',
          );
        }
        await CourseLearnersService(
          profiles: _profiles,
        ).resetEveryone(action.target);
      case InventoryActionKind.removeImageBank:
        final records = await _images.loadCatalog();
        final removed = await _banks.removeBank(action.target);
        final ids = {
          for (final record in records)
            if (removed.contains(record.id) &&
                record.origin == 'bank:${action.target}')
              record.id,
        };
        if (ids.isNotEmpty) {
          await _images.removeLocalRecords(
            actorProfileId: actor,
            imageIds: ids,
          );
        }
    }
  }

  /// Build 271 Revision 1: the whole media folder of a Course no longer on
  /// this device. The folder must be one of the Course media folders and no
  /// stored Course, readable or not, may own it: both are checked again
  /// here, because the Inventory may have been read a while ago.
  Future<void> _deleteCourseMediaFolder(Directory folder) async {
    final root = await CourseMediaStore(
      supportDirectory: _support,
    ).rootDirectory();
    final name = folder.absolute.uri.pathSegments.lastWhere(
      (segment) => segment.isNotEmpty,
    );
    final hash = CourseStorageNames.hashOfMediaFolder(name);
    final expected = Directory(
      '${root.absolute.path}${Platform.pathSeparator}$name',
    );
    bool same(String a, String b) =>
        Platform.isWindows ? a.toLowerCase() == b.toLowerCase() : a == b;
    if (hash == null ||
        !same(folder.absolute.path, expected.absolute.path) ||
        await FileSystemEntity.isLink(folder.path)) {
      throw const InventoryActionException(
        'Only a Course media folder can be deleted here.',
      );
    }
    final courses = _courses;
    final owners = <String>{
      for (final course in await courses.listUserCourses())
        CourseStorageNames.hashOf(course.courseId),
      for (final file in courses.unreadableCourseFiles)
        if (file.courseId case final id?) CourseStorageNames.hashOf(id),
    };
    if (owners.contains(hash)) {
      throw const InventoryActionException(
        'A Course on this device uses this folder. Nothing was deleted.',
      );
    }
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  /// A file inside QQL's own folders, never the live Crash Log or session
  /// marker (Settings › Debug keeps those; Save&Open copies them).
  Future<void> _requireOwnFile(File file) async {
    final path = file.absolute.path;
    final roots = [
      '${(await _documents()).absolute.path}${Platform.pathSeparator}QuisquisLingo',
      (await _support()).absolute.path,
    ];
    bool inside(String root) => path.toLowerCase().startsWith(
      '${root.toLowerCase()}${Platform.pathSeparator}',
    );
    if (!roots.any(inside)) {
      throw const InventoryActionException(
        'Only files in QQL\'s own folders can be deleted here.',
      );
    }
    final logs =
        '${(await _support()).absolute.path}${Platform.pathSeparator}'
        '${DiagnosticLogService.logsDirectoryName}';
    if (inside(logs)) {
      throw const InventoryActionException(
        'The live Crash Log stays; Settings › Debug saves copies of it.',
      );
    }
  }

  static String _readable(Object error) => '$error'.replaceFirst(
    RegExp(r'^(Bad state|FormatException|Invalid argument\(s\)): ?'),
    '',
  );
}
