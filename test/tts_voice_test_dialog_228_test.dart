import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/tts_settings_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile('Voice Test Learner');
    await SettingsService().setTtsEnabled(true);
  });

  testWidgets(
    'Test Voice starts empty and speaks only exact user text with the course language',
    (tester) async {
      final tts = _RecordingTtsService();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          home: TtsSettingsScreen(course: _englishCourse(), ttsService: tts),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Test Voice'));
      await tester.pumpAndSettle();

      final fieldFinder = find.byKey(const Key('tts-voice-test-text'));
      expect(fieldFinder, findsOneWidget);
      expect(tester.widget<TextField>(fieldFinder).controller!.text, isEmpty);
      expect(find.text('Enter text to test'), findsOneWidget);
      expect(find.textContaining('Buongiorno. Questa'), findsNothing);
      expect(find.textContaining('Hello. This is'), findsNothing);
      expect(tts.requests, isEmpty);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('tts-voice-test-play')))
            .onPressed,
        isNull,
      );

      await tester.enterText(fieldFinder, '   ');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('tts-voice-test-play')))
            .onPressed,
        isNull,
      );
      expect(tts.requests, isEmpty);

      await tester.enterText(fieldFinder, 'Good morning');
      await tester.pump();
      await tester.tap(find.byKey(const Key('tts-voice-test-play')));
      await tester.pumpAndSettle();

      expect(tts.requests.last.text, 'Good morning');
      expect(tts.requests.last.language, 'en-GB');
      expect(tts.requests.last.learningLanguage, 'English');
      expect(tts.requests.last.targetLanguage, 'English');
      expect(
        tts.requests.any((request) => request.text == 'Enter text to test'),
        isFalse,
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(TtsSettingsScreen)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Test Voice'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('tts-voice-test-text')),
        'Buongiorno',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('tts-voice-test-play')));
      await tester.pumpAndSettle();

      expect(tts.requests.last.text, 'Buongiorno');
      expect(tts.requests.last.language, 'en-GB');
      expect(tts.requests.last.learningLanguage, 'English');
    },
  );

  testWidgets('missing compatible course voice keeps the specific failure', (
    tester,
  ) async {
    final tts = _RecordingTtsService(result: false);
    await tester.pumpWidget(
      MaterialApp(
        home: TtsSettingsScreen(course: _italianCourse(), ttsService: tts),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Test Voice'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('tts-voice-test-text')),
      'Testo scelto',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('tts-voice-test-play')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No compatible voice could be played for Italian.'),
      findsOneWidget,
    );
    expect(tts.requests.single.text, 'Testo scelto');
    expect(tts.requests.single.language, 'it-IT');
  });
}

typedef _TtsRequest = ({
  String text,
  String language,
  String? learningLanguage,
  String? targetLanguage,
});

class _RecordingTtsService extends TtsCacheService {
  final bool result;
  final List<_TtsRequest> requests = [];

  _RecordingTtsService({this.result = true});

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
  }) async {
    requests.add((
      text: text,
      language: language,
      learningLanguage: learningLanguage,
      targetLanguage: targetLanguage,
    ));
    return result;
  }
}

Course _englishCourse() => Course(
  courseId: 'english-course',
  learningLanguage: 'English',
  interfaceLanguage: 'Italian',
  sourceLanguage: 'Italian',
  targetLanguage: 'English',
  title: 'English course',
  ttsLanguage: 'en-GB',
  version: '1',
  lessons: const [],
);

Course _italianCourse() => Course(
  courseId: 'italian-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Italian course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: const [],
);
