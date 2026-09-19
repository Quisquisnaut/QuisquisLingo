import 'dart:typed_data';

import 'package:quisquislingo_app/services/file_dialog_service.dart';

/// Scriptable stand-in for the system dialog. Records what it was asked to do.
class FakeFileDialogBackend implements FileDialogBackend {
  Future<FileDialogResult> Function(Uint8List bytes, String name)? onSave;
  Future<FileDialogResult> Function()? onOpen;
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
  Future<FileDialogResult> openBytes({
    required List<String> extensions,
    required int maxBytes,
    String? initialDirectory,
  }) async {
    startedIn.add(initialDirectory);
    return onOpen != null ? onOpen!() : const FileDialogResult.cancelled();
  }
}
