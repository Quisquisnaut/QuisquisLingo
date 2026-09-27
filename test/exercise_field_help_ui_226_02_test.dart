import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/preset_variants.dart';

// This inventory is taken from the displayed editor forms, independently of
// their controller-to-help resolver. It catches a Help control bound to the
// wrong field as well as a missing control or an unreviewed new preset.
const _formFields = <String, Map<String, String>>{
  'choice_target': {
    'Prompt / instruction': 'prompt',
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'choice_source': {
    'Prompt / instruction': 'prompt',
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'translation_choice_to_target': {
    'Text to translate': 'question',
    'Answer options': 'answers',
    'Correct answer number': 'correct',
  },
  'translation_choice_to_source': {
    'Text to translate': 'question',
    'Answer options': 'answers',
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
  'listening_answer_target': {
    'Spoken text': 'tts',
    'Question (optional)': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'listening_answer_source': {
    'Spoken text': 'tts',
    'Question (optional)': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'reading_answer_target': {
    'Text to read': 'prompt',
    'Spoken text (optional)': 'tts',
    'Dialogue lines (optional)': 'dialogue',
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'reading_answer_source': {
    'Text to read': 'prompt',
    'Spoken text (optional)': 'tts',
    'Dialogue lines (optional)': 'dialogue',
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'type_translation_to_target': {
    'Source text': 'prompt',
    'Accepted translations': 'accepted',
    'Hint (optional)': 'hint',
  },
  'type_translation_to_source': {
    'Text to translate': 'prompt',
    'Accepted translations': 'accepted',
    'Hint (optional)': 'hint',
  },
  'type_missing_word': {
    'Sentence with one ___ gap': 'prompt',
    'Complete accepted words': 'accepted',
    'Hint (optional)': 'hint',
  },
  'build_translation_to_target': {
    'Source sentence': 'prompt',
    'Available target-language blocks': 'tokens',
    'Correct translation 1': 'correctTranslation',
  },
  'build_translation_to_source': {
    'Sentence to translate': 'prompt',
    'Available source-language blocks': 'tokens',
    'Correct translation 1': 'correctTranslation',
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
  'word_match': {'Instruction': 'prompt', 'Translation pairs': 'pairs'},
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
  'picture_flashcard': {
    'Word / expression': 'prompt',
    'Translation / meaning': 'question',
    'Pronunciation TTS': 'tts',
    'Usage sentence and optional translation': 'answers',
  },
  'true_false': {
    'Statement': 'question',
    'Spoken statement (optional)': 'tts',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'gap_choice_inline': {
    'Instruction (optional)': 'prompt',
    'Sentence with gaps': 'gapLayout',
    'Distractor options (optional)': 'tokens',
    'Spoken prompt (optional)': 'tts',
  },
  'complete_text': {
    'Text with the words to hide': 'prompt',
    'Missing words': 'missingWords',
  },
  'missing_letters': {
    'Text with the missing letters in brackets': 'prompt',
    'Spoken text (optional)': 'tts',
    'Hint (optional)': 'hint',
  },
  'gap_blocks': {
    'Instruction (optional)': 'prompt',
    'Sentence with gaps': 'gapLayout',
    'Extra distractor blocks (optional)': 'tokens',
    'Spoken prompt (optional)': 'tts',
  },
  'sentence_order': {
    'Instruction': 'prompt',
    'Sentences or lines': 'tokens',
    'Correct order': 'order',
  },
  'listening_image_choice': {
    'Spoken text': 'tts',
    'Question (optional)': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'spell_heard': {
    'Spoken word': 'tts',
    'Available letter / syllable blocks': 'tokens',
    'Correct word': 'order',
  },
  'picture_choice': {
    'Question': 'question',
    'Answers': 'answers',
    'Correct answer number': 'correct',
  },
  'picture_name': {
    'Question / instruction': 'question',
    'Accepted answers': 'accepted',
    'Hint (optional)': 'hint',
  },
  'spell_word': {
    'Clue': 'prompt',
    'Available letter / syllable blocks': 'tokens',
    'Correct word': 'order',
  },
  'picture_word_match': {'Instruction': 'prompt', 'Words': 'answers'},
  'note_card': {'Title': 'prompt', 'Note': 'question'},
};

void main() {
  test('field-control inventory covers every currently offered preset', () {
    expect(
      // Script has dynamic per-option fields and two image/text modes. Its
      // complete field-control coverage lives in script_recognition_226_03_test.
      {..._formFields.keys, 'script_recognition'},
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

  testWidgets('each dynamically added correct translation has its own Help', (
    tester,
  ) async {
    await _mount(tester, 'build_translation_to_target');
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
      'build_translation_to_target',
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
    await _mount(tester, 'choice_target', size: const Size(320, 700));

    await _reveal(tester, _help('prompt'));
    await tester.tap(_help('prompt'));
    await _settle(tester);
    expect(
      find.textContaining('The instruction shown to the learner.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('How do you say this in Italian?'),
      findsOneWidget,
    );
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
        'The question the learner answers, or the word or phrase to translate.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Good morning'), findsOneWidget);
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
          'type_translation_to_target',
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
          'build_translation_to_target',
          size: Size(width, 800),
          brightness: brightness,
        );
        await _reveal(tester, _help('correctTranslation'));
        await _openAndCheck(
          tester,
          _help('correctTranslation'),
          'build_translation_to_target',
          'correctTranslation',
        );
        expect(tester.takeException(), isNull);

        await _mount(
          tester,
          'reading_answer_target',
          size: Size(width, 800),
          brightness: brightness,
        );
        await _reveal(tester, _help('dialogue'));
        await _openAndCheck(
          tester,
          _help('dialogue'),
          'reading_answer_target',
          'dialogue',
        );
        await _reveal(tester, _help('image'));
        await _openAndCheck(
          tester,
          _help('image'),
          'reading_answer_target',
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
  final exercise = Exercise(
    id: 'help-exercise',
    type: PresetVariants.formBase(preset),
    editorTemplate: preset,
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
