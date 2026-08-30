import 'dart:math';

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
      version: '2.0.16',
      buildNumber: '216',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({
      'one_time_notice_seen_welcome_2.0.16': true,
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
    'Lesson selector opens the picker and changes the active Lesson',
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
      final secondTopic = course.topics[1];
      final secondLesson = find.text('Lesson 2: ${secondTopic.title}');
      await _pumpUntil(tester, secondLesson);
      await tester.pumpAndSettle();
      expect(find.text('Browse All Lessons'), findsNothing);
      expect(secondLesson, findsOneWidget);
      final secondLessonTile = find.ancestor(
        of: secondLesson,
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: secondLessonTile,
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      await tester.tap(secondLesson);
      await _pumpFrames(tester);
      expect(find.text('Lesson 2: ${secondTopic.title}'), findsOneWidget);
      late String? persistedTopicId;
      await tester.runAsync(() async {
        persistedTopicId = await SettingsService().getLastVisitedTopicId(
          course.courseId,
        );
      });
      expect(persistedTopicId, secondTopic.id);

      const unavailable =
          'Unavailable for this Lesson: not enough suitable exercises.';
      await tester.scrollUntilVisible(
        find.byKey(const Key('unified-duel-card')),
        240,
        scrollable: _mainLearnerScrollable(),
      );
      await tester.pump();
      await tester.ensureVisible(find.text(unavailable));
      expect(find.text(unavailable), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
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
      await _openHome(
        tester,
        scrollToActions: false,
        includeLearnerShell: true,
      );
      final semantics = tester.ensureSemantics();
      final learnerHeader = find.byKey(const Key('unified-learner-header'));
      final userBar = find.byKey(const Key('unified-learner-logo'));
      final statusBar = find.byKey(const Key('learner-status-position'));
      final courseSelector = find.byKey(const Key('unified-course-selector'));
      final lessonSelector = find.byKey(const Key('unified-lesson-selector'));
      final controls = find.byKey(const Key('unified-bottom-controls'));
      expect(learnerHeader, findsOneWidget);
      expect(userBar, findsOneWidget);
      expect(statusBar, findsOneWidget);
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
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
      expect(find.byIcon(Icons.history_edu_outlined), findsOneWidget);
      expect(find.byIcon(Icons.coffee_outlined), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      final learnerHeaderBefore = tester.getRect(learnerHeader);
      final userBarBefore = tester.getRect(userBar);
      final statusBarBefore = tester.getRect(statusBar);
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
      expect(tester.getRect(userBar), userBarBefore);
      expect(tester.getRect(statusBar), statusBarBefore);
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
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('unified-duel-card'))).bottom,
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

      final logoFinder = find.byKey(const Key('unified-learner-logo'));
      expect(logoFinder, findsOneWidget);
      final logo = tester.widget<Image>(logoFinder);
      expect(
        (logo.image as AssetImage).assetName,
        'assets/branding/quisquislingo_logo.png',
      );
      expect(logo.width, 156);
      expect(logo.height, 36);
      expect(logo.fit, BoxFit.contain);
      expect(logo.filterQuality, FilterQuality.high);
      expect(find.byIcon(Icons.forum_rounded), findsNothing);

      var page = tester.widget<Scaffold>(
        find.byKey(const Key('unified-learner-page')),
      );
      var statusAppBar = tester.widget<LearnerStatusAppBar>(
        find.byKey(const Key('unified-learner-status-appbar')),
      );
      var pageTheme = Theme.of(
        tester.element(find.byKey(const Key('unified-learner-page'))),
      );
      final appBar = statusAppBar.appBar as AppBar;
      expect(appBar.toolbarHeight, 58);
      expect(appBar.leadingWidth, 150);
      expect(appBar.centerTitle, isTrue);
      expect(find.text('Navigation Learner'), findsOneWidget);
      expect(find.byIcon(Icons.face_outlined), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      final stripOrder = [
        find.byIcon(Icons.face_outlined),
        logoFinder,
        find.byIcon(Icons.settings_outlined),
      ].map((finder) => tester.getRect(finder).center.dx).toList();
      expect(stripOrder, orderedEquals(stripOrder.toList()..sort()));
      final stripRect = tester.getRect(logoFinder);
      final statusRect = tester.getRect(
        find.byKey(const Key('learner-status-position')),
      );
      final contentRect = tester.getRect(
        find.byKey(const Key('unified-course-selector')),
      );
      final lessonSelectorRect = tester.getRect(
        find.byKey(const Key('unified-lesson-selector')),
      );
      expect(stripRect.bottom, lessThanOrEqualTo(statusRect.top));
      expect(statusRect.bottom, lessThanOrEqualTo(contentRect.top));
      expect(contentRect.bottom, lessThanOrEqualTo(lessonSelectorRect.top));
      expect(pageTheme.brightness, Brightness.light);
      expect(page.backgroundColor, const Color(0xFFF7F3E8));
      expect(statusAppBar.backgroundColor, const Color(0xFF214D3B));
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
      expect(
        _buttonBackgroundColor(tester, selector),
        Colors.white.withValues(alpha: .5),
      );

      dispatcher.platformBrightnessTestValue = Brightness.dark;
      await _pumpFrames(tester, count: 4);

      page = tester.widget<Scaffold>(
        find.byKey(const Key('unified-learner-page')),
      );
      statusAppBar = tester.widget<LearnerStatusAppBar>(
        find.byKey(const Key('unified-learner-status-appbar')),
      );
      pageTheme = Theme.of(
        tester.element(find.byKey(const Key('unified-learner-page'))),
      );
      background = tester.widget<CourseFlagBackdrop>(
        find.byKey(const Key('unified-learner-flag-background')),
      );
      expect(pageTheme.brightness, Brightness.dark);
      expect(page.backgroundColor, const Color(0xFF080B09));
      expect(statusAppBar.backgroundColor, page.backgroundColor);
      expect(background.course.courseId, italianCourse.courseId);
      expect(background.fallbackCode, 'IT');
      expect(background.opacity, 1);
      expect(
        pageTheme.colorScheme.onSurface.computeLuminance(),
        greaterThan(.5),
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
      expect(lessonProgress.style?.color, Colors.white);
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
            text.data != 'Version 2.0.16' &&
            text.data != 'Continue',
      );
      expect(
        tester.widget<Text>(find.text('Welcome to QuisquisLingo')).style?.color,
        Colors.white,
      );
      expect(
        tester.widget<Text>(find.text('Version 2.0.16')).style?.color,
        Colors.white,
      );
      expect(phrase.style?.color, Colors.white);
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
          'welcome_2.0.16',
        );
      });
      expect(welcomeSeen, isTrue);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Expiry date: 2026-09-28.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'OK'), findsOneWidget);
      expect(
        tester
            .widgetList<ModalBarrier>(find.byType(ModalBarrier))
            .any((barrier) => !barrier.dismissible),
        isTrue,
      );
    },
  );
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

Future<Course> _loadItalianCourse(WidgetTester tester) async {
  return _loadCourse(tester, 'IT');
}

Future<Course> _loadCourse(WidgetTester tester, String code) async {
  late Course course;
  await tester.runAsync(() async {
    course = await CourseService().loadCourse(code);
    await SettingsService().setIddqdModeEnabled(course.courseId, true);
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
