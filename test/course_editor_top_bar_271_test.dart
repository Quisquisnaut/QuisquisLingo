import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _profileId = '41111111-1111-4111-8111-111111111111';

// Build 271 Revision 2 (owner rule: at most three icons in a top bar): the
// Course Editor's main page has Save now as an icon, the access mode and
// Help; Show internal IDs is in Course Info Editor, whose IDs it controls.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  testWidgets('three icons in the top bar; Show internal IDs is in Course '
      'Info Editor', (tester) async {
    final course = _course();
    final profiles = ProfileService();
    await profiles.createProfile('Author', learnerProfileId: _profileId);
    await profiles.setActiveProfileById(_profileId);
    await SettingsService().markAudioOrphanCheckRun('IT');
    await SettingsService().setCourseEditorMode(
      course.courseId,
      CourseEditorMode.edit,
    );
    await tester.runAsync(() => CourseEditorService().saveUserCourse(course));
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(
          course: course,
          access: CourseAccessPolicy.evaluate(course, profileId: _profileId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = find.byType(AppBar);
    Finder inBar(Finder finder) => find.descendant(of: bar, matching: finder);
    expect(inBar(find.byType(IconButton)), findsNWidgets(3));
    final saveNow = find.byKey(const Key('course-editor-save-now'));
    expect(inBar(saveNow), findsOneWidget);
    expect(
      tester.widget<IconButton>(saveNow).tooltip,
      'Save now: write a new version and keep editing',
    );
    expect(tester.widget<IconButton>(saveNow).onPressed, isNull);
    expect(inBar(find.byKey(const Key('course-editor-lock'))), findsOneWidget);
    expect(inBar(find.byKey(const Key('editor-help-action'))), findsOneWidget);
    expect(find.byKey(const Key('editor-internal-ids-toggle')), findsNothing);
    expect(find.text('Save now'), findsNothing);

    await tester.tap(find.text('Course Info Editor'));
    await tester.pumpAndSettle();
    final ids = find.byKey(const Key('course-info-internal-ids'));
    expect(ids, findsOneWidget);
    expect(tester.widget<SwitchListTile>(ids).value, isFalse);
    expect(find.text('Course ID'), findsNothing);

    await tester.tap(ids);
    await tester.pumpUntilFileIoState(
      () => find.text('Course ID').evaluate().isNotEmpty,
    );
    expect(tester.widget<SwitchListTile>(ids).value, isTrue);
    expect(find.text(course.courseId), findsOneWidget);
    expect(EditorDisplayPreferences.showInternalIds.value, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getBool(EditorDisplayPreferences.showInternalIdsKey),
      isTrue,
    );

    await tester.tap(ids);
    await tester.pumpUntilFileIoState(
      () => find.text('Course ID').evaluate().isEmpty,
    );
    expect(EditorDisplayPreferences.showInternalIds.value, isFalse);
  });
}

Course _course() => Course(
  courseId: 'top-bar-course',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Top bar course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  license: 'All rights reserved',
  derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
  lessons: const [],
);
