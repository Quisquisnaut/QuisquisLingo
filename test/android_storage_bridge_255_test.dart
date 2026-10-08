import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/storage/android_file_dialog_backend.dart';
import 'package:quisquislingo_app/services/storage/android_storage_bridge.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/dialog_test_course.dart';
import 'support/fake_file_dialog_backend.dart';

/// Plays the Kotlin side of the bridge: documents live in memory, keyed by
/// URI, and every call is recorded.
class _FakeAndroid {
  _FakeAndroid() {
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

  final documents = <String, Uint8List>{};
  final names = <String, String>{};
  final calls = <String>[];
  final deleted = <String>[];

  /// What the next picker returns; null means the user cancelled.
  Map<String, Object?>? created;
  List<Map<String, Object?>>? opened;

  /// Makes this read call (1-based) or every write fail.
  int? failReadAt;
  bool failWrite = false;
  bool failOpen = false;
  int chunk = 4;

  final _reading = <int, ({String uri, int offset})>{};
  final _writing = <int, ({String uri, BytesBuilder bytes})>{};
  var _next = 1;
  var reads = 0;

  Future<Object?> _ui(MethodCall call) async {
    calls.add(call.method);
    switch (call.method) {
      case 'createDocument':
        return created;
      case 'openDocuments':
        return opened;
    }
    throw MissingPluginException(call.method);
  }

  Future<Object?> _io(MethodCall call) async {
    calls.add(call.method);
    final args = (call.arguments as Map).cast<String, Object?>();
    switch (call.method) {
      case 'openRead':
        final uri = args['uri']! as String;
        if (failOpen || !documents.containsKey(uri)) {
          throw PlatformException(code: 'io', message: 'FileNotFoundException');
        }
        _reading[_next] = (uri: uri, offset: 0);
        return _next++;
      case 'read':
        reads++;
        if (failReadAt == reads) {
          throw PlatformException(code: 'io', message: 'IOException');
        }
        final handle = args['handle']! as int;
        final state = _reading[handle]!;
        final bytes = documents[state.uri]!;
        final end = (state.offset + chunk).clamp(0, bytes.length);
        _reading[handle] = (uri: state.uri, offset: end);
        return Uint8List.sublistView(bytes, state.offset, end);
      case 'closeRead':
        _reading.remove(args['handle']);
        return null;
      case 'openWrite':
        _writing[_next] = (uri: args['uri']! as String, bytes: BytesBuilder());
        return _next++;
      case 'write':
        if (failWrite) {
          throw PlatformException(code: 'io', message: 'IOException');
        }
        _writing[args['handle']! as int]!.bytes.add(args['bytes']! as Uint8List);
        return null;
      case 'closeWrite':
        final writer = _writing.remove(args['handle']! as int)!;
        if (args['keep'] == true) {
          documents[writer.uri] = writer.bytes.takeBytes();
        } else {
          deleted.add(writer.uri);
        }
        return null;
    }
    throw MissingPluginException(call.method);
  }

  bool get allClosed => _reading.isEmpty && _writing.isEmpty;

  void offer(String uri, String name, List<int> bytes) {
    documents[uri] = Uint8List.fromList(bytes);
    names[uri] = name;
    opened = [
      {'uri': uri, 'name': name, 'size': bytes.length},
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAndroid android;
  late FileDialogService dialogs;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    android = _FakeAndroid();
    dialogs = FileDialogService(
      backend: const AndroidFileDialogBackend(),
      stager: testImportStager(),
    );
  });

  tearDown(() => android.dispose());

  group('Android Save as…', () {
    test('writes the bytes in bounded chunks and names the document', () async {
      final bytes = Uint8List.fromList(
        List<int>.generate(
          AndroidStorageBridge.chunkBytes * 2 + 5,
          (i) => i % 251,
        ),
      );
      android.created = {'uri': 'content://docs/1', 'name': 'my course.zip'};
      final result = await dialogs.saveBytes(
        bytes: bytes,
        suggestedName: 'quisquislingo_my_course.zip',
        extensions: const ['zip'],
        artifact: 'course',
      );
      expect(result.outcome, FileDialogOutcome.saved);
      expect(result.displayName, 'my course.zip');
      expect(android.documents['content://docs/1'], bytes);
      expect(android.calls.where((call) => call == 'write'), hasLength(3));
      expect(android.allClosed, isTrue);
    });

    test('a cancelled picker writes nothing and says nothing', () async {
      android.created = null;
      final result = await dialogs.saveBytes(
        bytes: Uint8List.fromList([1]),
        suggestedName: 'x.json',
        extensions: const ['json'],
        artifact: 'user-data',
      );
      expect(result.outcome, FileDialogOutcome.cancelled);
      expect(android.calls, ['createDocument']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quisquislingo_diagnostic_log'), isNull);
    });

    test('a failed write deletes the document and is logged without its '
        'address', () async {
      android.created = {'uri': 'content://docs/secret', 'name': 'x.json'};
      android.failWrite = true;
      final result = await dialogs.saveBytes(
        bytes: Uint8List.fromList([1, 2]),
        suggestedName: 'x.json',
        extensions: const ['json'],
        artifact: 'user-data',
      );
      expect(result.outcome, FileDialogOutcome.failed);
      expect(android.deleted, ['content://docs/secret']);
      expect(android.allClosed, isTrue);
      final log = (await SharedPreferences.getInstance()).getString(
        'quisquislingo_diagnostic_log',
      )!;
      expect(log, contains('platform='));
      expect(log, isNot(contains('content://')));
    });
  });

  group('Android Open from…', () {
    test('streams the document into staging and hands back its bytes', () async {
      android.offer('content://docs/a', 'import.json', utf8.encode('{"a":1}'));
      final result = await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 100,
        artifact: 'course',
      );
      expect(result.outcome, FileDialogOutcome.opened);
      expect(result.displayName, 'import.json');
      expect(utf8.decode(result.bytes!), '{"a":1}');
      expect(android.allClosed, isTrue);
    });

    test('stops reading as soon as the limit is passed', () async {
      android.offer('content://docs/big', 'big.zip', List.filled(40, 7));
      final result = await dialogs.openBytes(
        extensions: const ['zip'],
        maxBytes: 10,
        artifact: 'course',
      );
      expect(result.outcome, FileDialogOutcome.tooLarge);
      expect(android.reads, lessThan(10));
      expect(android.allClosed, isTrue);
    });

    test('a provider failure part-way fails cleanly', () async {
      android.offer('content://docs/b', 'b.json', List.filled(20, 1));
      android.failReadAt = 2;
      final result = await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 100,
        artifact: 'course',
      );
      expect(result.outcome, FileDialogOutcome.failed);
      expect(result.failureReason, 'b.json could not be read to the end.');
      expect(android.allClosed, isTrue);
    });

    test('an unreadable document is refused', () async {
      android.offer('content://docs/c', 'c.json', [1]);
      android.failOpen = true;
      final result = await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 100,
        artifact: 'course',
      );
      expect(result.outcome, FileDialogOutcome.failed);
      expect(result.failureReason, 'c.json could not be read.');
    });

    test('a cancelled picker opens nothing', () async {
      android.opened = null;
      final result = await dialogs.openBytes(
        extensions: const ['json'],
        maxBytes: 100,
        artifact: 'course',
      );
      expect(result.outcome, FileDialogOutcome.cancelled);
      expect(android.calls, ['openDocuments']);
    });

    test('a provider name is shown sanitized; the source name is kept for '
        'checks only', () async {
      android.offer('content://docs/d', '../../evil\u0000 .json', [1]);
      final picked = await const AndroidFileDialogBackend().pickFiles(
        extensions: const ['json'],
        multiple: false,
      );
      final file = picked.files.single;
      expect(file.displayName, 'evil .json');
      expect(file.sourceFileName, 'evil\u0000 .json');
    });

    test('several documents stage one by one within the batch', () async {
      android.documents['content://docs/1'] = Uint8List.fromList([1, 2]);
      android.documents['content://docs/2'] = Uint8List.fromList([3]);
      android.opened = [
        {'uri': 'content://docs/1', 'name': 'one.mp3', 'size': 2},
        {'uri': 'content://docs/2', 'name': 'two.mp3', 'size': 1},
      ];
      final picked = await dialogs.openFiles(
        extensions: const ['mp3'],
        maxBytesPerFile: 10,
        artifact: 'mp3',
      );
      final staged = picked.batch!.items.map((item) => item.staged!).toList();
      expect(staged.map((file) => file.length), [2, 1]);
      for (final file in staged) {
        await file.discard();
      }
      expect(android.allClosed, isTrue);
    });

    test('a Course package opened from a document goes through the ordinary '
        'package checks', () async {
      final course = dialogTestCourse();
      final json = Uint8List.fromList(utf8.encode(jsonEncode(course.toJson())));
      final zip = await CoursePackageService().build(course, json);
      android.offer('content://docs/pkg', 'shared.zip', zip);
      android.chunk = 4096;
      final transfer = CustomCourseTransferService(fileDialogs: dialogs);
      final picked = await transfer.importPackageFromDialog();
      addTearDown(() => picked.package?.discard() ?? Future.value());
      expect(picked.dialog.outcome, FileDialogOutcome.opened);
      expect(picked.package!.course.courseId, course.courseId);
      expect(android.allClosed, isTrue);
    });
  });

  group('Android picker types and backend choice', () {
    test('filters are generous hints; saves declare one type', () {
      expect(
        AndroidFileDialogBackend.mimeTypesFor(const ['zip', 'json']),
        containsAll([
          'application/zip',
          'application/json',
          'application/octet-stream',
        ]),
      );
      expect(AndroidFileDialogBackend.mimeTypesFor(const ['mp3']), [
        'audio/mpeg',
        'audio/mp3',
      ]);
      expect(AndroidFileDialogBackend.mimeTypesFor(const ['xyz']), ['*/*']);
      expect(AndroidFileDialogBackend.mimeTypeFor('a.zip'), 'application/zip');
      expect(
        AndroidFileDialogBackend.mimeTypeFor('quisquislingo_x.user-recovery-key.json'),
        'application/json',
      );
      expect(AndroidFileDialogBackend.mimeTypeFor('noext'),
          'application/octet-stream');
    });

    test('Android gets the document pickers; desktops keep theirs', () {
      expect(
        FileDialogService.backendFor(QqlStoragePlatform.android),
        isA<AndroidFileDialogBackend>(),
      );
      for (final desktop in [
        QqlStoragePlatform.windows,
        QqlStoragePlatform.macos,
        QqlStoragePlatform.linux,
      ]) {
        expect(
          FileDialogService.backendFor(desktop),
          isA<DesktopFileDialogBackend>(),
        );
      }
      expect(
        FileDialogService.backendFor(QqlStoragePlatform.ios).isAvailable,
        isFalse,
      );
    });
  });
}
