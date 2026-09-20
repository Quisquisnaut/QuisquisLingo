import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';

/// A Course file carries clip paths, never MP3 bytes. A custom author can
/// repair a broken path; a publisher cannot, because the path sits inside the
/// signed payload. Such a course would install silently broken and stay that
/// way, so it is refused at import instead.
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

  group('the structural rule', () {
    test('a device path is refused, bundled and empty are accepted', () {
      void check(Course course) =>
          CustomCourseTransferService.rejectUnreachablePublisherRecordings(
            course,
          );

      expect(() => check(fixture()), returnsNormally);
      expect(
        () => check(
          withClips(fixture(), const [
            CourseAudioClip(
              id: 'a',
              text: 'ciao',
              filePath: 'assets/audio/it_sample/sample_1.mp3',
            ),
          ]),
        ),
        returnsNormally,
        reason: 'recordings shipped with the app are reachable everywhere',
      );
      expect(
        () => check(
          withClips(fixture(), const [
            CourseAudioClip(
              id: 'a',
              text: 'ciao',
              filePath: 'C:/publisher/recordings/ciao.mp3',
            ),
          ]),
        ),
        throwsFormatException,
      );
    });
  });

  group('at import', () {
    test('a validly signed Publisher Course with recordings is refused', () async {
      // Signed with the real test key, so this fails on the media rule alone
      // and not because the signature stopped matching.
      final signed = await signFixture(
        withClips(fixture(), const [
          CourseAudioClip(
            id: 'a',
            text: 'ciao',
            filePath: 'C:/publisher/recordings/ciao.mp3',
          ),
        ]),
      );
      final transfer = CustomCourseTransferService(
        publisherVerification: verifier,
      );
      await expectLater(
        transfer.courseFromBytes(bytes(signed), 'signed-with-audio.json'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('cannot be delivered inside a Course file'),
          ),
        ),
        reason:
            'the media rule must fire on its own terms, before verification',
      );
    });

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
        {'id': 'a', 'text': 'ciao', 'filePath': 'C:/mine/ciao.mp3'},
      ];
      final custom = Course.fromJson(json);
      final imported = await transfer.courseFromBytes(
        bytes(custom),
        'custom.json',
      );
      expect(imported.audioLibrary.single.filePath, 'C:/mine/ciao.mp3');
    });
  });
}
