import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/first_letter_answer_service.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/widgets/course_media_image.dart';
import 'package:quisquislingo_app/widgets/portable_exercise_image.dart';
import 'package:quisquislingo_app/widgets/script_recognition_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/laboratory_presentation_254.dart';
import 'support/test_directories.dart';

const _asset = 'assets/courses/exercise_laboratory_en_it.json';

Map<String, dynamic> _json() =>
    jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;

/// The examples: every exercise but the Before you start card that opens
/// each Round (Build 257), which is no example of its own.
List<Exercise> _exercises(Course course) => [
  for (final lesson in course.lessons)
    for (final round in lesson.rounds)
      ...round.exercises.where(
        (e) => ExerciseFeatures(e).kind != LearnerExerciseKind.roundIntro,
      ),
];

/// Reconstruct the values exposed by the real authoring form. The production
/// builder, audit and runtime then consume the candidate; no grader is mocked.
Exercise _author(Exercise exercise) {
  // An example without a preset (the Assign Lesson, Build 256 Revision 7)
  // is authored in the Generic Primitive Editor: its draft rebuilds it.
  if (exercise.editorTemplate.isEmpty) {
    final draft = CanonicalExerciseDraft.fromExercise(exercise);
    expect(draft.violations, isEmpty, reason: exercise.id);
    return draft.toExercise(
      publicationState: PublicationState.published,
      updatedAt: exercise.updatedAt,
    );
  }
  final hasGaps = exercise.hasArrangeGaps || exercise.hasSelectGaps;
  String valueOf(String id) =>
      exercise.interaction.items.singleWhere((item) => item.id == id).value;
  final gapLayout = exercise.interaction.layout
      .map((part) {
        if (part.type != 'gap') return part.text;
        // A gap is _word_ since Build 259 Revision 4.
        return '_${valueOf(exercise.targetAssignments[part.text]!)}_';
      })
      .join(' ');
  final used = exercise.targetAssignments.values.toSet();
  final correctNumbers = exercise.evaluation.correctItemIds
      .map(
        (id) =>
            exercise.interaction.items.indexWhere((item) => item.id == id) + 1,
      )
      .join(',');
  final script = exercise.type == 'script_recognition'
      ? ScriptRecognitionController(exercise)
      : null;
  // Build 256 Revision 4: the shape hints (first-letter switch, text and
  // audio roles, Match sides) come from the production decompose, as in the
  // editor; the field values stay this test's own reconstruction.
  final hints = PresetRecipes.decompose(exercise, exercise.editorTemplate);
  // A Dialogue line or a Story cover has no v11 view: its fields are the
  // recipe's own (Build 256 Revision 5).
  final canonicalOnly = PresetRecipes.canonicalOnly.contains(
    exercise.editorTemplate,
  );
  try {
    final result = ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: exercise,
        type: exercise.editorTemplate,
        publicationState: PublicationState.published,
        requireValidAnswer: true,
        useInlineGaps: hasGaps,
        useMultiSelect: exercise.isMultiSelect,
        revealFirstLetter: hints.revealFirstLetter,
        textRole: hints.textRole,
        audioRole: hints.audioRole,
        matchSides: hints.matchSides,
        speakerId: hints.speakerId,
        lineMode: hints.lineMode,
        lineReadAloud: hints.lineReadAloud,
        lineTextReveal: hints.lineTextReveal,
        lineLanguage: hints.lineLanguage,
        // The Assign presets' fields and a Flashcard's read-aloud (Build
        // 256 Revision 7 follow-up) come from the production decompose.
        groups: hints.groups,
        dialogueReadAloud: hints.dialogueReadAloud,
        slots: hints.slots,
        extraWords: hints.extraWords,
        slotReuse: hints.slotReuse,
        // A Page's blocks (Build 258 Revision 3) come from decompose too.
        pageBlocks: hints.pageBlocks,
        cardReadAloud: hints.cardReadAloud,
        prompt: canonicalOnly
            ? hints.prompt
            : exercise.type == 'type_missing_word' && exercise.prompt.isEmpty
            ? exercise.question
            : exercise.prompt,
        // Complete the text keeps its instruction in the question value
        // (Build 259 Revision 1).
        question: exercise.editorTemplate == 'complete_text'
            ? hints.question
            : exercise.question,
        tts: exercise.tts ?? '',
        hint: exercise.hint,
        answers: exercise.answers.join('\n'),
        correct: correctNumbers,
        accepted: exercise.accepted.join('\n'),
        tokens: hasGaps
            ? exercise.interaction.items
                  .where((item) => !used.contains(item.id))
                  .map((item) => item.value)
                  .join('\n')
            : exercise.tokens.join('\n'),
        order: exercise.orderAnswer.join('\n'),
        gapLayout: gapLayout,
        pairs: exercise.pairs
            .map((pair) => '${pair[0]} = ${pair[1]}')
            .join('\n'),
        icons: exercise.icons.join('\n'),
        missingWords:
            (exercise.type == 'missing_word'
                    ? exercise.missingWords
                    : exercise.accepted)
                .join('\n'),
        context: exercise.contextText,
        dialogue: exercise.dialogueTurns
            .map((turn) => '${turn.speaker}: ${turn.text}')
            .join('\n'),
        requiredSelections: '${exercise.requiredSelectionCount}',
        correctTranslations: exercise.correctTranslationTexts,
        contextMode: exercise.contextMode,
        imageAsset: canonicalOnly ? hints.imageAsset : exercise.imageAsset,
        scriptCandidate: script?.build(PublicationState.published),
      ),
    );
    expect(
      result.error,
      isNull,
      reason: '${exercise.id}: ${result.error?.code}',
    );
    return result.candidate!;
  } finally {
    script?.dispose();
  }
}

Map<String, Object?> _semantics(Exercise exercise) {
  String valueOf(String id) =>
      exercise.interaction.items.singleWhere((item) => item.id == id).value;
  return {
    'preset': exercise.editorTemplate,
    'primitive': exercise.interaction.kind,
    'prompt': exercise.prompt,
    'question': exercise.question,
    'tts': exercise.tts,
    'hint': exercise.hint,
    'images': exercise.promptElements
        .where((part) => part.type == 'image')
        .map((part) => part.asset)
        .toList(),
    'items': exercise.interaction.items.map((item) => item.value).toList(),
    'icons': exercise.type == 'icon_choice' ? exercise.icons : null,
    'correct': exercise.evaluation.correctItemIds.map(valueOf).toList(),
    'accepted': exercise.accepted,
    'orders': exercise.correctTranslationTexts,
    'pairs': exercise.pairs,
    'missing': exercise.missingWords,
    'minimum': exercise.interaction.minSelections,
    'maximum': exercise.interaction.maxSelections,
    'layout': exercise.interaction.layout
        .map((part) => '${part.type}:${part.text}')
        .toList(),
    'gaps': exercise.targetAssignments.map(
      (gap, id) => MapEntry(gap, valueOf(id)),
    ),
    'dialogue': exercise.dialogueTurns
        .map((turn) => '${turn.speaker}: ${turn.text}')
        .toList(),
    'contextMode': exercise.contextMode,
    // A Story's lines and covers (Build 256 Revision 5).
    'speaker': ExerciseFeatures(exercise).speakerId,
    'lineText': ExerciseFeatures(exercise).lineText,
    'lineMode': ExerciseFeatures(exercise).lineMode,
    'lineReadAloud': ExerciseFeatures(exercise).lineReadAloud,
    'lineLanguage': ExerciseFeatures(exercise).lineLanguage,
    'textReveal': ExerciseFeatures(exercise).textReveal.name,
    'coverTitle': ExerciseFeatures(exercise).coverTitle,
    // Assign (Build 256 Revision 7).
    'targets': exercise.targets.map((target) => target.id).toList(),
    'assignments': ExerciseFeatures(exercise).assignmentsByTarget.map(
      (target, ids) => MapEntry(
        target,
        ids
            .map(
              (id) => exercise.items.singleWhere((item) => item.id == id).value,
            )
            .toList()
          ..sort(),
      ),
    ),
    'layoutElements': exercise.layout
        .map(
          (part) =>
              part.isText ? 'text:${part.text}' : 'target:${part.targetId}',
        )
        .toList(),
  };
}

/// What the learner sees for one Laboratory example: the heading, the
/// instruction, the displayed prompt, which panels, audio controls and
/// answer controls are present, what was spoken by itself and, after the
/// correct answer, the feedback. Counts and sorted texts only, so the
/// shuffled option order does not matter. Build 256 Session 3 refactors the
/// Round screen onto canonical data and must keep every record equal, except
/// where `laboratoryPresentation` says the change is deliberate.
Map<String, Object?> _presentation(
  WidgetTester tester,
  Exercise exercise,
  _Speech speech,
) {
  int count(Finder finder) => finder.evaluate().length;
  String? textOf(Key key) {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) return null;
    final widget = tester.widget(finder);
    return widget is Text ? widget.data : null;
  }

  List<String> textsContaining(String pattern) =>
      find
          .byWidgetPredicate(
            (widget) => widget is Text && (widget.data ?? '').contains(pattern),
          )
          .evaluate()
          .map((element) => (element.widget as Text).data!)
          .toList()
        ..sort();
  int keyed(String prefix) => count(
    find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith(prefix),
    ),
  );
  int shown(String text) => text.trim().isEmpty ? 0 : count(find.text(text));
  List<String> buttonTexts<T extends ButtonStyleButton>() =>
      find.byType(T).evaluate().map((element) {
        final child = (element.widget as ButtonStyleButton).child;
        return child is Text ? (child.data ?? '') : '<${child.runtimeType}>';
      }).toList()..sort();

  return {
    'heading': textOf(const Key('exercise-heading')),
    'instruction':
        textOf(const Key('exercise-instruction')) ??
        textOf(const Key('translation-choice-instruction')),
    'prompt': textOf(const Key('exercise-prompt-text')),
    'shown': {
      'question': shown(exercise.question),
      'prompt': shown(exercise.prompt),
      'context': shown(exercise.contextText),
      'translationText': count(
        find.byKey(const Key('translation-choice-text')),
      ),
    },
    'panels': {
      'context': count(find.byKey(const Key('contextual-comprehension-text'))),
      'dialogue': count(
        find.byKey(const Key('contextual-comprehension-dialogue')),
      ),
      'passage': count(find.byKey(const Key('exercise-passage'))),
      'image': count(find.byKey(const Key('exercise-image'))),
      'portableImages': count(find.byType(PortableExerciseImage)),
      'mediaImages': count(find.byType(CourseMediaImage)),
    },
    'audio': {
      'again': count(find.byTooltip('Play audio again')),
      'play': count(find.byTooltip('Play audio')),
      'context': count(find.byTooltip('Play context audio')),
      'sound': count(find.byTooltip('Play sound')),
      'pronounce': count(find.byTooltip('Pronounce word or phrase')),
      'usage': count(find.byTooltip('Pronounce usage sentence')),
      'playLabel': count(find.widgetWithText(FilledButton, 'Play audio')),
      'contextLabel': count(
        find.widgetWithText(FilledButton, 'Play context audio'),
      ),
      'translation': count(find.byKey(const Key('translation-choice-audio'))),
      'note': count(find.byKey(const Key('translation-choice-audio-note'))),
    },
    'controls': {
      'filled': buttonTexts<FilledButton>(),
      'outlined': buttonTexts<OutlinedButton>(),
      'checkboxes': count(find.byType(CheckboxListTile)),
      'textFields': count(find.byType(TextField)),
      'actionChips': count(find.byType(ActionChip)),
      'inputChips': count(find.byType(InputChip)),
      'filterChips': count(find.byType(FilterChip)),
      'choiceChips': count(find.byType(ChoiceChip)),
      'dropdowns': count(find.byType(DropdownButtonFormField<String>)),
      'gapSlots': keyed('gap-slot-'),
      'selectGapSlots': keyed('select-gap-slot-'),
      'imageButtons': count(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(PortableExerciseImage),
        ),
      ),
      'iconButtons': count(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Icon),
        ),
      ),
    },
    'texts': {
      'firstLetter': textOf(const Key('first-letter-sentence')),
      'gapHint': textOf(const Key('gap-choice-hint')),
      'hints': textsContaining('Hint:'),
      'translateFrom': textsContaining('Translate from'),
      'usage': count(find.text('Usage:')),
      'blanks': textsContaining('_____'),
    },
    'feedback': {
      'correct': count(find.text('Correct')),
      'correctAnswer': textsContaining('Correct answer'),
      'alternativesHeading': textOf(const Key('translation-feedback-heading')),
      'alternatives': keyed('translation-feedback-answer-'),
      'correctTranslations': count(find.text('Correct translations:')),
      'bullets': textsContaining('• ').length,
      'acceptedDifferences': textsContaining('Accepted difference'),
      'listenToAnswer': count(find.text('Listen to the answer')),
      'cardReviewed': count(find.text('Card reviewed.')),
      'surface': count(find.byKey(const Key('exercise-feedback-surface'))),
    },
    // Sorted: Listen and match plays its sounds in the shuffled card order.
    'spoken': List<String>.of(speech.spoken)..sort(),
  };
}

/// Compares the record with the expectation, or writes it as JSON when the
/// `QQL_RECORD_PRESENTATION` environment variable names a directory (used
/// once to produce `test/support/laboratory_presentation_254.dart`).
void _checkPresentation(String id, Map<String, Object?> record) {
  final directory = Platform.environment['QQL_RECORD_PRESENTATION'];
  if (directory != null && directory.isNotEmpty) {
    File('$directory/$id.json').writeAsStringSync(jsonEncode(record));
    return;
  }
  expect(laboratoryPresentation.containsKey(id), isTrue, reason: id);
  expect(record, laboratoryPresentation[id], reason: id);
}

class _Speech extends TtsCacheService {
  final spoken = <String>[];

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async {
    // The Story's narrator speaks the source language (Build 256 Revision 5).
    expect(language, anyOf('it-IT', 'en-GB'));
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  // Round initialization and completion await diagnostic log file I/O.
  // Pumping only the fake widget clock cannot complete that work, so real
  // time is allowed too: up to 10 seconds, like the shared
  // `pumpUntilFileIoState`, because a busy machine can need more than one.
  // The fake clock still advances at most 100 × 25 ms, as before.
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  for (var attempt = 0; ; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(
      attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
    );
    if (finder.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) break;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<_Speech> _show(
  WidgetTester tester,
  Course course,
  Exercise exercise,
) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final round = LearningRound(
    id: 'preview_${exercise.id}',
    title: 'Laboratory case',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: 'preview_lesson',
    title: 'Laboratory',
    rounds: [round],
  );
  final speech = _Speech();
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        key: ValueKey(exercise.id),
        course: course,
        lesson: lesson,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: true,
        ttsCacheService: speech,
      ),
    ),
  );
  await _until(
    tester,
    find.byKey(Key('exercise-renderer-${exercise.primitive.serialized}')),
  );
  return speech;
}

Future<void> _answer(
  WidgetTester tester,
  Exercise exercise,
  _Speech speech, {
  int orderIndex = 0,
}) async {
  final kind = ExerciseFeatures(exercise).kind;
  if (kind == LearnerExerciseKind.dialogueLine ||
      kind == LearnerExerciseKind.storyCover) {
    // A line or a cover is read (or heard) and continued (Build 256
    // Revision 5); it is never skipped and never scored.
    await _tap(
      tester,
      find.byKey(
        Key(
          kind == LearnerExerciseKind.dialogueLine
              ? 'story-line-continue'
              : 'story-cover-continue',
        ),
      ),
    );
    return;
  }
  if (kind == LearnerExerciseKind.page) {
    // A Page is read and continued (Build 258); never scored.
    await _tap(tester, find.byKey(const Key('page-continue')));
    return;
  }
  if (exercise.primitive == ExercisePrimitive.assign) {
    // Tap an item, then its destination (Build 256 Revision 7); gaps are
    // slots inside the text, groups and slots are bins.
    final features = ExerciseFeatures(exercise);
    final gaps = features.assignTargetMode == AssignTargetMode.gaps;
    for (final entry in features.assignmentsByTarget.entries) {
      for (final itemId in entry.value) {
        await _tap(tester, find.byKey(Key('assign-tile-$itemId')));
        await _tap(
          tester,
          find.byKey(
            Key('${gaps ? 'assign-slot' : 'assign-target'}-${entry.key}'),
          ),
        );
      }
    }
    await _tap(tester, find.byKey(const Key('assign-check')));
    expect(find.text('Correct'), findsOneWidget, reason: exercise.id);
    return;
  }
  if (exercise.type == 'flashcard') {
    // A vocabulary card is reviewed with Got it; a Note card continues.
    final reviewable =
        ExerciseFeatures(exercise).completionMode ==
        CompletionMode.understoodReview;
    await _tap(
      tester,
      find.widgetWithText(FilledButton, reviewable ? 'Got it' : 'Continue'),
    );
    expect(find.text('Card reviewed.'), findsOneWidget);
    return;
  }
  if (exercise.hasSelectGaps || exercise.hasArrangeGaps) {
    for (final gap in exercise.interaction.layout.where(
      (part) => part.type == 'gap',
    )) {
      final id = exercise.targetAssignments[gap.text]!;
      await _tap(
        tester,
        find.byKey(
          Key(
            '${exercise.hasSelectGaps ? 'select-gap-option' : 'arrange-tile'}-$id',
          ),
        ),
      );
    }
    await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
  } else if (exercise.isMultiSelect) {
    for (final id in exercise.evaluation.correctItemIds) {
      final answer = exercise.interaction.items
          .singleWhere((item) => item.id == id)
          .text;
      await _tap(tester, find.widgetWithText(CheckboxListTile, answer));
    }
    await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
  } else if (exercise.interaction.kind == 'select') {
    final correct = exercise.interaction.items.singleWhere(
      (item) => item.id == exercise.evaluation.correctItemIds.single,
    );
    Finder button;
    if (exercise.type == 'icon_choice' &&
        exercise.icons[exercise.correct!].startsWith('assets/')) {
      final asset = exercise.icons[exercise.correct!];
      button = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == asset,
        ),
        matching: find.byType(FilledButton),
      );
    } else if (correct.image.isNotEmpty) {
      button = find.ancestor(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is PortableExerciseImage && widget.asset == correct.image,
        ),
        matching: find.byType(FilledButton),
      );
    } else {
      button = find.widgetWithText(FilledButton, correct.text);
    }
    await _tap(tester, button);
  } else if (exercise.interaction.kind == 'input') {
    if (exercise.type == 'missing_word') {
      for (var index = 0; index < exercise.missingWords.length; index++) {
        // A gap may accept an answer expression, such as [il|un] treno
        // (Build 259 Revision 3): type its first answer.
        await tester.enterText(
          find.byType(TextField).at(index),
          AnswerExpressionParser.expandAll([
            exercise.missingWords[index],
          ]).first,
        );
      }
    } else {
      // Type what you hear accepts its Audio text without another line
      // (Build 259 Revision 3).
      final answer = exercise.accepted.isEmpty
          ? ExerciseFeatures(exercise).literalAnswers.first
          : AnswerExpressionParser.expandAll(exercise.accepted).first;
      await tester.enterText(find.byType(TextField), answer);
    }
    await tester.pump(); // Rebuild the Check button after TextField.onChanged.
    await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
  } else if (exercise.interaction.kind == 'arrange') {
    for (final value in exercise.orderAnswers[orderIndex]) {
      await _tap(tester, find.widgetWithText(ActionChip, value).first);
    }
    await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
  } else if (exercise.type == 'audio_match') {
    final controls = find.byTooltip('Play sound');
    expect(controls, findsNWidgets(3));
    for (var index = 0; index < 3; index++) {
      await _tap(tester, controls.at(index));
      final heard = speech.spoken.last;
      final right = exercise.pairs.singleWhere((pair) => pair[0] == heard)[1];
      final card = find.ancestor(
        of: controls.at(index),
        matching: find.byType(Card),
      );
      await _tap(
        tester,
        find.descendant(
          of: card,
          matching: find.widgetWithText(ChoiceChip, right),
        ),
      );
    }
    await _tap(tester, find.widgetWithText(FilledButton, 'Check matches'));
  } else if (exercise.interaction.kind == 'match') {
    for (final pair in exercise.pairs) {
      // A picture shows no text beside it (Build 259 Revision 4): its row
      // is found by the picture.
      final left = pair[0].startsWith('assets/')
          ? find.byWidgetPredicate(
              (widget) =>
                  widget is PortableExerciseImage && widget.asset == pair[0],
            )
          : find.text(pair[0]);
      final row = find
          .ancestor(of: left, matching: find.byType(LayoutBuilder))
          .first;
      await _tap(
        tester,
        find.descendant(
          of: row,
          matching: find.byType(DropdownButtonFormField<String>),
        ),
      );
      await _tap(tester, find.text(pair[1]).last);
    }
    await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
  } else {
    fail('No learner driver for ${exercise.id}');
  }
  expect(find.text('Correct'), findsOneWidget, reason: exercise.id);
  expect(find.text('Incorrect'), findsNothing, reason: exercise.id);
}

void _platforms() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => testSupportDirectory.path,
  );
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final course = Course.fromJson(_json());
  final examples = _exercises(course);

  setUp(() async {
    _platforms();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Laboratory verifier');
  });

  test(
    'Lab has the five named Lessons and every current preset in its primitive',
    () {
      expect(course.courseId, 'course_50d68435-d2c2-4b63-9a0b-b23161357f1d');
      expect(course.lessons.map((lesson) => lesson.title), [
        'Select',
        'Input',
        'Arrange',
        'Match',
        'Presentation',
        'Story',
        'Assign',
        // Build 258 Revision 3: Pages.
        'Page',
      ]);
      expect(course.createDuels, isFalse);
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      // 125 with Listen and answer (to source) (Build 259 Revision 2), 126
      // with the Complete the text alternatives (Revision 3), 124 with One
      // word fills all replacing the four reusable-option gaps (Revision 4).
      expect(examples, hasLength(124));
      // The examples cover every preset but Before you start, whose card
      // opens every Round (Build 257).
      expect({
        ...examples.map((e) => e.editorTemplate).where((id) => id.isNotEmpty),
        'before_you_start',
      }, ExercisePresetRegistry.presets.map((p) => p.id).toSet());
      for (final lesson in course.lessons) {
        expect(lesson.publicationState, PublicationState.published);
        for (final round in lesson.rounds) {
          expect(round.publicationState, PublicationState.published);
          expect(round.exercises, isNotEmpty);
          expect(
            ExerciseFeatures(round.exercises.first).kind,
            LearnerExerciseKind.roundIntro,
            reason: round.id,
          );
          for (final exercise in round.exercises) {
            expect(exercise.publicationState, PublicationState.published);
            if (ExerciseFeatures(exercise).kind ==
                LearnerExerciseKind.roundIntro) {
              continue;
            }
            // The Story Lesson mixes a cover, lines and exercises of several
            // primitives (Build 256 Revision 5).
            if (lesson.title == 'Story') continue;
            // Pages are presentations (Build 258 Revision 3).
            if (lesson.title == 'Page') continue;
            expect(
              ExercisePresetRegistry.byId(
                exercise.editorTemplate,
              )!.primitive.name,
              lesson.title.toLowerCase(),
            );
          }
        }
      }
    },
  );

  test(
    'Lab canonical model round trip preserves every field and has no Audit errors',
    () {
      expect(course.toJson(), _json());
      final restored = Course.fromJson(
        jsonDecode(jsonEncode(course.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), course.toJson());
      final issues = CourseAuditService().auditCourse(restored).issues;
      expect(
        issues.where((issue) => issue.severity == AuditSeverity.error),
        isEmpty,
        reason: issues
            .map(
              (issue) =>
                  '${issue.code}: ${issue.message} (${issue.exerciseId})',
            )
            .join('\n'),
      );
    },
  );

  test(
    'Flashcard usage and usage translation survive the actual runnable and authoring projections',
    () {
      for (final lesson in course.lessons) {
        for (final round in lesson.rounds) {
          for (final content in round.content.where(
            (content) => content.kind == 'presentation',
          )) {
            final authored = _author(content.asRunnableExercise()!);
            final projected = LearningContent.fromExercise(
              authored,
            ).presentation!;
            Map<String, String> textByRole(Presentation presentation) => {
              for (final part in presentation.content) part.role: part.text,
            };
            expect(
              textByRole(projected),
              textByRole(content.presentation!),
              reason: content.id,
            );
          }
        }
      }
    },
  );

  for (final exercise in examples) {
    test('authoring preserves ${exercise.id}', () {
      final candidate = _author(exercise);
      expect(candidate.id, exercise.id);
      expect(_semantics(candidate), _semantics(exercise));
      final errors = CourseAuditService()
          .auditExercise(candidate)
          .where((issue) => issue.severity == AuditSeverity.error);
      expect(
        errors,
        isEmpty,
        reason: errors
            .map((issue) => '${issue.code}: ${issue.message}')
            .join('\n'),
      );
      final content = LearningContent.fromExercise(candidate);
      final restored = LearningContent.fromJson(
        jsonDecode(jsonEncode(content.toJson())) as Map<String, dynamic>,
      );
      expect(_semantics(restored.asRunnableExercise()!), _semantics(candidate));
      // Type what you hear may accept only its Audio text, a literal answer
      // (Build 259 Revision 3).
      if (candidate.interaction.kind == 'input' &&
          candidate.type != 'missing_word' &&
          candidate.accepted.isNotEmpty) {
        for (final answer in AnswerExpressionParser.expandAll(
          candidate.accepted,
        )) {
          expect(
            const AnswerEngine()
                .evaluate(
                  answer,
                  candidate.accepted,
                  normalization: candidate.evaluation.normalization,
                )
                .isCorrect,
            isTrue,
          );
        }
        // The first-letter hint exists only in the inline-gap shape; with the
        // switch off the exercise is one field under its sentence.
        if (candidate.type == 'type_missing_word' &&
            candidate.layout.isNotEmpty) {
          expect(
            FirstLetterAnswerService.display(
              candidate.prompt,
              candidate.accepted,
            ),
            isNotEmpty,
          );
        }
      }
    });

    testWidgets('learner completes ${exercise.id}', (tester) async {
      final speech = await _show(tester, course, exercise);
      final before = _presentation(tester, exercise, speech);
      await _answer(tester, exercise, speech);
      final after = _presentation(tester, exercise, speech);
      _checkPresentation(exercise.id, {'before': before, 'after': after});
      // A line's or a cover's Continue moves straight on (Build 256
      // Revision 5), so a one-item Round is already complete.
      if (find.text('Preview complete').evaluate().isEmpty) {
        await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
      }
      await _until(tester, find.text('Preview complete'));
      expect(find.textContaining('Temporary result: perfect.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'a second authored Build translation order completes through the learner',
    (tester) async {
      final exercise = examples.singleWhere(
        (exercise) => exercise.id == 'qql_lab254_build_multiple',
      );
      final speech = await _show(tester, course, exercise);
      await _answer(tester, exercise, speech, orderIndex: 1);
      await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
      await _until(tester, find.text('Preview complete'));
      expect(find.textContaining('Temporary result: perfect.'), findsOneWidget);
    },
  );

  testWidgets('Review again requeues a Presentation card before completion', (
    tester,
  ) async {
    final exercise = examples.singleWhere(
      (exercise) => exercise.id == 'qql_lab254_card_complete',
    );
    await _show(tester, course, exercise);
    // A two-sided card offers Review again after turning (Build 268).
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Turn over'));
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Review again'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Got it'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
    await _until(tester, find.text('Preview complete'));
    expect(find.textContaining('Temporary result: perfect.'), findsOneWidget);
  });
}
