import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';

LearningContent _storedFlashcard({bool includeTranslation = true}) =>
    LearningContent.fromJson({
      'id': 'stable-flashcard',
      'publicationState': 'published',
      'kind': 'presentation',
      'required': true,
      'editorTemplate': 'flashcard',
      'presentation': {
        'content': [
          {'role': 'term', 'type': 'text', 'text': 'lìber'},
          {'role': 'audio', 'type': 'audio', 'text': 'lìber'},
          {'role': 'meaning', 'type': 'text', 'text': 'book'},
          {'role': 'usage', 'type': 'text', 'text': "I l'hai un lìber."},
          if (includeTranslation)
            {
              'role': 'usage_translation',
              'type': 'text',
              'text': 'I have a book.',
            },
        ],
        'completion': {
          'actions': ['understood', 'review_later'],
        },
      },
    });

void main() {
  for (final includeTranslation in [true, false]) {
    test('stored Flashcard usage survives the runnable view and save '
        '(translation: $includeTranslation)', () {
      final content = _storedFlashcard(includeTranslation: includeTranslation);
      final exercise = content.asRunnableExercise()!;
      expect(exercise.answers, [
        "I l'hai un lìber.",
        if (includeTranslation) 'I have a book.',
      ]);
      expect(exercise.id, content.id);
      expect(exercise.type, 'flashcard');
      expect(exercise.correct, isNull);
      expect(exercise.evaluation.correctItemIds, isEmpty);
      expect(exercise.publicationState, PublicationState.published);
      final encoded = jsonEncode(
        LearningContent.fromExercise(exercise).toJson(),
      );
      final restored = LearningContent.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
      expect(restored.toJson(), content.toJson());
      expect(restored.asRunnableExercise()!.answers, exercise.answers);
      expect(
        CourseAuditService().auditExercise(exercise).map((issue) => issue.code),
        isNot(contains('FLASHCARD_EXAMPLE_EMPTY')),
      );
    });
  }

  test(
    'Flashcard authoring keeps newly entered usage in Draft and Published',
    () {
      final original = _storedFlashcard().asRunnableExercise()!;
      for (final state in PublicationState.values) {
        final built = ExerciseDraftBuilder.build(
          ExerciseDraftValues(
            original: original,
            type: 'flashcard',
            publicationState: state,
            prompt: 'eva',
            question: 'water',
            tts: 'eva',
            answers: 'pan e eva\nbread and water',
          ),
        );
        expect(built.error, isNull);
        final candidate = built.candidate!;
        expect(candidate.id, original.id);
        expect(candidate.updatedAt, original.updatedAt);
        expect(candidate.publicationState, state);
        expect(candidate.answers, ['pan e eva', 'bread and water']);
        final content = LearningContent.fromExercise(candidate);
        expect(content.kind, 'presentation');
        expect(content.presentation!.actions, ['understood', 'review_later']);
        expect(
          {
            for (final element in content.presentation!.content)
              element.role: element.text,
          },
          {
            'term': 'eva',
            'meaning': 'water',
            'audio': 'eva',
            'usage': 'pan e eva',
            'usage_translation': 'bread and water',
          },
        );
        expect(
          LearningContent.fromJson(
            content.toJson(),
          ).asRunnableExercise()!.answers,
          ['pan e eva', 'bread and water'],
        );
      }
    },
  );
}
