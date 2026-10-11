import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/course_hierarchy_update_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/preset_variants.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 271 Revision 0 (owner decisions of 10 and 11 October 2026): content
/// that played wrong. Missing letters' optional spoken text is optional
/// audio, so the exercise stays in the Round when the learner's audio is
/// off; Put the sentences in order marks its blocks as lines, so two short
/// lines no longer play as words; a Round is copied whole where the Audit
/// flow used to rebuild it field by field.

final _stamp = DateTime.utc(2026, 10, 11);

/// A voice that records what it is asked to say.
class _Voice extends TtsCacheService {
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

Course _lab() => Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Exercise _labExercise(String id) => _lab().lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.content)
    .singleWhere((content) => content.id == id)
    .exercise!;

Course _course(List<Lesson> lessons) => Course(
  courseId: 'r0-271-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Revision 0 271',
  ttsLanguage: 'it-IT',
  lessons: lessons,
);

Exercise _blankFor(String presetId) =>
    PresetRecipes.canonicalOnly.contains(presetId)
    ? Exercise.canonical(
        id: 'blank-$presetId',
        publicationState: PublicationState.draft,
        primitive: ExercisePrimitive.presentation,
        canonicalEvaluation: CanonicalEvaluation.none,
        updatedAt: _stamp,
      )
    : Exercise(
        id: 'blank-$presetId',
        publicationState: PublicationState.draft,
        updatedAt: _stamp,
        type: ExercisePresetRegistry.byId(presetId)!.base,
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

Exercise _built(
  String presetId, {
  String prompt = '',
  String tts = '',
  String order = '',
  String extraWords = '',
  String tokens = '',
}) {
  final result = ExerciseDraftBuilder.build(
    ExerciseDraftValues(
      original: _blankFor(presetId),
      type: presetId,
      publicationState: PublicationState.published,
      prompt: prompt,
      tts: tts,
      order: order,
      extraWords: extraWords,
      tokens: tokens,
    ),
  );
  expect(result.error, isNull, reason: '${result.error?.code}');
  return result.candidate!;
}

Exercise _missingLetters({String tts = 'Il treno parte alle nove.'}) => _built(
  'missing_letters',
  prompt: 'Il t_ren_o parte alle n_ov_e.',
  tts: tts,
);

/// Missing letters as Build 270 and earlier stored it: its spoken text
/// required.
Exercise _earlierMissingLetters() {
  final now = _missingLetters();
  return now.copyWith(
    promptElements: [
      for (final element in now.promptElements)
        if (element.isAudio)
          PromptElement(
            role: element.role,
            type: element.type,
            text: element.text,
            playback: element.playback,
          )
        else
          element,
    ],
  );
}

Exercise _lines(List<String> lines) =>
    _built('sentence_order', order: lines.join('\n'));

/// Put the sentences in order as Build 270 and earlier stored it: its blocks
/// without the `line` mark.
Exercise _earlierLines(List<String> lines) {
  final now = _lines(lines);
  return now.copyWith(
    items: [
      for (final item in now.items)
        item.copyWith(
          content: [
            for (final element in item.content)
              element.copyWith(role: 'primary'),
          ],
        ),
    ],
  );
}

void _installPluginMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return testSupportDirectory.path;
      }
      throw PlatformException(code: 'test_storage_unavailable');
    },
  );
  keepCrashLogUnavailable();
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

/// Pumps a Round of [exercises] as a learner sees it (not the Preview, so
/// the learner's Audio Settings apply) and waits for [finder].
Future<_Voice> _pumpLearnerRound(
  WidgetTester tester,
  List<Exercise> exercises,
  Finder finder,
) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final round = LearningRound(
    id: 'round-271',
    title: 'Revision 0 round',
    updatedAt: _stamp,
    content: [
      for (final exercise in exercises) LearningContent.fromExercise(exercise),
    ],
  );
  final lesson = Lesson(
    lessonId: 'lesson-271',
    title: 'Revision 0 lesson',
    rounds: [round],
  );
  final voice = _Voice();
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: _course([lesson]),
        lesson: lesson,
        round: round,
        ttsLanguage: 'it-IT',
        roundIndex: 0,
        ttsCacheService: voice,
      ),
    ),
  );
  for (var i = 0; i < 200 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
  // What plays by itself starts once the exercise is active.
  await tester.pump();
  await tester.pump();
  return voice;
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPluginMocks();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Revision 0 learner');
  });

  group('Missing letters', () {
    test('stores its spoken text as optional audio', () {
      final exercise = _missingLetters();
      final f = ExerciseFeatures(exercise);
      final audio = f.audioElements.single;
      expect(audio.text, 'Il treno parte alle nove.');
      expect(audio.required, isFalse);
      // It still plays by itself while the learner's audio is on.
      expect(audio.effectivePlayback, AudioPlayback.automatic);
      expect(f.requiresAudio, isFalse);
      expect(
        AudioExerciseAvailabilityService().isAudioExercise(exercise),
        isFalse,
      );
      // The learner types letters; the spoken text is an aid.
      expect(f.kind, LearnerExerciseKind.inputComplete);
      expect(
        ExerciseCopyService.instructionForExercise(_course(const []), exercise),
        'Write the missing letters.',
      );
    });

    test('is represented by its preset and reads its fields back', () {
      final exercise = _missingLetters();
      expect(PresetRecipes.represents(exercise, 'missing_letters'), isTrue);
      expect(PresetRecipes.recognize(exercise), 'missing_letters');
      final draft = PresetRecipes.decompose(exercise, 'missing_letters');
      expect(draft.prompt, 'Il t_ren_o parte alle n_ov_e.');
      expect(draft.tts, 'Il treno parte alle nove.');
      // Without a spoken text nothing changes.
      final silent = _missingLetters(tts: '');
      expect(ExerciseFeatures(silent).audioElements, isEmpty);
      expect(PresetRecipes.represents(silent, 'missing_letters'), isTrue);
    });

    test('an exercise stored earlier keeps its audio and its form', () {
      final earlier = _earlierMissingLetters();
      final f = ExerciseFeatures(earlier);
      // Nothing is converted: it is an audio exercise as it was.
      expect(f.requiresAudio, isTrue);
      expect(f.kind, LearnerExerciseKind.inputListenGaps);
      // Its preset still represents it, and its form saves the new shape.
      expect(PresetRecipes.represents(earlier, 'missing_letters'), isTrue);
      expect(PresetRecipes.recognize(earlier), 'missing_letters');
      final saved = PresetRecipes.rebuild(earlier, 'missing_letters')!;
      expect(ExerciseFeatures(saved).requiresAudio, isFalse);
    });

    test('Listen and fill the gaps is still an audio exercise', () {
      final listen = _labExercise('qql_lab254_input_missing_one');
      final f = ExerciseFeatures(listen);
      expect(f.requiresAudio, isTrue);
      expect(f.kind, LearnerExerciseKind.inputListenGaps);
      expect(PresetVariants.withSaveMarks('missing_word', listen), listen);
    });

    test('the Laboratory example has optional audio', () {
      final example = _labExercise('qql_lab254_missing_letters_audio');
      expect(ExerciseFeatures(example).requiresAudio, isFalse);
      expect(PresetRecipes.recognize(example), 'missing_letters');
    });

    testWidgets('stays in the Round, silent, while audio is off', (
      tester,
    ) async {
      // Audio Exercises is off until a learner turns it on.
      final voice = await _pumpLearnerRound(tester, [
        _missingLetters(),
      ], find.byKey(const Key('exercise-instruction')));
      expect(_text(tester, 'exercise-heading'), 'MISSING LETTERS');
      expect(
        _text(tester, 'exercise-instruction'),
        'Write the missing letters.',
      );
      expect(find.text('Il t___o parte alle n__e.'), findsOneWidget);
      expect(find.text('Play audio'), findsNothing);
      expect(find.byTooltip('Play audio'), findsNothing);
      expect(voice.spoken, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads its text aloud while audio is on', (tester) async {
      await SettingsService().setAudioExercisesEnabled(true);
      await SettingsService().setTtsEnabled(true);
      final voice = await _pumpLearnerRound(tester, [
        _missingLetters(),
      ], find.byKey(const Key('exercise-instruction')));
      expect(
        _text(tester, 'exercise-instruction'),
        'Write the missing letters.',
      );
      expect(find.text('Play audio'), findsOneWidget);
      expect(voice.spoken, ['Il treno parte alle nove.']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an exercise stored earlier is still skipped without audio', (
      tester,
    ) async {
      // The earlier exercise needs audio, so only the new one is played.
      await _pumpLearnerRound(tester, [
        _earlierMissingLetters().copyWith(id: 'earlier'),
        _missingLetters().copyWith(id: 'now'),
      ], find.byKey(const Key('exercise-instruction')));
      expect(find.text('Play audio'), findsNothing);
      expect(find.text('Il t___o parte alle n__e.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Put the sentences in order', () {
    test('marks its blocks as lines', () {
      final exercise = _built(
        'sentence_order',
        order: 'Ciao Anna\nCiao Marco',
        extraWords: 'Buonanotte',
      );
      expect(exercise.items, hasLength(3));
      for (final item in exercise.items) {
        expect(item.content.single.role, 'line');
      }
      final f = ExerciseFeatures(exercise);
      expect(f.isLineOrder, isTrue);
      expect(f.kind, LearnerExerciseKind.arrangeLines);
      expect(
        ExerciseCopyService.instructionForExercise(_course(const []), exercise),
        'Arrange the lines in a logical order.',
      );
      expect(PresetRecipes.represents(exercise, 'sentence_order'), isTrue);
      expect(PresetRecipes.recognize(exercise), 'sentence_order');
      // Marked lines are never Put the words in order.
      expect(PresetRecipes.represents(exercise, 'word_order'), isFalse);
      final draft = PresetRecipes.decompose(exercise, 'sentence_order');
      expect(draft.order, 'Ciao Anna\nCiao Marco');
      expect(draft.extraWords, 'Buonanotte');
    });

    test('without the mark the text is still guessed', () {
      // Two short lines stored earlier read as words, as before.
      final short = _earlierLines(['Ciao Anna', 'Ciao Marco']);
      expect(ExerciseFeatures(short).isLineOrder, isFalse);
      expect(ExerciseFeatures(short).kind, LearnerExerciseKind.arrangeSentence);
      // Three words, or a closing mark, read as lines.
      final long = _earlierLines(['Anna entra nel bar.', 'Ordina un caffè.']);
      expect(ExerciseFeatures(long).isLineOrder, isTrue);
      // Either still opens in its form, which saves the mark.
      for (final earlier in [short, long]) {
        expect(PresetRecipes.represents(earlier, 'sentence_order'), isTrue);
        expect(PresetRecipes.recognize(earlier), 'sentence_order');
        final saved = PresetRecipes.rebuild(earlier, 'sentence_order')!;
        expect(ExerciseFeatures(saved).kind, LearnerExerciseKind.arrangeLines);
      }
    });

    test('Put the words in order is not marked', () {
      final words = _built(
        'word_order',
        tokens: 'Anna\nbeve\nun\ncaffè',
        order: 'Anna\nbeve\nun\ncaffè',
      );
      for (final item in words.items) {
        expect(item.content.single.role, 'primary');
      }
      expect(ExerciseFeatures(words).kind, LearnerExerciseKind.arrangeSentence);
      expect(PresetRecipes.recognize(words), 'word_order');
    });

    test('the canonical editor offers the line role for item texts', () {
      final role = ElementRoles.find(
        'line',
        type: 'text',
        place: ElementPlace.item,
        primitive: ExercisePrimitive.arrange,
      );
      expect(role, isNotNull);
      expect(role!.description, contains('Put the sentences in order'));
    });

    test('the Laboratory examples carry the mark', () {
      for (final id in [
        'qql_lab254_sentence_order_story',
        'qql_lab254_sentence_order_dialogue',
      ]) {
        final example = _labExercise(id);
        expect(
          example.items.every((item) => item.content.single.role == 'line'),
          isTrue,
          reason: id,
        );
        expect(PresetRecipes.recognize(example), 'sentence_order', reason: id);
      }
    });

    testWidgets('two short lines play as lines', (tester) async {
      await _pumpLearnerRound(tester, [
        _lines(['Ciao Anna', 'Ciao Marco']),
      ], find.byKey(const Key('exercise-instruction')));
      expect(_text(tester, 'exercise-heading'), 'PUT THE SENTENCES IN ORDER');
      expect(
        _text(tester, 'exercise-instruction'),
        'Arrange the lines in a logical order.',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('A Round copied whole', () {
    LearningContent content(String id) => LearningContent.fromExercise(
      _lines(['Ciao Anna', 'Ciao Marco']).copyWith(id: id),
    );

    test('keeps every field of a Test Round', () {
      final round = LearningRound(
        id: 'round-test',
        publicationState: PublicationState.draft,
        provisionalDraft: true,
        updatedAt: _stamp,
        title: 'Check what you know',
        visualType: 'test',
        roundType: RoundType.test,
        testFixedOrder: true,
        testPassingPercent: 80,
        content: [content('a'), content('b')],
        focusModuleId: 'module_1',
        supportingModuleIds: const ['module_2', 'module_3'],
      );
      final replaced = [content('b')];
      final copy = CourseHierarchyUpdateService().roundWithContent(
        round,
        replaced,
      );
      expect(copy.content.map((item) => item.id), ['b']);
      expect(
        copy.toJson()..remove('content'),
        round.toJson()..remove('content'),
      );
    });

    test('keeps a Timed Round\'s limits and a sequence\'s flow', () {
      final timed = LearningRound(
        id: 'round-timed',
        updatedAt: _stamp,
        title: 'Against the clock',
        roundType: RoundType.timed,
        timedLimitsSeconds: const [120, 90, 60],
        content: [content('a')],
      );
      final timedCopy = CourseHierarchyUpdateService().roundWithContent(timed, [
        content('a'),
        content('b'),
      ]);
      expect(timedCopy.timedLimitsSeconds, [120, 90, 60]);
      expect(timedCopy.roundType, RoundType.timed);

      final items = [content('a'), content('b')];
      final sequence = LearningRound(
        id: 'round-sequence',
        updatedAt: _stamp,
        title: '',
        content: items,
        flow: RoundFlowAuthoring.linearFor(items, title: 'In order'),
      );
      final sequenceCopy = CourseHierarchyUpdateService().roundWithContent(
        sequence,
        items,
      );
      expect(sequenceCopy.toJson(), sequence.toJson());
      expect(sequenceCopy.flow, isNotNull);
    });
  });
}
