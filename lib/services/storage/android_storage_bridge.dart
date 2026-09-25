import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../import/safe_file_name.dart';
import '../import/selected_external_file.dart';

/// One document an Android picker or folder returned: a content URI, never
/// a path. [name] is the provider's display name, unsanitized.
class AndroidDocument {
  const AndroidDocument({required this.uri, required this.name, this.size});

  factory AndroidDocument.fromMap(Map<Object?, Object?> map) =>
      AndroidDocument(
        uri: map['uri']! as String,
        name: (map['name'] as String?) ?? 'file',
        size: (map['size'] as num?)?.toInt(),
      );

  final String uri;
  final String name;
  final int? size;
}

/// Dart side of the Android storage bridge (`QqlStorageBridge.kt`).
///
/// The UI channel shows the Storage Access Framework pickers. The I/O
/// channel moves bytes in chunks of at most [chunkBytes] on a background
/// thread, so no file crosses the channel whole. Nothing here validates
/// content: every byte read goes through the same staging and checks as a
/// desktop file.
class AndroidStorageBridge {
  const AndroidStorageBridge({
    MethodChannel ui = uiChannel,
    MethodChannel io = ioChannel,
  }) : _ui = ui,
       _io = io;

  static const uiChannel = MethodChannel('org.quisquislingo.app/storage');
  static const ioChannel = MethodChannel('org.quisquislingo.app/storage_io');

  /// The largest piece moved in one call, both ways.
  static const chunkBytes = 1024 * 1024;

  final MethodChannel _ui;
  final MethodChannel _io;

  /// Save as…: the document the user created, or null when they cancelled.
  Future<AndroidDocument?> createDocument({
    required String suggestedName,
    required String mimeType,
  }) async {
    final picked = await _ui.invokeMapMethod<Object?, Object?>(
      'createDocument',
      {'suggestedName': suggestedName, 'mimeType': mimeType},
    );
    return picked == null ? null : AndroidDocument.fromMap(picked);
  }

  /// Open from…: the chosen documents, or null when the user cancelled.
  Future<List<AndroidDocument>?> openDocuments({
    required List<String> mimeTypes,
    required bool multiple,
  }) async {
    final picked = await _ui.invokeListMethod<Object?>('openDocuments', {
      'mimeTypes': mimeTypes,
      'multiple': multiple,
    });
    return picked
        ?.map((item) => AndroidDocument.fromMap(item! as Map<Object?, Object?>))
        .toList();
  }

  /// Opens [uri] now, so an unreadable document fails here; the stream then
  /// pulls it piece by piece and closes it when it ends or is cancelled.
  Future<Stream<List<int>>> openRead(String uri) async {
    final handle = await _io.invokeMethod<int>('openRead', {'uri': uri});
    return _chunks(handle!);
  }

  Stream<List<int>> _chunks(int handle) async* {
    try {
      while (true) {
        final chunk = await _io.invokeMethod<Uint8List>('read', {
          'handle': handle,
          'maxBytes': chunkBytes,
        });
        if (chunk == null || chunk.isEmpty) break;
        yield chunk;
      }
    } finally {
      try {
        await _io.invokeMethod<void>('closeRead', {'handle': handle});
      } catch (_) {}
    }
  }

  /// Writes [bytes] into [uri] piece by piece. A write that fails part-way
  /// deletes the document, so no truncated file is left where the user
  /// expects a good one.
  Future<void> writeDocument(String uri, List<int> bytes) async {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final handle = await _io.invokeMethod<int>('openWrite', {'uri': uri});
    var keep = false;
    try {
      for (var offset = 0; offset < data.length; offset += chunkBytes) {
        await _io.invokeMethod<void>('write', {
          'handle': handle,
          'bytes': Uint8List.fromList(
            Uint8List.sublistView(
              data,
              offset,
              min(offset + chunkBytes, data.length),
            ),
          ),
        });
      }
      keep = true;
    } finally {
      await _io.invokeMethod<void>('closeWrite', {
        'handle': handle,
        'keep': keep,
      });
    }
  }
}

/// A document chosen on Android, read through the bridge as a stream.
class AndroidDocumentFile implements SelectedExternalFile {
  AndroidDocumentFile(this.document, this._bridge)
    : displayName = safeDisplayName(document.name);

  final AndroidDocument document;
  final AndroidStorageBridge _bridge;

  @override
  final String displayName;

  @override
  String get sourceFileName => document.name.split(RegExp(r'[\\/]')).last;

  @override
  int? get reportedSize => document.size;

  @override
  ExternalFileSource get source => ExternalFileSource.document;

  @override
  Future<Stream<List<int>>> openRead() async {
    try {
      return await _bridge.openRead(document.uri);
    } on PlatformException {
      throw ImportAccessException('$displayName could not be read.');
    } on MissingPluginException {
      throw ImportAccessException('$displayName could not be read.');
    }
  }
}
