import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/lesson_presentation_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

void main() {
  test('Course Model clean cut requires canonical publication fields', () {
    final course = _course().toJson();
    course.remove('publicationState');
    expect(() => Course.fromJson(course), throwsFormatException);

    final lessonMissing = _course().toJson();
    ((lessonMissing['lessons'] as List).first as Map).remove(
      'publicationState',
    );
    expect(() => Course.fromJson(lessonMissing), throwsFormatException);

    final roundMissing = _course().toJson();
    final lesson = (roundMissing['lessons'] as List).first as Map;
    ((lesson['rounds'] as List).first as Map).remove('publicationState');
    expect(() => Course.fromJson(roundMissing), throwsFormatException);

    final exerciseMissing = _course().toJson();
    final exerciseLesson = (exerciseMissing['lessons'] as List).first as Map;
    final round = (exerciseLesson['rounds'] as List).first as Map;
    ((round['content'] as List).first as Map).remove('publicationState');
    expect(() => Course.fromJson(exerciseMissing), throwsFormatException);
  });

  test('learner projection enforces every publication ancestor', () {
    final course = _course();
    final learner = const PublicationService().learnerCourse(course)!;

    expect(learner.lessons.map((lesson) => lesson.lessonId), ['a', 'c']);
    expect(learner.lessons.first.rounds.map((round) => round.id), ['round-a']);
    expect(
      learner.lessons.first.rounds.single.exercises.map(
        (exercise) => exercise.id,
      ),
      ['published-exercise'],
    );
    expect(
      const LessonPresentationService().identity(learner, 1).fullText,
      'Lesson 2: Conclusions',
    );
    expect(
      const PublicationService().learnerCourse(
        Course.fromJson({...course.toJson(), 'publicationState': 'draft'}),
      ),
      isNull,
    );
  });

  test('Draft Rounds and Exercises are excluded from play and Duel', () {
    final course = _course();
    final lesson = course.lessons.first;
    final round = lesson.rounds.first;

    expect(RoundPlayabilityService().playableExerciseIndices(round), [0]);
    expect(
      RoundPlayabilityService().playableExerciseIndices(
        round,
        includeDrafts: true,
      ),
      [0, 1],
    );
    expect(
      RoundPlayabilityService().playableExerciseIndices(lesson.rounds.last),
      isEmpty,
    );
    expect(
      const DuelEligibilityService()
          .evaluate(lesson)
          .candidates
          .map((candidate) => candidate.exercise.id),
      ['published-exercise'],
    );
  });

  test(
    'publication round-trip and duplication preserve IDs or make Draft copies',
    () {
      final source = _course();
      final restored = Course.fromJson(source.toJson());
      expect(restored.lessons[1].publicationState, PublicationState.draft);
      expect(restored.lessons.first.rounds.last.id, 'draft-round');

      final duplicate = AuthoringDuplicationService().duplicateCourse(
        source,
        title: 'Copy',
      );
      expect(duplicate.publicationState, PublicationState.draft);
      expect(
        duplicate.lessons.every(
          (lesson) =>
              lesson.publicationState == PublicationState.draft &&
              lesson.rounds.every(
                (round) =>
                    round.publicationState == PublicationState.draft &&
                    round.exercises.every(
                      (exercise) =>
                          exercise.publicationState == PublicationState.draft,
                    ),
              ),
        ),
        isTrue,
      );
      expect(duplicate.courseId, isNot(source.courseId));
    },
  );

  test('untrusted imported authoring becomes Draft without changing IDs', () {
    final source = _course();
    final imported = const PublicationService().asDraftAuthoringTree(source);
    expect(imported.courseId, source.courseId);
    expect(imported.publicationState, PublicationState.draft);
    expect(
      imported.lessons.every(
        (lesson) =>
            lesson.publicationState == PublicationState.draft &&
            lesson.rounds.every(
              (round) =>
                  round.publicationState == PublicationState.draft &&
                  round.exercises.every(
                    (exercise) =>
                        exercise.publicationState == PublicationState.draft,
                  ),
            ),
      ),
      isTrue,
    );
    expect(imported.lessons.first.lessonId, source.lessons.first.lessonId);
    expect(
      imported.lessons.first.rounds.first.id,
      source.lessons.first.rounds.first.id,
    );
  });

  test('Lesson numbering modes and exact default-title de-duplication', () {
    const service = LessonPresentationService();
    final lesson = Lesson(
      lessonId: 'lesson',
      title: 'Lesson 1',
      rounds: const [],
    );
    Course withMode(LessonNumberingMode mode, {String custom = ''}) => Course(
      courseId: 'course',
      lessonNumberingMode: mode,
      customLessonLabel: custom,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Course',
      ttsLanguage: 'it-IT',
      version: '1',
      lessons: [lesson],
    );

    expect(
      service.identity(withMode(LessonNumberingMode.lesson), 0).fullText,
      'Lesson 1',
    );
    expect(
      service.identity(withMode(LessonNumberingMode.unit), 0).fullText,
      'Unit 1: Lesson 1',
    );
    expect(
      service.identity(withMode(LessonNumberingMode.numberOnly), 0).fullText,
      '1: Lesson 1',
    );
    expect(
      service.identity(withMode(LessonNumberingMode.none), 0).fullText,
      'Lesson 1',
    );
    expect(
      service
          .identity(withMode(LessonNumberingMode.other, custom: 'Level'), 0)
          .fullText,
      'Level 1: Lesson 1',
    );
    expect(
      service
          .identity(
            Course.fromJson({
              ...withMode(LessonNumberingMode.lesson).toJson(),
              'lessons': [
                {...lesson.toJson(), 'title': 'My Lesson 1'},
              ],
            }),
            0,
          )
          .deduplicated,
      isFalse,
    );
  });
}

Course _course() => Course(
  courseId: 'course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'a',
      title: 'Introductions',
      rounds: [
        LearningRound(
          id: 'round-a',
          title: 'Round A',
          exercises: [
            _choice('published-exercise', PublicationState.published),
            _choice('draft-exercise', PublicationState.draft),
          ],
        ),
        LearningRound(
          id: 'draft-round',
          publicationState: PublicationState.draft,
          title: 'Draft Round',
          exercises: [
            _choice('inside-draft-round', PublicationState.published),
          ],
        ),
      ],
    ),
    Lesson(
      lessonId: 'b',
      publicationState: PublicationState.draft,
      title: 'Hidden',
      rounds: [
        LearningRound(
          id: 'hidden-round',
          title: 'Hidden',
          exercises: [_choice('hidden-exercise', PublicationState.published)],
        ),
      ],
    ),
    Lesson(lessonId: 'c', title: 'Conclusions', rounds: const []),
  ],
);

Exercise _choice(String id, PublicationState state) => Exercise(
  id: id,
  publicationState: state,
  type: 'choice',
  prompt: 'Choose',
  question: 'Question',
  answers: const ['Correct', 'Wrong'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
