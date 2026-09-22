import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_hierarchy_update_service.dart';

const _updates = CourseHierarchyUpdateService();

void main() {
  test('replaces the Lesson collection without changing Course metadata', () {
    final course = _course();
    final replacement = Lesson.fromJson({
      ...course.lessons.last.toJson(),
      'title': 'Moved lesson',
    });

    final changed = _updates.apply(course, ReplaceLessons([replacement]));

    expect(changed.lessons.map((lesson) => lesson.lessonId), ['lesson-2']);
    expect(changed.lessons.single.title, 'Moved lesson');
    expect(changed.courseDescription, course.courseDescription);
    expect(changed.keywords, course.keywords);
    expect(course.lessons.length, 2);
  });

  test('replaces a Lesson by stable ID and retains its siblings', () {
    final course = _course();
    final source = course.lessons.first;
    final replacement = Lesson.fromJson({
      ...source.toJson(),
      'title': 'Renamed',
    });

    final changed = _updates.apply(
      course,
      ReplaceLesson(source.lessonId, replacement),
    );

    expect(changed.lessons.first.title, 'Renamed');
    expect(changed.lessons.first.guidebook.toJson(), source.guidebook.toJson());
    expect(changed.lessons.last.toJson(), course.lessons.last.toJson());
  });

  test('replaces a Lesson and its Course-owned icon in one update', () {
    final course = _course();
    final icon = CourseLessonIconAsset(
      assetId: 'revision_245_icon',
      base64Png: base64Encode(
        File('assets/lesson_icons/home.png').readAsBytesSync(),
      ),
    );
    final source = course.lessons.first;
    final replacement = Lesson.fromJson({
      ...source.toJson(),
      'themeIconAsset': icon.reference,
    });

    final changed = _updates.apply(
      course,
      ReplaceLesson(source.lessonId, replacement, lessonIconAssets: [icon]),
    );

    expect(changed.lessons.first.themeIconAsset, icon.reference);
    expect(changed.lessonIconAssets.single.assetId, icon.assetId);
    expect(changed.lessons.last.toJson(), course.lessons.last.toJson());
  });

  test('replaces Round collections and one Round by stable IDs', () {
    final course = _course();
    final sourceRound = course.lessons.first.rounds.single;
    final extra = LearningRound(
      id: 'round-new',
      title: 'New round',
      content: const [],
    );

    final appended = _updates.apply(
      course,
      ReplaceRounds('lesson-1', [sourceRound, extra]),
    );
    final replacement = LearningRound.fromJson({
      ...extra.toJson(),
      'title': 'Renamed round',
    });
    final changed = _updates.apply(
      appended,
      ReplaceRound('lesson-1', 'round-new', replacement),
    );

    expect(changed.lessons.first.rounds.map((round) => round.id), [
      'round-1',
      'round-new',
    ]);
    expect(changed.lessons.first.rounds.last.title, 'Renamed round');
    expect(changed.lessons.first.rounds.first.toJson(), sourceRound.toJson());
    expect(changed.lessons.last.toJson(), course.lessons.last.toJson());
  });

  test(
    'ordered Exercise edits preserve Content wrappers and metadata slots',
    () {
      final course = _course();
      final original = course.lessons.first.rounds.single.content;
      final presentation = Exercise.presentation(
        id: 'presentation-1',
        editorTemplate: 'flashcard',
        term: 'Edited term',
        meaning: '',
      );
      final changed = _updates.apply(
        course,
        SetRoundExercises('lesson-1', 'round-1', [
          presentation,
          _exercise('exercise-1', prompt: 'Edited prompt'),
        ]),
      );
      final content = changed.lessons.first.rounds.single.content;

      expect(content.map((item) => item.id), [
        'intro',
        'presentation-1',
        'metadata',
        'exercise-1',
      ]);
      expect(content.first.toJson(), original.first.toJson());
      expect(content[1].required, isFalse);
      expect(content[1].role, 'round_note');
      expect(content[1].sourceRefs, ['source-presentation']);
      expect(content[1].presentation?.actions, ['review_later']);
      expect(content[1].presentation?.content.first.text, 'Edited term');
      expect(content[2].toJson(), original[2].toJson());
      expect(content[3].required, isFalse);
      expect(content[3].role, 'practice');
      expect(content[3].sourceRefs, ['source-1']);
      expect(content[3].exercise?.prompt, 'Edited prompt');
      expect(
        course.lessons.first.rounds.single.content[1].exercise?.prompt,
        'Original prompt',
      );
    },
  );

  test('upserts Exercises without discarding a nondefault Content wrapper', () {
    final course = _course();
    final changed = _updates.apply(
      course,
      UpsertExercise(
        'lesson-1',
        'round-1',
        _exercise('exercise-1', prompt: 'Updated'),
      ),
    );
    final inserted = _updates.apply(
      changed,
      UpsertExercise('lesson-1', 'round-1', _exercise('exercise-2')),
    );
    final content = inserted.lessons.first.rounds.single.content;

    expect(content[1].exercise?.prompt, 'Updated');
    expect(content[1].required, isFalse);
    expect(content[1].sourceRefs, ['source-1']);
    expect(content.last.id, 'exercise-2');
    expect(content.last.kind, 'exercise');
    expect(content.first.id, 'intro');
  });

  test('edited textual Content retains its authoring metadata', () {
    final source = _course().lessons.first.rounds.single.content[2];

    final changed = _updates.replaceExerciseContent(
      source,
      _exercise('metadata', prompt: 'Edited note'),
    );

    expect(changed.kind, 'text');
    expect(changed.text, 'Edited note');
    expect(changed.required, isFalse);
    expect(changed.role, 'round_note');
    expect(changed.sourceRefs, ['metadata-source']);
  });

  test('ordered Exercise edits use the first duplicate Content wrapper', () {
    final original = _course();
    final lesson = original.lessons.first;
    final round = lesson.rounds.single;
    final duplicate = LearningContent(
      id: 'exercise-1',
      kind: 'exercise',
      editorTemplate: 'select',
      role: 'second-wrapper',
      exercise: _exercise('exercise-1', prompt: 'Second original'),
      sourceRefs: const ['second-source'],
    );
    final duplicateRound = LearningRound.fromJson({
      ...round.toJson(),
      'content': [
        ...round.content.take(2).map((item) => item.toJson()),
        duplicate.toJson(),
        ...round.content.skip(2).map((item) => item.toJson()),
      ],
    });
    final duplicateLesson = Lesson.fromJson({
      ...lesson.toJson(),
      'rounds': [duplicateRound.toJson()],
    });
    final course = Course.fromJson({
      ...original.toJson(),
      'lessons': [duplicateLesson.toJson(), original.lessons.last.toJson()],
    });

    final changed = _updates.apply(
      course,
      SetRoundExercises('lesson-1', 'round-1', [
        _exercise('exercise-1', prompt: 'First edited'),
        _exercise('exercise-1', prompt: 'Second edited'),
        round.content.last.asRunnableExercise()!,
      ]),
    );
    final content = changed.lessons.first.rounds.single.content;

    expect(content.map((item) => item.id), [
      'intro',
      'exercise-1',
      'exercise-1',
      'metadata',
      'presentation-1',
    ]);
    expect(content[1].exercise?.prompt, 'First edited');
    expect(content[2].exercise?.prompt, 'Second edited');
    expect(content[1].role, 'practice');
    expect(content[2].role, 'practice');
    expect(content[2].sourceRefs, ['source-1']);
    expect(content[3].toJson(), round.content[2].toJson());
    expect(
      () => _updates.apply(
        course,
        UpsertExercise('lesson-1', 'round-1', _exercise('exercise-1')),
      ),
      throwsStateError,
    );
  });

  test('preview overlays tolerate duplicate Lesson and Round identities', () {
    final base = _course();
    final lesson = base.lessons.first;
    final round = lesson.rounds.single;
    final course = Course.fromJson({
      ...base.toJson(),
      'lessons': [lesson.toJson(), lesson.toJson(), base.lessons.last.toJson()],
    });
    final editedRound = LearningRound.fromJson({
      ...round.toJson(),
      'title': 'Preview edit',
    });
    final localLesson = Lesson.fromJson({
      ...lesson.toJson(),
      'rounds': [round.toJson(), round.toJson()],
    });

    final changed = _updates.apply(
      course,
      OverlayRoundDraft(localLesson, editedRound),
    );

    expect(changed.lessons.take(2).map((item) => item.lessonId), [
      'lesson-1',
      'lesson-1',
    ]);
    for (final item in changed.lessons.take(2)) {
      expect(item.rounds.map((round) => round.title), [
        'Preview edit',
        'Preview edit',
      ]);
    }
    expect(changed.lessons.last.toJson(), base.lessons.last.toJson());
    expect(
      () => _updates.apply(course, ReplaceLesson('lesson-1', localLesson)),
      throwsStateError,
    );
  });

  test('preview Lesson overlay can carry a new Round and icon assets', () {
    final base = _course();
    final lesson = base.lessons.first;
    final generated = LearningRound(
      id: 'generated-round',
      title: 'Generated',
      content: const [],
    );
    final localLesson = Lesson.fromJson({
      ...lesson.toJson(),
      'rounds': [generated.toJson()],
    });
    final icon = CourseLessonIconAsset(
      assetId: 'preview_icon',
      base64Png: base64Encode(
        File('assets/lesson_icons/home.png').readAsBytesSync(),
      ),
    );

    final lessonPreview = _updates.apply(
      base,
      OverlayLessonDraft(localLesson, lessonIconAssets: [icon]),
    );
    final roundPreview = _updates.apply(
      base,
      OverlayRoundDraft(localLesson, generated),
    );

    expect(lessonPreview.lessons.first.rounds.single.id, 'generated-round');
    expect(lessonPreview.lessonIconAssets.single.assetId, 'preview_icon');
    expect(roundPreview.lessons.first.rounds.single.id, 'generated-round');
    expect(base.lessons.first.rounds.single.id, 'round-1');
  });

  test('missing, mismatched and duplicate hierarchy targets are rejected', () {
    final course = _course();
    final lesson = course.lessons.first;
    final round = lesson.rounds.single;
    final absentLesson = Lesson.fromJson({
      ...lesson.toJson(),
      'lessonId': 'absent',
      'duel': {'id': 'absent_duel', 'title': 'Duel'},
    });
    final absentRound = LearningRound.fromJson({
      ...round.toJson(),
      'id': 'absent',
    });

    expect(
      () => _updates.apply(course, ReplaceLesson('absent', absentLesson)),
      throwsStateError,
    );
    expect(
      () => _updates.apply(
        course,
        ReplaceLesson('lesson-1', course.lessons.last),
      ),
      throwsArgumentError,
    );
    expect(
      () => _updates.apply(course, ReplaceLessons([lesson, lesson])),
      throwsArgumentError,
    );
    expect(
      () => _updates.apply(course, ReplaceRounds('lesson-1', [round, round])),
      throwsArgumentError,
    );
    expect(
      () => _updates.apply(
        course,
        ReplaceRound('lesson-1', 'absent', absentRound),
      ),
      throwsStateError,
    );
    expect(
      () => _updates.apply(
        course,
        UpsertExercise('lesson-1', 'round-1', _exercise('intro')),
      ),
      throwsStateError,
    );
  });
}

Course _course() {
  final first = Lesson(
    lessonId: 'lesson-1',
    title: 'First',
    rounds: [
      LearningRound(
        id: 'round-1',
        title: 'Round',
        content: [
          const LearningContent(
            id: 'intro',
            kind: 'text',
            role: 'lesson_intro',
            required: false,
            text: 'Keep this introduction',
            sourceRefs: ['source-intro'],
          ),
          LearningContent(
            id: 'exercise-1',
            kind: 'exercise',
            required: false,
            editorTemplate: 'select',
            role: 'practice',
            exercise: _exercise('exercise-1', prompt: 'Original prompt'),
            sourceRefs: const ['source-1'],
          ),
          const LearningContent(
            id: 'metadata',
            kind: 'text',
            role: 'round_note',
            required: false,
            sourceRefs: ['metadata-source'],
          ),
          const LearningContent(
            id: 'presentation-1',
            kind: 'presentation',
            required: false,
            editorTemplate: 'flashcard',
            role: 'round_note',
            presentation: Presentation(
              content: [
                PromptElement(role: 'term', type: 'text', text: 'Term'),
              ],
              actions: ['review_later'],
            ),
            sourceRefs: ['source-presentation'],
          ),
        ],
      ),
    ],
    guidebook: Guidebook(
      content: const [
        LearningContent(
          id: 'guide-1',
          kind: 'text',
          role: 'goal',
          required: false,
          text: 'Goal',
          sourceRefs: ['guide-source'],
        ),
      ],
    ),
  );
  final second = Lesson(
    lessonId: 'lesson-2',
    title: 'Second',
    rounds: [LearningRound(id: 'round-2', title: 'Other', content: const [])],
  );
  return Course(
    courseId: 'hierarchy-service-fixture',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Course',
    ttsLanguage: 'it-IT',
    courseDescription: 'Unrelated metadata',
    keywords: const ['keep'],
    lessons: [first, second],
  );
}

Exercise _exercise(String id, {String prompt = 'Prompt'}) => Exercise(
  id: id,
  type: 'select',
  prompt: prompt,
  question: 'Question',
  answers: const ['yes', 'no'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
