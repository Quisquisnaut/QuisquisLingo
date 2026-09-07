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

const _hint = 'Think about the time of day.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Hint Preview author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  testWidgets('unsaved Fill in the Blank Hint uses shared no-write Preview', (
    tester,
  ) async {
    final course = workflow.exampleCourse([_exercise()]);
    final originalJson = jsonEncode(course.toJson());
    final before = await workflow.preferences();
    final saves = <Exercise>[];
    await _open(tester, course, saves: saves, previewOnly: true);
    expect(find.text('Use ___ (3 underscores)'), findsOneWidget);
    await _enterHint(tester, _hint);
    await workflow.tapKey(tester, 'exercise-preview');
    final runtime = tester.widget<RoundScreen>(find.byType(RoundScreen));
    expect(runtime.previewMode, isTrue);
    expect(runtime.round.exercises.single.hint, _hint);
    expect(find.text('Hint: $_hint'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('gap-choice-hint'))).data,
      isNot(contains('buongiorno')),
    );
    expect(saves, isEmpty);
    expect(jsonEncode(course.toJson()), originalJson);
    expect(await workflow.preferences(), before);
    await tester.tap(find.byType(BackButton));
    await workflow.settle(tester);
    expect(
      tester
          .widget<TextField>(workflow.field('Hint (optional)'))
          .controller!
          .text,
      _hint,
    );
    expect(await workflow.preferences(), before);
    expect(tester.takeException(), isNull);
  });

  for (final state in PublicationState.values) {
    testWidgets(
      'saved ${state.name} Hint survives Course round trip and reopen',
      (tester) async {
        final course = workflow.exampleCourse([_exercise()]);
        final saves = <Exercise>[];
        await _open(tester, course, saves: saves);
        await _enterHint(tester, _hint);
        await workflow.tapKey(
          tester,
          state.isPublished ? 'exercise-save' : 'exercise-save-draft',
        );
        expect(saves, hasLength(1));
        final saved = saves.single;
        expect(saved.id, 'gap-hint');
        expect(saved.hint, _hint);
        expect(saved.publicationState, state);
        expect(saved.updatedAt, DateTime.utc(2026, 9, 7, 12));
        expect(find.byType(ExerciseEditorScreen), findsNothing);

        // The real save callback supplies the complete Exercise to the working
        // copy. Serialize the complete Course rather than a reduced Exercise DTO.
        final reloaded = Course.fromJson(
          jsonDecode(jsonEncode(workflow.exampleCourse([saved]).toJson()))
              as Map<String, dynamic>,
        );
        final persisted = reloaded.lessons.first.rounds.first.exercises.single;
        expect(persisted.hint, _hint);
        expect(persisted.publicationState, state);
        await _open(tester, reloaded, previewOnly: true);
        expect(
          tester
              .widget<TextField>(workflow.field('Hint (optional)'))
              .controller!
              .text,
          _hint,
        );
        final beforePreview = await workflow.preferences();
        await workflow.tapKey(tester, 'exercise-preview');
        expect(find.text('Hint: $_hint'), findsOneWidget);
        final runtime = tester.widget<RoundScreen>(find.byType(RoundScreen));
        expect(runtime.round.exercises.single.publicationState, state);
        expect(runtime.round.exercises.single.updatedAt, persisted.updatedAt);
        expect(await workflow.preferences(), beforePreview);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty Hint remains absent from Preview', (tester) async {
    await _open(
      tester,
      workflow.exampleCourse([_exercise()]),
      previewOnly: true,
    );
    await _enterHint(tester, '   ');
    await workflow.tapKey(tester, 'exercise-preview');
    expect(find.byType(RoundScreen), findsOneWidget);
    expect(find.byKey(const Key('gap-choice-hint')), findsNothing);
    expect(find.textContaining('Hint:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final correct in [false, true]) {
    testWidgets(
      'Hint does not change ${correct ? 'correct' : 'incorrect'} choice feedback',
      (tester) async {
        await _open(
          tester,
          workflow.exampleCourse([_exercise()]),
          previewOnly: true,
        );
        await _enterHint(tester, _hint);
        final before = await workflow.preferences();
        await workflow.tapKey(tester, 'exercise-preview');
        await tester.tap(find.text(correct ? 'buongiorno' : 'buonanotte'));
        await workflow.settle(tester);
        expect(find.text(correct ? 'Correct' : 'Incorrect'), findsOneWidget);
        expect(await workflow.preferences(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Hint cannot bypass invalid correct-answer Preview validation', (
    tester,
  ) async {
    await _open(
      tester,
      workflow.exampleCourse([_exercise()]),
      previewOnly: true,
    );
    await _enterHint(tester, _hint);
    await tester.enterText(workflow.field('Correct answer number'), '99');
    await workflow.tapKey(tester, 'exercise-preview');
    expect(find.byType(RoundScreen), findsNothing);
    expect(find.textContaining('Correct answer number'), findsWidgets);
    expect(
      tester
          .widget<TextField>(workflow.field('Hint (optional)'))
          .controller!
          .text,
      _hint,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _enterHint(WidgetTester tester, String hint) async {
  final field = workflow.field('Hint (optional)');
  await tester.ensureVisible(field);
  await tester.enterText(field, hint);
  tester.testTextInput.hide();
  await tester.pump();
}

Future<void> _open(
  WidgetTester tester,
  Course course, {
  List<Exercise>? saves,
  bool previewOnly = false,
}) async {
  await workflow.useViewport(tester);
  // Reopening mounts fresh navigator/editor state, as after a persisted reload.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<Exercise>(
                builder: (_) => ExerciseEditorScreen(
                  exercise: course.lessons.first.rounds.first.exercises.single,
                  title: 'Fill in the Blank',
                  isNew: false,
                  course: course,
                  lesson: course.lessons.first,
                  round: course.lessons.first.rounds.first,
                  onExerciseSaved: saves?.add,
                  clock: () => previewOnly
                      ? throw StateError(
                          'Preview must not stamp authoring time',
                        )
                      : DateTime.utc(2026, 9, 7, 12),
                ),
              ),
            ),
            child: const Text('Open Exercise'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Exercise'));
  await tester.pumpAndSettle();
}

Exercise _exercise() => Exercise(
  id: 'gap-hint',
  type: 'gap_choice',
  publicationState: PublicationState.draft,
  updatedAt: DateTime.utc(2026, 9, 6),
  prompt: 'Choose the missing greeting.',
  question: 'Al mattino dico ___.',
  answers: const ['buongiorno', 'buonanotte'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
