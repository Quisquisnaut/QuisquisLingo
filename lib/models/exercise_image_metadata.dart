class ExerciseImageMetadata {
  final String id;
  final String label;
  final String category;
  final List<String> tags;
  final String assetPath;
  final String origin;

  const ExerciseImageMetadata({
    required this.id,
    required this.label,
    required this.category,
    required this.tags,
    required this.assetPath,
    required this.origin,
  });

  ExerciseImageMetadata copyWith({String? category, List<String>? tags}) =>
      ExerciseImageMetadata(
        id: id,
        label: label,
        category: category ?? this.category,
        tags: List.unmodifiable(tags ?? this.tags),
        assetPath: assetPath,
        origin: origin,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category,
    'tags': tags,
    'assetPath': assetPath,
    'origin': origin,
  };
}
