import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _maintainerId = '12345678-1234-4234-9234-123456789abc';

void main() {
  test('legacy v5 course is rejected instead of partially loaded', () {
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

    expect(
      () => Course.fromJson(json),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('format 11 only'),
        ),
      ),
    );
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

  test(
    'Course Manager classifies its current course by declared origin',
    () async {
      // Since Build 249 the listing is CourseLibraryOperations.load, so the rule
      // is checked by behaviour rather than by searching the screen's source.
      SharedPreferences.setMockInitialValues({});
      final ops = CourseLibraryOperations();
      final italian = await CourseService().loadCourse('IT');

      final bundledCurrent = Course.fromJson({
        ...italian.toJson(),
        'title': 'Current bundled copy',
      });
      final withBundled = await ops.load(currentCourse: bundledCurrent);
      expect(withBundled.bundledCourses.first.title, 'Current bundled copy');
      expect(
        withBundled.bundledCourses.where((c) => c.courseId == italian.courseId),
        hasLength(1),
      );

      final customCurrent = Course(
        courseId: 'custom-current',
        originType: CourseOriginType.custom,
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: _maintainerId,
          displayName: 'Maintainer',
        ),
        maintainer: const CourseMaintainer(_maintainerId),
        originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Custom current',
        ttsLanguage: 'it-IT',
        lessons: [
          Lesson(lessonId: 'lesson', title: 'Lesson', rounds: const []),
        ],
      );
      final withCustom = await ops.load(currentCourse: customCurrent);
      expect(
        withCustom.bundledCourses.map((c) => c.courseId),
        isNot(contains('custom-current')),
      );
      expect(
        withCustom.bundledCourses.where((c) => c.courseId == italian.courseId),
        hasLength(1),
      );
    },
  );
}
