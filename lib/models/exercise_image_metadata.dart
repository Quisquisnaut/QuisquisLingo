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

/// Where a device-added shared image came from, recorded when it was
/// imported, so later duplicate and conflict decisions are deterministic.
/// Only [sha256] is always known: images added before Build 243 Revision 16
/// get it (and [byteLength]) the first time the library is indexed. Never an
/// external path or URI.
class ImageProvenance {
  const ImageProvenance({
    required this.sha256,
    this.byteLength,
    this.detectedFormat,
    this.sourceName,
    this.source,
    this.bankId,
    this.importedBy,
    this.importedAtUtc,
  });

  /// Lowercase hex SHA-256 of the stored file.
  final String sha256;
  final int? byteLength;

  /// `png`, `jpg` or `webp`, from the content.
  final String? detectedFormat;

  /// The external file's sanitized name.
  final String? sourceName;

  /// One of [sources].
  final String? source;
  final String? bankId;

  /// The importing Admin's profile ID.
  final String? importedBy;
  final DateTime? importedAtUtc;

  static const singleImport = 'single_import';
  static const imageBank = 'image_bank';
  static const coursePackage = 'course_package';
  static const sources = {singleImport, imageBank, coursePackage};
  static final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  Map<String, dynamic> toJson() => {
    'sha256': sha256,
    'byteLength': ?byteLength,
    'detectedFormat': ?detectedFormat,
    'sourceName': ?sourceName,
    'source': ?source,
    'bankId': ?bankId,
    'importedBy': ?importedBy,
    if (importedAtUtc != null)
      'importedAtUtc': importedAtUtc!.toUtc().toIso8601String(),
  };

  factory ImageProvenance.fromJson(Map<String, dynamic> json) {
    const allowed = {
      'sha256',
      'byteLength',
      'detectedFormat',
      'sourceName',
      'source',
      'bankId',
      'importedBy',
      'importedAtUtc',
    };
    if (json.keys.toSet().difference(allowed).isNotEmpty) {
      throw const FormatException('Image provenance has unsupported fields.');
    }
    final sha = json['sha256'];
    if (sha is! String || !_sha256Pattern.hasMatch(sha)) {
      throw const FormatException('Image provenance needs a SHA-256.');
    }
    String? text(String name) {
      final value = json[name];
      if (value == null) return null;
      if (value is! String || value.isEmpty || value.length > 200) {
        throw FormatException('Image provenance $name is invalid.');
      }
      return value;
    }

    final length = json['byteLength'];
    if (length != null && (length is! int || length < 0)) {
      throw const FormatException('Image provenance byteLength is invalid.');
    }
    final source = text('source');
    if (source != null && !sources.contains(source)) {
      throw const FormatException('Image provenance source is invalid.');
    }
    final at = text('importedAtUtc');
    final importedAt = at == null ? null : DateTime.tryParse(at);
    if (at != null && importedAt == null) {
      throw const FormatException('Image provenance importedAtUtc is invalid.');
    }
    return ImageProvenance(
      sha256: sha,
      byteLength: length as int?,
      detectedFormat: text('detectedFormat'),
      sourceName: text('sourceName'),
      source: source,
      bankId: text('bankId'),
      importedBy: text('importedBy'),
      importedAtUtc: importedAt?.toUtc(),
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

  /// Set for images this device imported; null for QQL's own.
  final ImageProvenance? provenance;

  const ExerciseImageMetadata({
    required this.id,
    required this.label,
    required this.category,
    required this.tags,
    required this.assetPath,
    required this.origin,
    this.attribution,
    this.localWords = const [],
    this.provenance,
  });

  ExerciseImageMetadata copyWith({
    String? category,
    List<String>? tags,
    ImageAttribution? attribution,
    bool clearAttribution = false,
    List<String>? localWords,
    ImageProvenance? provenance,
  }) => ExerciseImageMetadata(
    id: id,
    label: label,
    category: category ?? this.category,
    tags: List.unmodifiable(tags ?? this.tags),
    assetPath: assetPath,
    origin: origin,
    attribution: clearAttribution ? null : attribution ?? this.attribution,
    localWords: List.unmodifiable(localWords ?? this.localWords),
    provenance: provenance ?? this.provenance,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category,
    'tags': tags,
    'assetPath': assetPath,
    'origin': origin,
    if (attribution != null) 'attribution': attribution!.toJson(),
    if (provenance != null) 'provenance': provenance!.toJson(),
  };
}
