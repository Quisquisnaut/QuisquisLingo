import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_image_removal.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';

String _media(String c) => 'media:${c * 64}.png';

Map<String, dynamic> _json() =>
    jsonDecode(
          File(
            'demo_courses/italian_demo_2_pick_the_translation.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

const _source = SharedImageSource(
  id: 'cat-01',
  label: 'Cat',
  category: 'animals',
  tags: ['cat'],
  origin: 'local',
);

void main() {
  test('a Course without a library is byte-identical', () {
    final json = _json();
    final course = Course.fromJson(json);
    expect(course.imageLibrary, isEmpty);
    expect(course.toJson().containsKey('imageLibrary'), isFalse);
  });

  test('entries round-trip, with or without a Shared source', () {
    final json = _json()
      ..['imageLibrary'] = [
        {'asset': _media('a')},
        {'asset': _media('b'), 'sharedImageSource': _source.toJson()},
      ];
    final course = Course.fromJson(json);
    expect(course.imageLibrary.map((e) => e.asset), [_media('a'), _media('b')]);
    expect(course.imageLibrary.last.sharedImageSource?.id, 'cat-01');
    final again = Course.fromJson(
      jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>,
    );
    expect(jsonEncode(again.toJson()), jsonEncode(course.toJson()));
  });

  test('invalid entries are refused', () {
    for (final bad in [
      'not a list',
      [
        {'asset': 'assets/exercise_images/apple.webp'},
      ],
      [
        {'asset': _media('a'), 'extra': 1},
      ],
      [
        {'asset': _media('a')},
        {'asset': _media('a')},
      ],
      ['x'],
    ]) {
      expect(
        () => Course.fromJson(_json()..['imageLibrary'] = bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });

  test('storage keeps unused library images', () {
    final course = Course.fromJson(
      _json()
        ..['imageLibrary'] = [
          {'asset': _media('c')},
        ],
    );
    expect(CourseMediaStore.referencesOf(course), contains(_media('c')));
  });

  test('updateLibrary adds and removes entries', () {
    final course = Course.fromJson(_json());
    final kept = CourseImageRemoval.updateLibrary(
      course,
      keep: {_media('a'): null, _media('b'): _source},
    );
    expect(kept.imageLibrary.map((e) => e.asset), [_media('a'), _media('b')]);
    expect(kept.imageLibrary.last.sharedImageSource?.id, 'cat-01');
    final removed = CourseImageRemoval.updateLibrary(
      kept,
      remove: {_media('a')},
    );
    expect(removed.imageLibrary.map((e) => e.asset), [_media('b')]);
    final empty = CourseImageRemoval.updateLibrary(
      removed,
      remove: {_media('b')},
    );
    expect(empty.toJson().containsKey('imageLibrary'), isFalse);
  });

  test('Copy as New Course keeps the library', () {
    final course = Course.fromJson(
      _json()
        ..['imageLibrary'] = [
          {'asset': _media('d'), 'sharedImageSource': _source.toJson()},
        ],
    );
    final copy = AuthoringDuplicationService().copyCourseAsNew(
      course,
      title: 'Copy',
      originalCourseCreator: course.originalCourseCreator,
      maintainer: course.maintainer!,
    );
    expect(copy.imageLibrary.single.asset, _media('d'));
    expect(copy.imageLibrary.single.sharedImageSource?.id, 'cat-01');
  });
}
