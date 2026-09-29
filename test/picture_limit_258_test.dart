import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/exercise_image_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/import/image_validator.dart';
import 'package:quisquislingo_app/services/portable_exercise_image.dart';

/// Build 258 Revision 1 (owner decision, 29 September 2026): a Course
/// picture may be up to 300 KB (it was 50 KB), stored as Course media, in
/// the Shared Image Library or an Image Bank; a picture embedded in
/// `course.json` as a `data:` URI keeps 50 KB.

/// A 512-pixel-wide PNG whose first [noisyRows] rows are random, so its
/// size grows with them (about 1.8 KB per noisy row).
Future<Uint8List> _png(int noisyRows) async {
  final random = Random(11);
  final pixels = Uint8List(512 * 512 * 4);
  for (var i = 0; i < pixels.length; i += 4) {
    final noisy = i < 512 * 4 * noisyRows;
    pixels[i] = noisy ? random.nextInt(256) : 30;
    pixels[i + 1] = noisy ? random.nextInt(256) : 90;
    pixels[i + 2] = noisy ? random.nextInt(256) : 160;
    pixels[i + 3] = 255;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: 512,
    height: 512,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  late Directory temp;
  late CourseMediaStore media;
  late Uint8List medium;
  late Uint8List large;

  setUpAll(() async {
    medium = await _png(100);
    large = await _png(220);
  });
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('qql_picture_limit_');
    media = CourseMediaStore(supportDirectory: () async => temp);
  });
  tearDown(() => temp.delete(recursive: true));

  test('one 300 KB limit for Course pictures, 50 KB inside course.json', () {
    expect(ImageProfile.courseImageMaxBytes, 300 * 1024);
    expect(ImageProfile.exerciseImage.maxBytes, 300 * 1024);
    expect(CourseMediaStore.maxImageBytes, 300 * 1024);
    expect(ExerciseImageService.maxImageBytes, 300 * 1024);
    expect(ImageBankService.maxImageBytes, 300 * 1024);
    expect(ImageProfile.portableImage.maxBytes, 50 * 1024);
    expect(PortableExerciseImageService.maxImageBytes, 50 * 1024);
  });

  test('a picture between 50 and 300 KB is a Course picture now', () async {
    expect(medium.length, greaterThan(50 * 1024));
    expect(medium.length, lessThan(300 * 1024));
    final checked = await ImageValidator.validate(
      medium,
      ImageProfile.exerciseImage,
    );
    final reference = await media.addValidated('course_a', checked);
    expect(await media.existingFile('course_a', reference), isNotNull);
  });

  test('a picture over 300 KB is refused', () async {
    expect(large.length, greaterThan(300 * 1024));
    await expectLater(
      media.addBytes('course_a', large, 'png'),
      throwsFormatException,
    );
    await expectLater(
      ImageValidator.validate(large, ImageProfile.exerciseImage),
      throwsFormatException,
    );
  });

  test('an embedded data: picture still keeps 50 KB', () async {
    await expectLater(
      PortableExerciseImageService.fromBytes(medium),
      throwsFormatException,
    );
    await expectLater(
      ImageValidator.validate(medium, ImageProfile.portableImage),
      throwsFormatException,
    );
  });
}
