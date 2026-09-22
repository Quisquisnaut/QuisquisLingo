import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/test_directories.dart';
import 'support/unique_png.dart';

const _authorId = '12345678-1234-4234-9234-123456789abc';

void main() {
  late Directory imports;
  late CourseEditorService editor;
  late String sentinel;
  late String incoming;

  Future<List<String>> stagedFiles() async {
    final directory = Directory(
      '${testSupportDirectory.path}/${ImportStager.stagingDirectoryName}',
    );
    if (!await directory.exists()) return const [];
    return [
      await for (final entity in directory.list(recursive: true))
        if (entity is File) entity.path,
    ];
  }

  /// A same-ID Course is installed; `Imports/import.zip` holds an incoming
  /// version with one new image.
  Future<void> prepare(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _authorId,
          displayName: 'Import Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _authorId,
    });
    editor = CourseEditorService();
    await tester.runAsync(() async {
      imports = await Directory.systemTemp.createTemp('qql_247_ui_imports_');
      final media = CourseMediaStore();
      sentinel = await media.addBytes('same', uniquePng(40), 'png');
      await editor.installImportedCustomCourse(
        _course(title: 'Installed', image: sentinel),
      );
      final bytes = uniquePng(41);
      incoming = CourseMediaStore.referenceFor(bytes, 'png');
      final course = _course(title: 'Incoming', image: incoming);
      final zip = await CoursePackageService().build(
        course,
        Uint8List.fromList(utf8.encode(jsonEncode(course.toJson()))),
        suppliedMedia: {incoming: bytes},
      );
      await File('${imports.path}/import.zip').writeAsBytes(zip, flush: true);
    });
    addTearDown(() async {
      if (await imports.exists()) await imports.delete(recursive: true);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: CourseProjectsScreen(
          currentCourse: null,
          editorService: editor,
          transferService: CustomCourseTransferService(
            importDirectory: () async => imports,
          ),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.byTooltip('Course Import').evaluate().isNotEmpty,
    );
    await tester.tap(find.byTooltip('Course Import'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('import-course-json-primary')));
    await tester.pumpUntilFileIoState(
      () => find.text('Matching Course ID').evaluate().isNotEmpty,
    );
  }

  testWidgets('Copy from an import opens its Editor with no staged media', (
    tester,
  ) async {
    await prepare(tester);
    expect(await tester.runAsync(stagedFiles), hasLength(1));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Copy as New Course'));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
    );

    final copy = tester.widget<CourseEditorScreen>(
      find.byType(CourseEditorScreen),
    );
    expect(copy.course.courseId, isNot('same'));
    final state = await tester.runAsync(() async {
      final media = CourseMediaStore();
      return (
        staged: await stagedFiles(),
        copyHasImage:
            await media.existingFile(copy.course.courseId, incoming) != null,
        sameHasImage: await media.existingFile('same', incoming) != null,
        sameKeepsSentinel: await media.existingFile('same', sentinel) != null,
      );
    });
    expect(state!.copyHasImage, isTrue);
    expect(state.sameHasImage, isFalse);
    expect(state.sameKeepsSentinel, isTrue);
    expect(
      state.staged,
      isEmpty,
      reason:
          'staging ends when the Copy is installed, not when its Editor closes',
    );
  });

  testWidgets(
    'Cancel on a matching Course ID writes nothing and clears staging',
    (tester) async {
      await prepare(tester);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpUntilFileIoState(
        () => find.text('Matching Course ID').evaluate().isEmpty,
      );

      final state = await tester.runAsync(() async {
        final media = CourseMediaStore();
        return (
          staged: await stagedFiles(),
          courses: await editor.listUserCourses(),
          sameHasImage: await media.existingFile('same', incoming) != null,
        );
      });
      expect(state!.staged, isEmpty);
      expect(state.courses.single.title, 'Installed');
      expect(state.sameHasImage, isFalse);
    },
  );
}

Course _course({required String title, required String image}) => Course(
  courseId: 'same',
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _authorId,
    displayName: 'Import Author',
  ),
  maintainer: const CourseMaintainer(_authorId),
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  imageLibrary: [CourseImageLibraryEntry(asset: image)],
  lessons: [
    Lesson(
      lessonId: 'lesson-same',
      publicationState: PublicationState.draft,
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);
