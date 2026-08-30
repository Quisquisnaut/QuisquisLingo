import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/info_screen.dart';

void main() {
  testWidgets('App Info starts with the complete QuisquisLingo logo', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InfoScreen()));

    final logoFinder = find.byKey(const Key('app-info-full-logo'));
    expect(logoFinder, findsOneWidget);
    final logo = tester.widget<Image>(logoFinder);
    expect(
      (logo.image as AssetImage).assetName,
      'assets/branding/quisquislingo_logo.png',
    );
    expect(logo.fit, BoxFit.contain);
    expect(logo.filterQuality, FilterQuality.high);

    final firstExistingSection = find.text('Choosing and opening courses');
    expect(firstExistingSection, findsOneWidget);
    expect(
      tester.getRect(logoFinder).bottom,
      lessThan(tester.getRect(firstExistingSection).top),
    );
    expect(find.text('Info'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('App and image credits'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Course content and AI'), findsOneWidget);
    expect(find.text('App and image credits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
