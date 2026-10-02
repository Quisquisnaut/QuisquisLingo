import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_en.dart';
import 'package:quisquislingo_app/localization/help/help_es.dart';
import 'package:quisquislingo_app/localization/help/help_it.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/canonical_exercise_samples.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/exercise_editor_intro.dart';
import 'package:quisquislingo_app/widgets/primitive_intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 261 Revision 6 (owner request and decisions of 2 October 2026):
/// the canonical editor explains its primitives (a popup once per
/// primitive, learner and Course; Clear all; a message when the primitive
/// changes over filled fields; Help at the primitive's section, nine
/// sections with screenshots) and its Role field is a menu of the roles QQL
/// reads.
final _stamp = DateTime.utc(2026, 10, 2, 12);
const _learner = '00000000-0000-4000-8000-000000261006';

Future<void> _setLearner() async => SharedPreferences.setMockInitialValues({
  ProfileService.profilesKey: [
    LearnerProfile(learnerProfileId: _learner, displayName: 'Owner').encode(),
  ],
  ProfileService.activeProfileIdKey: _learner,
});

Course _course(String id) => Course(
  courseId: id,
  title: 'Course $id',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

Exercise _blank(ExercisePrimitive primitive) =>
    CanonicalExerciseDraft.blankExercise(
      primitive,
      id: 'new_one',
      updatedAt: _stamp,
    );

Exercise _sample(ExercisePrimitive primitive, {String id = 'stored'}) =>
    CanonicalExerciseSamples.forPrimitive(primitive, id: id, updatedAt: _stamp);

Future<void> _pump(
  WidgetTester tester,
  Exercise exercise, {
  bool isNew = false,
  Course? course,
  bool readOnly = false,
  ValueChanged<Exercise>? onSaved,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: PrimitiveEditorScreen(
        key: UniqueKey(),
        exercise: exercise,
        title: isNew ? 'New Exercise' : 'Exercise',
        isNew: isNew,
        course: course,
        readOnly: readOnly,
        clock: () => _stamp,
        onExerciseSaved: onSaved,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choosePrimitive(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('primitive-editor-primitive')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Iterable<Course> _courseFiles() sync* {
  for (final folder in ['assets/courses', 'test/fixtures/v12']) {
    for (final file in Directory(folder).listSync().whereType<File>()) {
      if (!file.path.endsWith('.json')) continue;
      final json = jsonDecode(file.readAsStringSync());
      if (json is! Map<String, dynamic> || json['formatVersion'] != 12) {
        continue;
      }
      yield Course.fromJson(json);
    }
  }
}

Iterable<Exercise> _exercises(Course course) sync* {
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final content in round.content) {
        if (content.exercise != null) yield content.exercise!;
      }
    }
  }
}

/// A bundle holding a few screenshots, the rest missing.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);
  final Map<String, ByteData> files;

  @override
  Future<ByteData> load(String key) async =>
      files[key] ?? (throw FlutterError('missing $key'));
}

ByteData _pngHeader(int width, int height) {
  final data = ByteData(24);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < 8; i++) {
    data.setUint8(i, signature[i]);
  }
  data.setUint32(8, 13);
  data.setUint32(12, 0x49484452); // IHDR
  data.setUint32(16, width);
  data.setUint32(20, height);
  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await _setLearner();
    PrimitiveIntro.enabled = false;
    ExerciseEditorIntro.enabled = false;
    ExercisePrimitivesHelpScreen.bundle = null;
  });
  tearDown(() {
    PrimitiveIntro.enabled = false;
    ExerciseEditorIntro.enabled = false;
    ExercisePrimitivesHelpScreen.bundle = null;
  });

  group('the roles QQL reads', () {
    test('each menu offers a role once', () {
      for (final primitive in ExercisePrimitive.values) {
        for (final place in ElementPlace.values) {
          for (final type in ['text', 'audio', 'image', 'link']) {
            final ids = [
              for (final role in ElementRoles.offered(
                type: type,
                place: place,
                primitive: primitive,
              ))
                role.id,
            ];
            expect(ids.toSet().length, ids.length, reason: '$primitive $type');
          }
        }
      }
    });

    test('every role of the bundled Courses and the examples is offered', () {
      final missing = <String>{};
      void check(Exercise exercise) {
        for (final element in exercise.promptElements) {
          if (ElementRoles.find(
                element.role,
                type: element.type,
                place: ElementPlace.prompt,
                primitive: exercise.primitive,
              ) ==
              null) {
            missing.add(
              '${exercise.primitive.serialized} prompt '
              '${element.type} ${element.role}',
            );
          }
        }
        for (final item in exercise.items) {
          for (final element in item.content) {
            if (ElementRoles.find(
                  element.role,
                  type: element.type,
                  place: ElementPlace.item,
                  primitive: exercise.primitive,
                ) ==
                null) {
              missing.add(
                '${exercise.primitive.serialized} item '
                '${element.type} ${element.role}',
              );
            }
          }
        }
      }

      var count = 0;
      for (final course in _courseFiles()) {
        for (final exercise in _exercises(course)) {
          check(exercise);
          count++;
        }
      }
      for (final primitive in ExercisePrimitive.values) {
        check(_sample(primitive));
      }
      expect(count, greaterThan(300));
      expect(missing, isEmpty);
    });

    test('the roles the runtime reads are in the catalog', () {
      final ids = {for (final role in ElementRoles.all) role.id};
      expect(
        ids,
        containsAll([
          'primary',
          'question',
          'passage',
          'situation',
          'clue',
          'context',
          'dialogue_turn',
          'picture',
          'character',
          'icon',
          'term',
          'meaning',
          'usage',
          'usage_translation',
          'audio',
          'intro',
          'line',
          'title',
          'block',
        ]),
      );
    });

    test('a role outside the menu says why', () {
      expect(
        ElementRoles.notOfferedNote(
          'question',
          type: 'text',
          place: ElementPlace.prompt,
        ),
        'not used by this primitive',
      );
      expect(
        ElementRoles.notOfferedNote(
          'flavour',
          type: 'text',
          place: ElementPlace.prompt,
        ),
        'not a QQL role',
      );
    });
  });

  group('the Role menu', () {
    testWidgets('choosing a role changes the element and nothing else', (
      tester,
    ) async {
      Exercise? saved;
      await _pump(
        tester,
        _sample(ExercisePrimitive.select),
        onSaved: (exercise) => saved = exercise,
      );
      // The question's menu shows its role and what it does.
      expect(find.text('The question, or the sentence to complete.'), findsOne);
      await tester.tap(find.text('question').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('context').last);
      await tester.pumpAndSettle();
      expect(find.text('Context shown above the question.'), findsOne);
      await tester.tap(find.byKey(const Key('primitive-save')));
      await tester.pumpAndSettle();
      if (find.text('Use anyway').evaluate().isNotEmpty) {
        await tester.tap(find.text('Use anyway'));
        await tester.pumpAndSettle();
      }
      expect(saved, isNotNull);
      expect(saved!.promptElements.single.role, 'context');
      expect(saved!.promptElements.single.text, 'Which animal barks?');
    });

    testWidgets('a stored role outside the list stays and is marked', (
      tester,
    ) async {
      final sample = _sample(ExercisePrimitive.select);
      final odd = sample.copyWith(
        promptElements: [
          const PromptElement(type: 'text', role: 'flavour', text: 'Odd'),
        ],
      );
      await _pump(tester, odd);
      expect(find.text('flavour (not a QQL role)'), findsOne);
      expect(find.text('Kept as stored: not a QQL role.'), findsOne);
    });

    // At 360 pixels the option menus above overflow (they did before this
    // revision); the Role menu itself wraps and truncates.
    testWidgets('the menu fits a narrow window', (tester) async {
      tester.view.physicalSize = const Size(480, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: PrimitiveEditorScreen(
            exercise: _sample(ExercisePrimitive.presentation),
            title: 'Exercise',
            isNew: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('term').first);
      await tester.pumpAndSettle();
      expect(find.text('Flashcard: the translation of the example.'), findsOne);
      expect(tester.takeException(), isNull);
    });

    testWidgets('item content has the menu too', (tester) async {
      await _pump(tester, _sample(ExercisePrimitive.select));
      expect(find.text('The text of this item.'), findsWidgets);
    });
  });

  group('the primitive popup', () {
    setUp(() => PrimitiveIntro.enabled = true);

    testWidgets('once per primitive, learner and Course', (tester) async {
      await _pump(
        tester,
        _sample(ExercisePrimitive.select),
        course: _course('c1'),
      );
      expect(find.byKey(const Key('primitive-intro')), findsOne);
      expect(find.text('Select: how it works'), findsOne);
      await tester.tap(find.byKey(const Key('primitive-intro-ok')));
      await tester.pumpAndSettle();

      // The same primitive in the same Course: no popup.
      await _pump(
        tester,
        _sample(ExercisePrimitive.select),
        course: _course('c1'),
      );
      expect(find.byKey(const Key('primitive-intro')), findsNothing);

      // Another primitive chosen in the selector: its own popup.
      await _pump(
        tester,
        _blank(ExercisePrimitive.select),
        isNew: true,
        course: _course('c1'),
      );
      expect(find.byKey(const Key('primitive-intro')), findsNothing);
      await _choosePrimitive(tester, 'Match');
      expect(find.text('Match: how it works'), findsOne);
      await tester.tap(find.byKey(const Key('primitive-intro-ok')));
      await tester.pumpAndSettle();

      // Another Course: again.
      await _pump(
        tester,
        _sample(ExercisePrimitive.select),
        course: _course('c2'),
      );
      expect(find.text('Select: how it works'), findsOne);
      await tester.tap(find.byKey(const Key('primitive-intro-ok')));
      await tester.pumpAndSettle();

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getBool(
          'learner_${_learner}_one_time_notice_seen_primitive_intro_select_c1',
        ),
        isTrue,
      );

      // "Show one-time notices again" brings it back.
      await SettingsService().resetOneTimeNotices();
      await _pump(
        tester,
        _sample(ExercisePrimitive.select),
        course: _course('c1'),
      );
      expect(find.text('Select: how it works'), findsOne);
    });

    testWidgets('not in View only', (tester) async {
      await _pump(
        tester,
        _sample(ExercisePrimitive.select),
        course: _course('c1'),
        readOnly: true,
      );
      expect(find.byKey(const Key('primitive-intro')), findsNothing);
    });

    testWidgets('after the two-ways introduction when both are due', (
      tester,
    ) async {
      ExerciseEditorIntro.enabled = true;
      await _pump(
        tester,
        _sample(ExercisePrimitive.match),
        course: _course('c3'),
      );
      expect(find.byKey(const Key('exercise-editor-intro')), findsOne);
      expect(find.byKey(const Key('primitive-intro')), findsNothing);
      await tester.tap(find.byKey(const Key('exercise-editor-intro-ok')));
      await tester.pumpAndSettle();
      expect(find.text('Match: how it works'), findsOne);
    });

    test('every primitive has its text', () {
      expect(PrimitiveIntro.texts.keys, ExercisePrimitive.values);
    });
  });

  group('Clear all', () {
    testWidgets('a blank form clears at once', (tester) async {
      await _pump(tester, _blank(ExercisePrimitive.select), isNew: true);
      await tester.tap(find.byKey(const Key('primitive-clear-all')));
      await tester.pumpAndSettle();
      expect(find.text('Clear all fields?'), findsNothing);
    });

    testWidgets('a filled form asks, then returns to the defaults', (
      tester,
    ) async {
      await _pump(tester, _blank(ExercisePrimitive.select), isNew: true);
      await tester.tap(find.byKey(const Key('primitive-fill-example')));
      await tester.pumpAndSettle();
      expect(find.text('Which animal barks?'), findsOne);

      await tester.tap(find.byKey(const Key('primitive-clear-all')));
      await tester.pumpAndSettle();
      expect(find.text('Clear all fields?'), findsOne);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Which animal barks?'), findsOne);

      await tester.tap(find.byKey(const Key('primitive-clear-all')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('primitive-clear-all-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Which animal barks?'), findsNothing);
      expect(find.text('the dog'), findsNothing);

      // Back to blank: leaving does not ask.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsNothing);
    });

    testWidgets('an existing exercise has no Clear all', (tester) async {
      await _pump(tester, _sample(ExercisePrimitive.select));
      expect(find.byKey(const Key('primitive-clear-all')), findsNothing);
    });
  });

  group('changing the primitive', () {
    const notice = 'You changed exercise type. Please check all fields.';

    testWidgets('a blank form changes silently', (tester) async {
      await _pump(tester, _blank(ExercisePrimitive.select), isNew: true);
      await _choosePrimitive(tester, 'Match');
      expect(find.text(notice), findsNothing);
    });

    testWidgets('a filled form asks to check every field', (tester) async {
      await _pump(tester, _blank(ExercisePrimitive.select), isNew: true);
      await tester.tap(find.byKey(const Key('primitive-fill-example')));
      await tester.pumpAndSettle();
      await _choosePrimitive(tester, 'Match');
      expect(find.byKey(const Key('primitive-changed-notice')), findsOne);
      expect(find.text(notice), findsOne);
    });
  });

  group('Help for each primitive', () {
    test('nine sections in English, Italian and Spanish', () {
      final ids = [
        for (final primitive in ExercisePrimitive.values)
          exercisePrimitiveHelpSectionId(primitive.serialized),
      ];
      expect(exercisePrimitivesHelpSectionIds, containsAll(ids));
      for (final catalog in [helpEn, helpIt, helpEs]) {
        for (final id in ids) {
          final body = catalog['technical.exercisePrimitives.$id.body'];
          expect(body, isNotNull, reason: id);
          expect(body, isNotEmpty, reason: id);
        }
      }
    });

    test('the nine screenshots are in the assets as PNG files', () {
      for (final primitive in ExercisePrimitive.values) {
        final file = File(ExercisePrimitivesHelpScreen.screenshotOf(primitive));
        expect(file.existsSync(), isTrue, reason: file.path);
        final bytes = file.readAsBytesSync();
        expect(
          ExercisePrimitivesHelpScreen.pngSize(
            ByteData.sublistView(Uint8List.fromList(bytes)),
          ),
          isNotNull,
          reason: file.path,
        );
      }
    });

    testWidgets('a screenshot shows where it exists, text alone elsewhere', (
      tester,
    ) async {
      ExercisePrimitivesHelpScreen.bundle = _Bundle({
        ExercisePrimitivesHelpScreen.screenshotOf(ExercisePrimitive.select):
            _pngHeader(645, 600),
      });
      await tester.pumpWidget(
        const MaterialApp(home: ExercisePrimitivesHelpScreen()),
      );
      await tester.pumpAndSettle();
      for (final primitive in ExercisePrimitive.values) {
        expect(
          find.byKey(
            ValueKey('exercise-primitive-help-${primitive.serialized}'),
            skipOffstage: false,
          ),
          findsOne,
        );
      }
      expect(
        find.byKey(const ValueKey('exercise-primitive-help-image-select')),
        findsOne,
      );
      expect(
        find.byKey(
          const ValueKey('exercise-primitive-help-image-match'),
          skipOffstage: false,
        ),
        findsNothing,
      );
    });

    testWidgets('the canonical editor\'s Help opens at its primitive', (
      tester,
    ) async {
      await _pump(tester, _sample(ExercisePrimitive.presentation));
      tester.view.physicalSize = const Size(900, 700);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Help: Presentation'), findsOne);
      await tester.tap(find.byKey(const Key('editor-help-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise-primitives-help')), findsOne);
      final section = find.byKey(
        const ValueKey('exercise-primitive-help-presentation'),
      );
      expect(section.hitTestable(), findsOne);
      final top = tester.getTopLeft(section).dy;
      expect(top, lessThan(200));
    });

    testWidgets('elsewhere Help is unchanged', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExercisePrimitivesHelpScreen()),
      );
      await tester.pumpAndSettle();
      expect(
        find
            .byKey(const ValueKey('exercise-primitive-help-presentation'))
            .hitTestable(),
        findsNothing,
      );
    });
  });
}
