import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/exercise_copy/exercise_copy_catalogs.dart';
import 'package:quisquislingo_app/localization/learner_panel/learner_panel_catalogs.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/audio_library_index.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/spoken_line_pace.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/test_directories.dart';

final _laboratory = Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

Exercise _labExercise(String id) => _laboratory.lessons
    .expand((lesson) => lesson.rounds)
    .expand((round) => round.exercises)
    .singleWhere((exercise) => exercise.id == id);

/// A Course whose learners read Italian.
Course _italianCourse(
  List<Lesson> lessons, {
  LessonNumberingMode numbering = LessonNumberingMode.lesson,
  String customLabel = '',
}) => Course(
  courseId: 'labels-271-course',
  learningLanguage: 'English',
  interfaceLanguage: 'Italian',
  sourceLanguage: 'Italian',
  sourceLanguageTag: 'it',
  targetLanguage: 'English',
  title: 'Labels 271',
  ttsLanguage: 'en-GB',
  lessonNumberingMode: numbering,
  customLessonLabel: customLabel,
  lessons: lessons,
);

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

/// The six translated languages.
const _translated = ['es', 'it', 'de', 'pt', 'nl', 'fr'];

/// The names of a Course's items, as English writes them and as a sentence
/// names them.
final _names = <String, RegExp>{
  'Lesson': RegExp(r'\blessons?\b', caseSensitive: false),
  'Round': RegExp(r'\brounds?\b', caseSensitive: false),
  'Story': RegExp(r'\bstory\b', caseSensitive: false),
  'Sequence': RegExp(r'\bsequence\b', caseSensitive: false),
  'Duel': RegExp(r'\bduel\b', caseSensitive: false),
  'GuideBook': RegExp(r'\bguidebook\b', caseSensitive: false),
};

/// The texts whose "Review" is the Review page, not the verb.
const _reviewNamed = {
  'reviewOfRound',
  'review.title',
  'review.completed',
  'review.ready',
  'review.noMoreRounds',
  'review.wordsToReview.one',
  'review.wordsToReview.other',
  'review.next',
  'review.noRounds',
};

/// The words each language used for those names before, which no text may
/// use for them now. A Round's own repetition of the exercises missed (not
/// the Review page) keeps its word: [_repetition].
final _earlierWords = <String, RegExp>{
  'it': RegExp(
    r'\b(lezion[ei]|storia|sequenza|duello|ripasso|la guida)\b',
    caseSensitive: false,
  ),
  'es': RegExp(
    r'\b(lecci[oó]n|rondas?|historia|secuencia|duelo|repaso|la gu[ií]a)\b',
    caseSensitive: false,
  ),
  'de': RegExp(
    r'\b(lektion|runden?|geschichte|sequenz|\w*duell|wiederholung|leitfaden)\b',
    caseSensitive: false,
  ),
  'pt': RegExp(
    r'\b(li[cç][aã]o|rondas?|hist[oó]ria|sequ[eê]ncia|duelo|revis[aã]o|o guia)\b',
    caseSensitive: false,
  ),
  'nl': RegExp(
    r'\b(les|rondes?|verhaal\w*|reeks|eindduel|taalduel|herhaling|herhaalsessie|gids)\b',
    caseSensitive: false,
  ),
  // French writes séquence and duel: the names differ from them by the
  // accent and the capital, which the first test checks.
  'fr': RegExp(
    r'\b(le[cç]ons?|manches?|histoires?|séquences?|r[eé]visions?|le guide)\b',
    caseSensitive: false,
  ),
};
const _repetition = {'roundInReview', 'reviewingMissed'};

// Build 271 Revision 5 (owner decision of 12 October 2026): the names of a
// Course's items (Lesson, Round and the Round types, Story, Sequence, Duel,
// GuideBook, Review) are written in English in every language, also inside
// a sentence, as proper names; a Lesson's and a Round's label is the one the
// learner path shows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the names of a Course\'s items in the seven languages', () {
    test('a translated text names an item as English does', () {
      var checked = 0;
      for (final catalogs in [learnerPanelCatalogs, exerciseCopyCatalogs]) {
        final english = catalogs['en']!;
        for (final entry in english.entries) {
          // A placeholder such as {round} is not a name.
          final words = entry.value.replaceAll(RegExp(r'\{[^}]*\}'), '');
          for (final name in _names.entries) {
            if (!name.value.hasMatch(words)) continue;
            for (final language in _translated) {
              final text = catalogs[language]![entry.key];
              if (text == null) continue;
              // With its capital, as a proper name (a heading in capitals
              // writes it in capitals).
              expect(
                text.contains(name.key) ||
                    text.contains(name.key.toUpperCase()),
                isTrue,
                reason: '$language ${entry.key}: "$text"',
              );
              checked++;
            }
          }
          if (_reviewNamed.contains(entry.key)) {
            for (final language in _translated) {
              expect(
                catalogs[language]![entry.key],
                contains('Review'),
                reason: '$language ${entry.key}',
              );
              checked++;
            }
          }
        }
      }
      expect(checked, greaterThan(250));
    });

    test('no text uses a language\'s own word for one of them', () {
      for (final catalogs in [learnerPanelCatalogs, exerciseCopyCatalogs]) {
        for (final language in _translated) {
          for (final entry in catalogs[language]!.entries) {
            if (_repetition.contains(entry.key)) continue;
            expect(
              _earlierWords[language]!.firstMatch(entry.value)?.group(0),
              isNull,
              reason: '$language ${entry.key}: "${entry.value}"',
            );
          }
        }
      }
    });

    test('Italian, word for word', () {
      final panel = learnerPanelCatalogs['it']!;
      expect(panel['finish.story'], 'Termina la Story');
      expect(panel['completed.round'], 'Round completato');
      expect(panel['completed.sequence'], 'Sequence completata');
      expect(panel['summary.lessonCompleted'], 'Lesson completata: +{xp} XP');
      expect(panel['duel.title'], 'Language Duel');
      expect(panel['duel.finalTitle'], 'Final Duel');
      expect(panel['duel.won'], 'Duel vinto');
      expect(panel['openGuidebook'], 'Apri il GuideBook');
      expect(panel['review.title'], 'Review');
      expect(panel['review.next'], 'Prossima Review');
      expect(panel['steps.story'], 'Story · {n} passi');
      // The words around the names stay Italian.
      expect(panel['check'], 'Controlla');
      // A Round's own repetition of the exercises missed is not the Review.
      expect(panel['roundInReview'], '{round} · Ripasso');
      final copy = exerciseCopyCatalogs['it']!;
      expect(copy['type.storyCover'], 'STORY');
      expect(
        copy['instruction.storyCover'],
        'Inizia una Story. Continua quando sei pronto.',
      );
    });

    test('the catalogs no longer hold a Lesson or Round label', () {
      for (final catalog in learnerPanelCatalogs.values) {
        for (final key in ['lessonLine', 'review.lesson', 'review.round']) {
          expect(catalog.containsKey(key), isFalse, reason: key);
        }
      }
    });
  });

  group('on the Round screen of a Course whose learners read Italian', () {
    setUp(() async {
      _installPluginMocks();
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Labels author');
    });

    LearningRound round() => LearningRound(
      id: 'round-271',
      title: 'Saluti',
      content: [
        LearningContent.fromExercise(_labExercise('qql_lab254_input_explicit')),
      ],
    );

    Future<void> open(
      WidgetTester tester,
      Course Function(Lesson lesson) course, {
      bool review = false,
    }) async {
      _bigWindow(tester);
      final shown = round();
      final lesson = Lesson(
        lessonId: 'lesson-271',
        title: 'Primi passi',
        rounds: [shown],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course(lesson),
            lesson: lesson,
            round: shown,
            ttsLanguage: 'en-GB',
            roundIndex: 0,
            previewMode: !review,
            reviewMode: review,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await _pumpUntil(tester, find.text('Controlla'));
    }

    testWidgets('the Lesson is named as on the learner path: Lesson 1', (
      tester,
    ) async {
      await open(tester, (lesson) => _italianCourse([lesson]));

      expect(find.text('English · Lesson 1: Primi passi'), findsOneWidget);
      expect(find.textContaining('Lezione'), findsNothing);
      // The words around it are still Italian.
      expect(find.text('Controlla'), findsOneWidget);
    });

    testWidgets('an author\'s own label and no label are shown as they are', (
      tester,
    ) async {
      await open(
        tester,
        (lesson) => _italianCourse(
          [lesson],
          numbering: LessonNumberingMode.other,
          customLabel: 'Unità',
        ),
      );
      expect(find.text('English · Unità 1: Primi passi'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await open(
        tester,
        (lesson) =>
            _italianCourse([lesson], numbering: LessonNumberingMode.none),
      );
      expect(find.text('English · Primi passi'), findsOneWidget);
    });

    testWidgets('in a Review the Round is "Round 1" and the page is '
        '"Review"', (tester) async {
      await open(tester, (lesson) => _italianCourse([lesson]), review: true);

      expect(
        find.text(
          'Labels 271 · English · Lesson 1: Primi passi · '
          'Round 1: Practice · Saluti',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Review · Practice · Saluti', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('Ripasso'), findsNothing);
    });
  });

  group('the Audio Library\'s letters', () {
    CourseAudioClip clip(String text) =>
        CourseAudioClip(id: text, text: text, filePath: 'media:$text.mp3');

    List<String> keysOf(List<String> texts) => [
      for (final group in AudioLibraryIndex.groups([
        for (final text in texts) clip(text),
      ]))
        group.key,
    ];

    test('Cyrillic letters stand where their alphabets put them', () {
      // Ukrainian: Ґ after Г, Є after Е, І (with Ї) after И. By code point
      // they came before А.
      expect(
        keysOf([
          'Яна',
          'Єва',
          'Іван',
          'Їжак',
          'Анна',
          'Ґанок',
          'Жук',
          'Зоря',
          'Гай',
          'Ева',
          'Ирис',
        ]),
        ['А', 'Г', 'Ґ', 'Е', 'Є', 'Ж', 'З', 'И', 'І', 'Я'],
      );
      // Serbian: Ђ after Д, Љ after Л, Њ after Н, Ћ after Т, Џ after Ч.
      expect(
        keysOf([
          'Шума',
          'Џак',
          'Чај',
          'Ћуп',
          'Тата',
          'Њива',
          'Нос',
          'Љубав',
          'Лав',
          'Ђак',
          'Дан',
          'Ево',
        ]),
        ['Д', 'Ђ', 'Е', 'Л', 'Љ', 'Н', 'Њ', 'Т', 'Ћ', 'Ч', 'Џ', 'Ш'],
      );
      // Kazakh: Ә after А, by code point after Я.
      expect(keysOf(['Яна', 'Бала', 'Әке', 'Ана']), ['А', 'Ә', 'Б', 'Я']);
      // Latin and Greek are as they were.
      expect(keysOf(['zebra', 'Ωμέγα', 'apple', 'Άλφα']), ['A', 'Z', 'Α', 'Ω']);
    });

    test('texts are in alphabet order inside a group too', () {
      final texts = ['бк', 'біт', 'бит', 'бєр', 'бер', 'бжу'];
      texts.sort(
        (a, b) => AudioLibraryIndex.sortKey(
          a,
        ).compareTo(AudioLibraryIndex.sortKey(b)),
      );
      expect(texts, ['бер', 'бєр', 'бжу', 'бит', 'біт', 'бк']);
    });
  });

  testWidgets('the Course Info editor leaves no timer behind when it '
      'closes, and opens again', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const profileId = '71111111-1111-4111-8111-111111111111';
    final course = Course(
      courseId: 'course-info-271',
      originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
        profileId: profileId,
        displayName: 'Author',
      ),
      maintainer: const CourseMaintainer(profileId),
      publicationState: PublicationState.published,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Course Info 271',
      ttsLanguage: 'it-IT',
      courseVersion: '1',
      license: 'All rights reserved',
      derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
      lessons: const [],
    );
    final profiles = ProfileService();
    await profiles.createProfile('Author', learnerProfileId: profileId);
    await profiles.setActiveProfileById(profileId);
    await SettingsService().markAudioOrphanCheckRun('IT');
    await SettingsService().setCourseEditorMode(
      course.courseId,
      CourseEditorMode.edit,
    );
    await tester.runAsync(() => CourseEditorService().saveUserCourse(course));
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: profileId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hours = find.byKey(const Key('course-info-estimated-hours'));
    for (final value in ['12', '15']) {
      await tester.tap(find.text('Course Info Editor'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(hours);
      await tester.enterText(hours, value);
      await tester.pump();
      final apply = find.byKey(const Key('course-info-save'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpUntilFileIoState(() => apply.evaluate().isEmpty);
    }
    expect(find.byKey(const Key('course-editor-unsaved')), findsOneWidget);
    // The test ends here without waiting: before, the dialog's fields were
    // disposed by a timer 300 ms after it closed, and a test that ended
    // sooner failed on the pending timer.
  });

  group('the Round screen\'s test seams', () {
    test('a test may replace them', () {
      RoundScreen.openLink = (_) async => false;
      RoundScreen.lineStopwatch = () => Stopwatch()..start();
      SpokenLinePace.shared.record(
        'una frase di prova abbastanza lunga',
        const Duration(seconds: 1),
      );
      expect(
        SpokenLinePace.shared.charactersPerSecond,
        isNot(SpokenLinePace.defaultCharactersPerSecond),
      );
    });

    test('and the next test starts from the app\'s own again', () {
      expect(RoundScreen.openLink, RoundScreen.launchLink);
      expect(RoundScreen.lineStopwatch().isRunning, isFalse);
      expect(
        SpokenLinePace.shared.charactersPerSecond,
        SpokenLinePace.defaultCharactersPerSecond,
      );
    });
  });
}
