import '../models/course_models.dart';
import 'audio_library_index.dart';
import 'audio_segmenter.dart';
import 'course_audio_usage.dart';
import 'course_language_pair.dart';
import 'exercise_search_service.dart';
import 'storage/course_storage_names.dart';

/// How far the recordings of a Course go in saying one of its texts.
enum AudioTextState {
  /// One recording says exactly this text.
  ownRecording,

  /// Recordings of its parts join into it.
  allParts,

  /// Recordings say some of its parts; the rest is missing.
  someParts,

  /// No recording says any of it.
  none,
}

/// One text a Course speaks, with what its Audio Library has for it.
class CourseSpokenText {
  const CourseSpokenText({
    required this.text,
    required this.exercises,
    required this.draft,
    required this.state,
    required this.missing,
  });

  final String text;

  /// How many exercises say it.
  final int exercises;

  /// Whether only Draft exercises say it (or exercises of a Draft Round or
  /// Lesson): learners do not hear it yet.
  final bool draft;

  final AudioTextState state;

  /// The words no recording says, for [AudioTextState.someParts].
  final List<String> missing;

  /// Whether playback finds recordings for the whole text.
  bool get complete =>
      state == AudioTextState.ownRecording || state == AudioTextState.allParts;
}

/// Build 271 Revision 2 (owner decisions of 10 and 11 October 2026): Texts
/// in this Course, the list an author records from. Every text the Course
/// speaks ([CourseAudioUsage.spokenTexts]), Draft exercises included, in
/// alphabetical order without regard to accents and punctuation, each with
/// how many exercises say it and how far the recordings go. Pure Dart.
abstract final class CourseAudioTexts {
  static List<CourseSpokenText> of(Course course) {
    final counts = <String, int>{};
    final published = <String>{};
    // Build 275 Revision 3: a same-language Course's meanings are heard too.
    final sameLanguage = CourseLanguagePair.isSameLanguage(course);
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        final delivered =
            lesson.publicationState == PublicationState.published &&
            round.publicationState == PublicationState.published;
        for (final exercise in round.exercises) {
          for (final text in CourseAudioUsage.spokenTexts(
            exercise,
            sameLanguage: sameLanguage,
          )) {
            counts.update(text, (count) => count + 1, ifAbsent: () => 1);
            if (delivered &&
                exercise.publicationState == PublicationState.published) {
              published.add(text);
            }
          }
        }
      }
    }
    final texts = counts.keys.toList()
      ..sort((a, b) {
        final byKey = AudioLibraryIndex.sortKey(
          a,
        ).compareTo(AudioLibraryIndex.sortKey(b));
        return byKey != 0 ? byKey : a.compareTo(b);
      });
    return [
      for (final text in texts) _describe(course, text, counts, published),
    ];
  }

  static CourseSpokenText _describe(
    Course course,
    String text,
    Map<String, int> counts,
    Set<String> published,
  ) {
    final coverage = AudioSegmenter.coverage(text, course.audioLibrary);
    final state = coverage.complete
        ? (coverage.clips.length == 1
              ? AudioTextState.ownRecording
              : AudioTextState.allParts)
        : coverage.clips.isEmpty
        ? AudioTextState.none
        : AudioTextState.someParts;
    return CourseSpokenText(
      text: text,
      exercises: counts[text]!,
      draft: !published.contains(text),
      state: state,
      missing: state == AudioTextState.someParts ? coverage.missing : const [],
    );
  }

  /// The few words shown beside the state's dot.
  static String stateLabel(CourseSpokenText text) => switch (text.state) {
    AudioTextState.ownRecording => 'Its own recording',
    AudioTextState.allParts => 'All parts recorded',
    AudioTextState.someParts =>
      'Some parts recorded, still missing: ${text.missing.join(', ')}',
    AudioTextState.none => 'No recording',
  };

  /// "3 exercises", "1 exercise".
  static String exercisesLabel(CourseSpokenText text) =>
      '${text.exercises} exercise${text.exercises == 1 ? '' : 's'}';

  /// The texts [query] finds, capitals and accents ignored; all of them for
  /// an empty query. [onlyIncomplete] keeps the texts without a complete
  /// recording, for a recording session.
  static List<CourseSpokenText> filtered(
    List<CourseSpokenText> texts, {
    String query = '',
    bool onlyIncomplete = false,
  }) {
    final wanted = ExerciseSearchService.normalize(query.trim());
    return [
      for (final text in texts)
        if ((!onlyIncomplete || !text.complete) &&
            (wanted.isEmpty ||
                ExerciseSearchService.normalize(text.text).contains(wanted)))
          text,
    ];
  }

  /// One text on one line, for Copy and Save as…: the text (its lines
  /// joined), its state and the Draft mark.
  static String line(CourseSpokenText text) =>
      '${text.text.split(RegExp(r'\s*\n\s*')).join(' ')}'
      '\t${stateLabel(text)}'
      '${text.draft ? '\tDraft' : ''}';

  /// [texts] as the file Save as… writes and Copy puts on the clipboard.
  static String export(List<CourseSpokenText> texts) =>
      texts.isEmpty ? '' : '${texts.map(line).join('\n')}\n';

  /// The name Save as… suggests for the texts of [course]:
  /// `QQL_<pair>_<title>_texts.txt`.
  static String exportFileName(Course course) {
    final base = CourseStorageNames.exportBaseName(
      pair: CourseStorageNames.pairOfCourse(course),
      title: course.title,
    );
    return '${base}_texts.txt';
  }

  /// The other recording that already says [text] by itself, when giving
  /// [text] to the recording [clipId] would leave two for one text.
  static CourseAudioClip? ownRecordingOf(
    String text,
    List<CourseAudioClip> library, {
    required String except,
  }) {
    final key = AudioSegmenter.key(text);
    if (key.isEmpty) return null;
    for (final clip in library) {
      if (clip.id != except && AudioSegmenter.key(clip.text) == key) {
        return clip;
      }
    }
    return null;
  }
}
