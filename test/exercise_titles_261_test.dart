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

import 'support/edge_case_fixture.dart';
import 'support/pump_file_io.dart';

/// Build 261 Revision 3 (owner decisions of 2 October 2026): every exercise
/// has a title, the name of the preset that represents it, and an
/// instruction; a Story shows only the instruction.
Iterable<Exercise> _exercises(Course course) => [
  for (final lesson in course.lessons)
    for (final round in lesson.rounds) ...round.exercises,
];

/// The Edge Case fixture's Pick the translation: «una finestra».
Exercise _edgeCaseWindow(Course course) => _exercises(
  course,
).firstWhere((exercise) => exercise.id == 'qql_edge_254_e02_max_translation');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every preset has a title in the seven languages', () {
    final slugs = {
      for (final preset in ExercisePresetRegistry.presets)
        ExerciseTitle.slugOfName(preset.name),
    };
    // 41 with Listen and pick the missing word (Build 274 Revision 3).
    expect(slugs, hasLength(41));
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
    for (final code in CourseService.bundledAssets.keys) {
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

  // Build 262 Revision 0: QQL Demo: Piedmontese left the bundle and its dog
  // had a twin in QQL Demo: English from Italian. Build 272 Revision 15:
  // that Course left the app and the repository too (owner decision of 13
  // October 2026); the Edge Case fixture, which also speaks Italian to its
  // learners, has a Pick the translation of its own, the window.
  test('the window of the Edge Case fixture has its title', () async {
    registerEdgeCaseFixture();
    final course = await CourseService().loadCourse('EN_EDGE');
    final window = _edgeCaseWindow(course);
    expect(ExerciseCopyService.title(course, window), 'SCEGLI LA TRADUZIONE');
    expect(
      ExerciseCopyService.instructionForExercise(course, window),
      'Seleziona la traduzione corretta in inglese',
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
    registerEdgeCaseFixture();
    final course = (await tester.runAsync(
      () => CourseService().loadCourse('EN_EDGE'),
    ))!;
    final exercise = _edgeCaseWindow(course);
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
    // The Edge Case fixture speaks Italian to its learners.
    expect(
      tester.widget<Text>(find.byKey(const Key('exercise-heading'))).data,
      'SCEGLI LA TRADUZIONE',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('translation-choice-instruction')))
          .data,
      'Seleziona la traduzione corretta in inglese',
    );
  });

  testWidgets('a Story shows no title, not even on its cover', (tester) async {
    // The Edge Case fixture's Story «At the bar»: a Before you start card,
    // the cover, two lines, a question and a last line. (The Story «Al bar»
    // of QQL Demo: English from Italian until Build 272 Revision 15.)
    registerEdgeCaseFixture();
    final course = (await tester.runAsync(
      () => CourseService().loadCourse('EN_EDGE'),
    ))!;
    final story = course.lessons
        .expand((lesson) => lesson.rounds)
        .firstWhere((round) => round.id == 'qql_edge_254_r11_story');
    expect(story.isStory, isTrue);
    final question = story.exercises.firstWhere(
      (exercise) => exercise.id == 'qql_edge_254_e36_needs_audio',
    );
    // Outside a Story the question would be titled.
    final title = ExerciseCopyService.title(course, question);
    expect(title, 'SCEGLI LA RISPOSTA');
    await pumpRound(tester, course, story);
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const Key('before-you-start-continue'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.tap(find.byKey(const Key('before-you-start-continue')));
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('story-cover-continue')).evaluate().isNotEmpty,
    );
    expect(find.byKey(const Key('exercise-heading')), findsNothing);
    expect(find.byKey(const Key('exercise-instruction')), findsOneWidget);
    // Through the cover and the two lines to the question.
    await tester.tap(find.byKey(const Key('story-cover-continue')));
    // A line that reads itself aloud holds its Continue until it has been
    // read (Build 269 Revision 0): wait for a Continue that can be pressed.
    final lineContinue = find.byWidgetPredicate(
      (widget) =>
          widget is FilledButton &&
          widget.key == const Key('story-line-continue') &&
          widget.onPressed != null,
    );
    for (var line = 0; line < 2; line++) {
      await tester.pumpUntilFileIoState(
        () => lineContinue.evaluate().isNotEmpty,
      );
      await tester.ensureVisible(lineContinue.last);
      await tester.tap(lineContinue.last);
    }
    await tester.pumpUntilFileIoState(
      () => find.text('Che cosa ordina Marta?').evaluate().isNotEmpty,
    );
    expect(find.byKey(const Key('exercise-heading')), findsNothing);
    expect(find.text(title), findsNothing);
    // The question keeps its instruction line.
    expect(find.byKey(const Key('exercise-instruction')), findsWidgets);
  });
}
