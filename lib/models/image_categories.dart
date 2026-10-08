/// The categories of the image library (Build 264 Revision 2).
///
/// One flat list of category IDs, as the catalog and every stored record
/// write them. The characters are one group with subcategories, each ID
/// starting with `characters_`; the library shows the group as one category
/// with a second row of choices. QQL's list is fixed: an Admin no longer
/// creates categories, and an Image Bank's unknown category is mapped by the
/// Admin to one of these, or to `other`.
library;

/// The group that holds the character pictures.
const characterCategoryGroup = 'characters';

/// The character subcategories in display order, with their short names.
const characterCategoryLabels = <String, String>{
  'characters_latin': 'latin',
  'characters_blocks': 'toy blocks',
  'characters_accented': 'accented',
  'characters_greek': 'greek',
  'characters_cyrillic': 'cyrillic',
  'characters_armenian': 'armenian',
  'characters_georgian': 'georgian',
  'characters_hebrew': 'hebrew',
  'characters_arabic': 'arabic',
  'characters_devanagari': 'devanagari',
  'characters_thai': 'thai',
  'characters_korean': 'korean',
  'characters_hiragana': 'hiragana',
  'characters_katakana': 'katakana',
  'characters_chinese': 'chinese',
  'characters_diacritics': 'diacritics',
  'characters_confusables': 'confusable pairs',
  'characters_punctuation': 'punctuation',
  'characters_currency': 'currency',
  'characters_maths': 'maths',
  'characters_symbols': '@ # & © ® ™',
};

/// Every category a QQL or device picture may have.
const imageCategories = <String>{
  'actions',
  'animals',
  'appearance',
  'architecture',
  'art_cinema',
  'body_parts',
  'business_work',
  'celebrations',
  'city_places',
  'clock_times',
  'clothing_accessories',
  'colors',
  'communication',
  'concepts',
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
  'historical_figures',
  'hobbies_leisure',
  'home_household',
  'ideas_opinions',
  'jobs_professions',
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
  'other',
  'people_family',
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
  'units',
  'utilities',
  'characters_latin',
  'characters_blocks',
  'characters_accented',
  'characters_greek',
  'characters_cyrillic',
  'characters_armenian',
  'characters_georgian',
  'characters_hebrew',
  'characters_arabic',
  'characters_devanagari',
  'characters_thai',
  'characters_korean',
  'characters_hiragana',
  'characters_katakana',
  'characters_chinese',
  'characters_diacritics',
  'characters_confusables',
  'characters_punctuation',
  'characters_currency',
  'characters_maths',
  'characters_symbols',
};

/// Earlier category names and where their pictures are now. A device record
/// or an Image Bank that still uses one is read under the new category.
const imageCategoryAliases = <String, String>{
  'food': 'food_drinks',
  'home': 'home_household',
  // Build 264 Revision 2.
  'letters_latin': 'characters_latin',
  'letters_accented': 'characters_accented',
  'letters_greek': 'characters_greek',
  'letters_cyrillic': 'characters_cyrillic',
  'letters_armenian': 'characters_armenian',
  'letters_georgian': 'characters_georgian',
  'letters_hebrew': 'characters_hebrew',
  'letters_arabic': 'characters_arabic',
  'letters_devanagari': 'characters_devanagari',
  'letters_thai': 'characters_thai',
  'letters_korean': 'characters_korean',
  'kana_hiragana': 'characters_hiragana',
  'kana_katakana': 'characters_katakana',
  'chinese_characters': 'characters_chinese',
  'diacritics': 'characters_diacritics',
  'comparisons': 'characters_confusables',
  'punctuation': 'characters_punctuation',
  'currency_symbols': 'characters_currency',
  'math_symbols': 'characters_maths',
  'family_relatives': 'people_family',
  'people_roles': 'people_family',
  'relationships_marriage': 'relationships',
  'games_cards': 'games',
  'games_chess': 'games',
  'city_public_places': 'city_places',
  'urban_places': 'city_places',
  'public_services': 'services',
  'shops_services': 'services',
  'baby_care': 'home_household',
  'inheritance': 'death_remembrance',
  'safety_emergency': 'everyday_objects',
  'country_maps': 'maps_navigation',
  'everyday_misc': 'other',
  'time_space': 'other',
};

bool isCharacterCategory(String category) =>
    category.startsWith('${characterCategoryGroup}_');

/// Groups of categories (Build 265 Revision 9, owner decision of 7 October
/// 2026). The library shows a group as one choice with a second row of its
/// categories, as it does for the characters. Display only: every picture
/// keeps its own category, and a category is in one group at most; the
/// categories of no group stand alone. Group keys are never category IDs.
const imageCategoryGroups = <String, List<String>>{
  'people': [
    'people_family',
    'jobs_professions',
    'relationships',
    'life_stages',
    'appearance',
    'personality',
    'emotions',
  ],
  'food_drink': ['food_drinks', 'food_descriptions', 'restaurant'],
  'body_health': [
    'body_parts',
    'health_care',
    'health_illness',
    'death_remembrance',
  ],
  'home_things': [
    'home_household',
    'everyday_objects',
    'tools',
    'technology',
    'materials_commodities',
    'utilities',
  ],
  'places_travel': [
    'city_places',
    'architecture',
    'landmarks',
    'services',
    'shopping',
    'maps_navigation',
    'travel',
    'transport',
    'street_signs',
    'construction_farming',
  ],
  'numbers_time': [
    'numbers',
    'clock_times',
    'time_calendar',
    'units',
    'sizes_dimensions',
    'shapes_patterns',
  ],
  'language_grammar': [
    'grammar',
    'grammar_time',
    'pronouns_be_have',
    'question_words',
    'quantity_pointing',
    'directions_positions',
    'opposites',
    'greetings_expressions',
    'languages',
  ],
  'society_culture': [
    'politics',
    'crime_law',
    'economy_finance',
    'business_work',
    'ideas_opinions',
    'communication',
    'culture_traditions',
    'celebrations',
  ],
  'history_stories': [
    'historical_figures',
    'literary_characters',
    'mythology',
    'religious_figures',
  ],
  'free_time': ['hobbies_leisure', 'sports', 'games', 'art_cinema'],
  'nature_animals': ['nature', 'animals'],
};

/// The groups' names as the library shows them.
const imageCategoryGroupLabels = <String, String>{
  'people': 'people',
  'food_drink': 'food & drink',
  'body_health': 'body & health',
  'home_things': 'home & things',
  'places_travel': 'places & travel',
  'numbers_time': 'numbers & time',
  'language_grammar': 'language & grammar',
  'society_culture': 'society & culture',
  'history_stories': 'history & stories',
  'free_time': 'free time',
  'nature_animals': 'nature & animals',
};

final _groupOfCategory = <String, String>{
  for (final entry in imageCategoryGroups.entries)
    for (final category in entry.value) category: entry.key,
};

/// Whether [value] names a group (the characters' or one of
/// [imageCategoryGroups]) rather than a category.
bool isImageCategoryGroup(String value) =>
    value == characterCategoryGroup || imageCategoryGroups.containsKey(value);

/// The group [category] belongs to, or null when it stands alone.
String? imageCategoryGroupOf(String category) => isCharacterCategory(category)
    ? characterCategoryGroup
    : _groupOfCategory[category];

/// The categories of [group], in the order of its second row.
List<String> imageCategoriesOfGroup(String group) =>
    group == characterCategoryGroup
    ? characterCategoryLabels.keys.toList()
    : imageCategoryGroups[group] ?? const [];

/// A category's short name on its group's second row: "latin", "jobs
/// professions".
String imageSubcategoryLabel(String category) =>
    characterCategoryLabels[category] ?? category.replaceAll('_', ' ');

/// A category under its current name.
String canonicalImageCategory(String category) =>
    imageCategoryAliases[category] ?? category;

/// A category as people read it, after its group when it has one: "colors",
/// "characters › latin", "free time › art cinema"; a group by its name:
/// "food & drink".
String imageCategoryLabel(String category) {
  final character = characterCategoryLabels[category];
  if (character != null) return '$characterCategoryGroup › $character';
  if (category == characterCategoryGroup) return characterCategoryGroup;
  final group = imageCategoryGroupLabels[category];
  if (group != null) return group;
  final name = category.replaceAll('_', ' ');
  final groupOf = _groupOfCategory[category];
  return groupOf == null
      ? name
      : '${imageCategoryGroupLabels[groupOf]} › $name';
}
