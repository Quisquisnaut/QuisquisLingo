import 'dart:convert';
import 'course_flag_service.dart';
import 'course_editor_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_backup_service.dart';
import 'learner_status_events.dart';
import 'profile_service.dart';
import 'authoring_duplication_service.dart';
import 'course_access_policy.dart';
import 'team_service.dart';

class CourseConfirmationResult {
  final Course course;
  final String? backupPath;
  final bool hadPreviousVersion;

  const CourseConfirmationResult({
    required this.course,
    required this.backupPath,
    required this.hadPreviousVersion,
  });
}

class OfficialCourseUpdateResult {
  final Course officialCourse;
  final String? backupPath;

  const OfficialCourseUpdateResult({
    required this.officialCourse,
    required this.backupPath,
  });
}

/// Local, offline Course Model v9 authoring storage.
///
/// Bundled assets and imported official packages remain immutable sources.
/// Official sources are locally read-only. Only custom courses have authoring
/// transactions; nested editors never persist them independently.
class CourseEditorService {
  static const userCoursesStorageKey = CourseEditorStorage.userCoursesKey;
  static const externalOfficialStorageKey =
      CourseEditorStorage.externalOfficialCoursesKey;
  static const _corruptBackupKey = CourseEditorStorage.corruptBackupKey;
  static const _maxBytes = 8 * 1024 * 1024;
  static const _bundledOfficialCourseIds = {
    'sample_it_en_it',
    'sample_de_en_de',
    'sample_es_en_es',
    'sample_en_es_en',
    'sample_cy_en_cy',
    'sample_nl_en_nl',
    'sample_pt_en_pt',
    'sample_fi_en_fi',
    'sample_ko_en_ko',
  };

  CourseEditorService({
    CourseEditorPreferenceWriter? preferenceWriter,
    CourseBackupService? backupService,
    ProfileService? profileService,
    TeamService? teamService,
    CourseAccessPolicy? accessPolicy,
    DateTime Function()? clock,
  }) : _preferenceWriter = preferenceWriter,
       backupService = backupService ?? CourseBackupService(),
       _profiles = profileService ?? ProfileService(),
       _teams = teamService ?? TeamService(profileService: profileService),
       _access =
           accessPolicy ??
           CourseAccessPolicy(
             profileService: profileService,
             teamService: teamService,
           ),
       _clock = clock ?? DateTime.now;

  final CourseEditorPreferenceWriter? _preferenceWriter;
  final CourseBackupService backupService;
  final ProfileService _profiles;
  final TeamService _teams;
  final CourseAccessPolicy _access;
  final DateTime Function() _clock;

  Future<CourseAccessCapabilities> capabilitiesFor(Course course) =>
      _access.forCurrentProfile(course);

  Future<Map<String, dynamic>> _loadKey(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Stored authoring root must be an object.');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      await preferences.setString(_corruptBackupKey, raw);
      throw FormatException(
        'Stored Course Model v9 authoring data are invalid or unsupported. '
        'The original data were preserved and were not loaded. $error',
      );
    }
  }

  String _encodeKey(Map<String, dynamic> data) {
    final encoded = jsonEncode(data);
    if (utf8.encode(encoded).length > _maxBytes) {
      throw StateError(
        'Local course authoring data exceed the 8 MB safety limit. Export or simplify courses before saving more content.',
      );
    }
    return encoded;
  }

  Future<bool> _writePreference(
    SharedPreferences preferences,
    String key,
    String value,
  ) =>
      _preferenceWriter?.call(preferences, key, value) ??
      preferences.setString(key, value);

  Future<void> _writeVerified(
    SharedPreferences preferences,
    String key,
    String encoded,
  ) async {
    final saved = await _writePreference(preferences, key, encoded);
    if (!saved || preferences.getString(key) != encoded) {
      throw StateError('Verified local Course Editor storage write failed.');
    }
  }

  Future<void> _saveKey(String key, Map<String, dynamic> data) async {
    final preferences = await SharedPreferences.getInstance();
    await _writeVerified(preferences, key, _encodeKey(data));
  }

  Future<void> _replaceKeyAtomically(
    String key,
    Map<String, dynamic> data,
  ) async {
    final encoded = _encodeKey(data);
    final preferences = await SharedPreferences.getInstance();
    final previous = preferences.getString(key);
    try {
      await _writeVerified(preferences, key, encoded);
    } catch (error) {
      if (preferences.getString(key) != previous) {
        final restored = previous == null
            ? await preferences.remove(key)
            : await preferences.setString(key, previous);
        if (!restored || preferences.getString(key) != previous) {
          throw StateError(
            'Course transaction failed and the previous storage value could not be verified: $error',
          );
        }
      }
      rethrow;
    }
  }

  static Course _courseFromEntry(Object? entry) {
    if (entry is! Map || entry['course'] is! Map) {
      throw const FormatException('Stored course entry is invalid.');
    }
    return Course.fromJson(Map<String, dynamic>.from(entry['course'] as Map));
  }

  static Map<String, dynamic> _entry(Course course, DateTime savedAt) => {
    'savedAt': savedAt.toUtc().toIso8601String(),
    'course': course.toJson(),
  };

  Future<void> saveUserCourse(Course course) async {
    if (course.originType != CourseOriginType.custom) {
      throw ArgumentError('Official courses require official-source storage.');
    }
    course = await _materializeDetachedConstructorIdentity(course);
    Course.fromJson(course.toJson());
    if (_bundledOfficialCourseIds.contains(course.courseId) ||
        (await _loadKey(
          externalOfficialStorageKey,
        )).containsKey(course.courseId)) {
      throw const FormatException(
        'A custom course cannot replace an official course identity. Import it as a separate copy.',
      );
    }
    final all = await _loadKey(userCoursesStorageKey);
    final existing = all[course.courseId] == null
        ? null
        : _courseFromEntry(all[course.courseId]);
    final access = await _access.forCurrentProfile(existing ?? course);
    if (!access.canEditOriginal) {
      throw StateError(
        'Only the Course Maintainer or a member of the assigned Team can save this Course.',
      );
    }
    if (existing != null) {
      _requirePreservedProvenance(existing, course);
      await _requireAuthorizedGovernanceChange(existing, course);
    }
    all[course.courseId] = _entry(course, _clock());
    await _saveKey(userCoursesStorageKey, all);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  /// Installs an imported custom source without granting the importer access.
  /// Replacing an existing identity still requires Maintainer/assigned-Team
  /// authorization.
  Future<void> installImportedCustomCourse(Course course) async {
    if (course.originType != CourseOriginType.custom) {
      throw ArgumentError(
        'Only a custom course can use custom import storage.',
      );
    }
    Course.fromJson(course.toJson());
    if ((course.originalCourseCreator.type ==
                CourseProvenanceIdentityType.qqlUser &&
            course.originalCourseCreator.id ==
                Course.detachedInMemoryProfileId) ||
        course.maintainer?.profileId == Course.detachedInMemoryProfileId ||
        course.originalCreatedAtUtc.isEmpty) {
      throw const FormatException(
        'Imported Course Model v9 custom courses require real provenance, creation time and Maintainer metadata.',
      );
    }
    if (_bundledOfficialCourseIds.contains(course.courseId) ||
        (await _loadKey(
          externalOfficialStorageKey,
        )).containsKey(course.courseId)) {
      throw const FormatException(
        'A custom course cannot replace an official course identity. Import it as a separate copy.',
      );
    }
    final all = await _loadKey(userCoursesStorageKey);
    final existing = all[course.courseId];
    if (existing != null) {
      final current = _courseFromEntry(existing);
      await confirmCourseTransaction(
        originalCourse: current,
        workingCourse: course,
        languageCode: course.targetLanguageTag,
        versionNotes: course.versionNotes,
      );
      return;
    }
    all[course.courseId] = _entry(course, _clock());
    await _replaceKeyAtomically(userCoursesStorageKey, all);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<List<Course>> listUserCourses() async {
    final out = <Course>[];
    final custom = await _loadKey(userCoursesStorageKey);
    for (final item in custom.entries) {
      try {
        out.add(_courseFromEntry(item.value));
      } on FormatException catch (error) {
        throw FormatException(
          'Stored custom course ${item.key} has an unsupported course format or invalid data. It was preserved and was not loaded. $error',
        );
      }
    }
    final external = await _loadKey(externalOfficialStorageKey);
    for (final item in external.entries) {
      if (item.value is! Map) {
        throw FormatException(
          'Stored external official course ${item.key} is invalid.',
        );
      }
      final record = Map<String, dynamic>.from(item.value as Map);
      final source = Course.fromJson(
        Map<String, dynamic>.from(record['source'] as Map),
      );
      _validateOfficialSource(source);
      if (source.courseId != item.key ||
          source.originType != CourseOriginType.externalOfficial) {
        throw const FormatException(
          'Stored official source identity is invalid.',
        );
      }
      out.add(source);
    }
    out.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return out;
  }

  Future<bool> persistedCourseExists({
    required Course course,
    required String languageCode,
  }) async {
    if (course.originType == CourseOriginType.bundledOfficial) return true;
    if (course.originType == CourseOriginType.externalOfficial) {
      return (await _loadKey(
        externalOfficialStorageKey,
      )).containsKey(course.courseId);
    }
    return (await _loadKey(userCoursesStorageKey)).containsKey(course.courseId);
  }

  Future<void> deleteUserCourse(String courseId) async {
    final custom = await _loadKey(userCoursesStorageKey);
    final raw = custom[courseId];
    if (raw == null) return;
    final course = _courseFromEntry(raw);
    if (!(await _access.forCurrentProfile(course)).canDelete) {
      throw StateError(
        'Only the Course Maintainer or a member of the assigned Team can delete this Course.',
      );
    }
    custom.remove(courseId);
    await _saveKey(userCoursesStorageKey, custom);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<Course?> officialSourceFor(
    Course course, {
    Course? bundledSource,
  }) async {
    Course? source;
    if (course.originType == CourseOriginType.bundledOfficial) {
      source = bundledSource;
    } else if (course.originType == CourseOriginType.externalOfficial) {
      final record = (await _loadKey(
        externalOfficialStorageKey,
      ))[course.courseId];
      if (record is Map && record['source'] is Map) {
        source = Course.fromJson(
          Map<String, dynamic>.from(record['source'] as Map),
        );
      }
    }
    if (source != null) {
      _validateOfficialSource(source);
      if (source.courseId != course.courseId ||
          source.originType != course.originType ||
          source.publisherId != course.publisherId) {
        throw const FormatException(
          'The official source identity does not match.',
        );
      }
    }
    return source;
  }

  static void _validateOfficialSource(Course course) {
    if (!course.originType.isOfficial ||
        CourseBackupService.officialContentChecksum(course) !=
            course.officialChecksum) {
      throw const FormatException('The official package checksum is invalid.');
    }
  }

  static void _requirePreservedProvenance(Course original, Course candidate) {
    if (jsonEncode(original.forkProvenance?.toJson()) !=
            jsonEncode(candidate.forkProvenance?.toJson()) ||
        jsonEncode(original.originalCourseCreator.toJson()) !=
            jsonEncode(candidate.originalCourseCreator.toJson()) ||
        original.originalCreatedAtUtc != candidate.originalCreatedAtUtc) {
      throw const FormatException(
        'Original Course and fork provenance cannot be changed or removed.',
      );
    }
  }

  Future<void> _requireAuthorizedGovernanceChange(
    Course original,
    Course candidate, {
    bool governanceChangesMadeInEditMode = false,
  }) async {
    final maintainerChanged =
        jsonEncode(original.maintainer?.toJson()) !=
        jsonEncode(candidate.maintainer?.toJson());
    final assignmentChanged =
        original.assignedTeamId != candidate.assignedTeamId;
    if (!maintainerChanged && !assignmentChanged) return;
    if (!governanceChangesMadeInEditMode) {
      throw const FormatException(
        'Course Maintainer and Team assignment can change only through Course Editor Edit mode.',
      );
    }
    final actorProfileId = await _profiles.getActiveProfileId();
    if (actorProfileId == null ||
        original.maintainer?.profileId != actorProfileId) {
      throw StateError(
        'Only the current Course Maintainer can change the Maintainer or Team assignment.',
      );
    }
    final newMaintainerId = candidate.maintainer?.profileId;
    if (newMaintainerId == null ||
        await _profiles.getProfileById(newMaintainerId) == null) {
      throw StateError(
        'The new Course Maintainer must be an existing local user.',
      );
    }
    final assignedTeamId = candidate.assignedTeamId;
    if (assignedTeamId != null &&
        await _teams.teamById(assignedTeamId) == null) {
      throw StateError('The selected Team is unavailable.');
    }
  }

  Future<Course> forkOfficialCourse(
    Course official, {
    CourseMaintainer? maintainer,
  }) async {
    _validateOfficialSource(official);
    if (official.derivativeWorksPolicy != DerivativeWorksPolicy.allowed) {
      throw StateError(
        official.derivativeWorksPolicy == DerivativeWorksPolicy.forbidden
            ? 'The publisher forbids derivative works.'
            : 'The publisher has not explicitly allowed derivative works.',
      );
    }
    final profile = await _profiles.getActiveProfileRecord();
    if (profile == null) {
      throw StateError(
        'Select or create an active QQL learner profile before creating a custom fork.',
      );
    }
    final when = _clock().toUtc();
    final provenance = _forkProvenance(official, profile, when);
    final targetMaintainer =
        maintainer ?? CourseMaintainer(profile.learnerProfileId);
    await _requireValidTargetMaintainer(
      targetMaintainer,
      profile.learnerProfileId,
    );
    return AuthoringDuplicationService(clock: () => when).forkOfficialCourse(
      official,
      provenance: provenance,
      maintainer: targetMaintainer,
    );
  }

  Future<CourseConfirmationResult> createCopyAsNewCourse({
    required Course source,
    required String title,
  }) async {
    final access = await _access.forCurrentProfile(source);
    if (!access.canCopyAsNewCourse || source.maintainer == null) {
      throw StateError(
        'Copy as New Course is available only to the Course Maintainer or assigned Team members.',
      );
    }
    final profile = await _requireActiveProfile();
    final when = _clock().toUtc();
    final copy = AuthoringDuplicationService(clock: () => when).copyCourseAsNew(
      source,
      title: title,
      originalCourseCreator: CourseProvenanceIdentity.qqlUser(
        profileId: profile.learnerProfileId,
        displayName: profile.displayName,
      ),
      maintainer: CourseMaintainer(profile.learnerProfileId),
    );
    return confirmCourseTransaction(
      originalCourse: copy,
      workingCourse: copy,
      languageCode: copy.targetLanguageTag,
      versionNotes: 'Created as a new independent Course.',
      isNewCourse: true,
      committedAt: when,
    );
  }

  Future<CourseConfirmationResult> createFork({
    required Course source,
    CourseMaintainer? maintainer,
  }) async {
    if (source.originType.isOfficial) {
      _validateOfficialSource(source);
    }
    final access = await _access.forCurrentProfile(source);
    if (!access.canFork) {
      throw StateError('This course does not permit a derivative Fork.');
    }
    final profile = await _requireActiveProfile();
    final when = _clock().toUtc();
    final targetMaintainer =
        maintainer ?? CourseMaintainer(profile.learnerProfileId);
    await _requireValidTargetMaintainer(
      targetMaintainer,
      profile.learnerProfileId,
    );
    final fork = source.originType.isOfficial
        ? AuthoringDuplicationService(clock: () => when).forkOfficialCourse(
            source,
            provenance: _forkProvenance(source, profile, when),
            maintainer: targetMaintainer,
          )
        : AuthoringDuplicationService(clock: () => when).forkCustomCourse(
            source,
            provenance: _forkProvenance(source, profile, when),
            maintainer: targetMaintainer,
          );
    return confirmCourseTransaction(
      originalCourse: fork,
      workingCourse: fork,
      languageCode: fork.targetLanguageTag,
      versionNotes: 'Created as a licensed Fork of ${source.courseId}.',
      isNewCourse: true,
      committedAt: when,
    );
  }

  static CourseForkProvenance _forkProvenance(
    Course source,
    LearnerProfile profile,
    DateTime when,
  ) => CourseForkProvenance(
    sourceCourseId: source.courseId,
    sourceCourseTitle: source.title,
    sourceCourseVersion: source.originType.isOfficial
        ? source.officialCourseVersion
        : source.courseVersion,
    sourceOriginType: source.originType,
    sourcePublisherId: source.publisherId,
    sourcePublisherName: source.publisherName,
    sourceOfficialChecksum: source.officialChecksum,
    sourceAuthors: source.authors,
    forkCreatedByProfileId: profile.learnerProfileId,
    forkCreatedByDisplayName: profile.displayName,
    forkCreatedAtUtc: when.toIso8601String(),
  );

  Future<LearnerProfile> _requireActiveProfile() async {
    final profile = await _profiles.getActiveProfileRecord();
    if (profile == null) {
      throw StateError('Select or create an active QQL learner profile first.');
    }
    return profile;
  }

  Future<void> _requireValidTargetMaintainer(
    CourseMaintainer maintainer,
    String profileId,
  ) async {
    if (maintainer.profileId != profileId ||
        await _profiles.getProfileById(maintainer.profileId) == null) {
      throw StateError(
        'A new Fork must be maintained by the user creating it.',
      );
    }
  }

  Future<String> exportUserCourse(Course course) async =>
      const JsonEncoder.withIndent('  ').convert(course.toJson());

  Future<CourseConfirmationResult> confirmCourseTransaction({
    required Course originalCourse,
    required Course workingCourse,
    required String languageCode,
    required String versionNotes,
    bool isNewCourse = false,
    bool governanceChangesMadeInEditMode = false,
    DateTime? committedAt,
  }) async {
    await CourseFlagService().validateWorldFlag(workingCourse);
    originalCourse = await _materializeDetachedConstructorIdentity(
      originalCourse,
    );
    workingCourse = await _materializeDetachedConstructorIdentity(
      workingCourse,
    );
    if (!isNewCourse) Course.fromJson(workingCourse.toJson());
    if (originalCourse.originType.isOfficial ||
        workingCourse.originType.isOfficial) {
      throw StateError(
        'Official course - read only. Create a licensed custom fork to edit.',
      );
    }
    _requirePreservedProvenance(originalCourse, workingCourse);
    await _requireAuthorizedGovernanceChange(
      originalCourse,
      workingCourse,
      governanceChangesMadeInEditMode: governanceChangesMadeInEditMode,
    );
    final activeProfileId = await _profiles.getActiveProfileId();
    final authorized = (await _access.forCurrentProfile(
      isNewCourse ? workingCourse : originalCourse,
    )).canEditOriginal;
    final authorizedNewCreator =
        isNewCourse &&
        workingCourse.forkProvenance == null &&
        workingCourse.originalCourseCreator.type ==
            CourseProvenanceIdentityType.qqlUser &&
        activeProfileId == workingCourse.originalCourseCreator.id;
    if (!authorized && !authorizedNewCreator) {
      throw StateError(
        'Only the Course Maintainer, a member of the assigned Team, or the Original Course Creator of an unconfirmed new Course can confirm changes.',
      );
    }
    if (workingCourse.courseId != originalCourse.courseId) {
      throw ArgumentError(
        'The working copy must retain the persisted course identity.',
      );
    }
    final profile = await _profiles.getActiveProfileRecord();
    if (profile == null) {
      throw StateError(
        'Select or create an active QQL learner profile before confirming course changes.',
      );
    }
    if (isNewCourse &&
        await _profiles.getProfileById(workingCourse.maintainer!.profileId) ==
            null) {
      throw StateError(
        'The initial Course Maintainer must be an existing local user.',
      );
    }
    if (isNewCourse &&
        workingCourse.assignedTeamId != null &&
        await _teams.teamById(workingCourse.assignedTeamId!) == null) {
      throw StateError('The assigned Team is unavailable.');
    }
    final when = (committedAt ?? _clock()).toUtc();
    final notes = versionNotes.trim();

    const storageKey = userCoursesStorageKey;
    final storageId = workingCourse.courseId;
    final all = await _loadKey(storageKey);
    final entry = all[storageId];
    final current = entry == null ? null : _courseFromEntry(entry);
    if (!isNewCourse && current == null) {
      throw StateError('The persisted custom course is unavailable.');
    }
    if (current != null && current.courseId != originalCourse.courseId) {
      throw StateError(
        'The persisted course identity changed while the Editor was open.',
      );
    }
    if (isNewCourse && current != null) {
      throw StateError(
        'A course with this identity was created while the Editor was open.',
      );
    }
    if ((_bundledOfficialCourseIds.contains(workingCourse.courseId) ||
        (await _loadKey(
          externalOfficialStorageKey,
        )).containsKey(workingCourse.courseId))) {
      throw StateError(
        'An official course already uses this identity. Create a separate custom-course copy.',
      );
    }
    if (!isNewCourse &&
        current != null &&
        jsonEncode(current.toJson()) != jsonEncode(originalCourse.toJson())) {
      throw StateError(
        'The persisted course changed while the Editor was open. Reopen the Editor before confirming to avoid overwriting newer work.',
      );
    }

    CourseBackupRecord? backup;
    if (current != null) {
      backup = await backupService.createBackup(
        current,
        backedUpAt: when,
        reason: 'Pre-change Course Editor transaction backup',
      );
    }

    final committed = _confirmedCustomCourse(
      workingCourse,
      current,
      profile,
      when,
      notes,
    );
    final next = Map<String, dynamic>.from(all);
    next[storageId] = _entry(committed, when);
    await _replaceKeyAtomically(storageKey, next);

    final verified = _courseFromEntry((await _loadKey(storageKey))[storageId]);
    if (jsonEncode(verified.toJson()) != jsonEncode(committed.toJson())) {
      throw StateError('Course persistence verification failed.');
    }
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
    return CourseConfirmationResult(
      course: verified,
      backupPath: backup?.manifestFile.path,
      hadPreviousVersion: current != null,
    );
  }

  Future<Course> _materializeDetachedConstructorIdentity(Course course) async {
    if (course.originType != CourseOriginType.custom ||
        course.originalCourseCreator.type !=
            CourseProvenanceIdentityType.qqlUser ||
        course.originalCourseCreator.id != Course.detachedInMemoryProfileId ||
        course.maintainer?.profileId != Course.detachedInMemoryProfileId) {
      return course;
    }
    final profile = await _requireActiveProfile();
    final nowUtc = _clock().toUtc().toIso8601String();
    return Course.fromJson({
      ...course.toJson(),
      'originalCourseCreator': CourseProvenanceIdentity.qqlUser(
        profileId: profile.learnerProfileId,
        displayName: profile.displayName,
      ).toJson(),
      'maintainer': CourseMaintainer(profile.learnerProfileId).toJson(),
      'originalCreatedAtUtc': nowUtc,
      'lastVersionEditorProfileId': profile.learnerProfileId,
      'lastVersionEditorDisplayName': profile.displayName,
      'modifiedAtUtc': nowUtc,
    });
  }

  static Course _confirmedCustomCourse(
    Course working,
    Course? current,
    LearnerProfile profile,
    DateTime when,
    String notes,
  ) {
    final currentVersion = _customVersionNumber(current?.courseVersion ?? '');
    final nextVersion = currentVersion + 1;
    return Course.fromJson({
      ...working.toJson(),
      'originType': CourseOriginType.custom.name,
      'originalCourseCreator': working.originalCourseCreator.toJson(),
      'maintainer': working.maintainer!.toJson(),
      'courseVersion': '$nextVersion',
      'originalCreatedAtUtc': working.originalCreatedAtUtc.isEmpty
          ? when.toIso8601String()
          : working.originalCreatedAtUtc,
      'lastVersionEditorProfileId': profile.learnerProfileId,
      'lastVersionEditorDisplayName': profile.displayName,
      'modifiedAtUtc': when.toIso8601String(),
      'versionNotes': notes,
    });
  }

  static int _customVersionNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    final integer = int.tryParse(trimmed);
    if (integer != null && integer > 0 && '$integer' == trimmed) return integer;
    throw const FormatException(
      'A custom Course version must be a positive integer string.',
    );
  }

  Future<OfficialCourseUpdateResult> installExternalOfficialUpdate(
    Course update,
  ) async {
    if (update.originType != CourseOriginType.externalOfficial) {
      throw ArgumentError('The package is not an external official course.');
    }
    _validateOfficialSource(update);
    final normalizedUpdate = Course.fromJson({
      ...update.toJson(),
      'publisherVerificationStatus':
          PublisherVerificationStatus.unverified.name,
    });
    final all = await _loadKey(externalOfficialStorageKey);
    final raw = all[normalizedUpdate.courseId];
    if (raw == null) {
      if (_bundledOfficialCourseIds.contains(normalizedUpdate.courseId) ||
          (await _loadKey(
            userCoursesStorageKey,
          )).containsKey(normalizedUpdate.courseId)) {
        throw const FormatException(
          'This Course ID is already owned by another bundled or custom course origin.',
        );
      }
      final next = Map<String, dynamic>.from(all);
      next[normalizedUpdate.courseId] = {
        'source': normalizedUpdate.toJson(),
        'savedAt': _clock().toUtc().toIso8601String(),
      };
      await _replaceKeyAtomically(externalOfficialStorageKey, next);
      LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
      return OfficialCourseUpdateResult(
        officialCourse: normalizedUpdate,
        backupPath: null,
      );
    }
    if (raw is! Map || raw['source'] is! Map) {
      throw const FormatException('The stored official course is invalid.');
    }
    final record = Map<String, dynamic>.from(raw);
    final previousSource = Course.fromJson(
      Map<String, dynamic>.from(record['source'] as Map),
    );
    _validateOfficialSource(previousSource);
    if (previousSource.courseId != normalizedUpdate.courseId ||
        previousSource.originType != CourseOriginType.externalOfficial ||
        previousSource.publisherId != normalizedUpdate.publisherId) {
      throw const FormatException(
        'A different publisher cannot replace this official course identity.',
      );
    }
    if (_compareOfficialVersions(
          normalizedUpdate.officialCourseVersion,
          previousSource.officialCourseVersion,
        ) <=
        0) {
      throw const FormatException(
        'An official update must have a newer official course version.',
      );
    }
    _requirePreservedProvenance(previousSource, normalizedUpdate);
    final active = Course.fromJson(
      Map<String, dynamic>.from(record['source'] as Map),
    );
    final backup = await backupService.createBackup(
      active,
      backedUpAt: _clock(),
      reason: 'External official update archived previous official source',
    );
    final next = Map<String, dynamic>.from(all);
    next[normalizedUpdate.courseId] = {
      ...record,
      'source': normalizedUpdate.toJson(),
      'savedAt': _clock().toUtc().toIso8601String(),
    };
    await _replaceKeyAtomically(externalOfficialStorageKey, next);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
    return OfficialCourseUpdateResult(
      officialCourse: normalizedUpdate,
      backupPath: backup.manifestFile.path,
    );
  }

  static int _compareOfficialVersions(String left, String right) {
    final l = left.split('.').map((value) => int.tryParse(value) ?? 0).toList();
    final r = right
        .split('.')
        .map((value) => int.tryParse(value) ?? 0)
        .toList();
    final length = l.length > r.length ? l.length : r.length;
    for (var index = 0; index < length; index++) {
      final lv = index < l.length ? l[index] : 0;
      final rv = index < r.length ? r[index] : 0;
      if (lv != rv) return lv.compareTo(rv);
    }
    return 0;
  }
}

typedef CourseEditorPreferenceWriter =
    Future<bool> Function(
      SharedPreferences preferences,
      String key,
      String value,
    );
