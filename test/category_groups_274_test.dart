import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/models/image_categories.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// Build 274 Revision 6 (the owner's point 9 of 13 October 2026): two small
// categories join a group, as the other groups work. Movement goes with
// Actions, Symbols with Concepts. Display only: every picture keeps its
// own category.

const _adminId = '11111111-1111-4111-8111-111111111111';

ExerciseImageMetadata _picture(
  String category,
  String label, {
  List<String> tags = const ['thing'],
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

  group('the two groups', () {
    test('Movement joins Actions, Symbols joins Concepts', () {
      expect(imageCategoriesOfGroup('actions_movement'), [
        'actions',
        'movement',
      ]);
      expect(imageCategoriesOfGroup('concepts_symbols'), [
        'concepts',
        'symbols',
      ]);
      for (final category in ['actions', 'movement']) {
        expect(imageCategoryGroupOf(category), 'actions_movement');
      }
      for (final category in ['concepts', 'symbols']) {
        expect(imageCategoryGroupOf(category), 'concepts_symbols');
      }
      expect(isImageCategoryGroup('actions_movement'), isTrue);
      expect(isImageCategoryGroup('concepts_symbols'), isTrue);
      // A group key is never a category.
      expect(imageCategories, isNot(contains('actions_movement')));
      expect(imageCategories, isNot(contains('concepts_symbols')));
      expect(imageCategoryLabel('actions_movement'), 'actions & movement');
      expect(imageCategoryLabel('concepts_symbols'), 'concepts & symbols');
      expect(imageCategoryLabel('movement'), 'actions & movement › movement');
      expect(imageCategoryLabel('symbols'), 'concepts & symbols › symbols');
      expect(imageSubcategoryLabel('movement'), 'movement');
      // The stored categories are unchanged: the pictures keep them.
      for (final category in ['actions', 'movement', 'concepts', 'symbols']) {
        expect(imageCategories, contains(category));
        expect(canonicalImageCategory(category), category);
      }
    });

    test('the catalog has pictures in all four categories', () {
      final categories = {
        for (final record in readBundledImageRecords())
          record['category'] as String,
      };
      for (final category in ['actions', 'movement', 'concepts', 'symbols']) {
        expect(categories, contains(category), reason: category);
      }
    });

    test("a group's whole name finds both categories; a category's name "
        'finds only its own', () {
      final run = _picture('actions', 'Run', tags: const ['jog']);
      final spin = _picture('movement', 'Spin', tags: const ['turn']);
      final idea = _picture('concepts', 'Idea', tags: const ['thought']);
      final stop = _picture('symbols', 'Stop', tags: const ['halt']);
      bool finds(
        ExerciseImageMetadata asset,
        String text, {
        bool strict = false,
      }) => matchesImageSearch(
        asset,
        normalizeImageSearchText(text),
        strict: strict,
      );
      for (final text in ['actions & movement', 'Actions and Movement']) {
        expect(finds(run, text), isTrue, reason: text);
        expect(finds(spin, text), isTrue, reason: text);
        expect(finds(run, text, strict: true), isTrue, reason: text);
        expect(finds(idea, text), isFalse, reason: text);
      }
      for (final text in ['concepts & symbols', 'concepts and symbols']) {
        expect(finds(idea, text), isTrue, reason: text);
        expect(finds(stop, text), isTrue, reason: text);
        expect(finds(stop, text, strict: true), isTrue, reason: text);
      }
      // "movement" alone is the Movement category, not the whole group.
      expect(finds(spin, 'movement'), isTrue);
      expect(finds(run, 'movement'), isFalse);
      expect(finds(stop, 'symbols'), isTrue);
      expect(finds(idea, 'symbols'), isFalse);
      // A whole group's name is a whole-word match.
      expect(
        imageSearchMatch(spin, normalizeImageSearchText('actions & movement')),
        ImageSearchMatch.tagWord,
      );
    });
  });

  group('the library', () {
    final records = [
      for (final record in readBundledImageRecords()) _fromRecord(record),
    ];
    int inCategory(String category) =>
        records.where((r) => belongsToImageCategory(r, category)).length;
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

    Finder topChip(String label) => find.descendant(
      of: find.byKey(const Key('exercise-image-category-filter')),
      matching: find.widgetWithText(ChoiceChip, label),
    );

    Finder groupRow() =>
        find.byKey(const Key('exercise-image-group-categories'));

    // The chip row is a lazy list: a chip far to the right is not built
    // until it is scrolled to, so read every chip by scrolling the row.
    Future<Set<String>> topChipLabels(WidgetTester tester) async {
      final row = find.byKey(const Key('exercise-image-category-filter'));
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: row, matching: find.byType(Scrollable)),
          )
          .position;
      final labels = <String>{};
      var offset = 0.0;
      while (true) {
        position.jumpTo(offset.clamp(0, position.maxScrollExtent));
        await tester.pump();
        for (final text in tester.widgetList<Text>(
          find.descendant(of: row, matching: find.byType(Text)),
        )) {
          labels.add(text.data ?? '');
        }
        if (offset >= position.maxScrollExtent) break;
        offset += position.viewportDimension / 2;
      }
      position.jumpTo(0);
      await tester.pump();
      return labels;
    }

    Finder rowChip(String label) => find.descendant(
      of: groupRow(),
      matching: find.widgetWithText(ChoiceChip, label),
    );

    Future<void> chooseChip(WidgetTester tester, String label) async {
      await tester.scrollUntilVisible(
        topChip(label),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('exercise-image-category-filter')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(topChip(label));
      await tester.pump();
      await tester.tap(topChip(label));
      await tester.pump();
    }

    testWidgets('each group is one chip with a row of its two categories', (
      tester,
    ) async {
      await open(tester);
      final chips = await topChipLabels(tester);
      // The whole row was read: a group and a category from far right.
      expect(
        chips,
        containsAll(['nature & animals', 'school work', 'society & culture']),
      );
      expect(chips, containsAll(['actions & movement', 'concepts & symbols']));
      // The four categories are no chips of their own any more.
      for (final category in ['actions', 'movement', 'concepts', 'symbols']) {
        expect(chips, isNot(contains(category)), reason: category);
      }
      for (final (group, categories) in [
        ('actions_movement', ['actions', 'movement']),
        ('concepts_symbols', ['concepts', 'symbols']),
      ]) {
        final label = imageCategoryLabel(group);
        await chooseChip(tester, label);
        expect(groupRow(), findsOneWidget);
        expect(rowChip('all $label'), findsOneWidget);
        expect(count(tester), '${inGroup(group)} images');
        for (final category in categories) {
          await tester.tap(rowChip(category));
          await tester.pump();
          expect(
            count(tester),
            '${inCategory(category)} images',
            reason: category,
          );
          expect(tester.widget<ChoiceChip>(rowChip(category)).selected, isTrue);
          // The group's chip stays chosen above.
          expect(tester.widget<ChoiceChip>(topChip(label)).selected, isTrue);
        }
        await tester.tap(rowChip('all $label'));
        await tester.pump();
        expect(count(tester), '${inGroup(group)} images');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
