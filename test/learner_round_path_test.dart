import 'dart:io';
import 'support/pump_file_io.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/learner_mascots.dart';
import 'package:quisquislingo_app/services/lesson_color_palette.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const fixtureMascotAssets = <String>[
    'assets/mascots/qql-dog-tambourine.webp',
    'assets/mascots/qql-monkey-sleeping.webp',
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
    int lessonIndex = 0,
    bool halo = false,
    bool startsAtLessonCircle = false,
    bool leadsToDuel = false,
  }) => MaterialApp(
    theme: ThemeData.light(useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
    themeMode: themeMode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: LearnerPathHalo(
            enabled: halo,
            child: LearnerRoundPath(
              courseId: 'course-alpha',
              lessonIndex: lessonIndex,
              startsAtLessonCircle: startsAtLessonCircle,
              leadsToDuel: leadsToDuel,
              rounds: rounds,
              completedRounds: completedRounds,
              perfectRounds: perfectRounds,
              ttsSkippedPerfectRounds: const {},
              roundAudioAvailability: const {},
              mascotAssets: mascotAssets,
              mascotPositionOffset: mascotPositionOffset,
              roundPositionOffset: roundPositionOffset,
              onOpenRound: onOpenRound ?? (_) {},
            ),
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

    expect(positions, [0, 1, 3, 5, 7, 8]);
    expect(freeSides, {LearnerRoundPathSide.left, LearnerRoundPathSide.right});
  });

  test('no two Rounds in a row have a mascot on the same side', () {
    // Owner request of 3 October 2026 (Build 261 Revision 8), for every
    // Lesson start (Build 262 Revision 3).
    for (final start in learnerRoundPlacementStarts) {
      for (var offset = 0; offset < 20; offset++) {
        final rows = learnerRoundPathMascotRows(
          40,
          roundPositionOffset: offset,
          placementStart: start,
        );
        for (var index = 1; index < rows.length; index++) {
          expect(
            rows[index] &&
                rows[index - 1] &&
                learnerRoundPathSide(index, start: start) ==
                    learnerRoundPathSide(index - 1, start: start),
            isFalse,
            reason: 'start $start, offset $offset, Rounds ${index - 1}-$index',
          );
        }
        expect(
          rows.where((shown) => shown).length,
          greaterThanOrEqualTo(20),
          reason: 'more than half the Rounds keep a mascot',
        );
      }
    }
  });

  test('each Lesson and each Course has its own path shape', () {
    // Owner request of 3 October 2026 (Build 262 Revision 3): not the same
    // path in every Lesson and every Course.
    List<LearnerRoundPlacement> shape(String courseId, int lessonIndex) =>
        List.generate(
          6,
          (index) => learnerRoundPlacement(
            index,
            start: learnerRoundPlacementStart(courseId, lessonIndex),
          ),
        );

    // Eight starts, eight different shapes, each opening at the centre.
    expect(learnerRoundPlacementStarts.toSet(), hasLength(8));
    expect({
      for (final start in learnerRoundPlacementStarts)
        List.generate(
          6,
          (index) => learnerRoundPlacement(index, start: start),
        ).join(),
    }, hasLength(8));
    for (final start in learnerRoundPlacementStarts) {
      expect(
        learnerRoundPlacement(0, start: start),
        isIn(const [
          LearnerRoundPlacement.centerTextRight,
          LearnerRoundPlacement.centerTextLeft,
        ]),
      );
    }

    const courses = [
      'course-alpha',
      'course-beta',
      'course_65dce83b-fd0a-4b83-a5a1-8f8b97a58d05',
      'course_99b99a4a-0000-4000-8000-000000000000',
    ];
    for (final course in courses) {
      final shapes = [
        for (var lesson = 0; lesson < 8; lesson++) shape(course, lesson),
      ];
      // A Course's first eight Lessons all differ, and neighbouring Lessons
      // open with their texts on opposite sides.
      expect(shapes.map((shape) => shape.join()).toSet(), hasLength(8));
      for (var lesson = 1; lesson < shapes.length; lesson++) {
        expect(
          shapes[lesson].first,
          isNot(shapes[lesson - 1].first),
          reason: '$course Lessons ${lesson - 1} and $lesson',
        );
      }
      expect(shape(course, 3), shape(course, 3), reason: 'stable');
    }
    // The first Lesson does not have one shape in every Course.
    expect(
      {for (final course in courses) shape(course, 0).join()}.length,
      greaterThan(1),
    );
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
        courseId: 'sample_it_en_it',
      );
      for (
        var roundIndex = 0;
        roundIndex < lessons[lessonIndex].rounds.length;
        roundIndex++
      ) {
        if (learnerRoundPathShowsMascot(
          roundIndex,
          roundPositionOffset: roundOffset,
          placementStart: learnerRoundPlacementStart(
            'sample_it_en_it',
            lessonIndex,
          ),
        )) {
          selected.add(learnerMascotAssetAtPosition(order, mascotPosition++));
        }
      }
    }

    expect(learnerRoundPathMascotSlotCount(2), 2);
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
                      lessonIndex: lessonIndex,
                      rounds: lessons[lessonIndex].rounds,
                      completedRounds: const {},
                      perfectRounds: const {},
                      ttsSkippedPerfectRounds: const {},
                      roundAudioAvailability: const {},
                      mascotAssets: assets,
                      mascotPositionOffset:
                          learnerMascotPositionOffsetForLesson(
                            lessons,
                            lessonIndex,
                            courseId: 'sample_it_en_it',
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
              .where((file) => file.path.toLowerCase().endsWith('.webp'))
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
        if (learnerRoundPathShowsMascot(
          roundCount,
          placementStart: learnerRoundPlacementStart('course-alpha', 0),
        )) {
          slotCount++;
        }
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
        'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
        'sound_effects_enabled': false,
      });
      await ProfileService().addProfile('Mascot Learner');
      await SettingsService().completeWelcomeWizard();

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
        await tester.pumpUntilFileIoState(() => finder.evaluate().isNotEmpty);
      }

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      // Build 255 Revision 7: no Beta notice fifteen days before expiry.

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

    // Circles at the left edge, the centre or the right edge (Build 261
    // Revision 8): some places repeat, an edge never follows the other edge.
    final firstLayout = rects();
    expect(firstLayout[3].bottom + 20, lessThanOrEqualTo(firstLayout[4].top));
    expect(firstLayout.map((rect) => rect.left).toSet().length, 4);
    final circles = [
      for (final round in sample)
        tester
            .getRect(find.byKey(ValueKey('unified-round-icon-${round.id}')))
            .center
            .dx,
    ];
    final path = tester.getRect(find.byKey(const Key('unified-round-tree')));
    final start = learnerRoundPlacementStart('course-alpha', 0);
    for (var index = 0; index < sample.length; index++) {
      expect(
        circles[index],
        closeTo(switch (learnerRoundPlacement(index, start: start)) {
          LearnerRoundPlacement.left => path.left + learnerRoundIconCenterX,
          LearnerRoundPlacement.right => path.right - learnerRoundIconCenterX,
          _ => path.center.dx,
        }, .01),
      );
    }
    final placements = List.generate(32, learnerRoundPlacement);
    for (var index = 1; index < placements.length; index++) {
      expect(
        {placements[index - 1], placements[index]},
        isNot({LearnerRoundPlacement.left, LearnerRoundPlacement.right}),
        reason: 'no jump from edge to edge at $index',
      );
    }
    expect(
      List.generate(31, (index) => placements[index] == placements[index + 1]),
      contains(isTrue),
      reason: 'a place sometimes repeats',
    );

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
      // Rows without cards since Build 261 Revision 8.
      expect(find.byType(Card), findsNothing);
      for (final round in sample) {
        expect(
          find.byKey(ValueKey('unified-round-${round.id}')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull, reason: '$count Rounds');
    }
  });

  testWidgets('completion fills the icon circle with the Lesson colour', (
    tester,
  ) async {
    final sample = rounds(2);
    final lesson = LessonColorPalette.of(0, Brightness.light);
    final completedColor = lesson.solid;
    final incompleteColor = lesson.tint;

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
      LessonColorPalette.of(0, Brightness.light).solid,
    );
    expect(find.text('Completed'), findsOneWidget);
    // Written in the Lesson's deeper shade, not the circle's own.
    expect(
      tester.widget<Text>(find.text('Completed')).style!.color,
      LessonColorPalette.of(0, Brightness.light).onTint,
    );
    expect(find.text('Perfect'), findsNothing);
  });

  testWidgets(
    'a Round not yet completed is a pale tint ringed with its Lesson colour',
    (tester) async {
      // Owner decisions of 3 October 2026 (Build 261 Revision 8): each
      // Lesson has its own colour, by position; green is only Perfect.
      final sample = rounds(1);
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await tester.pumpWidget(
          app(rounds: sample, lessonIndex: 2, themeMode: mode),
        );
        await tester.pumpAndSettle();
        final colors = LessonColorPalette.of(
          2,
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
        );
        final circle = tester.widget<Container>(
          find.byKey(ValueKey('unified-round-icon-${sample.single.id}')),
        );
        final decoration = circle.decoration! as BoxDecoration;
        expect(decoration.color, colors.tint, reason: '$mode');
        expect((decoration.border! as Border).top.color, colors.solid);
        expect(
          tester
              .widget<Icon>(
                find.descendant(
                  of: find.byKey(
                    ValueKey('unified-round-icon-${sample.single.id}'),
                  ),
                  matching: find.byType(Icon),
                ),
              )
              .color,
          colors.onTint,
        );
        expect(find.text('Learn'), findsOneWidget);
      }
    },
  );

  test('the Lesson palette has eight colours, by position, without green', () {
    for (final brightness in Brightness.values) {
      final solids = {
        for (var index = 0; index < LessonColorPalette.count; index++)
          LessonColorPalette.of(index, brightness).solid,
      };
      expect(solids, hasLength(8), reason: '$brightness');
      expect(
        LessonColorPalette.of(8, brightness).solid,
        LessonColorPalette.of(0, brightness).solid,
      );
      for (final solid in solids) {
        final hue = HSVColor.fromColor(solid).hue;
        expect(
          hue < 75 || hue > 165,
          isTrue,
          reason: 'green is reserved for Perfect ($solid)',
        );
      }
    }
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
    // The laurel reaches past the icon slot, so the circle and the path line
    // stay in place (Build 261 Revision 8).
    final laurelFrame = tester.widget<SizedBox>(
      find.byKey(ValueKey('unified-round-laurel-${sample.single.id}')),
    );
    expect(laurelFrame.width, learnerRoundIconSlotWidth);
    expect(laurelFrame.height, 70);
    final iconContainer = tester.widget<Container>(
      find.byKey(ValueKey('unified-round-icon-${sample.single.id}')),
    );
    expect(
      (iconContainer.decoration! as BoxDecoration).color,
      const Color(0xFF34C759),
    );
    for (final side in ['left', 'right']) {
      expect(
        tester
            .getRect(
              find.byKey(
                ValueKey(
                  'unified-round-laurel-branch-$side-${sample.single.id}',
                ),
              ),
            )
            .overlaps(
              tester.getRect(
                find.byKey(ValueKey('unified-round-label-${sample.single.id}')),
              ),
            ),
        isFalse,
      );
    }
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
    expect(find.text('Completed'), findsOneWidget);
  });

  testWidgets(
    'long Round title wraps up to two lines under its label at 320 px',
    (tester) async {
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

      // Numbering is Off: the type is the label line, the author title below.
      final label = tester.widget<Text>(
        find.byKey(const ValueKey('unified-round-label-long-title-round')),
      );
      expect(label.data, 'Practice');
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('unified-round-title-long-title-round')),
      );
      expect(title.data, round.title);
      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Round, Story and sequence names: grey label line, lighter title, tooltip',
    (tester) async {
      // Owner decisions of 1 October 2026 (Build 261 Revision 0) and of
      // 3 October 2026 (Revision 8: label above a lighter, smaller title).
      final path = [
        LearningRound(id: 'titled', title: 'Pratica 1'),
        LearningRound(id: 'untitled', title: ''),
        LearningRound(
          id: 'story',
          title: 'Round three',
          visualType: LearningRound.storyVisualType,
          flow: ContentFlow.linear(const [], title: 'Al bar'),
        ),
        LearningRound(
          id: 'sequence',
          title: 'Numbers',
          flow: ContentFlow.linear(const []),
        ),
      ];
      await tester.pumpWidget(app(rounds: path, mascotAssets: const []));

      (String, String) parts(String id) => (
        tester
            .widget<Text>(find.byKey(ValueKey('unified-round-label-$id')))
            .data!,
        tester
            .widget<Text>(find.byKey(ValueKey('unified-round-title-$id')))
            .data!,
      );

      expect(parts('titled'), ('Practice', 'Pratica 1'));
      expect(parts('story'), ('Story', 'Al bar'));
      expect(parts('sequence'), ('Sequence', 'Numbers'));
      // Without a title of its own the label keeps the same small regular
      // style (owner decision): no title line.
      expect(
        find.byKey(const ValueKey('unified-round-title-untitled')),
        findsNothing,
      );
      final untitled = tester.widget<Text>(
        find.byKey(const ValueKey('unified-round-label-untitled')),
      );
      expect(untitled.data, 'Practice');
      expect(untitled.style!.fontSize, 12);

      expect(find.byTooltip('Practice · Pratica 1'), findsOneWidget);
      expect(find.byTooltip('Story · Al bar'), findsOneWidget);
      expect(find.byTooltip('Sequence · Numbers'), findsOneWidget);
      expect(find.byTooltip('Practice'), findsNothing);

      final label = tester.widget<Text>(
        find.byKey(const ValueKey('unified-round-label-titled')),
      );
      expect(label.style!.fontSize, 12);
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('unified-round-title-titled')),
      );
      expect(title.style!.fontSize, 15);
      expect(title.style!.fontWeight, FontWeight.w400);
      final status = tester.widget<Text>(
        find.byKey(const ValueKey('unified-round-status-titled')),
      );
      expect(status.data, 'Learn');
      expect(status.style!.fontSize, 12);
    },
  );

  testWidgets(
    'Round rows have a faint borderless background and unfaded texts',
    (tester) async {
      final sample = rounds(1);
      await tester.pumpWidget(app(rounds: sample));

      // 20% opaque, no border (Build 261 Revision 8, owner decision): the path
      // line shows through, a little dimmed.
      final row = tester.widget<Material>(
        find.byKey(ValueKey('unified-round-${sample.single.id}')),
      );
      expect(row.color!.a, closeTo(learnerPathSurfaceOpacity, .01));
      expect(learnerPathSurfaceOpacity, .20);
      expect((row.shape! as RoundedRectangleBorder).side, BorderSide.none);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('unified-round-${sample.single.id}')),
          matching: find.byType(Card),
        ),
        findsNothing,
      );
      expect(
        tester
                .widget<Text>(
                  find.byKey(
                    ValueKey('unified-round-title-${sample.single.id}'),
                  ),
                )
                .style
                ?.color
                ?.a ??
            1,
        1,
      );
    },
  );

  testWidgets('a halo surrounds the path texts only over a flag picture', (
    tester,
  ) async {
    final sample = rounds(1);
    for (final halo in [false, true]) {
      await tester.pumpWidget(app(rounds: sample, halo: halo));
      for (final key in ['title', 'label', 'status']) {
        final text = tester.widget<Text>(
          find.byKey(ValueKey('unified-round-$key-${sample.single.id}')),
        );
        expect(
          text.style!.shadows,
          halo ? isNotEmpty : isNull,
          reason: '$key halo=$halo',
        );
      }
      final connector = tester.widget<CustomPaint>(
        find.byKey(const Key('learner-round-connector')),
      );
      final dynamic painter = connector.painter;
      expect(
        (painter.supportColor as Color).a,
        halo ? greaterThan(.8) : lessThan(.55),
      );
    }
  });

  testWidgets('the path line joins the circles and never crosses a text', (
    tester,
  ) async {
    // Owner decision of 3 October 2026: circle to circle, from the Lesson
    // circle above (or the IDDQD pill's connector) to the Duel below; every
    // Lesson start (Build 262 Revision 3).
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sample = rounds(8);
    final starts = {
      for (var lesson = 0; lesson < 8; lesson++)
        learnerRoundPlacementStart('course-alpha', lesson),
    };
    expect(starts, learnerRoundPlacementStarts.toSet());
    for (final (lessonIndex, fromLessonCircle, width) in [
      for (var lesson = 0; lesson < 8; lesson++)
        for (final fromLessonCircle in [true, false])
          for (final width in [292.0, 347.0, 402.0, 560.0, 900.0])
            (lesson, fromLessonCircle, width),
    ]) {
      await tester.pumpWidget(
        app(
          rounds: sample,
          width: width,
          lessonIndex: lessonIndex,
          startsAtLessonCircle: fromLessonCircle,
          leadsToDuel: true,
          perfectRounds: {sample[1].id},
          completedRounds: {sample[1].id, sample[2].id},
        ),
      );
      final tree = find.byKey(const Key('unified-round-tree'));
      final treeRect = tester.getRect(tree);
      final connector = tester.widget<CustomPaint>(
        find.byKey(const Key('learner-round-connector')),
      );
      final dynamic painter = connector.painter;
      final path = painter.pathFor(treeRect.size) as Path;
      final points = <Offset>[];
      for (final metric in path.computeMetrics()) {
        for (var distance = 0.0; distance < metric.length; distance += 2) {
          points.add(
            metric.getTangentForOffset(distance)!.position + treeRect.topLeft,
          );
        }
        points.add(
          metric.getTangentForOffset(metric.length)!.position +
              treeRect.topLeft,
        );
      }
      expect(treeRect.width, lessThanOrEqualTo(learnerRoundPathMaxWidth));
      final pageLeft = treeRect.center.dx - width / 2;
      expect(
        points.first.dx - pageLeft,
        closeTo(
          fromLessonCircle ? learnerLessonCircleCenterX(width) : width / 2,
          .01,
        ),
      );
      expect(points.last.dx, closeTo(treeRect.center.dx, .01));
      expect(points.last.dy, closeTo(treeRect.bottom, .01));
      for (final round in sample) {
        final circle = tester.getRect(
          find.byKey(ValueKey('unified-round-icon-${round.id}')),
        );
        expect(
          points.any((point) => (point - circle.center).distance < 1.5),
          isTrue,
          reason: 'the line passes through ${round.id} at $width',
        );
        for (final key in ['label', 'title', 'status']) {
          final text = tester.getRect(
            find.byKey(ValueKey('unified-round-$key-${round.id}')),
          );
          expect(
            points.where((point) => text.inflate(1).contains(point)),
            isEmpty,
            reason:
                'the line crosses ${round.id} $key at $width, Lesson '
                '$lessonIndex, from the Lesson circle $fromLessonCircle',
          );
        }
      }
      expect(tester.takeException(), isNull);
    }
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

      // Some Rounds have a mascot and some do not; each stands in the half
      // opposite its Round, whatever the Lesson's start (Build 262
      // Revision 3).
      final start = learnerRoundPlacementStart('course-alpha', 0);
      final shown = learnerRoundPathMascotRows(
        sample.length,
        placementStart: start,
      );
      expect(shown, containsAll([true, false]));
      final pathCenter = tester
          .getRect(find.byKey(const Key('unified-round-tree')))
          .center
          .dx;
      for (var index = 0; index < sample.length; index++) {
        final mascot = find.byKey(ValueKey('learner-round-mascot-$index'));
        expect(mascot, shown[index] ? findsOneWidget : findsNothing);
        if (!shown[index]) continue;
        final round = tester.getRect(
          find.byKey(ValueKey('unified-round-${sample[index].id}')),
        );
        final mascotRect = tester.getRect(mascot);
        expect(mascotRect.overlaps(round), isFalse, reason: 'Round $index');
        if (learnerRoundPathSide(index, start: start) ==
            LearnerRoundPathSide.right) {
          expect(round.center.dx, greaterThan(pathCenter));
          expect(mascotRect.center.dx, lessThan(pathCenter));
        } else {
          expect(round.center.dx, lessThan(pathCenter));
          expect(mascotRect.center.dx, greaterThan(pathCenter));
        }
      }
      final firstMascot = find.byKey(
        ValueKey('learner-round-mascot-${shown.indexOf(true)}'),
      );
      final firstRound = find.byKey(ValueKey('unified-round-${sample[0].id}'));
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
              .getRect(find.byKey(ValueKey('unified-round-${sample[1].id}')))
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
