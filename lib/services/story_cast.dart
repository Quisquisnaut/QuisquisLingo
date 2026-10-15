import 'dart:convert';

import '../models/course_models.dart';

/// Who speaks in a Course's Stories (Build 273 Revision 0): the one owner of
/// the rules the Course Editor's Story characters and the Story Wizard
/// share. Pure Dart: a Course in, a Course, a number or a text out.
///
/// The runtime and the Audit find a line's speaker through
/// [Course.speakerOf]; this class decides how the cast is written into a
/// Course and what the editor says about it.
class StoryCast {
  StoryCast._();

  /// The line under a speaker's name: the language it speaks and its voice.
  static String describe(StorySpeaker speaker) =>
      '${speaker.language == TextLanguage.source ? 'Source' : 'Target'} '
      'language · voice ${speaker.voice.serialized}';

  /// The Course Editor's Story characters tile: who narrates and how many
  /// characters there are.
  static String summaryOf(Course course) {
    final narrator = course.narrator.name;
    final count = course.storyCharacters.length;
    return '${narrator.isEmpty ? 'Unnamed narrator' : 'Narrator: $narrator'} · '
        '$count character${count == 1 ? '' : 's'}';
  }

  /// How many Dialogue lines of [course] name [speakerId]: every exercise of
  /// every Lesson and Round whose prompt has an element with that speaker.
  static int linesSpokenBy(Course course, String speakerId) {
    var count = 0;
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        for (final content in round.content) {
          final exercise = content.exercise;
          if (exercise != null &&
              exercise.promptElements.any(
                (element) => element.speakerId == speakerId,
              )) {
            count++;
          }
        }
      }
    }
    return count;
  }

  /// Why a character cannot be removed: [lines] Dialogue lines still name
  /// it (owner decision: no silent fallback to the narrator).
  static String stillSpeaksMessage(int lines) =>
      '$lines Dialogue line${lines == 1 ? '' : 's'} of this Course name this character. Give those lines another speaker first; QQL never hands them to the narrator silently.';

  /// [characters] with [speaker] in place of the character that has its id;
  /// the others stay in their order.
  static List<StorySpeaker> replacing(
    List<StorySpeaker> characters,
    StorySpeaker speaker,
  ) => [
    for (final character in characters)
      character.id == speaker.id ? speaker : character,
  ];

  /// [characters] without the one whose id is [speakerId].
  static List<StorySpeaker> without(
    List<StorySpeaker> characters,
    String speakerId,
  ) => [
    for (final character in characters)
      if (character.id != speakerId) character,
  ];

  /// [course] with the Story [narrator] and [characters] and any new media
  /// [credits], each credit once (Build 256 Revision 5). One narrator rule
  /// for the Course Editor and the Story Wizard (Build 270 Revision 10
  /// follow-up, owner decision): a narrator is stored only when the Course
  /// already has one or it differs from the Course's narrator (the default,
  /// when it has none), so saving the default narrator unchanged changes
  /// nothing.
  static Course withSpeakers(
    Course course, {
    required StorySpeaker narrator,
    required List<StorySpeaker> characters,
    List<CourseMediaAttribution> credits = const [],
  }) {
    final json = {...course.toJson()}
      ..remove('storyNarrator')
      ..remove('storyCharacters')
      ..remove('mediaAttributions');
    final known = [...course.mediaAttributions];
    for (final credit in credits) {
      if (!known.any(
        (item) => jsonEncode(item.toJson()) == jsonEncode(credit.toJson()),
      )) {
        known.add(credit);
      }
    }
    final sameNarrator =
        jsonEncode(narrator.toJson()) == jsonEncode(course.narrator.toJson());
    return Course.fromJson({
      ...json,
      if (course.storyNarrator != null || !sameNarrator)
        'storyNarrator': narrator.toJson(),
      if (characters.isNotEmpty)
        'storyCharacters': [
          for (final character in characters) character.toJson(),
        ],
      if (known.isNotEmpty)
        'mediaAttributions': [for (final item in known) item.toJson()],
    });
  }
}
