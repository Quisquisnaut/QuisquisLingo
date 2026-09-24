import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_structure.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/screens/publisher_signing_help_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('distributable guide contains the same instructions as in-app Help', () {
    String markdownBody(String body) => body
        .split('\n\n')
        .map((paragraph) {
          if (paragraph.startsWith('openssl ') ||
              paragraph.startsWith('Purpose:') ||
              paragraph.startsWith('dart ') ||
              paragraph.startsWith('flutter ')) {
            return '```text\n$paragraph\n```';
          }
          return paragraph;
        })
        .join('\n\n');

    String english(String key) => helpText.lookup(AppLocale.english, key);
    final sections = [
      for (final id in publisherSigningHelpSectionIds)
        '## ${english('publisherSigningHelp.$id.title')}\n\n'
            '${markdownBody(english('publisherSigningHelp.$id.body'))}',
    ];
    final expected =
        '# ${english('publisherSigningHelp.title')}\n\n'
        '${sections.join('\n\n')}\n';
    expect(
      File(
        'docs/PUBLISHER_SIGNING_GUIDE.md',
      ).readAsStringSync().replaceAll('\r\n', '\n'),
      expected,
    );
  });

  for (final italian in [false, true]) {
    testWidgets(
      'technical guide opens from ${italian ? 'Italian' : 'English'} Help',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await ProfileService().addProfile('Publisher Help reader');
        await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
        await tester.pumpAndSettle();
        if (italian) {
          await tester.tap(
            find.byKey(const Key('editor-help-language-toggle')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('IT').last);
          await tester.pumpAndSettle();
        }
        final link = find.byKey(const Key('editor-help-publisher-signing'));
        await tester.scrollUntilVisible(
          link,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(link);
        await tester.pump();
        // Complete only the known route transition; there is no storage I/O.
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PublisherSigningHelpScreen), findsOneWidget);
        final locale = italian ? AppLocale.italian : AppLocale.english;
        expect(
          find.text(
            helpText.lookup(locale, 'publisherSigningHelp.status.title'),
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            helpText
                .lookup(locale, 'publisherSigningHelp.status.body')
                .split('\n\n')
                .first,
          ),
          findsOneWidget,
        );
        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text(helpText.lookup(locale, 'editorHelp.title')),
          findsOneWidget,
        );
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('commands remain selectable on narrow $brightness screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const PublisherSigningHelpScreen(),
        ),
      );
      final keysSection = find.byKey(const PageStorageKey('publisher-guide-2'));
      await tester.scrollUntilVisible(
        keysSection,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(keysSection);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final command = find.text(
        'openssl genpkey -algorithm ED25519 -aes-256-cbc -out publisher-private.pem',
      );
      await tester.scrollUntilVisible(
        command,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(
        find.ancestor(of: command, matching: find.byType(SelectableText)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
