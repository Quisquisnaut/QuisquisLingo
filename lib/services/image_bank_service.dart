import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_image_metadata.dart';
import 'exercise_image_metadata_service.dart';
import 'exercise_image_service.dart';
import 'file_dialog_service.dart';
import 'import/bounded_zip_reader.dart';
import 'import/image_validator.dart';
import 'import/json_limits.dart';

class ImportedImageBank {
  final String id;
  final String path;
  final String name;
  const ImportedImageBank({
    required this.id,
    required this.path,
    required this.name,
  });

  Map<String, dynamic> toJson() => {'id': id, 'path': path, 'name': name};
  factory ImportedImageBank.fromJson(Map<String, dynamic> json) =>
      ImportedImageBank(
        id: json['id'] as String,
        path: json['path'] as String,
        name: json['name'] as String,
      );
}

class ImageBankImportResult {
  final String bankName;
  final int imported;
  final List<String> warnings;
  final List<ExerciseImageMetadata> records;
  const ImageBankImportResult({
    required this.bankName,
    required this.imported,
    required this.warnings,
    required this.records,
  });
}

/// One image of an Image Bank, checked and held in memory.
class BankImage {
  const BankImage({
    required this.id,
    required this.label,
    required this.category,
    required this.tags,
    required this.filename,
    required this.bytes,
    this.attribution,
  });

  final String id;
  final String label;
  final String category;
  final List<String> tags;
  final String filename;
  final Uint8List bytes;
  final ImageAttribution? attribution;

  BankImage withCategory(String value) => BankImage(
    id: id,
    label: label,
    category: value,
    tags: tags,
    filename: filename,
    bytes: bytes,
    attribution: attribution,
  );
}

/// What the Admin decided about categories a bank adds.
enum NewCategoryChoice { add, useOther, cancel }

/// An Image Bank that passed every check. Nothing has been written.
class ParsedImageBank {
  const ParsedImageBank({
    required this.name,
    required this.warnings,
    required this.images,
  });

  final String name;
  final List<String> warnings;
  final List<BankImage> images;
}

class ImageBankService {
  static const int maxImageBytes = 50 * 1024;
  static const int maxZipBytes = 50 * 1024 * 1024;
  static const int maxManifestBytes = 2 * 1024 * 1024;
  static const int maxArchiveEntries = 5000;
  static const int maxImportedImages = 2500;
  static const int maxTotalImageBytes = 50 * 1024 * 1024;

  /// Every entry's inflated bytes together, referenced or not.
  static const int maxInflatedArchiveBytes = 50 * 1024 * 1024;
  static const banksKey = 'quisquislingo_imported_image_banks_v2';

  ImageBankService({
    FileDialogService? fileDialogs,
    Future<Directory> Function()? temporaryDirectory,
  }) : _fileDialogs = fileDialogs ?? FileDialogService(),
       _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  final FileDialogService _fileDialogs;
  final Future<Directory> Function() _temporaryDirectory;

  /// False when the system dialog is unsupported; hide Open from….
  bool get fileDialogsAvailable => _fileDialogs.isAvailable;

  /// Open from…: pick one Image Bank ZIP in the system dialog. The picked
  /// bytes are staged as a temporary file (keeping the ZIP's own name, which
  /// names the bank) and go through the ordinary [importBankZip]; the temporary
  /// copy is always deleted. The result is null when the user cancelled or the
  /// dialog failed; see the dialog result.
  Future<({FileDialogResult dialog, ImageBankImportResult? result})>
  importBankZipFromDialog({Set<String> existingIds = const {}}) async {
    ImageBankImportResult? result;
    final dialog = await _withDialogZip((file) async {
      result = await importBankZip(file, existingIds: existingIds);
    });
    return (dialog: dialog, result: result);
  }

  /// Picks a ZIP in the system dialog and hands it to [body] as a temporary
  /// file that keeps the ZIP's own name (which names the bank); the copy is
  /// always deleted.
  Future<FileDialogResult> _withDialogZip(
    Future<void> Function(File zip) body,
  ) async {
    final picked = await _fileDialogs.openBytes(
      extensions: const ['zip'],
      maxBytes: maxZipBytes,
      artifact: 'image-bank',
    );
    if (picked.outcome == FileDialogOutcome.tooLarge) {
      throw const FormatException(
        'Image Bank ZIP exceeds the 50 MB safety limit.',
      );
    }
    if (picked.outcome != FileDialogOutcome.opened) return picked;
    final staging = await (await _temporaryDirectory()).createTemp(
      'qql_image_bank_',
    );
    try {
      final name = picked.displayName!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${staging.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(picked.bytes!, flush: true);
      await body(file);
      return picked;
    } finally {
      try {
        await staging.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<List<ImportedImageBank>> banks() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <ImportedImageBank>[];
    for (final raw in prefs.getStringList(banksKey) ?? const []) {
      try {
        final item = ImportedImageBank.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
        if (await Directory(item.path).exists()) out.add(item);
      } catch (_) {}
    }
    return out;
  }

  /// Image Banks and single images share one fixed import folder; the folder
  /// is defined once, by [ExerciseImageService.fixedImportDirectory].
  Future<Directory> fixedImportDirectory() =>
      ExerciseImageService().fixedImportDirectory();

  /// The one Image Bank ZIP in the fixed import folder, read and checked
  /// without writing anything (a Course's own library imports from this).
  Future<ParsedImageBank> readBankFromFolder({
    Set<String> existingIds = const {},
  }) async => readBank(await _folderZip(), existingIds: existingIds);

  /// Open from…: an Image Bank ZIP read and checked without writing anything.
  Future<({FileDialogResult dialog, ParsedImageBank? bank})>
  readBankFromDialog({Set<String> existingIds = const {}}) async {
    ParsedImageBank? bank;
    final dialog = await _withDialogZip((file) async {
      bank = await readBank(file, existingIds: existingIds);
    });
    return (dialog: dialog, bank: bank);
  }

  Future<File> _folderZip() async {
    final importDir = await fixedImportDirectory();
    final zipFiles = await importDir
        .list(followLinks: false)
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => file.path.toLowerCase().endsWith('.zip'))
        .toList();
    zipFiles.sort(
      (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
    );
    if (zipFiles.isEmpty) {
      throw StateError(
        'No Image Bank ZIP found in ${importDir.path}. Copy one ZIP there and try again.',
      );
    }
    if (zipFiles.length > 1) {
      throw StateError(
        'More than one ZIP was found in ${importDir.path}. Keep only the Image Bank ZIP you want to import, then try again.',
      );
    }
    return zipFiles.single;
  }

  /// Reads and checks an Image Bank ZIP without writing anything. The ZIP
  /// goes through [BoundedZipReader]; it may hold only
  /// `image_bank_manifest.json` and the images the manifest lists (in any
  /// folder), each image passing the image check. Both the Shared Image
  /// Library and a Course's own library import from this.
  ///
  /// The manifest is either a list of entries or an object with `images`
  /// (that list), an optional bank-wide `attribution` used by every entry
  /// without its own, and an optional display `name`.
  Future<ParsedImageBank> readBank(
    File zipFile, {
    Set<String> existingIds = const {},
  }) async {
    if (await zipFile.length() > maxZipBytes) {
      throw const FormatException(
        'Image Bank ZIP exceeds the 50 MB safety limit.',
      );
    }
    final zip = BoundedZipReader.open(
      InputMemoryStream(await zipFile.readAsBytes()),
      label: 'Image Bank ZIP',
      maxEntries: maxArchiveEntries,
      maxTotalBytes: maxInflatedArchiveBytes,
    );
    final byBasename = <String, BoundedZipEntry>{};
    for (final entry in zip.entries) {
      final key = entry.baseName.toLowerCase();
      if (byBasename.containsKey(key)) {
        throw FormatException(
          'Image Bank ZIP contains duplicate filenames: ${entry.baseName}',
        );
      }
      byBasename[key] = entry;
    }
    final manifestFile = byBasename[manifestName];
    if (manifestFile == null) {
      throw const FormatException(
        'Image Bank ZIP has no image_bank_manifest.json.',
      );
    }
    if (manifestFile.size > maxManifestBytes) {
      throw const FormatException(
        'Image Bank manifest exceeds the 2 MB safety limit.',
      );
    }
    final String manifestText;
    try {
      manifestText = utf8.decode(zip.read(manifestFile));
    } on FormatException catch (error) {
      if (error.message.contains('Image Bank ZIP')) rethrow;
      throw const FormatException('Image Bank manifest is not UTF-8 text.');
    }
    final decoded = JsonLimits.imports.decode(
      manifestText,
      what: 'The Image Bank manifest',
      invalidMessage: 'Image Bank manifest is not valid JSON.',
    );
    final List<Object?> list;
    ImageAttribution? bankAttribution;
    String? manifestNameField;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map) {
      if (decoded.keys.any(
            (key) => key != 'images' && key != 'attribution' && key != 'name',
          ) ||
          decoded['images'] is! List) {
        throw const FormatException(
          'An Image Bank manifest object has "images" (a list) and '
          'optionally "attribution" and "name", nothing else.',
        );
      }
      list = decoded['images'] as List;
      if (decoded.containsKey('attribution')) {
        bankAttribution = _attribution(
          decoded['attribution'],
          'Invalid default attribution in the Image Bank manifest.',
        );
      }
      if (decoded.containsKey('name')) {
        manifestNameField = _text(
          decoded['name'],
          'Image Bank name',
          maxDisplayNameLength,
        );
      }
    } else {
      throw const FormatException(
        'Image Bank manifest must contain a JSON list.',
      );
    }
    if (list.length > maxImportedImages) {
      throw const FormatException(
        'Image Bank manifest contains too many images.',
      );
    }

    final ids = <String>{};
    final filenames = <String>{};
    final parsed =
        <
          ({
            String id,
            String label,
            String category,
            List<String> tags,
            String filename,
            ImageAttribution? attribution,
          })
        >[];
    for (final raw in list) {
      if (raw is! Map) {
        throw const FormatException(
          'Image Bank manifest contains a non-object entry.',
        );
      }
      final item = Map<String, dynamic>.from(raw);
      final id = (item['id'] ?? '').toString().trim();
      final filename = (item['filename'] ?? '').toString().trim();
      final rawLabel = item['primary_term'] ?? item['label'] ?? '';
      if (id.isEmpty ||
          filename.isEmpty ||
          rawLabel.toString().trim().isEmpty) {
        throw const FormatException(
          'Each Image Bank entry needs id, primary_term/label and filename.',
        );
      }
      if (!idPattern.hasMatch(id)) {
        throw FormatException(
          'Image Bank ID must be 1–128 letters, digits, dots, hyphens or '
          'underscores: $id',
        );
      }
      if (filename.contains('/') ||
          filename.contains('\\') ||
          filename == '.' ||
          filename == '..' ||
          !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(filename)) {
        throw FormatException('Unsafe Image Bank filename: $filename');
      }
      if (!ids.add(id)) throw FormatException('Duplicate Image Bank ID: $id');
      if (existingIds.contains(id)) {
        throw FormatException('Image Bank ID already exists in the app: $id');
      }
      if (!filenames.add(filename.toLowerCase())) {
        throw FormatException(
          'Two Image Bank entries use the same file: $filename',
        );
      }
      final label = _text(rawLabel, 'Image Bank label for $id', maxLabelLength);
      final rawTags = item['keywords'] ?? item['tags'];
      if (rawTags != null && rawTags is! List) {
        throw FormatException('Image Bank tags for $id must be a list.');
      }
      final tags = [
        for (final tag in (rawTags as List?) ?? const [])
          _text(tag, 'Image Bank tag for $id', maxTagLength),
      ];
      if (tags.length > maxTags) {
        throw FormatException(
          'Image Bank entry $id has more than $maxTags tags.',
        );
      }
      final category = normalizeCategory(item['category']);
      parsed.add((
        id: id,
        label: label,
        category: category,
        tags: tags,
        filename: filename,
        attribution: item.containsKey('attribution')
            ? _attribution(
                item['attribution'],
                'Invalid Image Bank attribution for $id.',
              )
            : bankAttribution,
      ));
    }

    // Only the manifest and the images it lists may be in the ZIP.
    for (final entry in zip.entries) {
      final key = entry.baseName.toLowerCase();
      if (key != manifestName && !filenames.contains(key)) {
        throw FormatException(
          'Image Bank ZIP contains a file the manifest does not list: '
          '${entry.name}. An Image Bank may hold only '
          'image_bank_manifest.json and its images; put credits in the '
          'manifest\'s "attribution" field.',
        );
      }
    }
    // Cheap pre-flight on declared sizes; the real limits are enforced on
    // the inflated bytes below.
    var declaredImageBytes = 0;
    for (final item in parsed) {
      final source = byBasename[item.filename.toLowerCase()];
      if (source == null) {
        throw FormatException(
          'Image asset is missing from ZIP: ${item.filename}',
        );
      }
      final ext = item.filename.toLowerCase().split('.').last;
      if (!const {'png', 'jpg', 'jpeg', 'webp'}.contains(ext)) {
        throw FormatException(
          'Unsupported Image Bank file format: ${item.filename}',
        );
      }
      if (source.size > maxImageBytes) {
        throw FormatException(
          'Image asset exceeds the 50 KB maximum: ${item.filename} '
          '(${source.size} bytes)',
        );
      }
      declaredImageBytes += source.size;
      if (declaredImageBytes > maxTotalImageBytes) {
        throw const FormatException(
          'Image Bank decompressed image data exceeds the 50 MB safety limit.',
        );
      }
    }

    final images = <BankImage>[];
    var inflatedImageBytes = 0;
    for (final item in parsed) {
      final sourceBytes = zip.read(
        byBasename[item.filename.toLowerCase()]!,
        limit: maxImageBytes,
      );
      try {
        ImageValidator.inspect(sourceBytes, ImageProfile.exerciseImage);
      } on ImageValidationException catch (error) {
        throw FormatException(
          'Image Bank image ${item.filename}: ${error.message}',
        );
      }
      inflatedImageBytes += sourceBytes.length;
      if (inflatedImageBytes > maxTotalImageBytes) {
        throw const FormatException(
          'Image Bank decompressed image data exceeds the 50 MB safety limit.',
        );
      }
      images.add(
        BankImage(
          id: item.id,
          label: item.label,
          category: item.category,
          tags: item.tags,
          filename: item.filename,
          bytes: sourceBytes,
          attribution: item.attribution,
        ),
      );
    }
    final fileName = zipFile.uri.pathSegments.last.replaceFirst(
      RegExp(r'\.zip$', caseSensitive: false),
      '',
    );
    return ParsedImageBank(
      name:
          manifestNameField ??
          (fileName.length > maxDisplayNameLength
              ? fileName.substring(0, maxDisplayNameLength)
              : fileName),
      warnings: const [],
      images: images,
    );
  }

  static const manifestName = 'image_bank_manifest.json';
  static final idPattern = RegExp(r'^[A-Za-z0-9._-]{1,128}$');
  static const maxLabelLength = 200;
  static const maxTags = 32;
  static const maxTagLength = 80;
  static const maxDisplayNameLength = 120;

  /// At most this many categories the device does not know yet, per bank.
  static const maxNewCategoriesPerBank = 16;

  /// A bank's category: `food`/`home` keep their usual meaning, a missing
  /// one is `other`, and anything else must be a valid category name.
  static String normalizeCategory(Object? raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return 'other';
    final mapped = switch (value) {
      'food' => 'food_drinks',
      'home' => 'home_household',
      _ => value,
    };
    if (!ExerciseImageMetadataService.categories.contains(mapped) &&
        !ExerciseImageMetadataService.deviceCategoryPattern.hasMatch(mapped)) {
      throw FormatException(
        'Image Bank category "$value" is not a valid name: use 2–40 '
        'lowercase letters, digits or underscores, starting with a letter.',
      );
    }
    return mapped;
  }

  static String _text(Object? raw, String what, int maxLength) {
    if (raw is! String && raw is! num) {
      throw FormatException('$what must be text.');
    }
    final value = raw.toString().trim();
    if (value.isEmpty || value.length > maxLength) {
      throw FormatException('$what must be 1–$maxLength characters.');
    }
    if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
      throw FormatException('$what contains control characters.');
    }
    return value;
  }

  static ImageAttribution _attribution(Object? raw, String message) {
    if (raw is! Map) throw FormatException(message);
    try {
      return ImageAttribution.fromJson(Map<String, dynamic>.from(raw));
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException(message);
    }
  }

  /// Imports an Image Bank into the Shared Image Library: [readBank], then
  /// the bank's own folder, manifest and records.
  Future<ImageBankImportResult> importBankZip(
    File zipFile, {
    Set<String> existingIds = const {},
  }) async => _install(await readBank(zipFile, existingIds: existingIds));

  /// Adds a checked [bank] to the Shared Image Library (Admin only).
  ///
  /// Categories this device does not know yet (at most
  /// [maxNewCategoriesPerBank], within the device's
  /// [ExerciseImageMetadataService.maxDeviceCategories]) are shown to the
  /// Admin through [chooseNewCategories] before anything is written: add
  /// them, put those images under `other`, or cancel (the result is then
  /// null). The bank's folder, images, records and new categories are
  /// written only after that; a failure removes all of them again.
  Future<ImageBankImportResult?> importToSharedLibrary(
    ParsedImageBank bank, {
    required ExerciseImageMetadataService metadata,
    required String actorProfileId,
    required Future<NewCategoryChoice> Function(List<String> names)
    chooseNewCategories,
  }) async {
    await metadata.requireAdmin(actorProfileId);
    // The Shared Image Library needs at least one tag per image.
    for (final image in bank.images) {
      if (image.tags.isEmpty) {
        throw FormatException(
          'Image Bank entry ${image.id} needs at least one keyword for the '
          'Shared Image Library.',
        );
      }
    }
    final known = (await metadata.allCategories()).toSet();
    final newCategories = {
      for (final image in bank.images)
        if (!known.contains(image.category)) image.category,
    }.toList()..sort();
    var images = bank.images;
    if (newCategories.isNotEmpty) {
      if (newCategories.length > maxNewCategoriesPerBank) {
        throw FormatException(
          'This Image Bank adds ${newCategories.length} new categories; at '
          'most $maxNewCategoriesPerBank are allowed per bank.',
        );
      }
      final device = await metadata.deviceCategories();
      if (device.length + newCategories.length >
          ExerciseImageMetadataService.maxDeviceCategories) {
        throw FormatException(
          'This Image Bank adds ${newCategories.length} new categories, but '
          'this device has room for only '
          '${ExerciseImageMetadataService.maxDeviceCategories - device.length} '
          'more.',
        );
      }
      switch (await chooseNewCategories(newCategories)) {
        case NewCategoryChoice.cancel:
          return null;
        case NewCategoryChoice.useOther:
          images = [
            for (final image in images)
              newCategories.contains(image.category)
                  ? image.withCategory('other')
                  : image,
          ];
          newCategories.clear();
        case NewCategoryChoice.add:
          break;
      }
    }
    final added = <String>[];
    ImageBankImportResult? result;
    try {
      for (final name in newCategories) {
        added.add(
          await metadata.addDeviceCategory(
            actorProfileId: actorProfileId,
            name: name,
          ),
        );
      }
      result = await _install(
        ParsedImageBank(
          name: bank.name,
          warnings: bank.warnings,
          images: images,
        ),
      );
      await metadata.addLocalRecords(
        actorProfileId: actorProfileId,
        records: result.records,
      );
      return result;
    } catch (_) {
      if (result != null && result.records.isNotEmpty) {
        final origin = result.records.first.origin;
        if (origin.startsWith('bank:')) {
          try {
            await removeBank(origin.substring('bank:'.length));
          } catch (_) {}
        }
      }
      for (final name in added.reversed) {
        try {
          await metadata.removeDeviceCategory(
            actorProfileId: actorProfileId,
            name: name,
          );
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Writes a checked [bank]: its own folder, images, manifest and entry.
  Future<ImageBankImportResult> _install(ParsedImageBank bank) async {
    final support = await getApplicationSupportDirectory();
    final bankId = 'bank_${DateTime.now().microsecondsSinceEpoch}';
    final dir = Directory(
      '${support.path}${Platform.pathSeparator}image_banks${Platform.pathSeparator}$bankId',
    );
    await dir.create(recursive: true);
    final imagesDir = Directory('${dir.path}${Platform.pathSeparator}images');
    try {
      await imagesDir.create(recursive: true);
      final normalizedManifest = <Map<String, dynamic>>[];
      final records = <ExerciseImageMetadata>[];
      for (final image in bank.images) {
        final target = File(
          '${imagesDir.path}${Platform.pathSeparator}${image.filename}',
        );
        await target.writeAsBytes(image.bytes, flush: true);
        normalizedManifest.add({
          'id': image.id,
          'label': image.label,
          'assetPath': target.path,
          'bankId': bankId,
        });
        records.add(
          ExerciseImageMetadata(
            id: image.id,
            label: image.label,
            category: image.category,
            tags: image.tags,
            assetPath: target.path,
            origin: 'bank:$bankId',
            attribution: image.attribution,
          ),
        );
      }
      await File(
        '${dir.path}${Platform.pathSeparator}manifest.json',
      ).writeAsString(jsonEncode(normalizedManifest), flush: true);

      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(banksKey) ?? <String>[];
      final entry = ImportedImageBank(id: bankId, path: dir.path, name: bank.name);
      await prefs.setStringList(banksKey, [
        ...current,
        jsonEncode(entry.toJson()),
      ]);
      return ImageBankImportResult(
        bankName: bank.name,
        imported: normalizedManifest.length,
        warnings: bank.warnings,
        records: List.unmodifiable(records),
      );
    } catch (_) {
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadImportedEntries() async {
    final out = <Map<String, dynamic>>[];
    for (final bank in await banks()) {
      final manifest = File(
        '${bank.path}${Platform.pathSeparator}manifest.json',
      );
      if (!await manifest.exists()) continue;
      try {
        final decoded = jsonDecode(await manifest.readAsString());
        if (decoded is! List) continue;
        for (final raw in decoded.whereType<Map>()) {
          final item = Map<String, dynamic>.from(raw);
          final path = (item['assetPath'] ?? '').toString();
          if (path.isEmpty || !await File(path).exists()) {
            item['missing'] = true;
          }
          item['bankName'] = bank.name;
          out.add(item);
        }
      } catch (_) {}
    }
    return out;
  }

  Future<Set<String>> removeBank(String bankId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await banks();
    final target = all.where((e) => e.id == bankId).toList();
    final removedIds = <String>{};
    if (target.isNotEmpty) {
      final dir = Directory(target.first.path);
      final manifest = File(
        '${dir.path}${Platform.pathSeparator}manifest.json',
      );
      if (await manifest.exists()) {
        try {
          final decoded = jsonDecode(await manifest.readAsString());
          if (decoded is List) {
            for (final raw in decoded.whereType<Map>()) {
              final id = raw['id']?.toString().trim() ?? '';
              if (id.isNotEmpty) removedIds.add(id);
            }
          }
        } catch (_) {}
      }
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    final kept = all
        .where((e) => e.id != bankId)
        .map((e) => jsonEncode(e.toJson()))
        .toList();
    await prefs.setStringList(banksKey, kept);
    return removedIds;
  }
}
