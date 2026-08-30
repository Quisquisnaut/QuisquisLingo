import 'dart:math';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/gamification_settings_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/learner_navigation.dart';
import 'package:quisquislingo_app/widgets/learner_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetLearnerStatusRouteObserver();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => throw PlatformException(
        code: 'test_storage_unavailable',
        message: 'Persistent logging is unavailable in widget tests.',
      ),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final arguments = call.arguments as Map<Object?, Object?>;
          _installEventChannelMock(
            messenger,
            'xyz.luan/audioplayers/events/${arguments['playerId']}',
          );
        }
        return null;
      },
    );
    _installEventChannelMock(messenger, 'xyz.luan/audioplayers.global/events');
    PackageInfo.setMockInitialValues(
      appName: 'QuisquisLingo',
      packageName: 'com.quisquislingo.app',
      version: '2.0.18',
      buildNumber: '218',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({
      'one_time_notice_seen_welcome_2.0.18': true,
      'sound_effects_enabled': false,
    });
    await ProfileService().addProfile('Navigation Learner');
  });

  testWidgets('Unified Home opens a Round directly from the active Lesson', (
    tester,
  ) async {
    final course = await _loadItalianCourse(tester);
    await _openHome(tester, scrollToActions: false);

    final firstTopic = course.topics.first;
    final firstRound = firstTopic.rounds.first;
    final firstRoundCard = find.text(firstRound.title).first;
    expect(find.text('Lesson 1: ${firstTopic.title}'), findsOneWidget);
    await tester.ensureVisible(firstRoundCard);
    await tester.tap(firstRoundCard);
    await _pumpUntil(tester, find.byType(RoundScreen));
    await tester.pumpAndSettle();
    expect(find.byType(RoundScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(RoundScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'learner content flows through subsequent Lessons once in course order',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      await _openHome(tester, scrollToActions: false);

      final listView = tester.widget<ListView>(
        find.byKey(const Key('unified-learner-scroll')),
      );
      expect(listView.childrenDelegate, isA<SliverChildBuilderDelegate>());
      expect(
        listView.childrenDelegate.estimatedChildCount,
        course.topics.length,
      );

      final scrollable = _mainLearnerScrollable();
      final position = tester.state<ScrollableState>(scrollable).position;
      final visitedOffsets = <double>[];
      for (final topic in course.topics) {
        final section = find.byKey(
          ValueKey('unified-lesson-section-${topic.id}'),
        );
        await tester.scrollUntilVisible(section, 260, scrollable: scrollable);
        await tester.pumpAndSettle();
        expect(section, findsOneWidget, reason: topic.id);
        visitedOffsets.add(position.pixels);
      }

      expect(visitedOffsets.first, lessThan(20));
      for (var index = 1; index < visitedOffsets.length; index++) {
        expect(visitedOffsets[index], greaterThan(visitedOffsets[index - 1]));
      }
    },
  );

  testWidgets(
    'restored intermediate Lesson is the initial target with earlier and later Lessons retained',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      final restoredTopic = course.topics[1];
      await SettingsService().setLastVisitedTopicId(
        course.courseId,
        restoredTopic.id,
      );

      await _openHome(tester, scrollToActions: false);
      await tester.pumpAndSettle();

      final scrollable = _mainLearnerScrollable();
      final restoredSection = find.byKey(
        ValueKey('unified-lesson-section-${restoredTopic.id}'),
      );
      expect(_lessonSelectorLabel(course, 1), findsOneWidget);
      expect(restoredSection, findsOneWidget);
      expect(
        tester.getRect(restoredSection).overlaps(tester.getRect(scrollable)),
        isTrue,
      );
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );

      final firstSection = find.byKey(
        ValueKey('unified-lesson-section-${course.topics.first.id}'),
      );
      await tester.scrollUntilVisible(
        firstSection,
        -260,
        scrollable: scrollable,
      );
      await tester.drag(
        find.byKey(const Key('unified-learner-scroll')),
        const Offset(0, 260),
      );
      await tester.pumpAndSettle();
      expect(firstSection, findsOneWidget);
      expect(_lessonSelectorLabel(course, 0), findsOneWidget);

      final thirdSection = find.byKey(
        ValueKey('unified-lesson-section-${course.topics[2].id}'),
      );
      await tester.scrollUntilVisible(
        thirdSection,
        260,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(thirdSection, findsOneWidget);
    },
  );

  testWidgets(
    'restored final Lesson is the initial target with previous Lessons retained',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      final finalIndex = course.topics.length - 1;
      final finalTopic = course.topics[finalIndex];
      await SettingsService().setLastVisitedTopicId(
        course.courseId,
        finalTopic.id,
      );

      await _openHome(tester, scrollToActions: false);
      await tester.pumpAndSettle();

      final scrollable = _mainLearnerScrollable();
      final finalSection = find.byKey(
        ValueKey('unified-lesson-section-${finalTopic.id}'),
      );
      expect(_lessonSelectorLabel(course, finalIndex), findsOneWidget);
      expect(finalSection, findsOneWidget);
      expect(
        tester.getRect(finalSection).overlaps(tester.getRect(scrollable)),
        isTrue,
      );
      expect(
        tester.widget<IconButton>(_lessonArrowButton('Next Lesson')).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(_lessonArrowButton('Previous Lesson'))
            .onPressed,
        isNotNull,
      );

      final firstSection = find.byKey(
        ValueKey('unified-lesson-section-${course.topics.first.id}'),
      );
      await tester.scrollUntilVisible(
        firstSection,
        -400,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(firstSection, findsOneWidget);
    },
  );

  testWidgets(
    'Lesson picker scrolls to the selected Lesson without truncating the flow',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      await _openHome(tester, scrollToActions: false);

      final selector = find.byKey(const Key('unified-lesson-selector'));
      expect(selector, findsOneWidget);
      expect(find.byKey(const Key('browse-all-lessons')), findsNothing);
      expect(
        tester.widget<OutlinedButton>(selector).style?.alignment,
        Alignment.centerLeft,
      );
      await tester.tap(selector);
      final selectedTopic = course.topics[2];
      final selectedLesson = find.text('Lesson 3: ${selectedTopic.title}');
      await _pumpUntil(tester, selectedLesson);
      await tester.pumpAndSettle();
      expect(find.text('Browse All Lessons'), findsNothing);
      expect(selectedLesson, findsOneWidget);
      final selectedLessonTile = find.ancestor(
        of: selectedLesson,
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: selectedLessonTile,
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      await tester.tap(selectedLesson);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: selector,
          matching: find.text('Lesson 3: ${selectedTopic.title}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('unified-lesson-section-${selectedTopic.id}')),
        findsOneWidget,
      );
      final firstSection = find.byKey(
        ValueKey('unified-lesson-section-${course.topics.first.id}'),
      );
      expect(
        tester.state<ScrollableState>(_mainLearnerScrollable()).position.pixels,
        greaterThan(0),
      );
      late String? persistedTopicId;
      await tester.runAsync(() async {
        persistedTopicId = await SettingsService().getLastVisitedTopicId(
          course.courseId,
        );
      });
      expect(persistedTopicId, selectedTopic.id);
      await tester.scrollUntilVisible(
        firstSection,
        -260,
        scrollable: _mainLearnerScrollable(),
      );
      expect(firstSection, findsOneWidget);

      const unavailable =
          'Unavailable for this Lesson: not enough suitable exercises.';
      final selectedDuel = find.byKey(
        ValueKey('unified-duel-${selectedTopic.id}'),
      );
      await tester.scrollUntilVisible(
        selectedDuel,
        240,
        scrollable: _mainLearnerScrollable(),
      );
      await tester.pump();
      final unavailableInSelectedLesson = find.descendant(
        of: selectedDuel,
        matching: find.text(unavailable),
      );
      await tester.ensureVisible(unavailableInSelectedLesson);
      expect(unavailableInSelectedLesson, findsOneWidget);
      final laterSection = find.byKey(
        ValueKey('unified-lesson-section-${course.topics[3].id}'),
      );
      await tester.scrollUntilVisible(
        laterSection,
        240,
        scrollable: _mainLearnerScrollable(),
      );
      expect(laterSection, findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Lesson arrows navigate within the full flow without opening the picker',
    (tester) async {
      final course = await _loadItalianCourse(tester, enableIddqd: false);
      await _openHome(tester, scrollToActions: false);

      expect(
        tester
            .widget<IconButton>(_lessonArrowButton('Previous Lesson'))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<IconButton>(_lessonArrowButton('Next Lesson')).onPressed,
        isNotNull,
      );

      await tester.tap(_lessonArrowButton('Next Lesson'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(_lessonSelectorLabel(course, 1), findsOneWidget);
      final lockedTopic = course.topics[1];
      expect(
        find.byKey(ValueKey('unified-lesson-locked-${lockedTopic.id}')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('unified-round-${lockedTopic.rounds.first.id}')),
        findsNothing,
      );
      expect(
        tester
            .widget<IconButton>(_lessonArrowButton('Previous Lesson'))
            .onPressed,
        isNotNull,
      );
      expect(
        tester.widget<IconButton>(_lessonArrowButton('Next Lesson')).onPressed,
        isNotNull,
      );

      await tester.tap(_lessonArrowButton('Previous Lesson'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(_lessonSelectorLabel(course, 0), findsOneWidget);
      expect(
        tester
            .widget<ListView>(find.byKey(const Key('unified-learner-scroll')))
            .childrenDelegate
            .estimatedChildCount,
        course.topics.length,
      );

      await tester.tap(_lessonSelectorLabel(course, 0));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    },
  );

  testWidgets('continuous flow keeps locked Lesson content inaccessible', (
    tester,
  ) async {
    final course = await _loadItalianCourse(tester, enableIddqd: false);
    await _openHome(tester, scrollToActions: false);

    final lockedTopic = course.topics[1];
    final lockedSection = find.byKey(
      ValueKey('unified-lesson-section-${lockedTopic.id}'),
    );
    await tester.scrollUntilVisible(
      lockedSection,
      260,
      scrollable: _mainLearnerScrollable(),
    );
    await tester.pumpAndSettle();

    expect(lockedSection, findsOneWidget);
    expect(
      find.byKey(ValueKey('unified-lesson-locked-${lockedTopic.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('flag-backdrop-locked-message-${lockedTopic.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('unified-round-${lockedTopic.rounds.first.id}')),
      findsNothing,
    );
  });

  testWidgets(
    'only text exposed directly to the course flag receives a contrast outline',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);
      final course = await _loadItalianCourse(tester);
      await _openHome(tester, scrollToActions: false);

      final firstSection = find.byKey(
        ValueKey('unified-lesson-section-${course.topics.first.id}'),
      );
      final guidebookLabel = find.descendant(
        of: firstSection,
        matching: find.text('GuideBook'),
      );
      expect(guidebookLabel, findsOneWidget);
      expect(
        find.ancestor(of: guidebookLabel, matching: _flagBackdropText()),
        findsNothing,
      );

      final secondTopic = course.topics[1];
      final secondSection = find.byKey(
        ValueKey('unified-lesson-section-${secondTopic.id}'),
      );
      await tester.scrollUntilVisible(
        secondSection,
        260,
        scrollable: _mainLearnerScrollable(),
      );
      await tester.pumpAndSettle();

      final outlinedTitle = find.byKey(
        ValueKey('flag-backdrop-lesson-title-${secondTopic.id}'),
      );
      expect(outlinedTitle, findsOneWidget);
      var titleLayers = tester
          .widgetList<Text>(
            find.descendant(of: outlinedTitle, matching: find.byType(Text)),
          )
          .toList();
      expect(titleLayers, hasLength(2));
      var outlineLayer = titleLayers.singleWhere(
        (text) => text.style?.foreground != null,
      );
      expect(outlineLayer.style!.foreground!.style, PaintingStyle.stroke);
      expect(outlineLayer.style!.foreground!.strokeWidth, 2);
      expect(outlineLayer.style!.foreground!.color, Colors.white);

      dispatcher.platformBrightnessTestValue = Brightness.dark;
      await _pumpFrames(tester, count: 4);

      titleLayers = tester
          .widgetList<Text>(
            find.descendant(of: outlinedTitle, matching: find.byType(Text)),
          )
          .toList();
      outlineLayer = titleLayers.singleWhere(
        (text) => text.style?.foreground != null,
      );
      expect(outlineLayer.style!.foreground!.color, Colors.black);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'scrolling into the next Lesson updates the fixed selector once',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      await _openHome(tester, scrollToActions: false);
      final secondTopic = course.topics[1];
      final secondSection = find.byKey(
        ValueKey('unified-lesson-section-${secondTopic.id}'),
      );

      await tester.scrollUntilVisible(
        secondSection,
        260,
        scrollable: _mainLearnerScrollable(),
      );
      await tester.drag(
        find.byKey(const Key('unified-learner-scroll')),
        const Offset(0, -260),
      );
      await tester.pumpAndSettle();

      final selectedLessonLabel = find.descendant(
        of: find.byKey(const Key('unified-lesson-selector')),
        matching: find.text('Lesson 2: ${secondTopic.title}'),
      );
      expect(selectedLessonLabel, findsOneWidget);
      late String? persistedTopicId;
      await tester.runAsync(() async {
        persistedTopicId = await SettingsService().getLastVisitedTopicId(
          course.courseId,
        );
      });
      expect(persistedTopicId, secondTopic.id);

      await tester.drag(
        find.byKey(const Key('unified-learner-scroll')),
        const Offset(0, 12),
      );
      await tester.pumpAndSettle();
      expect(selectedLessonLabel, findsOneWidget);
      await tester.runAsync(() async {
        persistedTopicId = await SettingsService().getLastVisitedTopicId(
          course.courseId,
        );
      });
      expect(persistedTopicId, secondTopic.id);
    },
  );

  testWidgets('Home Leaderboard opens Gamification and back returns Home', (
    tester,
  ) async {
    await _openHome(tester);

    final semantics = tester.ensureSemantics();
    expect(find.text('Leaderboard'), findsNothing);
    expect(find.bySemanticsLabel('Leaderboard'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Leaderboard'));
    await _pumpUntil(tester, find.byType(GamificationSettingsScreen));
    await _pumpFrames(tester);
    expect(find.text('Gamification'), findsOneWidget);

    await tester.pageBack();
    await _pumpFrames(tester);
    await _pumpUntil(tester, find.bySemanticsLabel('Leaderboard'));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GamificationSettingsScreen), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'selectors and bottom controls stay fixed while learner content scrolls',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      await _openHome(
        tester,
        scrollToActions: false,
        includeLearnerShell: true,
      );
      final semantics = tester.ensureSemantics();
      final learnerHeader = find.byKey(const Key('unified-learner-header'));
      final topBar = find.byKey(const Key('unified-learner-top-bar'));
      final courseSelector = find.byKey(const Key('unified-course-selector'));
      final lessonSelector = find.byKey(const Key('unified-lesson-selector'));
      final controls = find.byKey(const Key('unified-bottom-controls'));
      expect(learnerHeader, findsOneWidget);
      expect(topBar, findsOneWidget);
      expect(find.byKey(const Key('learner-status-position')), findsNothing);
      expect(courseSelector, findsOneWidget);
      expect(lessonSelector, findsOneWidget);
      expect(controls, findsOneWidget);
      for (final label in [
        'Leaderboard',
        'Review',
        'Buy a coffee',
        'Course Info',
      ]) {
        expect(find.text(label), findsNothing);
        final control = find.bySemanticsLabel(label);
        expect(control, findsOneWidget);
        expect(
          tester
              .getSemantics(control)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
      }
      final controlIcons = [
        find.byIcon(Icons.emoji_events_outlined),
        find.byIcon(Icons.history_edu_outlined),
        find.byIcon(Icons.coffee_outlined),
        find.byIcon(Icons.info_outline),
      ];
      for (final icon in controlIcons) {
        expect(icon, findsOneWidget);
      }
      final controlPositions = controlIcons
          .map((icon) => tester.getRect(icon).center.dx)
          .toList();
      expect(
        controlPositions,
        orderedEquals(controlPositions.toList()..sort()),
      );
      expect(
        find.descendant(
          of: controls,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.decoration is BoxDecoration,
          ),
        ),
        findsNothing,
      );

      final learnerHeaderBefore = tester.getRect(learnerHeader);
      final topBarBefore = tester.getRect(topBar);
      final courseSelectorBefore = tester.getRect(courseSelector);
      final lessonSelectorBefore = tester.getRect(lessonSelector);
      final controlsBefore = tester.getRect(controls);
      final scrollable = _mainLearnerScrollable();
      final position = tester.state<ScrollableState>(scrollable).position;
      final contentOffsetBefore = position.pixels;
      await tester.drag(
        find.byKey(const Key('unified-learner-scroll')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(tester.getRect(learnerHeader), learnerHeaderBefore);
      expect(tester.getRect(topBar), topBarBefore);
      expect(tester.getRect(courseSelector), courseSelectorBefore);
      expect(tester.getRect(lessonSelector), lessonSelectorBefore);
      expect(tester.getRect(controls), controlsBefore);
      expect(position.pixels, greaterThan(contentOffsetBefore));
      expect(
        controlsBefore.bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const Key('unified-learner-page'))).bottom,
        ),
      );
      final finalDuel = find.byKey(
        ValueKey('unified-duel-${course.topics.last.id}'),
      );
      await tester.scrollUntilVisible(finalDuel, 320, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(finalDuel).bottom,
        lessThanOrEqualTo(tester.getRect(controls).top),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'Home reloads the selected course after returning from Settings',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      await _openHome(tester, scrollToActions: false);
      const updatedTitle = 'Italian refreshed in Course Editor';
      final updatedJson = course.toJson()..['title'] = updatedTitle;
      await tester.runAsync(() async {
        await CourseEditorService().saveCourse(
          languageCode: 'IT',
          course: Course.fromJson(updatedJson),
        );
      });

      await tester.tap(find.byTooltip('Settings'));
      await _pumpUntil(tester, find.byType(SettingsScreen));
      await _pumpFrames(tester);
      await tester.pageBack();
      await _pumpFrames(tester);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await _pumpUntil(tester, find.text(updatedTitle));
      expect(find.text(updatedTitle), findsWidgets);
    },
  );

  testWidgets('unified Top Bar keeps learner management action', (
    tester,
  ) async {
    await _openHome(tester, scrollToActions: false, includeLearnerShell: true);

    await tester.tap(find.byKey(const Key('unified-topbar-user')));
    await tester.pumpAndSettle();

    expect(find.text('Learners'), findsOneWidget);
    expect(find.text('Navigation Learner'), findsWidgets);
    expect(find.text('Add learner'), findsOneWidget);
  });

  testWidgets('Settings no longer exposes Gamification', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(course: _courseFixture())),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await _pumpUntil(tester, find.byType(SettingsScreen));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Gamification'), findsNothing);
  });

  testWidgets('Unified Home loading follows system dark appearance', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    final loadingPage = tester.widget<Scaffold>(
      find.byKey(const Key('unified-learner-loading-page')),
    );
    expect(loadingPage.backgroundColor, const Color(0xFF080B09));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Unified Home preserves the learner strip and follows system appearance',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);
      final italianCourse = await _loadItalianCourse(tester);
      await _openHome(
        tester,
        scrollToActions: false,
        includeLearnerShell: true,
      );

      final topBar = find.byKey(const Key('unified-learner-top-bar'));
      final logoFinder = find.byKey(const Key('unified-topbar-logo-image'));
      expect(logoFinder, findsOneWidget);
      final logo = tester.widget<Image>(logoFinder);
      expect(
        (logo.image as AssetImage).assetName,
        'assets/branding/quisquislingo_logo.png',
      );
      expect(logo.height, 52);
      expect(logo.width, 156);
      expect(logo.fit, BoxFit.fill);
      expect(logo.filterQuality, FilterQuality.high);
      expect(
        find.ancestor(of: logoFinder, matching: find.byType(ClipRect)),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.forum_rounded), findsNothing);

      var page = tester.widget<Scaffold>(
        find.byKey(const Key('unified-learner-page')),
      );
      var pageTheme = Theme.of(
        tester.element(find.byKey(const Key('unified-learner-page'))),
      );
      expect(find.text('Navigation Learner'), findsOneWidget);
      expect(find.byIcon(Icons.face_outlined), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      final topBarOrder = [
        find.byKey(const Key('unified-topbar-user')),
        find.byKey(const Key('unified-topbar-logo-mark')),
        find.byKey(const Key('unified-topbar-streak')),
        find.byKey(const Key('unified-topbar-laurels')),
        find.byKey(const Key('unified-topbar-weekly-xp')),
        find.byKey(const Key('unified-topbar-settings')),
      ].map((finder) => tester.getRect(finder).center.dx).toList();
      expect(topBarOrder, orderedEquals(topBarOrder.toList()..sort()));
      expect(
        find.descendant(of: topBar, matching: find.text(italianCourse.title)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('unified-course-selector')),
          matching: find.text(italianCourse.title),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: topBar, matching: find.byType(CourseFlagBadge)),
        findsNothing,
      );
      expect(find.textContaining('Course Progress'), findsNothing);
      expect(find.byKey(const Key('learner-status-position')), findsNothing);
      final topBarRect = tester.getRect(topBar);
      final contentRect = tester.getRect(
        find.byKey(const Key('unified-course-selector')),
      );
      final lessonSelectorRect = tester.getRect(
        find.byKey(const Key('unified-lesson-selector')),
      );
      expect(topBarRect.bottom, lessThanOrEqualTo(contentRect.top));
      expect(contentRect.bottom, lessThanOrEqualTo(lessonSelectorRect.top));
      expect(pageTheme.brightness, Brightness.light);
      expect(page.backgroundColor, const Color(0xFFF7F3E8));
      var topBarMaterial = tester.widget<Material>(topBar);
      expect(topBarMaterial.color, pageTheme.colorScheme.surface);
      expect(topBarMaterial.color!.computeLuminance(), greaterThan(.5));
      var background = tester.widget<CourseFlagBackdrop>(
        find.byKey(const Key('unified-learner-flag-background')),
      );
      expect(background.course.courseId, italianCourse.courseId);
      expect(background.fallbackCode, 'IT');
      expect(background.opacity, 1);
      expect(
        find.image(const AssetImage('assets/olive_tree.png')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('unified-learner-background-tint')),
        findsNothing,
      );
      final selector = find.byKey(const Key('unified-lesson-selector'));
      final courseSelectorSurface = find.byKey(
        const Key('unified-course-selector-surface'),
      );
      expect(courseSelectorSurface, findsOneWidget);
      final courseSelectorRect = tester.getRect(courseSelectorSurface);
      final courseSelectorInkWell = tester.widget<InkWell>(
        find.byKey(const Key('unified-course-selector')),
      );
      expect(
        (courseSelectorInkWell.child! as Padding).padding,
        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      );
      expect(
        tester.widget<OutlinedButton>(selector).style?.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      );
      expect(courseSelectorRect.height, greaterThanOrEqualTo(48));
      expect(tester.getRect(selector).height, greaterThanOrEqualTo(48));
      expect(
        tester.widget<Material>(courseSelectorSurface).color,
        Colors.white.withValues(alpha: .5),
      );
      expect(
        _buttonBackgroundColor(tester, selector),
        Colors.white.withValues(alpha: .5),
      );

      dispatcher.platformBrightnessTestValue = Brightness.dark;
      await _pumpFrames(tester, count: 4);

      page = tester.widget<Scaffold>(
        find.byKey(const Key('unified-learner-page')),
      );
      pageTheme = Theme.of(
        tester.element(find.byKey(const Key('unified-learner-page'))),
      );
      topBarMaterial = tester.widget<Material>(topBar);
      background = tester.widget<CourseFlagBackdrop>(
        find.byKey(const Key('unified-learner-flag-background')),
      );
      expect(pageTheme.brightness, Brightness.dark);
      expect(page.backgroundColor, const Color(0xFF080B09));
      expect(topBarMaterial.color, pageTheme.colorScheme.surface);
      expect(topBarMaterial.color!.computeLuminance(), lessThan(.2));
      expect(background.course.courseId, italianCourse.courseId);
      expect(background.fallbackCode, 'IT');
      expect(background.opacity, 1);
      expect(
        pageTheme.colorScheme.onSurface.computeLuminance(),
        greaterThan(.5),
      );
      expect(tester.getRect(courseSelectorSurface), courseSelectorRect);
      expect(
        tester.widget<Material>(courseSelectorSurface).color,
        pageTheme.colorScheme.surface.withValues(alpha: .5),
      );
      expect(
        _buttonBackgroundColor(tester, selector),
        pageTheme.colorScheme.surface.withValues(alpha: .5),
      );
      final lessonTitle = tester.widget<Text>(
        find.descendant(
          of: selector,
          matching: find.text('Lesson 1: ${italianCourse.topics.first.title}'),
        ),
      );
      final lessonProgress = tester.widget<Text>(
        find.descendant(
          of: selector,
          matching: find.textContaining('Rounds completed'),
        ),
      );
      expect(lessonTitle.style?.color, Colors.white);
      expect(
        lessonTitle.style?.fontSize,
        pageTheme.textTheme.titleMedium?.fontSize,
      );
      expect(lessonTitle.style?.fontWeight, FontWeight.w900);
      expect(lessonProgress.style?.color, Colors.white);
      expect(
        lessonProgress.style?.fontSize,
        pageTheme.textTheme.bodySmall?.fontSize,
      );
      expect(lessonProgress.style?.fontWeight, FontWeight.normal);
      expect(
        _contrastRatio(Colors.white, page.backgroundColor!),
        greaterThanOrEqualTo(4.5),
      );

      await tester.tap(selector);
      await tester.pumpAndSettle();
      final lessonSheet = find.byType(BottomSheet);
      expect(lessonSheet, findsOneWidget);
      expect(Theme.of(tester.element(lessonSheet)).brightness, Brightness.dark);
      Navigator.of(tester.element(lessonSheet)).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Unified Home supports narrow width and enlarged text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await _pumpUntil(tester, find.text('Alpha expiry'));
    await _dismissAlphaNotice(tester);
    await _pumpFrames(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    final pageWidth = tester
        .getRect(find.byKey(const Key('unified-learner-page')))
        .width;
    final courseSelectorWidth = tester
        .getRect(find.byKey(const Key('unified-course-selector')))
        .width;
    final lessonSelectorWidth = tester
        .getRect(find.byKey(const Key('unified-lesson-selector')))
        .width;
    expect(courseSelectorWidth, lessThan(pageWidth - 28));
    expect(lessonSelectorWidth, lessThan(pageWidth - 28));
    expect(courseSelectorWidth, greaterThanOrEqualTo(pageWidth * .85));
    expect(lessonSelectorWidth, greaterThanOrEqualTo(pageWidth * .85));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected course changes the learner flag background', (
    tester,
  ) async {
    final germanCourse = await _loadCourse(tester, 'DE');
    await _openHome(tester, scrollToActions: false);

    var background = tester.widget<CourseFlagBackdrop>(
      find.byKey(const Key('unified-learner-flag-background')),
    );
    expect(background.fallbackCode, 'IT');

    await tester.tap(find.byKey(const Key('unified-course-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'German').last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await _pumpFrames(tester, count: 20);
    expect(find.byType(BottomSheet), findsNothing);

    background = tester.widget<CourseFlagBackdrop>(
      find.byKey(const Key('unified-learner-flag-background')),
    );
    expect(background.course.courseId, germanCourse.courseId);
    expect(background.fallbackCode, 'DE');
  });

  testWidgets(
    'course picker places three other recent courses before the complete list',
    (tester) async {
      final settings = SettingsService();
      for (final ref in ['DE', 'ES', 'FI', 'PT', 'IT']) {
        await settings.setLastSelectedCourseCode(ref);
      }
      await _openHome(tester, scrollToActions: false);

      await tester.tap(find.byKey(const Key('unified-course-selector')));
      await tester.pumpAndSettle();

      final currentTop = tester.getRect(find.text('Current course')).top;
      final recentTop = tester.getRect(find.text('Recently opened')).top;
      final allTop = tester.getRect(find.text('All included courses')).top;
      expect(currentTop, lessThan(recentTop));
      expect(recentTop, lessThan(allTop));

      final recentTiles = find.byType(ListTile).evaluate().where((element) {
        final center = tester
            .getRect(
              find.byElementPredicate(
                (candidate) => identical(candidate, element),
              ),
            )
            .center
            .dy;
        return center > recentTop && center < allTop;
      }).toList();
      expect(recentTiles, hasLength(3));

      final recentTitles = ['Portuguese', 'Finnish', 'Spanish'];
      final recentPositions = recentTitles
          .map((title) => tester.getRect(find.text(title).first).center.dy)
          .toList();
      expect(recentPositions, orderedEquals(recentPositions.toList()..sort()));
      for (final position in recentPositions) {
        expect(position, greaterThan(recentTop));
        expect(position, lessThan(allTop));
      }
    },
  );

  testWidgets(
    'Welcome and Alpha expiry dialogs retain their structure and controls',
    (tester) async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Popup Learner');

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await _pumpUntil(tester, find.text('Welcome to QuisquisLingo'));

      expect(find.byType(AlertDialog), findsOneWidget);
      final dialogTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Text),
            ),
          )
          .where((text) => text.data != null)
          .toList();
      final phrase = dialogTexts.singleWhere(
        (text) =>
            text.data != 'Welcome to QuisquisLingo' &&
            text.data != 'Version 2.0.18' &&
            text.data != 'Continue',
      );
      final welcomeDialog = tester.widget<AlertDialog>(
        find.byType(AlertDialog),
      );
      expect(welcomeDialog.backgroundColor, const Color(0xFFFFE600));
      expect(welcomeDialog.surfaceTintColor, Colors.transparent);
      expect(
        tester.widget<Text>(find.text('Welcome to QuisquisLingo')).style?.color,
        const Color(0xFF0756DF),
      );
      expect(
        tester.widget<Text>(find.text('Version 2.0.18')).style?.color,
        const Color(0xFF0756DF),
      );
      expect(phrase.style?.color, const Color(0xFF0756DF));
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
      expect(
        tester
            .widgetList<ModalBarrier>(find.byType(ModalBarrier))
            .any((barrier) => !barrier.dismissible),
        isTrue,
      );

      await tester.tap(find.text('Continue'));
      await _pumpUntil(tester, find.text('Alpha expiry'));

      late bool welcomeSeen;
      await tester.runAsync(() async {
        welcomeSeen = await SettingsService().hasSeenOneTimeNotice(
          'welcome_2.0.18',
        );
      });
      expect(welcomeSeen, isTrue);
      expect(find.byType(AlertDialog), findsOneWidget);
      final alphaDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alphaDialog.backgroundColor, isNull);
      expect(alphaDialog.surfaceTintColor, isNull);
      expect(find.textContaining('Expiry date: 2026-09-29.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'OK'), findsOneWidget);
      expect(
        tester
            .widgetList<ModalBarrier>(find.byType(ModalBarrier))
            .any((barrier) => !barrier.dismissible),
        isTrue,
      );
    },
  );

  testWidgets('Welcome popup keeps its yellow and blue palette in dark mode', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Dark Popup Learner');

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await _pumpUntil(tester, find.text('Welcome to QuisquisLingo'));

    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.backgroundColor, const Color(0xFFFFE600));
    expect(dialog.surfaceTintColor, Colors.transparent);
    final popupText = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Text),
          ),
        )
        .where((text) => text.data != null && text.data != 'Continue');
    expect(popupText, isNotEmpty);
    for (final text in popupText) {
      expect(text.style?.color, const Color(0xFF0756DF));
    }
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(
      tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .any((barrier) => !barrier.dismissible),
      isTrue,
    );
  });
}

void _installEventChannelMock(
  TestDefaultBinaryMessenger messenger,
  String channel,
) {
  messenger.setMockMessageHandler(channel, (message) async {
    return const StandardMethodCodec().encodeSuccessEnvelope(null);
  });
}

Course _courseFixture() => Course(
  courseId: 'navigation_course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Navigation Course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  topics: const [],
);

Future<Course> _loadItalianCourse(
  WidgetTester tester, {
  bool enableIddqd = true,
}) async {
  return _loadCourse(tester, 'IT', enableIddqd: enableIddqd);
}

Future<Course> _loadCourse(
  WidgetTester tester,
  String code, {
  bool enableIddqd = true,
}) async {
  late Course course;
  await tester.runAsync(() async {
    course = await CourseService().loadCourse(code);
    await SettingsService().setIddqdModeEnabled(course.courseId, enableIddqd);
  });
  return course;
}

Future<void> _openHome(
  WidgetTester tester, {
  bool scrollToActions = true,
  bool includeLearnerShell = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: includeLearnerShell ? learnerNavigatorKey : null,
      navigatorObservers: includeLearnerShell
          ? [learnerStatusRouteObserver]
          : const [],
      builder: includeLearnerShell
          ? (context, child) => LearnerShell(child: child!)
          : null,
      home: const HomeScreen(),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await _pumpUntil(tester, find.text('Alpha expiry'));
  await _dismissAlphaNotice(tester);
  for (var frame = 0; frame < 10; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  if (scrollToActions) {
    await tester.ensureVisible(
      find.byKey(const Key('unified-bottom-controls')),
    );
  }
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = max(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  final darker = min(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  return (lighter + .05) / (darker + .05);
}

Finder _mainLearnerScrollable() => find.byWidgetPredicate(
  (widget) =>
      widget is Scrollable && widget.physics is AlwaysScrollableScrollPhysics,
);

Finder _lessonSelectorLabel(Course course, int topicIndex) => find.descendant(
  of: find.byKey(const Key('unified-lesson-selector')),
  matching: find.text(
    'Lesson ${topicIndex + 1}: ${course.topics[topicIndex].title}',
  ),
);

Finder _lessonArrowButton(String tooltip) => find.widgetWithIcon(
  IconButton,
  tooltip == 'Previous Lesson' ? Icons.chevron_left : Icons.chevron_right,
);

Finder _flagBackdropText() => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith('flag-backdrop-');
});

Color? _buttonBackgroundColor(WidgetTester tester, Finder button) => tester
    .widget<OutlinedButton>(button)
    .style
    ?.backgroundColor
    ?.resolve(const {});

Future<void> _dismissAlphaNotice(WidgetTester tester) async {
  if (find.text('Alpha expiry').evaluate().isEmpty) return;
  await tester.tap(find.text('OK'));
  await tester.pump();
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 16}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 120; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .toList();
  fail('Timed out waiting for the requested widget. Text: $visibleText');
}
