import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('recorded audio resolution', () {
    final service = RecordedAudioService();

    test('matches case and edge punctuation while preferring longest text', () {
      const clips = <CourseAudioClip>[
        CourseAudioClip(id: 'short', text: 'buon', filePath: 'short.mp3'),
        CourseAudioClip(id: 'long', text: 'buon giorno', filePath: 'long.mp3'),
        CourseAudioClip(id: 'tail', text: 'a tutti', filePath: 'tail.mp3'),
      ];

      final result = service.segment('BUON giorno, a tutti!', clips);

      expect(result?.map((clip) => clip.id), <String>['long', 'tail']);
    });

    test('returns no recording for incomplete coverage or a missing file', () {
      const incomplete = <CourseAudioClip>[
        CourseAudioClip(id: 'hello', text: 'hello', filePath: 'hello.mp3'),
      ];
      const missingFile = CourseAudioClip(
        id: 'missing',
        text: 'hello',
        filePath: 'does-not-exist.mp3',
      );

      expect(service.segment('hello world', incomplete), isNull);
      expect(service.sourceForClip(missingFile), isNull);
    });
  });

  test(
    'Course JSON stores audio metadata paths without physical MP3 bytes',
    () async {
      final temp = await Directory.systemTemp.createTemp('qql_audio_json_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final mp3Bytes = utf8.encode(
        'PHYSICAL_MP3_BYTES_MUST_REMAIN_OUTSIDE_THE_COURSE_JSON',
      );
      final mp3 = File('${temp.path}${Platform.pathSeparator}exact-words.mp3');
      await mp3.writeAsBytes(mp3Bytes, flush: true);
      final course = _audioCourse(mp3.path);

      final encoded = jsonEncode(course.toJson());
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['audioMode'], 'hybrid');
      expect(decoded['audioLibrary'], <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'clip-1',
          'text': 'Buon giorno',
          'filePath': mp3.path,
        },
      ]);
      expect(encoded, isNot(contains(base64Encode(mp3Bytes))));
      expect(encoded, isNot(contains('PHYSICAL_MP3_BYTES_MUST_REMAIN')));
      expect(await mp3.readAsBytes(), mp3Bytes);
    },
  );

  test('existing directory seam remains shared by export and import', () async {
    final temp = await Directory.systemTemp.createTemp('qql_transfer_seam_');
    addTearDown(() async {
      if (await temp.exists()) {
        await temp.delete(recursive: true);
      }
    });
    final service = CustomCourseTransferService(directory: () async => temp);

    expect((await service.transferDirectory()).path, temp.path);
    expect((await service.importDirectory()).path, temp.path);
    expect(
      await service.importFilePath(),
      '${temp.path}${Platform.pathSeparator}import.json',
    );
  });

  test(
    'separate injected directories route export and import independently',
    () async {
      final temp = await Directory.systemTemp.createTemp('qql_transfer_split_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final exports = Directory(
        '${temp.path}${Platform.pathSeparator}test-exports',
      );
      final imports = Directory(
        '${temp.path}${Platform.pathSeparator}test-imports',
      );
      final service = CustomCourseTransferService(
        directory: () async => exports,
        importDirectory: () async => imports,
      );

      expect((await service.transferDirectory()).path, exports.path);
      expect((await service.importDirectory()).path, imports.path);
      expect(
        await service.importFilePath(),
        '${imports.path}${Platform.pathSeparator}import.json',
      );
      expect(await exports.exists(), isTrue);
      expect(await imports.exists(), isTrue);
    },
  );

  test(
    'default documents paths export to Exports and import from Imports without changing source files',
    () async {
      const pathProviderChannel = MethodChannel(
        'plugins.flutter.io/path_provider',
      );
      final documents = await Directory.systemTemp.createTemp('qql_documents_');
      final mp3 = File(
        '${documents.path}${Platform.pathSeparator}physical-audio.mp3',
      );
      final mp3Bytes = utf8.encode('physical mp3 payload outside course json');
      await mp3.writeAsBytes(mp3Bytes, flush: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            pathProviderChannel,
            (MethodCall call) async => documents.path,
          );
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, null);
        if (await documents.exists()) {
          await documents.delete(recursive: true);
        }
      });
      final service = CustomCourseTransferService();
      final expectedExports = Directory(
        '${documents.path}${Platform.pathSeparator}QuisquisLingo'
        '${Platform.pathSeparator}Exports',
      );
      final expectedImports = Directory(
        '${documents.path}${Platform.pathSeparator}QuisquisLingo'
        '${Platform.pathSeparator}Imports',
      );
      final course = _audioCourse(mp3.path);

      final exportPath = await service.exportCourse(course);
      final exportFile = File(exportPath);
      final exportedBytes = await exportFile.readAsBytes();
      final importPath = await service.importFilePath();
      final importFile = await exportFile.copy(importPath);
      final imported = await service.importCourse();

      expect(exportFile.parent.path, expectedExports.path);
      expect(importFile.parent.path, expectedImports.path);
      expect(exportFile.path, isNot(importFile.path));
      expect(await exportFile.readAsBytes(), exportedBytes);
      expect(await importFile.readAsBytes(), exportedBytes);
      expect(imported.toJson(), course.toJson());
      expect(await mp3.readAsBytes(), mp3Bytes);
      expect(await exportFile.exists(), isTrue);
      expect(await importFile.exists(), isTrue);
    },
  );
}

Course _audioCourse(String mp3Path) {
  return Course(
    courseId: 'audio-import-paths-course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Audio paths course',
    ttsLanguage: 'it-IT',
    audioMode: 'hybrid',
    audioLibrary: <CourseAudioClip>[
      CourseAudioClip(id: 'clip-1', text: 'Buon giorno', filePath: mp3Path),
    ],
    lessons: const <Lesson>[],
  );
}
