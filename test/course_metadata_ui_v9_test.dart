import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _profileId = '22222222-2222-4222-8222-222222222222';

void main() {
  test('Create Course exposes structured Rights Holder editing', () {
    final source = File(
      'lib/screens/course_projects_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'License / Rights'"));
    expect(
      RegExp(r"ValueKey\(\s*'new-course-rights-holder-name-").hasMatch(source),
      isTrue,
    );

    // Since Build 249 the dialog's values are built into the Course by
    // CourseLibraryOperations.newCourse, so the structure is checked by
    // behaviour rather than by searching the screen's source.
    final course = CourseLibraryOperations().newCourse(
      creator: const LearnerProfile(
        learnerProfileId: _profileId,
        displayName: 'Rights Author',
      ),
      maintainerProfileId: _profileId,
      title: 'Rights',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      credits: const [],
      license: 'CC BY 4.0',
      derivativeWorksPolicy: DerivativeWorksPolicy.allowed,
      rightsHolders: const [
        (type: CourseRightsHolderType.organization, name: ' Rights Org '),
        (type: CourseRightsHolderType.person, name: ''),
      ],
      languageVariant: '',
      startLevel: '',
      targetLevel: '',
      courseDescription: '',
      buyACoffeeUrl: '',
      flag: const CourseFlagSelection.automatic(),
      lessonCount: 1,
      roundsPerLesson: 1,
    );
    expect(course.rightsHolders, hasLength(1));
    expect(
      course.rightsHolders.single.type,
      CourseRightsHolderType.organization,
    );
    expect(course.rightsHolders.single.name, 'Rights Org');
  });

  testWidgets('Course Info Editor persists edited structured Rights Holders', (
    tester,
  ) async {
    final documents = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_rights_ui_'),
    ))!;
    addTearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });
    SharedPreferences.setMockInitialValues({});
    final profiles = ProfileService();
    await profiles.createProfile('Rights Author', learnerProfileId: _profileId);
    await profiles.setActiveProfileById(_profileId);
    await SettingsService().markAudioOrphanCheckRun('IT');
    await SettingsService().setCourseEditorMode(
      'rights-holder-ui',
      CourseEditorMode.edit,
    );
    final service = CourseEditorService(
      backupService: CourseBackupService(
        supportDirectoryProvider: () async => documents,
      ),
    );
    final original = _course();
    await tester.runAsync(() => service.saveUserCourse(original));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () =>
                Navigator.of(context).push<CourseConfirmationResult>(
                  MaterialPageRoute(
                    builder: (_) => CourseEditorScreen(
                      course: original,
                      userCourse: true,
                      editorService: service,
                    ),
                  ),
                ),
            child: const Text('Open Editor'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Course Info Editor'));
    await tester.pumpAndSettle();

    final rightsHolderName = find.byKey(
      const Key('course-info-rights-holder-name-0'),
    );
    expect(find.text('License / Rights'), findsOneWidget);
    await tester.ensureVisible(rightsHolderName);
    await tester.enterText(rightsHolderName, 'Independent Rights Organization');
    final rightsHolderType = find.byKey(
      const Key('course-info-rights-holder-type-0'),
    );
    await tester.ensureVisible(rightsHolderType);
    await tester.tap(rightsHolderType);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Organization').last);
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('course-info-save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpUntilFileIoState(() => save.evaluate().isEmpty);

    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isEmpty,
    );
    final saved = (await tester.runAsync(
      () => service.listUserCourses(),
    ))!.single;
    expect(saved.toJson()['rightsHolders'], [
      {'type': 'organization', 'name': 'Independent Rights Organization'},
    ]);
  });
}

Course _course() => Course(
  courseId: 'rights-holder-ui',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Rights Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Rights Holder Course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: [Lesson(lessonId: 'rights-lesson', title: 'Lesson', rounds: [])],
);
