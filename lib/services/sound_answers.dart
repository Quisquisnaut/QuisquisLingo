import '../models/course_models.dart';
import '../models/exercise_features.dart';

/// Answers that are sounds (Build 274 Revision 3, the owner's decisions of
/// 16 October 2026; Listen and pick the missing word). An answer's sound is
/// an audio element with either a text (the device voice reads it, or the
/// Audio Library recording given that text plays) or a `recording`: the id
/// of an Audio Library recording, played whatever its text, which it may
/// not have. On-Device TTS plays no recordings, chosen ones included.
///
/// Pure Dart: the Round screen, the right answer's text, the Audit, the
/// Audio Library and Course Info read the rules here.
abstract final class SoundAnswers {
  /// The build that plays sound answers and grades a single choice on Check.
  static const minimumAppBuild = 274003;

  /// The Audio Library recording [sound] names; null when it names none or
  /// the Audio Library has no such recording.
  static CourseAudioClip? recordingOf(
    PromptElement? sound,
    List<CourseAudioClip> library,
  ) {
    final id = sound?.recording ?? '';
    if (id.isEmpty) return null;
    return library.where((clip) => clip.id == id).firstOrNull;
  }

  /// The text [item] shows once the learner has answered: its own text
  /// (`after_answer`), else its sound's text, else the Audio Library text of
  /// its recording; empty when it has none (an Audit Info).
  static String shownText(
    ExerciseFeatures f,
    ExerciseItem item,
    List<CourseAudioClip> library,
  ) {
    final own = f.afterAnswerTextOf(item);
    if (own.isNotEmpty) return own;
    final sound = f.soundOf(item);
    final spoken = sound?.text.trim() ?? '';
    if (spoken.isNotEmpty) return spoken;
    return recordingOf(sound, library)?.text.trim() ?? '';
  }

  /// The ids of the recordings [exercise]'s answers name, in item order.
  static Set<String> recordingIds(Exercise exercise) => {
    for (final item in exercise.items)
      for (final element in item.content)
        if (element.isAudio && element.recording.isNotEmpty) element.recording,
  };

  /// How many answers of [course] name a recording: the answers On-Device
  /// TTS would leave without a sound.
  static int answersWithRecordings(Course course) {
    var count = 0;
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        for (final exercise in round.exercises) {
          for (final item in exercise.items) {
            if (item.content.any((e) => e.isAudio && e.recording.isNotEmpty)) {
              count++;
            }
          }
        }
      }
    }
    return count;
  }

  /// Whether [exercise] needs [minimumAppBuild]: answers that are sounds, a
  /// recording named by its id, an `after_answer` text, or a single choice
  /// graded on Check outside inline gaps (an earlier build would print the
  /// sounds' words, or grade on the tap).
  static bool needsThisBuild(Exercise exercise) {
    final f = ExerciseFeatures(exercise);
    if (f.hasSoundItems) return true;
    if (f.primitive == ExercisePrimitive.select &&
        f.checkedOnCheck &&
        !f.multipleSelection &&
        !f.hasInlineTargets) {
      return true;
    }
    return exercise.items.any(
      (item) => item.content.any(
        (e) => e.recording.isNotEmpty || (e.isText && e.role == 'after_answer'),
      ),
    );
  }

  /// [course] with `minimumAppBuild` raised to [minimumAppBuild] when one of
  /// its exercises [needsThisBuild]; never lowered.
  static Course withMinimumAppBuild(Course course) {
    final current = course.minimumAppBuild;
    if (current != null && current >= minimumAppBuild) return course;
    final uses = course.lessons.any(
      (lesson) =>
          lesson.rounds.any((round) => round.exercises.any(needsThisBuild)),
    );
    if (!uses) return course;
    return Course.fromJson({
      ...course.toJson(),
      'minimumAppBuild': minimumAppBuild,
    });
  }
}
