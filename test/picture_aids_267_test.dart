import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/guidebook_round_generator.dart';
import 'package:quisquislingo_app/services/preset_recipes.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_articles.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 267 Revision 3: the picture aids (owner decisions of 9 October
/// 2026): Suggest pictures on the module page, and five further picture
/// exercises with Prefer picture exercises in the Round Wizard.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the Round Wizard', () {
    GuidebookRoundGenerator generator() => GuidebookRoundGenerator(
      randomSeed: 3,
      draftIds: _Ids(),
      now: () => _now,
      articles: WordLookupArticles.forLanguage('it'),
    );

    test('spelling tiles are letters, accents kept with their letter', () {
      expect(GuidebookRoundGenerator.spellingBlocks('caffè'), [
        'c',
        'a',
        'f',
        'f',
        'è',
      ]);
      expect(GuidebookRoundGenerator.hasPictures(_module), isTrue);
      expect(
        GuidebookRoundGenerator.hasPictures(
          GuidebookModule(
            id: 'few',
            title: 'Few',
            words: [_word('a', 'il gatto', 'the cat', 'cat')],
          ),
        ),
        isFalse,
      );
    });

    test('the plan proposes Discover, Practice, Listen and Test', () {
      // Owner decision of 9 October 2026: not Practice every time.
      List<RoundType> types(int count) => [
        for (var i = 0; i < count; i++)
          GuidebookRoundGenerator.defaultTypeFor(i, count),
      ];
      final (d, p, l, t) = (
        RoundType.discover,
        RoundType.practice,
        RoundType.listening,
        RoundType.test,
      );
      expect(types(1), [p]);
      expect(types(2), [d, p]);
      expect(types(3), [d, p, t]);
      expect(types(6), [d, p, p, p, p, t]);
      // The Listen Round switch, off by default: the middle Round.
      List<RoundType> withListen(int count) => [
        for (var i = 0; i < count; i++)
          GuidebookRoundGenerator.defaultTypeFor(i, count, listenRound: true),
      ];
      expect(withListen(2), [d, p]);
      expect(withListen(3), [d, l, t]);
      expect(withListen(4), [d, p, l, t]);
      expect(withListen(6), [d, p, p, l, p, t]);

      expect([
        for (final round
            in generator()
                .plan(
                  Guidebook(modules: [_module]),
                  focusModuleId: _module.id,
                  roundCount: 6,
                )
                .rounds)
          round.roundType,
      ], types(6));
      final plan = generator().plan(
        Guidebook(modules: [_module]),
        focusModuleId: _module.id,
        roundCount: 6,
        listenRound: true,
      );
      expect([for (final round in plan.rounds) round.roundType], withListen(6));
      // The Listen Round holds listening exercises only, and every type
      // makes its drafts.
      expect(
        plan.rounds[3].presetIds.toSet(),
        everyElement(
          isIn({'listening_choose_target', 'listening_image_choice'}),
        ),
      );
      final drafts = generator().createDrafts(
        Guidebook(modules: [_module]),
        plan,
      );
      expect([for (final round in drafts) round.roundType], withListen(6));
    });

    test('nothing is asked twice in a Round', () {
      // Owner report of 9 October 2026: exercises the Wizard made were red
      // with ROUND_DUPLICATE_CONTENT (the sample has il conto twice, at the
      // restaurant and at the bank, and four sentences for 8 exercises).
      for (final seed in [1, 2, 3]) {
        for (final pictures in [true, false]) {
          expect(
            _duplicates(_sampleWithRounds(seed: seed, pictures: pictures)),
            isEmpty,
            reason: 'seed $seed, pictures $pictures',
          );
        }
      }
      // Two Matches of the same words are still the same exercise.
      expect(_duplicates(_withMatchCopy(_sampleWithRounds())), hasLength(1));
    });

    testWidgets('Audit in an exercise menu shows why its card is red', (
      tester,
    ) async {
      // Owner request of 9 October 2026.
      final course = _withMatchCopy(_sampleWithRounds());
      final lesson = course.lessons.first;
      final (index, round) = lesson.rounds.indexed.firstWhere(
        (entry) => entry.$2.exercises.any((e) => e.id == 'match_copy'),
      );
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: RoundEditorScreen(
            course: course,
            lesson: lesson,
            round: round,
            roundIndex: index,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final actions = find.byKey(const ValueKey('exercise-actions-match_copy'));
      await tester.scrollUntilVisible(
        actions,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Audit').last);
      await tester.pumpAndSettle();
      expect(find.text('Exercise Audit'), findsOneWidget);
      expect(
        find.textContaining('appears more than once in this round'),
        findsWidgets,
      );
    });

    test('Prefer picture exercises makes every second one a picture', () {
      final guidebook = Guidebook(modules: [_module]);
      final preferred = generator().plan(
        guidebook,
        focusModuleId: _module.id,
        roundCount: 6,
        exercisesPerRound: 8,
        preferPictures: true,
      );
      for (final round in preferred.rounds) {
        for (var i = 1; i < round.presetIds.length; i += 2) {
          expect(
            GuidebookRoundGenerator.picturePresets,
            contains(round.presetIds[i]),
            reason: 'Round ${round.index + 1}, exercise ${i + 1}',
          );
        }
        for (var i = 0; i < round.presetIds.length; i += 2) {
          expect(
            GuidebookRoundGenerator.picturePresets,
            isNot(contains(round.presetIds[i])),
          );
        }
      }
      final plain = generator().plan(
        guidebook,
        focusModuleId: _module.id,
        roundCount: 6,
        exercisesPerRound: 8,
      );
      expect(
        plain.rounds.every(
          (round) => [
            for (var i = 1; i < round.presetIds.length; i += 2)
              round.presetIds[i],
          ].every(GuidebookRoundGenerator.picturePresets.contains),
        ),
        isFalse,
      );
    });

    test('review slots stay reviews when earlier modules have no pictures', () {
      final saluti = GuidebookModule(
        id: 'saluti',
        title: 'Saluti',
        words: [
          _word('g1', 'ciao', 'hi'),
          _word('g2', 'grazie', 'thank you'),
          _word('g3', 'prego', 'you are welcome'),
        ],
      );
      final guidebook = Guidebook(modules: [saluti, _module]);
      final wizard = generator();
      final plan = wizard.plan(
        guidebook,
        roundCount: 3,
        exercisesPerRound: 8,
        preferPictures: true,
      );
      final pictured = plan.rounds.where(
        (round) => round.focusModuleId == _module.id,
      );
      expect(pictured, isNotEmpty);
      for (final round in pictured) {
        expect(round.reviewPositions, isNotEmpty);
        for (final position in round.reviewPositions) {
          expect(
            GuidebookRoundGenerator.picturePresets,
            isNot(contains(round.presetIds[position])),
          );
        }
        expect(wizard.wordsOf(guidebook, round), contains('Review: Saluti'));
      }
    });

    test('the five picture presets, built as their forms build them', () {
      final guidebook = Guidebook(modules: [_module]);
      final wizard = generator();
      final plan = wizard.plan(
        guidebook,
        focusModuleId: _module.id,
        roundCount: 12,
        exercisesPerRound: 15,
        preferPictures: true,
      );
      final drafts = wizard.createDrafts(guidebook, plan);
      final byPreset = <String, List<Exercise>>{};
      for (final round in drafts) {
        for (final exercise in round.exercises) {
          final preset = exercise.authoringMetadata['presetId'] as String?;
          if (preset == null) continue;
          (byPreset[preset] ??= []).add(exercise);
          expect(
            PresetRecipes.represents(exercise, preset),
            isTrue,
            reason: preset,
          );
          expect(
            CourseAuditService()
                .auditExercise(exercise, location: preset)
                .where((issue) => issue.severity == AuditSeverity.error),
            isEmpty,
            reason: preset,
          );
        }
      }
      for (final preset in const [
        'picture_choice',
        'image_word',
        'picture_blocks',
        'picture_name',
        'listening_image_choice',
      ]) {
        expect(byPreset[preset], isNotEmpty, reason: preset);
      }

      // Spell the word: the word without its article, at most 12 letters.
      final spelled = {
        for (final exercise in byPreset['image_word']!)
          PresetRecipes.decompose(
            exercise,
            'image_word',
          ).order.split('\n').join(),
      };
      expect(spelled, isNot(contains('aspirapolvere')));
      expect(
        spelled.difference({'gatto', 'acqua', 'cani', 'caffè', 'mela'}),
        isEmpty,
      );
      // A plural word keeps its Plural mark.
      final dogs = byPreset.values
          .expand((list) => list)
          .map((exercise) {
            final preset = exercise.authoringMetadata['presetId'] as String;
            return PresetRecipes.decompose(exercise, preset);
          })
          .where((values) => values.pluralPictures.isNotEmpty);
      expect(
        dogs.every(
          (values) =>
              values.pluralPictures.every((asset) => asset.contains('dog')),
        ),
        isTrue,
      );
      expect(dogs, isNotEmpty);

      // Name what you see: an entry of two words or more, a few extra
      // blocks that are not in the answer.
      for (final exercise in byPreset['picture_blocks']!) {
        final values = PresetRecipes.decompose(exercise, 'picture_blocks');
        final order = values.order.split('\n');
        final extras = values.extraWords.trim().isEmpty
            ? const <String>[]
            : values.extraWords.split('\n');
        expect(order.length, greaterThanOrEqualTo(2));
        expect(extras.length, lessThanOrEqualTo(2));
        expect(extras.toSet().intersection(order.toSet()), isEmpty);
      }
      // Type what you see accepts the entry's Target.
      for (final exercise in byPreset['picture_name']!) {
        final values = PresetRecipes.decompose(exercise, 'picture_name');
        expect(values.accepted, isNotEmpty);
        expect(values.imageAsset, isNotEmpty);
      }
      for (final exercise in byPreset['listening_image_choice']!) {
        final values = PresetRecipes.decompose(
          exercise,
          'listening_image_choice',
        );
        expect(values.tts, isNotEmpty);
        expect(values.icons.split('\n').length, greaterThanOrEqualTo(2));
      }
    });

    testWidgets('the switch is on with pictures and greyed without', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<SwitchListTile> open(GuidebookModule module) async {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(module.id),
            home: GuidebookRoundGeneratorScreen(
              course: _course(),
              lesson: Lesson(
                lessonId: 'lesson',
                title: 'Casa',
                rounds: const [],
                guidebook: Guidebook(modules: [module]),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.widget<SwitchListTile>(
          find.byKey(const Key('generator-prefer-pictures')),
        );
      }

      final pictured = await open(_module);
      expect(pictured.value, isTrue);
      expect(pictured.onChanged, isNotNull);
      final plain = await open(
        GuidebookModule(
          id: 'plain',
          title: 'Plain',
          words: [
            _word('p1', 'ciao', 'hi'),
            _word('p2', 'grazie', 'thank you'),
            _word('p3', 'prego', 'you are welcome'),
          ],
        ),
      );
      expect(plain.value, isFalse);
      expect(plain.onChanged, isNull);
    });
  });

  group('Suggest pictures on the module page', () {
    Future<GuidebookModule? Function()> open(
      WidgetTester tester,
      GuidebookModule module, {
      Course? course,
      ExerciseImageMetadataService? catalog,
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      GuidebookModule? done;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  done = await Navigator.of(context).push<GuidebookModule>(
                    MaterialPageRoute(
                      builder: (_) => GuidebookModuleEditorScreen(
                        module: module,
                        course: course ?? _course(),
                        ids: TimestampAuthoringIdGenerator(seed: 2673),
                        metadataService: catalog ?? _FakeCatalog(_catalog),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return () => done;
    }

    // Build 270 Revision 7: never a button that does nothing.
    testWidgets('says so when the picture library cannot be read', (
      tester,
    ) async {
      await open(
        tester,
        GuidebookModule(
          id: 'm',
          title: 'Al bar',
          words: [_word('w0', 'il gatto', 'the cat')],
        ),
        catalog: _UnreadableCatalog(),
      );
      final suggest = find.byKey(
        const Key('guidebook-module-suggest-pictures'),
      );
      await tester.ensureVisible(suggest);
      await tester.tap(suggest);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('guidebook-module-suggest-pictures-unavailable')),
        findsOneWidget,
      );
    });

    testWidgets('fills empty rows of a reopened module, never a chosen one', (
      tester,
    ) async {
      final done = await open(
        tester,
        GuidebookModule(
          id: 'm',
          title: 'Al bar',
          words: [
            _word('w0', 'il gatto', 'the cat'),
            _word('w1', 'la mela', 'an apple'),
            _word('w2', 'il caffè', 'coffee', 'apple'),
            _word('w3', "l'arancia", 'orange'),
            _word('w4', 'ciao', 'hi'),
          ],
        ),
      );
      // Reopened: no prefill by itself.
      expect(
        find.byKey(const ValueKey('guidebook-module-word-0-picture-suggested')),
        findsNothing,
      );
      final suggest = find.byKey(
        const Key('guidebook-module-suggest-pictures'),
      );
      await tester.ensureVisible(suggest);
      await tester.tap(suggest);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('guidebook-module-word-0-picture-suggested')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guidebook-module-word-1-picture-suggested')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('guidebook-module-word-2-picture-suggested')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('guidebook-module-word-3-picture-matches')),
        findsOneWidget,
      );
      expect(
        find.text(
          'QQL suggested 2 pictures; 1 word has several matching pictures. '
          'Tap a picture to change it.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('guidebook-module-done')));
      await tester.pumpAndSettle();
      final module = done()!;
      expect(module.words[0].picture?.asset, 'assets/exercise_images/cat.webp');
      expect(
        module.words[1].picture?.asset,
        'assets/exercise_images/apple.webp',
      );
      // The picture the author chose stays.
      expect(
        module.words[2].picture?.asset,
        'assets/exercise_images/apple.webp',
      );
      expect(module.words[3].picture, isNull);
      expect(module.words[4].picture, isNull);
    });

    testWidgets('only in a Course to or from English', (tester) async {
      await open(
        tester,
        GuidebookModule(
          id: 'm',
          title: 'Saluti',
          words: [_word('w0', 'hola', 'ciao')],
        ),
        course: _course(source: 'Italian', target: 'Spanish', tts: 'es-ES'),
      );
      expect(
        find.byKey(const Key('guidebook-module-suggest-pictures')),
        findsNothing,
      );
    });
  });
}

final _now = DateTime.utc(2026, 10, 9, 12);

GuidebookEntry _word(
  String id,
  String target,
  String source, [
  String? picture,
  bool plural = false,
]) => GuidebookEntry(
  id: id,
  target: target,
  source: source,
  picture: picture == null
      ? null
      : GuidebookPicture(
          asset: 'assets/exercise_images/$picture.webp',
          plural: plural,
        ),
);

final _module = GuidebookModule(
  id: 'module_1',
  title: 'Casa',
  sentences: [
    _word('s1', 'Il gatto beve l\'acqua.', 'The cat drinks the water.'),
    _word('s2', 'Mangio la mela.', 'I eat the apple.'),
  ],
  words: [
    _word('w1', 'il gatto', 'the cat', 'cat'),
    _word('w2', "l'acqua", 'the water', 'water'),
    _word('w3', 'i cani', 'the dogs', 'dog', true),
    _word('w4', 'il caffè', 'the coffee', 'coffee'),
    _word('w5', "l'aspirapolvere", 'the vacuum cleaner', 'vacuum_cleaner'),
    _word('w6', 'la mela', 'the apple', 'apple'),
    _word('w7', 'ciao', 'hi'),
  ],
);

Course _course({
  String source = 'English',
  String target = 'Italian',
  String tts = 'it-IT',
}) => Course(
  courseId: 'pictures',
  learningLanguage: target,
  interfaceLanguage: source,
  sourceLanguage: source,
  targetLanguage: target,
  title: 'Pictures',
  ttsLanguage: tts,
  lessons: const [],
);

ExerciseImageMetadata _picture(String id, String label, String category) =>
    ExerciseImageMetadata(
      id: id,
      label: label,
      category: category,
      tags: const ['tag'],
      assetPath: 'assets/exercise_images/$id.webp',
      origin: 'bundled',
    );

final _catalog = [
  _picture('apple', 'Apple', 'food_drinks'),
  _picture('cat', 'Cat', 'animals'),
  _picture('orange_fruit', 'Orange', 'food_drinks'),
  _picture('orange_colour', 'Orange', 'colors'),
  _picture('coffee', 'Coffee', 'food_drinks'),
];

class _FakeCatalog extends ExerciseImageMetadataService {
  _FakeCatalog(this.records);
  final List<ExerciseImageMetadata> records;

  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async => records;
}

class _UnreadableCatalog extends ExerciseImageMetadataService {
  @override
  Future<List<ExerciseImageMetadata>> loadCatalog() async =>
      throw const FormatException('The picture library could not be read.');
}

class _Ids implements AuthoringIdGenerator {
  var _next = 0;
  @override
  String next(String kind) => '${kind}_${_next++}';
}

/// A deep copy of a JSON map.
Map<String, dynamic> jsonDecodeCopy(Map<dynamic, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

/// The Course Wizard's sample Lesson with the Round Wizard's Rounds.
Course _sampleWithRounds({int seed = 1, bool pictures = true}) {
  var course = CourseWizardLessons.applyTo(
    CourseLibraryOperations(clock: () => _now).newWizardCourse(
      creator: const LearnerProfile(
        learnerProfileId: '12345678-1234-4234-9234-123456789abc',
        displayName: 'Author',
      ),
      title: 'Italian at the bar',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      sourceLanguageTag: 'en',
      targetLanguageTag: 'it',
    ),
    CourseWizardSample.lessons,
    now: _now,
    ids: _Ids(),
  );
  course = CourseWizardGuidebook.withModules(
    course,
    course.lessons.first.lessonId,
    CourseWizardSample.guidebook(_Ids()),
    state: PublicationState.published,
    now: _now,
  );
  final guidebook = course.lessons.first.guidebook;
  final generator = GuidebookRoundGenerator(
    randomSeed: seed,
    draftIds: _Ids(),
    now: () => _now,
    articles: WordLookupArticles.forLanguage('it'),
  );
  final plan = generator.plan(
    guidebook,
    roundCount: 6,
    exercisesPerRound: 8,
    preferPictures: pictures,
  );
  return CourseWizardRounds.withRounds(
    course,
    course.lessons.first.lessonId,
    generator.createDrafts(guidebook, plan),
    now: _now,
  );
}

/// [course] with a copy of its first Match, `match_copy`, in the same Round.
Course _withMatchCopy(Course course) {
  final json = course.toJson();
  final rounds = ((json['lessons'] as List).first as Map)['rounds'] as List;
  final (owner, match) = [
    for (final round in rounds)
      for (final content in (round as Map)['content'] as List)
        if (((content as Map)['exercise'] as Map?)?['primitive'] == 'match')
          (round, content),
  ].first;
  (owner['content'] as List).add(jsonDecodeCopy(match)..['id'] = 'match_copy');
  return Course.fromJson(json);
}

List<CourseAuditIssue> _duplicates(Course course) => [
  for (final issue in CourseAuditService().auditCourse(course).issues)
    if (issue.code == 'ROUND_DUPLICATE_CONTENT') issue,
];
