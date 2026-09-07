import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  final service = CourseAuditService();

  test(
    'all known rules have unique, complete definitions and fixed severity',
    () {
      final definitions = AuditCodeRegistry.definitions;
      expect(definitions.length, 102);
      expect(
        definitions.map((rule) => rule.code).toSet().length,
        definitions.length,
      );
      expect(
        definitions
            .where((rule) => rule.severity == AuditSeverity.error)
            .length,
        70,
      );
      expect(
        definitions
            .where((rule) => rule.severity == AuditSeverity.warning)
            .length,
        27,
      );
      expect(
        definitions.where((rule) => rule.severity == AuditSeverity.info).length,
        5,
      );
      for (final rule in definitions) {
        expect(rule.code, matches(RegExp(r'^[A-Z][A-Z0-9_]+$')));
        expect(rule.code, isNot('GENERAL'));
        expect(AuditCodeRegistry.byCode(rule.code), same(rule));
        for (final field in [
          rule.scope,
          rule.meaning,
          rule.trigger,
          rule.creatorAction,
        ]) {
          expect(field.trim(), isNotEmpty, reason: rule.code);
        }
        expect(rule.blocking, rule.severity == AuditSeverity.error);
      }
      expect(AuditCodeRegistry.byCode('GENERAL'), isNull);
      expect(AuditCodeRegistry.byCode('unknown'), isNull);
    },
  );

  test(
    'every production rule is registry-backed and every definition is used',
    () {
      // This structural check covers rare malformed-data branches as well as
      // normal fixtures. Whitespace and line endings do not affect the contract.
      final source = File(
        'lib/services/course_audit_service.dart',
      ).readAsStringSync();
      final implementation = source.substring(
        source.indexOf('class CourseAuditService'),
      );
      expect(
        RegExp(r'\bCourseAuditIssue\s*\(').hasMatch(implementation),
        isFalse,
        reason: 'Known rules must use CourseAuditIssue.fromCode.',
      );
      expect(
        RegExp(r'\bAuditSeverity\s*\.').hasMatch(implementation),
        isFalse,
        reason: 'Production severity must come from its registry definition.',
      );
      expect(implementation, isNot(contains('GENERAL')));
      final usedNames = RegExp(
        r'\bAuditCode\s*\.\s*(\w+)',
      ).allMatches(implementation).map((match) => match.group(1)!).toSet();
      expect(
        usedNames,
        AuditCodeRegistry.definitions.map((rule) => rule.name).toSet(),
      );
    },
  );

  test('definition-backed findings preserve issue context and timestamps', () {
    final timestamp = DateTime.utc(2026, 9, 5, 10);
    for (final rule in AuditCodeRegistry.definitions) {
      final issue = CourseAuditIssue.fromCode(
        rule,
        message: 'Detailed finding',
        location: 'Lesson 1',
        roundId: 'round',
        exerciseId: 'exercise',
        exerciseType: 'choice',
        updatedAt: timestamp,
      );
      final copied = issue.withUpdatedAt(
        timestamp.add(const Duration(hours: 1)),
      );
      expect(issue.code, rule.code);
      expect(issue.severity, rule.severity);
      expect(copied.code, issue.code);
      expect(copied.severity, issue.severity);
      expect(copied.message, 'Detailed finding');
      expect(copied.location, 'Lesson 1');
      expect(copied.roundId, 'round');
      expect(copied.exerciseId, 'exercise');
      expect(copied.exerciseType, 'choice');
      expect(copied.updatedAt, timestamp.add(const Duration(hours: 1)));
    }
    const fallback = CourseAuditIssue(
      severity: AuditSeverity.warning,
      message: 'Unexpected finding',
      location: 'Course',
    );
    expect(fallback.code, 'GENERAL');
    expect(fallback.severity, AuditSeverity.warning);
  });

  test(
    'search covers code, severity, scope, meaning, trigger and creator action',
    () {
      expect(AuditCodeRegistry.search('  reading_passage_required  '), [
        AuditCode.readingPassageRequired,
      ]);
      expect(
        AuditCodeRegistry.search('reading ERROR'),
        contains(AuditCode.readingPassageRequired),
      );
      expect(
        AuditCodeRegistry.search('whitespace punctuation'),
        contains(AuditCode.buildTranslationDuplicateAnswer),
      );
      expect(
        AuditCodeRegistry.search('Base64'),
        contains(AuditCode.lessonIconAssetInvalid),
      );
      expect(
        AuditCodeRegistry.search('reselect'),
        contains(AuditCode.correctItemUnresolved),
      );
      expect(
        AuditCodeRegistry.search('Blocking: No'),
        containsAll(
          AuditCodeRegistry.definitions.where((rule) => !rule.blocking),
        ),
      );
      expect(AuditCodeRegistry.search(''), AuditCodeRegistry.definitions);
      expect(AuditCodeRegistry.search('no-such-audit-rule'), isEmpty);
    },
  );

  test('pair-empty rules describe the canonical projected pair data', () {
    for (final rule in [
      AuditCode.audioMatchPairEmpty,
      AuditCode.matchPairEmpty,
    ]) {
      expect(rule.trigger, 'Either value in a two-entry pair is blank.');
      expect(rule.trigger, isNot(contains('does not have two entries')));
    }
  });

  test(
    'sample comparison is absent from the canonical registry and search',
    () {
      expect(AuditCodeRegistry.byCode('ROUND_CONTENT_SHORT'), isNull);
      expect(AuditCodeRegistry.search('ROUND_CONTENT_SHORT'), isEmpty);
      expect(AuditCodeRegistry.search('standard sample'), isEmpty);
      for (final rule in AuditCodeRegistry.definitions.where(
        (rule) => rule.severity == AuditSeverity.info,
      )) {
        expect(
          '${rule.meaning} ${rule.trigger} ${rule.creatorAction}'.toLowerCase(),
          isNot(contains('sample')),
          reason: rule.code,
        );
      }
    },
  );

  for (final count in [0, 1, 7, 8, 10, 11]) {
    test('Round with $count items keeps real checks without sample Info', () {
      final course = _course([
        for (var index = 0; index < count; index++)
          _exercise(id: 'exercise-$index', question: 'response $index?'),
      ]);
      final issues = service.auditRound(course, 'round').issues;
      expect(
        issues.where((issue) => issue.severity == AuditSeverity.info),
        isEmpty,
      );
      expect(
        issues.map((issue) => issue.code),
        count == 0
            ? ['ROUND_CONTENT_EMPTY']
            : count > 10
            ? ['ROUND_CONTENT_LONG']
            : isEmpty,
      );
      if (count == 0) {
        expect(issues.single.severity, AuditSeverity.error);
      } else if (count > 10) {
        expect(issues.single.severity, AuditSeverity.warning);
      }
    });
  }

  test('absence of Reading and Listening never creates a Round finding', () {
    final course = _course([_exercise()]);
    final issues = service.auditCourse(course).issues;
    expect(issues.map((issue) => issue.code), [
      'LESSON_GUIDEBOOK_EMPTY',
      'LESSON_ROUND_GUIDANCE',
      'LESSON_INTRO_MISSING',
      'DUEL_UNAVAILABLE',
    ]);
    expect(issues.map((issue) => issue.severity), [
      AuditSeverity.warning,
      AuditSeverity.info,
      AuditSeverity.info,
      AuditSeverity.info,
    ]);
    expect(
      issues.where(
        (issue) =>
            issue.message.contains('no Reading comprehension') ||
            issue.message.contains('without listening'),
      ),
      isEmpty,
    );
    expect(
      service.auditRound(course, 'round').issues.map((issue) => issue.code),
      isEmpty,
    );
  });

  test('malformed actual Reading and Listening retain their validation', () {
    final reading = _exercise(
      type: 'reading_comprehension',
      prompt: '',
      answers: const ['one'],
      correct: 7,
    );
    final listening = _exercise(
      type: 'listening_comprehension',
      prompt: '',
      tts: null,
    );
    final issues = service.auditCourse(_course([reading, listening])).issues;
    for (final code in [
      'CHOICE_ANSWERS_REQUIRED',
      'CHOICE_CORRECT_ANSWER_INVALID',
      'READING_PASSAGE_REQUIRED',
      'LISTENING_AUDIO_REQUIRED',
    ]) {
      expect(
        issues,
        contains(
          isA<CourseAuditIssue>()
              .having((issue) => issue.code, 'code', code)
              .having(
                (issue) => issue.severity,
                'severity',
                AuditSeverity.error,
              ),
        ),
      );
    }
    expect(
      issues,
      contains(
        isA<CourseAuditIssue>()
            .having((issue) => issue.code, 'code', 'LISTENING_PASSAGE_SHORT')
            .having((issue) => issue.severity, 'severity', AuditSeverity.info),
      ),
    );
    for (final issue in issues) {
      expect(
        AuditCodeRegistry.byCode(issue.code)?.severity,
        issue.severity,
        reason: issue.message,
      );
    }
  });

  test(
    'all supported presets emit registered codes for incomplete content',
    () {
      for (final type in CourseAuditService.supportedTypes) {
        final issues = service.auditExercise(
          _exercise(
            type: type,
            prompt: '',
            question: '',
            answers: const [],
            correct: null,
          ),
        );
        for (final issue in issues) {
          final definition = AuditCodeRegistry.byCode(issue.code);
          expect(definition, isNotNull, reason: '$type: ${issue.message}');
          expect(definition!.severity, issue.severity);
        }
      }
    },
  );

  test(
    'Arrange errors explain available blocks and preserve strict orders',
    () {
      final missing = service.auditExercise(
        _exercise(type: 'word_order', answers: const []),
      );
      expect(
        missing
            .firstWhere((issue) => issue.code == 'WORD_BLOCK_DATA_REQUIRED')
            .message,
        contains('select its blocks in order'),
      );
      final mismatch = Exercise.v2(
        id: 'arrange',
        editorTemplate: 'build_translation',
        promptElements: const [],
        interaction: const ExerciseInteraction(
          kind: 'arrange',
          items: [
            ExerciseItem(
              id: 'one',
              content: [PromptElement(type: 'text', text: 'io')],
            ),
            ExerciseItem(
              id: 'two',
              content: [PromptElement(type: 'text', text: 'sono')],
            ),
          ],
        ),
        evaluation: const ExerciseEvaluation(
          kind: 'ordered_items',
          correctOrders: [
            OrderedAnswer(text: 'io vado', itemIds: ['one', 'two']),
          ],
        ),
      );
      final issue = service
          .auditExercise(mismatch)
          .firstWhere(
            (issue) => issue.code == 'BUILD_TRANSLATION_UNCONSTRUCTABLE',
          );
      expect(issue.severity, AuditSeverity.error);
      expect(
        issue.message,
        contains('Make the answer text and ordered blocks agree'),
      );
    },
  );
}

Exercise _exercise({
  String? id,
  String type = 'choice',
  String prompt = 'choose a response',
  String question = 'which response fits?',
  List<String> answers = const ['ciao', 'grazie'],
  int? correct = 0,
  String? tts,
}) => Exercise(
  id: id ?? 'exercise-$type',
  type: type,
  prompt: prompt,
  question: question,
  answers: answers,
  correct: correct,
  tts: tts,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Course _course(List<Exercise> exercises) => Course(
  courseId: 'audit-registry-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Audit registry',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'lesson',
      rounds: [LearningRound(id: 'round', title: '', exercises: exercises)],
    ),
  ],
);
