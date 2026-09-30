import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Session 3: the learner runtime reads canonical data. The kind
/// every preset's exercises derive to, Duel eligibility by capability
/// (plan A.10), audio exercises by required audio, linear Stories (A.7) and
/// inline-gap Arrange graded by block content (A.11).
const _expectedKinds = <String, Set<LearnerExerciseKind>>{
  'choice_target': {
    LearnerExerciseKind.select,
    LearnerExerciseKind.selectListen,
  },
  'gap_choice': {LearnerExerciseKind.selectComplete},
  'icon_choice': {LearnerExerciseKind.selectImage},
  'script_recognition': {LearnerExerciseKind.selectCharacter},
  // Listen and choose (Build 259 Revision 2): what was heard, no question.
  'listening_choose_target': {LearnerExerciseKind.selectListen},
  'listening_choose_source': {LearnerExerciseKind.selectListen},
  'listening_answer_target': {
    LearnerExerciseKind.selectListen,
    LearnerExerciseKind.selectListenPassage,
  },
  // Read and answer: a source-language context and target-language dialogue
  // (Build 256 Revision 7 fourth follow-up).
  'reading_answer_target': {LearnerExerciseKind.selectContext},
  'translation_choice_to_target': {LearnerExerciseKind.selectTranslation},
  'translation_choice_to_source': {LearnerExerciseKind.selectTranslation},
  'type_translation_to_target': {LearnerExerciseKind.inputTranslation},
  'listening_spelling': {LearnerExerciseKind.inputListenWrite},
  'missing_word': {LearnerExerciseKind.inputListenGaps},
  'type_missing_word': {
    LearnerExerciseKind.inputMissingWord,
    LearnerExerciseKind.inputComplete,
  },
  'word_order': {LearnerExerciseKind.arrangeSentence},
  'build_translation_to_target': {LearnerExerciseKind.arrangeTranslation},
  'image_word': {LearnerExerciseKind.arrangeWord},
  'word_match': {LearnerExerciseKind.matchTranslation},
  'super_match': {LearnerExerciseKind.match},
  'audio_match': {LearnerExerciseKind.matchAudio},
  'flashcard': {LearnerExerciseKind.presentation},
  'choice_source': {
    LearnerExerciseKind.select,
    LearnerExerciseKind.selectListen,
  },
  'listening_answer_source': {
    LearnerExerciseKind.selectListen,
    LearnerExerciseKind.selectListenPassage,
  },
  'type_translation_to_source': {LearnerExerciseKind.inputTranslation},
  'build_translation_to_source': {LearnerExerciseKind.arrangeTranslation},
  'picture_flashcard': {LearnerExerciseKind.presentation},
  'true_false': {LearnerExerciseKind.select, LearnerExerciseKind.selectListen},
  // Build 259 Revision 4: One word fills all; gap_choice_inline merged
  // into gap_blocks.
  'one_word_fills_all': {LearnerExerciseKind.selectCompleteAll},
  'complete_text': {LearnerExerciseKind.inputComplete},
  'missing_letters': {
    LearnerExerciseKind.inputComplete,
    LearnerExerciseKind.inputListenGaps,
  },
  'gap_blocks': {LearnerExerciseKind.arrangeSentence},
  'sentence_order': {
    LearnerExerciseKind.arrangeSentence,
    LearnerExerciseKind.arrangeLines,
  },
  'listening_image_choice': {LearnerExerciseKind.selectListen},
  'spell_heard': {LearnerExerciseKind.arrangeWord},
  // What is in the picture has its own title (Build 259 Revision 3).
  'picture_choice': {LearnerExerciseKind.selectPicture},
  'picture_name': {LearnerExerciseKind.inputPictureName},
  'picture_blocks': {LearnerExerciseKind.arrangePictureName},
  'spell_word': {LearnerExerciseKind.arrangeWord},
  'picture_word_match': {
    LearnerExerciseKind.matchTranslation,
    LearnerExerciseKind.match,
  },
  'note_card': {LearnerExerciseKind.presentation},
  // Build 256 Revision 5: a Story's lines and covers.
  'dialogue_line': {LearnerExerciseKind.dialogueLine},
  'story_cover': {LearnerExerciseKind.storyCover},
  // Build 257: the card that opens a Round.
  'before_you_start': {LearnerExerciseKind.roundIntro},
  'page': {LearnerExerciseKind.page},
  // Build 256 Revision 7 follow-up: the Assign presets.
  'sort_into_groups': {LearnerExerciseKind.assignGroups},
  'fill_the_slots': {LearnerExerciseKind.assignSlots},
};

const _bundled = [
  'exercise_laboratory_en_it.json',
  'edge_case_it_en.json',
  'piedmontais_en.json',
];

Course _load(String file) => Course.fromJson(
  jsonDecode(File('assets/courses/$file').readAsStringSync())
      as Map<String, dynamic>,
);

Iterable<LearningContent> _exerciseContent(Course course) sync* {
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final content in round.content) {
        if (content.exercise != null) yield content;
      }
    }
  }
}

Exercise _choice(String id, String question, {String? tts}) => Exercise(
  id: id,
  type: 'choice',
  prompt: '',
  question: question,
  answers: ['Right $id', 'Wrong $id'],
  correct: 0,
  tts: tts,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Course _course(List<Lesson> lessons) => Course(
  courseId: 'runtime-canonical-course',
  title: 'Runtime canonical course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: lessons,
);

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
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}
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

Future<void> _until(WidgetTester tester, Finder finder) async {
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
  LearningRound round,
) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final speech = _Speech();
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
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
    find.byWidgetPredicate(
      (widget) =>
          widget is KeyedSubtree &&
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith(
            'exercise-renderer-',
          ),
    ),
  );
  return speech;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _platforms();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Runtime verifier');
  });

  group('learner kinds derive from canonical data', () {
    for (final file in _bundled) {
      test('$file: every exercise derives the kind its preset implies', () {
        final course = _load(file);
        var checked = 0;
        for (final content in _exerciseContent(course)) {
          if (content.editorTemplate.isEmpty) {
            // The Assign Lesson has no preset (Build 256 Revision 7): its
            // kind comes from the target mode alone.
            expect(content.exercise!.primitive, ExercisePrimitive.assign);
            expect(
              ExerciseFeatures(content.exercise!).kind,
              isIn([
                LearnerExerciseKind.assignGroups,
                LearnerExerciseKind.assignSlots,
                LearnerExerciseKind.assignGaps,
              ]),
              reason: content.id,
            );
            checked++;
            continue;
          }
          final expected = _expectedKinds[content.editorTemplate];
          expect(expected, isNotNull, reason: content.editorTemplate);
          expect(
            expected,
            contains(ExerciseFeatures(content.exercise!).kind),
            reason: '${content.id} (${content.editorTemplate})',
          );
          checked++;
        }
        expect(checked, greaterThan(0));
      });
    }

    test('the heading and instruction do not need the preset', () {
      final course = _load(_bundled.first);
      for (final content in _exerciseContent(course)) {
        final exercise = content.exercise!;
        final stripped = exercise.withAuthoringMetadata(const {});
        expect(stripped.editorTemplate, isEmpty);
        expect(
          ExerciseFeatures(stripped).kind,
          ExerciseFeatures(exercise).kind,
          reason: content.id,
        );
        expect(
          ExerciseCopyService.instructionForExercise(course, stripped),
          ExerciseCopyService.instructionForExercise(course, exercise),
          reason: content.id,
        );
      }
    });
  });

  group('Duel pool by capability (plan A.10)', () {
    test('every single-answer Select with choices qualifies', () {
      final course = _load(_bundled.first);
      const selectPresets = {
        'choice_target',
        'gap_choice',
        'one_word_fills_all',
        'icon_choice',
        'script_recognition',
        'listening_choose_target',
        'listening_choose_source',
        'listening_answer_target',
        'reading_answer_target',
        'translation_choice_to_target',
        'translation_choice_to_source',
        'true_false',
        'listening_image_choice',
        'picture_choice',
        'choice_source',
        'listening_answer_source',
      };
      var contextual = 0;
      var characters = 0;
      var multiple = 0;
      for (final content in _exerciseContent(course)) {
        final exercise = content.exercise!;
        final features = ExerciseFeatures(exercise);
        final expected =
            selectPresets.contains(content.editorTemplate) &&
            !features.multipleSelection &&
            !features.hasInlineTargets;
        expect(
          DuelEligibilityService.isEligible(exercise),
          expected,
          reason: '${content.id} (${content.editorTemplate})',
        );
        if (expected && content.editorTemplate == 'reading_answer_target') {
          contextual++;
        }
        if (expected && content.editorTemplate == 'script_recognition') {
          characters++;
        }
        if (features.multipleSelection) {
          multiple++;
        }
      }
      expect(contextual, greaterThan(0));
      expect(characters, greaterThan(0));
      expect(multiple, greaterThan(0));
    });
  });

  group('audio exercises are those with required audio', () {
    final availability = AudioExerciseAvailabilityService();

    test('automatic and manual audio count, optional audio does not', () {
      expect(
        availability.isAudioExercise(
          _choice('listen', 'Choose what you hear', tts: 'Buongiorno'),
        ),
        isTrue,
      );
      expect(
        availability.isAudioExercise(_choice('silent', 'Choose')),
        isFalse,
      );
      final optional = Exercise.canonical(
        id: 'optional',
        primitive: ExercisePrimitive.select,
        promptElements: const [
          PromptElement(type: 'text', text: 'Choose.'),
          PromptElement(type: 'audio', text: 'Ciao', required: false),
        ],
        items: const [
          ExerciseItem(
            id: 'a',
            content: [PromptElement(type: 'text', text: 'a')],
          ),
          ExerciseItem(
            id: 'b',
            content: [PromptElement(type: 'text', text: 'b')],
          ),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactItem,
          correctItemIds: ['a'],
        ),
      );
      expect(availability.isAudioExercise(optional), isFalse);
    });

    test(
      'the bundled Pick the translation exercises are not audio exercises',
      () {
        final course = _load(_bundled.first);
        for (final content in _exerciseContent(course)) {
          if (!content.editorTemplate.startsWith('translation_choice')) {
            continue;
          }
          expect(
            availability.isAudioExercise(content.exercise!),
            isFalse,
            reason: content.id,
          );
        }
      },
    );
  });

  group('Stories (plan A.7)', () {
    final exercises = [
      for (var i = 1; i <= 5; i++) _choice('e$i', 'Question $i'),
    ];
    const authoredOrder = ['e4', 'e1', 'e5', 'e2', 'e3'];
    final linear = ContentFlow.linear([
      for (final id in authoredOrder)
        FlowNode(id: 'node_$id', kind: FlowNodeKind.exercise, contentId: id),
    ]);

    testWidgets(
      'a linear Story plays its nodes in authored order, unshuffled and without a mistake review',
      (tester) async {
        final round = LearningRound(
          id: 'story',
          title: 'Story',
          visualType: LearningRound.storyVisualType,
          exercises: exercises,
          flow: linear,
        );
        final course = _course([
          Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
        ]);
        await _show(tester, course, round);
        for (var i = 0; i < authoredOrder.length; i++) {
          final id = authoredOrder[i];
          expect(
            find.text('Question ${id.substring(1)}'),
            findsOneWidget,
            reason: 'node $i',
          );
          // The first answer is wrong: a Story has no mistake review.
          await _tap(
            tester,
            find.widgetWithText(
              FilledButton,
              i == 0 ? 'Wrong $id' : 'Right $id',
            ),
          );
          await _tap(
            tester,
            find.widgetWithText(
              FilledButton,
              i == authoredOrder.length - 1 ? 'Finish story' : 'Continue',
            ),
          );
        }
        await _until(tester, find.text('Preview complete'));
        expect(find.text('Review your mistakes'), findsNothing);
        expect(find.textContaining('1 error'), findsOneWidget);
      },
    );

    test('a branching Story is not playable in this version', () {
      final branching = ContentFlow(
        startNodeId: 'node_e1',
        nodes: [
          const FlowNode(
            id: 'node_e1',
            kind: FlowNodeKind.exercise,
            contentId: 'e1',
            transitions: [
              FlowTransition(
                trigger: FlowTrigger.onCorrect,
                targetNodeId: 'node_e2',
              ),
              FlowTransition(
                trigger: FlowTrigger.onIncorrect,
                targetNodeId: 'node_e3',
              ),
            ],
          ),
          const FlowNode(
            id: 'node_e2',
            kind: FlowNodeKind.exercise,
            contentId: 'e2',
          ),
          const FlowNode(
            id: 'node_e3',
            kind: FlowNodeKind.exercise,
            contentId: 'e3',
          ),
        ],
      );
      expect(branching.isValid, isTrue);
      expect(branching.isLinear, isFalse);
      final round = LearningRound(
        id: 'branching',
        title: 'Branching',
        exercises: exercises,
        flow: branching,
      );
      expect(RoundPlayabilityService().playableExerciseIndices(round), isEmpty);
      final practice = LearningRound(
        id: 'practice',
        title: 'Practice',
        exercises: exercises,
      );
      expect(
        RoundPlayabilityService().playableExerciseIndices(practice),
        hasLength(5),
      );
    });
  });

  group('inline-gap Arrange grades block content (plan A.11)', () {
    testWidgets('two identical blocks fill either of their gaps', (
      tester,
    ) async {
      final laboratory = _load(_bundled.first);
      final content = _exerciseContent(
        laboratory,
      ).singleWhere((content) => content.id == 'qql_lab254_arrange_gap_repeat');
      final exercise = content.exercise!;
      final round = LearningRound(
        id: 'repeat',
        title: 'Repeat',
        exercises: [exercise],
      );
      final course = _course([
        Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
      ]);
      await _show(tester, course, round);
      // The assignments name item_0 for gap_1 and item_1 for gap_2; both
      // read "è". Placing them the other way round is right by content.
      final assignments = ExerciseFeatures(exercise).targetAssignments;
      final swapped = assignments.values.toList().reversed.toList();
      for (final itemId in swapped) {
        await _tap(tester, find.byKey(Key('arrange-tile-$itemId')));
      }
      await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
      expect(find.text('Correct'), findsOneWidget);
      expect(find.text('Incorrect'), findsNothing);
    });
  });
}
