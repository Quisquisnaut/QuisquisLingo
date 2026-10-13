import '../models/course_models.dart';
import 'course_merge_service.dart';

/// A setting of the merged Course for which the author picks a side when
/// the two Courses differ on it. The order is the order the Merge page
/// offers them in.
enum CourseMergeSetting {
  title('Course title'),
  createDuels('Create Duels'),
  useGuidebook('Use GuideBooks'),
  lessonNumbering('Lesson label and numbering'),
  sectionNames('Section names'),
  buyACoffee('Buy a Coffee'),
  description('Course description'),
  flag('Course flag'),
  startLevel('Start level'),
  targetLevel('Target level');

  const CourseMergeSetting(this.label);

  /// The setting's name on the Merge page.
  final String label;
}

/// What an author has chosen on the Merge page for two Courses: where each
/// Lesson comes from, and which Course gives each setting they differ on
/// (Build 272 Revision 11; before, fields and functions of the page).
///
/// A Lesson row comes from the left Course, from the right one or from
/// neither, never from both. Nothing is chosen at first; every setting
/// starts on the left Course.
///
/// Pure Dart: the page keeps the loading of the second Course, its package,
/// the dialogs and the layout.
class CourseMergeSelection {
  CourseMergeSelection(this.left, this.right)
    : _choices = List.filled(
        [
          left.lessons.length,
          right.lessons.length,
        ].reduce((a, b) => a > b ? a : b),
        LessonMergeChoice.exclude,
      );

  final Course left;
  final Course right;
  List<LessonMergeChoice> _choices;
  final Map<CourseMergeSetting, CourseMergeSide> _sides = {};

  /// One row for each Lesson of the longer Course.
  int get rowCount => _choices.length;

  /// Where each row's Lesson comes from, as the merge is asked for it.
  List<LessonMergeChoice> get choices => List.unmodifiable(_choices);

  LessonMergeChoice choiceAt(int index) => _choices[index];

  /// The Lesson a Course has at a row, or null when it has none there.
  Lesson? lessonAt(LessonMergeChoice side, int index) {
    final lessons = side == LessonMergeChoice.left
        ? left.lessons
        : right.lessons;
    return index < lessons.length ? lessons[index] : null;
  }

  /// At least one row has a Lesson chosen: there is something to merge.
  bool get hasSelection =>
      !_choices.every((choice) => choice == LessonMergeChoice.exclude);

  /// A cell's tick: ticked, the row comes from [side]; unticked, from
  /// neither Course.
  void choose(int index, LessonMergeChoice side, {required bool selected}) {
    _choices[index] = selected ? side : LessonMergeChoice.exclude;
  }

  /// Select all Left / Right: each row takes [side] where that Course has a
  /// Lesson, and no Course where it has none.
  void selectAll(LessonMergeChoice side) {
    _choices = List.generate(_choices.length, (index) {
      final available = side == LessonMergeChoice.left
          ? index < left.lessons.length
          : index < right.lessons.length;
      return available ? side : LessonMergeChoice.exclude;
    });
  }

  /// Whether the two Courses differ on [setting], so that a side is offered.
  bool differsIn(CourseMergeSetting setting) => switch (setting) {
    CourseMergeSetting.title => left.title != right.title,
    CourseMergeSetting.createDuels => left.createDuels != right.createDuels,
    CourseMergeSetting.useGuidebook => left.useGuidebook != right.useGuidebook,
    CourseMergeSetting.lessonNumbering =>
      left.lessonNumberingMode != right.lessonNumberingMode ||
          left.customLessonLabel != right.customLessonLabel,
    CourseMergeSetting.sectionNames =>
      left.sectionNames.join('\u0000') != right.sectionNames.join('\u0000'),
    CourseMergeSetting.buyACoffee => left.buyACoffeeUrl != right.buyACoffeeUrl,
    CourseMergeSetting.description =>
      left.courseDescription != right.courseDescription,
    CourseMergeSetting.flag =>
      left.flagCode != right.flagCode ||
          left.worldFlagId != right.worldFlagId ||
          left.flagImageBase64 != right.flagImageBase64,
    CourseMergeSetting.startLevel => left.startLevel != right.startLevel,
    CourseMergeSetting.targetLevel => left.targetLevel != right.targetLevel,
  };

  /// The settings the page offers a side for, in order.
  List<CourseMergeSetting> get differing => [
    for (final setting in CourseMergeSetting.values)
      if (differsIn(setting)) setting,
  ];

  CourseMergeSide sideOf(CourseMergeSetting setting) =>
      _sides[setting] ?? CourseMergeSide.left;

  void setSide(CourseMergeSetting setting, CourseMergeSide side) {
    _sides[setting] = side;
  }

  Course _from(CourseMergeSetting setting) =>
      sideOf(setting) == CourseMergeSide.left ? left : right;

  /// The merged Course's settings: each from the Course chosen for it. The
  /// numbering carries its custom label, the flag its three fields.
  CourseMergeOptions get options {
    final numbering = _from(CourseMergeSetting.lessonNumbering);
    final flag = _from(CourseMergeSetting.flag);
    return CourseMergeOptions(
      title: _from(CourseMergeSetting.title).title,
      createDuels: _from(CourseMergeSetting.createDuels).createDuels,
      useGuidebook: _from(CourseMergeSetting.useGuidebook).useGuidebook,
      lessonNumberingMode: numbering.lessonNumberingMode,
      customLessonLabel: numbering.customLessonLabel,
      sectionNames: _from(CourseMergeSetting.sectionNames).sectionNames,
      buyACoffeeUrl: _from(CourseMergeSetting.buyACoffee).buyACoffeeUrl,
      courseDescription: _from(
        CourseMergeSetting.description,
      ).courseDescription,
      startLevel: _from(CourseMergeSetting.startLevel).startLevel,
      targetLevel: _from(CourseMergeSetting.targetLevel).targetLevel,
      flagCode: flag.flagCode,
      worldFlagId: flag.worldFlagId,
      flagImageBase64: flag.flagImageBase64,
    );
  }
}
