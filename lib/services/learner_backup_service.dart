import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';
import 'learner_status_events.dart';

class LearnerBackupService {
  static const int maxBackupBytes = 10 * 1024 * 1024;
  static const String importFileName = 'learner_import.json';

  final ProfileService _profiles = ProfileService();

  Future<Directory> transferDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Exports',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> importFilePath() async {
    final directory = await transferDirectory();
    return '${directory.path}${Platform.pathSeparator}$importFileName';
  }

  Future<Map<String, dynamic>> exportActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = await _profiles.getActiveProfile() ?? 'default';
    final prefix = 'learner_${Uri.encodeComponent(name)}_';
    final data = <String, dynamic>{};
    for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      final value = prefs.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        data[key.substring(prefix.length)] = value;
      }
    }
    return {
      'format': 'quisquislingo_learner_backup_v1',
      'profile': name,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    };
  }

  Future<String> saveActiveProfile() async {
    final payload = const JsonEncoder.withIndent(
      '  ',
    ).convert(await exportActiveProfile());
    final bytes = utf8.encode(payload);
    if (bytes.length > maxBackupBytes) {
      throw const FormatException(
        'Learner backup exceeds the 10 MB export safety limit.',
      );
    }

    final profileName = (await _profiles.getActiveProfile() ?? 'learner')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        .toLowerCase();
    final directory = await transferDirectory();
    final baseName = 'quisquislingo_${profileName}_backup';
    var path = '${directory.path}${Platform.pathSeparator}$baseName.json';
    var suffix = 2;
    while (await File(path).exists()) {
      path =
          '${directory.path}${Platform.pathSeparator}${baseName}_$suffix.json';
      suffix++;
    }
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  Future<String?> importProfile() async {
    final path = await importFilePath();
    final file = File(path);
    if (!await file.exists()) {
      throw FormatException(
        'No $importFileName found. Copy the learner backup to $path, then press Import my data again.',
      );
    }
    if (await file.length() > maxBackupBytes) {
      throw const FormatException(
        'Learner backup is larger than the 10 MB safety limit.',
      );
    }

    String raw;
    try {
      raw = utf8.decode(await file.readAsBytes());
    } catch (_) {
      throw const FormatException(
        'learner_import.json must be valid UTF-8 text.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('learner_import.json is not valid JSON.');
    }
    if (decoded is! Map ||
        decoded['format'] != 'quisquislingo_learner_backup_v1' ||
        decoded['profile'] is! String ||
        decoded['data'] is! Map) {
      throw const FormatException(
        'Not a supported QuisquisLingo learner backup.',
      );
    }
    final name = (decoded['profile'] as String).trim();
    if (name.isEmpty) {
      throw const FormatException('Backup profile name is empty.');
    }
    if (name.length > 60) {
      throw const FormatException(
        'Backup profile name exceeds the 60-character limit.',
      );
    }
    final data = decoded['data'] as Map;
    if (data.length > 5000) {
      throw const FormatException(
        'Learner backup contains too many data entries.',
      );
    }
    await _profiles.addProfile(name);
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'learner_${Uri.encodeComponent(name)}_';
    for (final entry in data.entries) {
      final suffix = entry.key.toString();
      if (suffix.isEmpty ||
          suffix.length > 160 ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(suffix)) {
        continue;
      }
      final key = '$prefix$suffix';
      final v = entry.value;
      if (v is String) {
        await prefs.setString(key, v);
      } else if (v is bool) {
        await prefs.setBool(key, v);
      } else if (v is int) {
        await prefs.setInt(key, v);
      } else if (v is double) {
        await prefs.setDouble(key, v);
      } else if (v is List && v.every((e) => e is String)) {
        await prefs.setStringList(key, v.cast<String>());
      }
    }
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
    return name;
  }
}
