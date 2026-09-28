import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/portable_exercise_image.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/widgets/portable_exercise_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 5, Stage 2: a Story plays its cover and dialogue
/// lines (avatar, name, bubble, read-aloud in the speaker's language and
/// voice, text after listening), keeps only the dialogue in the scrolling
/// log, never skips a line when audio is off, skips an exercise that needs
/// the Story's audio, and keeps its exercises out of the Duel.
final _stamp = DateTime.utc(2026, 9, 28);

class _Speech extends TtsCacheService {
  final spoken = <({String text, String language, String? voice})>[];

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
    spoken.add((text: text, language: language, voice: voicePreference));
    return true;
  }

  @override
  Future<void> stop() async {}
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
  String speakerId = '',
  String mode = 'both',
  String readAloud = 'story',
  String reveal = 'immediate',
}) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank(id),
    type: 'dialogue_line',
    publicationState: PublicationState.published,
    prompt: text,
    speakerId: speakerId,
    lineMode: mode,
    lineReadAloud: readAloud,
    lineTextReveal: reveal,
  ),
).candidate!;

Exercise _cover(String id) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank(id),
    type: 'story_cover',
    publicationState: PublicationState.published,
    prompt: 'A morning in Turin',
    imageAsset: 'assets/avatars/robot.png',
  ),
).candidate!;

Exercise _select(String id, String question) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  promptElements: [PromptElement(type: 'text', text: question)],
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

LearningRound _story({
  FlowReadAloud readAloud = FlowReadAloud.automatic,
  FlowLog log = FlowLog.dialogue,
}) {
  final content = [
    for (final exercise in [
      _cover('cov'),
      _line('n1', 'Anna walks into the café.'),
      _line(
        'a1',
        'Buongiorno! Un caffè, per favore.',
        speakerId: 'character_anna',
        readAloud: 'manual',
        reveal: 'afterAudio',
      ),
      _line('a2', 'Grazie.', speakerId: 'character_anna', mode: 'audio'),
      _select('q1', 'What did Anna order?'),
      _select('q2', 'Where is Anna?'),
    ])
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
      presentation: FlowPresentation.scroll,
      title: 'Al bar',
      log: log,
      readAloud: readAloud,
      requiresAudio: {'q1'},
    ),
  );
}

Course _course(LearningRound round) => Course(
  courseId: 'story-runtime-course',
  title: 'Story course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  storyNarrator: const StorySpeaker(
    name: 'Narrator',
    language: TextLanguage.source,
  ),
  storyCharacters: const [
    StorySpeaker(
      id: 'character_anna',
      name: 'Anna',
      avatar: 'assets/avatars/cat.png',
      language: TextLanguage.target,
      voice: StoryVoice.female,
    ),
  ],
  lessons: [
    Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
  ],
);

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

Future<_Speech> _pump(
  WidgetTester tester,
  LearningRound round, {
  required bool preview,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final course = _course(round);
  final speech = _Speech();
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: preview,
        ttsCacheService: speech,
      ),
    ),
  );
  await _until(tester, find.byKey(const Key('story-cover-title')));
  return speech;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Story learner');
    _platforms();
    keepCrashLogUnavailable();
  });

  testWidgets('cover, lines, read-aloud, text after listening, dialogue log', (
    tester,
  ) async {
    final speech = await _pump(tester, _story(), preview: true);
    expect(find.text('Al bar'), findsWidgets);
    expect(find.text('A morning in Turin'), findsOneWidget);
    expect(find.text('Story · 6 steps'), findsOneWidget);
    // The cover card draws the picture once; the shared illustration of
    // ordinary exercises stays out (owner report, 28 September 2026).
    expect(find.byType(PortableExerciseImage), findsOneWidget);
    expect(find.byKey(const Key('exercise-image')), findsNothing);
    await _tap(tester, find.byKey(const Key('story-cover-continue')));

    // The narrator's line is read aloud by itself, in the source language,
    // with no voice preference.
    await _until(tester, find.text('Anna walks into the café.'));
    expect(find.byKey(const Key('story-line-narrator')), findsOneWidget);
    expect(find.text('Narrator'), findsOneWidget);
    expect(find.text('Read or listen, then continue.'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(speech.spoken, hasLength(1));
    expect(speech.spoken.single.text, 'Anna walks into the café.');
    expect(speech.spoken.single.language.toLowerCase(), startsWith('en'));
    expect(speech.spoken.single.voice, isNull);
    await _tap(tester, find.byKey(const Key('story-line-continue')));

    // Anna's line waits for the audio: on request, then the text appears,
    // spoken in the target language with the female voice.
    await _until(tester, find.byKey(const Key('story-line-bubble')));
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Listen first; the text appears after.'), findsOneWidget);
    // Anna's bundled avatar is drawn as the asset it is: the portable
    // decoder used to refuse assets/avatars and draw a broken image.
    expect(
      PortableExerciseImageService.decode('assets/avatars/cat.png'),
      isNull,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/avatars/cat.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Listen first…'), findsOneWidget);
    expect(find.text('Buongiorno! Un caffè, per favore.'), findsNothing);
    expect(speech.spoken, hasLength(1), reason: 'manual read-aloud');
    await _tap(tester, find.byKey(const Key('story-line-play')));
    expect(speech.spoken, hasLength(2));
    expect(speech.spoken.last.text, 'Buongiorno! Un caffè, per favore.');
    expect(speech.spoken.last.language.toLowerCase(), startsWith('it'));
    expect(speech.spoken.last.voice, 'female');
    expect(find.text('Buongiorno! Un caffè, per favore.'), findsOneWidget);
    await _tap(tester, find.byKey(const Key('story-line-continue')));

    // The audio-only line shows no text while it is active; the log shows
    // its transcript afterwards. The cover and every line are in the log.
    await _until(tester, find.text('Listen…'));
    expect(find.text('Grazie.'), findsNothing);
    await _tap(tester, find.byKey(const Key('story-line-continue')));
    await _until(tester, find.text('What did Anna order?'));
    expect(find.text('Grazie.'), findsOneWidget);
    expect(find.text('Now · step 5 of 6'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(ValueKey('story-entry-$i')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('story-entry-4')), findsNothing);

    // An exercise is answered as usual and leaves the dialogue log.
    await _tap(tester, find.widgetWithText(FilledButton, 'Right q1'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await _until(tester, find.text('Where is Anna?'));
    expect(find.byKey(const ValueKey('story-entry-4')), findsNothing);
    expect(find.text('What did Anna order?'), findsNothing);
    expect(find.text('Anna walks into the café.'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Right q2'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Finish story'));
    await _until(tester, find.text('Preview complete'));
  });

  testWidgets('the full log keeps the exercises too', (tester) async {
    await _pump(tester, _story(log: FlowLog.all), preview: true);
    await _tap(tester, find.byKey(const Key('story-cover-continue')));
    await _until(tester, find.byKey(const Key('story-line-continue')));
    await _tap(tester, find.byKey(const Key('story-line-continue')));
    await _until(tester, find.byKey(const Key('story-line-continue')));
    await _tap(tester, find.byKey(const Key('story-line-continue')));
    await _until(tester, find.byKey(const Key('story-line-continue')));
    await _tap(tester, find.byKey(const Key('story-line-continue')));
    await _until(tester, find.text('What did Anna order?'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Right q1'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await _until(tester, find.text('Where is Anna?'));
    expect(find.byKey(const ValueKey('story-entry-4')), findsOneWidget);
    expect(find.text('What did Anna order?'), findsOneWidget);
  });

  testWidgets('a Story whose read-aloud is on request stays silent', (
    tester,
  ) async {
    final speech = await _pump(
      tester,
      _story(readAloud: FlowReadAloud.manual),
      preview: true,
    );
    await _tap(tester, find.byKey(const Key('story-cover-continue')));
    await _until(tester, find.text('Anna walks into the café.'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(speech.spoken, isEmpty);
    await _tap(tester, find.byKey(const Key('story-line-play')));
    expect(speech.spoken, hasLength(1));
  });

  testWidgets('with audio off no line is skipped and the transcript shows', (
    tester,
  ) async {
    // Audio Exercises and TTS are off for a new learner.
    await _pump(tester, _story(), preview: false);
    expect(
      find.text('Story · 5 steps'),
      findsOneWidget,
      reason: 'cover, three lines and q2; q1 needs the Story audio',
    );
    await _tap(tester, find.byKey(const Key('story-cover-continue')));
    await _until(tester, find.text('Anna walks into the café.'));
    expect(find.byKey(const Key('story-line-audio-note')), findsOneWidget);
    await _tap(tester, find.byKey(const Key('story-line-continue')));
    await _until(tester, find.text('Buongiorno! Un caffè, per favore.'));
    expect(find.text('Listen first…'), findsNothing);
    await _tap(tester, find.byKey(const Key('story-line-continue')));
    await _until(tester, find.text('Grazie.'));
    expect(
      find.byKey(const Key('story-line-audio-note')),
      findsOneWidget,
      reason: 'the audio-only line shows its transcript and the note',
    );
    await _tap(tester, find.byKey(const Key('story-line-continue')));
    await _until(tester, find.text('Where is Anna?'));
    expect(find.text('What did Anna order?'), findsNothing);
  });

  test('Story exercises never enter the Duel pool', () {
    final story = _story();
    final practice = LearningRound(
      id: 'practice',
      title: 'Practice',
      updatedAt: _stamp,
      exercises: [for (var i = 0; i < 3; i++) _select('p$i', 'Question $i')],
    );
    final lesson = Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: [story, practice],
    );
    final result = const DuelEligibilityService().evaluate(lesson);
    expect(result.candidates.map((c) => c.exercise.id), ['p0', 'p1', 'p2']);
  });
}
