import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/localization/welcome_text.dart';
import 'package:quisquislingo_app/widgets/welcome_wizard_dialog.dart';

/// The asset a step's mascot shows.
String _mascot(WidgetTester tester, int step) {
  var image = tester
      .widget<Image>(find.byKey(ValueKey('welcome-wizard-mascot-$step')))
      .image;
  if (image is ResizeImage) image = image.imageProvider;
  return (image as AssetImage).assetName;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Welcome Wizard introduces new learners and can be completed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WelcomeWizardDialog())),
    );

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Welcome aboard!'), findsOneWidget);
    expect(find.byKey(const Key('welcome-wizard-back')), findsNothing);
    expect(find.byType(DecoratedBox), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome-wizard-next')));
    await tester.pump();

    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.text('Courses made by others'), findsOneWidget);
    expect(find.byKey(const Key('welcome-wizard-back')), findsOneWidget);

    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(const Key('welcome-wizard-next')));
      await tester.pump();
    }
    expect(find.text('Make your own Course'), findsOneWidget);
    expect(find.text('Start learning'), findsOneWidget);
  });

  testWidgets('Build 255 Revision 7: one mascot per step, in order', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WelcomeWizardDialog())),
    );
    final mascots = <String>[];
    for (var step = 1; step <= 5; step++) {
      mascots.add(_mascot(tester, step));
      if (step < 5) {
        await tester.tap(find.byKey(const Key('welcome-wizard-next')));
        await tester.pump();
      }
    }
    expect(mascots, [
      'assets/mascots/kid_reading.webp',
      'assets/mascots/cat-celebrating_tr.webp',
      'assets/mascots/monkey-yawning_tr.webp',
      'assets/mascots/robot_running.webp',
      'assets/mascots/dog-laughing-pencil_tr.webp',
    ]);
  });

  testWidgets('Build 255 Revision 7: the Wizard speaks Italian and Spanish', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WelcomeWizardDialog(locale: AppLocale.italian)),
      ),
    );
    expect(find.text('Passo 1 di 5'), findsOneWidget);
    expect(find.text('Ti diamo il benvenuto!'), findsOneWidget);
    expect(find.text('Salta'), findsOneWidget);
    expect(find.text('Avanti'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WelcomeWizardDialog(locale: AppLocale.spanish)),
      ),
    );
    expect(find.text('Paso 1 de 5'), findsOneWidget);
    expect(find.text('¡Te damos la bienvenida!'), findsOneWidget);
    expect(find.text('Omitir'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
  });

  test('Build 255 Revision 7: every Wizard text exists in every language', () {
    final keys = welcomeText.english.keys.toSet();
    expect(welcomeText.italian.keys.toSet(), keys);
    expect(welcomeText.spanish.keys.toSet(), keys);
    for (final catalog in [
      welcomeText.english,
      welcomeText.italian,
      welcomeText.spanish,
    ]) {
      expect(catalog.values.where((text) => text.trim().isEmpty), isEmpty);
    }
  });
}
