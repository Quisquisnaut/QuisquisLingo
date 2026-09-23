import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quisquislingo_app/services/xp_service.dart';
import 'package:quisquislingo_app/services/learning_activity_service.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/courses_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'support/publisher_fixtures.dart';
import 'support/pump_file_io.dart';

const alice = '11111111-1111-4111-8111-111111111111';
const bob = '22222222-2222-4222-8222-222222222222';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final profiles = ProfileService();
  final library = CourseLibraryService();
  late Course publisher;
  late CourseEditorService editor;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await profiles.createProfile(
      'Alice',
      learnerProfileId: alice,
      generateScreenNameSuffix: false,
    );
    await profiles.createProfile(
      'Bob',
      learnerProfileId: bob,
      generateScreenNameSuffix: false,
    );
    await profiles.setActiveProfileById(alice);
    publisher = Course.fromJson(
      jsonDecode(
            await File(
              'test/fixtures/publishers/dummy-signed-v1.json',
            ).readAsString(),
          )
          as Map<String, dynamic>,
    );
    editor = CourseEditorService(
      publisherVerification: fixtureVerifier(
        publisher.publisherId,
        publisher.publisherName,
      ),
    );
  });

  test(
    'import adds only importer; removal and reset are profile scoped; retired visibility flags are ignored',
    () async {
      await editor.installExternalOfficialUpdate(publisher);
      expect(await library.contains(publisher), isTrue);
      expect(await library.contains(publisher, profileId: bob), isFalse);
      final prefs = await SharedPreferences.getInstance();
      final suffix = 'v4_completed_rounds_course_${publisher.courseId}';
      final aliceKey = profiles.keyForProfileId(alice, suffix);
      final bobKey = profiles.keyForProfileId(bob, suffix);
      await prefs.setStringList(aliceKey, ['a']);
      await prefs.setStringList(bobKey, ['b']);
      final xp = XpService(now: () => DateTime(2026, 9, 20));
      final activity = LearningActivityService(
        now: () => DateTime(2026, 9, 20),
      );
      await xp.addXp(125, courseCode: 'IT', courseId: publisher.courseId);
      await activity.registerLearningActivity(courseCode: 'IT');
      final weeklyBreakdownKey = profiles.keyForProfileId(
        alice,
        'week_xp_by_course',
      );
      final weeklyBreakdown = prefs.getString(weeklyBreakdownKey);
      await (await SharedPreferences.getInstance()).setBool(
        profiles.keyForProfileId(
          (await profiles.getActiveProfileId())!,
          'course_hidden_${publisher.courseId}',
        ),
        true,
      );
      expect(await library.contains(publisher), isTrue);
      await library.remove(publisher);
      expect(await library.contains(publisher), isFalse);
      expect(prefs.getStringList(aliceKey), ['a']);
      expect(
        (await editor.listUserCourses()).single.courseId,
        publisher.courseId,
      );
      await library.add(publisher);
      expect(prefs.getStringList(aliceKey), ['a']);
      await library.remove(publisher, resetProgress: true);
      expect(prefs.containsKey(aliceKey), isFalse);
      expect(await xp.getXp(courseCode: 'IT'), 125);
      expect(await xp.getWeeklyXp(), 125);
      expect(prefs.getString(weeklyBreakdownKey), weeklyBreakdown);
      expect(await activity.getTotalStudyDays(), 1);
      expect(await activity.getDaysStudied(courseCode: 'IT'), 1);
      expect(await activity.getStreak(courseCode: 'IT'), 1);
      expect(prefs.getStringList(bobKey), ['b']);
      expect(await library.contains(publisher, profileId: bob), isTrue);
    },
  );

  test(
    'physical removal requires active admin and no other member including members with retired visibility flags',
    () async {
      await editor.installExternalOfficialUpdate(publisher);
      await profiles.setActiveProfileById(bob);
      await library.add(publisher);
      await expectLater(
        editor.removePublisherCourseFromDevice(publisher),
        throwsStateError,
      );
      await (await SharedPreferences.getInstance()).setBool(
        profiles.keyForProfileId(
          (await profiles.getActiveProfileId())!,
          'course_hidden_${publisher.courseId}',
        ),
        true,
      );
      await profiles.setActiveProfileById(alice);
      await expectLater(
        editor.removePublisherCourseFromDevice(publisher),
        throwsStateError,
      );
      expect(await editor.listUserCourses(), hasLength(1));
      await profiles.setActiveProfileById(bob);
      await library.remove(publisher);
      await profiles.setActiveProfileById(alice);
      await editor.removePublisherCourseFromDevice(publisher);
      expect(await editor.listUserCourses(), isEmpty);
      await editor.installExternalOfficialUpdate(publisher);
      expect(await library.contains(publisher), isTrue);
      expect(await library.contains(publisher, profileId: bob), isFalse);
      await expectLater(
        editor.removePublisherCourseFromDevice(
          await CourseService().loadCourse('IT'),
        ),
        throwsStateError,
      );
    },
  );

  testWidgets('empty library keeps Settings and opens All Courses', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await SettingsService().completeWelcomeWizard();
      await SettingsService().markOneTimeNoticeSeen(
        'welcome_${AppMetadata.technicalVersion}',
      );
      for (final code in CourseService.courseAssets.keys) {
        await library.remove(await CourseService().loadCourse(code));
      }
    });
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpUntilFileIoState(
      () => find
          .text('No courses available for study in your library.')
          .evaluate()
          .isNotEmpty,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    if (find.text('Beta expiry').evaluate().isNotEmpty) {
      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
    }
    expect(find.byTooltip('Learner profiles'), findsNothing);
    expect(find.byKey(const Key('empty-library-course-manager')), findsNothing);
    expect(
      find.byKey(const Key('unified-topbar-course-selector')),
      findsNothing,
    );
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpUntilFileIoState(
      () => find.text('Audio Settings').evaluate().isNotEmpty,
    );
    await SettingsService().setCourseEditorUnlocked(true);
    await tester.tap(find.text('Audio Settings'));
    await tester.pumpUntilFileIoState(
      () => find.text('Test Voice').evaluate().isNotEmpty,
    );
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Test Voice'))
          .onTap,
      isNull,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpUntilFileIoState(
      () => find.text('Learner profiles').evaluate().isNotEmpty,
    );
    await tester.scrollUntilVisible(find.text('User Data'), 250);
    await tester.tap(find.text('User Data'));
    await tester.pumpUntilFileIoState(
      () => find.text('Export my data').evaluate().isNotEmpty,
    );
    await tester.scrollUntilVisible(
      find.text('Reset current course progress'),
      250,
    );
    expect(
      tester
          .widget<ListTile>(
            find.widgetWithText(ListTile, 'Reset current course progress'),
          )
          .onTap,
      isNull,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpUntilFileIoState(
      () => find.text('All Courses').evaluate().isNotEmpty,
    );
    await tester.tap(find.byKey(const Key('empty-library-course-manager')));
    await tester.pumpUntilFileIoState(
      () => find
          .descendant(
            of: find.byKey(const ValueKey('manager-section-2')),
            matching: find.text('No courses in this section.'),
          )
          .evaluate()
          .isNotEmpty,
    );
    expect(
      tester.widget<CoursesScreen>(find.byType(CoursesScreen)).initialTab,
      CoursesTab.manager,
    );
    expect(find.textContaining('Bundled Courses ·'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpUntilFileIoState(
      () => find.text('All Courses').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('All Courses'));
    await tester.pumpUntilFileIoState(
      () => find.text('Bundled Courses').evaluate().isNotEmpty,
    );
    expect(
      tester.widget<CoursesScreen>(find.byType(CoursesScreen)).initialTab,
      CoursesTab.allCourses,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-course-sample_it_en_it')),
      250,
    );
    expect(
      find.byKey(const ValueKey('add-course-sample_it_en_it')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Manager removal hides only this profile and does not delete shared source',
    (tester) async {
      late Course bundled;
      await tester.runAsync(() async {
        await editor.installExternalOfficialUpdate(publisher);
        await profiles.setActiveProfileById(bob);
        await library.add(publisher);
        await profiles.setActiveProfileById(alice);
        bundled = await CourseService().loadCourse('IT');
      });
      await tester.pumpWidget(
        MaterialApp(
          home: CourseProjectsScreen(
            currentCourse: bundled,
            editorService: editor,
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.text('Bundled Courses').evaluate().isNotEmpty,
      );
      final action = find.byKey(
        ValueKey('course-manager-actions-${publisher.courseId}'),
      );
      await tester.scrollUntilVisible(action, 400);
      await tester.tap(action);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Remove Publisher Course from device'), findsOneWidget);
      await tester.tap(find.text('Remove from my courses'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse,
      );
      await tester.tap(
        find.widgetWithText(FilledButton, 'Remove from my courses'),
      );
      await tester.pumpUntilFileIoState(
        () =>
            find.byType(AlertDialog).evaluate().isEmpty &&
            find.text('Bundled Courses').evaluate().isNotEmpty,
      );
      await tester.scrollUntilVisible(find.text('No local courses yet.'), 400);
      expect(await tester.runAsync(editor.listUserCourses), hasLength(1));
      expect(await tester.runAsync(() => library.contains(publisher)), isFalse);
      expect(
        await tester.runAsync(
          () => library.contains(publisher, profileId: bob),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'adding another creator custom course never grants authoring rights',
    () async {
      final custom = Course(
        courseId: 'alice-custom',
        title: 'Alice custom',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        ttsLanguage: 'it-IT',
        lessons: const [],
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: alice,
          displayName: 'Alice',
        ),
        maintainer: const CourseMaintainer(alice),
        originalCreatedAtUtc: '2026-09-20T00:00:00.000Z',
      );
      await editor.saveUserCourse(custom);
      await profiles.setActiveProfileById(bob);
      expect(await library.contains(custom), isFalse);
      await library.add(custom);
      expect(await library.contains(custom), isTrue);
      expect(
        (await CourseAccessPolicy().forCurrentProfile(custom)).canEditOriginal,
        isFalse,
      );
      await library.remove(custom);
      expect(await library.contains(custom, profileId: alice), isTrue);
      expect(await editor.listUserCourses(), hasLength(1));
    },
  );

  testWidgets(
    'device page has four sections, adds another profile course and has Help',
    (tester) async {
      await tester.runAsync(() async {
        await editor.installExternalOfficialUpdate(publisher);
        await profiles.setActiveProfileById(bob);
      });
      await tester.pumpWidget(
        MaterialApp(home: AvailableCoursesScreen(editorService: editor)),
      );
      await tester.pumpUntilFileIoState(
        () => find.text('Bundled Courses').evaluate().isNotEmpty,
      );
      final bundled = find.byKey(const ValueKey('course-section-0'));
      final visibleTitles = tester
          .widgetList<Text>(
            find.descendant(of: bundled, matching: _courseTitles),
          )
          .map((title) => title.data!)
          .toList();
      expect(visibleTitles, isNotEmpty);
      final sortedTitles = [...visibleTitles]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(visibleTitles, sortedTitles);
      final rows = find.descendant(of: bundled, matching: _courseRows);
      expect(
        rows.evaluate().every(
          (row) => find
              .descendant(
                of: find.byWidget(row.widget),
                matching: find.textContaining('Maintainer: '),
              )
              .evaluate()
              .isNotEmpty,
        ),
        isTrue,
      );
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('add-course-${publisher.courseId}')),
        350,
      );
      await tester.ensureVisible(
        find.byKey(ValueKey('add-course-${publisher.courseId}')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('add-course-${publisher.courseId}')),
      );
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(ValueKey('add-course-${publisher.courseId}'))
            .evaluate()
            .isEmpty,
      );
      expect(await tester.runAsync(() => library.contains(publisher)), isTrue);
      expect(
        find.textContaining('Maintainer: ${publisher.publisherName}'),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(ValueKey('remove-course-${publisher.courseId}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Remove from my courses'),
      );
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(ValueKey('add-course-${publisher.courseId}'))
            .evaluate()
            .isNotEmpty,
      );
      expect(await tester.runAsync(() => library.contains(publisher)), isFalse);
      await tester.scrollUntilVisible(find.text('Other Local Courses'), 250);
      expect(find.text('My Local Courses'), findsOneWidget);
      expect(find.text('Other Local Courses'), findsOneWidget);
      await tester.tap(find.byTooltip('Help'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text(availableCoursesHelp), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'course titles and blocking states use their colors at 320 px in $brightness',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final blocked = Course.fromJson({
          ...publisher.toJson(),
          'publicationState': 'draft',
          'publisherVerificationStatus': 'unverified',
        });
        final custom = Course(
          courseId: 'custom-colors',
          title: 'Custom color check',
          sourceLanguage: 'English',
          targetLanguage: 'Italian',
          learningLanguage: 'Italian',
          interfaceLanguage: 'English',
          ttsLanguage: 'it-IT',
          lessons: const [],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: AvailableCoursesScreen(
              editorService: _DeviceCourses([blocked, custom]),
            ),
          ),
        );
        await tester.pumpUntilFileIoState(
          () => find.text('Bundled Courses').evaluate().isNotEmpty,
        );
        expect(find.text(blocked.title), findsNothing);
        await tester.tap(find.byKey(const Key('show-unavailable-courses')));
        await tester.pump();
        final bundledTitle = tester.widgetList<Text>(_courseTitles).first;
        expect(bundledTitle.style?.fontWeight, FontWeight.bold);
        expect(
          bundledTitle.style?.color,
          brightness == Brightness.dark ? Colors.white : Colors.black,
        );
        if (brightness == Brightness.dark) {
          expect(bundledTitle.style?.backgroundColor, Colors.black);
        }
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('device-course-${blocked.courseId}')),
          300,
        );
        final publisherTitle = tester.widget<Text>(find.text(blocked.title));
        expect(publisherTitle.style?.fontWeight, FontWeight.bold);
        expect(publisherTitle.style?.color, Colors.purple);
        for (final label in ['Unpublished', 'Verification required']) {
          final badge = find
              .ancestor(
                of: find.text(label),
                matching: find.byType(DecoratedBox),
              )
              .first;
          final decoration =
              tester.widget<DecoratedBox>(badge).decoration as BoxDecoration;
          expect(
            (decoration.border! as Border).top.color,
            brightness == Brightness.dark
                ? Colors.blue.shade300
                : Colors.blue.shade700,
          );
        }
        await tester.scrollUntilVisible(find.text(custom.title), 300);
        final customTitle = tester.widget<Text>(find.text(custom.title));
        expect(customTitle.style?.fontWeight, FontWeight.bold);
        expect(customTitle.style?.color, Colors.orange);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _DeviceCourses extends CourseEditorService {
  final List<Course> courses;
  _DeviceCourses(this.courses);
  @override
  Future<List<Course>> listUserCourses() async => courses;
}

Finder _keyedWith(String prefix) => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(prefix),
);

final _courseTitles = _keyedWith('device-course-title-');
final _courseRows = find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      RegExp(
        r'^device-course-(?!title-)',
      ).hasMatch((widget.key! as ValueKey<String>).value),
);
