import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;
import 'support/test_directories.dart';

final _saveTime = DateTime.utc(2026, 9, 24, 10, 11, 12);

void _largeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(2400, 12000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _mount(
  WidgetTester tester,
  Exercise original,
  ValueChanged<Exercise> onSaved, {
  bool isNew = true,
  Course? course,
}) async {
  _largeViewport(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: ExerciseEditorScreen(
        exercise: original,
        title: 'Characterize Exercise authoring',
        isNew: isNew,
        clock: () => _saveTime,
        course: course,
        lesson: course?.lessons.first,
        round: course?.lessons.first.rounds.first,
        onExerciseSaved: onSaved,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _contentJson(Exercise exercise) =>
    LearningContent.fromExercise(exercise).toJson();

void _expectV11RoundTrip(Exercise exercise) {
  final content = _contentJson(exercise);
  final contentAgain = LearningContent.fromJson(
    jsonDecode(jsonEncode(content)) as Map<String, dynamic>,
  );
  expect(contentAgain.toJson(), content);
  expect(contentAgain.id, exercise.id);
  expect(contentAgain.publicationState, exercise.publicationState);

  final course = workflow.exampleCourse([exercise]);
  final courseJson = course.toJson();
  expect(courseJson['formatVersion'], 11);
  final reloaded = Course.fromJson(
    jsonDecode(jsonEncode(courseJson)) as Map<String, dynamic>,
  );
  expect(reloaded.toJson(), courseJson);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Exercise characterization author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationSupportDirectory') {
              return testSupportDirectory.path;
            }
            throw PlatformException(code: 'test_storage_unavailable');
          },
        );
    keepCrashLogUnavailable();
  });

  testWidgets(
    'Draft choice accepts an invalid answer number; Preview rejects it and v11 JSON keeps the empty evaluation',
    (tester) async {
      final original = workflow.modelExercise('choice', PublicationState.draft);
      final course = workflow.exampleCourse([original]);
      Exercise? saved;
      await _mount(
        tester,
        original,
        (value) => saved = value,
        isNew: false,
        course: course,
      );
      await tester.enterText(workflow.field('Correct answer number'), '99');
      await workflow.tapKey(tester, 'exercise-preview');
      expect(find.byType(RoundScreen), findsNothing);
      expect(find.textContaining('Correct answer number'), findsWidgets);
      expect(saved, isNull);

      await workflow.tapKey(tester, 'exercise-save-draft');
      expect(saved, isNotNull);
      expect(_contentJson(saved!), {
        'id': 'preview-choice',
        'publicationState': 'draft',
        'kind': 'exercise',
        'required': true,
        'editorTemplate': 'choice',
        'exercise': {
          'updatedAt': _saveTime.toIso8601String(),
          'prompt': [
            {
              'role': 'primary',
              'type': 'text',
              'text': 'Translate this greeting',
            },
            {
              'role': 'question',
              'type': 'text',
              'text': 'Choose the greeting.',
            },
          ],
          'interaction': {
            'kind': 'select',
            'minSelections': 1,
            'maxSelections': 1,
            'items': [
              {
                'id': 'item_0',
                'content': [
                  {'role': 'primary', 'type': 'text', 'text': 'Ciao'},
                ],
              },
              {
                'id': 'item_1',
                'content': [
                  {'role': 'primary', 'type': 'text', 'text': 'Casa'},
                ],
              },
            ],
          },
          'evaluation': {'kind': 'selected_items'},
        },
      });
      expect(original.correct, 0);
      _expectV11RoundTrip(saved!);
    },
  );

  testWidgets('Published choice Save keeps the exercise and item IDs', (
    tester,
  ) async {
    final original = workflow.modelExercise('choice', PublicationState.draft);
    Exercise? saved;
    await _mount(tester, original, (value) => saved = value);
    await workflow.tapKey(tester, 'exercise-save');
    expect(saved, isNotNull);
    expect(saved!.id, original.id);
    expect(saved!.publicationState, PublicationState.published);
    expect(saved!.updatedAt, _saveTime);
    expect(saved!.interaction.items.map((item) => item.id), [
      'item_0',
      'item_1',
    ]);
    expect(saved!.evaluation.correctItemIds, ['item_0']);
    expect(_contentJson(saved!)['publicationState'], 'published');
    _expectV11RoundTrip(saved!);
  });

  for (final type in [
    'type_translation',
    'build_translation',
    'matching',
    'contextual_comprehension',
    'flashcard',
    'listening_spelling',
  ]) {
    testWidgets('$type Save Draft retains its v11 content wrapper', (
      tester,
    ) async {
      final original = workflow.modelExercise(type, PublicationState.draft);
      Exercise? saved;
      await _mount(tester, original, (value) => saved = value);
      await workflow.tapKey(tester, 'exercise-save-draft');
      expect(saved, isNotNull);
      expect(saved!.id, original.id);
      expect(saved!.editorTemplate, type);
      expect(saved!.publicationState, PublicationState.draft);
      expect(saved!.updatedAt, _saveTime);
      final content = _contentJson(saved!);
      expect(content['id'], original.id);
      expect(content['publicationState'], 'draft');
      expect(content['editorTemplate'], type);
      expect(
        content['kind'],
        type == 'flashcard' ? 'presentation' : 'exercise',
      );
      if (type == 'matching') {
        expect(saved!.interaction.items.map((item) => item.id), [
          'item_0',
          'item_1',
          'item_2',
          'item_3',
          'item_4',
          'item_5',
        ]);
        expect(saved!.evaluation.pairs, [
          ['item_0', 'item_1'],
          ['item_2', 'item_3'],
          ['item_4', 'item_5'],
        ]);
      }
      if (type == 'type_translation') {
        expect(saved!.interaction.kind, 'input');
        expect(saved!.evaluation.accepted, ['Ciao']);
      }
      if (type == 'build_translation') {
        expect(saved!.interaction.kind, 'arrange');
        expect(saved!.interaction.items.map((item) => item.id), [
          'item_0',
          'item_1',
        ]);
        expect(saved!.evaluation.correctOrders.single.itemIds, [
          'item_0',
          'item_1',
        ]);
      }
      if (type == 'contextual_comprehension') {
        expect(saved!.interaction.kind, 'select');
        expect(saved!.interaction.items.map((item) => item.id), [
          'item_0',
          'item_1',
        ]);
      }
      _expectV11RoundTrip(saved!);
    });
  }

  testWidgets('inline Arrange keeps deterministic item and gap IDs in v11', (
    tester,
  ) async {
    final original = workflow.modelExercise(
      'word_order',
      PublicationState.draft,
    );
    Exercise? saved;
    await _mount(tester, original, (value) => saved = value);
    await workflow.tapKey(tester, 'word-order-use-inline-gaps');
    await tester.enterText(
      workflow.field('Sentence with gaps'),
      'I {go} {to} school.',
    );
    await tester.enterText(
      workflow.field('Extra distractor blocks (optional)'),
      'goes\nfrom',
    );
    await workflow.tapKey(tester, 'exercise-save-draft');
    expect(saved, isNotNull);
    expect(saved!.id, original.id);
    expect(saved!.interaction.items.map((item) => item.id), [
      'item_0',
      'item_1',
      'item_2',
      'item_3',
    ]);
    expect(saved!.interaction.layout.map((element) => element.text), [
      'I',
      'gap_1',
      'gap_2',
      'school.',
    ]);
    expect(saved!.evaluation.gapAssignments, {
      'gap_1': 'item_0',
      'gap_2': 'item_1',
    });
    _expectV11RoundTrip(saved!);
  });

  testWidgets('linked-gap Select reuses an option ID across two gaps', (
    tester,
  ) async {
    final original = workflow.modelExercise('choice', PublicationState.draft);
    Exercise? saved;
    await _mount(tester, original, (value) => saved = value);
    await workflow.tapKey(tester, 'choice-use-inline-gaps');
    await tester.enterText(
      workflow.field('Sentence with gaps'),
      '{Was} she happy? {Was} he late?',
    );
    await tester.enterText(
      workflow.field('Distractor options (optional)'),
      'Perhaps',
    );
    await workflow.tapKey(tester, 'exercise-save-draft');
    expect(saved, isNotNull);
    expect(saved!.interaction.items.map((item) => item.id), [
      'item_0',
      'item_1',
    ]);
    expect(saved!.interaction.items.map((item) => item.value), [
      'Was',
      'Perhaps',
    ]);
    expect(saved!.evaluation.gapAssignments, {
      'gap_1': 'item_0',
      'gap_2': 'item_0',
    });
    _expectV11RoundTrip(saved!);
  });

  testWidgets('multi-select keeps ordered IDs and selection bounds', (
    tester,
  ) async {
    final original = workflow.modelExercise('choice', PublicationState.draft);
    Exercise? saved;
    await _mount(tester, original, (value) => saved = value);
    await workflow.tapKey(tester, 'choice-use-multi-select');
    await tester.enterText(workflow.field('Answers'), 'Apple\nCarrot\nBanana');
    await tester.enterText(workflow.field('Correct answer numbers'), '1, 3');
    await workflow.tapKey(tester, 'exercise-save-draft');
    expect(saved, isNotNull);
    expect(saved!.interaction.items.map((item) => item.id), [
      'item_0',
      'item_1',
      'item_2',
    ]);
    expect(saved!.evaluation.correctItemIds, ['item_0', 'item_2']);
    expect(saved!.interaction.minSelections, 2);
    expect(saved!.interaction.maxSelections, 3);
    _expectV11RoundTrip(saved!);
  });

  final asset = 'media:${List.filled(64, 'a').join()}.webp';
  const source = SharedImageSource(
    id: 'shared-cat',
    label: 'Cat',
    category: 'animals',
    tags: ['cat'],
    origin: 'local',
  );
  Exercise sourcedChoice() {
    final base = workflow.modelExercise('choice', PublicationState.draft);
    return Exercise.v2(
      id: base.id,
      publicationState: base.publicationState,
      updatedAt: base.updatedAt,
      editorTemplate: base.editorTemplate,
      promptElements: [
        ...base.promptElements,
        PromptElement(
          role: 'clue',
          type: 'image',
          asset: asset,
          sharedImageSource: source,
        ),
      ],
      interaction: base.interaction,
      evaluation: base.evaluation,
    );
  }

  testWidgets('Save retains a Course-owned image source in v11 JSON', (
    tester,
  ) async {
    final original = sourcedChoice();
    Exercise? saved;
    await _mount(tester, original, (value) => saved = value);
    await workflow.tapKey(tester, 'exercise-save-draft');
    expect(saved, isNotNull);
    final images = saved!.promptElements
        .where((e) => e.type == 'image')
        .toList();
    expect(images, hasLength(1));
    expect(images.single.asset, asset);
    expect(images.single.sharedImageSource?.toJson(), source.toJson());
    final json = _contentJson(saved!);
    final exerciseJson = json['exercise'] as Map<String, dynamic>;
    expect(
      (exerciseJson['prompt'] as List).cast<Map>().last['sharedImageSource'],
      source.toJson(),
    );
    _expectV11RoundTrip(saved!);
  });

  testWidgets(
    'Remove image clears its provenance only in the saved candidate',
    (tester) async {
      final original = sourcedChoice();
      Exercise? saved;
      await _mount(tester, original, (value) => saved = value);
      final remove = find.text('Remove image');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await workflow.tapKey(tester, 'exercise-save-draft');
      expect(saved, isNotNull);
      expect(saved!.promptElements.where((e) => e.type == 'image'), isEmpty);
      expect(
        original.promptElements
            .singleWhere((e) => e.type == 'image')
            .sharedImageSource
            ?.id,
        source.id,
      );
      _expectV11RoundTrip(saved!);
    },
  );

  testWidgets(
    'typed-answer Preview and Cancel leave Course and callback untouched',
    (tester) async {
      _largeViewport(tester);
      final original = workflow.modelExercise(
        'type_translation',
        PublicationState.draft,
      );
      final course = workflow.exampleCourse([original]);
      final beforeCourse = jsonEncode(course.toJson());
      var saveCount = 0;
      Exercise? returned;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  returned = await Navigator.of(context).push<Exercise>(
                    MaterialPageRoute(
                      builder: (_) => ExerciseEditorScreen(
                        exercise: original,
                        title: 'Typed answer',
                        isNew: false,
                        course: course,
                        lesson: course.lessons.first,
                        round: course.lessons.first.rounds.first,
                        clock: () => throw StateError(
                          'Preview and Cancel must not stamp authoring time',
                        ),
                        onExerciseSaved: (_) => saveCount++,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(workflow.field('Source text'), 'Unsaved source');
      await workflow.tapKey(tester, 'exercise-preview');
      expect(find.byType(RoundScreen), findsOneWidget);
      expect(
        tester
            .widget<RoundScreen>(find.byType(RoundScreen))
            .round
            .exercises
            .single
            .prompt,
        'Unsaved source',
      );
      expect(saveCount, 0);
      expect(jsonEncode(course.toJson()), beforeCourse);

      await tester.tap(find.byType(BackButton).last);
      await workflow.settle(tester);
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton).last);
      await workflow.settle(tester);
      expect(find.text('Unsaved Exercise changes'), findsOneWidget);
      await tester.tap(find.text('Discard changes'));
      await workflow.settle(tester);
      expect(returned, isNull);
      expect(saveCount, 0);
      expect(jsonEncode(course.toJson()), beforeCourse);
      expect(original.prompt, 'Translate this greeting');
    },
  );
}
