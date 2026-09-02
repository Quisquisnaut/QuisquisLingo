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
  ];

  static final assetPaths = Set<String>.unmodifiable(
    options.map((option) => option.assetPath),
  );

  static LessonIconOption byId(String id) =>
      options.singleWhere((option) => option.id == id);

  static bool isApproved(String path) => assetPaths.contains(path.trim());
}
