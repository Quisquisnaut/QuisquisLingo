import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_version_history_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 272 Revision 1: the Course Info Editor as an author meets it. These
/// cases were written on the code before the dialog got its form owner and
/// its own file, and passed there. Credits and licence are in
/// `course_credits_272_test.dart`; the descriptive fields, the cover, the
/// backups kept, the Maintainer and the Team have their own earlier tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [_profile.encode()],
      ProfileService.activeProfileIdKey: _profileId,
    }),
  );

  testWidgets('a media credit needs an author and a licence, each credit '
      'once; a row left blank is not stored', (tester) async {
    final service = CourseEditorService();
    await _openCourseInfo(tester, service, _course());
    Finder media(String field, int row) =>
        find.byKey(ValueKey('course-info-media-$field-$row'));
    final error = find.byKey(const Key('course-info-media-credit-error'));
    final apply = find.byKey(const Key('course-info-save'));
    // Apply reads the stored Courses for the name warning before it checks
    // the rest, so the message comes after that reading.
    Future<void> applyUntilMessage(String message) async {
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpUntilFileIoState(
        () =>
            tester.widgetList<Text>(error).any((text) => text.data == message),
      );
    }

    // The list starts with one blank row.
    expect(media('author', 0), findsOneWidget);
    expect(media('author', 1), findsNothing);
    expect(error, findsNothing);

    await _enter(tester, media('author', 0), 'Ada');
    await applyUntilMessage(
      'Each media credit needs both an author and a licence. '
      'Complete row 1 or clear it.',
    );
    expect(apply, findsOneWidget);

    await _enter(tester, media('license', 0), ' CC0 ');
    await _enter(tester, media('title', 0), ' Portrait ');
    await _tap(tester, find.byKey(const Key('course-info-add-media-credit')));
    await _enter(tester, media('author', 1), ' Ada');
    await _enter(tester, media('license', 1), 'CC0');
    await _enter(tester, media('title', 1), 'Portrait');
    await applyUntilMessage('Row 2 repeats an identical media credit.');
    expect(apply, findsOneWidget);

    // Removing a row takes the message away.
    await _tap(tester, find.byTooltip('Remove media credit').at(1));
    expect(media('author', 1), findsNothing);
    expect(error, findsNothing);
    // The only row left cannot be removed.
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.remove_circle_outline).last,
          )
          .onPressed,
      isNull,
    );

    await _tap(tester, find.byKey(const Key('course-info-add-media-credit')));
    final saved = await _applyAndSave(tester, service);
    expect(saved.toJson()['mediaAttributions'], [
      {'author': 'Ada', 'license': 'CC0', 'title': 'Portrait'},
    ]);
  });

  testWidgets('a name another Course has asks first; a name that cannot be '
      'stored is refused', (tester) async {
    final service = CourseEditorService();
    await tester.runAsync(
      () => service.saveUserCourse(
        _course(courseId: 'info-272-other', title: 'Taken Name'),
      ),
    );
    await _openCourseInfo(tester, service, _course());
    final name = find.byKey(const Key('course-info-title'));
    final apply = find.byKey(const Key('course-info-save'));

    await _enter(tester, name, '   ');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(apply, findsOneWidget);
    ScaffoldMessenger.of(tester.element(apply)).clearSnackBars();
    await tester.pumpAndSettle();

    // Capitals do not make a name another one.
    await _enter(tester, name, 'taken name');
    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpUntilFileIoState(
      () => find.text('Course name already exists').evaluate().isNotEmpty,
    );
    expect(find.text('A Course with this name already exists.'), findsOne);
    await tester.tap(find.text('Edit name'));
    await tester.pumpAndSettle();
    expect(find.text('Course name already exists'), findsNothing);
    expect(apply, findsOneWidget);

    await tester.ensureVisible(apply);
    await tester.tap(apply);
    await tester.pumpUntilFileIoState(
      () => find.text('Course name already exists').evaluate().isNotEmpty,
    );
    await tester.tap(find.text('Continue anyway'));
    await tester.pumpUntilFileIoState(() => apply.evaluate().isEmpty);
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isEmpty,
    );
    final stored = (await tester.runAsync(() => service.listUserCourses()))!;
    expect(
      stored.singleWhere((course) => course.courseId == 'info-272').title,
      'taken name',
    );
  });

  testWidgets('Private course, page sharing and the learners\' name of the '
      'language are stored; Cancel changes nothing', (tester) async {
    final service = CourseEditorService();
    await _openCourseInfo(tester, service, _course());
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('course-info-private')))
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('course-info-page-sharing')),
          )
          .value,
      isTrue,
    );
    await _tap(tester, find.byKey(const Key('course-info-private')));
    await _tap(tester, find.byKey(const Key('course-info-page-sharing')));
    final learnerName = find.byKey(
      const Key('course-info-learner-language-name'),
    );
    // QQL's own name of the language shows while the field is empty, and
    // the help under the field names it.
    expect(
      tester.widget<TextField>(learnerName).decoration!.hintText,
      'Italian',
    );
    expect(
      find.text(
        'How this Course’s learners call the language they learn, in lines '
        'such as “Translate into …”. Leave it empty for “Italian”.',
      ),
      findsOneWidget,
    );
    // The other texts of the dialog that carry a value of the Course.
    expect(find.text('Rights Holder 1'), findsOneWidget);
    expect(find.text('Media credit 1'), findsOneWidget);
    expect(
      find.textContaining('This is build ${Course.appBuildNumber}.'),
      findsOneWidget,
    );
    await _enter(tester, learnerName, ' italiano ');
    var saved = await _applyAndSave(tester, service);
    expect(saved.temporarySample, isTrue);
    expect(saved.allowPageSharing, isFalse);
    expect(saved.targetLanguageNameForLearners, 'italiano');

    await _openCourseInfo(tester, service, saved, store: false);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('course-info-private')))
          .value,
      isTrue,
    );
    await _enter(
      tester,
      find.byKey(const Key('course-info-title')),
      'Never applied',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('course-info-save')), findsNothing);
    // Nothing was applied, so leaving the Course Editor asks nothing.
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isEmpty,
    );
    expect(find.byKey(const Key('confirm-course-changes')), findsNothing);
    saved = (await tester.runAsync(() => service.listUserCourses()))!.single;
    expect(saved.title, 'Info Course');
  });

  testWidgets('the tags of the Course\'s own languages come from the list', (
    tester,
  ) async {
    final service = CourseEditorService();
    await _openCourseInfo(tester, service, _course());
    expect(find.text('Read-only · no language tag'), findsNWidgets(2));
    final add = find.byKey(const Key('course-info-language-tags'));
    await _tap(tester, add);
    // English and Italian are languages QQL knows: no question is asked.
    expect(find.text('Read-only · tag en'), findsOneWidget);
    expect(find.text('Read-only · tag it'), findsOneWidget);
    expect(add, findsNothing);
    final saved = await _applyAndSave(tester, service);
    expect(saved.sourceLanguageTag, 'en');
    expect(saved.targetLanguageTag, 'it');
  });

  testWidgets('Version history closes the Course Info Editor and opens', (
    tester,
  ) async {
    final service = CourseEditorService();
    await _openCourseInfo(tester, service, _course());
    // The Course Editor's own Version history entry is behind the dialog.
    final entry = find.text('Version history').last;
    await tester.ensureVisible(entry);
    await tester.pump();
    await tester.tap(entry);
    // The Version history page reads the backups from the disk.
    await tester.pumpUntilFileIoState(
      () =>
          find.byType(CourseVersionHistoryScreen).evaluate().isNotEmpty &&
          find.byKey(const Key('course-info-save')).evaluate().isEmpty,
    );
    expect(find.byKey(const Key('course-info-save')), findsNothing);
    expect(find.byType(CourseVersionHistoryScreen), findsOneWidget);
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Info Author',
);

Course _course({String courseId = 'info-272', String title = 'Info Course'}) =>
    Course(
      courseId: courseId,
      originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
        profileId: _profileId,
        displayName: 'Info Author',
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
      lessons: [
        Lesson(lessonId: '$courseId-lesson', title: 'Lesson', rounds: []),
      ],
    );

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

Future<void> _enter(WidgetTester tester, Finder field, String value) async {
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
