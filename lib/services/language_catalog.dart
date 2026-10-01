import '../localization/language_names.dart';
import 'exercise_search_service.dart';

part 'language_catalog_entries.dart';

/// One language a Course can be written from or teach (Build 260 Revision 0,
/// owner decisions of 1 October 2026).
class LanguageEntry {
  const LanguageEntry(this.tag, this.englishName, [this.aliases = const []]);

  /// The language's tag: an ISO 639-1 code (`it`) or, for a regional or
  /// minority language, an ISO 639-3 code (`nap`).
  final String tag;

  /// The name the selector shows and a new Course stores.
  final String englishName;

  /// Other names (native names, earlier English names) by which an earlier
  /// Course may have written the language.
  final List<String> aliases;

  String get label => '$englishName ($tag)';
}

/// The languages New Course and Course Info list by their English name: the
/// two-letter ISO 639-1 languages and a curated set of three-letter regional
/// and minority languages. A language not in the list is entered by hand,
/// with a name and an optional tag ([isValidTag]).
abstract final class LanguageCatalog {
  static const List<LanguageEntry> entries = _languageEntries;

  static final Map<String, LanguageEntry> _byTag = {
    for (final entry in entries) entry.tag: entry,
  };

  /// Every name a language is recognized by (English name, aliases, and its
  /// names in the instruction languages), normalized, to its entry. The
  /// English names come first, so they win a clash ("Ladino" is Judeo-
  /// Spanish, not Ladin).
  static final Map<String, LanguageEntry> _byName = () {
    final map = <String, LanguageEntry>{};
    void add(String name, LanguageEntry entry) => map.putIfAbsent(
      ExerciseSearchService.normalize(name.trim()),
      () => entry,
    );
    for (final entry in entries) {
      add(entry.englishName, entry);
    }
    for (final entry in entries) {
      for (final alias in entry.aliases) {
        add(alias, entry);
      }
    }
    for (final names in languageNamesByInstructionLanguage.values) {
      for (final MapEntry(key: tag, value: name) in names.entries) {
        final entry = _byTag[tag];
        if (entry != null) add(name, entry);
      }
    }
    return map;
  }();

  static final RegExp _tagPattern = RegExp(
    r'^[a-zA-Z]{2,3}(-[a-zA-Z0-9]{2,8})*$',
  );

  /// Whether [tag] has the shape of a language tag (`nap`, `pt-BR`,
  /// `zh-Hans`); a hand-entered language's tag must.
  static bool isValidTag(String tag) => _tagPattern.hasMatch(tag.trim());

  /// The entry of [tag] (`it`, `nap`), or of its primary language
  /// (`pt-BR` → Portuguese), whatever its capitals.
  static LanguageEntry? byTag(String tag) {
    final normalized = tag.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    return _byTag[normalized] ?? _byTag[normalized.split('-').first];
  }

  /// The entry [text] names: a tag, an English name, an alias or a name in
  /// an instruction language, ignoring capitals and accents.
  static LanguageEntry? resolve(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    if (isValidTag(value)) {
      final tagged = byTag(value);
      if (tagged != null) return tagged;
    }
    return _byName[ExerciseSearchService.normalize(value)];
  }

  /// The tag a Course side uses: its stored [tag] when it has the right
  /// shape, else the tag of the language its [name] (or [fallbackName])
  /// names, else null.
  static String? tagFor({
    required String tag,
    required String name,
    String fallbackName = '',
  }) {
    if (isValidTag(tag)) return tag.trim();
    return resolve(name)?.tag ?? resolve(fallbackName)?.tag;
  }

  /// The entries whose English name, tag or aliases contain [query].
  static List<LanguageEntry> search(String query) {
    final needle = ExerciseSearchService.normalize(query.trim());
    if (needle.isEmpty) return entries;
    return [
      for (final entry in entries)
        if (ExerciseSearchService.normalize(
              entry.englishName,
            ).contains(needle) ||
            entry.tag.contains(needle) ||
            entry.aliases.any(
              (alias) =>
                  ExerciseSearchService.normalize(alias).contains(needle),
            ))
          entry,
    ];
  }

  /// The name of the language [tag] inside a line in the instruction
  /// language [instructionLanguage], or null when QQL does not know it.
  /// Norwegian Bokmål and Nynorsk use the Norwegian name.
  static String? nameIn(String instructionLanguage, String tag) {
    final names = languageNamesByInstructionLanguage[instructionLanguage];
    if (names == null) return null;
    final normalized = tag.trim().toLowerCase();
    final primary = normalized.split('-').first;
    return names[normalized] ??
        names[primary] ??
        (primary == 'nb' || primary == 'nn' ? names['no'] : null);
  }
}
