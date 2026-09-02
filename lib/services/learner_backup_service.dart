import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_status_events.dart';
import 'profile_service.dart';
import 'flag_game_score_service.dart';

class LearnerBackupDocument {
  final int schemaVersion;
  final String learnerProfileId;
  final String displayName;
  final Map<String, Object> data;

  const LearnerBackupDocument({
    required this.schemaVersion,
    required this.learnerProfileId,
    required this.displayName,
    required this.data,
  });
}

class LearnerBackupIdentityCollision implements Exception {
  final String learnerProfileId;

  const LearnerBackupIdentityCollision(this.learnerProfileId);

  @override
  String toString() => 'Learner profile ID already exists: $learnerProfileId';
}

class LearnerBackupService {
  static const int schemaVersion = 2;
  static const String format = 'quisquislingo_learner_backup_v2';
  static const int maxBackupBytes = 10 * 1024 * 1024;
  static const String importFileName = 'learner_import.json';

  final ProfileService _profiles;
  final Future<Directory> Function() _documentsDirectoryProvider;

  LearnerBackupService({
    ProfileService? profileService,
    Future<Directory> Function()? documentsDirectoryProvider,
  }) : _profiles = profileService ?? ProfileService(),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  Future<Directory> transferDirectory() async {
    final documents = await _documentsDirectoryProvider();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Exports',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> importFilePath() async {
    final documents = await _documentsDirectoryProvider();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Imports',
    );
    await directory.create(recursive: true);
    return '${directory.path}${Platform.pathSeparator}$importFileName';
  }

  Future<Map<String, dynamic>> exportActiveProfile() async {
    final profile = await _profiles.getActiveProfileRecord();
    if (profile == null) {
      throw StateError('No active learner profile to export');
    }
    final prefs = await SharedPreferences.getInstance();
    final prefix = ProfileService.prefixForProfileId(profile.learnerProfileId);
    final data = <String, dynamic>{};
    for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
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
      'format': format,
      'schemaVersion': schemaVersion,
      'learnerProfileId': profile.learnerProfileId,
      'displayName': profile.displayName,
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

    final profile = await _profiles.getActiveProfileRecord();
    if (profile == null) throw StateError('No active learner profile');
    final profileName = profile.displayName
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

  Future<LearnerBackupDocument> readImportFile() async {
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
    return decodeDocument(await file.readAsBytes());
  }

  LearnerBackupDocument decodeDocument(List<int> bytes) {
    String raw;
    try {
      raw = utf8.decode(bytes);
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
        decoded['format'] != format ||
        decoded['schemaVersion'] != schemaVersion ||
        decoded['learnerProfileId'] is! String ||
        decoded['displayName'] is! String ||
        decoded['data'] is! Map) {
      throw const FormatException(
        'Not a supported QuisquisLingo learner backup.',
      );
    }
    final learnerProfileId = decoded['learnerProfileId'] as String;
    if (!ProfileService.isValidLearnerProfileId(learnerProfileId)) {
      throw const FormatException('Backup learner profile ID is invalid.');
    }
    final displayName = decoded['displayName'] as String;
    try {
      ProfileService.validateDisplayName(displayName);
    } on ArgumentError catch (error) {
      throw FormatException(
        error.message?.toString() ?? 'Invalid learner name',
      );
    }
    final rawData = decoded['data'] as Map;
    if (rawData.length > 5000) {
      throw const FormatException(
        'Learner backup contains too many data entries.',
      );
    }
    final data = <String, Object>{};
    for (final entry in rawData.entries) {
      final suffix = entry.key.toString();
      if (suffix.isEmpty ||
          suffix.length > 160 ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(suffix)) {
        continue;
      }
      final value = entry.value;
      if (value is String || value is bool || value is int || value is double) {
        data[suffix] = value;
      } else if (value is List && value.every((element) => element is String)) {
        data[suffix] = value.cast<String>();
      }
    }
    return LearnerBackupDocument(
      schemaVersion: schemaVersion,
      learnerProfileId: learnerProfileId,
      displayName: displayName.trim(),
      data: data,
    );
  }

  Future<bool> profileExists(String learnerProfileId) async =>
      await _profiles.getProfileById(learnerProfileId) != null;

  Future<LearnerProfile> restorePreservingIdentity(
    LearnerBackupDocument document, {
    bool replaceExisting = false,
  }) async {
    final existing = await _profiles.getProfileById(document.learnerProfileId);
    if (existing != null && !replaceExisting) {
      throw LearnerBackupIdentityCollision(document.learnerProfileId);
    }
    if (existing != null) {
      await _removeNamespace(document.learnerProfileId);
    }
    final profile = LearnerProfile(
      learnerProfileId: document.learnerProfileId,
      displayName: ProfileService.validateDisplayName(document.displayName),
    );
    await _profiles.replaceProfileRecord(profile);
    await _writeNamespace(profile.learnerProfileId, document.data);
    await _profiles.setActiveProfileById(profile.learnerProfileId);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
    return profile;
  }

  Future<LearnerProfile> importAsSeparateCopy(
    LearnerBackupDocument document, {
    required String displayName,
  }) async {
    final profile = await _profiles.createProfile(
      ProfileService.validateDisplayName(displayName),
    );
    await _writeNamespace(
      profile.learnerProfileId,
      document.data,
      rewriteImportedProfileId: true,
    );
    await _profiles.setActiveProfileById(profile.learnerProfileId);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
    return profile;
  }

  Future<void> _removeNamespace(String learnerProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = ProfileService.prefixForProfileId(learnerProfileId);
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(prefix)).toList()) {
      await prefs.remove(key);
    }
  }

  Future<void> _writeNamespace(
    String learnerProfileId,
    Map<String, Object> data, {
    bool rewriteImportedProfileId = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = ProfileService.prefixForProfileId(learnerProfileId);
    for (final entry in data.entries) {
      final key = '$prefix${entry.key}';
      final value =
          rewriteImportedProfileId &&
              entry.key.startsWith(FlagGameScoreService.keyPrefix) &&
              entry.value is String
          ? _rewriteFlagGameRecord(entry.value as String, learnerProfileId)
          : entry.value;
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }
  }

  String _rewriteFlagGameRecord(String raw, String learnerProfileId) {
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return raw;
      final copy = Map<String, dynamic>.from(value);
      copy['learnerProfileId'] = learnerProfileId;
      return jsonEncode(copy);
    } catch (_) {
      return raw;
    }
  }
}
