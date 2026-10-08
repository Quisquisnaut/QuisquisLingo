import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PathBackend implements FileDialogBackend, DesktopPathFileDialogBackend {
  FileDialogPathResult next = const FileDialogPathResult.cancelled();
  Object? error;
  final requests = <({List<String> extensions, String? initialDirectory})>[];

  @override
  bool get isAvailable => true;

  @override
  bool get supportsInitialDirectory => true;

  @override
  Future<FileDialogPathResult> pickDesktopPath({
    required List<String> extensions,
    String? initialDirectory,
  }) async {
    requests.add((extensions: extensions, initialDirectory: initialDirectory));
    if (error != null) throw error!;
    return next;
  }

  @override
  Future<FileDialogPick> pickFiles({
    required List<String> extensions,
    required bool multiple,
    String? initialDirectory,
  }) => throw UnimplementedError();

  @override
  Future<FileDialogResult> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required List<String> extensions,
    String? initialDirectory,
  }) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _PathBackend backend;
  late Directory downloads;
  late FileDialogService dialogs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    backend = _PathBackend();
    downloads = await Directory.systemTemp.createTemp('qql_tools_picker_');
    dialogs = FileDialogService(
      backend: backend,
      downloadsDirectory: () async => downloads,
    );
  });

  tearDown(() async {
    await downloads.delete(recursive: true);
  });

  test(
    'returns the original Course path and starts the first dialog in Downloads',
    () async {
      const path = r'C:\Users\Ada\Course files\sample course.zip';
      backend.next = FileDialogPathResult.picked(path);

      final result = await dialogs.pickDesktopPath(
        extensions: const ['json', 'zip'],
        artifact: 'qql-tools-course',
      );

      expect(result.outcome, FileDialogOutcome.opened);
      expect(result.path, path);
      expect(result.displayName, 'sample course.zip');
      expect(backend.requests.single.extensions, ['json', 'zip']);
      expect(backend.requests.single.initialDirectory, downloads.path);
    },
  );

  test(
    'executable selection permits no extension filter and cancellation is quiet',
    () async {
      final first = await dialogs.pickDesktopPath(
        extensions: const [],
        artifact: 'qql-tools-executable',
      );
      final second = await dialogs.pickDesktopPath(
        extensions: const [],
        artifact: 'qql-tools-executable',
      );

      expect(first.outcome, FileDialogOutcome.cancelled);
      expect(first.path, isNull);
      expect(second.outcome, FileDialogOutcome.cancelled);
      expect(backend.requests.map((request) => request.extensions), [[], []]);
      expect(backend.requests.map((request) => request.initialDirectory), [
        downloads.path,
        null,
      ]);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quisquislingo_diagnostic_log'), isNull);
    },
  );

  test('picker failure keeps full paths out of diagnostics', () async {
    backend.error = FileSystemException(
      'Access denied',
      r'C:\Users\Ada\Secret folder\qql-tools.exe',
      const OSError('Access denied', 5),
    );

    final result = await dialogs.pickDesktopPath(
      extensions: const [],
      artifact: 'qql-tools-executable',
    );

    expect(result.outcome, FileDialogOutcome.failed);
    expect(result.path, isNull);
    final prefs = await SharedPreferences.getInstance();
    final log = prefs.getString('quisquislingo_diagnostic_log')!;
    expect(log, contains('FILE-001'));
    expect(log, isNot(contains('Secret folder')));
  });

  test('unavailable backend exposes no path', () async {
    final result =
        await FileDialogService(
          backend: const UnavailableFileDialogBackend(),
          downloadsDirectory: () async => downloads,
        ).pickDesktopPath(
          extensions: const ['json', 'zip'],
          artifact: 'qql-tools-course',
        );

    expect(result.outcome, FileDialogOutcome.unavailable);
    expect(result.path, isNull);
  });
}
