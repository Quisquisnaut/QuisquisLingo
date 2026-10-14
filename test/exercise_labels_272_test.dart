import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/audio_library_screen.dart';
import 'package:quisquislingo_app/screens/course_audit_screen.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart'
    as course_editor;
import 'package:quisquislingo_app/screens/lesson_authoring_preview_screen.dart';
import 'package:quisquislingo_app/services/authoring_hierarchy_status.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/exercise_labels.dart';

/// Build 272 Revision 6: the names an author reads for an exercise have an
/// owner, and four pages left the Course Editor file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the moved pages are still reachable from the Course Editor file', () {
    expect(course_editor.AudioLibraryScreen, AudioLibraryScreen);
    expect(course_editor.CourseAuditScreen, CourseAuditScreen);
    expect(
      course_editor.LessonAuthoringPreviewScreen,
      LessonAuthoringPreviewScreen,
    );
    expect(course_editor.AuthoringHierarchyStatus, AuthoringHierarchyStatus);
  });

  group('ExerciseLabels, on every exercise of the bundled Courses', () {
    late List<Exercise> exercises;

    setUpAll(() async {
      exercises = [
        for (final code in CourseService.bundledAssets.keys)
          for (final lesson in (await CourseService().loadBundledCourse(
            code,
          )).lessons)
            for (final round in lesson.rounds) ...round.exercises,
      ];
      expect(exercises.length, greaterThan(100));
    });

    test('the kind name is the preset the exercise carries, else its kind', () {
      for (final exercise in exercises) {
        final name = ExerciseLabels.kindName(exercise);
        expect(
          name,
          exercise.editorTemplate.isNotEmpty
              ? exercise.editorTemplate
              : ExerciseFeatures(exercise).kind.name,
          reason: exercise.id,
        );
        expect(name, isNotEmpty, reason: exercise.id);
      }
    });

    test('the type label is the preset\'s name, else the kind\'s', () {
      for (final exercise in exercises) {
        final preset = ExercisePresetRegistry.byId(exercise.editorTemplate);
        expect(
          ExerciseLabels.typeLabel(exercise),
          preset?.name ??
              CourseAuditService.kindLabel(ExerciseFeatures(exercise).kind),
          reason: exercise.id,
        );
      }
    });

    test('the summary is one line of the exercise\'s own words, never empty, '
        'and its ID only when it has no words', () {
      var named = 0;
      for (final exercise in exercises) {
        final summary = ExerciseLabels.summary(exercise);
        expect(summary, isNotEmpty, reason: exercise.id);
        expect(summary, summary.trim(), reason: exercise.id);
        if (summary != exercise.id) named++;
      }
      // Nearly every bundled exercise has words of its own to show.
      expect(named, greaterThan(exercises.length * 9 ~/ 10));
    });
  });

  test('an exercise without any words is named by its ID; a Story cover '
      'without a title is a Title block', () {
    final bare = Exercise.canonical(
      id: 'bare-1',
      publicationState: PublicationState.draft,
      primitive: ExercisePrimitive.presentation,
      canonicalEvaluation: CanonicalEvaluation.none,
    );
    expect(ExerciseLabels.summary(bare), 'bare-1');
    final cover = bare.withAuthoringMetadata(const {'presetId': 'story_cover'});
    expect(ExerciseLabels.summary(cover), 'Title block');
  });
}
