import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/audit_codes_screen.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';

void main() {
  testWidgets('every production code is searchable and fully documented', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuditCodesScreen()));
    final search = find.widgetWithText(TextField, 'Search codes and guidance');
    for (final definition in AuditCodeRegistry.definitions) {
      await tester.enterText(search, definition.code.toLowerCase());
      await tester.pump();
      final card = find.byKey(ValueKey('audit-code-${definition.code}'));
      expect(card, findsOneWidget, reason: definition.code);
      expect(
        find.descendant(of: card, matching: find.text(definition.code)),
        findsOneWidget,
      );
      for (final field in [
        'Severity: ${definition.severityLabel}',
        'Scope: ${definition.scope}',
        'Meaning: ${definition.meaning}',
        'Trigger condition: ${definition.trigger}',
        'What to check or do: ${definition.creatorAction}',
        'Blocking: ${definition.blocking ? 'Yes' : 'No'}',
      ]) {
        expect(
          find.descendant(
            of: card,
            matching: find.text(field, findRichText: true),
          ),
          findsOneWidget,
          reason: definition.code,
        );
      }
      expect(tester.takeException(), isNull, reason: definition.code);
    }
  });

  testWidgets('search accepts guidance text and can be cleared', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuditCodesScreen()));
    final search = find.byType(TextField);
    await tester.enterText(search, 'reselect correct options');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('audit-code-EXERCISE_ITEM_REFERENCE')),
      findsOneWidget,
    );
    await tester.enterText(search, 'no-such-audit-rule');
    await tester.pump();
    expect(find.text('0 of 103 Audit codes'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('103 of 103 Audit codes'), findsOneWidget);
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
  });

  for (final width in [320.0, 375.0, 430.0, 1280.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('Audit reference at $width px in ${brightness.name}', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 820);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const AuditCodesScreen(),
          ),
        );
        await tester.enterText(
          find.byType(TextField),
          'BUILD_TRANSLATION_UNCONSTRUCTABLE',
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byKey(
              const ValueKey('audit-code-BUILD_TRANSLATION_UNCONSTRUCTABLE'),
            ),
            matching: find.text('BUILD_TRANSLATION_UNCONSTRUCTABLE'),
          ),
          findsOneWidget,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
        expect(find.text('Blocking: Yes', findRichText: true), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
