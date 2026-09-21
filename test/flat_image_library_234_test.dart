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

      await search('friend');
      expect(find.text('man'), findsOneWidget);
      expect(find.text('QQL'), findsWidgets);
      const uomoTags = 'Tags: man, adult man, male, friend';
      expect(find.text(uomoTags), findsOneWidget);
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
      expect(find.text(uomoTags), findsNWidgets(2));
      final previewTagsFinder = find.descendant(
        of: find.byType(Dialog),
        matching: find.text(uomoTags),
      );
      final previewTags = tester.widget<Text>(previewTagsFinder);
      expect(previewTags.maxLines, 2);
      expect(previewTags.overflow, TextOverflow.ellipsis);
      final previewTooltip = tester.widget<Tooltip>(
        find.ancestor(of: previewTagsFinder, matching: find.byType(Tooltip)),
      );
      expect(previewTooltip.message, uomoTags);
      expect(find.textContaining('Keywords:'), findsNothing);
      await tester.tap(find.byTooltip('Close preview'));
      await tester.pumpAndSettle();

      await search('people_family_man');
      expect(find.text('man'), findsOneWidget);

      await search('people family');
      expect(find.text('man'), findsOneWidget);
      expect(find.text('woman'), findsOneWidget);

      await search('leap');
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == 'saltare',
        ),
        findsOneWidget,
      );
      expect(find.text('Tags: jump, jumping, leap'), findsOneWidget);
    },
  );
}
