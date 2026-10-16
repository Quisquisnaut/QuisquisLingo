import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// Build 274 Revision 4 (the owner's point 8 of 13 October 2026): a search
// shows first the pictures whose name is the term, then those with the term
// as a whole word of the name, then of a tag, a Local word or the category,
// then those where it is only inside a longer word; the chosen sort orders
// each part. Strict search (off by default) keeps the whole words only, so
// "man" does not find Woman. The order never adds or hides a picture.

ExerciseImageMetadata _picture(
  String id,
  String label, {
  String category = 'people_family',
  List<String> tags = const ['person'],
  List<String> localWords = const [],
}) => ExerciseImageMetadata(
  id: id,
  label: label,
  category: category,
  tags: tags,
  assetPath: 'assets/exercise_images/$id.webp',
  origin: 'bundled',
  localWords: localWords,
);

ExerciseImageMetadata _fromRecord(Map<String, dynamic> record) =>
    ExerciseImageMetadata(
      id: record['id'] as String,
      label: record['label'] as String,
      category: record['category'] as String,
      tags: [for (final tag in record['tags'] as List) tag as String],
      assetPath: record['assetPath'] as String,
      origin: 'bundled',
    );

ImageSearchMatch? _match(ExerciseImageMetadata picture, String query) =>
    imageSearchMatch(picture, normalizeImageSearchText(query));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the parts of a search', () {
    test('the name, a word of the name, of a tag, inside a word', () {
      expect(_match(_picture('a', 'Man'), 'man'), ImageSearchMatch.name);
      expect(_match(_picture('b', 'Man 2'), 'man'), ImageSearchMatch.nameWord);
      expect(
        _match(_picture('c', 'Tennis player (man)'), 'man'),
        ImageSearchMatch.nameWord,
      );
      expect(
        _match(_picture('d', 'Father', tags: const ['man', 'dad']), 'man'),
        ImageSearchMatch.tagWord,
      );
      expect(
        _match(_picture('e', 'Uncle', localWords: const ['man']), 'man'),
        ImageSearchMatch.tagWord,
      );
      expect(_match(_picture('f', 'Woman'), 'man'), ImageSearchMatch.inside);
      expect(
        _match(_picture('g', 'Fisherman'), 'man'),
        ImageSearchMatch.inside,
      );
      expect(_match(_picture('h', 'Cat'), 'man'), isNull);
    });

    test('a plural counts as its word, and a phrase as words in a row', () {
      expect(
        _match(_picture('a', 'Cat', category: 'animals'), 'cats'),
        ImageSearchMatch.name,
      );
      expect(
        _match(_picture('b', 'Tennis player (woman)'), 'tennis player'),
        ImageSearchMatch.nameWord,
      );
      // Words out of order: the search does not find it at all.
      expect(_match(_picture('c', 'Player of tennis'), 'tennis player'), null);
    });

    test('a whole category or group is named; a word of it, or the ID, '
        'is only inside', () {
      final dish = _picture(
        'food_drinks_artichoke',
        'Artichoke',
        category: 'food_drinks',
        tags: const ['vegetable'],
      );
      expect(_match(dish, 'food'), ImageSearchMatch.inside);
      expect(_match(dish, 'food drinks'), ImageSearchMatch.tagWord);
      // The whole name of its group finds it too.
      expect(_match(dish, 'food & drink'), ImageSearchMatch.tagWord);
      // A category of characters as its chip names it.
      final letter = _picture(
        'char_latin_capital_a',
        'A',
        category: 'characters_latin',
        tags: const ['letter a'],
      );
      expect(_match(letter, 'latin'), ImageSearchMatch.tagWord);
      final device = _picture(
        'image_local_17',
        'Kettle',
        category: 'objects',
        tags: const ['boil'],
      );
      expect(_match(device, 'local'), ImageSearchMatch.inside);
    });

    test('a symbol is the name or tag it is', () {
      final euro = _picture(
        'char_currency_euro',
        'Euro sign',
        category: 'characters_currency',
        tags: const ['€', 'euro'],
      );
      expect(_match(euro, '€'), ImageSearchMatch.tagWord);
      expect(
        matchesImageSearch(euro, normalizeImageSearchText('€'), strict: true),
        isTrue,
      );
      expect(
        _match(_picture('q', '?', category: 'characters_punctuation'), '?'),
        ImageSearchMatch.name,
      );
    });

    test('letters across words are only inside; a script without spaces '
        'has a word in each character', () {
      expect(
        _match(_picture('t', 'Tennis player'), 'nis pla'),
        ImageSearchMatch.inside,
      );
      final cat = _picture(
        'animals_cat',
        'Cat',
        category: 'animals',
        localWords: const ['猫咪'],
      );
      expect(_match(cat, '猫'), ImageSearchMatch.tagWord);
      expect(_match(cat, '猫咪'), ImageSearchMatch.tagWord);
    });

    test('an empty search is one part: the sort alone orders it', () {
      expect(_match(_picture('a', 'Woman'), ''), ImageSearchMatch.name);
      expect(
        matchesImageSearch(_picture('a', 'Woman'), '', strict: true),
        isTrue,
      );
    });

    test('Strict search keeps whole words only', () {
      String q(String text) => normalizeImageSearchText(text);
      expect(matchesImageSearch(_picture('a', 'Man'), q('man')), isTrue);
      expect(
        matchesImageSearch(_picture('a', 'Man'), q('man'), strict: true),
        isTrue,
      );
      expect(
        matchesImageSearch(_picture('f', 'Woman'), q('man'), strict: true),
        isFalse,
      );
      expect(matchesImageSearch(_picture('f', 'Woman'), q('man')), isTrue);
    });

    test('on the catalog the order finds exactly what the search finds', () {
      final records = [
        for (final record in readBundledImageRecords()) _fromRecord(record),
      ];
      for (final query in const [
        'man',
        'cat',
        'cats',
        'red',
        'food',
        'food & drink',
        'tennis player',
        'e',
        'flag',
        'sun',
        '€',
        '?',
        'latin',
        'other',
        'characters',
      ]) {
        final q = normalizeImageSearchText(query);
        for (final record in records) {
          final found = imageSearchMatch(record, q);
          expect(
            found != null,
            matchesImageSearch(record, q),
            reason: '$query: ${record.id}',
          );
          expect(
            matchesImageSearch(record, q, strict: true),
            found?.isWhole ?? false,
            reason: '$query: ${record.id}',
          );
        }
      }
      // The owner's example: "man" as a word of its own, and inside a
      // longer word (Woman, …); Strict search keeps the first.
      final man = normalizeImageSearchText('man');
      final whole = records
          .where((r) => matchesImageSearch(r, man, strict: true))
          .toList();
      final all = records.where((r) => matchesImageSearch(r, man)).toList();
      expect(whole, isNotEmpty);
      expect(whole.length, lessThan(all.length));
      expect(whole.where((r) => r.label.toLowerCase() == 'woman'), isEmpty);
      expect(all.where((r) => r.label.toLowerCase() == 'woman'), isNotEmpty);
    });
  });

  group('the library', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    testWidgets('on a phone with large text the field keeps most of the row', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const FlatImageLibraryScreen(readOnly: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('exercise-image-strict-search')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('exercise-image-search-all')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const Key('exercise-image-search'))).width,
        greaterThan(336 * 0.55),
      );
    });

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: FlatImageLibraryScreen(readOnly: true)),
      );
      await tester.pumpAndSettle();
    }

    List<String> shownIds(WidgetTester tester) => [
      for (final element
          in find
              .byWidgetPredicate(
                (widget) =>
                    widget.key is ValueKey<String> &&
                    (widget.key! as ValueKey<String>).value.startsWith(
                      'exercise-image-',
                    ) &&
                    widget is InkWell,
              )
              .evaluate())
        (element.widget.key! as ValueKey<String>).value.substring(
          'exercise-image-'.length,
        ),
    ];

    String count(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const Key('exercise-image-count')))
        .data!;

    testWidgets('a search shows the whole words first; Strict search only '
        'them', (tester) async {
      final records = {
        for (final record in readBundledImageRecords())
          record['id'] as String: _fromRecord(record),
      };
      await open(tester);
      final strict = find.byKey(const Key('exercise-image-strict-search'));
      expect(tester.widget<Checkbox>(strict).value, isFalse);
      await tester.enterText(
        find.byKey(const Key('exercise-image-search')),
        'man',
      );
      await tester.pumpAndSettle();
      final shown = shownIds(tester);
      expect(shown, isNotEmpty);
      // The first part is the picture named "Man".
      expect(records[shown.first]!.label.toLowerCase(), 'man');
      final parts = [
        for (final id in shown) imageSearchMatch(records[id]!, 'man')!.index,
      ];
      expect(parts, orderedEquals([...parts]..sort()));
      final everything = count(tester);
      await tester.tap(strict);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(strict).value, isTrue);
      expect(count(tester), isNot(everything));
      for (final id in shownIds(tester)) {
        expect(imageSearchMatch(records[id]!, 'man')!.isWhole, isTrue);
      }
    });
  });
}
