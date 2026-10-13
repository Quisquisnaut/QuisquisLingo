import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

/// The Courses the comparisons run on: the bundled one and the fixtures
/// made to carry findings of many kinds. (QQL Demo: English from Italian was
/// among them until it left the app and the repository in Build 272
/// Revision 15.)
const _files = [
  'assets/courses/exercise_laboratory_en_it.json',
  'test/fixtures/v12/edge_case_it_en.json',
  'test/fixtures/v12/laboratory_future_en_it.json',
  'test/fixtures/v12/korean_en.json',
  'demo_courses/edge_case_it_en.json',
];

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

Course _load(String path) => Course.fromJson(_json(path));

/// One finding as text, with everything that tells two findings apart.
String _line(CourseAuditIssue issue) => [
  issue.severity.name,
  issue.code,
  issue.location,
  issue.message,
  issue.roundId ?? '-',
  issue.exerciseId ?? '-',
  issue.exerciseType ?? '-',
  issue.updatedAt?.toIso8601String() ?? '-',
].join(' | ');

List<String> _lines(Iterable<CourseAuditIssue> issues) => [
  for (final issue in issues) _line(issue),
];

/// A Course with the trouble a Lesson's own Audit could miss: IDs repeated
/// across Lessons (Lesson, Duel, GuideBook module, Sentence, Word, Round and
/// exercise), and a source reference that another Lesson's GuideBook
/// answers.
Course _troubled() {
  final json = _json('assets/courses/exercise_laboratory_en_it.json');
  final lessons = (json['lessons'] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic> copy(Map<String, dynamic> value) =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  // Lesson 3 repeats Lesson 1's first Round whole (its ID and its
  // exercises' IDs), with one exercise emptied so that it has findings.
  final repeated = copy(
    (lessons[0]['rounds'] as List).first as Map<String, dynamic>,
  );
  (lessons[2]['rounds'] as List).add(repeated);
  // Lesson 4 takes Lesson 2's ID.
  lessons[3]['lessonId'] = lessons[1]['lessonId'];
  // Lesson 5's first Content names a GuideBook word of Lesson 1 and an ID
  // that nothing has.
  final word =
      (((lessons[0]['guidebook'] as Map)['modules'] as List).first
              as Map)['words']
          as List;
  final content =
      ((lessons[4]['rounds'] as List).first as Map)['content'] as List;
  (content.first as Map)['sourceRefs'] = [
    (word.first as Map)['id'],
    'nothing-has-this-id',
  ];
  // Lesson 6 repeats Lesson 1's Duel, module, Sentence and Word IDs.
  Map<String, dynamic> moduleOf(int lesson) =>
      ((lessons[lesson]['guidebook'] as Map)['modules'] as List).first
          as Map<String, dynamic>;
  final firstModule = moduleOf(0);
  final sixthModule = moduleOf(5);
  for (final module in [firstModule, sixthModule]) {
    (module['sentences'] as List).add({
      'id': 'repeated-sentence',
      'target': 'Ciao a tutti.',
      'source': 'Hello, everyone.',
    });
  }
  sixthModule['id'] = firstModule['id'];
  ((sixthModule['words'] as List).first as Map)['id'] =
      ((firstModule['words'] as List).first as Map)['id'];
  (lessons[5]['duel'] as Map)['id'] = (lessons[0]['duel'] as Map)['id'];
  return Course.fromJson(json);
}

// Build 271 Revision 3 follow-up: the Audit of one Lesson or Round checks
// that Lesson alone, and the status of a working copy is worked out once.
// What they find must be what the whole Audit finds there.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final courses = <String, Course>{
    for (final path in _files) path: _load(path),
    'a Course with IDs repeated across Lessons': _troubled(),
  };

  group('a Lesson\'s own Audit finds what the whole Audit finds there', () {
    for (final entry in courses.entries) {
      test(entry.key, () {
        final course = entry.value;
        final audit = CourseAuditService();
        final whole = audit.auditCourse(course).issues;
        expect(course.lessons, isNotEmpty);
        var compared = 0;
        for (var index = 0; index < course.lessons.length; index++) {
          final lesson = course.lessons[index];
          // A repeated Lesson ID is found at its first place, as before.
          final first = course.lessons.indexWhere(
            (other) => other.lessonId == lesson.lessonId,
          );
          final prefix = 'Lesson ${first + 1} ·';
          expect(
            _lines(audit.auditLesson(course, lesson.lessonId).issues),
            _lines(whole.where((issue) => issue.location.startsWith(prefix))),
            reason: 'Lesson ${index + 1}',
          );
          for (final round in lesson.rounds) {
            expect(
              _lines(audit.auditRound(course, round.id).issues),
              _lines(whole.where((issue) => issue.roundId == round.id)),
              reason: 'Round ${round.id}',
            );
            compared++;
          }
        }
        expect(compared, greaterThan(0));
        expect(audit.auditLesson(course, 'no-such-lesson').issues, isEmpty);
        expect(audit.auditRound(course, 'no-such-round').issues, isEmpty);
      });
    }

    test('also with the Course the source references are read from', () {
      // What a publication gate passes: the learner projection audited
      // against the authored Course.
      final course = courses['test/fixtures/v12/edge_case_it_en.json']!;
      final audit = CourseAuditService();
      final whole = audit
          .auditCourse(course, sourceReferenceCourse: course)
          .issues;
      for (var index = 0; index < course.lessons.length; index++) {
        final prefix = 'Lesson ${index + 1} ·';
        expect(
          _lines(
            audit
                .auditLesson(
                  course,
                  course.lessons[index].lessonId,
                  sourceReferenceCourse: course,
                )
                .issues,
          ),
          _lines(whole.where((issue) => issue.location.startsWith(prefix))),
        );
      }
    });

    test('the troubled Course has the trouble it is meant to have', () {
      final whole = CourseAuditService()
          .auditCourse(courses.values.last)
          .issues;
      final codes = whole.map((issue) => issue.code).toSet();
      expect(codes, contains(AuditCode.idDuplicate.code));
      expect(codes, contains(AuditCode.sourceRefMissing.code));
      // The four IDs Lesson 6 repeats from Lesson 1 are found in Lesson 6:
      // its Duel, its module, a Sentence and a Word.
      final repeatedInSixth = {
        for (final issue in whole)
          if (issue.code == AuditCode.idDuplicate.code &&
              issue.location.startsWith('Lesson 6 ·'))
            issue.message,
      };
      expect(repeatedInSixth, hasLength(greaterThanOrEqualTo(4)));
    });
  });

  group('the colours of a Lesson\'s cards', () {
    for (final entry in courses.entries) {
      test('${entry.key}: the Lesson\'s own status answers as the whole '
          'one', () {
        final course = entry.value;
        final whole = AuthoringHierarchyStatus.fromCourse(course);
        for (final lesson in course.lessons) {
          final own = AuthoringHierarchyStatus.forLesson(
            course,
            lesson.lessonId,
          );
          final reason = 'Lesson ${lesson.lessonId}';
          expect(
            own.lessonHasRoundAuditConcern(lesson),
            whole.lessonHasRoundAuditConcern(lesson),
            reason: reason,
          );
          expect(
            own.lessonGuidebookAuditStatus(lesson),
            whole.lessonGuidebookAuditStatus(lesson),
            reason: reason,
          );
          expect(
            own.lessonHasAuditConcern(lesson),
            whole.lessonHasAuditConcern(lesson),
            reason: reason,
          );
          expect(
            own.lessonHasRoundDraft(lesson),
            whole.lessonHasRoundDraft(lesson),
          );
          expect(
            own.lessonGuidebookHasDraft(lesson),
            whole.lessonGuidebookHasDraft(lesson),
          );
          for (final round in lesson.rounds) {
            expect(
              own.roundHasAuditConcern(round),
              whole.roundHasAuditConcern(round),
              reason: '$reason, Round ${round.id}',
            );
            expect(own.roundHasDraft(round), whole.roundHasDraft(round));
            for (final exercise in round.exercises) {
              expect(
                own.exerciseHasAuditConcern(exercise),
                whole.exerciseHasAuditConcern(exercise),
                reason: '$reason, exercise ${exercise.id}',
              );
              expect(
                own.exerciseIsDraft(exercise),
                whole.exerciseIsDraft(exercise),
              );
            }
          }
        }
      });
    }

    test('a Lesson the Course does not have is all clear', () {
      final course = courses.values.first;
      final status = AuthoringHierarchyStatus.forLesson(course, 'no-such');
      expect(status.roundAuditConcernIds, isEmpty);
      expect(status.exerciseAuditConcernIds, isEmpty);
      expect(status.lessonAuditConcernIds, isEmpty);
    });
  });

  group('one Audit for each working copy', () {
    test('the same Course object is audited once; another is audited '
        'again', () {
      final course = _load('assets/courses/exercise_laboratory_en_it.json');
      final first = AuthoringHierarchyStatus.fromCourse(course);
      expect(
        identical(AuthoringHierarchyStatus.fromCourse(course), first),
        isTrue,
      );

      // The same content in another object: its own status, the same answers.
      final again = Course.fromJson(course.toJson());
      final second = AuthoringHierarchyStatus.fromCourse(again);
      expect(identical(second, first), isFalse);
      expect(second.roundAuditConcernIds, first.roundAuditConcernIds);
      expect(second.exerciseAuditConcernIds, first.exerciseAuditConcernIds);

      // A changed working copy is another object, and is audited as it is:
      // here its first Lesson has lost its Rounds.
      final lessons = [for (final lesson in course.lessons) lesson.toJson()];
      lessons.first['rounds'] = <Object>[];
      final changed = Course.fromJson({...course.toJson(), 'lessons': lessons});
      final lessonId = course.lessons.first.lessonId;
      expect(first.lessonEmptyRoundsIds, isNot(contains(lessonId)));
      expect(
        AuthoringHierarchyStatus.fromCourse(changed).lessonEmptyRoundsIds,
        contains(lessonId),
      );
    });
  });
}
