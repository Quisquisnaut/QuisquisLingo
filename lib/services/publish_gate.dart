import '../models/course_models.dart';
import 'course_audit_service.dart';
import 'publication_service.dart';

/// Whether an item of a Course may be applied as normal content (Published)
/// (Build 273 Revision 1): the one owner of the check the Course Editor's
/// pages and the two exercise forms each wrote for themselves. No screen and
/// no storage: a Course or an exercise in, a count, a list or a text out.
///
/// A Course, a Lesson or a Round is checked as learners would get it: the
/// learner projection ([PublicationService.learnerCourse]) is audited, a
/// Lesson with its Course taken as Published, a Round with its Course and
/// its Lesson taken as Published, and the Course Audit's errors in that
/// item's scope block it. An exercise is audited alone. Warnings and Info
/// never block here; the exercise forms ask about warnings.
class PublishGate {
  const PublishGate({CourseAuditService? audit}) : _audit = audit;

  final CourseAuditService? _audit;

  CourseAuditService get _service => _audit ?? CourseAuditService();

  /// The blocking errors of [candidate], a Course about to be Published.
  int courseErrors(Course candidate) {
    final visible = const PublicationService().learnerCourse(candidate)!;
    return _errorCount(
      _service.auditCourse(visible, sourceReferenceCourse: candidate).issues,
    );
  }

  /// The blocking errors of the Lesson [lessonId] of [authored], with the
  /// Course taken as Published.
  int lessonErrors(Course authored, String lessonId) {
    final root = _published(authored);
    final visible = const PublicationService().learnerCourse(root)!;
    return _errorCount(
      _service
          .auditLesson(visible, lessonId, sourceReferenceCourse: root)
          .issues,
    );
  }

  /// The blocking errors of the Round [roundId] of [authored], with the
  /// Course and the Lesson [lessonId] taken as Published.
  int roundErrors(Course authored, String lessonId, String roundId) {
    final root = _published(authored, lessonId: lessonId);
    final visible = const PublicationService().learnerCourse(root)!;
    return _errorCount(
      _service.auditRound(visible, roundId, sourceReferenceCourse: root).issues,
    );
  }

  /// The Course Audit's findings on [exercise] alone.
  List<CourseAuditIssue> exerciseIssues(Exercise exercise) =>
      _service.auditExercise(exercise);

  /// The errors among [issues], in their order.
  static List<CourseAuditIssue> errorsIn(List<CourseAuditIssue> issues) => [
    for (final issue in issues)
      if (issue.severity == AuditSeverity.error) issue,
  ];

  /// How many warnings [issues] hold.
  static int warningCount(List<CourseAuditIssue> issues) =>
      issues.where((issue) => issue.severity == AuditSeverity.warning).length;

  /// Why a Course cannot be published.
  static String courseRefusal(int errors) =>
      'Course cannot be published: $errors blocking error${errors == 1 ? '' : 's'}.';

  /// Why a Lesson or a Round ([entity]) cannot be applied as normal content.
  static String refusal(String entity, int errors) =>
      '$entity cannot be applied as normal content: $errors blocking error${errors == 1 ? '' : 's'}.';

  /// Why an exercise cannot be applied as normal content from the Round
  /// editor's list.
  static const exerciseRefusal =
      'Exercise cannot be applied as normal content until its Errors are fixed.';

  static int _errorCount(List<CourseAuditIssue> issues) =>
      issues.where((issue) => issue.severity == AuditSeverity.error).length;

  static Course _published(Course authored, {String? lessonId}) =>
      Course.fromJson({
        ...authored.toJson(),
        'publicationState': PublicationState.published.name,
        if (lessonId != null)
          'lessons': [
            for (final lesson in authored.lessons)
              lesson.lessonId == lessonId
                  ? {
                      ...lesson.toJson(),
                      'publicationState': PublicationState.published.name,
                    }
                  : lesson.toJson(),
          ],
      });
}
