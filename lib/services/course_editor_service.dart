import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_backup_service.dart';
import 'learner_status_events.dart';
import 'profile_service.dart';

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
  final bool archivedLocalChanges;

  const OfficialCourseUpdateResult({
    required this.officialCourse,
    required this.backupPath,
    required this.archivedLocalChanges,
  });
}

/// Local, offline Course Model v6 authoring storage.
///
/// Bundled assets and imported official packages remain immutable sources.
/// Confirmed local variants are stored separately. Nested editor pages never
/// call this service: only the top-level Course Editor confirms a transaction.
class CourseEditorService {
  static const bundledOverridesStorageKey =
      'quisquislingo_course_editor_overrides_v6_225';
  static const userCoursesStorageKey = 'quisquislingo_user_courses_v6_225';
  static const externalOfficialStorageKey =
      'quisquislingo_external_official_courses_v6_22504';
  static const officialUpdateNoticesStorageKey =
      'quisquislingo_official_update_notices_v6_22504';
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

  String _normalizeCode(String value) {
    final v = value.trim().toUpperCase();
    return switch (v) {
      'ITALIAN' || 'IT' => 'IT',
      'GERMAN' || 'DE' => 'DE',
      'SPANISH' || 'ES' => 'ES',
      'ENGLISH' || 'EN' => 'EN',
      'WELSH' || 'CY' => 'CY',
      'DUTCH' || 'NL' => 'NL',
      'PORTUGUESE' || 'PT' => 'PT',
      'FINNISH' || 'FI' => 'FI',
      'KOREAN' || 'KO' || 'KR' => 'KO',
      _ => v,
    };
  }

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

  /// Applies a local bundled variant without ever modifying the asset source.
  /// A pre-225.04 v6 override is adopted as a local variant of the current
  /// official source so existing authoring work is retained.
  Future<Map<String, dynamic>> applyToCourse(
    String languageCode,
    Map<String, dynamic> base,
  ) async {
    final official = Course.fromJson(base);
    final all = await _loadKey(bundledOverridesStorageKey);
    final code = _normalizeCode(languageCode);
    final rawEntry = all[code];
    if (rawEntry == null) return official.toJson();
    final stored = _courseFromEntry(rawEntry);
    if (stored.courseId != official.courseId) {
      throw const FormatException(
        'The stored bundled-course override has a different course identity.',
      );
    }

    if (!stored.originType.isOfficial) {
      return _asLocalOfficialVariant(stored, official).toJson();
    }
    final sameBase =
        stored.basePublisherId == official.publisherId &&
        stored.baseOfficialCourseVersion == official.officialCourseVersion &&
        stored.baseOfficialChecksum == official.officialChecksum;
    if (sameBase) return stored.toJson();

    final backup = await backupService.createBackup(
      stored,
      backedUpAt: _clock(),
      reason: 'Bundled official update archived active local version',
    );
    final next = Map<String, dynamic>.from(all)..remove(code);
    await _replaceKeyAtomically(bundledOverridesStorageKey, next);
    await _recordOfficialUpdateNotice(
      course: official,
      backupPath: backup.manifestFile.path,
    );
    return official.toJson();
  }

  Future<void> _recordOfficialUpdateNotice({
    required Course course,
    required String backupPath,
  }) async {
    final all = await _loadKey(officialUpdateNoticesStorageKey);
    all[course.courseId] = {
      'publisherName': course.publisherName,
      'officialCourseVersion': course.officialCourseVersion,
      'backupPath': backupPath,
      'recordedAtUtc': _clock().toUtc().toIso8601String(),
    };
    await _saveKey(officialUpdateNoticesStorageKey, all);
  }

  Future<Map<String, dynamic>?> consumeOfficialUpdateNotice(
    String courseId,
  ) async {
    final all = await _loadKey(officialUpdateNoticesStorageKey);
    final value = all.remove(courseId);
    if (value == null) return null;
    await _saveKey(officialUpdateNoticesStorageKey, all);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Course _asLocalOfficialVariant(Course edited, Course official) =>
      Course.fromJson({
        ...edited.toJson(),
        'originType': official.originType.name,
        'publisherId': official.publisherId,
        'publisherName': official.publisherName,
        'officialCourseVersion': official.officialCourseVersion,
        'officialReleaseDateUtc': official.officialReleaseDateUtc,
        'officialChecksum': official.officialChecksum,
        'officialReleaseNotes': official.officialReleaseNotes,
        'distributionChannel': official.distributionChannel,
        'publisherVerificationStatus':
            official.publisherVerificationStatus.name,
        if (official.publisherSignature.isNotEmpty)
          'publisherSignature': official.publisherSignature,
        'baseCourseId': official.courseId,
        'basePublisherId': official.publisherId,
        'baseOfficialCourseVersion': official.officialCourseVersion,
        'baseOfficialChecksum': official.officialChecksum,
      });

  /// Direct writes remain for import/project management only. Course Editor
  /// routes use [confirmCourseTransaction].
  Future<void> saveCourse({
    required String languageCode,
    required Course course,
  }) async {
    final all = await _loadKey(bundledOverridesStorageKey);
    final stored = course.originType == CourseOriginType.bundledOfficial
        ? _asLocalOfficialVariant(course, course)
        : course;
    all[_normalizeCode(languageCode)] = _entry(stored, _clock());
    await _saveKey(bundledOverridesStorageKey, all);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

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
      out.add(
        Course.fromJson(
          Map<String, dynamic>.from(
            (record['override'] ?? record['source']) as Map,
          ),
        ),
      );
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
    if (course.originType == CourseOriginType.bundledOfficial) {
      return bundledSource;
    }
    if (course.originType != CourseOriginType.externalOfficial) return null;
    final all = await _loadKey(externalOfficialStorageKey);
    final record = all[course.courseId];
    if (record is! Map || record['source'] is! Map) return null;
    return Course.fromJson(Map<String, dynamic>.from(record['source'] as Map));
  }

  Future<String> exportCourseEdits(String languageCode) async {
    final all = await _loadKey(bundledOverridesStorageKey);
    final code = _normalizeCode(languageCode);
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'QuisquisLingo Course Model v6 local override',
      'language': code,
      'override': all[code] ?? <String, dynamic>{},
    });
  }

  Future<String> exportUserCourse(Course course) async =>
      const JsonEncoder.withIndent('  ').convert(course.toJson());

  Future<void> copyCourseEdits(String languageCode) async => Clipboard.setData(
    ClipboardData(text: await exportCourseEdits(languageCode)),
  );

  Future<CourseConfirmationResult> confirmCourseTransaction({
    required Course originalCourse,
    required Course workingCourse,
    required String languageCode,
    required String versionNotes,
    bool isNewCourse = false,
    DateTime? committedAt,
  }) async {
    Course.fromJson(workingCourse.toJson());
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

    late final String storageKey;
    late final String storageId;
    late final Map<String, dynamic> all;
    Course? current;
    if (workingCourse.originType == CourseOriginType.bundledOfficial) {
      storageKey = bundledOverridesStorageKey;
      storageId = _normalizeCode(languageCode);
      all = await _loadKey(storageKey);
      final entry = all[storageId];
      current = entry == null ? originalCourse : _courseFromEntry(entry);
      if (!current.originType.isOfficial) {
        current = _asLocalOfficialVariant(current, originalCourse);
      }
    } else if (workingCourse.originType == CourseOriginType.externalOfficial) {
      storageKey = externalOfficialStorageKey;
      storageId = workingCourse.courseId;
      all = await _loadKey(storageKey);
      final raw = all[storageId];
      if (raw is! Map || raw['source'] is! Map) {
        throw StateError('The external official source is unavailable.');
      }
      final record = Map<String, dynamic>.from(raw);
      current = Course.fromJson(
        Map<String, dynamic>.from(
          (record['override'] ?? record['source']) as Map,
        ),
      );
    } else {
      storageKey = userCoursesStorageKey;
      storageId = workingCourse.courseId;
      all = await _loadKey(storageKey);
      final entry = all[storageId];
      current = entry == null ? null : _courseFromEntry(entry);
      if (!isNewCourse && current == null) {
        throw StateError('The persisted custom course is unavailable.');
      }
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
    if (isNewCourse &&
        workingCourse.originType == CourseOriginType.custom &&
        (_bundledOfficialCourseIds.contains(workingCourse.courseId) ||
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

    final committed = workingCourse.originType.isOfficial
        ? _confirmedOfficialVariant(
            workingCourse,
            current!,
            profile,
            when,
            notes,
          )
        : _confirmedCustomCourse(workingCourse, current, profile, when, notes);
    final next = Map<String, dynamic>.from(all);
    if (workingCourse.originType == CourseOriginType.externalOfficial) {
      final record = Map<String, dynamic>.from(next[storageId] as Map);
      record['override'] = committed.toJson();
      record['savedAt'] = when.toIso8601String();
      next[storageId] = record;
    } else {
      next[storageId] = _entry(committed, when);
    }
    await _replaceKeyAtomically(storageKey, next);

    final verifiedRoot = await _loadKey(storageKey);
    final verified =
        workingCourse.originType == CourseOriginType.externalOfficial
        ? Course.fromJson(
            Map<String, dynamic>.from(
              (verifiedRoot[storageId] as Map)['override'] as Map,
            ),
          )
        : _courseFromEntry(verifiedRoot[storageId]);
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

  static Course _confirmedOfficialVariant(
    Course working,
    Course current,
    LearnerProfile profile,
    DateTime when,
    String notes,
  ) => Course.fromJson({
    ...working.toJson(),
    'localCourseVersion': current.localCourseVersion + 1,
    'baseCourseId': working.courseId,
    'basePublisherId': working.publisherId,
    'baseOfficialCourseVersion': working.officialCourseVersion,
    'baseOfficialChecksum': working.officialChecksum,
    'localAuthorProfileId': profile.learnerProfileId,
    'localAuthorUsername': profile.displayName,
    'localModifiedAtUtc': when.toIso8601String(),
    'localVersionNotes': notes,
  });

  Future<OfficialCourseUpdateResult> installExternalOfficialUpdate(
    Course update,
  ) async {
    if (update.originType != CourseOriginType.externalOfficial) {
      throw ArgumentError('The package is not an external official course.');
    }
    if (CourseBackupService.officialContentChecksum(update) !=
        update.officialChecksum) {
      throw const FormatException('The official package checksum is invalid.');
    }
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
        archivedLocalChanges: false,
      );
    }
    if (raw is! Map || raw['source'] is! Map) {
      throw const FormatException('The stored official course is invalid.');
    }
    final record = Map<String, dynamic>.from(raw);
    final previousSource = Course.fromJson(
      Map<String, dynamic>.from(record['source'] as Map),
    );
    if (previousSource.publisherId != normalizedUpdate.publisherId) {
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
      Map<String, dynamic>.from(
        (record['override'] ?? record['source']) as Map,
      ),
    );
    final backup = await backupService.createBackup(
      active,
      backedUpAt: _clock(),
      reason: 'External official update archived active course state',
    );
    final next = Map<String, dynamic>.from(all);
    next[normalizedUpdate.courseId] = {
      'source': normalizedUpdate.toJson(),
      'savedAt': _clock().toUtc().toIso8601String(),
    };
    await _replaceKeyAtomically(externalOfficialStorageKey, next);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
    return OfficialCourseUpdateResult(
      officialCourse: normalizedUpdate,
      backupPath: backup.manifestFile.path,
      archivedLocalChanges: record['override'] != null,
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
