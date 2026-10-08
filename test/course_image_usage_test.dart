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
      // Build 266: a GuideBook word's picture.
      final picture = node['picture'];
      if (picture is Map &&
          picture['asset'] is String &&
          CourseMediaStore.isReference(picture['asset'] as String)) {
        out.add(picture['asset'] as String);
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

/// Build 266: a GuideBook whose one word has [asset] as its picture.
Map<String, dynamic> _guidebookWithPicture(
  String asset, {
  Map<String, dynamic>? sharedImageSource,
}) => {
  'modules': [
    {
      'id': 'usage_gb_module',
      'title': 'Animals',
      'sentences': <Object>[],
      'words': [
        {
          'id': 'usage_gb',
          'target': 'il gatto',
          'source': 'the cat',
          'picture': {
            'asset': asset,
            'sharedImageSource': ?sharedImageSource,
            'plural': true,
          },
        },
      ],
      'overview': '',
    },
  ],
};

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
  ((exercise['items'] as List).first as Map)['content'].add(
    _image(_media('b')),
  );
  // Course Model v12 layouts hold text runs and targets, never images, so
  // the third image goes into the last answer item instead.
  ((exercise['items'] as List).last as Map)['content'].add(_image(_media('c')));
  // A Presentation is a presentation-primitive exercise since v12.
  Map<String, dynamic> presentation(String id, String asset, {String? role}) =>
      {
        'id': id,
        'publicationState': 'published',
        'kind': 'exercise',
        'required': false,
        if (role != null) 'role': role,
        'exercise': {
          'updatedAt': '2026-09-01T00:00:00.000Z',
          'primitive': 'presentation',
          'prompt': [_image(asset)],
          'evaluation': {'mode': 'none'},
        },
      };
  content.add(presentation('usage_pres', _media('d')));
  content.insert(
    0,
    presentation('usage_intro', _media('e'), role: 'lesson_intro'),
  );
  lesson['guidebook'] = _guidebookWithPicture(_media('f'));
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
    expect(guidebook.location, 'Lesson 1 › GuideBook › Animals › il gatto');
    expect(guidebook.element?.isPlural, isTrue);
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
    const source = SharedImageSource(
      id: 'cat-01',
      label: 'Cat',
      category: 'animals',
      tags: ['cat'],
      origin: 'local',
    );
    lesson['guidebook'] = _guidebookWithPicture(
      _media('9'),
      sharedImageSource: source.toJson(),
    );
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
