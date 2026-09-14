import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_image_metadata.dart';
import 'profile_service.dart';

class ExerciseImageMetadataService {
  static const bundledCatalogAsset = 'assets/exercise_images/metadata_v2.json';
  static const preferencesKey = 'quisquislingo_exercise_image_metadata_v2';

  static const categories = <String>{
    'actions',
    'animals',
    'body_parts',
    'city_public_places',
    'clothing_accessories',
    'emotions',
    'food',
    'food_drinks',
    'home',
    'home_household',
    'nature',
    'other',
    'people_family',
    'school_work',
    'technology',
    'transport',
  };

  final AssetBundle _bundle;
  final ProfileService _profiles;

  ExerciseImageMetadataService({
    AssetBundle? bundle,
    ProfileService? profileService,
  }) : _bundle = bundle ?? rootBundle,
       _profiles = profileService ?? ProfileService();

  Future<List<ExerciseImageMetadata>> loadCatalog() async {
    final bundled = _parseDocument(
      await _bundle.loadString(bundledCatalogAsset),
      source: 'bundled exercise-image metadata',
    );
    final preferences = await SharedPreferences.getInstance();
    final persisted = preferences.getString(preferencesKey);
    if (persisted == null) return bundled;

    final current = _parseDocument(
      persisted,
      source: 'current exercise-image metadata',
    );
    final currentById = {for (final record in current) record.id: record};
    for (final seed in bundled) {
      final record = currentById[seed.id];
      if (record == null) {
        throw FormatException(
          'Current exercise-image metadata is missing ${seed.id}.',
        );
      }
      if (record.label != seed.label ||
          record.assetPath != seed.assetPath ||
          record.origin != seed.origin) {
        throw FormatException(
          'Current exercise-image identity fields changed for ${seed.id}.',
        );
      }
    }
    return current;
  }

  Future<ExerciseImageMetadata> metadataFor(String imageId) async {
    final normalized = imageId.trim();
    for (final record in await loadCatalog()) {
      if (record.id == normalized) return record;
    }
    throw FormatException(
      'No current exercise-image metadata exists for "$normalized".',
    );
  }

  Future<void> updateMetadata({
    required String actorProfileId,
    required String imageId,
    required String category,
    required List<String> tags,
  }) async {
    await _requireAdmin(actorProfileId);
    final normalizedCategory = _normalizeCategory(category);
    final normalizedTags = _normalizeTags(tags);
    final records = await loadCatalog();
    final index = records.indexWhere((record) => record.id == imageId.trim());
    if (index < 0) {
      throw FormatException(
        'No current exercise-image metadata exists for "${imageId.trim()}".',
      );
    }
    final updated = [...records];
    updated[index] = updated[index].copyWith(
      category: normalizedCategory,
      tags: normalizedTags,
    );
    await _persist(updated);
  }

  Future<void> addLocalRecord({
    required String actorProfileId,
    required ExerciseImageMetadata record,
  }) => addLocalRecords(actorProfileId: actorProfileId, records: [record]);

  Future<void> addLocalRecords({
    required String actorProfileId,
    required List<ExerciseImageMetadata> records,
  }) async {
    await _requireAdmin(actorProfileId);
    final current = await loadCatalog();
    final ids = current.map((record) => record.id).toSet();
    final paths = current.map((record) => record.assetPath).toSet();
    final normalizedRecords = <ExerciseImageMetadata>[];
    for (final record in records) {
      final normalized = ExerciseImageMetadata(
        id: _requiredText(record.id, 'id'),
        label: _requiredText(record.label, 'label'),
        category: _normalizeCategory(record.category),
        tags: _normalizeTags(record.tags),
        assetPath: _requiredText(record.assetPath, 'assetPath'),
        origin: _requiredText(record.origin, 'origin'),
      );
      if (!ids.add(normalized.id) || !paths.add(normalized.assetPath)) {
        throw FormatException(
          'Exercise-image ID or asset path is already registered: ${normalized.id}.',
        );
      }
      normalizedRecords.add(normalized);
    }
    await _persist([...current, ...normalizedRecords]);
  }

  Future<void> removeLocalRecords({
    required String actorProfileId,
    required Set<String> imageIds,
  }) async {
    await _requireAdmin(actorProfileId);
    final records = await loadCatalog();
    final targets = records.where((record) => imageIds.contains(record.id));
    if (targets.any((record) => record.origin == 'bundled')) {
      throw StateError('Bundled exercise-image metadata cannot be removed.');
    }
    await _persist(
      records.where((record) => !imageIds.contains(record.id)).toList(),
    );
  }

  Future<void> _requireAdmin(String actorProfileId) async {
    if (!await _profiles.isAdmin(actorProfileId)) {
      throw StateError(
        'Only an Admin may modify global exercise-image metadata.',
      );
    }
  }

  Future<void> _persist(List<ExerciseImageMetadata> records) async {
    final ordered = [...records]
      ..sort((left, right) => left.id.compareTo(right.id));
    final document = jsonEncode({
      'schemaVersion': 1,
      'records': ordered.map((record) => record.toJson()).toList(),
    });
    await (await SharedPreferences.getInstance()).setString(
      preferencesKey,
      document,
    );
  }

  static List<ExerciseImageMetadata> _parseDocument(
    String raw, {
    required String source,
  }) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['schemaVersion'] != 1) {
        throw FormatException('$source has an unsupported schema.');
      }
      final rawRecords = decoded['records'];
      if (rawRecords is! List) {
        throw FormatException('$source has no records list.');
      }
      final records = <ExerciseImageMetadata>[];
      final ids = <String>{};
      final paths = <String>{};
      const fields = {'id', 'label', 'category', 'tags', 'assetPath', 'origin'};
      for (final rawRecord in rawRecords) {
        if (rawRecord is! Map) {
          throw FormatException('$source contains a non-object record.');
        }
        final record = Map<String, dynamic>.from(rawRecord);
        if (record.keys.toSet().difference(fields).isNotEmpty ||
            fields.difference(record.keys.toSet()).isNotEmpty) {
          throw FormatException(
            '$source contains unsupported metadata fields.',
          );
        }
        final id = _requiredText(record['id'], 'id');
        final path = _requiredText(record['assetPath'], 'assetPath');
        if (!ids.add(id) || !paths.add(path)) {
          throw FormatException('$source contains duplicate image identity.');
        }
        final rawTags = record['tags'];
        if (rawTags is! List) {
          throw FormatException('$source contains invalid tags for $id.');
        }
        records.add(
          ExerciseImageMetadata(
            id: id,
            label: _requiredText(record['label'], 'label'),
            category: _normalizeCategory(record['category']),
            tags: _normalizeTags(rawTags.map((tag) => tag.toString()).toList()),
            assetPath: path,
            origin: _requiredText(record['origin'], 'origin'),
          ),
        );
      }
      return List.unmodifiable(records);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('$source is invalid: $error');
    }
  }

  static String _requiredText(Object? value, String field) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isEmpty) throw FormatException('$field must not be empty.');
    return normalized;
  }

  static String _normalizeCategory(Object? value) {
    final normalized = _requiredText(value, 'category');
    if (!categories.contains(normalized)) {
      throw FormatException(
        'Unsupported exercise-image category: $normalized.',
      );
    }
    return normalized;
  }

  static List<String> _normalizeTags(List<String> values) {
    final normalized = values
        .map((tag) => tag.trim().replaceAll(RegExp(r'\s+'), ' '))
        .toList(growable: false);
    if (normalized.isEmpty || normalized.any((tag) => tag.isEmpty)) {
      throw const FormatException('Exercise-image tags must not be empty.');
    }
    if (normalized.toSet().length != normalized.length) {
      throw const FormatException(
        'Exercise-image tags must not contain exact duplicates.',
      );
    }
    return List.unmodifiable(normalized);
  }
}
