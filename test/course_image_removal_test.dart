import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_image_removal.dart';
import 'package:quisquislingo_app/services/course_image_usage.dart';
import 'package:quisquislingo_app/services/provisional_publication_service.dart';

const _house = 'assets/exercise_images/house.webp';
String _media(String c) => 'media:${c * 64}.png';
final _now = DateTime.utc(2026, 9, 21, 12);

Map<String, dynamic> _image(String asset) => {
  'role': 'clue',
  'type': 'image',
  'asset': asset,
};

Map<String, dynamic> _presentation(String id, String asset) => {
  'id': id,
  'publicationState': 'published',
  'kind': 'presentation',
  'required': false,
  'presentation': {
    'content': [_image(asset)],
  },
};

/// The demo Course plus:
/// - `iw1`: an image_word exercise, which needs its image (house.webp);
/// - an optional clue image (media a) on the first choice exercise;
/// - a presentation with media b, a GuideBook presentation with media c;
/// - the cover media 0, and an unrelated image (media e) elsewhere.
Course _course() {
  final json =
      jsonDecode(
            File(
              'demo_courses/italian_demo_2_pick_the_translation.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final lesson = (json['lessons'] as List).first as Map;
  final content = ((lesson['rounds'] as List).first as Map)['content'] as List;
  ((content.first as Map)['exercise']['prompt'] as List).add(
    _image(_media('a')),
  );
  final imageWord = Exercise(
    id: 'iw1',
    type: 'image_word',
    prompt: 'Build the word',
    question: '',
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const ['c', 'a', 's', 'a'],
    orderAnswer: const ['c', 'a', 's', 'a'],
    pairs: const [],
    hint: '',
    icons: const [],
    imageAsset: _house,
  );
  content.add(LearningContent.fromExercise(imageWord).toJson());
  content.add(_presentation('pres_b', _media('b')));
  content.add(_presentation('pres_z', _media('e')));
  final guidebook = (lesson['guidebook'] ??= <String, dynamic>{}) as Map;
  (guidebook['content'] ??= <dynamic>[]).add(
    _presentation('gb_c', _media('c')),
  );
  json['coverImage'] = _media('0');
  return Course.fromJson(json);
}

LearningContent _content(Course course, String id) => [
  for (final lesson in course.lessons) ...[
    for (final round in lesson.rounds) ...round.content,
    ...lesson.guidebook.content,
  ],
].singleWhere((content) => content.id == id);

void main() {
  test('an exercise that needs its image becomes Draft', () {
    final course = _course();
    expect(
      _content(course, 'iw1').publicationState,
      PublicationState.published,
    );
    final houseUses = CourseImageUsage.uses(
      course,
    ).where((use) => use.asset == _house).length;
    final result = CourseImageRemoval.remove(course, {_house}, now: _now);
    expect(result.clearedUses, houseUses);
    expect(result.draftedContentIds, contains('iw1'));
    expect(CourseImageUsage.usedAssets(result.course), isNot(contains(_house)));
    final after = _content(result.course, 'iw1');
    expect(after.publicationState, PublicationState.draft);
    expect(after.exercise!.imageAsset, isEmpty);
    expect(after.exercise!.updatedAt, _now);
    expect(result.course.lessons.first.rounds.first.updatedAt, _now);
    expect(result.course.lessons.first.updatedAt, _now);
    // The Course Editor applies the change through the normal Draft
    // reconciliation, which must not publish the exercise again.
    final reconciled = const ProvisionalPublicationService().reconcile(
      result.course,
      updatedAt: _now,
      previous: course,
    );
    expect(
      _content(reconciled, 'iw1').publicationState,
      PublicationState.draft,
    );
  });

  test('an optional image is cleared and the exercise stays Published', () {
    final course = _course();
    final id = course.lessons.first.rounds.first.content.first.id;
    final result = CourseImageRemoval.remove(course, {_media('a')}, now: _now);
    expect(result.clearedUses, 1);
    expect(result.draftedContentIds, isEmpty);
    expect(
      _content(result.course, id).publicationState,
      PublicationState.published,
    );
    expect(
      CourseImageUsage.usedAssets(result.course),
      isNot(contains(_media('a'))),
    );
  });

  test('presentation, GuideBook and cover uses are all cleared', () {
    final course = _course();
    final result = CourseImageRemoval.remove(course, {
      _media('b'),
      _media('c'),
      _media('0'),
    }, now: _now);
    expect(result.clearedUses, 3);
    final used = CourseImageUsage.usedAssets(result.course);
    for (final gone in [_media('b'), _media('c'), _media('0')]) {
      expect(used, isNot(contains(gone)));
    }
    expect(result.course.coverImage, isEmpty);
    // Unrelated images and content are untouched.
    expect(used, containsAll([_media('e'), _media('a'), _house]));
    expect(
      _content(result.course, 'pres_z').presentation!.content.single.asset,
      _media('e'),
    );
  });

  test('an unused asset changes nothing', () {
    final course = _course();
    final result = CourseImageRemoval.remove(course, {_media('9')}, now: _now);
    expect(result.clearedUses, 0);
    expect(result.draftedContentIds, isEmpty);
    expect(jsonEncode(result.course.toJson()), jsonEncode(course.toJson()));
  });

  test('content already Draft stays Draft and is not reported again', () {
    final json = _course().toJson();
    final content =
        ((json['lessons'] as List).first['rounds'] as List).first['content']
            as List;
    content.firstWhere((c) => c['id'] == 'iw1')['publicationState'] = 'draft';
    final result = CourseImageRemoval.remove(
      Course.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>),
      {_house},
      now: _now,
    );
    expect(result.draftedContentIds, isNot(contains('iw1')));
    expect(
      _content(result.course, 'iw1').publicationState,
      PublicationState.draft,
    );
  });
}
