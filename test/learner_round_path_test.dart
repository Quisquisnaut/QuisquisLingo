import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const fixtureMascotAssets = <String>[
    'assets/mascots/qql-dog-tambourine.png',
    'assets/mascots/qql-monkey-sleeping.png',
  ];

  List<LearningRound> rounds(int count) => List.generate(
    count,
    (index) => LearningRound(
      id: 'round-${index + 1}',
      title: index.isEven
          ? 'Everyday words ${index + 1}'
          : 'Round ${index + 1}',
    ),
  );

  Widget app({
    required List<LearningRound> rounds,
    Set<String> completedRounds = const {},
    Set<String> perfectRounds = const {},
    List<String>? mascotAssets = fixtureMascotAssets,
    int mascotPositionOffset = 0,
    int roundPositionOffset = 0,
    double width = 430,
    ThemeMode themeMode = ThemeMode.light,
    void Function(LearningRound round)? onOpenRound,
  }) => MaterialApp(
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    themeMode: themeMode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: LearnerRoundPath(
            courseId: 'course-alpha',
            rounds: rounds,
            completedRounds: completedRounds,
            perfectRounds: perfectRounds,
            ttsSkippedPerfectRounds: const {},
            mascotAssets: mascotAssets,
            mascotPositionOffset: mascotPositionOffset,
            roundPositionOffset: roundPositionOffset,
            onOpenRound: onOpenRound ?? (_) {},
          ),
        ),
      ),
    ),
  );

  test('deterministic path uses both sides and same-side pairs', () {
    final sides = List.generate(24, learnerRoundPathSide);

    expect(sides, contains(LearnerRoundPathSide.left));
    expect(sides, contains(LearnerRoundPathSide.right));
    expect(
      List.generate(23, (index) => sides[index] == sides[index + 1]),
      contains(isTrue),
    );
    expect(
      List.generate(
        22,
        (index) =>
            sides[index] == sides[index + 1] &&
            sides[index + 1] == sides[index + 2],
      ),
      everyElement(isFalse),
    );
  });

  test('mascot slots use both free sides near the start of a Lesson', () {
    final positions = List.generate(
      10,
      (index) => index,
    ).where(learnerRoundPathShowsMascot).toList();
    final freeSides = positions
        .map(
          (index) => learnerRoundPathSide(index) == LearnerRoundPathSide.left
              ? LearnerRoundPathSide.right
              : LearnerRoundPathSide.left,
        )
        .toSet();

    expect(positions, [0, 3, 5, 8]);
    expect(freeSides, {LearnerRoundPathSide.left, LearnerRoundPathSide.right});
  });

  test('course identity gives mascots a stable full-set shuffle', () {
    const assets = <String>['a.png', 'b.png', 'c.png', 'd.png', 'e.png'];
    final alpha = learnerCourseMascotOrder('course-alpha', assets);
    final rebuiltAlpha = learnerCourseMascotOrder('course-alpha', assets);
    final beta = learnerCourseMascotOrder('course-beta', assets);

    expect(rebuiltAlpha, alpha);
    expect(beta, isNot(alpha));
    expect(alpha.toSet(), assets.toSet());
    expect(alpha, hasLength(assets.length));

    final reused = List.generate(
      assets.length * 2,
      (index) => learnerMascotAssetAtPosition(alpha, index),
    );
    expect(reused.take(assets.length).toSet(), hasLength(assets.length));
    expect(reused.skip(assets.length).toSet(), assets.toSet());
    expect(reused[assets.length], isIn(alpha));
    for (var index = 1; index < reused.length; index++) {
      expect(reused[index], isNot(reused[index - 1]));
    }
  });

  test('mascot cycle boundaries hold for one, two, and larger pools', () {
    for (final assetCount in [1, 2, 3, 9]) {
      final assets = List.generate(assetCount, (index) => 'mascot-$index.png');
      final selected = List.generate(
        assetCount * 3,
        (index) => learnerMascotAssetAtPosition(assets, index),
      );

      for (var cycle = 0; cycle < 3; cycle++) {
        expect(
          selected.skip(cycle * assetCount).take(assetCount).toSet(),
          assets.toSet(),
          reason: '$assetCount assets, cycle ${cycle + 1}',
        );
      }
      if (assetCount == 1) {
        expect(selected, everyElement(assets.single));
      } else {
        for (var index = 1; index < selected.length; index++) {
          expect(
            selected[index],
            isNot(selected[index - 1]),
            reason: '$assetCount assets at position $index',
          );
        }
      }
    }
  });

  test('bundled-size Lessons continue one course-wide mascot cycle', () {
    const assets = <String>[
      'a.png',
      'b.png',
      'c.png',
      'd.png',
      'e.png',
      'f.png',
    ];
    final lessons = List.generate(
      9,
      (index) => Lesson(
        lessonId: 'lesson-$index',
        title: 'Lesson $index',
        rounds: rounds(2),
      ),
    );
    final order = learnerCourseMascotOrder('sample_it_en_it', assets);
    final selected = <String>[];
    for (var lessonIndex = 0; lessonIndex < lessons.length; lessonIndex++) {
      final roundOffset = learnerRoundPositionOffsetForLesson(
        lessons,
        lessonIndex,
      );
      var mascotPosition = learnerMascotPositionOffsetForLesson(
        lessons,
        lessonIndex,
      );
      for (
        var roundIndex = 0;
        roundIndex < lessons[lessonIndex].rounds.length;
        roundIndex++
      ) {
        if (learnerRoundPathShowsMascot(
          roundIndex,
          roundPositionOffset: roundOffset,
        )) {
          selected.add(learnerMascotAssetAtPosition(order, mascotPosition++));
        }
      }
    }

    expect(learnerRoundPathMascotSlotCount(2), 1);
    expect(selected.take(assets.length).toSet(), hasLength(assets.length));
    expect(selected[assets.length], isIn(selected.take(assets.length)));
    for (var index = 1; index < selected.length; index++) {
      expect(selected[index], isNot(selected[index - 1]));
    }
  });

  test('mascot identity is not permanently tied to a path side', () {
    const assets = <String>[
      'a.png',
      'b.png',
      'c.png',
      'd.png',
      'e.png',
      'f.png',
    ];
    final order = learnerCourseMascotOrder('course-alpha', assets);
    final sidesByAsset = <String, Set<LearnerRoundPathSide>>{
      for (final asset in assets) asset: <LearnerRoundPathSide>{},
    };
    var mascotPosition = 0;
    for (var roundIndex = 0; roundIndex < 1200; roundIndex++) {
      if (!learnerRoundPathShowsMascot(roundIndex)) continue;
      final roundSide = learnerRoundPathSide(roundIndex);
      final freeSide = roundSide == LearnerRoundPathSide.left
          ? LearnerRoundPathSide.right
          : LearnerRoundPathSide.left;
      sidesByAsset[learnerMascotAssetAtPosition(order, mascotPosition++)]!.add(
        freeSide,
      );
    }

    expect(
      sidesByAsset.values,
      everyElement({LearnerRoundPathSide.left, LearnerRoundPathSide.right}),
    );
  });

  test('manifest filtering remains open to future PNG additions', () {
    final discovered = learnerMascotAssetsFromManifest([
      'assets/mascots/a.png',
      'assets/mascots/b.png',
      'assets/mascots/future-mascot.png',
      'assets/mascots/not-an-image.txt',
      'assets/exercise_images/not-a-mascot.png',
    ]);

    expect(discovered, [
      'assets/mascots/a.png',
      'assets/mascots/b.png',
      'assets/mascots/future-mascot.png',
    ]);
  });

  testWidgets('separate Lesson paths render one continuous mascot sequence', (
    tester,
  ) async {
    const assets = <String>[
      'a.png',
      'b.png',
      'c.png',
      'd.png',
      'e.png',
      'f.png',
    ];
    final lessons = List.generate(
      9,
      (index) => Lesson(
        lessonId: 'lesson-$index',
        title: 'Lesson $index',
        rounds: [
          LearningRound(id: 'lesson-$index-round-1', title: 'Round 1'),
          LearningRound(id: 'lesson-$index-round-2', title: 'Round 2'),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (
                  var lessonIndex = 0;
                  lessonIndex < lessons.length;
                  lessonIndex++
                )
                  SizedBox(
                    width: 430,
                    child: LearnerRoundPath(
                      courseId: 'sample_it_en_it',
                      rounds: lessons[lessonIndex].rounds,
                      completedRounds: const {},
                      perfectRounds: const {},
                      ttsSkippedPerfectRounds: const {},
                      mascotAssets: assets,
                      mascotPositionOffset:
                          learnerMascotPositionOffsetForLesson(
                            lessons,
                            lessonIndex,
                          ),
                      roundPositionOffset: learnerRoundPositionOffsetForLesson(
                        lessons,
                        lessonIndex,
                      ),
                      onOpenRound: (_) {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final actual = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName)
        .toList();
    final order = learnerCourseMascotOrder('sample_it_en_it', assets);
    expect(
      actual,
      List.generate(
        actual.length,
        (index) => learnerMascotAssetAtPosition(order, index),
      ),
    );
    expect(actual.take(assets.length).toSet(), hasLength(assets.length));
    for (var index = 1; index < actual.length; index++) {
      expect(actual[index], isNot(actual[index - 1]));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'production manifest discovery makes every current mascot renderable',
    (tester) async {
      final expected =
          Directory('assets/mascots')
              .listSync()
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.png'))
              .map((file) => 'assets/mascots/${file.uri.pathSegments.last}')
              .toList()
            ..sort();
      final discovered = (await tester.runAsync(
        () => loadLearnerMascotAssets(rootBundle),
      ))!;
      expect(discovered, expected);
      final validCycle = (await tester.runAsync(
        () => loadRenderableLearnerMascotAssets(rootBundle, [
          'assets/mascots/missing.png',
          expected.first,
          expected.last,
        ]),
      ))!;
      expect(validCycle, [expected.first, expected.last]);

      var roundCount = 0;
      var slotCount = 0;
      while (slotCount < discovered.length) {
        if (learnerRoundPathShowsMascot(roundCount)) slotCount++;
        roundCount++;
      }
      await tester.pumpWidget(
        app(rounds: rounds(roundCount), mascotAssets: discovered),
      );
      await tester.pumpAndSettle();

      final rendered = find
          .byType(Image)
          .evaluate()
          .map((element) => (element.widget as Image).image)
          .whereType<AssetImage>()
          .map((image) => image.assetName)
          .take(discovered.length)
          .toList();
      expect(rendered, hasLength(discovered.length));
      expect(rendered.toSet(), discovered.toSet());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home keeps one production mascot cycle across lazy bundled Lessons',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      PackageInfo.setMockInitialValues(
        appName: 'QuisquisLingo',
        packageName: 'com.quisquislingo.app',
        version: '2.0.23',
        buildNumber: '223',
        buildSignature: '',
      );
      SharedPreferences.setMockInitialValues({
        'one_time_notice_seen_welcome_2.0.23': true,
        'sound_effects_enabled': false,
      });
      await ProfileService().addProfile('Mascot Learner');

      late Course course;
      late List<String> discovered;
      await tester.runAsync(() async {
        course = await CourseService().loadCourse('IT');
        await SettingsService().setLastSelectedCourseCode('IT');
        await SettingsService().setIddqdModeEnabled(course.courseId, true);
        discovered = await loadProductionLearnerMascotAssets();
      });
      expect(discovered.length, greaterThan(1));

      Future<void> pumpUntil(Finder finder) async {
        for (var frame = 0; frame < 120; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (finder.evaluate().isNotEmpty) return;
        }
        fail('Timed out waiting for $finder');
      }

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      final alphaNotice = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'Alpha expiry' || widget.data == 'Alpha expired'),
      );
      await pumpUntil(alphaNotice);
      await tester.tap(find.text('OK'));
      await tester.pump();

      final learnerScroll = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            widget.physics is AlwaysScrollableScrollPhysics,
      );
      final mascotSurface = find.byWidgetPredicate((widget) {
        final key = widget.key;
        return key is ValueKey<String> &&
            key.value.startsWith('learner-round-mascot-surface-');
      });
      await pumpUntil(learnerScroll);
      final firstRoundPath = find.byKey(const Key('unified-round-tree')).first;
      await pumpUntil(firstRoundPath);
      expect(tester.getSize(firstRoundPath).width, greaterThanOrEqualTo(320));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await pumpUntil(mascotSurface);
      final selected = <String>[];
      for (final lesson in course.lessons) {
        final section = find.byKey(
          ValueKey('unified-lesson-section-${lesson.lessonId}'),
        );
        await tester.scrollUntilVisible(
          section,
          360,
          scrollable: learnerScroll,
        );
        await tester.pump(const Duration(milliseconds: 50));
        selected.addAll(
          tester
              .widgetList<Image>(
                find.descendant(of: section, matching: find.byType(Image)),
              )
              .map((image) => image.image)
              .whereType<AssetImage>()
              .map((image) => image.assetName)
              .where((asset) => asset.startsWith(learnerMascotAssetDirectory)),
        );
      }

      expect(selected.length, greaterThan(1));
      final firstCyclePrefix = selected.take(discovered.length).toList();
      expect(firstCyclePrefix.toSet(), hasLength(firstCyclePrefix.length));
      for (var index = 1; index < selected.length; index++) {
        expect(selected[index], isNot(selected[index - 1]));
      }
      expect(selected, everyElement(isIn(discovered)));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('same sequence rebuilds at the same positions with clear gaps', (
    tester,
  ) async {
    final sample = rounds(10);
    await tester.pumpWidget(app(rounds: sample));

    List<Rect> rects() => [
      for (final round in sample)
        tester.getRect(find.byKey(ValueKey('unified-round-${round.id}'))),
    ];

    final firstLayout = rects();
    expect(firstLayout[3].left, firstLayout[4].left);
    expect(firstLayout[3].bottom + 20, lessThanOrEqualTo(firstLayout[4].top));
    expect(firstLayout.map((rect) => rect.left).toSet().length, 2);

    await tester.pumpWidget(app(rounds: sample));
    expect(rects(), firstLayout);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one, two, and many Rounds retain valid path geometry', (
    tester,
  ) async {
    for (final count in [1, 2, 13]) {
      final sample = rounds(count);
      await tester.pumpWidget(app(rounds: sample));
      expect(find.byKey(const Key('unified-round-tree')), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(count));
      expect(tester.takeException(), isNull, reason: '$count Rounds');
    }
  });

  testWidgets('completion alone gives the icon its persistent bright accent', (
    tester,
  ) async {
    final sample = rounds(2);
    const completedColor = Color(0xFFFFB000);
    const incompleteColor = Color(0xFFFFEBC0);

    Color iconColor(String roundId) {
      final iconContainer = tester.widget<Container>(
        find.byKey(ValueKey('unified-round-icon-$roundId')),
      );
      return (iconContainer.decoration! as BoxDecoration).color!;
    }

    await tester.pumpWidget(
      app(rounds: sample, completedRounds: {sample.first.id}),
    );
    expect(iconColor(sample.first.id), completedColor);
    expect(iconColor(sample.last.id), incompleteColor);

    await tester.pumpWidget(
      app(rounds: sample, completedRounds: {sample.first.id}),
    );
    expect(iconColor(sample.first.id), completedColor);

    await tester.pumpWidget(
      app(rounds: sample, completedRounds: {sample.first.id}),
    );
    expect(iconColor(sample.first.id), completedColor);
  });

  testWidgets('completed-with-errors state does not require a Laurel', (
    tester,
  ) async {
    final sample = rounds(1);
    await tester.pumpWidget(
      app(rounds: sample, completedRounds: {sample.single.id}),
    );

    final iconContainer = tester.widget<Container>(
      find.byKey(ValueKey('unified-round-icon-${sample.single.id}')),
    );
    expect(
      (iconContainer.decoration! as BoxDecoration).color,
      const Color(0xFFFFB000),
    );
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Perfect'), findsNothing);
  });

  testWidgets('perfect completion uses two light Laurel branches', (
    tester,
  ) async {
    final sample = rounds(1);
    await tester.pumpWidget(
      app(
        rounds: sample,
        completedRounds: {sample.single.id},
        perfectRounds: {sample.single.id},
        mascotAssets: const [],
      ),
    );

    final round = find.byKey(ValueKey('unified-round-${sample.single.id}'));
    expect(
      find.descendant(
        of: round,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'unified-round-laurel-branch-',
              ),
        ),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: round, matching: find.byIcon(Icons.eco)),
      findsNothing,
    );
    final laurelFrame = tester.widget<SizedBox>(
      find.byKey(ValueKey('unified-round-laurel-${sample.single.id}')),
    );
    expect(laurelFrame.width, 72);
    expect(laurelFrame.height, 66);
    final iconContainer = tester.widget<Container>(
      find.byKey(ValueKey('unified-round-icon-${sample.single.id}')),
    );
    expect(
      (iconContainer.decoration! as BoxDecoration).color,
      const Color(0xFF34C759),
    );
    expect(
      tester
          .getRect(
            find.byKey(ValueKey('unified-round-laurel-${sample.single.id}')),
          )
          .overlaps(tester.getRect(find.text('Round 1'))),
      isFalse,
    );
    expect(find.text('Perfect'), findsOneWidget);

    await tester.pumpWidget(
      app(
        rounds: sample,
        completedRounds: {sample.single.id},
        perfectRounds: {sample.single.id},
        mascotAssets: const [],
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();
    final darkIconContainer = tester.widget<Container>(
      find.byKey(ValueKey('unified-round-icon-${sample.single.id}')),
    );
    expect(
      (darkIconContainer.decoration! as BoxDecoration).color,
      const Color(0xFF4CD964),
    );
  });

  testWidgets('non-perfect completion has no Laurel branch artwork', (
    tester,
  ) async {
    final sample = rounds(1);
    await tester.pumpWidget(
      app(rounds: sample, completedRounds: {sample.single.id}),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'unified-round-laurel-branch-',
            ),
      ),
      findsNothing,
    );
    expect(find.text('Practice'), findsOneWidget);
  });

  testWidgets('long Round title stays at two lines on a 320 px page', (
    tester,
  ) async {
    final round = LearningRound(
      id: 'long-title-round',
      title: 'A deliberately long descriptive Round title for narrow layouts',
    );
    await tester.pumpWidget(
      app(
        rounds: [round],
        completedRounds: {round.id},
        perfectRounds: {round.id},
        mascotAssets: fixtureMascotAssets,
        width: 320 - 28,
      ),
    );

    final title = tester.widget<Text>(find.text(round.title));
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Round surfaces are 75% opaque without fading content', (
    tester,
  ) async {
    final sample = rounds(1);
    await tester.pumpWidget(app(rounds: sample));

    final card = tester.widget<Card>(
      find.byKey(ValueKey('unified-round-${sample.single.id}')),
    );
    expect(card.color!.a, closeTo(.75, .01));
    expect(tester.widget<Text>(find.text('Round 1')).style?.color?.a ?? 1, 1);
  });

  testWidgets(
    'connector keeps its main stroke and adds subtle theme contrast support',
    (tester) async {
      Future<(Color, Color)> colors(ThemeMode mode) async {
        await tester.pumpWidget(app(rounds: rounds(2), themeMode: mode));
        await tester.pumpAndSettle();
        final connector = tester.widget<CustomPaint>(
          find.byKey(const Key('learner-round-connector')),
        );
        final dynamic painter = connector.painter;
        return (painter.lineColor as Color, painter.supportColor as Color);
      }

      final light = await colors(ThemeMode.light);
      final dark = await colors(ThemeMode.dark);

      expect(light.$1.a, closeTo(.55, .01));
      expect(dark.$1.a, closeTo(.55, .01));
      expect(light.$2.a, lessThan(light.$1.a));
      expect(dark.$2.a, lessThan(dark.$1.a));
      expect(
        light.$2.computeLuminance(),
        greaterThan(light.$1.computeLuminance()),
      );
      expect(dark.$2.computeLuminance(), lessThan(dark.$1.computeLuminance()));
      expect(learnerPathConnectorStrokeWidth, 2);
      expect(
        learnerPathConnectorSupportStrokeWidth,
        greaterThan(learnerPathConnectorStrokeWidth),
      );
    },
  );

  testWidgets(
    'mascots are intermittent, opposite, padded, and noninteractive',
    (tester) async {
      final sample = rounds(8);
      LearningRound? opened;
      await tester.pumpWidget(
        app(rounds: sample, onOpenRound: (round) => opened = round),
      );

      expect(
        find.byKey(const ValueKey('learner-round-mascot-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('learner-round-mascot-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('learner-round-mascot-2')),
        findsNothing,
      );
      final firstMascot = find.byKey(const ValueKey('learner-round-mascot-0'));
      final secondMascot = find.byKey(const ValueKey('learner-round-mascot-3'));
      final firstRound = find.byKey(ValueKey('unified-round-${sample[0].id}'));
      final secondRound = find.byKey(ValueKey('unified-round-${sample[3].id}'));
      final pathCenter = tester
          .getRect(find.byKey(const Key('unified-round-tree')))
          .center
          .dx;
      expect(
        tester.getRect(firstMascot).overlaps(tester.getRect(firstRound)),
        isFalse,
      );
      expect(tester.getRect(firstMascot).center.dx, lessThan(pathCenter));
      expect(tester.getRect(firstRound).center.dx, greaterThan(pathCenter));
      expect(
        tester.getRect(secondMascot).overlaps(tester.getRect(secondRound)),
        isFalse,
      );
      expect(tester.getRect(secondMascot).center.dx, greaterThan(pathCenter));
      expect(tester.getRect(secondRound).center.dx, lessThan(pathCenter));
      expect(
        tester
            .widget<Image>(
              find.descendant(of: firstMascot, matching: find.byType(Image)),
            )
            .fit,
        BoxFit.contain,
      );
      expect(
        find.descendant(of: firstMascot, matching: find.byType(Padding)),
        findsOneWidget,
      );

      await tester.tap(firstRound);
      expect(opened, same(sample[0]));
    },
  );

  testWidgets('empty and invalid mascot collections leave the path usable', (
    tester,
  ) async {
    final sample = rounds(5);
    await tester.pumpWidget(app(rounds: sample, mascotAssets: const []));
    expect(find.byKey(const ValueKey('learner-round-mascot-0')), findsNothing);
    expect(
      find.byKey(ValueKey('unified-round-${sample.first.id}')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      app(rounds: sample, mascotAssets: const ['assets/mascots/missing.png']),
    );
    await tester.pump();
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(
      find.byKey(ValueKey('unified-round-${sample.first.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('requested narrow widths keep Rounds within the learner path', (
    tester,
  ) async {
    final sample = rounds(6);
    for (final pageWidth in [320.0, 375.0, 430.0]) {
      await tester.pumpWidget(app(rounds: sample, width: pageWidth - 28));
      final pathRect = tester.getRect(
        find.byKey(const Key('unified-round-tree')),
      );
      for (final round in sample) {
        final roundRect = tester.getRect(
          find.byKey(ValueKey('unified-round-${round.id}')),
        );
        expect(roundRect.left, greaterThanOrEqualTo(pathRect.left));
        expect(roundRect.right, lessThanOrEqualTo(pathRect.right));
        expect(roundRect.width, lessThanOrEqualTo(244.01));
        expect(roundRect.height, closeTo(108, .01));
      }
      if (pageWidth == 430) {
        expect(
          tester
              .getRect(find.byKey(ValueKey('unified-round-${sample.first.id}')))
              .width,
          closeTo(244, .01),
        );
      }
      final mascotFinder = find.byKey(const ValueKey('learner-round-mascot-0'));
      if (mascotFinder.evaluate().isNotEmpty) {
        final mascot = tester.getRect(mascotFinder);
        expect(mascot.left, greaterThanOrEqualTo(pathRect.left));
        expect(mascot.right, lessThanOrEqualTo(pathRect.right));
      }
      expect(mascotFinder, pageWidth == 320 ? findsNothing : findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$pageWidth px page');
    }
  });

  testWidgets('mascots yield below the supported narrow layout', (
    tester,
  ) async {
    final sample = rounds(6);
    await tester.pumpWidget(app(rounds: sample, width: 260));

    expect(find.byKey(const ValueKey('learner-round-mascot-0')), findsNothing);
    expect(
      find.byKey(ValueKey('unified-round-${sample.first.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mascot treatment adapts to light and dark themes', (
    tester,
  ) async {
    final sample = rounds(2);

    Future<Color> decorationColor(ThemeMode mode) async {
      await tester.pumpWidget(app(rounds: sample, themeMode: mode));
      await tester.pumpAndSettle();
      final firstMascot = learnerCourseMascotOrder(
        'course-alpha',
        fixtureMascotAssets,
      ).first;
      final box = tester.widget<DecoratedBox>(
        find.byKey(ValueKey('learner-round-mascot-surface-$firstMascot')),
      );
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(ValueKey('learner-round-mascot-surface-$firstMascot')),
          matching: find.byType(Image),
        ),
      );
      expect(image.opacity, isNull);
      return (box.decoration as BoxDecoration).color!;
    }

    final light = await decorationColor(ThemeMode.light);
    final dark = await decorationColor(ThemeMode.dark);
    expect(light, isNot(dark));
    expect(light.a, closeTo(.10, .01));
    expect(dark.a, closeTo(.10, .01));
  });
}
