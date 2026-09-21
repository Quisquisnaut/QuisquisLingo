import 'dart:convert';

import '../models/course_models.dart';
import 'course_audit_service.dart';

/// What removing images from a Course changed.
class CourseImageRemovalResult {
  const CourseImageRemovalResult({
    required this.course,
    required this.clearedUses,
    required this.draftedContentIds,
  });

  /// The Course without the images. Nothing is stored until the Course
  /// Editor's normal Confirm.
  final Course course;

  /// How many image elements (and the cover, if it was one) were cleared.
  final int clearedUses;

  /// Content made Draft because the Audit reports it invalid without the
  /// image, so learners never meet a broken exercise.
  final Set<String> draftedContentIds;
}

/// Removes images from a Course: every use that [CourseImageUsage] would
/// report, in exercises, presentations, GuideBooks and the cover.
///
/// Only the Course changes. A Shared Image Library original or a bundled QQL
/// image stays where it is; a Course-stored file leaves the Course folder
/// through the normal cleanup after the next confirmed save.
abstract final class CourseImageRemoval {
  static CourseImageRemovalResult remove(
    Course course,
    Set<String> assets, {
    required DateTime now,
    CourseAuditService? audit,
  }) {
    final stamp = now.toUtc().toIso8601String();
    // A deep, fully modifiable copy: toJson() may share or fix list sizes.
    final json =
        jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>;
    var cleared = 0;
    final touched = <Map<String, dynamic>>[];

    int strip(Object? elements) {
      if (elements is! List) return 0;
      final before = elements.length;
      elements.removeWhere(
        (element) =>
            element is Map &&
            element['type'] == 'image' &&
            assets.contains(element['asset']),
      );
      return before - elements.length;
    }

    bool stripContent(Map<String, dynamic> content) {
      var removed = 0;
      final exercise = content['exercise'];
      if (exercise is Map) {
        removed += strip(exercise['prompt']);
        final interaction = exercise['interaction'];
        if (interaction is Map) {
          final items = interaction['items'];
          if (items is List) {
            for (final item in items) {
              if (item is Map) removed += strip(item['content']);
            }
          }
          removed += strip(interaction['layout']);
        }
        if (removed > 0) exercise['updatedAt'] = stamp;
      }
      final presentation = content['presentation'];
      if (presentation is Map) removed += strip(presentation['content']);
      cleared += removed;
      if (removed > 0) touched.add(content);
      return removed > 0;
    }

    for (final lesson
        in (json['lessons'] as List).cast<Map<String, dynamic>>()) {
      var lessonChanged = false;
      for (final round
          in (lesson['rounds'] as List).cast<Map<String, dynamic>>()) {
        var roundChanged = false;
        for (final content
            in (round['content'] as List).cast<Map<String, dynamic>>()) {
          if (stripContent(content)) roundChanged = true;
        }
        if (roundChanged) {
          round['updatedAt'] = stamp;
          lessonChanged = true;
        }
      }
      final guidebook = lesson['guidebook'];
      if (guidebook is Map && guidebook['content'] is List) {
        for (final content
            in (guidebook['content'] as List).cast<Map<String, dynamic>>()) {
          if (stripContent(content)) lessonChanged = true;
        }
      }
      if (lessonChanged) lesson['updatedAt'] = stamp;
    }
    if (assets.contains(json['coverImage'])) {
      json.remove('coverImage');
      cleared++;
    }

    // Draft whatever the Audit now rejects, using the same rule as
    // publication: any Audit error.
    final checker = audit ?? CourseAuditService();
    final drafted = <String>{};
    for (final content in touched) {
      if (content['publicationState'] == PublicationState.draft.name) continue;
      final exercise = LearningContent.fromJson(content).asRunnableExercise();
      if (exercise == null) continue;
      final invalid = checker
          .auditExercise(exercise)
          .any((issue) => issue.severity == AuditSeverity.error);
      if (invalid) {
        content['publicationState'] = PublicationState.draft.name;
        drafted.add(content['id'] as String);
      }
    }
    return CourseImageRemovalResult(
      course: Course.fromJson(json),
      clearedUses: cleared,
      draftedContentIds: drafted,
    );
  }

  /// [course] with its image library changed: [remove] leaves the library,
  /// [keep] joins it (with its Shared Image Library source, if any). An asset
  /// already listed keeps its entry.
  static Course updateLibrary(
    Course course, {
    Set<String> remove = const {},
    Map<String, SharedImageSource?> keep = const {},
    List<CourseImageLibraryEntry> add = const [],
  }) {
    final entries = <String, CourseImageLibraryEntry>{
      for (final entry in course.imageLibrary)
        if (!remove.contains(entry.asset)) entry.asset: entry,
    };
    keep.forEach(
      (asset, source) => entries.putIfAbsent(
        asset,
        () => CourseImageLibraryEntry(asset: asset, sharedImageSource: source),
      ),
    );
    for (final entry in add) {
      entries.putIfAbsent(entry.asset, () => entry);
    }
    final json = course.toJson()..remove('imageLibrary');
    if (entries.isNotEmpty) {
      json['imageLibrary'] = [
        for (final entry in entries.values) entry.toJson(),
      ];
    }
    return Course.fromJson(
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
    );
  }
}
