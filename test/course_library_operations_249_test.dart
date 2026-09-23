import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';

/// Build 249: every Course Manager operation, reached without the screen.
/// `course_manager_workflow_249_test.dart` proves the screen still behaves
/// the same; this file proves the owner stands on its own.

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _team = '33333333-3333-4333-8333-333333333333';
final _when = DateTime.utc(2026, 9, 23, 10, 30);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final profiles = ProfileService();
  late Course publisher;
  late CourseEditorService editor;
  late CourseLibraryOperations ops;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // Alice is created first, so she is the device admin.
    await profiles.createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await profiles.createProfile(
      'Bob',
      learnerProfileId: _bob,
      generateScreenNameSuffix: false,
    );
    await profiles.setActiveProfileById(_alice);
    publisher = Course.fromJson(
      jsonDecode(
            await File(
              'test/fixtures/publishers/dummy-signed-v1.json',
            ).readAsString(),
          )
          as Map<String, dynamic>,
    );
    final verifier = fixtureVerifier(
      publisher.publisherId,
      publisher.publisherName,
    );
    editor = CourseEditorService(
      publisherVerification: verifier,
      clock: () => _when,
    );
    ops = CourseLibraryOperations(
      editor: editor,
      transfer: CustomCourseTransferService(publisherVerification: verifier),
      clock: () => _when,
    );
  });

  Future<void> asProfile(String id, Future<void> Function() body) async {
    await profiles.setActiveProfileById(id);
    try {
      await body();
    } finally {
      await profiles.setActiveProfileById(_alice);
    }
  }

  Future<List<Course>> stored() => editor.listUserCourses();

  group('load', () {
    test('lists only the personal library, with who is looking', () async {
      await editor.installImportedCustomCourse(_course('mine', title: 'Mine'));
      final theirs = _course('theirs', title: 'Theirs', maintainer: _bob);
      await asProfile(_bob, () => editor.installImportedCustomCourse(theirs));

      final library = await ops.load(importOnly: true);

      expect(library.personalCourses.map((c) => c.courseId), ['mine']);
      expect(library.bundledCourses, isEmpty);
      expect(library.activeProfileId, _alice);
      expect(library.isAdmin, isTrue);
      expect(library.importAuthoringEnabled, isFalse);
      expect(library.unreadable, isEmpty);

      await CourseLibraryService().add(theirs);
      expect(
        (await ops.load(
          importOnly: true,
        )).personalCourses.map((c) => c.courseId).toSet(),
        {'mine', 'theirs'},
      );
    });

    test('import-only authoring follows the Course Editor unlock', () async {
      expect((await ops.load()).importAuthoringEnabled, isTrue);
      await SettingsService().setCourseEditorUnlocked(true);
      expect((await ops.load(importOnly: true)).importAuthoringEnabled, isTrue);
    });

    test('lists the Bundled Courses, the current one as given', () async {
      final italian = await CourseService().loadCourse('IT');
      final current = Course.fromJson({
        ...italian.toJson(),
        'title': 'Current copy in memory',
      });

      final library = await ops.load(currentCourse: current);

      expect(
        library.bundledCourses,
        hasLength(CourseService.courseAssets.length),
      );
      expect(library.bundledCourses.first.title, 'Current copy in memory');
      expect(
        library.bundledCourses.where((c) => c.courseId == italian.courseId),
        hasLength(1),
      );
    });

    test('names an unreadable stored Course file and lists the rest', () async {
      await editor.installImportedCustomCourse(_course('mine', title: 'Mine'));
      final directory = await CourseFileStore().directoryFor(
        CourseStoreKind.custom,
        create: true,
      );
      await File('${directory.path}/broken.json').writeAsString('{');

      final library = await ops.load(importOnly: true);

      expect(library.personalCourses.map((c) => c.courseId), ['mine']);
      expect(library.unreadable.single.fileName, 'broken.json');
    });
  });

  group('which actions are offered', () {
    const admin = CourseManagerLibrary(activeProfileId: _alice, isAdmin: true);
    const notAdmin = CourseManagerLibrary(activeProfileId: _bob);

    test('a maintained Custom Course', () {
      expect(admin.actionsFor(_course('mine', title: 'Mine')), const [
        CourseManagerAction.removeFromMyCourses,
        CourseManagerAction.open,
        CourseManagerAction.copyAsNewCourse,
        CourseManagerAction.merge,
        CourseManagerAction.audit,
        CourseManagerAction.export,
        CourseManagerAction.delete,
      ]);
    });

    test('an assigned Team member gets the Maintainer\'s actions', () {
      final teamCourse = Course.fromJson({
        ..._course('team', title: 'Team', maintainer: _bob).toJson(),
        'assignedTeamId': _team,
      });
      const member = CourseManagerLibrary(
        activeProfileId: _alice,
        memberTeamIds: {_team},
      );
      expect(
        member.actionsFor(teamCourse),
        contains(CourseManagerAction.delete),
      );
      expect(
        admin.actionsFor(teamCourse),
        isNot(contains(CourseManagerAction.delete)),
      );
    });

    test('an outsider\'s Custom Course forks only when allowed', () {
      Course theirs(DerivativeWorksPolicy policy) => _course(
        'theirs',
        title: 'Theirs',
        maintainer: _bob,
        derivatives: policy,
      );
      expect(admin.actionsFor(theirs(DerivativeWorksPolicy.allowed)), const [
        CourseManagerAction.removeFromMyCourses,
        CourseManagerAction.open,
        CourseManagerAction.fork,
        CourseManagerAction.audit,
      ]);
      expect(admin.actionsFor(theirs(DerivativeWorksPolicy.forbidden)), const [
        CourseManagerAction.removeFromMyCourses,
        CourseManagerAction.open,
        CourseManagerAction.audit,
      ]);
    });

    test('a Publisher Course offers device removal to an admin only', () {
      final verified = Course.fromJson({
        ...publisher.toJson(),
        'publisherVerificationStatus': 'verified',
      });
      expect(admin.actionsFor(verified), const [
        CourseManagerAction.removeFromMyCourses,
        CourseManagerAction.removePublisherFromDevice,
        CourseManagerAction.open,
        CourseManagerAction.fork,
        CourseManagerAction.audit,
        CourseManagerAction.export,
      ]);
      expect(
        notAdmin.actionsFor(verified),
        isNot(contains(CourseManagerAction.removePublisherFromDevice)),
      );
    });

    test('a Bundled Course is read only and exportable', () async {
      final bundled = await CourseService().loadCourse('IT');
      expect(admin.actionsFor(bundled), const [
        CourseManagerAction.removeFromMyCourses,
        CourseManagerAction.open,
        CourseManagerAction.audit,
        CourseManagerAction.export,
      ]);
    });
  });

  group('greyed-out entries and their reasons (Revision 1)', () {
    const admin = CourseManagerLibrary(activeProfileId: _alice, isAdmin: true);
    const notAdmin = CourseManagerLibrary(activeProfileId: _bob);
    const nobody = CourseManagerLibrary();
    Map<CourseManagerAction, String?> reasons(
      CourseManagerLibrary library,
      Course course,
    ) => {
      for (final entry in library.entriesFor(course))
        entry.action: entry.unavailableReason,
    };

    test('a maintained Custom Course greys out only Fork', () {
      final shown = reasons(admin, _course('mine', title: 'Mine'));
      expect(shown.keys, const [
        CourseManagerAction.removeFromMyCourses,
        CourseManagerAction.open,
        CourseManagerAction.fork,
        CourseManagerAction.copyAsNewCourse,
        CourseManagerAction.merge,
        CourseManagerAction.audit,
        CourseManagerAction.export,
        CourseManagerAction.delete,
      ]);
      expect(
        shown[CourseManagerAction.fork],
        'You maintain this Course: use Copy as New Course instead.',
      );
      expect(shown.entries.where((e) => e.value != null).map((e) => e.key), [
        CourseManagerAction.fork,
      ]);
    });

    test('an outsider sees every authoring entry with its reason', () {
      final shown = reasons(
        admin,
        _course(
          'theirs',
          title: 'Theirs',
          maintainer: _bob,
          derivatives: DerivativeWorksPolicy.forbidden,
        ),
      );
      expect(
        shown[CourseManagerAction.fork],
        'The license does not allow derivative works.',
      );
      for (final (action, verb) in const [
        (CourseManagerAction.copyAsNewCourse, 'copy'),
        (CourseManagerAction.merge, 'merge'),
        (CourseManagerAction.export, 'export'),
        (CourseManagerAction.delete, 'delete'),
      ]) {
        expect(
          shown[action],
          'Only the Maintainer or assigned Team can $verb this Course.',
        );
      }
      expect(shown[CourseManagerAction.open], isNull);
      expect(shown[CourseManagerAction.audit], isNull);
    });

    test('official Courses hide what can never apply', () async {
      final bundled = await CourseService().loadCourse('IT');
      final shown = reasons(admin, bundled);
      expect(shown.keys, const [
        CourseManagerAction.removeFromMyCourses,
        CourseManagerAction.open,
        CourseManagerAction.fork,
        CourseManagerAction.audit,
        CourseManagerAction.export,
      ]);
      expect(
        shown[CourseManagerAction.fork],
        'The license does not allow derivative works.',
      );
    });

    test('Publisher removal needs an admin; Fork needs verification', () {
      final unverified = Course.fromJson({
        ...publisher.toJson(),
        'publisherVerificationStatus': 'unverified',
      });
      expect(
        reasons(
          notAdmin,
          unverified,
        )[CourseManagerAction.removePublisherFromDevice],
        'Only an admin can remove a Publisher Course from this device.',
      );
      expect(
        reasons(
          admin,
          unverified,
        )[CourseManagerAction.removePublisherFromDevice],
        isNull,
      );
      expect(
        reasons(admin, unverified)[CourseManagerAction.fork],
        'The Publisher Course must be verified first.',
      );
    });

    test('without a learner profile, Fork asks for one', () {
      expect(
        reasons(
          nobody,
          _course(
            'theirs',
            title: 'Theirs',
            maintainer: _bob,
            derivatives: DerivativeWorksPolicy.allowed,
          ),
        )[CourseManagerAction.fork],
        'Select a learner profile first.',
      );
    });

    test('actionsFor keeps only the usable entries', () {
      final course = _course('mine', title: 'Mine');
      expect(admin.actionsFor(course), [
        for (final entry in admin.entriesFor(course))
          if (entry.available) entry.action,
      ]);
    });
  });

  group('titles', () {
    final library = CourseManagerLibrary(
      personalCourses: [
        _course('a', title: 'Mine'),
        _course('b', title: 'Mine copy'),
        _course('c', title: 'Mine merged'),
      ],
    );

    test('copies and merges count past the listed titles', () {
      expect(library.nextCopyTitle('Mine'), 'Mine copy 2');
      expect(library.nextCopyTitle('Other'), 'Other copy');
      expect(library.nextMergeTitle('Mine merged'), 'Mine merged 2');
      expect(library.nextMergeTitle('Other merged'), 'Other merged');
    });

    test('the New Course warning compares names as the policy does', () {
      expect(library.hasCourseTitled('Mine'), isTrue);
      expect(library.hasCourseTitled('Yours'), isFalse);
      expect(library.personalCourse('b')?.title, 'Mine copy');
      expect(library.personalCourse('zzz'), isNull);
    });
  });

  group('Copy as New Course and Fork', () {
    test('Copy stores a titled independent Course', () async {
      final mine = _course('mine', title: 'Mine');
      await editor.installImportedCustomCourse(mine);
      final library = await ops.load(importOnly: true);

      final result = await ops.copyAsNewCourse(mine, library);

      expect(result.course.title, 'Mine copy');
      expect(result.course.courseId, isNot('mine'));
      expect(result.course.forkProvenance, isNull);
      expect((await stored()).map((c) => c.title).toSet(), {
        'Mine',
        'Mine copy',
      });
    });

    test('Fork of a Publisher Course uses the stored signed source', () async {
      await editor.installExternalOfficialUpdate(publisher);
      final listed = (await stored()).single;

      final result = await ops.fork(listed);

      expect(result.course.forkProvenance?.sourceCourseId, publisher.courseId);
      expect(result.course.maintainer?.profileId, _alice);
    });

    test('Fork of an official Course is refused without its source', () async {
      await expectLater(
        ops.fork(publisher),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'The immutable official source is unavailable.',
          ),
        ),
      );
      expect(await stored(), isEmpty);
    });

    test('Fork of an outsider\'s Custom Course records it', () async {
      final theirs = _course(
        'theirs',
        title: 'Theirs',
        maintainer: _bob,
        derivatives: DerivativeWorksPolicy.allowed,
      );
      await asProfile(_bob, () => editor.installImportedCustomCourse(theirs));

      final result = await ops.fork(theirs);

      expect(result.course.forkProvenance?.sourceCourseId, 'theirs');
      expect(result.course.maintainer?.profileId, _alice);
    });
  });

  test(
    'Merge composes "<title> merged", writes nothing, then confirms',
    () async {
      final left = _course('left', title: 'Mine');
      final right = _course('right', title: 'Mine');
      await editor.installImportedCustomCourse(left);
      final library = await ops.load(importOnly: true);

      final proposal = await ops.composeMerge(
        left: left,
        right: right,
        choices: const [LessonMergeChoice.left],
        options: _mergeOptions(left),
        library: library,
      );
      expect(proposal.merged.title, 'Mine merged');
      expect(await stored(), hasLength(1));

      final result = await ops.confirmMerge(proposal);

      expect(result.course.title, 'Mine merged');
      expect((await stored()).map((c) => c.title).toSet(), {
        'Mine',
        'Mine merged',
      });
    },
  );

  group('Import review', () {
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

    test('a new Course has no existing Course and no choices', () async {
      final result = await review(_course('fresh', title: 'Fresh'));
      expect(result.existing, isNull);
      expect(result.choices, isEmpty);
      expect(result.blocked, isFalse);
      expect(result.isPublisherCourse, isFalse);
    });

    test('the Maintainer\'s matching ID offers Copy and Replace', () async {
      await editor.installImportedCustomCourse(_course('same', title: 'Old'));
      await SettingsService().setCourseEditorUnlocked(true);

      final result = await review(_course('same', title: 'New'));

      expect(result.existing?.title, 'Old');
      expect(result.choices, const [
        CourseImportChoice.copyAsNewCourse,
        CourseImportChoice.replace,
      ]);
    });

    test('locked import-only mode offers Replace only', () async {
      await editor.installImportedCustomCourse(_course('same', title: 'Old'));

      final result = await review(_course('same', title: 'New'));

      expect(result.choices, const [CourseImportChoice.replace]);
    });

    test('an outsider\'s matching ID offers Fork only', () async {
      final theirs = _course(
        'same',
        title: 'Old',
        maintainer: _bob,
        derivatives: DerivativeWorksPolicy.allowed,
      );
      await asProfile(_bob, () => editor.installImportedCustomCourse(theirs));
      await SettingsService().setCourseEditorUnlocked(true);

      final result = await review(theirs);

      expect(result.choices, const [CourseImportChoice.fork]);
    });

    test('a Publisher update over an unverified version asks to associate', () {
      Course withStatus(String status) => Course.fromJson({
        ...publisher.toJson(),
        'publisherVerificationStatus': status,
      });
      CourseImportReview over(Course? existing) => CourseImportReview(
        course: withStatus('verified'),
        errors: const [],
        warnings: const [],
        existing: existing,
        choices: const [],
      );
      expect(over(null).isPublisherCourse, isTrue);
      expect(over(null).confirmsUnverifiedAssociation, isFalse);
      expect(
        over(withStatus('verified')).confirmsUnverifiedAssociation,
        isFalse,
      );
      expect(
        over(withStatus('unverified')).confirmsUnverifiedAssociation,
        isTrue,
      );
    });

    test('a Bundled Course package is refused', () async {
      final bundled = await CourseService().loadCourse('IT');
      await expectLater(review(bundled), throwsA(isA<FormatException>()));
    });
  });

  group('Export, Audit, Delete and Publisher removal', () {
    test('Export writes the package into Exports', () async {
      final mine = _course('mine', title: 'Mine');
      await editor.installImportedCustomCourse(mine);

      final exported = await ops.exportCourse(mine);

      expect(await File(exported.path).exists(), isTrue);
      expect(exported.path, contains('Exports'));
    });

    test('Audit names an unavailable World Flag and still audits', () async {
      final course = Course.fromJson({
        ..._course('flag', title: 'Flag').toJson(),
        'worldFlagId': 'no-such-flag',
      });

      final audit = await ops.audit(course);

      expect(audit.flagProblem, contains('no-such-flag'));
      expect(audit.result.issues, isA<List<Object>>());
    });

    test('Delete removes a stored Custom Course', () async {
      final mine = _course('mine', title: 'Mine');
      await editor.installImportedCustomCourse(mine);

      await ops.deleteCourse(mine);

      expect(await stored(), isEmpty);
    });

    test(
      'Publisher removal is refused while another profile uses it',
      () async {
        await editor.installExternalOfficialUpdate(publisher);
        await asProfile(_bob, () => CourseLibraryService().add(publisher));

        await expectLater(
          ops.removePublisherCourse(publisher),
          throwsA(isA<StateError>()),
        );
        expect(await stored(), hasLength(1));

        await asProfile(_bob, () => CourseLibraryService().remove(publisher));
        await ops.removePublisherCourse(publisher);
        expect(await stored(), isEmpty);
      },
    );
  });

  test(
    'New Course builds the scaffolded Draft from the dialog values',
    () async {
      final creator = (await profiles.getActiveProfileRecord())!;

      final course = ops.newCourse(
        creator: creator,
        maintainerProfileId: _bob,
        title: 'Brand new',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        credits: const [
          (
            name: ' Alice ',
            roles: {'Contributor', 'Author'},
            customRoles: 'Voice, Author',
          ),
          (name: '   ', roles: {'Author'}, customRoles: ''),
          (name: 'Bob', roles: <String>{}, customRoles: ''),
        ],
        license: 'CC BY 4.0',
        derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
        rightsHolders: const [
          (type: CourseRightsHolderType.organization, name: ' QQL '),
          (type: CourseRightsHolderType.person, name: ''),
        ],
        languageVariant: '',
        startLevel: 'A1',
        targetLevel: 'A2',
        courseDescription: 'About',
        buyACoffeeUrl: '',
        flag: const CourseFlagSelection.automatic(),
        lessonCount: 2,
        roundsPerLesson: 3,
      );

      expect(course.title, 'Brand new');
      expect(course.originType, CourseOriginType.custom);
      expect(course.publicationState, PublicationState.draft);
      expect(course.maintainer?.profileId, _bob);
      expect(course.originalCourseCreator.id, _alice);
      expect(course.lastVersionEditorProfileId, _alice);
      expect(course.originalCreatedAtUtc, _when.toIso8601String());
      expect(course.modifiedAtUtc, _when.toIso8601String());
      expect(course.courseVersion, '');
      expect(course.ttsLanguage, isNot('und'));
      expect(course.authors.map((a) => a.name), ['Alice', 'Bob']);
      expect(course.authors.first.roles, ['Author', 'Contributor', 'Voice']);
      expect(course.authors.last.roles, ['Contributor']);
      expect(course.rightsHolders.single.name, 'QQL');
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      expect(course.lessons, hasLength(2));
      expect(course.lessons.every((l) => l.rounds.length == 3), isTrue);
      expect(course.lessons.every((l) => l.updatedAt == _when), isTrue);
    },
  );

  test('reports match the texts Course Manager has always shown', () {
    final mine = _course('mine', title: 'Mine');
    expect(CourseLibraryReports.imported(mine, 0), 'Imported “Mine”.');
    expect(
      CourseLibraryReports.imported(mine, 2),
      'Imported “Mine” with 2 Course Audit warnings. Review Course Audit.',
    );
    expect(
      CourseLibraryReports.exported(mine, 'X/Mine.zip', null),
      'Exported “Mine” to X/Mine.zip',
    );
    expect(
      CourseLibraryReports.importBlocked(1),
      'Course Audit found 1 error. Fix these errors before importing the course.',
    );
    expect(
      CourseLibraryReports.confirmed(
        CourseConfirmationResult(
          course: mine,
          backupPath: null,
          hadPreviousVersion: false,
        ),
      ),
      'Course changes confirmed.\nNew course version: 1\n'
      'No previous version existed, so no backup was required.',
    );
  });
}

CourseMergeOptions _mergeOptions(Course course) => CourseMergeOptions(
  title: course.title,
  createDuels: course.createDuels,
  useGuidebook: course.useGuidebook,
  lessonNumberingMode: course.lessonNumberingMode,
  customLessonLabel: course.customLessonLabel,
  sectionNames: course.sectionNames,
  buyACoffeeUrl: course.buyACoffeeUrl,
  courseDescription: course.courseDescription,
  startLevel: course.startLevel,
  targetLevel: course.targetLevel,
  flagCode: course.flagCode,
  worldFlagId: course.worldFlagId,
  flagImageBase64: course.flagImageBase64,
);

Course _course(
  String id, {
  required String title,
  String maintainer = _alice,
  DerivativeWorksPolicy derivatives = DerivativeWorksPolicy.unspecified,
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: maintainer == _alice ? 'Alice' : 'Bob',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  derivativeWorksPolicy: derivatives,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      updatedAt: DateTime.utc(2026, 9, 20),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);
