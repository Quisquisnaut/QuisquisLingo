import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_image_usage.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';

/// The storage rule as it stood before `CourseImageUsage`: every
/// `{type: image, asset: media:…}` anywhere in the Lessons' JSON, plus Audio
/// Library clips and the cover. Kept as the reference the single rule must
/// match, so storage keeps exactly the files it always kept.
Set<String> _jsonWalkReferences(Course course) {
  final out = <String>{};
  for (final clip in course.audioLibrary) {
    if (CourseMediaStore.isReference(clip.filePath)) out.add(clip.filePath);
  }
  if (CourseMediaStore.isReference(course.coverImage)) {
    out.add(course.coverImage);
  }
  void visit(Object? node) {
    if (node is Map) {
      final asset = node['asset'];
      if (node['type'] == 'image' &&
          asset is String &&
          CourseMediaStore.isReference(asset)) {
        out.add(asset);
      }
      node.values.forEach(visit);
    } else if (node is List) {
      node.forEach(visit);
    }
  }

  visit([for (final lesson in course.lessons) lesson.toJson()]);
  return out;
}

Map<String, dynamic> _demoJson() =>
    jsonDecode(
          File(
            'demo_courses/italian_demo_2_pick_the_translation.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

String _media(String c) => 'media:${c * 64}.png';

Map<String, dynamic> _image(String asset) => {
  'role': 'clue',
  'type': 'image',
  'asset': asset,
};

/// A Course with an image in every place a Lesson can hold one.
Course _everywhere() {
  final json = _demoJson();
  final lesson = (json['lessons'] as List).first as Map;
  final round = (lesson['rounds'] as List).first as Map;
  final content = round['content'] as List;
  final exercise = (content.first as Map)['exercise'] as Map;
  (exercise['prompt'] as List).add(_image(_media('a')));
  final interaction = exercise['interaction'] as Map;
  ((interaction['items'] as List).first as Map)['content'].add(
    _image(_media('b')),
  );
  (interaction['layout'] ??= <dynamic>[]).add(_image(_media('c')));
  Map<String, dynamic> presentation(String id, String asset, {String? role}) =>
      {
        'id': id,
        'publicationState': 'published',
        'kind': 'presentation',
        'required': false,
        if (role != null) 'role': role,
        'presentation': {
          'content': [_image(asset)],
        },
      };
  content.add(presentation('usage_pres', _media('d')));
  content.insert(
    0,
    presentation('usage_intro', _media('e'), role: 'lesson_intro'),
  );
  final guidebook = (lesson['guidebook'] ??= <String, dynamic>{}) as Map;
  (guidebook['content'] ??= <dynamic>[]).add(
    presentation('usage_gb', _media('f')),
  );
  json['coverImage'] = _media('0');
  return Course.fromJson(json);
}

void main() {
  test('finds an image in every place a Lesson can hold one', () {
    final course = _everywhere();
    final uses = CourseImageUsage.uses(course);
    final assets = {for (final use in uses) use.asset};
    for (final c in ['a', 'b', 'c', 'd', 'e', 'f', '0']) {
      expect(assets, contains(_media(c)), reason: 'image $c');
    }
    final cover = uses.singleWhere((use) => use.asset == _media('0'));
    expect(cover.location, 'Course cover');
    expect(cover.element, isNull);
    final guidebook = uses.singleWhere((use) => use.asset == _media('f'));
    expect(guidebook.location, startsWith('Lesson 1 › GuideBook › item '));
    final intro = uses.singleWhere((use) => use.asset == _media('e'));
    expect(intro.location, 'Lesson 1 › Round 1 › item 1');
  });

  test('storage keeps exactly what the whole-JSON search kept', () {
    final course = _everywhere();
    expect(CourseMediaStore.referencesOf(course), _jsonWalkReferences(course));
  });

  test('every bundled and demo Course gives the same references', () {
    final files = [
      ...Directory('assets/courses').listSync().whereType<File>(),
      ...Directory('demo_courses').listSync().whereType<File>(),
    ].where((file) => file.path.endsWith('.json'));
    expect(files, isNotEmpty);
    for (final file in files) {
      final course = Course.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      expect(
        CourseMediaStore.referencesOf(course),
        _jsonWalkReferences(course),
        reason: file.path,
      );
    }
  });

  test('the Shared Image Library source is found wherever the image is', () {
    final json = _demoJson();
    final lesson = (json['lessons'] as List).first as Map;
    final guidebook = (lesson['guidebook'] ??= <String, dynamic>{}) as Map;
    const source = SharedImageSource(
      id: 'cat-01',
      label: 'Cat',
      category: 'animals',
      tags: ['cat'],
      origin: 'local',
    );
    (guidebook['content'] ??= <dynamic>[]).add({
      'id': 'gb_source',
      'publicationState': 'published',
      'kind': 'presentation',
      'required': false,
      'presentation': {
        'content': [
          {..._image(_media('9')), 'sharedImageSource': source.toJson()},
        ],
      },
    });
    final course = Course.fromJson(json);
    expect(CourseImageUsage.sharedSourceOf(course, _media('9'))?.id, 'cat-01');
    expect(CourseImageUsage.sharedSourceOf(course, _media('8')), isNull);
  });

  test('a Course without a cover lists only its element images', () {
    final json = _demoJson()..remove('coverImage');
    final course = Course.fromJson(json);
    expect(CourseImageUsage.usedAssets(course), {
      for (final element in CourseImageUsage.imageElements(course))
        element.asset,
    });
    expect(
      CourseImageUsage.uses(
        course,
      ).any((use) => use.location == 'Course cover'),
      isFalse,
    );
  });
}
