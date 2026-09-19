import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise_image_metadata.dart';
import 'file_dialog_service.dart';

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

class ImageBankService {
  static const int maxImageBytes = 50 * 1024;
  static const int maxZipBytes = 50 * 1024 * 1024;
  static const int maxManifestBytes = 2 * 1024 * 1024;
  static const int maxArchiveEntries = 5000;
  static const int maxImportedImages = 2500;
  static const int maxTotalImageBytes = 50 * 1024 * 1024;
  static const banksKey = 'quisquislingo_imported_image_banks_v2';

  // Memory guard for Open from…; larger files than maxZipBytes reach the
  // ordinary check in importBankZip and get its standard message.
  static const int _dialogReadCap = 128 * 1024 * 1024;

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
    final picked = await _fileDialogs.openBytes(
      extensions: const ['zip'],
      maxBytes: _dialogReadCap,
      artifact: 'image-bank',
    );
    if (picked.outcome != FileDialogOutcome.opened) {
      return (dialog: picked, result: null);
    }
    final staging = await (await _temporaryDirectory()).createTemp(
      'qql_image_bank_',
    );
    try {
      final name = picked.displayName!.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${staging.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(picked.bytes!, flush: true);
      final result = await importBankZip(file, existingIds: existingIds);
      return (dialog: picked, result: result);
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

  Future<Directory> fixedImportDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Imports${Platform.pathSeparator}Images',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<ImageBankImportResult?> pickAndImportBank({
    Set<String> existingIds = const {},
  }) async {
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
    return importBankZip(zipFiles.single, existingIds: existingIds);
  }

  Future<ImageBankImportResult> importBankZip(
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
    final archive = ZipDecoder().decodeBytes(bytes);
    if (archive.files.length > maxArchiveEntries) {
      throw const FormatException(
        'Image Bank ZIP contains too many archive entries.',
      );
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
    final manifestBytes = manifestFile.readBytes();
    if (manifestBytes == null) {
      throw const FormatException('Image Bank manifest could not be read.');
    }
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
    var totalImageBytes = 0;
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
      totalImageBytes += source.size.toInt();
      if (totalImageBytes > maxTotalImageBytes) {
        throw const FormatException(
          'Image Bank decompressed image data exceeds the 50 MB safety limit.',
        );
      }
      final ext = filename.toLowerCase().split('.').last;
      if (!const {'png', 'jpg', 'jpeg', 'webp'}.contains(ext)) {
        throw FormatException('Unsupported Image Bank file format: $filename');
      }
    }

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
      for (final item in entries) {
        final filename = item['filename'].toString();
        final source = byBasename[filename]!;
        final target = File(
          '${imagesDir.path}${Platform.pathSeparator}$filename',
        );
        final sourceBytes = source.readBytes();
        if (sourceBytes == null) {
          throw FormatException(
            'Image asset could not be read from ZIP: $filename',
          );
        }
        await target.writeAsBytes(sourceBytes, flush: true);
        normalizedManifest.add({
          'id': item['id'],
          'label': item['primary_term'] ?? item['label'],
          'assetPath': target.path,
          'bankId': bankId,
        });
        final tags = item['keywords'] is List
            ? (item['keywords'] as List).map((tag) => tag.toString()).toList()
            : item['tags'] is List
            ? (item['tags'] as List).map((tag) => tag.toString()).toList()
            : <String>[];
        records.add(
          ExerciseImageMetadata(
            id: item['id'].toString(),
            label: (item['primary_term'] ?? item['label']).toString(),
            category: (item['category'] ?? 'other').toString(),
            tags: tags,
            assetPath: target.path,
            origin: 'bank:$bankId',
          ),
        );
      }
      await File(
        '${dir.path}${Platform.pathSeparator}manifest.json',
      ).writeAsString(jsonEncode(normalizedManifest), flush: true);

      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(banksKey) ?? <String>[];
      final name = zipFile.uri.pathSegments.last.replaceFirst(
        RegExp(r'\.zip$', caseSensitive: false),
        '',
      );
      final bank = ImportedImageBank(id: bankId, path: dir.path, name: name);
      await prefs.setStringList(banksKey, [
        ...current,
        jsonEncode(bank.toJson()),
      ]);
      return ImageBankImportResult(
        bankName: name,
        imported: normalizedManifest.length,
        warnings: warnings,
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
