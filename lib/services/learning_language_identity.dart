/// Canonical learner-language identity used by language-scoped progress.
///
/// Region, country, orthography, pronunciation and TTS subtags do not create a
/// second learning language. Persistence keeps the existing uppercase key
/// suffixes while learner-facing canonical IDs use lowercase ISO-style codes.
class LearningLanguageIdentity {
  static const Map<String, String> _idsByName = {
    'cymraeg': 'cy',
    'deutsch': 'de',
    'dutch': 'nl',
    'english': 'en',
    'español': 'es',
    'finnish': 'fi',
    'german': 'de',
    'italian': 'it',
    'italiano': 'it',
    'korean': 'ko',
    'nederlands': 'nl',
    'portuguese': 'pt',
    'português': 'pt',
    'spanish': 'es',
    'suomi': 'fi',
    'welsh': 'cy',
  };

  static const Map<String, String> _namesById = {
    'cy': 'Welsh',
    'de': 'German',
    'en': 'English',
    'es': 'Spanish',
    'fi': 'Finnish',
    'it': 'Italian',
    'ko': 'Korean',
    'nl': 'Dutch',
    'pt': 'Portuguese',
  };

  const LearningLanguageIdentity._();

  static String canonicalId(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    if (normalized.isEmpty) return '';
    final named = _idsByName[normalized];
    if (named != null) return named;
    final base = normalized.split('-').first;
    return _idsByName[base] ?? base;
  }

  static String storageId(String value) => canonicalId(value).toUpperCase();

  static String displayName(String canonicalId) {
    final id = LearningLanguageIdentity.canonicalId(canonicalId);
    return _namesById[id] ?? id.toUpperCase();
  }

  static String flagCode(String canonicalId) =>
      storageId(canonicalId) == 'EN' ? 'EN' : storageId(canonicalId);
}
