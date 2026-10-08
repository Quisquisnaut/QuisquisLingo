import '../models/course_models.dart';
import 'course_audit_service.dart';
import 'publication_service.dart';

/// Reconciles parent Drafts after an author Save.
///
/// A parent Draft is promoted to Published in two cases only:
///  * it was created automatically (`provisionalDraft`) and is now ready; or
///  * its last Draft child was just saved as Published. This needs [previous],
///    the course before the Save, so an explicit "Save as draft" on a Round or
///    Lesson whose children were already all Published is never undone.
/// Explicit/legacy Drafts and the Course's delivery choice are otherwise never
/// changed.
class ProvisionalPublicationService {
  const ProvisionalPublicationService();

  Course reconcile(
    Course source, {
    required DateTime updatedAt,
    Course? previous,
  }) {
    if (source.originType.isOfficial) return source;

    final previousRounds = <String, LearningRound>{
      for (final lesson in previous?.lessons ?? const <Lesson>[])
        for (final round in lesson.rounds) round.id: round,
    };
    final previousLessons = <String, Lesson>{
      for (final lesson in previous?.lessons ?? const <Lesson>[])
        lesson.lessonId: lesson,
    };
    bool exercisesDone(LearningRound round) =>
        round.exercises.isNotEmpty &&
        round.exercises.every(
          (exercise) => exercise.publicationState.isPublished,
        );
    bool roundsDone(Iterable<LearningRound> rounds) =>
        rounds.isNotEmpty &&
        rounds.every((round) => round.publicationState.isPublished);
    bool roundJustCompleted(LearningRound round) {
      final before = previousRounds[round.id];
      return before != null && !exercisesDone(before) && exercisesDone(round);
    }

    bool lessonJustCompleted(Lesson lesson, Iterable<LearningRound> rounds) {
      final before = previousLessons[lesson.lessonId];
      return before != null && !roundsDone(before.rounds) && roundsDone(rounds);
    }

    if (!source.lessons.any(
      (lesson) =>
          (lesson.provisionalDraft && !lesson.publicationState.isPublished) ||
          (!lesson.publicationState.isPublished &&
              lessonJustCompleted(lesson, lesson.rounds)) ||
          lesson.rounds.any(
            (round) =>
                !round.publicationState.isPublished &&
                (round.provisionalDraft || roundJustCompleted(round)),
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
        if ((round.provisionalDraft || roundJustCompleted(round)) &&
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
          (lesson.provisionalDraft || lessonJustCompleted(lesson, rounds)) &&
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
