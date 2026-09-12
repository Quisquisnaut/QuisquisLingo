import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  test(
    'missing Exercise source reference belongs to every canonical ancestor',
    () {
      final exercise = _choice('exercise-source');
      final course = _course(
        content: [
          LearningContent(
            id: exercise.id,
            kind: 'exercise',
            exercise: exercise,
            sourceRefs: const ['missing-guide-content'],
          ),
        ],
      );
      final lesson = course.lessons.single;
      final round = lesson.rounds.single;
      final audit = CourseAuditService();
      final issue = audit
          .auditCourse(course)
          .issues
          .singleWhere((issue) => issue.code == 'SOURCE_REF_MISSING');

      expect(issue.severity, AuditSeverity.error);
      expect(issue.roundId, round.id);
      expect(issue.exerciseId, exercise.id);
      expect(issue.updatedAt, exercise.updatedAt);
      expect(
        issue.location,
        'Lesson 1 · Reviewed lesson · Practice · Content 1',
      );
      expect(
        _concerns(
          audit.auditRound(course, round.id),
        ).map((issue) => issue.code),
        ['SOURCE_REF_MISSING'],
      );
      expect(
        _concerns(
          audit.auditLesson(course, lesson.lessonId),
        ).map((issue) => issue.code),
        ['SOURCE_REF_MISSING'],
      );
      final status = AuthoringHierarchyStatus.fromCourse(course);
      expect(status.exerciseHasAuditConcern(exercise), isTrue);
      expect(status.roundHasAuditConcern(round), isTrue);
      expect(status.lessonHasRoundAuditConcern(lesson), isTrue);
      expect(status.lessonHasAuditConcern(lesson), isTrue);
      expect(status.hasLessonsAuditConcern, isTrue);
      expect(status.hasCourseAuditConcern, isTrue);
    },
  );

  test('runnable presentation source references retain Exercise ownership', () {
    final course = _course(
      content: const [
        LearningContent(
          id: 'round-note',
          kind: 'text',
          role: 'round_note',
          text: 'Reviewed learning material.',
          sourceRefs: ['missing-guide-content'],
        ),
      ],
    );
    final round = course.lessons.single.rounds.single;
    final issue = CourseAuditService()
        .auditRound(course, round.id)
        .issues
        .singleWhere((issue) => issue.code == 'SOURCE_REF_MISSING');
    expect(issue.exerciseId, round.exercises.single.id);
    expect(
      AuthoringHierarchyStatus.fromCourse(
        course,
      ).exerciseHasAuditConcern(round.exercises.single),
      isTrue,
    );
  });

  test(
    'Lesson intro source references belong to the Round without a fake Exercise',
    () {
      final course = _course(
        content: const [
          LearningContent(
            id: 'lesson-intro',
            kind: 'text',
            role: 'lesson_intro',
            text: 'Reviewed introduction.',
            sourceRefs: ['missing-guide-content'],
          ),
        ],
      );
      final round = course.lessons.single.rounds.single;
      final issue = CourseAuditService()
          .auditRound(course, round.id)
          .issues
          .singleWhere((issue) => issue.code == 'SOURCE_REF_MISSING');
      expect(issue.roundId, round.id);
      expect(issue.exerciseId, isNull);
      expect(round.exercises, isEmpty);
      expect(
        AuthoringHierarchyStatus.fromCourse(course).roundHasAuditConcern(round),
        isTrue,
      );
    },
  );

  test('Guidebook source references remain outside the Rounds branch', () {
    final course = _course(
      guidebook: Guidebook(
        content: const [
          LearningContent(
            id: 'guide-content',
            kind: 'explanation',
            role: 'overview',
            text: 'Reviewed overview.',
            sourceRefs: ['missing-guide-content'],
          ),
        ],
      ),
    );
    final lesson = course.lessons.single;
    final issue = CourseAuditService()
        .auditLesson(course, lesson.lessonId)
        .issues
        .singleWhere((issue) => issue.code == 'SOURCE_REF_MISSING');
    expect(issue.roundId, isNull);
    expect(issue.exerciseId, isNull);
    final status = AuthoringHierarchyStatus.fromCourse(course);
    expect(status.lessonHasAuditConcern(lesson), isTrue);
    expect(status.lessonHasRoundAuditConcern(lesson), isFalse);
    expect(status.roundHasAuditConcern(lesson.rounds.single), isFalse);
  });

  test(
    'Round titles resembling Guidebook locations do not color the Guidebook branch',
    () {
      for (final title in [
        'Guidebook',
        'Guidebook practice',
        'Guidebook Content 1',
      ]) {
        for (final empty in [false, true]) {
          final course = _course(
            roundTitle: title,
            content: empty
                ? []
                : [
                    LearningContent.fromExercise(
                      _choice('invalid-answer', correct: 99),
                    ),
                  ],
          );
          final lesson = course.lessons.single;
          final round = lesson.rounds.single;
          expect(
            _concerns(CourseAuditService().auditRound(course, round.id)),
            isNotEmpty,
          );
          final status = AuthoringHierarchyStatus.fromCourse(course);
          expect(status.roundHasAuditConcern(round), isTrue);
          expect(status.lessonHasRoundAuditConcern(lesson), isTrue);
          expect(status.lessonHasAuditConcern(lesson), isTrue);
          expect(status.hasLessonsAuditConcern, isTrue);
          expect(
            status.lessonGuidebookHasAuditConcern(lesson),
            isFalse,
            reason:
                'Round "$title" must not be mistaken for Guidebook Content.',
          );
        }
      }
    },
  );

  test('valid references and three valid Exercises leave only Lesson Info', () {
    final course = _course(
      content: [
        for (var index = 0; index < 3; index++)
          LearningContent(
            id: 'exercise-$index',
            kind: 'exercise',
            exercise: _choice('exercise-$index'),
            sourceRefs: const ['guide-content'],
          ),
      ],
    );
    final lesson = course.lessons.single;
    final audit = CourseAuditService().auditLesson(course, lesson.lessonId);
    expect(_concerns(audit), isEmpty);
    expect(
      audit.issues.map((issue) => issue.code),
      unorderedEquals([
        'LESSON_ROUND_GUIDANCE',
        'LESSON_INTRO_MISSING',
        'DUEL_UNAVAILABLE',
      ]),
    );
    final status = AuthoringHierarchyStatus.fromCourse(course);
    expect(status.lessonHasAuditConcern(lesson), isFalse);
    expect(status.lessonHasRoundAuditConcern(lesson), isFalse);
    expect(status.hasLessonsAuditConcern, isFalse);
    expect(status.hasCourseAuditConcern, isFalse);
    expect(AuditCode.values, hasLength(101));
  });

  test(
    'empty Guidebook keeps Lesson red while its three valid Exercises are green',
    () {
      for (final state in PublicationState.values) {
        final course = _course(
          guidebook: Guidebook.empty(),
          content: [
            for (var index = 0; index < 3; index++)
              LearningContent.fromExercise(
                _choice('exercise-$index', state: state),
              ),
          ],
        );
        final lesson = course.lessons.single;
        final concerns = _concerns(
          CourseAuditService().auditLesson(course, lesson.lessonId),
        );
        expect(concerns.map((issue) => issue.code), ['LESSON_GUIDEBOOK_EMPTY']);
        expect(concerns.single.severity, AuditSeverity.warning);
        final status = AuthoringHierarchyStatus.fromCourse(course);
        expect(status.lessonHasAuditConcern(lesson), isTrue);
        expect(status.hasLessonsAuditConcern, isTrue);
        expect(status.roundHasAuditConcern(lesson.rounds.single), isFalse);
        expect(
          lesson.rounds.single.exercises.any(status.exerciseHasAuditConcern),
          isFalse,
        );
        expect(status.courseHasDraft, state == PublicationState.draft);
      }
    },
  );

  test('Course metadata concern does not belong to the Lessons link', () {
    final course = Course.fromJson({
      ..._course().toJson(),
      'courseDescription': List.filled(5001, 'x').join(),
    });
    final concerns = _concerns(CourseAuditService().auditCourse(course));
    expect(concerns.map((issue) => issue.code), ['COURSE_DESCRIPTION_LONG']);
    final status = AuthoringHierarchyStatus.fromCourse(course);
    expect(status.hasCourseAuditConcern, isTrue);
    expect(status.hasLessonsAuditConcern, isFalse);
  });

  test('empty Course Lessons branch preserves its canonical severity', () {
    final course = Course.fromJson({
      ..._course().toJson(),
      'lessons': <Object>[],
    });
    final audit = CourseAuditService().auditCourse(course);
    final issue = audit.issues.singleWhere(
      (issue) => issue.code == 'COURSE_LESSONS_EMPTY',
    );
    final status = AuthoringHierarchyStatus.fromCourse(course);
    expect(issue.severity, AuditSeverity.warning);
    expect(status.hasLessonsAuditConcern, isTrue);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'Info-only, stale and unavailable Audit borders in ${brightness.name}',
      (tester) async {
        final status = AuthoringHierarchyStatus.fromCourse(_course());
        final hasConcern = status.hasLessonsAuditConcern;
        expect(hasConcern, isFalse);
        Future<void> render(bool? concern) => tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(
              body: AuthoringStatusCard(
                indicatorKey: const Key('audit-border'),
                draftIndicatorKey: const Key('draft-badge'),
                hasDraft: true,
                hasAuditConcern: concern,
                child: const Text('Lesson branch'),
              ),
            ),
          ),
        );
        BorderSide border() =>
            (tester.widget<Card>(find.byType(Card)).shape!
                    as RoundedRectangleBorder)
                .side;

        await render(hasConcern);
        expect(
          border().color,
          brightness == Brightness.dark
              ? const Color(0xFF5CFF85)
              : const Color(0xFF00A83B),
        );
        expect(find.byKey(const Key('draft-badge')), findsOneWidget);
        await render(null); // A previously current result has become stale.
        expect(border(), BorderSide.none);
        expect(
          find.byTooltip(
            'Audit status is not current; no red or green border is shown. Blue Draft indicator: this branch contains authored Draft content hidden from learner delivery.',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await render(
          null,
        ); // No result has ever been available for this widget.
        expect(border(), BorderSide.none);
        expect(find.byKey(const Key('draft-badge')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

List<CourseAuditIssue> _concerns(CourseAuditResult result) => result.issues
    .where(
      (issue) =>
          issue.severity == AuditSeverity.error ||
          issue.severity == AuditSeverity.warning,
    )
    .toList();

Course _course({
  List<LearningContent>? content,
  Guidebook? guidebook,
  String roundTitle = 'Practice',
}) => Course(
  courseId: 'branch-ownership-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Branch ownership',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'reviewed-lesson',
      title: 'Reviewed lesson',
      updatedAt: DateTime.utc(2026, 9, 4),
      guidebook:
          guidebook ??
          Guidebook(
            content: [
              LearningContent.textual(
                id: 'guide-content',
                kind: 'explanation',
                role: 'overview',
                text: 'Reviewed overview.',
              ),
            ],
          ),
      rounds: [
        LearningRound(
          id: 'practice-round',
          title: roundTitle,
          updatedAt: DateTime.utc(2026, 9, 5),
          content:
              content ??
              [
                for (var index = 0; index < 3; index++)
                  LearningContent.fromExercise(_choice('exercise-$index')),
              ],
        ),
      ],
    ),
  ],
);

Exercise _choice(
  String id, {
  PublicationState state = PublicationState.published,
  int correct = 0,
}) => Exercise(
  id: id,
  publicationState: state,
  updatedAt: DateTime.utc(2026, 9, 6),
  type: 'choice',
  prompt: 'Choose the greeting.',
  question: 'How are you in exercise $id?',
  answers: const ['well', 'badly'],
  correct: correct,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
