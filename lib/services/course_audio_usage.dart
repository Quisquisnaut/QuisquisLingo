import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'course_language_pair.dart';
import 'inline_marks.dart';
import 'playback_on_request.dart';
import 'sound_answers.dart';

/// Where one recording is heard: an exercise of a Round of a Lesson.
class AudioClipUse {
  const AudioClipUse({
    required this.lessonIndex,
    required this.roundIndex,
    required this.exerciseIndex,
    required this.exercise,
  });

  final int lessonIndex;
  final int roundIndex;

  /// The exercise's place among its Round's exercises.
  final int exerciseIndex;
  final Exercise exercise;
}

/// Build 270 Revision 13 (owner decisions of 10 October 2026): which
/// exercises play each recording of a Course's Audio Library.
///
/// A recording is used by an exercise when one of the exercise's spoken
/// texts is made of recordings from end to end, as playback joins them
/// ([segment], the longest matching recordings first). A text with a word
/// no recording says plays no recording at all (Recorded MP3 only stays
/// silent, Hybrid uses the device voice), so it uses none.
abstract final class CourseAudioUsage {
  /// Every text an exercise can speak, as the Round screen speaks it: its
  /// audio elements (main, context, passage, dialogue lines, Story lines,
  /// the flashcard word), its answers' sounds, what a learner may hear on
  /// request (`PlaybackOnRequest`: a translation's target-language sentence
  /// or answer, the words of picture options; Build 274 Revision 2; with
  /// [sameLanguage], the meanings too, Build 275 Revision 3), the
  /// flashcard's example, and a Page's audio blocks and read-aloud text.
  static List<String> spokenTexts(
    Exercise exercise, {
    bool sameLanguage = false,
  }) {
    final features = ExerciseFeatures(exercise);
    final texts = <String>[
      for (final element in features.audioElements) element.text,
      for (final item in features.items)
        if (item.content.any((element) => element.isAudio)) ...[
          for (final element in item.content)
            if (element.isAudio) element.text,
          item.label,
        ],
      ...PlaybackOnRequest.texts(exercise, sameLanguage: sameLanguage),
      features.textOf('usage'),
      for (final block in features.pageBlocks)
        if (block.isAudio)
          block.text
        else if (block.isText && block.readAloud == true)
          block.text
              .split('\n')
              .map(InlineMarks.plain)
              .where((line) => line.trim().isNotEmpty)
              .join('\n'),
    ];
    final seen = <String>{};
    return [
      for (final text in texts.map((text) => text.trim()))
        if (text.isNotEmpty && seen.add(text)) text,
    ];
  }

  /// For each recording's ID, the exercises that play it, in Course order.
  /// [segment] is playback's own rule: the recordings that say a text from
  /// end to end, or null.
  static Map<String, List<AudioClipUse>> usesByClip(
    Course course,
    List<CourseAudioClip>? Function(String text) segment,
  ) {
    final uses = <String, List<AudioClipUse>>{};
    // Build 275 Revision 3: a same-language Course's meanings are heard too.
    final sameLanguage = CourseLanguagePair.isSameLanguage(course);
    for (final (lessonIndex, lesson) in course.lessons.indexed) {
      for (final (roundIndex, round) in lesson.rounds.indexed) {
        for (final (exerciseIndex, exercise) in round.exercises.indexed) {
          final clipIds = <String>{
            for (final text in spokenTexts(
              exercise,
              sameLanguage: sameLanguage,
            ))
              ...?segment(text)?.map((clip) => clip.id),
            // Build 274 Revision 3: the recordings answers name by their id.
            ...SoundAnswers.recordingIds(exercise),
          };
          for (final id in clipIds) {
            uses
                .putIfAbsent(id, () => [])
                .add(
                  AudioClipUse(
                    lessonIndex: lessonIndex,
                    roundIndex: roundIndex,
                    exerciseIndex: exerciseIndex,
                    exercise: exercise,
                  ),
                );
          }
        }
      }
    }
    return uses;
  }

  /// The recordings with a text that no exercise plays. Recordings without
  /// text are not listed: the Audio Library shows them under #.
  /// The exercises whose answers name the recording [clipId] by its id
  /// (Build 274 Revision 3), in Course order: deleting the recording leaves
  /// those answers without a sound.
  static List<AudioClipUse> answersNaming(Course course, String clipId) => [
    for (final (lessonIndex, lesson) in course.lessons.indexed)
      for (final (roundIndex, round) in lesson.rounds.indexed)
        for (final (exerciseIndex, exercise) in round.exercises.indexed)
          if (SoundAnswers.recordingIds(exercise).contains(clipId))
            AudioClipUse(
              lessonIndex: lessonIndex,
              roundIndex: roundIndex,
              exerciseIndex: exerciseIndex,
              exercise: exercise,
            ),
  ];

  static List<CourseAudioClip> unused(
    Course course,
    Map<String, List<AudioClipUse>> uses,
  ) => [
    for (final clip in course.audioLibrary)
      if (clip.text.trim().isNotEmpty && !uses.containsKey(clip.id)) clip,
  ];
}
