import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/team_manager_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/course_language_resolver.dart';
import 'package:quisquislingo_app/services/course_owner_resolver.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/flag_background_palette_service.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:quisquislingo_app/widgets/course_entry_animation.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _aliceId = '11111111-1111-4111-8111-111111111111';
const _bobId = '22222222-2222-4222-8222-222222222222';
const _charlieId = '33333333-3333-4333-8333-333333333333';
const _teamId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  tearDown(() {
    EditorDisplayPreferences.resetForTesting();
  });

  group('authoritative course-language resolution', () {
    for (final code in const ['it-IT', 'en-GB', 'en-US', 'it', 'en']) {
      test('custom course preserves $code', () {
        final language = code.startsWith('it') ? 'Italian' : 'English';
        final resolved = CourseLanguageResolver.learning(
          _course(learning: language, base: 'German', ttsLanguage: code),
        );
        expect(resolved.code, code);
        expect(resolved.displayLabel, '$language ($code)');
        expect(resolved.displayLabel, isNot(contains('und')));
      });
    }

    test('absent and malformed codes use the established general fallback', () {
      for (final invalid in const ['', 'und', 'not a code']) {
        final course = _course(
          learning: 'Italian',
          ttsLanguage: invalid,
          targetLanguageTag: invalid,
        );
        expect(CourseLanguageResolver.learning(course).code, 'it');
        expect(
          CourseLanguageResolver.learning(course).displayLabel,
          'Italian (it)',
        );
      }
    });

    test(
      'bundled and custom origins resolve equivalent metadata identically',
      () {
        final custom = _course(ttsLanguage: 'en-US', learning: 'English');
        final bundled = _course(
          ttsLanguage: 'en-US',
          learning: 'English',
          origin: CourseOriginType.bundledOfficial,
        );
        expect(
          CourseLanguageResolver.learning(custom).displayLabel,
          CourseLanguageResolver.learning(bundled).displayLabel,
        );
      },
    );
  });

  testWidgets(
    'Course Info shows language codes, resolved flag, live Team name and full years',
    (tester) async {
      final profiles = await _profiles();
      final teams = await _team(profiles);
      final course = _course(
        assignedTeamId: _teamId,
        ttsLanguage: 'it-IT',
        targetLanguageTag: 'it-IT',
        sourceLanguageTag: 'en-GB',
        createdAtUtc: '2024-01-02T10:00:00.000Z',
        modifiedAtUtc: '2026-09-09T11:00:00.000Z',
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: CourseInfoScreen(
            course: course,
            profileService: profiles,
            teamService: teams,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Learning language: Italian (it-IT)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Base language: English (en-GB)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Assigned Team: Revision Two Team'),
        findsOneWidget,
      );
      expect(find.byType(CourseFlagBadge), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Created:'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Created:'), findsOneWidget);
      expect(find.textContaining('2024'), findsOneWidget);
      expect(find.textContaining('Modified:'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await teams.renameTeam(
        teamId: _teamId,
        actorProfileId: _aliceId,
        displayName: 'Renamed Team',
      );
      final renamed = await CourseOwnerResolver(
        profileService: profiles,
        teamService: teams,
      ).resolve(course);
      expect(renamed.ownerLabel, 'Alice');
      expect(renamed.assignedTeamLabel, 'Renamed Team');
      expect(course.ownership!.id, _aliceId);
    },
  );

  testWidgets(
    'Course Info Editor shows Team/model IDs conditionally and saves Automatic or explicit flags',
    (tester) async {
      final profiles = await _profiles();
      await _team(profiles);
      final course = _course(
        assignedTeamId: _teamId,
        ttsLanguage: 'it-IT',
        targetLanguageTag: 'it-IT',
        sourceLanguageTag: 'en-GB',
        createdAtUtc: '2024-01-02T10:00:00.000Z',
        modifiedAtUtc: '2026-09-09T11:00:00.000Z',
      );
      await _pumpEditor(tester, course);
      await _openCourseInfoEditor(tester);

      expect(find.text('Revision Two Team'), findsWidgets);
      expect(find.textContaining(_teamId), findsNothing);
      expect(find.byKey(const Key('course-info-model-version')), findsNothing);
      expect(find.text('Italian (it-IT)'), findsOneWidget);
      expect(find.text('English (en-GB)'), findsOneWidget);
      expect(find.textContaining('2024'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);

      await _chooseDropdown(
        tester,
        const Key('course-info-flag-choice'),
        'Explicit flag',
      );
      await _chooseDropdown(
        tester,
        const Key('course-info-built-in-flag'),
        'Spain (ES)',
      );
      await _saveCourseInfo(tester);
      var working = _editorFlagCourse(tester);
      expect(working.flagCode, 'ES');
      expect(working.flagImageBase64, isEmpty);
      expect(working.worldFlagId, isEmpty);

      await _openCourseInfoEditor(tester);
      await _chooseDropdown(
        tester,
        const Key('course-info-flag-choice'),
        'Automatic',
      );
      await _saveCourseInfo(tester);
      working = _editorFlagCourse(tester);
      expect(working.flagCode, isEmpty);
      expect(working.flagImageBase64, isEmpty);
      expect(working.worldFlagId, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      SharedPreferences.setMockInitialValues({
        EditorDisplayPreferences.showInternalIdsKey: true,
      });
      EditorDisplayPreferences.resetForTesting();
      await _profiles();
      await _team(ProfileService());
      await _pumpEditor(tester, course);
      await _openCourseInfoEditor(tester);
      expect(find.textContaining('Team ID: $_teamId'), findsOneWidget);
      expect(
        find.text('Course Model: v${course.formatVersion}'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'read-only Course Info resolves a flag but exposes no flag editor',
    (tester) async {
      final official = _course(
        origin: CourseOriginType.bundledOfficial,
        flagCode: 'ES',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: official,
            access: CourseAccessPolicy.evaluate(official, profileId: _aliceId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-editor-audit')), findsNothing);
      expect(find.widgetWithText(TextButton, 'Run audit'), findsOneWidget);
      await tester.tap(find.text('Course Info'));
      await tester.pumpAndSettle();
      expect(find.byType(CourseFlagBadge), findsOneWidget);
      expect(find.byKey(const Key('course-info-flag-choice')), findsNothing);
      expect(find.byType(TextField), findsNothing);
    },
  );

  test(
    'one flag resolution is shared by badge, backdrop, palette and entry',
    () async {
      final course = _course(flagCode: 'ES', ttsLanguage: 'it-IT');
      final resolved = CourseFlagService.resolve(course, fallbackCode: 'IT');
      expect(resolved.identifier, 'ES');
      expect(resolved.isExplicit, isTrue);
      final entry = await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: 'other',
        destination: course,
        fallbackCode: 'IT',
        animationsEnabled: true,
        reducedMotion: false,
      );
      expect(entry!.identifier, resolved.identifier);
      final palette = await CourseFlagPaletteResolver().resolve(
        course,
        fallbackCode: 'IT',
        brightness: Brightness.light,
      );
      expect(palette.source, CourseFlagPaletteSource.builtIn);
    },
  );

  testWidgets('badge and backdrop use explicit precedence over automatic', (
    tester,
  ) async {
    final course = _course(flagCode: 'ES', ttsLanguage: 'it-IT');
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            CourseFlagBadge(course: course, fallbackCode: 'IT'),
            SizedBox(
              width: 100,
              height: 60,
              child: CourseFlagBackdrop(course: course, fallbackCode: 'IT'),
            ),
          ],
        ),
      ),
    );
    final badge = tester.widget<FlagBadge>(find.byType(FlagBadge).first);
    final backdrop = tester.widget<FlagBackdrop>(find.byType(FlagBackdrop));
    expect(badge.code, 'ES');
    expect(backdrop.code, 'ES');
  });

  testWidgets('Course Manager keeps only icon Import/Create controls', (
    tester,
  ) async {
    await _profiles();
    await tester.pumpWidget(
      MaterialApp(home: CourseProjectsScreen(currentCourse: _course())),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('course-import-icon-action')), findsOneWidget);
    expect(find.byKey(const Key('create-course-icon-action')), findsOneWidget);
    expect(find.byKey(const Key('course-import-entry')), findsNothing);
    expect(
      find.widgetWithText(FilledButton, 'Create new course'),
      findsNothing,
    );
    expect(find.byTooltip('Course Import'), findsOneWidget);
    expect(find.byTooltip('Create new course'), findsOneWidget);
  });

  testWidgets(
    'Team Manager toggles Team and every User ID without hiding names',
    (tester) async {
      final profiles = await _profiles();
      final teams = await _team(profiles);
      await tester.pumpWidget(
        MaterialApp(
          home: TeamManagerScreen(profileService: profiles, teamService: teams),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Revision Two Team'), findsOneWidget);
      expect(find.textContaining(_teamId), findsNothing);
      await tester.tap(find.byKey(const Key('editor-internal-ids-toggle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Team ID: $_teamId'), findsOneWidget);

      await tester.tap(find.text('Revision Two Team'));
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.textContaining('User ID: $_aliceId'), findsOneWidget);
      expect(find.textContaining('User ID: $_bobId'), findsOneWidget);
      expect(
        find.textContaining(
          'The final Team Leader cannot be demoted or removed',
        ),
        findsNothing,
      );
      expect(
        find.byTooltip('The Team must retain at least one Team Leader'),
        findsOneWidget,
      );
      await expectLater(
        teams.demoteLead(
          teamId: _teamId,
          actorProfileId: _aliceId,
          leadProfileId: _aliceId,
        ),
        throwsStateError,
      );

      await tester.tap(find.byKey(const Key('editor-internal-ids-toggle')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Team ID:'), findsNothing);
      expect(find.textContaining('User ID:'), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    },
  );

  test(
    'developer unlock is isolated, persistent, backed up and deleted per user',
    () async {
      SharedPreferences.setMockInitialValues({'course_editor_unlocked': true});
      final profiles = await _profiles();
      final settings = SettingsService();
      expect(await settings.isCourseEditorUnlocked(), isFalse);

      await settings.setCourseEditorUnlocked(true);
      expect(await SettingsService().isCourseEditorUnlocked(), isTrue);
      await profiles.setActiveProfileById(_bobId);
      expect(await settings.isCourseEditorUnlocked(), isFalse);
      await profiles.setActiveProfileById(_aliceId);
      expect(await settings.isCourseEditorUnlocked(), isTrue);

      await profiles.createProfile(
        'Charlie',
        learnerProfileId: _charlieId,
        generateScreenNameSuffix: false,
      );
      expect(await settings.isCourseEditorUnlocked(), isFalse);
      await profiles.setActiveProfileById(_aliceId);
      final backup = await LearnerBackupService(
        profileService: profiles,
      ).exportActiveProfile();
      expect(backup['data'], containsPair('course_editor_unlocked', true));
      final backupDocument = LearnerBackupDocument(
        schemaVersion: LearnerBackupService.schemaVersion,
        learnerProfileId: _aliceId,
        displayName: 'Alice',
        data: Map<String, Object>.from(backup['data']! as Map),
      );

      final aliceKey = profiles.keyForProfileId(
        _aliceId,
        'course_editor_unlocked',
      );
      expect((await SharedPreferences.getInstance()).getBool(aliceKey), isTrue);
      await profiles.promoteToAdmin(
        actorProfileId: _aliceId,
        targetProfileId: _bobId,
      );
      await profiles.deleteProfileById(_aliceId);
      expect(
        (await SharedPreferences.getInstance()).containsKey(aliceKey),
        isFalse,
      );
      expect(
        (await SharedPreferences.getInstance()).getBool(
          'course_editor_unlocked',
        ),
        isTrue,
      );
      await LearnerBackupService(
        profileService: profiles,
      ).restorePreservingIdentity(backupDocument);
      expect(await settings.isCourseEditorUnlocked(), isTrue);
    },
  );

  test(
    'developer unlock never grants ownership or Team authorization',
    () async {
      await _profiles();
      await SettingsService().setCourseEditorUnlocked(true);
      final outsiderCourse = _course(ownerId: _bobId);
      final access = CourseAccessPolicy.evaluate(
        outsiderCourse,
        profileId: _aliceId,
        memberTeamIds: const {},
      );
      expect(await SettingsService().isCourseEditorUnlocked(), isTrue);
      expect(access.canEditOriginal, isFalse);
      expect(access.canDuplicate, isFalse);
    },
  );
}

Future<ProfileService> _profiles() async {
  final profiles = ProfileService();
  await profiles.createProfile(
    'Alice',
    learnerProfileId: _aliceId,
    generateScreenNameSuffix: false,
  );
  await profiles.createProfile(
    'Bob',
    learnerProfileId: _bobId,
    generateScreenNameSuffix: false,
  );
  await profiles.setActiveProfileById(_aliceId);
  return profiles;
}

Future<TeamService> _team(ProfileService profiles) async {
  final teams = TeamService(
    profileService: profiles,
    idGenerator: () => _teamId,
    clock: () => DateTime.utc(2026, 9, 9),
  );
  await teams.createTeam(
    creatorProfileId: _aliceId,
    displayName: 'Revision Two Team',
  );
  await teams.addMember(
    teamId: _teamId,
    actorProfileId: _aliceId,
    memberProfileId: _bobId,
  );
  return teams;
}

Future<void> _pumpEditor(WidgetTester tester, Course course) async {
  await SettingsService().markAudioOrphanCheckRun('IT');
  await SettingsService().setCourseEditorMode(
    course.courseId,
    CourseEditorMode.edit,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: CourseEditorScreen(
        course: course,
        access: CourseAccessPolicy.evaluate(
          course,
          profileId: _aliceId,
          memberTeamIds: const {_teamId},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openCourseInfoEditor(WidgetTester tester) async {
  await tester.tap(find.text('Course Info Editor'));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
}

Future<void> _chooseDropdown(
  WidgetTester tester,
  Key key,
  String option,
) async {
  final dropdown = find.byKey(key);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _saveCourseInfo(WidgetTester tester) async {
  final save = find.byKey(const Key('course-info-save'));
  await tester.ensureVisible(save);
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Course _editorFlagCourse(WidgetTester tester) =>
    tester.widget<CourseFlagBadge>(find.byType(CourseFlagBadge).first).course;

Course _course({
  String learning = 'Italian',
  String base = 'English',
  String ttsLanguage = 'it-IT',
  String targetLanguageTag = '',
  String sourceLanguageTag = '',
  String ownerId = _aliceId,
  String? assignedTeamId,
  CourseOriginType origin = CourseOriginType.custom,
  String flagCode = '',
  String createdAtUtc = '',
  String modifiedAtUtc = '',
}) => Course(
  courseId: 'revision-two-${origin.name}-course',
  originType: origin,
  publisherId: origin.isOfficial ? 'org.quisquislingo' : '',
  publisherName: origin.isOfficial ? 'QuisquisLingo' : '',
  officialCourseVersion: origin.isOfficial ? '1.0.0' : '',
  officialReleaseDateUtc: origin.isOfficial ? '2026-09-09T00:00:00.000Z' : '',
  officialChecksum: origin.isOfficial ? List.filled(64, '0').join() : '',
  distributionChannel: origin.isOfficial ? 'bundled' : '',
  publisherVerificationStatus: origin.isOfficial
      ? PublisherVerificationStatus.verified
      : PublisherVerificationStatus.unverified,
  creatorProfileId: origin.isOfficial ? null : _aliceId,
  ownership: origin.isOfficial ? null : CourseOwnership.individual(ownerId),
  assignedTeamId: origin.isOfficial ? null : assignedTeamId,
  createdByProfileId: origin.isOfficial ? '' : _aliceId,
  createdByUsername: origin.isOfficial ? '' : 'Alice',
  createdAtUtc: createdAtUtc,
  lastModifiedByProfileId: origin.isOfficial ? '' : _aliceId,
  lastModifiedByUsername: origin.isOfficial ? '' : 'Alice',
  lastModifiedAtUtc: modifiedAtUtc,
  publicationState: PublicationState.draft,
  learningLanguage: learning,
  interfaceLanguage: base,
  sourceLanguage: base,
  targetLanguage: learning,
  sourceLanguageTag: sourceLanguageTag,
  targetLanguageTag: targetLanguageTag,
  title: 'Revision two course',
  ttsLanguage: ttsLanguage,
  version: '1',
  flagCode: flagCode,
  lessons: const [],
);
