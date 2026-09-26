import 'dart:io';

import 'package:flutter/material.dart';

import '../services/file_dialog_service.dart';
import '../services/storage/qql_storage.dart';

/// One place that turns a [FileDialogResult] into the message the user sees.
///
/// * saved: [savedMessage]
/// * cancelled: nothing at all
/// * failed / unavailable: what went wrong plus [fallbackHint], which points
///   at the ordinary Quick action. The Quick folder is only offered, never
///   used silently.
///
/// An opened file is not handled here: the caller validates it like any
/// other import and reports validation errors itself.
void showFileDialogFeedback(
  BuildContext context,
  FileDialogResult result, {
  String savedMessage = '',
  required String fallbackHint,
  required bool saving,
}) {
  final String message;
  var isError = true;
  switch (result.outcome) {
    case FileDialogOutcome.cancelled:
    case FileDialogOutcome.opened:
      return;
    case FileDialogOutcome.saved:
      message = savedMessage;
      isError = false;
    case FileDialogOutcome.failed:
      message =
          '${saving ? 'Couldn’t save to that location.' : 'Couldn’t open that file.'} '
          '$fallbackHint';
    case FileDialogOutcome.unavailable:
      message = 'The system file dialog is not available here. $fallbackHint';
    case FileDialogOutcome.tooLarge:
      message = '${result.displayName ?? 'That file'} is too large to import. Choose a smaller file and try again.';
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 10),
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

/// Explains that QQL never signs in to a cloud service: the system dialog
/// lists a cloud folder only if the device already shows it. [operatingSystem]
/// is injectable for tests; it defaults to the current platform.
String cloudFolderHelpText({String? operatingSystem}) {
  final os = operatingSystem ?? Platform.operatingSystem;
  final String how;
  switch (os) {
    case 'android':
      how =
          'On Android, install the provider’s app (for example Google Drive) '
          'and sign in to it once. Then open the menu (three lines) at the '
          'top left of the file picker and choose it. If it is missing, '
          'open its app, sign in and try again.';
    case 'windows':
      how =
          'On Windows, install and sign in to the provider’s desktop app '
          '(for example Google Drive for desktop or OneDrive). The cloud '
          'then appears as an ordinary drive or folder in the dialog.';
    case 'macos':
      how =
          'On a Mac, install and sign in to the provider’s app (for example '
          'Google Drive for desktop or iCloud Drive). It then appears in the '
          'sidebar of the dialog.';
    case 'linux':
      how =
          'On Linux, add the account in your desktop’s Online Accounts, or '
          'use a sync client, so the cloud folder is mounted. Then it '
          'appears in the dialog. Without that, save to a normal folder and '
          'sync it yourself.';
    default:
      how = 'Sign in to the provider on this device first.';
  }
  return 'Cloud folders such as Google Drive appear in this dialog only if '
      'this device already shows them. QQL does not sign in to any cloud '
      'service. $how';
}

String _folder(QqlStorageRole role) =>
    QqlStorageLayout.current.folderLabel(role);

String _file(QqlStorageRole role, String name) =>
    QqlStorageLayout.current.fileLabel(role, name);

/// Quick-folder fallback wording. The folders are named for the current
/// platform, the same way the screens name them.
String get exportFallbackHint =>
    'You can use Quick Export instead; it saves to '
    '${_folder(QqlStorageRole.courseExports)}.';
String get userDataExportFallbackHint =>
    'You can use Export instead; it saves to '
    '${_folder(QqlStorageRole.learnerDataExports)}.';
String get mp3FallbackHint =>
    'Copy the MP3 to ${_folder(QqlStorageRole.audioImports)} and use Import '
    'MP3 instead.';
String get exerciseImageFallbackHint =>
    'Copy one image to ${_folder(QqlStorageRole.imageImports)} and use '
    'Import custom image (or Import single image) instead.';
String get lessonIconFallbackHint =>
    'Copy one image to ${_folder(QqlStorageRole.lessonIconImports)} and use '
    'Import custom icon instead.';
String get userDataImportFallbackHint =>
    'Copy the file to '
    '${_file(QqlStorageRole.learnerDataImports, 'learner_import.json')} '
    'and use Import my data instead.';
String get recoveryKeyImportFallbackHint =>
    'Copy the key file to ${_folder(QqlStorageRole.recoveryKeyImports)} and '
    'use Import User Recovery Key instead.';
String get imageBankFallbackHint =>
    'Copy the ZIP to ${_folder(QqlStorageRole.imageImports)} (only one ZIP '
    'there) and use Import Image Bank ZIP instead.';
String get mergeImportFallbackHint =>
    'Copy the package to ${_file(QqlStorageRole.mergeImports, 'merge.zip')} '
    '(or a media-free JSON to merge.json) and use Merge Course package or '
    'JSON instead.';
String get courseImportFallbackHint =>
    'Copy the package to ${_file(QqlStorageRole.courseImports, 'import.zip')} '
    '(or a media-free JSON to import.json) and use Quick Import instead.';
