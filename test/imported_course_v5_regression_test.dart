import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';

void main() {
  test('v5 listening spelling keeps input interaction and acceptedAnswers', () {
    final json =
        jsonDecode(r'''
{
  "formatVersion": 5,
  "courseId": "imported",
  "publicationState": "published",
  "lessonNumberingMode": "lesson",
  "defaultLessonIconStyle": "monochrome",
  "learningLanguage": "Italian",
  "interfaceLanguage": "English",
  "sourceLanguage": "English",
  "targetLanguage": "Italian",
  "title": "Imported",
  "ttsLanguage": "it-IT",
  "version": "1",
  "lessons": [{
      "lessonId": "lesson_1",
      "publicationState": "published",
      "title": "Lesson 1",
      "guidebook": {"content": [{"id":"g1","publicationState":"published","kind":"vocabulary","required":false,"role":"vocabulary","text":"ecco = there"}]},
      "rounds": [{
        "id": "r1",
        "publicationState": "published",
        "title": "Round 1",
        "visualType": "listening",
        "content": [{
          "id": "ls1",
          "publicationState": "published",
          "kind": "exercise",
          "required": true,
          "editorTemplate": "listening_spelling",
          "exercise": {
            "prompt": [{"role":"primary","type":"audio","text":"ecco"},{"role":"question","type":"text","text":"Type what you hear."}],
            "interaction": {"kind":"input"},
            "evaluation": {"kind":"text_match","acceptedAnswers":["ecco"]}
          }
        }]
      }],
      "duel": {"id":"lesson_1_duel","title":"Duel"}
    }]
}
''')
            as Map<String, dynamic>;

    final exercise = Course.fromJson(
      json,
    ).lessons.single.rounds.single.exercises.single;
    expect(exercise.type, 'listening_spelling');
    expect(exercise.interaction.kind, 'input');
    expect(exercise.accepted, ['ecco']);
    expect(exercise.tts, 'ecco');
  });

  test('selected_items resolves stable correct Item ID to visible answer', () {
    final exercise = Exercise.v2(
      id: 'read1',
      editorTemplate: 'reading_comprehension',
      promptElements: const [
        PromptElement(
          role: 'passage',
          type: 'text',
          text: 'Va bene, ci sentiamo dopo.',
        ),
        PromptElement(
          role: 'question',
          type: 'text',
          text: 'Which expression means all right?',
        ),
      ],
      interaction: const ExerciseInteraction(
        kind: 'select',
        items: [
          ExerciseItem(
            id: 'wrong',
            content: [PromptElement(type: 'text', text: 'ecco')],
          ),
          ExerciseItem(
            id: 'right',
            content: [PromptElement(type: 'text', text: 'va bene')],
          ),
        ],
      ),
      evaluation: const ExerciseEvaluation(
        kind: 'selected_items',
        correctItemIds: ['right'],
      ),
    );
    expect(exercise.correct, 1);
    expect(exercise.answers[exercise.correct!], 'va bene');
  });

  test('learner source has a dedicated listening spelling input renderer', () {
    final source = File('lib/screens/round_screen.dart').readAsStringSync();
    expect(
      source.contains('Widget _listeningSpellingExercise(Exercise ex)'),
      isTrue,
    );
    expect(
      RegExp(
        r"case 'listening_spelling':\r?\n[ \t]+return _listeningSpellingExercise\(ex\);",
      ).hasMatch(source),
      isTrue,
    );
    expect(source.contains("labelText: 'Your answer'"), isTrue);
  });

  test('Course Editor uses persisted custom selection origin', () {
    final source = File(
      'lib/screens/course_projects_screen.dart',
    ).readAsStringSync();
    expect(
      source.contains(
        "selectedRef == 'custom:\${widget.currentCourse.courseId}'",
      ),
      isTrue,
    );
    expect(
      source.contains(
        '_user.any((course) => course.courseId == widget.currentCourse.courseId)',
      ),
      isFalse,
    );
  });
}
