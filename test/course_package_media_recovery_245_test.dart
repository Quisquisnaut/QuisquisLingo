import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporary;
  late CourseMediaStore mediaStore;
  late Course course;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('qql_package_recovery_');
    mediaStore = CourseMediaStore(supportDirectory: () async => temporary);
    final raw =
        jsonDecode(
              await File(
                'demo_courses/italian_demo_2_pick_the_translation.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;
    course = Course.fromJson(raw);
  });

  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  ({CoursePackage package, String reference}) packageWithMedia() {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    final reference = CourseMediaStore.referenceFor(bytes, 'mp3');
    return (
      package: CoursePackage(course, Uint8List(0), {
        reference: bytes,
      }, mediaStore: mediaStore),
      reference: reference,
    );
  }

  test('default save failure rolls back newly installed media', () async {
    final item = packageWithMedia();
    final failure = StateError('save failed');

    await expectLater(
      item.package.withInstalledMedia<void>(
        'new-course',
        () async => throw failure,
      ),
      throwsA(same(failure)),
    );

    expect(await mediaStore.existingFile('new-course', item.reference), isNull);
  });

  test('retention callback keeps media after save failure', () async {
    final item = packageWithMedia();
    final failure = StateError('save may have committed');
    var checked = false;

    await expectLater(
      item.package.withInstalledMedia<void>(
        'new-course',
        () async => throw failure,
        retainCreatedOnFailure: () async {
          checked = true;
          expect(
            await mediaStore.existingFile('new-course', item.reference),
            isNotNull,
          );
          return true;
        },
      ),
      throwsA(same(failure)),
    );

    expect(checked, isTrue);
    expect(
      await mediaStore.existingFile('new-course', item.reference),
      isNotNull,
    );
  });

  test(
    'failed retention read preserves media and original save error',
    () async {
      final item = packageWithMedia();
      final failure = StateError('save may have committed');
      var checked = false;

      await expectLater(
        item.package.withInstalledMedia<void>(
          'new-course',
          () async => throw failure,
          retainCreatedOnFailure: () async {
            checked = true;
            throw FileSystemException('stored Course read failed');
          },
        ),
        throwsA(same(failure)),
      );

      expect(checked, isTrue);
      expect(
        await mediaStore.existingFile('new-course', item.reference),
        isNotNull,
      );
    },
  );
}
