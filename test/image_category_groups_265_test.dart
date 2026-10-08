import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/models/image_categories.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// Build 265 Revision 9 (owner decisions of 7 October 2026): groups of image
// categories, shown like the characters: one chip per group and a second row
// of its categories. Display only: every picture keeps its own category.

const _adminId = '11111111-1111-4111-8111-111111111111';

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

Map<String, Object> _local(String id, List<String> tags) => {
  'id': id,
  'label': id,
  'category': 'other',
  'tags': tags,
  'assetPath': 'C:/no/such/$id.webp',
  'origin': 'local',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the groups', () {
    test('hold library categories, each in one group at most', () {
      final seen = <String, String>{};
      for (final entry in imageCategoryGroups.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
        expect(imageCategoryGroupLabels[entry.key], isNotNull);
        // A group key is never a category, so the two never meet.
        expect(imageCategories, isNot(contains(entry.key)));
        expect(entry.key, isNot(characterCategoryGroup));
        for (final category in entry.value) {
          expect(imageCategories, contains(category), reason: category);
          expect(isCharacterCategory(category), isFalse, reason: category);
          expect(
            seen[category],
            isNull,
            reason: '$category is in ${seen[category]} and ${entry.key}',
          );
          seen[category] = entry.key;
        }
      }
      expect(
        imageCategoryGroupLabels.keys.toSet(),
        imageCategoryGroups.keys.toSet(),
      );
      // The categories that stand alone (owner's list).
      final alone = {
        for (final category in imageCategories)
          if (!isCharacterCategory(category) && !seen.containsKey(category))
            category,
      };
      expect(alone, {
        'actions',
        'clothing_accessories',
        'colors',
        'concepts',
        'flags',
        'lesson_icons',
        'movement',
        'other',
        'school_work',
        'symbols',
      });
    });

    test('names, lookups and labels', () {
      expect(imageCategoryGroupOf('jobs_professions'), 'people');
      expect(imageCategoryGroupOf('restaurant'), 'food_drink');
      expect(imageCategoryGroupOf('characters_greek'), characterCategoryGroup);
      expect(imageCategoryGroupOf('colors'), isNull);
      expect(isImageCategoryGroup('people'), isTrue);
      expect(isImageCategoryGroup(characterCategoryGroup), isTrue);
      expect(isImageCategoryGroup('people_family'), isFalse);
      expect(imageCategoriesOfGroup('nature_animals'), ['nature', 'animals']);
      expect(
        imageCategoriesOfGroup(characterCategoryGroup),
        characterCategoryLabels.keys.toList(),
      );
      expect(imageCategoryLabel('food_drink'), 'food & drink');
      expect(imageCategoryLabel('restaurant'), 'food & drink › restaurant');
      expect(imageCategoryLabel('characters_greek'), 'characters › greek');
      expect(imageCategoryLabel('flags'), 'flags');
      expect(imageSubcategoryLabel('jobs_professions'), 'jobs professions');
      expect(imageSubcategoryLabel('characters_blocks'), 'toy blocks');
    });

    test("a group's whole name finds its pictures, a word of it does not", () {
      final dish = _picture('restaurant', tags: const ['dish', 'plate']);
      final seven = _picture('numbers', label: 'Seven', tags: const ['seven']);
      String query(String text) => normalizeImageSearchText(text);
      expect(matchesImageSearch(dish, query('Food & Drink')), isTrue);
      expect(matchesImageSearch(dish, query('food and drink')), isTrue);
      expect(matchesImageSearch(seven, query('numbers & time')), isTrue);
      // "time" alone does not bring every number, unit and shape.
      expect(matchesImageSearch(seven, query('time')), isFalse);
      expect(matchesImageSearch(dish, query('people')), isFalse);
      // What a search found before still finds it.
      expect(matchesImageSearch(seven, query('numbers')), isTrue);
    });
  });

  group('the library', () {
    final records = [
      for (final record in readBundledImageRecords()) _fromRecord(record),
    ];
    int inGroup(String group) => records
        .where(
          (r) => imageCategoriesOfGroup(
            group,
          ).any((category) => belongsToImageCategory(r, category)),
        )
        .length;

    setUp(
      () => SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: _adminId,
            displayName: 'Admin',
          ).encode(),
        ],
        ProfileService.adminProfileIdsKey: [_adminId],
        ExerciseImageMetadataService.preferencesKey: jsonEncode({
          'schemaVersion': 2,
          'records': [
            _local('local_5000000000000001', ['people', 'crowd']),
            _local('local_5000000000000002', ['restaurant', 'menu']),
          ],
        }),
      }),
    );

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: FlatImageLibraryScreen(
            selectMode: false,
            readOnly: false,
            metadataEditingEnabled: true,
            actorProfileId: _adminId,
          ),
        ),
      );
      for (
        var attempt = 0;
        attempt < 20 &&
            find.byKey(const Key('exercise-image-search')).evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    String count(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const Key('exercise-image-count')))
        .data!;

    Future<void> chooseChip(WidgetTester tester, String label) async {
      await tester.scrollUntilVisible(
        find.widgetWithText(ChoiceChip, label),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('exercise-image-category-filter')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, label));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pump();
    }

    Finder groupRow() =>
        find.byKey(const Key('exercise-image-group-categories'));

    testWidgets('a group is one chip with a row of its categories', (
      tester,
    ) async {
      await open(tester);
      // Its categories are not chips of their own any more.
      for (final category in ['people_family', 'jobs_professions', 'animals']) {
        expect(
          find.widgetWithText(ChoiceChip, imageSubcategoryLabel(category)),
          findsNothing,
          reason: category,
        );
      }
      expect(groupRow(), findsNothing);
      await chooseChip(tester, 'people');
      expect(groupRow(), findsOneWidget);
      expect(
        find.descendant(
          of: groupRow(),
          matching: find.widgetWithText(ChoiceChip, 'all people'),
        ),
        findsOneWidget,
      );
      // The tag "people" adds nothing to People: the rule of a tag and the
      // category of the same name stays with the categories.
      expect(count(tester), '${inGroup('people')} images');
      expect(
        find.byKey(const ValueKey('exercise-image-local_5000000000000001')),
        findsNothing,
      );

      await tester.tap(
        find.descendant(
          of: groupRow(),
          matching: find.widgetWithText(ChoiceChip, 'jobs professions'),
        ),
      );
      await tester.pump();
      final jobs = records
          .where((r) => belongsToImageCategory(r, 'jobs_professions'))
          .length;
      expect(count(tester), '$jobs images');
      // Still on the group's row, now on the category.
      expect(
        tester
            .widget<ChoiceChip>(
              find.descendant(
                of: groupRow(),
                matching: find.widgetWithText(ChoiceChip, 'jobs professions'),
              ),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'people'))
            .selected,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a picture tagged with a category shows in its group', (
      tester,
    ) async {
      await open(tester);
      await chooseChip(tester, 'food & drink');
      // The device picture tagged "restaurant" shows in Restaurant, so in
      // Food & drink too.
      expect(count(tester), '${inGroup('food_drink') + 1} images');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the characters keep their own row', (tester) async {
      await open(tester);
      await chooseChip(tester, 'characters');
      expect(
        find.byKey(const Key('exercise-image-character-categories')),
        findsOneWidget,
      );
      expect(groupRow(), findsNothing);
      expect(find.widgetWithText(ChoiceChip, 'all characters'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
