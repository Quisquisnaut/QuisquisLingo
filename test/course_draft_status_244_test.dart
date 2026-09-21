import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_draft_status.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';

const _published = PublicationState.published;
const _draft = PublicationState.draft;

Course draftStatusCourse({
  PublicationState lesson = _published,
  PublicationState round = _published,
  PublicationState exercise = _published,
  PublicationState guidebook = _published,
  bool useGuidebook = true,
}) {
  final time = DateTime.utc(2026, 9, 21, 12);
  return Course(
    courseId: 'user_draft_status',
    publicationState: _published,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Draft status',
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

void main() {
  test('a fully published hierarchy has no Draft', () {
    expect(CourseDraftStatus.courseHasDraft(draftStatusCourse()), isFalse);
  });

  test('Draft at any level marks the Course', () {
    for (final course in [
      draftStatusCourse(lesson: _draft),
      draftStatusCourse(round: _draft),
      draftStatusCourse(exercise: _draft),
      draftStatusCourse(guidebook: _draft),
    ]) {
      expect(CourseDraftStatus.courseHasDraft(course), isTrue);
    }
  });

  test('a Draft GuideBook does not count while GuideBook is off', () {
    final course = draftStatusCourse(guidebook: _draft, useGuidebook: false);
    expect(CourseDraftStatus.courseHasDraft(course), isFalse);
  });

  test('the Editor hierarchy status delegates to the same rule', () {
    for (final course in [
      draftStatusCourse(),
      draftStatusCourse(exercise: _draft),
      draftStatusCourse(guidebook: _draft, useGuidebook: false),
    ]) {
      expect(
        AuthoringHierarchyStatus.fromCourse(course).courseHasDraft,
        CourseDraftStatus.courseHasDraft(course),
      );
    }
  });
}
