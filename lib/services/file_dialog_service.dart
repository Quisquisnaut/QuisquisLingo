import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_errors.dart';
import 'diagnostic_log_service.dart';

/// Result of asking the operating system to save or open a file.
///
/// [cancelled] is a normal outcome, not an error: nothing is shown or logged.
enum FileDialogOutcome { saved, opened, cancelled, failed, unavailable }

class FileDialogResult {
  const FileDialogResult._(
    this.outcome, {
    this.displayName,
    this.bytes,
    this.failureReason,
  });

  const FileDialogResult.saved(String displayName)
    : this._(FileDialogOutcome.saved, displayName: displayName);
  const FileDialogResult.opened(String displayName, Uint8List bytes)
    : this._(FileDialogOutcome.opened, displayName: displayName, bytes: bytes);
  const FileDialogResult.cancelled() : this._(FileDialogOutcome.cancelled);
  const FileDialogResult.failed(String reason)
    : this._(FileDialogOutcome.failed, failureReason: reason);
  const FileDialogResult.unavailable() : this._(FileDialogOutcome.unavailable);

  final FileDialogOutcome outcome;

  /// File name only (never a full path).
  final String? displayName;

  /// Contents of the opened file; present only for [FileDialogOutcome.opened].
  final Uint8List? bytes;

  final String? failureReason;
}

/// Platform seam. Bytes in, bytes out: no file path crosses this interface,
/// because some platforms return document URIs instead of paths.
abstract class FileDialogBackend {
  bool get isAvailable;

  /// True where the dialog can start in a folder chosen by QQL (desktop).
  /// Document pickers such as Android's decide their own starting place.
  bool get supportsInitialDirectory;

  Future<FileDialogResult> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required List<String> extensions,
    String? initialDirectory,
  });

  /// [maxBytes] is a safety limit: a larger file is reported as failed
  /// without being read.
  Future<FileDialogResult> openBytes({
    required List<String> extensions,
    required int maxBytes,
    String? initialDirectory,
  });
}

/// Used on platforms with no supported dialog backend.
class UnavailableFileDialogBackend implements FileDialogBackend {
  const UnavailableFileDialogBackend();

  @override
  bool get isAvailable => false;

  @override
  bool get supportsInitialDirectory => false;

  @override
  Future<FileDialogResult> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required List<String> extensions,
    String? initialDirectory,
  }) async => const FileDialogResult.unavailable();

  @override
  Future<FileDialogResult> openBytes({
    required List<String> extensions,
    required int maxBytes,
    String? initialDirectory,
  }) async => const FileDialogResult.unavailable();
}

/// Windows, macOS and Linux (GTK) through `file_selector`. The dialog returns
/// an ordinary path, which this class writes or reads itself.
class DesktopFileDialogBackend implements FileDialogBackend {
  const DesktopFileDialogBackend();

  @override
  bool get isAvailable => true;

  @override
  bool get supportsInitialDirectory => true;

  static XTypeGroup _group(List<String> extensions) => XTypeGroup(
    label: extensions.map((e) => '.$e').join(', '),
    extensions: extensions,
  );

  @override
  Future<FileDialogResult> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required List<String> extensions,
    String? initialDirectory,
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      initialDirectory: initialDirectory,
      acceptedTypeGroups: [_group(extensions)],
    );
    if (location == null) return const FileDialogResult.cancelled();
    final target = File(location.path);
    // Write beside the target, then replace it, so a failed write cannot
    // leave a truncated file where the user expects a good one.
    final temporary = File('${target.path}.qqltmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } catch (_) {
      try {
        if (await temporary.exists()) await temporary.delete();
      } catch (_) {}
      rethrow;
    }
    return FileDialogResult.saved(_fileName(location.path));
  }

  @override
  Future<FileDialogResult> openBytes({
    required List<String> extensions,
    required int maxBytes,
    String? initialDirectory,
  }) async {
    final file = await openFile(
      initialDirectory: initialDirectory,
      acceptedTypeGroups: [_group(extensions)],
    );
    if (file == null) return const FileDialogResult.cancelled();
    final name = _fileName(file.path);
    if (await file.length() > maxBytes) {
      return FileDialogResult.failed('$name is larger than the safety limit.');
    }
    return FileDialogResult.opened(name, await file.readAsBytes());
  }

  static String _fileName(String path) =>
      path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty).last;
}

/// Additive "Save to…" / "Open from…" support. It knows nothing about
/// courses or backups: callers supply bytes, a suggested name and a size
/// limit, and validate whatever comes back.
class FileDialogService {
  FileDialogService({
    FileDialogBackend? backend,
    DiagnosticLogService? diagnosticLog,
    Future<Directory?> Function()? downloadsDirectory,
  }) : _backend = backend ?? _defaultBackend(),
       _log = diagnosticLog ?? DiagnosticLogService(),
       _downloadsDirectory = downloadsDirectory ?? getDownloadsDirectory;

  /// Device-wide flag: the first dialog ever opened starts in Downloads; after
  /// that QQL passes nothing, so the OS remembers the user's last folder.
  static const downloadsOfferedKey = 'qql_file_dialog_downloads_offered_v1';

  final FileDialogBackend _backend;
  final DiagnosticLogService _log;
  final Future<Directory?> Function() _downloadsDirectory;
  bool _loggedUnavailable = false;

  Future<String?> _firstUseDirectory() async {
    if (!_backend.supportsInitialDirectory) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(downloadsOfferedKey) ?? false) return null;
      final directory = await _downloadsDirectory();
      if (directory == null || !await directory.exists()) return null;
      return directory.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _markDownloadsOffered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(downloadsOfferedKey, true);
    } catch (_) {}
  }

  static FileDialogBackend _defaultBackend() {
    if (kIsWeb) return const UnavailableFileDialogBackend();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return const DesktopFileDialogBackend();
    }
    // Android (Storage Access Framework) has no backend yet; the buttons stay
    // hidden there and the fixed-folder actions remain the only route.
    return const UnavailableFileDialogBackend();
  }

  /// False when the dialog buttons should be hidden.
  bool get isAvailable => _backend.isAvailable;

  Future<FileDialogResult> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required List<String> extensions,
    required String artifact,
  }) => _run(
    'save',
    artifact,
    suggestedName,
    (initialDirectory) => _backend.saveBytes(
      bytes: bytes,
      suggestedName: suggestedName,
      extensions: extensions,
      initialDirectory: initialDirectory,
    ),
  );

  Future<FileDialogResult> openBytes({
    required List<String> extensions,
    required int maxBytes,
    required String artifact,
  }) => _run(
    'open',
    artifact,
    null,
    (initialDirectory) => _backend.openBytes(
      extensions: extensions,
      maxBytes: maxBytes,
      initialDirectory: initialDirectory,
    ),
  );

  Future<FileDialogResult> _run(
    String direction,
    String artifact,
    String? fileName,
    Future<FileDialogResult> Function(String? initialDirectory) action,
  ) async {
    FileDialogResult result;
    Object? error;
    final initialDirectory = await _firstUseDirectory();
    try {
      result = await action(initialDirectory);
      if (initialDirectory != null) await _markDownloadsOffered();
    } catch (caught) {
      if (initialDirectory != null) await _markDownloadsOffered();
      error = caught;
      result = FileDialogResult.failed(caught.runtimeType.toString());
    }
    switch (result.outcome) {
      case FileDialogOutcome.failed:
        await _log.log(
          AppErrorCode.fileDialogFailed,
          context: _context(
            direction,
            artifact,
            result.displayName ?? fileName,
          ),
          exception: error == null ? result.failureReason : _describe(error),
        );
      case FileDialogOutcome.unavailable:
        if (!_loggedUnavailable) {
          _loggedUnavailable = true;
          await _log.log(
            AppErrorCode.fileDialogUnavailable,
            context: _context(direction, artifact, fileName),
          );
        }
      case FileDialogOutcome.saved:
      case FileDialogOutcome.opened:
      case FileDialogOutcome.cancelled:
        break;
    }
    return result;
  }

  // Exception text can embed the full path (FileSystemException does), so log
  // the type and, where available, the OS error without the path.
  static String _describe(Object error) {
    if (error is FileSystemException) {
      final os = error.osError;
      return 'FileSystemException: ${error.message}'
          '${os == null ? '' : ' (OS error ${os.errorCode}: ${os.message})'}';
    }
    return error.runtimeType.toString();
  }

  // File name only: the Diagnostic Log may be sent to the developer, and full
  // paths often contain the user's name. Never log file contents.
  static String _context(String direction, String artifact, String? name) =>
      'platform=${Platform.operatingSystem}; direction=$direction; '
      'artifact=$artifact${name == null ? '' : '; file=$name'}';
}
