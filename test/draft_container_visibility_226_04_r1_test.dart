import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  test('Course delivery alone is not an authoring Draft badge', () {
    final course = Course.fromJson({
      ..._course().toJson(),
      'publicationState': 'draft',
    });
    final status = AuthoringHierarchyStatus.fromCourse(course);
    expect(status.courseHasDraft, isFalse);
    expect(status.lessonHasDraft(course.lessons.single), isFalse);
  });

  test(
    'non-runnable canonical Draft Content propagates independently of Audit',
    () {
      final pending = LearningContent.textual(
        id: 'pending-text',
        kind: 'text',
        role: 'round_note',
        text: '',
        publicationState: PublicationState.draft,
      );
      expect(pending.asRunnableExercise(), isNull);
      final course = _course(content: [pending]);
      final lesson = course.lessons.single;
      final round = lesson.rounds.single;
      expect(round.exercises, isEmpty);
      final status = AuthoringHierarchyStatus.fromCourse(course);
      expect(status.roundHasDraft(round), isTrue);
      expect(status.lessonHasRoundDraft(lesson), isTrue);
      expect(status.lessonHasDraft(lesson), isTrue);
      expect(status.courseHasDraft, isTrue);
      expect(status.lessonGuidebookHasDraft(lesson), isFalse);
    },
  );

  for (final draftLesson in [true, false]) {
    final owner = draftLesson ? 'Lesson' : 'Round';
    test(
      'publishing the last own $owner Draft clears ancestors, isolates sibling',
      () {
        final affected = _course(
          lessonState: draftLesson
              ? PublicationState.draft
              : PublicationState.published,
          roundState: draftLesson
              ? PublicationState.published
              : PublicationState.draft,
        );
        final sibling = Lesson(
          lessonId: 'clean-sibling',
          title: 'Clean sibling',
          rounds: [
            LearningRound(
              id: 'sibling-round',
              title: '',
              exercises: [_exercise(99)],
            ),
          ],
        );
        final course = Course.fromJson({
          ...affected.toJson(),
          'lessons': [affected.lessons.single.toJson(), sibling.toJson()],
        });
        final before = AuthoringHierarchyStatus.fromCourse(course);
        expect(before.courseHasDraft, isTrue);
        expect(before.lessonHasDraft(course.lessons.first), isTrue);
        expect(before.lessonHasDraft(course.lessons.last), isFalse);
        expect(before.hasCourseAuditConcern, isFalse);
        final editedLesson = course.lessons.first.toJson();
        if (draftLesson) {
          editedLesson['publicationState'] = 'published';
        } else {
          (editedLesson['rounds'] as List).single['publicationState'] =
              'published';
        }
        final afterCourse = Course.fromJson({
          ...course.toJson(),
          'lessons': [editedLesson, course.lessons.last.toJson()],
        });
        final after = AuthoringHierarchyStatus.fromCourse(afterCourse);
        expect(after.courseHasDraft, isFalse);
        expect(after.lessonHasDraft(afterCourse.lessons.first), isFalse);
        expect(after.hasCourseAuditConcern, isFalse);
        expect(afterCourse.lessons.last.toJson(), course.lessons.last.toJson());
        expect(
          afterCourse.lessons.first.lessonId,
          course.lessons.first.lessonId,
        );
        expect(
          afterCourse.lessons.first.rounds.single.id,
          course.lessons.first.rounds.single.id,
        );
      },
    );

    testWidgets(
      'own $owner Draft is visible through Manager and Editor hierarchy',
      (tester) async {
        _viewport(tester);
        final course = _course(
          lessonState: draftLesson
              ? PublicationState.draft
              : PublicationState.published,
          roundState: draftLesson
              ? PublicationState.published
              : PublicationState.draft,
        );
        final lesson = course.lessons.single;
        final round = lesson.rounds.single;
        final audit = CourseAuditService().auditCourse(course);
        expect(
          audit.issues.where((issue) => issue.severity != AuditSeverity.info),
          isEmpty,
        );
        await CourseEditorService().saveUserCourse(course);
        await SettingsService().setLastSelectedCourseCode(
          'custom:${course.courseId}',
        );
        await SettingsService().setCourseEditorLocked(course.courseId, false);
        await SettingsService().markAudioOrphanCheckRun(
          CourseService.codeForCourse(course),
        );

        await _mount(tester, CourseProjectsScreen(currentCourse: course));
        _expectStatus(
          tester,
          'course-manager-status-container-course',
          draft: true,
        );
        await _mount(
          tester,
          CourseEditorScreen(course: course, userCourse: true),
        );
        _expectStatus(tester, 'course-lessons-status-indicator', draft: true);
        await _mount(
          tester,
          LessonManagementScreen(course: course, initiallyLocked: false),
        );
        _expectStatus(
          tester,
          'lesson-status-indicator-container-lesson',
          draft: true,
        );
        await _mount(
          tester,
          LessonEditorScreen(course: course, lesson: lesson),
        );
        expect(
          find.byKey(const Key('lesson-own-draft-indicator')),
          draftLesson ? findsOneWidget : findsNothing,
        );
        _expectStatus(
          tester,
          'lesson-rounds-status-indicator',
          draft: !draftLesson,
        );
        _expectStatus(
          tester,
          'lesson-guidebook-status-indicator',
          draft: false,
        );
        await _mount(
          tester,
          LessonRoundsScreen(course: course, lesson: lesson),
        );
        _expectStatus(
          tester,
          'round-status-indicator-container-round',
          draft: !draftLesson,
        );
        await _mount(
          tester,
          RoundEditorScreen(
            course: course,
            lesson: lesson,
            round: round,
            roundIndex: 0,
          ),
        );
        expect(
          find.byKey(const Key('round-own-draft-indicator')),
          draftLesson ? findsNothing : findsOneWidget,
        );
        for (final exercise in round.exercises) {
          expect(
            find.byKey(ValueKey('exercise-draft-indicator-${exercise.id}')),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final state in PublicationState.values) {
    testWidgets(
      'explicit ${state.name} empty Round keeps canonical red independent of Draft',
      (tester) async {
        _viewport(tester);
        final course = _course(roundState: state, content: const []);
        final lesson = course.lessons.single;
        final result = CourseAuditService().auditRound(
          course,
          lesson.rounds.single.id,
        );
        expect(result.issues.map((issue) => issue.code), [
          'ROUND_CONTENT_EMPTY',
        ]);
        expect(result.issues.single.severity, AuditSeverity.error);
        final hasDraft = state == PublicationState.draft;
        final status = AuthoringHierarchyStatus.fromCourse(course);
        expect(status.courseHasDraft, hasDraft);
        expect(status.lessonHasDraft(lesson), hasDraft);
        expect(status.lessonGuidebookHasDraft(lesson), isFalse);
        await _mount(
          tester,
          LessonRoundsScreen(course: course, lesson: lesson),
        );
        expect(find.text('0 Exercises'), findsOneWidget);
        _expectStatus(
          tester,
          'round-status-indicator-container-round',
          draft: hasDraft,
          auditConcern: true,
        );
        expect(find.text('Draft'), hasDraft ? findsOneWidget : findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _expectStatus(
  WidgetTester tester,
  String key, {
  required bool draft,
  bool auditConcern = false,
}) {
  final statuses = tester.widgetList<AuthoringStatusCard>(
    find.byWidgetPredicate(
      (widget) =>
          widget is AuthoringStatusCard && widget.indicatorKey == ValueKey(key),
    ),
  );
  expect(statuses, isNotEmpty, reason: key);
  // Manager can show the same Course in both current and local lists. Verify
  // every rendered instance without assuming that its stable key is unique
  // across those separate lists.
  for (final status in statuses) {
    expect(status.hasDraft, draft, reason: key);
    expect(status.hasAuditConcern, auditConcern, reason: key);
    final instance = find.byWidget(status);
    expect(
      find.descendant(
        of: instance,
        matching: find.byKey(status.draftIndicatorKey),
      ),
      draft ? findsOneWidget : findsNothing,
    );
    final card = tester.widget<Card>(
      find.descendant(of: instance, matching: find.byType(Card)).first,
    );
    expect(
      (card.shape! as RoundedRectangleBorder).side.color,
      auditConcern ? const Color(0xFFC90000) : const Color(0xFF00A83B),
    );
  }
}

Future<void> _mount(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void _viewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Course _course({
  PublicationState lessonState = PublicationState.published,
  PublicationState roundState = PublicationState.published,
  List<LearningContent>? content,
}) => Course(
  courseId: 'container-course',
  title: 'Container publication',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  version: '1',
  useGuidebook: false,
  createDuels: false,
  lessons: [
    Lesson(
      lessonId: 'container-lesson',
      title: 'Greetings',
      publicationState: lessonState,
      rounds: [
        LearningRound(
          id: 'container-round',
          title: '',
          publicationState: roundState,
          content:
              content ??
              [
                for (var index = 0; index < 3; index++)
                  LearningContent.fromExercise(_exercise(index)),
              ],
        ),
      ],
    ),
  ],
);

Exercise _exercise(int index) => Exercise(
  id: 'container-exercise-$index',
  type: 'choice',
  prompt: 'choose a response',
  question: 'response $index?',
  answers: const ['ciao', 'grazie'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
