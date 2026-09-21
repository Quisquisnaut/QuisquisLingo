import 'dart:convert';
import 'dart:typed_data';

/// What kind of web page a file turned out to be.
enum WebPageKind {
  /// A site's "your download is starting" page.
  downloadPage,
  page,
}

/// The kind of web page [bytes] are, or null when they are not HTML.
///
/// A failed or redirected download often saves the site's web page under the
/// name of the file that was meant to arrive. Saying so is more useful than
/// "not a valid file".
WebPageKind? webPageKind(Uint8List bytes) {
  // Skip a UTF-8 byte-order mark, then read the start as ASCII.
  final start =
      bytes.length >= 3 &&
          bytes[0] == 0xef &&
          bytes[1] == 0xbb &&
          bytes[2] == 0xbf
      ? 3
      : 0;
  final end = bytes.length < start + 4096 ? bytes.length : start + 4096;
  final head = ascii
      .decode(bytes.sublist(start, end), allowInvalid: true)
      .trimLeft()
      .toLowerCase();
  final isPage =
      head.startsWith('<!doctype html') ||
      head.startsWith('<html') ||
      (head.startsWith('<!--') && head.contains('<html'));
  if (!isPage) return null;
  final title = RegExp(r'<title>([^<]*)</title>').firstMatch(head)?.group(1);
  final redirect =
      RegExp(r'''http-equiv\s*=\s*["']?refresh''').hasMatch(head) ||
      (title?.contains('download') ?? false) ||
      (title?.contains('redirect') ?? false);
  return redirect ? WebPageKind.downloadPage : WebPageKind.page;
}
