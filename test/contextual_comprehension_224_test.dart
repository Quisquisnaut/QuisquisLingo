import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  Exercise contextExercise({
    required bool text,
    required bool audio,
    bool dialogue = false,
  }) {
    return Exercise.v2(
      id: 'context_stable',
      editorTemplate: 'contextual_comprehension',
      promptElements: [
        if (text)
          const PromptElement(
            role: 'context',
            type: 'text',
            text: 'A short announcement.',
          ),
        if (audio)
          const PromptElement(
            role: 'context',
            type: 'audio',
            text: 'A short announcement.',
          ),
        if (dialogue) ...const [
          PromptElement(
            role: 'dialogue_turn',
            type: 'text',
            speaker: 'Jane',
            text: 'Are you coming?',
          ),
          PromptElement(
            role: 'dialogue_turn',
            type: 'text',
            speaker: 'Jim',
            text: 'I changed my mind.',
          ),
        ],
        const PromptElement(
          role: 'question',
          type: 'text',
          text: 'What happened?',
        ),
      ],
      interaction: const ExerciseInteraction(
        kind: 'select',
        items: [
          ExerciseItem(
            id: 'yes',
            content: [PromptElement(type: 'text', text: 'Jim is not coming.')],
          ),
          ExerciseItem(
            id: 'no',
            content: [PromptElement(type: 'text', text: 'Jim is coming.')],
          ),
        ],
      ),
      evaluation: const ExerciseEvaluation(
        kind: 'selected_items',
        correctItemIds: ['yes'],
      ),
    );
  }

  test('question, text context, audio context and modes remain distinct', () {
    expect(contextExercise(text: true, audio: false).contextMode, 'text');
    expect(contextExercise(text: false, audio: true).contextMode, 'audio');
    final both = contextExercise(text: true, audio: true);
    expect(both.contextMode, 'textAndAudio');
    expect(both.question, 'What happened?');
    expect(both.contextText, 'A short announcement.');
    expect(both.contextAudio, 'A short announcement.');
  });

  test('friendly contextual constructor assigns context roles', () {
    final exercise = Exercise(
      id: 'legacy_friendly_context',
      type: 'contextual_comprehension',
      prompt: 'A visible situation.',
      question: 'What happened?',
      answers: const ['One', 'Two'],
      correct: 0,
      tts: 'A spoken situation.',
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
      imageAsset: 'assets/exercise_images/example.webp',
    );
    expect(exercise.contextMode, 'textAndAudio');
    expect(exercise.contextText, 'A visible situation.');
    expect(exercise.contextAudio, 'A spoken situation.');
    expect(exercise.imageAsset, 'assets/exercise_images/example.webp');
  });

  test('structured dialogue and stable IDs survive v5 JSON', () {
    final original = contextExercise(text: false, audio: true, dialogue: true);
    final content = LearningContent.fromExercise(original);
    final decoded = LearningContent.fromJson(content.toJson()).exercise!;
    expect(decoded.id, 'context_stable');
    expect(decoded.dialogueTurns.map((turn) => turn.speaker), ['Jane', 'Jim']);
    expect(decoded.dialogueTurns.last.text, 'I changed my mind.');
    expect(
      CourseAuditService()
          .auditExercise(decoded)
          .where((issue) => issue.severity == AuditSeverity.error),
      isEmpty,
    );
  });

  test('context and dialogue validation rejects incomplete definitions', () {
    final missingContext = contextExercise(text: false, audio: false);
    expect(
      CourseAuditService()
          .auditExercise(missingContext)
          .map((issue) => issue.code),
      contains('CONTEXT_REQUIRED'),
    );
    final malformedTurn = Exercise.v2(
      id: 'bad_turn',
      editorTemplate: 'contextual_comprehension',
      promptElements: const [
        PromptElement(role: 'dialogue_turn', type: 'text', text: 'No speaker'),
        PromptElement(role: 'question', type: 'text', text: 'Question?'),
      ],
      interaction: contextExercise(text: true, audio: false).interaction,
      evaluation: contextExercise(text: true, audio: false).evaluation,
    );
    expect(
      CourseAuditService()
          .auditExercise(malformedTurn)
          .map((issue) => issue.code),
      contains('DIALOGUE_TURN_INVALID'),
    );
  });
}
