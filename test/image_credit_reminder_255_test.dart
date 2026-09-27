import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/import/import_result.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';
import 'package:quisquislingo_app/widgets/course_flag_picker.dart';
import 'package:quisquislingo_app/widgets/exercise_image_field.dart';
import 'package:quisquislingo_app/widgets/image_credit_reminder.dart';
import 'package:quisquislingo_app/widgets/import_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/quick_folders.dart';

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff3366cc),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Build 255 Revision 7: a picture whose maker QQL does not know reminds its
/// author to credit it in Course Info › Media credits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('an imported Exercise image brings the reminder', (tester) async {
    final support = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_image_credit_'),
    ))!;
    addTearDown(() => support.delete(recursive: true));
    final folder = (await tester.runAsync(
      () => quickFolder(QqlStorageRole.imageImports),
    ))!;
    final picture = File('${folder.path}/credit_reminder.png');
    await tester.runAsync(() async => picture.writeAsBytes(await _png(64, 64)));
    addTearDown(() async {
      if (await picture.exists()) await picture.delete();
    });
    final course = Course(
      courseId: 'image-credit-course',
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Image credit course',
      ttsLanguage: 'it-IT',
      lessons: const [],
    );
    final changes = <ExerciseImageChange>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExerciseImageField(
              course: course,
              asset: '',
              sharedSource: null,
              readOnly: false,
              onChanged: changes.add,
              mediaStore: CourseMediaStore(
                supportDirectory: () async => support,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Import custom image'));
    await tester.pumpUntilFileIoState(() => changes.isNotEmpty);
    expect(changes.single.asset, startsWith('media:'));
    expect(find.text(imageCreditReminder), findsOneWidget);
  });

  testWidgets('a custom Course flag carries the reminder', (tester) async {
    final flag = base64Encode((await tester.runAsync(() => _png(96, 64)))!);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseFlagSelector(
            selection: CourseFlagSelection.customImage(flag),
            languageName: 'Italian',
            languageTag: 'it',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const Key('course-flag-credit-reminder')))
          .data,
      imageCreditReminder,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseFlagSelector(
            selection: const CourseFlagSelection.automatic(),
            languageName: 'Italian',
            languageTag: 'it',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('course-flag-credit-reminder')), findsNothing);
  });

  testWidgets('an import summary shows its note under the outcomes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => showImportSummary(
              context,
              title: 'Images added to this Course',
              items: [
                ImportItemResult('photo.png', ImportItemOutcome.imported),
              ],
              note: imageCreditReminder,
            ),
            child: const Text('Summary'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('import-summary-note'))).data,
      imageCreditReminder,
    );
  });
}
