import 'dart:convert';
import 'dart:io';

import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/publisher_verification_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';

/// Developer tool: it never reads a private key or approves a publisher.
Future<void> main(List<String> args) async {
  try {
    if (args.length != 4 && args.length != 6) {
      throw const FormatException(
        'Usage:\n dart run tools/sign_course.dart prepare INPUT.json KEY_ID PAYLOAD.bin\n'
        ' dart run tools/sign_course.dart attach INPUT.json KEY_ID SIGNATURE.bin PUBLIC.der OUTPUT.json',
      );
    }
    final input = Course.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(await File(args[1]).readAsString()) as Map,
      ),
    );
    if (input.originType != CourseOriginType.externalOfficial) {
      throw const FormatException(
        'Input must already be a valid externalOfficial course.',
      );
    }
    final course = Course.fromJson({
      ...input.toJson(),
      'officialChecksum': CourseChecksums.official(input),
      'publisherVerificationStatus': 'unverified',
    });
    final payload = PublisherVerificationService.signingBytes(course, args[2]);
    if (args[0] == 'prepare' && args.length == 4) {
      await _writeNew(args[3], payload);
      stdout.writeln(
        'Prepared signing payload. Sign it with OpenSSL Ed25519 -rawin.',
      );
    } else if (args[0] == 'attach' && args.length == 6) {
      final der = await File(args[4]).readAsBytes();
      // Ed25519 SubjectPublicKeyInfo: RFC 8410, OID 1.3.101.112, 32-byte key.
      const prefix = [
        0x30,
        0x2a,
        0x30,
        0x05,
        0x06,
        0x03,
        0x2b,
        0x65,
        0x70,
        0x03,
        0x21,
        0x00,
      ];
      if (der.length != 44 ||
          !List.generate(12, (i) => der[i] == prefix[i]).every((v) => v)) {
        throw const FormatException(
          'Expected an Ed25519 public key in DER SubjectPublicKeyInfo format.',
        );
      }
      final signed = Course.fromJson({
        ...course.toJson(),
        'publisherSignature':
            '${PublisherVerificationService.protocol}:${args[2]}:${base64Encode(await File(args[3]).readAsBytes())}',
      });
      await PublisherVerificationService(
        publishers: TrustedPublishers([
          TrustedPublisherKey(
            publisherId: course.publisherId,
            publisherName: course.publisherName,
            keyId: args[2],
            publicKeyBase64: base64Encode(der.sublist(12)),
          ),
        ]),
      ).requireVerified(signed);
      // Verification above proves key/payload agreement, not QQL approval.
      await _writeNew(
        args[5],
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert(signed.toJson()),
        ),
      );
      stdout.writeln(
        'Signature verified and attached. QQL must separately trust this publisher/key.',
      );
    } else {
      throw const FormatException('Invalid command or argument count.');
    }
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

Future<void> _writeNew(String path, List<int> bytes) async {
  final file = File(path);
  if (await file.exists()) {
    throw FileSystemException('Output already exists; choose a new name', path);
  }
  await file.writeAsBytes(bytes, flush: true);
}
