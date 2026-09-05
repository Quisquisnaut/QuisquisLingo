import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_backup_service.dart';
import 'learner_status_events.dart';
import 'profile_service.dart';
import 'authoring_duplication_service.dart';

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

/// Local, offline Course Model v6 authoring storage.
///
/// Bundled assets and imported official packages remain immutable sources.
/// Official sources are locally read-only. Only custom courses have authoring
/// transactions; nested editors never persist them independently.
class CourseEditorService {
  static const userCoursesStorageKey = 'quisquislingo_user_courses_v6_225';
  static const externalOfficialStorageKey =
      'quisquislingo_external_official_courses_v6_22504';
  static const _corruptBackupKey =
      'quisquislingo_course_editor_corrupt_backup_v6_225';
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
    DateTime Function()? clock,
  }) : _preferenceWriter = preferenceWriter,
       backupService = backupService ?? CourseBackupService(),
       _profiles = profileService ?? ProfileService(),
       _clock = clock ?? DateTime.now;

  final CourseEditorPreferenceWriter? _preferenceWriter;
  final CourseBackupService backupService;
  final ProfileService _profiles;
  final DateTime Function() _clock;

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
        'Stored Course Model v6 authoring data are invalid or unsupported. '
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
    if (all[course.courseId] != null) {
      _requirePreservedProvenance(
        _courseFromEntry(all[course.courseId]),
        course,
      );
    }
    all[course.courseId] = _entry(course, _clock());
    await _saveKey(userCoursesStorageKey, all);
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
        jsonEncode(candidate.forkProvenance?.toJson())) {
      throw const FormatException(
        'Original fork authorship and provenance cannot be changed or removed.',
      );
    }
  }

  Future<Course> forkOfficialCourse(Course official) async {
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
    final provenance = CourseForkProvenance(
      originalPublisherId: official.publisherId,
      originalPublisherName: official.publisherName,
      originalCourseId: official.courseId,
      originalOfficialCourseVersion: official.officialCourseVersion,
      originalOfficialChecksum: official.officialChecksum,
      originalCourseTitle: official.title,
      originalAuthor: official.author,
      originalAuthors: official.authors,
      forkCreatedByProfileId: profile.learnerProfileId,
      forkCreatedByUsername: profile.displayName,
      forkCreatedAtUtc: _clock().toUtc().toIso8601String(),
    );
    return AuthoringDuplicationService().forkOfficialCourse(
      official,
      provenance: provenance,
    );
  }

  Future<String> exportUserCourse(Course course) async =>
      const JsonEncoder.withIndent('  ').convert(course.toJson());

  Future<CourseConfirmationResult> confirmCourseTransaction({
    required Course originalCourse,
    required Course workingCourse,
    required String languageCode,
    required String versionNotes,
    bool isNewCourse = false,
    DateTime? committedAt,
  }) async {
    Course.fromJson(workingCourse.toJson());
    if (originalCourse.originType.isOfficial ||
        workingCourse.originType.isOfficial) {
      throw StateError(
        'Official course - read only. Create a licensed custom fork to edit.',
      );
    }
    _requirePreservedProvenance(originalCourse, workingCourse);
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

  static Course _confirmedCustomCourse(
    Course working,
    Course? current,
    LearnerProfile profile,
    DateTime when,
    String notes,
  ) {
    final currentVersion = _customVersionNumber(current?.courseVersion ?? '');
    final nextVersion = currentVersion + 1;
    final first = current == null;
    return Course.fromJson({
      ...working.toJson(),
      'originType': CourseOriginType.custom.name,
      'courseVersion': '$nextVersion',
      'createdByProfileId': first
          ? profile.learnerProfileId
          : current.createdByProfileId,
      'createdByUsername': first
          ? profile.displayName
          : current.createdByUsername,
      'createdAtUtc': first ? when.toIso8601String() : current.createdAtUtc,
      'lastModifiedByProfileId': profile.learnerProfileId,
      'lastModifiedByUsername': profile.displayName,
      'lastModifiedAtUtc': when.toIso8601String(),
      'versionNotes': notes,
    });
  }

  static int _customVersionNumber(String value) {
    final trimmed = value.trim();
    final integer = int.tryParse(trimmed);
    if (integer != null && integer >= 0) return integer;
    final legacyMajor = RegExp(r'^(\d+)\.').firstMatch(trimmed)?.group(1);
    return int.tryParse(legacyMajor ?? '') ?? 0;
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
