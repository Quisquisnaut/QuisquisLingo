import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/team_manager_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _leadId = '11111111-1111-4111-8111-111111111111';
const _memberId = '22222222-2222-4222-8222-222222222222';
const _otherMemberId = '33333333-3333-4333-8333-333333333333';
const _teamId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('QQL 233 release metadata uses Phase and revision terminology', () {
    expect(AppMetadata.technicalVersion, '2.0.33+233030');
    expect(AppMetadata.build, '233.3');
    expect(AppMetadata.displayLabel, 'Version 2.0.33\nBuild 233.1');
  });

  testWidgets(
    'ordinary current member can cancel and then confirm Leave Team',
    (tester) async {
      final profiles = await _profiles(activeId: _memberId);
      final teams = await _team(profiles);

      await tester.pumpWidget(
        MaterialApp(
          home: TeamManagerScreen(profileService: profiles, teamService: teams),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revision Three Team'));
      await tester.pumpAndSettle();

      final menu = find.byKey(const ValueKey('team-member-actions-$_memberId'));
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      expect(find.text('Leave Team'), findsOneWidget);
      await tester.tap(find.text('Leave Team'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Team?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect((await teams.teamById(_teamId))!.hasMember(_memberId), isTrue);

      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave Team'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('leave-team-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('You do not belong to a Team yet.'), findsOneWidget);
      final remaining = (await teams.teamById(_teamId))!;
      expect(remaining.hasMember(_memberId), isFalse);
      expect(remaining.hasMember(_leadId), isTrue);
      expect(remaining.hasMember(_otherMemberId), isTrue);
      expect(remaining.leadProfileIds, [_leadId]);
    },
  );

  test(
    'leaving removes Team authorization without changing course or other Team data',
    () async {
      final profiles = await _profiles(activeId: _memberId);
      final teams = await _team(profiles);
      final policy = CourseAccessPolicy(
        profileService: profiles,
        teamService: teams,
      );
      final course = _customCourse(ownerId: _teamId);
      final courseBefore = jsonEncode(course.toJson());

      expect((await policy.forCurrentProfile(course)).canEditOriginal, isTrue);
      await teams.leaveTeam(teamId: _teamId);
      final after = await policy.forCurrentProfile(course);
      expect(after.canEditOriginal, isFalse);
      expect(after.canDuplicate, isFalse);
      expect(jsonEncode(course.toJson()), courseBefore);

      final team = (await teams.teamById(_teamId))!;
      expect(team.displayName, 'Revision Three Team');
      expect(team.hasMember(_leadId), isTrue);
      expect(team.hasMember(_otherMemberId), isTrue);
      await profiles.setActiveProfileById(_otherMemberId);
      expect((await policy.forCurrentProfile(course)).canEditOriginal, isTrue);
    },
  );

  test('a Team Leader cannot use self-service leave', () async {
    final profiles = await _profiles(activeId: _leadId);
    final teams = await _team(profiles);
    await expectLater(
      teams.leaveTeam(teamId: _teamId),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Team Leader'),
        ),
      ),
    );
    final team = (await teams.teamById(_teamId))!;
    expect(team.hasLead(_leadId), isTrue);
    expect(team.leadProfileIds, [_leadId]);
  });

  testWidgets(
    'Temporary Sample appears in View Course Info but not the main Course Editor',
    (tester) async {
      final sample = _officialCourse(
        published: true,
        hasDraft: false,
        temporarySample: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: sample,
            access: CourseAccessPolicy.evaluate(sample, profileId: _memberId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TEMPORARY SAMPLE'), findsNothing);
      expect(find.textContaining('Replace sample material'), findsNothing);
      await tester.tap(find.text('Course Info'));
      await tester.pumpAndSettle();
      expect(find.text('Temporary Sample'), findsOneWidget);
      expect(
        find.textContaining('Replace sample material with reviewed content'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Temporary Sample metadata survives an unrelated editor save and export',
    (tester) async {
      await _profiles(activeId: _leadId);
      await SettingsService().markAudioOrphanCheckRun('IT');
      final course = _customCourse(temporarySample: true);
      await SettingsService().setCourseEditorMode(
        course.courseId,
        CourseEditorMode.edit,
      );
      final transfer = _RecordingTransferService();
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: course,
            access: CourseAccessPolicy.evaluate(course, profileId: _leadId),
            transferService: transfer,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('TEMPORARY SAMPLE'), findsNothing);

      await tester.tap(find.text('Course Info Editor'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('course-info-title')),
        'Renamed sample course',
      );
      final save = find.byKey(const Key('course-info-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final export = find.byKey(const Key('course-editor-export-json'));
      await tester.scrollUntilVisible(
        export,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(export);
      await tester.pumpAndSettle();

      expect(transfer.exported?.title, 'Renamed sample course');
      expect(transfer.exported?.temporarySample, isTrue);
      expect(transfer.exported?.toJson()['temporarySample'], isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: transfer.exported!,
            access: CourseAccessPolicy.evaluate(
              transfer.exported!,
              profileId: _leadId,
            ),
            transferService: transfer,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('TEMPORARY SAMPLE'), findsNothing);
    },
  );

  test('Temporary Sample is present in the actual exported JSON', () async {
    final directory = await Directory.systemTemp.createTemp('qql-2293-export-');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final course = Course.fromJson({
      ..._customCourse(temporarySample: true).toJson(),
      'title': 'Unrelated saved title',
    });
    final path = await CustomCourseTransferService(
      directory: () async => directory,
    ).exportCourse(course);
    final exported = jsonDecode(await File(path).readAsString()) as Map;
    expect(exported['title'], 'Unrelated saved title');
    expect(exported['temporarySample'], isTrue);
  });

  testWidgets('Course Manager shows all Draft and Unpublished combinations', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      for (final published in [true, false]) {
        for (final hasDraft in [false, true]) {
          final course = _officialCourse(
            published: published,
            hasDraft: hasDraft,
          );
          await _pumpManager(tester, course, brightness: brightness);
          expect(
            find.byKey(ValueKey('course-manager-draft-${course.courseId}')),
            hasDraft ? findsOneWidget : findsNothing,
          );
          expect(
            find.byKey(
              ValueKey('course-manager-unpublished-${course.courseId}'),
            ),
            published ? findsNothing : findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets(
    'Course Manager badges update independently and wrap on a narrow layout',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      var course = _officialCourse(published: true, hasDraft: false);
      await _pumpManager(tester, course, brightness: Brightness.dark);
      expect(find.text('Draft'), findsNothing);
      expect(find.text('Unpublished'), findsNothing);

      course = _officialCourse(published: true, hasDraft: true);
      await _pumpManager(tester, course, brightness: Brightness.dark);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Unpublished'), findsNothing);

      course = _officialCourse(published: false, hasDraft: false);
      await _pumpManager(tester, course, brightness: Brightness.dark);
      expect(find.text('Draft'), findsNothing);
      expect(find.text('Unpublished'), findsOneWidget);

      course = _officialCourse(published: false, hasDraft: true);
      await _pumpManager(tester, course, brightness: Brightness.dark);
      final draft = find.byKey(
        ValueKey('course-manager-draft-${course.courseId}'),
      );
      final unpublished = find.byKey(
        ValueKey('course-manager-unpublished-${course.courseId}'),
      );
      expect(draft, findsOneWidget);
      expect(unpublished, findsOneWidget);
      final draftPosition = tester.getTopLeft(draft);
      final unpublishedPosition = tester.getTopLeft(unpublished);
      expect(
        unpublishedPosition.dy > draftPosition.dy ||
            unpublishedPosition.dx > draftPosition.dx,
        isTrue,
      );
      expect(tester.getRect(draft).right, lessThanOrEqualTo(320));
      expect(tester.getRect(unpublished).right, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);
    },
  );
}

Future<ProfileService> _profiles({required String activeId}) async {
  final profiles = ProfileService();
  await profiles.createProfile('Alice', learnerProfileId: _leadId);
  await profiles.createProfile('Bob', learnerProfileId: _memberId);
  await profiles.createProfile('Charlie', learnerProfileId: _otherMemberId);
  await profiles.setActiveProfileById(activeId);
  return profiles;
}

Future<TeamService> _team(ProfileService profiles) async {
  final teams = TeamService(
    profileService: profiles,
    idGenerator: () => _teamId,
    clock: () => DateTime.utc(2026, 9, 10),
  );
  await teams.createTeam(
    creatorProfileId: _leadId,
    displayName: 'Revision Three Team',
  );
  await teams.addMember(
    teamId: _teamId,
    actorProfileId: _leadId,
    memberProfileId: _memberId,
  );
  await teams.addMember(
    teamId: _teamId,
    actorProfileId: _leadId,
    memberProfileId: _otherMemberId,
  );
  return teams;
}

Course _customCourse({
  String ownerId = _leadId,
  bool temporarySample = false,
}) => Course(
  courseId: 'revision-three-custom-course',
  creatorProfileId: _leadId,
  ownership: CourseOwnership.individual(ownerId == _teamId ? _leadId : ownerId),
  assignedTeamId: ownerId == _teamId ? _teamId : null,
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Revision three course',
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: '1.0.0',
  license: 'All rights reserved',
  derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
  temporarySample: temporarySample,
  lessons: [_lesson(hasDraft: false)],
);

Course _officialCourse({
  required bool published,
  required bool hasDraft,
  bool temporarySample = false,
}) => Course(
  courseId: 'revision-three-badge-course',
  originType: CourseOriginType.bundledOfficial,
  publisherId: 'org.quisquislingo',
  publisherName: 'QuisquisLingo',
  officialCourseVersion: '1.0.0',
  officialReleaseDateUtc: '2026-09-10T00:00:00.000Z',
  officialChecksum: List.filled(64, 'a').join(),
  distributionChannel: 'bundled',
  publisherVerificationStatus: PublisherVerificationStatus.verified,
  publicationState: published
      ? PublicationState.published
      : PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title:
      'A deliberately very long Course Manager title for narrow layout coverage',
  ttsLanguage: 'it-IT',
  version: '1',
  temporarySample: temporarySample,
  lessons: [_lesson(hasDraft: hasDraft)],
);

Lesson _lesson({required bool hasDraft}) => Lesson(
  lessonId: 'revision-three-lesson',
  title: 'Lesson',
  rounds: [
    LearningRound(
      id: 'revision-three-round',
      title: 'Round',
      publicationState: hasDraft
          ? PublicationState.draft
          : PublicationState.published,
      content: [LearningContent.fromExercise(_exercise())],
    ),
  ],
);

Exercise _exercise() => Exercise(
  id: 'revision-three-exercise',
  type: 'choice',
  prompt: 'Choose',
  question: 'Hello?',
  answers: const ['Ciao', 'Grazie'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Future<void> _pumpManager(
  WidgetTester tester,
  Course course, {
  required Brightness brightness,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: CourseProjectsScreen(currentCourse: course),
    ),
  );
  await tester.pumpAndSettle();
}

class _RecordingTransferService extends CustomCourseTransferService {
  Course? exported;

  @override
  Future<String> exportCourse(Course course) async {
    exported = course;
    return 'revision-three-export.json';
  }
}
