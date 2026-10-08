import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';

/// Signed Publisher JSON may name content-addressed media. The Course ZIP
/// supplies the bytes; installation checks their presence and digest.
final _courseMedia = 'media:${'c' * 64}.mp3';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final verifier = fixtureVerifier(
    TrustedPublishers.dummy.publisherId,
    TrustedPublishers.dummy.publisherName,
  );

  Course fixture() => Course.fromJson(
    Map<String, dynamic>.from(
      jsonDecode(
            File(
              'test/fixtures/publishers/dummy-signed-v1.json',
            ).readAsStringSync(),
          )
          as Map,
    ),
  );

  Uint8List bytes(Course value) =>
      Uint8List.fromList(utf8.encode(jsonEncode(value.toJson())));

  Course withClips(Course course, List<CourseAudioClip> clips) =>
      Course.fromJson({
        ...course.toJson(),
        'audioMode': 'recorded',
        'audioLibrary': clips.map((clip) => clip.toJson()).toList(),
      });

  group('at import', () {
    test(
      'a validly signed Publisher Course with recordings verifies',
      () async {
        final signed = await signFixture(
          withClips(fixture(), [
            CourseAudioClip(id: 'a', text: 'ciao', filePath: _courseMedia),
          ]),
        );
        final transfer = CustomCourseTransferService(
          publisherVerification: verifier,
        );
        final verified = await transfer.courseFromBytes(
          bytes(signed),
          'signed-with-audio.json',
        );
        expect(verified.audioLibrary.single.filePath, _courseMedia);
        expect(
          verified.publisherVerificationStatus,
          PublisherVerificationStatus.verified,
        );
      },
    );

    test('an unchanged Publisher Course still imports', () async {
      final transfer = CustomCourseTransferService(
        publisherVerification: verifier,
      );
      final imported = await transfer.courseFromBytes(
        bytes(fixture()),
        'signed.json',
      );
      expect(
        imported.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
    });

    test('a custom course keeps its local recordings', () async {
      // The rule is about Publisher Courses only: a custom author can repair
      // a path, so their course must still import exactly as before.
      final transfer = CustomCourseTransferService(
        publisherVerification: verifier,
      );
      final json = Map<String, dynamic>.from(fixture().toJson())
        ..remove('publisherId')
        ..remove('publisherName')
        ..remove('publisherSignature')
        ..remove('publisherVerificationStatus')
        ..remove('officialChecksum')
        ..remove('officialCourseVersion')
        ..remove('officialReleaseDateUtc')
        ..remove('officialReleaseNotes')
        ..remove('distributionChannel');
      json['originType'] = 'custom';
      json['maintainer'] = {
        'profileId': '12345678-1234-4234-9234-123456789abc',
      };
      json['originalCourseCreator'] = {
        'type': 'qqlUser',
        'id': '12345678-1234-4234-9234-123456789abc',
        'displayName': 'Original Creator',
      };
      json['lastVersionEditorProfileId'] =
          '12345678-1234-4234-9234-123456789abc';
      json['lastVersionEditorDisplayName'] = 'Last Editor';
      json['modifiedAtUtc'] = '2026-09-20T11:00:00.000Z';
      json['audioMode'] = 'recorded';
      json['audioLibrary'] = [
        {'id': 'a', 'text': 'ciao', 'filePath': _courseMedia},
      ];
      final custom = Course.fromJson(json);
      final imported = await transfer.courseFromBytes(
        bytes(custom),
        'custom.json',
      );
      expect(imported.audioLibrary.single.filePath, _courseMedia);
    });
  });
}
