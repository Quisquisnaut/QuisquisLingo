import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/screens/info_screen.dart';
import 'package:quisquislingo_app/screens/info_screen_content.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 261 Revision 8 (owner request of 3 October 2026): App Info explains
/// the learner path's colours with the owner's picture.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the colour guide follows Laurel crowns and its picture is bundled', () {
    expect(
      appInfoSectionIds.indexOf('pathColours'),
      appInfoSectionIds.indexOf('laurelCrowns') + 1,
    );
    final file = File(appInfoPathColoursPicture);
    expect(file.existsSync(), isTrue);
    // The proportions the card and the enlarged view use are the picture's.
    final header = file.readAsBytesSync();
    final width = ByteData.sublistView(header, 16, 20).getUint32(0);
    final height = ByteData.sublistView(header, 20, 24).getUint32(0);
    expect(appInfoPathColoursAspectRatio, closeTo(width / height, .001));
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/rounds_screenshots/'),
    );
    final english = infoSections(
      HelpLanguage.english,
    ).singleWhere((section) => section.id == 'pathColours');
    expect(english.title, 'Colour code of the path');
    expect(english.body, contains('one of eight that start again'));
    expect(
      infoSections(
        HelpLanguage.italian,
      ).singleWhere((section) => section.id == 'pathColours').title,
      'Codice colori del percorso',
    );
    expect(
      infoSections(
        HelpLanguage.spanish,
      ).singleWhere((section) => section.id == 'pathColours').title,
      'Código de colores del camino',
    );
  });

  testWidgets('App Info shows the picture and opens it enlarged', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ProfileService().addProfile('Alice');
    await tester.pumpWidget(const MaterialApp(home: InfoScreen()));
    await tester.pumpAndSettle();

    final section = find.byKey(const ValueKey('app-info-section-pathColours'));
    await tester.scrollUntilVisible(
      section,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: section,
        matching: find.text('Colour code of the path'),
      ),
      findsOneWidget,
    );
    final picture = tester.widget<Image>(
      find.byKey(const Key('app-info-path-colours-picture')),
    );
    expect(
      (picture.image as AssetImage).assetName,
      'assets/rounds_screenshots/colors.png',
    );
    expect(picture.semanticLabel, contains('eight Lesson colours'));
    // Only this section carries a picture.
    expect(find.byKey(const Key('app-info-path-colours-picture')), findsOne);

    await tester.tap(find.byKey(const Key('app-info-path-colours-enlarge')));
    await tester.pumpAndSettle();
    final dialog = find.byKey(const Key('app-info-path-colours-dialog'));
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.byType(InteractiveViewer)),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('app-info-path-colours-close')));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
  });
}
