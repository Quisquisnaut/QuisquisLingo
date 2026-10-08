import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 259 Revision 4 (owner review of 30 September 2026, evening, points
/// 1–10): every picture preset needs its picture; no picture path reaches
/// the learner; spelling lines without a picture; demo hints; gaps are
/// written _word_; Pick the words for the gaps uses each word once (Drag the
/// blocks into the gaps merged into it); One word fills all.

final _stamp = DateTime.utc(2026, 9, 30);

Course _load(String file) => Course.fromJson(
  jsonDecode(File('assets/courses/$file').readAsStringSync())
      as Map<String, dynamic>,
);

final _laboratory = _load('exercise_laboratory_en_it.json');

Iterable<LearningContent> _contents(Course course) => course.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.content);

Exercise _exercise(Course course, String id) =>
    _contents(course).singleWhere((content) => content.id == id).exercise!;

Exercise _lab(String id) => _exercise(_laboratory, 'qql_lab254_$id');

Course _course(List<Lesson> lessons, {String source = 'English'}) => Course(
  courseId: 'r4-259-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: source,
  targetLanguage: 'Italian',
  title: 'Revision 4 259',
  ttsLanguage: 'it-IT',
  lessons: lessons,
);

Exercise _blankFor(String presetId) =>
    (PresetRecipes.canonicalOnly.contains(presetId)
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
              ))
        .withAuthoringMetadata({'presetId': presetId});

ExerciseDraftBuildResult _build(
  String presetId, {
  PublicationState state = PublicationState.published,
  String prompt = '',
  String question = '',
  String tts = '',
  String answers = '',
  String correct = '',
  String missingWords = '',
  String imageAsset = '',
  String gapLayout = '',
  String tokens = '',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blankFor(presetId),
    type: presetId,
    publicationState: state,
    prompt: prompt,
    question: question,
    tts: tts,
    answers: answers,
    correct: correct,
    missingWords: missingWords,
    imageAsset: imageAsset,
    gapLayout: gapLayout,
    tokens: tokens,
  ),
);

Exercise _built(
  String presetId, {
  String prompt = '',
  String question = '',
  String tts = '',
  String answers = '',
  String correct = '',
  String missingWords = '',
  String imageAsset = '',
  String gapLayout = '',
  String tokens = '',
}) {
  final result = _build(
    presetId,
    prompt: prompt,
    question: question,
    tts: tts,
    answers: answers,
    correct: correct,
    missingWords: missingWords,
    imageAsset: imageAsset,
    gapLayout: gapLayout,
    tokens: tokens,
  );
  expect(result.error, isNull, reason: '${result.error?.code}');
  return result.candidate!;
}

String _line(Exercise exercise) =>
    ExerciseCopyService.instructionForExercise(_laboratory, exercise);

void _window(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 160; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpRound(
  WidgetTester tester,
  Exercise exercise, {
  Size size = const Size(1200, 3000),
}) async {
  _window(tester, size);
  final round = LearningRound(
    id: 'round-${exercise.id}',
    title: 'Revision 4 round',
    content: [LearningContent.fromExercise(exercise)],
  );
  final lesson = Lesson(
    lessonId: 'lesson-${exercise.id}',
    title: 'Revision 4 lesson',
    rounds: [round],
  );
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: _course([lesson]),
        lesson: lesson,
        round: round,
        ttsLanguage: 'it-IT',
        roundIndex: 0,
        previewMode: true,
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 200)),
  );
  await _pumpUntil(tester, find.byKey(const Key('exercise-instruction')));
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPluginMocks();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Revision 4 author');
  });

  group('1. Every picture preset needs its picture', () {
    test('Type what you see and Name what you see refuse a Published save '
        'without it', () {
      expect(
        _build('picture_name', prompt: 'What is this?').error?.code,
        ExerciseDraftErrorCode.pictureRequired,
      );
      expect(
        _build('picture_blocks', prompt: 'What is this?').error?.code,
        ExerciseDraftErrorCode.pictureRequired,
      );
      expect(
        _build(
          'picture_blocks',
          state: PublicationState.draft,
          prompt: 'What is this?',
        ).error,
        isNull,
      );
    });
  });

  group('2. No picture path reaches the learner', () {
    test('an item label is its text or spoken text, never its asset', () {
      const picture = ExerciseItem(
        id: 'p',
        content: [
          PromptElement(
            type: 'image',
            asset: 'assets/exercise_images/cat.webp',
          ),
        ],
      );
      expect(picture.value, 'assets/exercise_images/cat.webp');
      expect(picture.label, isEmpty);
    });

    testWidgets('Match pictures to words shows the pictures without paths', (
      tester,
    ) async {
      await _pumpRound(tester, _lab('picture_word_match'));
      expect(find.textContaining('assets/'), findsNothing);
      expect(find.textContaining('.webp'), findsNothing);
    });
  });

  group('3. Spelling lines follow what the learner has', () {
    test('a clue, a recording or a picture', () {
      // Revision 7 wording: the lines no longer repeat BUILD THE WORD.
      expect(
        _line(_lab('spell_word_clue')),
        'Form the word the clue describes.',
      );
      expect(_line(_lab('spell_heard_letters')), 'Form the word you hear.');
      expect(_line(_lab('image_letters')), 'Form the word the picture shows.');
    });
  });

  group('8. Gaps are written _word_', () {
    test('Pick the words for the gaps reads and writes _word_', () {
      final exercise = _built(
        'gap_blocks',
        gapLayout: 'Io _vorrei_ un _caffè_.',
        tokens: 'voglio',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.hasInlineTargets, isTrue);
      expect(exercise.targets, hasLength(2));
      final draft = PresetRecipes.decompose(exercise, 'gap_blocks');
      expect(draft.gapLayout, contains('_vorrei_'));
      expect(draft.gapLayout, contains('_caffè_'));
      expect(PresetRecipes.represents(exercise, 'gap_blocks'), isTrue);
      // Braces are no longer gaps; a lone underscore is refused.
      expect(
        _build('gap_blocks', gapLayout: 'Io {vorrei} un caffè.').error?.code,
        ExerciseDraftErrorCode.arrangeGapMissing,
      );
      expect(
        _build('gap_blocks', gapLayout: 'Io _vorrei un caffè.').error?.code,
        ExerciseDraftErrorCode.arrangeGapBraces,
      );
    });

    test('Missing letters reads and writes dr_ink_', () {
      final exercise = _built(
        'missing_letters',
        prompt: 'My cat doesn’t dr_ink_ milk.',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.gapFieldTargets, hasLength(1));
      expect(f.answersFor(f.gapFieldTargets.single.id)!.answers, ['ink']);
      expect(
        PresetRecipes.decompose(exercise, 'missing_letters').prompt,
        'My cat doesn’t dr_ink_ milk.',
      );
    });
  });

  group('9. One word per gap, and One word fills all', () {
    test('Drag the blocks into the gaps is Pick the words for the gaps', () {
      final preset = ExercisePresetRegistry.byId('gap_blocks')!;
      expect(preset.name, 'Pick the words for the gaps');
      expect(preset.primitive, ExercisePrimitive.arrange);
      expect(ExercisePresetRegistry.byId('gap_choice_inline'), isNull);
      expect(
        ExercisePresetRegistry.successorOf['gap_choice_inline'],
        'gap_blocks',
      );
      expect(_line(_lab('arrange_gap_many')), 'Choose a word for each gap.');
    });

    test('One word fills all needs two gaps or more', () {
      final preset = ExercisePresetRegistry.byId('one_word_fills_all')!;
      expect(preset.name, 'One word fills all');
      final exercise = _built(
        'one_word_fills_all',
        question: '___ gatto dorme. ___ cane mangia.',
        answers: 'Il\nLa\nLo',
        correct: '1',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.selectCompleteAll);
      expect(
        ExerciseCopyService.typeLabel(_laboratory, f.kind),
        'ONE WORD FILLS ALL',
      );
      expect(_line(exercise), 'Choose the word that fills every gap.');
      expect(PresetRecipes.represents(exercise, 'one_word_fills_all'), isTrue);
      expect(
        PresetRecipes.recognize(exercise.withAuthoringMetadata(const {})),
        'one_word_fills_all',
      );
      expect(
        _build(
          'one_word_fills_all',
          question: '___ gatto dorme.',
          answers: 'Il\nLa',
          correct: '1',
        ).error?.code,
        ExerciseDraftErrorCode.blanksTooFew,
      );
      // One gap stays Pick the missing word.
      expect(
        ExerciseFeatures(
          _built(
            'gap_choice',
            question: 'Il gatto ___ sul divano.',
            answers: 'dorme\ndormono',
            correct: '1',
          ),
        ).kind,
        LearnerExerciseKind.selectComplete,
      );
    });

    testWidgets('the chosen word appears in every gap', (tester) async {
      await _pumpRound(tester, _lab('select_gap_all_article'));
      expect(
        _text(tester, 'select-question-text'),
        '___ gatto dorme. ___ cane mangia.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Il'));
      await tester.pumpAndSettle();
      expect(find.text('Correct'), findsOneWidget);
      expect(
        _text(tester, 'select-question-text'),
        'Il gatto dorme. Il cane mangia.',
      );
    });

    test('the demos show the merged preset and the new one', () {
      final labPresets = {
        for (final content in _contents(_laboratory)) content.editorTemplate,
      };
      expect(labPresets, isNot(contains('gap_choice_inline')));
      expect(labPresets, containsAll(['gap_blocks', 'one_word_fills_all']));
    });
  });

  test('every learner language has the new lines', () {
    for (final source in const [
      'English',
      'Spanish',
      'Italian',
      'German',
      'Portuguese',
      'Dutch',
      // Build 260 Revision 0: Finnish and Welsh left, French joined.
      'French',
    ]) {
      final course = _course(const [], source: source);
      for (final variant in const [
        'arrangeWordHeard',
        'arrangeWordClue',
        'arrangeGaps',
        'selectCompleteAll',
      ]) {
        expect(
          ExerciseCopyService.instructionVariant(
            course,
            variant,
            LearnerExerciseKind.selectCharacter,
          ),
          isNot(
            ExerciseCopyService.instruction(
              course,
              LearnerExerciseKind.selectCharacter,
            ),
          ),
          reason: '$source $variant',
        );
      }
      expect(
        ExerciseCopyService.typeLabel(
          course,
          LearnerExerciseKind.selectCompleteAll,
        ),
        isNot(ExerciseCopyService.typeLabel(course, LearnerExerciseKind.match)),
        reason: source,
      );
    }
  });
}
