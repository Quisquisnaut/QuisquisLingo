import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_editor_search_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ownerId = '00000000-0000-4000-8000-000000002311';
const _otherId = '00000000-0000-4000-8000-000000002312';
final _updatedAt = DateTime.utc(2026, 9, 12, 10);

Exercise _choiceExercise({String id = 'revision1_choice'}) => Exercise(
  id: id,
  updatedAt: _updatedAt,
  type: 'choice',
  prompt: 'Come stai oggi?',
  question: 'How are you?',
  answers: const ['Bene', 'Male'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _contextExercise() => Exercise(
  id: 'revision1_context',
  updatedAt: _updatedAt,
  type: 'contextual_comprehension',
  prompt: 'A visible context.',
  question: 'What happened?',
  answers: const ['One', 'Two'],
  correct: 0,
  tts: 'A spoken context.',
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _buildTranslationExercise() => Exercise(
  id: 'revision1_build',
  updatedAt: _updatedAt,
  type: 'build_translation',
  prompt: 'How are you?',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const ['Come', 'stai'],
  orderAnswer: const [],
  correctTranslations: const ['Come stai?', 'Come va?'],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _scriptExercise() => Exercise.v2(
  id: 'revision1_script',
  updatedAt: _updatedAt,
  editorTemplate: 'script_recognition',
  promptElements: const [PromptElement(type: 'image', asset: '')],
  interaction: const ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'script-a',
        content: [PromptElement(type: 'text', text: 'ga')],
      ),
      ExerciseItem(
        id: 'script-b',
        content: [PromptElement(type: 'text', text: 'na')],
      ),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    correctItemIds: ['script-a'],
  ),
);

Course _course(Exercise exercise, {String courseId = 'qql231_r1_course'}) =>
    Course(
      courseId: courseId,
      originalCourseCreator: CourseProvenanceIdentity.qqlUser(
        profileId: _ownerId,
        displayName: 'Original Course Creator',
      ),
      maintainer: const CourseMaintainer(_ownerId),
      originType: CourseOriginType.custom,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'QQL 231 revision 1',
      ttsLanguage: 'it-IT',
      lessons: [
        Lesson(
          lessonId: 'revision1_lesson',
          updatedAt: _updatedAt,
          title: 'Everyday Italian',
          rounds: [
            LearningRound(
              id: 'revision1_round',
              updatedAt: _updatedAt,
              title: 'Greetings',
              exercises: [exercise],
            ),
          ],
        ),
      ],
    );

Future<void> _setProfile([String profileId = _ownerId]) async {
  SharedPreferences.setMockInitialValues({
    ProfileService.profilesKey: [
      LearnerProfile(learnerProfileId: _ownerId, displayName: 'Owner').encode(),
      LearnerProfile(learnerProfileId: _otherId, displayName: 'Other').encode(),
    ],
    ProfileService.activeProfileIdKey: profileId,
  });
  EditorDisplayPreferences.resetForTesting();
}

Future<void> _pumpExercise(
  WidgetTester tester,
  Exercise exercise, {
  required bool readOnly,
  bool initiallyInspecting = false,
}) async {
  final course = _course(exercise);
  await tester.pumpWidget(
    MaterialApp(
      home: ExerciseEditorScreen(
        key: ValueKey('${exercise.id}-$readOnly-$initiallyInspecting'),
        exercise: exercise,
        title: readOnly ? 'View exercise' : 'Edit exercise',
        isNew: false,
        course: course,
        lesson: course.lessons.single,
        round: course.lessons.single.rounds.single,
        readOnly: readOnly,
        initiallyInspecting: initiallyInspecting,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _showInspectionToggle(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('exercise-inspection-toggle')),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollExerciseToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
  await tester.pumpAndSettle();
}

IconData _accessIcon(WidgetTester tester) => tester
    .widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('course-editor-lock')),
        matching: find.byType(Icon),
      ),
    )
    .icon!;

Future<void> _selectMode(WidgetTester tester, CourseEditorMode mode) async {
  await tester.tap(find.byKey(const Key('course-editor-lock')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode.label));
  await tester.pumpAndSettle();
}

void main() {
  setUp(_setProfile);

  testWidgets('Course Editor exposes and persists all four access states', (
    tester,
  ) async {
    final course = _course(_choiceExercise());
    final settings = SettingsService();
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: _ownerId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_accessIcon(tester), Icons.visibility_outlined);
    await tester.tap(find.byKey(const Key('course-editor-lock')));
    await tester.pumpAndSettle();
    expect(find.text('Locked'), findsOneWidget);
    expect(find.text('View only'), findsOneWidget);
    expect(find.text('Inspection mode'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Inspection mode'));
    await tester.pumpAndSettle();
    expect(_accessIcon(tester), Icons.code);
    expect(
      await settings.getCourseEditorMode(course.courseId),
      CourseEditorMode.inspection,
    );

    await _selectMode(tester, CourseEditorMode.edit);
    expect(_accessIcon(tester), Icons.edit_outlined);
    await _selectMode(tester, CourseEditorMode.locked);
    expect(_accessIcon(tester), Icons.lock_outline);
    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await tester.pumpAndSettle();
    expect(find.text('Course Editor is locked'), findsOneWidget);
    expect(find.byKey(const Key('lessons-search-action')), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await _selectMode(tester, CourseEditorMode.viewOnly);
    expect(_accessIcon(tester), Icons.visibility_outlined);
    expect(
      await settings.getCourseEditorMode(course.courseId),
      CourseEditorMode.viewOnly,
    );

    await (await SharedPreferences.getInstance()).setString(
      ProfileService.activeProfileIdKey,
      _otherId,
    );
    expect(
      await settings.getCourseEditorMode(course.courseId),
      CourseEditorMode.viewOnly,
    );
  });

  testWidgets('leaving Edit protects unapplied course changes', (tester) async {
    final course = _course(_choiceExercise(), courseId: 'dirty_mode_switch');
    final settings = SettingsService();
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: _ownerId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _selectMode(tester, CourseEditorMode.edit);

    await tester.tap(find.text('Unpublish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not published'));
    await tester.pumpAndSettle();

    await _selectMode(tester, CourseEditorMode.viewOnly);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(_accessIcon(tester), Icons.edit_outlined);
    expect(
      await settings.getCourseEditorMode(course.courseId),
      CourseEditorMode.edit,
    );

    await _selectMode(tester, CourseEditorMode.inspection);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('cancel-course-changes')));
    await tester.pumpAndSettle();
    expect(_accessIcon(tester), Icons.code);
    expect(
      await settings.getCourseEditorMode(course.courseId),
      CourseEditorMode.inspection,
    );
    expect(find.text('Published'), findsOneWidget);
  });

  testWidgets('View only uses the normal form without text or image mutation', (
    tester,
  ) async {
    await _pumpExercise(tester, _choiceExercise(), readOnly: true);
    expect(find.byKey(const Key('exercise-read-only-notice')), findsOneWidget);
    expect(
      find.byKey(const Key('exercise-inspection-presentation')),
      findsNothing,
    );

    final prompt = find.byKey(const Key('exercise-field-prompt'));
    expect(tester.widget<TextField>(prompt).readOnly, isTrue);
    await tester.tap(prompt);
    await tester.enterText(prompt, 'Changed without permission');
    await tester.pump();
    expect(
      tester.widget<TextField>(prompt).controller!.text,
      'Come stai oggi?',
    );

    await tester.scrollUntilVisible(
      find.text('Choose flat image'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Choose flat image'),
          )
          .onPressed,
      isNull,
    );
    await _showInspectionToggle(tester);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('exercise-preview')))
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('exercise-save')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved Exercise changes'), findsNothing);
  });

  testWidgets(
    'View only disables selector, toggle, add, remove and reorder families',
    (tester) async {
      await _pumpExercise(tester, _contextExercise(), readOnly: true);
      final contextMode = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('context-mode-selector')),
      );
      expect(contextMode.onChanged, isNull);

      await _pumpExercise(tester, _buildTranslationExercise(), readOnly: true);
      await tester.scrollUntilVisible(
        find.byKey(const Key('add-correct-translation')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('add-correct-translation')),
            )
            .onPressed,
        isNull,
      );
      final deleteTranslation = find.ancestor(
        of: find.byTooltip('Delete correct translation 1'),
        matching: find.byType(IconButton),
      );
      expect(tester.widget<IconButton>(deleteTranslation).onPressed, isNull);
      expect(find.byType(ReorderableDragStartListener), findsNothing);

      await _pumpExercise(tester, _scriptExercise(), readOnly: true);
      expect(
        tester
            .widget<DropdownButtonFormField>(
              find.byKey(const ValueKey('script-mode')),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('script-correct-0')))
            .onPressed,
        isNull,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('script-add-option')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('script-add-option')))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('View and Inspection defaults keep the local toggle read-only', (
    tester,
  ) async {
    await _pumpExercise(tester, _choiceExercise(), readOnly: true);
    await _showInspectionToggle(tester);
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const Key('exercise-inspection-toggle')),
          )
          .selected,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('exercise-inspection-toggle')));
    await tester.pumpAndSettle();
    await _scrollExerciseToTop(tester);
    expect(
      find.byKey(const Key('exercise-inspection-presentation')),
      findsOneWidget,
    );
    await _showInspectionToggle(tester);
    await tester.tap(find.byKey(const Key('exercise-inspection-toggle')));
    await tester.pumpAndSettle();
    await _scrollExerciseToTop(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('exercise-field-prompt')))
          .readOnly,
      isTrue,
    );

    await _pumpExercise(
      tester,
      _choiceExercise(),
      readOnly: true,
      initiallyInspecting: true,
    );
    expect(
      find.byKey(const Key('exercise-inspection-presentation')),
      findsOneWidget,
    );
    await _showInspectionToggle(tester);
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const Key('exercise-inspection-toggle')),
          )
          .selected,
      isTrue,
    );
    await tester.tap(find.byKey(const Key('exercise-inspection-toggle')));
    await tester.pumpAndSettle();
    await _scrollExerciseToTop(tester);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('exercise-field-prompt')))
          .readOnly,
      isTrue,
    );
    await _showInspectionToggle(tester);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('exercise-save')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Edit preserves dirty form state across Inspection round trip', (
    tester,
  ) async {
    await _pumpExercise(tester, _choiceExercise(), readOnly: false);
    final prompt = find.byKey(const Key('exercise-field-prompt'));
    expect(tester.widget<TextField>(prompt).readOnly, isFalse);
    await tester.enterText(prompt, 'Unsaved editor text');
    await tester.pump();
    await _showInspectionToggle(tester);
    await tester.tap(find.byKey(const Key('exercise-inspection-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('exercise-inspection-presentation')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('exercise-save')))
          .onPressed,
      isNull,
    );

    await _showInspectionToggle(tester);
    await tester.tap(find.byKey(const Key('exercise-inspection-toggle')));
    await tester.pumpAndSettle();
    await _scrollExerciseToTop(tester);
    expect(
      tester.widget<TextField>(prompt).controller!.text,
      'Unsaved editor text',
    );
    expect(tester.widget<TextField>(prompt).readOnly, isFalse);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved Exercise changes'), findsOneWidget);
  });

  testWidgets('Search opens the state-specific exercise presentation', (
    tester,
  ) async {
    final course = _course(_choiceExercise(id: 'search_revision1'));
    final settings = SettingsService();
    await settings.markCourseEditorViewNoticeSeen(course.courseId);

    for (final mode in const [
      CourseEditorMode.viewOnly,
      CourseEditorMode.inspection,
      CourseEditorMode.edit,
    ]) {
      await settings.setCourseEditorMode(course.courseId, mode);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: course,
            access: CourseAccessPolicy.evaluate(course, profileId: _ownerId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lessons-search-action')));
      await tester.pumpAndSettle();
      expect(find.byType(CourseEditorSearchScreen), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('course-editor-search-query')),
        'oggi',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('course-editor-search-result-search_revision1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      expect(
        find.byKey(const Key('exercise-inspection-presentation')),
        mode == CourseEditorMode.inspection ? findsOneWidget : findsNothing,
      );
      if (mode != CourseEditorMode.inspection) {
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('exercise-field-prompt')))
              .readOnly,
          mode != CourseEditorMode.edit,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Create Duels guidance omits the unnecessary qualifier', (
    tester,
  ) async {
    final course = _course(_choiceExercise());
    await tester.pumpWidget(
      MaterialApp(
        home: LessonManagementScreen(course: course, initiallyLocked: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('course-create-duels')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(
        'When enough eligible Exercises are available, winning a Duel unlocks the next Lesson without completing the preceding Lesson.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('without normally completing'), findsNothing);
  });
}
