import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/services/app_reset_service.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/course_privacy.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 259 Revision 8 (owner decisions of 1 October 2026): a custom Course
/// whose `temporarySample` flag is on is a Private course, visible in QQL
/// only to its Maintainer and assigned Team (admins included in the rule).
/// Someone else's Private course is neither imported nor merged; Fork and
/// Copy as New Course start non-private; removing non-admin learners is
/// refused while one of them maintains a Course, and the reset confirmations
/// count the Private courses the admin cannot see.

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _carol = '44444444-4444-4444-8444-444444444444';
final _when = DateTime.utc(2026, 10, 1, 10);

Course _course(
  String id, {
  required String maintainer,
  bool private = false,
  String? team,
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: 'Author',
  ),
  maintainer: CourseMaintainer(maintainer),
  assignedTeamId: team,
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  courseVersion: '1',
  derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
  temporarySample: private,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course $id',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      updatedAt: DateTime.utc(2026, 9, 20),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profiles = ProfileService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Alice is created first, so she is the device admin.
    for (final (id, name) in [
      (_alice, 'Alice'),
      (_bob, 'Bob'),
      (_carol, 'Carol'),
    ]) {
      await profiles.createProfile(
        name,
        learnerProfileId: id,
        generateScreenNameSuffix: false,
      );
    }
    await profiles.setActiveProfileById(_alice);
  });

  Future<T> asProfile<T>(String id, Future<T> Function() body) async {
    await profiles.setActiveProfileById(id);
    try {
      return await body();
    } finally {
      await profiles.setActiveProfileById(_alice);
    }
  }

  test('only a custom Course is ever private', () async {
    expect(
      CoursePrivacy.isPrivate(_course('c', maintainer: _bob, private: true)),
      isTrue,
    );
    expect(CoursePrivacy.isPrivate(_course('c', maintainer: _bob)), isFalse);
    final bundled = await CourseService().loadCourse('EN_IT');
    expect(bundled.temporarySample, isFalse);
    final flagged = Course.fromJson({
      ...bundled.toJson(),
      'temporarySample': true,
    });
    expect(CoursePrivacy.isPrivate(flagged), isFalse);
  });

  test('the Maintainer and the assigned Team see it; admins do not', () async {
    final teams = TeamService(profileService: profiles);
    final team = await teams.createTeam(
      creatorProfileId: _bob,
      displayName: 'Piedmont team',
    );
    await teams.addMember(
      teamId: team.teamId,
      actorProfileId: _bob,
      memberProfileId: _carol,
    );
    final course = _course(
      'private',
      maintainer: _bob,
      private: true,
      team: team.teamId,
    );
    final privacy = CoursePrivacy();
    expect(await privacy.isVisibleTo(course, _bob), isTrue);
    expect(await privacy.isVisibleTo(course, _carol), isTrue);
    expect(await privacy.isVisibleTo(course, _alice), isFalse);
    expect(await profiles.isAdmin(_alice), isTrue);

    final library = CourseLibraryService();
    // Alice's earlier choice to add it does not count.
    await library.add(course);
    expect(await library.contains(course), isFalse);
    expect(await library.contains(course, profileId: _bob), isTrue);
    await asProfile(_carol, () => library.add(course));
    expect(await library.contains(course, profileId: _carol), isTrue);
    expect(await library.included([course]), isEmpty);
    // Turned off, everyone may see it.
    final open = Course.fromJson({
      ...course.toJson(),
      'temporarySample': false,
    });
    expect(await library.contains(open), isTrue);
  });

  testWidgets('Course Info shows who can see a Private course', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseInfoScreen(
          course: _course('c', maintainer: _alice, private: true),
          profileService: profiles,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private course'), findsOneWidget);
    expect(
      find.textContaining('visible in QQL only to its Course Maintainer'),
      findsOneWidget,
    );
  });

  test('Fork and Copy as New Course start non-private', () {
    final duplication = AuthoringDuplicationService(clock: () => _when);
    final source = _course('source', maintainer: _bob, private: true);
    final copy = duplication.copyCourseAsNew(
      source,
      title: 'Copy',
      originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
        profileId: _bob,
        displayName: 'Bob',
      ),
      maintainer: const CourseMaintainer(_bob),
    );
    expect(copy.temporarySample, isFalse);
  });

  group('import and Merge', () {
    late CourseEditorService editor;
    late CourseLibraryOperations ops;

    setUp(() {
      editor = CourseEditorService(clock: () => _when);
      ops = CourseLibraryOperations(
        editor: editor,
        transfer: CustomCourseTransferService(),
        clock: () => _when,
      );
    });

    Future<CourseImportReview> review(Course course) async {
      final library = await ops.load(importOnly: true);
      final attempt = CoursePackageImport(
        CoursePackage(course, Uint8List(0), const {}),
        editor: editor,
      );
      try {
        return await ops.reviewImport(attempt, library);
      } finally {
        await attempt.close();
      }
    }

    test("someone else's Private course is refused", () async {
      final theirs = _course('theirs', maintainer: _bob, private: true);
      await expectLater(
        review(theirs),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('is a Private course'),
          ),
        ),
      );
      // Its Maintainer imports it.
      final mine = await asProfile(_bob, () => review(theirs));
      expect(mine.course.courseId, 'theirs');
      // A course that is not private imports as before.
      expect(
        (await review(_course('open', maintainer: _bob))).course.courseId,
        'open',
      );
    });

    test("someone else's Private course is not merged", () async {
      final left = _course('left', maintainer: _alice);
      await editor.installImportedCustomCourse(left);
      final right = _course('left', maintainer: _bob, private: true);
      final library = await ops.load(importOnly: true);
      await expectLater(
        ops.composeMerge(
          left: left,
          right: right,
          choices: const [LessonMergeChoice.left],
          options: CourseMergeOptions(
            title: left.title,
            createDuels: left.createDuels,
            useGuidebook: left.useGuidebook,
            lessonNumberingMode: left.lessonNumberingMode,
            customLessonLabel: left.customLessonLabel,
            sectionNames: left.sectionNames,
            buyACoffeeUrl: left.buyACoffeeUrl,
            courseDescription: left.courseDescription,
            startLevel: left.startLevel,
            targetLevel: left.targetLevel,
            flagCode: left.flagCode,
            worldFlagId: left.worldFlagId,
            flagImageBase64: left.flagImageBase64,
          ),
          library: library,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('resets', () {
    late Directory support;
    late Directory documents;
    late CourseEditorService editor;
    late AppResetService reset;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('qql_private_259_');
      documents = await Directory.systemTemp.createTemp('qql_private_259_d_');
      editor = CourseEditorService(
        courseStore: CourseFileStore(supportDirectory: () async => support),
        clock: () => _when,
      );
      reset = AppResetService(
        profiles: profiles,
        documentsDirectory: () async => documents,
        supportDirectory: () async => support,
      );
      await editor.installImportedCustomCourse(
        _course('alice', maintainer: _alice),
      );
      await asProfile(
        _bob,
        () => editor.installImportedCustomCourse(
          _course('bob', maintainer: _bob, private: true),
        ),
      );
      // Last: once Alice has a PIN, switching back to her asks for it.
      await profiles.setOwnAccessPin(actorProfileId: _alice, pin: '4321');
    });

    tearDown(() async {
      for (final directory in [support, documents]) {
        if (await directory.exists()) await directory.delete(recursive: true);
      }
    });

    test('the preview counts and names without revealing a title', () async {
      final preview = await reset.preview();
      expect(preview.hiddenPrivateCourseCount, 1);
      expect(preview.coursesMaintainedByNonAdmins, ['a Private course']);
    });

    test('non-admin learners who maintain a Course are not removed', () async {
      await expectLater(
        reset.reset(
          AppResetScope.nonAdminLearners,
          actorProfileId: _alice,
          pin: '4321',
        ),
        throwsA(
          isA<AppResetException>().having(
            (error) => error.message,
            'message',
            contains('a Private course'),
          ),
        ),
      );
      expect(await profiles.getProfileById(_bob), isNotNull);
    });

    test('removing custom courses removes the Private ones too', () async {
      await reset.reset(
        AppResetScope.customCourses,
        actorProfileId: _alice,
        pin: '4321',
      );
      expect(await editor.listUserCourses(), isEmpty);
    });
  });
}
