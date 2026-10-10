import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/spoken_line_pace.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 269 Revision 0 (owner decisions of 10 October 2026): a Story line
/// that reads itself aloud shows at once, dimmer, its words become bright as
/// the time to say them passes, and Continue waits until the line has been
/// read. Lines not spoken, Play on request, reduced motion and a failing
/// voice keep or adapt the earlier behaviour.
final _stamp = DateTime.utc(2026, 10, 10);

const _sentence = 'Buongiorno! Un caffè, per favore.';

/// A voice that takes [duration] of the test's time, or fails.
class _Speech extends TtsCacheService {
  _Speech({this.duration = Duration.zero, this.ok = true});

  final Duration duration;
  final bool ok;
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
    if (duration > Duration.zero) await Future<void>.delayed(duration);
    return ok;
  }

  @override
  Future<void> stop() async {}
}

/// A stopwatch on the test's clock.
class _TestWatch implements Stopwatch {
  _TestWatch(this._now);

  final DateTime Function() _now;
  DateTime? _started;

  @override
  void start() => _started ??= _now();

  @override
  Duration get elapsed =>
      _started == null ? Duration.zero : _now().difference(_started!);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

Exercise _line(
  String id,
  String text, {
  String mode = 'both',
  String readAloud = 'story',
  String reveal = 'immediate',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank(id),
    type: 'dialogue_line',
    publicationState: PublicationState.published,
    prompt: text,
    speakerId: 'character_anna',
    lineMode: mode,
    lineReadAloud: readAloud,
    lineTextReveal: reveal,
  ),
).candidate!;

Exercise _question() => Exercise.canonical(
  id: 'q1',
  primitive: ExercisePrimitive.select,
  promptElements: [PromptElement(type: 'text', text: 'What did Anna order?')],
  items: [
    ExerciseItem(
      id: 'q1_a',
      content: [PromptElement(type: 'text', text: 'A coffee')],
    ),
    ExerciseItem(
      id: 'q1_b',
      content: [PromptElement(type: 'text', text: 'Tea')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['q1_a'],
  ),
  updatedAt: _stamp,
);

LearningRound _story(
  Exercise line, {
  FlowReadAloud readAloud = FlowReadAloud.automatic,
}) {
  final content = [
    for (final exercise in [line, _question()])
      LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: 'story',
    title: 'Story: Al bar',
    visualType: 'story',
    updatedAt: _stamp,
    content: content,
    flow: RoundFlowAuthoring.linearFor(
      content,
      title: 'Al bar',
      readAloud: readAloud,
    ),
  );
}

Course _course(LearningRound round) => Course(
  courseId: 'spoken-lines-course',
  title: 'Spoken lines',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  storyCharacters: const [
    StorySpeaker(
      id: 'character_anna',
      name: 'Anna',
      language: TextLanguage.target,
    ),
  ],
  lessons: [
    Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
  ],
);

void _platforms() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => testSupportDirectory.path,
      );
}

final _continue = find.byKey(const Key('story-line-continue'));
final _spoken = find.byKey(const Key('story-line-spoken'));

bool _continueEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_continue).onPressed != null;

/// The bright beginning of the line being read.
String _bright(WidgetTester tester) {
  final text = tester.widget<Text>(_spoken);
  final children = (text.textSpan! as TextSpan).children!;
  return (children.first as TextSpan).text!;
}

Future<_Speech> _pump(
  WidgetTester tester,
  LearningRound round, {
  _Speech? speech,
  bool reducedMotion = false,
  bool preview = true,
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final course = _course(round);
  final voice = speech ?? _Speech();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: preview,
        ttsCacheService: voice,
      ),
    ),
  );
  // The Round prepares itself (preferences, the Audit) in real time.
  for (var i = 0; i < 200 && _continue.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(_continue, findsOneWidget);
  // The line's audio starts once the line is active.
  await tester.pump();
  await tester.pump();
  return voice;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Spoken learner');
    _platforms();
    keepCrashLogUnavailable();
    SpokenLinePace.shared.reset();
  });

  tearDown(() {
    RoundScreen.lineStopwatch = Stopwatch.new;
    SpokenLinePace.shared.reset();
  });

  void useTestClock(WidgetTester tester) {
    RoundScreen.lineStopwatch = () => _TestWatch(tester.binding.clock.now);
  }

  group('SpokenLinePace', () {
    test('a usual pace, a shortest line and the measured pace', () {
      final pace = SpokenLinePace();
      expect(pace.charactersPerSecond, 12);
      expect(pace.estimate('a' * 24), const Duration(seconds: 2));
      expect(pace.estimate('Sì.'), SpokenLinePace.shortestLine);
      pace.record('a' * 30, const Duration(seconds: 3));
      expect(pace.charactersPerSecond, 10);
      expect(pace.estimate('a' * 20), const Duration(seconds: 2));
      pace.record('a' * 970, const Duration(seconds: 1));
      expect(
        pace.charactersPerSecond,
        SpokenLinePace.fastestCharactersPerSecond,
      );
      pace.reset();
      pace.record('a' * 6, const Duration(seconds: 10));
      expect(
        pace.charactersPerSecond,
        SpokenLinePace.slowestCharactersPerSecond,
      );
      // Nothing to measure.
      pace.reset();
      pace.record('   ', const Duration(seconds: 1));
      pace.record('abc', Duration.zero);
      expect(pace.charactersPerSecond, 12);
    });

    test('an end reported too early is not the real end', () {
      const estimate = Duration(seconds: 10);
      expect(
        SpokenLinePace.isRealEnd(const Duration(seconds: 3), estimate),
        isFalse,
      );
      expect(
        SpokenLinePace.isRealEnd(const Duration(seconds: 4), estimate),
        isTrue,
      );
      expect(
        SpokenLinePace.isRealEnd(const Duration(seconds: 12), estimate),
        isTrue,
      );
    });
  });

  group('SpokenLineWords', () {
    test('words with their punctuation brighten in turn', () {
      expect(SpokenLineWords.brightLength(_sentence, 0), 'Buongiorno!'.length);
      expect(
        SpokenLineWords.brightLength(_sentence, 12 / _sentence.length),
        'Buongiorno! Un'.length,
      );
      expect(
        SpokenLineWords.brightLength(_sentence, 15 / _sentence.length),
        'Buongiorno! Un caffè,'.length,
      );
      expect(SpokenLineWords.brightLength(_sentence, .99), _sentence.length);
      expect(SpokenLineWords.brightLength(_sentence, 1), _sentence.length);
      expect(SpokenLineWords.brightLength('', .5), 0);
      expect(SpokenLineWords.brightLength('  Ciao', 0), 0);
    });
  });

  group('a line reading itself aloud', () {
    testWidgets('shows dim, brightens word by word, and Continue waits for '
        'the voice', (tester) async {
      useTestClock(tester);
      // 33 characters at 12 a second: 2.75 seconds; the voice takes 3.
      final speech = await _pump(
        tester,
        _story(_line('l1', _sentence)),
        speech: _Speech(duration: const Duration(seconds: 3)),
      );
      expect(speech.spoken, [_sentence]);
      expect(_spoken, findsOneWidget);
      expect(
        find.text(_sentence),
        findsOneWidget,
        reason: 'the whole line shows at once',
      );
      expect(_bright(tester), 'Buongiorno!');
      // The words still to come are dimmer than the bright ones.
      final spans = (tester.widget<Text>(_spoken).textSpan! as TextSpan)
          .children!
          .cast<TextSpan>();
      expect(spans.first.style?.color, isNull, reason: 'the line colour');
      expect(spans.last.text, ' Un caffè, per favore.');
      expect(spans.last.style!.color!.a, lessThan(.5));
      expect(_continueEnabled(tester), isFalse);

      await tester.pump(const Duration(milliseconds: 1500));
      final bright = _bright(tester);
      expect(bright.length, greaterThan('Buongiorno!'.length));
      expect(bright.length, lessThan(_sentence.length));
      expect(_sentence.startsWith(bright), isTrue);
      expect(_continueEnabled(tester), isFalse);

      // Every word is bright: the line's ordinary text again, but the voice
      // is still speaking.
      await tester.pump(const Duration(milliseconds: 1300));
      expect(_spoken, findsNothing);
      expect(find.text(_sentence), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);

      await tester.pump(const Duration(milliseconds: 300));
      expect(_continueEnabled(tester), isTrue);
      // The voice's real end measured the pace: 33 characters in 3 seconds.
      expect(SpokenLinePace.shared.charactersPerSecond, closeTo(11, .01));

      await tester.tap(_continue);
      await tester.pumpAndSettle();
      expect(find.text('What did Anna order?'), findsOneWidget);
    });

    testWidgets('a voice that ends before the estimate brightens the rest at '
        'once', (tester) async {
      useTestClock(tester);
      await _pump(
        tester,
        _story(_line('l1', _sentence)),
        speech: _Speech(duration: const Duration(seconds: 2)),
      );
      await tester.pump(const Duration(milliseconds: 1950));
      expect(_continueEnabled(tester), isFalse);
      expect(_bright(tester).length, lessThan(_sentence.length));
      await tester.pump(const Duration(milliseconds: 100));
      expect(_continueEnabled(tester), isTrue);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_spoken, findsNothing);
      expect(find.text(_sentence), findsOneWidget);
    });

    testWidgets('a voice that returns at once leaves the line to its '
        'estimate', (tester) async {
      useTestClock(tester);
      await _pump(tester, _story(_line('l1', _sentence)));
      await tester.pump(const Duration(seconds: 1));
      expect(_continueEnabled(tester), isFalse);
      expect(_spoken, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1800));
      expect(find.text(_sentence), findsOneWidget);
      expect(_continueEnabled(tester), isTrue);
      expect(
        SpokenLinePace.shared.charactersPerSecond,
        SpokenLinePace.defaultCharactersPerSecond,
        reason: 'an end reported too early is not measured',
      );
    });

    testWidgets('a voice that fails shows the line and frees Continue', (
      tester,
    ) async {
      useTestClock(tester);
      await _pump(
        tester,
        _story(_line('l1', _sentence)),
        speech: _Speech(ok: false),
      );
      expect(_continueEnabled(tester), isTrue);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_sentence), findsOneWidget);
      // The failure says so, as before.
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('with reduced motion the line shows whole and Continue still '
        'waits', (tester) async {
      useTestClock(tester);
      await _pump(
        tester,
        _story(_line('l1', _sentence)),
        speech: _Speech(duration: const Duration(seconds: 3)),
        reducedMotion: true,
      );
      expect(_spoken, findsNothing);
      expect(find.text(_sentence), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 3100));
      expect(_continueEnabled(tester), isTrue);
    });

    testWidgets('text shown after listening waits whole for the voice', (
      tester,
    ) async {
      useTestClock(tester);
      await _pump(
        tester,
        _story(_line('l1', _sentence, reveal: 'afterAudio')),
        speech: _Speech(duration: const Duration(seconds: 3)),
      );
      expect(find.text('Listen first…'), findsOneWidget);
      expect(_spoken, findsNothing);
      expect(_continueEnabled(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 3100));
      expect(find.text(_sentence), findsOneWidget);
      expect(_spoken, findsNothing);
      expect(_continueEnabled(tester), isTrue);
    });

    testWidgets('an audio-only line holds Continue until it is read', (
      tester,
    ) async {
      useTestClock(tester);
      await _pump(
        tester,
        _story(_line('l1', _sentence, mode: 'audio')),
        speech: _Speech(duration: const Duration(seconds: 3)),
      );
      expect(find.text('Listen…'), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 3100));
      expect(_continueEnabled(tester), isTrue);
    });
  });

  group('lines that do not read themselves aloud', () {
    testWidgets('Play on request changes nothing', (tester) async {
      useTestClock(tester);
      final speech = await _pump(
        tester,
        _story(_line('l1', _sentence), readAloud: FlowReadAloud.manual),
        speech: _Speech(duration: const Duration(seconds: 3)),
      );
      expect(speech.spoken, isEmpty);
      expect(find.text(_sentence), findsOneWidget);
      expect(_continueEnabled(tester), isTrue);
      await tester.tap(find.byKey(const Key('story-line-play')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(speech.spoken, [_sentence]);
      expect(_spoken, findsNothing);
      expect(find.text(_sentence), findsOneWidget);
      expect(_continueEnabled(tester), isTrue);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('with the learner\'s audio off the line shows at once', (
      tester,
    ) async {
      // Audio Exercises and Text-to-speech are off for a new learner.
      await _pump(tester, _story(_line('l1', _sentence)), preview: false);
      expect(_spoken, findsNothing);
      expect(find.text(_sentence), findsOneWidget);
      expect(_continueEnabled(tester), isTrue);
    });
  });
  // Build 270 Revision 2 (audit item 3).
  group('a voice that misbehaves', () {
    testWidgets('one that never reports its end frees Continue after twice '
        'the estimate and the slack, and teaches no pace', (tester) async {
      useTestClock(tester);
      final speech = _Endless();
      await _pump(tester, _story(_line('l1', _sentence)), speech: speech);
      expect(_continueEnabled(tester), isFalse);
      // 33 characters at 12 a second: 2.75 s; released at 5.5 s + 5 s.
      await tester.pump(const Duration(seconds: 10));
      expect(_continueEnabled(tester), isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(_continueEnabled(tester), isTrue);
      speech.finish();
      await tester.pump();
      expect(SpokenLinePace.shared.charactersPerSecond, 12);
      expect(_continueEnabled(tester), isTrue);
    });

    testWidgets('Play waits while the line reads itself aloud', (tester) async {
      useTestClock(tester);
      await _pump(
        tester,
        _story(_line('l1', _sentence)),
        speech: _Speech(duration: const Duration(seconds: 3)),
      );
      final play = find.byKey(const Key('story-line-play'));
      expect(tester.widget<IconButton>(play).onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 3100));
      expect(tester.widget<IconButton>(play).onPressed, isNotNull);
    });

    testWidgets('audio still playing when the learner goes on reveals nothing '
        'on the next line', (tester) async {
      useTestClock(tester);
      const second = 'Ecco il suo caffè.';
      final speech = await _pump(
        tester,
        _twoLines(
          _line('l1', _sentence),
          _line('l2', second, reveal: 'afterAudio'),
        ),
        speech: _Speech(duration: const Duration(seconds: 3)),
      );
      await tester.tap(find.byKey(const Key('story-line-play')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(speech.spoken, [_sentence]);
      await tester.tap(_continue);
      await tester.pump();
      await tester.pump();
      expect(find.text(second), findsNothing);
      // The first line's audio ends now.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text(second), findsNothing);
    });
  });
}

/// A voice that starts and never reports its end until [finish].
class _Endless extends _Speech {
  final _end = Completer<bool>();

  void finish() => _end.complete(true);

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) => _end.future;

  @override
  Future<void> stop() async {}
}

/// Two lines read on request, the second shown after listening.
LearningRound _twoLines(Exercise first, Exercise second) {
  final content = [
    for (final exercise in [first, second, _question()])
      LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: 'story',
    title: 'Story: Al bar',
    visualType: 'story',
    updatedAt: _stamp,
    content: content,
    flow: RoundFlowAuthoring.linearFor(
      content,
      title: 'Al bar',
      readAloud: FlowReadAloud.manual,
    ),
  );
}
