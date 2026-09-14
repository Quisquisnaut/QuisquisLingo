import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/credits_screen.dart';

void main() {
  testWidgets('Image credits exposes every attribution-required flag author', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ImageCreditsScreen()));

    expect(find.text('World and language-related flags'), findsOneWidget);
    expect(find.textContaining('lipis/flag-icons v7.5.0'), findsOneWidget);
    expect(find.textContaining('Willtron — CC BY-SA 3.0'), findsOneWidget);
    expect(find.textContaining('Ipankonin — CC BY-SA 3.0'), findsOneWidget);
    expect(find.textContaining('Angelus — CC BY-SA 3.0'), findsOneWidget);
  });
}
