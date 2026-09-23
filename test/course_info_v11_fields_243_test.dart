import 'support/pump_file_io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '31111111-1111-4111-8111-111111111111';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Course Info Editor saves the v11 descriptive fields', (
    tester,
  ) async {
    await _pumpEditor(tester, _course());

    await tester.tap(find.text('Course Info Editor'));
    await tester.pumpAndSettle();
    await _enter(tester, 'course-info-estimated-hours', '40');
    await _enter(tester, 'course-info-keywords', ' travel, Travel, , food ');
    await _enter(
      tester,
      'course-info-contact-website',
      'https://example.org/courses',
    );
    await _enter(tester, 'course-info-contact-email', 'errata@example.org');
    await _enter(
      tester,
      'course-info-minimum-app-build',
      '${Course.appBuildNumber}',
    );
    final age = find.byKey(const Key('course-info-minimum-age'));
    await tester.ensureVisible(age);
    await tester.tap(age);
    await tester.pumpAndSettle();
    await tester.tap(find.text('13+').last);
    await tester.pumpAndSettle();
    final saved = await _saveAndConfirm(tester);
    expect(saved.estimatedStudyHours, 40);
    expect(saved.keywords, ['travel', 'food']);
    expect(saved.publisherContact!.websiteUrl, 'https://example.org/courses');
    expect(saved.publisherContact!.email, 'errata@example.org');
    expect(saved.minimumAppBuild, Course.appBuildNumber);
    expect(saved.minimumAge, 13);
  });

  testWidgets('clearing the fields removes them from the Course', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      _course(
        estimatedStudyHours: 5,
        keywords: const ['old'],
        publisherContact: CoursePublisherContact(email: 'a@example.org'),
        minimumAppBuild: 1,
      ),
    );
    await tester.tap(find.text('Course Info Editor'));
    await tester.pumpAndSettle();
    for (final key in const [
      'course-info-estimated-hours',
      'course-info-keywords',
      'course-info-contact-email',
      'course-info-minimum-app-build',
    ]) {
      await _enter(tester, key, '');
    }
    final json = (await _saveAndConfirm(tester)).toJson();
    for (final key in const [
      'estimatedStudyHours',
      'keywords',
      'publisherContact',
      'minimumAppBuild',
    ]) {
      expect(json.containsKey(key), isFalse, reason: key);
    }
  });

  testWidgets('invalid values keep the editor open with a message', (
    tester,
  ) async {
    await _pumpEditor(tester, _course());
    await tester.tap(find.text('Course Info Editor'));
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('course-info-save'));

    Future<void> expectRefused(String key, String value, String message) async {
      await _enter(tester, key, value);
      await tester.ensureVisible(save);
      await tester.tap(save);
      // Save first checks stored Course names through real file IO.
      await tester.pumpUntilFileIoState(
        () => find.textContaining(message).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(save, findsOneWidget, reason: '$key=$value must not save');
      expect(find.textContaining(message), findsOneWidget);
      await _enter(tester, key, '');
      ScaffoldMessenger.of(
        tester.element(find.byType(AlertDialog)),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    }

    await expectRefused(
      'course-info-estimated-hours',
      'many',
      'must be a whole number',
    );
    await expectRefused('course-info-estimated-hours', '0', '1 to 1000');
    await expectRefused(
      'course-info-contact-website',
      'http://example.org',
      'must be a valid HTTPS URL',
    );
    await expectRefused(
      'course-info-minimum-app-build',
      '${Course.appBuildNumber + 1}',
      'Update QuisquisLingo',
    );
    await expectRefused(
      'course-info-keywords',
      'a' * 33,
      'at most 32 characters',
    );
  });

  testWidgets('Course Info shows the descriptive fields', (tester) async {
    // Tall enough that the whole lazily built page is laid out.
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: CourseInfoScreen(
          course: _course(
            estimatedStudyHours: 40,
            minimumAge: 16,
            keywords: const ['travel', 'food'],
            publisherContact: CoursePublisherContact(
              websiteUrl: 'https://example.org',
              email: 'errata@example.org',
            ),
            minimumAppBuild: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Estimated study time: 40 hours'), findsOne);
    expect(find.textContaining('Minimum age: 16+'), findsOne);
    expect(find.textContaining('Keywords: travel, food'), findsOne);
    expect(find.textContaining('Requires QuisquisLingo build 1'), findsOne);
    expect(find.textContaining('Website: https://example.org'), findsOne);
    expect(find.textContaining('Email: errata@example.org'), findsOne);
  });
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<Course> _saveAndConfirm(WidgetTester tester) async {
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
  return ((await tester.runAsync(CourseEditorService().listUserCourses))!)
      .single;
}

Future<void> _pumpEditor(
  WidgetTester tester,
  Course course,
) async {
  final profiles = ProfileService();
  await profiles.createProfile('Author', learnerProfileId: _profileId);
  await profiles.setActiveProfileById(_profileId);
  await SettingsService().markAudioOrphanCheckRun('IT');
  await SettingsService().setCourseEditorMode(
    course.courseId,
    CourseEditorMode.edit,
  );
  await tester.runAsync(() => CourseEditorService().saveUserCourse(course));
  // Pushed rather than root, so the Editor has a Back button and its
  // confirmation can be reached.
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
                  profileId: _profileId,
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
}

Course _course({
  int? estimatedStudyHours,
  int? minimumAge,
  List<String> keywords = const [],
  CoursePublisherContact? publisherContact,
  int? minimumAppBuild,
}) => Course(
  courseId: 'v11-fields-course',
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
  title: 'v11 fields course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  license: 'All rights reserved',
  derivativeWorksPolicy: DerivativeWorksPolicy.forbidden,
  estimatedStudyHours: estimatedStudyHours,
  minimumAge: minimumAge,
  keywords: keywords,
  publisherContact: publisherContact,
  minimumAppBuild: minimumAppBuild,
  lessons: [
    Lesson(
      lessonId: 'v11-lesson',
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'v11-round',
          title: 'Round',
          content: [
            LearningContent.fromExercise(
              Exercise(
                id: 'v11-exercise',
                type: 'choice',
                prompt: 'Choose',
                question: 'Hello?',
                answers: const ['Ciao', 'Grazie'],
                correct: 0,
                tts: null,
                accepted: const [],
                tokens: const [],
                orderAnswer: const [],
                pairs: const [],
                hint: '',
                icons: const [],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
