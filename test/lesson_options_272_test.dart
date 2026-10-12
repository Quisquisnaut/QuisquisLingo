import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/lesson_options.dart';

/// Build 272 Revision 4: the Lesson Options rules, without a screen.
void main() {
  group('LessonOptions.apply', () {
    test('changes only the settings given', () {
      final course = _course();
      final same = LessonOptions.apply(course);
      expect(same.toJson(), course.toJson());

      final duels = LessonOptions.apply(course, createDuels: false);
      expect(duels.createDuels, isFalse);
      expect(
        {...duels.toJson()}..remove('createDuels'),
        {...course.toJson()}..remove('createDuels'),
      );
      expect(
        LessonOptions.apply(course, useGuidebook: false).useGuidebook,
        isFalse,
      );
      expect(
        LessonOptions.apply(course, wordLookup: false).wordLookup,
        isFalse,
      );
    });

    test('a custom label is kept only by the custom numbering', () {
      final course = _course();
      final custom = LessonOptions.apply(
        course,
        lessonNumbering: LessonNumberingMode.other,
        customLessonLabel: 'Step',
        roundNumbering: RoundNumberingMode.customAndNumber,
        customRoundLabel: 'Turn',
      );
      expect(custom.lessonNumberingMode, LessonNumberingMode.other);
      expect(custom.customLessonLabel, 'Step');
      expect(custom.roundNumberingMode, RoundNumberingMode.customAndNumber);
      expect(custom.customRoundLabel, 'Turn');

      // Choosing the custom numbering again without a label keeps the one
      // the Course has.
      final again = LessonOptions.apply(
        custom,
        lessonNumbering: LessonNumberingMode.other,
        roundNumbering: RoundNumberingMode.customAndNumber,
      );
      expect(again.customLessonLabel, 'Step');
      expect(again.customRoundLabel, 'Turn');

      // Another numbering drops the label, also one handed in.
      final plain = LessonOptions.apply(
        custom,
        lessonNumbering: LessonNumberingMode.numberOnly,
        customLessonLabel: 'Ignored',
        roundNumbering: RoundNumberingMode.off,
        customRoundLabel: 'Ignored',
      );
      expect(plain.lessonNumberingMode, LessonNumberingMode.numberOnly);
      expect(plain.customLessonLabel, isEmpty);
      expect(plain.roundNumberingMode, RoundNumberingMode.off);
      expect(plain.customRoundLabel, isEmpty);
      // A numbering of the other kind is not touched.
      final lessonsOnly = LessonOptions.apply(
        custom,
        lessonNumbering: LessonNumberingMode.lesson,
      );
      expect(lessonsOnly.customRoundLabel, 'Turn');
    });

    test('the picture answers are stored only when they are not the '
        'standard look', () {
      final course = _course();
      final bordered = LessonOptions.apply(
        course,
        pictureAnswers: PictureAnswerStyle.newCourse,
      );
      expect(bordered.pictureAnswers.border, PictureBorder.thin);
      expect(bordered.toJson()['pictureAnswers'], isNotNull);
      final standard = LessonOptions.apply(
        bordered,
        pictureAnswers: PictureAnswerStyle.standard,
      );
      expect(standard.pictureAnswers, PictureAnswerStyle.standard);
      expect(standard.toJson().containsKey('pictureAnswers'), isFalse);
    });

    test('no default Timed limit stores nothing', () {
      final course = _course();
      final timed = LessonOptions.apply(course, defaultTimedLimits: [90, 60]);
      expect(timed.defaultTimedLimitsSeconds, [90, 60]);
      final none = LessonOptions.apply(timed, defaultTimedLimits: const []);
      expect(none.defaultTimedLimitsSeconds, isEmpty);
      expect(none.toJson().containsKey('defaultTimedLimitsSeconds'), isFalse);
    });

    test('the Course Wizard\'s options step writes the same Course', () {
      final course = _course();
      const options = CourseWizardOptions(
        lessonNumbering: LessonNumberingMode.other,
        customLessonLabel: ' Step ',
        roundNumbering: RoundNumberingMode.customAndNumber,
        customRoundLabel: ' Turn ',
        wordLookup: false,
        createDuels: true,
        pictureAnswers: PictureAnswerStyle.earlier,
        defaultTimedLimits: [120, 60],
      );
      final applied = options.applyTo(
        LessonOptions.apply(course, useGuidebook: false),
      );
      // What the step wrote before it used the owner, field by field.
      final json = {...course.toJson()}
        ..remove('pictureAnswers')
        ..remove('defaultTimedLimitsSeconds');
      final expected = Course.fromJson({
        ...json,
        'lessonNumberingMode': 'other',
        'customLessonLabel': 'Step',
        'roundNumberingMode': RoundNumberingMode.customAndNumber.name,
        'customRoundLabel': 'Turn',
        'useGuidebook': true,
        'wordLookup': false,
        'createDuels': true,
        'pictureAnswers': PictureAnswerStyle.earlier.toJson(),
        'defaultTimedLimitsSeconds': [120, 60],
      });
      expect(applied.toJson(), expected.toJson());
      // The Wizard keeps the GuideBook on, whatever the Course had.
      expect(applied.useGuidebook, isTrue);
      // The defaults leave a new Course as New Course makes it.
      final defaults = CourseWizardOptions.defaults.applyTo(course);
      expect(defaults.pictureAnswers, PictureAnswerStyle.newCourse);
      expect(defaults.createDuels, isFalse);
      expect(defaults.customLessonLabel, isEmpty);
    });
  });

  test('the numbering menus name a custom label and an earlier numbering', () {
    expect(LessonOptions.customNumberingText(''), 'Custom + number');
    expect(LessonOptions.customNumberingText('  '), 'Custom + number');
    expect(LessonOptions.customNumberingText(' Step '), 'Step + number');
    expect(
      LessonOptions.earlierLessonNumberingLabel(LessonNumberingMode.unit),
      'Unit',
    );
    expect(
      LessonOptions.earlierLessonNumberingLabel(LessonNumberingMode.part),
      'Part',
    );
    for (final mode in [
      LessonNumberingMode.none,
      LessonNumberingMode.lesson,
      LessonNumberingMode.numberOnly,
      LessonNumberingMode.other,
    ]) {
      expect(LessonOptions.earlierLessonNumberingLabel(mode), isNull);
    }
    // Every numbering is either offered today or named as an earlier one.
    expect(
      LessonNumberingMode.values
          .where(
            (mode) => LessonOptions.earlierLessonNumberingLabel(mode) != null,
          )
          .length,
      LessonNumberingMode.values.length - 4,
    );
  });

  test('the default Timed limits: each different, in the author\'s order', () {
    const limits = [60, 120, 300];
    expect(LessonOptions.timedLimitsWith(limits, 90), [60, 120, 300, 90]);
    expect(LessonOptions.timedLimitsWith(limits, 90, index: 1), [60, 90, 300]);
    // A limit another stage has is refused; a stage's own limit is not.
    expect(LessonOptions.timedLimitsWith(limits, 120), isNull);
    expect(LessonOptions.timedLimitsWith(limits, 60, index: 1), isNull);
    expect(LessonOptions.timedLimitsWith(limits, 120, index: 1), limits);
    expect(
      LessonOptions.timedLimitRepeated,
      'Each Timed limit must be different.',
    );
    expect(LessonOptions.timedLimitsMoved(limits, 0, 1), [120, 60, 300]);
    expect(LessonOptions.timedLimitsMoved(limits, 2, -1), [60, 300, 120]);
    expect(LessonOptions.timedLimitsWithout(limits, 0), [120, 300]);
    // The list handed in is never changed.
    expect(limits, [60, 120, 300]);
  });
}

Course _course() => Course(
  courseId: 'options-owner',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: '12345678-1234-4234-9234-123456789abc',
    displayName: 'Options Author',
  ),
  maintainer: const CourseMaintainer('12345678-1234-4234-9234-123456789abc'),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Options Course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: const [],
);
