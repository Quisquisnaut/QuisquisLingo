import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_pin_gate.dart';
import 'course_editor_service.dart';
import 'course_media_store.dart';
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

  Future<void> run(
    InventoryAction action, {
    required String actorProfileId,
    required String pin,
  }) async {
    final problem = await AdminPinGate(
      _profiles,
    ).problem(actorProfileId, pin, what: 'delete what the Inventory lists');
    if (problem != null) throw InventoryActionException(problem);
    try {
      await _run(action, actorProfileId);
    } on InventoryActionException {
      rethrow;
    } catch (error) {
      throw InventoryActionException(_readable(error));
    }
    await DiagnosticLogService().logInfo(
      'Inventory: ${action.label} ${action.kind.name} ${action.target}',
    );
  }

  Future<void> _run(InventoryAction action, String actor) async {
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
        await _courses.deleteUserCourse(action.target);
      case InventoryActionKind.deletePublisherCourse:
        final course = (await _courses.listUserCourses())
            .where((candidate) => candidate.courseId == action.target)
            .firstOrNull;
        if (course == null) {
          throw const InventoryActionException(
            'This Publisher Course is no longer on this device.',
          );
        }
        await _courses.removePublisherCourseFromDevice(course);
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
