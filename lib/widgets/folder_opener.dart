import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a folder in the system's file manager (Build 266 Revision 2: the
/// Debug screen's Save&Open and the Inventory's Open folder). Offered on
/// Windows, macOS and Linux only; Android and iOS cannot open a folder for
/// people reliably.
abstract final class FolderOpener {
  /// Whether this system can open a folder (a test seam).
  static bool Function() available = () =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Opens [folder]; false when the system refused (a test seam).
  static Future<bool> Function(String folder) open = (folder) =>
      launchUrl(Uri.directory(folder));
}
