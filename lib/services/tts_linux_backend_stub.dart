import 'tts_language_resolver.dart';

String? linuxTtsVoiceForLanguage(String language) {
  final normalized = TtsLanguageResolver.normalize(language);
  if (normalized == null) return null;
  final base = normalized.split('-').first.toLowerCase();
  return base == 'en' ? 'en-gb' : base;
}

Future<bool> speakWithLinuxTts({
  required String text,
  required String language,
  required double rate,
}) async {
  return false;
}
