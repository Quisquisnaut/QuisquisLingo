/// A Team's shared Google Drive folder link (Build 255 Revision 6).
///
/// Only a link to a Google Drive folder is accepted. A link to a single file,
/// a direct download, another Google service, a shortened link or any other
/// website could lead Team members to download something unsafe, so each is
/// refused. QQL never downloads anything from the folder itself.
abstract final class TeamSharedFolderLink {
  static const maxLength = 500;

  static final _folderId = RegExp(r'^[A-Za-z0-9_-]{10,128}$');
  static final _accountIndex = RegExp(r'^[0-9]{1,2}$');
  static final _resourceKey = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static const _sharingParameters = {
    'sharing',
    'drive_link',
    'share_link',
    'drive_web',
  };

  static const refusal = FormatException(
    'Only a link to a Google Drive folder is accepted, such as '
    'https://drive.google.com/drive/folders/… Links to single files, '
    'downloads, documents, other websites and shortened links are refused.',
  );

  /// The link in its one stored form,
  /// `https://drive.google.com/drive/folders/<ID>`, keeping only a
  /// `resourcekey` the folder needs. Throws [refusal] for anything else.
  static String normalize(String input) {
    final text = input.trim();
    if (text.isEmpty ||
        text.length > maxLength ||
        RegExp(r'\s').hasMatch(text)) {
      throw refusal;
    }
    final uri = Uri.tryParse(text);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.toLowerCase() != 'drive.google.com' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw refusal;
    }
    final segments = [...uri.pathSegments];
    if (segments.isNotEmpty && segments.last.isEmpty) segments.removeLast();
    // drive/folders/<ID>, or drive/u/<account>/folders/<ID> from a browser
    // signed in to several accounts; the account part is not kept.
    final String id;
    if (segments.length == 3 &&
        segments[0] == 'drive' &&
        segments[1] == 'folders') {
      id = segments[2];
    } else if (segments.length == 5 &&
        segments[0] == 'drive' &&
        segments[1] == 'u' &&
        _accountIndex.hasMatch(segments[2]) &&
        segments[3] == 'folders') {
      id = segments[4];
    } else {
      throw refusal;
    }
    if (!_folderId.hasMatch(id)) throw refusal;
    String? resourceKey;
    for (final entry in uri.queryParametersAll.entries) {
      if (entry.value.length != 1) throw refusal;
      final value = entry.value.single;
      switch (entry.key) {
        case 'usp' when _sharingParameters.contains(value):
          break;
        case 'resourcekey' when _resourceKey.hasMatch(value):
          resourceKey = value;
        default:
          throw refusal;
      }
    }
    return Uri(
      scheme: 'https',
      host: 'drive.google.com',
      pathSegments: ['drive', 'folders', id],
      queryParameters: resourceKey == null
          ? null
          : {'resourcekey': resourceKey},
    ).toString();
  }

  /// Whether [value] is a link in its stored form.
  static bool isStored(String value) {
    try {
      return normalize(value) == value;
    } on FormatException {
      return false;
    }
  }
}
