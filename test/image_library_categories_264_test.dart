import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/image_categories.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// Build 264 Revision 2 (owner decisions of 5 October 2026): the categories
// of the image library, Search all, the category in a picture's card, the
// characters as one category with subcategories, and the tag hint.

const _adminId = '11111111-1111-4111-8111-111111111111';

Map<String, Object> _admin({Map<String, Object> extra = const {}}) => {
  ProfileService.profilesKey: [
    const LearnerProfile(
      learnerProfileId: _adminId,
      displayName: 'Admin',
    ).encode(),
  ],
  ProfileService.adminProfileIdsKey: [_adminId],
  ...extra,
};

Finder _tile(String id) => find.byKey(ValueKey('exercise-image-$id'));

/// The category chips are built as they scroll into view.
Future<void> _showChip(WidgetTester tester, String label) =>
    tester.scrollUntilVisible(
      find.widgetWithText(ChoiceChip, label),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('exercise-image-category-filter')),
        matching: find.byType(Scrollable),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(_admin()));

  Future<void> open(
    WidgetTester tester, {
    String? initialCategory,
    bool admin = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: FlatImageLibraryScreen(
          selectMode: false,
          readOnly: !admin,
          metadataEditingEnabled: admin,
          actorProfileId: admin ? _adminId : null,
          initialCategory: initialCategory,
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

  test('the catalog uses exactly the library categories', () {
    final used = {
      for (final record in readBundledImageRecords())
        record['category'] as String,
    };
    expect(imageCategories.containsAll(used), isTrue);
    // Every category QQL offers has pictures, apart from Other.
    expect(imageCategories.difference(used), {'other'});
    for (final category in characterCategoryLabels.keys) {
      expect(isCharacterCategory(category), isTrue, reason: category);
      expect(imageCategories, contains(category));
    }
    for (final entry in imageCategoryAliases.entries) {
      expect(imageCategories, contains(entry.value), reason: entry.key);
      expect(imageCategories, isNot(contains(entry.key)), reason: entry.key);
    }
    expect(imageCategoryLabel('characters_latin'), 'characters › latin');
    // Revision 7: the toy-block letters A–Z have a subcategory of their own.
    expect(imageCategoryLabel('characters_blocks'), 'characters › toy blocks');
    // Build 265 Revision 9: a category in a group is named after it.
    expect(imageCategoryLabel('art_cinema'), 'free time › art cinema');
    expect(imageCategoryLabel('colors'), 'colors');
  });

  test('the tag hint: only when every tag repeats the name', () {
    expect(tagsOnlyRepeatName('Drum', ['drum']), isTrue);
    expect(tagsOnlyRepeatName('Hair dryer', [' hair  dryer ']), isTrue);
    expect(tagsOnlyRepeatName('Drum', ['drum', 'percussion']), isFalse);
    expect(splitImageTags(' drum, , percussion '), ['drum', 'percussion']);
  });

  testWidgets('the characters are one category with a row of their own', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('characters › latin'), findsNothing);
    expect(
      find.byKey(const Key('exercise-image-character-categories')),
      findsNothing,
    );
    await _showChip(tester, 'characters');
    await tester.tap(find.widgetWithText(ChoiceChip, 'characters'));
    await tester.pump();
    expect(
      find.byKey(const Key('exercise-image-character-categories')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ChoiceChip, 'latin'));
    await tester.pump();
    expect(_tile('letters_latin_char_latin_capital_a'), findsOneWidget);
    expect(_tile('people_family_man'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Recognize characters opens the library on the characters', (
    tester,
  ) async {
    await open(tester, initialCategory: characterCategoryGroup);
    expect(
      find.byKey(const Key('exercise-image-character-categories')),
      findsOneWidget,
    );
    expect(_tile('people_family_man'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Search all looks in every category, unless unticked', (
    tester,
  ) async {
    await open(tester);
    // Build 265 Revision 9: Animals is in the group Nature & animals.
    await _showChip(tester, 'nature & animals');
    await tester.ensureVisible(
      find.widgetWithText(ChoiceChip, 'nature & animals'),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'nature & animals'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, 'animals'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'people_family_grandfather',
    );
    await tester.pump();
    expect(_tile('people_family_grandfather'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exercise-image-search-all')));
    await tester.pump();
    expect(_tile('people_family_grandfather'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets("the category in a picture's card opens that category", (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'people_family_man',
    );
    await tester.pump();
    await tester.tap(_tile('people_family_man'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('image-preview-category')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    // The search is cleared and the category is shown alone, on its
    // group's row (Build 265 Revision 9).
    expect(find.text('people_family_man'), findsNothing);
    final chip = find.descendant(
      of: find.byKey(const Key('exercise-image-group-categories')),
      matching: find.widgetWithText(ChoiceChip, 'people family'),
    );
    expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
    expect(_tile('people_family_grandmother'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the tag hint appears in Edit metadata and never blocks', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(
      _admin(
        extra: {
          ExerciseImageMetadataService.preferencesKey: jsonEncode({
            'schemaVersion': 2,
            'records': [
              {
                'id': 'local_5000000000000000',
                'label': 'Drum',
                'category': 'other',
                'tags': ['drum'],
                'assetPath': 'C:/no/such/drum.webp',
                'origin': 'local',
              },
            ],
          }),
        },
      ),
    );
    await open(tester, admin: true);
    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'local_5000000000000000',
    );
    await tester.pump();
    await tester.tap(_tile('local_5000000000000000'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('exercise-image-metadata-edit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const Key('exercise-image-tag-hint')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('exercise-image-tags-editor')),
      'drum, percussion',
    );
    await tester.pump();
    expect(find.byKey(const Key('exercise-image-tag-hint')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
