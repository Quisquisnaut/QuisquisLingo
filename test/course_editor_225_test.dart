import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'weekly_xp_target': 1000,
    });
    await ProfileService().addProfile('Editor 225 tester');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  testWidgets(
    'Build the translation saves natural punctuation through reload and Audit',
    (tester) async {
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<Exercise>(
                  MaterialPageRoute(
                    builder: (_) => ExerciseEditorScreen(
                      exercise: _buildTranslation(),
                      title: 'Build the translation',
                      isNew: false,
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(_field('Source text'), 'How are you?');
      await tester.enterText(
        _field('Available target-language blocks'),
        'Come\nstai',
      );
      await tester.enterText(_field('Correct translation'), 'Come stai?');
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save-draft')),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('exercise-save-draft')));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved changes'), findsNothing);
      expect(saved, isNotNull);
      final reloaded = Exercise.fromV2Json(
        saved!.toV2Json(),
        contentId: saved!.id,
        editorTemplate: saved!.editorTemplate,
        publicationState: saved!.publicationState,
      );
      expect(reloaded.tokens, ['Come', 'stai']);
      expect(reloaded.orderAnswer, ['Come', 'stai']);
      expect(reloaded.evaluation.correctOrder, hasLength(2));
      expect(
        CourseAuditService()
            .auditExercise(reloaded)
            .where((issue) => issue.severity == AuditSeverity.error),
        isEmpty,
      );
    },
  );

  testWidgets('reloaded Build the translation is playable and evaluates', (
    tester,
  ) async {
    final exercise = Exercise(
      id: 'build-translation-runtime',
      type: 'build_translation',
      prompt: 'How are you?',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: const ['Come', 'stai'],
      orderAnswer: const ['Come stai?'],
      pairs: const [],
      hint: '',
      icons: const [],
    );
    final reloaded = Exercise.fromV2Json(
      exercise.toV2Json(),
      contentId: exercise.id,
      editorTemplate: exercise.editorTemplate,
      publicationState: exercise.publicationState,
    );
    expect(
      CourseAuditService()
          .auditExercise(reloaded)
          .where((issue) => issue.severity == AuditSeverity.error),
      isEmpty,
    );
    final round = LearningRound(
      id: 'round',
      title: 'Round',
      exercises: [reloaded],
    );
    final lesson = Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]);
    final course = _course(lesson);

    await tester.pumpWidget(
      MaterialApp(
        home: RoundScreen(
          course: course,
          lesson: lesson,
          round: round,
          ttsLanguage: course.ttsLanguage,
          roundIndex: 0,
          previewMode: true,
        ),
      ),
    );
    for (var frame = 0; frame < 100; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Come').evaluate().isNotEmpty) break;
    }
    await tester.tap(find.text('Come'));
    await tester.pump();
    await tester.tap(find.text('stai'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await tester.pump();
    expect(find.text('Correct'), findsOneWidget);
  });

  test('Build the translation retains blocking errors for missing data', () {
    final service = CourseAuditService();
    final missingBlocks = Exercise(
      id: 'missing-blocks',
      type: 'build_translation',
      prompt: 'How are you?',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const ['Come stai?'],
      pairs: const [],
      hint: '',
      icons: const [],
    );
    final missingTranslation = Exercise(
      id: 'missing-translation',
      type: 'build_translation',
      prompt: 'How are you?',
      question: '',
      answers: const [],
      correct: null,
      tts: null,
      accepted: const [],
      tokens: const ['Come', 'stai'],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );

    for (final exercise in [missingBlocks, missingTranslation]) {
      expect(
        service
            .auditExercise(exercise)
            .any((issue) => issue.severity == AuditSeverity.error),
        isTrue,
      );
    }
  });

  testWidgets('Missing Word Editor keeps both canonical answer views', (
    tester,
  ) async {
    Exercise? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<Exercise>(
                MaterialPageRoute(
                  builder: (_) => ExerciseEditorScreen(
                    exercise: _emptyExercise('missing_word'),
                    title: 'Missing Word',
                    isNew: false,
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Passage transcript'), 'Una casa.');
    await tester.enterText(_field('Audio text'), 'Una casa.');
    await tester.scrollUntilVisible(
      _field('Missing word(s)'),
      300,
      scrollable: _editorScroll(),
    );
    await tester.enterText(_field('Missing word(s)'), 'casa');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      400,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await tester.pumpAndSettle();

    expect(saved!.evaluation.kind, 'text_match');
    expect(saved!.evaluation.accepted, ['casa']);
    expect(saved!.missingWords, ['casa']);
  });

  testWidgets('Listening Spelling Editor omits incompatible missingWords', (
    tester,
  ) async {
    Exercise? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<Exercise>(
                MaterialPageRoute(
                  builder: (_) => ExerciseEditorScreen(
                    exercise: _emptyExercise('listening_spelling'),
                    title: 'Listening Spelling',
                    isNew: false,
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Passage transcript'), 'casa');
    await tester.enterText(_field('Audio text'), 'casa');
    await tester.enterText(_field('Missing word'), 'casa');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      400,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await tester.pumpAndSettle();

    expect(saved!.evaluation.kind, 'text_match');
    expect(saved!.evaluation.accepted, ['casa']);
    expect(saved!.missingWords, isEmpty);
  });
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _editorScroll() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Exercise _buildTranslation() => Exercise(
  id: 'build-translation-editor',
  publicationState: PublicationState.draft,
  type: 'build_translation',
  prompt: '',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _emptyExercise(String type) => Exercise(
  id: '$type-editor',
  publicationState: PublicationState.draft,
  type: type,
  prompt: '',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Course _course(Lesson lesson) => Course(
  courseId: 'course-225',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [lesson],
);
