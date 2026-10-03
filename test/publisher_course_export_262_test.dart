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
import 'package:quisquislingo_app/services/publisher_verification_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';

/// Build 262 Revision 2 (`docs/PUBLISHER_COURSES_PLAN.md` 4.3): Export as
/// Publisher Course turns a custom Course its Maintainer or Team may
/// publish into an unsigned Publisher Course of a known publisher, every ID
/// kept, its official version the Course version (owner decision of
/// 3 October 2026).

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _courseId = 'course_7c1d2b9e-4f3a-4b6c-8d2e-1a5f9e3c7b40';
final _when = DateTime.utc(2026, 10, 3, 16, 45);
const _publisher = TrustedPublishers.quisquisLingoCourses;

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

/// TEST ONLY: a deterministic Ed25519 key for QuisquisLingo Courses.
Future<SimpleKeyPair> _testKeyPair() =>
    Ed25519().newKeyPairFromSeed(List<int>.generate(32, (i) => 0xA5 ^ i));

Future<PublisherVerificationService> _testVerifier() async {
  final publicKey = await (await _testKeyPair()).extractPublicKey();
  return PublisherVerificationService(
    publishers: TrustedPublishers([
      TrustedPublisherKey(
        publisherId: _publisher.publisherId,
        publisherName: _publisher.publisherName,
        keyId: _publisher.keyId,
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
      expect(exported.publisherId, 'com.quisquislingo');
      expect(exported.publisherName, 'QuisquisLingo Courses');
      expect(
        exported.originalCourseCreator.type,
        CourseProvenanceIdentityType.publisher,
      );
      expect(exported.originalCourseCreator.id, 'com.quisquislingo');
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

  group('publishers', () {
    test('QuisquisLingo Courses is offered even while its key is pending', () {
      expect(PublisherCourseExport.publishers(TrustedPublishers(const [])), [
        _publisher,
      ]);
    });

    test('one entry per publisher, revoked keys left out', () {
      const revoked = TrustedPublisherKey(
        publisherId: 'org.example.revoked',
        publisherName: 'Revoked',
        keyId: 'r-1',
        publicKeyBase64: 'AA==',
        revoked: true,
      );
      const second = TrustedPublisherKey(
        publisherId: 'com.quisquislingo',
        publisherName: 'QuisquisLingo Courses',
        keyId: 'qqlc-2027-1',
        publicKeyBase64: 'AA==',
      );
      final listed = PublisherCourseExport.publishers(
        TrustedPublishers([TrustedPublishers.dummy, revoked, second]),
      );
      expect(listed.map((key) => key.publisherId), [
        TrustedPublishers.dummy.publisherId,
        'com.quisquislingo',
      ]);
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
      final path = await ops.exportAsPublisherCourse(
        await _custom(),
        _publisher,
      );
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
      final first = await signWithKey(course, pair, _publisher.keyId);
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
        _publisher.keyId,
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
      var exports = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PublisherCourseExportScreen(
            course: course,
            refusals: const ['The Course has no Course version yet.'],
            publishers: const [_publisher],
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

    testWidgets('Quick Export exports for the chosen publisher', (
      tester,
    ) async {
      final course = (await tester.runAsync(_custom))!;
      final chosen = <TrustedPublisherKey>[];
      await tester.pumpWidget(
        MaterialApp(
          home: PublisherCourseExportScreen(
            course: course,
            refusals: const [],
            publishers: const [_publisher, TrustedPublishers.dummy],
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
      if (TrustedPublishers.quisquisLingoCoursesPublicKeyBase64.isEmpty) {
        expect(
          find.byKey(const Key('publisher-export-key-pending')),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(const Key('publisher-export-publisher')));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .text(
              '${TrustedPublishers.dummy.publisherName} '
              '(${TrustedPublishers.dummy.publisherId})',
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('publisher-export-quick')));
      await tester.pump();
      expect(chosen, [TrustedPublishers.dummy]);
    });
  });
}
