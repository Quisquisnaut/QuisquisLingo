import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/first_letter_answer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/widgets/portable_exercise_image.dart';
import 'package:quisquislingo_app/widgets/script_recognition_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

const _asset = 'assets/courses/exercise_laboratory_en_it.json';

Map<String, dynamic> _json() =>
    jsonDecode(File(_asset).readAsStringSync()) as Map<String, dynamic>;

List<Exercise> _exercises(Course course) => [
  for (final lesson in course.lessons)
    for (final round in lesson.rounds) ...round.exercises,
];

/// Reconstruct the values exposed by the real authoring form. The production
/// builder, audit and runtime then consume the candidate; no grader is mocked.
Exercise _author(Exercise exercise) {
  final hasGaps = exercise.hasArrangeGaps || exercise.hasSelectGaps;
  String valueOf(String id) =>
      exercise.interaction.items.singleWhere((item) => item.id == id).value;
  final gapLayout = exercise.arrangeLayout
      .map((part) {
        if (part.type != 'gap') return part.text;
        return '{${valueOf(exercise.arrangeGapAssignments[part.text]!)}}';
      })
      .join(' ');
  final used = exercise.arrangeGapAssignments.values.toSet();
  final correctNumbers = exercise.evaluation.correctItemIds
      .map(
        (id) =>
            exercise.interaction.items.indexWhere((item) => item.id == id) + 1,
      )
      .join(',');
  final script = exercise.type == 'script_recognition'
      ? ScriptRecognitionController(exercise)
      : null;
  try {
    final result = ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: exercise,
        type: exercise.type,
        publicationState: PublicationState.published,
        requireValidAnswer: true,
        useInlineGaps: hasGaps,
        useMultiSelect: exercise.isMultiSelect,
        prompt: exercise.prompt,
        question: exercise.question,
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
        imageAsset: exercise.imageAsset,
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
    'layout': exercise.arrangeLayout
        .map((part) => '${part.type}:${part.text}')
        .toList(),
    'gaps': exercise.arrangeGapAssignments.map(
      (gap, id) => MapEntry(gap, valueOf(id)),
    ),
    'dialogue': exercise.dialogueTurns
        .map((turn) => '${turn.speaker}: ${turn.text}')
        .toList(),
    'contextMode': exercise.contextMode,
  };
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
  }) async {
    expect(language, 'it-IT');
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    // Round initialization and completion await diagnostic log file I/O.
    // Pumping only the fake widget clock cannot complete that work.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 25));
    if (finder.evaluate().isNotEmpty) return;
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
  await _until(tester, find.byKey(Key('exercise-renderer-${exercise.type}')));
  return speech;
}

Future<void> _answer(
  WidgetTester tester,
  Exercise exercise,
  _Speech speech, {
  int orderIndex = 0,
}) async {
  if (exercise.type == 'flashcard') {
    await _tap(tester, find.widgetWithText(FilledButton, 'Got it'));
    expect(find.text('Card reviewed.'), findsOneWidget);
    return;
  }
  if (exercise.hasSelectGaps || exercise.hasArrangeGaps) {
    for (final gap in exercise.arrangeLayout.where(
      (part) => part.type == 'gap',
    )) {
      final id = exercise.arrangeGapAssignments[gap.text]!;
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
        await tester.enterText(
          find.byType(TextField).at(index),
          exercise.missingWords[index],
        );
      }
    } else {
      final answer = AnswerExpressionParser.expandAll(exercise.accepted).first;
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
      final row = find
          .ancestor(
            of: find.text(pair[0]),
            matching: find.byType(LayoutBuilder),
          )
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
      ]);
      expect(course.createDuels, isFalse);
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      expect(examples, hasLength(80));
      expect(
        examples.map((e) => e.editorTemplate).toSet(),
        ExercisePresetRegistry.presets.map((p) => p.id).toSet(),
      );
      for (final lesson in course.lessons) {
        expect(lesson.publicationState, PublicationState.published);
        for (final round in lesson.rounds) {
          expect(round.publicationState, PublicationState.published);
          expect(round.exercises, isNotEmpty);
          for (final exercise in round.exercises) {
            expect(exercise.publicationState, PublicationState.published);
            expect(
              ExercisePresetRegistry.byId(exercise.editorTemplate)!.model.name,
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
      if (candidate.interaction.kind == 'input' &&
          candidate.type != 'missing_word') {
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
        if (candidate.type == 'type_missing_word') {
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
      await _answer(tester, exercise, speech);
      await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
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
    await _tap(tester, find.widgetWithText(OutlinedButton, 'Review again'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Next'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Got it'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
    await _until(tester, find.text('Preview complete'));
    expect(find.textContaining('Temporary result: perfect.'), findsOneWidget);
  });
}
