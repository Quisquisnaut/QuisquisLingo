import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/audio_library_index.dart';

import 'support/dialog_test_course.dart';

// Build 270 Revision 12 (owner reports of 10 October 2026): the Audio
// Library's A–Z buttons did nothing for a letter further down, because the
// list builds only the rows near the screen; and its two imports sat at
// opposite ends of the screen.
void main() {
  // Wide enough for all 26 buttons of the A–Z bar, itself a scrolling row.
  Future<void> open(
    WidgetTester tester,
    List<String> texts, {
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(1600, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final course = Course.fromJson({
      ...dialogTestCourse().toJson(),
      'audioMode': 'recorded',
      'audioLibrary': [
        // A bundled path that does not exist resolves to "missing" without
        // reading the device's files.
        for (final (i, text) in texts.indexed)
          {
            'id': 'clip-$i',
            'text': text,
            'filePath': 'assets/audio_library_test/clip_$i.mp3',
          },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(home: AudioLibraryScreen(course: course)),
    );
    await tester.pumpAndSettle();
  }

  List<String> manyClips() => [
    for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''))
      for (var i = 1; i <= 6; i++) '${letter.toLowerCase()}word $i',
  ];

  Future<void> jump(WidgetTester tester, String letter) async {
    await tester.tap(
      find.descendant(of: find.byType(ActionChip), matching: find.text(letter)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a letter further down the list is brought to the top', (
    tester,
  ) async {
    await open(tester, manyClips());
    expect(find.text('xword 1'), findsNothing);

    await jump(tester, 'X');
    final row = find.text('xword 1');
    expect(row, findsOneWidget);
    final top = tester.getTopLeft(row).dy;
    expect(top, greaterThan(0));
    expect(top, lessThan(300), reason: 'X is near the top of the list');
    expect(find.text('wword 1'), findsNothing, reason: 'W is above X');
  });

  testWidgets('the last letter is reached too', (tester) async {
    await open(tester, manyClips());
    await jump(tester, 'Z');
    expect(find.text('zword 1'), findsOneWidget);
    expect(find.text('zword 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('# (no text) comes first, then 0–9, the letters and other '
      'scripts', (tester) async {
    await open(tester, [
      '1 uno',
      'bello',
      '[zeta]',
      '¿qué?',
      '',
      'école',
      '€ 5',
      '',
    ], height: 2400);
    expect(tester.takeException(), isNull);
    final buttons = [
      for (final chip in tester.widgetList<ActionChip>(find.byType(ActionChip)))
        (chip.label as Text).data,
    ];
    expect(buttons, ['#', '0–9', 'B', 'E', 'Q', 'Z']);
    expect(find.text('# (MP3s with no assigned text)'), findsOneWidget);
    // The last match: 0–9 is also a button above the list.
    double top(String text) => tester.getTopLeft(find.text(text).last).dy;
    final ordered = [
      '# (MP3s with no assigned text)',
      'Unassigned MP3',
      '0–9',
      '1 uno',
      '€ 5',
      'bello',
      'école',
      '¿qué?',
      '[zeta]',
    ];
    for (var i = 1; i < ordered.length; i++) {
      expect(
        top(ordered[i]),
        greaterThan(top(ordered[i - 1])),
        reason: '${ordered[i]} comes after ${ordered[i - 1]}',
      );
    }
    expect(find.text('Unassigned MP3'), findsNWidgets(2));
  });

  group('the filing rule', () {
    test('a text is filed under its first letter without accents', () {
      for (final (text, group) in [
        ('gatto', 'G'),
        ('[gatto]', 'G'),
        ('¿qué?', 'Q'),
        ('«ciao»', 'C'),
        ('- sì', 'S'),
        ('école', 'E'),
        ('Àncora', 'A'),
        ('ñandú', 'N'),
        ('Ärger', 'A'),
        ('øl', 'O'),
        ('æble', 'A'),
        ('ßtraße', 'S'),
        ('łódź', 'L'),
      ]) {
        expect(AudioLibraryIndex.groupOf(text), group, reason: text);
      }
    });

    test('digits and symbols are 0–9; no text is #', () {
      for (final text in ['1 uno', '100', '3:00', '€ 5', '+ più', '#tag']) {
        expect(AudioLibraryIndex.groupOf(text), '0–9', reason: text);
      }
      expect(AudioLibraryIndex.groupOf('...'), '0–9');
      expect(AudioLibraryIndex.groupOf(''), '#');
      expect(AudioLibraryIndex.groupOf('   '), '#');
    });

    test('Greek and Cyrillic have their letters; other scripts one group', () {
      expect(AudioLibraryIndex.groupOf('άλφα'), 'Α');
      expect(AudioLibraryIndex.groupOf('ἄνθρωπος'), 'Α');
      expect(AudioLibraryIndex.groupOf('ёлка'), 'Е');
      expect(AudioLibraryIndex.groupOf('йод'), 'И');
      for (final text in ['안녕', '日本', 'がっこう', 'مرحبا', 'שלום']) {
        expect(AudioLibraryIndex.groupOf(text), 'Other scripts', reason: text);
      }
    });

    test('groups come #, 0–9, Latin, Greek, Cyrillic, other scripts', () {
      CourseAudioClip clip(int i, String text) =>
          CourseAudioClip(id: 'c$i', text: text, filePath: 'f$i.mp3');
      final groups = AudioLibraryIndex.groups([
        for (final (i, text) in [
          '안녕',
          'мир',
          'άλφα',
          'zeta',
          'école',
          'ecco',
          'edificio',
          '',
          '2 due',
        ].indexed)
          clip(i, text),
      ]);
      expect(
        [for (final group in groups) group.key],
        ['#', '0–9', 'E', 'Z', 'Α', 'М', 'Other scripts'],
      );
      expect(
        [for (final c in groups[2].clips) c.text],
        ['ecco', 'école', 'edificio'],
        reason: 'accents are ignored in the order',
      );
    });
  });

  testWidgets('Quick Import and Open from… sit side by side in the import '
      'card', (tester) async {
    await open(tester, const ['bello']);
    final quick = find.byKey(const Key('audio-quick-import'));
    expect(quick, findsOneWidget);
    expect(
      find.descendant(of: quick, matching: find.text('Quick Import')),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(const Key('open-mp3-from')),
      ),
      findsNothing,
    );
    final openFrom = find.byKey(const Key('open-mp3-from'));
    if (openFrom.evaluate().isNotEmpty) {
      expect(
        (tester.getTopLeft(openFrom).dy - tester.getTopLeft(quick).dy).abs(),
        lessThan(1),
        reason: 'the two imports share a row',
      );
    }
  });
}
