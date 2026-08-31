import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';

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
    List<String>? mascotAssets = fixtureMascotAssets,
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
            perfectRounds: const {},
            ttsSkippedPerfectRounds: const {},
            mascotAssets: mascotAssets,
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

    expect(positions, [0, 3, 6, 8]);
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
      (index) => alpha[index % alpha.length],
    );
    expect(reused.take(assets.length).toSet(), hasLength(assets.length));
    expect(reused[assets.length], alpha.first);
    for (var index = 1; index < reused.length; index++) {
      expect(reused[index], isNot(reused[index - 1]));
    }
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
      final discovered = await loadLearnerMascotAssets(rootBundle);
      expect(discovered, expected);

      var roundCount = 0;
      var slotCount = 0;
      while (slotCount < discovered.length) {
        if (learnerRoundPathShowsMascot(roundCount)) slotCount++;
        roundCount++;
      }
      await tester.pumpWidget(
        app(rounds: rounds(roundCount), mascotAssets: null),
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

  testWidgets('perfect completion keeps its Laurel around the bright icon', (
    tester,
  ) async {
    final sample = rounds(1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnerRoundPath(
            courseId: 'course-alpha',
            rounds: sample,
            completedRounds: {sample.single.id},
            perfectRounds: {sample.single.id},
            ttsSkippedPerfectRounds: const {},
            mascotAssets: const [],
            onOpenRound: (_) {},
          ),
        ),
      ),
    );

    final round = find.byKey(ValueKey('unified-round-${sample.single.id}'));
    expect(
      find.descendant(of: round, matching: find.byIcon(Icons.eco)),
      findsNWidgets(2),
    );
    for (final laurel in tester.widgetList<Icon>(
      find.descendant(of: round, matching: find.byIcon(Icons.eco)),
    )) {
      expect(laurel.size, 34);
    }
    final iconContainer = tester.widget<Container>(
      find.byKey(ValueKey('unified-round-icon-${sample.single.id}')),
    );
    expect(
      (iconContainer.decoration! as BoxDecoration).color,
      const Color(0xFFFFB000),
    );
    expect(find.text('Perfect'), findsOneWidget);
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

  testWidgets('supported narrow width keeps mascots without Round overflow', (
    tester,
  ) async {
    final sample = rounds(6);
    await tester.pumpWidget(app(rounds: sample, width: 292));

    final pathRect = tester.getRect(
      find.byKey(const Key('unified-round-tree')),
    );
    for (final round in sample) {
      final roundRect = tester.getRect(
        find.byKey(ValueKey('unified-round-${round.id}')),
      );
      expect(roundRect.left, greaterThanOrEqualTo(pathRect.left));
      expect(roundRect.right, lessThanOrEqualTo(pathRect.right));
    }
    final mascot = tester.getRect(
      find.byKey(const ValueKey('learner-round-mascot-0')),
    );
    expect(mascot.left, greaterThanOrEqualTo(pathRect.left));
    expect(mascot.right, lessThanOrEqualTo(pathRect.right));
    expect(tester.takeException(), isNull);
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
    expect(light.a, closeTo(.5, .01));
    expect(dark.a, closeTo(.5, .01));
  });
}
