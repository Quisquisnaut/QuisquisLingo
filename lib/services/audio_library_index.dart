import 'package:characters/characters.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import '../models/course_models.dart';
import 'exercise_search_service.dart';

/// One group of the Audio Library's index: its button, its heading and its
/// recordings in order.
class AudioLibraryGroup {
  const AudioLibraryGroup({
    required this.key,
    required this.heading,
    required this.clips,
  });

  /// The group's button, and its identity: `#`, `0–9`, a letter, or
  /// [AudioLibraryIndex.otherScripts].
  final String key;
  final String heading;
  final List<CourseAudioClip> clips;
}

/// Build 270 Revision 12 (owner decisions of 10 October 2026): how the Audio
/// Library files its recordings under the A–Z buttons.
///
/// * `#` first: recordings with no text yet.
/// * `0–9` second: texts whose first character, after any brackets, quotes,
///   dashes or sentence marks, is a digit or a symbol, or that hold nothing
///   else.
/// * Then the first letter of the text, after those marks, without its
///   accents ("[gatto]" G, "¿qué?" Q, "école" E, "ñandú" N, "øl" O): the
///   Latin letters, then Greek, then Cyrillic.
/// * Last, one group for every other script (Korean, Chinese, Arabic…).
///
/// Within a group the texts are in alphabetical order, read the same way.
abstract final class AudioLibraryIndex {
  static const noText = '#';
  static const numbersAndSymbols = '0–9';
  static const otherScripts = 'Other scripts';

  /// What is passed over before the first character that files a text:
  /// spaces, brackets, quotes, dashes and sentence marks. Other marks, as
  /// # % & * @, are symbols and file the text under 0–9.
  static final _skipped = RegExp(
    r'^[\s\p{Ps}\p{Pe}\p{Pi}\p{Pf}\p{Pd}¿¡.,;:!?…·\u0022\u0027]+$',
    unicode: true,
  );
  static final _letter = RegExp(r'^\p{L}', unicode: true);
  static final _mark = RegExp(r'\p{M}', unicode: true);
  static final _latin = RegExp(r'^\p{Script=Latin}', unicode: true);
  static final _greek = RegExp(r'^\p{Script=Greek}', unicode: true);
  static final _cyrillic = RegExp(r'^\p{Script=Cyrillic}', unicode: true);

  /// The group [text] is filed under.
  static String groupOf(String text) {
    if (text.trim().isEmpty) return noText;
    final first = text.characters.firstWhere(
      (character) => !_skipped.hasMatch(character),
      orElse: () => '',
    );
    if (!_letter.hasMatch(first)) return numbersAndSymbols;
    final letter = _base(first);
    if (_latin.hasMatch(letter) ||
        _greek.hasMatch(letter) ||
        _cyrillic.hasMatch(letter)) {
      return letter.toUpperCase();
    }
    return otherScripts;
  }

  /// [clips] in their groups, the groups in the order above.
  static List<AudioLibraryGroup> groups(List<CourseAudioClip> clips) {
    final byKey = <String, List<(int, CourseAudioClip)>>{};
    for (final (index, clip) in clips.indexed) {
      byKey.putIfAbsent(groupOf(clip.text), () => []).add((index, clip));
    }
    final keys = byKey.keys.toList()..sort(_compareKeys);
    return [
      for (final key in keys)
        AudioLibraryGroup(
          key: key,
          heading: key == noText ? '# (MP3s with no assigned text)' : key,
          clips: [
            for (final (_, clip) in byKey[key]!..sort(_compareClips)) clip,
          ],
        ),
    ];
  }

  /// The letter without its accents: the search's Latin folding (ø, æ, ß
  /// and ł included), then any mark left, as on Greek and Cyrillic letters.
  static String _base(String letter) {
    final latin = ExerciseSearchService.normalize(letter);
    final folded = unorm
        .nfd(latin.isEmpty ? letter.toLowerCase() : latin)
        .replaceAll(_mark, '');
    return folded.isEmpty ? letter : folded.characters.first;
  }

  static int _rank(String key) {
    if (key == noText) return 0;
    if (key == numbersAndSymbols) return 1;
    if (key == otherScripts) return 5;
    if (_latin.hasMatch(key)) return 2;
    if (_greek.hasMatch(key)) return 3;
    return 4;
  }

  static int _compareKeys(String a, String b) {
    final rank = _rank(a).compareTo(_rank(b));
    return rank != 0 ? rank : a.compareTo(b);
  }

  /// Alphabetical, ignoring capitals, accents and leading punctuation;
  /// recordings with no text keep the library's order.
  static int _compareClips((int, CourseAudioClip) a, (int, CourseAudioClip) b) {
    final byText = sortKey(a.$2.text).compareTo(sortKey(b.$2.text));
    if (byText != 0) return byText;
    final written = a.$2.text.compareTo(b.$2.text);
    return written != 0 ? written : a.$1.compareTo(b.$1);
  }

  /// What texts are put in order by: no capitals, accents or punctuation
  /// (also the order of Texts in this Course, Build 271 Revision 2).
  static String sortKey(String text) =>
      unorm.nfd(ExerciseSearchService.normalize(text)).replaceAll(_mark, '');
}
