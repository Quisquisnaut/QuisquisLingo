import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:quisquislingo_app/main.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/lesson_unlock_service.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/learning_completion_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/learner_bottom_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('227.01 control enums preserve exact labels, values, and cycles', () {
    expect(
      LearnerThemeMode.values
          .map((mode) => (mode.name, mode.storageValue, mode.label))
          .toList(),
      const [
        ('defaultMode', 'default', 'Default'),
        ('light', 'light', 'Light'),
        ('dark', 'dark', 'Dark'),
      ],
    );
    expect(LearnerThemeMode.values.map((mode) => mode.next).toList(), const [
      LearnerThemeMode.light,
      LearnerThemeMode.dark,
      LearnerThemeMode.defaultMode,
    ]);
    expect(LearnerThemeMode.fromStorage(null), LearnerThemeMode.defaultMode);
    expect(
      LearnerThemeMode.fromStorage('legacy-or-unknown'),
      LearnerThemeMode.defaultMode,
    );

    expect(
      LearnerFlagBackgroundMode.values
          .map((mode) => (mode.name, mode.storageValue, mode.label))
          .toList(),
      const [
        ('small', 'small', 'Small'),
        ('off', 'off', 'Off'),
        ('extended', 'extended', 'Extended'),
        ('tinted', 'tinted', 'Tinted'),
        ('softInspired', 'soft_inspired', 'Inspired'),
      ],
    );
    expect(
      LearnerFlagBackgroundMode.values.map((mode) => mode.next).toList(),
      const [
        LearnerFlagBackgroundMode.off,
        LearnerFlagBackgroundMode.extended,
        LearnerFlagBackgroundMode.tinted,
        LearnerFlagBackgroundMode.softInspired,
        LearnerFlagBackgroundMode.small,
      ],
    );
    expect(
      LearnerFlagBackgroundMode.fromStorage(null),
      LearnerFlagBackgroundMode.off,
    );
    expect(
      LearnerFlagBackgroundMode.fromStorage('legacy-or-unknown'),
      LearnerFlagBackgroundMode.off,
    );
  });

  test(
    '227.01 Theme is per learner, course-independent, persistent, and defaults to Default',
    () async {
      final profiles = ProfileService();
      final settings = SettingsService();
      await profiles.addProfile('Alice');
      final aliceId = (await profiles.getActiveProfileId())!;
      expect(await profiles.getThemeMode(), LearnerThemeMode.defaultMode);

      await settings.setLastSelectedCourseCode('course-a');
      await profiles.setThemeMode(LearnerThemeMode.dark);
      await settings.setLastSelectedCourseCode('course-b');
      expect(await profiles.getThemeMode(), LearnerThemeMode.dark);

      await profiles.addProfile('Bob');
      expect(await profiles.getThemeMode(), LearnerThemeMode.defaultMode);
      await profiles.setThemeMode(LearnerThemeMode.light);

      final restarted = ProfileService();
      await restarted.setActiveProfileById(aliceId);
      expect(await restarted.getThemeMode(), LearnerThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        profiles.keyForProfileId(aliceId, 'theme_mode'),
        'unknown',
      );
      expect(await restarted.getThemeMode(), LearnerThemeMode.defaultMode);
    },
  );

  test(
    '227.01 Flag Background is clean-cut per learner and exact course ID',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Alice');
      final aliceId = (await profiles.getActiveProfileId())!;
      final prefs = await SharedPreferences.getInstance();
      final oldKey = profiles.keyForProfileId(aliceId, 'flag_background_mode');
      await prefs.setString(oldKey, 'extended');

      expect(
        await profiles.getFlagBackgroundMode('Course/A'),
        LearnerFlagBackgroundMode.off,
      );
      await profiles.setFlagBackgroundMode(
        ' Course/A ',
        LearnerFlagBackgroundMode.small,
      );
      await profiles.setFlagBackgroundMode(
        'course-b',
        LearnerFlagBackgroundMode.extended,
      );
      expect(
        await profiles.getFlagBackgroundMode('Course/A'),
        LearnerFlagBackgroundMode.small,
      );
      expect(
        await profiles.getFlagBackgroundMode('course/a'),
        LearnerFlagBackgroundMode.off,
      );
      expect(
        await profiles.getFlagBackgroundMode('course-b'),
        LearnerFlagBackgroundMode.extended,
      );

      await profiles.addProfile('Bob');
      expect(
        await profiles.getFlagBackgroundMode('Course/A'),
        LearnerFlagBackgroundMode.off,
      );
      await profiles.setFlagBackgroundMode(
        'Course/A',
        LearnerFlagBackgroundMode.extended,
      );

      final restarted = ProfileService();
      await restarted.setActiveProfileById(aliceId);
      expect(
        await restarted.getFlagBackgroundMode('Course/A'),
        LearnerFlagBackgroundMode.small,
      );
      expect(prefs.getString(oldKey), 'extended');
      expect(
        prefs.getString(
          profiles.keyForProfileId(
            aliceId,
            'flag_background_mode_course_${sha256.convert(utf8.encode('Course/A'))}',
          ),
        ),
        'small',
      );

      await prefs.setString(
        profiles.keyForProfileId(
          aliceId,
          'flag_background_mode_course_${sha256.convert(utf8.encode('corrupt-course'))}',
        ),
        'unknown',
      );
      expect(
        await restarted.getFlagBackgroundMode('corrupt-course'),
        LearnerFlagBackgroundMode.off,
      );
    },
  );

  test(
    '227.01 Flag Background survives backup decode and separate-copy restore',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Backup source');
      final courseId =
          '${List.filled(12, 'course/with:unsafe?characters.').join()}END';
      await profiles.setFlagBackgroundMode(
        courseId,
        LearnerFlagBackgroundMode.extended,
      );
      final backup = LearnerBackupService(profileService: profiles);

      final exported = await backup.exportActiveProfile();
      final document = backup.decodeDocument(utf8.encode(jsonEncode(exported)));
      final storedFlagEntries = document.data.entries
          .where(
            (entry) => entry.key.startsWith('flag_background_mode_course_'),
          )
          .toList();
      expect(storedFlagEntries, hasLength(1));
      expect(storedFlagEntries.single.key, hasLength(92));
      expect(storedFlagEntries.single.key, matches(r'^[A-Za-z0-9_.:-]+$'));
      expect(storedFlagEntries.single.value, 'extended');

      await backup.importAsSeparateCopy(document, displayName: 'Backup copy');
      expect(
        await profiles.getFlagBackgroundMode(courseId),
        LearnerFlagBackgroundMode.extended,
      );
    },
  );

  test(
    '227.01 IDDQD is Off by default and persists independently per learner and course',
    () async {
      final profiles = ProfileService();
      final settings = SettingsService();
      await profiles.addProfile('Alice');
      final aliceId = (await profiles.getActiveProfileId())!;
      expect(await settings.isIddqdModeEnabled('Course/A'), isFalse);
      await settings.setIddqdModeEnabled(' Course/A ', true);
      expect(await settings.isIddqdModeEnabled('Course/A'), isTrue);
      expect(await settings.isIddqdModeEnabled('course/a'), isFalse);
      expect(await settings.isIddqdModeEnabled('course-b'), isFalse);

      await profiles.addProfile('Bob');
      expect(await settings.isIddqdModeEnabled('Course/A'), isFalse);
      await settings.setIddqdModeEnabled('Course/A', true);

      final restarted = SettingsService();
      await profiles.setActiveProfileById(aliceId);
      expect(await restarted.isIddqdModeEnabled('Course/A'), isTrue);
      expect(await restarted.isIddqdModeEnabled('course-b'), isFalse);
    },
  );

  test(
    '227.01 IDDQD keeps real completion, XP, activity, Laurel, and unlock semantics',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Progress Learner');
      final settings = SettingsService();
      final progress = ProgressService(now: () => DateTime(2026, 9, 7, 12));
      final course = _twoLessonCourse();
      final unlocks = const LessonUnlockService();

      expect(
        unlocks.isLessonUnlocked(
          lessonIndex: 1,
          course: course,
          completedLessons: const <String>{},
          wonDuels: const <String>{},
        ),
        isFalse,
      );
      await settings.setIddqdModeEnabled(course.courseId, true);
      expect(await settings.isIddqdModeEnabled(course.courseId), isTrue);
      expect(
        await progress.getCompletedRounds(courseId: course.courseId),
        isEmpty,
      );
      expect(
        await progress.getCompletedLessons(courseId: course.courseId),
        isEmpty,
      );
      expect(await progress.getXp(courseCode: 'IT'), 0);
      expect(await progress.getWeeklyXp(), 0);
      expect(
        unlocks.isLessonUnlocked(
          lessonIndex: 1,
          course: course,
          completedLessons: const <String>{},
          wonDuels: const <String>{},
        ),
        isFalse,
      );

      final result = await LearningCompletionService(progressService: progress)
          .completeRound(
            LearningCompletionRequest(
              roundId: 'round-1',
              lessonId: 'lesson-1',
              courseId: course.courseId,
              courseCode: 'IT',
              completedLessonId: 'lesson-1',
              readAttemptFacts: () => const LearningCompletionAttemptFacts(
                errorsThisAttempt: 0,
                firstPassCorrect: 1,
                evaluableExerciseCount: 1,
                wasCompletedAtStart: false,
                ttsWasSkipped: false,
              ),
            ),
            onNewLaurel: () async {},
            getWeeklyXpTarget: () async => 1000,
          );
      await settings.setIddqdModeEnabled(course.courseId, false);

      final completedLessons = await progress.getCompletedLessons(
        courseId: course.courseId,
      );
      expect(await settings.isIddqdModeEnabled(course.courseId), isFalse);
      expect(result.awardedXp, 60);
      expect(await progress.getCompletedRounds(courseId: course.courseId), {
        'round-1',
      });
      expect(completedLessons, {'lesson-1'});
      expect(await progress.getPerfectRounds(courseId: course.courseId), {
        'round-1',
      });
      expect(await progress.getXp(courseCode: 'IT'), 60);
      expect(await progress.getWeeklyXp(), 60);
      expect(await progress.getDaysStudied(courseCode: 'IT'), 1);
      expect(await progress.getStreak(courseCode: 'IT'), 1);
      expect(
        unlocks.isLessonUnlocked(
          lessonIndex: 1,
          course: course,
          completedLessons: completedLessons,
          wonDuels: await progress.getWonDuels(courseId: course.courseId),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    '227.01 Default theme follows live platform brightness while staying system mode',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(dispatcher.clearPlatformBrightnessTestValue);
      final profiles = ProfileService();
      await profiles.addProfile('System Theme Learner');

      await tester.pumpWidget(
        QuisquisLingoApp(
          profileService: profiles,
          home: const Scaffold(
            body: Center(child: SizedBox(key: Key('theme-brightness-probe'))),
          ),
        ),
      );
      await _pumpFrames(tester);

      ThemeData activeTheme() => Theme.of(
        tester.element(find.byKey(const Key('theme-brightness-probe'))),
      );
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(activeTheme().brightness, Brightness.light);

      dispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(activeTheme().brightness, Brightness.dark);

      dispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      expect(activeTheme().brightness, Brightness.light);
    },
  );

  testWidgets(
    '227.01 Theme and Flag controls do not mutate progress, XP, streak, or Laurels',
    (tester) async {
      final profiles = ProfileService();
      await profiles.addProfile('Visual Learner');
      final progress = ProgressService(now: () => DateTime(2026, 9, 7, 12));
      const courseId = 'visual-course';
      await progress.completeRound(
        'round-1',
        courseId: courseId,
        courseCode: 'IT',
      );
      await progress.markPerfectRound('round-1', courseId: courseId);
      await progress.completeLesson(
        'lesson-1',
        courseId: courseId,
        courseCode: 'IT',
      );
      final before = await _progressSnapshot(progress, courseId);
      final prefs = await SharedPreferences.getInstance();
      final learnerId = (await profiles.getActiveProfileId())!;
      final themeKey = profiles.keyForProfileId(learnerId, 'theme_mode');
      final flagKey = profiles.keyForProfileId(
        learnerId,
        'flag_background_mode_course_${sha256.convert(utf8.encode(courseId))}',
      );
      Map<String, Object?> nonVisualStorage() => {
        for (final key in prefs.getKeys())
          if (key != themeKey && key != flagKey) key: prefs.get(key),
      };
      final storedBefore = nonVisualStorage();

      await tester.pumpWidget(
        QuisquisLingoApp(
          profileService: profiles,
          home: Scaffold(
            body: LearnerBottomActions(
              profileService: profiles,
              courseId: courseId,
              onProfile: () {},
              onReview: () {},
              onCourseInfo: () {},
            ),
          ),
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('learner-bottom-theme')));
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('learner-bottom-flag-background')));
      await _pumpFrames(tester);

      expect(await _progressSnapshot(progress, courseId), before);
      expect(nonVisualStorage(), storedBefore);
    },
  );

  testWidgets(
    '227.01 flag backdrop fallbacks preserve missing and invalid behavior',
    (tester) async {
      await tester.pumpWidget(
        _flagApp(
          _flagCourse(flagCode: '', flagImageBase64: 'not-base64'),
          fallbackCode: 'DE',
        ),
      );
      final fallbackPainter = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CourseFlagBackdrop),
          matching: find.byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.painter is FlagPainter,
          ),
        ),
      );
      expect((fallbackPainter.painter! as FlagPainter).code, 'DE');
      expect(tester.takeException(), isNull);

      const missingWorldFlagId = 'missing-world-flag-id';
      final emptyManifest = jsonEncode({
        'schemaVersion': 1,
        'entities': const <Object>[],
      });
      await tester.pumpWidget(
        _flagApp(
          _flagCourse(flagCode: 'IT', worldFlagId: missingWorldFlagId),
          fallbackCode: 'DE',
          bundle: _StringAssetBundle(emptyManifest),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey(
            'course-world-flag-backdrop-unavailable-$missingWorldFlagId',
          ),
        ),
        findsOneWidget,
      );
      expect(find.byType(FlagBackdrop), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<Map<String, Object>> _progressSnapshot(
  ProgressService progress,
  String courseId,
) async => {
  'completedRounds': await progress.getCompletedRounds(courseId: courseId),
  'completedLessons': await progress.getCompletedLessons(courseId: courseId),
  'perfectRounds': await progress.getPerfectRounds(courseId: courseId),
  'wonDuels': await progress.getWonDuels(courseId: courseId),
  'xp': await progress.getXp(courseCode: 'IT'),
  'weeklyXp': await progress.getWeeklyXp(),
  'daysStudied': await progress.getDaysStudied(courseCode: 'IT'),
  'streak': await progress.getStreak(courseCode: 'IT'),
};

Course _twoLessonCourse() => Course(
  courseId: 'iddqd-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'IDDQD course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  lessons: [
    Lesson(lessonId: 'lesson-1', title: 'First', rounds: const []),
    Lesson(lessonId: 'lesson-2', title: 'Second', rounds: const []),
  ],
);

Course _flagCourse({
  required String flagCode,
  String flagImageBase64 = '',
  String worldFlagId = '',
}) => Course(
  courseId: 'flag-course',
  learningLanguage: 'Test language',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Test language',
  title: 'Flag course',
  ttsLanguage: 'en-US',
  version: '1.0.0',
  flagCode: flagCode,
  flagImageBase64: flagImageBase64,
  worldFlagId: worldFlagId,
  lessons: const [],
);

Widget _flagApp(
  Course course, {
  required String fallbackCode,
  AssetBundle? bundle,
}) => MaterialApp(
  home: Scaffold(
    body: CourseFlagBackdrop(
      course: course,
      fallbackCode: fallbackCode,
      opacity: 1,
      worldFlagRepository: bundle == null
          ? null
          : WorldFlagRepository(bundle: bundle),
    ),
  ),
);

class _StringAssetBundle extends CachingAssetBundle {
  final String manifest;

  _StringAssetBundle(this.manifest);

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(manifest)));

  @override
  Future<String> loadString(String key, {bool cache = true}) async => manifest;
}
