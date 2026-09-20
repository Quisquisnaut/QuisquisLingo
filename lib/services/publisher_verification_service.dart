import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../models/course_models.dart';
import 'course_checksums.dart';
import 'trusted_publishers.dart';

class PublisherVerificationService {
  PublisherVerificationService({TrustedPublishers? publishers})
    : publishers = publishers ?? TrustedPublishers.application();

  final TrustedPublishers publishers;
  static const protocol = 'qql-ed25519-v1';
  static final _keyIdPattern = RegExp(r'^[A-Za-z0-9._-]{1,64}$');
  static bool _validKeyId(String value) =>
      _keyIdPattern.firstMatch(value)?.group(0) == value;

  /// The same bytes are used by the developer signing tool and the verifier.
  static List<int> signingBytes(Course course, String keyId) {
    if (!_validKeyId(keyId) ||
        course.publisherId.isEmpty ||
        course.publisherId.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException(
        'Invalid publisher or signing key identifier.',
      );
    }
    return utf8.encode(
      'QQL-COURSE-SIGNATURE-V1\n${course.publisherId}\n$keyId\n${CourseChecksums.official(course)}\n',
    );
  }

  Future<Course> requireVerified(Course course) async {
    if (course.originType != CourseOriginType.externalOfficial) {
      throw const FormatException(
        'Only Publisher Courses use publisher signatures.',
      );
    }
    if (CourseChecksums.official(course) != course.officialChecksum) {
      throw const FormatException(
        'The Publisher Course package checksum is invalid.',
      );
    }
    if (course.publisherSignature.isEmpty) {
      throw const FormatException(
        'Publisher signature missing. This file cannot be imported as a Publisher Course.',
      );
    }
    final parts = course.publisherSignature.split(':');
    if (parts.length != 3 || parts[0] != protocol || !_validKeyId(parts[1])) {
      throw const FormatException(
        'Unsupported or malformed publisher signature.',
      );
    }
    final key = publishers.find(course.publisherId, parts[1]);
    if (key == null) {
      throw const FormatException(
        'Unknown publisher signing key. An app update with an approved key may be required.',
      );
    }
    if (key.revoked) {
      throw const FormatException(
        'The publisher signing key has been revoked.',
      );
    }
    if (key.publisherName != course.publisherName) {
      throw const FormatException(
        'The publisher name does not match the approved identity.',
      );
    }
    List<int> bytes;
    try {
      bytes = base64Decode(parts[2]);
    } on FormatException {
      throw const FormatException('Malformed publisher signature encoding.');
    }
    if (bytes.length != 64 ||
        base64Encode(bytes) != parts[2] ||
        key.publicKeyBytes.length != 32) {
      throw const FormatException('Invalid publisher signature or key length.');
    }
    final valid = await Ed25519().verify(
      signingBytes(course, parts[1]),
      signature: Signature(
        bytes,
        publicKey: SimplePublicKey(
          key.publicKeyBytes,
          type: KeyPairType.ed25519,
        ),
      ),
    );
    if (!valid) {
      throw const FormatException(
        'Publisher signature invalid. The course may have been altered.',
      );
    }
    return _withStatus(course, PublisherVerificationStatus.verified);
  }

  /// Re-evaluate stored sources without deleting/quarantining their files or
  /// trusting a serialized verification flag. Invalid signatures remain visible
  /// to the manager, but cannot enter learner delivery or a verified import.
  Future<Course> assessStored(Course course) async {
    if (course.originType != CourseOriginType.externalOfficial) return course;
    try {
      return await requireVerified(course);
    } on FormatException {
      return _withStatus(course, PublisherVerificationStatus.unverified);
    }
  }

  static Course _withStatus(
    Course course,
    PublisherVerificationStatus status,
  ) => Course.fromJson({
    ...course.toJson(),
    'publisherVerificationStatus': status.name,
  });
}
