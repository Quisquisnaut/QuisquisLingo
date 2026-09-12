import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/editor_breadcrumbs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Preview author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  testWidgets(
    'new unsaved Exercise Preview retains editor fields and all preferences',
    (tester) async {
      final original = exampleExercise();
      final course = exampleCourse([original]);
      final before = await preferences();
      await useViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: original,
            title: 'New Exercise',
            isNew: true,
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        field('Prompt / instruction'),
        'Unsaved new prompt',
      );
      await tapKey(tester, 'exercise-preview');
      expect(find.byType(RoundScreen), findsOneWidget);
      final preview = tester.widget<RoundScreen>(find.byType(RoundScreen));
      expect(preview.previewMode, isTrue);
      expect(preview.round.exercises.single.prompt, 'Unsaved new prompt');
      expect(
        preview.round.exercises.single.publicationState,
        original.publicationState,
      );
      expect(original.prompt, 'Original prompt');
      expect(await preferences(), before);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(
        tester
            .widget<TextField>(field('Prompt / instruction'))
            .controller!
            .text,
        'Unsaved new prompt',
      );
      expect(await preferences(), before);
    },
  );

  for (final type in [
    'choice',
    'type_translation',
    'word_order',
    'matching',
    'flashcard',
    'build_translation',
    'contextual_comprehension',
    'listening_spelling',
  ]) {
    for (final state in PublicationState.values) {
      testWidgets(
        'unsaved $type Preview preserves $state, timestamps, JSON and preferences',
        (tester) async {
          final exercise = modelExercise(type, state);
          final course = exampleCourse([exercise]);
          final beforeCourse = jsonEncode(course.toJson());
          final beforePrefs = await preferences();
          var saves = 0;
          await useViewport(tester);
          await tester.pumpWidget(
            MaterialApp(
              home: ExerciseEditorScreen(
                exercise: exercise,
                title: type,
                isNew: false,
                course: course,
                lesson: course.lessons.first,
                round: course.lessons.first.rounds.first,
                onExerciseSaved: (_) => saves++,
                clock: () => throw StateError(
                  'Preview must not use the authoring clock',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final input = find.byType(TextField).first;
          final controller = tester.widget<TextField>(input).controller!;
          final unsaved = '${controller.text} updated';
          await tester.enterText(input, unsaved);
          await tapKey(tester, 'exercise-preview');
          expect(find.byType(RoundScreen), findsOneWidget);
          final runtime = tester.widget<RoundScreen>(find.byType(RoundScreen));
          expect(runtime.previewMode, isTrue);
          expect(runtime.round.exercises.single.publicationState, state);
          expect(saves, 0);
          expect(jsonEncode(course.toJson()), beforeCourse);
          expect(await preferences(), beforePrefs);
          await tester.tap(find.byType(BackButton));
          await settle(tester);
          expect(controller.text, unsaved);
          expect(await preferences(), beforePrefs);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'invalid Preview identifies correct-answer field and retains invalid text',
    (tester) async {
      final exercise = exampleExercise();
      final course = exampleCourse([exercise]);
      await useViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: exercise,
            title: 'Edit',
            isNew: false,
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(field('Correct answer number'), '99');
      await tapKey(tester, 'exercise-preview');
      expect(find.byType(RoundScreen), findsNothing);
      expect(find.textContaining('Correct answer number'), findsWidgets);
      expect(
        tester
            .widget<TextField>(field('Correct answer number'))
            .controller!
            .text,
        '99',
      );
    },
  );

  testWidgets(
    'completed unsaved Preview awards no learner state or save callback',
    (tester) async {
      final exercise = exampleExercise();
      final course = exampleCourse([exercise]);
      var saves = 0;
      await useViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: exercise,
            title: 'Edit',
            isNew: true,
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
            onExerciseSaved: (_) => saves++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        field('Prompt / instruction'),
        'Changed before preview',
      );
      final before = await preferences();
      await tapKey(tester, 'exercise-preview');
      await tester.tap(find.text('Ciao'));
      await settle(tester);
      await tester.tap(find.text('Finish round'));
      await settle(tester);
      expect(find.text('Preview complete'), findsOneWidget);
      expect(await preferences(), before);
      expect(saves, 0);
      await tester.tap(find.text('Close'));
      await settle(tester);
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      expect(
        tester
            .widget<TextField>(field('Prompt / instruction'))
            .controller!
            .text,
        'Changed before preview',
      );
      expect(await preferences(), before);
    },
  );

  testWidgets(
    'Previous/Next follows Round IDs and protects save/discard decisions',
    (tester) async {
      final first = exampleExercise();
      final second = exampleExercise(id: 'second');
      final course = exampleCourse([first, second]);
      final saves = <Exercise>[];
      await useViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: first,
            title: 'Edit',
            isNew: false,
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
            onExerciseSaved: saves.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('exercise-previous')))
            .onPressed,
        isNull,
      );
      await tester.enterText(field('Prompt / instruction'), 'Keep this draft');
      await tapKey(tester, 'exercise-next');
      expect(find.text('Unsaved Exercise changes'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await settle(tester);
      expect(
        tester
            .widget<TextField>(field('Prompt / instruction'))
            .controller!
            .text,
        'Keep this draft',
      );
      await tapKey(tester, 'exercise-next');
      await tester.tap(find.widgetWithText(TextButton, 'Save as draft'));
      await settle(tester);
      expect(saves.single.id, first.id);
      expect(saves.single.prompt, 'Keep this draft');
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('exercise-next')))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        field('Prompt / instruction'),
        'Discard this change',
      );
      await tapKey(tester, 'exercise-previous');
      await tester.tap(find.text('Discard changes'));
      await settle(tester);
      expect(
        tester
            .widget<TextField>(field('Prompt / instruction'))
            .controller!
            .text,
        'Keep this draft',
      );
      expect(saves, hasLength(1));
      await tapKey(tester, 'exercise-next');
      expect(
        tester
            .widget<TextField>(field('Prompt / instruction'))
            .controller!
            .text,
        second.prompt,
      );
      expect(find.text('Lesson 1: Lesson title'), findsOneWidget);
    },
  );

  testWidgets(
    'audio Preview ignores learner Audio Settings and requires no active learner',
    (tester) async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await SettingsService().setAudioExercisesEnabled(false);
      final exercise = modelExercise(
        'listening_spelling',
        PublicationState.draft,
      );
      final course = exampleCourse([exercise]);
      final before = await preferences();
      await useViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: exercise,
            title: 'Audio preview',
            isNew: false,
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('Missing word')).controller!.text,
        'Ciao',
      );
      await tapKey(tester, 'exercise-preview');
      expect(find.byType(RoundScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(await preferences(), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('malformed pair input is explained instead of silently omitted', (
    tester,
  ) async {
    final exercise = modelExercise('matching', PublicationState.draft);
    final course = exampleCourse([exercise]);
    await useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: exercise,
          title: 'Pairs',
          isNew: false,
          course: course,
          lesson: course.lessons.first,
          round: course.lessons.first.rounds.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pairs = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.controller!.text.contains('Ciao = Hello'),
    );
    await tester.enterText(
      pairs,
      'Ciao = Hello\nCasa = House\nGatto = Cat\nUnfinished line',
    );
    await tapKey(tester, 'exercise-preview');
    expect(find.byType(RoundScreen), findsNothing);
    expect(find.textContaining('Pairs line 4:'), findsOneWidget);
    expect(
      tester.widget<TextField>(pairs).controller!.text,
      contains('Unfinished line'),
    );
  });

  testWidgets('intentional untitled Round accepts Enter without a fake title', (
    tester,
  ) async {
    final course = exampleCourse([exampleExercise()]);
    List<LearningRound>? returned;
    await useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              returned = await Navigator.of(context).push<List<LearningRound>>(
                MaterialPageRoute(
                  builder: (_) => LessonRoundsScreen(
                    course: course,
                    lesson: course.lessons.first,
                  ),
                ),
              );
            },
            child: const Text('Open rounds'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open rounds'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New round'));
    await tester.pumpAndSettle();
    expect(find.text('Press Enter to keep this Round untitled.'), findsNothing);
    expect(field('Title, or Enter to skip'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Round 3'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(returned, hasLength(3));
    expect(returned!.last.title, isEmpty);
    expect(returned!.map((round) => round.id).toSet(), hasLength(3));
  });

  testWidgets('Rename Round uses the compact untitled label at 320 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = exampleCourse([exampleExercise()]);
    LearningRound? returned;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              returned = await Navigator.of(context).push<LearningRound>(
                MaterialPageRoute(
                  builder: (_) => RoundEditorScreen(
                    course: course,
                    lesson: course.lessons.first,
                    round: course.lessons.first.rounds.first,
                    roundIndex: 0,
                  ),
                ),
              );
            },
            child: const Text('Open Round'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Round'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('round-rename-action')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Rename Round'),
      ),
      findsOneWidget,
    );
    expect(field('Title, or Enter to skip'), findsOneWidget);
    expect(find.text('Press Enter to keep this Round untitled.'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.enterText(field('Title, or Enter to skip'), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Round 1')),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(returned?.title, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter without a replacement preserves a titled Round', (
    tester,
  ) async {
    await useViewport(tester);
    final base = exampleCourse([exampleExercise()]);
    final originalRound = base.lessons.first.rounds.first;
    final titledRound = LearningRound(
      id: originalRound.id,
      publicationState: originalRound.publicationState,
      updatedAt: originalRound.updatedAt,
      title: 'Keep this title',
      visualType: originalRound.visualType,
      content: originalRound.content,
    );
    final lesson = Lesson(
      lessonId: base.lessons.first.lessonId,
      publicationState: base.lessons.first.publicationState,
      updatedAt: base.lessons.first.updatedAt,
      title: base.lessons.first.title,
      rounds: [titledRound],
      section: base.lessons.first.section,
      sectionName: base.lessons.first.sectionName,
      themeIconAsset: base.lessons.first.themeIconAsset,
      guidebook: base.lessons.first.guidebook,
      duel: base.lessons.first.duel,
    );
    final course = Course.fromJson({
      ...base.toJson(),
      'lessons': [lesson.toJson()],
    });
    LearningRound? returned;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              returned = await Navigator.of(context).push<LearningRound>(
                MaterialPageRoute(
                  builder: (_) => RoundEditorScreen(
                    course: course,
                    lesson: lesson,
                    round: titledRound,
                    roundIndex: 0,
                  ),
                ),
              );
            },
            child: const Text('Open titled Round'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open titled Round'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('round-rename-action')));
    await tester.pumpAndSettle();
    expect(field('Title, or Enter to skip'), findsOneWidget);
    await tester.enterText(field('Title, or Enter to skip'), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Keep this title'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(returned?.title, 'Keep this title');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Round breadcrumb uses the same unsaved guard as Back', (
    tester,
  ) async {
    final course = exampleCourse([exampleExercise()]);
    await useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: course,
          lesson: course.lessons.first,
          round: course.lessons.first.rounds.first,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Original prompt'));
    await tester.pumpAndSettle();
    await tester.enterText(
      field('Prompt / instruction'),
      'Unsaved breadcrumb edit',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Round 1'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved Exercise changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('Prompt / instruction')).controller!.text,
      'Unsaved breadcrumb edit',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Round 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseEditorScreen), findsNothing);
    expect(find.text('Original prompt'), findsOneWidget);
  });

  testWidgets('new unsaved Exercises have no Previous/Next destination', (
    tester,
  ) async {
    final course = exampleCourse([exampleExercise()]);
    await useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: exampleExercise(id: 'new-id'),
          title: 'New',
          isNew: true,
          course: course,
          lesson: course.lessons.first,
          round: course.lessons.first.rounds.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in ['exercise-previous', 'exercise-next']) {
      expect(
        tester.widget<OutlinedButton>(find.byKey(Key(key))).onPressed,
        isNull,
      );
    }
  });

  testWidgets(
    'Lesson breadcrumb refreshes after Rename and resolves duplicate titles by ID',
    (tester) async {
      final original = exampleCourse([exampleExercise()]);
      final duplicateTitleCourse = Course.fromJson({
        ...original.toJson(),
        'lessons': [
          original.lessons.first.toJson(),
          {...original.lessons.last.toJson(), 'title': 'Renamed lesson'},
        ],
      });
      await useViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: LessonEditorScreen(
            course: duplicateTitleCourse,
            lesson: duplicateTitleCourse.lessons.first,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lesson-title-control')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Renamed lesson');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Save'),
        ),
      );
      await tester.pumpAndSettle();

      final breadcrumb = find.byType(EditorBreadcrumbs);
      expect(
        find.descendant(
          of: breadcrumb,
          matching: find.text('Lesson 1: Renamed lesson'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: breadcrumb,
          matching: find.text('Lesson 2: Renamed lesson'),
        ),
        findsNothing,
      );
    },
  );
}

Finder field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<Map<String, Object?>> preferences() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)};
}

Exercise exampleExercise({
  String id = 'exercise-one',
  PublicationState state = PublicationState.draft,
}) => Exercise(
  id: id,
  publicationState: state,
  updatedAt: DateTime.utc(2026, 9, 5),
  type: 'choice',
  prompt: 'Original prompt',
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

Future<void> tapKey(WidgetTester tester, String key) async {
  tester.testTextInput.hide();
  await tester.pump();
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      350,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await settle(tester);
}

Course exampleCourse(List<Exercise> exercises) => Course(
  courseId: 'workflow-course',
  title: 'Workflow course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson-one',
      title: 'Lesson title',
      rounds: [
        LearningRound(id: 'round-one', title: '', exercises: exercises),
        LearningRound(
          id: 'round-two',
          title: 'Destination',
          exercises: [exampleExercise(id: 'destination-exercise')],
        ),
      ],
    ),
    Lesson(
      lessonId: 'lesson-two',
      title: 'Second lesson',
      rounds: [
        LearningRound(
          id: 'round-three',
          title: 'Other destination',
          exercises: [exampleExercise(id: 'third-exercise')],
        ),
      ],
    ),
  ],
);

Exercise modelExercise(String type, PublicationState state) => Exercise(
  id: 'preview-$type',
  type: type,
  publicationState: state,
  updatedAt: DateTime.utc(2026, 9, 4),
  prompt: type == 'flashcard' ? 'Ciao' : 'Translate this greeting',
  question: type == 'flashcard' ? 'Hello' : 'Choose the greeting.',
  answers: type == 'flashcard'
      ? const ['Ciao, amico.', 'Hello, friend.']
      : const ['Ciao', 'Casa'],
  correct: 0,
  tts: type == 'listening_spelling' ? 'Ciao amico' : null,
  accepted: const ['Ciao'],
  tokens: const ['Ciao', 'amico'],
  orderAnswer: const ['Ciao', 'amico'],
  correctTranslations: type == 'build_translation'
      ? const ['Ciao amico']
      : const [],
  pairs: const [
    ['Ciao', 'Hello'],
    ['Casa', 'House'],
    ['Gatto', 'Cat'],
  ],
  hint: '',
  icons: const [],
);

Future<void> useViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}
