import 'package:quisquislingo_app/models/course_models.dart';

/// A one-Lesson, one-Round, one-Exercise Custom Course whose publication
/// state can be set at each level.

const _published = PublicationState.published;

Course draftStatusCourse({
  String courseId = 'user_draft_status',
  String title = 'Draft status',
  PublicationState course = _published,
  PublicationState lesson = _published,
  PublicationState round = _published,
  PublicationState exercise = _published,
  PublicationState guidebook = _published,
  bool useGuidebook = true,
}) {
  final time = DateTime.utc(2026, 9, 21, 12);
  return Course(
    courseId: courseId,
    publicationState: course,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: title,
    ttsLanguage: 'it-IT',
    useGuidebook: useGuidebook,
    lessons: [
      Lesson(
        lessonId: 'lesson',
        publicationState: lesson,
        updatedAt: time,
        title: 'Lesson',
        guidebook: Guidebook(publicationState: guidebook, content: const []),
        rounds: [
          LearningRound(
            id: 'round',
            publicationState: round,
            updatedAt: time,
            title: '',
            exercises: [
              Exercise(
                id: 'exercise',
                publicationState: exercise,
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
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
