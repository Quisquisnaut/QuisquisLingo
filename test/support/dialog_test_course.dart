import 'package:quisquislingo_app/models/course_models.dart';

Course dialogTestCourse() {
  final time = DateTime.utc(2026, 9, 19, 12);
  final exercise = Exercise(
    id: 'dialog-exercise',
    publicationState: PublicationState.draft,
    updatedAt: time,
    type: 'build_translation',
    prompt: 'How are you?',
    question: '',
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const ['Come', 'stai'],
    orderAnswer: const [],
    correctTranslations: const ['Come stai?'],
    pairs: const [],
    hint: '',
    icons: const [],
  );
  return Course(
    courseId: 'user_dialog_course',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Dialog Course',
    ttsLanguage: 'it-IT',
    lessons: [
      Lesson(
        lessonId: 'dialog-lesson',
        publicationState: PublicationState.draft,
        updatedAt: time,
        title: 'Dialog',
        rounds: [
          LearningRound(
            id: 'dialog-round',
            publicationState: PublicationState.draft,
            updatedAt: time,
            title: '',
            exercises: [exercise],
          ),
        ],
      ),
    ],
  );
}
