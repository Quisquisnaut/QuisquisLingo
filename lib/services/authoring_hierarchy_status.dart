import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import 'audit_code_registry.dart' show AuditCode;
import 'course_audit_service.dart';

class AuthoringHierarchyStatus {
  AuthoringHierarchyStatus._(this.course, CourseAuditResult audit)
    : hasCourseAuditConcern = audit.issues.any(_isAuditConcern),
      hasLessonsAuditConcern = audit.issues.any(
        (issue) =>
            _isAuditConcern(issue) &&
            (issue.code == AuditCode.courseLessonsEmpty.code ||
                issue.location.startsWith('Lesson ')),
      ),
      exerciseAuditConcernIds = {
        for (final issue in audit.issues)
          if (_isAuditConcern(issue) && issue.exerciseId != null)
            issue.exerciseId!,
      },
      roundAuditConcernIds = {
        for (final issue in audit.issues)
          if (_isAuditConcern(issue) && issue.roundId != null) issue.roundId!,
      },
      lessonAuditConcernIds = {
        for (var index = 0; index < course.lessons.length; index++)
          if (audit.issues.any(
            (issue) =>
                _isAuditConcern(issue) &&
                (issue.location ==
                        'Lesson ${index + 1} · ${course.lessons[index].title}' ||
                    issue.location.startsWith(
                      'Lesson ${index + 1} · ${course.lessons[index].title} ·',
                    )),
          ))
            course.lessons[index].lessonId,
      },
      lessonEmptyRoundsIds = {
        for (var index = 0; index < course.lessons.length; index++)
          if (audit.issues.any(
            (issue) =>
                issue.code == AuditCode.lessonRoundsEmpty.code &&
                issue.location ==
                    'Lesson ${index + 1} · ${course.lessons[index].title}',
          ))
            course.lessons[index].lessonId,
      },
      lessonGuidebookAuditConcernIds = {
        for (var index = 0; index < course.lessons.length; index++)
          if (audit.issues.any(
            (issue) =>
                _isAuditConcern(issue) &&
                issue.roundId == null &&
                issue.exerciseId == null &&
                (issue.location ==
                        'Lesson ${index + 1} · ${course.lessons[index].title} · Guidebook' ||
                    // Build 266: a module's location (and its entries').
                    issue.location.startsWith(
                      'Lesson ${index + 1} · ${course.lessons[index].title} · Guidebook · ',
                    )),
          ))
            course.lessons[index].lessonId,
      };

  static bool _isAuditConcern(CourseAuditIssue issue) =>
      issue.severity == AuditSeverity.error ||
      issue.severity == AuditSeverity.warning;

  /// One status for each Course object (Build 271 Revision 3). A Course is
  /// never changed in place, so the same object always audits the same.
  /// Before, the whole Audit ran again on every rebuild of the Course
  /// Editor's main page, of the Lessons page and of every row of Course
  /// Studio.
  static final _byCourse = Expando<AuthoringHierarchyStatus>();

  factory AuthoringHierarchyStatus.fromCourse(Course course) =>
      _byCourse[course] ??= AuthoringHierarchyStatus._(
        course,
        CourseAuditService().auditCourse(course),
      );

  /// The status of one Lesson's cards (its GuideBook, its Rounds and their
  /// exercises) from the Audit of that Lesson alone (Build 271 Revision 3):
  /// the answers [fromCourse] gives for them, without checking the content
  /// of the other Lessons. A Lesson that repeats one of this Lesson's IDs
  /// is audited too, because a finding is found again by its ID. Ask it
  /// about this Lesson only.
  factory AuthoringHierarchyStatus.forLesson(Course course, String lessonId) {
    Set<String> idsOf(Lesson lesson) => {
      for (final round in lesson.rounds) ...[
        round.id,
        for (final content in round.content) content.id,
        for (final exercise in round.exercises) exercise.id,
      ],
    };
    final index = course.lessons.indexWhere(
      (lesson) => lesson.lessonId == lessonId,
    );
    if (index < 0) {
      return AuthoringHierarchyStatus._(course, CourseAuditResult(const []));
    }
    final own = idsOf(course.lessons[index]);
    final lessons = {
      index,
      for (var other = 0; other < course.lessons.length; other++)
        if (other != index &&
            (course.lessons[other].lessonId == lessonId ||
                idsOf(course.lessons[other]).any(own.contains)))
          other,
    };
    return AuthoringHierarchyStatus._(
      course,
      CourseAuditService().auditCourse(course, onlyLessons: lessons),
    );
  }

  final Course course;
  final bool hasCourseAuditConcern;
  final bool hasLessonsAuditConcern;
  final Set<String> exerciseAuditConcernIds;
  final Set<String> roundAuditConcernIds;
  final Set<String> lessonAuditConcernIds;
  final Set<String> lessonEmptyRoundsIds;
  final Set<String> lessonGuidebookAuditConcernIds;

  /// Draft rules live in [CourseDraftStatus]; these getters delegate to it.
  bool get courseHasDraft => CourseDraftStatus.courseHasDraft(course);
  bool lessonHasDraft(Lesson lesson) =>
      CourseDraftStatus.lessonHasDraft(course, lesson);
  bool lessonGuidebookHasDraft(Lesson lesson) =>
      CourseDraftStatus.lessonGuidebookHasDraft(course, lesson);
  bool lessonHasRoundDraft(Lesson lesson) =>
      CourseDraftStatus.lessonHasRoundDraft(lesson);
  bool lessonHasAuditConcern(Lesson lesson) =>
      lessonAuditConcernIds.contains(lesson.lessonId);

  /// The Guidebook card border: no color at all while GuideBook is off.
  bool? lessonGuidebookAuditStatus(Lesson lesson) =>
      course.useGuidebook ? lessonGuidebookHasAuditConcern(lesson) : null;
  bool lessonGuidebookHasAuditConcern(Lesson lesson) =>
      lessonGuidebookAuditConcernIds.contains(lesson.lessonId);
  bool lessonHasRoundAuditConcern(Lesson lesson) =>
      lessonEmptyRoundsIds.contains(lesson.lessonId) ||
      lesson.rounds.any(roundHasAuditConcern);
  bool roundHasDraft(LearningRound round) =>
      CourseDraftStatus.roundHasDraft(round);
  bool roundHasAuditConcern(LearningRound round) =>
      roundAuditConcernIds.contains(round.id);
  bool exerciseIsDraft(Exercise exercise) =>
      CourseDraftStatus.exerciseIsDraft(exercise);
  bool exerciseHasAuditConcern(Exercise exercise) =>
      exerciseAuditConcernIds.contains(exercise.id);
}
