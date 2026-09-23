import 'course_library_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'course_flag_service.dart';
import 'course_editor_storage.dart';
import 'course_file_store.dart';
import 'publisher_verification_service.dart';

import '../models/course_models.dart';
import 'course_backup_service.dart';
import 'learner_status_events.dart';
import 'profile_service.dart';
import 'authoring_duplication_service.dart';
import 'course_access_policy.dart';
import 'course_media_store.dart';
import 'course_package_service.dart';
import 'course_received_service.dart';
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

/// Local, offline Course Model v11 authoring storage.
///
/// Bundled assets and imported official packages remain immutable sources.
/// Official sources are locally read-only. Only custom courses have authoring
/// transactions; nested editors never persist them independently.
class CourseEditorService {
  static const userCoursesStorageKey = CourseEditorStorage.userCoursesKey;
  static const externalOfficialStorageKey =
      CourseEditorStorage.externalOfficialCoursesKey;
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
    'sample_nap_it_nap',
  };

  CourseEditorService({
    CourseFileStore? courseStore,
    CourseBackupService? backupService,
    ProfileService? profileService,
    TeamService? teamService,
    CourseAccessPolicy? accessPolicy,
    DateTime Function()? clock,
    CourseMediaStore? mediaStore,
    PublisherVerificationService? publisherVerification,
    CourseReceivedService? receivedCourses,
  }) : _store = courseStore ?? CourseFileStore(),
       _media = mediaStore ?? CourseMediaStore(),
       _publisherVerification =
           publisherVerification ?? PublisherVerificationService(),
       backupService =
           backupService ??
           CourseBackupService(
             publisherVerification: publisherVerification,
             mediaStore: mediaStore,
           ),
       _profiles = profileService ?? ProfileService(),
       _teams = teamService ?? TeamService(profileService: profileService),
       _access =
           accessPolicy ??
           CourseAccessPolicy(
             profileService: profileService,
             teamService: teamService,
           ),
       _clock = clock ?? DateTime.now,
       _receivedCourses =
           receivedCourses ??
           CourseReceivedService(profiles: profileService, teams: teamService);

  final CourseFileStore _store;
  final PublisherVerificationService _publisherVerification;
  final CourseMediaStore _media;
  final CourseBackupService backupService;
  final ProfileService _profiles;
  final TeamService _teams;
  final CourseAccessPolicy _access;
  final DateTime Function() _clock;
  final CourseReceivedService _receivedCourses;

  /// The device-local received-Course status used by import review.
  CourseReceivedService get receivedCourses => _receivedCourses;

  /// Stored Course files the last [listUserCourses] could not load. They are
  /// kept on disk untouched; the readable Courses are listed regardless.
  List<SkippedCourseFile> get unreadableCourseFiles =>
      List.unmodifiable(_unreadable);
  final List<SkippedCourseFile> _unreadable = [];

  Future<CourseAccessCapabilities> capabilitiesFor(Course course) =>
      _access.forCurrentProfile(course);

  /// The Course's own media folder, for the Editor and tests.
  CourseMediaStore get mediaStore => _media;

  /// Copies a new merged Course's referenced media from the left source first,
  /// then the right source, and confirms it through the ordinary Course save.
  /// A failed or uncertain save keeps media whenever a stored Course may use it.
  Future<CourseConfirmationResult> confirmMergedCourse({
    required Course left,
    required Course right,
    required Course merged,
  }) => _store.withCourseLock(merged.courseId, () async {
    if (merged.courseId == left.courseId || merged.courseId == right.courseId) {
      throw ArgumentError('A merged Course needs a fresh Course identity.');
    }
    if (await _customRecord(merged.courseId) != null ||
        _bundledOfficialCourseIds.contains(merged.courseId) ||
        await _officialRecord(merged.courseId) != null) {
      throw StateError('A course with this identity already exists.');
    }

    final references = CourseMediaStore.referencesOf(merged);
    final newlyCopied = <String>{};
    for (final reference in references) {
      if (await _media.existingFile(merged.courseId, reference) == null) {
        newlyCopied.add(reference);
      }
    }
    try {
      final missing = await _media.copyReferences(
        left.courseId,
        merged.courseId,
        references,
      );
      await _media.copyReferences(right.courseId, merged.courseId, missing);
      return await confirmCourseTransaction(
        originalCourse: merged,
        workingCourse: merged,
        languageCode: merged.targetLanguageTag,
        versionNotes: merged.versionNotes,
        isNewCourse: true,
      );
    } catch (_) {
      var absenceConfirmed = false;
      try {
        absenceConfirmed = await _customRecord(merged.courseId) == null;
      } catch (_) {
        // An unreadable record cannot prove that copied media are unowned.
      }
      if (absenceConfirmed) {
        for (final reference in newlyCopied) {
          await _media.deleteStored(merged.courseId, reference);
        }
      }
      rethrow;
    }
  });

  /// Copies the media [copy] uses from [source]'s folder into its own, runs
  /// [create], and removes the new folder again if creation fails, so a failed
  /// Fork or Copy leaves no files behind. Each Course owns its media folder;
  /// nothing is shared between Courses. An imported [package] supplies the
  /// media instead, written straight into the new Course's folder.
  Future<CourseConfirmationResult> _withCopiedMedia(
    Course source,
    Course copy,
    Future<CourseConfirmationResult> Function() create, {
    CoursePackage? package,
  }) => _store.withCourseLock(copy.courseId, () async {
    try {
      if (package != null) {
        // Recovery below decides what happens to these files on failure.
        return await package.withInstalledMedia(
          copy.courseId,
          create,
          mediaStore: _media,
          retainCreatedOnFailure: () async => true,
        );
      }
      await _media.copyReferences(
        source.courseId,
        copy.courseId,
        CourseMediaStore.referencesOf(copy),
      );
      return await create();
    } catch (_) {
      // A later library or cleanup error must not remove media after the
      // Course record has committed and begun referencing it.
      var absenceConfirmed = false;
      try {
        absenceConfirmed = await _customRecord(copy.courseId) == null;
      } catch (_) {
        // When storage is unreadable, retaining media is the recoverable path.
      }
      if (absenceConfirmed) {
        await _media.deleteCourse(copy.courseId);
      }
      rethrow;
    }
  });

  /// Reads only the requested Course identity. Mutations use the matching
  /// token so a later storage change cannot be overwritten by a stale editor.
  Future<CourseStoredRecord?> _customRecord(String courseId) =>
      _store.snapshot(CourseStoreKind.custom, courseId);

  Future<CourseStoredRecord?> _officialRecord(String courseId) =>
      _store.snapshot(CourseStoreKind.externalOfficial, courseId);

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

  Future<void> saveUserCourse(Course course) => _store.withCourseLock(
    course.courseId,
    () => _saveUserCourseLocked(course),
  );

  Future<void> _saveUserCourseLocked(Course course) async {
    if (course.originType != CourseOriginType.custom) {
      throw ArgumentError('Official courses require official-source storage.');
    }
    course = await _materializeDetachedConstructorIdentity(course);
    Course.fromJson(course.toJson());
    if (_bundledOfficialCourseIds.contains(course.courseId) ||
        await _officialRecord(course.courseId) != null) {
      throw const FormatException(
        'A custom course cannot replace an official course identity. Import it as a separate copy.',
      );
    }
    final stored = await _customRecord(course.courseId);
    final existing = stored == null ? null : _courseFromEntry(stored.entry);
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
    final entry = _entry(course, _clock());
    if (stored == null) {
      await _store.createIfAbsent(
        CourseStoreKind.custom,
        course.courseId,
        entry,
      );
    } else {
      await _store.replaceIfUnchanged(
        CourseStoreKind.custom,
        course.courseId,
        entry,
        expectedToken: stored.token,
      );
    }
    if (existing == null) await _addToImporterLibrary(course);
    await _receivedCourses.clear(course.courseId);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  /// Installs an imported custom source without granting the importer access.
  /// Replacing an existing identity still requires Maintainer/assigned-Team
  /// authorization.
  ///
  /// With [package], its media are written into the Course's own folder and
  /// the Course is saved under one hold of the Course lock. Media created by
  /// this call stay when the stored Course uses every package medium — which
  /// is what a committed import looks like — or when storage cannot be read.
  /// A rejected Replace therefore leaves the previous Course's own media in
  /// place and removes the files this attempt added.
  Future<void> installImportedCustomCourse(
    Course course, {
    CoursePackage? package,
  }) async {
    if (package == null) {
      return _store.withCourseLock(
        course.courseId,
        () => _installImportedCustomCourse(course),
      );
    }
    _requireMatchingPackage(package, course);
    return _store.withCourseLock(
      course.courseId,
      () => package.withInstalledMedia(
        course.courseId,
        () => _installImportedCustomCourse(course),
        mediaStore: _media,
        retainCreatedOnFailure: () => _persistedCustomCourseUsesAll(
          course.courseId,
          package.mediaReferences,
        ),
      ),
    );
  }

  static void _requireMatchingPackage(CoursePackage package, Course course) {
    final references = CourseMediaStore.referencesOf(course);
    if (jsonEncode(package.course.toJson()) != jsonEncode(course.toJson()) ||
        package.mediaReferences.difference(references).isNotEmpty ||
        references.difference(package.mediaReferences).isNotEmpty) {
      throw const FormatException('Course package does not match its Course.');
    }
  }

  Future<void> _installImportedCustomCourse(Course course) async {
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
        'Imported Course Model v11 custom courses require real provenance, creation time and Maintainer metadata.',
      );
    }
    if (_bundledOfficialCourseIds.contains(course.courseId) ||
        await _officialRecord(course.courseId) != null) {
      throw const FormatException(
        'A custom course cannot replace an official course identity. Import it as a separate copy.',
      );
    }
    final stored = await _customRecord(course.courseId);
    if (stored != null) {
      final current = _courseFromEntry(stored.entry);
      if (!(await _access.forCurrentProfile(current)).canEditOriginal) {
        final decision = await _receivedCourses.reviewUpdate(
          existing: current,
          incoming: course,
        );
        if (!decision.allowed) {
          throw StateError(decision.unavailableReason!);
        }
        await _installReceivedCustomUpdate(stored, current, course);
        return;
      }
      await confirmCourseTransaction(
        originalCourse: current,
        workingCourse: course,
        languageCode: course.targetLanguageTag,
        versionNotes: course.versionNotes,
      );
      return;
    }
    await _store.withCourseLock(course.courseId, () async {
      if (_bundledOfficialCourseIds.contains(course.courseId) ||
          await _officialRecord(course.courseId) != null) {
        throw const FormatException(
          'A custom course cannot replace an official course identity. Import it as a separate copy.',
        );
      }
      await _receivedCourses.recordNewImport(course);
      try {
        await _store.createIfAbsent(
          CourseStoreKind.custom,
          course.courseId,
          _entry(course, _clock()),
        );
      } catch (_) {
        // A file write may commit before reporting failure. Preserve the
        // received marker and importer membership when that exact Course is
        // readable; otherwise remove the provisional marker. An unreadable
        // record leaves the marker for recovery rather than guessing.
        try {
          final persisted = await _customRecord(course.courseId);
          if (persisted == null ||
              jsonEncode(_courseFromEntry(persisted.entry).toJson()) !=
                  jsonEncode(course.toJson())) {
            await _receivedCourses.clear(course.courseId);
          } else {
            await _addToImporterLibrary(course);
          }
        } catch (_) {}
        rethrow;
      }
      await _addToImporterLibrary(course);
      LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
    });
  }

  /// The exceptional import-only path keeps the friend's supplied version and
  /// the previous Course backup; no Course Editor working copy is created.
  Future<void> _installReceivedCustomUpdate(
    CourseStoredRecord stored,
    Course current,
    Course incoming,
  ) async {
    await CourseFlagService().validateWorldFlag(incoming);
    _requirePreservedProvenance(current, incoming);
    final when = _clock().toUtc();
    await backupService.createBackup(
      current,
      backedUpAt: when,
      reason: 'Received Custom Course update archived previous version',
    );
    await _store.replaceIfUnchanged(
      CourseStoreKind.custom,
      incoming.courseId,
      _entry(incoming, when),
      expectedToken: stored.token,
    );
    final verifiedRecord = await _customRecord(incoming.courseId);
    if (verifiedRecord == null ||
        jsonEncode(_courseFromEntry(verifiedRecord.entry).toJson()) !=
            jsonEncode(incoming.toJson())) {
      throw StateError('Course persistence verification failed.');
    }
    await _media.deleteUnreferenced(
      incoming.courseId,
      CourseMediaStore.referencesOf(incoming),
    );
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  /// Every readable stored Course. One unreadable Course never hides the
  /// others: it is skipped, left on disk and listed in [unreadableCourseFiles].
  Future<List<Course>> listUserCourses() async {
    final out = <Course>[];
    final unreadable = <SkippedCourseFile>[];
    final customSnapshot = await _store.readReadable(CourseStoreKind.custom);
    unreadable.addAll(customSnapshot.skipped);
    for (final item in customSnapshot.records.entries) {
      try {
        out.add(_courseFromEntry(item.value));
      } on FormatException catch (error) {
        unreadable.add(
          SkippedCourseFile(
            item.key,
            'Stored custom course ${item.key} has an unsupported course format or invalid data. It was preserved and was not loaded. ${error.message}',
          ),
        );
      }
    }
    final externalSnapshot = await _store.readReadable(
      CourseStoreKind.externalOfficial,
    );
    unreadable.addAll(externalSnapshot.skipped);
    for (final item in externalSnapshot.records.entries) {
      try {
        if (item.value is! Map || (item.value as Map)['source'] is! Map) {
          throw FormatException(
            'Stored external official course ${item.key} is invalid.',
          );
        }
        final record = Map<String, dynamic>.from(item.value as Map);
        final source = Course.fromJson(
          Map<String, dynamic>.from(record['source'] as Map),
        );
        if (source.courseId != item.key ||
            source.originType != CourseOriginType.externalOfficial) {
          throw const FormatException(
            'Stored official source identity is invalid.',
          );
        }
        out.add(await _publisherVerification.assessStored(source));
      } on FormatException catch (error) {
        unreadable.add(
          SkippedCourseFile(
            item.key,
            'Stored Publisher Course ${item.key} could not be loaded. It was preserved. ${error.message}',
          ),
        );
      }
    }
    _unreadable
      ..clear()
      ..addAll(unreadable);
    out.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return out;
  }

  Future<bool> persistedCourseExists({
    required Course course,
    required String languageCode,
  }) async {
    if (course.originType == CourseOriginType.bundledOfficial) return true;
    if (course.originType == CourseOriginType.externalOfficial) {
      return await _officialRecord(course.courseId) != null;
    }
    return await _customRecord(course.courseId) != null;
  }

  /// Whether the stored custom Course uses every one of [references]. A
  /// failed import that nevertheless committed leaves exactly that state, so
  /// its media must stay. A stored Course that uses only some of them is the
  /// previous version, which never used the files this attempt created.
  /// An unreadable record throws, and the caller then keeps the media.
  Future<bool> _persistedCustomCourseUsesAll(
    String courseId,
    Set<String> references,
  ) async {
    final stored = await _customRecord(courseId);
    if (stored == null) return false;
    final used = CourseMediaStore.referencesOf(_courseFromEntry(stored.entry));
    return references.every(used.contains);
  }

  /// The `media:` references the stored custom Course uses, or null when no
  /// custom Course is stored under [courseId]. An unreadable record throws,
  /// and the caller then keeps the media rather than assume they are unused.
  Future<Set<String>?> persistedCustomCourseReferences(String courseId) async {
    final stored = await _customRecord(courseId);
    if (stored == null) return null;
    return CourseMediaStore.referencesOf(_courseFromEntry(stored.entry));
  }

  Future<void> _addToImporterLibrary(Course course) async {
    if (await _profiles.getActiveProfileId() != null) {
      await CourseLibraryService(profileService: _profiles).add(course);
    }
  }

  Future<void> removePublisherCourseFromDevice(Course course) =>
      _store.withCourseLock(
        course.courseId,
        () => _removePublisherCourseFromDeviceLocked(course),
      );

  Future<void> _removePublisherCourseFromDeviceLocked(Course course) async {
    final actor = await _profiles.getActiveProfileId();
    if (actor == null || !await _profiles.isAdmin(actor)) {
      throw StateError(
        'Only an admin may remove a Publisher Course from this device.',
      );
    }
    if (course.originType != CourseOriginType.externalOfficial) {
      throw StateError('Only Publisher Courses can be uninstalled here.');
    }
    final storedRecord = await _officialRecord(course.courseId);
    if (storedRecord == null) return;
    final record = storedRecord.entry;
    if (record is! Map || record['source'] is! Map) {
      throw const FormatException('Invalid stored publisher source.');
    }
    final stored = Course.fromJson(
      Map<String, dynamic>.from(record['source'] as Map),
    );
    if (stored.courseId != course.courseId ||
        stored.originType != CourseOriginType.externalOfficial) {
      throw const FormatException('Invalid stored publisher identity.');
    }
    final library = CourseLibraryService(profileService: _profiles);
    for (final profile in await _profiles.getProfileRecords()) {
      if (profile.learnerProfileId != actor &&
          await library.contains(stored, profileId: profile.learnerProfileId)) {
        throw StateError(
          'Another profile still has this course in My courses. Nothing was removed.',
        );
      }
    }
    await _store.removeIfUnchanged(
      CourseStoreKind.externalOfficial,
      course.courseId,
      expectedToken: storedRecord.token,
    );
    // Keep membership, progress, media and backups for future reinstallation.
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<void> deleteUserCourse(String courseId) =>
      _store.withCourseLock(courseId, () => _deleteUserCourseLocked(courseId));

  Future<void> _deleteUserCourseLocked(String courseId) async {
    final stored = await _customRecord(courseId);
    if (stored == null) return;
    final course = _courseFromEntry(stored.entry);
    if (!(await _access.forCurrentProfile(course)).canDelete) {
      throw StateError(
        'Only the Course Maintainer or a member of the assigned Team can delete this Course.',
      );
    }
    await _store.removeIfUnchanged(
      CourseStoreKind.custom,
      courseId,
      expectedToken: stored.token,
    );
    await _receivedCourses.clear(courseId);
    // The folder is this Course's alone; its version backups keep their own
    // copies of the media.
    await _media.deleteCourse(course.courseId);
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
      final record = (await _officialRecord(course.courseId))?.entry;
      if (record is Map && record['source'] is Map) {
        source = Course.fromJson(
          Map<String, dynamic>.from(record['source'] as Map),
        );
      }
    }
    if (source != null) {
      if (source.originType == CourseOriginType.externalOfficial) {
        source = await _publisherVerification.assessStored(source);
      } else {
        _validateOfficialSource(source);
      }
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
        jsonEncode(original.mergeProvenance?.toJson()) !=
            jsonEncode(candidate.mergeProvenance?.toJson()) ||
        jsonEncode(original.originalCourseCreator.toJson()) !=
            jsonEncode(candidate.originalCourseCreator.toJson()) ||
        original.originalCreatedAtUtc != candidate.originalCreatedAtUtc) {
      throw const FormatException(
        'Original Course, fork and merge provenance cannot be changed or removed.',
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

  /// With [package], an imported [source]'s media come from the package
  /// straight into the new Course's folder, never into another Course's.
  Future<CourseConfirmationResult> createCopyAsNewCourse({
    required Course source,
    required String title,
    CoursePackage? package,
  }) async {
    if (package != null) _requireMatchingPackage(package, source);
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
    return _withCopiedMedia(
      source,
      copy,
      () => confirmCourseTransaction(
        originalCourse: copy,
        workingCourse: copy,
        languageCode: copy.targetLanguageTag,
        versionNotes: 'Created as a new independent Course.',
        isNewCourse: true,
        committedAt: when,
      ),
      package: package,
    );
  }

  /// With [package], as for [createCopyAsNewCourse].
  Future<CourseConfirmationResult> createFork({
    required Course source,
    CourseMaintainer? maintainer,
    CoursePackage? package,
  }) async {
    if (package != null) _requireMatchingPackage(package, source);
    if (source.originType == CourseOriginType.externalOfficial) {
      source = await _publisherVerification.requireVerified(source);
    }
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
    return _withCopiedMedia(
      source,
      fork,
      () => confirmCourseTransaction(
        originalCourse: fork,
        workingCourse: fork,
        languageCode: fork.targetLanguageTag,
        versionNotes: 'Created as a licensed Fork of ${source.courseId}.',
        isNewCourse: true,
        committedAt: when,
      ),
      package: package,
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
  }) => _store.withCourseLock(
    workingCourse.courseId,
    () => _confirmCourseTransactionLocked(
      originalCourse: originalCourse,
      workingCourse: workingCourse,
      languageCode: languageCode,
      versionNotes: versionNotes,
      isNewCourse: isNewCourse,
      governanceChangesMadeInEditMode: governanceChangesMadeInEditMode,
      committedAt: committedAt,
    ),
  );

  Future<CourseConfirmationResult> _confirmCourseTransactionLocked({
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

    final storageId = workingCourse.courseId;
    final stored = await _customRecord(storageId);
    final current = stored == null ? null : _courseFromEntry(stored.entry);
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
    if (_bundledOfficialCourseIds.contains(workingCourse.courseId) ||
        await _officialRecord(workingCourse.courseId) != null) {
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
    final committedEntry = _entry(committed, when);
    if (stored == null) {
      await _store.createIfAbsent(
        CourseStoreKind.custom,
        storageId,
        committedEntry,
      );
    } else {
      await _store.replaceIfUnchanged(
        CourseStoreKind.custom,
        storageId,
        committedEntry,
        expectedToken: stored.token,
      );
    }

    if (current == null) await _addToImporterLibrary(committed);
    final verifiedRecord = await _customRecord(storageId);
    if (verifiedRecord == null) {
      throw StateError('Course persistence verification failed.');
    }
    final verified = _courseFromEntry(verifiedRecord.entry);
    if (jsonEncode(verified.toJson()) != jsonEncode(committed.toJson())) {
      throw StateError('Course persistence verification failed.');
    }
    await _receivedCourses.clear(storageId);
    // Media added while editing and then removed, or no longer used by the
    // confirmed version, leave the Course folder. The pre-change backup above
    // holds its own copies, so older versions still restore.
    await _media.deleteUnreferenced(
      verified.courseId,
      CourseMediaStore.referencesOf(verified),
    );
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
    Course update, {
    bool confirmUnverifiedAssociation = false,
    CoursePackage? package,
  }) => _store.withCourseLock(
    update.courseId,
    () => _installExternalOfficialUpdateLocked(
      update,
      confirmUnverifiedAssociation: confirmUnverifiedAssociation,
      package: package,
    ),
  );

  Future<OfficialCourseUpdateResult> _installExternalOfficialUpdateLocked(
    Course update, {
    required bool confirmUnverifiedAssociation,
    CoursePackage? package,
  }) async {
    if (update.originType != CourseOriginType.externalOfficial) {
      throw ArgumentError('The package is not an external official course.');
    }
    final normalizedUpdate = await _publisherVerification.requireVerified(
      update,
    );
    final references = CourseMediaStore.referencesOf(update);
    if (package != null) {
      if (jsonEncode(package.course.toJson()) != jsonEncode(update.toJson()) ||
          package.mediaReferences.difference(references).isNotEmpty ||
          references.difference(package.mediaReferences).isNotEmpty) {
        throw const FormatException(
          'Publisher package does not match its Course.',
        );
      }
      return package.withInstalledMedia(
        update.courseId,
        () => _installVerifiedExternalOfficialUpdate(
          normalizedUpdate,
          confirmUnverifiedAssociation: confirmUnverifiedAssociation,
        ),
        mediaStore: _media,
        retainCreatedOnFailure: () async {
          // A failure after the Course record commits must leave its referenced
          // media available for a later retry or recovery.
          final persisted = await _officialRecord(update.courseId);
          if (persisted == null) return false;
          final entry = persisted.entry;
          if (entry is! Map || entry['source'] is! Map) return true;
          try {
            final source = Course.fromJson(
              Map<String, dynamic>.from(entry['source'] as Map),
            );
            return jsonEncode(source.toJson()) ==
                jsonEncode(normalizedUpdate.toJson());
          } catch (_) {
            return true;
          }
        },
      );
    }
    for (final reference in references) {
      final file = await _media.existingFile(update.courseId, reference);
      if (file == null ||
          sha256.convert(await file.readAsBytes()).toString() !=
              CourseMediaStore.digestOf(reference)) {
        throw FormatException(
          'Publisher Course media ${CourseMediaStore.fileNameOf(reference)} is missing or damaged. Import its ZIP package.',
        );
      }
    }
    return _installVerifiedExternalOfficialUpdate(
      normalizedUpdate,
      confirmUnverifiedAssociation: confirmUnverifiedAssociation,
    );
  }

  Future<OfficialCourseUpdateResult> _installVerifiedExternalOfficialUpdate(
    Course normalizedUpdate, {
    required bool confirmUnverifiedAssociation,
  }) async {
    final stored = await _officialRecord(normalizedUpdate.courseId);
    final raw = stored?.entry;
    if (stored == null) {
      if (_bundledOfficialCourseIds.contains(normalizedUpdate.courseId) ||
          await _customRecord(normalizedUpdate.courseId) != null) {
        throw const FormatException(
          'This Course ID is already owned by another bundled or custom course origin.',
        );
      }
      final entry = {
        'source': normalizedUpdate.toJson(),
        'savedAt': _clock().toUtc().toIso8601String(),
      };
      await _store.createIfAbsent(
        CourseStoreKind.externalOfficial,
        normalizedUpdate.courseId,
        entry,
      );
      await _addToImporterLibrary(normalizedUpdate);
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
    final assessedPrevious = await _publisherVerification.assessStored(
      previousSource,
    );
    if (assessedPrevious.publisherVerificationStatus !=
            PublisherVerificationStatus.verified &&
        !confirmUnverifiedAssociation) {
      throw const FormatException(
        'Verification required: explicitly confirm association with the existing unverified course before replacing it.',
      );
    }
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
    final entry = {
      ...record,
      'source': normalizedUpdate.toJson(),
      'savedAt': _clock().toUtc().toIso8601String(),
    };
    await _store.replaceIfUnchanged(
      CourseStoreKind.externalOfficial,
      normalizedUpdate.courseId,
      entry,
      expectedToken: stored.token,
    );
    await _addToImporterLibrary(normalizedUpdate);
    await _media.deleteUnreferenced(
      normalizedUpdate.courseId,
      CourseMediaStore.referencesOf(normalizedUpdate),
    );
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
