import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_workflow_226_02_test.dart' as workflow;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    _mockAudio();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Guidance author');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  testWidgets(
    'How do you say Prompt and Question examples match unchanged real Preview roles',
    (tester) async {
      final source = _exercise('choice');
      await _mount(tester, source);
      await _hoverHelp(tester, 'choice', 'prompt');
      await _hoverHelp(tester, 'choice', 'question');
      await _enter(
        tester,
        'Prompt / instruction',
        'How do you say this in Italian?',
      );
      await _enter(tester, 'Question', 'Good morning');
      final original = jsonEncode(source.toJson());
      final preferences = await workflow.preferences();
      await workflow.tapKey(tester, 'exercise-preview');
      final preview = tester.widget<RoundScreen>(find.byType(RoundScreen));
      expect(
        preview.round.exercises.single.prompt,
        'How do you say this in Italian?',
      );
      expect(preview.round.exercises.single.question, 'Good morning');
      expect(
        find.descendant(
          of: find.byType(RoundScreen),
          matching: find.text('How do you say this in Italian?'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(RoundScreen),
          matching: find.text('Good morning'),
        ),
        findsOneWidget,
      );
      expect(jsonEncode(source.toJson()), original);
      expect(await workflow.preferences(), preferences);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Context text is the passage with background and Text is only its presentation mode',
    (tester) async {
      final source = _exercise('contextual_comprehension');
      await _mount(tester, source);
      expect(workflow.field('Text'), findsNothing);
      expect(workflow.field('Context text'), findsOneWidget);
      expect(find.byKey(const Key('context-mode-selector')), findsOneWidget);
      await _hoverHelp(tester, 'contextual_comprehension', 'contextMode');
      await _hoverHelp(tester, 'contextual_comprehension', 'context');
      const passage =
          'Marta is describing her daily routine. Marta takes the train to work every morning.';
      await _enter(tester, 'Context text', passage);
      await _enter(tester, 'Question', 'How does Marta travel to work?');
      await workflow.tapKey(tester, 'exercise-preview');
      final exercise = tester
          .widget<RoundScreen>(find.byType(RoundScreen))
          .round
          .exercises
          .single;
      expect(exercise.contextText, passage);
      expect(exercise.question, 'How does Marta travel to work?');
      expect(
        find.descendant(
          of: find.byType(RoundScreen),
          matching: find.text(passage),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  const modeGuidance = {
    'tts': 'QQL reads this text aloud using the device’s native TTS.',
    'recorded':
        'Recorded MP3: QQL matches this text to this Course’s Audio Library recordings.',
    'hybrid':
        'Hybrid: QQL tries this Course’s MP3 recordings, then native TTS if a complete sequence is unavailable.',
  };
  for (final mode in modeGuidance.entries) {
    testWidgets(
      'Spoken text explains the actual ${mode.key} audio mode and MP3 association workflow',
      (tester) async {
        await _mount(
          tester,
          _exercise('listening_choice'),
          audioMode: mode.key,
        );
        final field = workflow.field('Spoken text');
        await tester.ensureVisible(field);
        expect(workflow.field('Audio text'), findsNothing);
        expect(
          tester.widget<TextField>(field).decoration!.helperText,
          mode.value,
        );
        expect(find.text(mode.value), findsOneWidget);
        await _hoverHelp(tester, 'listening_choice', 'tts');
        final button = find.byKey(const ValueKey('exercise-field-help-tts'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        final help = ExerciseFieldHelpRegistry.forEditorField(
          'listening_choice',
          'tts',
        );
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(help.text),
          ),
          findsOneWidget,
        );
        for (final required in [
          'Course Editor > Audio Library',
          'Documents/QuisquisLingo/Imports/Audio',
          'Import MP3',
          'Associate recording',
          'Word or expression',
          'no per-exercise file attachment',
          'JSON alone does not transfer recordings',
        ]) {
          expect(help.text, contains(required));
        }
        await tester.tap(find.widgetWithText(TextButton, 'Close'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text,
          'Buongiorno, come stai?',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Spoken text rename leaves other listening preset labels intact',
    (tester) async {
      await _mount(tester, _exercise('listening_comprehension'));
      expect(workflow.field('Spoken passage'), findsOneWidget);
      expect(workflow.field('Spoken text'), findsNothing);
    },
  );

  testWidgets(
    'lowercase guidance is visible and never rewrites proper names or author syntax',
    (tester) async {
      final source = _exercise('type_translation');
      await _mount(tester, source);
      const expression = '{io} [amo|visito] Roma';
      final accepted = workflow.field('Accepted translations');
      await tester.ensureVisible(accepted);
      expect(
        find.textContaining('Use lowercase except for proper names.'),
        findsWidgets,
      );
      await tester.enterText(accepted, expression);
      await workflow.tapKey(tester, 'expand-translation-answers');
      expect(find.text('4 answers generated'), findsOneWidget);
      final generated = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;
      expect(generated.split('\n'), [
        'Amo Roma',
        'Visito Roma',
        'Io amo Roma',
        'Io visito Roma',
      ]);
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(accepted).controller!.text, expression);
      await workflow.tapKey(tester, 'exercise-preview');
      expect(
        tester
            .widget<RoundScreen>(find.byType(RoundScreen))
            .round
            .exercises
            .single
            .accepted,
        [expression],
      );
      expect(source.accepted, ['caffè']);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _hoverHelp(
  WidgetTester tester,
  String preset,
  String field,
) async {
  final button = find.byKey(ValueKey('exercise-field-help-$field'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  final expected = ExerciseFieldHelpRegistry.forEditorField(
    preset,
    field,
  ).purpose;
  expect(expected, contains('Example:'));
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  await mouse.moveTo(tester.getCenter(button));
  await tester.pump(const Duration(seconds: 1));
  expect(find.text(expected), findsOneWidget);
  await mouse.removePointer();
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String text) async {
  final field = workflow.field(label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester,
  Exercise exercise, {
  String audioMode = 'tts',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1100, 1500);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final course = Course.fromJson({
    ...workflow.exampleCourse([exercise]).toJson(),
    'audioMode': audioMode,
  });
  await tester.pumpWidget(
    MaterialApp(
      home: ExerciseEditorScreen(
        exercise: exercise,
        title: 'Field guidance',
        isNew: false,
        course: course,
        lesson: course.lessons.first,
        round: course.lessons.first.rounds.first,
        clock: () =>
            throw StateError('Help and Preview must not stamp authoring time'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Exercise _exercise(String type) => Exercise(
  id: 'guidance-exercise',
  type: type,
  updatedAt: DateTime.utc(2026, 9, 8),
  publicationState: PublicationState.draft,
  prompt: type == 'contextual_comprehension'
      ? 'Marta takes the train.'
      : 'Read the instruction.',
  question: 'Choose one.',
  answers: const ['Buongiorno', 'Buonasera'],
  correct: 0,
  tts: type.startsWith('listening') ? 'Buongiorno, come stai?' : null,
  accepted: const ['caffè'],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

void _mockAudio() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}
