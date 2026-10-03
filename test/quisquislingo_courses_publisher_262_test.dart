import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/publisher_verification_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';

/// Build 262 Revision 1 (`docs/PUBLISHER_COURSES_PLAN.md` 4.2): the
/// publisher QuisquisLingo Courses has its place in the trusted publisher
/// registry. Its real key is pending (the owner creates it), so these tests
/// trust a TEST ONLY key under the same identity, as guide §6 asks: a
/// Course signed by the key is accepted; altered, unsigned and wrong-key
/// Courses are refused.

const _publisher = TrustedPublishers.quisquisLingoCourses;

/// TEST ONLY: a deterministic Ed25519 key, never a production credential.
Future<SimpleKeyPair> _testKeyPair() =>
    Ed25519().newKeyPairFromSeed(List<int>.generate(32, (i) => 0xC0 ^ i));

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

/// The Dummy fixture Course, published by QuisquisLingo Courses.
Course _unsigned() {
  final json = Map<String, dynamic>.from(
    jsonDecode(
          File(
            'test/fixtures/publishers/dummy-unsigned.json',
          ).readAsStringSync(),
        )
        as Map,
  );
  return Course.fromJson({
    ...json,
    'courseId': 'qqlc-test-course',
    'title': 'QuisquisLingo Courses sample — TEST ONLY',
    'publisherId': _publisher.publisherId,
    'publisherName': _publisher.publisherName,
    'originalCourseCreator': {
      'type': 'publisher',
      'id': _publisher.publisherId,
      'displayName': _publisher.publisherName,
    },
    'distributionChannel': 'publisher',
    'publisherSignature': '',
  });
}

Future<Course> _signed([Course? course]) async =>
    signWithKey(course ?? _unsigned(), await _testKeyPair(), _publisher.keyId);

Course _mutate(Course course, Map<String, Object?> changes) =>
    Course.fromJson({...course.toJson(), ...changes});

Uint8List _bytes(Course course) =>
    Uint8List.fromList(utf8.encode(jsonEncode(course.toJson())));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the registry entry', () {
    test('names QuisquisLingo Courses, apart from the app', () {
      expect(_publisher.publisherId, 'com.quisquislingo');
      expect(_publisher.publisherName, 'QuisquisLingo Courses');
      expect(_publisher.keyId, 'qqlc-2026-1');
      expect(_publisher.revoked, isFalse);
      // The bundled Courses' publisher is the app itself.
      expect(_publisher.publisherId, isNot('org.quisquislingo'));
      // A key ID the signing payload accepts.
      expect(
        () => PublisherVerificationService.signingBytes(
          _unsigned(),
          _publisher.keyId,
        ),
        returnsNormally,
      );
    });

    test('the app trusts it only once its key is there', () {
      final pending =
          TrustedPublishers.quisquisLingoCoursesPublicKeyBase64.isEmpty;
      final found = TrustedPublishers.application().find(
        _publisher.publisherId,
        _publisher.keyId,
      );
      if (pending) {
        expect(found, isNull);
      } else {
        expect(found, isNotNull);
        expect(found!.publicKeyBytes, hasLength(32));
      }
      // The Dummy publisher stays a test-build option.
      expect(
        TrustedPublishers.application().find(
              TrustedPublishers.dummy.publisherId,
              TrustedPublishers.dummy.keyId,
            ) !=
            null,
        TrustedPublishers.dummyEnabled,
      );
    });

    test('while the key is pending its Courses are refused', () async {
      if (TrustedPublishers.quisquisLingoCoursesPublicKeyBase64.isNotEmpty) {
        return;
      }
      await expectLater(
        PublisherVerificationService().requireVerified(await _signed()),
        throwsFormatException,
      );
    });
  });

  group('with the TEST ONLY key', () {
    test('a signed Course verifies, imports and installs', () async {
      final verifier = await _testVerifier();
      final signed = await _signed();
      expect(
        (await verifier.requireVerified(signed)).publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      final imported = await CustomCourseTransferService(
        publisherVerification: verifier,
      ).courseFromBytes(_bytes(signed), 'signed.json');
      expect(
        imported.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      expect(imported.publisherName, 'QuisquisLingo Courses');

      final directory = await Directory.systemTemp.createTemp('qqlc-');
      addTearDown(() => directory.delete(recursive: true));
      final editor = CourseEditorService(
        publisherVerification: verifier,
        backupService: CourseBackupService(
          backupsDirectoryProvider: () async => directory,
          publisherVerification: verifier,
        ),
      );
      final installed = await editor.installExternalOfficialUpdate(signed);
      expect(installed.officialCourse.courseId, 'qqlc-test-course');
      expect(
        installed.officialCourse.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      expect(
        (await editor.listUserCourses()).map((course) => course.courseId),
        contains('qqlc-test-course'),
      );
    });

    test('an altered Course is refused, even with a new checksum', () async {
      final verifier = await _testVerifier();
      final changed = _mutate(await _signed(), {'title': 'Altered title'});
      final recalculated = _mutate(changed, {
        'officialChecksum': CourseBackupService.officialContentChecksum(
          changed,
        ),
      });
      for (final course in [changed, recalculated]) {
        await expectLater(
          verifier.requireVerified(course),
          throwsFormatException,
        );
      }
    });

    test('a Course without a signature is refused', () async {
      final verifier = await _testVerifier();
      final unsigned = _mutate(await _signed(), {
        'publisherSignature': '',
        'publisherVerificationStatus': 'verified',
      });
      await expectLater(
        verifier.requireVerified(unsigned),
        throwsFormatException,
      );
      await expectLater(
        CustomCourseTransferService(
          publisherVerification: verifier,
        ).courseFromBytes(_bytes(unsigned), 'unsigned.json'),
        throwsFormatException,
      );
    });

    test('a Course signed with another key is refused', () async {
      final verifier = await _testVerifier();
      // The Dummy key, under QuisquisLingo Courses' key ID.
      final wrongKey = await signWithKey(
        _unsigned(),
        await dummyKeyPair(),
        _publisher.keyId,
      );
      await expectLater(
        verifier.requireVerified(wrongKey),
        throwsFormatException,
      );
      // Another key ID, unknown to the registry.
      final unknownKeyId = await signWithKey(
        _unsigned(),
        await _testKeyPair(),
        'qqlc-2026-2',
      );
      await expectLater(
        verifier.requireVerified(unknownKeyId),
        throwsFormatException,
      );
    });

    test('another publisher name or ID is refused', () async {
      final verifier = await _testVerifier();
      final renamed = await _signed(
        _mutate(_unsigned(), {
          'publisherName': 'QuisquisLingo',
          'originalCourseCreator': {
            'type': 'publisher',
            'id': _publisher.publisherId,
            'displayName': 'QuisquisLingo',
          },
        }),
      );
      await expectLater(
        verifier.requireVerified(renamed),
        throwsFormatException,
      );
      final otherId = await _signed(
        _mutate(_unsigned(), {
          'publisherId': 'org.quisquislingo',
          'originalCourseCreator': {
            'type': 'publisher',
            'id': 'org.quisquislingo',
            'displayName': _publisher.publisherName,
          },
        }),
      );
      await expectLater(
        verifier.requireVerified(otherId),
        throwsFormatException,
      );
    });
  });
}
