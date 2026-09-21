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
    'food_drinks',
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

  /// The stored document's current shape: device-owned records only, plus
  /// Local words for QQL images and the device's own categories.
  static const documentSchemaVersion = 2;
  static const maxDeviceCategories = 64;
  static const maxLocalWords = 32;
  static const maxLocalWordLength = 80;
  static final deviceCategoryPattern = RegExp(r'^[a-z][a-z0-9_]{1,39}$');

  /// The catalog: QQL's bundled records, always as the app ships them, with
  /// any Local words, followed by the images an Admin added on this device.
  Future<List<ExerciseImageMetadata>> loadCatalog() async {
    final bundled = await _bundledRecords();
    final document = await _loadDocument(bundled);
    final ids = {for (final record in bundled) record.id};
    final paths = {for (final record in bundled) record.assetPath};
    return List.unmodifiable([
      for (final record in bundled)
        document.localWords.containsKey(record.id)
            ? record.copyWith(localWords: document.localWords[record.id])
            : record,
      // A device record can never shadow a QQL image, even if a later app
      // release reuses its ID or path.
      for (final record in document.records)
        if (!ids.contains(record.id) && !paths.contains(record.assetPath))
          record,
    ]);
  }

  /// The device's own categories, in name order.
  Future<List<String>> deviceCategories() async =>
      (await _loadDocument(await _bundledRecords())).deviceCategories;

  /// QQL's categories and the device's own, in name order.
  Future<List<String>> allCategories() async =>
      ({...categories, ...await deviceCategories()}.toList()..sort());

  Future<ExerciseImageMetadata> metadataFor(String imageId) async {
    final normalized = imageId.trim();
    for (final record in await loadCatalog()) {
      if (record.id == normalized) return record;
    }
    throw FormatException(
      'No current exercise-image metadata exists for "$normalized".',
    );
  }

  /// Changes an Admin-added image. QQL images are read-only: use
  /// [updateLocalWords] for them.
  Future<void> updateMetadata({
    required String actorProfileId,
    required String imageId,
    required String category,
    required List<String> tags,
    ImageAttribution? attribution,
  }) async {
    await _requireAdmin(actorProfileId);
    final bundled = await _bundledRecords();
    final id = imageId.trim();
    if (bundled.any((record) => record.id == id)) {
      throw StateError(
        'QQL image metadata is read-only. Add Local words instead.',
      );
    }
    final document = await _loadDocument(bundled);
    final normalizedCategory = _normalizeCategory(category, {
      ...categories,
      ...document.deviceCategories,
    });
    final normalizedTags = _normalizeTags(tags);
    final records = [...document.records];
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) {
      throw FormatException(
        'No current exercise-image metadata exists for "$id".',
      );
    }
    records[index] = records[index].copyWith(
      category: normalizedCategory,
      tags: normalizedTags,
      attribution: _normalizedAttribution(attribution),
      clearAttribution: attribution == null,
    );
    await _persistDocument(document.copyWith(records: records));
  }

  /// Sets the Local words of a QQL image; an empty list removes them.
  Future<void> updateLocalWords({
    required String actorProfileId,
    required String imageId,
    required List<String> words,
  }) async {
    await _requireAdmin(actorProfileId);
    final bundled = await _bundledRecords();
    final id = imageId.trim();
    if (!bundled.any((record) => record.id == id)) {
      throw StateError('Local words apply to QQL images only.');
    }
    final normalized = normalizeLocalWords(words);
    final document = await _loadDocument(bundled);
    final localWords = {...document.localWords};
    if (normalized.isEmpty) {
      localWords.remove(id);
    } else {
      localWords[id] = normalized;
    }
    await _persistDocument(document.copyWith(localWords: localWords));
  }

  /// Trims and collapses spaces, drops blanks and case-insensitive repeats,
  /// and enforces [maxLocalWords] and [maxLocalWordLength].
  static List<String> normalizeLocalWords(Iterable<String> words) {
    final out = <String>[];
    final seen = <String>{};
    for (final word in words) {
      final value = word.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
      if (value.length > maxLocalWordLength ||
          value.contains(RegExp(r'[\x00-\x1F\x7F]'))) {
        throw FormatException(
          'A Local word must be at most $maxLocalWordLength characters, '
          'without control characters.',
        );
      }
      out.add(value);
    }
    if (out.length > maxLocalWords) {
      throw const FormatException(
        'An image can have at most $maxLocalWords Local words.',
      );
    }
    return List.unmodifiable(out);
  }

  /// Adds a device category and returns its name.
  Future<String> addDeviceCategory({
    required String actorProfileId,
    required String name,
  }) async {
    await _requireAdmin(actorProfileId);
    final bundled = await _bundledRecords();
    final document = await _loadDocument(bundled);
    final normalized = _newCategoryName(name, document.deviceCategories);
    if (document.deviceCategories.length >= maxDeviceCategories) {
      throw const FormatException(
        'This device already has $maxDeviceCategories categories of its own.',
      );
    }
    await _persistDocument(
      document.copyWith(
        deviceCategories: [...document.deviceCategories, normalized],
      ),
    );
    return normalized;
  }

  /// Renames a device category and moves every image that uses it.
  Future<String> renameDeviceCategory({
    required String actorProfileId,
    required String from,
    required String to,
  }) async {
    await _requireAdmin(actorProfileId);
    final bundled = await _bundledRecords();
    final document = await _loadDocument(bundled);
    if (!document.deviceCategories.contains(from)) {
      throw StateError('Only this device\'s own categories can be renamed.');
    }
    final others = [
      for (final name in document.deviceCategories)
        if (name != from) name,
    ];
    final normalized = _newCategoryName(to, others);
    await _persistDocument(
      document.copyWith(
        deviceCategories: [...others, normalized],
        records: [
          for (final record in document.records)
            record.category == from
                ? record.copyWith(category: normalized)
                : record,
        ],
      ),
    );
    return normalized;
  }

  /// Removes a device category that no image uses.
  Future<void> removeDeviceCategory({
    required String actorProfileId,
    required String name,
  }) async {
    await _requireAdmin(actorProfileId);
    final bundled = await _bundledRecords();
    final document = await _loadDocument(bundled);
    if (!document.deviceCategories.contains(name)) {
      throw StateError('Only this device\'s own categories can be removed.');
    }
    if (document.records.any((record) => record.category == name)) {
      throw const FormatException(
        'This category is still used by an image. Move those images first.',
      );
    }
    await _persistDocument(
      document.copyWith(
        deviceCategories: [
          for (final category in document.deviceCategories)
            if (category != name) category,
        ],
      ),
    );
  }

  static String _newCategoryName(String name, List<String> existing) {
    final value = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (!deviceCategoryPattern.hasMatch(value)) {
      throw const FormatException(
        'A category name uses 2–40 lowercase letters, digits or underscores, '
        'starting with a letter.',
      );
    }
    if (categories.contains(value) ||
        _categoryAliases.containsKey(value) ||
        existing.contains(value)) {
      throw FormatException('The category "$value" already exists.');
    }
    return value;
  }

  static const _categoryAliases = {
    'food': 'food_drinks',
    'home': 'home_household',
  };

  Future<void> addLocalRecord({
    required String actorProfileId,
    required ExerciseImageMetadata record,
  }) => addLocalRecords(actorProfileId: actorProfileId, records: [record]);

  Future<void> addLocalRecords({
    required String actorProfileId,
    required List<ExerciseImageMetadata> records,
  }) async {
    await _requireAdmin(actorProfileId);
    final bundled = await _bundledRecords();
    final document = await _loadDocument(bundled);
    final allowed = {...categories, ...document.deviceCategories};
    final ids = {
      for (final record in [...bundled, ...document.records]) record.id,
    };
    final paths = {
      for (final record in [...bundled, ...document.records]) record.assetPath,
    };
    final normalizedRecords = <ExerciseImageMetadata>[];
    for (final record in records) {
      final normalized = ExerciseImageMetadata(
        id: _requiredText(record.id, 'id'),
        label: _requiredText(record.label, 'label'),
        category: _normalizeCategory(record.category, allowed),
        tags: _normalizeTags(record.tags),
        assetPath: _requiredText(record.assetPath, 'assetPath'),
        origin: _requiredText(record.origin, 'origin'),
        attribution: _normalizedAttribution(record.attribution),
      );
      if (normalized.origin == 'bundled') {
        throw const FormatException(
          'Only QQL releases add bundled exercise images.',
        );
      }
      if (!ids.add(normalized.id) || !paths.add(normalized.assetPath)) {
        throw FormatException(
          'Exercise-image ID or asset path is already registered: ${normalized.id}.',
        );
      }
      normalizedRecords.add(normalized);
    }
    await _persistDocument(
      document.copyWith(records: [...document.records, ...normalizedRecords]),
    );
  }

  Future<void> removeLocalRecords({
    required String actorProfileId,
    required Set<String> imageIds,
  }) async {
    await _requireAdmin(actorProfileId);
    final bundled = await _bundledRecords();
    if (bundled.any((record) => imageIds.contains(record.id))) {
      throw StateError('Bundled exercise-image metadata cannot be removed.');
    }
    final document = await _loadDocument(bundled);
    await _persistDocument(
      document.copyWith(
        records: [
          for (final record in document.records)
            if (!imageIds.contains(record.id)) record,
        ],
      ),
    );
  }

  /// Refuses anyone but an Admin; import code calls it before writing.
  Future<void> requireAdmin(String actorProfileId) =>
      _requireAdmin(actorProfileId);

  Future<void> _requireAdmin(String actorProfileId) async {
    if (!await _profiles.isAdmin(actorProfileId)) {
      throw StateError(
        'Only an Admin may modify global exercise-image metadata.',
      );
    }
  }

  Future<List<ExerciseImageMetadata>> _bundledRecords() async => _parseDocument(
    await _bundle.loadString(bundledCatalogAsset),
    source: 'bundled exercise-image metadata',
  );

  /// Reads the stored document. A schema-1 snapshot (the whole catalog,
  /// bundled records included) is converted once: bundled records leave it,
  /// tags an Admin had added to a QQL image become its Local words, removed
  /// tags return and category changes to QQL images are dropped.
  Future<_MetadataDocument> _loadDocument(
    List<ExerciseImageMetadata> bundled,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(preferencesKey);
    if (raw == null) return const _MetadataDocument();
    const source = 'current exercise-image metadata';
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (error) {
      throw FormatException('$source is invalid: $error');
    }
    if (decoded is Map && decoded['schemaVersion'] == 1) {
      final converted = _convertSnapshot(
        _parseDocument(raw, source: source),
        bundled,
      );
      await _persistDocument(converted);
      return converted;
    }
    if (decoded is! Map || decoded['schemaVersion'] != documentSchemaVersion) {
      throw FormatException('$source has an unsupported schema.');
    }
    final rawCategories = decoded['deviceCategories'] ?? const [];
    if (rawCategories is! List ||
        rawCategories.any(
          (name) => name is! String || !deviceCategoryPattern.hasMatch(name),
        )) {
      throw FormatException('$source has invalid device categories.');
    }
    final deviceCategories = [...rawCategories.cast<String>()]..sort();
    final rawWords = decoded['localWords'] ?? const {};
    if (rawWords is! Map) {
      throw FormatException('$source has invalid Local words.');
    }
    final bundledIds = {for (final record in bundled) record.id};
    final localWords = <String, List<String>>{};
    rawWords.forEach((id, words) {
      if (id is! String || words is! List) {
        throw FormatException('$source has invalid Local words.');
      }
      // Words for an image a later release no longer ships are ignored.
      if (!bundledIds.contains(id)) return;
      final normalized = normalizeLocalWords(
        words.map((word) => word.toString()),
      );
      if (normalized.isNotEmpty) localWords[id] = normalized;
    });
    return _MetadataDocument(
      records: _parseDocument(
        jsonEncode({
          'schemaVersion': 1,
          'records': decoded['records'] ?? const [],
        }),
        source: source,
        allowedCategories: {...categories, ...deviceCategories},
      ),
      localWords: localWords,
      deviceCategories: deviceCategories,
    );
  }

  static _MetadataDocument _convertSnapshot(
    List<ExerciseImageMetadata> snapshot,
    List<ExerciseImageMetadata> bundled,
  ) {
    final bundledById = {for (final record in bundled) record.id: record};
    final records = <ExerciseImageMetadata>[];
    final localWords = <String, List<String>>{};
    for (final record in snapshot) {
      final seed = bundledById[record.id];
      if (seed == null) {
        // A QQL record the app no longer ships simply leaves the document.
        if (record.origin != 'bundled') records.add(record);
        continue;
      }
      final qqlTags = {for (final tag in seed.tags) tag.toLowerCase()};
      final added = [
        for (final tag in record.tags)
          if (!qqlTags.contains(tag.toLowerCase()) &&
              tag.length <= maxLocalWordLength)
            tag,
      ];
      if (added.isNotEmpty) {
        localWords[record.id] = normalizeLocalWords(added.take(maxLocalWords));
      }
    }
    return _MetadataDocument(records: records, localWords: localWords);
  }

  Future<void> _persistDocument(_MetadataDocument document) async {
    final records = [...document.records]
      ..sort((left, right) => left.id.compareTo(right.id));
    final wordIds = document.localWords.keys.toList()..sort();
    final encoded = jsonEncode({
      'schemaVersion': documentSchemaVersion,
      'records': records.map((record) => record.toJson()).toList(),
      if (wordIds.isNotEmpty)
        'localWords': {for (final id in wordIds) id: document.localWords[id]},
      if (document.deviceCategories.isNotEmpty)
        'deviceCategories': [...document.deviceCategories]..sort(),
    });
    await (await SharedPreferences.getInstance()).setString(
      preferencesKey,
      encoded,
    );
  }

  static List<ExerciseImageMetadata> _parseDocument(
    String raw, {
    required String source,
    Set<String> allowedCategories = categories,
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
      const requiredFields = {
        'id',
        'label',
        'category',
        'tags',
        'assetPath',
        'origin',
      };
      const allowedFields = {...requiredFields, 'attribution'};
      for (final rawRecord in rawRecords) {
        if (rawRecord is! Map) {
          throw FormatException('$source contains a non-object record.');
        }
        final record = Map<String, dynamic>.from(rawRecord);
        if (record.keys.toSet().difference(allowedFields).isNotEmpty ||
            requiredFields.difference(record.keys.toSet()).isNotEmpty) {
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
        final rawAttribution = record['attribution'];
        if (record.containsKey('attribution') && rawAttribution is! Map) {
          throw FormatException('$source contains invalid attribution for $id.');
        }
        final attribution = rawAttribution == null
            ? null
            : ImageAttribution.fromJson(
                Map<String, dynamic>.from(rawAttribution),
              );
        records.add(
          ExerciseImageMetadata(
            id: id,
            label: _requiredText(record['label'], 'label'),
            category: _normalizeCategory(record['category'], allowedCategories),
            tags: _normalizeTags(rawTags.map((tag) => tag.toString()).toList()),
            assetPath: path,
            origin: _requiredText(record['origin'], 'origin'),
            attribution: attribution,
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

  static ImageAttribution? _normalizedAttribution(ImageAttribution? value) =>
      value == null ? null : ImageAttribution.fromJson(value.toJson());

  static String _normalizeCategory(
    Object? value, [
    Set<String> allowed = categories,
  ]) {
    final raw = _requiredText(value, 'category');
    final normalized = _categoryAliases[raw] ?? raw;
    if (!allowed.contains(normalized)) {
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

/// The stored metadata document (schema 2).
class _MetadataDocument {
  const _MetadataDocument({
    this.records = const [],
    this.localWords = const {},
    this.deviceCategories = const [],
  });

  /// Admin-added images only; QQL records always come from the app.
  final List<ExerciseImageMetadata> records;

  /// Local words by QQL image ID.
  final Map<String, List<String>> localWords;
  final List<String> deviceCategories;

  _MetadataDocument copyWith({
    List<ExerciseImageMetadata>? records,
    Map<String, List<String>>? localWords,
    List<String>? deviceCategories,
  }) => _MetadataDocument(
    records: records ?? this.records,
    localWords: localWords ?? this.localWords,
    deviceCategories: deviceCategories ?? this.deviceCategories,
  );
}
