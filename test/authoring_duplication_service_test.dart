import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';

void main() {
  test('Exercise duplication remaps owned items and evaluation references', () {
    final source = _select('exercise_source');
    final copy = AuthoringDuplicationService(
      ids: _SequenceIds(),
    ).duplicateExercise(source);

    expect(copy.id, isNot(source.id));
    expect(
      copy.interaction.items.map((item) => item.id).toSet(),
      isNot(equals(source.interaction.items.map((item) => item.id).toSet())),
    );
    expect(
      copy.evaluation.correctItemIds.single,
      copy.interaction.items.first.id,
    );
    expect(source.evaluation.correctItemIds.single, 'answer_a');
    expect(copy.toV2Json(), isNot(same(source.toV2Json())));
  });

  test(
    'Round duplication remaps internal refs but preserves external refs',
    () {
      final source = LearningRound(
        id: 'round_source',
        title: 'Round',
        content: [
          const LearningContent(
            id: 'note_source',
            kind: 'text',
            role: 'round_note',
            text: 'Note',
          ),
          LearningContent(
            id: 'content_source',
            kind: 'exercise',
            editorTemplate: 'choice',
            exercise: _select('exercise_source'),
            sourceRefs: const ['note_source', 'guide_external'],
          ),
        ],
      );
      final copy = AuthoringDuplicationService(
        ids: _SequenceIds(),
      ).duplicateRound(source);

      expect(copy.id, isNot(source.id));
      expect(
        copy.content.map((content) => content.id).toSet(),
        isNot(contains('note_source')),
      );
      expect(copy.content.last.sourceRefs.first, copy.content.first.id);
      expect(copy.content.last.sourceRefs.last, 'guide_external');
      expect(copy.content.last.exercise!.id, isNot(copy.content.last.id));
      expect(copy.content.last.exercise!.id, isNot('exercise_source'));
    },
  );

  test(
    'Lesson duplication assigns fresh recursive IDs and remaps GuideBook refs',
    () {
      final source = Lesson(
        lessonId: 'lesson_source',
        title: 'Original',
        section: true,
        sectionName: 'Section',
        themeIconAsset: 'assets/lesson_icons/home.png',
        guidebook: Guidebook(
          content: const [
            LearningContent(
              id: 'guide_source',
              kind: 'vocabulary',
              role: 'vocabulary',
              text: 'casa = house',
            ),
          ],
        ),
        rounds: [
          LearningRound(
            id: 'round_source',
            title: 'Round',
            content: [
              LearningContent(
                id: 'exercise_source',
                kind: 'exercise',
                editorTemplate: 'choice',
                exercise: _select('exercise_source'),
                sourceRefs: const ['guide_source'],
              ),
            ],
          ),
        ],
        duel: Duel(id: 'duel_source', title: 'Duel'),
      );
      final copy = AuthoringDuplicationService(
        ids: _SequenceIds(),
      ).duplicateLesson(source);

      final sourceIds = _allIds(source);
      final copyIds = _allIds(copy);
      expect(copyIds.intersection(sourceIds), isEmpty);
      expect(copyIds, hasLength(sourceIds.length));
      expect(
        copy.rounds.single.content.single.sourceRefs.single,
        copy.guidebook.content.single.id,
      );
      expect(copy.title, source.title);
      expect(copy.sectionName, source.sectionName);
      expect(copy.themeIconAsset, source.themeIconAsset);
      expect(source.rounds.single.content.single.sourceRefs, ['guide_source']);
    },
  );

  test('Course duplication remaps every owned ID and preserves metadata', () {
    final sourceLesson = Lesson(
      lessonId: 'lesson-source',
      title: 'Lesson',
      section: true,
      sectionName: 'Section',
      themeIconAsset: 'assets/lesson_icons/home.png',
      guidebook: Guidebook(
        content: const [
          LearningContent(
            id: 'guide-source',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'casa = house',
          ),
        ],
      ),
      rounds: [
        LearningRound(
          id: 'round-source',
          title: 'Round',
          content: [
            LearningContent(
              id: 'content-source',
              kind: 'exercise',
              editorTemplate: 'choice',
              exercise: _select('exercise-source'),
              sourceRefs: const ['guide-source'],
            ),
          ],
        ),
      ],
      duel: Duel(id: 'duel-source', title: 'Duel'),
    );
    final source = Course(
      courseId: 'course-source',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Original',
      ttsLanguage: 'it-IT',
      version: '1',
      courseDescription: 'Metadata',
      buyACoffeeUrl: 'https://example.com/coffee',
      flagCode: 'IT',
      audioLibrary: const [
        CourseAudioClip(id: 'audio-source', text: 'ciao', filePath: 'ciao.mp3'),
      ],
      lessons: [sourceLesson],
    );
    final copy = AuthoringDuplicationService(
      ids: _SequenceIds(),
    ).duplicateCourse(source, title: 'Original copy');

    expect(copy.courseId, isNot(source.courseId));
    expect(copy.parentCourseId, source.courseId);
    expect(copy.title, 'Original copy');
    expect(copy.courseDescription, source.courseDescription);
    expect(copy.buyACoffeeUrl, source.buyACoffeeUrl);
    expect(copy.flagCode, source.flagCode);
    expect(copy.audioLibrary.single.id, isNot(source.audioLibrary.single.id));
    expect(
      _allIds(copy.lessons.single).intersection(_allIds(sourceLesson)),
      isEmpty,
    );
    expect(
      copy.lessons.single.rounds.single.content.single.sourceRefs.single,
      copy.lessons.single.guidebook.content.single.id,
    );
  });

  test('duplication preserves source modification timestamps', () {
    final lessonTime = DateTime.utc(2026, 9, 1, 8);
    final roundTime = DateTime.utc(2026, 9, 2, 9);
    final exerciseTime = DateTime.utc(2026, 9, 3, 10);
    final source = Lesson(
      lessonId: 'lesson-source',
      updatedAt: lessonTime,
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'round-source',
          updatedAt: roundTime,
          title: 'Round',
          content: [
            LearningContent.fromExercise(
              _select('exercise-source', updatedAt: exerciseTime),
            ),
          ],
        ),
      ],
    );

    final copy = AuthoringDuplicationService(
      ids: _SequenceIds(),
    ).duplicateLesson(source);

    expect(copy.updatedAt, lessonTime);
    expect(copy.rounds.single.updatedAt, roundTime);
    expect(copy.rounds.single.exercises.single.updatedAt, exerciseTime);
  });
}

Exercise _select(String id, {DateTime? updatedAt}) => Exercise.v2(
  id: id,
  updatedAt: updatedAt,
  editorTemplate: 'choice',
  promptElements: const [PromptElement(type: 'text', text: 'Question')],
  interaction: const ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'answer_a',
        content: [PromptElement(type: 'text', text: 'A')],
      ),
      ExerciseItem(
        id: 'answer_b',
        content: [PromptElement(type: 'text', text: 'B')],
      ),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    correctItemIds: ['answer_a'],
  ),
);

Set<String> _allIds(Lesson lesson) => {
  lesson.lessonId,
  lesson.duel.id,
  for (final content in lesson.guidebook.content) content.id,
  for (final round in lesson.rounds) ...{
    round.id,
    for (final content in round.content) ...{
      content.id,
      if (content.exercise != null) ...{
        content.exercise!.id,
        for (final item in content.exercise!.interaction.items) item.id,
      },
    },
  },
};

class _SequenceIds implements AuthoringIdGenerator {
  int _next = 0;

  @override
  String next(String kind) => 'new_${kind}_${_next++}';
}
