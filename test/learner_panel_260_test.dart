import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/learner_panel/learner_panel_catalogs.dart';
import 'package:quisquislingo_app/localization/learner_panel/learner_panel_en.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/learner_panel_text.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 260 Revision 1 (plan `docs/260_LANGUAGES_PLAN.md` point 6): the
/// learner panel's buttons and messages follow the Course's instruction
/// language, as the exercise lines do.

final _laboratory = Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

/// The Laboratory with another base language (and no tag, so the name
/// decides).
Course _inLanguage(String source) => Course.fromJson({
  ..._laboratory.toJson()..remove('sourceLanguageTag'),
  'sourceLanguage': source,
});

Exercise _labExercise(String id) => _laboratory.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.exercises)
    .singleWhere((exercise) => exercise.id == id);

Course _italianCourse(List<Lesson> lessons) => Course(
  courseId: 'learner-panel-260-course',
  learningLanguage: 'English',
  interfaceLanguage: 'Italian',
  sourceLanguage: 'Italian',
  sourceLanguageTag: 'it',
  targetLanguage: 'English',
  title: 'Learner panel 260',
  ttsLanguage: 'en-GB',
  lessons: lessons,
);

class _Settings extends SettingsService {
  @override
  Future<bool> areAudioExercisesEnabled() async => false;

  @override
  Future<bool> isTtsEnabled() async => false;
}

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the catalogs', () {
    test('seven languages, each complete with the English placeholders', () {
      expect(learnerPanelCatalogs.keys, [
        'en',
        'es',
        'it',
        'de',
        'pt',
        'nl',
        'fr',
      ]);
      final placeholder = RegExp(r'\{\w+\}');
      List<String> holes(String text) =>
          placeholder.allMatches(text).map((m) => m.group(0)!).toList()..sort();
      for (final MapEntry(key: language, value: catalog)
          in learnerPanelCatalogs.entries) {
        expect(
          catalog.keys.toSet(),
          learnerPanelEn.keys.toSet(),
          reason: language,
        );
        for (final MapEntry(:key, :value) in catalog.entries) {
          expect(value.trim(), isNotEmpty, reason: '$language $key');
          expect(
            holes(value),
            holes(learnerPanelEn[key]!),
            reason: '$language $key',
          );
        }
      }
    });
  });

  group('the language of the panel', () {
    test('follows the base language, else English', () {
      expect(LearnerPanelText.of(_laboratory, 'check'), 'Check');
      expect(LearnerPanelText.of(_inLanguage('Spanish'), 'check'), 'Comprobar');
      expect(LearnerPanelText.of(_inLanguage('Italian'), 'check'), 'Controlla');
      expect(LearnerPanelText.of(_inLanguage('German'), 'check'), 'Prüfen');
      expect(
        LearnerPanelText.of(_inLanguage('Portuguese'), 'check'),
        'Verificar',
      );
      expect(LearnerPanelText.of(_inLanguage('Dutch'), 'check'), 'Controleren');
      expect(LearnerPanelText.of(_inLanguage('French'), 'check'), 'Vérifier');
      // A base language QQL has no catalog for gets English.
      expect(LearnerPanelText.of(_inLanguage('Japanese'), 'check'), 'Check');
    });

    test('fills the placeholders', () {
      expect(
        LearnerPanelText.of(_inLanguage('Italian'), 'summary.total', {
          'xp': 12,
        }),
        'Totale: 12 XP',
      );
      expect(
        LearnerPanelText.of(_inLanguage('Spanish'), 'review.word', {
          'i': 2,
          'n': 5,
        }),
        'Palabra 2 de 5',
      );
      expect(
        LearnerPanelText.of(_laboratory, 'duel.question', {
          'n': 1,
          'total': 25,
        }),
        'Question 1/25 · 4 lives',
      );
    });
  });

  group('on screen', () {
    setUp(() async {
      _installPluginMocks();
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Learner panel author');
    });

    testWidgets('an Italian-base Round checks, marks and moves on in Italian', (
      tester,
    ) async {
      _bigWindow(tester);
      final round = LearningRound(
        id: 'round-260',
        title: 'Round 260',
        content: [
          LearningContent.fromExercise(
            _labExercise('qql_lab254_input_explicit'),
          ),
        ],
      );
      final lesson = Lesson(
        lessonId: 'lesson-260',
        title: 'Lesson 260',
        rounds: [round],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: _italianCourse([lesson]),
            lesson: lesson,
            round: round,
            ttsLanguage: 'en-GB',
            roundIndex: 0,
            previewMode: true,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await _pumpUntil(tester, find.text('Controlla'));
      expect(find.text('Check'), findsNothing);
      expect(find.text('La tua risposta'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nothing like it');
      await tester.pump();
      await tester.tap(find.text('Controlla'));
      await _pumpUntil(tester, find.text('Sbagliato'));
      // A translation shows its ranked translations.
      expect(
        tester
            .widget<Text>(find.byKey(const Key('translation-feedback-heading')))
            .data,
        anyOf('Traduzioni corrette:', 'Alcune traduzioni possibili:'),
      );
      expect(find.text('Rivedi gli errori'), findsOneWidget);
    });

    testWidgets('an Italian-base Duel names its questions in Italian', (
      tester,
    ) async {
      _bigWindow(tester);
      final choice = _labExercise('qql_lab254_choice_source_meaning');
      final round = LearningRound(
        id: 'duel-round-260',
        title: 'Duel round',
        exercises: [
          for (var index = 0; index < 25; index++)
            choice.copyWith(id: 'duel-260-$index'),
        ],
      );
      final lesson = Lesson(
        lessonId: 'duel-lesson-260',
        title: 'Duel lesson',
        rounds: [round],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DuelScreen(
            // A later Lesson, so this Duel is not the Final Duel.
            course: _italianCourse([
              lesson,
              Lesson(
                lessonId: 'next-lesson-260',
                title: 'Next',
                rounds: const [],
              ),
            ]),
            lesson: lesson,
            ttsLanguage: 'en-GB',
            settingsService: _Settings(),
          ),
        ),
      );
      await _pumpUntil(tester, find.text('Domanda 1/25 · 4 vite'));
      // Since Build 264 the heading names the Lesson, as on the learner
      // path, not "Duello linguistico".
      expect(
        tester.widget<Text>(find.byKey(const Key('duel-page-heading'))).data,
        endsWith('Duel lesson'),
      );
      expect(find.text('Question 1/25 · 4 lives'), findsNothing);
    });
  });
}
