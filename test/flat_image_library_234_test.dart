import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'Course Editor Media Library shows tags and searches normalized metadata',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: FlatImageLibraryScreen(readOnly: true)),
      );
      await tester.pumpAndSettle();

      Future<void> search(String query) async {
        await tester.enterText(find.byType(TextField), query);
        await tester.pump();
      }

      // Build 265 Revision 5: "friend" finds the picture Friends, no
      // longer the man.
      await search('adult man');
      expect(find.text('man'), findsOneWidget);
      expect(find.text('QQL'), findsWidgets);
      // The name is never repeated among the tags (Build 264). Man 2 and
      // Man 3 share Man's tags (Build 265 Revision 11): read Man's own tile.
      const uomoTags = 'Tags: adult man, male, adult, grown man, gentleman';
      final manTags = find.descendant(
        of: find.byKey(const ValueKey('exercise-image-people_family_man')),
        matching: find.text(uomoTags),
      );
      expect(manTags, findsOneWidget);
      await tester.tap(find.text('man'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text(
            'Source: QQL · App bundled; supplied by QQL on every device.',
          ),
        ),
        findsOneWidget,
      );
      // Since Build 264 Revision 5 the card lists each tag as a link.
      expect(manTags, findsOneWidget);
      const previewTags = [
        'adult man',
        'male',
        'adult',
        'grown man',
        'gentleman',
      ];
      for (final (index, tag) in previewTags.indexed) {
        expect(
          find.descendant(
            of: find.byKey(Key('image-preview-tag-$index')),
            matching: find.text(tag),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(Key('image-preview-tag-${previewTags.length}')),
        findsNothing,
      );
      expect(find.textContaining('Keywords:'), findsNothing);
      await tester.tap(find.byTooltip('Close preview'));
      await tester.pumpAndSettle();

      await search('people_family_man');
      expect(find.text('man'), findsOneWidget);

      // A category name finds its pictures. Since Build 264 the family
      // category holds 36 pictures; the first ones by name are on screen.
      await search('people family');
      expect(find.text('ancestor'), findsOneWidget);
      expect(find.text('baby'), findsOneWidget);

      await search('leap');
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'jump',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Tags: jumping, leap, hop, jump for joy, jump up'),
        findsOneWidget,
      );
    },
  );
}
