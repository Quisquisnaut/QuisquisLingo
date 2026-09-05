import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';

// This inventory is taken from the displayed editor forms, independently of
// their controller-to-help resolver. It catches a Help control bound to the
// wrong field as well as a missing control or an unreviewed new preset.
const _formFields = <String, Map<String, String>>{
  'choice': {
    'Prompt / instruction': 'prompt',
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'gap_choice': {
    'Target-language sentence with one gap': 'question',
    'Answer blocks': 'answers',
    'Correct answer number': 'correct',
    'Hint (optional)': 'hint',
  },
  'icon_choice': {
    'Question': 'question',
    'Target-language options': 'answers',
    'Correct answer number': 'correct',
    'Icons / image keys': 'icons',
  },
  'listening_choice': {
    'Audio text': 'tts',
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'listening_comprehension': {
    'Spoken passage': 'tts',
    'Comprehension question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'reading_comprehension': {
    'Reading passage': 'prompt',
    'Comprehension question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'dialogue_response': {
    'Context sentence': 'prompt',
    'Question': 'question',
    'Two response options': 'answers',
    'Correct response number': 'correct',
  },
  'contextual_comprehension': {
    'Context text': 'context',
    'Context audio text': 'tts',
    'Structured dialogue (optional)': 'dialogue',
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'type_translation': {
    'Source text': 'prompt',
    'Accepted translations': 'accepted',
    'Hint (optional)': 'hint',
  },
  'build_translation': {
    'Source sentence': 'prompt',
    'Available target-language blocks': 'tokens',
    'Correct translation 1': 'correctTranslation',
  },
  'fill_blank': {
    'Incomplete word / phrase': 'question',
    'Accepted answers': 'accepted',
    'Hint': 'hint',
    'Complete phrase TTS (optional)': 'tts',
  },
  'listening_spelling': {
    'Passage transcript': 'prompt',
    'Audio text': 'tts',
    'Missing word': 'missingWords',
  },
  'missing_word': {
    'Passage transcript': 'prompt',
    'Audio text': 'tts',
    'Missing word(s)': 'missingWords',
  },
  'matching': {'Instruction': 'prompt', 'Pairs': 'pairs'},
  'word_match': {'Instruction': 'prompt', 'Three translation pairs': 'pairs'},
  'super_match': {
    'Match type / instruction': 'prompt',
    'Three target-language pairs': 'pairs',
  },
  'audio_match': {'Instruction': 'prompt', 'Three sound matches': 'pairs'},
  'word_order': {
    'Translation prompt / instruction': 'prompt',
    'Available word blocks': 'tokens',
    'Correct sentence': 'order',
  },
  'image_word': {
    'Instruction': 'prompt',
    'Available letter / syllable blocks': 'tokens',
    'Correct target-language word': 'order',
  },
  'flashcard': {
    'Word / expression': 'prompt',
    'Translation / meaning': 'question',
    'Pronunciation TTS': 'tts',
    'Usage sentence and optional translation': 'answers',
  },
};

void main() {
  test('field-control inventory covers every currently offered preset', () {
    expect(
      _formFields.keys.toSet(),
      ExercisePresetRegistry.presets.map((preset) => preset.id).toSet(),
    );
  });

  for (final form in _formFields.entries) {
    testWidgets('${form.key}: each actual field opens its contextual Help', (
      tester,
    ) async {
      await _mount(tester, form.key, size: const Size(900, 1600));
      expect(find.widgetWithText(TextButton, 'Exercise Help'), findsOneWidget);
      for (final field in form.value.entries) {
        final input = _field(field.key);
        await _reveal(tester, input);
        _assertMountedFieldsHaveHelp(tester, form.value);
        final textField = tester.widget<TextField>(input);
        final control = textField.decoration?.suffixIcon;
        expect(control, isA<IconButton>(), reason: field.key);
        expect(
          control!.key,
          ValueKey('exercise-field-help-${field.value}'),
          reason: field.key,
        );
        final button = find.descendant(
          of: input,
          matching: find.byKey(ValueKey('exercise-field-help-${field.value}')),
        );
        await _openAndCheck(tester, button, form.key, field.value);
      }
      await _reveal(tester, _help('image'));
      _assertMountedFieldsHaveHelp(tester, form.value);
      await _openAndCheck(tester, _help('image'), form.key, 'image');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('conditional context fields and mode retain direct Help', (
    tester,
  ) async {
    await _mount(tester, 'contextual_comprehension');
    await _reveal(tester, _help('contextMode'));
    await _openAndCheck(
      tester,
      _help('contextMode'),
      'contextual_comprehension',
      'contextMode',
    );

    final mode = find.byKey(const Key('context-mode-selector'));
    await _reveal(tester, mode);
    await tester.tap(mode);
    await _settle(tester);
    await tester.tap(find.text('Audio').last);
    await _settle(tester);
    await _reveal(tester, _field('Context audio text'));
    expect(_field('Context text'), findsNothing);
    expect(_field('Structured dialogue (optional)'), findsNothing);
    await _openAndCheck(
      tester,
      _help('tts'),
      'contextual_comprehension',
      'tts',
    );

    await _reveal(tester, mode);
    await tester.tap(mode);
    await _settle(tester);
    await tester.tap(find.text('Text').last);
    await _settle(tester);
    await _reveal(tester, _field('Context text'));
    expect(_field('Context audio text'), findsNothing);
    await _openAndCheck(
      tester,
      _help('context'),
      'contextual_comprehension',
      'context',
    );
    await _reveal(tester, _field('Structured dialogue (optional)'));
    await _openAndCheck(
      tester,
      _help('dialogue'),
      'contextual_comprehension',
      'dialogue',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('each dynamically added correct translation has its own Help', (
    tester,
  ) async {
    await _mount(tester, 'build_translation');
    final add = find.byKey(const Key('add-correct-translation'));
    await _reveal(tester, add);
    await tester.tap(add);
    await _settle(tester);
    final second = _field('Correct translation 2');
    await _reveal(tester, second);
    await tester.enterText(second, 'Vorrei un caffè.');
    final button = find.descendant(
      of: second,
      matching: _help('correctTranslation'),
    );
    await _openAndCheck(
      tester,
      button,
      'build_translation',
      'correctTranslation',
    );
    expect(
      tester.widget<TextField>(second).controller!.text,
      'Vorrei un caffè.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prompt and Question Help stay distinct and fit at 320 px', (
    tester,
  ) async {
    await _mount(tester, 'choice', size: const Size(320, 700));

    await _reveal(tester, _help('prompt'));
    await tester.tap(_help('prompt'));
    await _settle(tester);
    expect(
      find.textContaining('The instruction or context shown to the learner.'),
      findsOneWidget,
    );
    expect(find.textContaining('Translate into Italian.'), findsOneWidget);
    var bounds = tester.getRect(find.byType(AlertDialog));
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(320));
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await _settle(tester);

    await _reveal(tester, _help('question'));
    await tester.tap(_help('question'));
    await _settle(tester);
    expect(
      find.textContaining(
        'The concrete content to which the learner responds.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('How are you?'), findsOneWidget);
    bounds = tester.getRect(find.byType(AlertDialog));
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 375.0, 430.0, 1100.0]) {
      testWidgets('Help dialogs fit $width px in ${brightness.name}', (
        tester,
      ) async {
        await _mount(
          tester,
          'type_translation',
          size: Size(width, 800),
          brightness: brightness,
        );
        final accepted = _field('Accepted translations');
        await _reveal(tester, accepted);
        await tester.enterText(accepted, '{Io} [prendo|vorrei] un cappuccino');
        // Editing schedules a form rebuild and caret-driven scrolling. Finish
        // both before hit-testing the suffix control at its new position.
        await _settle(tester);
        await _reveal(tester, _help('accepted'));
        expect(
          tester.widget<IconButton>(_help('accepted')).onPressed,
          isNotNull,
        );
        expect(_help('accepted').hitTestable(), findsOneWidget);
        await tester.tap(_help('accepted'));
        await _settle(tester);
        final dialog = find.byType(AlertDialog);
        expect(dialog, findsOneWidget);
        final body = find.descendant(
          of: dialog,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data?.contains('equal alternative counts') ?? false),
          ),
        );
        expect(body, findsOneWidget);
        final text = tester.widget<Text>(body).data!;
        expect(text, contains('{Io}'));
        expect(text, contains('[*:il|i]'));
        expect(text, contains('(non arrivo <> oggi)'));
        expect(text, contains('128 answers'));
        expect(
          find.descendant(
            of: dialog,
            matching: find.byType(SingleChildScrollView),
          ),
          findsWidgets,
        );
        final bounds = tester.getRect(dialog);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(TextButton, 'Close'));
        await _settle(tester);
        expect(
          tester.widget<TextField>(accepted).controller!.text,
          '{Io} [prendo|vorrei] un cappuccino',
        );

        await _mount(
          tester,
          'build_translation',
          size: Size(width, 800),
          brightness: brightness,
        );
        await _reveal(tester, _help('correctTranslation'));
        await _openAndCheck(
          tester,
          _help('correctTranslation'),
          'build_translation',
          'correctTranslation',
        );
        expect(tester.takeException(), isNull);

        await _mount(
          tester,
          'contextual_comprehension',
          size: Size(width, 800),
          brightness: brightness,
        );
        await _reveal(tester, _help('contextMode'));
        await _openAndCheck(
          tester,
          _help('contextMode'),
          'contextual_comprehension',
          'contextMode',
        );
        await _reveal(tester, _help('image'));
        await _openAndCheck(
          tester,
          _help('image'),
          'contextual_comprehension',
          'image',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _help(String fieldKey) =>
    find.byKey(ValueKey('exercise-field-help-$fieldKey'));

void _assertMountedFieldsHaveHelp(
  WidgetTester tester,
  Map<String, String> expectedFields,
) {
  for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
    final label = field.decoration?.labelText;
    expect(
      expectedFields.containsKey(label),
      isTrue,
      reason: 'Review Help for an added or renamed authoring field: $label',
    );
    final control = field.decoration?.suffixIcon;
    expect(control, isA<IconButton>(), reason: label);
    expect(
      control!.key,
      ValueKey('exercise-field-help-${expectedFields[label]}'),
      reason: label,
    );
  }
}

Future<void> _openAndCheck(
  WidgetTester tester,
  Finder control,
  String preset,
  String key,
) async {
  final expected = ExerciseFieldHelpRegistry.forEditorField(preset, key);
  final button = tester.widget<IconButton>(control);
  expect(button.tooltip, expected.purpose);
  expect(button.onPressed, isNotNull);
  await tester.ensureVisible(control);
  await tester.tap(control);
  await _settle(tester);
  final dialog = find.byType(AlertDialog);
  expect(dialog, findsOneWidget);
  expect(
    find.descendant(of: dialog, matching: find.text(expected.title)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: dialog, matching: find.text(expected.text)),
    findsOneWidget,
  );
  await tester.tap(find.widgetWithText(TextButton, 'Close'));
  await _settle(tester);
  expect(find.byType(AlertDialog), findsNothing);
}

Future<void> _reveal(WidgetTester tester, Finder target) async {
  final scrollable = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(
    target,
    220,
    scrollable: scrollable,
    maxScrolls: 35,
  );
  await tester.ensureVisible(target);
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}

Future<void> _mount(
  WidgetTester tester,
  String preset, {
  Size size = const Size(800, 1000),
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final exercise = preset == 'contextual_comprehension'
      ? Exercise.v2(
          id: 'help-exercise',
          editorTemplate: preset,
          publicationState: PublicationState.draft,
          updatedAt: DateTime.utc(2026, 9, 5),
          promptElements: const [
            PromptElement(
              role: 'context',
              type: 'text',
              text: 'Context passage',
            ),
            PromptElement(
              role: 'context',
              type: 'audio',
              text: 'Spoken passage',
            ),
          ],
          interaction: const ExerciseInteraction(kind: 'select'),
          evaluation: const ExerciseEvaluation(kind: 'selected_items'),
        )
      : Exercise(
          id: 'help-exercise',
          type: preset,
          publicationState: PublicationState.draft,
          updatedAt: DateTime.utc(2026, 9, 5),
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
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: ExerciseEditorScreen(
        exercise: exercise,
        title: 'Exercise field Help',
        isNew: true,
      ),
    ),
  );
  await _settle(tester);
}
