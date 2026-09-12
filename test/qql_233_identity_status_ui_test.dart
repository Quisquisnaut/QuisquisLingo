import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/team_manager_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_governance_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:quisquislingo_app/widgets/learner_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

const aliceId = '11111111-1111-4111-8111-111111111111';
const bobId = '22222222-2222-4222-8222-222222222222';
const charlieId = '33333333-3333-4333-8333-333333333333';
const teamId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

Course assignedCourse() => Course(
  courseId: 'course-qql-233-ui',
  creatorProfileId: aliceId,
  ownership: const CourseOwnership.individual(bobId),
  assignedTeamId: teamId,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Assigned Course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  lessons: const [],
);

Future<({ProfileService profiles, TeamService teams})> setUpPeople() async {
  final profiles = ProfileService();
  await profiles.createProfile(
    'Alice',
    learnerProfileId: aliceId,
    discordHandle: 'alice_creator',
  );
  await profiles.createProfile(
    'Bob',
    learnerProfileId: bobId,
    discordHandle: '@bob_owner',
  );
  await profiles.createProfile('Charlie', learnerProfileId: charlieId);
  final teams = TeamService(
    profileService: profiles,
    idGenerator: () => teamId,
    clock: () => DateTime.utc(2026, 9, 12),
  );
  await teams.createTeam(
    creatorProfileId: aliceId,
    displayName: 'Independent Team',
  );
  await teams.addMember(
    teamId: teamId,
    actorProfileId: aliceId,
    memberProfileId: charlieId,
  );
  await profiles.setActiveProfileById(bobId);
  return (profiles: profiles, teams: teams);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  test('Learner status composition is mounted only by the Learner Panel', () {
    final mountingScreens = Directory('lib/screens')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) {
          final source = file.readAsStringSync();
          return source.contains('LearnerStatusPage(') ||
              source.contains('LearnerStatusAppBar(');
        })
        .map((file) => file.path.replaceAll('\\', '/'))
        .toList(growable: false);
    expect(mountingScreens, ['lib/screens/home_screen.dart']);
  });

  testWidgets(
    'Course Info separates identities, uses Discord presentation, and obeys ID display',
    (tester) async {
      final people = await setUpPeople();
      await tester.pumpWidget(
        MaterialApp(
          home: CourseInfoScreen(
            course: assignedCourse(),
            profileService: people.profiles,
            teamService: people.teams,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Course Owner: @bob_owner'), findsOneWidget);
      expect(find.text('Course Creator: @alice_creator'), findsOneWidget);
      expect(find.text('Assigned Team: Independent Team'), findsOneWidget);
      expect(find.text('Team Leaders: @alice_creator'), findsOneWidget);
      expect(find.text('Team Members: Charlie'), findsOneWidget);
      expect(
        find.textContaining('Course Owner: Independent Team'),
        findsNothing,
      );
      expect(find.textContaining(aliceId), findsNothing);
      expect(find.textContaining(bobId), findsNothing);
      expect(find.textContaining(charlieId), findsNothing);
      expect(find.textContaining(teamId), findsNothing);

      EditorDisplayPreferences.showInternalIds.value = true;
      await tester.pump();
      expect(find.textContaining(aliceId), findsWidgets);
      expect(find.textContaining(bobId), findsOneWidget);
      expect(find.textContaining(charlieId), findsOneWidget);
      expect(find.textContaining(teamId), findsOneWidget);
    },
  );

  testWidgets('Course Info mounts no Learner status-bar composition', (
    tester,
  ) async {
    final people = await setUpPeople();
    await tester.pumpWidget(
      MaterialApp(
        home: CourseInfoScreen(
          course: assignedCourse(),
          profileService: people.profiles,
          teamService: people.teams,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LearnerStatusPage), findsNothing);
    expect(find.byType(LearnerStatusAppBar), findsNothing);
    expect(find.byKey(const Key('learner-status-position')), findsNothing);
  });

  testWidgets(
    'Course Owner sees individual transfer and Team assignment controls with warning',
    (tester) async {
      await setUpPeople();
      final course = assignedCourse();
      await SettingsService().setCourseEditorMode(
        course.courseId,
        CourseEditorMode.edit,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: course,
            access: CourseAccessPolicy.evaluate(course, profileId: bobId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-editor-course-info')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('course-info-owner')), findsOneWidget);
      expect(
        find.byKey(const Key('course-info-assigned-team')),
        findsOneWidget,
      );
      expect(find.text('@alice_creator'), findsWidgets);
      expect(find.text('@bob_owner'), findsWidgets);
      expect(find.text('Independent Team'), findsWidgets);

      // First revoke the current assignment, then assign it again so the
      // confirmation boundary is exercised.
      await tester.ensureVisible(
        find.byKey(const Key('course-info-assigned-team')),
      );
      await tester.tap(find.byKey(const Key('course-info-assigned-team')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No assigned Team').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('course-info-assigned-team')),
      );
      await tester.tap(find.byKey(const Key('course-info-assigned-team')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Independent Team').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('team-assignment-warning')), findsOneWidget);
      expect(
        find.text(CourseGovernanceService.teamAssignmentWarning),
        findsOneWidget,
      );
      expect(find.byKey(const Key('team-assignment-cancel')), findsOneWidget);
      expect(find.byKey(const Key('team-assignment-confirm')), findsOneWidget);
      expect(find.byType(LearnerStatusPage), findsNothing);
      expect(find.byType(LearnerStatusAppBar), findsNothing);

      await tester.tap(find.byKey(const Key('team-assignment-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('No assigned Team'), findsOneWidget);

      await tester.tap(find.byKey(const Key('course-info-assigned-team')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Independent Team').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('team-assignment-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Independent Team'), findsOneWidget);
    },
  );

  testWidgets('assigned Team member gets no owner governance controls', (
    tester,
  ) async {
    await setUpPeople();
    final profiles = ProfileService();
    await profiles.setActiveProfileById(charlieId);
    final course = assignedCourse();
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
            profileId: charlieId,
            memberTeamIds: {teamId},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-editor-course-info')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-info-owner')), findsNothing);
    expect(find.byKey(const Key('course-info-assigned-team')), findsNothing);
    expect(
      find.text('Only the current Course Owner may change this field.'),
      findsOneWidget,
    );
    expect(
      find.text('Only the current Course Owner may assign or revoke a Team.'),
      findsOneWidget,
    );
  });

  testWidgets('Team Manager presents Discord identity and experimental Help', (
    tester,
  ) async {
    final people = await setUpPeople();
    await people.profiles.setActiveProfileById(aliceId);
    await tester.pumpWidget(
      MaterialApp(
        home: TeamManagerScreen(
          profileService: people.profiles,
          teamService: people.teams,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Independent Team'));
    await tester.pumpAndSettle();
    expect(find.text('@alice_creator'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);

    await tester.tap(find.byKey(const Key('team-model-help')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('experimental-team-help')), findsOneWidget);
    expect(
      find.textContaining('experimental QQL collaboration'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Course is always owned by an individual'),
      findsOneWidget,
    );
    expect(find.textContaining('copyright ownership'), findsOneWidget);
    expect(find.byType(LearnerStatusPage), findsNothing);
  });
}
