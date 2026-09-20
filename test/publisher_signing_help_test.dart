import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/screens/publisher_signing_help_content.dart';
import 'package:quisquislingo_app/screens/publisher_signing_help_screen.dart';

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

    final expected =
        '# $publisherSigningGuideTitle\n\n${publisherSigningGuideSections.map((section) => '## ${section.title}\n\n${markdownBody(section.body)}').join('\n\n')}\n';
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
        await tester.pumpWidget(const MaterialApp(home: EditorHelpScreen()));
        if (italian) {
          await tester.tap(
            find.byKey(const Key('editor-help-language-toggle')),
          );
          await tester.pump();
        }
        final link = find.byKey(const Key('editor-help-publisher-signing'));
        await tester.scrollUntilVisible(link, 200);
        await tester.tap(link);
        await tester.pump();
        // Complete only the known route transition; there is no storage I/O.
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PublisherSigningHelpScreen), findsOneWidget);
        expect(
          find.text('Status: signature verification implemented'),
          findsOneWidget,
        );
        expect(find.textContaining('Build 241 now verifies'), findsOneWidget);
        await tester.pageBack();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          find.text(italian ? 'Guida all’Editor' : 'Editor Help'),
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
