import '../models/course_models.dart';

/// Produces the one learner-visible view of an authored Course.
///
/// Authoring keeps every Draft. Learner flows receive only Published entities,
/// with ancestor visibility enforced from Course down to Content.
class PublicationService {
  const PublicationService();

  Course? learnerCourse(Course source) {
    if (!source.publicationState.isPublished) return null;
    final courseJson = source.toJson();
    courseJson['lessons'] = [
      for (final lesson in source.lessons)
        if (lesson.publicationState.isPublished) _publishedLessonJson(lesson),
    ];
    return Course.fromJson(courseJson);
  }

  /// Imports enter ordinary untrusted authoring as Draft without changing IDs.
  Course asDraftAuthoringTree(Course source) {
    final json = source.toJson();
    json['publicationState'] = PublicationState.draft.name;
    for (final rawLesson in (json['lessons'] as List).whereType<Map>()) {
      final lesson = rawLesson;
      lesson['publicationState'] = PublicationState.draft.name;
      final guidebook = lesson['guidebook'];
      if (guidebook is Map) {
        for (final rawContent
            in (guidebook['content'] as List? ?? const []).whereType<Map>()) {
          rawContent['publicationState'] = PublicationState.draft.name;
        }
      }
      for (final rawRound
          in (lesson['rounds'] as List? ?? const []).whereType<Map>()) {
        rawRound['publicationState'] = PublicationState.draft.name;
        for (final rawContent
            in (rawRound['content'] as List? ?? const []).whereType<Map>()) {
          rawContent['publicationState'] = PublicationState.draft.name;
        }
      }
    }
    return Course.fromJson(json);
  }

  Map<String, dynamic> _publishedLessonJson(Lesson lesson) {
    final lessonJson = lesson.toJson();
    lessonJson['guidebook'] = {
      'content': [
        for (final content in lesson.guidebook.content)
          if (content.publicationState.isPublished) content.toJson(),
      ],
    };
    lessonJson['rounds'] = [
      for (final round in lesson.rounds)
        if (round.publicationState.isPublished) _publishedRoundJson(round),
    ];
    return lessonJson;
  }

  Map<String, dynamic> _publishedRoundJson(LearningRound round) {
    final roundJson = round.toJson();
    roundJson['content'] = [
      for (final content in round.content)
        if (content.publicationState.isPublished) content.toJson(),
    ];
    return roundJson;
  }
}
