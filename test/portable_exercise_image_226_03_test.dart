import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/portable_exercise_image.dart';
import 'package:quisquislingo_app/widgets/portable_exercise_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('safe bundled image paths need no embedded decoding', () {
    for (final path in [
      'assets/exercise_images/character.png',
      'assets/exercise_images/hangul/ga.webp',
      'assets/exercise_images/sample-2.jpeg',
    ]) {
      expect(PortableExerciseImageService.isPortable(path), isTrue);
      expect(PortableExerciseImageService.decode(path), isNull);
    }
  });

  test('absolute, remote, traversal and malformed embedded paths fail', () {
    for (final path in [
      '',
      r'C:\images\character.png',
      '/tmp/character.png',
      'https://example.com/character.png',
      'assets/exercise_images/../character.png',
      'assets/exercise_images/%2e%2e/character.png',
      r'assets\exercise_images\character.png',
      'data:image/svg+xml;base64,PHN2Zz4=',
      'data:image/png;base64,not an image',
      'data:image/png;base64,AQID',
      'data:image/png;base64,',
    ]) {
      expect(PortableExerciseImageService.isPortable(path), isFalse);
      expect(
        () => PortableExerciseImageService.decode(path),
        throwsFormatException,
      );
    }
  });

  test('oversize embedded input is rejected without truncating', () {
    final uri =
        'data:image/png;base64,${base64Encode(Uint8List(50 * 1024 + 1))}';
    expect(
      () => PortableExerciseImageService.decode(uri),
      throwsFormatException,
    );
  });

  testWidgets(
    'Audit decoding rejects truncated containers and oversized embedded dimensions',
    (tester) async {
      final png = (await tester.runAsync(() => _png()))!;
      for (final broken in [
        png.sublist(0, 24),
        png.sublist(0, png.length - 1),
      ]) {
        final uri = 'data:image/png;base64,${base64Encode(broken)}';
        expect(PortableExerciseImageService.isPortable(uri), isFalse);
        expect(
          () => PortableExerciseImageService.decode(uri),
          throwsFormatException,
        );
      }
      final tooWide = (await tester.runAsync(() => _png(width: 4097)))!;
      expect(
        PortableExerciseImageService.isPortable(
          'data:image/png;base64,${base64Encode(tooWide)}',
        ),
        isFalse,
      );
      expect(
        PortableExerciseImageService.isPortable(
          'data:image/jpeg;base64,${base64Encode([255, 216, 255, 192])}',
        ),
        isFalse,
      );
    },
  );

  testWidgets(
    'existing WebP image passes portable container and pixel validation',
    (tester) async {
      await tester.runAsync(() async {
        final source = File('assets/exercise_images/bus.webp');
        final bytes = await source.readAsBytes();
        final uri = await PortableExerciseImageService.fromFile(source);
        expect(uri, startsWith('data:image/webp;base64,'));
        expect(PortableExerciseImageService.decode(uri), bytes);
        final broken =
            'data:image/webp;base64,${base64Encode(bytes.sublist(0, bytes.length - 1))}';
        expect(PortableExerciseImageService.isPortable(broken), isFalse);
      });
    },
  );

  testWidgets('import preserves exact PNG bytes and survives JSON roundtrip', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_portable_image_',
      );
      try {
        final bytes = await _png();
        final file = await File(
          '${directory.path}/character.png',
        ).writeAsBytes(bytes);
        final uri = await PortableExerciseImageService.fromFile(file);
        final restored =
            jsonDecode(jsonEncode({'asset': uri})) as Map<String, dynamic>;
        expect(
          PortableExerciseImageService.decode(restored['asset'] as String),
          bytes,
        );
        expect(await file.readAsBytes(), bytes);
        expect(directory.listSync(), hasLength(1));
        expect(
          PortableExerciseImageService.isPortable(
            uri.replaceFirst('image/png', 'image/jpeg'),
          ),
          isFalse,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    });
  });

  testWidgets('import rejects oversize and undecodable source files', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_invalid_image_',
      );
      try {
        final file = File('${directory.path}/character.png');
        await file.writeAsBytes(Uint8List(50 * 1024 + 1));
        await expectLater(
          PortableExerciseImageService.fromFile(file),
          throwsFormatException,
        );
        final bytes = await _png();
        await file.writeAsBytes(bytes.sublist(0, 24));
        await expectLater(
          PortableExerciseImageService.fromFile(file),
          throwsFormatException,
        );
        expect(await file.length(), 24);
        await file.writeAsBytes(await _png(width: 4097));
        await expectLater(
          PortableExerciseImageService.fromFile(file),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'dimension limit',
              contains('4096'),
            ),
          ),
        );
      } finally {
        await directory.delete(recursive: true);
      }
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'embedded image renders unchanged in $brightness at narrow width',
      (tester) async {
        final bytes = await tester.runAsync(() => _png());
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Center(
              child: SizedBox(
                width: 80,
                child: PortableExerciseImage(
                  asset: 'data:image/png;base64,${base64Encode(bytes!)}',
                  width: 64,
                  height: 64,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(find.byType(Image));
        expect((image.image as MemoryImage).bytes, bytes);
        expect(image.color, isNull);
        expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('invalid assets render a bounded fallback without file access', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PortableExerciseImage(
          asset: r'C:\private\character.png',
          width: 64,
          height: 64,
        ),
      ),
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<Uint8List> _png({int width = 2}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xff1245aa),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, 2);
  try {
    return (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}
