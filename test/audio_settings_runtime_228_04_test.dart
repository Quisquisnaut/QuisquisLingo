import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/screens/tts_settings_screen.dart';
import 'package:quisquislingo_app/services/audio_diagnostic_service.dart';
import 'package:quisquislingo_app/services/diagnostic_log_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => throw PlatformException(code: 'test-storage'),
        );
  });

  test(
    '228 correction Enable Audio Exercises is per learner and defaults off',
    () async {
      final profiles = ProfileService();
      final settings = SettingsService();
      await profiles.addProfile('Audio Learner A');
      final learnerAId = (await profiles.getActiveProfileId())!;
      expect(await settings.areAudioExercisesEnabled(), isFalse);
      expect(await settings.isTtsEnabled(), isFalse);
      await settings.setAudioExercisesEnabled(true);
      await settings.setTtsEnabled(true);
      await settings.setTtsVoicePreference('female');

      await profiles.addProfile('Audio Learner B');
      expect(await settings.areAudioExercisesEnabled(), isFalse);
      expect(await settings.isTtsEnabled(), isFalse);
      expect(await settings.getTtsVoicePreference(), 'system');
      await profiles.setActiveProfile('Audio Learner A');
      expect(await SettingsService().areAudioExercisesEnabled(), isTrue);
      expect(await SettingsService().isTtsEnabled(), isTrue);
      expect(await SettingsService().getTtsVoicePreference(), 'female');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool(
          profiles.keyForProfileId(learnerAId, 'audio_exercises_enabled'),
        ),
        isTrue,
      );
      expect(prefs.get('audio_exercises_enabled'), isNull);
      expect(prefs.get('tts_enabled'), isNull);
      expect(prefs.get('tts_voice_preference'), isNull);
      expect(prefs.get('skip_tts_exercises'), isNull);
    },
  );

  test('228 correction is a clean per-learner audio-settings cut', () async {
    final profiles = ProfileService();
    final settings = SettingsService();
    await profiles.addProfile('Compatibility Learner');
    final learnerId = (await profiles.getActiveProfileId())!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      profiles.keyForProfileId(learnerId, 'skip_all_audio_exercises'),
      false,
    );
    await prefs.setBool('tts_enabled', true);
    await prefs.setString('tts_voice_preference', 'female');
    expect(await settings.areAudioExercisesEnabled(), isFalse);
    expect(await settings.isTtsEnabled(), isFalse);
    expect(await settings.getTtsVoicePreference(), 'system');

    await settings.setAudioExercisesEnabled(true);
    await settings.setTtsEnabled(true);
    await settings.setTtsVoicePreference('male');
    expect(await settings.areAudioExercisesEnabled(), isTrue);
    expect(await settings.isTtsEnabled(), isTrue);
    expect(await settings.getTtsVoicePreference(), 'male');
    expect(
      prefs.getBool(profiles.keyForProfileId(learnerId, 'tts_enabled')),
      isTrue,
    );
    expect(
      prefs.getString(
        profiles.keyForProfileId(learnerId, 'tts_voice_preference'),
      ),
      'male',
    );
    expect(prefs.getBool('tts_enabled'), isTrue);
    expect(prefs.getString('tts_voice_preference'), 'female');
    expect(
      prefs.getBool(
        profiles.keyForProfileId(learnerId, 'skip_all_audio_exercises'),
      ),
      isFalse,
    );
  });

  test('228.04 missing recorded assets resolve unavailable', () async {
    final source = await RecordedAudioService().resolveSourceForClip(
      const CourseAudioClip(
        id: 'missing-runtime-audio',
        text: 'missing',
        filePath: 'assets/audio/does_not_exist_228.mp3',
      ),
    );
    expect(source, isNull);
  });

  testWidgets(
    '228 correction Audio Settings keeps the requested controls and Test Voice',
    (tester) async {
      await ProfileService().addProfile('Audio Settings Learner');
      await tester.pumpWidget(
        MaterialApp(home: TtsSettingsScreen(course: _audioFixture.course)),
      );
      await tester.pumpAndSettle();

      final audio = find.widgetWithText(
        SwitchListTile,
        'Enable Audio Exercises',
      );
      final tts = find.widgetWithText(SwitchListTile, 'Text-to-speech');
      final voice = find.byType(DropdownButtonFormField<String>);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      expect(voice, findsOneWidget);
      expect(find.text('Test Voice'), findsOneWidget);
      expect(find.text('Skip All Audio Exercises'), findsNothing);
      expect(find.text('Skip all TTS exercises'), findsNothing);
      expect(tester.getTopLeft(audio).dy, lessThan(tester.getTopLeft(tts).dy));
      expect(tester.getTopLeft(tts).dy, lessThan(tester.getTopLeft(voice).dy));
      expect(
        tester.getTopLeft(voice).dy,
        lessThan(tester.getTopLeft(find.text('Test Voice')).dy),
      );
    },
  );

  testWidgets(
    '228 correction disabled audio excludes recorded exercises before infrastructure work',
    (tester) async {
      final recorded = _CountingRecordedAudio();
      final tts = _CountingTts();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: false, ttsEnabled: true),
        recorded: recorded,
        tts: tts,
      );

      expect(
        find.text(
          'All exercises in this round use audio and Audio Exercises are disabled.',
        ),
        findsOneWidget,
      );
      expect(recorded.segmentCalls, 0);
      expect(recorded.sourceCalls, 0);
      expect(recorded.playCalls, 0);
      expect(tts.speakCalls, 0);
    },
  );

  testWidgets(
    '228 correction disabled audio excludes TTS exercises before playback',
    (tester) async {
      final recorded = _CountingRecordedAudio();
      final tts = _CountingTts();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: false, ttsEnabled: true),
        recorded: recorded,
        tts: tts,
        fixture: _ttsAudioFixture,
      );

      expect(
        find.text(
          'All exercises in this round use audio and Audio Exercises are disabled.',
        ),
        findsOneWidget,
      );
      expect(recorded.segmentCalls, 0);
      expect(recorded.playCalls, 0);
      expect(tts.speakCalls, 0);
    },
  );

  testWidgets(
    '228.04 unavailable recorded audio is excluded before playback initialization',
    (tester) async {
      final recorded = _CountingRecordedAudio(sourceAvailable: false);
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: true, ttsEnabled: true),
        recorded: recorded,
        tts: _CountingTts(),
      );

      expect(
        find.text(
          'All audio exercises in this round are currently unavailable.',
        ),
        findsOneWidget,
      );
      expect(recorded.segmentCalls, 1);
      expect(recorded.sourceCalls, 1);
      expect(recorded.playCalls, 0);
    },
  );

  testWidgets(
    '228 correction enabled audio admits available recorded exercises',
    (tester) async {
      final recorded = _CountingRecordedAudio();
      final tts = _CountingTts();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: true, ttsEnabled: false),
        recorded: recorded,
        tts: tts,
      );

      expect(find.text('What do you hear?'), findsWidgets);
      expect(recorded.segmentCalls, 1);
      expect(recorded.sourceCalls, 1);
      expect(recorded.playCalls, 1);
      expect(tts.speakCalls, 0);
    },
  );

  testWidgets(
    '228 correction Before you start suppresses TTS until the exercise is active',
    (tester) async {
      final tts = _CountingTts();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: true, ttsEnabled: true),
        recorded: _CountingRecordedAudio(),
        tts: tts,
        fixture: _ttsIntroAudioFixture,
      );

      expect(find.text('Before you start'), findsOneWidget);
      expect(tts.speakCalls, 0);

      await tester.tap(find.text('Continue to Round'));
      await _pumpFrames(tester);

      expect(find.text('Before you start'), findsNothing);
      expect(find.text('What do you hear?'), findsWidgets);
      expect(tts.speakCalls, 1);
    },
  );

  testWidgets(
    '228 correction Before you start suppresses recorded audio until the exercise is active',
    (tester) async {
      final recorded = _CountingRecordedAudio();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: true, ttsEnabled: false),
        recorded: recorded,
        tts: _CountingTts(),
        fixture: _recordedIntroAudioFixture,
      );

      expect(find.text('Before you start'), findsOneWidget);
      expect(recorded.playCalls, 0);

      await tester.tap(find.text('Continue to Round'));
      await _pumpFrames(tester);

      expect(find.text('Before you start'), findsNothing);
      expect(find.text('What do you hear?'), findsWidgets);
      expect(recorded.playCalls, 1);
    },
  );

  testWidgets(
    '228 correction diagnostics order preparation suppression activation and playback',
    (tester) async {
      final tts = _CountingTts();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: true, ttsEnabled: true),
        recorded: _CountingRecordedAudio(),
        tts: tts,
        fixture: _ttsIntroAudioFixture,
      );

      final prefs = await SharedPreferences.getInstance();
      final before = prefs.getString('quisquislingo_diagnostic_log') ?? '';
      final preparedAt = before.indexOf(
        'kind=round_activation phase=preparation outcome=prepared',
      );
      final sourceAt = before.indexOf(
        'kind=round_activation phase=source_resolution '
        'outcome=eligibility_confirmed',
      );
      final suppressedAt = before.indexOf(
        'kind=round_activation phase=playback '
        'outcome=suppressed_not_active',
      );
      expect(preparedAt, greaterThanOrEqualTo(0));
      expect(sourceAt, greaterThan(preparedAt));
      expect(suppressedAt, greaterThan(sourceAt));
      expect(before, contains('uiState=before_you_start'));
      expect(before, contains('targetExerciseId=recorded-listening'));
      expect(before, contains('exerciseType=listening_choice'));
      expect(before, contains('prepared=true active=false'));

      await tester.tap(find.text('Continue to Round'));
      await _pumpFrames(tester);

      final after = prefs.getString('quisquislingo_diagnostic_log') ?? '';
      final activeAt = after.indexOf(
        'kind=round_activation phase=activation outcome=active',
      );
      final requestedAt = after.indexOf(
        'kind=round_activation phase=playback outcome=requested',
      );
      final completedAt = after.indexOf(
        'kind=round_activation phase=playback outcome=completed',
      );
      expect(activeAt, greaterThan(suppressedAt));
      expect(requestedAt, greaterThan(activeAt));
      expect(completedAt, greaterThan(requestedAt));
      expect(after, contains('uiState=exercise_active'));
      expect(after, contains('active=true'));
      expect(after, contains('trigger=before_you_start_continue'));
      expect(tts.speakCalls, 1);
    },
  );

  testWidgets(
    '228 correction enabled audio follows the Text-to-speech setting',
    (tester) async {
      final disabledTts = _CountingTts();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: true, ttsEnabled: false),
        recorded: _CountingRecordedAudio(),
        tts: disabledTts,
        fixture: _ttsAudioFixture,
      );
      expect(
        find.text(
          'All audio exercises in this round are currently unavailable.',
        ),
        findsOneWidget,
      );
      expect(disabledTts.speakCalls, 0);

      final enabledTts = _CountingTts();
      await _pumpRound(
        tester,
        settings: _AudioSettings(audioEnabled: true, ttsEnabled: true),
        recorded: _CountingRecordedAudio(),
        tts: enabledTts,
        fixture: _ttsAudioFixture,
      );
      expect(find.text('What do you hear?'), findsWidgets);
      expect(enabledTts.speakCalls, 1);
    },
  );

  testWidgets('228.04 Editor Preview ignores learner Audio Settings', (
    tester,
  ) async {
    final recorded = _CountingRecordedAudio();
    await _pumpRound(
      tester,
      settings: _AudioSettings(audioEnabled: false, ttsEnabled: false),
      recorded: recorded,
      tts: _CountingTts(),
      previewMode: true,
    );

    expect(find.byType(RoundScreen), findsOneWidget);
    expect(find.text('What do you hear?'), findsWidgets);
    expect(find.text('casa'), findsOneWidget);
    expect(recorded.segmentCalls, 0);
    expect(recorded.playCalls, 1);
  });

  test(
    '228.04 audio diagnostics are correlated, bounded, and path safe',
    () async {
      final crashEntries = <String>[];
      final lifecycle = AudioDiagnosticLifecycle.start(
        kind: 'recorded',
        diagnosticLog: DiagnosticLogService(),
        crashWriter: (message) async => crashEntries.add(message),
      );
      await lifecycle.event(
        'source_resolution',
        outcome: 'resolved',
        backend: r'C:\Users\PrivateName\secret.mp3',
        count: 1,
        uiState: 'before_you_start',
        targetExerciseId: 'stable-listening-id',
        exerciseType: 'listening_choice',
        prepared: true,
        active: false,
        trigger: 'round_initialized',
      );
      for (var index = 0; index < 12; index++) {
        await lifecycle.event('playback', outcome: 'retry_$index');
      }
      await lifecycle.dispose(outcome: 'completed');

      expect(crashEntries, hasLength(AudioDiagnosticLifecycle.maximumEvents));
      expect(crashEntries.map(_correlationId).toSet(), hasLength(1));
      expect(crashEntries.last, contains('phase=disposal'));
      expect(crashEntries.join('\n'), contains('backend=path-redacted'));
      expect(crashEntries.join('\n'), contains('uiState=before_you_start'));
      expect(
        crashEntries.join('\n'),
        contains('targetExerciseId=stable-listening-id'),
      );
      expect(crashEntries.join('\n'), contains('prepared=true active=false'));
      expect(crashEntries.join('\n'), isNot(contains('PrivateName')));
      expect(crashEntries.join('\n'), isNot(contains('secret.mp3')));
      final diagnostic = (await SharedPreferences.getInstance()).getString(
        'quisquislingo_diagnostic_log',
      );
      expect(diagnostic, contains('correlationId='));
      expect(diagnostic, contains('phase=disposal'));
    },
  );

  test('228.04 TTS failures do not log spoken text', () async {
    const privateSpokenText = 'private spoken answer must stay out of logs';
    await ProfileService().addProfile('TTS Failure Learner');
    await SettingsService().setTtsEnabled(true);
    final service = TtsCacheService();
    expect(
      await service.speak(text: privateSpokenText, language: 'und'),
      isFalse,
    );
    final log = (await SharedPreferences.getInstance()).getString(
      'quisquislingo_diagnostic_log',
    );
    expect(log, isNot(contains(privateSpokenText)));
    expect(log, isNot(contains('text=')));
  });
}

String _correlationId(String message) =>
    RegExp(r'correlationId=([^ ]+)').firstMatch(message)!.group(1)!;

class _AudioSettings extends SettingsService {
  final bool audioEnabled;
  final bool ttsEnabled;

  _AudioSettings({required this.audioEnabled, required this.ttsEnabled});

  @override
  Future<bool> areAudioExercisesEnabled() async => audioEnabled;

  @override
  Future<bool> isTtsEnabled() async => ttsEnabled;
}

class _CountingRecordedAudio extends RecordedAudioService {
  final bool sourceAvailable;
  int segmentCalls = 0;
  int sourceCalls = 0;
  int playCalls = 0;

  _CountingRecordedAudio({this.sourceAvailable = true});

  @override
  List<CourseAudioClip>? segment(String text, List<CourseAudioClip> library) {
    segmentCalls++;
    return library;
  }

  @override
  Source? sourceForClip(CourseAudioClip clip) {
    sourceCalls++;
    return sourceAvailable ? AssetSource('audio/test.mp3') : null;
  }

  @override
  Future<Source?> resolveSourceForClip(CourseAudioClip clip) async {
    sourceCalls++;
    return sourceAvailable ? AssetSource('audio/test.mp3') : null;
  }

  @override
  Future<bool> playConcatenated(
    String text,
    List<CourseAudioClip> library, {
    Duration gap = const Duration(milliseconds: 90),
    bool enableDiagnostics = true,
  }) async {
    playCalls++;
    return true;
  }
}

class _CountingTts extends TtsCacheService {
  int speakCalls = 0;

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
  }) async {
    speakCalls++;
    return true;
  }
}

Future<void> _pumpRound(
  WidgetTester tester, {
  required SettingsService settings,
  required _CountingRecordedAudio recorded,
  required _CountingTts tts,
  bool previewMode = false,
  _AudioFixture? fixture,
}) async {
  if (!previewMode && await ProfileService().getActiveProfileId() == null) {
    await ProfileService().addProfile('Round Audio Learner');
  }
  final data = fixture ?? _audioFixture;
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        key: UniqueKey(),
        course: data.course,
        lesson: data.lesson,
        round: data.round,
        ttsLanguage: 'it-IT',
        roundIndex: 0,
        previewMode: previewMode,
        settingsService: settings,
        recordedAudioService: recorded,
        ttsCacheService: tts,
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 20}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _AudioFixture {
  final Course course;
  final Lesson lesson;
  final LearningRound round;

  const _AudioFixture({
    required this.course,
    required this.lesson,
    required this.round,
  });
}

final _audioFixture = _buildAudioFixture(audioMode: 'recorded');
final _ttsAudioFixture = _buildAudioFixture(audioMode: 'tts');
final _recordedIntroAudioFixture = _buildAudioFixture(
  audioMode: 'recorded',
  includeIntro: true,
);
final _ttsIntroAudioFixture = _buildAudioFixture(
  audioMode: 'tts',
  includeIntro: true,
);

_AudioFixture _buildAudioFixture({
  required String audioMode,
  bool includeIntro = false,
}) {
  final exercise = Exercise(
    id: 'recorded-listening',
    type: 'listening_choice',
    prompt: '',
    question: 'What do you hear?',
    answers: const ['casa', 'pane'],
    correct: 0,
    tts: 'casa',
    accepted: const [],
    tokens: const [],
    orderAnswer: const [],
    pairs: const [],
    hint: '',
    icons: const [],
  );
  final round = LearningRound(
    id: 'audio-round',
    title: 'Audio Round',
    content: [
      if (includeIntro)
        const LearningContent(
          id: 'audio-round-intro',
          kind: 'text',
          role: 'lesson_intro',
          text: 'Round introduction.',
        ),
      LearningContent.fromExercise(exercise),
    ],
  );
  final lesson = Lesson(
    lessonId: 'audio-lesson',
    title: 'Audio Lesson',
    rounds: [round],
    guidebook: Guidebook.empty(),
  );
  final course = Course(
    courseId: 'audio-course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Audio Course',
    ttsLanguage: 'it-IT',
    audioMode: audioMode,
    audioLibrary: const [
      CourseAudioClip(
        id: 'recorded-casa',
        text: 'casa',
        filePath: 'assets/audio/casa.mp3',
      ),
    ],
    lessons: [lesson],
  );
  return _AudioFixture(course: course, lesson: lesson, round: round);
}
