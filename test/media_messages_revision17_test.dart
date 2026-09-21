import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_service.dart';
import 'package:quisquislingo_app/services/import/image_validator.dart';
import 'package:quisquislingo_app/services/import/mp3_validator.dart';

import 'support/dialog_test_course.dart';

void main() {
  test('a recording renamed as an image is identified', () {
    final bytes = Uint8List.fromList([0x49, 0x44, 0x33, 3, 0, 0, 0, 0, 0, 0]);
    expect(
      () => ImageValidator.inspect(bytes, ImageProfile.exerciseImage),
      throwsA(isA<ImageValidationException>().having(
        (error) => error.message,
        'message',
        allOf(contains('MP3'), contains('image')),
      )),
    );
  });

  test('a picture renamed as an MP3 is identified', () {
    final bytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]);
    expect(
      () => Mp3Validator.inspect(bytes),
      throwsA(isA<Mp3ValidationException>().having(
        (error) => error.message,
        'message',
        allOf(contains('PNG'), contains('MP3')),
      )),
    );
  });

  test('a web page renamed as an image is identified', () {
    final bytes = Uint8List.fromList(utf8.encode('<!doctype html><title>Download</title>'));
    expect(
      () => ImageValidator.inspect(bytes, ImageProfile.exerciseImage),
      throwsA(isA<ImageValidationException>().having(
        (error) => error.message,
        'message',
        allOf(contains('web page'), contains('Download')),
      )),
    );
  });

  testWidgets('Audio Library shows MP3 actions only in recorded modes', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AudioLibraryScreen(course: dialogTestCourse())));
    await tester.pump();
    expect(find.text('On-Device TTS'), findsOneWidget);
    expect(find.textContaining('No MP3 files are needed'), findsOneWidget);
    expect(find.text('Import MP3'), findsNothing);
    expect(find.text('Check unused MP3 files'), findsNothing);
    expect(find.byKey(const Key('open-mp3-from')), findsNothing);

    await tester.tap(find.text('On-Device TTS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recorded MP3 only').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('there is no TTS fallback'), findsOneWidget);
    expect(find.text('Import MP3'), findsOneWidget);
    expect(find.text('Check unused MP3 files'), findsOneWidget);
    expect(find.byKey(const Key('open-mp3-from')), findsOneWidget);

    await tester.tap(find.text('Recorded MP3 only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hybrid: MP3 + TTS fallback').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('this device’s text-to-speech voice'), findsOneWidget);
    expect(find.text('Import MP3'), findsOneWidget);
    expect(find.text('Check unused MP3 files'), findsOneWidget);
    expect(find.byKey(const Key('open-mp3-from')), findsOneWidget);
  });

  test('missing Image Bank manifest explains how to create it and where to read more', () async {
    final directory = await Directory.systemTemp.createTemp('qql-manifest-message-');
    try {
      final zip = File('${directory.path}${Platform.pathSeparator}bank.zip');
      await zip.writeAsBytes(ZipEncoder().encode(Archive()
        ..addFile(ArchiveFile.bytes('picture.png', [1, 2, 3]))));
      await expectLater(
        ImageBankService().readBank(zip),
        throwsA(isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('small JSON file'),
            contains('Create it as UTF-8 text'),
            contains('Editor Help > Image Bank'),
          ),
        )),
      );
    } finally {
      await directory.delete(recursive: true);
    }
  });

  test('Course package names a PDF masquerading as a ZIP', () async {
    await expectLater(
      CoursePackageService().parse(
        Uint8List.fromList(utf8.encode('%PDF-1.7\n')),
        (bytes, name) async => dialogTestCourse(),
      ),
      throwsA(isA<FormatException>().having(
        (error) => error.message,
        'message',
        allOf(contains('PDF document'), contains('Course package ZIP')),
      )),
    );
  });

  test('Lesson icon and flag identify an MP3 renamed as a picture', () async {
    final bytes = Uint8List.fromList([0x49, 0x44, 0x33, 3, 0, 0, 0, 0, 0, 0]);
    for (final load in <Future<Object> Function()>[
      () => LessonIconService().prepareIcon(bytes, assetId: 'test'),
      () => CourseFlagService().prepareFlag(bytes),
    ]) {
      await expectLater(
        load(),
        throwsA(isA<ImageValidationException>().having(
          (error) => error.message,
          'message',
          allOf(contains('MP3 recording'), contains('not an image')),
        )),
      );
    }
  });
}
