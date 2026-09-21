import 'dart:convert';

/// Structural limits checked on JSON text before `jsonDecode` builds it, so
/// a small file cannot make the decoder nest thousands of levels deep or
/// build one enormous string or list.
class JsonLimits {
  const JsonLimits({
    this.maxDepth = 64,
    this.maxStringLength = 1024 * 1024,
    this.maxArrayLength = 100000,
  });

  final int maxDepth;

  /// In UTF-16 code units of the raw (still escaped) text, which is never
  /// shorter than the decoded string.
  final int maxStringLength;
  final int maxArrayLength;

  static const imports = JsonLimits();

  /// Throws [FormatException] naming [what] when [text] goes past a limit.
  /// Malformed JSON is left for `jsonDecode` to report.
  void check(String text, {String what = 'The file'}) {
    // One open array's element count per nesting level (-1 for objects).
    final counts = <int>[];
    var i = 0;
    final length = text.length;
    while (i < length) {
      final c = text.codeUnitAt(i);
      // The first element of an array counts as one.
      if (c > 0x20 && c != 0x5d && counts.isNotEmpty && counts.last == 0) {
        counts[counts.length - 1] = 1;
      }
      if (c == 0x22) {
        // A string: find its end, skipping escapes.
        final start = i;
        i++;
        while (i < length) {
          final d = text.codeUnitAt(i);
          if (d == 0x5c) {
            i += 2;
            continue;
          }
          if (d == 0x22) break;
          i++;
        }
        if (i - start - 1 > maxStringLength) {
          throw FormatException(
            '$what contains text longer than ${_size(maxStringLength)}.',
          );
        }
        i++;
        continue;
      }
      if (c == 0x5b || c == 0x7b) {
        counts.add(c == 0x5b ? 0 : -1);
        if (counts.length > maxDepth) {
          throw FormatException(
            '$what is nested more than $maxDepth levels deep.',
          );
        }
      } else if (c == 0x5d || c == 0x7d) {
        if (counts.isNotEmpty) counts.removeLast();
      } else if (c == 0x2c) {
        if (counts.isNotEmpty && counts.last >= 0) {
          final next = counts.last + 1;
          if (next > maxArrayLength) {
            throw FormatException(
              '$what contains a list of more than $maxArrayLength items.',
            );
          }
          counts[counts.length - 1] = next;
        }
      }
      i++;
    }
  }

  /// [check], then `jsonDecode`. Malformed JSON becomes [FormatException]
  /// with [invalidMessage].
  Object? decode(
    String text, {
    String what = 'The file',
    required String invalidMessage,
  }) {
    check(text, what: what);
    try {
      return jsonDecode(text);
    } catch (_) {
      throw FormatException(invalidMessage);
    }
  }

  static String _size(int characters) => characters >= 1024 * 1024
      ? '${characters ~/ (1024 * 1024)} MB'
      : '${characters ~/ 1024} KB';
}

/// Element counts an imported Course may have, checked on the decoded JSON
/// before the Course is built. Far above any real Course; they only stop a
/// file from making QQL build millions of objects.
abstract final class CourseShapeLimits {
  static const maxLessons = 500;
  static const maxRoundsPerLesson = 100;
  static const maxContentPerRound = 1000;
  static const maxAudioClips = 20000;

  /// Throws [FormatException] when [json] (a Course) has too many elements,
  /// or a NUL character in an identity or name field.
  static void check(Map json) {
    noNul(json, const [
      'courseId',
      'title',
      'publisherId',
      'publisherName',
      'originalCourseCreator',
    ], what: 'The Course');
    final lessons = _list(json['lessons']);
    _count(lessons, maxLessons, 'Lessons');
    _count(_list(json['audioLibrary']), maxAudioClips, 'recordings');
    for (final lesson in lessons.whereType<Map>()) {
      noNul(lesson, const ['lessonId', 'title'], what: 'A Lesson');
      final rounds = _list(lesson['rounds']);
      _count(rounds, maxRoundsPerLesson, 'Rounds in one Lesson');
      final guidebook = lesson['guidebook'];
      if (guidebook is Map) {
        _count(
          _list(guidebook['content']),
          maxContentPerRound,
          'GuideBook items in one Lesson',
        );
      }
      for (final round in rounds.whereType<Map>()) {
        noNul(round, const ['id', 'title'], what: 'A Round');
        _count(
          _list(round['content']),
          maxContentPerRound,
          'exercises in one Round',
        );
      }
    }
  }

  /// Refuses a NUL character in any of [keys] of [map].
  static void noNul(Map map, List<String> keys, {required String what}) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.contains(String.fromCharCode(0))) {
        throw FormatException('$what field "$key" contains a NUL character.');
      }
    }
  }

  static List _list(Object? value) => value is List ? value : const [];

  static void _count(List list, int max, String what) {
    if (list.length > max) {
      throw FormatException('The Course has more than $max $what.');
    }
  }
}
