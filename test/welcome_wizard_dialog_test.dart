import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/widgets/welcome_wizard_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Welcome Wizard introduces new learners and can be completed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WelcomeWizardDialog())),
    );

    expect(find.text('Step 1 of 5'), findsOneWidget);
    expect(find.text('Welcome to QuisquisLingo'), findsOneWidget);
    expect(find.byIcon(Icons.language_outlined), findsOneWidget);
    expect(find.byKey(const Key('welcome-wizard-back')), findsNothing);
    expect(find.byType(DecoratedBox), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome-wizard-next')));
    await tester.pump();

    expect(find.text('Step 2 of 5'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byKey(const Key('welcome-wizard-back')), findsOneWidget);

    for (var step = 0; step < 3; step++) {
      await tester.tap(find.byKey(const Key('welcome-wizard-next')));
      await tester.pump();
    }
    expect(find.text('Start learning'), findsOneWidget);
  });
}
