import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';
import '../tools/sign_course.dart' as signing_tool;
import 'support/synthetic_mp3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'checked-in signed Dummy media ZIP verifies and carries its recording',
    () async {
      final verifier = fixtureVerifier(
        TrustedPublishers.dummy.publisherId,
        TrustedPublishers.dummy.publisherName,
      );
      final package = await CoursePackageService().parse(
        await File(
          'test/fixtures/publishers/dummy-signed-media.zip',
        ).readAsBytes(),
        CustomCourseTransferService(
          publisherVerification: verifier,
        ).courseFromBytes,
      );
      final reference = package.course.audioLibrary.single.filePath;
      expect(
        package.course.publisherVerificationStatus,
        PublisherVerificationStatus.verified,
      );
      expect(await package.mediaBytes(reference), syntheticMp3());
    },
  );

  test(
    'signed Publisher package installs audio and update archives and removes it',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'qql-publisher-package-',
      );
      addTearDown(() => root.delete(recursive: true));
      final media = CourseMediaStore(supportDirectory: () async => root);
      final verifier = fixtureVerifier(
        TrustedPublishers.dummy.publisherId,
        TrustedPublishers.dummy.publisherName,
      );
      final transfer = CustomCourseTransferService(
        publisherVerification: verifier,
      );
      final packages = CoursePackageService(mediaStore: media);
      final editor = CourseEditorService(
        courseStore: CourseFileStore(supportDirectory: () async => root),
        mediaStore: media,
        backupService: CourseBackupService(
          supportDirectoryProvider: () async => root,
          publisherVerification: verifier,
          mediaStore: media,
        ),
        publisherVerification: verifier,
      );
      final base = Course.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
                File(
                  'test/fixtures/publishers/dummy-signed-v1.json',
                ).readAsStringSync(),
              )
              as Map,
        ),
      );
      final recording = syntheticMp3(seed: 1);
      final reference = CourseMediaStore.referenceFor(recording, 'mp3');
      final first = await signFixture(
        Course.fromJson({
          ...base.toJson(),
          'audioMode': 'recorded',
          'audioLibrary': [
            {'id': 'clip', 'text': 'ciao', 'filePath': reference},
          ],
        }),
      );
      Uint8List courseBytes(Course course) =>
          Uint8List.fromList(utf8.encode(jsonEncode(course.toJson())));
      final firstZip = await packages.build(
        first,
        courseBytes(first),
        suppliedMedia: {reference: recording},
      );
      final imported = await packages.parse(firstZip, transfer.courseFromBytes);
      await expectLater(
        editor.installExternalOfficialUpdate(imported.course),
        throwsFormatException,
        reason: 'direct installation cannot persist missing Publisher media',
      );
      final installed = await editor.installExternalOfficialUpdate(
        imported.course,
        package: imported,
      );
      expect(installed.officialCourse.audioLibrary.single.filePath, reference);
      expect(
        await (await media.existingFile(
          first.courseId,
          reference,
        ))!.readAsBytes(),
        recording,
      );

      final second = await signFixture(
        Course.fromJson({
          ...base.toJson(),
          'officialCourseVersion': '2',
          'title': 'Updated without recording',
        }),
      );
      final secondZip = await packages.build(second, courseBytes(second));
      final update = await packages.parse(secondZip, transfer.courseFromBytes);
      final result = await editor.installExternalOfficialUpdate(
        update.course,
        package: update,
      );
      expect(result.backupPath, isNotNull);
      expect(await media.existingFile(first.courseId, reference), isNull);
      expect(
        (await editor.backupService.listOfficialBackups(
          first.courseId,
        )).single.course.audioLibrary.single.filePath,
        reference,
      );
    },
  );

  test(
    'signing tool packages only referenced media and refuses changed bytes',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'qql-publisher-signing-',
      );
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
      final recording = syntheticMp3(seed: 2);
      final reference = CourseMediaStore.referenceFor(recording, 'mp3');
      final signed = await signFixture(
        Course.fromJson({
          ...source.toJson(),
          'audioMode': 'recorded',
          'audioLibrary': [
            {'id': 'clip', 'text': 'ciao', 'filePath': reference},
          ],
        }),
      );
      final signedFile = File('${root.path}/signed.json');
      await signedFile.writeAsString(jsonEncode(signed.toJson()));
      final mediaDir = Directory('${root.path}/media')..createSync();
      final mediaFile = File(
        '${mediaDir.path}/${CourseMediaStore.fileNameOf(reference)}',
      );
      await mediaFile.writeAsBytes(recording);
      await File('${mediaDir.path}/unused.mp3').writeAsBytes([1, 2, 3]);
      final output = '${root.path}/course.zip';
      await signing_tool.packageSignedCourse(
        signedFile.path,
        mediaDir.path,
        'test/fixtures/publishers/dummy-public.der',
        output,
      );
      final verifier = fixtureVerifier(
        TrustedPublishers.dummy.publisherId,
        TrustedPublishers.dummy.publisherName,
      );
      final package = await CoursePackageService().parse(
        await File(output).readAsBytes(),
        CustomCourseTransferService(
          publisherVerification: verifier,
        ).courseFromBytes,
      );
      expect(package.mediaReferences, {reference});
      await mediaFile.writeAsBytes([0x49, 0x44, 0x33, 9]);
      await expectLater(
        signing_tool.packageSignedCourse(
          signedFile.path,
          mediaDir.path,
          'test/fixtures/publishers/dummy-public.der',
          '${root.path}/damaged.zip',
        ),
        throwsFormatException,
      );
    },
  );
}
