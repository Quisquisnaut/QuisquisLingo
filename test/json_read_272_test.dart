import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/json_read.dart';
import 'package:quisquislingo_app/services/course_service.dart';

/// Build 272 Revision 9: the Course models read a file's JSON through shared
/// readers. This first group was written before the readers were shared, on
/// the Laboratory's own file changed in one place each, and is unchanged by
/// the change: what a broken file is told stays word for word.
Map<String, dynamic> _copy(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

/// The first map under [node] that [test] accepts, depth first.
Map<String, dynamic>? _find(
  Object? node,
  bool Function(Map<String, dynamic>) test,
) {
  if (node is Map<String, dynamic>) {
    if (test(node)) return node;
    for (final value in node.values) {
      final found = _find(value, test);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final value in node) {
      final found = _find(value, test);
      if (found != null) return found;
    }
  }
  return null;
}

Matcher _refuses(String message) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', message),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('what a broken Course file is told', () {
    late Map<String, dynamic> laboratory;

    setUpAll(() async {
      laboratory = (await CourseService().loadBundledCourse('IT')).toJson();
      expect(
        Course.fromJson(_copy(laboratory)).courseId,
        laboratory['courseId'],
      );
    });

    Map<String, dynamic> lessonOf(Map<String, dynamic> json) =>
        (json['lessons'] as List).first as Map<String, dynamic>;
    Map<String, dynamic> roundOf(Map<String, dynamic> json) =>
        (lessonOf(json)['rounds'] as List).first as Map<String, dynamic>;
    Map<String, dynamic> contentOf(Map<String, dynamic> json) =>
        (roundOf(json)['content'] as List).first as Map<String, dynamic>;
    Map<String, dynamic> exerciseOf(Map<String, dynamic> json) => _find(
      json['lessons'],
      (map) => map['primitive'] is String && map['prompt'] is List,
    )!;
    Map<String, dynamic> evaluationOf(Map<String, dynamic> json) => _find(
      json['lessons'],
      (map) => map['mode'] is String && map['correctItemIds'] is List,
    )!;

    test('a text that must be there', () {
      final json = _copy(laboratory);
      lessonOf(json).remove('title');
      expect(
        () => Course.fromJson(json),
        _refuses('Missing or invalid lesson.title'),
      );
      lessonOf(json)['title'] = '   ';
      expect(
        () => Course.fromJson(json),
        _refuses('Missing or invalid lesson.title'),
      );
      lessonOf(json)['title'] = 7;
      expect(
        () => Course.fromJson(json),
        _refuses('Missing or invalid lesson.title'),
      );
    });

    test('a moment that must be in UTC', () {
      final json = _copy(laboratory);
      lessonOf(json)['updatedAt'] = '2026-10-03T00:00:00';
      expect(
        () => Course.fromJson(json),
        _refuses(
          'lesson.updatedAt must be an ISO 8601 UTC timestamp ending in Z.',
        ),
      );
      lessonOf(json)['updatedAt'] = 'yesterdayZ';
      expect(
        () => Course.fromJson(json),
        _refuses(
          'lesson.updatedAt must be an unambiguous ISO 8601 UTC timestamp.',
        ),
      );
      lessonOf(json).remove('updatedAt');
      expect(
        () => Course.fromJson(json),
        _refuses(
          'lesson.updatedAt must be an ISO 8601 UTC timestamp ending in Z.',
        ),
      );
    });

    test('a list the file must have: missing, of another kind, holding '
        'something that is not an object', () {
      var json = _copy(laboratory);
      lessonOf(json).remove('rounds');
      expect(
        () => Course.fromJson(json),
        _refuses('lesson.rounds must be a list.'),
      );
      json = _copy(laboratory);
      lessonOf(json)['rounds'] = 'none';
      expect(
        () => Course.fromJson(json),
        _refuses('lesson.rounds must be a list.'),
      );
      json = _copy(laboratory);
      lessonOf(json)['rounds'] = ['a Round'];
      expect(
        () => Course.fromJson(json),
        _refuses('lesson.rounds contains a non-object value.'),
      );
      json = _copy(laboratory);
      roundOf(json).remove('content');
      expect(
        () => Course.fromJson(json),
        _refuses('round.content must be a list.'),
      );
      // An exercise without its prompt is refused before its lists are
      // read, with words of its own.
      json = _copy(laboratory);
      exerciseOf(json).remove('prompt');
      expect(
        () => Course.fromJson(json),
        _refuses('Exercise requires prompt[] and an evaluation object.'),
      );
      json = _copy(laboratory);
      exerciseOf(json)['prompt'] = ['a question'];
      expect(
        () => Course.fromJson(json),
        _refuses('exercise.prompt contains a non-object value.'),
      );
      json = _copy(laboratory);
      (lessonOf(json)['guidebook'] as Map<String, dynamic>).remove('modules');
      expect(
        () => Course.fromJson(json),
        _refuses('guidebook.modules must be a list.'),
      );
    });

    test('a list the file may leave out: missing is empty; of another kind, '
        'or holding something that is not an object, is refused', () {
      var json = _copy(laboratory);
      final exercise = exerciseOf(json);
      exercise
        ..remove('targets')
        ..remove('layout');
      // The file still reads: these lists were left out.
      expect(Course.fromJson(json).courseId, laboratory['courseId']);
      json = _copy(laboratory);
      exerciseOf(json)['targets'] = 'none';
      expect(
        () => Course.fromJson(json),
        _refuses('exercise.targets must be a list.'),
      );
      json = _copy(laboratory);
      exerciseOf(json)['targets'] = [7];
      expect(
        () => Course.fromJson(json),
        _refuses('exercise.targets contains a non-object value.'),
      );
      json = _copy(laboratory);
      evaluationOf(json)['correctOrders'] = 'none';
      expect(
        () => Course.fromJson(json),
        _refuses('evaluation.correctOrders must be a list.'),
      );
      json = _copy(laboratory);
      evaluationOf(json)['correctOrders'] = ['an order'];
      expect(
        () => Course.fromJson(json),
        _refuses('evaluation.correctOrders contains a non-object value.'),
      );
    });

    test('a list of texts: the Course models name the field, the canonical '
        'exercise the place too', () {
      var json = _copy(laboratory);
      contentOf(json)['sourceRefs'] = 'one';
      expect(
        () => Course.fromJson(json),
        _refuses('sourceRefs must be a list.'),
      );
      json = _copy(laboratory);
      contentOf(json)['sourceRefs'] = ['one', 2];
      expect(
        () => Course.fromJson(json),
        _refuses('sourceRefs must contain strings only.'),
      );
      json = _copy(laboratory);
      evaluationOf(json)['correctItemIds'] = 'one';
      expect(
        () => Course.fromJson(json),
        _refuses('evaluation.correctItemIds must be a list.'),
      );
      json = _copy(laboratory);
      evaluationOf(json)['correctItemIds'] = ['one', 2];
      expect(
        () => Course.fromJson(json),
        _refuses('evaluation.correctItemIds must contain strings only.'),
      );
    });

    test('a field the canonical exercise does not know', () {
      final json = _copy(laboratory);
      evaluationOf(json)['bonus'] = true;
      expect(
        () => Course.fromJson(json),
        _refuses('evaluation contains unsupported fields: bonus.'),
      );
    });
  });

  group('JsonRead, the readers themselves', () {
    test('a text that must be there is trimmed; nothing, blanks and '
        'another kind of value are refused', () {
      expect(
        JsonRead.requiredString({'title': '  Ciao '}, 'title', 'lesson'),
        'Ciao',
      );
      for (final value in <Object?>[null, '', '   ', 7, true, <String>[]]) {
        expect(
          () => JsonRead.requiredString({'title': value}, 'title', 'lesson'),
          _refuses('Missing or invalid lesson.title'),
          reason: '$value',
        );
      }
      expect(
        () => JsonRead.requiredString({}, 'title', 'lesson'),
        _refuses('Missing or invalid lesson.title'),
      );
    });

    test('a text that may be missing: trimmed, else the fallback', () {
      expect(JsonRead.optionalString({'note': ' a '}, 'note', 'none'), 'a');
      expect(JsonRead.optionalString({'note': ''}, 'note', 'none'), '');
      expect(JsonRead.optionalString({}, 'note', 'none'), 'none');
      expect(JsonRead.optionalString({'note': 7}, 'note', 'none'), 'none');
      expect(JsonRead.optionalString({'note': null}, 'note', 'none'), 'none');
    });

    test('a whole number that may be missing', () {
      expect(JsonRead.optionalInt({'n': 3}, 'n', 1), 3);
      expect(JsonRead.optionalInt({}, 'n', 1), 1);
      expect(JsonRead.optionalInt({'n': '3'}, 'n', 1), 1);
      expect(JsonRead.optionalInt({'n': 3.5}, 'n', 1), 1);
    });

    test('a list of texts: missing is empty; the two wordings', () {
      expect(JsonRead.stringListByKey({}, 'tags'), isEmpty);
      expect(JsonRead.stringListByKey({'tags': null}, 'tags'), isEmpty);
      expect(
        JsonRead.stringListByKey({
          'tags': ['a', ' b '],
        }, 'tags'),
        ['a', ' b '],
      );
      expect(
        () => JsonRead.stringListByKey({'tags': 'a'}, 'tags'),
        _refuses('tags must be a list.'),
      );
      expect(
        () => JsonRead.stringListByKey({
          'tags': ['a', 1],
        }, 'tags'),
        _refuses('tags must contain strings only.'),
      );

      expect(JsonRead.stringList({}, 'answers', 'evaluation'), isEmpty);
      expect(
        JsonRead.stringList({'answers': null}, 'answers', 'evaluation'),
        isEmpty,
      );
      expect(
        JsonRead.stringList(
          {
            'answers': ['a', ' b '],
          },
          'answers',
          'evaluation',
        ),
        ['a', ' b '],
      );
      expect(
        () => JsonRead.stringList({'answers': 'a'}, 'answers', 'evaluation'),
        _refuses('evaluation.answers must be a list.'),
      );
      expect(
        () => JsonRead.stringList(
          {
            'answers': ['a', 1],
          },
          'answers',
          'evaluation',
        ),
        _refuses('evaluation.answers must contain strings only.'),
      );
    });

    test('a list of pairs of texts', () {
      expect(JsonRead.pairList({}, 'pairs'), isEmpty);
      expect(
        JsonRead.pairList({
          'pairs': [
            ['a', 'b'],
            ['c', 'd'],
          ],
        }, 'pairs'),
        [
          ['a', 'b'],
          ['c', 'd'],
        ],
      );
      expect(
        () => JsonRead.pairList({'pairs': 'a'}, 'pairs'),
        _refuses('pairs must be a list.'),
      );
      for (final entry in <Object?>[
        ['a'],
        ['a', 'b', 'c'],
        ['a', 1],
        'ab',
      ]) {
        expect(
          () => JsonRead.pairList({
            'pairs': [entry],
          }, 'pairs'),
          _refuses('pairs entries must contain exactly two strings.'),
          reason: '$entry',
        );
      }
    });

    test('a list of objects the file must have: missing is refused', () {
      String name(Map<String, dynamic> j) => j['name'] as String;
      expect(
        JsonRead.requiredList(
          {
            'rounds': [
              {'name': 'a'},
              {'name': 'b'},
            ],
          },
          'rounds',
          'lesson',
          name,
        ),
        ['a', 'b'],
      );
      expect(
        JsonRead.requiredList({'rounds': <Object>[]}, 'rounds', 'lesson', name),
        isEmpty,
      );
      for (final json in <Map<String, dynamic>>[
        {},
        {'rounds': null},
        {'rounds': 'none'},
        {'rounds': <String, Object>{}},
      ]) {
        expect(
          () => JsonRead.requiredList(json, 'rounds', 'lesson', name),
          _refuses('lesson.rounds must be a list.'),
          reason: '$json',
        );
      }
      expect(
        () => JsonRead.requiredList(
          {
            'rounds': [
              {'name': 'a'},
              'b',
            ],
          },
          'rounds',
          'lesson',
          name,
        ),
        _refuses('lesson.rounds contains a non-object value.'),
      );
    });

    test('a list of objects the file may leave out: missing is empty', () {
      String name(Map<String, dynamic> j) => j['name'] as String;
      expect(JsonRead.optionalList({}, 'targets', 'exercise', name), isEmpty);
      expect(
        JsonRead.optionalList({'targets': null}, 'targets', 'exercise', name),
        isEmpty,
      );
      expect(
        JsonRead.optionalList(
          {
            'targets': [
              {'name': 'a'},
            ],
          },
          'targets',
          'exercise',
          name,
        ),
        ['a'],
      );
      expect(
        () => JsonRead.optionalList(
          {'targets': 'none'},
          'targets',
          'exercise',
          name,
        ),
        _refuses('exercise.targets must be a list.'),
      );
      expect(
        () => JsonRead.optionalList(
          {
            'targets': [7],
          },
          'targets',
          'exercise',
          name,
        ),
        _refuses('exercise.targets contains a non-object value.'),
      );
    });

    test('fields nobody knows are refused, all named', () {
      JsonRead.refuseUnknownKeys({'a': 1, 'b': 2}, {'a', 'b', 'c'}, 'target');
      JsonRead.refuseUnknownKeys({}, {'a'}, 'target');
      expect(
        () => JsonRead.refuseUnknownKeys(
          {'a': 1, 'x': 2, 'y': 3},
          {'a'},
          'target',
        ),
        _refuses('target contains unsupported fields: x, y.'),
      );
    });

    test('moments: read in UTC only, written in UTC', () {
      expect(
        JsonRead.requiredUtcTimestamp(
          {'updatedAt': '2026-10-13T08:30:00.000Z'},
          'updatedAt',
          'round',
        ),
        DateTime.utc(2026, 10, 13, 8, 30),
      );
      for (final value in <Object?>[
        null,
        7,
        '2026-10-13T08:30:00',
        '2026-10-13T08:30:00+02:00',
      ]) {
        expect(
          () => JsonRead.requiredUtcTimestamp(
            {'updatedAt': value},
            'updatedAt',
            'round',
          ),
          _refuses(
            'round.updatedAt must be an ISO 8601 UTC timestamp ending in Z.',
          ),
          reason: '$value',
        );
      }
      expect(
        () => JsonRead.requiredUtcTimestamp(
          {'updatedAt': 'soonZ'},
          'updatedAt',
          'round',
        ),
        _refuses(
          'round.updatedAt must be an unambiguous ISO 8601 UTC timestamp.',
        ),
      );
      expect(
        JsonRead.timestampToJson(DateTime.utc(2026, 10, 13, 8, 30)),
        '2026-10-13T08:30:00.000Z',
      );
      final local = DateTime(2026, 10, 13, 8, 30);
      expect(JsonRead.timestampToJson(local), local.toUtc().toIso8601String());
      expect(
        JsonRead.canonicalUtcTimestamp(null),
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      expect(JsonRead.canonicalUtcTimestamp(local), local.toUtc());
      expect(JsonRead.canonicalUtcTimestamp(local).isUtc, isTrue);
    });
  });
}
