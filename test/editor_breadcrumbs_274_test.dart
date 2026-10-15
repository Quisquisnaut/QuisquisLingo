import 'support/test_directories.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/lesson_presentation_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/editor_breadcrumbs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 274 Revision 0: the Rounds page names its Lesson once, and every
/// breadcrumb whose page is open above is a link that goes back through each
/// page's own way back (owner decisions of 13 and 15 October 2026).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationSupportDirectory') {
              return testSupportDirectory.path;
            }
            throw PlatformException(code: 'test_storage_unavailable');
          },
        );
    keepCrashLogUnavailable();
  });

  group('EditorTrail', () {
    test('a page opened outside the chain can jump back only to itself', () {
      final trail = EditorTrail.below(null, EditorLevel.round);
      expect(trail.levels, {EditorLevel.round});
      final below = EditorTrail.below(trail, EditorLevel.exercise);
      expect(below.levels, {EditorLevel.round, EditorLevel.exercise});
    });

    test('a jump passes the pages above its level and ends at it', () async {
      final course = EditorTrail.below(null, EditorLevel.course);
      final lessons = EditorTrail.below(course, EditorLevel.lessons);
      final lesson = EditorTrail.below(lessons, EditorLevel.lesson);
      final rounds = EditorTrail.below(lesson, EditorLevel.rounds);
      final round = EditorTrail.below(rounds, EditorLevel.round);
      var left = 0;
      await round.jumpTo(
        EditorLevel.lesson,
        leave: () async => left++,
        stayed: () => false,
      );
      expect(left, 1);
      expect(round.target, EditorLevel.lesson);
      // The Round editor and the Rounds list go on; the Lesson page stops.
      expect(round.passesThrough(EditorLevel.round), isTrue);
      expect(rounds.passesThrough(EditorLevel.rounds), isTrue);
      expect(lesson.passesThrough(EditorLevel.lesson), isFalse);
      expect(course.target, isNull);
      expect(lessons.passesThrough(EditorLevel.lessons), isFalse);
    });

    test('a page that stays ends the jump', () async {
      final course = EditorTrail.below(null, EditorLevel.course);
      final round = EditorTrail.below(course, EditorLevel.round);
      await round.jumpTo(
        EditorLevel.course,
        leave: () async {},
        stayed: () => true,
      );
      expect(round.target, isNull);
      expect(round.passesThrough(EditorLevel.round), isFalse);
    });

    test('a way back that fails ends the jump', () async {
      final course = EditorTrail.below(null, EditorLevel.course);
      final round = EditorTrail.below(course, EditorLevel.round);
      await expectLater(
        round.jumpTo(
          EditorLevel.course,
          leave: () async => throw StateError('no way back'),
          stayed: () => true,
        ),
        throwsStateError,
      );
      expect(round.target, isNull);
    });

    test('a level whose page is not open above is no jump', () async {
      final round = EditorTrail.below(null, EditorLevel.round);
      var left = 0;
      await round.jumpTo(
        EditorLevel.course,
        leave: () async => left++,
        stayed: () => false,
      );
      expect(left, 0);
      expect(round.target, isNull);
    });
  });

  group('the Lesson named once', () {
    for (final (mode, custom, expected) in [
      (LessonNumberingMode.lesson, '', 'Lesson 2'),
      (LessonNumberingMode.unit, '', 'Unit 2'),
      (LessonNumberingMode.other, 'Step', 'Step 2'),
      (LessonNumberingMode.numberOnly, '', 'Greetings'),
      (LessonNumberingMode.none, '', 'Greetings'),
    ]) {
      test('${mode.name} gives "$expected"', () {
        final course = _course(numbering: mode, customLabel: custom);
        expect(
          const LessonPresentationService().shortName(course, 1),
          expected,
        );
      });
    }
  });

  testWidgets('the Rounds page says the Lesson once, in the title type', (
    tester,
  ) async {
    await _viewport(tester);
    final course = _course();
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(course: course, lesson: course.lessons[1]),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Rounds · Lesson 2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.textContaining('Greetings'),
      ),
      findsNothing,
    );
    // The breadcrumb names it whole, and ends with Rounds.
    final crumbs = find.byType(EditorBreadcrumbs);
    expect(
      find.descendant(of: crumbs, matching: find.text('Lesson 2: Greetings')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: crumbs, matching: find.text('Rounds')),
      findsOneWidget,
    );
  });

  testWidgets('with numbering Off the Rounds page names the Lesson by title', (
    tester,
  ) async {
    await _viewport(tester);
    final course = _course(numbering: LessonNumberingMode.none);
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(course: course, lesson: course.lessons[1]),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Rounds · Greetings'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the exercise crumb is its place in the Round', (tester) async {
    await _viewport(tester);
    final course = _course();
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: course,
          lesson: course.lessons[1],
          round: course.lessons[1].rounds.first,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-entry-second')));
    await tester.pumpAndSettle();
    _expectExerciseCrumb('Exercise 2');
    // Outside the chain only the Round can be jumped to.
    expect(_link('round'), findsOneWidget);
    expect(_link('rounds'), findsNothing);
    expect(_link('lesson'), findsNothing);
    expect(_link('course'), findsNothing);
  });

  testWidgets(
    'from an exercise every crumb above is a link, and a jump asks first',
    (tester) async {
      await _viewport(tester);
      await _openExerciseFromCourseEditor(tester);
      _expectExerciseCrumb('Exercise 2');
      for (final level in ['course', 'lesson', 'rounds', 'round']) {
        expect(_link(level), findsOneWidget, reason: level);
      }

      // Unsaved changes ask first; Keep editing stays and ends the jump.
      await _changeExercise(tester);
      await _tapLink(tester, 'course');
      expect(find.text('Exercise changes not applied'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);

      // The jump that stayed has ended: an ordinary Back now stops at the
      // Round instead of going on to the Course.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditorScreen), findsNothing);
      expect(find.byType(RoundEditorScreen), findsOneWidget);

      // From the Round, the Rounds crumb opens the Rounds list.
      await _tapLink(tester, 'rounds');
      expect(find.byType(RoundEditorScreen), findsNothing);
      expect(find.byType(LessonRoundsScreen), findsOneWidget);

      // From the Rounds list, the Lesson crumb opens the Lesson's page.
      await _tapLink(tester, 'lesson');
      expect(find.byType(LessonRoundsScreen), findsNothing);
      expect(find.byType(LessonEditorScreen), findsOneWidget);
    },
  );

  testWidgets('Discard on the way to the Course leaves the Course as it was', (
    tester,
  ) async {
    await _viewport(tester);
    await _openExerciseFromCourseEditor(tester);
    await _changeExercise(tester);
    await _tapLink(tester, 'course');
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    for (final type in [
      ExerciseEditorScreen,
      RoundEditorScreen,
      LessonRoundsScreen,
      LessonEditorScreen,
      LessonManagementScreen,
    ]) {
      expect(find.byType(type), findsNothing, reason: '$type');
    }
    expect(
      find.byKey(const Key('course-editor-lessons-navigation')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('course-editor-unsaved')), findsNothing);
  });

  testWidgets('Apply on the way to the Course keeps the change', (
    tester,
  ) async {
    await _viewport(tester);
    await _openExerciseFromCourseEditor(tester);
    await _changeExercise(tester);
    await _tapLink(tester, 'course');
    await tester.tap(find.widgetWithText(TextButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseEditorScreen), findsNothing);
    expect(find.byType(LessonManagementScreen), findsNothing);
    expect(find.byKey(const Key('course-editor-unsaved')), findsOneWidget);
  });

  testWidgets('Previous and Next change the exercise crumb', (tester) async {
    await _viewport(tester);
    final course = _course();
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: course,
          lesson: course.lessons[1],
          round: course.lessons[1].rounds.first,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-entry-first')));
    await tester.pumpAndSettle();
    _expectExerciseCrumb('Exercise 1');
    final next = find.byKey(const Key('exercise-next'));
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    _expectExerciseCrumb('Exercise 2');
  });

  testWidgets('the canonical editor names its exercise and jumps too', (
    tester,
  ) async {
    await _viewport(tester);
    final course = _course();
    final lesson = course.lessons[1];
    final round = lesson.rounds.first;
    var trail = EditorTrail.below(null, EditorLevel.course);
    for (final level in [
      EditorLevel.lessons,
      EditorLevel.lesson,
      EditorLevel.rounds,
      EditorLevel.round,
    ]) {
      trail = EditorTrail.below(trail, level);
    }
    final fromRound = trail;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PrimitiveEditorScreen(
                  exercise: round.exercises[1],
                  title: 'Edit exercise 2',
                  isNew: false,
                  course: course,
                  lesson: lesson,
                  round: round,
                  trail: fromRound,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    _expectExerciseCrumb('Exercise 2');
    for (final level in ['course', 'lesson', 'rounds', 'round']) {
      expect(_link(level), findsOneWidget, reason: level);
    }
    await _tapLink(tester, 'lesson');
    expect(find.byType(PrimitiveEditorScreen), findsNothing);
    // The Round editor and the Rounds list would go on; the Lesson stops.
    expect(fromRound.target, EditorLevel.lesson);
    expect(fromRound.passesThrough(EditorLevel.round), isTrue);
    expect(fromRound.passesThrough(EditorLevel.lesson), isFalse);
    expect(fromRound.target, isNull);
  });

  testWidgets(
    'the canonical editor opened from a new exercise jumps through its form',
    (tester) async {
      await _viewport(tester);
      await _openExerciseFromCourseEditor(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      final newExercise = find.text('New Exercise');
      await tester.ensureVisible(newExercise);
      await tester.pumpAndSettle();
      await tester.tap(newExercise);
      await tester.pumpAndSettle();
      final selector = find.byKey(const Key('exercise-preset-selector'));
      await tester.ensureVisible(selector);
      await tester.pumpAndSettle();
      await tester.tap(selector);
      await tester.pumpAndSettle();
      // The canonical choice ends the sheet's list, built as it scrolls.
      final canonical = find.byKey(const Key('exercise-preset-canonical'));
      await tester.scrollUntilVisible(
        canonical,
        500,
        scrollable: find
            .descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(canonical);
      await tester.pumpAndSettle();
      expect(find.byType(PrimitiveEditorScreen), findsOneWidget);
      _expectExerciseCrumb('New Exercise');
      for (final level in ['course', 'lesson', 'rounds', 'round']) {
        expect(_link(level), findsOneWidget, reason: level);
      }
      await _tapLink(tester, 'lesson');
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      for (final type in [
        PrimitiveEditorScreen,
        ExerciseEditorScreen,
        RoundEditorScreen,
        LessonRoundsScreen,
      ]) {
        expect(
          find.byType(type, skipOffstage: false),
          findsNothing,
          reason: '$type',
        );
      }
    },
  );

  testWidgets(
    'Keep editing in the form under the canonical editor ends the jump',
    (tester) async {
      await _viewport(tester);
      await _openExerciseFromCourseEditor(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      final newExercise = find.text('New Exercise');
      await tester.ensureVisible(newExercise);
      await tester.pumpAndSettle();
      await tester.tap(newExercise);
      await tester.pumpAndSettle();
      // A change the form has not applied.
      final notes = find.byKey(const Key('exercise-editor-notes'));
      await tester.ensureVisible(notes);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: notes, matching: find.byType(TextField)),
        'Not applied yet',
      );
      await tester.pumpAndSettle();
      final selector = find.byKey(const Key('exercise-preset-selector'));
      await tester.ensureVisible(selector);
      await tester.pumpAndSettle();
      await tester.tap(selector);
      await tester.pumpAndSettle();
      final canonical = find.byKey(const Key('exercise-preset-canonical'));
      await tester.scrollUntilVisible(
        canonical,
        500,
        scrollable: find
            .descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(canonical);
      await tester.pumpAndSettle();
      expect(find.byType(PrimitiveEditorScreen), findsOneWidget);
      await _tapLink(tester, 'lesson');
      // The canonical editor closed; the form asks about its own change.
      expect(find.byType(PrimitiveEditorScreen), findsNothing);
      expect(find.text('Exercise changes not applied'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      // An ordinary Back now stops at the Round editor.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditorScreen), findsNothing);
      expect(find.byType(RoundEditorScreen), findsOneWidget);
    },
  );

  testWidgets('the Lesson crumb goes back three pages, then Course one more', (
    tester,
  ) async {
    await _viewport(tester);
    await _openExerciseFromCourseEditor(tester);
    await _tapLink(tester, 'lesson');
    expect(find.byType(LessonEditorScreen), findsOneWidget);
    for (final type in [
      ExerciseEditorScreen,
      RoundEditorScreen,
      LessonRoundsScreen,
    ]) {
      expect(
        find.byType(type, skipOffstage: false),
        findsNothing,
        reason: '$type',
      );
    }
    expect(
      find.byType(LessonManagementScreen, skipOffstage: false),
      findsOneWidget,
    );
    // The Lesson page's Course crumb goes back to the main page.
    await _tapLink(tester, 'course');
    for (final type in [LessonEditorScreen, LessonManagementScreen]) {
      expect(
        find.byType(type, skipOffstage: false),
        findsNothing,
        reason: '$type',
      );
    }
    expect(
      find.byKey(const Key('course-editor-lessons-navigation')),
      findsOneWidget,
    );
  });

  testWidgets('a jump works in View only too', (tester) async {
    await _viewport(tester);
    await _openExerciseFromCourseEditor(tester, viewOnly: true);
    expect(find.byKey(const Key('exercise-read-only-notice')), findsOneWidget);
    for (final level in ['course', 'lesson', 'rounds', 'round']) {
      expect(_link(level), findsOneWidget, reason: level);
    }
    await _tapLink(tester, 'course');
    for (final type in [
      ExerciseEditorScreen,
      RoundEditorScreen,
      LessonRoundsScreen,
      LessonEditorScreen,
      LessonManagementScreen,
    ]) {
      expect(
        find.byType(type, skipOffstage: false),
        findsNothing,
        reason: '$type',
      );
    }
    expect(
      find.byKey(const Key('course-editor-lessons-navigation')),
      findsOneWidget,
    );
  });
}

void _expectExerciseCrumb(String text) => expect(
  find.descendant(
    of: find.byType(EditorBreadcrumbs),
    matching: find.text(text),
  ),
  findsOneWidget,
);

Finder _link(String level) => find.byWidgetPredicate(
  (widget) =>
      widget is TextButton && widget.key == ValueKey('editor-crumb-$level'),
);

Future<void> _tapLink(WidgetTester tester, String level) async {
  final link = _link(level);
  await tester.ensureVisible(link);
  await tester.pumpAndSettle();
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Future<void> _changeExercise(WidgetTester tester) async {
  final instruction = find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.labelText == 'Instruction or context (optional)',
  );
  await tester.ensureVisible(instruction);
  await tester.pumpAndSettle();
  await tester.enterText(instruction, 'An unsaved instruction');
  await tester.pumpAndSettle();
}

/// The Course Editor's main page, then the Lessons list, Lesson 2, its
/// Rounds, its first Round and that Round's second exercise.
Future<void> _openExerciseFromCourseEditor(
  WidgetTester tester, {
  bool viewOnly = false,
}) async {
  final course = _course();
  if (!viewOnly) {
    await SettingsService().setCourseEditorLocked(course.courseId, false);
  }
  await SettingsService().markAudioOrphanCheckRun(
    CourseService.codeForCourse(course),
  );
  await tester.pumpWidget(
    MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
  );
  await tester.pumpAndSettle();
  final lessons = find.byKey(const Key('course-editor-lessons-navigation'));
  await tester.ensureVisible(lessons);
  await tester.pumpAndSettle();
  await tester.tap(lessons);
  await tester.pumpAndSettle();
  final notice = find.byKey(const Key('course-editor-view-mode-notice'));
  if (notice.evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }
  final lesson = find.descendant(
    of: find.byKey(const ValueKey('lesson-status-indicator-lesson-two')),
    matching: find.text('Lesson 2: Greetings'),
  );
  await tester.ensureVisible(lesson);
  await tester.pumpAndSettle();
  await tester.tap(lesson);
  await tester.pumpAndSettle();
  final rounds = find.byKey(const Key('lesson-rounds-navigation'));
  await tester.ensureVisible(rounds);
  await tester.pumpAndSettle();
  await tester.tap(rounds);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('round-label-round-two')));
  await tester.pumpAndSettle();
  final exercise = find.byKey(const ValueKey('exercise-entry-second'));
  await tester.ensureVisible(exercise);
  await tester.pumpAndSettle();
  await tester.tap(exercise);
  await tester.pumpAndSettle();
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
}

Future<void> _viewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Exercise _exercise(String id, String prompt) => Exercise(
  id: id,
  publicationState: PublicationState.draft,
  updatedAt: DateTime.utc(2026, 10, 15),
  type: 'choice',
  prompt: prompt,
  question: 'Choose the greeting.',
  answers: const ['Ciao', 'Casa'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Course _course({
  LessonNumberingMode numbering = LessonNumberingMode.lesson,
  String customLabel = '',
}) => Course(
  courseId: 'breadcrumbs-274',
  title: 'Breadcrumbs course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessonNumberingMode: numbering,
  customLessonLabel: customLabel,
  lessons: [
    Lesson(
      lessonId: 'lesson-one',
      title: 'First steps',
      rounds: [
        LearningRound(
          id: 'round-one',
          title: 'Warm up',
          exercises: [_exercise('lesson-one-exercise', 'Warm prompt')],
        ),
      ],
    ),
    Lesson(
      lessonId: 'lesson-two',
      title: 'Greetings',
      rounds: [
        LearningRound(
          id: 'round-two',
          title: 'Hello',
          exercises: [
            _exercise('first', 'First prompt'),
            _exercise('second', 'Second prompt'),
          ],
        ),
      ],
    ),
  ],
);
