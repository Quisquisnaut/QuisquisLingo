import '../models/course_models.dart';
import 'authoring_duplication_service.dart';

/// One-time creation choices, never Course metadata or import/editing limits.
class NewCourseStructure {
  static const defaultLessons = 3;
  static const defaultRoundsPerLesson = 1;

  static String? validateCount(String text, {required int maximum}) {
    final value = text.trim();
    if (value.isEmpty) return 'Enter a number.';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Enter a whole number from 1 to $maximum.';
    }
    final count = int.tryParse(value);
    if (count == null || count < 1 || count > maximum) {
      return 'Enter a whole number from 1 to $maximum.';
    }
    return null;
  }

  /// Builds the entire hierarchy before the caller can adopt or persist it.
  static List<Lesson> create({
    required int lessonCount,
    required int roundsPerLesson,
    required String sourceLanguage,
    required String learningLanguage,
    required DateTime updatedAt,
    AuthoringIdGenerator? ids,
  }) {
    if (lessonCount < 1 || lessonCount > 100) {
      throw RangeError.range(lessonCount, 1, 100, 'Number of Lessons');
    }
    if (roundsPerLesson < 1 || roundsPerLesson > 20) {
      throw RangeError.range(roundsPerLesson, 1, 20, 'Rounds per Lesson');
    }
    final source = sourceLanguage.trim();
    final learning = learningLanguage.trim();
    if (source.isEmpty || learning.isEmpty) {
      throw ArgumentError('Source and learning languages are required.');
    }
    final generator = ids ?? TimestampAuthoringIdGenerator();
    return [
      for (var index = 0; index < lessonCount; index++)
        Lesson(
          lessonId: generator.next('lesson'),
          publicationState: PublicationState.draft,
          provisionalDraft: true,
          updatedAt: updatedAt,
          title: 'Lesson ${index + 1}',
          guidebook: Guidebook.empty(),
          rounds: [
            for (var round = 0; round < roundsPerLesson; round++)
              LearningRound(
                id: generator.next('round'),
                updatedAt: updatedAt,
                title: '',
                content: [
                  sampleExercise(
                    generator,
                    sourceLanguage: source,
                    learningLanguage: learning,
                    updatedAt: updatedAt,
                  ),
                ],
              ),
          ],
        ),
    ];
  }

  /// Creates the shared Draft authoring example used by new Courses and by
  /// manually created Rounds.
  static LearningContent sampleExercise(
    AuthoringIdGenerator ids, {
    required String sourceLanguage,
    required String learningLanguage,
    required DateTime updatedAt,
  }) {
    final exerciseId = ids.next('exercise');
    final correctId = ids.next('item');
    final distractorId = ids.next('item');
    // These are editable, language-labelled authoring placeholders, not
    // translated teaching material. Never silently publish generated examples.
    return LearningContent.fromExercise(
      Exercise.v2(
        id: exerciseId,
        publicationState: PublicationState.draft,
        updatedAt: updatedAt,
        editorTemplate: 'choice',
        promptElements: [
          PromptElement(
            type: 'text',
            text:
                'Write a $sourceLanguage instruction to translate into $learningLanguage.',
          ),
          PromptElement(
            role: 'question',
            type: 'text',
            text: 'Text in $sourceLanguage',
          ),
        ],
        interaction: ExerciseInteraction(
          kind: 'select',
          items: [
            ExerciseItem(
              id: correctId,
              content: [
                PromptElement(
                  type: 'text',
                  text: 'Translation in $learningLanguage',
                ),
              ],
            ),
            ExerciseItem(
              id: distractorId,
              content: const [
                PromptElement(type: 'text', text: 'Wrong Answer'),
              ],
            ),
          ],
        ),
        evaluation: ExerciseEvaluation(
          kind: 'selected_items',
          correctItemIds: [correctId],
        ),
      ),
    );
  }
}
