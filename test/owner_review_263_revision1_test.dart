import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/preset_examples.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 263 Revision 1 (owner review of 4 October 2026): a preset form,
/// like the canonical editor, offers Fill with an example and Clear all for
/// a new exercise, and says "You changed exercise type. Please check all
/// fields." when the preset changes over a form that holds something.

final _laboratory = Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Exercise? _labExercise(String id) {
  for (final lesson in _laboratory.lessons) {
    for (final round in lesson.rounds) {
      for (final exercise in round.exercises) {
        if (exercise.id == id) return exercise;
      }
    }
  }
  return null;
}

Course _course() => Course(
  courseId: 'r1-263-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Revision 1 263',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

/// A new exercise as the Round editor makes it: a recipe with no v11 shape
/// is what its builder makes from empty fields.
Exercise _blankFor(String presetId) {
  const id = 'r1-263-new';
  if (PresetRecipes.canonicalOnly.contains(presetId)) {
    return ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: Exercise.canonical(
          id: id,
          publicationState: PublicationState.draft,
          primitive: ExercisePrimitive.presentation,
          canonicalEvaluation: CanonicalEvaluation.none,
        ),
        type: presetId,
        publicationState: PublicationState.draft,
      ),
    ).candidate!;
  }
  return Exercise(
    id: id,
    publicationState: PublicationState.draft,
    updatedAt: DateTime.utc(2026, 10, 4),
    type: ExercisePresetRegistry.byId(presetId)!.base,
    editorTemplate: presetId,
    prompt: '',
    question: '',
    answers: const [],
    correct: null,
    tts: null,
    accepted: const [],
    tokens: const [],
    orderAnswer: const [],
    pairs: const [],
    hint: '',
    icons: const [],
  );
}

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 36000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// The form pushed over a host page, as the Round editor pushes it, so that
/// saving or leaving pops back to the host.
Future<void> _pumpForm(
  WidgetTester tester,
  String presetId, {
  Exercise? exercise,
  bool isNew = true,
  ValueChanged<Exercise>? onSaved,
}) async {
  _bigWindow(tester);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('host-$presetId'),
      navigatorKey: navigator,
      home: const Scaffold(body: Text('Host page')),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<Exercise>(
      builder: (_) => ExerciseEditorScreen(
        exercise: exercise ?? _blankFor(presetId),
        title: 'Preset form',
        isNew: isNew,
        course: _course(),
        onExerciseSaved: onSaved,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _field(WidgetTester tester, String key) => tester
    .widget<TextField>(find.byKey(ValueKey('exercise-field-$key')))
    .controller!
    .text;

Future<void> _tapButton(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  // The example comes from the bundled Laboratory, read asynchronously.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickPreset(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const Key('exercise-preset-selector')));
  await tester.pumpAndSettle();
  final tile = find.text(name).last;
  await tester.dragUntilVisible(
    tile,
    find
        .descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(ListView),
        )
        .first,
    const Offset(0, -400),
  );
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the examples', () {
    test('every preset has a Laboratory example that it represents', () {
      for (final preset in ExercisePresetRegistry.presets) {
        final id = PresetExamples.exampleIds[preset.id];
        expect(id, isNotNull, reason: preset.id);
        final example = _labExercise(id!);
        expect(example, isNotNull, reason: '${preset.id}: $id');
        expect(
          PresetRecipes.represents(example!, preset.id),
          isTrue,
          reason: '${preset.id}: $id',
        );
      }
      expect(
        PresetExamples.exampleIds.keys.toSet(),
        ExercisePresetRegistry.presets.map((preset) => preset.id).toSet(),
      );
    });

    test('an example uses no picture of another Course', () {
      for (final id in PresetExamples.exampleIds.values) {
        final json = jsonEncode(_labExercise(id)!.toJson());
        expect(json, isNot(contains('media:')), reason: id);
      }
    });

    test('the Laboratory is the bundled Course of its code', () async {
      final laboratory = await PresetExamples.loadLaboratory();
      expect(laboratory.courseId, _laboratory.courseId);
    });
  });

  group('the preset form', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Revision 1 263 author');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async {
              if (call.method == 'getApplicationSupportDirectory') {
                return testSupportDirectory.path;
              }
              throw PlatformException(code: 'test-storage');
            },
          );
      keepCrashLogUnavailable();
      PresetExamples.loadLaboratory = () async => _laboratory;
      addTearDown(
        () => PresetExamples.loadLaboratory = PresetExamples.loadBundled,
      );
    });

    testWidgets('Fill with an example fills a blank form at once', (
      tester,
    ) async {
      await _pumpForm(tester, 'choice_target');
      expect(_field(tester, 'question'), isEmpty);
      await _tapButton(tester, 'exercise-fill-example');
      expect(
        find.byKey(const Key('exercise-fill-example-confirm')),
        findsNothing,
      );
      final example = _labExercise(
        PresetExamples.exampleIds['choice_target']!,
      )!;
      final draft = PresetRecipes.decompose(example, 'choice_target');
      expect(_field(tester, 'question'), draft.question);
      expect(_field(tester, 'answers'), draft.answers);
    });

    testWidgets('Fill with an example asks before replacing the form', (
      tester,
    ) async {
      await _pumpForm(tester, 'choice_target');
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'Mine',
      );
      await tester.pump();
      await _tapButton(tester, 'exercise-fill-example');
      expect(
        find.byKey(const Key('exercise-fill-example-confirm')),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_field(tester, 'question'), 'Mine');
      await _tapButton(tester, 'exercise-fill-example');
      await tester.tap(find.byKey(const Key('exercise-fill-example-confirm')));
      await tester.pumpAndSettle();
      expect(_field(tester, 'question'), isNot('Mine'));
    });

    testWidgets('Clear all returns a filled form to the preset start', (
      tester,
    ) async {
      await _pumpForm(tester, 'choice_target');
      await _tapButton(tester, 'exercise-fill-example');
      await _tapButton(tester, 'exercise-clear-all');
      expect(
        find.byKey(const Key('exercise-clear-all-confirm')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('exercise-clear-all-confirm')));
      await tester.pumpAndSettle();
      expect(_field(tester, 'question'), isEmpty);
      expect(_field(tester, 'answers'), isEmpty);
      // A new single-answer Choose starts with answer 1 correct.
      expect(_field(tester, 'correct'), '1');
      // Back at the start: leaving asks nothing.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved Exercise changes'), findsNothing);
      expect(find.text('Host page'), findsOneWidget);
    });

    testWidgets('Clear all on a blank form asks nothing', (tester) async {
      await _pumpForm(tester, 'choice_target');
      await _tapButton(tester, 'exercise-clear-all');
      expect(find.byKey(const Key('exercise-clear-all-confirm')), findsNothing);
      expect(_field(tester, 'question'), isEmpty);
    });

    testWidgets('True or false starts again with its two answers', (
      tester,
    ) async {
      await _pumpForm(tester, 'true_false');
      await _tapButton(tester, 'exercise-fill-example');
      await _tapButton(tester, 'exercise-clear-all');
      await tester.tap(find.byKey(const Key('exercise-clear-all-confirm')));
      await tester.pumpAndSettle();
      // As when True or false is chosen in the picker: its two answers in
      // the source language, the first one correct.
      expect(_field(tester, 'answers'), 'True\nFalse');
      expect(_field(tester, 'correct'), '1');
    });

    testWidgets('changing the preset over a filled form asks to check', (
      tester,
    ) async {
      await _pumpForm(tester, 'choice_target');
      await _pickPreset(tester, 'True or false');
      expect(
        find.byKey(const Key('exercise-preset-changed-notice')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'Il gatto dorme.',
      );
      await tester.pump();
      await _pickPreset(tester, 'Choose the answer (to target)');
      expect(
        find.byKey(const Key('exercise-preset-changed-notice')),
        findsOneWidget,
      );
      expect(
        find.text('You changed exercise type. Please check all fields.'),
        findsOneWidget,
      );
    });

    testWidgets('an existing exercise has no Fill or Clear', (tester) async {
      final example = _labExercise(
        PresetExamples.exampleIds['choice_target']!,
      )!;
      await _pumpForm(tester, 'choice_target', exercise: example, isNew: false);
      expect(find.byKey(const Key('exercise-fill-example')), findsNothing);
      expect(find.byKey(const Key('exercise-clear-all')), findsNothing);
    });

    testWidgets('every preset saves its example as that preset', (
      tester,
    ) async {
      for (final preset in ExercisePresetRegistry.presets) {
        Exercise? saved;
        await _pumpForm(
          tester,
          preset.id,
          onSaved: (exercise) => saved = exercise,
        );
        await _tapButton(tester, 'exercise-fill-example');
        expect(
          find.byKey(const Key('exercise-fill-example-missing')),
          findsNothing,
          reason: preset.id,
        );
        await tester.ensureVisible(
          find.byKey(const Key('exercise-save-draft')),
        );
        await tester.tap(find.byKey(const Key('exercise-save-draft')));
        // Recognize characters checks its pictures by decoding them, which
        // needs real asynchronous work.
        for (var attempt = 0; attempt < 20 && saved == null; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pumpAndSettle();
        }
        expect(saved, isNotNull, reason: preset.id);
        final example = _labExercise(PresetExamples.exampleIds[preset.id]!)!;
        expect(saved!.id, 'r1-263-new', reason: preset.id);
        expect(
          PresetRecipes.represents(saved!, preset.id),
          isTrue,
          reason: preset.id,
        );
        // The example's content, under this exercise's own IDs.
        expect(
          saved!.items.map((item) => item.label).toList(),
          example.items.map((item) => item.label).toList(),
          reason: preset.id,
        );
        expect(
          saved!.items.any((item) => item.id.startsWith('qql_lab254')),
          isFalse,
          reason: preset.id,
        );
      }
    });
  });
}
