import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_report_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  final audit = CourseAuditService();

  group('Reading Comprehension passage length', () {
    for (final entry in <String, (String, AuditSeverity?, String?)>{
      'empty': ('', AuditSeverity.error, 'READING_PASSAGE_REQUIRED'),
      'punctuation only': (
        '... — !!!',
        AuditSeverity.error,
        'READING_PASSAGE_REQUIRED',
      ),
      'one word': ('Ciao!', AuditSeverity.warning, 'READING_PASSAGE_TOO_SHORT'),
      'two words': (
        '«Ciao, Áine!»',
        AuditSeverity.warning,
        'READING_PASSAGE_TOO_SHORT',
      ),
      'three words': ('Ciao cara Áine.', null, null),
      'Unicode and apostrophes': ('L’été d’Áine arrive.', null, null),
    }.entries) {
      test(entry.key, () {
        final issues = audit.auditExercise(_reading(entry.value.$1));
        if (entry.value.$3 == null) {
          expect(
            issues.where(
              (issue) =>
                  issue.code == 'READING_PASSAGE_REQUIRED' ||
                  issue.code == 'READING_PASSAGE_TOO_SHORT',
            ),
            isEmpty,
          );
        } else {
          expect(
            issues,
            contains(
              isA<CourseAuditIssue>()
                  .having((issue) => issue.code, 'code', entry.value.$3)
                  .having(
                    (issue) => issue.severity,
                    'severity',
                    entry.value.$2,
                  ),
            ),
          );
        }
      });
    }

    test('exported report includes the stable short-passage finding', () {
      final course = _course(
        rounds: [
          LearningRound(
            id: 'short-round',
            updatedAt: DateTime.utc(2026, 9, 4, 10),
            title: '',
            exercises: [_reading('Due parole')],
          ),
        ],
      );
      final report =
          CourseAuditReportService(
            clock: () => DateTime.utc(2026, 9, 4, 12),
          ).buildReport(
            course: course,
            result: audit.auditCourse(course),
            scope: 'Course Audit',
            sortMode: AuditSortMode.recentlyModified,
          );
      expect(report, contains('READING_PASSAGE_TOO_SHORT'));
      expect(report, contains('Warning 1 of'));
      expect(report, contains('Round: Round 1 (short-round)'));
    });
  });

  test('missing Listening Comprehension is not itself an Audit issue', () {
    final course = _course(
      rounds: [
        LearningRound(
          id: 'choice-round',
          updatedAt: DateTime.utc(2026, 9, 4),
          title: '',
          exercises: [_choice('ordinary-choice')],
        ),
      ],
    );
    final issues = audit.auditCourse(course).issues;
    expect(
      issues.where(
        (issue) =>
            issue.message.toLowerCase().contains('without listening') ||
            issue.code.toLowerCase().contains('listening_missing'),
      ),
      isEmpty,
    );
  });

  test('malformed Listening exercises retain the blocking audio check', () {
    final exercise = Exercise(
      id: 'silent-listening',
      updatedAt: DateTime.utc(2026, 9, 4),
      type: 'listening_choice',
      prompt: '',
      question: 'Which expression do you hear?',
      answers: const ['Ciao', 'Grazie'],
      correct: 0,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
    expect(
      audit.auditExercise(exercise),
      contains(
        isA<CourseAuditIssue>()
            .having((issue) => issue.code, 'code', 'LISTENING_AUDIO_REQUIRED')
            .having((issue) => issue.severity, 'severity', AuditSeverity.error),
      ),
    );
  });

  test('Hints warn when repetitive and block when revealing', () {
    final repeated = _choice(
      'repeat',
      prompt: 'Translate this',
      hint: ' translate this! ',
    );
    final revealing = _choice('reveal', hint: 'Correct');
    final useful = _choice(
      'useful',
      hint: 'Think about the greeting used at noon.',
    );

    expect(
      audit.auditExercise(repeated).map((issue) => issue.code),
      contains('HINT_REPEATS_PROMPT'),
    );
    expect(
      audit.auditExercise(revealing),
      contains(
        isA<CourseAuditIssue>()
            .having((issue) => issue.code, 'code', 'HINT_REVEALS_ANSWER')
            .having((issue) => issue.severity, 'severity', AuditSeverity.error),
      ),
    );
    expect(
      audit
          .auditExercise(useful)
          .where((issue) => issue.code.startsWith('HINT_')),
      isEmpty,
    );
  });

  test('Recently modified is descending with deterministic ties', () {
    final old = DateTime.utc(2026, 9, 4, 9);
    final recent = DateTime.utc(2026, 9, 4, 11);
    final result = CourseAuditResult([
      CourseAuditIssue(
        severity: AuditSeverity.info,
        code: 'Z',
        message: 'old',
        location: 'Lesson 2',
        updatedAt: old,
      ),
      CourseAuditIssue(
        severity: AuditSeverity.error,
        code: 'B',
        message: 'second tie',
        location: 'Lesson 1 · B',
        updatedAt: recent,
      ),
      CourseAuditIssue(
        severity: AuditSeverity.warning,
        code: 'A',
        message: 'first tie',
        location: 'Lesson 1 · A',
        updatedAt: recent,
      ),
    ]);
    expect(
      result
          .sorted(AuditSortMode.recentlyModified)
          .map((issue) => issue.message),
      ['first tie', 'second tie', 'old'],
    );
  });

  test('progressive numbering follows every sort and active filter', () {
    final result = CourseAuditResult(const [
      CourseAuditIssue(
        severity: AuditSeverity.warning,
        code: 'W2',
        message: 'warning B',
        location: 'Lesson 2',
        exerciseType: 'choice',
      ),
      CourseAuditIssue(
        severity: AuditSeverity.error,
        code: 'E1',
        message: 'error',
        location: 'Lesson 1',
        exerciseType: 'reading_comprehension',
      ),
      CourseAuditIssue(
        severity: AuditSeverity.warning,
        code: 'W1',
        message: 'warning A',
        location: 'Lesson 1',
        exerciseType: 'build_translation',
      ),
      CourseAuditIssue(
        severity: AuditSeverity.info,
        code: 'I1',
        message: 'info',
        location: 'Lesson 3',
      ),
    ]);

    for (final mode in AuditSortMode.values) {
      final all = result.numbered(mode);
      expect(
        all
            .where((entry) => entry.issue.severity == AuditSeverity.error)
            .single
            .label,
        'Error 1 of 1',
      );
      expect(
        all
            .where((entry) => entry.issue.severity == AuditSeverity.info)
            .single
            .label,
        'Info 1 of 1',
      );
      expect(
        all
            .where((entry) => entry.issue.severity == AuditSeverity.warning)
            .map((entry) => entry.label),
        ['Warning 1 of 2', 'Warning 2 of 2'],
      );
      expect(
        result
            .numbered(mode, severity: AuditSeverity.warning)
            .map((entry) => entry.label),
        ['Warning 1 of 2', 'Warning 2 of 2'],
      );
    }
  });

  test('untitled Round fallback follows its current position', () {
    final invalid = _choice('invalid', correct: 8);
    final first = LearningRound(
      id: 'first',
      updatedAt: DateTime.utc(2026, 9, 4),
      title: 'Custom title',
      exercises: [_choice('valid')],
    );
    final untitled = LearningRound(
      id: 'untitled',
      updatedAt: DateTime.utc(2026, 9, 4),
      title: '   ',
      exercises: [invalid],
    );

    String locationFor(List<LearningRound> rounds) => audit
        .auditCourse(_course(rounds: rounds))
        .issues
        .firstWhere((issue) => issue.exerciseId == invalid.id)
        .location;

    expect(locationFor([first, untitled]), contains('Round 2'));
    expect(locationFor([untitled, first]), contains('Round 1'));
  });
}

Exercise _reading(String passage) => Exercise(
  id: 'reading-${passage.hashCode}',
  updatedAt: DateTime.utc(2026, 9, 4, 10),
  type: 'reading_comprehension',
  prompt: passage,
  question: 'What happened?',
  answers: const ['They met', 'They left'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _choice(
  String id, {
  String prompt = 'Choose the correct response.',
  String hint = '',
  int correct = 0,
}) => Exercise(
  id: id,
  updatedAt: DateTime.utc(2026, 9, 4),
  type: 'choice',
  prompt: prompt,
  question: 'Which answer is correct?',
  answers: const ['Correct', 'Wrong'],
  correct: correct,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: hint,
  icons: const [],
);

Course _course({required List<LearningRound> rounds}) => Course(
  courseId: 'audit-22502',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Audit 225.02',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      updatedAt: DateTime.utc(2026, 9, 4),
      title: 'Lesson',
      rounds: rounds,
    ),
  ],
);
