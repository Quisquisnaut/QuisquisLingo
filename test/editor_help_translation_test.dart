import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/editor_help_content.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile('Help Reader');
  });

  Future<void> selectLocale(
    WidgetTester tester,
    String selectorKey,
    String id,
  ) async {
    await tester.tap(find.byKey(Key(selectorKey)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(id).last);
    await tester.pumpAndSettle();
  }

  group('Course Help translation', () {
    for (final italian in [false, true]) {
      testWidgets(
        'four columns fit a narrow ${italian ? 'Italian' : 'English'} Help page',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            const MaterialApp(home: CourseManagerHelpScreen()),
          );
          if (italian) {
            await selectLocale(
              tester,
              'course-manager-help-language-toggle',
              'IT',
            );
          }
          final table = find.byKey(
            const Key('course-manager-help-course-types-table'),
          );
          await tester.scrollUntilVisible(table, 250);
          await tester.pump();
          final bounds = tester.getRect(table);
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(320));
          for (final label in [
            'Official Bundled',
            'Publisher Course',
            'Custom',
          ]) {
            final header = find.descendant(
              of: table,
              matching: find.text(label),
            );
            expect(header, findsOneWidget);
            final cell = tester.getRect(header);
            expect(cell.left, greaterThanOrEqualTo(bounds.left));
            expect(cell.right, lessThanOrEqualTo(bounds.right));
            expect(tester.widget<Text>(header).style?.fontSize, 12);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    test(
      'Editor Help is questions and answers; Manager keeps its sections',
      () {
        // Build 256 Revision 8: Editor Help is questions in seven topics (66;
        // 67 since Build 257's Before you start question, 68 with Build 258's
        // Page question). Build 261 Revision 7 adds Round Types as an eighth.
        final english = editorHelpTopics(HelpLanguage.english);
        final italian = editorHelpTopics(HelpLanguage.italian);
        final spanish = editorHelpTopics(HelpLanguage.spanish);
        final managerEnglish = courseManagerHelpSections(HelpLanguage.english);
        final managerItalian = courseManagerHelpSections(HelpLanguage.italian);
        final managerSpanish = courseManagerHelpSections(HelpLanguage.spanish);

        List<String> ids(List<EditorHelpTopic> topics) => [
          for (final topic in topics)
            for (final question in topic.questions)
              '${topic.id}.${question.id}',
        ];
        expect(english, hasLength(8));
        // Build 259 Revision 6 removed the Temporary Sample question.
        // Revision 8 added What is a Private course?
        // Build 260 Revisions 0 and 5 added the Course languages and
        // difficulty questions.
        expect(ids(english), hasLength(82));
        expect(ids(italian), ids(english));
        expect(ids(spanish), ids(english));
        // Build 262 Revision 2 adds Export as Publisher Course.
        expect(managerEnglish, hasLength(15));
        expect(managerItalian, hasLength(managerEnglish.length));
        expect(managerSpanish, hasLength(managerEnglish.length));
        expect(english.map((topic) => topic.title), [
          'Getting started',
          'Saving and versions',
          'Course settings',
          'Lessons and Rounds',
          'Round Types',
          'Exercises',
          'Pictures and sound',
          'Checking the Course',
        ]);
        expect(
          managerEnglish.map((section) => section.title),
          containsAll([
            'Course origin',
            'Create a new course',
            'Course creation rules',
            'Import a custom course',
            'Export a custom course',
            'Export as Publisher Course',
            'Course responsibility, permissions and Teams',
            'Android device backup (technical)',
            'Course operations',
          ]),
        );
        for (final title in [
          'Course Audit',
          'Audit severity and codes',
          'Local course edits and backups',
          'Course Info Editor and license',
        ]) {
          expect(
            managerEnglish.map((section) => section.title),
            contains(title),
          );
        }
        for (final translated in [italian, spanish]) {
          for (var t = 0; t < english.length; t++) {
            expect(translated[t].title, isNot(english[t].title));
            for (var q = 0; q < english[t].questions.length; q++) {
              final source = english[t].questions[q];
              final other = translated[t].questions[q];
              expect(other.question, isNot(source.question), reason: source.id);
              expect(other.answer, isNot(source.answer), reason: source.id);
              expect(
                other.answer,
                isNot(contains('{folder')),
                reason: source.id,
              );
            }
          }
        }
        for (var index = 0; index < managerEnglish.length; index++) {
          expect(managerItalian[index].title.trim(), isNotEmpty);
          expect(
            managerItalian[index].body,
            isNot(managerEnglish[index].body),
            reason: 'Manager section at $index is untranslated',
          );
        }
        final operations = managerEnglish
            .singleWhere((section) => section.title == 'Course operations')
            .body;
        final browsing = managerEnglish
            .singleWhere((section) => section.title == 'Finding Courses')
            .body;
        expect(browsing, contains('Search'));
        expect(browsing, contains('Favorites'));
        expect(browsing, contains('Show unavailable'));
        final italianBrowsing = managerItalian
            .singleWhere((section) => section.title == 'Trovare i corsi')
            .body;
        expect(italianBrowsing, contains('Search'));
        expect(italianBrowsing, contains('Favorites'));
        for (final action in [
          'Copy as New Course',
          'Fork',
          'Merge',
          'Delete course',
          'Remove Publisher Course from device',
        ]) {
          expect(operations, contains(action));
        }
      },
    );

    test('media Help describes both import routes in both languages', () {
      // Build 240 added the system file dialog next to the fixed folder, but
      // the media Help entries kept claiming there was no file picker. Assert
      // the dialog route is documented so the two cannot drift apart again.
      for (final language in HelpLanguage.values) {
        final answers = {
          for (final topic in editorHelpTopics(language))
            for (final question in topic.questions)
              question.id: question.answer,
        };
        for (final title in const ['addRecordings', 'addPictures']) {
          final body = answers[title]!;
          expect(
            body,
            contains('from…'),
            reason: '$title ($language) does not mention Open from…',
          );
          expect(
            body,
            contains('Documents/QuisquisLingo/Import/'),
            reason: '$title ($language) dropped the fixed-folder route',
          );
          expect(
            body,
            isNot(contains('without a file picker')),
            reason: '$title ($language) still denies the file picker',
          );
          expect(
            body,
            isNot(contains('senza finestra di selezione file')),
            reason: '$title ($language) still denies the file picker',
          );
        }
      }
    });

    test('the Course types table keeps its shape in both languages', () {
      final english = editorHelpCourseTypes(HelpLanguage.english);
      final italian = editorHelpCourseTypes(HelpLanguage.italian);

      expect(italian.rows, hasLength(english.rows.length));
      expect(italian.types, hasLength(english.types.length));
      expect(english.types, hasLength(3));
      expect(italian.notes, hasLength(english.notes.length));
      for (var row = 0; row < english.rows.length; row++) {
        expect(
          italian.rows[row],
          hasLength(4),
          reason: 'Italian row $row is not four columns',
        );
        expect(english.rows[row], hasLength(4));
      }
      // Course-type names are product terms, not translated prose.
      expect(italian.rows.first.skip(1), [
        'Official Bundled',
        'Publisher Course',
        'Custom',
      ]);
    });

    test('the Technical reference card uses localized descriptions', () {
      expect(editorHelpTechnicalIntro(HelpLanguage.english).note, isEmpty);
      expect(editorHelpTechnicalIntro(HelpLanguage.italian).note, isEmpty);
      expect(
        editorHelpTechnicalIntro(HelpLanguage.italian).body,
        isNot(editorHelpTechnicalIntro(HelpLanguage.english).body),
      );
    });

    test('Italian keeps on-screen names in English', () {
      final italian = [
        for (final topic in editorHelpTopics(HelpLanguage.italian))
          for (final question in topic.questions) question.answer,
      ].join('\n');
      for (final label in const [
        'Save as draft',
        'Confirm course changes',
        'View only',
        'Inspection mode',
        'Use GuideBook',
        'Create Duels',
        'Import Image Bank ZIP',
        'Course Maintainer',
      ]) {
        expect(italian, contains(label), reason: '$label was translated away');
      }
    });

    testWidgets('the toggle swaps the page between English and Italian', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Editor Help'), findsOneWidget);
      expect(find.text('Technical reference'), findsOneWidget);
      expect(find.text('Course types'), findsNothing);
      expect(find.text('EN'), findsOneWidget);

      await selectLocale(tester, 'editor-help-language-toggle', 'IT');

      expect(find.text('Guida all’Editor'), findsOneWidget);
      expect(find.text('Riferimento tecnico'), findsOneWidget);
      expect(find.text('Tipi di corso'), findsNothing);
      expect(find.text('IT'), findsOneWidget);
      expect(find.text('Editor Help'), findsNothing);

      await selectLocale(tester, 'editor-help-language-toggle', 'EN');

      expect(find.text('Editor Help'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('the links out stay English in both languages', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Audit Codes'), findsOneWidget);

      await selectLocale(tester, 'editor-help-language-toggle', 'IT');

      // They name English-only screens, so translating the label would send
      // the reader somewhere that does not match what they tapped.
      expect(find.text('Audit Codes'), findsOneWidget);
      expect(find.text('Exercise types'), findsOneWidget);
    });

    testWidgets(
      'Manager Help has course types and a Locale selector but no technical reference',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CourseManagerHelpScreen()),
        );
        expect(find.text('Course Studio Help'), findsOneWidget);
        expect(find.text('Course types'), findsOneWidget);
        expect(find.text('Technical reference'), findsNothing);

        await selectLocale(tester, 'course-manager-help-language-toggle', 'IT');
        expect(find.text('Guida al Course Studio'), findsOneWidget);
        expect(find.text('Tipi di corso'), findsOneWidget);
        expect(find.text('Riferimento tecnico'), findsNothing);
      },
    );
  });
}
