import 'dart:typed_data';

import '../file_dialog_service.dart';
import '../import/safe_file_name.dart';
import 'android_storage_bridge.dart';

/// Android Save as… and Open from… through the Storage Access Framework.
/// The pickers return document URIs, never paths: saving writes the bytes
/// through the bridge, and opening hands back streamed documents that
/// [FileDialogService] stages and the callers validate like any other file.
class AndroidFileDialogBackend implements FileDialogBackend {
  const AndroidFileDialogBackend({
    AndroidStorageBridge bridge = const AndroidStorageBridge(),
  }) : _bridge = bridge;

  final AndroidStorageBridge _bridge;

  /// Picker filters by extension. They are hints: every file is still
  /// checked by name and content after it is read.
  static const _mimeTypes = <String, List<String>>{
    'zip': ['application/zip', 'application/x-zip-compressed'],
    'json': ['application/json', 'text/plain'],
    'mp3': ['audio/mpeg', 'audio/mp3'],
    'png': ['image/png'],
    'jpg': ['image/jpeg'],
    'jpeg': ['image/jpeg'],
    'webp': ['image/webp'],
    'txt': ['text/plain'],
    'log': ['text/plain'],
  };

  /// The MIME types Open from… offers. Providers label some files loosely
  /// (a JSON or ZIP may be "application/octet-stream"), so that type is
  /// always included rather than greying out a good file.
  static List<String> mimeTypesFor(List<String> extensions) {
    final types = <String>{};
    for (final extension in extensions) {
      final known = _mimeTypes[extension.toLowerCase()];
      if (known == null) return const ['*/*'];
      types.addAll(known);
    }
    if (types.isEmpty) return const ['*/*'];
    if (extensions.any((e) => const {'zip', 'json'}.contains(e.toLowerCase()))) {
      types.add('application/octet-stream');
    }
    return types.toList();
  }

  /// The MIME type Save as… declares for [fileName].
  static String mimeTypeFor(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    return _mimeTypes[extension]?.first ?? 'application/octet-stream';
  }

  @override
  bool get isAvailable => true;

  /// Android's picker chooses where it starts.
  @override
  bool get supportsInitialDirectory => false;

  @override
  Future<FileDialogResult> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required List<String> extensions,
    String? initialDirectory,
  }) async {
    final document = await _bridge.createDocument(
      suggestedName: suggestedName,
      mimeType: mimeTypeFor(suggestedName),
    );
    if (document == null) return const FileDialogResult.cancelled();
    await _bridge.writeDocument(document.uri, bytes);
    return FileDialogResult.saved(safeDisplayName(document.name));
  }

  @override
  Future<FileDialogPick> pickFiles({
    required List<String> extensions,
    required bool multiple,
    String? initialDirectory,
  }) async {
    final documents = await _bridge.openDocuments(
      mimeTypes: mimeTypesFor(extensions),
      multiple: multiple,
    );
    if (documents == null || documents.isEmpty) {
      return const FileDialogPick.cancelled();
    }
    return FileDialogPick.picked([
      for (final document in multiple ? documents : documents.take(1))
        AndroidDocumentFile(document, _bridge),
    ]);
  }
}
