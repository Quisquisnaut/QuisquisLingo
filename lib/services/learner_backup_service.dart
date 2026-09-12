import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learner_status_events.dart';
import 'profile_service.dart';
import 'flag_game_score_service.dart';

typedef LearnerBackupPreferenceWriter =
    Future<bool> Function(
      SharedPreferences preferences,
      String key,
      Object value,
    );

class LearnerBackupDocument {
  final int schemaVersion;
  final String learnerProfileId;
  final String displayName;
  final String? discordHandle;
  final String? screenNameSuffix;
  final Map<String, Object> data;

  const LearnerBackupDocument({
    required this.schemaVersion,
    required this.learnerProfileId,
    required this.displayName,
    this.discordHandle,
    this.screenNameSuffix,
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
  final LearnerBackupPreferenceWriter? _preferenceWriter;

  LearnerBackupService({
    ProfileService? profileService,
    Future<Directory> Function()? documentsDirectoryProvider,
    LearnerBackupPreferenceWriter? preferenceWriter,
  }) : _profiles = profileService ?? ProfileService(),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _preferenceWriter = preferenceWriter;

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
      final suffix = key.substring(prefix.length);
      if (ProfileService.isSensitiveCredentialPreferenceSuffix(suffix)) {
        continue;
      }
      final value = prefs.get(key);
      if (value is String ||
          value is bool ||
          value is int ||
          value is double ||
          value is List<String>) {
        data[suffix] = value;
      }
    }
    return {
      'format': format,
      'schemaVersion': schemaVersion,
      'learnerProfileId': profile.learnerProfileId,
      'displayName': profile.displayName,
      if (profile.discordHandle != null) 'discordHandle': profile.discordHandle,
      if (profile.screenNameSuffix != null)
        'screenNameSuffix': profile.screenNameSuffix,
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
        (decoded['discordHandle'] != null &&
            decoded['discordHandle'] is! String) ||
        (decoded['screenNameSuffix'] != null &&
            decoded['screenNameSuffix'] is! String) ||
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
    final screenNameSuffix = decoded['screenNameSuffix'] as String?;
    String? discordHandle;
    try {
      ProfileService.validateDisplayName(displayName);
      if (screenNameSuffix != null &&
          (!RegExp(r'^\d{5}$').hasMatch(screenNameSuffix) ||
              !displayName.endsWith(' $screenNameSuffix'))) {
        throw const FormatException('Invalid Screen Name suffix.');
      }
      discordHandle = ProfileService.normalizeDiscordHandle(
        decoded['discordHandle'] as String?,
      );
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
        throw FormatException(
          'Learner backup contains an invalid data key: $suffix',
        );
      }
      final value = entry.value;
      if (value is String || value is bool || value is int || value is double) {
        data[suffix] = value;
      } else if (value is List && value.every((element) => element is String)) {
        data[suffix] = value.cast<String>();
      } else {
        throw FormatException(
          'Learner backup contains an unsupported value for $suffix.',
        );
      }
    }
    return LearnerBackupDocument(
      schemaVersion: schemaVersion,
      learnerProfileId: learnerProfileId,
      displayName: displayName.trim(),
      discordHandle: discordHandle,
      screenNameSuffix: screenNameSuffix,
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
    final profile = LearnerProfile(
      learnerProfileId: document.learnerProfileId,
      displayName: ProfileService.validateDisplayName(document.displayName),
      discordHandle: document.discordHandle,
      screenNameSuffix: document.screenNameSuffix,
    );
    final preferences = await SharedPreferences.getInstance();
    final snapshot = _snapshot(preferences, profile.learnerProfileId);
    try {
      await _upsertProfile(preferences, profile);
      await _replaceNamespace(
        preferences,
        profile.learnerProfileId,
        document.data,
      );
      await _writeVerified(
        preferences,
        ProfileService.activeProfileIdKey,
        profile.learnerProfileId,
      );
      LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
      return profile;
    } catch (error, stackTrace) {
      await _rollbackOrThrow(
        preferences,
        profile.learnerProfileId,
        snapshot,
        error,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<LearnerProfile> importAsSeparateCopy(
    LearnerBackupDocument document, {
    required String displayName,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final profilesBefore = preferences.getStringList(
      ProfileService.profilesKey,
    );
    final activeBefore = preferences.getString(
      ProfileService.activeProfileIdKey,
    );
    LearnerProfile? profile;
    try {
      profile = await _profiles.createProfile(
        ProfileService.validateDisplayName(displayName),
        discordHandle: document.discordHandle,
      );
      final created = await _profiles.getProfileById(profile.learnerProfileId);
      if (created?.displayName != profile.displayName ||
          await _profiles.getActiveProfileId() != profile.learnerProfileId) {
        throw StateError('Learner profile creation could not be verified.');
      }
      await _writeNamespace(
        preferences,
        profile.learnerProfileId,
        document.data,
        rewriteImportedProfileId: true,
      );
      LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
      return profile;
    } catch (error, stackTrace) {
      try {
        if (profile != null) {
          await _removeNamespace(preferences, profile.learnerProfileId);
        }
        await _restoreOptionalStringList(
          preferences,
          ProfileService.profilesKey,
          profilesBefore,
        );
        await _restoreOptionalString(
          preferences,
          ProfileService.activeProfileIdKey,
          activeBefore,
        );
        LearnerStatusEvents.publish(LearnerStatusInvalidation.activeProfile);
      } catch (rollbackError) {
        throw StateError(
          'Learner backup import failed and its partial changes could not be rolled back. '
          'Original error: $error. Rollback error: $rollbackError',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _upsertProfile(
    SharedPreferences preferences,
    LearnerProfile replacement,
  ) async {
    final profiles = await _profiles.getProfileRecords();
    final index = profiles.indexWhere(
      (profile) => profile.learnerProfileId == replacement.learnerProfileId,
    );
    final updated = [...profiles];
    if (index < 0) {
      updated.add(replacement);
    } else {
      updated[index] = replacement;
    }
    await _writeVerified(
      preferences,
      ProfileService.profilesKey,
      updated.map((profile) => profile.encode()).toList(),
    );
  }

  Future<void> _removeNamespace(
    SharedPreferences prefs,
    String learnerProfileId,
  ) async {
    final prefix = ProfileService.prefixForProfileId(learnerProfileId);
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(prefix)).toList()) {
      if (!await prefs.remove(key) || prefs.containsKey(key)) {
        throw StateError('Verified learner-data removal failed for $key.');
      }
    }
  }

  Future<void> _replaceNamespace(
    SharedPreferences preferences,
    String learnerProfileId,
    Map<String, Object> data,
  ) async {
    await _removeNamespace(preferences, learnerProfileId);
    await _writeNamespace(preferences, learnerProfileId, data);
  }

  Future<void> _writeNamespace(
    SharedPreferences prefs,
    String learnerProfileId,
    Map<String, Object> data, {
    bool rewriteImportedProfileId = false,
  }) async {
    final prefix = ProfileService.prefixForProfileId(learnerProfileId);
    for (final entry in data.entries) {
      if (ProfileService.isSensitiveCredentialPreferenceSuffix(entry.key)) {
        continue;
      }
      final key = '$prefix${entry.key}';
      final value =
          rewriteImportedProfileId &&
              entry.key.startsWith(FlagGameScoreService.keyPrefix) &&
              entry.value is String
          ? _rewriteFlagGameRecord(entry.value as String, learnerProfileId)
          : entry.value;
      await _writeVerified(prefs, key, value);
    }
  }

  _LearnerRestoreSnapshot _snapshot(
    SharedPreferences preferences,
    String learnerProfileId,
  ) {
    final prefix = ProfileService.prefixForProfileId(learnerProfileId);
    final namespace = <String, Object>{};
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(prefix),
    )) {
      final value = preferences.get(key);
      if (value is List<String>) {
        namespace[key] = List<String>.from(value);
      } else if (value is String ||
          value is bool ||
          value is int ||
          value is double) {
        namespace[key] = value!;
      }
    }
    return _LearnerRestoreSnapshot(
      profiles: preferences.getStringList(ProfileService.profilesKey),
      activeProfileId: preferences.getString(ProfileService.activeProfileIdKey),
      namespace: namespace,
    );
  }

  Future<void> _rollbackOrThrow(
    SharedPreferences preferences,
    String learnerProfileId,
    _LearnerRestoreSnapshot snapshot,
    Object originalError,
  ) async {
    try {
      await _removeNamespace(preferences, learnerProfileId);
      for (final entry in snapshot.namespace.entries) {
        await _writeDirectVerified(preferences, entry.key, entry.value);
      }
      await _restoreOptionalStringList(
        preferences,
        ProfileService.profilesKey,
        snapshot.profiles,
      );
      await _restoreOptionalString(
        preferences,
        ProfileService.activeProfileIdKey,
        snapshot.activeProfileId,
      );
    } catch (rollbackError) {
      throw StateError(
        'Learner backup restore failed and the previous learner data could not be rolled back. '
        'Original error: $originalError. Rollback error: $rollbackError',
      );
    }
  }

  Future<void> _restoreOptionalStringList(
    SharedPreferences preferences,
    String key,
    List<String>? value,
  ) async {
    if (value == null) {
      if (!await preferences.remove(key) || preferences.containsKey(key)) {
        throw StateError('Verified preference rollback failed for $key.');
      }
      return;
    }
    await _writeDirectVerified(preferences, key, value);
  }

  Future<void> _restoreOptionalString(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    if (value == null) {
      if (!await preferences.remove(key) || preferences.containsKey(key)) {
        throw StateError('Verified preference rollback failed for $key.');
      }
      return;
    }
    await _writeDirectVerified(preferences, key, value);
  }

  Future<void> _writeVerified(
    SharedPreferences preferences,
    String key,
    Object value,
  ) async {
    final writer = _preferenceWriter;
    final saved = writer == null
        ? await _setPreference(preferences, key, value)
        : await writer(preferences, key, value);
    if (!saved || !_samePreferenceValue(preferences.get(key), value)) {
      throw StateError('Verified learner-data write failed for $key.');
    }
  }

  Future<void> _writeDirectVerified(
    SharedPreferences preferences,
    String key,
    Object value,
  ) async {
    if (!await _setPreference(preferences, key, value) ||
        !_samePreferenceValue(preferences.get(key), value)) {
      throw StateError('Verified preference rollback failed for $key.');
    }
  }

  static Future<bool> _setPreference(
    SharedPreferences preferences,
    String key,
    Object value,
  ) {
    if (value is String) return preferences.setString(key, value);
    if (value is bool) return preferences.setBool(key, value);
    if (value is int) return preferences.setInt(key, value);
    if (value is double) return preferences.setDouble(key, value);
    if (value is List<String>) return preferences.setStringList(key, value);
    throw ArgumentError.value(value, 'value', 'Unsupported preference value');
  }

  static bool _samePreferenceValue(Object? actual, Object expected) {
    if (actual is List<String> && expected is List<String>) {
      if (actual.length != expected.length) return false;
      for (var index = 0; index < actual.length; index++) {
        if (actual[index] != expected[index]) return false;
      }
      return true;
    }
    return actual == expected;
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

class _LearnerRestoreSnapshot {
  final List<String>? profiles;
  final String? activeProfileId;
  final Map<String, Object> namespace;

  const _LearnerRestoreSnapshot({
    required this.profiles,
    required this.activeProfileId,
    required this.namespace,
  });
}
