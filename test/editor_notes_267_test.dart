import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/editor_notes.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/publisher_course_export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 267 Revision 8 (owner decisions of 9 October 2026): an optional
/// Editor Notes field on every exercise, stored on its Content as
/// `editorNotes`, never shown to learners, kept by Copy and Fork, removed
/// by Export as Publisher Course.

final _stamp = DateTime.utc(2026, 10, 9);
const _profileId = '00000000-0000-4000-8000-000000000268';

Exercise _select({String notes = ''}) => Exercise.canonical(
  id: 'select-notes',
  updatedAt: _stamp,
  primitive: ExercisePrimitive.select,
  promptElements: [
    PromptElement(type: 'text', text: 'Pick ‘ciao’.', role: 'question'),
  ],
  items: [
    ExerciseItem(
      id: 'a',
      content: [PromptElement(type: 'text', text: 'hello')],
    ),
    ExerciseItem(
      id: 'b',
      content: [PromptElement(type: 'text', text: 'goodbye')],
    ),
  ],
  canonicalEvaluation: const CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['a'],
  ),
  authoringMetadata: const {'presetId': 'choice_target'},
  editorNotes: notes,
);

Course _course(Exercise exercise, {String courseVersion = ''}) => Course(
  courseId: 'notes-267-course',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Notes author',
  ),
  originalCreatedAtUtc: '2026-10-09T00:00:00.000Z',
  maintainer: const CourseMaintainer(_profileId),
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Notes author',
  modifiedAtUtc: '2026-10-09T00:00:00.000Z',
  courseVersion: courseVersion,
  license: 'CC BY 4.0',
  title: 'Notes 267',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson-notes',
      updatedAt: _stamp,
      title: 'Notes',
      rounds: [
        LearningRound(
          id: 'round-notes',
          updatedAt: _stamp,
          title: '',
          exercises: [exercise],
        ),
      ],
    ),
  ],
);

Map<String, dynamic> _contentJson(Course course) =>
    ((((course.toJson()['lessons'] as List).single as Map)['rounds'] as List)
                    .single
                as Map)['content']
            .single
        as Map<String, dynamic>;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the Course file', () {
    test('notes are stored on the Content, only when there are some', () {
      final json = _contentJson(_course(_select(notes: 'Check with Anna.')));
      expect(json['editorNotes'], 'Check with Anna.');
      expect((json['exercise'] as Map).containsKey('editorNotes'), isFalse);
      expect(
        _contentJson(_course(_select())).containsKey('editorNotes'),
        isFalse,
      );

      final read = Course.fromJson(_course(_select(notes: 'Note')).toJson());
      expect(
        read.lessons.single.rounds.single.exercises.single.editorNotes,
        'Note',
      );
    });

    test(
      'a note that is not a string, too long or without exercise is refused',
      () {
        Map<String, dynamic> content(Object? notes) => {
          ..._contentJson(_course(_select())),
          'editorNotes': notes,
        };
        expect(
          () => LearningContent.fromJson(content(3)),
          throwsFormatException,
        );
        expect(
          () => LearningContent.fromJson(
            content('x' * (Exercise.maxEditorNotesLength + 1)),
          ),
          throwsFormatException,
        );
        expect(
          LearningContent.fromJson(
            content('x' * Exercise.maxEditorNotesLength),
          ).exercise!.editorNotes,
          hasLength(Exercise.maxEditorNotesLength),
        );
        expect(
          () => LearningContent.fromJson({
            'id': 'text',
            'publicationState': 'published',
            'kind': 'text',
            'text': 'A note',
            'editorNotes': 'Not here',
          }),
          throwsFormatException,
        );
      },
    );

    test('notes never change what the exercise is', () {
      final plain = _select();
      final noted = _select(notes: 'An idea');
      expect(noted.semanticallyEquals(plain), isTrue);
      expect(PresetRecipes.recognize(noted), PresetRecipes.recognize(plain));
      expect(
        noted.withPublicationState(PublicationState.draft).editorNotes,
        'An idea',
      );
      expect(noted.withAuthoringMetadata(const {}).editorNotes, 'An idea');
    });

    test('the canonical editor keeps and saves the notes', () {
      final draft = CanonicalExerciseDraft.fromExercise(
        _select(notes: 'Old note'),
      );
      expect(draft.editorNotes, 'Old note');
      draft.editorNotes = '  New note  ';
      final saved = draft.toExercise(
        publicationState: PublicationState.published,
        updatedAt: _stamp,
      );
      expect(saved.editorNotes, 'New note');
      // Only the notes changed: the exercise is the same, its preset kept.
      expect(saved.semanticallyEquals(_select()), isTrue);
      expect(saved.authoringMetadata['presetId'], 'choice_target');
    });

    test('a copy keeps the notes', () {
      final copy = AuthoringDuplicationService().duplicateExercise(
        _select(notes: 'Keep me'),
      );
      expect(copy.editorNotes, 'Keep me');
    });

    test('a Course with notes needs this build', () {
      expect(
        EditorNotes.withMinimumAppBuild(_course(_select())).minimumAppBuild,
        isNull,
      );
      expect(
        EditorNotes.withMinimumAppBuild(
          _course(_select(notes: 'Note')),
        ).minimumAppBuild,
        EditorNotes.minimumAppBuild,
      );
      expect(
        EditorNotes.minimumAppBuild,
        lessThanOrEqualTo(int.parse(AppMetadata.buildNumber)),
      );
    });

    test('Export as Publisher Course leaves the notes out', () {
      final course = _course(_select(notes: 'Private'), courseVersion: '3');
      expect(
        EditorNotes.courseHasNotes(EditorNotes.withoutNotes(course)),
        isFalse,
      );
      final publisher = PublisherCourseExport.build(
        course,
        const PublisherIdentity(
          publisherId: 'org.example.notes',
          publisherName: 'Example Courses',
        ),
        now: _stamp,
      );
      expect(EditorNotes.courseHasNotes(publisher), isFalse);
      expect(_contentJson(publisher).containsKey('editorNotes'), isFalse);
    });
  });

  group('the editors', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => testSupportDirectory.path,
          );
    });

    testWidgets('the Round editor shows a note icon with the note', (
      tester,
    ) async {
      final course = _course(_select(notes: 'Check with Anna.'));
      final lesson = course.lessons.single;
      await tester.pumpWidget(
        MaterialApp(
          home: RoundEditorScreen(
            course: course,
            lesson: lesson,
            round: lesson.rounds.single,
            roundIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final icon = find.byKey(const ValueKey('exercise-notes-select-notes'));
      expect(icon, findsOneWidget);
      expect(tester.widget<Tooltip>(icon).message, 'Check with Anna.');
    });

    testWidgets('the preset form edits the notes and saves them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Exercise? saved;
      final exercise = _select(notes: 'First note');
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: exercise,
            title: 'Notes form',
            isNew: false,
            course: _course(exercise),
            onExerciseSaved: (value) => saved = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byKey(const Key('exercise-editor-notes')),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(field).controller.text, 'First note');
      await tester.enterText(field, 'Second note');
      // The exercise is Published: Save keeps it so (Save as draft would
      // first ask to move it to Draft).
      final save = find.byKey(const Key('exercise-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.editorNotes, 'Second note');
    });
  });
}
