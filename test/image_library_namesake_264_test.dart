import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// Build 264 Revision 10 (owner decisions of 6 October 2026): a category and
// the tag of the same name are one, singular and plural count as one, the
// picture count sits beside the badges and follows the filters, and the
// library's explanations moved into its Help.

ExerciseImageMetadata _picture(
  String category, {
  List<String> tags = const ['thing'],
  String label = 'Picture',
}) => ExerciseImageMetadata(
  id: '${category}_${label.toLowerCase()}',
  label: label,
  category: category,
  tags: tags,
  assetPath: 'assets/exercise_images/${label.toLowerCase()}.webp',
  origin: 'bundled',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rules', () {
    test('singular and plural count as one', () {
      expect(imageTagKey('Cats'), 'cat');
      expect(imageTagKey('boxes'), 'box');
      expect(imageTagKey('berries'), 'berry');
      expect(imageTagKey('glasses'), 'glass');
      expect(imageTagKey('ice creams'), 'ice cream');
      expect(imageTagKey('body_parts'), 'body part');
      // Words of their own, or not plurals at all, stay.
      expect(imageTagKey('news'), 'news');
      expect(imageTagKey('bus'), 'bus');
      expect(imageTagKey('glass'), 'glass');
      expect(imageTagKey('cactus'), 'cactus');
    });

    test('a tag and the category of the same name are one', () {
      final inRestaurant = _picture('restaurant', tags: const ['menu']);
      final tagged = _picture('food_drinks', tags: const ['Restaurants']);
      final elsewhere = _picture('food_drinks', tags: const ['bread']);
      // The tag finds the category's pictures, in singular or plural.
      expect(carriesImageTag(inRestaurant, 'restaurant'), isTrue);
      expect(carriesImageTag(inRestaurant, 'restaurants'), isTrue);
      // The category shows the pictures tagged with its name.
      expect(belongsToImageCategory(tagged, 'restaurant'), isTrue);
      expect(belongsToImageCategory(elsewhere, 'restaurant'), isFalse);
      expect(belongsToImageCategory(tagged, 'food_drinks'), isTrue);
    });

    test('characters and Other are not topics to tag with', () {
      final thaiFlag = _picture('flags', tags: const ['thai']);
      expect(belongsToImageCategory(thaiFlag, 'characters_thai'), isFalse);
      expect(belongsToImageCategory(thaiFlag, 'characters'), isFalse);
      expect(
        belongsToImageCategory(
          _picture('food_drinks', tags: const ['other']),
          'other',
        ),
        isFalse,
      );
      expect(carriesImageTag(_picture('characters_thai'), 'thai'), isFalse);
    });

    test('the search finds the plural of what is typed', () {
      final dog = _picture('animals', tags: const ['dog']);
      expect(matchesImageSearch(dog, normalizeImageSearchText('dogs')), isTrue);
      expect(matchesImageSearch(dog, normalizeImageSearchText('do')), isTrue);
      expect(
        matchesImageSearch(dog, normalizeImageSearchText('cats')),
        isFalse,
      );
    });

    test('on the catalog, Restaurant shows the pictures tagged so', () {
      final records = [
        for (final record in readBundledImageRecords()) _fromRecord(record),
      ];
      final own = records.where((r) => r.category == 'restaurant').length;
      final shown = records
          .where((r) => belongsToImageCategory(r, 'restaurant'))
          .length;
      expect(own, greaterThan(0));
      expect(shown, greaterThan(own));
    });
  });

  group('the library', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

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

    String count(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const Key('exercise-image-count')))
        .data!;

    testWidgets('the count is beside the badges and follows the category', (
      tester,
    ) async {
      await open(tester);
      // Not in the title any more.
      expect(find.text('Shared Images'), findsOneWidget);
      expect(find.textContaining('Shared Images ·'), findsNothing);
      expect(count(tester), '$bundledImageCount images');

      final records = [
        for (final record in readBundledImageRecords()) _fromRecord(record),
      ];
      final restaurant = records
          .where((r) => belongsToImageCategory(r, 'restaurant'))
          .length;
      // Restaurant is in the group Food & drink (Build 265 Revision 9).
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, 'food & drink'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('exercise-image-category-filter')),
          matching: find.byType(Scrollable),
        ),
      );
      // Fully in view: the chip row stops scrolling with it at the edge.
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'food & drink'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'food & drink'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'restaurant'));
      await tester.pumpAndSettle();
      expect(count(tester), '$restaurant images');
    });

    testWidgets('the question mark opens the library Help', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('image-library-help')));
      await tester.pumpAndSettle();
      expect(find.text('Image Library Help'), findsOneWidget);
      expect(find.textContaining('there is no Save button'), findsOneWidget);
    });
  });
}
