import '../models/course_models.dart';
import '../models/exercise_image_metadata.dart';
import '../models/guidebook_text.dart';
import '../models/image_categories.dart';
import 'course_language_resolver.dart';
import 'image_library_rules.dart';

/// Which side of a Words & Expressions entry names its picture.
enum GuidebookPictureSide { target, source }

/// What [GuidebookPictureIndex.find] found for one word: no picture, one
/// (the module page fills the row with it, marked Suggested) or several
/// (the row offers "N matching pictures").
class GuidebookPictureMatch {
  const GuidebookPictureMatch(this.pictures, {this.plural = false});

  static const none = GuidebookPictureMatch([]);

  /// The matching QQL pictures, in catalog order.
  final List<ExerciseImageMetadata> pictures;

  /// Found by the word's singular ("cats" → Cat): the picture is marked
  /// Plural.
  final bool plural;

  bool get isEmpty => pictures.isEmpty;
  bool get isSingle => pictures.length == 1;
}

/// The picture prefill of the GuideBook module page (Build 266 Revision 1,
/// owner decisions of 6–8 October 2026): which QQL picture a word names.
///
/// - Only the QQL catalog, whose names are English, and only in a Course
///   to or from English ([sideFor]).
/// - A picture's name equals the word, capitals and a leading *a*, *an* or
///   *the* ignored ("an apple" finds Apple). When none does, the word's
///   singular by the library's own rule ([imageTagKey]: "cats" finds Cat,
///   marked Plural); when none does either, the part of a name before its
///   bracket ("baker" finds Baker (man) and Baker (woman)), for the word,
///   then for its singular. An exact name always comes first: "glasses"
///   finds Glasses, "father" the Father scene, not Father (family tree).
/// - Never a character picture (the article *a* is not the letter A), a
///   Lesson icon (five repeat ordinary names) or a one-letter name (the
///   Roman numerals I, V, X; the units g, l, m: "io = I" is not the
///   numeral one).
class GuidebookPictureIndex {
  GuidebookPictureIndex._(this._byName, this._byBase);

  /// Indexes the QQL pictures of [catalog]; device pictures never match.
  factory GuidebookPictureIndex(Iterable<ExerciseImageMetadata> catalog) {
    final byName = <String, List<ExerciseImageMetadata>>{};
    final byBase = <String, List<ExerciseImageMetadata>>{};
    for (final picture in catalog) {
      if (!_eligible(picture)) continue;
      final name = key(picture.label);
      if (name.isEmpty) continue;
      (byName[name] ??= []).add(picture);
      final bracket = picture.label.indexOf('(');
      if (bracket > 0) {
        final base = key(picture.label.substring(0, bracket));
        if (base.isNotEmpty) (byBase[base] ??= []).add(picture);
      }
    }
    return GuidebookPictureIndex._(byName, byBase);
  }

  final Map<String, List<ExerciseImageMetadata>> _byName;
  final Map<String, List<ExerciseImageMetadata>> _byBase;

  static bool _eligible(ExerciseImageMetadata picture) =>
      isBundledImage(picture) &&
      picture.category != characterCategoryGroup &&
      !isCharacterCategory(picture.category) &&
      picture.category != 'lesson_icons' &&
      key(picture.label).runes.length > 1;

  /// A name or word as the prefill compares it: capitals and spacing
  /// ignored, a leading article and closing punctuation dropped.
  static String key(String value) {
    var text = normalizeImageSearchText(value);
    text = text.replaceAll(RegExp(r'[.!?;:,]+$'), '').trim();
    final article = RegExp(r'^(a|an|the) (?=\S)').firstMatch(text);
    if (article != null) text = text.substring(article.end);
    return text;
  }

  /// The side whose words name pictures in [course]: the Target when the
  /// Course teaches English, the Source when its learners speak English;
  /// null in any other Course (QQL's picture names are English).
  static GuidebookPictureSide? sideFor(Course course) {
    bool english(String? code) =>
        (code ?? '').toLowerCase().split(RegExp('[-_]')).first == 'en';
    if (english(CourseLanguageResolver.learning(course).code)) {
      return GuidebookPictureSide.target;
    }
    if (english(CourseLanguageResolver.base(course).code)) {
      return GuidebookPictureSide.source;
    }
    return null;
  }

  /// The word of [target] or [source] that names a picture on [side].
  static List<String> wordsOf(
    GuidebookPictureSide side, {
    required String target,
    required String source,
  }) => switch (side) {
    // A target's optional words: "{to} eat" tries "to eat", then "eat".
    GuidebookPictureSide.target => GuidebookText.forms(target.trim()),
    GuidebookPictureSide.source => [source.trim()],
  };

  /// The pictures [words] name, trying each word in turn.
  GuidebookPictureMatch findAny(Iterable<String> words) {
    for (final word in words) {
      final match = find(word);
      if (!match.isEmpty) return match;
    }
    return GuidebookPictureMatch.none;
  }

  /// The pictures [word] names.
  GuidebookPictureMatch find(String word) {
    final wanted = key(word);
    if (wanted.isEmpty) return GuidebookPictureMatch.none;
    final exact = _byName[wanted];
    if (exact != null) return GuidebookPictureMatch(exact);
    final singular = imageTagKey(wanted);
    final plural = singular != wanted;
    if (plural) {
      final bySingular = _byName[singular];
      if (bySingular != null) {
        return GuidebookPictureMatch(bySingular, plural: true);
      }
    }
    final byBase = _byBase[wanted];
    if (byBase != null) return GuidebookPictureMatch(byBase);
    if (plural) {
      final bySingularBase = _byBase[singular];
      if (bySingularBase != null) {
        return GuidebookPictureMatch(bySingularBase, plural: true);
      }
    }
    return GuidebookPictureMatch.none;
  }
}
