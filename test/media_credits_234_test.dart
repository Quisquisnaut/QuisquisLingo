import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/credits_screen.dart';

/// Every entry in the language-related flag licence file, as
/// `- **Name** (`file.svg`) — <licence clause>; author: <author>; …`.
typedef _FlagLicence = ({String name, String author, String license});

/// Reads the authoritative record rather than repeating it.
///
/// The in-app credits and this licence file drifted apart once already: five
/// flags were added, the file was updated and the Credits screen was not, so
/// two works under CC BY / CC BY-SA shipped uncredited. Deriving the
/// expectation from the file means adding a flag cannot repeat that.
List<_FlagLicence> _licences() {
  final entry = RegExp(
    r'^- \*\*(?<name>[^*]+)\*\* \(`[^`]+`\) — (?<licence>.*?); author: (?<author>[^;]+);',
    multiLine: true,
  );
  final text = File(
    'assets/world_flags/LICENSE-language-related-flags.md',
  ).readAsStringSync();
  return [
    for (final match in entry.allMatches(text))
      (
        name: match.namedGroup('name')!.trim(),
        author: match.namedGroup('author')!.trim(),
        license: match.namedGroup('licence')!.trim(),
      ),
  ];
}

/// A work needs a visible credit when its licence is any CC BY variant.
/// Public-domain and CC0 files do not.
bool _needsAttribution(_FlagLicence licence) =>
    RegExp(r'CC BY').hasMatch(licence.license);

/// `[CC BY-SA 3.0](https://…)` or a bare `CC BY 4.0`.
String _licenceLabel(_FlagLicence licence) =>
    RegExp(r'CC BY[A-Z0-9.\- ]*').firstMatch(licence.license)!.group(0)!.trim();

void main() {
  test('the licence file is parsed and lists the expected flag set', () {
    final licences = _licences();
    // Guards the regex itself: a formatting change that silently matched
    // nothing would make every assertion below vacuous.
    expect(licences, hasLength(24));
    expect(licences.where(_needsAttribution), hasLength(5));
  });

  testWidgets('Image credits exposes every attribution-required flag author', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ImageCreditsScreen()));

    expect(find.text('World and language-related flags'), findsOneWidget);
    expect(find.textContaining('lipis/flag-icons v7.5.0'), findsOneWidget);

    for (final licence in _licences().where(_needsAttribution)) {
      expect(
        find.textContaining('${licence.author} — ${_licenceLabel(licence)}'),
        findsOneWidget,
        reason:
            '${licence.name} is under ${_licenceLabel(licence)} and must be '
            'credited on the Image credits page',
      );
    }
  });

  testWidgets('Image credits states the real number of language flags', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ImageCreditsScreen()));
    final total = _licences().length;
    final free = _licences().where((l) => !_needsAttribution(l)).length;
    expect(
      find.textContaining('Twenty-four community or regional flags'),
      findsOneWidget,
      reason: 'the page must not understate the $total language flags',
    );
    expect(
      find.textContaining('other nineteen language-related files'),
      findsOneWidget,
      reason: 'the page must not overstate the $free public-domain files',
    );
  });
}
