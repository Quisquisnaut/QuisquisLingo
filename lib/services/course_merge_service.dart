import 'dart:convert';

import '../models/course_models.dart';
import 'authoring_duplication_service.dart';
import 'custom_course_transfer_service.dart';
import 'profile_service.dart';

enum LessonMergeChoice { left, right, exclude }

enum CourseMergeSide { left, right }

class CourseMergeOptions {
  const CourseMergeOptions({
    required this.title,
    this.outputTitle,
    required this.createDuels,
    required this.useGuidebook,
    required this.lessonNumberingMode,
    required this.customLessonLabel,
    required this.sectionNames,
    required this.buyACoffeeUrl,
    required this.courseDescription,
    required this.startLevel,
    required this.targetLevel,
    required this.flagCode,
    required this.worldFlagId,
    required this.flagImageBase64,
  });

  factory CourseMergeOptions.fromCourse(Course course) => CourseMergeOptions(
    title: course.title,
    createDuels: course.createDuels,
    useGuidebook: course.useGuidebook,
    lessonNumberingMode: course.lessonNumberingMode,
    customLessonLabel: course.customLessonLabel,
    sectionNames: course.sectionNames,
    buyACoffeeUrl: course.buyACoffeeUrl,
    courseDescription: course.courseDescription,
    startLevel: course.startLevel,
    targetLevel: course.targetLevel,
    flagCode: course.flagCode,
    worldFlagId: course.worldFlagId,
    flagImageBase64: course.flagImageBase64,
  );

  final String title;
  final String? outputTitle;
  final bool createDuels;
  final bool useGuidebook;
  final LessonNumberingMode lessonNumberingMode;
  final String customLessonLabel;
  final List<String> sectionNames;
  final String buyACoffeeUrl;
  final String courseDescription;
  final String startLevel;
  final String targetLevel;
  final String flagCode;
  final String worldFlagId;
  final String flagImageBase64;
}

class CourseMergeService {
  CourseMergeService({
    CustomCourseTransferService? transfer,
    AuthoringDuplicationService? duplication,
    ProfileService? profileService,
    DateTime Function()? clock,
  }) : _transfer = transfer ?? CustomCourseTransferService(),
       _duplication = duplication ?? AuthoringDuplicationService(),
       _profiles = profileService ?? ProfileService(),
       _clock = clock ?? DateTime.now;

  final CustomCourseTransferService _transfer;
  final AuthoringDuplicationService _duplication;
  final ProfileService _profiles;
  final DateTime Function() _clock;

  Future<Course> readMergeCourse() => _transfer.mergeCourse();

  void validateCompatibility(Course left, Course right) {
    if (left.originType != CourseOriginType.custom ||
        right.originType != CourseOriginType.custom) {
      throw const FormatException('Only custom Courses can be merged.');
    }
    if (left.courseId == right.courseId &&
        left.courseVersion == right.courseVersion &&
        left.modifiedAtUtc == right.modifiedAtUtc) {
      throw const FormatException('A Course cannot be merged with itself.');
    }
    final leftInfo = _courseInfo(left);
    final rightInfo = _courseInfo(right);
    for (final field in leftInfo.keys) {
      if (jsonEncode(leftInfo[field]) != jsonEncode(rightInfo[field])) {
        throw FormatException(
          'Course merge blocked: Course info does not match for "$field".',
        );
      }
    }
  }

  Future<Course> createMergedCourse({
    required Course left,
    required Course right,
    required List<LessonMergeChoice> choices,
    required CourseMergeOptions options,
  }) async {
    validateCompatibility(left, right);
    final count = [
      left.lessons.length,
      right.lessons.length,
    ].reduce((a, b) => a > b ? a : b);
    if (choices.length != count) {
      throw ArgumentError('Choose a source for every Lesson position.');
    }
    final selected = <Lesson>[];
    for (var index = 0; index < count; index++) {
      final choice = choices[index];
      final availableLeft = index < left.lessons.length;
      final availableRight = index < right.lessons.length;
      if ((choice == LessonMergeChoice.left && !availableLeft) ||
          (choice == LessonMergeChoice.right && !availableRight)) {
        throw ArgumentError('Choose one available source for every Lesson.');
      }
      if (choice == LessonMergeChoice.exclude) continue;
      selected.add(
        _duplication.duplicateLesson(
          choice == LessonMergeChoice.left
              ? left.lessons[index]
              : right.lessons[index],
          preservePublicationState: true,
        ),
      );
    }
    if (selected.isEmpty) {
      throw ArgumentError('Select at least one Lesson to merge.');
    }
    final profile = await _profiles.getActiveProfileRecord();
    if (profile == null) {
      throw StateError('Select or create a learner profile before merging.');
    }
    final when = _clock().toUtc();
    final output = Map<String, dynamic>.from(left.toJson())
      ..['formatVersion'] = Course.mergedFormatVersion
      ..['courseId'] = Course.newCourseId()
      ..['title'] = options.outputTitle ?? '${options.title} merged'
      ..['originalCreatedAtUtc'] = _earliest(
        left.originalCreatedAtUtc,
        right.originalCreatedAtUtc,
      )
      ..['modifiedAtUtc'] = when.toIso8601String()
      ..['lastVersionEditorProfileId'] = profile.learnerProfileId
      ..['lastVersionEditorDisplayName'] = profile.displayName
      ..['courseVersion'] = '1'
      ..['versionNotes'] =
          'Created by merging ${left.courseId} and ${right.courseId}.'
      ..remove('restoredFromVersion')
      ..['publicationState'] =
          (left.publicationState.isPublished &&
              right.publicationState.isPublished)
          ? PublicationState.published.name
          : PublicationState.draft.name
      ..['createDuels'] = options.createDuels
      ..['useGuidebook'] = options.useGuidebook
      ..['lessonNumberingMode'] = options.lessonNumberingMode.name
      ..['customLessonLabel'] = options.customLessonLabel
      ..['sectionNames'] = options.sectionNames
      ..['buyACoffeeUrl'] = options.buyACoffeeUrl
      ..['courseDescription'] = options.courseDescription
      ..['startLevel'] = options.startLevel
      ..['targetLevel'] = options.targetLevel
      ..['flagCode'] = options.flagCode
      ..['worldFlagId'] = options.worldFlagId
      ..['flagImageBase64'] = options.flagImageBase64
      ..['mergeProvenance'] = CourseMergeProvenance(
        leftSourceCourseId: left.courseId,
        leftSourceCourseVersion: left.courseVersion,
        leftSourceModifiedAtUtc: left.modifiedAtUtc,
        rightSourceCourseId: right.courseId,
        rightSourceCourseVersion: right.courseVersion,
        rightSourceModifiedAtUtc: right.modifiedAtUtc,
        mergedAtUtc: when.toIso8601String(),
      ).toJson()
      ..['lessons'] = selected.map((lesson) => lesson.toJson()).toList();
    return Course.fromJson(output);
  }

  static Map<String, dynamic> _courseInfo(Course course) {
    final info = Map<String, dynamic>.from(course.toJson());
    for (final key in const [
      'formatVersion',
      'publicationState',
      'createDuels',
      'useGuidebook',
      'lessonNumberingMode',
      'customLessonLabel',
      'sectionNames',
      'title',
      'buyACoffeeUrl',
      'courseDescription',
      'startLevel',
      'targetLevel',
      'flagCode',
      'worldFlagId',
      'flagImageBase64',
      'courseId',
      'originalCreatedAtUtc',
      'modifiedAtUtc',
      'courseVersion',
      'versionNotes',
      'restoredFromVersion',
      'lastVersionEditorProfileId',
      'lastVersionEditorDisplayName',
      'mergeProvenance',
      'lessons',
    ]) {
      info.remove(key);
    }
    return info;
  }

  static String _earliest(String left, String right) =>
      DateTime.parse(left).isAfter(DateTime.parse(right)) ? right : left;

  static String nextAvailableTitle(
    String preferredTitle,
    Iterable<String> existingTitles,
  ) {
    final existing = existingTitles.toSet();
    if (!existing.contains(preferredTitle)) return preferredTitle;
    var suffix = 2;
    while (existing.contains('$preferredTitle $suffix')) {
      suffix++;
    }
    return '$preferredTitle $suffix';
  }
}
