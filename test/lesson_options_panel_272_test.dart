import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 272 Revision 4: the Course Editor's Lesson Options as an author
/// meets them. These cases were written on the code before the options got
/// their owner and their own panel, and passed there. The numbering menus
/// with Cancel, Use GuideBook, Word Lookup, Create Duels, the picture size,
/// shape and number per row, and the first default Timed limit have their
/// own earlier tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(
    () => SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [_profile.encode()],
      ProfileService.activeProfileIdKey: _profileId,
    }),
  );

  testWidgets('a custom Round label, the picture border and the default '
      'Timed limits are staged and saved', (tester) async {
    final service = CourseEditorService();
    await _openLessonOptions(tester, service, CourseEditorMode.edit);

    // ---- Round label and numbering: Custom asks for the label.
    await _choose<RoundNumberingMode>(tester, 'Custom + number');
    expect(find.text('Custom Round label'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      ' Turn ',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    // The label is in the menu and on the line under it.
    expect(find.text('Turn + number'), findsOneWidget);
    expect(find.text('Custom Round label: Turn'), findsOneWidget);

    // ---- Lesson label and numbering: another numbering drops a custom
    // label.
    await _choose<LessonNumberingMode>(tester, 'Custom + number');
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Step',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Custom Lesson label: Step'), findsOneWidget);
    await _choose<LessonNumberingMode>(tester, 'Number only');
    expect(find.textContaining('Custom Lesson label:'), findsNothing);

    // ---- Picture border.
    await _choose<PictureBorder>(tester, 'Thin grey line');

    // ---- Default Timed limits: add three, replace one, move, remove.
    final add = find.byKey(const Key('default-timed-limit-add'));
    Future<void> addLimit(int seconds) async {
      await tester.ensureVisible(add);
      await tester.pump();
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('timed-limit-$seconds')));
      await tester.pumpAndSettle();
    }

    await addLimit(60);
    await addLimit(120);
    await addLimit(300);
    expect(find.text('Stage 1 · 1 min'), findsOneWidget);
    expect(find.text('Stage 2 · 2 min'), findsOneWidget);
    expect(find.text('Stage 3 · 5 min'), findsOneWidget);
    // The first stage cannot go up, the last cannot go down.
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('default-timed-limit-up-0')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('default-timed-limit-down-2')),
          )
          .onPressed,
      isNull,
    );

    // A stage tapped takes another limit; a limit another stage has is
    // refused; its own limit again changes nothing.
    final second = find.byKey(const Key('default-timed-limit-1'));
    await tester.ensureVisible(second);
    await tester.pump();
    await tester.tap(second);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timed-limit-60')));
    await tester.pumpAndSettle();
    expect(find.text('Each Timed limit must be different.'), findsOneWidget);
    expect(find.text('Stage 2 · 2 min'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(add)).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.ensureVisible(second);
    await tester.pump();
    await tester.tap(second);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timed-limit-120')));
    await tester.pumpAndSettle();
    expect(find.text('Each Timed limit must be different.'), findsNothing);
    expect(find.text('Stage 2 · 2 min'), findsOneWidget);

    await tester.ensureVisible(second);
    await tester.pump();
    await tester.tap(second);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timed-limit-90')));
    await tester.pumpAndSettle();
    expect(find.text('Stage 2 · 90 sec'), findsOneWidget);

    Future<void> tapKey(String key) async {
      final button = find.byKey(Key(key));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    // 60, 90, 300 -> the first goes down -> 90, 60, 300.
    await tapKey('default-timed-limit-down-0');
    expect(find.text('Stage 1 · 90 sec'), findsOneWidget);
    expect(find.text('Stage 2 · 1 min'), findsOneWidget);
    // -> the last goes up -> 90, 300, 60.
    await tapKey('default-timed-limit-up-2');
    expect(find.text('Stage 2 · 5 min'), findsOneWidget);
    expect(find.text('Stage 3 · 1 min'), findsOneWidget);
    // -> the first is removed -> 300, 60.
    await tapKey('default-timed-limit-remove-0');
    expect(find.text('Stage 1 · 5 min'), findsOneWidget);
    expect(find.text('Stage 2 · 1 min'), findsOneWidget);
    expect(find.byKey(const Key('default-timed-limit-2')), findsNothing);

    // ---- Leave saving: what the Course stores.
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isEmpty,
    );
    final saved = (await tester.runAsync(
      () => service.listUserCourses(),
    ))!.single;
    expect(saved.roundNumberingMode, RoundNumberingMode.customAndNumber);
    expect(saved.customRoundLabel, 'Turn');
    expect(saved.lessonNumberingMode, LessonNumberingMode.numberOnly);
    expect(saved.customLessonLabel, isEmpty);
    expect(saved.pictureAnswers.border, PictureBorder.thin);
    expect(saved.defaultTimedLimitsSeconds, [300, 60]);
    expect(saved.toJson()['pictureAnswers'], isNotNull);
  });

  // The two cases below were added after the independent review of the
  // move: they passed on the code before it, and the first version of the
  // panel failed them.
  testWidgets('two options changed in the same moment are both kept', (
    tester,
  ) async {
    final service = CourseEditorService();
    await _openLessonOptions(tester, service, CourseEditorMode.edit);
    final duels = find.byKey(const Key('course-create-duels'));
    final lookup = find.byKey(const Key('course-word-lookup'));
    final duelsBefore = tester.widget<SwitchListTile>(duels).value;
    final lookupBefore = tester.widget<SwitchListTile>(lookup).value;
    // No frame between the two taps: the second change starts from the
    // Course the first one made.
    await tester.tap(duels);
    await tester.tap(lookup);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(duels).value, !duelsBefore);
    expect(tester.widget<SwitchListTile>(lookup).value, !lookupBefore);
  });

  testWidgets('a label typed while the list has let go of Lesson Options is '
      'still applied', (tester) async {
    final service = CourseEditorService();
    // A short window, so the page is much longer than what is seen.
    await _openLessonOptions(
      tester,
      service,
      CourseEditorMode.edit,
      size: const Size(700, 700),
    );
    final tile = find.byKey(const Key('course-lesson-options'));
    final page = tester
        .state<ScrollableState>(
          find.ancestor(of: tile, matching: find.byType(Scrollable)).first,
        )
        .position;
    // The custom Round label is asked for.
    tester
        .widget<DropdownButtonFormField<RoundNumberingMode>>(
          find.byType(DropdownButtonFormField<RoundNumberingMode>),
        )
        .onChanged!(RoundNumberingMode.customAndNumber);
    await tester.pumpAndSettle();
    expect(find.text('Custom Round label'), findsOneWidget);

    // Lesson Options is one item of the page's list, and a list lets go of
    // an item far from what is seen. Under the dialog the page moves to its
    // end: the panel is no longer there, the Course Editor page is.
    page.jumpTo(page.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tile, findsNothing);
    expect(find.byType(CourseEditorScreen), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Turn',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();

    // Back at Lesson Options: the label is in the Course.
    page.jumpTo(0);
    await tester.pumpAndSettle();
    if (find.text('Round label and numbering').evaluate().isEmpty) {
      await tester.ensureVisible(tile);
      await tester.pump();
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }
    expect(find.text('Custom Round label: Turn'), findsOneWidget);
  });

  testWidgets('in View only every Lesson Option is greyed', (tester) async {
    final service = CourseEditorService();
    await _openLessonOptions(tester, service, CourseEditorMode.viewOnly);
    for (final key in ['course-use-guidebook', 'course-create-duels']) {
      expect(
        tester.widget<SwitchListTile>(find.byKey(Key(key))).onChanged,
        isNull,
        reason: key,
      );
    }
    expect(
      tester
          .widget<DropdownButtonFormField<LessonNumberingMode>>(
            find.byType(DropdownButtonFormField<LessonNumberingMode>),
          )
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<PictureBorder>>(
            find.byType(DropdownButtonFormField<PictureBorder>),
          )
          .onChanged,
      isNull,
    );
    expect(find.byKey(const Key('default-timed-limit-add')), findsNothing);
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _profile = LearnerProfile(
  learnerProfileId: _profileId,
  displayName: 'Options Author',
);

Course _course() => Course(
  courseId: 'options-272',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Options Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Options Course',
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: [Lesson(lessonId: 'options-lesson', title: 'Lesson', rounds: [])],
);

/// The Course Editor in [mode] on a stored Course, with Lesson Options
/// open.
Future<void> _openLessonOptions(
  WidgetTester tester,
  CourseEditorService service,
  CourseEditorMode mode, {
  Size size = const Size(1000, 3200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final course = _course();
  await SettingsService().markAudioOrphanCheckRun('IT');
  await SettingsService().setCourseEditorMode(course.courseId, mode);
  await tester.runAsync(() => service.saveUserCourse(course));
  await tester.pumpWidget(
    MaterialApp(
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
  final options = find.byKey(const Key('course-lesson-options'));
  await tester.ensureVisible(options);
  await tester.pump();
  await tester.tap(options);
  await tester.pumpAndSettle();
}

/// Choose the entry reading [text] in the menu of values of type [T].
Future<void> _choose<T>(WidgetTester tester, String text) async {
  final menu = find.byType(DropdownButtonFormField<T>);
  await tester.ensureVisible(menu);
  await tester.pump();
  await tester.tap(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}
