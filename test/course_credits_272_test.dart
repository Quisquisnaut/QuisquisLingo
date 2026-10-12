import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_metadata_options.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/screens/course_wizard_screen.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_authoring_session.dart';
import 'package:quisquislingo_app/services/course_credits.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_wizard.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 272 Revision 0: the credits and licence rules of Course Info, New
/// Course and the Course Wizard. The owner's own cases first; then the three
/// screens as they behave. The screen cases were written on the code before
/// the rules got one owner, and passed there: they pin what an author gets,
/// the differences between the screens included.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [_profile.encode()],
      ProfileService.activeProfileIdKey: _profileId,
    }),
  );

  group('CourseCredits', () {
    test('roles: the standard ones in their order, the others once, '
        'Contributor for none', () {
      expect(
        CourseCredits.rolesOf({'Contributor', 'Author'}, 'Voice, Author'),
        ['Author', 'Contributor', 'Voice'],
      );
      expect(CourseCredits.rolesOf(const <String>{}, ''), ['Contributor']);
      expect(CourseCredits.rolesOf(const <String>{}, ' , ,'), ['Contributor']);
      // The other roles keep their capitals and their order.
      expect(
        CourseCredits.rolesOf(const ['Reviewer'], ' Sound , Sound,sound'),
        ['Reviewer', 'Sound', 'sound'],
      );
      // Only a standard role counts among the chosen ones.
      expect(CourseCredits.rolesOf({'Wizard'}, ''), ['Contributor']);
      expect(
        CourseCredits.rolesOf(CourseMetadataOptions.standardRoles.reversed, ''),
        CourseMetadataOptions.standardRoles,
      );
      expect(
        CourseCredits.defaultRole,
        const CourseAuthor(name: 'x').roles.single,
      );
    });

    test('stored roles split into the chosen standard ones and a text', () {
      const stored = ['Editor', 'Voice', 'Author', 'Subtitles'];
      expect(CourseCredits.standardRolesIn(stored), {'Editor', 'Author'});
      expect(CourseCredits.customRolesIn(stored), 'Voice, Subtitles');
      expect(CourseCredits.customRolesIn(const ['Author']), isEmpty);
      // Reading a credit and writing it unchanged puts the standard roles
      // first.
      expect(
        CourseCredits.rolesOf(
          CourseCredits.standardRolesIn(stored),
          CourseCredits.customRolesIn(stored),
        ),
        ['Author', 'Editor', 'Voice', 'Subtitles'],
      );
    });

    test('a row without a name is no credit and no Rights Holder', () {
      expect(
        CourseCredits.author(
          name: '  ',
          standardRoles: const {'Author'},
          customRoles: 'Voice',
        ),
        isNull,
      );
      final author = CourseCredits.author(
        name: ' Ann ',
        standardRoles: const <String>{},
        customRoles: '',
      )!;
      expect(author.name, 'Ann');
      expect(author.roles, ['Contributor']);
      expect(
        CourseCredits.rightsHolder(CourseRightsHolderType.person, ' '),
        isNull,
      );
      final holder = CourseCredits.rightsHolder(
        CourseRightsHolderType.organization,
        ' Org ',
      )!;
      expect(holder.name, 'Org');
      expect(holder.type, CourseRightsHolderType.organization);
    });

    test('the licence list: the entry for a stored licence, the licence of '
        'an entry', () {
      for (final license in CourseMetadataOptions.standardLicenses) {
        expect(CourseCredits.licenseChoiceFor(license), license);
      }
      expect(
        CourseCredits.licenseChoiceFor('My terms'),
        CourseMetadataOptions.customLicense,
      );
      expect(
        CourseCredits.licenseChoiceFor(''),
        CourseMetadataOptions.customLicense,
      );
      expect(
        CourseMetadataOptions.standardLicenses.last,
        'Other / Custom license',
      );
      expect(
        CourseCredits.isCustomLicenseChoice('Other / Custom license'),
        isTrue,
      );
      expect(CourseCredits.isCustomLicenseChoice('CC0 1.0'), isFalse);

      expect(CourseCredits.licenseOf('CC BY 4.0', 'ignored'), 'CC BY 4.0');
      expect(
        CourseCredits.licenseOf(CourseMetadataOptions.customLicense, ' Mine '),
        'Mine',
      );
      // Nothing typed: the form refuses the empty licence.
      expect(
        CourseCredits.licenseOf(CourseMetadataOptions.customLicense, '  '),
        isEmpty,
      );
    });

    test('the policy stored with a licence, and the one a form shows after '
        'a choice', () {
      const custom = CourseMetadataOptions.customLicense;
      const allowed = DerivativeWorksPolicy.allowed;
      const forbidden = DerivativeWorksPolicy.forbidden;
      const unspecified = DerivativeWorksPolicy.unspecified;

      expect(CourseCredits.policyOf('All rights reserved', allowed), forbidden);
      for (final license in CourseMetadataOptions.standardLicenses) {
        if (license.startsWith('CC')) {
          expect(CourseCredits.policyOf(license, forbidden), allowed);
        }
      }
      for (final chosen in DerivativeWorksPolicy.values) {
        expect(CourseCredits.policyOf(custom, chosen), chosen);
      }

      // Course Info: a licence of the list left as stored keeps the stored
      // policy; a changed one brings its own; a custom one the chosen one.
      DerivativeWorksPolicy kept(String choice, DerivativeWorksPolicy chosen) =>
          CourseCredits.policyKeepingStored(
            choice,
            chosen,
            storedLicense: 'All rights reserved',
            storedPolicy: allowed,
          );
      expect(kept('All rights reserved', forbidden), allowed);
      expect(kept('CC0 1.0', forbidden), allowed);
      expect(kept(custom, unspecified), unspecified);
      // A Course that stores the words of the list as its licence shows the
      // custom entry, and the chosen policy counts.
      expect(
        CourseCredits.policyKeepingStored(
          custom,
          forbidden,
          storedLicense: custom,
          storedPolicy: allowed,
        ),
        forbidden,
      );

      expect(CourseCredits.policyAfterChoosing('CC0 1.0', forbidden), allowed);
      expect(
        CourseCredits.policyAfterChoosing('All rights reserved', allowed),
        forbidden,
      );
      for (final current in DerivativeWorksPolicy.values) {
        expect(CourseCredits.policyAfterChoosing(custom, current), current);
      }
    });
  });

  group('Course Info', () {
    testWidgets('roles in the standard order, each other role once, '
        'Contributor for none; an unchanged licence keeps its policy', (
      tester,
    ) async {
      final service = CourseEditorService();
      await _openCourseInfo(
        tester,
        service,
        _course(
          license: 'All rights reserved',
          policy: DerivativeWorksPolicy.allowed,
        ),
      );

      // The stored roles, split: the standard ones as chips, the others as
      // text.
      expect(_chip(tester, 'Author', 0).selected, isTrue);
      expect(_chip(tester, 'Editor', 0).selected, isTrue);
      expect(_chip(tester, 'Contributor', 0).selected, isFalse);
      expect(_texts(tester, 'Custom role(s)'), ['Voice, Subtitles']);

      await _enter(tester, _field('Custom role(s)'), ' Sound , Author,, Sound');
      // A second author starts as Contributor; without any role it is still
      // a Contributor.
      await _tapText(tester, 'Add author');
      expect(_chip(tester, 'Contributor', 1).selected, isTrue);
      await _enter(tester, _field('Name').at(1), ' Bo ');
      await _tapFinder(
        tester,
        find.widgetWithText(FilterChip, 'Contributor').at(1),
      );
      expect(_chip(tester, 'Contributor', 1).selected, isFalse);
      // A third author without a name is not stored.
      await _tapText(tester, 'Add author');
      await _tapFinder(
        tester,
        find.widgetWithText(FilterChip, 'Reviewer').at(2),
      );

      final saved = await _applyAndSave(tester, service);
      expect(_credits(saved), {
        'Ann': ['Author', 'Editor', 'Sound'],
        'Bo': ['Contributor'],
      });
      expect(saved.license, 'All rights reserved');
      expect(saved.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
    });

    testWidgets('a licence of the list brings its policy; Other / Custom '
        'license keeps the policy shown and needs a text', (tester) async {
      final service = CourseEditorService();
      await _openCourseInfo(
        tester,
        service,
        _course(
          license: 'CC BY 4.0',
          policy: DerivativeWorksPolicy.unspecified,
        ),
      );
      expect(_field('Custom license'), findsNothing);

      await _choose(tester, 'Course content license', 'CC0 1.0');
      await _choose(tester, 'Course content license', 'Other / Custom license');
      // Course Info shows the stored licence in the Custom license field,
      // also when it was one of the list.
      expect(_texts(tester, 'Custom license'), ['CC BY 4.0']);
      // CC0 allowed derivative works, and the custom licence keeps that.
      expect(
        tester
            .widget<DropdownButtonFormField<DerivativeWorksPolicy>>(
              find.byType(DropdownButtonFormField<DerivativeWorksPolicy>),
            )
            .initialValue,
        DerivativeWorksPolicy.allowed,
      );

      // Without a text Apply does nothing.
      await _enter(tester, _field('Custom license'), '   ');
      final apply = find.byKey(const Key('course-info-save'));
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpUntilFileIoState(() => true);
      expect(apply, findsOneWidget);

      await _enter(tester, _field('Custom license'), ' My terms ');
      await _enter(
        tester,
        find.byKey(const ValueKey('course-info-rights-holder-name-0')),
        ' Org ',
      );
      final saved = await _applyAndSave(tester, service);
      expect(saved.license, 'My terms');
      expect(saved.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      expect(saved.rightsHolders.single.name, 'Org');
    });

    testWidgets('a licence chosen from the list replaces a policy the '
        'Course stored', (tester) async {
      final service = CourseEditorService();
      await _openCourseInfo(
        tester,
        service,
        _course(
          license: 'All rights reserved',
          policy: DerivativeWorksPolicy.allowed,
        ),
      );
      await _choose(tester, 'Course content license', 'CC BY-NC 4.0');
      await _choose(tester, 'Course content license', 'All rights reserved');
      // The licence is the stored one again, so the stored policy stays.
      var saved = await _applyAndSave(tester, service);
      expect(saved.license, 'All rights reserved');
      expect(saved.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);

      await _openCourseInfo(tester, service, saved, store: false);
      await _choose(tester, 'Course content license', 'CC BY-NC 4.0');
      saved = await _applyAndSave(tester, service);
      expect(saved.license, 'CC BY-NC 4.0');
      expect(saved.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);

      await _openCourseInfo(tester, service, saved, store: false);
      await _choose(tester, 'Course content license', 'All rights reserved');
      saved = await _applyAndSave(tester, service);
      expect(saved.derivativeWorksPolicy, DerivativeWorksPolicy.forbidden);
    });
  });

  group('New Course', () {
    testWidgets('the creator is an Author; roles, Rights Holders and a '
        'custom licence as typed; Other / Custom license starts unspecified', (
      tester,
    ) async {
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
      await _enter(tester, _field('Course title *'), 'Credits by hand');
      await _enter(tester, _field('Source language *'), 'English');
      await _enter(tester, _field('Target language *'), 'Italian');

      expect(_texts(tester, 'Name'), ['Credits Author']);
      expect(_chip(tester, 'Author', 0).selected, isTrue);
      await _enter(tester, _field('Custom role(s)'), 'Voice, Author');
      await _tapText(tester, 'Add author or contributor');
      expect(_chip(tester, 'Contributor', 1).selected, isTrue);
      await _enter(tester, _field('Name').at(1), ' Bo ');
      await _tapFinder(
        tester,
        find.widgetWithText(FilterChip, 'Contributor').at(1),
      );

      // A licence of the list brings its policy, and so does Other / Custom
      // license: it states none, so New Course shows Not specified.
      await _choose(tester, 'Course content license', 'CC BY-SA 4.0');
      await _choose(tester, 'Course content license', 'Other / Custom license');
      expect(_texts(tester, 'Custom license'), ['']);
      expect(
        tester
            .widget<DropdownButtonFormField<DerivativeWorksPolicy>>(
              find.byKey(const Key('new-course-derivative-policy')),
            )
            .initialValue,
        DerivativeWorksPolicy.unspecified,
      );
      await _enter(tester, _field('Custom license'), ' My terms ');
      await _enter(
        tester,
        find.byKey(const ValueKey('new-course-rights-holder-name-0')),
        ' Org ',
      );

      final create = find.widgetWithText(FilledButton, 'Continue to Editor');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final course = tester
          .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
          .course;
      expect(_credits(course), {
        'Credits Author': ['Author', 'Voice'],
        'Bo': ['Contributor'],
      });
      expect(course.license, 'My terms');
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.unspecified);
      expect(course.rightsHolders.single.name, 'Org');
      expect(course.rightsHolders.single.type, CourseRightsHolderType.person);
    });

    testWidgets('a licence of the list is stored with its own policy', (
      tester,
    ) async {
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
      await _enter(tester, _field('Course title *'), 'Credits by hand');
      await _enter(tester, _field('Source language *'), 'English');
      await _enter(tester, _field('Target language *'), 'Italian');
      await _choose(tester, 'Course content license', 'CC BY-NC-SA 4.0');
      final create = find.widgetWithText(FilledButton, 'Continue to Editor');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      final course = tester
          .widget<CourseEditorScreen>(find.byType(CourseEditorScreen))
          .course;
      expect(course.license, 'CC BY-NC-SA 4.0');
      expect(course.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);
      expect(course.rightsHolders, isEmpty);
    });
  });

  group('Course Wizard', () {
    testWidgets('roles as in Course Info; a licence of the list is stored '
        'with its own policy; a custom licence keeps the policy shown', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final stored = (await tester.runAsync(
        () => _store(
          _course(
            license: 'CC BY 4.0',
            policy: DerivativeWorksPolicy.unspecified,
          ),
        ),
      ))!;
      await tester.pumpWidget(
        MaterialApp(
          home: CourseWizardScreen(
            course: stored,
            access: CourseAccessPolicy.evaluate(stored, profileId: _profileId),
            pause: CourseWizardPause(
              step: CourseWizardStep.about,
              savedAtUtc: DateTime.utc(2026, 10, 12),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _tapFinder(tester, find.byKey(const Key('course-wizard-advanced')));

      expect(_chip(tester, 'Author', 0).selected, isTrue);
      expect(_chip(tester, 'Editor', 0).selected, isTrue);
      expect(_texts(tester, 'Other roles'), ['Voice, Subtitles']);
      await _enter(tester, _field('Other roles'), ' Sound , Author,, Sound');

      Future<Course> saveNow() async {
        final save = find.byKey(const Key('course-wizard-save-now'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpUntilFileIoState(
          () => find.text('Saved.').evaluate().isNotEmpty,
        );
        // The message leaves before the next save.
        ScaffoldMessenger.of(
          tester.element(find.byType(CourseWizardScreen)),
        ).clearSnackBars();
        await tester.pumpAndSettle();
        return (await tester.runAsync(
          () => CourseEditorService().listUserCourses(),
        ))!.single;
      }

      // The Wizard stores the policy of the licence of the list, whatever
      // the Course stored before.
      var saved = await saveNow();
      expect(saved.authors.single.roles, ['Author', 'Editor', 'Sound']);
      expect(saved.license, 'CC BY 4.0');
      expect(saved.derivativeWorksPolicy, DerivativeWorksPolicy.allowed);

      await _choose(tester, 'Course content license', 'All rights reserved');
      await _choose(tester, 'Course content license', 'Other / Custom license');
      // The Wizard leaves the Custom license field empty for a licence of
      // the list, and Save now says what is missing.
      expect(_texts(tester, 'Custom license'), ['']);
      final saveNow0 = find.byKey(const Key('course-wizard-save-now'));
      await tester.ensureVisible(saveNow0);
      await tester.tap(saveNow0);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Type the custom license, or choose a license from the list.',
        ),
        findsOneWidget,
      );
      ScaffoldMessenger.of(
        tester.element(find.byType(CourseWizardScreen)),
      ).clearSnackBars();
      await tester.pumpAndSettle();
      // All rights reserved forbade derivative works; the custom licence
      // keeps that.
      expect(
        tester
            .widget<DropdownButtonFormField<DerivativeWorksPolicy>>(
              find.byType(DropdownButtonFormField<DerivativeWorksPolicy>),
            )
            .initialValue,
        DerivativeWorksPolicy.forbidden,
      );
      await _enter(tester, _field('Custom license'), ' My terms ');
      await _tapFinder(
        tester,
        find.byKey(const Key('course-wizard-add-rights-holder')),
      );
      await _enter(tester, _field('Rights Holder'), ' Org ');

      saved = await saveNow();
      expect(saved.license, 'My terms');
      expect(saved.derivativeWorksPolicy, DerivativeWorksPolicy.forbidden);
      expect(saved.rightsHolders.single.name, 'Org');
    });
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Credits Author',
);

Course _course({
  required String license,
  required DerivativeWorksPolicy policy,
}) => Course(
  courseId: 'credits-272',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Credits Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Credits Course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  authors: const [
    // Stored out of the standard order, with two roles of the author's own.
    CourseAuthor(
      name: 'Ann',
      roles: ['Editor', 'Voice', 'Author', 'Subtitles'],
    ),
  ],
  license: license,
  derivativeWorksPolicy: policy,
  lessons: [Lesson(lessonId: 'credits-lesson', title: 'Lesson', rounds: [])],
);

Course _host() => Course(
  courseId: 'credits-host',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Host',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

Future<Course> _store(Course course) async {
  final session = CourseAuthoringSession(
    course: course,
    access: CourseAccessPolicy.evaluate(
      course,
      profileId: _profileId,
    ).copyForUnconfirmedCreator(),
    editorService: CourseEditorService(),
    isNewCourse: true,
  )..setEditorMode(CourseEditorMode.edit);
  return (await session.confirm(
    languageCode: 'IT',
    versionNotes: 'Stored for the test',
  )).course;
}

/// The Course Editor on [course], then its Course Info Editor.
Future<void> _openCourseInfo(
  WidgetTester tester,
  CourseEditorService service,
  Course course, {
  bool store = true,
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (store) {
    await SettingsService().markAudioOrphanCheckRun('IT');
    await SettingsService().setCourseEditorMode(
      course.courseId,
      CourseEditorMode.edit,
    );
    await tester.runAsync(() => service.saveUserCourse(course));
  }
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push<CourseConfirmationResult>(
            MaterialPageRoute(
              builder: (_) => CourseEditorScreen(
                course: course,
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
}

/// Apply in Course Info, leave the Course Editor saving, and the stored
/// Course.
Future<Course> _applyAndSave(
  WidgetTester tester,
  CourseEditorService service,
) async {
  final apply = find.byKey(const Key('course-info-save'));
  await tester.ensureVisible(apply);
  await tester.tap(apply);
  await tester.pumpUntilFileIoState(() => apply.evaluate().isEmpty);
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-course-changes')));
  await tester.pumpUntilFileIoState(
    () => find.byType(CourseEditorScreen).evaluate().isEmpty,
  );
  return (await tester.runAsync(() => service.listUserCourses()))!.single;
}

/// The credits of [course]: each name with its roles in the stored order.
Map<String, List<String>> _credits(Course course) => {
  for (final author in course.authors) author.name: author.roles,
};

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

List<String> _texts(WidgetTester tester, String label) => [
  for (final field in tester.widgetList<TextField>(_field(label)))
    field.controller!.text,
];

FilterChip _chip(WidgetTester tester, String role, int row) =>
    tester.widget<FilterChip>(find.widgetWithText(FilterChip, role).at(row));

Future<void> _enter(WidgetTester tester, Finder field, String value) async {
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) =>
    _tapFinder(tester, find.text(text));

/// Choose [value] in the list labelled [label].
Future<void> _choose(WidgetTester tester, String label, String value) async {
  final list = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<String> &&
        widget.decoration.labelText == label,
  );
  await tester.ensureVisible(list);
  await tester.pump();
  await tester.tap(list);
  await tester.pumpAndSettle();
  await tester.tap(find.text(value).last);
  await tester.pumpAndSettle();
}
