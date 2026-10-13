/// The readers the Course models share for a Course file's JSON (Build 272
/// Revision 9). Before, `course_models.dart` and `exercise_canonical.dart`
/// each kept private copies, and two of the copies had grown different.
/// Revision 10 (owner decision of 13 October 2026) made them the same:
/// every refusal of a list names the place and the field, and a list read
/// here is read by [requiredList] (the file must have it) or by
/// [optionalList], [stringList] or [pairList] (the file may leave it out),
/// never behind a check written at the place that reads it. (The Course
/// root still reads some lists of its own with checks of its own:
/// `sectionNames`, `keywords`, `authors`, `rightsHolders`,
/// `lessonIconAssets`, `audioLibrary`, `defaultTimedLimitsSeconds`.)
///
/// A list of the wrong kind is a [FormatException] whose text names the
/// place. The texts are part of what an author reads when a file is
/// refused: do not reword them.
///
/// Pure Dart.
abstract final class JsonRead {
  /// The text at [key], trimmed; a missing, empty or non-text value is
  /// refused.
  static String requiredString(
    Map<String, dynamic> j,
    String key,
    String where,
  ) {
    final v = j[key];
    if (v is! String || v.trim().isEmpty) {
      throw FormatException('Missing or invalid $where.$key');
    }
    return v.trim();
  }

  /// The text at [key], trimmed, or [fallback] when it is not a text.
  static String optionalString(
    Map<String, dynamic> j,
    String key,
    String fallback,
  ) {
    final v = j[key];
    return v is String ? v.trim() : fallback;
  }

  /// The whole number at [key], or [fallback] when it is not one.
  static int optionalInt(Map<String, dynamic> j, String key, int fallback) {
    final v = j[key];
    return v is int ? v : fallback;
  }

  /// The texts at [key]; a missing list, or one written as null, is
  /// empty. The refusal names the place and the field.
  static List<String> stringList(
    Map<String, dynamic> j,
    String key,
    String where,
  ) {
    final v = j[key];
    if (v == null) return const [];
    if (v is! List) throw FormatException('$where.$key must be a list.');
    return [
      for (final x in v)
        if (x is String)
          x
        else
          throw FormatException('$where.$key must contain strings only.'),
    ];
  }

  /// The pairs of texts at [key]; a missing list, or one written as null,
  /// is empty. The refusal names the place and the field.
  static List<List<String>> pairList(
    Map<String, dynamic> j,
    String key,
    String where,
  ) {
    final v = j[key];
    if (v == null) return const [];
    if (v is! List) throw FormatException('$where.$key must be a list.');
    return [
      for (final x in v)
        if (x is List && x.length == 2 && x.every((e) => e is String))
          [x[0] as String, x[1] as String]
        else
          throw FormatException(
            '$where.$key entries must contain exactly two strings.',
          ),
    ];
  }

  /// The objects at [key], each read by [parser]. **A missing list is
  /// refused**: a list the file must have (see [optionalList]).
  static List<T> requiredList<T>(
    Map<String, dynamic> j,
    String key,
    String where,
    T Function(Map<String, dynamic>) parser,
  ) {
    final v = j[key];
    if (v is! List) throw FormatException('$where.$key must be a list.');
    return [
      for (final x in v)
        if (x is Map)
          parser(Map<String, dynamic>.from(x))
        else
          throw FormatException('$where.$key contains a non-object value.'),
    ];
  }

  /// The objects at [key], each read by [parser]. **A missing list, or one
  /// written as null, is empty**: a list the file may leave out (see
  /// [requiredList]). A value of another kind is refused.
  ///
  /// The empty list is a list of [T] that cannot be changed. A bare
  /// `const []` here would be a list of nothing, whatever [T] is, and
  /// looking in it with a fallback (`firstWhere(…, orElse: …)`) would throw.
  static List<T> optionalList<T>(
    Map<String, dynamic> j,
    String key,
    String where,
    T Function(Map<String, dynamic>) parser,
  ) {
    final v = j[key];
    if (v == null) return List<T>.unmodifiable(const <Never>[]);
    if (v is! List) throw FormatException('$where.$key must be a list.');
    return [
      for (final x in v)
        if (x is Map)
          parser(Map<String, dynamic>.from(x))
        else
          throw FormatException('$where.$key contains a non-object value.'),
    ];
  }

  /// Refuses an object that carries a key outside [known].
  static void refuseUnknownKeys(
    Map<String, dynamic> j,
    Set<String> known,
    String where,
  ) {
    final unknown = j.keys.where((key) => !known.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException(
        '$where contains unsupported fields: ${unknown.join(', ')}.',
      );
    }
  }

  /// [value] in UTC, or the start of the epoch when there is none.
  static DateTime canonicalUtcTimestamp(DateTime? value) =>
      (value ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)).toUtc();

  /// A moment as a Course file writes it: ISO 8601, UTC.
  static String timestampToJson(DateTime value) =>
      value.toUtc().toIso8601String();

  /// The moment at [key]: an ISO 8601 text in UTC ending in Z, else refused.
  static DateTime requiredUtcTimestamp(
    Map<String, dynamic> json,
    String key,
    String location,
  ) {
    final raw = json[key];
    if (raw is! String || !raw.endsWith('Z')) {
      throw FormatException(
        '$location.$key must be an ISO 8601 UTC timestamp ending in Z.',
      );
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null || !parsed.isUtc) {
      throw FormatException(
        '$location.$key must be an unambiguous ISO 8601 UTC timestamp.',
      );
    }
    return parsed;
  }
}
