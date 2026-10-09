import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/guidebook_editor_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/guidebook_size_advice.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guidebook_fixtures.dart';

/// Build 267 Revision 5: the GuideBook size that suits the Round Wizard
/// (owner decisions of 9 October 2026): 3 to 6 modules per Lesson (best 4),
/// 5 to 10 Words & Expressions (best about 8) and 2 to 5 Sentences (best
/// 3–4) per module; grey hints and Info findings, never a block.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the advice', () {
    test('the number of modules', () {
      expect(GuidebookSizeAdvice.lessonHint(const []), isNull);
      expect(
        GuidebookSizeAdvice.lessonHint(_modules(1)),
        startsWith('1 module:'),
      );
      expect(
        GuidebookSizeAdvice.lessonHint(_modules(2)),
        startsWith('2 modules:'),
      );
      for (final count in [3, 4, 6]) {
        expect(GuidebookSizeAdvice.lessonHint(_modules(count)), isNull);
      }
      expect(
        GuidebookSizeAdvice.lessonHint(_modules(7)),
        '7 modules make a long Lesson: consider splitting it into two Lessons.',
      );
      // An empty module does not count: it has its own Warning.
      expect(
        GuidebookSizeAdvice.lessonHint([
          ..._modules(3),
          GuidebookModule(id: 'empty', title: 'Empty'),
        ]),
        isNull,
      );
    });

    test('the size of a module', () {
      String? hint(int words, int sentences, [String title = 'Al bar']) =>
          GuidebookSizeAdvice.hintFor(
            title: title,
            words: words,
            sentences: sentences,
          );
      expect(hint(0, 0), isNull);
      expect(
        hint(4, 1),
        '“Al bar” has 4 words and 1 sentence: some Rounds may repeat '
        'exercises. Best: about 8 words and 3–4 sentences.',
      );
      expect(hint(8, 1), contains('1 sentence'));
      expect(hint(5, 2), isNull);
      expect(hint(8, 3), isNull);
      expect(hint(12, 5), isNull);
      expect(
        hint(14, 3),
        '“Al bar” has 14 words: some may not get an exercise. Consider '
        'splitting it into two modules.',
      );
      expect(hint(8, 13), contains('13 sentences'));
      expect(hint(1, 0, ' '), startsWith('This module has 1 word'));
      expect(
        GuidebookSizeAdvice.countLine(words: 8, sentences: 1),
        '8 Words & Expressions · 1 Sentence',
      );
    });
  });

  group('the Audit', () {
    test('Info for the Round Wizard, only with Use GuideBook on', () {
      final course = _course([
        _module('bar', words: 3, sentences: 1),
        GuidebookModule(id: 'empty', title: 'Empty'),
      ]);
      List<String> codes(Course course) => [
        for (final issue in CourseAuditService().auditCourse(course).issues)
          if (issue.code.startsWith('GUIDEBOOK_MODULE_SIZE') ||
              issue.code == 'GUIDEBOOK_MODULE_COUNT')
            '${issue.code} ${issue.severity.name}',
      ];
      expect(
        codes(course),
        unorderedEquals([
          'GUIDEBOOK_MODULE_SIZE info',
          'GUIDEBOOK_MODULE_COUNT info',
        ]),
      );
      final size = CourseAuditService()
          .auditCourse(course)
          .issues
          .firstWhere((issue) => issue.code == 'GUIDEBOOK_MODULE_SIZE');
      expect(
        size.message,
        startsWith('For the Round Wizard: “bar” has 3 words'),
      );
      expect(size.location, endsWith('· Guidebook · Module 1'));

      final off = Course.fromJson({...course.toJson(), 'useGuidebook': false});
      expect(codes(off), isEmpty);

      final suited = _course([
        for (var i = 0; i < 4; i++) _module('m$i', words: 8, sentences: 3),
      ]);
      expect(codes(suited), isEmpty);
    });
  });

  group('the hints on screen', () {
    testWidgets('the GuideBook page: the Lesson and each module', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GuidebookEditorScreen(
            guidebook: Guidebook(
              modules: [
                _module('bar', words: 3, sentences: 1),
                _module('fine', words: 8, sentences: 3),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('guidebook-size-advice')),
          matching: find.textContaining('2 modules'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guidebook-module-size-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guidebook-module-size-1')),
        findsNothing,
      );
    });

    testWidgets('the module page counts as the author writes', (tester) async {
      // Tall enough for the whole page: the line is under the two lists.
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: GuidebookModuleEditorScreen(
            module: _module('bar', words: 5, sentences: 2),
            ids: TimestampAuthoringIdGenerator(seed: 2675),
            metadataService: _NoPictures(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final line = find.byKey(const Key('guidebook-module-size'));
      expect(
        find.descendant(
          of: line,
          matching: find.text('5 Words & Expressions · 2 Sentences'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: line, matching: find.textContaining('Best:')),
        findsNothing,
      );
      // Emptying a word's box counts it out, and the hint appears.
      await tester.enterText(
        find.byKey(const Key('guidebook-module-word-0-target')),
        '',
      );
      await tester.pump();
      expect(
        find.descendant(
          of: line,
          matching: find.text('4 Words & Expressions · 2 Sentences'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: line,
          matching: find.textContaining('some Rounds may repeat exercises'),
        ),
        findsOneWidget,
      );
    });
  });
}

List<GuidebookModule> _modules(int count) => [
  for (var i = 0; i < count; i++) _module('m$i', words: 8, sentences: 3),
];

GuidebookModule _module(
  String id, {
  required int words,
  required int sentences,
}) => GuidebookModule(
  id: id,
  title: id,
  words: [
    for (var i = 0; i < words; i++) testEntry('${id}_w$i', 'parola$i = word$i'),
  ],
  sentences: [
    for (var i = 0; i < sentences; i++)
      testEntry('${id}_s$i', 'Frase numero $i. = Sentence number $i.'),
  ],
);

/// A Wizard Course (Use GuideBook on) with one Lesson holding [modules].
Course _course(List<GuidebookModule> modules) {
  final now = DateTime.utc(2026, 10, 9, 12);
  final course = CourseWizardLessons.applyTo(
    CourseLibraryOperations(clock: () => now).newWizardCourse(
      creator: const LearnerProfile(
        learnerProfileId: '12345678-1234-4234-9234-123456789abc',
        displayName: 'Author',
      ),
      title: 'Sizes',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      sourceLanguageTag: 'en',
      targetLanguageTag: 'it',
    ),
    [CourseWizardSample.lessons.first],
    now: now,
    ids: TimestampAuthoringIdGenerator(seed: 2675),
  );
  return CourseWizardGuidebook.withModules(
    course,
    course.lessons.single.lessonId,
    modules,
    state: PublicationState.published,
    now: now,
  );
}

class _NoPictures extends ExerciseImageMetadataService {
  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => const [];
}
