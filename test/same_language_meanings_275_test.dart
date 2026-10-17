import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audio_texts.dart';
import 'package:quisquislingo_app/services/course_audio_usage.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/playback_on_request.dart';
import 'package:quisquislingo_app/services/preset_examples.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup.dart';
import 'package:quisquislingo_app/widgets/word_lookup_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quisquislingo_app/services/settings_service.dart';

import 'support/test_directories.dart';

// Build 275 Revision 3 (owner decisions of 17 October 2026): in a Course in
// the same language a meaning is the language being learned too, so its
// words can be looked up (Word Lookup) and it can be heard on request (the
// speakers of Build 274 Revision 2). A translation Course is unchanged: the
// learners' own language is neither looked up nor spoken.

const _profile = LearnerProfile(
  learnerProfileId: '27500000-0000-4000-8000-000000000301',
  displayName: 'Meanings',
);
final _operations = CourseLibraryOperations(
  clock: () => DateTime.utc(2026, 10, 17, 12),
);

/// An English to English Course holding the Laboratory's Lessons, made In
/// the same language or (with [sameLanguage] false) Through another
/// language: the same exercises, the two kinds.
Course _english(Course laboratory, {required bool sameLanguage}) =>
    Course.fromJson({
      ..._operations
          .newWizardCourse(
            creator: _profile,
            title: 'Meanings',
            sourceLanguage: 'English',
            targetLanguage: 'English',
            sourceLanguageTag: 'en',
            targetLanguageTag: 'en',
            sameLanguage: sameLanguage,
          )
          .toJson(),
      'lessons': laboratory.toJson()['lessons'],
    });

Exercise _example(Course course, String presetId) {
  final id = PresetExamples.exampleIds[presetId]!;
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final exercise in round.exercises) {
        if (exercise.id == id) return exercise;
      }
    }
  }
  throw StateError('No example of $presetId');
}

void main() {
  group('the speaker', () {
    late Course same;
    late Course other;

    setUpAll(() async {
      final laboratory = await CourseService().loadCourse('IT');
      same = _english(laboratory, sameLanguage: true);
      other = _english(laboratory, sameLanguage: false);
    });

    test('a meaning is heard in a same-language Course only; the word side '
        'is heard in both', () {
      for (final (preset, meaningSide) in [
        ('translation_choice_to_target', 'prompt'),
        ('translation_choice_to_source', 'answer'),
        ('type_translation_to_target', 'prompt'),
        ('type_translation_to_source', 'answer'),
        ('build_translation_to_target', 'prompt'),
        ('build_translation_to_source', 'answer'),
      ]) {
        final exercise = _example(same, preset);
        final f = ExerciseFeatures(exercise);
        String? prompt(bool sameLanguage) =>
            PlaybackOnRequest.promptText(f, sameLanguage: sameLanguage);
        String? answer(bool sameLanguage) => PlaybackOnRequest.answerText(
          exercise,
          f,
          answered: true,
          sameLanguage: sameLanguage,
        );
        final (meaning, word) = meaningSide == 'prompt'
            ? (prompt, answer)
            : (answer, prompt);
        expect(meaning(false), isNull, reason: preset);
        expect(meaning(true), isNotNull, reason: preset);
        expect(word(true), word(false), reason: preset);
        expect(word(true), isNotNull, reason: preset);
        // Nothing before the answer.
        expect(
          PlaybackOnRequest.answerText(
            exercise,
            f,
            answered: false,
            sameLanguage: true,
          ),
          isNull,
          reason: preset,
        );
      }
    });

    test('Pick the word says its meaning; Pick the meaning its right '
        'meaning', () {
      final pickWord = ExerciseFeatures(
        _example(same, 'translation_choice_to_target'),
      );
      expect(
        PlaybackOnRequest.promptText(pickWord, sameLanguage: true),
        pickWord.questionText.trim(),
      );
      final pickMeaning = _example(same, 'translation_choice_to_source');
      final f = ExerciseFeatures(pickMeaning);
      final right = f.items
          .singleWhere((item) => item.id == f.evaluation.correctItemIds.first)
          .text
          .trim();
      expect(
        PlaybackOnRequest.answerText(
          pickMeaning,
          f,
          answered: true,
          sameLanguage: true,
        ),
        right,
      );
    });

    test('an option word marked as the source language is heard only in a '
        'same-language Course', () {
      // The first option the learner may hear today, its word then marked
      // as the source language.
      Exercise? found;
      ExerciseItem? item;
      for (final lesson in same.lessons) {
        for (final round in lesson.rounds) {
          for (final exercise in round.exercises) {
            final f = ExerciseFeatures(exercise);
            for (final candidate in f.items) {
              if (found == null &&
                  PlaybackOnRequest.optionWord(f, candidate) != null) {
                found = exercise;
                item = candidate;
              }
            }
          }
        }
      }
      expect(found, isNotNull);
      final json =
          jsonDecode(jsonEncode(found!.toJson())) as Map<String, dynamic>;
      for (final entry
          in (json['items'] as List).cast<Map<String, dynamic>>()) {
        if (entry['id'] != item!.id) continue;
        for (final element
            in (entry['content'] as List).cast<Map<String, dynamic>>()) {
          if (element['type'] == 'text' && element['role'] != 'icon') {
            element['language'] = 'source';
          }
        }
      }
      final marked = Exercise.fromJson(
        json,
        contentId: found.id,
        publicationState: found.publicationState,
      );
      final f = ExerciseFeatures(marked);
      final markedItem = f.items.singleWhere((each) => each.id == item!.id);
      expect(PlaybackOnRequest.optionWord(f, markedItem), isNull);
      expect(
        PlaybackOnRequest.optionWord(f, markedItem, sameLanguage: true),
        item!.label.trim(),
      );
    });

    test('the Audio Library lists the meanings as texts to record', () {
      final meaning = ExerciseFeatures(
        _example(same, 'translation_choice_to_target'),
      ).questionText.trim();
      final sameTexts = {
        for (final text in CourseAudioTexts.of(same)) text.text,
      };
      final otherTexts = {
        for (final text in CourseAudioTexts.of(other)) text.text,
      };
      expect(sameTexts, contains(meaning));
      expect(otherTexts, isNot(contains(meaning)));
      expect(sameTexts.containsAll(otherTexts), isTrue);
      // A recording of a meaning is used in a same-language Course.
      const clip = CourseAudioClip(
        id: 'meaning_clip',
        text: 'meaning',
        filePath: 'media:meaning.mp3',
      );
      List<CourseAudioClip>? segment(String text) =>
          text == meaning ? const [clip] : null;
      expect(
        CourseAudioUsage.usesByClip(same, segment),
        contains('meaning_clip'),
      );
      expect(
        CourseAudioUsage.usesByClip(other, segment),
        isNot(contains('meaning_clip')),
      );
    });
  });

  group('Word Lookup', () {
    Future<void> pumpScope(WidgetTester tester, {required bool same}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WordLookupScope(
                index: WordLookupIndex.build(const [
                  WordLookupSourceEntry(
                    id: 'coffee',
                    target: 'coffee',
                    source: 'a hot drink made from roasted beans',
                    lessonIndex: 0,
                  ),
                ]),
                currentLessonIndex: 0,
                lessonName: (_) => '',
                note: 'One possible meaning.',
                notePlural: 'Some possible meanings.',
                actionLabel: 'Vocabulary in this text',
                sameLanguage: same,
                child: Column(
                  children: [
                    LookupText(
                      'a small, strong coffee',
                      key: const Key('meaning'),
                      language: TextLanguage.source,
                    ),
                    LookupText(
                      'coffee',
                      key: const Key('word'),
                      language: TextLanguage.target,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

    Finder marksIn(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byKey(const Key('word-lookup-marks')),
    );

    testWidgets('a meaning\'s words can be looked up only in a '
        'same-language Course', (tester) async {
      await pumpScope(tester, same: true);
      expect(marksIn('meaning'), findsOneWidget);
      expect(marksIn('word'), findsOneWidget);
      await pumpScope(tester, same: false);
      await tester.pump();
      expect(marksIn('meaning'), findsNothing);
      expect(marksIn('word'), findsOneWidget);
    });
  });

  group('the Round screen', () {
    Future<void> pumpRound(
      WidgetTester tester, {
      required bool same,
      required String preset,
      bool lookUpTheQuestion = false,
      bool preview = true,
      SettingsService? settings,
    }) async {
      final laboratory = (await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      ))!;
      var course = _english(laboratory, sameLanguage: same);
      if (lookUpTheQuestion) {
        // A GuideBook entry for a word of the question, so Word Lookup has
        // something to find in it.
        final question = ExerciseFeatures(
          _example(course, preset),
        ).questionText;
        // The longest word: never an article, which Word Lookup treats
        // apart.
        final word =
            (RegExp('[A-Za-z]+')
                    .allMatches(question)
                    .map((match) => match.group(0)!.toLowerCase())
                    .toList()
                  ..sort((a, b) => b.length.compareTo(a.length)))
                .first;
        final json = course.toJson();
        final lessons = (json['lessons'] as List).cast<Map<String, dynamic>>();
        lessons.first['guidebook'] = {
          'modules': [
            {
              'id': 'meanings_module',
              'title': 'Meanings',
              'sentences': const <Object>[],
              'words': [
                {'id': 'meanings_word', 'target': word, 'source': 'a meaning'},
              ],
              'overview': '',
            },
          ],
        };
        course = Course.fromJson(json);
      }
      final round = LearningRound(
        id: 'meanings_preview',
        title: 'Preview',
        content: [LearningContent.fromExercise(_example(course, preset))],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            // A learner's Round belongs to its Lesson.
            lesson: preview
                ? course.lessons.first
                : Lesson(
                    lessonId: course.lessons.first.lessonId,
                    title: course.lessons.first.title,
                    rounds: [round],
                  ),
            round: round,
            ttsLanguage: 'en-GB',
            roundIndex: 0,
            previewMode: preview,
            settingsService: settings,
          ),
        ),
      );
      // Round start awaits file work: real time between pumps too.
      final heading = find.byKey(const Key('exercise-heading'));
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      for (var attempt = 0; heading.evaluate().isEmpty; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(
          attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
        );
        if (DateTime.now().isAfter(deadline)) fail('No exercise on the page');
      }
    }

    final speaker = find.byKey(const Key('translation-choice-audio'));
    Finder lookupOfQuestion() => find.ancestor(
      of: find.byKey(const Key('translation-choice-text')),
      matching: find.byType(LookupText),
    );

    Finder marksInQuestion() => find.descendant(
      of: lookupOfQuestion(),
      matching: find.byKey(const Key('word-lookup-marks')),
    );

    testWidgets('Pick the word: the meaning has its speaker and its words '
        'can be looked up in a same-language Course', (tester) async {
      await pumpRound(
        tester,
        same: true,
        preset: 'translation_choice_to_target',
        lookUpTheQuestion: true,
      );
      expect(speaker, findsOneWidget);
      expect(lookupOfQuestion(), findsOneWidget);
      expect(marksInQuestion(), findsOneWidget);
    });

    testWidgets('Pick the word: no speaker and no lookup for the question in '
        'a translation Course', (tester) async {
      await pumpRound(
        tester,
        same: false,
        preset: 'translation_choice_to_target',
        lookUpTheQuestion: true,
      );
      expect(speaker, findsNothing);
      expect(marksInQuestion(), findsNothing);
    });

    testWidgets('after the answer, the word and its meaning each have their '
        'own speaker, and audio off is said once', (tester) async {
      // A learner's Round (the Preview always plays audio), with the
      // learner's audio off.
      SharedPreferences.setMockInitialValues({});
      keepCrashLogUnavailable();
      // A learner's Round needs its learner.
      await tester.runAsync(() async {
        await ProfileService().createProfile(
          'Meanings',
          learnerProfileId: _profile.learnerProfileId,
          generateScreenNameSuffix: false,
        );
        await ProfileService().setActiveProfileById(_profile.learnerProfileId);
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => testSupportDirectory.path,
          );
      await pumpRound(
        tester,
        same: true,
        preset: 'translation_choice_to_target',
        preview: false,
        settings: _AudioOff(),
      );
      final f = ExerciseFeatures(
        _example(
          _english(
            (await tester.runAsync(() => CourseService().loadCourse('IT')))!,
            sameLanguage: true,
          ),
          'translation_choice_to_target',
        ),
      );
      final right = f.items
          .singleWhere((item) => item.id == f.evaluation.correctItemIds.first)
          .text;
      final option = find.text(right).last;
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(find.text('Listen to the answer'), findsOneWidget);
      expect(speaker, findsOneWidget);
      expect(
        find.byKey(const Key('translation-choice-answer-audio')),
        findsOneWidget,
      );
      // Audio is off: the note is shown once, under the meaning.
      expect(
        find.byKey(const Key('translation-choice-audio-note')),
        findsOneWidget,
      );
    });

    testWidgets('Pick the meaning: the word stays plain text (its GuideBook '
        'entry would show the answer)', (tester) async {
      await pumpRound(
        tester,
        same: true,
        preset: 'translation_choice_to_source',
      );
      expect(find.byKey(const Key('translation-choice-text')), findsOneWidget);
      expect(lookupOfQuestion(), findsNothing);
      expect(speaker, findsOneWidget);
    });
  });
}

/// The learner's audio is off.
class _AudioOff extends SettingsService {
  @override
  Future<bool> areAudioExercisesEnabled() async => false;

  @override
  Future<bool> isTtsEnabled() async => false;
}
