class LessonIconOption {
  final String id;
  final String assetPath;
  final String label;

  const LessonIconOption({
    required this.id,
    required this.assetPath,
    required this.label,
  });
}

/// The closed set of release-owned Lesson theme icons available to courses.
class LessonIconCatalog {
  static const directory = 'assets/lesson_icons/';

  static const options = <LessonIconOption>[
    LessonIconOption(
      id: 'conversation',
      assetPath: 'assets/lesson_icons/speech_bubbles.png',
      label: 'Conversation',
    ),
    LessonIconOption(
      id: 'family',
      assetPath: 'assets/lesson_icons/family.png',
      label: 'Family',
    ),
    LessonIconOption(
      id: 'home',
      assetPath: 'assets/lesson_icons/home.png',
      label: 'Home',
    ),
    LessonIconOption(
      id: 'food',
      assetPath: 'assets/lesson_icons/food.png',
      label: 'Food',
    ),
    LessonIconOption(
      id: 'coffee',
      assetPath: 'assets/lesson_icons/coffee.png',
      label: 'Café / Coffee',
    ),
    LessonIconOption(
      id: 'shopping',
      assetPath: 'assets/lesson_icons/shopping.png',
      label: 'Shopping',
    ),
    LessonIconOption(
      id: 'directions',
      assetPath: 'assets/lesson_icons/directions.png',
      label: 'Directions / Map',
    ),
    LessonIconOption(
      id: 'airport',
      assetPath: 'assets/lesson_icons/airport.png',
      label: 'Airport / Travel',
    ),
    LessonIconOption(
      id: 'train',
      assetPath: 'assets/lesson_icons/train.png',
      label: 'Train',
    ),
    LessonIconOption(
      id: 'hotel',
      assetPath: 'assets/lesson_icons/hotel.png',
      label: 'Hotel',
    ),
    LessonIconOption(
      id: 'work',
      assetPath: 'assets/lesson_icons/work.png',
      label: 'Work',
    ),
    LessonIconOption(
      id: 'school',
      assetPath: 'assets/lesson_icons/school.png',
      label: 'School',
    ),
    LessonIconOption(
      id: 'time',
      assetPath: 'assets/lesson_icons/time.png',
      label: 'Time / Calendar',
    ),
    LessonIconOption(
      id: 'leisure',
      assetPath: 'assets/lesson_icons/leisure.png',
      label: 'Leisure',
    ),
    // Build 264 Revision 8: sixteen icons drawn by the owner (series 2).
    LessonIconOption(
      id: 'animals',
      assetPath: 'assets/lesson_icons/animals.png',
      label: 'Animals',
    ),
    LessonIconOption(
      id: 'nature_weather',
      assetPath: 'assets/lesson_icons/nature_weather.png',
      label: 'Nature and weather',
    ),
    LessonIconOption(
      id: 'body_health',
      assetPath: 'assets/lesson_icons/body_health.png',
      label: 'Body and health',
    ),
    LessonIconOption(
      id: 'clothing',
      assetPath: 'assets/lesson_icons/clothing.png',
      label: 'Clothing',
    ),
    LessonIconOption(
      id: 'sports',
      assetPath: 'assets/lesson_icons/sports.png',
      label: 'Sports',
    ),
    LessonIconOption(
      id: 'music',
      assetPath: 'assets/lesson_icons/music.png',
      label: 'Music',
    ),
    LessonIconOption(
      id: 'art_culture',
      assetPath: 'assets/lesson_icons/art_culture.png',
      label: 'Art and culture',
    ),
    LessonIconOption(
      id: 'colours_shapes',
      assetPath: 'assets/lesson_icons/colours_shapes.png',
      label: 'Colours and shapes',
    ),
    LessonIconOption(
      id: 'numbers_maths',
      assetPath: 'assets/lesson_icons/numbers_maths.png',
      label: 'Numbers and maths',
    ),
    LessonIconOption(
      id: 'emotions',
      assetPath: 'assets/lesson_icons/emotions.png',
      label: 'Emotions',
    ),
    LessonIconOption(
      id: 'city',
      assetPath: 'assets/lesson_icons/city.png',
      label: 'City',
    ),
    LessonIconOption(
      id: 'world_countries',
      assetPath: 'assets/lesson_icons/world_countries.png',
      label: 'World and countries',
    ),
    LessonIconOption(
      id: 'technology',
      assetPath: 'assets/lesson_icons/technology.png',
      label: 'Technology',
    ),
    LessonIconOption(
      id: 'celebrations',
      assetPath: 'assets/lesson_icons/celebrations.png',
      label: 'Celebrations',
    ),
    LessonIconOption(
      id: 'alphabet_writing',
      assetPath: 'assets/lesson_icons/alphabet_writing.png',
      label: 'Alphabet and writing',
    ),
    LessonIconOption(
      id: 'questions_conversation',
      assetPath: 'assets/lesson_icons/questions_conversation.png',
      label: 'Questions and conversation',
    ),
  ];

  static final assetPaths = Set<String>.unmodifiable(
    options.map((option) => option.assetPath),
  );

  static LessonIconOption byId(String id) =>
      options.singleWhere((option) => option.id == id);

  static bool isApproved(String path) => assetPaths.contains(path.trim());

  /// The icons added in Build 264 Revision 8: an earlier build does not
  /// have them, so a Course that uses one records this build too.
  static final addedInBuild264 = Set<String>.unmodifiable({
    'assets/lesson_icons/animals.png',
    'assets/lesson_icons/nature_weather.png',
    'assets/lesson_icons/body_health.png',
    'assets/lesson_icons/clothing.png',
    'assets/lesson_icons/sports.png',
    'assets/lesson_icons/music.png',
    'assets/lesson_icons/art_culture.png',
    'assets/lesson_icons/colours_shapes.png',
    'assets/lesson_icons/numbers_maths.png',
    'assets/lesson_icons/emotions.png',
    'assets/lesson_icons/city.png',
    'assets/lesson_icons/world_countries.png',
    'assets/lesson_icons/technology.png',
    'assets/lesson_icons/celebrations.png',
    'assets/lesson_icons/alphabet_writing.png',
    'assets/lesson_icons/questions_conversation.png',
  });

  /// Build 264 Revision 8 (owner decision of 5 October 2026): a Lesson icon
  /// may also be a QQL picture of the image library. Only QQL's own WebP
  /// pictures qualify: not a World Flag (not square), not a picture of this
  /// device or of a Course (a Course keeps its own icons as managed ones).
  static bool isLibraryPicture(String path) =>
      _libraryPicture.hasMatch(path.trim());

  static final _libraryPicture = RegExp(
    r'^assets/exercise_images/[a-z0-9_]+\.webp$',
  );

  /// The first build that draws a library picture as a Lesson icon; a
  /// Course that uses one records it as its `minimumAppBuild`.
  static const libraryPictureMinimumAppBuild = 264008;
}
