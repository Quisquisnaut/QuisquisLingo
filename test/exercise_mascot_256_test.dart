import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_mascot_policy.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/widgets/exercise_mascot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 9 (owner decisions, 29 September 2026): a random
/// mascot on the leading side of the sentence of a learner exercise that
/// shows no picture, avatar or video, has a sentence the learner reads or
/// hears, and keeps room beside it. Random pictures, never matched to the
/// exercise; the sleeping monkey stays on the Round path only; within one
/// Round no picture twice and never the same character twice in a row.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 29, 12);

final _bundledMascots = [
  for (final file in Directory('assets/mascots').listSync())
    if (file.path.toLowerCase().endsWith('.webp'))
      'assets/mascots/${file.uri.pathSegments.last}',
]..sort();

const _sleepingMonkey = 'assets/mascots/qql-monkey-sleeping.webp';

// The Edge Case is the Course to import since Build 259 Revision 5.
Course _load(String file) => Course.fromJson(
  jsonDecode(
        File(
          file == 'edge_case_it_en.json'
              ? 'demo_courses/$file'
              : 'assets/courses/$file',
        ).readAsStringSync(),
      )
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

/// Presets whose exercises never show a mascot: a picture or an avatar
/// (rule 1), no sentence (rule 2), no room beside one (rule 3).
const _neverMascot = {
  'icon_choice',
  'script_recognition',
  'listening_image_choice',
  'picture_choice',
  'picture_name',
  'picture_blocks',
  'image_word',
  'spell_word',
  'spell_heard',
  'picture_word_match',
  'picture_flashcard',
  'word_match',
  'super_match',
  'audio_match',
  'sentence_order',
  'sort_into_groups',
  'fill_the_slots',
  'flashcard',
  'note_card',
  'dialogue_line',
  'story_cover',
  'before_you_start',
  'page',
};

/// Where the mascot of an exercise of each other preset may sit (none when
/// the exercise lacks a sentence or has a picture added).
const _allowedAnchors = <String, Set<ExerciseMascotAnchor>>{
  'translation_choice_to_target': {ExerciseMascotAnchor.question},
  'translation_choice_to_source': {ExerciseMascotAnchor.question},
  'choice_target': {
    ExerciseMascotAnchor.prompt,
    ExerciseMascotAnchor.question,
    ExerciseMascotAnchor.playButton,
  },
  'choice_source': {
    ExerciseMascotAnchor.prompt,
    ExerciseMascotAnchor.question,
    ExerciseMascotAnchor.playButton,
  },
  'gap_choice': {ExerciseMascotAnchor.question},
  'true_false': {
    ExerciseMascotAnchor.question,
    ExerciseMascotAnchor.playButton,
  },
  'one_word_fills_all': {ExerciseMascotAnchor.question},
  'listening_choose_target': {ExerciseMascotAnchor.playButton},
  'listening_choose_source': {ExerciseMascotAnchor.playButton},
  'listening_answer_target': {ExerciseMascotAnchor.playButton},
  'listening_answer_source': {ExerciseMascotAnchor.playButton},
  'reading_answer_target': {ExerciseMascotAnchor.question},
  'type_translation_to_target': {ExerciseMascotAnchor.prompt},
  'type_translation_to_source': {ExerciseMascotAnchor.prompt},
  'listening_spelling': {ExerciseMascotAnchor.playButton},
  'missing_word': {ExerciseMascotAnchor.gappedText},
  // The first-letter sentence; with the hint off, the gapped text or the
  // prompt.
  'type_missing_word': {
    ExerciseMascotAnchor.question,
    ExerciseMascotAnchor.gappedText,
    ExerciseMascotAnchor.prompt,
  },
  'complete_text': {ExerciseMascotAnchor.gappedText},
  'missing_letters': {ExerciseMascotAnchor.gappedText},
  'word_order': {ExerciseMascotAnchor.prompt},
  'build_translation_to_target': {ExerciseMascotAnchor.prompt},
  'build_translation_to_source': {ExerciseMascotAnchor.prompt},
  'gap_blocks': {ExerciseMascotAnchor.gappedText},
};

/// The Laboratory presets whose examples show a mascot (Read and answer
/// without dialogue lines, Type the missing word with a sentence).
const _laboratoryShows = {
  'reading_answer_target',
  'type_missing_word',
  'translation_choice_to_target',
  'translation_choice_to_source',
  'choice_target',
  'choice_source',
  'gap_choice',
  'true_false',
  'one_word_fills_all',
  'listening_choose_target',
  'listening_choose_source',
  'listening_answer_target',
  'listening_answer_source',
  'type_translation_to_target',
  'type_translation_to_source',
  'listening_spelling',
  'missing_word',
  'complete_text',
  'missing_letters',
  'word_order',
  'build_translation_to_target',
  'build_translation_to_source',
  'gap_blocks',
};

Exercise _select(
  String id,
  String question, {
  List<PromptElement> extra = const [],
}) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  promptElements: [
    ...extra,
    PromptElement(role: 'question', type: 'text', text: question),
  ],
  items: [
    ExerciseItem(
      id: '${id}_a',
      content: [PromptElement(type: 'text', text: 'Right $id')],
    ),
    ExerciseItem(
      id: '${id}_b',
      content: [PromptElement(type: 'text', text: 'Wrong $id')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_a'],
  ),
  updatedAt: _stamp,
);

LearningRound _round(
  List<Exercise> exercises, {
  String visualType = 'generic',
  bool flow = false,
}) {
  final content = [
    for (final exercise in exercises) LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: 'mascot_round',
    title: 'Mascots',
    updatedAt: _stamp,
    visualType: visualType,
    content: content,
    flow: flow ? RoundFlowAuthoring.linearFor(content) : null,
  );
}

Course _course(LearningRound round) => Course(
  courseId: 'exercise_mascot_256',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  title: 'Mascot course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson_one',
      title: 'Lesson one',
      updatedAt: _stamp,
      rounds: [round],
    ),
  ],
);

class _Speech extends TtsCacheService {
  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async => true;

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
    (_) async => null,
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

Future<void> _show(
  WidgetTester tester,
  LearningRound round, {
  Size size = const Size(1000, 1400),
  int seed = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final course = _course(round);
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        // A new screen each time, not an update of the last one.
        key: UniqueKey(),
        course: course,
        lesson: course.lessons.single,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: true,
        ttsCacheService: _Speech(),
        mascotAssets: _bundledMascots,
        mascotRandom: Random(seed),
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
}

/// The picture of the mascot on screen, or null.
String? _mascotOnScreen(WidgetTester tester) {
  final mascots = tester.widgetList<ExerciseMascot>(
    find.byType(ExerciseMascot),
  );
  expect(mascots.length, lessThanOrEqualTo(1));
  return mascots.isEmpty ? null : mascots.single.asset;
}

void main() {
  group('policy', () {
    test('the bundled mascots are five characters; the exercise pool '
        'leaves out the sleeping monkey only', () {
      expect(_bundledMascots, hasLength(10));
      expect(
        {
          for (final asset in _bundledMascots)
            asset: ExerciseMascotPolicy.characterOf(asset),
        },
        {
          'assets/mascots/cat-celebrating_tr.webp': 'cat',
          'assets/mascots/cat_reading.webp': 'cat',
          'assets/mascots/cat_speaking.webp': 'cat',
          'assets/mascots/dog-laughing-pencil_tr.webp': 'dog',
          'assets/mascots/kid_reading.webp': 'kid',
          'assets/mascots/monkey-yawning_tr.webp': 'monkey',
          'assets/mascots/qql-dog-tambourine.webp': 'dog',
          _sleepingMonkey: 'monkey',
          'assets/mascots/robot_running.webp': 'robot',
          'assets/mascots/robot_speaking.webp': 'robot',
        },
      );
      final pool = ExerciseMascotPolicy.exercisePool(_bundledMascots);
      expect(pool, hasLength(9));
      expect(pool, isNot(contains(_sleepingMonkey)));
      expect(pool, contains('assets/mascots/monkey-yawning_tr.webp'));
    });

    test('a sentence has two words or ends a sentence', () {
      expect(ExerciseMascotPolicy.isSentence('Grazie.'), isTrue);
      expect(ExerciseMascotPolicy.isSentence('Che cosa dici?'), isTrue);
      expect(ExerciseMascotPolicy.isSentence('il gatto'), isTrue);
      expect(ExerciseMascotPolicy.isSentence('Buon_____!'), isTrue);
      expect(ExerciseMascotPolicy.isSentence('你好。'), isTrue);
      expect(ExerciseMascotPolicy.isSentence('"Ciao!"'), isTrue);
      expect(ExerciseMascotPolicy.isSentence('ciao'), isFalse);
      expect(ExerciseMascotPolicy.isSentence('Buona_____'), isFalse);
      expect(ExerciseMascotPolicy.isSentence('   '), isFalse);
    });

    test('room: 220 pixels of text, three lines, a 560-pixel window', () {
      bool fits(double width, int? lines, double height) =>
          ExerciseMascotPolicy.fits(
            textWidth: width,
            lines: lines,
            viewportHeight: height,
          );
      expect(fits(220, 3, 560), isTrue);
      expect(fits(219, 1, 800), isFalse);
      expect(fits(400, 4, 800), isFalse);
      expect(fits(400, 1, 559), isFalse);
      expect(fits(400, null, 800), isTrue);
      expect(ExerciseMascotPolicy.mascotSize(350), 72);
      expect(ExerciseMascotPolicy.mascotSize(600), 96);
    });

    test('the order never repeats a picture nor a character in a row', () {
      final pool = ExerciseMascotPolicy.exercisePool(_bundledMascots);
      final orders = <String>{};
      for (var seed = 0; seed < 500; seed++) {
        final sequence = ExerciseMascotSequence.build(pool, Random(seed));
        final order = sequence.order;
        expect(order, hasLength(9), reason: 'seed $seed');
        expect(order.toSet(), hasLength(9), reason: 'seed $seed');
        expect(order, isNot(contains(_sleepingMonkey)));
        for (var i = 1; i < order.length; i++) {
          expect(
            ExerciseMascotPolicy.characterOf(order[i]),
            isNot(ExerciseMascotPolicy.characterOf(order[i - 1])),
            reason: 'seed $seed at $i: $order',
          );
        }
        for (final expected in order) {
          expect(sequence.next(), expected);
        }
        expect(sequence.next(), isNull);
        expect(sequence.taken, 9);
        orders.add(order.join(','));
      }
      // Random, not a fixed order.
      expect(orders.length, greaterThan(400));
    });

    test('a pool that cannot alternate stops rather than repeat', () {
      final cats = [
        'assets/mascots/cat_reading.webp',
        'assets/mascots/cat_speaking.webp',
        'assets/mascots/cat-celebrating_tr.webp',
      ];
      expect(ExerciseMascotSequence.build(cats, Random(3)).order, hasLength(1));
      for (var seed = 0; seed < 50; seed++) {
        final order = ExerciseMascotSequence.build([
          ...cats,
          'assets/mascots/robot_running.webp',
        ], Random(seed)).order;
        expect(order.toSet(), hasLength(order.length));
        for (var i = 1; i < order.length; i++) {
          expect(
            ExerciseMascotPolicy.characterOf(order[i]),
            isNot(ExerciseMascotPolicy.characterOf(order[i - 1])),
          );
        }
      }
      expect(ExerciseMascotSequence.build(const [], Random(1)).next(), isNull);
    });

    // Build 271 Revision 5: which picture an exercise shows has its own
    // owner; the Round screen tells it what happens and reads it.
    test('the cast gives an exercise its picture the first time it has room '
        'and keeps it until the next exercise', () {
      final sequence = ExerciseMascotSequence.build(
        ExerciseMascotPolicy.exercisePool(_bundledMascots),
        Random(7),
      );
      final order = sequence.order;
      final cast = ExerciseMascotCast(sequence);
      expect(cast.picture, isNull);
      // No room: nothing is taken, however often the page says so.
      cast.settle(hasRoom: false);
      cast.settle(hasRoom: false);
      expect(cast.picture, isNull);
      expect(sequence.taken, 0);
      // Room: the Round's first picture, taken once.
      cast.settle(hasRoom: true);
      expect(cast.picture, order[0]);
      // The window gets narrower and wider again: the picture is its own.
      cast.settle(hasRoom: false);
      cast.settle(hasRoom: true);
      cast.settle(hasRoom: true);
      expect(cast.picture, order[0]);
      expect(sequence.taken, 1);
      // An exercise that never has room spends no picture.
      cast.startExercise();
      expect(cast.picture, isNull);
      cast.settle(hasRoom: false);
      expect(sequence.taken, 1);
      // So the one after it shows the second picture, not the third.
      cast.startExercise();
      cast.settle(hasRoom: true);
      expect(cast.picture, order[1]);
      for (var i = 2; i < order.length; i++) {
        cast.startExercise();
        cast.settle(hasRoom: true);
        expect(cast.picture, order[i]);
      }
      // The Round's pictures are used up: later exercises show none.
      cast.startExercise();
      cast.settle(hasRoom: true);
      cast.settle(hasRoom: true);
      expect(cast.picture, isNull);
      expect(sequence.taken, order.length);
    });

    for (final file in const [
      'exercise_laboratory_en_it.json',
      'edge_case_it_en.json',
      'english_from_italian_it_en.json',
    ]) {
      test('$file: every exercise follows the three rules', () {
        final course = _load(file);
        final shown = <String>{};
        for (final content in _exerciseContent(course)) {
          final exercise = content.exercise!;
          final preset = content.editorTemplate;
          final anchor = ExerciseMascotPolicy.anchorFor(exercise);
          final f = ExerciseFeatures(exercise);
          final reason = '${content.id} ($preset): $anchor';
          if (!ExerciseMascotPolicy.wordsAndSoundOnly(f) ||
              _neverMascot.contains(preset) ||
              preset.isEmpty) {
            expect(anchor, ExerciseMascotAnchor.none, reason: reason);
            continue;
          }
          expect(
            _allowedAnchors[preset],
            isNotNull,
            reason: 'unexpected preset $preset',
          );
          if (anchor == ExerciseMascotAnchor.none) continue;
          expect(_allowedAnchors[preset], contains(anchor), reason: reason);
          final sentence =
              ExerciseMascotPolicy.sentenceAt(exercise, anchor) ??
              f.primaryAudioText ??
              '';
          expect(
            ExerciseMascotPolicy.isSentence(sentence),
            isTrue,
            reason: reason,
          );
          shown.add(preset);
        }
        if (file == 'exercise_laboratory_en_it.json') {
          expect(shown, _laboratoryShows);
        }
      });
    }
  });

  // Build 271 Revision 5: the measure of rule 3 has its own owner. It reads
  // the page and changes nothing.
  group('the room a page has', () {
    const sentence = 'Il gatto nero dorme sempre sul divano rosso?';

    Future<List<ExerciseMascotRoom?>> rooms(
      WidgetTester tester,
      Size size,
      Exercise exercise, {
      ExerciseMascotAnchor? only,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final answers = <ExerciseMascotRoom?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: Builder(
                // A new page each time, so that it is asked again.
                key: UniqueKey(),
                builder: (context) {
                  for (var asked = 0; asked < 3; asked++) {
                    answers.add(
                      ExerciseMascotRoom.of(
                        context,
                        exercise,
                        promptAsInstruction: false,
                        only: only,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      return answers;
    }

    Future<ExerciseMascotRoom?> room(
      WidgetTester tester,
      Size size,
      Exercise exercise, {
      ExerciseMascotAnchor? only,
      double textScale = 1,
    }) async {
      final answers = await rooms(
        tester,
        size,
        exercise,
        only: only,
        textScale: textScale,
      );
      // Asked again and again, the same page gives the same answer.
      expect(answers, hasLength(greaterThanOrEqualTo(3)));
      for (final answer in answers) {
        expect(answer?.anchor, answers.first?.anchor);
        expect(answer?.size, answers.first?.size);
      }
      return answers.first;
    }

    testWidgets('beside the question, larger from 600 pixels of content', (
      tester,
    ) async {
      final exercise = _select('q', sentence);
      final wide = await room(tester, const Size(1000, 1400), exercise);
      expect(wide?.anchor, ExerciseMascotAnchor.question);
      expect(wide?.size, 96);
      // A sentence short enough for three lines beside the smaller mascot.
      final narrower = await room(
        tester,
        const Size(500, 1000),
        _select('short', 'Il gatto dorme?'),
      );
      expect(narrower?.anchor, ExerciseMascotAnchor.question);
      expect(narrower?.size, 72);
      // The longer one would take four lines there.
      expect(await room(tester, const Size(500, 1000), exercise), isNull);
    });

    testWidgets('none without 220 pixels of text, in a low window, beside '
        'one word, or when the sentence takes more than three lines', (
      tester,
    ) async {
      final exercise = _select('q', sentence);
      expect(await room(tester, const Size(330, 1000), exercise), isNull);
      expect(await room(tester, const Size(1000, 540), exercise), isNull);
      expect(
        await room(tester, const Size(1000, 1400), _select('w', 'ciao')),
        isNull,
      );
      expect(
        await room(
          tester,
          const Size(1000, 1400),
          _select('long', [for (var i = 0; i < 12; i++) sentence].join(' ')),
        ),
        isNull,
      );
      // Larger text takes more lines.
      expect(
        await room(tester, const Size(1000, 1400), exercise, textScale: 3),
        isNull,
      );
    });

    testWidgets('a renderer asks about the sentence it draws', (tester) async {
      final exercise = _select('q', sentence);
      expect(
        (await room(
          tester,
          const Size(1000, 1400),
          exercise,
          only: ExerciseMascotAnchor.question,
        ))?.anchor,
        ExerciseMascotAnchor.question,
      );
      for (final other in [
        ExerciseMascotAnchor.prompt,
        ExerciseMascotAnchor.gappedText,
        ExerciseMascotAnchor.playButton,
      ]) {
        expect(
          await room(tester, const Size(1000, 1400), exercise, only: other),
          isNull,
          reason: '$other',
        );
      }
    });
  });

  group('Round screen', () {
    setUp(() {
      ExerciseMascot.enabled = true;
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: _profileId,
            displayName: 'Mascot learner',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: _profileId,
        'sound_effects_enabled': false,
      });
      keepCrashLogUnavailable();
      _platforms();
    });
    tearDown(() => ExerciseMascot.enabled = false);

    testWidgets('the mascot sits on the leading side of the question', (
      tester,
    ) async {
      await _show(
        tester,
        _round([_select('q1', 'Il gatto dorme sul divano?')]),
      );
      final asset = _mascotOnScreen(tester);
      expect(asset, isNotNull);
      expect(asset, isNot(_sleepingMonkey));
      final row = find.byKey(const Key('exercise-mascot-row'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(
          of: row,
          matching: find.text('Il gatto dorme sul divano?'),
        ),
        findsOneWidget,
      );
      final mascotLeft = tester.getTopLeft(find.byType(ExerciseMascot)).dx;
      final textLeft = tester
          .getTopLeft(find.text('Il gatto dorme sul divano?'))
          .dx;
      expect(mascotLeft, lessThan(textLeft));
      // Decoration only: nothing for screen readers.
      expect(
        find.descendant(
          of: find.byType(ExerciseMascot),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no mascot without room, in a Story, or when off', (
      tester,
    ) async {
      final sentence = [_select('q1', 'Il gatto dorme sul divano?')];
      // Too narrow for 220 pixels of text beside it.
      await _show(tester, _round(sentence), size: const Size(330, 1000));
      expect(find.byType(ExerciseMascot), findsNothing);
      // A window lower than 560 pixels.
      await _show(tester, _round(sentence), size: const Size(1000, 540));
      expect(find.byType(ExerciseMascot), findsNothing);
      // A Story: its characters are its cast.
      await _show(
        tester,
        _round(sentence, visualType: LearningRound.storyVisualType, flow: true),
      );
      expect(find.byType(ExerciseMascot), findsNothing);
      // A sequence (a plain Round in order) does show one.
      await _show(tester, _round(sentence, flow: true));
      expect(find.byType(ExerciseMascot), findsOneWidget);
      ExerciseMascot.enabled = false;
      await _show(tester, _round(sentence));
      expect(find.byType(ExerciseMascot), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a Round never repeats a picture, never shows one character '
        'twice in a row, and keeps each mascot through the feedback', (
      tester,
    ) async {
      final exercises = [
        for (var i = 1; i <= 6; i++)
          _select('s$i', 'Frase numero $i per il gatto.'),
        // Rule 1: a picture.
        _select(
          'picture',
          'Che cosa vedi qui?',
          extra: const [
            PromptElement(
              role: 'picture',
              type: 'image',
              asset: 'assets/exercise_images/apple.webp',
            ),
          ],
        ),
        // Rule 2: one word.
        _select('word', 'ciao'),
      ];
      await _show(tester, _round(exercises), seed: 11);
      final seen = <(String, String?)>[];
      for (var step = 0; step < exercises.length; step++) {
        final question = find.textContaining(
          RegExp(
            r'^(Frase numero \d per il gatto\.|Che cosa vedi qui\?|ciao)$',
          ),
        );
        expect(question, findsOneWidget);
        final text = tester.widget<Text>(question).data!;
        final id = exercises
            .firstWhere((e) => ExerciseFeatures(e).questionText == text)
            .id;
        final before = _mascotOnScreen(tester);
        await _tap(tester, find.text('Right $id'));
        expect(_mascotOnScreen(tester), before, reason: 'kept after answering');
        seen.add((id, before));
        if (step < exercises.length - 1) {
          await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
        }
      }
      expect(seen.firstWhere((s) => s.$1 == 'picture').$2, isNull);
      expect(seen.firstWhere((s) => s.$1 == 'word').$2, isNull);
      final pictures = [
        for (final (_, asset) in seen)
          if (asset != null) asset,
      ];
      expect(pictures, hasLength(6));
      expect(pictures.toSet(), hasLength(6), reason: '$pictures');
      expect(pictures, isNot(contains(_sleepingMonkey)));
      for (var i = 1; i < pictures.length; i++) {
        expect(
          ExerciseMascotPolicy.characterOf(pictures[i]),
          isNot(ExerciseMascotPolicy.characterOf(pictures[i - 1])),
          reason: '$pictures',
        );
      }
      expect(tester.takeException(), isNull);
    });

    // Build 271 Revision 5: the picture is chosen when an exercise comes on
    // the page or the window changes, never while the page draws. What the
    // learner sees is what it was.
    List<Exercise> sentences(int count) => [
      for (var i = 1; i <= count; i++)
        _select('s$i', 'Frase numero $i per il gatto.'),
    ];

    List<String> orderFor(int seed) => ExerciseMascotSequence.build(
      ExerciseMascotPolicy.exercisePool(_bundledMascots),
      Random(seed),
    ).order;

    Future<void> resize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
    }

    /// Answers the exercise on the page and goes to the next one.
    Future<void> answerAndContinue(WidgetTester tester, int count) async {
      for (var i = 1; i <= count; i++) {
        final right = find.text('Right s$i');
        if (right.evaluate().isEmpty) continue;
        await _tap(tester, right);
        await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
        return;
      }
      fail('No exercise on the page.');
    }

    testWidgets('a window made wider shows the mascot, a narrower one hides '
        'it, and the same picture comes back', (tester) async {
      const narrow = Size(330, 1000);
      const wide = Size(1000, 1400);
      await _show(tester, _round(sentences(2)), size: narrow, seed: 5);
      expect(_mascotOnScreen(tester), isNull);
      await resize(tester, wide);
      // The Round's first picture: nothing was spent while there was no
      // room.
      expect(_mascotOnScreen(tester), orderFor(5)[0]);
      await resize(tester, narrow);
      expect(_mascotOnScreen(tester), isNull);
      await resize(tester, wide);
      expect(_mascotOnScreen(tester), orderFor(5)[0]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an exercise that never had room spends no picture', (
      tester,
    ) async {
      await _show(
        tester,
        _round(sentences(3)),
        size: const Size(330, 1000),
        seed: 5,
      );
      expect(_mascotOnScreen(tester), isNull);
      await answerAndContinue(tester, 3);
      expect(_mascotOnScreen(tester), isNull);
      await resize(tester, const Size(1000, 1400));
      // The second exercise shows the Round's first picture.
      expect(_mascotOnScreen(tester), orderFor(5)[0]);
      await answerAndContinue(tester, 3);
      expect(_mascotOnScreen(tester), orderFor(5)[1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the page is drawn again and again and takes no other '
        'picture', (tester) async {
      await _show(tester, _round(sentences(3)), seed: 5);
      expect(_mascotOnScreen(tester), orderFor(5)[0]);
      // Each change of the window draws the page again and tells the
      // mascots again that there is room.
      for (var step = 1; step <= 6; step++) {
        await resize(tester, Size(1000 + step * 20, 1400));
        expect(_mascotOnScreen(tester), orderFor(5)[0]);
      }
      await answerAndContinue(tester, 3);
      // The next exercise shows the second picture: none was skipped.
      expect(_mascotOnScreen(tester), orderFor(5)[1]);
      await answerAndContinue(tester, 3);
      expect(_mascotOnScreen(tester), orderFor(5)[2]);
      expect(tester.takeException(), isNull);
    });
  });
}
