import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'custom icon import creates a portable canonical 256x256 PNG asset',
    (tester) async {
      await tester.runAsync(() async {
        final imported = await LessonIconService().prepareIcon(
          File('assets/lesson_icons/home.png').readAsBytesSync(),
          assetId: 'custom_test',
        );
        expect(imported.sourceWidth, 256);
        expect(imported.sourceHeight, 256);
        expect(imported.asset.reference, contains('custom_test.png'));

        final bytes = base64Decode(imported.asset.base64Png);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 256);
        expect(frame.image.height, 256);
        frame.image.dispose();
        codec.dispose();
      });
      expect(
        LessonIconService.containDestination(120, 60),
        const ui.Rect.fromLTWH(0, 64, 256, 128),
      );
    },
  );

  test('managed icon survives Course JSON export and import', () {
    final png = base64Encode(
      File('assets/lesson_icons/home.png').readAsBytesSync(),
    );
    final asset = CourseLessonIconAsset(assetId: 'custom_home', base64Png: png);
    final source = _course(asset);

    final restored = Course.fromJson(
      jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>,
    );
    expect(restored.lessonIconAssets.single.assetId, 'custom_home');
    expect(restored.lessons.single.themeIconAsset, asset.reference);
    expect(
      CourseAuditService()
          .auditCourse(restored)
          .issues
          .where((issue) => issue.code == 'LESSON_THEME_ICON_INVALID'),
      isEmpty,
    );
  });

  test('Course duplication copies and remaps managed custom icons', () {
    final png = base64Encode(
      File('assets/lesson_icons/home.png').readAsBytesSync(),
    );
    final source = _course(
      CourseLessonIconAsset(assetId: 'custom_home', base64Png: png),
    );
    final duplicate = AuthoringDuplicationService(
      ids: _SequenceIds(),
    ).duplicateCourse(source, title: 'Copy');

    expect(duplicate.lessonIconAssets.single.assetId, isNot('custom_home'));
    expect(
      duplicate.lessons.single.themeIconAsset,
      duplicate.lessonIconAssets.single.reference,
    );
    expect(
      duplicate.lessonIconAssets.single.base64Png,
      source.lessonIconAssets.single.base64Png,
    );
  });

  test(
    'unresolved managed icons and external filesystem paths are rejected',
    () {
      final unresolved = _course(
        null,
        icon: 'course-assets/lesson-icons/lost.png',
      );
      expect(
        CourseAuditService()
            .auditCourse(unresolved)
            .issues
            .where((issue) => issue.code == 'LESSON_THEME_ICON_INVALID'),
        hasLength(1),
      );
      final json = unresolved.toJson();
      (json['lessons'] as List).first['themeIconAsset'] =
          r'C:\icons\lesson.png';
      expect(() => Course.fromJson(json), throwsFormatException);
    },
  );
}

Course _course(CourseLessonIconAsset? asset, {String? icon}) => Course(
  courseId: 'course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessonIconAssets: asset == null ? const [] : [asset],
  lessons: [
    Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      themeIconAsset: icon ?? asset?.reference,
      rounds: const [],
    ),
  ],
);

class _SequenceIds implements AuthoringIdGenerator {
  var value = 0;

  @override
  String next(String kind) => '${kind}_${value++}';
}
