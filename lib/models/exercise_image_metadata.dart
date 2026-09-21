/// Optional credit attached to one Admin-added shared image.
class ImageAttribution {
  final String author;
  final String license;
  final String title;
  final String source;

  const ImageAttribution({
    required this.author,
    required this.license,
    this.title = '',
    this.source = '',
  });

  Map<String, dynamic> toJson() => {
    'author': author,
    'license': license,
    if (title.isNotEmpty) 'title': title,
    if (source.isNotEmpty) 'source': source,
  };

  factory ImageAttribution.fromJson(Map<String, dynamic> json) {
    if (json.keys.toSet().difference({
      'author',
      'license',
      'title',
      'source',
    }).isNotEmpty) {
      throw const FormatException('Image attribution has unsupported fields.');
    }
    String field(String name, {bool required = false, int limit = 200}) {
      final raw = json[name];
      if (raw != null && raw is! String) {
        throw FormatException('Image attribution $name must be text.');
      }
      final value = (raw as String? ?? '').trim().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      if (required && value.isEmpty) {
        throw FormatException('Image attribution $name is required.');
      }
      if (value.length > limit) {
        throw FormatException('Image attribution $name is too long.');
      }
      return value;
    }

    return ImageAttribution(
      author: field('author', required: true),
      license: field('license', required: true),
      title: field('title'),
      source: field('source', limit: 500),
    );
  }
}

class ExerciseImageMetadata {
  final String id;
  final String label;
  final String category;
  final List<String> tags;
  final String assetPath;
  final String origin;
  final ImageAttribution? attribution;

  /// Device-local search words an Admin added to a QQL (bundled) image. They
  /// never replace QQL's own tags and are never exported. Always empty for
  /// other images, and not part of [toJson].
  final List<String> localWords;

  const ExerciseImageMetadata({
    required this.id,
    required this.label,
    required this.category,
    required this.tags,
    required this.assetPath,
    required this.origin,
    this.attribution,
    this.localWords = const [],
  });

  ExerciseImageMetadata copyWith({
    String? category,
    List<String>? tags,
    ImageAttribution? attribution,
    bool clearAttribution = false,
    List<String>? localWords,
  }) => ExerciseImageMetadata(
    id: id,
    label: label,
    category: category ?? this.category,
    tags: List.unmodifiable(tags ?? this.tags),
    assetPath: assetPath,
    origin: origin,
    attribution: clearAttribution ? null : attribution ?? this.attribution,
    localWords: List.unmodifiable(localWords ?? this.localWords),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category,
    'tags': tags,
    'assetPath': assetPath,
    'origin': origin,
    if (attribution != null) 'attribution': attribution!.toJson(),
  };
}
