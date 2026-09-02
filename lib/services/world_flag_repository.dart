import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/world_flag_entity.dart';

class WorldFlagRepository {
  static const manifestAsset = 'assets/world_flags/manifest.json';

  final AssetBundle _bundle;
  List<WorldFlagEntity>? _cache;

  WorldFlagRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<List<WorldFlagEntity>> load() async =>
      _cache ??= parseManifest(await _bundle.loadString(manifestAsset));

  static List<WorldFlagEntity> parseManifest(String raw) {
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
    return List.unmodifiable(entities);
  }

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
