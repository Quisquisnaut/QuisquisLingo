import '../models/course_models.dart';
import 'app_errors.dart';
import 'diagnostic_log_service.dart';

/// A stored Course this version cannot open: its file is valid JSON with a
/// Course ID, but `Course.fromJson` refuses it (a GuideBook in the shape
/// before Build 266, a field of the wrong type, a hand-edited file). What
/// its JSON still says is kept, so the app can name it, tell who maintains
/// it, and let it be removed or replaced.
class UnopenableStoredCourse {
  const UnopenableStoredCourse({
    required this.courseId,
    required this.reason,
    this.title,
    this.maintainerProfileId,
    this.assignedTeamId,
    this.private = false,
  });

  final String courseId;
  final String reason;
  final String? title;
  final String? maintainerProfileId;
  final String? assignedTeamId;

  /// A Private course (`temporarySample`), whose title only its Maintainer
  /// and Team may see.
  final bool private;

  /// The Course as people know it: its title in quotes, else its ID.
  String get shownName => title == null ? courseId : '“$title”';
}

/// The one way QQL opens a stored custom Course entry (`{savedAt, course}`)
/// (Build 266 Revision 2, owner decisions of 8 October 2026): one Course
/// this version cannot open must never stop a feature that reads the
/// others. It is reported with what its JSON says, logged once per session
/// and left on disk until someone removes or replaces it.
abstract final class StoredCourseReader {
  /// The Course in [entry], or what its JSON says when it cannot be opened.
  static ({Course? course, UnopenableStoredCourse? unopenable}) open(
    String courseId,
    Object? entry,
  ) {
    final raw = entry is Map && entry['course'] is Map
        ? Map<String, dynamic>.from(entry['course'] as Map)
        : null;
    if (raw == null) {
      return (
        course: null,
        unopenable: UnopenableStoredCourse(
          courseId: courseId,
          reason: 'The stored entry holds no Course.',
        ),
      );
    }
    try {
      return (course: Course.fromJson(raw), unopenable: null);
    } catch (error) {
      if (!isDataError(error)) rethrow;
      final maintainer = raw['maintainer'];
      return (
        course: null,
        unopenable: UnopenableStoredCourse(
          courseId: courseId,
          reason: reasonOf(error),
          title: _text(raw['title']),
          maintainerProfileId: maintainer is Map
              ? _text(maintainer['profileId'])
              : null,
          assignedTeamId: _text(raw['assignedTeamId']),
          private: raw['temporarySample'] == true,
        ),
      );
    }
  }

  /// What `Course.fromJson` throws for data it refuses, never a fault of
  /// the program itself such as running out of memory.
  static bool isDataError(Object error) =>
      error is FormatException ||
      error is TypeError ||
      error is ArgumentError ||
      error is StateError ||
      error is RangeError;

  /// [error] as a sentence for people: a FormatException's own message.
  static String reasonOf(Object error) =>
      error is FormatException ? error.message : '$error';

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static final Set<String> _logged = {};

  /// Test seam: forgets which Courses were logged this session.
  static void resetLogForTests() => _logged.clear();

  /// Writes [unopenable] to the Diagnostic Log, once per session per Course.
  static Future<void> log(
    UnopenableStoredCourse unopenable, {
    String? fileName,
    DiagnosticLogService? diagnostics,
  }) async {
    if (!_logged.add(unopenable.courseId)) return;
    await (diagnostics ?? DiagnosticLogService()).log(
      AppErrorCode.invalidCourseData,
      context:
          'A stored Course could not be opened and was skipped: '
          '${unopenable.shownName}, ID ${unopenable.courseId}'
          '${fileName == null ? '' : ', file $fileName'}. It stays on disk; '
          'its Maintainer or an admin can remove it in Advanced (Admin) › '
          'Inventory, or replace it by importing a Course with the same ID. '
          'Reason: ${unopenable.reason}',
    );
  }
}
