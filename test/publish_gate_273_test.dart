import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/publish_gate.dart';

import 'support/guidebook_fixtures.dart';

/// Build 273 Revision 1: `PublishGate`, the one owner of the check that
/// decides whether an item may be applied as normal content. The screens'
/// cases are in `publish_gate_screens_273_test` (written before the owner).
final _stamp = DateTime.utc(2026, 10, 15);

Exercise _choice(String id, {bool draft = false, int correct = 0}) => Exercise(
  id: id,
  publicationState: draft ? PublicationState.draft : PublicationState.published,
  updatedAt: _stamp,
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

Lesson _lesson(
  String id, {
  required List<Exercise> exercises,
  PublicationState state = PublicationState.draft,
  PublicationState roundState = PublicationState.draft,
}) => Lesson(
  lessonId: id,
  title: id,
  publicationState: state,
  updatedAt: _stamp,
  guidebook: testGuidebook(
    moduleId: '${id}_module',
    overview: 'Reviewed overview.',
    words: [testEntry('${id}_word', 'casa = house')],
  ),
  rounds: [
    LearningRound(
      id: '$id-round',
      title: '$id round',
      publicationState: roundState,
      updatedAt: _stamp,
      exercises: exercises,
    ),
  ],
);

Course _course(List<Lesson> lessons, {PublicationState? state}) => Course(
  courseId: 'publish-gate-owner-273',
  publicationState: state ?? PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Publish gate owner course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: lessons,
);

void main() {
  const gate = PublishGate();

  group('roundErrors', () {
    test('counts the Round\'s errors with the Course and Lesson Published', () {
      // The Course and the Lesson are Draft: without forcing them the learner
      // projection would hide the Round and find nothing.
      final course = _course([
        _lesson(
          'a',
          exercises: [_choice('a1'), _choice('a2', correct: 9)],
          roundState: PublicationState.published,
        ),
      ]);
      expect(gate.roundErrors(course, 'a', 'a-round'), 1);
    });

    test('a Draft exercise is not seen by learners and does not block', () {
      final course = _course([
        _lesson(
          'a',
          exercises: [_choice('a1'), _choice('a2', draft: true, correct: 9)],
          roundState: PublicationState.published,
        ),
      ]);
      expect(gate.roundErrors(course, 'a', 'a-round'), 0);
    });

    test('only the named Lesson is taken as Published', () {
      // Lesson b is Draft and holds a broken Round with the same ID as
      // Lesson a's: the Round Audit looks at every Lesson holding that ID,
      // so b would count if it were taken as Published too.
      Lesson withRound(String lessonId, Exercise exercise) => Lesson(
        lessonId: lessonId,
        title: lessonId,
        publicationState: PublicationState.draft,
        updatedAt: _stamp,
        guidebook: testGuidebook(
          moduleId: '${lessonId}_module',
          overview: 'Reviewed overview.',
          words: [testEntry('${lessonId}_word', 'casa = house')],
        ),
        rounds: [
          LearningRound(
            id: 'shared-round',
            title: 'Shared',
            publicationState: PublicationState.published,
            updatedAt: _stamp,
            exercises: [exercise],
          ),
        ],
      );
      final course = _course([
        withRound('a', _choice('a1')),
        withRound('b', _choice('b1', correct: 9)),
      ]);
      expect(gate.roundErrors(course, 'a', 'shared-round'), 0);
      expect(gate.roundErrors(course, 'b', 'shared-round'), greaterThan(0));
    });
  });

  group('lessonErrors', () {
    test('takes the Course as Published, not the Lesson', () {
      final draftLesson = _course([
        _lesson(
          'a',
          exercises: [_choice('a1', correct: 9)],
          roundState: PublicationState.published,
        ),
      ]);
      // The callers pass the Lesson already Published; a Draft one is
      // hidden from learners, so nothing is found.
      expect(gate.lessonErrors(draftLesson, 'a'), 0);
      final published = _course([
        _lesson(
          'a',
          exercises: [_choice('a1', correct: 9)],
          state: PublicationState.published,
          roundState: PublicationState.published,
        ),
      ]);
      expect(gate.lessonErrors(published, 'a'), 1);
    });

    test('another Lesson\'s errors do not count', () {
      final course = _course([
        _lesson(
          'a',
          exercises: [_choice('a1')],
          state: PublicationState.published,
          roundState: PublicationState.published,
        ),
        _lesson(
          'b',
          exercises: [_choice('b1', correct: 9)],
          state: PublicationState.published,
          roundState: PublicationState.published,
        ),
      ]);
      expect(gate.lessonErrors(course, 'a'), 0);
      expect(gate.lessonErrors(course, 'b'), 1);
    });
  });

  test('courseErrors audits the Course as given', () {
    final clean = _course([
      _lesson(
        'a',
        exercises: [_choice('a1')],
        state: PublicationState.published,
        roundState: PublicationState.published,
      ),
    ], state: PublicationState.published);
    expect(gate.courseErrors(clean), 0);
    final broken = _course([
      _lesson(
        'a',
        exercises: [_choice('a1', correct: 9)],
        state: PublicationState.published,
        roundState: PublicationState.published,
      ),
    ], state: PublicationState.published);
    expect(gate.courseErrors(broken), greaterThan(0));
  });

  test('exerciseIssues is the Audit of the exercise alone', () {
    final issues = gate.exerciseIssues(_choice('x', correct: 9));
    expect(PublishGate.errorsIn(issues), isNotEmpty);
    expect(
      PublishGate.errorsIn(
        issues,
      ).every((issue) => issue.severity == AuditSeverity.error),
      isTrue,
    );
    expect(PublishGate.errorsIn(gate.exerciseIssues(_choice('y'))), isEmpty);
    expect(
      PublishGate.warningCount(gate.exerciseIssues(_choice('y'))),
      CourseAuditService()
          .auditExercise(_choice('y'))
          .where((issue) => issue.severity == AuditSeverity.warning)
          .length,
    );
  });

  test('the refusals', () {
    expect(
      PublishGate.courseRefusal(1),
      'Course cannot be published: 1 blocking error.',
    );
    expect(
      PublishGate.courseRefusal(3),
      'Course cannot be published: 3 blocking errors.',
    );
    expect(
      PublishGate.refusal('Lesson', 1),
      'Lesson cannot be applied as normal content: 1 blocking error.',
    );
    expect(
      PublishGate.refusal('Round', 2),
      'Round cannot be applied as normal content: 2 blocking errors.',
    );
    expect(
      PublishGate.exerciseRefusal,
      'Exercise cannot be applied as normal content until its Errors are fixed.',
    );
  });
}
