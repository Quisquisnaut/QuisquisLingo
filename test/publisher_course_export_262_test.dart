import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/publisher_course_export_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publisher_course_export.dart';
import 'package:quisquislingo_app/services/publisher_export_memory.dart';
import 'package:quisquislingo_app/services/publisher_verification_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';

/// Build 262 Revision 2 (`docs/PUBLISHER_COURSES_PLAN.md` 4.3): Export as
/// Publisher Course turns a custom Course its Maintainer or Team may
/// publish into an unsigned Publisher Course, every ID kept, its official
/// version the Course version (owner decision of 3 October 2026), for any
/// publisher the author names (owner decision of 4 October 2026).

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _courseId = 'course_7c1d2b9e-4f3a-4b6c-8d2e-1a5f9e3c7b40';
final _when = DateTime.utc(2026, 10, 3, 16, 45);
const _publisher = PublisherIdentity(
  publisherId: 'org.example.courses',
  publisherName: 'Example Courses',
);
const _keyId = 'example-2026-1';

const _officialKeys = [
  'publisherId',
  'publisherName',
  'officialCourseVersion',
  'officialReleaseDateUtc',
  'officialReleaseNotes',
  'distributionChannel',
  'publisherVerificationStatus',
  'officialChecksum',
  'publisherSignature',
];

/// QQL Demo: English from Italian as a custom Course Alice maintains.
Future<Course> _custom({
  String version = '3',
  Map<String, Object?> changes = const {},
}) async {
  final json = (await CourseService().loadBundledCourse('EN_IT')).toJson();
  for (final key in _officialKeys) {
    json.remove(key);
  }
  final merged = <String, dynamic>{
    ...json,
    'courseId': _courseId,
    'originType': 'custom',
    'originalCourseCreator': {
      'type': 'qqlUser',
      'id': _alice,
      'displayName': 'Alice',
    },
    'maintainer': {'profileId': _alice},
    'courseVersion': version,
    'versionNotes': 'Edition $version.',
    'lastVersionEditorProfileId': _alice,
    'lastVersionEditorDisplayName': 'Alice',
    ...changes,
  }..removeWhere((_, value) => value == null);
  return Course.fromJson(merged);
}

List<String> _ids(Course course) => [
  for (final lesson in course.lessons) ...[
    lesson.lessonId,
    for (final round in lesson.rounds) ...[
      round.id,
      for (final content in round.content) content.id,
    ],
  ],
];

/// TEST ONLY: a deterministic Ed25519 key for the example publisher.
Future<SimpleKeyPair> _testKeyPair() =>
    Ed25519().newKeyPairFromSeed(List<int>.generate(32, (i) => 0xA5 ^ i));

Future<PublisherVerificationService> _testVerifier() async {
  final publicKey = await (await _testKeyPair()).extractPublicKey();
  return PublisherVerificationService(
    publishers: TrustedPublishers([
      TrustedPublisherKey(
        publisherId: _publisher.publisherId,
        publisherName: _publisher.publisherName,
        keyId: _keyId,
        publicKeyBase64: base64Encode(publicKey.bytes),
      ),
    ]),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('refusals', () {
    test('a published, clean Course its Maintainer exports', () async {
      expect(
        PublisherCourseExport.refusals(
          await _custom(),
          hasOperationalAccess: true,
        ),
        isEmpty,
      );
    });

    test('each reason is named', () async {
      Future<List<String>> refusals(
        Map<String, Object?> changes, {
        bool access = true,
      }) async => PublisherCourseExport.refusals(
        await _custom(changes: changes),
        hasOperationalAccess: access,
      );
      expect(await refusals(const {}, access: false), [
        'Only the Maintainer or assigned Team can publish this Course.',
      ]);
      expect(await refusals({'courseVersion': null}), [
        'The Course has no Course version yet: confirm it once in the '
            'Course Editor.',
      ]);
      expect(await refusals({'publicationState': 'draft'}), [
        'The Course is not published: use Publish under Course delivery '
            'status in the Course Editor.',
      ]);
      expect(await refusals({'license': ''}), [
        'The Course states no License: set it in Course Info Editor.',
      ]);
      final course = await _custom();
      final firstRound = course.lessons.first.rounds.first;
      final withDraft = Course.fromJson({
        ...course.toJson(),
        'lessons': [
          {
            ...course.lessons.first.toJson(),
            'rounds': [
              {...firstRound.toJson(), 'publicationState': 'draft'},
              for (final round in course.lessons.first.rounds.skip(1))
                round.toJson(),
            ],
          },
          for (final lesson in course.lessons.skip(1)) lesson.toJson(),
        ],
      });
      expect(
        PublisherCourseExport.refusals(withDraft, hasOperationalAccess: true),
        contains(
          'The Course still has Draft content: publish or remove it in the '
          'Course Editor.',
        ),
      );
      final official = await CourseService().loadBundledCourse('EN_IT');
      expect(
        PublisherCourseExport.refusals(official, hasOperationalAccess: true),
        ['Only a custom Course can become a Publisher Course.'],
      );
    });
  });

  group('build', () {
    test('an unsigned Publisher Course with every ID kept', () async {
      final source = await _custom();
      final sourceJson = source.toJson();
      final exported = PublisherCourseExport.build(
        source,
        _publisher,
        now: _when,
      );
      expect(exported.originType, CourseOriginType.externalOfficial);
      expect(exported.courseId, _courseId);
      expect(_ids(exported), _ids(source));
      expect(exported.publisherId, 'org.example.courses');
      expect(exported.publisherName, 'Example Courses');
      expect(
        exported.originalCourseCreator.type,
        CourseProvenanceIdentityType.publisher,
      );
      expect(exported.originalCourseCreator.id, 'org.example.courses');
      expect(exported.originalCreatedAtUtc, source.originalCreatedAtUtc);
      expect(exported.officialCourseVersion, '3');
      expect(exported.officialReleaseNotes, 'Edition 3.');
      expect(exported.officialReleaseDateUtc, '2026-10-03T16:45:00.000Z');
      expect(exported.distributionChannel, 'publisher');
      expect(exported.maintainer, isNull);
      expect(exported.assignedTeamId, isNull);
      expect(exported.courseVersion, isEmpty);
      expect(exported.lastVersionEditorProfileId, isEmpty);
      expect(exported.temporarySample, isFalse);
      expect(exported.license, source.license);
      expect(exported.authors.length, source.authors.length);
      expect(
        exported.publisherVerificationStatus,
        PublisherVerificationStatus.unverified,
      );
      expect(exported.publisherSignature, isEmpty);
      expect(CourseChecksums.official(exported), exported.officialChecksum);
      expect(Course.fromJson(exported.toJson()).toJson(), exported.toJson());
      // The source is never changed.
      expect(source.toJson(), sourceJson);
    });

    test('a Private course is exported as not private', () async {
      final exported = PublisherCourseExport.build(
        await _custom(changes: const {'temporarySample': true}),
        _publisher,
        now: _when,
      );
      expect(exported.temporarySample, isFalse);
    });
  });

  group('publisher', () {
    test('any publisher ID and name the author types, trimmed', () {
      final identity = PublisherCourseExport.identity(
        '  net.someone.lessons ',
        ' Someone Lessons ',
      )!;
      expect(identity.publisherId, 'net.someone.lessons');
      expect(identity.publisherName, 'Someone Lessons');
      expect(PublisherCourseExport.identity('', 'Someone'), isNull);
      expect(PublisherCourseExport.identity('net.someone', '  '), isNull);
      expect(PublisherCourseExport.identity('net someone', 'Someone'), isNull);
      expect(PublisherCourseExport.publisherIdProblem(''), isNull);
      expect(
        PublisherCourseExport.publisherIdProblem('net.some_one-2'),
        isNull,
      );
      expect(
        PublisherCourseExport.publisherIdProblem('net someone'),
        'A publisher ID has no spaces: only letters, digits, dots, hyphens '
        'and underscores.',
      );
    });

    test('a publisher the app does not know is exported too', () async {
      const unknown = PublisherIdentity(
        publisherId: 'net.someone.lessons',
        publisherName: 'Someone Lessons',
      );
      expect(
        TrustedPublishers.application().keys.map((key) => key.publisherId),
        isNot(contains(unknown.publisherId)),
      );
      final exported = PublisherCourseExport.build(
        await _custom(),
        unknown,
        now: _when,
      );
      expect(exported.publisherId, 'net.someone.lessons');
      expect(exported.publisherName, 'Someone Lessons');
      expect(
        () => PublisherCourseExport.build(exported, _publisher, now: _when),
        throwsArgumentError,
        reason: 'already a Publisher Course',
      );
    });

    test('a warning compares the publisher with the accepted ones', () {
      // Owner request of 4 October 2026: warn, never refuse.
      const accepted = TrustedPublisherKey(
        publisherId: 'org.example.courses',
        publisherName: 'Example Courses',
        keyId: 'example-2026-1',
        publicKeyBase64: 'AA==',
      );
      const revoked = TrustedPublisherKey(
        publisherId: 'net.old.lessons',
        publisherName: 'Old Lessons',
        keyId: 'old-1',
        publicKeyBase64: 'AA==',
        revoked: true,
      );
      final registry = TrustedPublishers(const [accepted, revoked]);
      String? warning(String id, String name) =>
          PublisherCourseExport.trustWarning(
            PublisherIdentity(publisherId: id, publisherName: name),
            registry,
          );

      expect(warning('org.example.courses', 'Example Courses'), isNull);
      expect(
        warning('org.example.courses', 'Example courses'),
        'This version of QuisquisLingo knows this publisher as “Example '
        'Courses”: write the name exactly so, or the Course will be refused '
        'at installation.',
      );
      const notAccepted =
          'This version of QuisquisLingo does not accept this publisher yet: '
          'the Course can be exported and signed, but not installed until a '
          'version of the app has its signing key.';
      expect(warning('net.someone.lessons', 'Someone Lessons'), notAccepted);
      // Revoked is not "not yet" (owner review of 4 October 2026).
      expect(
        warning('net.old.lessons', 'Old Lessons'),
        "QuisquisLingo has revoked this publisher's signing key: the Course "
        'cannot be installed until the publisher has a new approved key.',
      );
      // A publisher with a revoked and an active key is accepted.
      expect(
        PublisherCourseExport.trustWarning(
          const PublisherIdentity(
            publisherId: 'net.old.lessons',
            publisherName: 'Old Lessons',
          ),
          TrustedPublishers(const [
            revoked,
            TrustedPublisherKey(
              publisherId: 'net.old.lessons',
              publisherName: 'Old Lessons',
              keyId: 'old-2',
              publicKeyBase64: 'AA==',
            ),
          ]),
        ),
        isNull,
      );
      // This app accepts no such publisher.
      expect(
        PublisherCourseExport.trustWarning(
          const PublisherIdentity(
            publisherId: 'net.someone.lessons',
            publisherName: 'Someone Lessons',
          ),
        ),
        notAccepted,
      );
    });

    test('an unusable publisher is refused', () async {
      final course = await _custom();
      for (final publisher in const [
        PublisherIdentity(publisherId: 'net someone', publisherName: 'X'),
        PublisherIdentity(publisherId: 'net.someone', publisherName: ' '),
      ]) {
        expect(
          () => PublisherCourseExport.build(course, publisher, now: _when),
          throwsArgumentError,
        );
      }
    });
  });

  group('remembered publisher', () {
    test('one per Course, read back, forgotten', () async {
      final memory = PublisherExportMemory();
      expect(await memory.recall(_courseId), isNull);
      await memory.remember(_courseId, _publisher);
      final recalled = (await memory.recall(_courseId))!;
      expect(recalled.publisherId, 'org.example.courses');
      expect(recalled.publisherName, 'Example Courses');
      expect(await memory.recall('course_other'), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where(
          (key) => key.startsWith(PublisherExportMemory.keyPrefix),
        ),
        [PublisherExportMemory.keyForCourseId(_courseId)],
      );
      await memory.forget(_courseId);
      expect(await memory.recall(_courseId), isNull);
    });

    test('an unusable stored value is ignored', () async {
      final prefs = await SharedPreferences.getInstance();
      final key = PublisherExportMemory.keyForCourseId(_courseId);
      for (final raw in [
        'not json',
        '[]',
        '{"publisherId": "net someone", "publisherName": "X"}',
        '{"publisherId": "net.someone"}',
      ]) {
        await prefs.setString(key, raw);
        expect(await PublisherExportMemory().recall(_courseId), isNull);
      }
    });
  });

  group('export, sign, install', () {
    late Directory folder;
    late Directory backups;
    late CourseLibraryOperations ops;

    setUp(() async {
      await ProfileService().createProfile(
        'Alice',
        learnerProfileId: _alice,
        generateScreenNameSuffix: false,
      );
      await ProfileService().setActiveProfileById(_alice);
      folder = await Directory.systemTemp.createTemp('qql-publisher-export-');
      backups = await Directory.systemTemp.createTemp('qql-publisher-bkp-');
      ops = CourseLibraryOperations(
        transfer: CustomCourseTransferService(directory: () async => folder),
        clock: () => _when,
      );
    });
    tearDown(() async {
      await folder.delete(recursive: true);
      await backups.delete(recursive: true);
    });

    Future<Course> exported(String path) async {
      final parsed = await CoursePackageService().parseFile(
        File(path),
        (bytes, _) async => Course.fromJson(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
        ),
      );
      try {
        return parsed.course;
      } finally {
        await parsed.discard();
      }
    }

    test('Quick Export writes the ZIP the signing tool starts from', () async {
      final source = await _custom();
      expect(await ops.rememberedPublisher(source), isNull);
      final path = await ops.exportAsPublisherCourse(source, _publisher);
      // The publisher is remembered for the next export of this Course.
      final remembered = (await ops.rememberedPublisher(source))!;
      expect(remembered.publisherId, _publisher.publisherId);
      expect(remembered.publisherName, _publisher.publisherName);
      expect(
        path,
        endsWith('QQL_IT_EN_qql_demo_english_from_italian_publisher_v3.zip'),
      );
      final course = await exported(path);
      expect(course.originType, CourseOriginType.externalOfficial);
      expect(course.officialCourseVersion, '3');

      // Signed with the publisher's (TEST ONLY) key, it installs; a later
      // export is an update; the same version again is refused.
      final verifier = await _testVerifier();
      final editor = CourseEditorService(
        publisherVerification: verifier,
        backupService: CourseBackupService(
          backupsDirectoryProvider: () async => backups,
          publisherVerification: verifier,
        ),
      );
      final pair = await _testKeyPair();
      final first = await signWithKey(course, pair, _keyId);
      expect(
        (await editor.installExternalOfficialUpdate(
          first,
        )).officialCourse.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      final next = await signWithKey(
        await exported(
          await ops.exportAsPublisherCourse(
            await _custom(version: '4'),
            _publisher,
          ),
        ),
        pair,
        _keyId,
      );
      final updated = await editor.installExternalOfficialUpdate(next);
      expect(updated.officialCourse.officialCourseVersion, '4');
      expect(updated.backupPath, isNotNull);
      await expectLater(
        editor.installExternalOfficialUpdate(first),
        throwsFormatException,
      );
    });

    test('a refused Course is not exported', () async {
      await expectLater(
        ops.exportAsPublisherCourse(
          await _custom(changes: const {'license': ''}),
          _publisher,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('The Course states no License'),
          ),
        ),
      );
      expect(folder.listSync(), isEmpty);
      expect(await PublisherExportMemory().recall(_courseId), isNull);
    });

    test('someone else\'s Course is not exported', () async {
      await expectLater(
        ops.exportAsPublisherCourse(
          await _custom(
            changes: const {
              'maintainer': {'profileId': _bob},
            },
          ),
          _publisher,
        ),
        throwsFormatException,
      );
      expect(folder.listSync(), isEmpty);
    });
  });

  group('Course Studio', () {
    test('the menu entry follows the Maintainer and Team', () async {
      final mine = await _custom();
      final theirs = await _custom(
        changes: const {
          'maintainer': {'profileId': _bob},
        },
      );
      final library = CourseManagerLibrary(
        personalCourses: [mine, theirs],
        activeProfileId: _alice,
      );
      CourseManagerEntry? entry(Course course) => library
          .entriesFor(course)
          .where(
            (entry) =>
                entry.action == CourseManagerAction.exportAsPublisherCourse,
          )
          .firstOrNull;
      expect(entry(mine)!.available, isTrue);
      expect(
        entry(theirs)!.unavailableReason,
        'Only the Maintainer or assigned Team can publish this Course.',
      );
      expect(entry(await CourseService().loadBundledCourse('EN_IT')), isNull);
    });

    testWidgets('the screen names the refusals and exports nothing', (
      tester,
    ) async {
      final course = (await tester.runAsync(_custom))!;
      // The whole page, buttons included, is built.
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var exports = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PublisherCourseExportScreen(
            course: course,
            refusals: const ['The Course has no Course version yet.'],
            onExport: (_) async => exports++,
          ),
        ),
      );
      expect(
        find.text('• The Course has no Course version yet.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('publisher-export-quick')),
            )
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('publisher-export-save-as')), findsNothing);
      expect(exports, 0);
    });

    testWidgets('the page warns about a publisher it would not accept', (
      tester,
    ) async {
      final course = (await tester.runAsync(_custom))!;
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final registry = TrustedPublishers(const [
        TrustedPublisherKey(
          publisherId: 'org.example.courses',
          publisherName: 'Example Courses',
          keyId: 'example-2026-1',
          publicKeyBase64: 'AA==',
        ),
      ]);
      var exports = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PublisherCourseExportScreen(
            course: course,
            refusals: const [],
            registry: registry,
            onExport: (_) async => exports++,
          ),
        ),
      );
      final warning = find.byKey(const Key('publisher-export-trust-warning'));
      expect(warning, findsNothing);

      Future<void> type(String id, String name) async {
        await tester.enterText(
          find.byKey(const Key('publisher-export-publisher-id')),
          id,
        );
        await tester.enterText(
          find.byKey(const Key('publisher-export-publisher-name')),
          name,
        );
        await tester.pump();
      }

      await type('net.someone.lessons', 'Someone Lessons');
      expect(warning, findsOneWidget);
      expect(find.textContaining('does not accept this publisher'), findsOne);
      await type('org.example.courses', 'Example courses');
      expect(
        find.textContaining('knows this publisher as “Example Courses”'),
        findsOne,
      );
      // A warning, not a refusal.
      await tester.tap(find.byKey(const Key('publisher-export-quick')));
      await tester.pump();
      expect(exports, 1);
      await type('org.example.courses', 'Example Courses');
      expect(warning, findsNothing);
    });

    testWidgets('a remembered publisher is filled in', (tester) async {
      final course = (await tester.runAsync(_custom))!;
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final chosen = <PublisherIdentity>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PublisherCourseExportScreen(
            course: course,
            refusals: const [],
            initialPublisher: _publisher,
            onExport: (publisher) async => chosen.add(publisher),
          ),
        ),
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('publisher-export-publisher-id')),
            )
            .controller!
            .text,
        'org.example.courses',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('publisher-export-publisher-name')),
            )
            .controller!
            .text,
        'Example Courses',
      );
      expect(
        find.byKey(const Key('publisher-export-remembered')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('publisher-export-quick')));
      await tester.pump();
      expect(chosen.single.publisherId, 'org.example.courses');
    });

    testWidgets('Quick Export exports for the publisher the author names', (
      tester,
    ) async {
      final course = (await tester.runAsync(_custom))!;
      // The whole page, buttons included, is built.
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final chosen = <PublisherIdentity>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PublisherCourseExportScreen(
            course: course,
            refusals: const [],
            onExport: (publisher) async => chosen.add(publisher),
            onSaveTo: (_) async {},
          ),
        ),
      );
      expect(
        find.text(
          'Official version: 3 (the Course version, which rises each time '
          'you confirm the Course)',
        ),
        findsOneWidget,
      );
      // No publisher is suggested (owner decision of 4 October 2026).
      expect(find.textContaining('com.quisquislingo'), findsNothing);
      expect(find.textContaining('QuisquisLingo Courses'), findsNothing);
      FilledButton quick() => tester.widget<FilledButton>(
        find.byKey(const Key('publisher-export-quick')),
      );
      OutlinedButton saveAs() => tester.widget<OutlinedButton>(
        find.byKey(const Key('publisher-export-save-as')),
      );
      expect(quick().onPressed, isNull);
      expect(saveAs().onPressed, isNull);
      expect(
        find.byKey(const Key('publisher-export-remembered')),
        findsNothing,
      );

      await tester.enterText(
        find.byKey(const Key('publisher-export-publisher-id')),
        'net someone',
      );
      await tester.enterText(
        find.byKey(const Key('publisher-export-publisher-name')),
        'Someone Lessons',
      );
      await tester.pump();
      expect(
        find.textContaining('A publisher ID has no spaces'),
        findsOneWidget,
      );
      expect(quick().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('publisher-export-publisher-id')),
        'net.someone.lessons ',
      );
      await tester.pump();
      expect(find.textContaining('A publisher ID has no spaces'), findsNothing);
      expect(saveAs().onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('publisher-export-quick')));
      await tester.pump();
      expect(chosen.single.publisherId, 'net.someone.lessons');
      expect(chosen.single.publisherName, 'Someone Lessons');
    });
  });
}
