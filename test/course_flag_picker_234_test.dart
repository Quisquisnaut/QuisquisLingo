import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/widgets/course_flag_picker.dart';

void main() {
  testWidgets(
    'picker searches every section and cancel leaves the current value unchanged',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _PickerHarness()));

      await tester.tap(find.byKey(const Key('open-picker')));
      await tester.pumpAndSettle();
      expect(find.text('Current selection'), findsOneWidget);
      expect(find.text('Suggested WORLD Flag for Japanese'), findsOneWidget);
      expect(find.text('Flags from installed QQL courses'), findsNothing);
      final search = find.byKey(const Key('course-flag-picker-search'));
      await tester.enterText(search, 'Naples');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('course-flag-option-world:neapolitan')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('course-flag-option-qql-flagpainter-spanish'),
        ),
        findsNothing,
      );
      await tester.enterText(search, '');
      await tester.pumpAndSettle();

      final results = find.byKey(const Key('course-flag-picker-results'));
      final resultsScrollable = find.descendant(
        of: results,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('course-flag-section-qqlFlagPainter')),
        180,
        scrollable: resultsScrollable.first,
      );
      expect(
        find.byKey(const Key('course-flag-section-qqlFlagPainter')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('course-flag-section-worldFlags')),
        180,
        scrollable: resultsScrollable.first,
      );
      expect(
        find.byKey(const Key('course-flag-section-worldFlags')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('course-flag-picker-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('builtin:IT'), findsOneWidget);
    },
  );

  testWidgets('only an explicit result selection changes the working value', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _PickerHarness()));
    await tester.tap(find.byKey(const Key('open-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('course-flag-picker-search')),
      'Spanish',
    );
    await tester.pump();
    final spanish = find.byKey(
      const ValueKey('course-flag-option-qql-flagpainter-spanish'),
    );
    await _scrollToResult(tester, spanish);
    await tester.tap(spanish);
    await tester.pumpAndSettle();

    expect(find.text('builtin:ES'), findsOneWidget);
  });

  testWidgets('permanent QQL catalog search returns a portable flag value', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _PickerHarness()));
    await tester.tap(find.byKey(const Key('open-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('course-flag-picker-search')),
      'German',
    );
    await tester.pump();
    final german = find.byKey(
      const ValueKey('course-flag-option-qql-flagpainter-german'),
    );
    await _scrollToResult(tester, german);
    await tester.tap(german);
    await tester.pumpAndSettle();

    expect(find.text('builtin:DE'), findsOneWidget);
  });

  testWidgets(
    'picker remains usable in compact landscape with the Android keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 360);
      tester.view.viewInsets = const FakeViewPadding(bottom: 150);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(const MaterialApp(home: _PickerHarness()));
      await tester.tap(find.byKey(const Key('open-picker')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('course-flag-picker-search')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('course-flag-picker-cancel')).hitTestable(),
        findsOneWidget,
      );
    },
  );
}

Future<void> _scrollToResult(WidgetTester tester, Finder candidate) async {
  final scrollable = find.descendant(
    of: find.byKey(const Key('course-flag-picker-results')),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(candidate, 180, scrollable: scrollable.first);
  await tester.pump();
}

class _PickerHarness extends StatefulWidget {
  const _PickerHarness();

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  CourseFlagSelection _selection = CourseFlagSelection.builtIn('IT');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text(_selection.stableKey),
        FilledButton(
          key: const Key('open-picker'),
          onPressed: () async {
            final result = await showCourseFlagPicker(
              context: context,
              currentSelection: _selection,
              languageName: 'Japanese',
              languageTag: 'ja',
              catalogFuture: Future.value(_catalog),
            );
            if (result != null && mounted) {
              setState(() => _selection = result);
            }
          },
          child: const Text('Open'),
        ),
      ],
    ),
  );
}

final _catalog = CourseFlagCatalog(
  automaticCandidate: CourseFlagCandidate(
    identity: 'qql-flagpainter-japanese',
    selection: CourseFlagSelection.builtIn('JA'),
    label: 'Japanese',
    subtitle: 'QQL FlagPainter Flag · Generated by QQL',
    searchTerms: const ['Japanese', 'Nihongo', 'ja', 'jpn'],
  ),
  suggestedWorldFlag: CourseFlagCandidate(
    identity: 'world:japan',
    selection: CourseFlagSelection.worldFlag('japan'),
    label: 'Japan',
    subtitle: 'WORLD Flag · JP',
    searchTerms: const ['Japanese', 'Nihongo', 'ja', 'jpn', 'JP'],
  ),
  sections: [
    CourseFlagCatalogSection(
      kind: CourseFlagCatalogSectionKind.qqlFlagPainter,
      title: 'QQL FlagPainter Flags',
      candidates: [
        CourseFlagCandidate(
          identity: 'qql-flagpainter-japanese',
          selection: CourseFlagSelection.builtIn('JA'),
          label: 'Japanese',
          subtitle: 'QQL FlagPainter Flag · Generated by QQL',
          searchTerms: const ['Japanese', 'Nihongo', 'ja', 'jpn'],
        ),
        CourseFlagCandidate(
          identity: 'qql-flagpainter-italian',
          selection: CourseFlagSelection.builtIn('IT'),
          label: 'Italian',
          subtitle: 'QQL FlagPainter Flag · Generated by QQL',
          searchTerms: const ['Italian', 'Italiano', 'it', 'ita'],
        ),
        CourseFlagCandidate(
          identity: 'qql-flagpainter-german',
          selection: CourseFlagSelection.builtIn('DE'),
          label: 'German',
          subtitle: 'QQL FlagPainter Flag · Generated by QQL',
          searchTerms: const ['German', 'Deutsch', 'de', 'deu'],
        ),
        CourseFlagCandidate(
          identity: 'qql-flagpainter-spanish',
          selection: CourseFlagSelection.builtIn('ES'),
          label: 'Spanish',
          subtitle: 'QQL FlagPainter Flag · Generated by QQL',
          searchTerms: const ['Spanish', 'Español', 'es', 'spa'],
        ),
      ],
    ),
    CourseFlagCatalogSection(
      kind: CourseFlagCatalogSectionKind.worldFlags,
      title: 'WORLD Flags',
      candidates: [
        CourseFlagCandidate(
          identity: 'world:japan',
          selection: CourseFlagSelection.worldFlag('japan'),
          label: 'Japan',
          subtitle: 'WORLD Flag · JP',
          searchTerms: const ['Japanese', 'Nihongo', 'ja', 'jpn', 'JP'],
        ),
        CourseFlagCandidate(
          identity: 'world:neapolitan',
          selection: CourseFlagSelection.worldFlag('neapolitan'),
          label: 'Neapolitan',
          subtitle: 'WORLD Flag · NAP',
          searchTerms: const ['Naples', 'Napoli', 'Napoletano', 'nap'],
        ),
        CourseFlagCandidate(
          identity: 'world:wales',
          selection: CourseFlagSelection.worldFlag('wales'),
          label: 'Wales',
          subtitle: 'WORLD Flag · GB-WLS',
          searchTerms: const ['Welsh', 'GB-WLS'],
        ),
      ],
    ),
  ],
);
