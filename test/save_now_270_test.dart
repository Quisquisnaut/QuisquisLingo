import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _profileId = '31111111-1111-4111-8111-111111111111';

// Build 270 Revision 12 (owner decision of 10 October 2026): "Save" always
// writes the Course to the device; inside the Course Editor a change is
// applied ("Apply") and the main page's Save now, or Save course on leaving,
// writes it.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('an applied change shows Unsaved changes; Save now writes it '
      'and stays; leaving then asks nothing and returns the save', (
    tester,
  ) async {
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
    CourseConfirmationResult? returned;
    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              returned = await Navigator.of(context)
                  .push<CourseConfirmationResult>(
                    MaterialPageRoute(
                      builder: (_) => CourseEditorScreen(
                        course: course,
                        access: CourseAccessPolicy.evaluate(
                          course,
                          profileId: _profileId,
                        ),
                      ),
                    ),
                  );
              popped = true;
            },
            child: const Text('Open Course'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Course'));
    await tester.pumpAndSettle();

    final saveNow = find.byKey(const Key('course-editor-save-now'));
    expect(saveNow, findsOneWidget);
    // Build 271 Revision 2: Save now is an icon of the top bar.
    expect(tester.widget<IconButton>(saveNow).onPressed, isNull);
    expect(
      tester.widget<IconButton>(saveNow).tooltip,
      'Save now: write a new version and keep editing',
    );
    expect(find.byKey(const Key('course-editor-unsaved')), findsNothing);

    // Course Info's button applies; nothing is written yet.
    await tester.tap(find.text('Course Info Editor'));
    await tester.pumpAndSettle();
    final hours = find.byKey(const Key('course-info-estimated-hours'));
    await tester.ensureVisible(hours);
    await tester.enterText(hours, '12');
    await tester.pump();
    final apply = find.byKey(const Key('course-info-save'));
    expect(
      find.descendant(of: apply, matching: find.text('Apply')),
      findsOneWidget,
    );
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpUntilFileIoState(() => apply.evaluate().isEmpty);
    expect(find.byKey(const Key('course-editor-unsaved')), findsOneWidget);
    expect(tester.widget<IconButton>(saveNow).onPressed, isNotNull);
    var stored = (await tester.runAsync(
      () => CourseEditorService().listUserCourses(),
    ))!.single;
    expect(stored.estimatedStudyHours, isNull);

    // Save now writes a new version and the Editor stays open.
    await tester.tap(saveNow);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('course-save-now-dialog')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('course-version-notes')),
      'Twelve hours',
    );
    await tester.tap(find.byKey(const Key('course-save-now-confirm')));
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('course-editor-saved')).evaluate().isNotEmpty,
    );
    expect(find.byType(CourseEditorScreen), findsOneWidget);
    expect(find.byKey(const Key('course-editor-unsaved')), findsNothing);
    stored = (await tester.runAsync(
      () => CourseEditorService().listUserCourses(),
    ))!.single;
    expect(stored.estimatedStudyHours, 12);
    expect(stored.versionNotes, 'Twelve hours');
    expect(stored.courseVersion, '2');

    // Nothing unsaved: leaving asks nothing and hands back the save.
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpUntilFileIoState(() => popped);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsNothing,
    );
    expect(returned?.course.estimatedStudyHours, 12);
  });
}

Course _course() => Course(
  courseId: 'save-now-course',
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
  title: 'Save now course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  license: 'All rights reserved',
  derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
  lessons: const [],
);
