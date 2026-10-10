/// A file in QQL's own bundle (Build 270 Revision 3): `assets/` and
/// segments of letters, digits, `_`, `-` and `.`, none starting with a dot.
/// Before, any text starting with `assets/` was accepted from a Course, so it
/// could name `assets/../…` and send a file outside the bundle through the
/// picture and sound decoders. Every bundled file matches it.
final RegExp bundledAsset = RegExp(r'^assets(/[A-Za-z0-9_-][A-Za-z0-9_.-]*)+$');

bool isBundledAsset(String value) => bundledAsset.hasMatch(value);
