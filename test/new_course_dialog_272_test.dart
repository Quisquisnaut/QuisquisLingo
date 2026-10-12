import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 272 Revision 3: New Course's form as an author meets it. These
/// cases were written on the code before the form got its owner and its own
/// file, and passed there. Credits and licence are in
/// `course_credits_272_test.dart`; the numbers of Lessons and Rounds, the
/// flag, the cover, the Maintainer list and the Wizard's prefill have their
/// own earlier tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [_profile.encode()],
      ProfileService.activeProfileIdKey: _profileId,
    }),
  );

  testWidgets('a name that cannot be stored is refused; without both '
      'languages nothing happens; Buy a Coffee must be HTTPS', (tester) async {
    await _openForm(tester);
    final create = find.widgetWithText(FilledButton, 'Continue to Editor');
    Future<void> tapCreate() async {
      await tester.ensureVisible(create);
      await tester.pump();
      await tester.tap(create);
      await tester.pumpAndSettle();
    }

    Future<void> clearMessage() async {
      ScaffoldMessenger.of(tester.element(create)).clearSnackBars();
      await tester.pumpAndSettle();
    }

    // No title: a message, and the form stays.
    await tapCreate();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(CourseEditorScreen), findsNothing);
    await clearMessage();

    // A title but no languages: nothing happens and nothing is said.
    await _enter(tester, _field('Course title *'), 'By hand');
    await tapCreate();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(CourseEditorScreen), findsNothing);
    expect(find.text('Create new course'), findsOneWidget);

    await _enter(tester, _field('Source language *'), 'English');
    await tapCreate();
    expect(find.byType(CourseEditorScreen), findsNothing);
    await _enter(tester, _field('Target language *'), 'Italian');

    await _enter(
      tester,
      _field('Buy a Coffee URL (optional)'),
      'http://example.org/coffee',
    );
    await tapCreate();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(CourseEditorScreen), findsNothing);
    await clearMessage();

    await _enter(
      tester,
      _field('Buy a Coffee URL (optional)'),
      ' https://example.org/coffee ',
    );
    await _enter(tester, _field('Language variant'), ' Tuscan ');
    await _enter(tester, _field('Starting level'), ' A1 ');
    await _enter(tester, _field('Target level'), ' A2 ');
    await _enter(
      tester,
      _field('Course description / information'),
      ' About it ',
    );
    await tapCreate();
    final course = tester
        .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
        .course;
    expect(course.title, 'By hand');
    expect(course.sourceLanguage, 'English');
    expect(course.targetLanguage, 'Italian');
    expect(course.sourceLanguageTag, 'en');
    expect(course.targetLanguageTag, 'it');
    expect(course.buyACoffeeUrl, 'https://example.org/coffee');
    expect(course.languageVariant, 'Tuscan');
    expect(course.startLevel, 'A1');
    expect(course.targetLevel, 'A2');
    expect(course.courseDescription, 'About it');
    expect(course.maintainer?.profileId, _profileId);
    expect(course.originalCourseCreator.id, _profileId);
    expect(course.license, 'All rights reserved');
    expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.forbidden);
    expect(course.lessons, hasLength(3));
    expect(course.publicationState, PublicationState.draft);
    // Nothing is stored until the Course Editor is confirmed.
    expect(
      (await tester.runAsync(() => CourseEditorService().listUserCourses()))!,
      isEmpty,
    );
  });

  testWidgets('a name another Course of the learner has asks first', (
    tester,
  ) async {
    await tester.runAsync(
      () => CourseEditorService().saveUserCourse(_stored('Taken Name')),
    );
    await _openForm(tester);
    final create = find.widgetWithText(FilledButton, 'Continue to Editor');
    await _enter(tester, _field('Course title *'), 'taken name');
    await _enter(tester, _field('Source language *'), 'English');
    await _enter(tester, _field('Target language *'), 'Italian');

    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.text('Course name already exists'), findsOneWidget);
    expect(find.text('A Course with this name already exists.'), findsOne);
    await tester.tap(find.text('Edit name'));
    await tester.pumpAndSettle();
    expect(find.text('Course name already exists'), findsNothing);
    expect(find.text('Create new course'), findsOneWidget);
    expect(find.byType(CourseEditorScreen), findsNothing);

    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
          .course
          .title,
      'taken name',
    );
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Form Author',
);

Course _host() => Course(
  courseId: 'new-course-272-host',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Host',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

Course _stored(String title) => Course(
  courseId: 'new-course-272-stored',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Form Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: const [],
);

/// Course Studio, New Course, then Continue by hand: New Course's form.
Future<void> _openForm(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: CourseProjectsScreen(currentCourse: _host())),
  );
  await tester.pumpUntilFileIoState(
    () => find.text('Bundled Courses').evaluate().isNotEmpty,
  );
  await tester.tap(find.byKey(const Key('create-course-icon-action')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('course-wizard-manual')));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _enter(WidgetTester tester, Finder field, String value) async {
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, value);
  await tester.pump();
}
