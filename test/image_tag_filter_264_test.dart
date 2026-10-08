import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/screens/flat_image_library_screen.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// Build 264 Revision 5 (owner decision of 5 October 2026, "Ok B"): a tag in a
// picture's card shows only the pictures that carry that tag, or are named
// so, in every category, under a removable "Tag:" chip. Typing in Search
// keeps finding every word that contains the text.

ExerciseImageMetadata _picture({
  String label = 'Cat',
  List<String> tags = const ['pet', 'kitten'],
  List<String> localWords = const [],
}) => ExerciseImageMetadata(
  id: 'animals_cat',
  label: label,
  category: 'animals',
  tags: tags,
  assetPath: 'assets/exercise_images/cat.webp',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('carriesImageTag', () {
    test('matches a whole tag, Local word or name', () {
      final cat = _picture(localWords: const ['gatto']);
      expect(carriesImageTag(cat, 'pet'), isTrue);
      expect(carriesImageTag(cat, 'gatto'), isTrue);
      // The name counts: QQL never repeats it as a tag.
      expect(carriesImageTag(cat, 'cat'), isTrue);
    });

    test('ignores capitals and spaces, never matches part of a word', () {
      final cat = _picture(tags: const ['house  pet']);
      expect(carriesImageTag(cat, ' House Pet '), isTrue);
      expect(carriesImageTag(cat, 'pet'), isFalse);
      expect(carriesImageTag(_picture(label: 'Catalonia'), 'cat'), isFalse);
      expect(carriesImageTag(cat, ''), isFalse);
    });

    test('on the catalog it is narrower than the search', () {
      final records = [
        for (final record in readBundledImageRecords()) _fromRecord(record),
      ];
      final tagged = records.where((r) => carriesImageTag(r, 'cat')).length;
      final searched = records
          .where((r) => matchesImageSearch(r, normalizeImageSearchText('cat')))
          .length;
      expect(tagged, greaterThan(0));
      expect(tagged, lessThan(searched));
    });
  });

  group('the library', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    // A tag carried by a few pictures in at least two categories, so that
    // every one of them is on screen and the filter is seen to cross
    // categories; chosen from the catalog, not hard-coded.
    ({ExerciseImageMetadata source, String tag, Set<String> carriers})
    pickTag() {
      final records = [
        for (final record in readBundledImageRecords())
          if ((record['assetPath'] as String).endsWith('.webp'))
            _fromRecord(record),
      ]..sort((a, b) => a.id.compareTo(b.id));
      for (final source in records) {
        for (final tag in source.tags) {
          final carriers = records.where((r) => carriesImageTag(r, tag));
          final categories = {for (final r in carriers) r.category};
          if (carriers.length >= 3 &&
              carriers.length <= 6 &&
              categories.length >= 2) {
            return (
              source: source,
              tag: tag,
              carriers: {for (final r in carriers) r.id},
            );
          }
        }
      }
      throw StateError('no suitable tag in the catalog');
    }

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

    Set<String> shownIds(WidgetTester tester) => {
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
    };

    testWidgets('a tag in a card filters the whole library until removed', (
      tester,
    ) async {
      final pick = pickTag();
      await open(tester);

      // Find the source picture by its ID and open its card.
      await tester.enterText(
        find.byKey(const Key('exercise-image-search')),
        pick.source.id,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('exercise-image-${pick.source.id}')),
      );
      await tester.pumpAndSettle();

      final index = pick.source.tags.indexOf(pick.tag);
      await tester.tap(find.byKey(Key('image-preview-tag-$index')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Tag: ${pick.tag}'), findsOneWidget);
      final search = tester.widget<TextField>(
        find.byKey(const Key('exercise-image-search')),
      );
      expect(search.controller!.text, isEmpty);
      expect(shownIds(tester), pick.carriers);

      // Removing the chip shows the whole library again.
      await tester.tap(find.byTooltip('Remove the tag filter'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise-image-tag-filter')), findsNothing);
      expect(shownIds(tester).difference(pick.carriers), isNotEmpty);
    });

    testWidgets('choosing a category ends the tag filter', (tester) async {
      final pick = pickTag();
      await open(tester);
      await tester.enterText(
        find.byKey(const Key('exercise-image-search')),
        pick.source.id,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(ValueKey('exercise-image-${pick.source.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          Key('image-preview-tag-${pick.source.tags.indexOf(pick.tag)}'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('exercise-image-tag-filter')),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('exercise-image-tag-filter')), findsNothing);
    });
  });
}
