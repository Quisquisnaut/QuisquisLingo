enum WorldFlagCategory {
  unMember,
  isoExtra,
  shortlist,
  communityOrRegionalFlagAssociatedWithLanguage,
}

enum FlagGameMode {
  unMembers('UN'),
  iso('UN + ISO'),
  isoPlusShortlist('UN + ISO + Shortlist'),
  allFlags('All Flags');

  final String label;

  const FlagGameMode(this.label);
}

enum WorldFlagReferenceCategory {
  unMembers('UN Members', 'Flags of the 193 United Nations Member States.'),
  isoExtras(
    'ISO extras',
    'Additional ISO 3166-1 entities not included among UN Member States.',
  ),
  shortlist(
    'Shortlist',
    'Additional nationally or regionally distinct entities with well-established flags and strong cultural or political identity.',
  ),
  languageRelatedFlags(
    'Language-related flags',
    'Flags associated with distinct linguistic communities or minority-language regions not already represented in the preceding categories.',
  );

  final String label;
  final String description;

  const WorldFlagReferenceCategory(this.label, this.description);
}

class WorldFlagEntity {
  final String id;
  final String displayNameEn;
  final String assetPath;
  final String? isoAlpha2;
  final String? isoAlpha3;
  final String? subdivisionCode;
  final WorldFlagCategory category;
  final List<String> aliases;
  final String? artworkSourcePage;
  final String? artworkLicense;
  final String? artworkAuthor;

  /// Upstream SHA-1 when the bundled SVG is renderer-normalized.
  ///
  /// When null, [artworkSha1] also identifies the unmodified source bytes.
  final String? artworkSourceSha1;

  /// SHA-1 of the exact SVG bytes bundled with the application.
  final String? artworkSha1;
  final Set<String> distractorTags;
  final Set<String> avoidAsDistractorWith;

  const WorldFlagEntity({
    required this.id,
    required this.displayNameEn,
    required this.assetPath,
    required this.category,
    this.isoAlpha2,
    this.isoAlpha3,
    this.subdivisionCode,
    this.aliases = const [],
    this.artworkSourcePage,
    this.artworkLicense,
    this.artworkAuthor,
    this.artworkSourceSha1,
    this.artworkSha1,
    this.distractorTags = const {},
    this.avoidAsDistractorWith = const {},
  });

  factory WorldFlagEntity.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];
    return WorldFlagEntity(
      id: json['id'] as String,
      displayNameEn: json['displayNameEn'] as String,
      assetPath: json['assetPath'] as String,
      isoAlpha2: json['isoAlpha2'] as String?,
      isoAlpha3: json['isoAlpha3'] as String?,
      subdivisionCode: json['subdivisionCode'] as String?,
      category: WorldFlagCategory.values.firstWhere(
        (value) => value.name == rawCategory,
      ),
      aliases: List<String>.unmodifiable(
        (json['aliases'] as List? ?? const []).cast<String>(),
      ),
      artworkSourcePage: json['artworkSourcePage'] as String?,
      artworkLicense: json['artworkLicense'] as String?,
      artworkAuthor: json['artworkAuthor'] as String?,
      artworkSourceSha1: json['artworkSourceSha1'] as String?,
      artworkSha1: json['artworkSha1'] as String?,
      distractorTags: Set<String>.unmodifiable(
        (json['distractorTags'] as List? ?? const []).cast<String>(),
      ),
      avoidAsDistractorWith: Set<String>.unmodifiable(
        (json['avoidAsDistractorWith'] as List? ?? const []).cast<String>(),
      ),
    );
  }
}

class WorldFlagLanguageSuggestion {
  final String languageTag;
  final List<String> languageNames;
  final List<String> worldFlagIds;

  const WorldFlagLanguageSuggestion({
    required this.languageTag,
    required this.worldFlagIds,
    this.languageNames = const [],
  });

  factory WorldFlagLanguageSuggestion.fromJson(Map<String, dynamic> json) {
    return WorldFlagLanguageSuggestion(
      languageTag: json['languageTag'] as String,
      languageNames: List<String>.unmodifiable(
        (json['languageNames'] as List? ?? const []).cast<String>(),
      ),
      worldFlagIds: List<String>.unmodifiable(
        (json['worldFlagIds'] as List? ?? const []).cast<String>(),
      ),
    );
  }
}

class WorldFlagManifest {
  final List<WorldFlagEntity> entities;
  final List<WorldFlagLanguageSuggestion> languageSuggestions;

  const WorldFlagManifest({
    required this.entities,
    this.languageSuggestions = const [],
  });
}
