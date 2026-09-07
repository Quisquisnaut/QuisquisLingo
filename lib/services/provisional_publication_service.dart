import '../models/course_models.dart';
import 'course_audit_service.dart';
import 'publication_service.dart';

/// Reconciles only automatically created parent Drafts after an author Save.
/// Explicit/legacy Drafts and the Course's delivery choice are never changed.
class ProvisionalPublicationService {
  const ProvisionalPublicationService();

  Course reconcile(Course source, {required DateTime updatedAt}) {
    if (source.originType.isOfficial ||
        !source.lessons.any(
          (lesson) =>
              (lesson.provisionalDraft &&
                  !lesson.publicationState.isPublished) ||
              lesson.rounds.any(
                (round) =>
                    round.provisionalDraft &&
                    !round.publicationState.isPublished,
              ),
        )) {
      return source;
    }

    // Match normal parent Save: audit learner-visible Content with every
    // parent exposed for validation, including provisional Rounds inside an
    // explicitly Draft Lesson. This temporary view is never adopted or saved.
    final validationRoot = Course.fromJson({
      ...source.toJson(),
      'publicationState': 'published',
      'lessons': [
        for (final lesson in source.lessons)
          {
            ...lesson.toJson(),
            'publicationState': 'published',
            'rounds': [
              for (final round in lesson.rounds)
                {...round.toJson(), 'publicationState': 'published'},
            ],
          },
      ],
    });
    final visible = const PublicationService().learnerCourse(validationRoot)!;
    // One complete canonical Audit avoids repeating it for every Round in a
    // large scaffold. Source references retain the full authored provenance.
    final issues = CourseAuditService()
        .auditCourse(visible, sourceReferenceCourse: source)
        .issues;
    final roundsWithErrors = {
      for (final issue in issues)
        if (issue.severity == AuditSeverity.error && issue.roundId != null)
          issue.roundId!,
    };
    final lessonsWithErrors = <String>{};
    final lessonsWithEmptyGuidebooks = <String>{};
    for (var index = 0; index < source.lessons.length; index++) {
      // This is the same canonical branch boundary used by auditLesson.
      final prefix = 'Lesson ${index + 1} ·';
      for (final issue in issues.where(
        (issue) => issue.location.startsWith(prefix),
      )) {
        if (issue.severity == AuditSeverity.error) {
          lessonsWithErrors.add(source.lessons[index].lessonId);
        }
        if (issue.code == 'LESSON_GUIDEBOOK_EMPTY') {
          lessonsWithEmptyGuidebooks.add(source.lessons[index].lessonId);
        }
      }
    }

    bool roundReady(LearningRound round) =>
        round.content.isNotEmpty &&
        !roundsWithErrors.contains(round.id) &&
        round.exercises.every(
          (exercise) => exercise.publicationState.isPublished,
        ) &&
        round.content.every(
          (content) =>
              (!content.required && content.exercise == null) ||
              content.publicationState.isPublished,
        );

    var changed = false;
    final stamp = updatedAt.toUtc().toIso8601String();
    final lessons = <Lesson>[];
    for (final lesson in source.lessons) {
      var roundChanged = false;
      final rounds = <LearningRound>[];
      for (final round in lesson.rounds) {
        if (round.provisionalDraft &&
            !round.publicationState.isPublished &&
            roundReady(round)) {
          rounds.add(
            LearningRound.fromJson({
              ...round.toJson(),
              'publicationState': 'published',
              'provisionalDraft': false,
              'updatedAt': stamp,
            }),
          );
          roundChanged = true;
        } else {
          rounds.add(round);
        }
      }
      final guidebookReady =
          !source.useGuidebook ||
          (lesson.guidebook.publicationState.isPublished &&
              !lessonsWithEmptyGuidebooks.contains(lesson.lessonId) &&
              lesson.guidebook.content.every(
                (content) =>
                    !content.required || content.publicationState.isPublished,
              ));
      final publishLesson =
          lesson.provisionalDraft &&
          !lesson.publicationState.isPublished &&
          rounds.isNotEmpty &&
          rounds.every(
            (round) => round.publicationState.isPublished && roundReady(round),
          ) &&
          guidebookReady &&
          !lessonsWithErrors.contains(lesson.lessonId);
      if (roundChanged || publishLesson) {
        changed = true;
        lessons.add(
          Lesson.fromJson({
            ...lesson.toJson(),
            if (roundChanged)
              'rounds': rounds.map((round) => round.toJson()).toList(),
            if (publishLesson) ...{
              'publicationState': 'published',
              'provisionalDraft': false,
              'updatedAt': stamp,
            },
          }),
        );
      } else {
        lessons.add(lesson);
      }
    }
    if (!changed) return source;
    return Course.fromJson({
      ...source.toJson(),
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    });
  }
}
