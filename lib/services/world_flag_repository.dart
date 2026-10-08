import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/world_flag_entity.dart';

class WorldFlagRepository {
  static const manifestAsset = 'assets/world_flags/manifest.json';

  final AssetBundle _bundle;
  WorldFlagManifest? _manifestCache;
  Map<String, WorldFlagEntity>? _byId;

  WorldFlagRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<WorldFlagManifest> loadManifest() async => _manifestCache ??=
      parseManifestDocument(await _bundle.loadString(manifestAsset));

  Future<List<WorldFlagEntity>> load() async => (await loadManifest()).entities;

  Future<WorldFlagEntity?> findById(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return null;
    final entities = await load();
    final byId = _byId ??= Map.unmodifiable({
      for (final entity in entities) entity.id: entity,
    });
    return byId[normalized];
  }

  static bool matchesSearch(WorldFlagEntity entity, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return <String?>[
      entity.id,
      entity.displayNameEn,
      entity.isoAlpha2,
      entity.isoAlpha3,
      entity.subdivisionCode,
      ...entity.aliases,
    ].whereType<String>().any(
      (value) => value.toLowerCase().contains(normalized),
    );
  }

  static List<WorldFlagEntity> search(
    Iterable<WorldFlagEntity> entities,
    String query,
  ) => List.unmodifiable(
    entities.where((entity) => matchesSearch(entity, query)),
  );

  static List<WorldFlagEntity> parseManifest(String raw) {
    return parseManifestDocument(raw).entities;
  }

  static WorldFlagManifest parseManifestDocument(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported world-flag manifest');
    }
    final rawEntities = decoded['entities'];
    if (rawEntities is! List) {
      throw const FormatException('World-flag manifest has no entities');
    }
    final entities = rawEntities
        .map(
          (value) =>
              WorldFlagEntity.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false);
    final ids = entities.map((entity) => entity.id).toSet();
    if (ids.length != entities.length) {
      throw const FormatException('World-flag IDs are not unique');
    }
    final rawSuggestions = decoded['languageSuggestions'] ?? const [];
    if (rawSuggestions is! List) {
      throw const FormatException(
        'World-flag manifest language suggestions are invalid',
      );
    }
    final suggestions = rawSuggestions
        .map(
          (value) => WorldFlagLanguageSuggestion.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false);
    final normalizedTags = <String>{};
    final normalizedNames = <String>{};
    for (final suggestion in suggestions) {
      final tag = _normalizeLanguageTag(suggestion.languageTag);
      if (tag.isEmpty || !normalizedTags.add(tag)) {
        throw const FormatException(
          'World-flag language suggestion tags must be non-empty and unique',
        );
      }
      if (suggestion.worldFlagIds.isEmpty ||
          suggestion.worldFlagIds.toSet().length !=
              suggestion.worldFlagIds.length ||
          suggestion.worldFlagIds.any((id) => !ids.contains(id))) {
        throw FormatException(
          'World-flag language suggestion "$tag" has invalid flag IDs',
        );
      }
      for (final name in suggestion.languageNames) {
        final normalizedName = _normalizeLanguageName(name);
        if (normalizedName.isEmpty || !normalizedNames.add(normalizedName)) {
          throw const FormatException(
            'World-flag language suggestion names must be non-empty and unique',
          );
        }
      }
    }
    return WorldFlagManifest(
      entities: List.unmodifiable(entities),
      languageSuggestions: List.unmodifiable(suggestions),
    );
  }

  static List<WorldFlagEntity> suggestForLanguage(
    WorldFlagManifest manifest, {
    String? languageTag,
    String? languageName,
  }) {
    final byTag = <String, WorldFlagLanguageSuggestion>{
      for (final suggestion in manifest.languageSuggestions)
        _normalizeLanguageTag(suggestion.languageTag): suggestion,
    };
    final byName = <String, WorldFlagLanguageSuggestion>{
      for (final suggestion in manifest.languageSuggestions)
        for (final name in suggestion.languageNames)
          _normalizeLanguageName(name): suggestion,
    };

    WorldFlagLanguageSuggestion? match;
    final normalizedTag = _normalizeLanguageTag(languageTag ?? '');
    if (normalizedTag.isNotEmpty) {
      match = byTag[normalizedTag];
      if (match == null) {
        final baseTag = normalizedTag.split('-').first;
        match = byTag[baseTag];
      }
    }
    if (match == null) {
      final normalizedName = _normalizeLanguageName(languageName ?? '');
      if (normalizedName.isNotEmpty) {
        match = byName[normalizedName];
      }
    }
    if (match == null) return const [];

    final byId = {for (final entity in manifest.entities) entity.id: entity};
    return List.unmodifiable(match.worldFlagIds.map((id) => byId[id]!));
  }

  static String _normalizeLanguageTag(String value) => value
      .trim()
      .replaceAll('_', '-')
      .toLowerCase()
      .split('-')
      .where((part) => part.isNotEmpty)
      .join('-');

  static String _normalizeLanguageName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static List<WorldFlagEntity> poolFor(
    List<WorldFlagEntity> entities,
    FlagGameMode mode,
  ) => List.unmodifiable(
    entities.where(
      (entity) => switch (mode) {
        FlagGameMode.unMembers => entity.category == WorldFlagCategory.unMember,
        FlagGameMode.iso =>
          entity.category == WorldFlagCategory.unMember ||
              entity.category == WorldFlagCategory.isoExtra,
        FlagGameMode.isoPlusShortlist =>
          entity.category !=
              WorldFlagCategory.communityOrRegionalFlagAssociatedWithLanguage,
        FlagGameMode.allFlags => true,
      },
    ),
  );

  static List<WorldFlagEntity> referenceFor(
    List<WorldFlagEntity> entities,
    WorldFlagReferenceCategory category,
  ) {
    final requested = switch (category) {
      WorldFlagReferenceCategory.unMembers => WorldFlagCategory.unMember,
      WorldFlagReferenceCategory.isoExtras => WorldFlagCategory.isoExtra,
      WorldFlagReferenceCategory.shortlist => WorldFlagCategory.shortlist,
      WorldFlagReferenceCategory.languageRelatedFlags =>
        WorldFlagCategory.communityOrRegionalFlagAssociatedWithLanguage,
    };
    final result = entities
        .where((entity) => entity.category == requested)
        .toList();
    result.sort(
      (left, right) => left.displayNameEn.toLowerCase().compareTo(
        right.displayNameEn.toLowerCase(),
      ),
    );
    return List.unmodifiable(result);
  }
}
