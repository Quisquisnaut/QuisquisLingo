import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/audit_codes_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/services/audit_code_registry.dart';

void main() {
  testWidgets(
    'categories default visible and render Errors, Warnings, Info order',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuditCodesScreen()));
      expect(find.text('102 of 102 Audit codes'), findsOneWidget);
      for (final severity in AuditSeverity.values) {
        expect(
          tester
              .widget<FilterChip>(
                find.byKey(ValueKey('audit-code-filter-${severity.name}')),
              )
              .selected,
          isTrue,
        );
      }

      final list = tester.widget<ListView>(find.byType(ListView));
      final children =
          (list.childrenDelegate as SliverChildListDelegate).children;
      int headingIndex(AuditSeverity severity) => children.indexWhere(
        (child) => child.key == ValueKey('audit-code-heading-${severity.name}'),
      );
      expect(
        headingIndex(AuditSeverity.error),
        lessThan(headingIndex(AuditSeverity.warning)),
      );
      expect(
        headingIndex(AuditSeverity.warning),
        lessThan(headingIndex(AuditSeverity.info)),
      );
      expect(
        find.text(
          'Errors block actions that require a valid Audit. Warnings and Info provide review guidance.',
        ),
        findsNothing,
      );
      expect(
        find.textContaining('GENERAL is reserved for unexpected'),
        findsNothing,
      );
    },
  );

  testWidgets('Technical Reference Audit Codes link has no subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
    await tester.pumpAndSettle();

    final link = find.byKey(const Key('editor-help-audit-codes'));
    expect(link, findsOneWidget);
    expect(
      find.text('Search rule meanings, triggers and creator actions.'),
      findsNothing,
    );
    expect(tester.widget<ListTile>(link).subtitle, isNull);
  });

  for (final selected in AuditSeverity.values) {
    testWidgets('${selected.name} can be selected as the only category', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AuditCodesScreen()));
      for (final severity in AuditSeverity.values.where(
        (severity) => severity != selected,
      )) {
        await tester.tap(
          find.byKey(ValueKey('audit-code-filter-${severity.name}')),
        );
        await tester.pump();
      }
      final expected = AuditCodeRegistry.definitions
          .where((definition) => definition.severity == selected)
          .length;
      expect(find.text('$expected of 102 Audit codes'), findsOneWidget);
      for (final severity in AuditSeverity.values) {
        expect(
          find.byKey(ValueKey('audit-code-heading-${severity.name}')),
          severity == selected ? findsOneWidget : findsNothing,
        );
      }
    });
  }

  testWidgets('multiple categories combine and search stays inside them', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuditCodesScreen()));
    await tester.tap(find.byKey(const ValueKey('audit-code-filter-warning')));
    await tester.pump();
    final errorsAndInfo = AuditCodeRegistry.definitions
        .where((definition) => definition.severity != AuditSeverity.warning)
        .length;
    expect(find.text('$errorsAndInfo of 102 Audit codes'), findsOneWidget);

    final warning = AuditCodeRegistry.definitions.firstWhere(
      (definition) => definition.severity == AuditSeverity.warning,
    );
    await tester.enterText(find.byType(TextField), warning.code);
    await tester.pump();
    expect(find.text('0 of 102 Audit codes'), findsOneWidget);
    expect(find.byKey(ValueKey('audit-code-${warning.code}')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('audit-code-filter-warning')));
    await tester.pump();
    expect(find.text('1 of 102 Audit codes'), findsOneWidget);
    expect(find.byKey(ValueKey('audit-code-${warning.code}')), findsOneWidget);
  });

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
    expect(find.text('0 of 102 Audit codes'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('102 of 102 Audit codes'), findsOneWidget);
    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
  });

  testWidgets('removed sample comparison has no searchable Help entry', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuditCodesScreen()));
    await tester.enterText(find.byType(TextField), 'ROUND_CONTENT_SHORT');
    await tester.pump();
    expect(find.text('0 of 102 Audit codes'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('audit-code-ROUND_CONTENT_SHORT')),
      findsNothing,
    );
    await tester.enterText(find.byType(TextField), 'standard sample');
    await tester.pump();
    expect(find.text('0 of 102 Audit codes'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('102 of 102 Audit codes'), findsOneWidget);
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
