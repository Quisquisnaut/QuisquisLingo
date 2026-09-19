import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'course_editor_storage.dart';
import 'learner_status_events.dart';
import 'profile_service.dart';

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
  final int mediaFileCount;
  final bool hasCustomCourses;

  const AppResetPreview({
    required this.learnerCount,
    required this.nonAdminLearnerCount,
    required this.mediaFileCount,
    required this.hasCustomCourses,
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

  static const _mediaFolders = <String>[
    'exercise_images',
    'image_banks',
    'quisquislingo_audio',
  ];

  final ProfileService _profiles;
  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _support;

  AppResetService({
    ProfileService? profiles,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? supportDirectory,
  }) : _profiles = profiles ?? ProfileService(),
       _documents = documentsDirectory ?? getApplicationDocumentsDirectory,
       _support = supportDirectory ?? getApplicationSupportDirectory;

  Future<Directory> _qqlDocuments() async => Directory(
    '${(await _documents()).path}${Platform.pathSeparator}QuisquisLingo',
  );

  Future<List<Directory>> _mediaDirectories() async {
    final support = (await _support()).path;
    return [
      for (final name in _mediaFolders)
        Directory('$support${Platform.pathSeparator}$name'),
    ];
  }

  Future<AppResetPreview> preview() async {
    final prefs = await SharedPreferences.getInstance();
    final learners = await _profiles.getProfileRecords();
    final admins = await _profiles.getAdminProfileIds();
    var files = 0;
    for (final directory in await _mediaDirectories()) {
      if (!await directory.exists()) continue;
      files += await directory
          .list(recursive: true, followLinks: false)
          .where((entity) => entity is File)
          .length;
    }
    return AppResetPreview(
      learnerCount: learners.length,
      nonAdminLearnerCount: learners
          .where((learner) => !admins.contains(learner.learnerProfileId))
          .length,
      mediaFileCount: files,
      hasCustomCourses: _courseKeys.any(prefs.containsKey),
    );
  }

  /// Resets [scope]. [keepExports] and [keepLogs] apply only to
  /// [AppResetScope.everything].
  Future<void> reset(
    AppResetScope scope, {
    required String actorProfileId,
    required String pin,
    bool keepExports = true,
    bool keepLogs = true,
  }) async {
    await _authorize(actorProfileId, pin);
    switch (scope) {
      case AppResetScope.learnerProgress:
        await _resetLearnerProgress();
      case AppResetScope.nonAdminLearners:
        await _removeNonAdminLearners();
      case AppResetScope.importedMedia:
        await _removeImportedMedia();
      case AppResetScope.customCourses:
        await _removeCustomCourses();
      case AppResetScope.everything:
        await _wipeEverything(keepExports: keepExports, keepLogs: keepLogs);
    }
    ProfileService.beginAccessSession();
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

  Future<void> _removeNonAdminLearners() async {
    final prefs = await SharedPreferences.getInstance();
    final learners = await _profiles.getProfileRecords();
    final admins = await _profiles.getAdminProfileIds();
    final removed = learners
        .where((learner) => !admins.contains(learner.learnerProfileId))
        .map((learner) => learner.learnerProfileId)
        .toSet();
    if (removed.isEmpty) return;
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

  Future<void> _removeImportedMedia() async {
    for (final directory in await _mediaDirectories()) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in _mediaKeys) {
      await prefs.remove(key);
    }
  }

  Future<void> _removeCustomCourses() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _courseKeys) {
      await prefs.remove(key);
    }
    await _removeImportedMedia();
  }

  Future<void> _wipeEverything({
    required bool keepExports,
    required bool keepLogs,
  }) async {
    // Files first and preferences last: the reset is idempotent, so if the app
    // dies part-way the admin (and the PIN) still exist and can run it again.
    for (final directory in await _mediaDirectories()) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
    final root = await _qqlDocuments();
    if (await root.exists()) {
      final kept = <String>{if (keepExports) 'exports', if (keepLogs) 'logs'};
      await for (final entity in root.list(followLinks: false)) {
        final name = entity.uri.pathSegments
            .lastWhere((segment) => segment.isNotEmpty)
            .toLowerCase();
        if (kept.contains(name)) continue;
        await entity.delete(recursive: true);
      }
    }
    await (await SharedPreferences.getInstance()).clear();
  }
}
