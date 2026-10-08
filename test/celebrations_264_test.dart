import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/widgets/bundled_picture.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

// Build 264 Revision 3 (owner decisions of 5 October 2026): confetti after a
// won Duel and a passed Test Round (its threshold reached, or, without one,
// every answer right), only with Animations on; QQL pictures drawn as
// pictures in the Duel's answers.

const _profileId = '12345678-1234-4234-9234-123456789abc';

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

Exercise _question(
  String id, {
  List<PromptElement> right = const [],
  PromptElement? picture,
}) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  promptElements: [
    PromptElement(type: 'text', role: 'question', text: 'Question $id?'),
    ?picture,
  ],
  items: [
    ExerciseItem(
      id: '${id}_right',
      content: [
        PromptElement(type: 'text', text: 'Right $id'),
        ...right,
      ],
    ),
    ExerciseItem(
      id: '${id}_wrong',
      content: [PromptElement(type: 'text', text: 'Wrong $id')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_right'],
  ),
);

Course _course(Lesson lesson) => Course(
  courseId: 'celebration-course',
  title: 'Course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [lesson],
);

Future<void> _frames(WidgetTester tester, {int count = 10}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  void prefs({bool animations = true}) =>
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: _profileId,
            displayName: 'Tester',
          ).encode(),
        ],
        ProfileService.activeProfileIdKey: _profileId,
        'sound_effects_enabled': false,
        'startup_animation_enabled': animations,
      });

  setUp(() {
    prefs();
    keepCrashLogUnavailable();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => testSupportDirectory.path,
    );
    for (final channel in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
  });

  group('Test Round', () {
    Future<void> takeTest(
      WidgetTester tester, {
      int? threshold,
      required List<bool> answers,
    }) async {
      tester.view.physicalSize = const Size(1000, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final round = LearningRound(
        id: 'test-round',
        title: 'Quiz',
        roundType: RoundType.test,
        testFixedOrder: true,
        testPassingPercent: threshold,
        exercises: [for (var i = 0; i < answers.length; i++) _question('q$i')],
      );
      final lesson = Lesson(lessonId: 'lesson', title: 'L', rounds: [round]);
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: _course(lesson),
            lesson: lesson,
            round: round,
            ttsLanguage: 'it-IT',
            roundIndex: 0,
            previewMode: true,
            ttsCacheService: _Speech(),
          ),
        ),
      );
      for (
        var i = 0;
        i < 100 && find.text('Question q0?').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 20));
      }
      for (var i = 0; i < answers.length; i++) {
        await tester.tap(find.text('${answers[i] ? 'Right' : 'Wrong'} q$i'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('test-next')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('test-results')), findsOneWidget);
    }

    testWidgets('reaching the threshold brings confetti', (tester) async {
      await takeTest(tester, threshold: 50, answers: [true, false]);
      expect(find.byKey(const Key('test-passed-confetti')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('below the threshold, none', (tester) async {
      await takeTest(tester, threshold: 60, answers: [true, false]);
      expect(find.byKey(const Key('test-passed-confetti')), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('without a threshold, only every answer right', (tester) async {
      await takeTest(tester, answers: [true, false]);
      expect(find.byKey(const Key('test-passed-confetti')), findsNothing);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await takeTest(tester, answers: [true, true]);
      expect(find.byKey(const Key('test-passed-confetti')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('with Animations off, none', (tester) async {
      prefs(animations: false);
      await takeTest(tester, answers: [true, true]);
      expect(find.byKey(const Key('test-passed-confetti')), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  group('Duel', () {
    Future<void> openDuel(
      WidgetTester tester, {
      List<PromptElement> picture = const [],
      PromptElement? questionPicture,
    }) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final round = LearningRound(
        id: 'duel-source',
        title: 'Source',
        exercises: [
          for (var i = 0; i < 25; i++)
            _question('d$i', right: picture, picture: questionPicture),
        ],
      );
      final lesson = Lesson(lessonId: 'lesson', title: 'L', rounds: [round]);
      final course = _course(lesson);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => DuelScreen(
                      course: course,
                      lesson: lesson,
                      ttsLanguage: 'it-IT',
                    ),
                  ),
                ),
                child: const Text('Open Duel'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Duel'));
      await tester.pump();
      await _frames(tester);
    }

    Future<void> answerAll(WidgetTester tester, {required bool right}) async {
      for (var index = 0; index < 25; index++) {
        final choice = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? '').startsWith(right ? 'Right ' : 'Wrong '),
        );
        if (choice.evaluate().isEmpty) break;
        await tester.tap(choice.first);
        await _frames(tester, count: 2);
        final finish = find.text('Finish duel');
        final next = finish.evaluate().isNotEmpty
            ? finish
            : find.text('Continue');
        if (next.evaluate().isEmpty) break;
        await tester.tap(next);
        await _frames(tester, count: 2);
      }
      await _frames(tester);
    }

    testWidgets('a won Duel brings confetti', (tester) async {
      await openDuel(tester);
      await answerAll(tester, right: true);
      expect(find.byKey(const Key('duel-won-confetti')), findsOneWidget);
    });

    testWidgets('a lost Duel does not', (tester) async {
      await openDuel(tester);
      await answerAll(tester, right: false);
      expect(find.text('Back to course'), findsOneWidget);
      expect(find.byKey(const Key('duel-won-confetti')), findsNothing);
    });

    testWidgets('a question asked about a picture shows the picture', (
      tester,
    ) async {
      // Owner report of 6 October 2026: a "What is in the picture?"
      // exercise asked "Che cos'è?" in the Duel with no picture.
      await openDuel(
        tester,
        questionPicture: PromptElement(
          type: 'image',
          role: 'picture',
          text: 'the boy',
          asset: 'assets/exercise_images/boy.webp',
        ),
      );
      expect(find.byKey(const Key('duel-question-picture')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is BundledPicture &&
              widget.asset == 'assets/exercise_images/boy.webp',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a question without a picture shows none', (tester) async {
      await openDuel(tester);
      expect(find.byKey(const Key('duel-question-picture')), findsNothing);
    });

    testWidgets('the Final Duel is named in the top bar, its Lesson below', (
      tester,
    ) async {
      // Owner decision of 6 October 2026: the last Lesson's Duel read "Final
      // Duel" in the top bar and again as the page heading; the heading now
      // names the Lesson whose words the Duel asks.
      await openDuel(tester);
      expect(find.text('Final Duel'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Final Duel'),
        ),
        findsOneWidget,
      );
      final heading = tester.widget<Text>(
        find.byKey(const Key('duel-page-heading')),
      );
      expect(heading.data, 'Lesson 1: L');
    });

    testWidgets('a QQL picture answer is drawn, not named', (tester) async {
      await openDuel(
        tester,
        picture: [
          PromptElement(
            type: 'text',
            role: 'icon',
            text: 'assets/exercise_images/cat.webp',
          ),
        ],
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is BundledPicture &&
              widget.asset == 'assets/exercise_images/cat.webp',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && (widget.data ?? '').startsWith('Right '),
        ),
        findsNothing,
      );
    });
  });
}
