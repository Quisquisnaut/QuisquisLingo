import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bundled_image_catalog.dart';

// Build 265 Revision 5 (owner's brief of 7 October 2026): better tags and a
// few new pictures for the image library. Every record outside the
// character categories should carry at least five tags besides its name;
// Revisions 5 to 8 completed them group by group and Revision 8 made it a
// rule for the whole catalog (`image_catalog_rules_264_test` and
// `tools/validate_images.py` refuse a picture below it).

/// The categories whose tags are complete. Each revision adds its group.
const _completedCategories = {
  // Revision 5, group 1.
  'actions',
  'animals',
  'appearance',
  'architecture',
  'art_cinema',
  'body_parts',
  'business_work',
  'celebrations',
  'city_places',
  'clothing_accessories',
  'colors',
  'communication',
  'concepts',
  // Revision 6, group 2.
  'construction_farming',
  'crime_law',
  'culture_traditions',
  'death_remembrance',
  'directions_positions',
  'economy_finance',
  'emotions',
  'everyday_objects',
  'flags',
  'food_descriptions',
  'food_drinks',
  'games',
  'grammar',
  'grammar_time',
  'greetings_expressions',
  'health_care',
  'health_illness',
  // Revision 7, group 3.
  'historical_figures',
  'hobbies_leisure',
  'home_household',
  'ideas_opinions',
  'landmarks',
  'languages',
  'lesson_icons',
  'life_stages',
  'literary_characters',
  'maps_navigation',
  'materials_commodities',
  'movement',
  'mythology',
  'nature',
  'numbers',
  'opposites',
  'people_family',
  // Revision 8, group 4 and the categories no group named.
  'personality',
  'politics',
  'pronouns_be_have',
  'quantity_pointing',
  'question_words',
  'relationships',
  'religious_figures',
  'restaurant',
  'school_work',
  'services',
  'shapes_patterns',
  'shopping',
  'sizes_dimensions',
  'sports',
  'street_signs',
  'symbols',
  'technology',
  'time_calendar',
  'tools',
  'transport',
  'travel',
  'utilities',
  'jobs_professions',
  'units',
  'clock_times',
};

const _minimumTags = 5;
const _maximumTags = 32;
const _maximumTagLength = 80;

void main() {
  final records = readBundledImageRecords();
  final byId = {for (final r in records) r['id'] as String: r};
  List<String> tagsOf(String id) => (byId[id]!['tags'] as List).cast<String>();
  Set<String> keysOf(String id) => tagsOf(id).map(imageWordKey).toSet();

  test('the completed categories give every picture five tags or more', () {
    final short = [
      for (final r in records)
        if (_completedCategories.contains(r['category']) &&
            (r['tags'] as List).length < _minimumTags)
          '${r['id']} (${(r['tags'] as List).length})',
    ];
    expect(short, isEmpty);
    // Every completed category still holds pictures.
    for (final category in _completedCategories) {
      expect(
        records.where((r) => r['category'] == category),
        isNotEmpty,
        reason: category,
      );
    }
  });

  test('no picture carries more than 32 tags or a tag over 80 characters', () {
    for (final r in records) {
      final tags = (r['tags'] as List).cast<String>();
      expect(tags.length, lessThanOrEqualTo(_maximumTags), reason: r['id']);
      for (final tag in tags) {
        expect(
          tag.length,
          inInclusiveRange(1, _maximumTagLength),
          reason: '${r['id']}: $tag',
        );
      }
    }
  });

  test('the ten new pictures are in the catalog with their tags', () {
    const expected = {
      'food_drinks_artichoke': ('Artichoke', 'food_drinks', 'artichoke'),
      'food_drinks_fig': ('Fig', 'food_drinks', 'fig'),
      'food_drinks_macaroni': ('Macaroni', 'food_drinks', 'macaroni'),
      'food_drinks_provolone': ('Provolone', 'food_drinks', 'provolone'),
      'food_drinks_orange_soda': ('Orange soda', 'food_drinks', 'orange_soda'),
      'nature_asteroid': ('Asteroid', 'nature', 'asteroid'),
      'nature_dry_soil': ('Dry soil', 'nature', 'dry_soil'),
      'jobs_professions_tennis_player_man': (
        'Tennis Player (man)',
        'jobs_professions',
        'tennis_player_man',
      ),
      'jobs_professions_tennis_player_woman': (
        'Tennis Player (woman)',
        'jobs_professions',
        'tennis_player_woman',
      ),
      'relationships_friends': ('Friends', 'relationships', 'friends'),
    };
    for (final MapEntry(key: id, value: (label, category, file))
        in expected.entries) {
      final record = byId[id];
      expect(record, isNotNull, reason: id);
      expect(record!['label'], label);
      expect(record['category'], category);
      expect(record['assetPath'], 'assets/exercise_images/$file.webp');
      expect(tagsOf(id).length, greaterThanOrEqualTo(_minimumTags), reason: id);
    }
    expect(keysOf('food_drinks_macaroni'), contains('elbow pasta'));
    expect(keysOf('food_drinks_orange_soda'), contains('can of soda'));
    expect(keysOf('nature_asteroid'), contains('space rock'));
    expect(keysOf('nature_dry_soil'), contains('cracked earth'));
    expect(keysOf('jobs_professions_tennis_player_woman'), contains('female'));
  });

  test('"friend" finds the Friends picture, not a single man or woman', () {
    expect(keysOf('relationships_friends'), contains('friend'));
    expect(keysOf('people_family_man'), isNot(contains('friend')));
    expect(keysOf('people_family_woman'), isNot(contains('friend')));
  });

  test('the owner\'s seven tag additions are there', () {
    expect(keysOf('emotions_waving'), containsAll(['hi', 'wave hand']));
    expect(keysOf('concepts_wrong'), contains('not'));
    expect(keysOf('body_parts_eye'), containsAll(['see', 'look', 'sight']));
    expect(keysOf('travel_tourist'), contains('travel'));
    expect(keysOf('opposites_dry_adj'), contains('dried'));
    expect(keysOf('emotions_angry'), contains('angry face'));
    // Revision 6 moved "me" and "myself" to "I, me, my, myself".
    expect(keysOf('pronouns_be_have_pronoun_i'), containsAll(['myself', 'me']));
    expect(
      keysOf('pronouns_be_have_pronoun_i_am'),
      isNot(anyOf(contains('me'), contains('myself'))),
    );
  });

  test('Revision 6: the fifteen new pictures are in the catalog', () {
    const expected = {
      'pronouns_be_have_pronoun_i': ('I, me, my, myself', 'pronoun_i'),
      'pronouns_be_have_pronoun_you': ('You, your, yourself', 'pronoun_you'),
      'pronouns_be_have_pronoun_he': ('He, him, his, himself', 'pronoun_he'),
      'pronouns_be_have_pronoun_she': ('She, her, herself', 'pronoun_she'),
      'pronouns_be_have_pronoun_it': ('It, its, itself', 'pronoun_it'),
      'pronouns_be_have_pronoun_we': ('We, us, our, ourselves', 'pronoun_we'),
      'pronouns_be_have_pronoun_you_all': (
        'You all, your, yourselves',
        'pronoun_you_all',
      ),
      'pronouns_be_have_pronoun_they': (
        'They, them, their, themselves',
        'pronoun_they',
      ),
      'relationships_friend_man': ('Friend (man)', 'friend_man'),
      'relationships_friend_woman': ('Friend (woman)', 'friend_woman'),
      'people_family_kid_boy': ('Kid (boy)', 'kid_boy'),
      'people_family_kid_girl': ('Kid (girl)', 'kid_girl'),
      // Not hello.webp: that path is retired (unified_learner_layout_regression).
      'greetings_expressions_hello': ('Hello!', 'hello_greeting'),
      'greetings_expressions_bye': ('Bye!', 'bye'),
      'greetings_expressions_goodbye': ('Goodbye!', 'goodbye'),
    };
    for (final MapEntry(key: id, value: (label, file)) in expected.entries) {
      final record = byId[id];
      expect(record, isNotNull, reason: id);
      expect(record!['label'], label);
      expect(record['assetPath'], 'assets/exercise_images/$file.webp');
      expect(tagsOf(id).length, greaterThanOrEqualTo(_minimumTags), reason: id);
    }
    // Every form of the pronoun is a tag of its picture.
    expect(
      keysOf('pronouns_be_have_pronoun_she'),
      containsAll(['her', 'hers']),
    );
    expect(
      keysOf('pronouns_be_have_pronoun_they'),
      containsAll(['them', 'their', 'theirs', 'themselves']),
    );
    expect(keysOf('greetings_expressions_goodbye'), contains('farewell'));
  });

  test(
    'Revision 6: Jump is named Jump, adults man/woman, children boy/girl',
    () {
      expect(byId['actions_jump']!['label'], 'Jump');
      expect(keysOf('actions_jump'), isNot(contains('jump')));
      // Owner decision of 7 October 2026: a picture of an adult names its
      // person "(man)" / "(woman)", of a child "(boy)" / "(girl)"; the tags
      // carry male and female too. "(male)" / "(female)" are for animals.
      for (final r in records.where((r) => r['category'] != 'animals')) {
        final label = r['label'] as String;
        expect(label, isNot(contains('(male)')), reason: r['id']);
        expect(label, isNot(contains('(female)')), reason: r['id']);
      }
      expect(keysOf('relationships_friend_woman'), contains('female'));
      expect(keysOf('relationships_friend_man'), contains('male'));
    },
  );

  test('Revision 7: the owner\'s pronoun tags and three corrections', () {
    expect(
      keysOf('pronouns_be_have_pronoun_you_all'),
      containsAll(['you plural', 'plural you']),
    );
    expect(
      keysOf('pronouns_be_have_pronoun_you'),
      containsAll(['you singular', 'singular you']),
    );
    // A tag goes to the picture that answers it best: the noun "hoover" is
    // the vacuum cleaner, "glass of water" is Water, Hot is a hot drink.
    expect(keysOf('home_household_vacuum_cleaner'), contains('hoover'));
    expect(keysOf('actions_vacuuming'), isNot(contains('hoover')));
    expect(keysOf('water'), contains('glass of water'));
    expect(keysOf('actions_drink'), isNot(contains('glass of water')));
    expect(keysOf('food_descriptions_hot'), contains('hot drink'));
    expect(keysOf('food_descriptions_hot'), isNot(contains('hot food')));
  });

  test('Revision 8: "racket" finds the racket, not the sport', () {
    expect(keysOf('sports_tennis_racket'), contains('racket'));
    expect(keysOf('sports_tennis'), isNot(contains('racket')));
  });

  test('every category outside the characters is complete', () {
    final categories = {
      for (final r in records)
        if (!isCharacterImageCategory(r['category'] as String))
          r['category'] as String,
    };
    expect(categories.difference(_completedCategories), isEmpty);
  });

  test('the tennis racket is drawn apart from the sport, at its old path', () {
    final racket = byId['sports_tennis_racket']!;
    expect(racket['assetPath'], 'assets/exercise_images/tennis_racket.webp');
    expect(racket['label'], 'Tennis racket');
    String digest(String path) =>
        sha256.convert(File(path).readAsBytesSync()).toString();
    expect(
      digest(racket['assetPath'] as String),
      isNot(digest(byId['sports_tennis']!['assetPath'] as String)),
    );
  });
}
