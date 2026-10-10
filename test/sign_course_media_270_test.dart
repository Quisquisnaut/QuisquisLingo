import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';

import 'support/publisher_fixtures.dart';
import 'support/unique_png.dart';
import '../tools/sign_course.dart' as signing_tool;

// Build 270 Revision 7: the signing tool packages the media the app looks
// for (it missed the Course's image library, so QQL refused the package).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a picture only in the image library is packaged', () async {
    final root = await Directory.systemTemp.createTemp('qql-270-signing-');
    addTearDown(() => root.delete(recursive: true));
    final source = Course.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
              File(
                'test/fixtures/publishers/dummy-signed-v1.json',
              ).readAsStringSync(),
            )
            as Map,
      ),
    );
    final picture = uniquePng(270);
    final reference = CourseMediaStore.referenceFor(picture, 'png');
    final signed = await signFixture(
      Course.fromJson({
        ...source.toJson(),
        'imageLibrary': [
          {'asset': reference},
        ],
      }),
    );
    expect(CourseMediaStore.referencesOf(signed), {reference});
    final signedFile = File('${root.path}/signed.json');
    await signedFile.writeAsString(jsonEncode(signed.toJson()));
    final mediaDir = Directory('${root.path}/media')..createSync();
    await File(
      '${mediaDir.path}/${CourseMediaStore.fileNameOf(reference)}',
    ).writeAsBytes(picture);
    final output = '${root.path}/course.zip';
    await signing_tool.packageSignedCourse(
      signedFile.path,
      mediaDir.path,
      'test/fixtures/publishers/dummy-public.der',
      output,
    );
    final package = await CoursePackageService().parse(
      await File(output).readAsBytes(),
      CustomCourseTransferService(
        publisherVerification: fixtureVerifier(
          TrustedPublishers.dummy.publisherId,
          TrustedPublishers.dummy.publisherName,
        ),
      ).courseFromBytes,
    );
    expect(package.mediaReferences, {reference});
    await package.discard();
  });
}
