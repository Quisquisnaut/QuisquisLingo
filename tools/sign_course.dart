import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';
import 'package:quisquislingo_app/services/publisher_verification_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';

/// Developer tool: it never reads a private key or approves a publisher.
Future<void> main(List<String> args) async {
  try {
    if (args.length == 5 && args[0] == 'package') {
      await packageSignedCourse(args[1], args[2], args[3], args[4]);
      return;
    }
    if (args.length != 4 && args.length != 6) {
      throw const FormatException(
        'Usage:\n dart run tools/sign_course.dart prepare INPUT.json KEY_ID PAYLOAD.bin\n'
        ' dart run tools/sign_course.dart attach INPUT.json KEY_ID SIGNATURE.bin PUBLIC.der OUTPUT.json\n'
        ' dart run tools/sign_course.dart package SIGNED.json MEDIA_DIR PUBLIC.der OUTPUT.zip',
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

Future<void> packageSignedCourse(
  String signedPath,
  String mediaPath,
  String publicKeyPath,
  String outputPath,
) async {
  final sourceBytes = await File(signedPath).readAsBytes();
  final signed = Course.fromJson(
    Map<String, dynamic>.from(jsonDecode(utf8.decode(sourceBytes)) as Map),
  );
  if (signed.originType != CourseOriginType.externalOfficial) {
    throw const FormatException(
      'Only signed Publisher Courses can be packaged.',
    );
  }
  final signatureParts = signed.publisherSignature.split(':');
  if (signatureParts.length != 3 ||
      signatureParts[0] != PublisherVerificationService.protocol) {
    throw const FormatException(
      'The Publisher signature is missing or malformed.',
    );
  }
  final der = await File(publicKeyPath).readAsBytes();
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
      !List.generate(12, (i) => der[i] == prefix[i]).every((valid) => valid)) {
    throw const FormatException(
      'Expected an Ed25519 public key in DER format.',
    );
  }
  await PublisherVerificationService(
    publishers: TrustedPublishers([
      TrustedPublisherKey(
        publisherId: signed.publisherId,
        publisherName: signed.publisherName,
        keyId: signatureParts[1],
        publicKeyBase64: base64Encode(der.sublist(12)),
      ),
    ]),
  ).requireVerified(signed);
  final references = _mediaReferences(signed).toList()..sort();
  final archive = Archive();
  final sources = _sharedImageSources(signed);
  final manifest = Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'packageFormat': 1,
        if (sources.isNotEmpty) 'sharedImageSources': sources,
      }),
    ),
  );
  if (sourceBytes.length > 10 * 1024 * 1024 || manifest.length > 1024 * 1024) {
    throw const FormatException(
      'Publisher Course JSON or manifest is too large.',
    );
  }
  archive
    ..addFile(ArchiveFile.bytes('qql-course-package.json', manifest))
    ..addFile(
      ArchiveFile.bytes('course.json', Uint8List.fromList(sourceBytes)),
    );
  var total = sourceBytes.length + manifest.length;
  for (final reference in references) {
    final name = reference.substring('media:'.length);
    final file = File('$mediaPath${Platform.pathSeparator}$name');
    final limit = reference.endsWith('.mp3') ? 50 * 1024 * 1024 : 50 * 1024;
    if (!await file.exists() || await file.length() > limit) {
      throw FormatException(
        'Missing or oversized Publisher media: ${file.path}',
      );
    }
    final bytes = Uint8List.fromList(await file.readAsBytes());
    if (bytes.isEmpty ||
        sha256.convert(bytes).toString() != name.substring(0, 64)) {
      throw FormatException(
        'Publisher media has the wrong SHA-256: ${file.path}',
      );
    }
    total += bytes.length;
    if (total > 300 * 1024 * 1024) {
      throw const FormatException('Course package exceeds the 300 MB limit.');
    }
    archive.addFile(ArchiveFile.bytes('media/$name', bytes));
  }
  final zip = ZipEncoder().encode(archive);
  if (zip.length > 300 * 1024 * 1024) {
    throw const FormatException('Course package exceeds the 300 MB limit.');
  }
  await _writeNew(outputPath, zip);
  stdout.writeln(
    'Signed Course ZIP verified and written. QQL must separately trust this publisher/key.',
  );
}

final _mediaPattern = RegExp(r'^media:[0-9a-f]{64}\.(mp3|png|jpg|jpeg|webp)$');

Set<String> _mediaReferences(Course course) {
  final found = <String>{};
  for (final clip in course.audioLibrary) {
    if (_mediaPattern.hasMatch(clip.filePath)) found.add(clip.filePath);
  }
  if (_mediaPattern.hasMatch(course.coverImage)) found.add(course.coverImage);
  void visit(Object? node) {
    if (node is Map) {
      final asset = node['asset'];
      if (node['type'] == 'image' &&
          asset is String &&
          _mediaPattern.hasMatch(asset)) {
        found.add(asset);
      }
      node.values.forEach(visit);
    } else if (node is List) {
      node.forEach(visit);
    }
  }

  visit([for (final lesson in course.lessons) lesson.toJson()]);
  return found;
}

List<Map<String, dynamic>> _sharedImageSources(Course course) {
  final entries = <String, Map<String, dynamic>>{};
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final exercise in round.exercises) {
        for (final element in exercise.promptElements) {
          final source = element.sharedImageSource;
          if (source == null) continue;
          final entry = <String, dynamic>{
            'media': element.asset,
            'sha256': element.asset.substring(
              'media:'.length,
              'media:'.length + 64,
            ),
            ...source.toJson(),
          };
          entries[jsonEncode(entry)] = entry;
        }
      }
    }
  }
  final sorted = entries.keys.toList()..sort();
  return [for (final key in sorted) entries[key]!];
}

Future<void> _writeNew(String path, List<int> bytes) async {
  final file = File(path);
  if (await file.exists()) {
    throw FileSystemException('Output already exists; choose a new name', path);
  }
  await file.writeAsBytes(bytes, flush: true);
}
