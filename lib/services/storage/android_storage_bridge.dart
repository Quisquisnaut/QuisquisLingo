import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../import/safe_file_name.dart';
import '../import/selected_external_file.dart';
import 'qql_storage.dart';

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

/// What the Android side reports about storage, once per run.
class AndroidStorageInfo {
  const AndroidStorageInfo({
    required this.sdk,
    required this.scopedStorage,
    required this.downloadsPath,
  });

  factory AndroidStorageInfo.fromMap(Map<Object?, Object?> map) =>
      AndroidStorageInfo(
        sdk: (map['sdk']! as num).toInt(),
        scopedStorage: map['scoped'] == true,
        downloadsPath: map['downloadsPath']! as String,
      );

  final int sdk;

  /// Android 10 and later: MediaStore and one folder permission. Before
  /// that, ordinary files in [downloadsPath] with the storage permission.
  final bool scopedStorage;

  /// The public Download directory, used directly only before Android 10.
  final String downloadsPath;
}

/// Quick Import lost its folder permission, or never had it.
class AndroidImportAccessMissing implements Exception {
  const AndroidImportAccessMissing();
}

/// Dart side of the Android storage bridge (`QqlStorageBridge.kt` and
/// `QuickFolders.kt`).
///
/// The UI channel shows the system screens: the Storage Access Framework
/// pickers, the folder screen for Quick Import, and the Android 7–9 storage
/// permission. The I/O channel moves bytes in chunks of at most
/// [chunkBytes] on a background thread, so no file crosses the channel
/// whole. Nothing here validates content: every byte read goes through the
/// same staging and checks as a desktop file.
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
    final handle = await _io.invokeMethod<int>('openWrite', {'uri': uri});
    await _writeAll(handle!, bytes);
  }

  /// Android 10 and later: writes [bytes] as a Download entry in
  /// [relativeFolder] (for example `Download/QuisquisLingo/Exports/Courses`),
  /// named `baseName.extension`, or `baseName_2.extension` and so on when
  /// QQL already has one; [replace] overwrites QQL's own entry. Nothing is
  /// visible until the write has finished. Returns the final file name.
  Future<String> writeDownload({
    required String relativeFolder,
    required String baseName,
    required String extension,
    required String mimeType,
    required List<int> bytes,
    required bool replace,
  }) async {
    final handle = await _io.invokeMethod<int>('beginDownload', {
      'relativeFolder': relativeFolder,
      'baseName': baseName,
      'extension': extension,
      'mimeType': mimeType,
      'replace': replace,
    });
    return await _writeAll(handle!, bytes) ?? '$baseName.$extension';
  }

  Future<String?> _writeAll(int handle, List<int> bytes) async {
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    var keep = false;
    String? name;
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
      name = await _io.invokeMethod<String>('closeWrite', {
        'handle': handle,
        'keep': keep,
      });
    }
    // Only a completed write gets here; a failed one threw above.
    return name;
  }

  Future<AndroidStorageInfo> storageInfo() async => AndroidStorageInfo.fromMap(
    (await _io.invokeMapMethod<Object?, Object?>('storageInfo'))!,
  );

  /// Whether Quick Import can read `Download/QuisquisLingo/Imports` now.
  Future<bool> hasImportAccess() async =>
      await _io.invokeMethod<bool>('hasImportAccess') ?? false;

  /// Android 10 and later: the folder screen, opened on
  /// `Download/QuisquisLingo/Imports`; only that folder is accepted. Android
  /// 7–9: the storage permission.
  Future<QuickImportAccessResult> requestImportAccess() async =>
      switch (await _ui.invokeMethod<String>('requestImportAccess')) {
        'granted' => QuickImportAccessResult.granted,
        'wrongFolder' => QuickImportAccessResult.wrongFolder,
        'denied' => QuickImportAccessResult.denied,
        _ => QuickImportAccessResult.cancelled,
      };

  /// Android 7–9: the storage permission for Quick Export; true when held.
  Future<bool> requestLegacyWriteAccess() async =>
      await _ui.invokeMethod<bool>('requestLegacyWriteAccess') ?? false;

  /// The files in `Imports/[segments]`, creating missing folders. Throws
  /// [AndroidImportAccessMissing] when the folder permission is gone.
  Future<List<AndroidDocument>> listImports(List<String> segments) async {
    try {
      final items = await _io.invokeListMethod<Object?>('listImports', {
        'segments': segments,
      });
      return [
        for (final item in items ?? const <Object?>[])
          AndroidDocument.fromMap(item! as Map<Object?, Object?>),
      ];
    } on PlatformException catch (error) {
      if (error.code == 'accessRequired') {
        throw const AndroidImportAccessMissing();
      }
      rethrow;
    }
  }

  /// Every file below Imports, for Inventory.
  Future<List<QqlPublicFile>> listAllImports() async =>
      _publicFiles(await _io.invokeListMethod<Object?>('listAllImports'));

  /// Deletes everything below Imports; returns the file count.
  Future<int> deleteImports() async =>
      await _io.invokeMethod<int>('deleteImports') ?? 0;

  Future<void> releaseImportAccess() =>
      _io.invokeMethod<void>('releaseImportAccess');

  /// QQL's own Download entries below [relativePrefix], for Inventory.
  Future<List<QqlPublicFile>> listOwnDownloads(String relativePrefix) async =>
      _publicFiles(
        await _io.invokeListMethod<Object?>('listOwnDownloads', {
          'relativePrefix': relativePrefix,
        }),
      );

  /// Deletes QQL's own Download entries below [relativePrefix].
  Future<int> deleteOwnDownloads(String relativePrefix) async =>
      await _io.invokeMethod<int>('deleteOwnDownloads', {
        'relativePrefix': relativePrefix,
      }) ??
      0;

  /// Android 7–9: announces a new file to file managers.
  Future<void> scanFile(String path) =>
      _io.invokeMethod<void>('scanFile', {'path': path});

  static List<QqlPublicFile> _publicFiles(List<Object?>? items) => [
    for (final item in items ?? const <Object?>[])
      if (item case final Map<Object?, Object?> map)
        QqlPublicFile(
          map['name']! as String,
          size: (map['size'] as num?)?.toInt(),
          modified: map['modified'] is num
              ? DateTime.fromMillisecondsSinceEpoch(
                  (map['modified']! as num).toInt(),
                )
              : null,
        ),
  ];
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
