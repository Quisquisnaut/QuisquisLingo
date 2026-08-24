/// Selects QuisquisLingo's existing System.Speech path instead of registering the
/// native flutter_tts Windows plugin.
class QuisquisLingoFlutterTtsWindows {
  /// Windows speech is handled by the app's System.Speech backend.
  static void registerWith() {}
}
