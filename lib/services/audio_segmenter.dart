import '../models/course_models.dart';

/// How much of one text the recordings of an Audio Library say.
class AudioCoverage {
  const AudioCoverage({required this.clips, required this.missing});

  /// The recordings that say parts of the text, in order.
  final List<CourseAudioClip> clips;

  /// The runs of words no recording says, as written, without the
  /// punctuation around them.
  final List<String> missing;

  /// Whether recordings say the text from beginning to end, so playback
  /// joins them.
  bool get complete => missing.isEmpty && clips.isNotEmpty;
}

/// The one rule that matches a text to the recordings of an Audio Library
/// (pure Dart; `RecordedAudioService.segment` is this rule): capitals,
/// spaces and the punctuation around a text do not count, and the longest
/// recording that fits is taken first, so a one-word recording never takes
/// the place of a recording of the whole expression.
abstract final class AudioSegmenter {
  static final RegExp _nonWordBoundary = RegExp(
    r'^[^\p{L}\p{M}\p{N}]+|[^\p{L}\p{M}\p{N}]+$',
    unicode: true,
  );
  static final RegExp _spaces = RegExp(r'\s+');

  /// What two texts must share to be the same text for a recording.
  static String key(String value) => value
      .trim()
      .replaceAll(_spaces, ' ')
      .replaceAll(_nonWordBoundary, '')
      .toLowerCase();

  static Map<String, CourseAudioClip> _byKey(List<CourseAudioClip> library) => {
    for (final clip in library)
      if (key(clip.text).isNotEmpty) key(clip.text): clip,
  };

  /// The recordings that say [text] from beginning to end, or null when a
  /// word of it has none.
  static List<CourseAudioClip>? segment(
    String text,
    List<CourseAudioClip> library,
  ) {
    final words = text.trim().split(_spaces);
    if (words.isEmpty) return const [];
    final byText = _byKey(library);
    final out = <CourseAudioClip>[];
    var i = 0;
    while (i < words.length) {
      CourseAudioClip? found;
      var foundLength = 0;
      for (var length = words.length - i; length >= 1; length--) {
        final raw = key(words.sublist(i, i + length).join(' '));
        if (byText.containsKey(raw)) {
          found = byText[raw];
          foundLength = length;
          break;
        }
      }
      if (found == null) return null;
      out.add(found);
      i += foundLength;
    }
    return out;
  }

  /// [segment] that goes on past a word without a recording (Build 271
  /// Revision 2): the recordings that say parts of [text] and the words
  /// still missing. For a text recordings say whole, the same recordings as
  /// [segment].
  static AudioCoverage coverage(String text, List<CourseAudioClip> library) {
    final words = text.trim().isEmpty
        ? const <String>[]
        : text.trim().split(_spaces);
    final byText = _byKey(library);
    final clips = <CourseAudioClip>[];
    final missing = <String>[];
    final run = <String>[];
    void closeRun() {
      if (run.isEmpty) return;
      final written = run.join(' ').replaceAll(_nonWordBoundary, '');
      if (written.isNotEmpty) missing.add(written);
      run.clear();
    }

    var i = 0;
    while (i < words.length) {
      CourseAudioClip? found;
      var foundLength = 0;
      for (var length = words.length - i; length >= 1; length--) {
        final raw = key(words.sublist(i, i + length).join(' '));
        if (byText.containsKey(raw)) {
          found = byText[raw];
          foundLength = length;
          break;
        }
      }
      if (found == null) {
        // A word of punctuation alone needs no recording.
        if (key(words[i]).isNotEmpty) run.add(words[i]);
        i++;
        continue;
      }
      closeRun();
      clips.add(found);
      i += foundLength;
    }
    closeRun();
    return AudioCoverage(
      clips: List.unmodifiable(clips),
      missing: List.unmodifiable(missing),
    );
  }
}
