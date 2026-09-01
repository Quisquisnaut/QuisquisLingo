import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';

void main() {
  Course course({required String flagCode, String flagImageBase64 = ''}) =>
      Course(
        courseId: 'flag-$flagCode',
        learningLanguage: 'Test language',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Test language',
        title: 'Flag test',
        ttsLanguage: 'en-US',
        version: '1.0.0',
        flagCode: flagCode,
        flagImageBase64: flagImageBase64,
        topics: const [],
      );

  Widget app(Course value, {BoxFit fit = BoxFit.contain}) => MaterialApp(
    home: Scaffold(
      body: CourseFlagBackdrop(
        course: value,
        fallbackCode: value.flagCode,
        opacity: 1,
        fit: fit,
      ),
    ),
  );

  testWidgets('built-in flag backdrops preserve their flag aspect ratio', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final sample in [('IT', 3 / 2), ('UK', 2.0)]) {
      await tester.pumpWidget(app(course(flagCode: sample.$1)));

      final backdrop = find.byType(CourseFlagBackdrop);
      final aspectRatio = tester.widget<AspectRatio>(
        find.descendant(of: backdrop, matching: find.byType(AspectRatio)),
      );
      final flagPaint = find.descendant(
        of: backdrop,
        matching: find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is FlagPainter,
        ),
      );

      expect(aspectRatio.aspectRatio, closeTo(sample.$2, .001));
      expect(tester.getSize(flagPaint).aspectRatio, closeTo(sample.$2, .001));
      expect(tester.getSize(flagPaint).height, lessThan(900));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('custom flag backdrops contain images without cropping', (
    tester,
  ) async {
    final onePixelPng = base64Encode(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    await tester.pumpWidget(
      app(course(flagCode: 'IT', flagImageBase64: onePixelPng)),
    );

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(CourseFlagBackdrop),
        matching: find.byType(Image),
      ),
    );
    expect(image.fit, BoxFit.contain);
    expect(tester.takeException(), isNull);
  });

  testWidgets('extended backdrops preserve aspect ratio while filling', (
    tester,
  ) async {
    final onePixelPng = base64Encode(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );

    await tester.pumpWidget(
      app(
        course(flagCode: 'IT', flagImageBase64: onePixelPng),
        fit: BoxFit.cover,
      ),
    );
    final customImage = tester.widget<Image>(find.byType(Image));
    expect(customImage.fit, BoxFit.cover);

    await tester.pumpWidget(app(course(flagCode: 'IT'), fit: BoxFit.cover));
    final fittedFlag = tester.widget<FittedBox>(
      find.descendant(
        of: find.byType(CourseFlagBackdrop),
        matching: find.byType(FittedBox),
      ),
    );
    expect(fittedFlag.fit, BoxFit.cover);
    expect(tester.takeException(), isNull);
  });
}
