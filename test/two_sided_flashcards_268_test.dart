import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_catalogs.dart';
import 'package:quisquislingo_app/localization/learner_panel/learner_panel_catalogs.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_copy_service.dart';
import 'package:quisquislingo_app/services/flashcard_sides.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 268 Revision 0: two-sided Flashcards (owner decisions of 9 October
/// 2026). The word is on the front the first time through a Round; on a
/// repeat of a completed Round and in Review the meaning is, and the word
/// with its read-aloud moves to the back. Turn over, a tap on the card,
/// Enter or Space turns it; Got it is offered on the front. A Note card
/// stays one page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final course = Course.fromJson(
    jsonDecode(
          File(
            'assets/courses/exercise_laboratory_en_it.json',
          ).readAsStringSync(),
        )
        as Map<String, Object?>,
  );
  Exercise card(String id) => [
    for (final lesson in course.lessons)
      for (final round in lesson.rounds) ...round.exercises,
  ].singleWhere((exercise) => exercise.id == id);

  /// [exercise] with its word read aloud automatically.
  Exercise readAloud(Exercise exercise) => exercise.copyWith(
    promptElements: [
      for (final element in exercise.promptElements)
        if (element.isAudio)
          element.copyWith(playback: AudioPlayback.automatic)
        else
          element,
    ],
  );

  group('which cards have two sides', () {
    test('vocabulary and picture cards; never a Note card', () {
      for (final id in [
        'qql_lab254_card_minimal',
        'qql_lab254_card_complete',
        'qql_lab254_card_audio',
        'qql_lab254_card_usage',
        'qql_lab254_picture_card',
        'qql_lab254_picture_card_plain',
      ]) {
        expect(
          FlashcardSides.isTwoSided(ExerciseFeatures(card(id))),
          isTrue,
          reason: id,
        );
      }
      for (final id in [
        'qql_lab254_note_card_tip',
        'qql_lab254_note_card_grammar',
      ]) {
        expect(
          FlashcardSides.isTwoSided(ExerciseFeatures(card(id))),
          isFalse,
          reason: id,
        );
      }
    });

    test('a card needs a meaning or a picture behind its word', () {
      final minimal = card('qql_lab254_card_minimal');
      final wordOnly = minimal.copyWith(
        promptElements: [
          for (final element in minimal.promptElements)
            if (element.role != 'meaning') element,
        ],
      );
      expect(FlashcardSides.isTwoSided(ExerciseFeatures(wordOnly)), isFalse);
      final picture = card('qql_lab254_picture_card_plain');
      final pictureOnly = picture.copyWith(
        promptElements: [
          for (final element in picture.promptElements)
            if (element.role != 'meaning') element,
        ],
      );
      expect(FlashcardSides.isTwoSided(ExerciseFeatures(pictureOnly)), isTrue);
    });

    test('the word faces up first; the meaning on a repeat and in Review', () {
      FlashcardFront front({
        bool completed = false,
        bool review = false,
        bool preview = false,
      }) => FlashcardSides.frontFor(
        roundCompleted: completed,
        review: review,
        preview: preview,
      );
      expect(front(), FlashcardFront.word);
      expect(front(completed: true), FlashcardFront.meaning);
      expect(front(review: true), FlashcardFront.meaning);
      expect(front(completed: true, review: true), FlashcardFront.meaning);
      // The editor's Preview always shows the word first.
      expect(front(completed: true, preview: true), FlashcardFront.word);
      expect(front(review: true, preview: true), FlashcardFront.word);
    });
  });

  group('learner texts', () {
    test('the instruction asks for the meaning, or for the word', () {
      final exercise = card('qql_lab254_card_complete');
      expect(
        ExerciseCopyService.instructionForExercise(course, exercise),
        'Think of what it means, then turn the card.',
      );
      final language = ExerciseCopyService.languageName(
        course,
        intoSource: false,
      );
      expect(language, 'Italian');
      expect(
        ExerciseCopyService.instructionForExercise(
          course,
          exercise,
          meaningFirst: true,
        ),
        'Think of the Italian word, then turn the card.',
      );
      // A Note card keeps its line.
      expect(
        ExerciseCopyService.instructionForExercise(
          course,
          card('qql_lab254_note_card_tip'),
          meaningFirst: true,
        ),
        'Study the word and its usage.',
      );
    });

    test('every learner language has the card texts', () {
      for (final MapEntry(key: language, value: copy)
          in exerciseCopyCatalogs.entries) {
        expect(copy['instruction.flashcardWordFirst'], isNotEmpty);
        expect(
          copy['instruction.flashcardMeaningFirst'],
          contains('{language}'),
          reason: language,
        );
      }
      for (final MapEntry(key: language, value: panel)
          in learnerPanelCatalogs.entries) {
        expect(panel['turnOver'], isNotEmpty, reason: language);
        expect(panel['tapToTurn'], isNotEmpty, reason: language);
      }
    });
  });

  group('on the learner screen', () {
    setUp(() async {
      _installPluginMocks();
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Card Learner');
    });

    testWidgets('the Preview shows the word first and turns on a tap', (
      tester,
    ) async {
      await _show(tester, course, card('qql_lab254_card_complete'));
      expect(
        find.text('Think of what it means, then turn the card.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('flashcard-front')), findsOneWidget);
      expect(find.byKey(const Key('flashcard-word')), findsOneWidget);
      expect(find.text('acqua'), findsOneWidget);
      expect(find.text('water'), findsNothing);
      expect(find.text("Bevo un bicchiere d'acqua."), findsNothing);
      expect(find.byTooltip('Pronounce word or phrase'), findsOneWidget);
      expect(find.text('Tap the card to turn it over'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Turn over'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Got it'), findsOneWidget);
      expect(find.text('Review again'), findsNothing);

      await _tap(tester, _cardFace);
      expect(find.byKey(const Key('flashcard-back')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('flashcard-back-front-text')))
            .data,
        'acqua',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('flashcard-back-answer')))
            .data,
        'water',
      );
      expect(find.text("Bevo un bicchiere d'acqua."), findsOneWidget);
      expect(find.text('I drink a glass of water.'), findsOneWidget);
      expect(find.byTooltip('Pronounce usage sentence'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Review again'),
        findsOneWidget,
      );
      expect(find.text('Turn over'), findsNothing);

      // A second tap turns it back.
      await _tap(tester, _cardFace);
      expect(find.byKey(const Key('flashcard-front')), findsOneWidget);
      expect(find.text('water'), findsNothing);
    });

    testWidgets('Turn over, Enter and Space turn the card', (tester) async {
      await _show(tester, course, card('qql_lab254_card_complete'));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Turn over'));
      expect(find.byKey(const Key('flashcard-back')), findsOneWidget);
      await _tap(tester, _cardFace);
      expect(find.byKey(const Key('flashcard-front')), findsOneWidget);

      Focus.of(
        tester.element(find.byKey(const Key('flashcard-front'))),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('flashcard-back')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('flashcard-front')), findsOneWidget);
    });

    testWidgets('Got it on the front skips a known card', (tester) async {
      await _show(tester, course, card('qql_lab254_card_complete'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Got it'));
      expect(find.text('Card reviewed.'), findsOneWidget);
      expect(find.byKey(const Key('flashcard-front')), findsOneWidget);
      expect(find.text('water'), findsNothing);
      // The learner may still look at the back.
      await _tap(tester, _cardFace);
      expect(find.text('water'), findsOneWidget);
    });

    testWidgets('Review again comes after turning and requeues the card', (
      tester,
    ) async {
      await _show(tester, course, card('qql_lab254_card_complete'));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Turn over'));
      await _tap(tester, find.widgetWithText(OutlinedButton, 'Review again'));
      expect(
        find.text('This card will be shown again later in this round.'),
        findsOneWidget,
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
      // The card comes back word first, face up.
      expect(find.byKey(const Key('flashcard-front')), findsOneWidget);
      expect(find.text('acqua'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Got it'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
      await _until(tester, find.text('Preview complete'));
    });

    testWidgets('a Picture flashcard keeps its picture for the back', (
      tester,
    ) async {
      await _show(tester, course, card('qql_lab254_picture_card'));
      expect(find.text('la mela'), findsOneWidget);
      expect(find.text('apple'), findsNothing);
      expect(find.byKey(const Key('exercise-image')), findsNothing);
      await _tap(tester, _cardFace);
      expect(
        find.descendant(
          of: find.byKey(const Key('flashcard-back')),
          matching: find.byKey(const Key('exercise-image')),
        ),
        findsOneWidget,
      );
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('Mangio una mela.'), findsOneWidget);
    });

    testWidgets('the card turns with an animation when Animations are on', (
      tester,
    ) async {
      await _show(tester, course, card('qql_lab254_card_complete'));
      final turning = find.byWidgetPredicate(
        (widget) => widget is TweenAnimationBuilder<double>,
      );
      expect(turning, findsOneWidget);
      await tester.tap(_cardFace);
      await tester.pump();
      await tester.pump(RoundScreen.cardTurnDuration ~/ 4);
      // A quarter of the way the front is still turning away.
      expect(find.byKey(const Key('flashcard-front')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('flashcard-back')), findsOneWidget);
    });

    testWidgets('with reduced motion the sides just swap', (tester) async {
      await _show(
        tester,
        course,
        card('qql_lab254_card_complete'),
        reducedMotion: true,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TweenAnimationBuilder<double>,
        ),
        findsNothing,
      );
      await tester.tap(_cardFace);
      await tester.pump();
      expect(find.byKey(const Key('flashcard-back')), findsOneWidget);
    });

    testWidgets('a Note card stays one page', (tester) async {
      await _show(tester, course, card('qql_lab254_note_card_tip'));
      expect(find.byKey(const Key('flashcard-card')), findsNothing);
      expect(find.text('Turn over'), findsNothing);
      expect(find.text('Tap the card to turn it over'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    });

    testWidgets('the first time through a Round the word is read on the '
        'front', (tester) async {
      final exercise = readAloud(card('qql_lab254_card_complete'));
      final speech = await _show(tester, course, exercise, previewMode: false);
      await _settle(tester);
      expect(find.text('acqua'), findsOneWidget);
      expect(speech.spoken, ['acqua']);
    });

    testWidgets('a repeat of a completed Round shows the meaning first and '
        'reads the word when the card turns', (tester) async {
      final exercise = readAloud(card('qql_lab254_card_complete'));
      await ProgressService().completeRound(
        'card_round_${exercise.id}',
        courseId: course.courseId,
        courseCode: 'IT',
      );
      final speech = await _show(tester, course, exercise, previewMode: false);
      await _settle(tester);
      expect(
        find.text('Think of the Italian word, then turn the card.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('flashcard-meaning')), findsOneWidget);
      expect(find.text('water'), findsOneWidget);
      expect(find.text('acqua'), findsNothing);
      expect(find.byTooltip('Pronounce word or phrase'), findsNothing);
      // Nothing gives the word away: no read-aloud, no Play audio.
      expect(find.byTooltip('Play audio'), findsNothing);
      expect(speech.spoken, isEmpty);

      await _tap(tester, _cardFace);
      await _settle(tester);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('flashcard-back-answer')))
            .data,
        'acqua',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('flashcard-back-front-text')))
            .data,
        'water',
      );
      expect(find.byTooltip('Pronounce word or phrase'), findsOneWidget);
      expect(find.byTooltip('Play audio'), findsOneWidget);
      expect(speech.spoken, ['acqua']);

      // Turning again reads it only on request.
      await _tap(tester, _cardFace);
      await _tap(tester, _cardFace);
      await _settle(tester);
      expect(speech.spoken, ['acqua']);
    });

    testWidgets('Review shows the meaning first; a Picture flashcard shows '
        'its picture with the translation', (tester) async {
      await _show(
        tester,
        course,
        card('qql_lab254_picture_card'),
        previewMode: false,
        reviewMode: true,
      );
      await _settle(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('flashcard-front')),
          matching: find.byKey(const Key('exercise-image')),
        ),
        findsOneWidget,
      );
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('la mela'), findsNothing);
      await _tap(tester, _cardFace);
      expect(find.text('la mela'), findsOneWidget);
    });
  });
}

/// A tap on the card away from its buttons: its hint line.
final _cardFace = find.byKey(const Key('flashcard-turn-hint'));

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
  Future<void> synthesizeCached({
    required String text,
    required String language,
    String voice = '',
    double rate = 0.5,
    bool applyLearnerSettings = true,
  }) async {}

  @override
  Future<void> stop() async {}
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

/// Lets the post-frame audio work of the active card finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
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
  Exercise exercise, {
  bool previewMode = true,
  bool reviewMode = false,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final round = LearningRound(
    id: 'card_round_${exercise.id}',
    title: 'Cards',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: 'card_lesson',
    title: 'Cards',
    rounds: [round],
  );
  final speech = _Speech();
  await tester.pumpWidget(
    MaterialApp(
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      home: RoundScreen(
        key: ValueKey(exercise.id),
        course: course,
        lesson: lesson,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: previewMode,
        reviewMode: reviewMode,
        ttsCacheService: speech,
      ),
    ),
  );
  await _until(tester, find.byKey(const Key('exercise-renderer-presentation')));
  return speech;
}
