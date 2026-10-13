import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_merge_selection.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';

/// Build 272 Revision 11: what the Merge page lets an author choose, and
/// what it hands on. The first group was written on the page before the
/// choices got their owner and is unchanged by it.
class _PackageMergeService extends CourseMergeService {
  _PackageMergeService(this.package);

  final CoursePackage package;

  @override
  Future<CoursePackage> readMergePackage() async => package;

  @override
  bool get fileDialogsAvailable => false;
}

Lesson _lesson(String id, String title) => Lesson(
  lessonId: id,
  updatedAt: DateTime.utc(2026, 10, 13),
  title: title,
  rounds: const [],
);

Course _left({int lessons = 1}) => Course(
  courseId: 'left',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Italian, first steps',
  ttsLanguage: 'it-IT',
  lessons: [
    for (var i = 1; i <= lessons; i++) _lesson('left-$i', 'Left Lesson $i'),
  ],
);

/// A second Course that differs from [_left] in every setting the page lets
/// an author choose a side for.
Course _differentRight({int lessons = 1}) => Course(
  courseId: 'right',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Italian, second edition',
  ttsLanguage: 'it-IT',
  createDuels: false,
  useGuidebook: false,
  lessonNumberingMode: LessonNumberingMode.other,
  customLessonLabel: 'Tappa',
  sectionNames: const ['Basics', 'Travel'],
  buyACoffeeUrl: 'https://example.org/coffee',
  courseDescription: 'A second description.',
  flagCode: 'IT',
  startLevel: 'A1',
  targetLevel: 'B1',
  lessons: [
    for (var i = 1; i <= lessons; i++) _lesson('right-$i', 'Right Lesson $i'),
  ],
);

Course _sameSettingsRight({int lessons = 1}) => Course(
  courseId: 'right',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Italian, first steps',
  ttsLanguage: 'it-IT',
  lessons: [
    for (var i = 1; i <= lessons; i++) _lesson('right-$i', 'Right Lesson $i'),
  ],
);

const _labels = [
  'Course title',
  'Create Duels',
  'Use GuideBooks',
  'Lesson label and numbering',
  'Section names',
  'Buy a Coffee',
  'Course description',
  'Course flag',
  'Start level',
  'Target level',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<LessonMergeChoice> choices;
  late CourseMergeOptions options;
  late int merges;

  Future<void> open(WidgetTester tester, Course left, Course right) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    merges = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CourseMergeScreen(
          leftCourse: left,
          mergeService: _PackageMergeService(
            CoursePackage(right, Uint8List(0), const {}),
          ),
          onMerge: (course, chosen, given) async {
            merges++;
            choices = List.of(chosen);
            options = given;
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('merge-course-json-primary')));
    await tester.pump();
    await tester.pump();
  }

  Finder side(String label) => find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<CourseMergeSide> &&
        widget.decoration.labelText == '$label source',
  );

  Future<void> useRight(WidgetTester tester, String label) async {
    await tester.ensureVisible(side(label));
    await tester.tap(side(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use Right').last);
    await tester.pumpAndSettle();
  }

  FilledButton mergeButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'DO MERGE!'),
  );

  Future<void> merge(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'DO MERGE!');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    await tester.pump();
  }

  group('the Merge page', () {
    testWidgets('offers no side when the two Courses have the same '
        'settings', (tester) async {
      await open(tester, _left(), _sameSettingsRight());
      for (final label in _labels) {
        expect(side(label), findsNothing, reason: label);
      }
    });

    testWidgets('offers a side for each setting that differs, in a fixed '
        'order', (tester) async {
      await open(tester, _left(), _differentRight());
      final offered = tester
          .widgetList<DropdownButtonFormField<CourseMergeSide>>(
            find.byWidgetPredicate(
              (widget) => widget is DropdownButtonFormField<CourseMergeSide>,
            ),
          )
          .map((field) => field.decoration.labelText)
          .toList();
      expect(offered, [for (final label in _labels) '$label source']);
    });

    testWidgets('hands on the left Course\'s settings until a side is '
        'changed', (tester) async {
      final left = _left();
      final right = _differentRight();
      await open(tester, left, right);
      await tester.tap(find.text('Select all Left'));
      await tester.pump();
      await merge(tester);
      expect(merges, 1);
      expect(options.title, left.title);
      expect(options.createDuels, left.createDuels);
      expect(options.useGuidebook, left.useGuidebook);
      expect(options.lessonNumberingMode, left.lessonNumberingMode);
      expect(options.customLessonLabel, left.customLessonLabel);
      expect(options.sectionNames, left.sectionNames);
      expect(options.buyACoffeeUrl, left.buyACoffeeUrl);
      expect(options.courseDescription, left.courseDescription);
      expect(options.flagCode, left.flagCode);
      expect(options.worldFlagId, left.worldFlagId);
      expect(options.flagImageBase64, left.flagImageBase64);
      expect(options.startLevel, left.startLevel);
      expect(options.targetLevel, left.targetLevel);
    });

    testWidgets('a setting set to Right takes the right Course\'s value, the '
        'others stay Left', (tester) async {
      final left = _left();
      final right = _differentRight();
      await open(tester, left, right);
      await useRight(tester, 'Course title');
      await useRight(tester, 'Lesson label and numbering');
      await useRight(tester, 'Course flag');
      await useRight(tester, 'Target level');
      await tester.tap(find.text('Select all Left'));
      await tester.pump();
      await merge(tester);
      expect(options.title, right.title);
      // The numbering carries its own label, the flag its three fields.
      expect(options.lessonNumberingMode, right.lessonNumberingMode);
      expect(options.customLessonLabel, right.customLessonLabel);
      expect(options.flagCode, right.flagCode);
      expect(options.worldFlagId, right.worldFlagId);
      expect(options.flagImageBase64, right.flagImageBase64);
      expect(options.targetLevel, right.targetLevel);
      // Untouched settings.
      expect(options.createDuels, left.createDuels);
      expect(options.useGuidebook, left.useGuidebook);
      expect(options.sectionNames, left.sectionNames);
      expect(options.buyACoffeeUrl, left.buyACoffeeUrl);
      expect(options.courseDescription, left.courseDescription);
      expect(options.startLevel, left.startLevel);
    });

    testWidgets('every setting set to Right', (tester) async {
      final right = _differentRight();
      await open(tester, _left(), right);
      for (final label in _labels) {
        await useRight(tester, label);
      }
      await tester.tap(find.text('Select all Left'));
      await tester.pump();
      await merge(tester);
      expect(options.title, right.title);
      expect(options.createDuels, right.createDuels);
      expect(options.useGuidebook, right.useGuidebook);
      expect(options.lessonNumberingMode, right.lessonNumberingMode);
      expect(options.customLessonLabel, right.customLessonLabel);
      expect(options.sectionNames, right.sectionNames);
      expect(options.buyACoffeeUrl, right.buyACoffeeUrl);
      expect(options.courseDescription, right.courseDescription);
      expect(options.flagCode, right.flagCode);
      expect(options.startLevel, right.startLevel);
      expect(options.targetLevel, right.targetLevel);
    });

    testWidgets('has one row for each Lesson of the longer Course; nothing '
        'is chosen at first and DO MERGE! waits', (tester) async {
      await open(tester, _left(lessons: 3), _sameSettingsRight(lessons: 2));
      expect(find.byType(Checkbox), findsNWidgets(6));
      expect(find.text('Not available'), findsOneWidget);
      // The cell without a Lesson cannot be ticked.
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes.map((box) => box.value), everyElement(isFalse));
      expect(boxes[5].onChanged, isNull);
      expect(boxes[4].onChanged, isNotNull);
      expect(mergeButton(tester).onPressed, isNull);
    });

    testWidgets('Select all Right takes the right Course wherever it has a '
        'Lesson', (tester) async {
      await open(tester, _left(lessons: 3), _sameSettingsRight(lessons: 2));
      await tester.tap(find.text('Select all Right'));
      await tester.pump();
      await merge(tester);
      expect(merges, 1);
      expect(choices, [
        LessonMergeChoice.right,
        LessonMergeChoice.right,
        LessonMergeChoice.exclude,
      ]);
    });

    testWidgets('Select all Left after Select all Right takes the left '
        'Course for every row it has', (tester) async {
      await open(tester, _left(lessons: 3), _sameSettingsRight(lessons: 2));
      await tester.tap(find.text('Select all Right'));
      await tester.pump();
      await tester.tap(find.text('Select all Left'));
      await tester.pump();
      await merge(tester);
      expect(choices, [
        LessonMergeChoice.left,
        LessonMergeChoice.left,
        LessonMergeChoice.left,
      ]);
    });

    testWidgets('Select all Left with the shorter Course on the left', (
      tester,
    ) async {
      await open(tester, _left(lessons: 1), _sameSettingsRight(lessons: 3));
      await tester.tap(find.text('Select all Left'));
      await tester.pump();
      await merge(tester);
      expect(choices, [
        LessonMergeChoice.left,
        LessonMergeChoice.exclude,
        LessonMergeChoice.exclude,
      ]);
    });

    testWidgets('a Lesson comes from one Course or from neither', (
      tester,
    ) async {
      await open(tester, _left(lessons: 2), _sameSettingsRight(lessons: 2));
      Future<void> tick(int index) async {
        await tester.tap(find.byType(Checkbox).at(index));
        await tester.pump();
      }

      // Row 1: left, then right instead; row 2: right, then unticked.
      await tick(0);
      await tick(1);
      await tick(3);
      var boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes.map((box) => box.value), [false, true, false, true]);
      await tick(3);
      boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      expect(boxes.map((box) => box.value), [false, true, false, false]);
      await merge(tester);
      expect(choices, [LessonMergeChoice.right, LessonMergeChoice.exclude]);

      // Everything unticked again: nothing to merge.
      await tick(1);
      expect(mergeButton(tester).onPressed, isNull);
    });
  });

  group('CourseMergeSelection, the choices themselves', () {
    Course rightWith({
      String title = 'Italian, first steps',
      bool createDuels = true,
      bool useGuidebook = true,
      LessonNumberingMode numbering = LessonNumberingMode.lesson,
      String customLabel = '',
      List<String> sections = const [],
      String coffee = '',
      String description = '',
      String flagCode = '',
      String worldFlagId = '',
      String startLevel = '',
      String targetLevel = '',
    }) => Course(
      courseId: 'right',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: title,
      ttsLanguage: 'it-IT',
      createDuels: createDuels,
      useGuidebook: useGuidebook,
      lessonNumberingMode: numbering,
      customLessonLabel: customLabel,
      sectionNames: sections,
      buyACoffeeUrl: coffee,
      courseDescription: description,
      flagCode: flagCode,
      worldFlagId: worldFlagId,
      startLevel: startLevel,
      targetLevel: targetLevel,
      lessons: [_lesson('right-1', 'Right Lesson 1')],
    );

    test('nothing is chosen at first; one row for each Lesson of the longer '
        'Course', () {
      final selection = CourseMergeSelection(
        _left(lessons: 3),
        _sameSettingsRight(lessons: 2),
      );
      expect(selection.rowCount, 3);
      expect(selection.choices, [
        LessonMergeChoice.exclude,
        LessonMergeChoice.exclude,
        LessonMergeChoice.exclude,
      ]);
      expect(selection.hasSelection, isFalse);
      expect(selection.lessonAt(LessonMergeChoice.left, 2)?.lessonId, 'left-3');
      expect(
        selection.lessonAt(LessonMergeChoice.right, 1)?.lessonId,
        'right-2',
      );
      expect(selection.lessonAt(LessonMergeChoice.right, 2), isNull);
      expect(
        CourseMergeSelection(_left(), _sameSettingsRight(lessons: 4)).rowCount,
        4,
      );
    });

    test('a row comes from one Course or from neither', () {
      final selection = CourseMergeSelection(
        _left(lessons: 2),
        _sameSettingsRight(lessons: 2),
      );
      selection.choose(0, LessonMergeChoice.left, selected: true);
      expect(selection.choiceAt(0), LessonMergeChoice.left);
      selection.choose(0, LessonMergeChoice.right, selected: true);
      expect(selection.choiceAt(0), LessonMergeChoice.right);
      expect(selection.hasSelection, isTrue);
      selection.choose(0, LessonMergeChoice.right, selected: false);
      expect(selection.choiceAt(0), LessonMergeChoice.exclude);
      expect(selection.hasSelection, isFalse);
      // What the merge is handed cannot be changed from outside.
      expect(
        () => selection.choices[0] = LessonMergeChoice.left,
        throwsUnsupportedError,
      );
    });

    test('Select all takes a side wherever that Course has a Lesson, and '
        'forgets what was chosen before', () {
      final selection = CourseMergeSelection(
        _left(lessons: 3),
        _sameSettingsRight(lessons: 2),
      );
      selection.choose(2, LessonMergeChoice.left, selected: true);
      selection.selectAll(LessonMergeChoice.right);
      expect(selection.choices, [
        LessonMergeChoice.right,
        LessonMergeChoice.right,
        LessonMergeChoice.exclude,
      ]);
      selection.selectAll(LessonMergeChoice.left);
      expect(selection.choices, [
        LessonMergeChoice.left,
        LessonMergeChoice.left,
        LessonMergeChoice.left,
      ]);
    });

    test('a side is offered for each setting the two Courses differ on, and '
        'only for those', () {
      expect(
        CourseMergeSelection(_left(), _sameSettingsRight()).differing,
        isEmpty,
      );
      expect(
        CourseMergeSelection(_left(), _differentRight()).differing,
        CourseMergeSetting.values,
      );
      expect([
        for (final setting in CourseMergeSetting.values) setting.label,
      ], _labels);
      final one = <CourseMergeSetting, Course>{
        CourseMergeSetting.title: rightWith(title: 'Another title'),
        CourseMergeSetting.createDuels: rightWith(createDuels: false),
        CourseMergeSetting.useGuidebook: rightWith(useGuidebook: false),
        CourseMergeSetting.lessonNumbering: rightWith(
          numbering: LessonNumberingMode.unit,
        ),
        CourseMergeSetting.sectionNames: rightWith(sections: const ['Basics']),
        CourseMergeSetting.buyACoffee: rightWith(
          coffee: 'https://example.org/coffee',
        ),
        CourseMergeSetting.description: rightWith(description: 'Another.'),
        CourseMergeSetting.flag: rightWith(flagCode: 'IT'),
        CourseMergeSetting.startLevel: rightWith(startLevel: 'A1'),
        CourseMergeSetting.targetLevel: rightWith(targetLevel: 'B1'),
      };
      expect(one.keys, CourseMergeSetting.values);
      for (final entry in one.entries) {
        expect(CourseMergeSelection(_left(), entry.value).differing, [
          entry.key,
        ], reason: entry.key.name);
      }
      // The numbering also differs by its own label alone, the flag by its
      // World Flag alone.
      expect(
        CourseMergeSelection(
          _left(),
          rightWith(customLabel: 'Tappa'),
        ).differing,
        [CourseMergeSetting.lessonNumbering],
      );
      expect(
        CourseMergeSelection(_left(), rightWith(worldFlagId: 'it')).differing,
        [CourseMergeSetting.flag],
      );
    });

    test('every setting starts on the left Course; the merged Course takes '
        'each from the side chosen', () {
      final left = _left();
      final right = _differentRight();
      final selection = CourseMergeSelection(left, right);
      for (final setting in CourseMergeSetting.values) {
        expect(selection.sideOf(setting), CourseMergeSide.left);
      }
      var options = selection.options;
      expect(options.title, left.title);
      expect(options.createDuels, left.createDuels);
      expect(options.useGuidebook, left.useGuidebook);
      expect(options.lessonNumberingMode, left.lessonNumberingMode);
      expect(options.customLessonLabel, left.customLessonLabel);
      expect(options.sectionNames, left.sectionNames);
      expect(options.buyACoffeeUrl, left.buyACoffeeUrl);
      expect(options.courseDescription, left.courseDescription);
      expect(options.flagCode, left.flagCode);
      expect(options.startLevel, left.startLevel);
      expect(options.targetLevel, left.targetLevel);

      for (final setting in CourseMergeSetting.values) {
        selection.setSide(setting, CourseMergeSide.right);
      }
      options = selection.options;
      expect(options.title, right.title);
      expect(options.createDuels, right.createDuels);
      expect(options.useGuidebook, right.useGuidebook);
      expect(options.lessonNumberingMode, right.lessonNumberingMode);
      expect(options.customLessonLabel, right.customLessonLabel);
      expect(options.sectionNames, right.sectionNames);
      expect(options.buyACoffeeUrl, right.buyACoffeeUrl);
      expect(options.courseDescription, right.courseDescription);
      expect(options.flagCode, right.flagCode);
      expect(options.worldFlagId, right.worldFlagId);
      expect(options.flagImageBase64, right.flagImageBase64);
      expect(options.startLevel, right.startLevel);
      expect(options.targetLevel, right.targetLevel);

      selection.setSide(CourseMergeSetting.title, CourseMergeSide.left);
      expect(selection.options.title, left.title);
      expect(selection.options.targetLevel, right.targetLevel);
    });
  });
}
