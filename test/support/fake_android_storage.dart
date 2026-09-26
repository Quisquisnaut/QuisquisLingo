import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/storage/android_storage_bridge.dart';

/// Plays the Android side of the storage bridge (`QqlStorageBridge.kt` and
/// `QuickFolders.kt`) in memory: MediaStore Download entries, the
/// QuisquisLingo folder behind its permission, and the Android 7–9 storage
/// permission. Every call is recorded; [uiCalls] are the ones that would
/// show a screen.
class FakeAndroidStorage {
  FakeAndroidStorage({this.scoped = true, this.downloadsPath = '/unused'}) {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AndroidStorageBridge.uiChannel, _ui);
    messenger.setMockMethodCallHandler(AndroidStorageBridge.ioChannel, _io);
  }

  void dispose() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(AndroidStorageBridge.uiChannel, null);
    messenger.setMockMethodCallHandler(AndroidStorageBridge.ioChannel, null);
  }

  /// Android 10 and later when true; Android 7–9 when false.
  bool scoped;

  /// Android 7–9: the public Download directory (a test folder).
  String downloadsPath;

  /// The QuisquisLingo folder permission (Android 10+) or the storage
  /// permission (Android 7–9).
  bool importAccess = false;

  /// What the folder screen or permission prompt answers; 'granted' also
  /// grants [importAccess].
  String requestAnswer = 'granted';

  /// Android 7–9: whether the storage permission prompt is accepted.
  bool legacyWriteGranted = true;

  /// The permission is still listed, but the folder is gone.
  bool folderGone = false;

  /// The permission disappears between the access check and the read.
  bool revokeOnList = false;

  /// Files people put below the QuisquisLingo folder, read through the
  /// permission, by path such as `Import/Courses/import.zip`.
  final imports = <String, Uint8List>{};

  /// The folders the last folder request asked Android to create.
  List<String> requestedFolders = const [];

  /// QQL's own Download entries, by relative path and name, such as
  /// `Download/QuisquisLingo/Exports/Courses/x.zip`.
  final downloads = <String, Uint8List>{};

  final calls = <MethodCall>[];
  final uiCalls = <String>[];
  bool released = false;
  final scanned = <String>[];

  final _reading = <int, ({Uint8List bytes, int offset})>{};
  final _writing = <int, ({String? path, BytesBuilder bytes})>{};
  var _next = 1;

  Future<Object?> _ui(MethodCall call) async {
    calls.add(call);
    uiCalls.add(call.method);
    switch (call.method) {
      case 'requestImportAccess':
        requestedFolders =
            ((call.arguments as Map?)?['folders'] as List? ?? const [])
                .cast<String>();
        if (requestAnswer == 'granted') {
          importAccess = true;
          folderGone = false;
        }
        return requestAnswer;
      case 'requestLegacyWriteAccess':
        return legacyWriteGranted;
    }
    throw MissingPluginException(call.method);
  }

  Future<Object?> _io(MethodCall call) async {
    calls.add(call);
    final args = (call.arguments as Map?)?.cast<String, Object?>() ?? const {};
    switch (call.method) {
      case 'storageInfo':
        return {
          'sdk': scoped ? 36 : 28,
          'scoped': scoped,
          'downloadsPath': downloadsPath,
        };
      case 'hasImportAccess':
        return importAccess && !folderGone;
      case 'listImports':
        if (!importAccess || folderGone || revokeOnList) {
          throw PlatformException(code: 'accessRequired');
        }
        final folder = (args['segments']! as List).cast<String>().join('/');
        final prefix = folder.isEmpty ? '' : '$folder/';
        return [
          for (final entry in imports.entries)
            if (entry.key.startsWith(prefix) &&
                !entry.key.substring(prefix.length).contains('/'))
              {
                'uri': 'content://imports/${entry.key}',
                'name': entry.key.substring(prefix.length),
                'size': entry.value.length,
              },
        ];
      case 'listTree':
        if (!importAccess || folderGone) return const [];
        final prefix =
            '${(args['segments']! as List).cast<String>().join('/')}/';
        return [
          for (final entry in imports.entries)
            if (entry.key.startsWith(prefix))
              {
                'name': entry.key.substring(prefix.length),
                'size': entry.value.length,
                'modified': 1000,
              },
        ];
      case 'deleteTree':
        if (!importAccess || folderGone) return 0;
        final prefix =
            '${(args['segments']! as List).cast<String>().join('/')}/';
        final gone = imports.keys.where((k) => k.startsWith(prefix)).toList();
        gone.forEach(imports.remove);
        return gone.length;
      case 'releaseImportAccess':
        released = true;
        importAccess = false;
        return null;
      case 'listOwnDownloads':
        final prefix = args['relativePrefix']! as String;
        return [
          for (final entry in downloads.entries)
            if (entry.key.startsWith(prefix))
              {
                'name': entry.key.substring(prefix.length),
                'size': entry.value.length,
                'modified': 2000,
              },
        ];
      case 'deleteOwnDownloads':
        final prefix = args['relativePrefix']! as String;
        final gone = downloads.keys.where((k) => k.startsWith(prefix)).toList();
        gone.forEach(downloads.remove);
        return gone.length;
      case 'scanFile':
        scanned.add(args['path']! as String);
        return null;
      case 'openRead':
        final uri = args['uri']! as String;
        final key = uri.replaceFirst('content://imports/', '');
        final bytes = imports[key];
        if (bytes == null) throw PlatformException(code: 'io');
        _reading[_next] = (bytes: bytes, offset: 0);
        return _next++;
      case 'read':
        final handle = args['handle']! as int;
        final state = _reading[handle]!;
        final end = (state.offset + 4096).clamp(0, state.bytes.length);
        _reading[handle] = (bytes: state.bytes, offset: end);
        return Uint8List.sublistView(state.bytes, state.offset, end);
      case 'closeRead':
        _reading.remove(args['handle']);
        return null;
      case 'beginDownload':
        final folder = (args['relativeFolder']! as String).replaceAll(
          RegExp(r'/+$'),
          '',
        );
        final base = args['baseName']! as String;
        final extension = args['extension']! as String;
        var name = '$base.$extension';
        if (args['replace'] != true) {
          var suffix = 2;
          while (downloads.containsKey('$folder/$name')) {
            name = '${base}_$suffix.$extension';
            suffix++;
          }
        }
        _writing[_next] = (path: '$folder/$name', bytes: BytesBuilder());
        return _next++;
      case 'write':
        _writing[args['handle']! as int]!.bytes.add(
          args['bytes']! as Uint8List,
        );
        return null;
      case 'closeWrite':
        final writer = _writing.remove(args['handle']! as int)!;
        if (args['keep'] != true || writer.path == null) return null;
        downloads[writer.path!] = writer.bytes.takeBytes();
        return writer.path!.split('/').last;
    }
    throw MissingPluginException(call.method);
  }

  /// No read or write handle is left open.
  bool get allClosed => _reading.isEmpty && _writing.isEmpty;
}
