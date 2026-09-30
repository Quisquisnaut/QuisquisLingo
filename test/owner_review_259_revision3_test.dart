import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_authoring.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/exercise_field_help.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 259 Revision 3 (owner review of 30 September 2026, points A–H):
/// Type what you hear accepts its Audio text without another line; the
/// listening lines follow the question; What is in the picture has its own
/// title and line and needs its picture; the page scrolls to the feedback
/// after an answer; typed gaps ask to type; Complete the text marks gaps
/// with ___ and accepts answer expressions; Put the sentences in order asks
/// to arrange.

final _stamp = DateTime.utc(2026, 9, 30);

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

final _laboratory = _load('exercise_laboratory_en_it.json');

Iterable<LearningContent> _contents(Course course) => course.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.content);

Exercise _exercise(Course course, String id) =>
    _contents(course).singleWhere((content) => content.id == id).exercise!;

Exercise _lab(String id) => _exercise(_laboratory, 'qql_lab254_$id');

Course _course(List<Lesson> lessons, {String source = 'English'}) => Course(
  courseId: 'r3-259-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: source,
  targetLanguage: 'Italian',
  title: 'Revision 3 259',
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
  );
  expect(result.error, isNull, reason: '${result.error?.code}');
  return result.candidate!;
}

String _line(Exercise exercise, {Course? course}) =>
    ExerciseCopyService.instructionForExercise(course ?? _laboratory, exercise);

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
    title: 'Revision 3 round',
    content: [LearningContent.fromExercise(exercise)],
  );
  final lesson = Lesson(
    lessonId: 'lesson-${exercise.id}',
    title: 'Revision 3 lesson',
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installPluginMocks();
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Revision 3 author');
  });

  group('A. Type what you hear', () {
    test('publishes with the Audio text alone, which is its answer', () {
      final exercise = _built('listening_spelling', tts: 'Arrivo alle otto.');
      expect(exercise.canonicalEvaluation.answers, isEmpty);
      expect(exercise.canonicalEvaluation.literalAnswers, [
        'Arrivo alle otto.',
      ]);
      expect(
        CourseAuditService().auditExercise(exercise).map((issue) => issue.code),
        isNot(contains('LISTENING_SPELLING_NO_ANSWER')),
      );
      expect(
        PresetRecipes.decompose(exercise, 'listening_spelling').missingWords,
        isEmpty,
      );
      // Another spelling is an extra line.
      final spelled = _built(
        'listening_spelling',
        tts: 'Arrivo alle otto.',
        missingWords: 'arrivo alle 8',
      );
      expect(spelled.canonicalEvaluation.answers, ['arrivo alle 8']);
      expect(PresetRecipes.represents(spelled, 'listening_spelling'), isTrue);
    });

    test('the box is Other accepted spellings, and the example is honest', () {
      expect(
        ExerciseFieldHelpRegistry.forEditorField(
          'listening_spelling',
          'missingWords',
        ).title,
        'Other accepted spellings (optional)',
      );
      final variants = _lab('input_listen_variants');
      expect(variants.canonicalEvaluation.answers, ['arrivo alle 8']);
      expect(variants.canonicalEvaluation.literalAnswers, [
        'Arrivo alle otto.',
      ]);
      expect(_lab('input_listen_word').canonicalEvaluation.answers, isEmpty);
    });

    testWidgets('the form labels the box', (tester) async {
      _window(tester, const Size(1200, 3000));
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _blankFor('listening_spelling'),
            title: 'Type what you hear form',
            isNew: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Other accepted spellings (optional)'), findsOneWidget);
      expect(find.text('Missing word'), findsNothing);
    });
  });

  group('B and H. Listening lines', () {
    test('a question is answered; without one the heard sentence or its '
        'meaning is chosen', () {
      expect(
        _line(_lab('select_listening_passage')),
        'Listen and answer the question.',
      );
      expect(
        _line(_lab('listening_source_question')),
        'Listen and answer the question.',
      );
      expect(
        _line(
          _built(
            'listening_choose_target',
            tts: 'Buongiorno.',
            answers: 'Buongiorno.\nBuonasera.',
            correct: '1',
          ),
        ),
        'Select the sentence that you heard.',
      );
      expect(
        _line(
          _built(
            'listening_choose_source',
            tts: 'Grazie mille!',
            answers: 'Thank you very much\nGood night',
            correct: '1',
          ),
        ),
        'Select the meaning of what you heard.',
      );
      // Picture answers keep their line.
      expect(
        _line(_lab('listening_image')),
        'Listen and choose the correct answer.',
      );
    });

    test('a primary-audio Listen and answer with a question, in Italian', () {
      final edge = _load('edge_case_it_en.json');
      expect(
        _line(_exercise(edge, 'qql_edge_254_e24_mp3'), course: edge),
        'Ascolta e rispondi alla domanda.',
      );
    });

    testWidgets('Listen and choose (to source) quotes the meaning line', (
      tester,
    ) async {
      _window(tester, const Size(1200, 3000));
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _blankFor('listening_choose_source'),
            title: 'Listen and choose form',
            isNew: true,
            course: _course(const []),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'instead of the standard line “Select the meaning of what you heard.”',
        ),
        findsOneWidget,
      );
    });
  });

  group('C. What is in the picture', () {
    test('has its own title and line and needs its picture', () {
      final exercise = _built(
        'picture_choice',
        answers: 'la mela\nla pera',
        correct: '1',
        imageAsset: 'assets/exercise_images/apple.webp',
      );
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.selectPicture);
      expect(
        ExerciseCopyService.typeLabel(_laboratory, f.kind),
        'WHAT IS IN THE PICTURE?',
      );
      expect(_line(exercise), 'Choose the option that fits best.');
      expect(PresetRecipes.recognize(exercise), 'picture_choice');
      expect(
        _build(
          'picture_choice',
          answers: 'la mela\nla pera',
          correct: '1',
        ).error?.code,
        ExerciseDraftErrorCode.pictureRequired,
      );
      expect(
        _build(
          'picture_choice',
          state: PublicationState.draft,
          answers: 'la mela\nla pera',
          correct: '1',
        ).error,
        isNull,
      );
    });

    testWidgets('the Round shows the title', (tester) async {
      await _pumpRound(tester, _lab('picture_choice'));
      expect(_text(tester, 'exercise-heading'), 'WHAT IS IN THE PICTURE?');
    });
  });

  group('D. The feedback comes into view', () {
    testWidgets('Sort into groups shows Finish round after Check', (
      tester,
    ) async {
      // A short window: without the scroll the panel was below the edge
      // and not even built.
      const size = Size(800, 450);
      final exercise = _lab('assign_groups');
      await _pumpRound(tester, exercise, size: size);
      final expected = ExerciseFeatures(exercise).assignmentsByTarget;
      for (final entry in expected.entries) {
        for (final item in entry.value) {
          await _tapVisible(tester, find.byKey(Key('assign-tile-$item')));
          await _tapVisible(
            tester,
            find.byKey(Key('assign-target-${entry.key}')),
          );
        }
      }
      // A learner scrolls only until Check shows at the bottom of the
      // window, then taps it.
      final check = find.byKey(const Key('assign-check'));
      await Scrollable.ensureVisible(tester.element(check), alignment: 1);
      await tester.pumpAndSettle();
      await tester.tap(check);
      await tester.pumpAndSettle();
      final finish = find.widgetWithText(FilledButton, 'Finish round');
      expect(finish, findsOneWidget);
      final rect = tester.getRect(finish);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
    });
  });

  group('E. Typed gaps ask to type', () {
    test('letters, one word or several words', () {
      expect(_line(_lab('missing_letters')), 'Type the missing letters.');
      expect(
        _line(_lab('complete_text')),
        'Type the words that complete the sentence.',
      );
      expect(
        _line(_lab('complete_text_alternatives')),
        'Type the word that completes the sentence.',
      );
    });
  });

  group('F. Complete the text with ___', () {
    Exercise text({String missing = 'caffè\n[il|un] treno'}) => _built(
      'complete_text',
      question: 'Anna’s morning before work.',
      prompt: 'Anna beve un ___ al bar. Poi prende ___.',
      missingWords: missing,
    );

    test('gaps come from ___ and a line may accept several answers', () {
      final exercise = text();
      final f = ExerciseFeatures(exercise);
      expect(f.kind, LearnerExerciseKind.inputComplete);
      expect(exercise.targets.map((t) => t.id), ['gap_1', 'gap_2']);
      expect(f.answersFor('gap_2')!.answers, ['[il|un] treno']);
      expect(f.authoredInstruction, 'Anna’s morning before work.');
      expect(PresetRecipes.represents(exercise, 'complete_text'), isTrue);
      final draft = PresetRecipes.decompose(exercise, 'complete_text');
      expect(draft.prompt, 'Anna beve un ___ al bar. Poi prende ___.');
      expect(draft.missingWords, 'caffè\n[il|un] treno');
      // The bundled example.
      final bundled = _lab('complete_text_alternatives');
      expect(PresetRecipes.represents(bundled, 'complete_text'), isTrue);
    });

    test('a Published save checks the gaps and the lines', () {
      final mismatch = _build(
        'complete_text',
        prompt: 'Anna beve un ___ al bar. Poi prende ___.',
        missingWords: 'caffè',
      );
      expect(mismatch.error?.code, ExerciseDraftErrorCode.gapCountMismatch);
      expect(
        mismatch.error?.detail,
        'The text has 2 gaps and Missing words has 1 line',
      );
      expect(
        _build(
          'complete_text',
          prompt: 'Anna beve un caffè.',
          missingWords: 'caffè',
        ).error?.code,
        ExerciseDraftErrorCode.gapsRequired,
      );
      expect(
        _build(
          'complete_text',
          prompt: 'Luca prende ___.',
          missingWords: '[il|un treno',
        ).error?.code,
        ExerciseDraftErrorCode.answerExpression,
      );
      // A draft keeps its text even without gaps.
      final draft = _build(
        'complete_text',
        state: PublicationState.draft,
        prompt: 'Anna beve un caffè.',
      ).candidate!;
      expect(
        PresetRecipes.decompose(draft, 'complete_text').prompt,
        'Anna beve un caffè.',
      );
    });

    testWidgets('the learner may type either answer', (tester) async {
      await _pumpRound(tester, _lab('complete_text_alternatives'));
      await tester.enterText(find.byType(TextField).first, 'un treno');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pumpAndSettle();
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('a wrong answer shows the first accepted answer', (
      tester,
    ) async {
      await _pumpRound(tester, _lab('complete_text_alternatives'));
      await tester.enterText(find.byType(TextField).first, 'la macchina');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pumpAndSettle();
      expect(find.text('Correct answer: il treno'), findsOneWidget);
    });

    testWidgets('the form names the ___ gaps', (tester) async {
      _window(tester, const Size(1200, 3000));
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _blankFor('complete_text'),
            title: 'Complete the text form',
            isNew: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Text, with ___ for each gap'), findsOneWidget);
      expect(
        find.textContaining('[il|un] gatto accepts both il gatto and un gatto'),
        findsOneWidget,
      );
    });
  });

  group('G. Put the sentences in order', () {
    test('asks to arrange the lines', () {
      expect(
        ExerciseCopyService.instruction(
          _laboratory,
          LearnerExerciseKind.arrangeLines,
        ),
        'Arrange the lines in a logical order.',
      );
      expect(
        ExerciseCopyService.instruction(
          _course(const [], source: 'Italian'),
          LearnerExerciseKind.arrangeLines,
        ),
        'Metti le righe in un ordine logico.',
      );
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
      'Finnish',
      'Welsh',
    ]) {
      final course = _course(const [], source: source);
      for (final variant in const [
        'selectListenQuestion',
        'selectListenHeard',
        'selectListenMeaning',
        'inputCompleteOne',
        'inputCompleteLetters',
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
          LearnerExerciseKind.selectPicture,
        ),
        isNot(ExerciseCopyService.typeLabel(course, LearnerExerciseKind.match)),
        reason: source,
      );
      expect(
        ExerciseCopyService.instruction(
          course,
          LearnerExerciseKind.selectPicture,
        ),
        isNot(
          ExerciseCopyService.instruction(course, LearnerExerciseKind.select),
        ),
        reason: source,
      );
    }
  });
}
