import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_catalogs.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_en.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_title.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 261 Revision 3 (owner decisions of 2 October 2026): every exercise
/// has a title, the name of the preset that represents it, and an
/// instruction; a Story shows only the instruction.
Iterable<Exercise> _exercises(Course course) => [
  for (final lesson in course.lessons)
    for (final round in lesson.rounds) ...round.exercises,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every preset has a title in the seven languages', () {
    final slugs = {
      for (final preset in ExercisePresetRegistry.presets)
        ExerciseTitle.slugOfName(preset.name),
    };
    expect(slugs, hasLength(40));
    for (final preset in ExercisePresetRegistry.presets) {
      final slug = ExerciseTitle.slugOfName(preset.name);
      final english = exerciseCopyEn['title.$slug'];
      expect(
        english?.replaceAll('?', ''),
        preset.name
            .replaceAll(RegExp(r'\s*\(to (target|source)\)$'), '')
            .toUpperCase(),
        reason: preset.id,
      );
      for (final MapEntry(key: language, value: catalog)
          in exerciseCopyCatalogs.entries) {
        expect(catalog['title.$slug'], isNotEmpty, reason: '$language $slug');
      }
    }
    for (final MapEntry(key: language, value: catalog)
        in exerciseCopyCatalogs.entries) {
      expect(
        catalog['instruction.selectTranslation'],
        contains('{language}'),
        reason: language,
      );
    }
  });

  test('the bundled exercises are titled by their recognized preset', () async {
    for (final code in CourseService.courseAssets.keys) {
      final course = await CourseService().loadCourse(code);
      for (final exercise in _exercises(course)) {
        final preset = ExercisePresetRegistry.byId(exercise.editorTemplate);
        if (preset == null) continue;
        final expected =
            exerciseCopyCatalogs[ExerciseCopyService.instructionLanguage(
              course,
            )]!['title.${ExerciseTitle.slugOfName(preset.name)}'];
        expect(
          ExerciseCopyService.title(course, exercise),
          expected,
          reason: '$code ${exercise.id}',
        );
      }
    }
  });

  test('the dog of QQL Demo: Piedmontese has its title', () async {
    final course = await CourseService().loadCourse('PMS_MIX');
    final dog = course.lessons.first.rounds[5].exercises.firstWhere(
      (exercise) => exercise.id == 'pmsmix_69ff369e_l01_r06_e05',
    );
    expect(ExerciseCopyService.title(course, dog), 'PICK THE TRANSLATION');
    expect(
      ExerciseCopyService.instructionForExercise(course, dog),
      'Pick the correct Piedmontese translation',
    );
  });

  Future<void> pumpRound(
    WidgetTester tester,
    Course course,
    LearningRound round,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoundScreen(
          course: course,
          lesson: course.lessons.first,
          round: round,
          ttsLanguage: 'en-GB',
          roundIndex: 0,
          previewMode: true,
        ),
      ),
    );
  }

  testWidgets('Pick the translation shows its title and a translated line', (
    tester,
  ) async {
    final course = (await tester.runAsync(
      () => CourseService().loadCourse('EN_IT'),
    ))!;
    final exercise = course.lessons.first.rounds[1].exercises.first;
    expect(exercise.editorTemplate, 'translation_choice_to_target');
    await pumpRound(
      tester,
      course,
      LearningRound(
        id: 'preview_title',
        title: 'Preview',
        content: [LearningContent.fromExercise(exercise)],
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('exercise-heading')).evaluate().isNotEmpty,
    );
    // QQL Demo: English from Italian speaks Italian to its learners.
    expect(
      tester.widget<Text>(find.byKey(const Key('exercise-heading'))).data,
      'SCEGLI LA TRADUZIONE',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('translation-choice-instruction')))
          .data,
      'Scegli la traduzione corretta in inglese',
    );
  });

  testWidgets('a Story shows no title, not even on its cover', (tester) async {
    final course = (await tester.runAsync(
      () => CourseService().loadCourse('EN_IT'),
    ))!;
    final story = course.lessons.first.rounds[3];
    expect(story.isStory, isTrue);
    await pumpRound(tester, course, story);
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('story-cover-continue')).evaluate().isNotEmpty,
    );
    expect(find.byKey(const Key('exercise-heading')), findsNothing);
    expect(find.byKey(const Key('exercise-instruction')), findsOneWidget);
    // Through the cover and the three lines to the first question.
    await tester.tap(find.byKey(const Key('story-cover-continue')));
    for (var line = 0; line < 3; line++) {
      await tester.pumpUntilFileIoState(
        () =>
            find.byKey(const Key('story-line-continue')).evaluate().isNotEmpty,
      );
      await tester.ensureVisible(
        find.byKey(const Key('story-line-continue')).last,
      );
      await tester.tap(find.byKey(const Key('story-line-continue')).last);
    }
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const Key('translation-choice-instruction'))
          .evaluate()
          .isNotEmpty,
    );
    expect(find.byKey(const Key('exercise-heading')), findsNothing);
    expect(find.text('SCEGLI LA TRADUZIONE'), findsNothing);
  });
}
