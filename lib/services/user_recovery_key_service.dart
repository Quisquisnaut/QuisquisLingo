import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';

class UserRecoveryKeyDocument {
  final String learnerProfileId;
  final String secret;

  const UserRecoveryKeyDocument({
    required this.learnerProfileId,
    required this.secret,
  });
}

class UserRecoveryKeyCandidate {
  final String path;
  final UserRecoveryKeyDocument document;

  const UserRecoveryKeyCandidate({required this.path, required this.document});
}

class UserRecoveryIdentityConflict implements Exception {
  final String learnerProfileId;

  const UserRecoveryIdentityConflict(this.learnerProfileId);

  @override
  String toString() =>
      'This QQL identity already exists on this installation: $learnerProfileId';
}

class UserRecoveryKeyService {
  static const format = 'quisquislingo_user_recovery_key_v1';
  static const schemaVersion = 1;
  static const _maximumKeyBytes = 64 * 1024;

  final ProfileService _profiles;
  final Future<Directory> Function() _exportsDirectoryProvider;
  final Future<Directory> Function() _importsDirectoryProvider;
  final List<int> Function(int length) _secureBytes;

  UserRecoveryKeyService({
    ProfileService? profileService,
    Future<Directory> Function()? exportsDirectoryProvider,
    Future<Directory> Function()? importsDirectoryProvider,
    List<int> Function(int length)? secureBytes,
  }) : _profiles = profileService ?? ProfileService(),
       _exportsDirectoryProvider =
           exportsDirectoryProvider ?? (() => _qqlDirectory('Exports')),
       _importsDirectoryProvider =
           importsDirectoryProvider ?? (() => _qqlDirectory('Imports')),
       _secureBytes =
           secureBytes ??
           ((length) =>
               List<int>.generate(length, (_) => Random.secure().nextInt(256)));

  static Future<Directory> _qqlDirectory(String name) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo'
      '${Platform.pathSeparator}$name',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> exportActiveUserRecoveryKey() async {
    final profile = await _profiles.getActiveProfileRecord();
    if (profile == null) {
      throw StateError('No active learner profile to export.');
    }
    final prefs = await SharedPreferences.getInstance();
    final credentialKey = _profiles.keyForProfileId(
      profile.learnerProfileId,
      ProfileService.recoveryCredentialKeyBase,
    );
    var secret = prefs.getString(credentialKey);
    if (secret == null) {
      secret = base64Url.encode(_secureBytes(32));
      await prefs.setString(credentialKey, secret);
    }
    final payload = const JsonEncoder.withIndent('  ').convert({
      'format': format,
      'schemaVersion': schemaVersion,
      'learnerProfileId': profile.learnerProfileId,
      'secret': secret,
    });
    final directory = await _exportsDirectoryProvider();
    await directory.create(recursive: true);
    final stem = 'quisquislingo_${profile.learnerProfileId}.user-recovery-key';
    var file = File('${directory.path}${Platform.pathSeparator}$stem.json');
    var suffix = 2;
    while (await file.exists()) {
      file = File(
        '${directory.path}${Platform.pathSeparator}${stem}_$suffix.json',
      );
      suffix++;
    }
    await file.writeAsString(payload, flush: true);
    return file.path;
  }

  Future<List<UserRecoveryKeyCandidate>>
  findImportableUserRecoveryKeys() async {
    final directory = await _importsDirectoryProvider();
    await directory.create(recursive: true);
    final files = await directory
        .list(followLinks: false)
        .where(
          (entry) =>
              entry is File &&
              entry.path.toLowerCase().endsWith('.user-recovery-key.json'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    final candidates = <UserRecoveryKeyCandidate>[];
    for (final file in files) {
      if (await file.length() > _maximumKeyBytes) {
        throw const FormatException('A User Recovery Key is too large.');
      }
      candidates.add(
        UserRecoveryKeyCandidate(
          path: file.path,
          document: decodeDocument(await file.readAsBytes()),
        ),
      );
    }
    return candidates;
  }

  UserRecoveryKeyDocument decodeDocument(List<int> bytes) {
    dynamic value;
    try {
      value = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const FormatException('The User Recovery Key is not valid JSON.');
    }
    if (value is! Map ||
        value['format'] != format ||
        value['schemaVersion'] != schemaVersion ||
        value['learnerProfileId'] is! String ||
        value['secret'] is! String) {
      throw const FormatException(
        'This is not a supported QQL User Recovery Key.',
      );
    }
    final learnerProfileId = value['learnerProfileId'] as String;
    final secret = value['secret'] as String;
    if (!ProfileService.isValidLearnerProfileId(learnerProfileId)) {
      throw const FormatException('The Recovery Key identity is invalid.');
    }
    try {
      if (base64Url.decode(base64Url.normalize(secret)).length != 32) {
        throw const FormatException('The Recovery Key credential is invalid.');
      }
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('The Recovery Key credential is invalid.');
    }
    return UserRecoveryKeyDocument(
      learnerProfileId: learnerProfileId,
      secret: secret,
    );
  }

  Future<LearnerProfile> importIdentity(
    UserRecoveryKeyDocument document, {
    required String screenNameText,
    String? discordHandle,
  }) async {
    if (await _profiles.getProfileById(document.learnerProfileId) != null) {
      throw UserRecoveryIdentityConflict(document.learnerProfileId);
    }
    final profile = await _profiles.createProfile(
      screenNameText,
      learnerProfileId: document.learnerProfileId,
      discordHandle: discordHandle,
    );
    await (await SharedPreferences.getInstance()).setString(
      _profiles.keyForProfileId(
        profile.learnerProfileId,
        ProfileService.recoveryCredentialKeyBase,
      ),
      document.secret,
    );
    return profile;
  }
}
