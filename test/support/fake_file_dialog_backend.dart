import 'dart:typed_data';

import 'dart:io';

import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/import/selected_external_file.dart';

/// A stager that uses a temporary folder instead of app storage.
ImportStager testImportStager() => ImportStager(
  supportDirectory: () async =>
      Directory.systemTemp.createTemp('qql_test_import_support_'),
);

/// Scriptable stand-in for the system dialog. Records what it was asked to do.
class FakeFileDialogBackend implements FileDialogBackend {
  Future<FileDialogResult> Function(Uint8List bytes, String name)? onSave;
  Future<FileDialogResult> Function()? onOpen;

  /// Files returned for a multiple selection.
  List<SelectedExternalFile>? onOpenMany;
  final saved = <({Uint8List bytes, String name})>[];
  final startedIn = <String?>[];
  bool supportsStart = false;

  @override
  bool get isAvailable => true;

  @override
  bool get supportsInitialDirectory => supportsStart;

  @override
  Future<FileDialogResult> saveBytes({
    required Uint8List bytes,
    required String suggestedName,
    required List<String> extensions,
    String? initialDirectory,
  }) async {
    startedIn.add(initialDirectory);
    saved.add((bytes: bytes, name: suggestedName));
    return onSave != null
        ? onSave!(bytes, suggestedName)
        : FileDialogResult.saved(suggestedName);
  }

  @override
  Future<FileDialogPick> pickFiles({
    required List<String> extensions,
    required bool multiple,
    String? initialDirectory,
  }) async {
    startedIn.add(initialDirectory);
    if (multiple && onOpenMany != null) {
      return FileDialogPick.picked(onOpenMany!);
    }
    final result = onOpen != null
        ? await onOpen!()
        : const FileDialogResult.cancelled();
    return switch (result.outcome) {
      FileDialogOutcome.opened => FileDialogPick.picked([
        MemorySelectedFile(result.displayName!, result.bytes!),
      ]),
      FileDialogOutcome.cancelled => const FileDialogPick.cancelled(),
      FileDialogOutcome.unavailable => const FileDialogPick.unavailable(),
      _ => FileDialogPick.failed(result.failureReason ?? 'failed'),
    };
  }
}
