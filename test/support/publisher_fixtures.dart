import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/publisher_verification_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';

/// Explicit trust injection for tests only. No global registry override.
PublisherVerificationService fixtureVerifier(
  String publisherId,
  String name, {
  bool revoked = false,
}) => PublisherVerificationService(
  publishers: TrustedPublishers([
    TrustedPublisherKey(
      publisherId: publisherId,
      publisherName: name,
      keyId: TrustedPublishers.dummy.keyId,
      publicKeyBase64: TrustedPublishers.dummy.publicKeyBase64,
      revoked: revoked,
    ),
  ]),
);

Future<Course> signFixture(Course course) async =>
    signWithKey(course, await dummyKeyPair(), 'dummy-1');

/// The Dummy publisher's key pair, read from its TEST ONLY private key.
Future<SimpleKeyPair> dummyKeyPair() {
  final pem = File(
    'test/fixtures/publishers/dummy-private.pem',
  ).readAsLinesSync().where((line) => !line.startsWith('-----')).join();
  final der = base64Decode(pem);
  return Ed25519().newKeyPairFromSeed(der.sublist(der.length - 32));
}

/// [course] signed with [pair] under [keyId], as `tools/sign_course.dart`
/// and OpenSSL would sign it.
Future<Course> signWithKey(
  Course course,
  SimpleKeyPair pair,
  String keyId,
) async {
  final normalized = Course.fromJson({
    ...course.toJson(),
    'officialChecksum': CourseChecksums.official(course),
    'publisherVerificationStatus': 'unverified',
  });
  final signature = await Ed25519().sign(
    PublisherVerificationService.signingBytes(normalized, keyId),
    keyPair: pair,
  );
  return Course.fromJson({
    ...normalized.toJson(),
    'publisherSignature':
        '${PublisherVerificationService.protocol}:$keyId:${base64Encode(signature.bytes)}',
  });
}
