import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/controllers/learner_status_controller.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/learner_status_events.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/unified_learner_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Profiles extends ProfileService {
  @override
  Future<String?> getActiveProfile() async => 'Top Bar Learner';
}

class _Settings extends SettingsService {
  int goal = 2000;

  @override
  Future<String?> getLastSelectedCourseCode() async => 'IT';

  @override
  Future<int> getWeeklyXpTarget() async => goal;
}

class _Courses extends CourseService {
  late Course course;

  @override
  Future<Course> loadCourse(String languageCode) async => course;
}

class _Editor extends CourseEditorService {
  @override
  Future<List<Course>> listUserCourses() async => const [];
}

class _Progress extends ProgressService {
  _Progress() : super(now: () => DateTime(2026, 8, 30, 12));

  int weeklyXp = 1250;
  int streak = 14;
  Set<String> perfectRounds = {
    for (var index = 0; index < 7; index++) 'round_$index',
  };

  @override
  Future<int> getWeeklyXp() async => weeklyXp;

  @override
  Future<int> getStreak({required String courseCode}) async => streak;

  @override
  Future<Set<String>> getPerfectRounds({required String courseId}) async =>
      perfectRounds;
}

LearningRound _eligibleRound(int index) => LearningRound(
  id: 'round_$index',
  title: 'Round ${index + 1}',
  content: [
    LearningContent.textual(
      id: 'content_$index',
      kind: 'explanation',
      role: 'round_note',
      text: 'Readable information $index',
    ),
  ],
);

LearningRound _nonEligibleRound() => LearningRound(
  id: 'topic_intro_only',
  title: 'Topic introduction only',
  content: [
    LearningContent.textual(
      id: 'topic_intro_content',
      kind: 'explanation',
      role: 'topic_intro',
      text: 'Introduction',
    ),
  ],
);

Course _course(int eligibleRounds) => Course(
  courseId: 'top_bar_course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course name belongs only in the selector',
  ttsLanguage: 'it-IT',
  version: '1',
  topics: [
    Topic(
      id: 'topic',
      title: 'Lesson',
      rounds: [
        for (var index = 0; index < eligibleRounds; index++)
          _eligibleRound(index),
        _nonEligibleRound(),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Settings settings;
  late _Courses courses;
  late _Progress progress;
  late StreamController<LearnerStatusInvalidation> events;
  late LearnerStatusController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = _Settings();
    courses = _Courses()..course = _course(42);
    progress = _Progress();
    events = StreamController<LearnerStatusInvalidation>.broadcast(sync: true);
    controller = LearnerStatusController(
      profileService: _Profiles(),
      settingsService: settings,
      courseService: courses,
      courseEditorService: _Editor(),
      progressService: progress,
      invalidations: events.stream,
      observeLifecycle: false,
    );
    await controller.refresh();
  });

  tearDown(() async {
    controller.dispose();
    await events.close();
  });

  Widget app({
    double width = 430,
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
    VoidCallback? onCoursePressed,
    VoidCallback? onLogoPressed,
    VoidCallback? onSettingsPressed,
  }) => MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F622D),
        brightness: Brightness.light,
      ),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF54D8FF),
        brightness: Brightness.dark,
      ),
    ),
    themeMode: themeMode,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: UnifiedLearnerTopBar(
              controller: controller,
              course: courses.course,
              courseCode: 'IT',
              onCoursePressed: onCoursePressed ?? () {},
              onLogoPressed: onLogoPressed ?? () {},
              onSettingsPressed: onSettingsPressed ?? () {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'one row has exact course, Streak, Laurel, Weekly XP, logo, Settings order',
    (tester) async {
      var courseTaps = 0;
      var logoTaps = 0;
      var settingsTaps = 0;
      await tester.pumpWidget(
        app(
          onCoursePressed: () => courseTaps++,
          onLogoPressed: () => logoTaps++,
          onSettingsPressed: () => settingsTaps++,
        ),
      );
      await tester.pump();

      final groups = [
        find.byKey(const Key('unified-topbar-course-selector')),
        find.byKey(const Key('unified-topbar-streak')),
        find.byKey(const Key('unified-topbar-laurels')),
        find.byKey(const Key('unified-topbar-weekly-xp')),
        find.byKey(const Key('unified-topbar-logo')),
        find.byKey(const Key('unified-topbar-settings')),
      ];
      final centers = groups
          .map((group) => tester.getRect(group).center.dx)
          .toList();
      expect(centers, orderedEquals(centers.toList()..sort()));
      expect(groups.map((group) => tester.getRect(group).center.dy).toSet(), {
        tester.getRect(groups.first).center.dy,
      });
      expect(find.byKey(const Key('unified-topbar-user')), findsNothing);
      expect(find.text('Top Bar Learner'), findsNothing);
      expect(find.byIcon(Icons.face_outlined), findsNothing);
      expect(
        find.text('Course name belongs only in the selector'),
        findsNothing,
      );

      await tester.tap(groups.first);
      await tester.tap(groups[4]);
      await tester.tap(groups.last);
      expect(courseTaps, 1);
      expect(logoTaps, 1);
      expect(settingsTaps, 1);
    },
  );

  testWidgets('course entry point is a compact, clearly visible flag only', (
    tester,
  ) async {
    await tester.pumpWidget(app(width: 320));
    await tester.pump();

    final selector = find.byKey(const Key('unified-topbar-course-selector'));
    final flag = find.descendant(
      of: selector,
      matching: find.byType(CourseFlagBadge),
    );
    expect(flag, findsOneWidget);
    expect(
      find.descendant(of: selector, matching: find.byType(Text)),
      findsNothing,
    );
    expect(tester.getSize(flag).width, greaterThanOrEqualTo(40));
    expect(tester.getSize(flag).height, greaterThanOrEqualTo(28));
    expect(tester.getSize(selector).width, lessThanOrEqualTo(56));
    expect(tester.getSize(selector).height, greaterThanOrEqualTo(48));
  });

  testWidgets('compact mark clips the unchanged full-logo asset', (
    tester,
  ) async {
    await tester.pumpWidget(app(width: 320));
    await tester.pump();

    final imageFinder = find.byKey(const Key('unified-topbar-logo-image'));
    final image = tester.widget<Image>(imageFinder);
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/quisquislingo_logo.png',
    );
    expect(image.width, 120);
    expect(image.height, 40);
    expect(image.fit, BoxFit.fill);
    expect(
      find.ancestor(of: imageFinder, matching: find.byType(ClipRect)),
      findsOneWidget,
    );
    final overflow = tester.widget<OverflowBox>(
      find.ancestor(of: imageFinder, matching: find.byType(OverflowBox)),
    );
    expect(overflow.alignment, Alignment.centerLeft);
    final clipRect = tester.getRect(
      find.byKey(const Key('unified-topbar-logo-clip')),
    );
    final imageRect = tester.getRect(imageFinder);
    expect(imageRect.left, clipRect.left);
    expect(imageRect.right, greaterThan(clipRect.right));
    expect(clipRect.width / imageRect.width, lessThan(552 / 2172));
    expect(clipRect.width / imageRect.width, greaterThan(495 / 2172));
    expect(find.text('QuisquisLingo'), findsNothing);
  });

  testWidgets('required groups expose concise semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await tester.pump();

    expect(
      find.bySemanticsLabel(
        'Choose course: Course name belongs only in the selector',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('QuisquisLingo logo, open App Info'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Learner: Top Bar Learner'), findsNothing);
    expect(find.bySemanticsLabel('Italian streak: 14 days'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Laurels in this course: 7 out of 42'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Weekly XP: 1250 out of 2000'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('required number ranges remain unpadded and do not overflow', (
    tester,
  ) async {
    courses.course = _course(999);
    progress.perfectRounds = const {};
    progress.streak = 1;
    progress.weeklyXp = 1;
    settings.goal = 1;
    await controller.refresh();
    await tester.pumpWidget(app(width: 320, textScale: 1.5));
    await tester.pump();

    final stablePositions = [
      const Key('unified-topbar-streak'),
      const Key('unified-topbar-laurels'),
      const Key('unified-topbar-weekly-xp'),
      const Key('unified-topbar-settings'),
    ].map((key) => tester.getRect(find.byKey(key)).left).toList();

    final cases = [
      (1, 0, 0, 1, 1),
      (999, 7, 42, 999, 2000),
      (1000, 99, 120, 10000, 20000),
      (9999, 999, 999, 99999, 99999),
    ];
    for (final item in cases) {
      progress.streak = item.$1;
      progress.perfectRounds = {
        for (var index = 0; index < item.$2; index++) 'round_$index',
      };
      courses.course = _course(item.$3);
      progress.weeklyXp = item.$4;
      settings.goal = item.$5;
      await controller.refresh();
      await tester.pump();

      expect(
        tester
            .widget<Text>(find.byKey(const Key('unified-topbar-streak-number')))
            .data,
        '${item.$1}',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('unified-topbar-laurel-current')),
            )
            .data,
        '${item.$2}',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('unified-topbar-laurel-maximum')),
            )
            .data,
        '/ ${item.$3}',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('unified-topbar-xp-current')))
            .data,
        '${item.$4}',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('unified-topbar-xp-maximum')))
            .data,
        '/ ${item.$5}',
      );
      expect(tester.takeException(), isNull);
      expect(
        [
          const Key('unified-topbar-streak'),
          const Key('unified-topbar-laurels'),
          const Key('unified-topbar-weekly-xp'),
          const Key('unified-topbar-settings'),
        ].map((key) => tester.getRect(find.byKey(key)).left).toList(),
        stablePositions,
      );
    }
  });

  testWidgets('Laurel and Weekly XP are vertical while Streak stays one line', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    final laurelCurrent = find.byKey(
      const Key('unified-topbar-laurel-current'),
    );
    final laurelMaximum = find.byKey(
      const Key('unified-topbar-laurel-maximum'),
    );
    final xpCurrent = find.byKey(const Key('unified-topbar-xp-current'));
    final xpMaximum = find.byKey(const Key('unified-topbar-xp-maximum'));
    expect(
      tester.getRect(laurelCurrent).center.dy,
      lessThan(tester.getRect(laurelMaximum).center.dy),
    );
    expect(
      tester.getRect(laurelCurrent).center.dx,
      closeTo(tester.getRect(laurelMaximum).center.dx, .5),
    );
    expect(
      tester.getRect(xpCurrent).center.dy,
      lessThan(tester.getRect(xpMaximum).center.dy),
    );
    expect(
      tester.getRect(xpCurrent).center.dx,
      closeTo(tester.getRect(xpMaximum).center.dx, .5),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('unified-topbar-streak')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Streak, Laurel, and Weekly XP explain their meaning', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    for (final item in [
      (
        const Key('unified-topbar-streak'),
        'Italian streak: 14 days. It tracks your current run of study days for this language.',
      ),
      (
        const Key('unified-topbar-laurels'),
        'Course Laurels: 7 out of 42. A Laurel marks a Round completed with zero errors.',
      ),
      (
        const Key('unified-topbar-weekly-xp'),
        'Weekly XP: 1250 out of 2000. It totals this learner\'s XP across all courses for the current week.',
      ),
    ]) {
      await tester.tap(find.byKey(item.$1));
      await tester.pumpAndSettle();
      expect(find.text(item.$2), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('logical groups have explicit horizontal gaps', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    for (final name in [
      'course-streak',
      'streak-laurel',
      'laurel-xp',
      'xp-logo',
      'logo-settings',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey('unified-topbar-gap-$name'))).width,
        greaterThanOrEqualTo(6),
      );
    }
  });

  testWidgets('light and dark surfaces provide contrasting text', (
    tester,
  ) async {
    Future<(Color, Color)> colors(ThemeMode mode) async {
      await tester.pumpWidget(app(themeMode: mode));
      await tester.pumpAndSettle();
      final material = tester.widget<Material>(
        find.byKey(const Key('unified-learner-top-bar')),
      );
      final text = tester.widget<Text>(
        find.byKey(const Key('unified-topbar-streak-number')),
      );
      return (material.color!, text.style!.color!);
    }

    final light = await colors(ThemeMode.light);
    expect(light.$1, Colors.white);
    expect(light.$1.computeLuminance(), greaterThan(.5));
    expect(_contrastRatio(light.$2, light.$1), greaterThanOrEqualTo(4.5));

    final dark = await colors(ThemeMode.dark);
    expect(dark.$1.computeLuminance(), lessThan(.2));
    expect(_contrastRatio(dark.$2, dark.$1), greaterThanOrEqualTo(4.5));
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + .05) / (darker + .05);
}
