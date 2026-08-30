import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

void main() {
  final service = RoundPlayabilityService();

  test(
    'Laurel-eligible Round IDs reuse audit-valid runnable exercise rules',
    () {
      final validExercise = _choiceExercise('valid');
      final invalidExercise = _choiceExercise(
        'invalid',
        answers: const ['Only'],
      );
      final rounds = [
        LearningRound(
          id: 'evaluated',
          title: 'Evaluated',
          exercises: [validExercise],
        ),
        LearningRound(
          id: 'flashcard',
          title: 'Flashcard',
          exercises: [_flashcardExercise('card')],
        ),
        LearningRound(
          id: 'textual',
          title: 'Textual',
          content: [
            LearningContent.textual(
              id: 'explanation',
              kind: 'explanation',
              role: 'round_note',
              text: 'Read this explanation.',
            ),
          ],
        ),
        LearningRound(
          id: 'topic_intro_only',
          title: 'Topic intro only',
          content: [
            LearningContent.textual(
              id: 'intro',
              kind: 'explanation',
              role: 'topic_intro',
              text: 'Read the Guidebook first.',
            ),
          ],
        ),
        LearningRound(id: 'empty', title: 'Empty'),
        LearningRound(
          id: 'all_invalid',
          title: 'All invalid',
          exercises: [invalidExercise],
        ),
        LearningRound(
          id: 'mixed',
          title: 'Mixed',
          exercises: [invalidExercise, validExercise],
        ),
      ];
      final course = _course(rounds);

      expect(service.playableExerciseIndices(rounds.last), [1]);
      final flashcardQueue = service.playableExerciseIndices(rounds[1]);
      flashcardQueue.add(0);
      expect(flashcardQueue, [0, 0]);
      expect(service.laurelEligibleRoundIds(course), {
        'evaluated',
        'flashcard',
        'textual',
        'mixed',
      });
    },
  );
}

Course _course(List<LearningRound> rounds) => Course(
  courseId: 'course',
  learningLanguage: 'English',
  interfaceLanguage: 'Italian',
  sourceLanguage: 'Italian',
  targetLanguage: 'English',
  title: 'Course',
  ttsLanguage: 'en-US',
  version: '1',
  topics: [Topic(id: 'topic', title: 'Lesson', rounds: rounds)],
);

Exercise _choiceExercise(String id, {List<String>? answers}) => Exercise(
  id: id,
  type: 'choice',
  prompt: 'Choose the answer.',
  question: '',
  answers: answers ?? const ['Correct', 'Incorrect'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _flashcardExercise(String id) => Exercise(
  id: id,
  type: 'flashcard',
  prompt: 'Term',
  question: 'Meaning',
  answers: const ['Example'],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
