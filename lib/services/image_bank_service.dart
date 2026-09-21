import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_image_metadata.dart';
import 'bounded_archive_entry.dart';
import 'exercise_image_service.dart';
import 'file_dialog_service.dart';
import 'import/image_validator.dart';

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
}

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

  Future<ImageBankImportResult?> pickAndImportBank({
    Set<String> existingIds = const {},
  }) async =>
      importBankZip(await _folderZip(), existingIds: existingIds);

  /// The one Image Bank ZIP in the fixed import folder, read and checked
  /// without writing anything (a Course's own library imports from this).
  Future<ParsedImageBank> readBankFromFolder() async =>
      readBank(await _folderZip());

  /// Open from…: an Image Bank ZIP read and checked without writing anything.
  Future<({FileDialogResult dialog, ParsedImageBank? bank})>
  readBankFromDialog() async {
    ParsedImageBank? bank;
    final dialog = await _withDialogZip((file) async {
      bank = await readBank(file);
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

  /// Reads and checks an Image Bank ZIP without writing anything: the
  /// archive pre-scan, the manifest, and every image's size and structure.
  /// Both the Shared Image Library and a Course's own library import from
  /// this.
  Future<ParsedImageBank> readBank(
    File zipFile, {
    Set<String> existingIds = const {},
  }) async {
    final zipLength = await zipFile.length();
    if (zipLength > maxZipBytes) {
      throw const FormatException(
        'Image Bank ZIP exceeds the 50 MB safety limit.',
      );
    }
    final bytes = await zipFile.readAsBytes();
    // Read the central directory before ZipDecoder: decoding eagerly inflates
    // symlink entries, and entries must be counted and their sizes bounded
    // before anything is expanded. Each entry is later inflated only up to its
    // declared size, so the declared total also bounds the real output.
    final directory = ZipDirectory();
    try {
      directory.read(InputMemoryStream(bytes));
    } catch (_) {
      throw const FormatException('This is not a readable Image Bank ZIP.');
    }
    if (directory.fileHeaders.isEmpty) {
      throw const FormatException('This is not a readable Image Bank ZIP.');
    }
    if (directory.fileHeaders.length > maxArchiveEntries) {
      throw const FormatException(
        'Image Bank ZIP contains too many archive entries.',
      );
    }
    var declaredTotal = 0;
    for (final header in directory.fileHeaders) {
      if (((header.externalFileAttributes >> 16) & 0xf000) == 0xa000) {
        throw FormatException(
          'Image Bank ZIP contains a symbolic link: ${header.filename}',
        );
      }
      final size = header.uncompressedSize;
      declaredTotal += size;
      if (size < 0 || declaredTotal > maxInflatedArchiveBytes) {
        throw const FormatException(
          'Image Bank ZIP expands beyond the 50 MB safety limit.',
        );
      }
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const FormatException('This is not a readable Image Bank ZIP.');
    }
    ArchiveFile? manifestFile;
    for (final file in archive.files) {
      final normalized = file.name.replaceAll('\\', '/');
      if (normalized == 'image_bank_manifest.json' ||
          normalized.endsWith('/image_bank_manifest.json')) {
        manifestFile = file;
        break;
      }
    }
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
    final manifestBytes = readBoundedEntry(
      manifestFile,
      manifestFile.size,
      overflowMessage: 'Image Bank manifest expands beyond its declared size.',
      damagedMessage: 'Image Bank manifest could not be read.',
    );
    final decoded = jsonDecode(utf8.decode(manifestBytes));
    if (decoded is! List) {
      throw const FormatException(
        'Image Bank manifest must contain a JSON list.',
      );
    }
    if (decoded.length > maxImportedImages) {
      throw const FormatException(
        'Image Bank manifest contains too many images.',
      );
    }

    final entries = <Map<String, dynamic>>[];
    final attributions = <String, ImageAttribution>{};
    final ids = <String>{};
    final warnings = <String>[];
    for (final raw in decoded) {
      if (raw is! Map) {
        throw const FormatException(
          'Image Bank manifest contains a non-object entry.',
        );
      }
      final item = Map<String, dynamic>.from(raw);
      final id = (item['id'] ?? '').toString().trim();
      final filename = (item['filename'] ?? '').toString().trim();
      final label = (item['primary_term'] ?? item['label'] ?? '')
          .toString()
          .trim();
      if (id.isEmpty || filename.isEmpty || label.isEmpty) {
        throw const FormatException(
          'Each Image Bank entry needs id, primary_term/label and filename.',
        );
      }
      final normalizedFilename = filename.replaceAll('\\', '/');
      if (normalizedFilename.contains('/') ||
          filename == '.' ||
          filename == '..' ||
          !RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(filename)) {
        throw FormatException('Unsafe Image Bank filename: $filename');
      }
      if (!ids.add(id)) throw FormatException('Duplicate Image Bank ID: $id');
      if (existingIds.contains(id)) {
        throw FormatException('Image Bank ID already exists in the app: $id');
      }
      if (item.containsKey('attribution')) {
        final rawAttribution = item['attribution'];
        if (rawAttribution is! Map) {
          throw FormatException('Invalid Image Bank attribution for $id.');
        }
        try {
          attributions[id] = ImageAttribution.fromJson(
            Map<String, dynamic>.from(rawAttribution),
          );
        } on FormatException {
          rethrow;
        } catch (_) {
          throw FormatException('Invalid Image Bank attribution for $id.');
        }
      }
      entries.add(item);
    }

    final byBasename = <String, ArchiveFile>{};
    for (final file in archive.files.where((f) => f.isFile)) {
      final normalized = file.name.replaceAll('\\', '/');
      if (normalized.startsWith('/') || normalized.split('/').contains('..')) {
        throw FormatException('Unsafe path in Image Bank ZIP: ${file.name}');
      }
      final name = normalized.split('/').last;
      if (name.isEmpty) continue;
      if (byBasename.containsKey(name)) {
        throw FormatException(
          'Image Bank ZIP contains duplicate filenames: $name',
        );
      }
      byBasename[name] = file;
    }
    // Cheap pre-flight against the sizes the archive declares. This rejects an
    // obviously oversized bank before any directory is created, but it is not
    // the authoritative check: `size` comes from the ZIP's own header and an
    // archive is free to understate it. The real limits are enforced against
    // the inflated bytes in the write loop below.
    var declaredImageBytes = 0;
    for (final item in entries) {
      final filename = item['filename'].toString();
      final source = byBasename[filename];
      if (source == null) {
        throw FormatException('Image asset is missing from ZIP: $filename');
      }
      if (source.size > maxImageBytes) {
        throw FormatException(
          'Image asset exceeds the 50 KB maximum: $filename (${source.size} bytes)',
        );
      }
      declaredImageBytes += source.size.toInt();
      if (declaredImageBytes > maxTotalImageBytes) {
        throw const FormatException(
          'Image Bank decompressed image data exceeds the 50 MB safety limit.',
        );
      }
      final ext = filename.toLowerCase().split('.').last;
      if (!const {'png', 'jpg', 'jpeg', 'webp'}.contains(ext)) {
        throw FormatException('Unsupported Image Bank file format: $filename');
      }
    }

    // Authoritative size accounting, measured after inflation. The declared
    // sizes checked above cannot be trusted: a ZIP may claim an entry is
    // 500 bytes and inflate to megabytes, which would otherwise slip past
    // both the per-image and the total limit.
    final images = <BankImage>[];
    var inflatedImageBytes = 0;
    for (final item in entries) {
      final filename = item['filename'].toString();
      final source = byBasename[filename]!;
      final sourceBytes = readBoundedEntry(
        source,
        source.size,
        overflowMessage: 'Image asset expands beyond its declared size: $filename',
        damagedMessage: 'Image asset could not be read from ZIP: $filename',
      );
      try {
        ImageValidator.inspect(sourceBytes, ImageProfile.exerciseImage);
      } on ImageValidationException catch (error) {
        throw FormatException('Image Bank image $filename: ${error.message}');
      }
      if (sourceBytes.length > maxImageBytes) {
        throw FormatException(
          'Image asset exceeds the 50 KB maximum: $filename '
          '(${sourceBytes.length} bytes)',
        );
      }
      inflatedImageBytes += sourceBytes.length;
      if (inflatedImageBytes > maxTotalImageBytes) {
        throw const FormatException(
          'Image Bank decompressed image data exceeds the 50 MB safety limit.',
        );
      }
      final tags = item['keywords'] is List
          ? (item['keywords'] as List).map((tag) => tag.toString()).toList()
          : item['tags'] is List
          ? (item['tags'] as List).map((tag) => tag.toString()).toList()
          : <String>[];
      images.add(
        BankImage(
          id: item['id'].toString(),
          label: (item['primary_term'] ?? item['label']).toString(),
          category: (item['category'] ?? 'other').toString(),
          tags: tags,
          filename: filename,
          bytes: sourceBytes,
          attribution: attributions[item['id'].toString()],
        ),
      );
    }
    return ParsedImageBank(
      name: zipFile.uri.pathSegments.last.replaceFirst(
        RegExp(r'\.zip$', caseSensitive: false),
        '',
      ),
      warnings: warnings,
      images: images,
    );
  }

  /// Imports an Image Bank into the Shared Image Library: [readBank], then
  /// the bank's own folder, manifest and records.
  Future<ImageBankImportResult> importBankZip(
    File zipFile, {
    Set<String> existingIds = const {},
  }) async {
    final bank = await readBank(zipFile, existingIds: existingIds);
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
