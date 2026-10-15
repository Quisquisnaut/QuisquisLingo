import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_minimum_build.dart';
import 'package:quisquislingo_app/services/editor_notes.dart';
import 'package:quisquislingo_app/services/lesson_icon_pictures.dart';
import 'package:quisquislingo_app/services/page_blocks.dart';
import 'package:quisquislingo_app/services/picture_answers.dart';
import 'package:quisquislingo_app/services/plural_pictures.dart';

/// Build 273 Revision 9: the oldest build that can play a Course has one
/// list of rules, which the Course Editor's confirmation applies. Each
/// rule's own cases stay in its own tests (`page_card_258_test`,
/// `editor_notes_267_test`, `plural_pictures_265_test` and the others);
/// these check that the list is the same five rules, chained as before.
final _stamp = DateTime.utc(2026, 10, 15);

Exercise _page(String id) => Exercise.canonical(
  id: id,
  updatedAt: _stamp,
  primitive: ExercisePrimitive.presentation,
  promptElements: const [
    PromptElement(role: 'block', type: 'text', text: 'A page'),
  ],
  canonicalEvaluation: CanonicalEvaluation.none,
);

Exercise _choice(String id, {String notes = ''}) => Exercise.canonical(
  id: id,
  updatedAt: _stamp,
  primitive: ExercisePrimitive.select,
  promptElements: const [PromptElement(type: 'text', text: 'Which?')],
  items: const [
    ExerciseItem(
      id: 'right',
      content: [PromptElement(type: 'text', text: 'Right')],
    ),
    ExerciseItem(
      id: 'wrong',
      content: [PromptElement(type: 'text', text: 'Wrong')],
    ),
  ],
  canonicalEvaluation: const CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['right'],
  ),
  editorNotes: notes,
);

Course _course(List<Exercise> exercises, {int? minimumAppBuild}) => Course(
  courseId: 'minimum-build-273',
  title: 'Minimum build',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  minimumAppBuild: minimumAppBuild,
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      updatedAt: _stamp,
      rounds: [
        LearningRound(
          id: 'round',
          title: 'Round',
          updatedAt: _stamp,
          exercises: exercises,
        ),
      ],
    ),
  ],
);

/// The five rules chained as the Course Editor's confirmation chained them
/// before Build 273 Revision 9.
Course _chainedAsBefore(Course course) => EditorNotes.withMinimumAppBuild(
  PluralPictures.withMinimumAppBuild(
    LessonIconPictures.withMinimumAppBuild(
      PictureAnswers.withMinimumAppBuild(
        PageBlocks.withMinimumAppBuild(course),
      ),
    ),
  ),
);

void main() {
  test('a Course that uses none of the features is left as it is', () {
    final course = _course([_choice('q')]);
    expect(CourseMinimumBuild.stamp(course).toJson(), course.toJson());
    expect(CourseMinimumBuild.stamp(course).minimumAppBuild, isNull);
  });

  test('a Page asks for the build that draws Pages', () {
    expect(
      CourseMinimumBuild.stamp(_course([_page('p')])).minimumAppBuild,
      PageBlocks.minimumAppBuild,
    );
  });

  test('the latest feature used decides', () {
    final course = _course([_page('p'), _choice('q', notes: 'check this')]);
    expect(
      CourseMinimumBuild.stamp(course).minimumAppBuild,
      EditorNotes.minimumAppBuild,
    );
  });

  test('a higher build the Course already asks for is kept', () {
    // The highest a Course may ask for is this app's own build.
    final course = _course([
      _page('p'),
    ], minimumAppBuild: Course.appBuildNumber);
    expect(
      CourseMinimumBuild.stamp(course).minimumAppBuild,
      Course.appBuildNumber,
    );
  });

  test('the same result as the five rules chained before', () {
    for (final course in [
      _course([_choice('q')]),
      _course([_page('p')]),
      _course([_choice('q', notes: 'n')]),
      _course([_page('p'), _choice('q', notes: 'n')], minimumAppBuild: 1),
    ]) {
      expect(
        CourseMinimumBuild.stamp(course).toJson(),
        _chainedAsBefore(course).toJson(),
      );
    }
  });
}
