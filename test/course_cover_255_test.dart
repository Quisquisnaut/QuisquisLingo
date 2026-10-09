import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_cover_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/image_credit.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';
import 'package:quisquislingo_app/widgets/course_artwork.dart';
import 'package:quisquislingo_app/widgets/course_cover_field.dart';
import 'package:quisquislingo_app/widgets/cover_crop_dialog.dart';
import 'package:quisquislingo_app/widgets/image_credit_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/quick_folders.dart';

/// A PNG whose left half is red and right half blue.
Future<Uint8List> _halves(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
    ui.Paint()..color = const ui.Color(0xffff0000),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(width / 2, 0, width / 2, height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff0000ff),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// A 512 × 512 PNG well above the 50 KB limit of other Course images: its
/// top rows are noise, which PNG cannot compress.
Future<Uint8List> _detailedCover() async {
  final random = Random(7);
  final pixels = Uint8List(512 * 512 * 4);
  for (var i = 0; i < pixels.length; i += 4) {
    // Enough noise to pass the ordinary 300 KB limit (Build 258 Revision 1)
    // and stay under the cover's 1 MB.
    final noisy = i < 512 * 4 * 220;
    pixels[i] = noisy ? random.nextInt(256) : 40;
    pixels[i + 1] = noisy ? random.nextInt(256) : 120;
    pixels[i + 2] = noisy ? random.nextInt(256) : 200;
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

Future<(int, int, Color Function(int x, int y))> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final width = image.width;
  final height = image.height;
  image.dispose();
  codec.dispose();
  Color at(int x, int y) {
    final offset = (y * width + x) * 4;
    return Color.fromARGB(
      data.getUint8(offset + 3),
      data.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
    );
  }

  return (width, height, at);
}

Course _course(String id, {String cover = ''}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  courseVersion: '1',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Cover $id',
  ttsLanguage: 'it-IT',
  flagCode: 'IT',
  coverImage: cover,
  lessons: const [],
);

/// Build 255 Revision 6: the Course Info Editor sets a cover from any
/// picture, and only the cover may reach 1 MB.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late CourseMediaStore media;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('qql_course_cover_');
    media = CourseMediaStore(supportDirectory: () async => temp);
  });
  tearDown(() => temp.delete(recursive: true));

  group('CourseCoverService.prepare', () {
    test('keeps a ready 512 × 512 picture as it is', () async {
      final ready = await File(
        'test/fixtures/import/valid_cover.png',
      ).readAsBytes();
      final cover = await CourseCoverService.prepare(ready);
      expect(cover.extension, 'png');
      expect(cover.bytes, ready);
    });

    test('crops the centred square and scales it to 512 × 512', () async {
      // 300 × 200: the centred square runs from x = 50 to x = 250, so red
      // (x < 150) fills its left half and blue its right half.
      final cover = await CourseCoverService.prepare(await _halves(300, 200));
      expect(cover.extension, 'png');
      final (width, height, at) = await _decode(cover.bytes);
      expect((width, height), (512, 512));
      expect(at(60, 256), const Color(0xffff0000));
      expect(at(450, 256), const Color(0xff0000ff));
      await CoursePackageService.checkCover(
        CourseMediaStore.referenceFor(cover.bytes, 'png'),
        cover.bytes,
      );
    });

    test('Revision 7: crops the square its author chose', () async {
      final source = await _halves(300, 200);
      // Red runs from x = 0 to 150, blue from 150 to 300.
      final red = await CourseCoverService.prepare(
        source,
        crop: const Rect.fromLTWH(20, 50, 100, 100),
      );
      final (width, height, redAt) = await _decode(red.bytes);
      expect((width, height), (512, 512));
      expect(redAt(20, 20), const Color(0xffff0000));
      expect(redAt(490, 490), const Color(0xffff0000));
      final blue = await CourseCoverService.prepare(
        source,
        // Past the right edge: kept inside the picture.
        crop: const Rect.fromLTWH(260, 150, 100, 100),
      );
      final (_, _, blueAt) = await _decode(blue.bytes);
      expect(blueAt(20, 20), const Color(0xff0000ff));
      expect(blueAt(490, 490), const Color(0xff0000ff));
    });

    test('Revision 7: a ready picture is kept only when wholly chosen', () async {
      final ready = await File(
        'test/fixtures/import/valid_cover.png',
      ).readAsBytes();
      final whole = await CourseCoverService.prepare(
        ready,
        crop: const Rect.fromLTWH(0, 0, 512, 512),
      );
      expect(whole.bytes, ready);
      final part = await CourseCoverService.prepare(
        ready,
        crop: const Rect.fromLTWH(0, 0, 256, 256),
      );
      expect(part.bytes, isNot(ready));
      final (width, height, _) = await _decode(part.bytes);
      expect((width, height), (512, 512));
    });

    test('a small picture is enlarged to 512 × 512', () async {
      final cover = await CourseCoverService.prepare(await _halves(64, 64));
      final (width, height, _) = await _decode(cover.bytes);
      expect((width, height), (512, 512));
    });

    test('refuses what is not a picture, or is over 10 MB', () async {
      await expectLater(
        CourseCoverService.prepare(
          Uint8List.fromList(utf8.encode('not a picture')),
        ),
        throwsFormatException,
      );
      await expectLater(
        CourseCoverService.prepare(Uint8List(10 * 1024 * 1024 + 1)),
        throwsFormatException,
      );
    });
  });

  group('Revision 7: the credit QQL knows for a library picture', () {
    ExerciseImageMetadata picture({
      String origin = 'local',
      String asset = 'C:/shared/image_local_1.png',
      ImageAttribution? attribution,
    }) => ExerciseImageMetadata(
      id: 'picture',
      label: 'Red apple',
      category: 'food',
      tags: const [],
      assetPath: asset,
      origin: origin,
      attribution: attribution,
    );

    test('a QQL picture is an original QuisquisLingo asset', () {
      expect(
        knownImageCredit(
          picture(origin: 'bundled', asset: 'assets/exercise_images/a.webp'),
          appliesTo: 'Course cover',
        ),
        const CourseMediaAttribution(
          author: 'QuisquisLingo',
          license: 'Original QuisquisLingo asset',
          title: 'Red apple',
          source: 'QuisquisLingo Flat Image Bank',
          appliesTo: 'Course cover',
        ),
      );
    });

    test('a library picture brings its recorded attribution', () {
      expect(
        knownImageCredit(
          picture(
            attribution: const ImageAttribution(
              author: 'Ada',
              license: 'CC BY 4.0',
              title: 'Apple study',
              source: 'example.org/apple',
            ),
          ),
          appliesTo: 'Course cover',
        ),
        const CourseMediaAttribution(
          author: 'Ada',
          license: 'CC BY 4.0',
          title: 'Apple study',
          source: 'example.org/apple',
          appliesTo: 'Course cover',
        ),
      );
    });

    test('a picture whose maker is unknown has none', () {
      expect(knownImageCredit(picture(), appliesTo: 'Course cover'), isNull);
    });
  });

  group('the 1 MB limit belongs to the cover only', () {
    late Uint8List detailed;
    setUpAll(() async => detailed = await _detailedCover());

    test('the store keeps a large cover, not a large ordinary image', () async {
      expect(detailed.length, greaterThan(CourseMediaStore.maxImageBytes));
      expect(detailed.length, lessThan(CourseMediaStore.maxCoverBytes));
      await expectLater(
        media.addBytes('course_a', detailed, 'png'),
        throwsFormatException,
      );
      final reference = await CourseCoverService(
        mediaStore: media,
      ).store('course_a', detailed);
      expect(reference, CourseMediaStore.referenceFor(detailed, 'png'));
      expect(await media.existingFile('course_a', reference), isNotNull);

      // Fork, Copy and Merge copy the destination's cover under its limit.
      await media.copyReferences('course_a', 'course_b', [
        reference,
      ], cover: reference);
      expect(await media.existingFile('course_b', reference), isNotNull);
      await expectLater(
        media.copyReferences('course_a', 'course_c', [reference]),
        throwsFormatException,
      );
    });

    test('a Course package exports and imports its large cover', () async {
      final packages = CoursePackageService(mediaStore: media);
      final reference = await CourseCoverService(
        mediaStore: media,
      ).store('course_package_cover', detailed);
      final course = _course('course_package_cover', cover: reference);
      final json = Uint8List.fromList(utf8.encode(jsonEncode(course.toJson())));
      final zip = await packages.build(course, json);
      final imported = await packages.parse(
        zip,
        (bytes, _) async => Course.fromJson(jsonDecode(utf8.decode(bytes))),
      );
      expect(imported.course.coverImage, reference);
      await imported.withInstalledMedia('destination', () async => null);
      expect(await media.existingFile('destination', reference), isNotNull);
      await imported.discard();
    });
  });

  testWidgets('Quick Import makes a cover and Remove cover clears it', (
    tester,
  ) async {
    final folder = (await tester.runAsync(
      () => quickFolder(QqlStorageRole.imageImports),
    ))!;
    final source = (await tester.runAsync(() => _halves(300, 200)))!;
    await tester.runAsync(
      () => File('${folder.path}/landscape.png').writeAsBytes(source),
    );
    addTearDown(() async {
      final file = File('${folder.path}/landscape.png');
      if (await file.exists()) await file.delete();
    });
    final course = _course('course_cover_field');
    var cover = '';
    CourseMediaAttribution? credit;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CourseCoverField(
              courseId: course.courseId,
              course: course,
              cover: cover,
              mediaStore: media,
              onChanged: (choice) => setState(() {
                cover = choice.cover;
                credit = choice.credit;
              }),
            ),
          ),
        ),
      ),
    );
    expect(find.text('No cover: only the flag is shown.'), findsOneWidget);
    expect(find.byKey(const Key('course-cover-remove')), findsNothing);

    await tester.tap(find.byKey(const Key('course-cover-quick-import')));
    // Revision 7: the author chooses the square before the cover is made.
    final confirm = find.byKey(const Key('cover-crop-confirm'));
    await tester.pumpUntilFileIoState(() => confirm.evaluate().isNotEmpty);
    await tester.tap(confirm);
    await tester.pumpUntilFileIoState(() => cover.isNotEmpty);
    expect(cover, startsWith('media:'));
    expect(cover, endsWith('.png'));
    final stored = (await tester.runAsync(
      () => media.existingFile(course.courseId, cover),
    ))!;
    final (width, height, _) = (await tester.runAsync(
      () async => _decode(await stored.readAsBytes()),
    ))!;
    expect((width, height), (512, 512));
    await tester.pump();
    expect(find.byKey(const Key('course-cover-preview-image')), findsOneWidget);
    // A picture from a file: QQL does not know its maker.
    expect(credit, isNull);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('course-cover-credit-note')))
          .data,
      imageCreditReminder,
    );

    await tester.tap(find.byKey(const Key('course-cover-remove')));
    await tester.pump();
    expect(cover, isEmpty);
    expect(find.text('No cover: only the flag is shown.'), findsOneWidget);
  });

  testWidgets('Revision 7: the crop dialog moves, resizes and resets the '
      'square', (tester) async {
    final source = (await tester.runAsync(() => _halves(300, 200)))!;
    Rect? chosen;
    var closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              closed = false;
              chosen = await showCoverCropDialog(
                context,
                bytes: source,
                width: 300,
                height: 200,
              );
              closed = true;
            },
            child: const Text('Crop'),
          ),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.text('Crop'));
      await tester.pumpAndSettle();
    }

    Future<void> close(String key) async {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    }

    // In small steps, like a real pointer: the recognizer moves nothing
    // until the drag is past its slop.
    Future<void> dragBy(Offset start, Offset offset) async {
      final gesture = await tester.startGesture(start);
      for (var step = 0; step < 10; step++) {
        await gesture.moveBy(offset / 10);
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();
    }

    // The centred square, as large as the picture allows.
    await open();
    await close('cover-crop-confirm');
    expect(chosen, const Rect.fromLTWH(50, 0, 200, 200));

    // Smallest size keeps the centre; a long drag stops at the edge.
    await open();
    final slider = tester.widget<Slider>(
      find.byKey(const Key('cover-crop-size')),
    );
    expect(slider.min, 40);
    expect(slider.max, 200);
    slider.onChanged!(40);
    await tester.pump();
    // Away from the corner handle, which sits on the square's lower right.
    await dragBy(
      tester.getTopLeft(find.byKey(const Key('cover-crop-square'))) +
          const Offset(6, 6),
      const Offset(-500, 0),
    );
    await close('cover-crop-confirm');
    expect(chosen, const Rect.fromLTWH(0, 80, 40, 40));

    // The corner makes it larger again; Reset returns to the centred square.
    await open();
    tester
        .widget<Slider>(find.byKey(const Key('cover-crop-size')))
        .onChanged!(40);
    await tester.pump();
    await dragBy(
      tester.getCenter(find.byKey(const Key('cover-crop-corner'))),
      const Offset(60, 60),
    );
    expect(
      tester.widget<Slider>(find.byKey(const Key('cover-crop-size'))).value,
      greaterThan(40),
    );
    await tester.tap(find.byKey(const Key('cover-crop-reset')));
    await tester.pump();
    await close('cover-crop-confirm');
    expect(chosen, const Rect.fromLTWH(50, 0, 200, 200));

    await open();
    await close('cover-crop-cancel');
    expect(chosen, isNull);
  });

  testWidgets(
    'Revision 7: a cover whose credit QQL knows fills Media credits',
    (tester) async {
      const profileId = '31111111-1111-4111-8111-111111111112';
      final profiles = ProfileService();
      await profiles.createProfile('Author', learnerProfileId: profileId);
      await profiles.setActiveProfileById(profileId);
      await SettingsService().markAudioOrphanCheckRun('IT');
      const existing = CourseMediaAttribution(
        author: 'Someone',
        license: 'CC0',
        appliesTo: 'Lesson icons',
      );
      final course = Course(
        courseId: 'cover-credit-course',
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: profileId,
          displayName: 'Author',
        ),
        maintainer: const CourseMaintainer(profileId),
        publicationState: PublicationState.published,
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Cover credit course',
        ttsLanguage: 'it-IT',
        courseVersion: '1',
        mediaAttributions: const [existing],
        lessons: const [],
      );
      await SettingsService().setCourseEditorMode(
        course.courseId,
        CourseEditorMode.edit,
      );
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(
            course: course,
            access: CourseAccessPolicy.evaluate(course, profileId: profileId),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('course-editor-course-info')));
      await tester.pumpAndSettle();

      String row(String field, int index) => tester
          .widget<TextField>(
            find.byKey(ValueKey('course-info-media-$field-$index')),
          )
          .controller!
          .text;
      int rows() => find
          .byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'course-info-media-author-',
                ),
          )
          .evaluate()
          .length;
      void choose(CourseMediaAttribution? credit) => tester
          .widget<CourseCoverField>(find.byKey(const Key('course-info-cover')))
          .onChanged((
            cover: credit == null ? '' : 'media:${'c' * 64}.png',
            credit: credit,
          ));

      const qql = CourseMediaAttribution(
        author: 'QuisquisLingo',
        license: 'Original QuisquisLingo asset',
        title: 'Red apple',
        source: 'QuisquisLingo Flat Image Bank',
        appliesTo: 'Course cover',
      );
      choose(qql);
      await tester.pump();
      expect(rows(), 2);
      expect(row('author', 0), 'Someone');
      expect(row('author', 1), 'QuisquisLingo');
      expect(row('license', 1), 'Original QuisquisLingo asset');
      expect(row('title', 1), 'Red apple');
      expect(row('source', 1), 'QuisquisLingo Flat Image Bank');
      expect(row('applies-to', 1), 'Course cover');

      // The next cover replaces the credit the last one added.
      const ada = CourseMediaAttribution(
        author: 'Ada',
        license: 'CC BY 4.0',
        appliesTo: 'Course cover',
      );
      choose(ada);
      await tester.pump();
      expect(rows(), 2);
      expect(row('author', 1), 'Ada');

      // A credit the author changed is theirs and stays.
      await tester.enterText(
        find.byKey(const ValueKey('course-info-media-title-1')),
        'Portrait',
      );
      choose(null);
      await tester.pump();
      expect(rows(), 2);
      expect(row('title', 1), 'Portrait');
      expect(row('author', 0), 'Someone');
    },
  );

  testWidgets(
    'the Course Info Editor cover shows in the header and is confirmed',
    (tester) async {
      const profileId = '31111111-1111-4111-8111-111111111111';
      final profiles = ProfileService();
      await profiles.createProfile('Author', learnerProfileId: profileId);
      await profiles.setActiveProfileById(profileId);
      await SettingsService().markAudioOrphanCheckRun('IT');
      final course = Course(
        courseId: 'cover-editor-course',
        originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
          profileId: profileId,
          displayName: 'Author',
        ),
        maintainer: const CourseMaintainer(profileId),
        publicationState: PublicationState.published,
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Cover editor course',
        ttsLanguage: 'it-IT',
        courseVersion: '1',
        lessons: const [],
      );
      await SettingsService().setCourseEditorMode(
        course.courseId,
        CourseEditorMode.edit,
      );
      await tester.runAsync(() => CourseEditorService().saveUserCourse(course));
      final folder = (await tester.runAsync(
        () => quickFolder(QqlStorageRole.imageImports),
      ))!;
      final picture = File('${folder.path}/cover_source.png');
      final source = (await tester.runAsync(() => _halves(640, 480)))!;
      await tester.runAsync(() => picture.writeAsBytes(source));
      addTearDown(() async {
        if (await picture.exists()) await picture.delete();
      });
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => CourseEditorScreen(
                    course: course,
                    access: CourseAccessPolicy.evaluate(
                      course,
                      profileId: profileId,
                    ),
                  ),
                ),
              ),
              child: const Text('Open Course'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Course'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('course-editor-header-cover')), findsNothing);

      await tester.tap(find.byKey(const Key('course-editor-course-info')));
      await tester.pumpAndSettle();
      final quickImport = find.byKey(const Key('course-cover-quick-import'));
      await tester.ensureVisible(quickImport);
      await tester.pumpAndSettle();
      await tester.tap(quickImport);
      final confirm = find.byKey(const Key('cover-crop-confirm'));
      await tester.pumpUntilFileIoState(() => confirm.evaluate().isNotEmpty);
      await tester.tap(confirm);
      await tester.pumpUntilFileIoState(
        () => find
            .byKey(const Key('course-cover-preview-image'))
            .evaluate()
            .isNotEmpty,
      );
      final save = find.byKey(const Key('course-info-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpUntilFileIoState(() => save.evaluate().isEmpty);
      expect(
        find.byKey(const Key('course-editor-header-cover')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CourseArtwork>(
              find.byKey(const Key('course-editor-header-cover')),
            )
            .course
            .coverImage,
        startsWith('media:'),
      );

      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-course-changes')));
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isEmpty,
      );
      final saved = ((await tester.runAsync(
        CourseEditorService().listUserCourses,
      ))!).single;
      expect(saved.coverImage, startsWith('media:'));
      final file = (await tester.runAsync(
        () => CourseMediaStore().existingFile(saved.courseId, saved.coverImage),
      ));
      expect(file, isNotNull);
    },
  );
}
