import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_access_policy.dart';
import 'course_editor_storage.dart';
import 'course_file_store.dart';
import 'course_received_service.dart';
import 'course_media_store.dart';
import 'course_privacy.dart';
import 'diagnostic_log_service.dart';
import 'exercise_image_service.dart';
import 'image_bank_service.dart';
import 'learner_status_events.dart';
import 'profile_service.dart';
import 'import/import_stager.dart';
import 'storage/qql_earlier_private_folders.dart';
import 'storage/qql_storage.dart';

/// The ways an admin can reset this device. See
/// docs/239_RESET_STORAGE_INVENTORY.md for what each scope removes.
enum AppResetScope {
  learnerProgress,
  nonAdminLearners,
  importedMedia,
  customCourses,
  everything,
}

class AppResetException implements Exception {
  final String message;
  const AppResetException(this.message);

  @override
  String toString() => message;
}

class AppResetPreview {
  final int learnerCount;
  final int nonAdminLearnerCount;
  final int imageFileCount;
  final int audioFileCount;
  final bool hasCustomCourses;

  /// True when QQL's settings hold an image-bank list or edits to the
  /// shared image library, which "Remove images" also clears even when no
  /// image file exists.
  final bool hasImageLibraryRecords;

  /// How many stored Private courses the active admin cannot see (Build 259
  /// Revision 8): removing custom courses removes them too.
  final int hiddenPrivateCourseCount;

  /// The Courses a non-admin learner maintains, named for the active admin
  /// (another learner's Private course is "a Private course"): removing the
  /// non-admin learners is refused while there are any (Build 259 Revision
  /// 8).
  final List<String> coursesMaintainedByNonAdmins;

  int get mediaFileCount => imageFileCount + audioFileCount;

  const AppResetPreview({
    required this.learnerCount,
    required this.nonAdminLearnerCount,
    required this.imageFileCount,
    required this.audioFileCount,
    required this.hasCustomCourses,
    required this.hasImageLibraryRecords,
    this.hiddenPrivateCourseCount = 0,
    this.coursesMaintainedByNonAdmins = const [],
  });
}

/// Performs admin resets. Every reset requires an admin actor who has set a
/// PIN and supplies it; the check is made here, not only in the UI.
class AppResetService {
  static const progressSuffixPatterns = <String>[
    'v4_',
    'v1_vocabulary_review_course_',
    'xp_',
    'week_xp',
    'last_week_xp',
    'week_goal_celebrated_week',
    'study_days',
    'streak_',
    'last_active_',
    'guidebook_availability_notice_seen',
  ];

  static const _teamsKey = 'quisquislingo_authoring_teams_v1_2291';

  static const _courseKeys = <String>[
    CourseEditorStorage.userCoursesKey,
    CourseEditorStorage.externalOfficialCoursesKey,
    CourseEditorStorage.corruptBackupKey,
    _teamsKey,
  ];

  static const _mediaKeys = <String>[
    'quisquislingo_imported_image_banks_v2',
    'quisquislingo_exercise_image_metadata_v2',
  ];

  /// Device-level prefix, one key per Course code, holding the date the
  /// Audio Library orphan check last ran. Removing the recordings makes the
  /// stored date meaningless, so the audio reset clears it too.
  static const audioOrphanCheckKeyPrefix = 'audio_orphan_check_last_';

  /// Shared Image Library device images and Image Banks, in their folders and
  /// in the folders earlier versions used, whose files are still in use.
  static const _imageFolders = <String>[
    ExerciseImageService.sharedImagesDirectoryName,
    QqlEarlierPrivateFolders.sharedImages,
    ImageBankService.banksDirectoryName,
    QqlEarlierPrivateFolders.imageBanks,
  ];

  /// Course media (`CourseMediaStore`) holds both images and recordings, one
  /// folder per Course; the imported-media reset removes them by file type.
  static const _courseMediaFolder = CourseMediaStore.rootDirectoryName;

  static bool _isCourseAudio(File file) =>
      file.path.toLowerCase().endsWith('.mp3');

  Future<List<File>> _courseMediaFiles({
    required bool images,
    required bool audio,
  }) async {
    final root = (await _directories([_courseMediaFolder])).single;
    if (!await root.exists()) return const [];
    return [
      await for (final entity in root.list(recursive: true, followLinks: false))
        if (entity is File && (_isCourseAudio(entity) ? audio : images)) entity,
    ];
  }

  final ProfileService _profiles;
  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _support;
  final QqlStorage _storage;

  AppResetService({
    ProfileService? profiles,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? supportDirectory,
    QqlStorage? storage,
  }) : _profiles = profiles ?? ProfileService(),
       _documents = documentsDirectory ?? getApplicationDocumentsDirectory,
       _support = supportDirectory ?? getApplicationSupportDirectory,
       _storage = storage ?? QqlStorage();

  Future<Directory> _qqlDocuments() async => Directory(
    '${(await _documents()).path}${Platform.pathSeparator}QuisquisLingo',
  );

  Future<List<Directory>> _directories(List<String> names) async {
    final support = (await _support()).path;
    return [
      for (final name in names)
        Directory('$support${Platform.pathSeparator}$name'),
    ];
  }

  Future<int> _countFiles(List<Directory> directories) async {
    var files = 0;
    for (final directory in directories) {
      if (!await directory.exists()) continue;
      files += await directory
          .list(recursive: true, followLinks: false)
          .where((entity) => entity is File)
          .length;
    }
    return files;
  }

  Future<AppResetPreview> preview() async {
    final prefs = await SharedPreferences.getInstance();
    final learners = await _profiles.getProfileRecords();
    final admins = await _profiles.getAdminProfileIds();
    // One pass over course media counts both kinds.
    final courseMedia = await _courseMediaFiles(images: true, audio: true);
    final audio = courseMedia.where(_isCourseAudio).length;
    final courses = await _storedCustomCourses();
    final images =
        await _countFiles(await _directories(_imageFolders)) +
        courseMedia.length -
        audio;
    return AppResetPreview(
      learnerCount: learners.length,
      nonAdminLearnerCount: learners
          .where((learner) => !admins.contains(learner.learnerProfileId))
          .length,
      imageFileCount: images,
      audioFileCount: audio,
      hasCustomCourses:
          _courseKeys.any(prefs.containsKey) ||
          prefs.getKeys().any(
            (key) =>
                key.startsWith(CourseReceivedService.keyPrefix) &&
                prefs.getBool(key) == true,
          ) ||
          await _countFiles(
                await _directories([CourseFileStore.rootDirectoryName]),
              ) >
              0,
      hasImageLibraryRecords: _mediaKeys.any(prefs.containsKey),
      hiddenPrivateCourseCount: await _hiddenPrivateCourseCount(courses),
      coursesMaintainedByNonAdmins: await _maintainedCourseNames(
        courses,
        learners
            .where((learner) => !admins.contains(learner.learnerProfileId))
            .map((learner) => learner.learnerProfileId)
            .toSet(),
        await _profiles.getActiveProfileId(),
      ),
    );
  }

  /// Resets [scope]. [keepExports], [keepLogs], [keepImports] and
  /// [keepBackups] apply only to [AppResetScope.everything]. [removeImages]
  /// and [removeAudio] choose what [AppResetScope.importedMedia] removes; at
  /// least one must be true.
  Future<void> reset(
    AppResetScope scope, {
    required String actorProfileId,
    required String pin,
    bool keepExports = true,
    bool keepLogs = true,
    bool keepImports = true,
    bool keepBackups = true,
    bool removeImages = true,
    bool removeAudio = true,
  }) async {
    await _authorize(actorProfileId, pin);
    if (scope == AppResetScope.importedMedia && !removeImages && !removeAudio) {
      throw const AppResetException(
        'Choose at least one kind of media to remove.',
      );
    }
    switch (scope) {
      case AppResetScope.learnerProgress:
        await _resetLearnerProgress();
      case AppResetScope.nonAdminLearners:
        await _removeNonAdminLearners(actorProfileId);
      case AppResetScope.importedMedia:
        await _removeImportedMedia(images: removeImages, audio: removeAudio);
      case AppResetScope.customCourses:
        await _removeCustomCourses();
      case AppResetScope.everything:
        await _wipeEverything(
          keepExports: keepExports,
          keepLogs: keepLogs,
          keepImports: keepImports,
          keepBackups: keepBackups,
        );
    }
    // Only a full wipe ends the session. Any other reset must leave the admin
    // unlocked, otherwise their own PIN-protected profile would look logged out.
    if (scope == AppResetScope.everything) ProfileService.beginAccessSession();
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
  }

  Future<void> _authorize(String actorProfileId, String pin) async {
    if (!await _profiles.isAdmin(actorProfileId)) {
      throw const AppResetException('Only an admin may reset QQL.');
    }
    if (!await _profiles.hasAccessPin(actorProfileId)) {
      throw const AppResetException('Set a PIN before using reset options.');
    }
    if (!await _profiles.verifyAccessPin(actorProfileId, pin)) {
      throw const AppResetException('Incorrect PIN. Nothing was changed.');
    }
  }

  // Personal course membership is a setting, not progress: keep it here.
  // Profile removal and full reset clear it with all other profile keys.
  Future<void> _resetLearnerProgress() async {
    final prefs = await SharedPreferences.getInstance();
    for (final learner in await _profiles.getProfileRecords()) {
      final prefix = ProfileService.prefixForProfileId(
        learner.learnerProfileId,
      );
      for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
        final suffix = key.substring(prefix.length);
        if (progressSuffixPatterns.any(suffix.startsWith)) {
          await prefs.remove(key);
        }
      }
    }
  }

  /// The stored custom Courses that can be read. An unreadable file names
  /// no Maintainer and is listed by nobody anyway, so it is skipped.
  Future<List<Course>> _storedCustomCourses() async {
    final records = (await CourseFileStore(
      supportDirectory: _support,
    ).readReadable(CourseStoreKind.custom)).records;
    return [
      for (final record in records.values)
        if (record is Map && record['course'] is Map)
          Course.fromJson(Map<String, dynamic>.from(record['course'] as Map)),
    ];
  }

  Future<int> _hiddenPrivateCourseCount(List<Course> courses) async {
    final privacy = CoursePrivacy(
      accessPolicy: CourseAccessPolicy(profileService: _profiles),
    );
    var count = 0;
    for (final course in courses) {
      if (CoursePrivacy.isPrivate(course) && !await privacy.isVisible(course)) {
        count++;
      }
    }
    return count;
  }

  /// The Courses maintained by [maintainers], by title, except another
  /// learner's Private course, which [viewerProfileId] cannot see.
  Future<List<String>> _maintainedCourseNames(
    List<Course> courses,
    Set<String> maintainers,
    String? viewerProfileId,
  ) async {
    final privacy = CoursePrivacy(
      accessPolicy: CourseAccessPolicy(profileService: _profiles),
    );
    return [
      for (final course in courses)
        if (course.originType == CourseOriginType.custom &&
            maintainers.contains(course.maintainer?.profileId))
          await privacy.isVisibleTo(course, viewerProfileId)
              ? '“${course.title}”'
              : 'a Private course',
    ];
  }

  Future<void> _removeNonAdminLearners(String actorProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    final learners = await _profiles.getProfileRecords();
    final admins = await _profiles.getAdminProfileIds();
    final removed = learners
        .where((learner) => !admins.contains(learner.learnerProfileId))
        .map((learner) => learner.learnerProfileId)
        .toSet();
    if (removed.isEmpty) return;
    // Like deleting one profile (CourseMaintainerGuard): a learner who
    // maintains a Course is not removed, or their Private course would stay
    // on the device seen by nobody (Build 259 Revision 8, owner decision).
    final maintained = await _maintainedCourseNames(
      await _storedCustomCourses(),
      removed,
      actorProfileId,
    );
    if (maintained.isNotEmpty) {
      throw AppResetException(
        'These learners maintain ${maintained.join(', ')}. Change the Course Maintainer or delete those Courses first. Nothing was changed.',
      );
    }
    for (final id in removed) {
      final prefix = ProfileService.prefixForProfileId(id);
      for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
        await prefs.remove(key);
      }
    }
    await prefs.setStringList(
      ProfileService.profilesKey,
      learners
          .where((learner) => !removed.contains(learner.learnerProfileId))
          .map((learner) => learner.encode())
          .toList(),
    );
    final active = prefs.getString(ProfileService.activeProfileIdKey);
    if (active != null && removed.contains(active)) {
      await prefs.remove(ProfileService.activeProfileIdKey);
    }
    // Team membership is stored by learner ID inside one registry. Rather than
    // leave references to removed learners, drop the registry when it names
    // any of them; the custom-course reset explains that teams are removed.
    final teams = prefs.getString(_teamsKey);
    if (teams != null && removed.any(teams.contains)) {
      await prefs.remove(_teamsKey);
    }
  }

  Future<void> _removeImportedMedia({
    bool images = true,
    bool audio = true,
  }) async {
    final directories = [
      if (images) ...await _directories(_imageFolders),
      if (images && audio) ...await _directories([_courseMediaFolder]),
    ];
    for (final directory in directories) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
    if (images != audio) {
      for (final file in await _courseMediaFiles(
        images: images,
        audio: audio,
      )) {
        await file.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    if (images) {
      for (final key in _mediaKeys) {
        await prefs.remove(key);
      }
    }
    if (audio) {
      for (final key in prefs.getKeys().where(
        (key) => key.startsWith(audioOrphanCheckKeyPrefix),
      )) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _removeCourseFiles() async {
    final directory = await CourseFileStore(
      supportDirectory: _support,
    ).rootDirectory();
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<void> _removeCustomCourses() async {
    await _removeCourseFiles();
    final prefs = await SharedPreferences.getInstance();
    for (final key in _courseKeys) {
      await prefs.remove(key);
    }
    for (final key in prefs.getKeys().where(
      (key) => key.startsWith(CourseReceivedService.keyPrefix),
    )) {
      await prefs.remove(key);
    }
    await _removeImportedMedia();
  }

  Future<void> _wipeEverything({
    required bool keepExports,
    required bool keepLogs,
    required bool keepImports,
    required bool keepBackups,
  }) async {
    // Files first and preferences last: the reset is idempotent, so if the app
    // dies part-way the admin (and the PIN) still exist and can run it again.
    await _removeCourseFiles();
    await _removeImportedMedia();
    // The live Crash Log goes with the Logs choice.
    for (final directory in await _directories([
      ImportStager.stagingDirectoryName,
      if (!keepLogs) DiagnosticLogService.logsDirectoryName,
    ])) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
    // The private folders earlier versions used go too; their Crash Log
    // follows the Logs choice and their Course Backups the Backups choice.
    final support = await _support();
    for (final name in await QqlEarlierPrivateFolders.presentIn(
      support,
      [
        ...QqlEarlierPrivateFolders.retired,
        if (!keepLogs) QqlEarlierPrivateFolders.logs,
        if (!keepBackups) ...QqlEarlierPrivateFolders.backups,
      ],
      current: const [DiagnosticLogService.logsDirectoryName],
    )) {
      await Directory(
        '${support.path}${Platform.pathSeparator}$name',
      ).delete(recursive: true);
    }
    final root = await _qqlDocuments();
    if (await root.exists()) {
      // Folders from earlier versions follow the choice for their
      // replacement.
      bool keeps(QqlTopFolder folder) => switch (folder) {
        QqlTopFolder.export => keepExports,
        QqlTopFolder.logs => keepLogs,
        QqlTopFolder.import || QqlTopFolder.toBeMerged => keepImports,
        QqlTopFolder.backups => keepBackups,
      };
      final kept = <String>{
        for (final folder in QqlTopFolder.values)
          if (keeps(folder)) folder.folderName.toLowerCase(),
        for (final MapEntry(key: name, value: folder)
            in QqlTopFolder.earlierFolders.entries)
          if (keeps(folder)) name.toLowerCase(),
      };
      await for (final entity in root.list(followLinks: false)) {
        final name = entity.uri.pathSegments
            .lastWhere((segment) => segment.isNotEmpty)
            .toLowerCase();
        if (kept.contains(name)) continue;
        await entity.delete(recursive: true);
      }
    }
    // Android keeps the user folders public, in Download/QuisquisLingo: the
    // same ticks decide them, and a full wipe gives back the Quick Import
    // folder permission.
    final public = _storage.publicFolders;
    if (public != null) {
      if (!keepExports) await public.delete(QqlTopFolder.export);
      if (!keepLogs) await public.delete(QqlTopFolder.logs);
      if (!keepImports) {
        await public.delete(QqlTopFolder.import);
        await public.delete(QqlTopFolder.toBeMerged);
      }
      if (!keepBackups) await public.delete(QqlTopFolder.backups);
      await public.releaseImportAccess();
    }
    await (await SharedPreferences.getInstance()).clear();
  }
}
