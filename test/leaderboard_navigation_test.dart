import 'dart:math';
import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/info_screen.dart';
import 'package:quisquislingo_app/screens/profile_screen.dart';
import 'package:quisquislingo_app/screens/review_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
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
      version: '2.0.20',
      buildNumber: '220',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({
      'one_time_notice_seen_welcome_2.0.20': true,
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
    'GuideBook and Duel stay centered, compact, and surface-only translucent',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      await _openHome(tester, scrollToActions: false);
      final viewport = tester.getRect(
        find.byKey(const Key('unified-learner-scroll')),
      );

      final guidebook = find.byKey(const Key('unified-guidebook-node')).first;
      final guidebookRect = tester.getRect(guidebook);
      expect(guidebookRect.width, lessThanOrEqualTo(400));
      expect(guidebookRect.center.dx, closeTo(viewport.center.dx, 1));
      expect(tester.widget<Card>(guidebook).color!.a, closeTo(.75, .01));

      final duel = find.byKey(
        ValueKey('unified-duel-${course.topics.first.id}'),
      );
      await tester.scrollUntilVisible(
        duel,
        240,
        scrollable: _mainLearnerScrollable(),
      );
      await tester.pumpAndSettle();
      final duelCardFinder = find.descendant(
        of: duel,
        matching: find.byKey(const Key('unified-duel-card')),
      );
      final duelRect = tester.getRect(duelCardFinder);
      expect(duelRect.width, lessThanOrEqualTo(400));
      expect(duelRect.center.dx, closeTo(viewport.center.dx, 1));
      final duelCard = tester.widget<Card>(duelCardFinder);
      expect(duelCard.color!.a, closeTo(.75, .01));
    },
  );

  testWidgets(
    'persisted completion with errors keeps the Round icon bright after rebuild and repeat',
    (tester) async {
      final course = await _loadItalianCourse(tester);
      final lesson = course.topics.first;
      final completedRound = lesson.rounds.first;
      final incompleteRound = lesson.rounds.last;
      final progress = ProgressService();
      await progress.completeRound(
        completedRound.id,
        courseId: course.courseId,
        courseCode: 'IT',
      );
      await progress.recordRecentRound(
        course.courseId,
        lesson.id,
        completedRound.id,
        errors: 3,
      );

      Color iconColor(LearningRound round) {
        final container = tester.widget<Container>(
          find.byKey(ValueKey('unified-round-icon-${round.id}')),
        );
        return (container.decoration! as BoxDecoration).color!;
      }

      await _openHome(tester, scrollToActions: false);
      expect(iconColor(completedRound), const Color(0xFFFFB000));
      expect(iconColor(incompleteRound), const Color(0xFFFFEBC0));

      await tester.pumpWidget(const SizedBox.shrink());
      await _openHome(tester, scrollToActions: false);
      expect(iconColor(completedRound), const Color(0xFFFFB000));

      await progress.completeRound(
        completedRound.id,
        courseId: course.courseId,
        courseCode: 'IT',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _openHome(tester, scrollToActions: false);
      expect(iconColor(completedRound), const Color(0xFFFFB000));
    },
  );

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

  testWidgets('Home Profile opens Profile and back returns Home', (
    tester,
  ) async {
    await _openHome(tester);

    final semantics = tester.ensureSemantics();
    expect(find.text('Leaderboard'), findsNothing);
    expect(find.bySemanticsLabel('Leaderboard'), findsNothing);
    expect(
      find.bySemanticsLabel('Profile, Navigation Learner'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('learner-bottom-profile-avatar')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('learner-bottom-profile')));
    await _pumpUntil(tester, find.byType(ProfileScreen));
    await _pumpFrames(tester);
    expect(find.text('Profile'), findsOneWidget);

    await tester.pageBack();
    await _pumpFrames(tester);
    await _pumpUntil(
      tester,
      find.bySemanticsLabel('Profile, Navigation Learner'),
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    semantics.dispose();
  });

  testWidgets('Home Review and Course Info destinations remain unchanged', (
    tester,
  ) async {
    await _openHome(tester);

    await tester.tap(find.byKey(const Key('learner-bottom-review')));
    await _pumpUntil(tester, find.byType(ReviewScreen));
    expect(find.text('Review'), findsOneWidget);
    await tester.pageBack();
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('learner-bottom-course-info')));
    await _pumpUntil(tester, find.byType(CourseInfoScreen));
    expect(find.text('Course Info'), findsOneWidget);
    await tester.pageBack();
    await _pumpFrames(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
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
      final courseSelector = find.byKey(
        const Key('unified-topbar-course-selector'),
      );
      final lessonSelector = find.byKey(const Key('unified-lesson-selector'));
      final controls = find.byKey(const Key('unified-bottom-controls'));
      expect(learnerHeader, findsOneWidget);
      expect(topBar, findsOneWidget);
      expect(find.byKey(const Key('learner-status-position')), findsNothing);
      expect(courseSelector, findsOneWidget);
      expect(lessonSelector, findsOneWidget);
      expect(controls, findsOneWidget);
      expect(
        find.bySemanticsLabel('Profile, Navigation Learner'),
        findsOneWidget,
      );
      for (final label in ['Review', 'Course Info']) {
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
      expect(find.bySemanticsLabel('Leaderboard'), findsNothing);
      expect(find.bySemanticsLabel('Buy a coffee'), findsNothing);
      final controlIcons = [
        find.byKey(const Key('learner-bottom-profile-avatar')),
        find.byIcon(Icons.history_edu_outlined),
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
      await _pumpUntil(
        tester,
        find.byKey(const Key('unified-topbar-course-selector')),
      );
      await tester.tap(find.byKey(const Key('unified-topbar-course-selector')));
      await tester.pumpAndSettle();
      expect(find.text(updatedTitle), findsWidgets);
    },
  );

  testWidgets('Settings exposes Profile as the learner identity entry point', (
    tester,
  ) async {
    await _openHome(tester, scrollToActions: false, includeLearnerShell: true);

    expect(find.byKey(const Key('unified-topbar-user')), findsNothing);
    await tester.tap(find.byTooltip('Settings'));
    await _pumpUntil(tester, find.byType(SettingsScreen));
    await _pumpFrames(tester);
    expect(find.widgetWithText(ListTile, 'Profile'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Avatar'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Learner profiles'), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'Profile'));
    await _pumpUntil(tester, find.byType(ProfileScreen));
    await tester.tap(find.widgetWithText(ListTile, 'Learner profiles'));
    await tester.pumpAndSettle();

    expect(find.text('Learners'), findsOneWidget);
    expect(find.text('Navigation Learner'), findsWidgets);
    expect(find.text('Add learner'), findsOneWidget);
  });

  testWidgets('Profile logout returns Home to learner selection', (
    tester,
  ) async {
    await _openHome(tester);

    await tester.tap(find.byKey(const Key('learner-bottom-profile')));
    await _pumpUntil(tester, find.byType(ProfileScreen));
    await tester.drag(
      find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-logout')));
    await _pumpUntil(tester, find.text('Log out of this local profile?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await _pumpUntil(tester, find.text('Learners'));
    await _pumpFrames(tester);

    expect(find.text('Navigation Learner'), findsOneWidget);
    expect(find.text('Add learner'), findsOneWidget);
    expect(await ProfileService().getActiveProfile(), isNull);

    await tester.tap(find.text('Navigation Learner'));
    await _pumpFrames(tester);
    await _pumpUntil(
      tester,
      find.bySemanticsLabel('Profile, Navigation Learner'),
    );
    expect(await ProfileService().getActiveProfile(), 'Navigation Learner');
  });

  testWidgets('Top Bar cat logo opens the existing App Info screen', (
    tester,
  ) async {
    await _openHome(tester, scrollToActions: false, includeLearnerShell: true);

    await tester.tap(find.byKey(const Key('unified-topbar-logo')));
    await _pumpUntil(tester, find.byType(InfoScreen));
    await _pumpFrames(tester);

    expect(find.byKey(const Key('app-info-full-logo')), findsOneWidget);
  });

  testWidgets('Settings no longer exposes Gamification', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          course: _courseFixture(),
          onManageLearners: (_) async {},
        ),
      ),
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
      expect(find.text('Navigation Learner'), findsNothing);
      expect(find.byIcon(Icons.face_outlined), findsNothing);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      final topBarOrder = [
        find.byKey(const Key('unified-topbar-course-selector')),
        find.byKey(const Key('unified-topbar-streak')),
        find.byKey(const Key('unified-topbar-laurels')),
        find.byKey(const Key('unified-topbar-weekly-xp')),
        find.byKey(const Key('unified-topbar-logo')),
        find.byKey(const Key('unified-topbar-settings')),
      ].map((finder) => tester.getRect(finder).center.dx).toList();
      expect(topBarOrder, orderedEquals(topBarOrder.toList()..sort()));
      expect(
        find.descendant(of: topBar, matching: find.text(italianCourse.title)),
        findsNothing,
      );
      expect(find.text(italianCourse.title), findsNothing);
      expect(
        find.descendant(of: topBar, matching: find.byType(CourseFlagBadge)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('unified-course-selector')), findsNothing);
      expect(find.textContaining('Course Progress'), findsNothing);
      expect(find.byKey(const Key('learner-status-position')), findsNothing);
      final topBarRect = tester.getRect(topBar);
      final lessonSelectorRect = tester.getRect(
        find.byKey(const Key('unified-lesson-selector')),
      );
      expect(topBarRect.bottom, lessThanOrEqualTo(lessonSelectorRect.top));
      expect(pageTheme.brightness, Brightness.light);
      expect(page.backgroundColor, const Color(0xFFF7F3E8));
      var topBarMaterial = tester.widget<Material>(topBar);
      expect(topBarMaterial.color, Colors.white);
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
      expect(find.byKey(const Key('unified-learner-dark-veil')), findsNothing);
      final selector = find.byKey(const Key('unified-lesson-selector'));
      final courseSelector = find.byKey(
        const Key('unified-topbar-course-selector'),
      );
      expect(courseSelector, findsOneWidget);
      final courseSelectorRect = tester.getRect(courseSelector);
      final courseSelectorInkWell = tester.widget<InkWell>(
        find.descendant(of: courseSelector, matching: find.byType(InkWell)),
      );
      expect(courseSelectorInkWell.onTap, isNotNull);
      expect(
        find.descendant(of: courseSelector, matching: find.byType(Text)),
        findsNothing,
      );
      expect(
        tester.widget<OutlinedButton>(selector).style?.padding?.resolve({}),
        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      );
      expect(courseSelectorRect.height, greaterThanOrEqualTo(48));
      expect(courseSelectorRect.width, lessThanOrEqualTo(56));
      expect(tester.getRect(selector).height, greaterThanOrEqualTo(48));
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
      final darkVeil = tester.widget<ColoredBox>(
        find.byKey(const Key('unified-learner-dark-veil')),
      );
      expect(darkVeil.color.a, closeTo(.18, .01));
      expect(
        darkVeil.color.withValues(alpha: 1),
        pageTheme.colorScheme.surface,
      );
      expect(
        pageTheme.colorScheme.onSurface.computeLuminance(),
        greaterThan(.5),
      );
      expect(tester.getRect(courseSelector), courseSelectorRect);
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
    final courseSelector = find.byKey(
      const Key('unified-topbar-course-selector'),
    );
    final courseSelectorWidth = tester.getRect(courseSelector).width;
    final lessonSelectorWidth = tester
        .getRect(find.byKey(const Key('unified-lesson-selector')))
        .width;
    expect(courseSelectorWidth, lessThanOrEqualTo(56));
    expect(lessonSelectorWidth, lessThan(pageWidth - 28));
    expect(lessonSelectorWidth, greaterThanOrEqualTo(pageWidth * .85));
    for (final key in const [
      Key('unified-topbar-course-selector'),
      Key('unified-topbar-streak'),
      Key('unified-topbar-laurels'),
      Key('unified-topbar-weekly-xp'),
      Key('unified-topbar-logo'),
      Key('unified-topbar-settings'),
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }
    expect(
      find.descendant(of: courseSelector, matching: find.byType(Text)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected course changes the learner flag background', (
    tester,
  ) async {
    final italianCourse = await _loadItalianCourse(tester);
    final germanCourse = await _loadCourse(tester, 'DE');
    await _openHome(tester, scrollToActions: false);

    var background = tester.widget<CourseFlagBackdrop>(
      find.byKey(const Key('unified-learner-flag-background')),
    );
    expect(background.course.courseId, italianCourse.courseId);
    expect(background.fallbackCode, 'IT');

    await tester.tap(find.byKey(const Key('unified-topbar-course-selector')));
    await tester.pumpAndSettle();
    final fullPicker = tester.widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(fullPicker.heightFactor, greaterThanOrEqualTo(.65));
    expect(find.text('Choose course'), findsOneWidget);
    expect(find.text('Current course'), findsOneWidget);
    expect(find.text('All included courses'), findsOneWidget);
    expect(find.text(italianCourse.title), findsWidgets);
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
    final compactFlag = tester.widget<CourseFlagBadge>(
      find.descendant(
        of: find.byKey(const Key('unified-topbar-course-selector')),
        matching: find.byType(CourseFlagBadge),
      ),
    );
    expect(compactFlag.course.courseId, germanCourse.courseId);
    expect(compactFlag.fallbackCode, 'DE');
  });

  testWidgets(
    'course picker places three other recent courses before the complete list',
    (tester) async {
      final settings = SettingsService();
      for (final ref in ['DE', 'ES', 'FI', 'PT', 'IT']) {
        await settings.setLastSelectedCourseCode(ref);
      }
      await _openHome(tester, scrollToActions: false);

      await tester.tap(find.byKey(const Key('unified-topbar-course-selector')));
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
            text.data != 'Version 2.0.20' &&
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
        tester.widget<Text>(find.text('Version 2.0.20')).style?.color,
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
          'welcome_2.0.20',
        );
      });
      expect(welcomeSeen, isTrue);
      expect(find.byType(AlertDialog), findsOneWidget);
      final alphaDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alphaDialog.backgroundColor, isNull);
      expect(alphaDialog.surfaceTintColor, isNull);
      expect(find.textContaining('Expiry date: 2026-10-01.'), findsOneWidget);
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
