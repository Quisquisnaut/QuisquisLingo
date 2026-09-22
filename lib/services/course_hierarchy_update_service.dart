import 'dart:convert';

import '../models/course_models.dart';

/// A Course authoring change addressed by stable hierarchy identities.
sealed class CourseHierarchyUpdate {
  const CourseHierarchyUpdate();
}

/// Replaces the ordered Lesson collection, for add, remove and reorder flows.
final class ReplaceLessons extends CourseHierarchyUpdate {
  final List<Lesson> lessons;
  final List<CourseLessonIconAsset>? lessonIconAssets;

  const ReplaceLessons(this.lessons, {this.lessonIconAssets});
}

/// Replaces one Lesson while retaining its stable identity and siblings.
final class ReplaceLesson extends CourseHierarchyUpdate {
  final String lessonId;
  final Lesson lesson;
  final List<CourseLessonIconAsset>? lessonIconAssets;

  const ReplaceLesson(this.lessonId, this.lesson, {this.lessonIconAssets});
}

/// Replaces the ordered Round collection of one Lesson.
final class ReplaceRounds extends CourseHierarchyUpdate {
  final String lessonId;
  final List<LearningRound> rounds;

  const ReplaceRounds(this.lessonId, this.rounds);
}

/// Replaces one Round while retaining its stable identity and siblings.
final class ReplaceRound extends CourseHierarchyUpdate {
  final String lessonId;
  final String roundId;
  final LearningRound round;

  const ReplaceRound(this.lessonId, this.roundId, this.round);
}

/// Applies the Round editor's current runnable Exercise order and edits.
final class SetRoundExercises extends CourseHierarchyUpdate {
  final String lessonId;
  final String roundId;
  final List<Exercise> exercises;

  const SetRoundExercises(this.lessonId, this.roundId, this.exercises);
}

/// Inserts or updates one runnable Exercise by its Content identity.
final class UpsertExercise extends CourseHierarchyUpdate {
  final String lessonId;
  final String roundId;
  final Exercise exercise;

  const UpsertExercise(this.lessonId, this.roundId, this.exercise);
}

/// Projects one local Lesson draft into every matching Course slot for Audit
/// and editor previews, including Courses whose duplicate IDs need repair.
final class OverlayLessonDraft extends CourseHierarchyUpdate {
  final Lesson lesson;
  final List<CourseLessonIconAsset>? lessonIconAssets;

  const OverlayLessonDraft(this.lesson, {this.lessonIconAssets});
}

/// Builds the Round editor's preview Course from its local Lesson/Round draft.
///
/// This tolerant overlay mirrors the existing editor projection and is not an
/// ID-addressed authoring mutation. It can display Courses with duplicate IDs
/// while Audit reports them for repair.
final class OverlayRoundDraft extends CourseHierarchyUpdate {
  final Lesson lesson;
  final LearningRound round;

  const OverlayRoundDraft(this.lesson, this.round);
}

/// Pure hierarchy updates for an already selected Course working copy.
///
/// Publication reconciliation, Audit freshness and persistence belong to the
/// authoring session. This service changes only the requested Course subtree.
class CourseHierarchyUpdateService {
  const CourseHierarchyUpdateService();

  Course apply(Course course, CourseHierarchyUpdate update) {
    if (update is OverlayLessonDraft) {
      return _withLessons(course, [
        for (final lesson in course.lessons)
          lesson.lessonId == update.lesson.lessonId ? update.lesson : lesson,
      ], lessonIconAssets: update.lessonIconAssets);
    }
    if (update is OverlayRoundDraft) {
      final overlayLesson = Lesson.fromJson({
        ...update.lesson.toJson(),
        'rounds': [
          for (final round in update.lesson.rounds)
            (round.id == update.round.id ? update.round : round).toJson(),
        ],
      });
      return apply(course, OverlayLessonDraft(overlayLesson));
    }
    if (update is ReplaceLessons) {
      _requireDistinct(
        update.lessons.map((lesson) => lesson.lessonId),
        'Lesson',
      );
      return _withLessons(
        course,
        update.lessons,
        lessonIconAssets: update.lessonIconAssets,
      );
    }
    if (update is ReplaceLesson) {
      _requireSameId(update.lessonId, update.lesson.lessonId, 'Lesson');
      final lessons = _replaceTarget(
        course.lessons,
        update.lessonId,
        (lesson) => lesson.lessonId,
        update.lesson,
        'Lesson',
      );
      return _withLessons(
        course,
        lessons,
        lessonIconAssets: update.lessonIconAssets,
      );
    }
    if (update is ReplaceRounds) {
      _requireDistinct(update.rounds.map((round) => round.id), 'Round');
      return _updateLesson(course, update.lessonId, (lesson) {
        return _withRounds(lesson, update.rounds);
      });
    }
    if (update is ReplaceRound) {
      _requireSameId(update.roundId, update.round.id, 'Round');
      return _updateRound(course, update.lessonId, update.roundId, (_) {
        return update.round;
      });
    }
    if (update is SetRoundExercises) {
      return _updateRound(course, update.lessonId, update.roundId, (round) {
        return _withContent(
          round,
          contentForExercises(round.content, update.exercises),
        );
      });
    }
    if (update is UpsertExercise) {
      return _updateRound(course, update.lessonId, update.roundId, (round) {
        final content = [...round.content];
        var index = -1;
        for (var candidate = 0; candidate < content.length; candidate++) {
          if (content[candidate].id != update.exercise.id) continue;
          if (index >= 0) {
            throw StateError(
              'Duplicate Content target: ${update.exercise.id}.',
            );
          }
          index = candidate;
        }
        if (index < 0) {
          content.add(LearningContent.fromExercise(update.exercise));
        } else {
          final source = content[index];
          if (!_isRunnableContent(source)) {
            throw StateError(
              'Content ${source.id} is not a runnable Exercise.',
            );
          }
          content[index] = _contentForEditedExercise(source, update.exercise);
        }
        return _withContent(round, content);
      });
    }
    throw ArgumentError.value(
      update,
      'update',
      'Unsupported hierarchy update.',
    );
  }

  /// Reuses the Round editor's established order: non-runnable slots stay in
  /// place, while runnable slots receive Exercises in their current order.
  /// Duplicate IDs remain displayable; the first matching original Content
  /// supplies the wrapper, matching the existing editor's repair path.
  List<LearningContent> contentForExercises(
    List<LearningContent> originalContent,
    List<Exercise> exercises,
  ) {
    final sourceById = <String, LearningContent>{};
    for (final item in originalContent) {
      sourceById.putIfAbsent(item.id, () => item);
    }

    final pending = exercises.iterator;
    final content = <LearningContent>[];
    for (final original in originalContent) {
      if (!_isRunnableContent(original)) {
        content.add(original);
      } else if (pending.moveNext()) {
        content.add(
          _contentForEditedExercise(
            sourceById[pending.current.id],
            pending.current,
          ),
        );
      }
    }
    while (pending.moveNext()) {
      content.add(
        _contentForEditedExercise(
          sourceById[pending.current.id],
          pending.current,
        ),
      );
    }
    return content;
  }

  /// Applies one edited Exercise to its existing Content wrapper. This keeps
  /// the wrapper's authoring metadata rather than rebuilding it in a screen.
  LearningContent replaceExerciseContent(
    LearningContent source,
    Exercise exercise,
  ) {
    _requireSameId(source.id, exercise.id, 'Content');
    return _contentForEditedExercise(source, exercise);
  }

  Course _updateLesson(
    Course course,
    String lessonId,
    Lesson Function(Lesson) update,
  ) {
    final index = _targetIndex(
      course.lessons,
      lessonId,
      (lesson) => lesson.lessonId,
      'Lesson',
    );
    final lessons = [...course.lessons];
    lessons[index] = update(lessons[index]);
    return _withLessons(course, lessons);
  }

  Course _updateRound(
    Course course,
    String lessonId,
    String roundId,
    LearningRound Function(LearningRound) update,
  ) => _updateLesson(course, lessonId, (lesson) {
    final index = _targetIndex(
      lesson.rounds,
      roundId,
      (round) => round.id,
      'Round',
    );
    final rounds = [...lesson.rounds];
    rounds[index] = update(rounds[index]);
    return _withRounds(lesson, rounds);
  });
}

Course _withLessons(
  Course course,
  List<Lesson> lessons, {
  List<CourseLessonIconAsset>? lessonIconAssets,
}) => Course.fromJson({
  ...course.toJson(),
  'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
  if (lessonIconAssets != null)
    'lessonIconAssets': lessonIconAssets
        .map((asset) => asset.toJson())
        .toList(),
});

Lesson _withRounds(Lesson lesson, List<LearningRound> rounds) =>
    Lesson.fromJson({
      ...lesson.toJson(),
      'rounds': rounds.map((round) => round.toJson()).toList(),
    });

LearningRound _withContent(
  LearningRound round,
  List<LearningContent> content,
) => LearningRound.fromJson({
  ...round.toJson(),
  'content': content.map((item) => item.toJson()).toList(),
});

LearningContent _contentForEditedExercise(
  LearningContent? source,
  Exercise exercise,
) {
  if (source == null) return LearningContent.fromExercise(exercise);
  final original = source.asRunnableExercise();
  if (source.publicationState == exercise.publicationState &&
      original != null &&
      jsonEncode(original.toJson()) == jsonEncode(exercise.toJson())) {
    return source;
  }
  return _replaceLearningContentExercise(source, exercise);
}

bool _isRunnableContent(LearningContent item) =>
    item.role != 'lesson_intro' && item.asRunnableExercise() != null;

LearningContent _replaceLearningContentExercise(
  LearningContent source,
  Exercise exercise,
) {
  if (source.kind == 'exercise') {
    return LearningContent(
      id: source.id,
      publicationState: exercise.publicationState,
      kind: source.kind,
      required: source.required,
      editorTemplate: source.editorTemplate,
      role: source.role,
      exercise: exercise,
      text: source.text,
      sourceRefs: source.sourceRefs,
    );
  }
  if (source.kind == 'presentation') {
    final converted = Presentation.fromLegacyExercise(exercise);
    return LearningContent(
      id: source.id,
      publicationState: exercise.publicationState,
      kind: source.kind,
      required: source.required,
      editorTemplate: source.editorTemplate,
      role: source.role,
      presentation: Presentation(
        content: converted.content,
        actions: source.presentation?.actions ?? converted.actions,
      ),
      text: source.text,
      sourceRefs: source.sourceRefs,
    );
  }
  if (const {
    'explanation',
    'example',
    'vocabulary',
    'text',
    'dialogue',
  }.contains(source.kind)) {
    return LearningContent(
      id: source.id,
      publicationState: exercise.publicationState,
      kind: source.kind,
      required: source.required,
      editorTemplate: source.editorTemplate,
      role: source.role,
      text: exercise.prompt.isNotEmpty ? exercise.prompt : exercise.question,
      sourceRefs: source.sourceRefs,
    );
  }
  return LearningContent.fromExercise(exercise);
}

void _requireSameId(String target, String replacement, String label) {
  if (target != replacement) {
    throw ArgumentError.value(
      replacement,
      'replacement',
      '$label identity must remain $target.',
    );
  }
}

void _requireDistinct(Iterable<String> keys, String label) {
  final seen = <String>{};
  for (final key in keys) {
    if (!seen.add(key)) {
      throw ArgumentError.value(key, 'id', 'Duplicate $label identity.');
    }
  }
}

int _targetIndex<T>(
  List<T> entries,
  String id,
  String Function(T) keyOf,
  String label,
) {
  var index = -1;
  for (var candidate = 0; candidate < entries.length; candidate++) {
    if (keyOf(entries[candidate]) != id) continue;
    if (index >= 0) {
      throw StateError('Duplicate $label target: $id.');
    }
    index = candidate;
  }
  if (index < 0) throw StateError('Missing $label target: $id.');
  return index;
}

List<T> _replaceTarget<T>(
  List<T> entries,
  String id,
  String Function(T) keyOf,
  T replacement,
  String label,
) {
  final index = _targetIndex(entries, id, keyOf, label);
  final result = [...entries];
  result[index] = replacement;
  return result;
}
