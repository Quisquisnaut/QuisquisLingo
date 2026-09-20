import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/editor_help_content.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Course Editor Help translation', () {
    for (final italian in [false, true]) {
      testWidgets(
        'four columns fit a narrow ${italian ? 'Italian' : 'English'} Help page',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
          if (italian) {
            await tester.tap(
              find.byKey(const Key('editor-help-language-toggle')),
            );
            await tester.pump();
          }
          final table = find.byKey(const Key('editor-help-course-types-table'));
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

    test('both languages carry the same sections in the same order', () {
      final english = editorHelpSections(HelpLanguage.english);
      final italian = editorHelpSections(HelpLanguage.italian);

      expect(english, hasLength(37));
      expect(italian, hasLength(english.length));
      for (var index = 0; index < english.length; index++) {
        expect(
          italian[index].title.trim(),
          isNotEmpty,
          reason: 'Italian title missing at $index',
        );
        expect(
          italian[index].body,
          isNot(english[index].body),
          reason: '"${english[index].title}" is untranslated',
        );
      }
    });

    test('media Help describes both import routes in both languages', () {
      // Build 240 added the system file dialog next to the fixed folder, but
      // the media Help entries kept claiming there was no file picker. Assert
      // the dialog route is documented so the two cannot drift apart again.
      for (final language in HelpLanguage.values) {
        final sections = editorHelpSections(language);
        for (final title in const ['Audio Library', 'Image Bank']) {
          final body = sections
              .firstWhere((section) => section.title == title)
              .body;
          expect(
            body,
            contains('from…'),
            reason: '$title ($language) does not mention Open from…',
          );
          expect(
            body,
            contains('Documents/QuisquisLingo/Imports/'),
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

    test('the Technical reference card warns that its links are English', () {
      expect(editorHelpTechnicalIntro(HelpLanguage.english).note, isEmpty);
      expect(
        editorHelpTechnicalIntro(HelpLanguage.italian).note,
        contains('inglese'),
      );
    });

    test('Italian keeps on-screen names in English', () {
      final italian = editorHelpSections(
        HelpLanguage.italian,
      ).map((section) => section.body).join('\n');
      for (final label in const [
        'Course Manager',
        'Save as draft',
        'Confirm course changes',
        'View only',
        'Inspection mode',
        'Use GuideBook',
        'Create Duels',
        'Export Course JSON',
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
      expect(find.text('Course types'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor-help-language-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Guida all’Editor'), findsOneWidget);
      expect(find.text('Riferimento tecnico'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Tipi di corso'), 200);
      await tester.pump();
      expect(find.text('Tipi di corso'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Editor Help'), findsNothing);

      await tester.tap(find.byKey(const Key('editor-help-language-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Editor Help'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
    });

    testWidgets('the links out stay English in both languages', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Audit Codes'), findsOneWidget);

      await tester.tap(find.byKey(const Key('editor-help-language-toggle')));
      await tester.pumpAndSettle();

      // They name English-only screens, so translating the label would send
      // the reader somewhere that does not match what they tapped.
      expect(find.text('Audit Codes'), findsOneWidget);
      expect(find.text('Exercise types'), findsOneWidget);
    });
  });
}
