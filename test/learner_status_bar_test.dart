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
import 'package:quisquislingo_app/widgets/learner_shell.dart';
import 'package:quisquislingo_app/widgets/learner_status_bar.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/learner_navigation.dart';
import 'package:quisquislingo_app/screens/review_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Profiles extends ProfileService {
  String active = 'Tester';

  @override
  Future<String?> getActiveProfile() async => active;
}

class _Settings extends SettingsService {
  String? selected = 'IT';
  int goal = 2000;

  @override
  Future<String?> getLastSelectedCourseCode() async => selected;

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
  Future<List<Course>> listUserCourses() async => [];
}

class _Progress extends ProgressService {
  _Progress() : super(now: () => DateTime(2026, 8, 27, 12));

  int weekly = 1250;
  int streak = 14;
  int laurels = 7;

  @override
  Future<int> getWeeklyXp() async => weekly;

  @override
  Future<int> getStreak({required String courseCode}) async => streak;

  @override
  Future<Set<String>> getPerfectRounds({required String courseId}) async => {
    for (var index = 0; index < laurels; index++) 'round_$index',
  };
}

Course _course({String title = 'Italian', String flagCode = 'IT'}) => Course(
  courseId: 'course_it',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  version: '1',
  flagCode: flagCode,
  topics: [
    Topic(
      id: 'topic_it',
      title: 'Lesson',
      rounds: [
        for (var index = 0; index < 7; index++)
          LearningRound(
            id: 'round_$index',
            title: 'Round ${index + 1}',
            content: [
              LearningContent.textual(
                id: 'content_$index',
                kind: 'explanation',
                role: 'round_note',
                text: 'Information $index',
              ),
            ],
          ),
      ],
    ),
  ],
);

final _topic = Topic(id: 'topic', title: 'Topic', rounds: const []);

Course _navigationCourse() => Course(
  courseId: 'navigation_course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Navigation course',
  ttsLanguage: 'it-IT',
  version: '1',
  topics: [_topic],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Profiles profiles;
  late _Settings settings;
  late _Courses courses;
  late _Progress progress;
  late StreamController<LearnerStatusInvalidation> events;
  late LearnerStatusController controller;

  setUp(() async {
    resetLearnerStatusRouteObserver();
    SharedPreferences.setMockInitialValues({});
    profiles = _Profiles();
    settings = _Settings();
    courses = _Courses()..course = _course();
    progress = _Progress();
    events = StreamController<LearnerStatusInvalidation>.broadcast(sync: true);
    controller = LearnerStatusController(
      profileService: profiles,
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
    LearnerStatusForeground foreground = LearnerStatusForeground.dark,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: width,
        height: 700,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            navigatorKey: learnerNavigatorKey,
            navigatorObservers: [learnerStatusRouteObserver],
            builder: (context, child) =>
                LearnerShell(controller: controller, child: child!),
            home: LearnerStatusPage(
              foreground: foreground,
              child: Scaffold(
                appBar: LearnerStatusAppBar(
                  appBar: AppBar(title: const Text('HomeScreen')),
                ),
                body: Builder(
                  builder: (context) => Column(
                    children: [
                      FilledButton(
                        key: const Key('push-learner-page'),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LearnerStatusPage(
                              child: Scaffold(
                                appBar: LearnerStatusAppBar(
                                  appBar: AppBar(
                                    title: const Text('Lesson page'),
                                  ),
                                ),
                                body: const Text('Lesson and Review'),
                              ),
                            ),
                          ),
                        ),
                        child: const Text('Push learner page'),
                      ),
                      FilledButton(
                        key: const Key('push-round'),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              body: Center(child: Text('RoundScreen')),
                            ),
                          ),
                        ),
                        child: const Text('Push round'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'bar stays fixed through learner route animation and hides for Round',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump();
      final before = tester.getTopLeft(
        find.byKey(const Key('learner-status-position')),
      );

      await tester.tap(find.byKey(const Key('push-learner-page')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester.getTopLeft(find.byKey(const Key('learner-status-position'))),
        before,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('learner-status-position'))),
        before,
      );

      Navigator.of(tester.element(find.text('Lesson page'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('push-round')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('learner-status-position')), findsNothing);
    },
  );

  testWidgets(
    'final order uses accented icons and title yields before numeric fields',
    (tester) async {
      courses.course = _course(
        title:
            'An exceptionally long imported custom course title that cannot fit',
      );
      await controller.refresh();
      await tester.pumpWidget(app(width: 320, textScale: 1.5));
      await tester.pump();

      final title = tester.widget<Text>(
        find.text(
          'An exceptionally long imported custom course title that cannot fit',
        ),
      );
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(find.text('1250 / 2000'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final flame = find.byKey(const Key('learner-status-flame-icon'));
      final flag = find.byType(CourseFlagBadge);
      final courseTitle = find.text(
        'An exceptionally long imported custom course title that cannot fit',
      );
      final laurel = find.byKey(const Key('learner-status-laurel-icon'));
      final xp = find.byKey(const Key('learner-status-xp-icon'));
      expect(tester.widget<Icon>(flame).color, const Color(0xFFF05A28));
      expect(tester.getRect(flame).left, greaterThanOrEqualTo(1));
      expect(tester.widget<Icon>(laurel).color, const Color(0xFF2E8B57));
      expect(xp, findsOneWidget);
      expect(flag, findsOneWidget);
      final ordered = [
        flame,
        find.text('14'),
        flag,
        courseTitle,
        laurel,
        find.text('7'),
        xp,
        find.text('1250 / 2000'),
      ].map((finder) => tester.getRect(finder).center.dx).toList();
      expect(ordered, ordered.toList()..sort());
    },
  );

  testWidgets(
    '1-5 digit XP changes stay unpadded and preserve other numeric fields',
    (tester) async {
      await tester.pumpWidget(app(width: 430));
      await tester.pump();
      final xpLeft = tester.getTopLeft(
        find.byKey(const Key('learner-status-xp-numbers')),
      );
      final streakLeft = tester.getTopLeft(
        find.byKey(const Key('learner-status-streak-number')),
      );

      for (final value in [1, 12, 999, 1000, 99999]) {
        progress.weekly = value;
        progress.streak = value.clamp(0, 9999);
        settings.goal = value;
        await controller.refresh();
        await tester.pump();
        expect(find.text('$value / $value'), findsOneWidget);
        expect(find.text('${value.clamp(0, 9999)}'), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(const Key('learner-status-xp-numbers'))),
          xpLeft,
        );
        expect(
          tester.getTopLeft(
            find.byKey(const Key('learner-status-streak-number')),
          ),
          streakLeft,
        );
      }
    },
  );

  testWidgets('XP icon keeps the same small gap for 1 and 5 digits', (
    tester,
  ) async {
    settings.goal = 20000;
    progress.weekly = 1;
    await controller.refresh();
    await tester.pumpWidget(app(width: 430));
    await tester.pump();

    double iconToNumberGap(String text) =>
        tester.getRect(find.text(text)).left -
        tester.getRect(find.byKey(const Key('learner-status-xp-icon'))).right;

    final oneDigitGap = iconToNumberGap('1 / 20000');
    expect(oneDigitGap, closeTo(1, 0.01));

    progress.weekly = 99999;
    await controller.refresh();
    await tester.pump();

    expect(iconToNumberGap('99999 / 20000'), closeTo(oneDigitGap, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('light and dark foreground contracts color status text', (
    tester,
  ) async {
    await tester.pumpWidget(app(foreground: LearnerStatusForeground.light));
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('Italian')).style?.color,
      Colors.white,
    );

    await tester.pumpWidget(app(foreground: LearnerStatusForeground.dark));
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('Italian')).style?.color,
      const Color(0xFF173F35),
    );
  });

  testWidgets(
    'accessibility scaling is retained without overflow at narrow and desktop widths',
    (tester) async {
      courses.course = _course(title: 'A long course title that must yield');
      progress.weekly = 54321;
      settings.goal = 98765;
      await controller.refresh();

      await tester.pumpWidget(app(width: 320, textScale: 1));
      await tester.pump();
      final unscaledHeight = tester.getSize(find.text('54321 / 98765')).height;

      for (final width in [320.0, 430.0]) {
        await tester.pumpWidget(app(width: width, textScale: 1.5));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('54321 / 98765'), findsOneWidget);
        expect(
          tester.getSize(find.text('54321 / 98765')).height,
          greaterThan(unscaledHeight),
        );
      }
    },
  );

  testWidgets(
    'course, XP, streak, and Laurel targets show explanations and semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app());
      await tester.pump();

      expect(find.bySemanticsLabel('Current course: Italian'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Weekly XP: 1250 out of 2000'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Italian streak: 14 days'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Laurels in this course: 7'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('learner-status-course')));
      await tester.pumpAndSettle();
      expect(find.text('Italian'), findsWidgets);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('learner-status-xp')));
      await tester.pumpAndSettle();
      expect(find.text('Weekly XP: 1250 out of 2000'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('learner-status-streak')));
      await tester.pumpAndSettle();
      expect(find.text('Italian streak: 14 days'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('learner-status-laurels')));
      await tester.pumpAndSettle();
      expect(find.text('Laurels in this course: 7'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('missing active course leaves only weekly XP target', (
    tester,
  ) async {
    settings.selected = 'custom:missing';
    await controller.refresh();
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byKey(const Key('learner-status-course')), findsNothing);
    expect(find.byKey(const Key('learner-status-streak')), findsNothing);
    expect(find.byKey(const Key('learner-status-laurels')), findsNothing);
    expect(find.byKey(const Key('learner-status-laurel-icon')), findsNothing);
    expect(find.byType(CourseFlagBadge), findsNothing);
    expect(find.text('1250 / 2000'), findsOneWidget);
  });

  testWidgets('Home and Review use the identical learner-shell position', (
    tester,
  ) async {
    final course = _navigationCourse();
    await tester.pumpWidget(app());
    await tester.pump();
    final before = tester.getTopLeft(
      find.byKey(const Key('learner-status-position')),
    );

    unawaited(
      Navigator.of(
        tester.element(find.byType(LearnerStatusPage).last),
      ).push<void>(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(course: course, courseCode: 'IT'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const Key('learner-status-position'))),
      before,
    );
  });
}
