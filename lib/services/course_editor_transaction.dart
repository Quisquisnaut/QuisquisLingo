import 'dart:collection';
import 'dart:convert';

import '../models/course_models.dart';

/// One in-memory Course Editor session.
///
/// Nested editors replace parts of [workingCourse]. The immutable original is
/// retained until the user either confirms or cancels the whole course edit.
class CourseEditorTransaction {
  CourseEditorTransaction(Course persistedCourse, {bool isNewCourse = false})
    : _originalCourse = _copy(persistedCourse),
      _workingCourse = _copy(persistedCourse),
      _newCourseUnconfirmed = isNewCourse;

  Course _originalCourse;
  Course _workingCourse;
  bool _newCourseUnconfirmed;

  Course get originalCourse => _copy(_originalCourse);
  Course get workingCourse => _workingCourse;

  bool get hasChanges =>
      _newCourseUnconfirmed ||
      _semanticJson(_workingCourse) != _semanticJson(_originalCourse);

  void replaceWorkingCourse(Course course) {
    if (course.courseId != _originalCourse.courseId) {
      throw ArgumentError.value(
        course.courseId,
        'course.courseId',
        'A Course Editor transaction cannot change course identity.',
      );
    }
    _workingCourse = _copy(course);
  }

  void cancel() {
    _workingCourse = _copy(_originalCourse);
    _newCourseUnconfirmed = false;
  }

  /// Loads historical content for inspection while retaining the active
  /// version/provenance counters used by the eventual monotonic confirmation.
  void loadHistoricalCourse(Course historical) {
    if (historical.courseId != _originalCourse.courseId) {
      throw const FormatException('The backup belongs to a different course.');
    }
    if (_originalCourse.originType.isOfficial &&
        (historical.publisherId != _originalCourse.publisherId ||
            historical.officialCourseVersion !=
                _originalCourse.officialCourseVersion ||
            historical.officialChecksum != _originalCourse.officialChecksum)) {
      throw const FormatException(
        'This historical local version uses a different official base. Open it as a separate custom-course copy instead.',
      );
    }
    final restoredVersion = historical.originType.isOfficial
        ? (historical.localCourseVersion > 0
              ? historical.localCourseVersion
              : null)
        : int.tryParse(historical.courseVersion);
    final json = Map<String, dynamic>.from(historical.toJson());
    final active = _originalCourse.toJson();
    for (final key in const [
      'originType',
      'publisherId',
      'publisherName',
      'officialCourseVersion',
      'officialReleaseDateUtc',
      'officialChecksum',
      'officialReleaseNotes',
      'distributionChannel',
      'publisherVerificationStatus',
      'publisherSignature',
      'baseCourseId',
      'basePublisherId',
      'baseOfficialCourseVersion',
      'baseOfficialChecksum',
      'localCourseVersion',
      'localAuthorProfileId',
      'localAuthorUsername',
      'localModifiedAtUtc',
      'localVersionNotes',
      'courseVersion',
      'createdByProfileId',
      'createdByUsername',
      'createdAtUtc',
      'lastModifiedByProfileId',
      'lastModifiedByUsername',
      'lastModifiedAtUtc',
      'versionNotes',
    ]) {
      if (active.containsKey(key)) {
        json[key] = active[key];
      } else {
        json.remove(key);
      }
    }
    if (restoredVersion == null) {
      json.remove('restoredFromVersion');
    } else {
      json['restoredFromVersion'] = restoredVersion;
    }
    _workingCourse = Course.fromJson(json);
  }

  void markConfirmed(Course course) {
    _originalCourse = _copy(course);
    _workingCourse = _copy(course);
    _newCourseUnconfirmed = false;
  }

  static Course _copy(Course course) => Course.fromJson(
    Map<String, dynamic>.from(jsonDecode(jsonEncode(course.toJson())) as Map),
  );

  static String _semanticJson(Course course) =>
      jsonEncode(_semanticValue(course.toJson()));

  static Object? _semanticValue(Object? value) {
    if (value is Map) {
      final normalized = SplayTreeMap<String, Object?>();
      for (final entry in value.entries) {
        final key = entry.key.toString();
        // Modification timestamps describe the last edit event, not the
        // semantic authoring value. Ignoring them lets a user restore the
        // original content without leaving a false dirty transaction.
        if (key == 'updatedAt') continue;
        normalized[key] = _semanticValue(entry.value);
      }
      return normalized;
    }
    if (value is List) {
      return value.map(_semanticValue).toList(growable: false);
    }
    return value;
  }
}
