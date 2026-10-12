import '../models/course_models.dart';

/// The Course-level settings an author meets as **Lesson Options**: the
/// Lesson and Round numberings, Use GuideBook, Word Lookup, Create Duels,
/// the default Timed limits and the look of picture answers.
///
/// Each function gives the Course with one setting changed; none of them
/// stores anything. The Course Editor's Lesson Options panel and the Course
/// Wizard's options step use them (Build 272 Revision 4; before, each wrote
/// the Course's JSON by itself). Pure Dart.
abstract final class LessonOptions {
  /// [course] with the settings given; a setting left out stays as it is.
  ///
  /// The rules that go with them: a custom label is kept only by the custom
  /// numbering; the picture answers are stored only when they are not the
  /// standard look; no default Timed limit stores nothing.
  static Course apply(
    Course course, {
    LessonNumberingMode? lessonNumbering,
    String? customLessonLabel,
    RoundNumberingMode? roundNumbering,
    String? customRoundLabel,
    bool? useGuidebook,
    bool? wordLookup,
    bool? createDuels,
    List<int>? defaultTimedLimits,
    PictureAnswerStyle? pictureAnswers,
  }) {
    final json = {...course.toJson()};
    if (lessonNumbering != null) {
      json['lessonNumberingMode'] = lessonNumbering.name;
      json['customLessonLabel'] = lessonNumbering == LessonNumberingMode.other
          ? customLessonLabel ?? course.customLessonLabel
          : '';
    }
    if (roundNumbering != null) {
      json['roundNumberingMode'] = roundNumbering.name;
      json['customRoundLabel'] =
          roundNumbering == RoundNumberingMode.customAndNumber
          ? customRoundLabel ?? course.customRoundLabel
          : '';
    }
    if (useGuidebook != null) json['useGuidebook'] = useGuidebook;
    if (wordLookup != null) json['wordLookup'] = wordLookup;
    if (createDuels != null) json['createDuels'] = createDuels;
    if (defaultTimedLimits != null) {
      json.remove('defaultTimedLimitsSeconds');
      if (defaultTimedLimits.isNotEmpty) {
        json['defaultTimedLimitsSeconds'] = defaultTimedLimits;
      }
    }
    if (pictureAnswers != null) {
      json.remove('pictureAnswers');
      if (!pictureAnswers.isStandard) {
        json['pictureAnswers'] = pictureAnswers.toJson();
      }
    }
    return Course.fromJson(json);
  }

  // ---- Numbering

  /// The custom numbering entry of a menu: the author's label once there is
  /// one ("Step + number"), else "Custom + number".
  static String customNumberingText(String label) =>
      label.trim().isEmpty ? 'Custom + number' : '${label.trim()} + number';

  /// The label of a Lesson numbering of earlier Courses (Unit, Topic,
  /// Module…) that the menu no longer offers but still shows for a Course
  /// that has it; null for the numberings of today.
  static String? earlierLessonNumberingLabel(LessonNumberingMode mode) =>
      switch (mode) {
        LessonNumberingMode.unit => 'Unit',
        LessonNumberingMode.topic => 'Topic',
        LessonNumberingMode.module => 'Module',
        LessonNumberingMode.skill => 'Skill',
        LessonNumberingMode.chapter => 'Chapter',
        LessonNumberingMode.stage => 'Stage',
        LessonNumberingMode.step => 'Step',
        LessonNumberingMode.part => 'Part',
        _ => null,
      };

  // ---- Default Timed limits

  /// What is said when a Timed limit is chosen that another stage has.
  static const timedLimitRepeated = 'Each Timed limit must be different.';

  /// [limits] with [seconds] as a new last stage ([index] null) or in the
  /// place of stage [index]; null when another stage already has that
  /// limit. Choosing a stage's own limit again changes nothing.
  static List<int>? timedLimitsWith(
    List<int> limits,
    int seconds, {
    int? index,
  }) {
    if (limits.contains(seconds) &&
        (index == null || limits[index] != seconds)) {
      return null;
    }
    final changed = [...limits];
    if (index == null) {
      changed.add(seconds);
    } else {
      changed[index] = seconds;
    }
    return changed;
  }

  /// [limits] with stage [index] moved by [offset] places.
  static List<int> timedLimitsMoved(List<int> limits, int index, int offset) {
    final changed = [...limits];
    final value = changed.removeAt(index);
    changed.insert(index + offset, value);
    return changed;
  }

  /// [limits] without stage [index].
  static List<int> timedLimitsWithout(List<int> limits, int index) =>
      [...limits]..removeAt(index);
}
