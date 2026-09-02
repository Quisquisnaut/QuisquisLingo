import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/screens/flag_game_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/screens/world_flag_reference_screen.dart';
import 'package:quisquislingo_app/services/flag_game_engine.dart';
import 'package:quisquislingo_app/services/flag_game_score_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/sound_effect_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/learner_avatar.dart';
import 'package:quisquislingo_app/widgets/world_flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sounds extends SoundEffectService {
  int suspense = 0;
  int victory = 0;
  int defeat = 0;

  @override
  Future<void> playSuspense() async => suspense++;

  @override
  Future<void> playVictory() async => victory++;

  @override
  Future<void> playDefeat() async => defeat++;

  @override
  Future<void> dispose() async {}
}

class _Repository extends WorldFlagRepository {
  final List<WorldFlagEntity> values;

  _Repository(this.values);

  @override
  Future<List<WorldFlagEntity>> load() async => values;
}

class _FixedEngine extends FlagGameEngine {
  final List<FlagGameQuestion> questions;

  _FixedEngine(this.questions);

  @override
  List<FlagGameQuestion> createGame({
    required List<WorldFlagEntity> entities,
    required FlagGameMode mode,
    List<String> previousTargetOrder = const [],
  }) => questions;
}

class _Clock {
  _Clock(this.value);
  DateTime value;
  DateTime call() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<WorldFlagEntity> entities;

  setUpAll(() {
    entities = WorldFlagRepository.parseManifest(
      File('assets/world_flags/manifest.json').readAsStringSync(),
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'QuisquisLingo',
      packageName: 'quisquislingo_app',
      version: '2.0.23',
      buildNumber: '223',
      buildSignature: '',
    );
  });

  test('seeded game has 12 distinct targets and five fair options', () {
    final engine = FlagGameEngine(random: Random(222));
    final questions = engine.createGame(
      entities: entities,
      mode: FlagGameMode.allFlags,
    );

    expect(questions, hasLength(12));
    expect(
      questions.map((question) => question.target.id).toSet(),
      hasLength(12),
    );
    final poolIds = WorldFlagRepository.poolFor(
      entities,
      FlagGameMode.allFlags,
    ).map((entity) => entity.id).toSet();
    for (final question in questions) {
      expect(question.options, hasLength(5));
      expect(question.options.map((option) => option.id).toSet(), hasLength(5));
      expect(
        question.options.where((option) => option.id == question.target.id),
        hasLength(1),
      );
      expect(
        question.options.map((option) => option.id),
        everyElement(isIn(poolIds)),
      );
      for (final option in question.options) {
        expect(
          question.target.avoidAsDistractorWith,
          isNot(contains(option.id)),
        );
      }
    }
    expect(
      questions.map((question) => question.correctOptionIndex).toSet().length,
      greaterThan(1),
    );
  });

  test('distractors prefer the most similar fair candidates', () {
    final engine = FlagGameEngine(random: Random(7));
    final pool = WorldFlagRepository.poolFor(entities, FlagGameMode.iso);
    final question = engine
        .createGame(entities: entities, mode: FlagGameMode.iso)
        .first;
    final fair = pool.where(
      (candidate) =>
          candidate.id != question.target.id &&
          !candidate.avoidAsDistractorWith.contains(question.target.id) &&
          !question.target.avoidAsDistractorWith.contains(candidate.id),
    );
    final bestAvailable = fair
        .map((candidate) => engine.similarityScore(question.target, candidate))
        .reduce(max);
    final bestChosen = question.options
        .where((option) => option.id != question.target.id)
        .map((candidate) => engine.similarityScore(question.target, candidate))
        .reduce(max);
    expect(bestChosen, bestAvailable);
  });

  test('an immediately repeated seeded order is changed when avoidable', () {
    final first = FlagGameEngine(
      random: Random(10),
    ).createGame(entities: entities, mode: FlagGameMode.unMembers);
    final previous = first.map((question) => question.target.id).toList();
    final second = FlagGameEngine(random: Random(10)).createGame(
      entities: entities,
      mode: FlagGameMode.unMembers,
      previousTargetOrder: previous,
    );
    expect(second.map((question) => question.target.id), isNot(previous));
    expect(second.map((question) => question.target.id).toSet(), hasLength(12));
  });

  testWidgets('setup uses the approved intro and cumulative pool labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlagGameScreen(
          repository: _Repository(entities),
          soundEffectService: _Sounds(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Each game has 12 flags, with 5 answer choices per question. Select the flag pool for your game.',
      ),
      findsOneWidget,
    );
    const labels = {
      FlagGameMode.unMembers: 'UN',
      FlagGameMode.iso: 'UN + ISO',
      FlagGameMode.isoPlusShortlist: 'UN + ISO + Shortlist',
      FlagGameMode.allFlags: 'All Flags',
    };
    for (final entry in labels.entries) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('flag-game-mode-${entry.key.name}')),
          matching: find.text(entry.value),
        ),
        findsOneWidget,
      );
    }
    expect(find.text('Extra Flags'), findsNothing);
    expect(find.text('Language-related flags'), findsOneWidget);
  });

  testWidgets('feedback is immediate below the flag with unchanged sounds', (
    tester,
  ) async {
    final sounds = _Sounds();
    final questions = _fixedQuestions(entities);
    await tester.pumpWidget(
      MaterialApp(
        home: FlagGameScreen(
          repository: _Repository(entities),
          engine: _FixedEngine(questions),
          soundEffectService: sounds,
          correctAnswerFeedbackDuration: const Duration(milliseconds: 20),
          wrongAnswerFeedbackDuration: const Duration(milliseconds: 10),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('flag-game-start')));
    await tester.pump();

    final first = questions.first;
    final wrong = first.options.firstWhere(
      (option) => option.id != first.target.id,
    );
    await tester.tap(find.byKey(ValueKey('flag-game-answer-${wrong.id}')));
    await tester.pump();
    expect(sounds.defeat, 1);
    expect(
      find.text('Correct answer: ${first.target.displayNameEn}'),
      findsOneWidget,
    );
    final flagBottom = tester.getBottomLeft(find.byType(WorldFlagArt)).dy;
    final feedbackTop = tester
        .getTopLeft(find.byKey(const Key('flag-game-feedback')))
        .dy;
    final firstAnswerTop = tester
        .getTopLeft(
          find.byKey(ValueKey('flag-game-answer-${first.options.first.id}')),
        )
        .dy;
    expect(feedbackTop, greaterThanOrEqualTo(flagBottom));
    expect(feedbackTop, lessThan(firstAnswerTop));
    await tester.pump(const Duration(milliseconds: 11));

    final second = questions[1];
    await tester.tap(
      find.byKey(ValueKey('flag-game-answer-${second.target.id}')),
    );
    await tester.pump();
    expect(sounds.victory, 1);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Correct!'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const Key('flag-game-feedback'))).dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(
                ValueKey('flag-game-answer-${second.options.first.id}'),
              ),
            )
            .dy,
      ),
    );
  });

  testWidgets('correct delay is 800 ms and wrong delay remains 700 ms', (
    tester,
  ) async {
    final questions = _fixedQuestions(entities);
    await tester.pumpWidget(
      MaterialApp(
        home: FlagGameScreen(
          repository: _Repository(entities),
          engine: _FixedEngine(questions),
          soundEffectService: _Sounds(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('flag-game-start')));
    await tester.pump();

    await tester.tap(
      find.byKey(ValueKey('flag-game-answer-${questions.first.target.id}')),
    );
    await tester.pump();
    expect(find.text('Correct'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 799));
    expect(find.byKey(const ValueKey('flag-game-question-0')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('flag-game-question-1')), findsOneWidget);

    final second = questions[1];
    final wrong = second.options.firstWhere(
      (option) => option.id != second.target.id,
    );
    await tester.tap(find.byKey(ValueKey('flag-game-answer-${wrong.id}')));
    await tester.pump();
    expect(
      find.text('Correct answer: ${second.target.displayNameEn}'),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 699));
    expect(find.byKey(const ValueKey('flag-game-question-1')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const ValueKey('flag-game-question-2')), findsOneWidget);
  });

  testWidgets('timer starts when question one is visible and ends after 12', (
    tester,
  ) async {
    final clock = _Clock(DateTime(2026, 9, 2, 12));
    final questions = _fixedQuestions(entities);
    await tester.pumpWidget(
      MaterialApp(
        home: FlagGameScreen(
          repository: _Repository(entities),
          engine: _FixedEngine(questions),
          soundEffectService: _Sounds(),
          now: clock.call,
          correctAnswerFeedbackDuration: Duration.zero,
          wrongAnswerFeedbackDuration: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();
    clock.value = clock.value.add(const Duration(minutes: 5));
    await tester.tap(find.byKey(const Key('flag-game-start')));
    await tester.pump();
    clock.value = clock.value.add(const Duration(seconds: 18));

    for (var index = 0; index < questions.length; index++) {
      final target = questions[index].target;
      await tester.tap(find.byKey(ValueKey('flag-game-answer-${target.id}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(find.byKey(const Key('flag-game-results')), findsOneWidget);
    expect(find.text('12 / 12'), findsOneWidget);
    expect(find.text('Perfect flags! Brilliant work!'), findsOneWidget);
    expect(find.text('18.0s'), findsOneWidget);
  });

  testWidgets('setup, questions and references do not overflow phone widths', (
    tester,
  ) async {
    final responsiveQuestions = _fixedQuestions(entities);
    final longestNameTarget = entities.reduce(
      (left, right) => left.displayNameEn.length >= right.displayNameEn.length
          ? left
          : right,
    );
    responsiveQuestions[0] = FlagGameQuestion(
      target: longestNameTarget,
      options: [
        longestNameTarget,
        ...entities
            .where((entity) => entity.id != longestNameTarget.id)
            .take(4),
      ],
    );
    for (final themeMode in ThemeMode.values) {
      for (final width in [320.0, 375.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 760));
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: FlagGameScreen(
              key: ValueKey('${themeMode.name}-$width'),
              repository: _Repository(entities),
              engine: _FixedEngine(responsiveQuestions),
              soundEffectService: _Sounds(),
            ),
          ),
        );
        await _pumpFrames(tester);
        expect(
          find.byKey(const Key('flag-game-mode-selector')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('flag-game-reference-buttons')),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${themeMode.name} setup width $width',
        );
        await tester.tap(find.byKey(const Key('flag-game-start')));
        await tester.pump();
        expect(
          find.byKey(const ValueKey('flag-game-question-0')),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${themeMode.name} question width $width',
        );
        await tester.tap(
          find.byKey(
            ValueKey(
              'flag-game-answer-${responsiveQuestions.first.options[1].id}',
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text('Correct answer: ${longestNameTarget.displayNameEn}'),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${themeMode.name} long feedback width $width',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeMode,
            home: WorldFlagReferenceScreen(
              key: ValueKey('reference-${themeMode.name}-$width'),
              category: WorldFlagReferenceCategory.languageRelatedFlags,
              entities: WorldFlagRepository.referenceFor(
                entities,
                WorldFlagReferenceCategory.languageRelatedFlags,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('flag-reference-search')), findsOneWidget);
        expect(
          find.byKey(const Key('flag-reference-description')),
          findsOneWidget,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${themeMode.name} reference width $width',
        );
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('US and UM render in game and reference at narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final entityId in [
      'united_states',
      'united_states_minor_outlying_islands',
    ]) {
      final entity = entities.singleWhere((entity) => entity.id == entityId);
      final questions = _fixedQuestions(entities);
      questions[0] = FlagGameQuestion(
        target: entity,
        options: [
          entity,
          ...entities.where((candidate) => candidate.id != entity.id).take(4),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: FlagGameScreen(
            repository: _Repository(entities),
            engine: _FixedEngine(questions),
            soundEffectService: _Sounds(),
          ),
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('flag-game-start')));
      await _pumpFrames(tester);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is WorldFlagArt && widget.entity.id == entityId,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: WorldFlagReferenceScreen(
            category: entity.isoAlpha2 == 'US'
                ? WorldFlagReferenceCategory.unMembers
                : WorldFlagReferenceCategory.isoExtras,
            entities: [entity],
          ),
        ),
      );
      await _pumpFrames(tester);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is WorldFlagArt && widget.entity.id == entityId,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Settings opens only on five rapid taps and returns naturally', (
    tester,
  ) async {
    final sounds = _Sounds();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          course: _course(),
          onManageLearners: (_) async {},
          soundEffectService: sounds,
          flagGameBuilder: (_) => const Scaffold(body: Text('Hidden flags')),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      find.byKey(const Key('settings-flag-game-trigger')),
    );
    expect(find.byTooltip('Flag Game'), findsOneWidget);

    for (var tap = 0; tap < 4; tap++) {
      await tester.tap(find.byKey(const Key('settings-flag-game-trigger')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Hidden flags'), findsNothing);
    expect(sounds.suspense, 0);

    await tester.tap(find.byKey(const Key('settings-flag-game-trigger')));
    await _pumpFrames(tester);
    expect(find.text('Hidden flags'), findsOneWidget);
    expect(sounds.suspense, 1);
    Navigator.of(tester.element(find.text('Hidden flags'))).pop();
    await _pumpFrames(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('reference descriptions and scoped live search are consistent', (
    tester,
  ) async {
    for (final category in WorldFlagReferenceCategory.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: WorldFlagReferenceScreen(
            key: ValueKey(category.name),
            category: category,
            entities: WorldFlagRepository.referenceFor(entities, category),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(category.description), findsOneWidget);
      expect(find.byKey(const Key('flag-reference-search')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: category.name);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: WorldFlagReferenceScreen(
          category: WorldFlagReferenceCategory.languageRelatedFlags,
          entities: WorldFlagRepository.referenceFor(
            entities,
            WorldFlagReferenceCategory.languageRelatedFlags,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('flag-reference-search')),
      '  SÁPMI  ',
    );
    await tester.pump();
    expect(find.text('Sámi'), findsOneWidget);
    expect(find.text('Roma'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('flag-reference-search')),
      'Wales',
    );
    await tester.pump();
    expect(find.text('No flags found'), findsOneWidget);

    await tester.tap(find.byKey(const Key('flag-reference-clear-search')));
    await tester.pump();
    expect(find.text('Breton'), findsOneWidget);
    expect(find.text('Cornish'), findsOneWidget);
    expect(find.text('No flags found'), findsNothing);
  });

  testWidgets('scorecard always shows four modes and duplicate-name avatars', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profiles = ProfileService();
    final scores = FlagGameScoreService(profileService: profiles);
    for (var index = 1; index <= 2; index++) {
      final profile = await profiles.createProfile(
        'Marco',
        learnerProfileId:
            '00000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
        skinTone: index == 1 ? 'light' : 'dark',
      );
      await profiles.setActiveProfileById(profile.learnerProfileId);
      await scores.recordResult(
        mode: FlagGameMode.unMembers,
        score: 10 + index,
        elapsedTime: Duration(seconds: 15 + index),
        achievedAt: DateTime(2026, 9, 2, 12, index),
      );
    }
    await tester.pumpWidget(
      MaterialApp(
        home: FlagGameScreen(
          repository: _Repository(entities),
          engine: _FixedEngine(_fixedQuestions(entities)),
          soundEffectService: _Sounds(),
          scoreService: scores,
        ),
      ),
    );
    await _pumpFrames(tester, count: 20);
    await tester.scrollUntilVisible(
      find.byKey(const Key('flag-game-scorecard')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('flag-game-scorecard')), findsOneWidget);
    for (final mode in FlagGameMode.values) {
      expect(
        find.byKey(ValueKey('flag-game-scorecard-${mode.name}')),
        findsOneWidget,
      );
    }
    expect(find.text('Marco'), findsNWidgets(2));
    expect(find.byType(LearnerAvatar), findsAtLeastNWidgets(2));
    expect(find.text('12/12 · 17.0 s · 02 Sep 2026'), findsOneWidget);
    expect(find.text('11/12 · 16.0 s · 02 Sep 2026'), findsOneWidget);
    final compactDetail = tester.widget<Text>(
      find.text('12/12 · 17.0 s · 02 Sep 2026'),
    );
    expect(compactDetail.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Flag Game persists only its score and not learning progress', (
    tester,
  ) async {
    const learnerId = '00000000-0000-4000-8000-000000000001';
    final profiles = ProfileService();
    await profiles.createProfile('Independent', learnerProfileId: learnerId);
    final prefix = ProfileService.prefixForProfileId(learnerId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${prefix}xp_IT', 120);
    await prefs.setInt('${prefix}week_xp', 45);
    await prefs.setInt('${prefix}streak_IT', 7);
    await prefs.setStringList('${prefix}v4_completed_rounds_course_course-a', [
      'round-1',
    ]);
    final protectedBefore = {
      for (final key in prefs.getKeys().where(
        (key) => !key.contains(FlagGameScoreService.keyPrefix),
      ))
        key: prefs.get(key),
    };
    final questions = _fixedQuestions(entities);
    await tester.pumpWidget(
      MaterialApp(
        home: FlagGameScreen(
          repository: _Repository(entities),
          engine: _FixedEngine(questions),
          soundEffectService: _Sounds(),
          correctAnswerFeedbackDuration: Duration.zero,
          wrongAnswerFeedbackDuration: Duration.zero,
          scoreService: FlagGameScoreService(profileService: profiles),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('flag-game-start')));
    await tester.pump();
    for (final question in questions) {
      await tester.tap(
        find.byKey(ValueKey('flag-game-answer-${question.target.id}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
    }
    await _pumpFrames(tester);

    expect(find.byKey(const Key('flag-game-results')), findsOneWidget);
    expect({
      for (final key in prefs.getKeys().where(
        (key) => !key.contains(FlagGameScoreService.keyPrefix),
      ))
        key: prefs.get(key),
    }, protectedBefore);
    expect(
      prefs.getKeys().where(
        (key) => key.contains(FlagGameScoreService.keyPrefix),
      ),
      hasLength(1),
    );
  });

  testWidgets('stale Settings tap sequences reset', (tester) async {
    final sounds = _Sounds();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          course: _course(),
          onManageLearners: (_) async {},
          soundEffectService: sounds,
          flagGameBuilder: (_) => const Scaffold(body: Text('Hidden flags')),
        ),
      ),
    );
    await _pumpUntil(
      tester,
      find.byKey(const Key('settings-flag-game-trigger')),
    );
    for (var tap = 0; tap < 4; tap++) {
      await tester.tap(find.byKey(const Key('settings-flag-game-trigger')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('settings-flag-game-trigger')));
    await tester.pump();
    expect(find.text('Hidden flags'), findsNothing);
    expect(sounds.suspense, 0);
  });
}

List<FlagGameQuestion> _fixedQuestions(List<WorldFlagEntity> entities) => [
  for (var index = 0; index < 12; index++)
    FlagGameQuestion(
      target: entities[index],
      options: [
        entities[index],
        entities[12 + index * 4],
        entities[13 + index * 4],
        entities[14 + index * 4],
        entities[15 + index * 4],
      ],
    ),
];

Course _course() => Course(
  courseId: 'flag-game-settings-test',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Italian',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  lessons: const [],
);

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 80; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 12}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
