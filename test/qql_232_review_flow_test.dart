import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/review_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/vocabulary_review_service.dart';
import 'package:quisquislingo_app/widgets/learner_status_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installDesktopPluginMocks();
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'weekly_xp_target': 1000,
    });
    await ProfileService().addProfile('QQL 232 Review learner');
  });

  testWidgets('empty Review is a dedicated page with reset and Help', (
    tester,
  ) async {
    final course = _course();
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewScreen(course: course, courseCode: 'IT'),
      ),
    );
    await _pumpUntil(
      tester,
      find.text('There are no Rounds available for Review in this course.'),
    );

    expect(find.byType(LearnerStatusBar), findsNothing);
    expect(find.byKey(const Key('review-reset-word-list')), findsOneWidget);
    expect(find.byKey(const Key('review-help')), findsOneWidget);
  });

  testWidgets(
    'Review waits on the shared inter-review screen before the first Round',
    (tester) async {
      final course = _course(vocabulary: const []);
      final progress = ProgressService();
      await progress.recordRecentRound(
        course.courseId,
        course.lessons.single.lessonId,
        'round-low',
        errors: 1,
      );
      await progress.recordRecentRound(
        course.courseId,
        course.lessons.single.lessonId,
        'round-high',
        errors: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(course: course, courseCode: 'IT'),
        ),
      );
      await _pumpUntil(tester, find.text('Next Review'));

      expect(find.byType(RoundScreen), findsNothing);
      expect(find.text('Review completed!'), findsNothing);
      expect(find.textContaining('Congratulations'), findsNothing);
      expect(
        find.text('0 words to review in the next Review.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('review-reset-word-list')), findsOneWidget);
      expect(find.byKey(const Key('review-help')), findsOneWidget);

      await _tap(tester, 'Next Review');
      await _pumpUntil(tester, find.byType(RoundScreen));

      final round = tester.widget<RoundScreen>(find.byType(RoundScreen));
      expect(round.round.id, 'round-high');
      expect(round.lesson.lessonId, course.lessons.single.lessonId);
      expect(round.reviewMode, isTrue);
      expect(round.viewOnlyMode, isFalse);
    },
  );

  testWidgets('Review Round context wraps long custom titles without ellipsis', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(420, 760);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const courseTitle =
        'A deliberately long custom Course title that must remain completely visible';
    const lessonTitle =
        'A deliberately long Lesson title that wraps across the available width';
    const roundTitle =
        'A deliberately long Round title that is not replaced by an ellipsis';
    final course = _course(
      vocabulary: const [],
      includeLowRound: false,
      courseTitle: courseTitle,
      lessonTitle: lessonTitle,
      highRoundTitle: roundTitle,
    );
    await _seedReview(course, 'round-high', errors: 2);

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewScreen(course: course, courseCode: 'IT'),
      ),
    );
    await _startNextReview(tester);
    await _pumpUntil(tester, find.text('Correct round-high'));
    await tester.pumpAndSettle();

    final contextText = tester.widget<Text>(find.textContaining(courseTitle));
    expect(contextText.softWrap, isTrue);
    expect(contextText.overflow, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pre-Round cards reveal answers and persist both decisions', (
    tester,
  ) async {
    final course = _course();
    final lesson = course.lessons.single;
    await _seedReview(course, 'round-high', errors: 4);

    await tester.pumpWidget(
      MaterialApp(
        home: ReviewScreen(course: course, courseCode: 'IT'),
      ),
    );
    await _startNextReview(tester);
    await _pumpUntil(tester, find.text('Before the Round'));

    expect(find.text(course.title), findsOneWidget);
    expect(find.textContaining('Lesson 1'), findsOneWidget);
    expect(find.textContaining('Round 2'), findsOneWidget);
    expect(find.text('casa'), findsOneWidget);
    expect(find.text('house'), findsNothing);
    expect(find.text('I know it'), findsNothing);
    expect(find.text('Show it to me again'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await _tap(tester, 'Show answer');
    expect(find.text('house'), findsOneWidget);
    await _tap(tester, 'I know it');
    expect(find.text('pane'), findsOneWidget);
    await _tap(tester, 'Show answer');
    await _tap(tester, 'Show it to me again');
    await _pumpUntil(tester, find.byType(RoundScreen));

    final service = VocabularyReviewService();
    final entries = service.resolveEntries(course, lesson);
    expect(
      await service.stateFor(course.courseId, lesson.lessonId, entries.first),
      const VocabularyReviewState(encountered: true),
    );
    expect(
      await service.stateFor(course.courseId, lesson.lessonId, entries.last),
      const VocabularyReviewState(encountered: true, needsReinforcement: true),
    );
  });

  testWidgets(
    'post-Round repeats only requested words and Next skips known words',
    (tester) async {
      final course = _course();
      final lesson = course.lessons.single;
      await _seedReview(course, 'round-high', errors: 5);
      await _seedReview(course, 'round-low', errors: 1);
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(course: course, courseCode: 'IT'),
        ),
      );

      await _startNextReview(tester);
      await _pumpUntil(tester, find.text('Before the Round'));
      await _tap(tester, 'Show answer');
      await _tap(tester, 'I know it');
      await _tap(tester, 'Show answer');
      await _tap(tester, 'Show it to me again');
      await _completeCurrentRound(tester, 'round-high');

      await _pumpUntil(tester, find.text('After the Round'));
      expect(find.text('pane'), findsOneWidget);
      expect(find.text('casa'), findsNothing);
      expect(find.text("I still don't know it"), findsNothing);
      await _tap(tester, 'Show answer');
      await _tap(tester, "I still don't know it");
      await _pumpUntil(tester, find.text('Review completed!'));

      await _tap(tester, 'Next Review');
      await _pumpUntil(tester, find.text('Before the Round'));
      expect(find.text('pane'), findsOneWidget);
      expect(find.text('casa'), findsNothing);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );

      final entries = VocabularyReviewService().resolveEntries(course, lesson);
      expect(
        (await VocabularyReviewService().stateFor(
          course.courseId,
          lesson.lessonId,
          entries.last,
        )).needsReinforcement,
        isTrue,
      );
    },
  );

  testWidgets(
    'Next Review consumes the exact eligible vocabulary list already counted',
    (tester) async {
      final course = _course();
      final lesson = course.lessons.single;
      final vocabulary = VocabularyReviewService();
      final entries = vocabulary.resolveEntries(course, lesson);
      await _seedReview(course, 'round-high', errors: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(course: course, courseCode: 'IT'),
        ),
      );
      await _pumpUntil(
        tester,
        find.text('2 words to review in the next Review.'),
      );

      await vocabulary.markKnown(
        course.courseId,
        lesson.lessonId,
        entries.first,
      );
      await _tap(tester, 'Next Review');
      await _pumpUntil(tester, find.text('Before the Round'));

      expect(find.text('casa'), findsOneWidget);
      expect(find.text('Word 1 of 2'), findsOneWidget);
    },
  );

  testWidgets(
    'Reset Word List refreshes the cached next Review vocabulary count',
    (tester) async {
      final course = _course();
      final lesson = course.lessons.single;
      final vocabulary = VocabularyReviewService();
      final entries = vocabulary.resolveEntries(course, lesson);
      await vocabulary.markKnown(
        course.courseId,
        lesson.lessonId,
        entries.first,
      );
      await _seedReview(course, 'round-high', errors: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(course: course, courseCode: 'IT'),
        ),
      );
      await _pumpUntil(
        tester,
        find.text('1 word to review in the next Review.'),
      );

      await tester.tap(find.byKey(const Key('review-reset-word-list')));
      await tester.pumpAndSettle();
      await _tap(tester, 'Reset');
      await _pumpUntil(
        tester,
        find.text('2 words to review in the next Review.'),
      );
    },
  );

  testWidgets(
    'Next Review reports session exhaustion and keeps return action',
    (tester) async {
      final course = _course(vocabulary: const [], includeLowRound: false);
      await _seedReview(course, 'round-high', errors: 3);
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(course: course, courseCode: 'IT'),
        ),
      );
      await _startNextReview(tester);
      await _completeCurrentRound(tester, 'round-high');
      await _pumpUntil(tester, find.text('Review completed!'));

      await _tap(tester, 'Next Review');
      await _pumpUntil(
        tester,
        find.text('No more Rounds are available in this Review session.'),
      );
      expect(find.byKey(const Key('review-back-to-course')), findsOneWidget);
      expect(find.text('Next Review'), findsOneWidget);
      expect(find.textContaining('Word Review'), findsNothing);
    },
  );

  testWidgets(
    'Reset restarts preparation and Help describes Review boundaries',
    (tester) async {
      final course = _course();
      final lesson = course.lessons.single;
      final vocabulary = VocabularyReviewService();
      final entries = vocabulary.resolveEntries(course, lesson);
      await vocabulary.markKnown(
        course.courseId,
        lesson.lessonId,
        entries.first,
      );
      await _seedReview(course, 'round-high', errors: 2);
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(course: course, courseCode: 'IT'),
        ),
      );
      await _startNextReview(tester);
      await _pumpUntil(tester, find.text('Before the Round'));
      expect(find.text('pane'), findsOneWidget);
      expect(find.text('casa'), findsNothing);

      await tester.tap(find.byKey(const Key('review-help')));
      await tester.pumpAndSettle();
      expect(find.text('Review Help'), findsOneWidget);
      expect(find.textContaining('GuideBook Vocabulary'), findsOneWidget);
      expect(find.textContaining('separate XP'), findsOneWidget);
      await _tap(tester, 'Close');

      await tester.tap(find.byKey(const Key('review-reset-word-list')));
      await tester.pumpAndSettle();
      expect(find.text('Reset Word List?'), findsOneWidget);
      expect(
        find.text(
          'All vocabulary for this course will be treated as new again. '
          'Round Review and course progress will not be changed.',
        ),
        findsOneWidget,
      );
      await _tap(tester, 'Cancel');
      expect(find.text('pane'), findsOneWidget);

      await tester.tap(find.byKey(const Key('review-reset-word-list')));
      await tester.pumpAndSettle();
      await _tap(tester, 'Reset');
      await _pumpUntil(tester, find.text('casa'));
    },
  );

  testWidgets(
    'abandoning the Round returns to the Course and keeps decisions',
    (tester) async {
      final course = _course();
      final lesson = course.lessons.single;
      await _seedReview(course, 'round-high', errors: 4);
      await tester.pumpWidget(
        MaterialApp(home: _ReviewLauncher(course: course)),
      );
      await _tap(tester, 'Open Review');
      await _startNextReview(tester);
      await _pumpUntil(tester, find.text('Before the Round'));
      await _tap(tester, 'Show answer');
      await _tap(tester, 'I know it');
      await _tap(tester, 'Show answer');
      await _tap(tester, 'Show it to me again');
      await _pumpUntil(tester, find.byType(RoundScreen));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Course Learner Panel'), findsOneWidget);
      expect(find.byType(ReviewScreen), findsNothing);

      await _tap(tester, 'Open Review');
      await _startNextReview(tester);
      await _pumpUntil(tester, find.text('Before the Round'));
      expect(find.text('pane'), findsOneWidget);
      expect(find.text('casa'), findsNothing);
      final entries = VocabularyReviewService().resolveEntries(course, lesson);
      expect(
        await VocabularyReviewService().stateFor(
          course.courseId,
          lesson.lessonId,
          entries.last,
        ),
        const VocabularyReviewState(
          encountered: true,
          needsReinforcement: true,
        ),
      );
      expect(
        (await ProgressService().getRecentRounds(
          courseId: course.courseId,
        )).single.errors,
        4,
      );
    },
  );

  testWidgets('reset during post-Round discards pending reinforcement', (
    tester,
  ) async {
    final course = _course();
    final lesson = course.lessons.single;
    await _seedReview(course, 'round-high', errors: 4);
    await tester.pumpWidget(
      MaterialApp(
        home: ReviewScreen(course: course, courseCode: 'IT'),
      ),
    );
    await _startNextReview(tester);
    await _pumpUntil(tester, find.text('Before the Round'));
    await _tap(tester, 'Show answer');
    await _tap(tester, 'I know it');
    await _tap(tester, 'Show answer');
    await _tap(tester, 'Show it to me again');
    await _completeCurrentRound(tester, 'round-high');
    await _pumpUntil(tester, find.text('After the Round'));

    await tester.tap(find.byKey(const Key('review-reset-word-list')));
    await tester.pumpAndSettle();
    await _tap(tester, 'Reset');
    await _pumpUntil(tester, find.text('Review completed!'));
    expect(find.text('After the Round'), findsNothing);
    expect(
      await VocabularyReviewService().eligibleEntries(course, lesson),
      hasLength(2),
    );
  });

  testWidgets(
    'inter-review count updates for the next selected Round and Back exits',
    (tester) async {
      final course = _courseAcrossLessons();
      await _seedReview(
        course,
        'round-high',
        errors: 5,
        lessonId: 'priority-lesson',
      );
      await _seedReview(
        course,
        'round-low',
        errors: 1,
        lessonId: 'next-lesson',
      );
      await tester.pumpWidget(
        MaterialApp(home: _ReviewLauncher(course: course)),
      );

      await _tap(tester, 'Open Review');
      await _pumpUntil(
        tester,
        find.text('0 words to review in the next Review.'),
      );
      await _startNextReview(tester);
      await _completeCurrentRound(tester, 'round-high');
      await _pumpUntil(
        tester,
        find.text('4 words to review in the next Review.'),
      );
      expect(find.textContaining('7 words'), findsNothing);

      await _tap(tester, 'Back to Course');
      await tester.pumpAndSettle();
      await _pumpUntil(tester, find.text('Course Learner Panel'));
      expect(find.byType(ReviewScreen), findsNothing);
    },
  );
}

Future<void> _seedReview(
  Course course,
  String roundId, {
  required int errors,
  String? lessonId,
}) {
  return ProgressService().recordRecentRound(
    course.courseId,
    lessonId ?? course.lessons.single.lessonId,
    roundId,
    errors: errors,
  );
}

Future<void> _completeCurrentRound(WidgetTester tester, String roundId) async {
  await _pumpUntil(tester, find.text('Correct $roundId'));
  await _tap(tester, 'Correct $roundId');
  await _tap(tester, 'Finish round');
  await _pumpUntil(tester, find.text('Round completed'));
  await _tap(tester, 'Continue');
  await tester.pumpAndSettle();
}

Future<void> _startNextReview(WidgetTester tester) async {
  await _pumpUntil(tester, find.text('Next Review'));
  await _tap(tester, 'Next Review');
}

Future<void> _tap(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxFrames = 120,
}) async {
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for $finder. Visible text: $visible');
}

Course _course({
  List<LearningContent>? vocabulary,
  bool includeLowRound = true,
  String courseTitle = 'QQL 232 full Review Course title',
  String lessonTitle = 'Full Review Lesson title',
  String highRoundTitle = 'Higher priority Round',
}) {
  final rounds = [
    if (includeLowRound) _round('round-low', 'Lower priority Round'),
    _round('round-high', highRoundTitle),
  ];
  return Course(
    courseId: 'qql-232-review-course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: courseTitle,
    ttsLanguage: 'it-IT',
    lessons: [
      Lesson(
        lessonId: 'review-lesson',
        title: lessonTitle,
        guidebook: Guidebook(
          content:
              vocabulary ??
              const [
                LearningContent(
                  id: 'casa',
                  kind: 'vocabulary',
                  role: 'vocabulary',
                  text: 'casa = house',
                ),
                LearningContent(
                  id: 'pane',
                  kind: 'vocabulary',
                  role: 'vocabulary',
                  text: 'pane = bread',
                ),
              ],
        ),
        rounds: rounds,
      ),
    ],
  );
}

Course _courseAcrossLessons() => Course(
  courseId: 'qql-232-review-across-lessons',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Review across Lessons',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'priority-lesson',
      title: 'Priority Lesson',
      guidebook: Guidebook.empty(),
      rounds: [_round('round-high', 'Higher priority Round')],
    ),
    Lesson(
      lessonId: 'next-lesson',
      title: 'Next Lesson',
      guidebook: Guidebook(
        content: const [
          LearningContent(
            id: 'sole',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'sole = sun',
          ),
          LearningContent(
            id: 'luna',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'luna = moon',
          ),
          LearningContent(
            id: 'stella',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'stella = star',
          ),
          LearningContent(
            id: 'cielo',
            kind: 'vocabulary',
            role: 'vocabulary',
            text: 'cielo = sky',
          ),
        ],
      ),
      rounds: [_round('round-low', 'Lower priority Round')],
    ),
  ],
);

LearningRound _round(String id, String title) => LearningRound(
  id: id,
  title: title,
  exercises: [
    Exercise(
      id: '${id}_choice',
      type: 'choice',
      prompt: 'Choose the correct answer.',
      question: '',
      answers: ['Correct $id', 'Wrong $id'],
      correct: 0,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    ),
    if (id == 'round-low')
      Exercise(
        id: '${id}_second_choice',
        type: 'choice',
        prompt: 'Choose the second correct answer.',
        question: '',
        answers: ['Second correct $id', 'Second wrong $id'],
        correct: 0,
        tts: null,
        accepted: const [],
        tokens: const [],
        orderAnswer: const [],
        pairs: const [],
        hint: '',
        icons: const [],
      ),
  ],
);

class _ReviewLauncher extends StatelessWidget {
  const _ReviewLauncher({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const Text('Course Learner Panel'),
        FilledButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ReviewScreen(course: course, courseCode: 'IT'),
            ),
          ),
          child: const Text('Open Review'),
        ),
      ],
    ),
  );
}

void _installDesktopPluginMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => throw PlatformException(
      code: 'test_storage_unavailable',
      message: 'Persistent crash logging is unavailable in widget tests.',
    ),
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
        final playerId = arguments['playerId'] as String;
        _installEventChannelMock(
          messenger,
          'xyz.luan/audioplayers/events/$playerId',
        );
      }
      return null;
    },
  );
  _installEventChannelMock(messenger, 'xyz.luan/audioplayers.global/events');
}

void _installEventChannelMock(
  TestDefaultBinaryMessenger messenger,
  String channel,
) {
  messenger.setMockMessageHandler(channel, (message) async {
    return const StandardMethodCodec().encodeSuccessEnvelope(null);
  });
}
