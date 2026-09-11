import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/screens/tts_settings_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/audio_exercise_availability_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
    });
    await ProfileService().addProfile('Round audio indicator learner');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => throw PlatformException(code: 'test-storage'),
        );
  });

  group('effective Round audio availability', () {
    test(
      'Audio Exercises Off preserves structural audio but disables it',
      () async {
        final recorded = _RecordedAvailability();
        final result =
            await AudioExerciseAvailabilityService(
              recordedAudio: recorded,
            ).evaluateRound(
              _course(audioMode: 'tts'),
              _ttsRound,
              audioExercisesEnabled: false,
              ttsEnabled: true,
            );

        expect(result, EffectiveRoundAudioAvailability.audioExercisesDisabled);
        expect(recorded.sourceChecks, 0);
      },
    );

    test('TTS-only Round is active with both audio settings on', () async {
      final result = await AudioExerciseAvailabilityService().evaluateRound(
        _course(audioMode: 'tts'),
        _ttsRound,
        audioExercisesEnabled: true,
        ttsEnabled: true,
      );

      expect(result, EffectiveRoundAudioAvailability.available);
    });

    test('TTS-only Round is disabled when Text-to-speech is off', () async {
      final result = await AudioExerciseAvailabilityService().evaluateRound(
        _course(audioMode: 'tts'),
        _ttsRound,
        audioExercisesEnabled: true,
        ttsEnabled: false,
      );

      expect(result, EffectiveRoundAudioAvailability.ttsDisabled);
    });

    test('recorded Round remains active when Text-to-speech is off', () async {
      final result =
          await AudioExerciseAvailabilityService(
            recordedAudio: _RecordedAvailability(availableTexts: {'recorded'}),
          ).evaluateRound(
            _course(audioMode: 'recorded'),
            _recordedRound,
            audioExercisesEnabled: true,
            ttsEnabled: false,
          );

      expect(result, EffectiveRoundAudioAvailability.available);
    });

    test(
      'mixed Round remains active when its recorded audio is usable',
      () async {
        final result =
            await AudioExerciseAvailabilityService(
              recordedAudio: _RecordedAvailability(
                availableTexts: {'recorded'},
              ),
            ).evaluateRound(
              _course(audioMode: 'hybrid'),
              _mixedRound,
              audioExercisesEnabled: true,
              ttsEnabled: false,
            );

        expect(result, EffectiveRoundAudioAvailability.available);
      },
    );

    test('Round without structural audio has no audio state', () async {
      final result = await AudioExerciseAvailabilityService().evaluateRound(
        _course(audioMode: 'tts'),
        _textRound,
        audioExercisesEnabled: true,
        ttsEnabled: true,
      );

      expect(result, EffectiveRoundAudioAvailability.none);
    });
  });

  group('Learner Panel Round audio indicator', () {
    testWidgets('active and disabled states preserve icon placement', (
      tester,
    ) async {
      await _pumpRoundPath(
        tester,
        round: _ttsRound,
        availability: EffectiveRoundAudioAvailability.available,
      );
      final active = tester.widget<Icon>(_audioIcon(_ttsRound.id));
      expect(active.color, const Color(0xFF1657D9));
      expect(
        find.byTooltip('Audio exercises are turned off in Audio Settings.'),
        findsNothing,
      );

      await _pumpRoundPath(
        tester,
        round: _ttsRound,
        availability: EffectiveRoundAudioAvailability.audioExercisesDisabled,
      );
      final disabled = tester.widget<Icon>(_audioIcon(_ttsRound.id));
      expect(disabled.color, ThemeData.light(useMaterial3: true).disabledColor);
      expect(
        find.byTooltip('Audio exercises are turned off in Audio Settings.'),
        findsOneWidget,
      );

      await _pumpRoundPath(
        tester,
        round: _ttsRound,
        availability: EffectiveRoundAudioAvailability.ttsDisabled,
      );
      expect(
        find.byTooltip('Text-to-speech is turned off in Audio Settings.'),
        findsOneWidget,
      );
    });

    testWidgets('Round without structural audio keeps no indicator', (
      tester,
    ) async {
      await _pumpRoundPath(
        tester,
        round: _textRound,
        availability: EffectiveRoundAudioAvailability.none,
      );

      expect(_audioIcon(_textRound.id), findsNothing);
      expect(find.byIcon(Icons.volume_up_outlined), findsNothing);
    });

    testWidgets('Audio Exercises changes refresh on return from Settings', (
      tester,
    ) async {
      final settings = SettingsService();
      await settings.setAudioExercisesEnabled(true);
      await settings.setTtsEnabled(true);
      await _openHome(tester, _course(audioMode: 'tts'));
      _expectActiveIcon(tester, _ttsRound.id);

      await _setAudioPreference(tester, 'Enable Audio Exercises', false);
      expect(
        find.byTooltip('Audio exercises are turned off in Audio Settings.'),
        findsOneWidget,
      );

      await _setAudioPreference(tester, 'Enable Audio Exercises', true);
      _expectActiveIcon(tester, _ttsRound.id);
    });

    testWidgets('Text-to-speech changes refresh on return from Settings', (
      tester,
    ) async {
      final settings = SettingsService();
      await settings.setAudioExercisesEnabled(true);
      await settings.setTtsEnabled(true);
      await _openHome(tester, _course(audioMode: 'tts'));
      _expectActiveIcon(tester, _ttsRound.id);

      await _setAudioPreference(tester, 'Text-to-speech', false);
      expect(
        find.byTooltip('Text-to-speech is turned off in Audio Settings.'),
        findsOneWidget,
      );

      await _setAudioPreference(tester, 'Text-to-speech', true);
      _expectActiveIcon(tester, _ttsRound.id);
    });
  });
}

Finder _audioIcon(String roundId) =>
    find.byKey(ValueKey('unified-round-audio-$roundId'));

void _expectActiveIcon(WidgetTester tester, String roundId) {
  expect(_audioIcon(roundId), findsOneWidget);
  expect(
    tester.widget<Icon>(_audioIcon(roundId)).color,
    const Color(0xFF1657D9),
  );
  expect(
    find.byTooltip('Audio exercises are turned off in Audio Settings.'),
    findsNothing,
  );
  expect(
    find.byTooltip('Text-to-speech is turned off in Audio Settings.'),
    findsNothing,
  );
}

Future<void> _pumpRoundPath(
  WidgetTester tester, {
  required LearningRound round,
  required EffectiveRoundAudioAvailability availability,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: SizedBox(
          width: 430,
          child: LearnerRoundPath(
            courseId: 'round-audio-indicator-course',
            rounds: [round],
            completedRounds: const {},
            perfectRounds: const {},
            ttsSkippedPerfectRounds: const {},
            roundAudioAvailability: {round.id: availability},
            mascotAssets: const [],
            onOpenRound: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openHome(WidgetTester tester, Course course) async {
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await CourseEditorService().saveUserCourse(course);
  await SettingsService().setLastSelectedCourseCode(
    'custom:${course.courseId}',
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: const HomeScreen(),
    ),
  );
  await _pumpFrames(tester);
  if (find.text('Alpha expiry').evaluate().isNotEmpty) {
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await _pumpFrames(tester);
  }
}

Future<void> _setAudioPreference(
  WidgetTester tester,
  String title,
  bool value,
) async {
  await tester.tap(find.byKey(const Key('unified-topbar-settings')));
  await _pumpUntil(tester, find.byType(SettingsScreen));
  await tester.tap(find.widgetWithText(ListTile, 'Audio Settings'));
  await _pumpUntil(tester, find.byType(TtsSettingsScreen));
  final tile = find.widgetWithText(SwitchListTile, title);
  expect(tester.widget<SwitchListTile>(tile).value, isNot(value));
  await tester.tap(tile);
  await tester.pumpAndSettle();
  expect(tester.widget<SwitchListTile>(tile).value, value);
  Navigator.of(tester.element(find.byType(TtsSettingsScreen))).pop();
  await _pumpUntil(tester, find.byType(SettingsScreen));
  Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
  await _pumpUntil(tester, _audioIcon(_ttsRound.id));
  await _pumpFrames(tester);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int frames = 40,
}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpFrames(WidgetTester tester, {int frames = 30}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _RecordedAvailability extends RecordedAudioService {
  final Set<String> availableTexts;
  int sourceChecks = 0;

  _RecordedAvailability({this.availableTexts = const {}});

  @override
  List<CourseAudioClip>? segment(String text, List<CourseAudioClip> library) {
    final matches = library.where((clip) => clip.text == text).toList();
    return matches.isEmpty ? null : matches;
  }

  @override
  Future<Source?> resolveSourceForClip(CourseAudioClip clip) async {
    sourceChecks++;
    return availableTexts.contains(clip.text)
        ? AssetSource('audio/${clip.id}.mp3')
        : null;
  }
}

Course _course({required String audioMode}) => Course(
  courseId: 'round_audio_indicator_course',
  title: 'Round audio indicator',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  version: '1',
  audioMode: audioMode,
  createDuels: false,
  useGuidebook: false,
  audioLibrary: const [
    CourseAudioClip(
      id: 'recorded-clip',
      text: 'recorded',
      filePath: 'assets/audio/recorded.mp3',
    ),
  ],
  lessons: [
    Lesson(
      lessonId: 'round-audio-indicator-lesson',
      title: 'Audio indicators',
      rounds: [_ttsRound],
    ),
  ],
);

final _ttsRound = LearningRound(
  id: 'tts-audio-round',
  title: 'TTS audio',
  exercises: [_audioExercise('tts-only', 'tts only')],
);

final _recordedRound = LearningRound(
  id: 'recorded-audio-round',
  title: 'Recorded audio',
  exercises: [_audioExercise('recorded-only', 'recorded')],
);

final _mixedRound = LearningRound(
  id: 'mixed-audio-round',
  title: 'Mixed audio',
  exercises: [
    _audioExercise('tts-only', 'tts only'),
    _audioExercise('recorded-only', 'recorded'),
  ],
);

final _textRound = LearningRound(
  id: 'text-round',
  title: 'Text only',
  exercises: [_textExercise],
);

Exercise _audioExercise(String id, String text) => Exercise(
  id: id,
  type: 'listening_choice',
  prompt: 'Choose what you hear.',
  question: 'What do you hear?',
  answers: const ['One', 'Two'],
  correct: 0,
  tts: text,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

final _textExercise = Exercise(
  id: 'text-only',
  type: 'choice',
  prompt: 'Choose.',
  question: 'Text only?',
  answers: const ['Yes', 'No'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
