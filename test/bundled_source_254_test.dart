import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/publication_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late Course source;
  late Course learner;
  late CourseEditorService editor;
  late CoursePackageService packages;
  late CourseLibraryOperations operations;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    support = await Directory.systemTemp.createTemp('qql_bundled_source_254_');
    await ProfileService().addProfile('Source reviewer');
    source = await CourseService().loadBundledCourse('EN_EDGE');
    learner = const PublicationService().learnerCourse(source)!;
    final media = CourseMediaStore(supportDirectory: () async => support);
    editor = CourseEditorService(
      courseStore: CourseFileStore(supportDirectory: () async => support),
      mediaStore: media,
    );
    packages = CoursePackageService(
      mediaStore: media,
      stager: ImportStager(supportDirectory: () async => support),
    );
    operations = CourseLibraryOperations(
      editor: editor,
      transfer: CustomCourseTransferService(
        directory: () async => support,
        packageService: packages,
      ),
    );
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  void expectFullSource(Course actual) {
    expect(actual.courseId, source.courseId);
    expect(actual.lessons, hasLength(5));
    expect(actual.lessons.expand((lesson) => lesson.rounds), hasLength(10));
    expect(
      actual.lessons
          .expand((lesson) => lesson.rounds)
          .expand((round) => round.exercises),
      hasLength(31),
    );
    expect(
      CourseBackupService.officialContentChecksum(actual),
      source.officialChecksum,
    );
    expect(actual.toJson(), source.toJson());
  }

  test(
    'Studio keeps full bundled source when Home passes its learner view',
    () async {
      expect(learner.lessons, hasLength(4));
      final library = await operations.load(currentCourse: learner);
      expect(library.activeCourseId, source.courseId);
      expectFullSource(
        library.bundledCourses.singleWhere(
          (course) => course.courseId == source.courseId,
        ),
      );
    },
  );

  test(
    'Studio exports all Draft content with the official source checksum',
    () async {
      final library = await operations.load(currentCourse: learner);
      final selected = library.bundledCourses.singleWhere(
        (course) => course.courseId == source.courseId,
      );
      final exported = await operations.exportCourse(selected);
      // Ordinary Course import rejects official bundles. Read this exported
      // official package only to verify that its immutable source is intact.
      final parsed = await packages.parseFile(
        File(exported.path),
        (bytes, _) async => Course.fromJson(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
        ),
      );
      try {
        expectFullSource(parsed.course);
      } finally {
        await parsed.discard();
      }
    },
  );

  testWidgets(
    'opening the active bundled Course uses full source in read-only Editor',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseProjectsScreen(
            currentCourse: learner,
            initialCourseIdToOpen: source.courseId,
            editorService: editor,
          ),
        ),
      );
      await tester.pumpUntilFileIoState(
        () => find.byType(CourseEditorScreen).evaluate().isNotEmpty,
      );
      final opened = tester.widget<CourseEditorScreen>(
        find.byType(CourseEditorScreen),
      );
      expect(opened.access!.canEditOriginal, isFalse);
      expectFullSource(opened.course);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
