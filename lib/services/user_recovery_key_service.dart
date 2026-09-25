import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'file_dialog_service.dart';
import 'profile_service.dart';
import 'import/import_stager.dart';
import 'import/json_limits.dart';
import 'import/selected_external_file.dart';
import 'storage/file_system_storage.dart';
import 'storage/qql_storage.dart';

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

  /// Replace the Quick Export and Quick Import folders in tests.
  final Future<Directory> Function()? _exportsDirectoryProvider;
  final Future<Directory> Function()? _importsDirectoryProvider;
  final QqlStorage _storage;
  final List<int> Function(int length) _secureBytes;
  final FileDialogService _fileDialogs;

  UserRecoveryKeyService({
    ProfileService? profileService,
    Future<Directory> Function()? exportsDirectoryProvider,
    Future<Directory> Function()? importsDirectoryProvider,
    List<int> Function(int length)? secureBytes,
    FileDialogService? fileDialogs,
    QqlStorage? storage,
  }) : _profiles = profileService ?? ProfileService(),
       _fileDialogs = fileDialogs ?? FileDialogService(),
       _exportsDirectoryProvider = exportsDirectoryProvider,
       _importsDirectoryProvider = importsDirectoryProvider,
       _storage = storage ?? QqlStorage(),
       _secureBytes =
           secureBytes ??
           ((length) =>
               List<int>.generate(length, (_) => Random.secure().nextInt(256)));

  static Future<Directory> _created(
    Future<Directory> Function() injected,
  ) async {
    final directory = await injected();
    await directory.create(recursive: true);
    return directory;
  }

  Future<QuickExportFolder> _exportFolder() async {
    final injected = _exportsDirectoryProvider;
    return injected == null
        ? _storage.exportFolder(QqlStorageRole.recoveryKeyExports)
        : FileSystemExportFolder(await _created(injected));
  }

  Future<QuickImportFolder> _importFolder() async {
    final injected = _importsDirectoryProvider;
    return injected == null
        ? _storage.importFolder(QqlStorageRole.recoveryKeyImports)
        : FileSystemImportFolder(await _created(injected));
  }

  /// False when the system dialog is unsupported; hide Save as… / Open from….
  bool get fileDialogsAvailable => _fileDialogs.isAvailable;

  /// Save as…: the same key file as [exportActiveUserRecoveryKey], written
  /// wherever the user chooses. The key is a secret: callers must warn the
  /// user before the dialog opens.
  Future<FileDialogResult> exportActiveUserRecoveryKeyTo() async {
    final export = await _buildActiveKeyExport();
    return _fileDialogs.saveBytes(
      bytes: export.bytes,
      suggestedName: '${export.stem}.json',
      extensions: const ['json'],
      artifact: 'user-recovery-key',
    );
  }

  /// Open from…: pick one Recovery Key file in the system dialog. Decoded by
  /// the same [decodeDocument] as the fixed-folder scan; the candidate is null
  /// when the user cancelled or the dialog failed. Its `path` is the file
  /// name only.
  Future<({FileDialogResult dialog, UserRecoveryKeyCandidate? candidate})>
  openUserRecoveryKeyFromDialog() async {
    final picked = await _fileDialogs.openBytes(
      extensions: const ['json'],
      maxBytes: _maximumKeyBytes,
      artifact: 'user-recovery-key',
    );
    if (picked.outcome == FileDialogOutcome.tooLarge) {
      throw const FormatException('A User Recovery Key is too large.');
    }
    if (picked.outcome != FileDialogOutcome.opened) {
      return (dialog: picked, candidate: null);
    }
    final bytes = picked.bytes!;
    return (
      dialog: picked,
      candidate: UserRecoveryKeyCandidate(
        path: picked.displayName!,
        document: decodeDocument(bytes),
      ),
    );
  }

  Future<({Uint8List bytes, String stem})> _buildActiveKeyExport() async {
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
    return (
      bytes: Uint8List.fromList(utf8.encode(payload)),
      stem: 'quisquislingo_${profile.learnerProfileId}.user-recovery-key',
    );
  }

  Future<String> exportActiveUserRecoveryKey() async {
    final export = await _buildActiveKeyExport();
    final written = await (await _exportFolder()).write(
      baseName: export.stem,
      extension: 'json',
      bytes: export.bytes,
    );
    return written.location;
  }

  Future<List<UserRecoveryKeyCandidate>>
  findImportableUserRecoveryKeys() async {
    final folder = await _importFolder();
    final files =
        (await folder.files())
            .where(
              (file) =>
                  file.name.toLowerCase().endsWith('.user-recovery-key.json'),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    const tooLarge = FormatException('A User Recovery Key is too large.');
    final candidates = <UserRecoveryKeyCandidate>[];
    for (final file in files) {
      if ((file.reportedSize ?? 0) > _maximumKeyBytes) throw tooLarge;
      final List<int> bytes;
      try {
        bytes = await readQuickImportFile(file, maxBytes: _maximumKeyBytes);
      } on ImportTooLargeException {
        throw tooLarge;
      } on ImportAccessException catch (error) {
        throw FormatException(error.message);
      }
      candidates.add(
        UserRecoveryKeyCandidate(
          path: folder.locationOf(file.name),
          document: decodeDocument(bytes),
        ),
      );
    }
    return candidates;
  }

  UserRecoveryKeyDocument decodeDocument(List<int> bytes) {
    const invalid = FormatException('The User Recovery Key is not valid JSON.');
    final String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      throw invalid;
    }
    final value = JsonLimits.imports.decode(
      text,
      what: 'The User Recovery Key',
      invalidMessage: invalid.message,
    );
    if (value is Map) {
      CourseShapeLimits.noNul(value, const [
        'learnerProfileId',
      ], what: 'The User Recovery Key');
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
