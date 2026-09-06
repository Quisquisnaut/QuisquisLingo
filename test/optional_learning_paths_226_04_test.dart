import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/guidebook_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
    });
    await ProfileService().addProfile('Optional paths learner');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  for (final enabled in [false, true]) {
    for (final count in [24, 25]) {
      test('Duel enabled=$enabled count=$count uses canonical eligibility', () {
        final course = _course(createDuels: enabled, count: count);
        final eligibility = const DuelEligibilityService().evaluate(
          course.lessons.single,
        );
        expect(eligibility.eligibleCount, count);
        expect(eligibility.isAvailable, count == 25);
        final unavailable = CourseAuditService()
            .auditCourse(course)
            .issues
            .where((issue) => issue.code == 'DUEL_UNAVAILABLE');
        expect(unavailable.length, enabled && count < 25 ? 1 : 0);
      });

      testWidgets(
        'Home Duel enabled=$enabled count=$count has no placeholder',
        (tester) async {
          final course = _course(createDuels: enabled, count: count);
          await _openHome(tester, course);
          final visible = enabled && count == 25;
          expect(
            find.byKey(const ValueKey('unified-duel-optional-lesson')),
            visible ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(const Key('learner-tree-connector')),
            findsNWidgets(visible ? 2 : 1),
            reason: 'The unavailable Duel must not leave its 24px connector.',
          );
          expect(find.textContaining('suitable exercises'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test(
    'Use GuideBook suppresses only the empty rule and restores canonical red',
    () {
      // Keep this branch free of the independent ROUND_CONTENT_LONG Warning.
      final enabled = _course(emptyGuidebook: true, count: 3);
      final disabled = _preferences(enabled, useGuidebook: false);
      final audit = CourseAuditService();
      final before = audit.auditCourse(enabled).issues;
      final after = audit.auditCourse(disabled).issues;
      expect(
        before
            .where((issue) => issue.severity != AuditSeverity.info)
            .map((issue) => issue.code),
        ['LESSON_GUIDEBOOK_EMPTY'],
      );
      expect(
        before.any((issue) => issue.code == 'LESSON_GUIDEBOOK_EMPTY'),
        isTrue,
      );
      expect(
        after.map((issue) => '${issue.code}|${issue.location}'),
        before
            .where((issue) => issue.code != 'LESSON_GUIDEBOOK_EMPTY')
            .map((issue) => '${issue.code}|${issue.location}'),
      );
      final enabledStatus = AuthoringHierarchyStatus.fromCourse(enabled);
      final disabledStatus = AuthoringHierarchyStatus.fromCourse(disabled);
      expect(
        enabledStatus.lessonHasAuditConcern(enabled.lessons.single),
        isTrue,
      );
      expect(enabledStatus.hasLessonsAuditConcern, isTrue);
      expect(
        disabledStatus.lessonHasAuditConcern(disabled.lessons.single),
        isFalse,
      );
      expect(disabledStatus.hasLessonsAuditConcern, isFalse);
      final restored = _preferences(disabled, useGuidebook: true);
      expect(
        AuthoringHierarchyStatus.fromCourse(restored).hasLessonsAuditConcern,
        isTrue,
      );
    },
  );

  test(
    'disabled GuideBook preserves malformed source findings and Draft state',
    () {
      final enabled = _course(malformedGuidebook: true, draftGuidebook: true);
      final disabled = _preferences(enabled, useGuidebook: false);
      final findings = CourseAuditService().auditCourse(disabled).issues;
      expect(
        findings.any((issue) => issue.code == 'SOURCE_REF_MISSING'),
        isTrue,
      );
      final status = AuthoringHierarchyStatus.fromCourse(disabled);
      expect(
        status.lessonGuidebookHasAuditConcern(disabled.lessons.single),
        isTrue,
      );
      expect(status.lessonGuidebookHasDraft(disabled.lessons.single), isTrue);
      expect(status.hasLessonsAuditConcern, isTrue);
      expect(disabled.lessons.single.toJson(), enabled.lessons.single.toJson());
    },
  );

  testWidgets('Lessons toggle immediately recomputes canonical red and green', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final course = _course(emptyGuidebook: true, count: 3);
    Course? adopted;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonManagementScreen(
          course: course,
          initiallyLocked: false,
          onCourseChanged: (value) => adopted = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final indicator = find.byWidgetPredicate(
      (widget) =>
          widget is AuthoringStatusCard &&
          widget.indicatorKey ==
              const ValueKey('lesson-status-indicator-optional-lesson'),
    );
    expect(
      tester.widget<AuthoringStatusCard>(indicator).hasAuditConcern,
      isTrue,
    );
    final toggle = find.byKey(const Key('course-use-guidebook'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(adopted!.useGuidebook, isFalse);
    expect(
      tester.widget<AuthoringStatusCard>(indicator).hasAuditConcern,
      isFalse,
    );
    expect(
      AuthoringHierarchyStatus.fromCourse(adopted!).hasLessonsAuditConcern,
      isFalse,
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(adopted!.useGuidebook, isTrue);
    expect(
      tester.widget<AuthoringStatusCard>(indicator).hasAuditConcern,
      isTrue,
    );
    expect(
      AuthoringHierarchyStatus.fromCourse(adopted!).hasLessonsAuditConcern,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'GuideBook toggle refreshes the still-mounted Course Lessons link in both directions',
    (tester) async {
      final course = _course(emptyGuidebook: true, count: 3);
      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
      );
      await tester.pumpAndSettle();
      final ancestor = find.byWidgetPredicate(
        (widget) =>
            widget is AuthoringStatusCard &&
            widget.indicatorKey == const Key('course-lessons-status-indicator'),
        skipOffstage: false,
      );
      expect(
        tester.widget<AuthoringStatusCard>(ancestor).hasAuditConcern,
        isTrue,
      );
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson-management-lock')));
      await tester.pumpAndSettle();
      final toggle = find.byKey(const Key('course-use-guidebook'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        tester.widget<AuthoringStatusCard>(ancestor).hasAuditConcern,
        isFalse,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        tester.widget<AuthoringStatusCard>(ancestor).hasAuditConcern,
        isTrue,
      );
      expect(await CourseEditorService().listUserCourses(), isEmpty);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'disabled GuideBook keeps identity and icon geometry in $brightness',
      (tester) async {
        final course = _course(createDuels: false);
        final title = find.byKey(
          const ValueKey('unified-guidebook-lesson-title-optional-lesson'),
        );
        final action = find.byKey(
          const ValueKey('unified-guidebook-action-optional-lesson'),
        );
        await _openHome(tester, course, brightness: brightness);
        final titleRect = tester.getRect(title);
        final actionRect = tester.getRect(action);
        final iconColor = _renderedBookColor(tester, action);
        expect(find.byTooltip('GuideBook'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await _openHome(
          tester,
          _preferences(course, useGuidebook: false),
          brightness: brightness,
        );
        expect(tester.getRect(title), titleRect);
        expect(tester.getRect(action), actionRect);
        expect(_renderedBookColor(tester, action), iconColor);
        expect(find.byTooltip('GuideBook'), findsNothing);
        expect(
          find.descendant(of: action, matching: find.byType(Icon)),
          findsOneWidget,
        );
        _expectPassiveBook(tester, action);
        final node = find.ancestor(of: title, matching: find.byType(InkWell));
        expect(tester.widget<InkWell>(node).onTap, isNull);
        expect(tester.widget<InkWell>(node).excludeFromSemantics, isTrue);
        await tester.tap(title);
        await _pumpFrames(tester);
        expect(find.byType(GuidebookScreen), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    for (final state in ['Draft', 'locked']) {
      testWidgets(
        'disabled GuideBook preserves $state icon tint in $brightness',
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            final source = _course(
              createDuels: false,
              count: 1,
              draftGuidebook: state == 'Draft',
            );
            final course = state == 'locked'
                ? Course.fromJson({
                    ...source.toJson(),
                    'lessons': [
                      Lesson(
                        lessonId: 'preceding-uncompleted-lesson',
                        title: 'Preceding Lesson',
                        rounds: const [],
                      ).toJson(),
                      source.lessons.single.toJson(),
                    ],
                  })
                : source;
            final action = find.byKey(
              const ValueKey('unified-guidebook-action-optional-lesson'),
            );
            await _openHome(tester, course, brightness: brightness);
            await tester.ensureVisible(action);
            await _pumpFrames(tester);
            expect(tester.widget<IconButton>(action).onPressed, isNull);
            final rect = tester.getRect(action);
            final color = _renderedBookColor(tester, action);
            expect(color, isNotNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await _openHome(
              tester,
              _preferences(course, useGuidebook: false),
              brightness: brightness,
            );
            await tester.ensureVisible(action);
            await _pumpFrames(tester);
            expect(tester.getRect(action), rect);
            expect(_renderedBookColor(tester, action), color);
            expect(find.byTooltip('GuideBook'), findsNothing);
            expect(find.bySemanticsLabel('GuideBook'), findsNothing);
            _expectPassiveBook(tester, action);
            await tester.tap(action, warnIfMissed: false);
            await _pumpFrames(tester);
            expect(find.byType(GuidebookScreen), findsNothing);
            expect(tester.takeException(), isNull);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  for (final preview in [false, true]) {
    for (final enabled in [false, true]) {
      testWidgets('Round intro GuideBook enabled=$enabled Preview=$preview', (
        tester,
      ) async {
        final course = _course(useGuidebook: enabled, count: 1);
        await tester.pumpWidget(
          MaterialApp(
            home: RoundScreen(
              course: course,
              lesson: course.lessons.single,
              round: course.lessons.single.rounds.single,
              ttsLanguage: course.ttsLanguage,
              roundIndex: 0,
              previewMode: preview,
            ),
          ),
        );
        await _pumpFrames(tester);
        expect(find.text('Optional paths introduction.'), findsOneWidget);
        expect(
          find.text('Open Guidebook'),
          enabled ? findsOneWidget : findsNothing,
        );
        expect(find.text('Continue to Round'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'disabling and reenabling optional paths preserves earned progress',
    (tester) async {
      final course = _course();
      final progress = ProgressService();
      await progress.completeRound(
        'optional-round',
        courseId: course.courseId,
        courseCode: 'IT',
      );
      await progress.winDuel(
        'optional-lesson',
        courseId: course.courseId,
        courseCode: 'IT',
      );
      final prefs = await SharedPreferences.getInstance();
      final snapshot = {
        for (final key in prefs.getKeys()) key: jsonEncode(prefs.get(key)),
      };
      await _openHome(
        tester,
        _preferences(course, createDuels: false, useGuidebook: false),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await _openHome(tester, course);
      expect(await progress.getCompletedRounds(courseId: course.courseId), {
        'optional-round',
      });
      expect(await progress.getWonDuels(courseId: course.courseId), {
        'optional-lesson',
      });
      for (final entry in snapshot.entries.where(
        (entry) =>
            entry.key.contains('xp') ||
            entry.key.contains('completed') ||
            entry.key.contains('won_duels'),
      )) {
        expect(
          jsonEncode(prefs.get(entry.key)),
          entry.value,
          reason: entry.key,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}

Color? _renderedBookColor(WidgetTester tester, Finder action) {
  final icon = find.descendant(of: action, matching: find.byType(Icon));
  final text = find.descendant(of: icon, matching: find.byType(RichText));
  return tester.widget<RichText>(text).text.style?.color;
}

void _expectPassiveBook(WidgetTester tester, Finder action) {
  expect(
    tester
        .widget<IgnorePointer>(
          find.ancestor(of: action, matching: find.byType(IgnorePointer)).first,
        )
        .ignoring,
    isTrue,
  );
  expect(
    tester
        .widget<ExcludeFocus>(
          find.ancestor(of: action, matching: find.byType(ExcludeFocus)).first,
        )
        .excluding,
    isTrue,
  );
  expect(
    tester
        .widget<ExcludeSemantics>(
          find
              .ancestor(of: action, matching: find.byType(ExcludeSemantics))
              .first,
        )
        .excluding,
    isTrue,
  );
}

Course _preferences(Course course, {bool? createDuels, bool? useGuidebook}) =>
    Course.fromJson({
      ...course.toJson(),
      if (createDuels != null) 'createDuels': createDuels,
      if (useGuidebook != null) 'useGuidebook': useGuidebook,
    });

Future<void> _openHome(
  WidgetTester tester,
  Course course, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await CourseEditorService().saveUserCourse(course);
  await SettingsService().setLastSelectedCourseCode(
    'custom:${course.courseId}',
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: const HomeScreen(),
    ),
  );
  await _pumpFrames(tester);
  if (find.text('Alpha expiry').evaluate().isNotEmpty) {
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await _pumpFrames(tester);
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Course _course({
  bool createDuels = true,
  bool useGuidebook = true,
  int count = 25,
  bool emptyGuidebook = false,
  bool malformedGuidebook = false,
  bool draftGuidebook = false,
}) => Course(
  courseId: 'optional-paths',
  title: 'Optional learning paths',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  version: '1',
  createDuels: createDuels,
  useGuidebook: useGuidebook,
  lessons: [
    Lesson(
      lessonId: 'optional-lesson',
      title: 'Optional paths Lesson',
      guidebook: Guidebook(
        publicationState: draftGuidebook
            ? PublicationState.draft
            : PublicationState.published,
        content: emptyGuidebook
            ? []
            : [
                LearningContent(
                  id: 'optional-guide-content',
                  kind: 'explanation',
                  role: 'overview',
                  text: 'Learner-facing explanation.',
                  sourceRefs: malformedGuidebook
                      ? const ['missing-source']
                      : const [],
                ),
              ],
      ),
      rounds: [
        LearningRound(
          id: 'optional-round',
          title: 'Optional paths Round',
          content: [
            const LearningContent(
              id: 'optional-intro',
              kind: 'explanation',
              role: 'lesson_intro',
              text: 'Optional paths introduction.',
            ),
            for (var index = 0; index < count; index++)
              LearningContent.fromExercise(
                Exercise(
                  id: 'optional-exercise-$index',
                  type: 'choice',
                  editorTemplate: 'choice',
                  prompt: 'Choose the matching answer.',
                  question: 'Question $index',
                  answers: ['Answer $index', 'Another answer $index'],
                  correct: 0,
                  tts: null,
                  accepted: const [],
                  tokens: const [],
                  orderAnswer: const [],
                  pairs: const [],
                  hint: '',
                  icons: const [],
                ),
              ),
          ],
        ),
      ],
    ),
  ],
);
