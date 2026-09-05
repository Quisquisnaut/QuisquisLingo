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
      _useEditorViewport(tester);
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

      await tester.enterText(_field('Source sentence'), 'How are you?');
      await tester.enterText(
        _field('Available target-language blocks'),
        'Come\nstai\nva\nte\nla\npassi',
      );
      await tester.enterText(
        find.byKey(const ValueKey('build-translation-answer-0')),
        'Come stai?',
      );
      for (final answer in ['Come va?', 'Come te la passi?']) {
        await tester.tap(find.byKey(const Key('add-correct-translation')));
        await tester.pump();
        await tester.enterText(
          find.byKey(
            ValueKey(
              'build-translation-answer-${answer == 'Come va?' ? 1 : 2}',
            ),
          ),
          answer,
        );
      }
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
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
      expect(reloaded.tokens, ['Come', 'stai', 'va', 'te', 'la', 'passi']);
      expect(reloaded.orderAnswer, ['Come', 'stai']);
      expect(reloaded.correctTranslationTexts, [
        'Come stai?',
        'Come va?',
        'Come te la passi?',
      ]);
      expect(reloaded.evaluation.correctOrders, hasLength(3));
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
    _useEditorViewport(tester);
    final exercise = _playableBuildTranslation();
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
    await tester.tap(find.text('va'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await tester.pump();
    expect(find.text('Correct'), findsOneWidget);
    for (final answer in [
      '• Come stai?',
      '• Come va?',
      '• Come te la passi?',
    ]) {
      expect(find.text(answer), findsOneWidget);
    }
  });

  testWidgets('Build translation editor deletes and reorders literal answers', (
    tester,
  ) async {
    Exercise? saved;
    await _openExerciseEditor(tester, _playableBuildTranslation(), (value) {
      saved = value;
    });

    await tester.scrollUntilVisible(
      find.byTooltip('Delete correct translation 2'),
      300,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byTooltip('Delete correct translation 2'));
    await tester.pump();
    final list = tester.widget<ReorderableListView>(
      find.byKey(const Key('build-translation-correct-translations')),
    );
    list.onReorderItem!(1, 0);
    await tester.pump();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save')),
      400,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save')));
    await tester.pumpAndSettle();

    expect(saved?.correctTranslationTexts, ['Come te la passi?', 'Come stai?']);
  });

  testWidgets('normalized duplicate translations show field-level errors', (
    tester,
  ) async {
    await _openExerciseEditor(tester, _buildTranslation(), (_) {});
    await tester.enterText(
      _field('Available target-language blocks'),
      'Come\nstai',
    );
    await tester.enterText(
      find.byKey(const ValueKey('build-translation-answer-0')),
      'Come stai?',
    );
    await tester.tap(find.byKey(const Key('add-correct-translation')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('build-translation-answer-1')),
      '  come   stai. ',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      400,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await tester.pump();

    expect(
      find.text(
        'Duplicate after case, spacing and terminal punctuation normalization.',
      ),
      findsNWidgets(2),
    );
    expect(find.byType(ExerciseEditorScreen), findsOneWidget);
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
    _useEditorViewport(tester);
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
    _useEditorViewport(tester);
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

Exercise _playableBuildTranslation() => Exercise(
  id: 'build-translation-runtime',
  type: 'build_translation',
  prompt: 'How are you?',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const ['Come', 'stai', 'va', 'te', 'la', 'passi'],
  orderAnswer: const [],
  correctTranslations: const ['Come stai?', 'Come va?', 'Come te la passi?'],
  pairs: const [],
  hint: '',
  icons: const [],
);

Future<void> _openExerciseEditor(
  WidgetTester tester,
  Exercise exercise,
  ValueChanged<Exercise?> onClosed,
) async {
  _useEditorViewport(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () async => onClosed(
            await Navigator.of(context).push<Exercise>(
              MaterialPageRoute(
                builder: (_) => ExerciseEditorScreen(
                  exercise: exercise,
                  title: 'Build the translation',
                  isNew: false,
                ),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void _useEditorViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

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
