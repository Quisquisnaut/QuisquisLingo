class QqlFlagPainterFlag {
  final String id;
  final String displayName;
  final String languageName;
  final List<String> languageAliases;
  final List<String> languageCodes;
  final String painterCode;
  final Set<String> painterCases;

  const QqlFlagPainterFlag({
    required this.id,
    required this.displayName,
    required this.languageName,
    required this.languageAliases,
    required this.languageCodes,
    required this.painterCode,
    required this.painterCases,
  });

  Iterable<String> get searchTerms sync* {
    yield id;
    yield displayName;
    yield languageName;
    yield* languageAliases;
    yield* languageCodes;
    yield painterCode;
    yield* painterCases;
  }
}

class LanguageWorldFlagAssociation {
  final String languageName;
  final List<String> languageAliases;
  final List<String> languageCodes;
  final String primaryWorldFlagId;

  const LanguageWorldFlagAssociation({
    required this.languageName,
    required this.languageAliases,
    required this.languageCodes,
    required this.primaryWorldFlagId,
  });

  Iterable<String> get searchTerms sync* {
    yield languageName;
    yield* languageAliases;
    yield* languageCodes;
  }
}

/// Permanent language-to-flag knowledge owned by QQL.
///
/// It is deliberately independent of bundled, imported and custom Courses.
abstract final class LanguageFlagCatalog {
  static const qqlFlagPainterFlags = <QqlFlagPainterFlag>[
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-dutch',
      displayName: 'Dutch',
      languageName: 'Dutch',
      languageAliases: ['Nederlands'],
      languageCodes: ['nl', 'nld', 'dut'],
      painterCode: 'NL',
      painterCases: {'NL'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-english',
      displayName: 'English',
      languageName: 'English',
      languageAliases: [],
      languageCodes: ['en', 'eng'],
      painterCode: 'EN',
      painterCases: {'EN', 'UK'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-finnish',
      displayName: 'Finnish',
      languageName: 'Finnish',
      languageAliases: ['Suomi'],
      languageCodes: ['fi', 'fin'],
      painterCode: 'FI',
      painterCases: {'FI'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-german',
      displayName: 'German',
      languageName: 'German',
      languageAliases: ['Deutsch'],
      languageCodes: ['de', 'deu', 'ger'],
      painterCode: 'DE',
      painterCases: {'DE'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-italian',
      displayName: 'Italian',
      languageName: 'Italian',
      languageAliases: ['Italiano'],
      languageCodes: ['it', 'ita'],
      painterCode: 'IT',
      painterCases: {'IT'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-japanese',
      displayName: 'Japanese',
      languageName: 'Japanese',
      languageAliases: ['Nihongo', '日本語'],
      languageCodes: ['ja', 'jpn'],
      painterCode: 'JA',
      painterCases: {'JA', 'JP'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-korean',
      displayName: 'Korean',
      languageName: 'Korean',
      languageAliases: ['Hanguk-eo', '한국어'],
      languageCodes: ['ko', 'kor'],
      painterCode: 'KO',
      painterCases: {'KO', 'KR'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-portuguese',
      displayName: 'Portuguese',
      languageName: 'Portuguese',
      languageAliases: ['Português'],
      languageCodes: ['pt', 'por'],
      painterCode: 'PT',
      painterCases: {'PT'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-spanish',
      displayName: 'Spanish',
      languageName: 'Spanish',
      languageAliases: ['Español'],
      languageCodes: ['es', 'spa'],
      painterCode: 'ES',
      painterCases: {'ES'},
    ),
    QqlFlagPainterFlag(
      id: 'qql-flagpainter-welsh',
      displayName: 'Welsh',
      languageName: 'Welsh',
      languageAliases: ['Cymraeg'],
      languageCodes: ['cy', 'cym', 'wel'],
      painterCode: 'CY',
      painterCases: {'CY'},
    ),
  ];

  static const worldAssociations = <LanguageWorldFlagAssociation>[
    LanguageWorldFlagAssociation(
      languageName: 'Aragonese',
      languageAliases: ['Aragonés'],
      languageCodes: ['an', 'arg'],
      primaryWorldFlagId: 'aragonese',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Asturian',
      languageAliases: ['Asturianu'],
      languageCodes: ['ast'],
      primaryWorldFlagId: 'asturian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Amazigh',
      languageAliases: ['Berber', 'Imazighen', 'Tamazight'],
      languageCodes: ['ber'],
      primaryWorldFlagId: 'amazigh',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Breton',
      languageAliases: ['Brezhoneg'],
      languageCodes: ['br', 'bre'],
      primaryWorldFlagId: 'breton',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Corsican',
      languageAliases: ['Corsu'],
      languageCodes: ['co', 'cos'],
      primaryWorldFlagId: 'corsican',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Welsh',
      languageAliases: ['Cymraeg'],
      languageCodes: ['cy', 'cym', 'wel'],
      primaryWorldFlagId: 'wales',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Danish',
      languageAliases: ['Dansk'],
      languageCodes: ['da', 'dan'],
      primaryWorldFlagId: 'denmark',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'German',
      languageAliases: ['Deutsch'],
      languageCodes: ['de', 'deu', 'ger'],
      primaryWorldFlagId: 'germany',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Lower Sorbian',
      languageAliases: ['Dolnoserbski'],
      languageCodes: ['dsb'],
      primaryWorldFlagId: 'sorbian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Upper Sorbian',
      languageAliases: ['Hornjoserbsce'],
      languageCodes: ['hsb'],
      primaryWorldFlagId: 'sorbian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sorbian',
      languageAliases: ['Sorbs', 'Sorbian languages'],
      languageCodes: ['wen'],
      primaryWorldFlagId: 'sorbian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'English',
      languageAliases: [],
      languageCodes: ['en', 'eng'],
      primaryWorldFlagId: 'united_kingdom',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Esperanto',
      languageAliases: [],
      languageCodes: ['eo', 'epo'],
      primaryWorldFlagId: 'esperanto',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Spanish',
      languageAliases: ['Español'],
      languageCodes: ['es', 'spa'],
      primaryWorldFlagId: 'spain',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Finnish',
      languageAliases: ['Suomi'],
      languageCodes: ['fi', 'fin'],
      primaryWorldFlagId: 'finland',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'French',
      languageAliases: ['Français'],
      languageCodes: ['fr', 'fra', 'fre'],
      primaryWorldFlagId: 'france',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Friulian',
      languageAliases: ['Furlan'],
      languageCodes: ['fur'],
      primaryWorldFlagId: 'friulian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'West Frisian',
      languageAliases: ['Frisian', 'Frysk', 'Frisone'],
      languageCodes: ['fy', 'fry'],
      primaryWorldFlagId: 'west_frisian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Italian',
      languageAliases: ['Italiano'],
      languageCodes: ['it', 'ita'],
      primaryWorldFlagId: 'italy',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Kabyle',
      languageAliases: ['Taqbaylit'],
      languageCodes: ['kab'],
      primaryWorldFlagId: 'amazigh',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Japanese',
      languageAliases: ['Nihongo', '日本語'],
      languageCodes: ['ja', 'jpn'],
      primaryWorldFlagId: 'japan',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Korean',
      languageAliases: ['Hanguk-eo', '한국어'],
      languageCodes: ['ko', 'kor'],
      primaryWorldFlagId: 'south_korea',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Cornish',
      languageAliases: ['Kernewek'],
      languageCodes: ['kw', 'cor'],
      primaryWorldFlagId: 'cornish',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Livonian',
      languageAliases: ['Līvõ kēļ'],
      languageCodes: ['liv'],
      primaryWorldFlagId: 'livonian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Ladin',
      languageAliases: ['Ladinia'],
      languageCodes: ['lld'],
      primaryWorldFlagId: 'ladin',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Neapolitan',
      languageAliases: ['Napoletano', 'Napulitano', 'Partenopeo'],
      languageCodes: ['nap'],
      primaryWorldFlagId: 'neapolitan',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Dutch',
      languageAliases: ['Nederlands'],
      languageCodes: ['nl', 'nld', 'dut'],
      primaryWorldFlagId: 'netherlands',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Occitan',
      languageAliases: ["Lenga d'òc"],
      languageCodes: ['oc', 'oci'],
      primaryWorldFlagId: 'occitan',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Piedmontese',
      languageAliases: ['Piemontese', 'Piemontèis'],
      languageCodes: ['pms'],
      primaryWorldFlagId: 'piedmontese',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Portuguese',
      languageAliases: ['Português'],
      languageCodes: ['pt', 'por'],
      primaryWorldFlagId: 'portugal',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Romani',
      languageAliases: ['Roma language'],
      languageCodes: ['rom'],
      primaryWorldFlagId: 'roma',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sardinian',
      languageAliases: ['Sardu'],
      languageCodes: ['sc', 'srd'],
      primaryWorldFlagId: 'sardinian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sicilian',
      languageAliases: ['Sicilianu'],
      languageCodes: ['scn'],
      primaryWorldFlagId: 'sicilian',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Northern Sami',
      languageAliases: ['Northern Sámi', 'Davvisámegiella'],
      languageCodes: ['se', 'sme'],
      primaryWorldFlagId: 'sami',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sámi languages',
      languageAliases: ['Sámi', 'Sami', 'Saami', 'Sami languages'],
      languageCodes: ['smi'],
      primaryWorldFlagId: 'sami',
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Standard Moroccan Tamazight',
      languageAliases: [],
      languageCodes: ['zgh'],
      primaryWorldFlagId: 'amazigh',
    ),
  ];

  static final Map<String, String> builtInLabelsByPainterCase =
      Map.unmodifiable({
        for (final flag in qqlFlagPainterFlags)
          for (final painterCase in flag.painterCases)
            painterCase: flag.displayName,
      });

  static final Set<String> renderablePainterCases = Set.unmodifiable(
    qqlFlagPainterFlags.expand((flag) => flag.painterCases),
  );

  static QqlFlagPainterFlag? qqlFlagFor({
    String? languageTag,
    String? languageName,
  }) => _find(
    qqlFlagPainterFlags,
    languageTag: languageTag,
    languageName: languageName,
    codes: (flag) => flag.languageCodes,
    names: (flag) => [flag.languageName, ...flag.languageAliases],
  );

  static QqlFlagPainterFlag? qqlFlagForPainterCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final flag in qqlFlagPainterFlags) {
      if (flag.painterCases.contains(normalized)) return flag;
    }
    return null;
  }

  static LanguageWorldFlagAssociation? worldAssociationFor({
    String? languageTag,
    String? languageName,
  }) => _find(
    worldAssociations,
    languageTag: languageTag,
    languageName: languageName,
    codes: (association) => association.languageCodes,
    names: (association) => [
      association.languageName,
      ...association.languageAliases,
    ],
  );

  static String? primaryWorldFlagId({
    String? languageTag,
    String? languageName,
  }) => worldAssociationFor(
    languageTag: languageTag,
    languageName: languageName,
  )?.primaryWorldFlagId;

  static T? _find<T>(
    Iterable<T> entries, {
    required String? languageTag,
    required String? languageName,
    required Iterable<String> Function(T entry) codes,
    required Iterable<String> Function(T entry) names,
  }) {
    final tag = _normalizeTag(languageTag ?? '');
    if (tag.isNotEmpty) {
      final base = tag.split('-').first;
      for (final entry in entries) {
        if (codes(entry).any((code) => _normalizeTag(code) == base)) {
          return entry;
        }
      }
    }
    final name = _normalizeName(languageName ?? '');
    if (name.isNotEmpty) {
      for (final entry in entries) {
        if (names(
          entry,
        ).any((candidate) => _normalizeName(candidate) == name)) {
          return entry;
        }
      }
    }
    return null;
  }

  static String _normalizeTag(String value) =>
      value.trim().toLowerCase().replaceAll('_', '-');

  static String _normalizeName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
