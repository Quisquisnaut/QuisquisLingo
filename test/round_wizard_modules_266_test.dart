import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/plural_pictures.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/guidebook_fixtures.dart';

/// Build 266 Revision 3 (`docs/266_GUIDEBOOK_MODULES_PLAN.md` §7, owner
/// decisions of 5–8 October 2026): the Round Wizard over GuideBook modules.

const _cat = 'assets/exercise_images/cat.webp';
const _dog = 'assets/exercise_images/dog.webp';
const _apple = 'assets/exercise_images/apple.webp';
const _coffee = 'assets/exercise_images/coffee.webp';

GuidebookModule _module(
  String id,
  String title, {
  required List<GuidebookEntry> words,
  List<GuidebookEntry> sentences = const [],
  String overview = '',
}) => GuidebookModule(
  id: id,
  title: title,
  words: words,
  sentences: sentences,
  overview: overview,
);

/// Three modules: Saluti (first), Al bar (with Contexts and synonyms) and
/// Animali (with pictures, one Plural).
Guidebook _guidebook() => Guidebook(
  modules: [
    _module(
      'saluti',
      'Saluti',
      overview: 'Greetings for every time of day.',
      words: [
        testEntry('ciao', 'ciao = hi'),
        testEntry('salve', 'salve = hi'),
        testEntry('buongiorno', 'buongiorno = good morning'),
        testEntry('arrivederci', 'arrivederci = goodbye'),
      ],
      sentences: [testEntry('s_ciao', 'Ciao, come stai? = Hi, how are you?')],
    ),
    _module(
      'bar',
      'Al bar',
      words: [
        testEntry('conto', 'il conto = the bill', context: 'restaurant'),
        testEntry('conto_bank', 'il conto = the account', context: 'bank'),
        testEntry('mangia', 'mangia = you eat', context: 'formal'),
        testEntry('mangi', 'mangi = you eat', context: 'informal'),
        testEntry('caffe', 'il caffè = coffee'),
        testEntry('stanco', '{io} sono stanco = I am tired'),
      ],
      sentences: [
        testEntry('s_conto', 'Il conto, per favore. = The bill, please.'),
        testEntry('s_caffe', 'Vorrei il caffè. = I would like coffee.'),
      ],
    ),
    _module(
      'animali',
      'Animali',
      words: [
        testEntry(
          'gatto',
          'il gatto = the cat',
          picture: const GuidebookPicture(asset: _cat),
        ),
        testEntry(
          'gatti',
          'i gatti = the cats',
          picture: const GuidebookPicture(asset: _cat, plural: true),
        ),
        testEntry(
          'cane',
          'il cane = the dog',
          picture: const GuidebookPicture(asset: _dog),
        ),
        testEntry(
          'mela',
          'la mela = the apple',
          picture: const GuidebookPicture(asset: _apple),
        ),
        testEntry(
          'tazza',
          'la tazza = the cup',
          picture: const GuidebookPicture(asset: _coffee, plural: true),
        ),
      ],
    ),
  ],
);

class _Ids implements AuthoringIdGenerator {
  _Ids(this.prefix);
  final String prefix;
  int _next = 0;

  @override
  String next(String kind) => '${prefix}_${kind}_${_next++}';
}

void main() {
  final guidebook = _guidebook();
  final entryIds = {for (final entry in guidebook.entries) entry.id};
  GuidebookRoundGenerator generator([int seed = 1]) =>
      GuidebookRoundGenerator(randomSeed: seed, draftIds: _Ids('d'));

  group('the plan', () {
    test('All modules: each module its own curve, titled after it', () {
      final plan = generator().plan(guidebook, roundCount: 3);
      expect(plan.rounds, hasLength(9));
      expect(plan.focusModuleId, isNull);
      expect(plan.rounds.map((round) => round.title).take(3), [
        'Foundations: Saluti',
        'Practice: Saluti',
        'Use in context: Saluti',
      ]);
      expect(plan.rounds[3].title, 'Foundations: Al bar');
      expect(plan.rounds[8].focusModuleId, 'animali');
      expect(
        [for (final round in plan.rounds) round.opensModule],
        [true, false, false, true, false, false, true, false, false],
      );
    });

    test('a focus module, and the limits', () {
      final plan = generator().plan(
        guidebook,
        focusModuleId: 'bar',
        roundCount: 6,
      );
      expect(plan.rounds, hasLength(6));
      expect(plan.rounds.map((r) => r.focusModuleId).toSet(), {'bar'});
      expect(
        () => generator().plan(guidebook, roundCount: 9),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'At most 24 Rounds per run. With 3 modules, choose up to 8 Rounds '
                'per module.',
          ),
        ),
      );
      final small = Guidebook(
        modules: [
          ...guidebook.modules,
          _module('tiny', 'Tiny', words: [testEntry('uno', 'uno = one')]),
        ],
      );
      expect(generator().plan(small, roundCount: 2).skippedModules, ['Tiny']);
      expect(
        () => generator().plan(small, focusModuleId: 'tiny'),
        throwsA(isA<GuidebookGenerationException>()),
      );
    });

    test('review slots: a third, never first, none in the first module', () {
      final plan = generator().plan(guidebook, roundCount: 2);
      for (final round in plan.rounds) {
        if (round.focusModuleId == 'saluti') {
          expect(round.reviewPositions, isEmpty);
        } else {
          expect(round.reviewPositions, [3, 5]);
        }
      }
    });

    test('a Round can change its focus; the plan lists its words', () {
      final g = generator();
      final plan = g.plan(guidebook, focusModuleId: 'saluti', roundCount: 2);
      final changed = g.changeFocus(guidebook, plan.rounds.first, 'animali');
      expect(changed.focusModuleId, 'animali');
      expect(changed.title, 'Foundations: Animali');
      expect(changed.reviewPositions, isNotEmpty);
      final words = g.wordsOf(guidebook, changed);
      expect(words, startsWith('Focus: Animali — '));
      expect(words, contains('Review: '));
      expect(
        () => g.changeFocus(
          Guidebook(
            modules: [
              ...guidebook.modules,
              _module('tiny', 'Tiny', words: [testEntry('uno', 'uno = one')]),
            ],
          ),
          plan.rounds.first,
          'tiny',
        ),
        throwsA(isA<GuidebookGenerationException>()),
      );
    });

    test('pictures add the three picture presets', () {
      final animals = generator().plan(
        guidebook,
        focusModuleId: 'animali',
        roundCount: 3,
      );
      expect(
        animals.rounds.expand((round) => round.presetIds),
        containsAll(['icon_choice', 'picture_word_match']),
      );
      final bar = generator().plan(guidebook, focusModuleId: 'bar');
      expect(
        bar.rounds.expand((round) => round.presetIds),
        isNot(anyOf(contains('icon_choice'), contains('picture_word_match'))),
      );
      final flashcards = generator().changeType(
        guidebook,
        animals.rounds.first,
        RoundType.flashcard,
      );
      expect(flashcards.presetIds.toSet(), {'flashcard', 'picture_flashcard'});
    });
  });

  group('the drafts', () {
    late List<LearningRound> drafts;
    setUpAll(() {
      final g = generator(4);
      final plan = g.plan(guidebook, roundCount: 3, exercisesPerRound: 8);
      drafts = g.createDrafts(guidebook, plan);
    });

    Iterable<(LearningContent, Exercise)> exercises() sync* {
      for (final round in drafts) {
        for (final content in round.content) {
          final exercise = content.asRunnableExercise();
          if (exercise != null) yield (content, exercise);
        }
      }
    }

    test('valid, represented by their presets, each naming its entries', () {
      for (final (content, exercise) in exercises()) {
        final preset = exercise.editorTemplate;
        if (preset == 'before_you_start') {
          expect(content.sourceRefs, isEmpty);
          continue;
        }
        expect(
          PresetRecipes.represents(exercise, preset),
          isTrue,
          reason: preset,
        );
        expect(
          CourseAuditService()
              .auditExercise(exercise)
              .where((issue) => issue.severity == AuditSeverity.error),
          isEmpty,
          reason: preset,
        );
        expect(content.sourceRefs, isNotEmpty, reason: preset);
        expect(content.sourceRefs, everyElement(isIn(entryIds)));
      }
    });

    test('Rounds record their focus and the modules they reviewed', () {
      expect(drafts.map((round) => round.focusModuleId).toSet(), {
        'saluti',
        'bar',
        'animali',
      });
      for (final round in drafts) {
        if (round.focusModuleId == 'saluti') {
          expect(round.supportingModuleIds, isEmpty);
        } else {
          expect(round.supportingModuleIds, isNotEmpty);
          final order = guidebook.modules.map((m) => m.id).toList();
          expect(
            round.supportingModuleIds.map(order.indexOf),
            orderedEquals(
              [...round.supportingModuleIds.map(order.indexOf)]..sort(),
            ),
          );
          expect(
            round.supportingModuleIds,
            isNot(contains(round.focusModuleId)),
          );
        }
      }
    });

    test('the first Round of each module opens with its Overview', () {
      final cards = [
        for (final round in drafts)
          if (round.content.isNotEmpty &&
              round.content.first.exercise?.editorTemplate ==
                  'before_you_start')
            round,
      ];
      expect(cards.map((round) => round.focusModuleId), [
        'saluti',
        'bar',
        'animali',
      ]);
      String text(LearningRound round) => round
          .content
          .first
          .exercise!
          .promptElements
          .firstWhere((element) => element.role == 'intro')
          .text;
      expect(text(cards[0]), 'Greetings for every time of day.');
      expect(text(cards[1]), contains('“Al bar”'));
    });
  });

  group('one right answer', () {
    Exercise first(String preset, String moduleId, {int seed = 1}) {
      for (var s = seed; s < seed + 40; s++) {
        final g = GuidebookRoundGenerator(randomSeed: s, draftIds: _Ids('x'));
        final plan = g.plan(guidebook, focusModuleId: moduleId, roundCount: 3);
        for (final round in g.createDrafts(guidebook, plan)) {
          for (final content in round.content) {
            final exercise = content.asRunnableExercise();
            if (exercise?.editorTemplate == preset) return exercise!;
          }
        }
      }
      throw StateError('no $preset exercise');
    }

    test('the Context is shown with the translation', () {
      final pick = first('choice_target', 'bar');
      final draft = PresetRecipes.decompose(pick, 'choice_target');
      expect(draft.prompt, contains('('));
    });

    test('wrong answers: never the same Target, never a synonym', () {
      for (var s = 0; s < 12; s++) {
        final g = GuidebookRoundGenerator(randomSeed: s, draftIds: _Ids('w'));
        final plan = g.plan(guidebook, roundCount: 3);
        for (final round in g.createDrafts(guidebook, plan)) {
          for (final content in round.content) {
            final exercise = content.asRunnableExercise();
            if (exercise?.editorTemplate != 'choice_target') continue;
            final answers = PresetRecipes.decompose(
              exercise!,
              'choice_target',
            ).answers.split('\n');
            expect(answers.toSet(), hasLength(answers.length));
            // ciao and salve both mean "hi": never offered together.
            expect(
              answers.contains('ciao') && answers.contains('salve'),
              isFalse,
            );
          }
        }
      }
    });

    test('an entry that differs only by its Context is a wrong answer', () {
      final verbs = Guidebook(
        modules: [
          _module(
            'verbi',
            'Verbi',
            words: [
              testEntry('mangia', 'mangia = you eat', context: 'formal'),
              testEntry('mangi', 'mangi = you eat', context: 'informal'),
              testEntry('bevi', 'bevi = you drink'),
              testEntry('dormi', 'dormi = you sleep'),
            ],
          ),
        ],
      );
      var seen = 0;
      for (var s = 0; s < 10; s++) {
        final g = GuidebookRoundGenerator(randomSeed: s, draftIds: _Ids('m'));
        final plan = g.plan(verbs, roundCount: 3, exercisesPerRound: 12);
        for (final round in g.createDrafts(verbs, plan)) {
          for (final content in round.content) {
            final exercise = content.asRunnableExercise();
            if (exercise?.editorTemplate != 'choice_target') continue;
            final draft = PresetRecipes.decompose(exercise!, 'choice_target');
            final answers = draft.answers.split('\n');
            if (draft.prompt.contains('you eat (formal)')) {
              expect(answers, contains('mangi'));
              seen++;
            }
            if (draft.prompt.contains('you eat (informal)')) {
              expect(answers, contains('mangia'));
              seen++;
            }
          }
        }
      }
      expect(seen, greaterThan(0));
    });

    test('a typed answer accepts every synonym and the optional words', () {
      for (var s = 0; s < 40; s++) {
        final g = GuidebookRoundGenerator(randomSeed: s, draftIds: _Ids('t'));
        final plan = g.plan(guidebook, roundCount: 3, exercisesPerRound: 8);
        for (final round in g.createDrafts(guidebook, plan)) {
          for (final content in round.content) {
            final exercise = content.asRunnableExercise();
            if (exercise?.editorTemplate != 'type_translation_to_target') {
              continue;
            }
            final draft = PresetRecipes.decompose(
              exercise!,
              'type_translation_to_target',
            );
            final accepted = draft.accepted.split('\n');
            if (draft.prompt == 'hi') {
              expect(accepted, containsAll(['ciao', 'salve']));
            }
            if (draft.prompt == 'I am tired') {
              expect(accepted, contains('{io} sono stanco'));
            }
          }
        }
      }
    });
  });

  group('pictures', () {
    test('Plural carries over; one picture is never offered twice', () {
      var checked = 0;
      for (var s = 0; s < 20; s++) {
        final g = GuidebookRoundGenerator(randomSeed: s, draftIds: _Ids('p'));
        final plan = g.plan(guidebook, focusModuleId: 'animali', roundCount: 3);
        for (final round in g.createDrafts(guidebook, plan)) {
          for (final content in round.content) {
            final exercise = content.asRunnableExercise();
            final preset = exercise?.editorTemplate;
            if (preset != 'icon_choice' && preset != 'picture_word_match') {
              continue;
            }
            final draft = PresetRecipes.decompose(exercise!, preset!);
            final pictures = preset == 'icon_choice'
                ? draft.icons.split('\n')
                : [
                    for (final line in draft.pairs.split('\n'))
                      line.split('=').first.trim(),
                  ];
            expect(pictures.toSet(), hasLength(pictures.length));
            final marked = PluralPictures.markedIn(exercise);
            expect(
              marked.difference({_cat, _coffee}),
              isEmpty,
              reason: '$marked',
            );
            if (pictures.contains(_coffee)) {
              expect(marked, contains(_coffee));
            }
            checked++;
          }
        }
      }
      expect(checked, greaterThan(0));
    });
  });

  group('the screen', () {
    Future<void> open(WidgetTester tester, Guidebook guidebook) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final lesson = Lesson(
        lessonId: 'l1',
        title: 'Lesson',
        guidebook: guidebook,
        rounds: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GuidebookRoundGeneratorScreen(
            course: Course(
              courseId: 'wizard',
              learningLanguage: 'Italian',
              interfaceLanguage: 'English',
              sourceLanguage: 'English',
              targetLanguage: 'Italian',
              title: 'Wizard',
              ttsLanguage: 'it-IT',
              lessons: [lesson],
            ),
            lesson: lesson,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('All modules by default; counts per module; the limit', (
      tester,
    ) async {
      await open(tester, guidebook);
      final count = find.byKey(const Key('generator-round-count'));
      expect(tester.widget<TextField>(count).controller!.text, '3');
      expect(find.text('Rounds per module'), findsOneWidget);
      expect(
        find.text('3 modules × 3 Rounds × 8 exercises = 72 exercises'),
        findsOneWidget,
      );
      await tester.enterText(count, '9');
      await tester.pump();
      expect(
        find.textContaining('At most 24 Rounds per run. With 3 modules'),
        findsOneWidget,
      );
      // One module: the count becomes the number of Rounds, 6 by default.
      await tester.tap(find.byKey(const Key('generator-focus-module')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Al bar').last);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(count).controller!.text, '6');
      expect(find.text('Number of Rounds'), findsOneWidget);
    });

    testWidgets('the plan shows each Round\'s focus and words', (tester) async {
      await open(tester, guidebook);
      await tester.tap(find.byKey(const Key('generator-review-plan')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('guidebook-generator-plan')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('generator-round-words-0')))
            .data,
        startsWith('Focus: Saluti — '),
      );
      expect(
        find.byKey(const ValueKey('generator-round-focus-0')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('generator-round-focus-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Focus: Animali').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('generator-round-words-0')))
            .data,
        startsWith('Focus: Animali — '),
      );
    });
  });
}
