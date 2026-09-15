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
  final List<String> worldFlagIds;

  String? get primaryWorldFlagId =>
      worldFlagIds.isEmpty ? null : worldFlagIds.first;

  const LanguageWorldFlagAssociation({
    required this.languageName,
    required this.languageAliases,
    required this.languageCodes,
    required this.worldFlagIds,
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
      languageName: 'Afrikaans',
      languageAliases: [],
      languageCodes: ['af'],
      worldFlagIds: ['south_africa', 'namibia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Albanian',
      languageAliases: [],
      languageCodes: ['sq', 'sqi'],
      worldFlagIds: ['albania', 'kosovo', 'north_macedonia_republic_of'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Amharic',
      languageAliases: [],
      languageCodes: ['am', 'amh'],
      worldFlagIds: ['ethiopia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Arabic',
      languageAliases: [],
      languageCodes: ['ar', 'ara'],
      worldFlagIds: [
        'saudi_arabia',
        'egypt',
        'algeria',
        'sudan',
        'iraq',
        'yemen',
        'morocco',
        'syria',
        'jordan',
        'tunisia',
        'united_arab_emirates',
        'libya',
        'palestine',
        'lebanon',
        'oman',
        'kuwait',
        'qatar',
        'bahrain',
        'mauritania',
        'chad',
        'somalia',
        'comoros',
        'djibouti',
        'eritrea',
        'western_sahara',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Aragonese',
      languageAliases: ['Aragonés'],
      languageCodes: ['an', 'arg'],
      worldFlagIds: ['aragonese', 'spain'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Armenian',
      languageAliases: [],
      languageCodes: ['hy', 'hye'],
      worldFlagIds: ['armenia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Asturian',
      languageAliases: ['Asturianu'],
      languageCodes: ['ast'],
      worldFlagIds: ['asturian', 'spain'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Azerbaijani',
      languageAliases: [],
      languageCodes: ['az', 'aze'],
      worldFlagIds: ['azerbaijan'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Basque',
      languageAliases: [],
      languageCodes: ['eu', 'eus'],
      worldFlagIds: ['basque_country', 'spain'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Belarusian',
      languageAliases: [],
      languageCodes: ['be', 'bel'],
      worldFlagIds: ['belarus'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Bengali',
      languageAliases: ['Bangla'],
      languageCodes: ['bn', 'ben'],
      worldFlagIds: ['bangladesh', 'india'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Bosnian',
      languageAliases: [],
      languageCodes: ['bs', 'bos'],
      worldFlagIds: ['bosnia_and_herzegowina'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Breton',
      languageAliases: ['Brezhoneg'],
      languageCodes: ['br', 'bre'],
      worldFlagIds: ['breton', 'france'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Bulgarian',
      languageAliases: [],
      languageCodes: ['bg', 'bul'],
      worldFlagIds: ['bulgaria'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Burmese',
      languageAliases: [],
      languageCodes: ['my', 'mya'],
      worldFlagIds: ['myanmar'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Cantonese',
      languageAliases: [],
      languageCodes: ['yue'],
      worldFlagIds: ['hong_kong', 'macao', 'china'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Catalan',
      languageAliases: [],
      languageCodes: ['ca', 'cat'],
      worldFlagIds: ['catalonia', 'andorra', 'spain'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Chinese',
      languageAliases: [],
      languageCodes: ['zh', 'zho'],
      worldFlagIds: ['china', 'taiwan', 'singapore', 'hong_kong', 'macao'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Chinese (Traditional)',
      languageAliases: ['Traditional Chinese'],
      languageCodes: ['zh-Hant'],
      worldFlagIds: ['taiwan', 'hong_kong', 'macao'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Corsican',
      languageAliases: ['Corsu'],
      languageCodes: ['co', 'cos'],
      worldFlagIds: ['corsican', 'france'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Croatian',
      languageAliases: [],
      languageCodes: ['hr', 'hrv'],
      worldFlagIds: ['croatia_local_name_hrvatska', 'bosnia_and_herzegowina'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Czech',
      languageAliases: [],
      languageCodes: ['cs', 'ces'],
      worldFlagIds: ['czechia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Danish',
      languageAliases: ['Dansk'],
      languageCodes: ['da', 'dan'],
      worldFlagIds: ['denmark'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Dutch',
      languageAliases: [],
      languageCodes: ['nl', 'nld', 'dut'],
      worldFlagIds: [
        'netherlands',
        'belgium',
        'suriname',
        'aruba',
        'cura_ao',
        'sint_maarten_dutch_part',
        'bonaire_sint_eustatius_and_saba',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'English',
      languageAliases: [],
      languageCodes: ['en', 'eng'],
      worldFlagIds: [
        'united_kingdom',
        'united_states',
        'australia',
        'canada',
        'new_zealand',
        'south_africa',
        'india',
        'ireland',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Estonian',
      languageAliases: [],
      languageCodes: ['et', 'est'],
      worldFlagIds: ['estonia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Faroese',
      languageAliases: [],
      languageCodes: ['fo', 'fao'],
      worldFlagIds: ['faroe_islands'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Finnish',
      languageAliases: [],
      languageCodes: ['fi', 'fin'],
      worldFlagIds: ['finland', 'sweden'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Flemish',
      languageAliases: [],
      languageCodes: ['vls'],
      worldFlagIds: ['belgium'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'French',
      languageAliases: ['Français'],
      languageCodes: ['fr', 'fra', 'fre'],
      worldFlagIds: [
        'france',
        'canada',
        'belgium',
        'switzerland',
        'luxembourg',
        'monaco',
        'democratic_republic_of_the_congo',
        'cameroon',
        'cote_d_ivoire',
        'senegal',
        'madagascar',
        'burundi',
        'benin',
        'burkina_faso',
        'guinea',
        'republic_of_the_congo',
        'togo',
        'niger',
        'chad',
        'gabon',
        'central_african_republic',
        'rwanda',
        'haiti',
        'djibouti',
        'comoros',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Friulian',
      languageAliases: ['Furlan'],
      languageCodes: ['fur'],
      worldFlagIds: ['friulian', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Galician',
      languageAliases: [],
      languageCodes: ['gl', 'glg'],
      worldFlagIds: ['galicia', 'spain'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Georgian',
      languageAliases: [],
      languageCodes: ['ka', 'kat'],
      worldFlagIds: ['georgia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'German',
      languageAliases: [],
      languageCodes: ['de', 'deu', 'ger'],
      worldFlagIds: [
        'germany',
        'austria',
        'switzerland',
        'belgium',
        'liechtenstein',
        'luxembourg',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Greek',
      languageAliases: [],
      languageCodes: ['el', 'ell'],
      worldFlagIds: ['greece', 'cyprus'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Greenlandic',
      languageAliases: ['Kalaallisut'],
      languageCodes: ['kl', 'kal'],
      worldFlagIds: ['greenland'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Hebrew',
      languageAliases: [],
      languageCodes: ['he', 'heb'],
      worldFlagIds: ['israel'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Hindi',
      languageAliases: [],
      languageCodes: ['hi', 'hin'],
      worldFlagIds: ['india'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Hungarian',
      languageAliases: [],
      languageCodes: ['hu', 'hun'],
      worldFlagIds: ['hungary', 'romania', 'serbia', 'slovakia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Icelandic',
      languageAliases: [],
      languageCodes: ['is', 'isl'],
      worldFlagIds: ['iceland'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Indonesian',
      languageAliases: [],
      languageCodes: ['id', 'ind'],
      worldFlagIds: ['indonesia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Irish',
      languageAliases: [],
      languageCodes: ['ga', 'gle'],
      worldFlagIds: ['ireland', 'united_kingdom'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Italian',
      languageAliases: [],
      languageCodes: ['it', 'ita'],
      worldFlagIds: ['italy', 'switzerland', 'san_marino', 'vatican_city'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Japanese',
      languageAliases: [],
      languageCodes: ['ja', 'jpn'],
      worldFlagIds: ['japan'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Khmer',
      languageAliases: [],
      languageCodes: ['km', 'khm'],
      worldFlagIds: ['cambodia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Korean',
      languageAliases: [],
      languageCodes: ['ko', 'kor'],
      worldFlagIds: ['south_korea', 'north_korea'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Lao',
      languageAliases: [],
      languageCodes: ['lo', 'lao'],
      worldFlagIds: ['laos'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Latvian',
      languageAliases: [],
      languageCodes: ['lv', 'lav'],
      worldFlagIds: ['latvia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Ligurian',
      languageAliases: [],
      languageCodes: ['lij'],
      worldFlagIds: ['ligurian', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Lithuanian',
      languageAliases: [],
      languageCodes: ['lt', 'lit'],
      worldFlagIds: ['lithuania'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Lombard',
      languageAliases: [],
      languageCodes: ['lmo'],
      worldFlagIds: ['lombard', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Luxembourgish',
      languageAliases: [],
      languageCodes: ['lb', 'ltz'],
      worldFlagIds: ['luxembourg'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Macedonian',
      languageAliases: [],
      languageCodes: ['mk', 'mkd'],
      worldFlagIds: ['north_macedonia_republic_of'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Malay',
      languageAliases: [],
      languageCodes: ['ms', 'msa', 'may'],
      worldFlagIds: ['malaysia', 'brunei', 'singapore'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Maltese',
      languageAliases: [],
      languageCodes: ['mt', 'mlt'],
      worldFlagIds: ['malta'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Mirandese',
      languageAliases: [],
      languageCodes: ['mwl'],
      worldFlagIds: ['mirandese', 'portugal'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Māori',
      languageAliases: ['Maori'],
      languageCodes: ['mi', 'mri', 'mao'],
      worldFlagIds: ['new_zealand'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Neapolitan',
      languageAliases: ['Napoletano', 'Napulitano', 'Partenopeo'],
      languageCodes: ['nap'],
      worldFlagIds: ['neapolitan', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Nepali',
      languageAliases: [],
      languageCodes: ['ne', 'nep'],
      worldFlagIds: ['nepal', 'india'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Norwegian',
      languageAliases: [],
      languageCodes: ['no', 'nor'],
      worldFlagIds: ['norway'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Norwegian Bokmål',
      languageAliases: [],
      languageCodes: ['nb'],
      worldFlagIds: ['norway'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Norwegian Nynorsk',
      languageAliases: [],
      languageCodes: ['nn'],
      worldFlagIds: ['norway'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Occitan',
      languageAliases: ['Lenga d\'òc'],
      languageCodes: ['oc', 'oci'],
      worldFlagIds: ['occitan', 'france', 'spain'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Pashto',
      languageAliases: [],
      languageCodes: ['ps', 'pus'],
      worldFlagIds: ['afghanistan', 'pakistan'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Persian',
      languageAliases: [],
      languageCodes: ['fa', 'fas', 'per'],
      worldFlagIds: ['iran', 'afghanistan'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Piedmontese',
      languageAliases: ['Piemontese', 'Piemontèis'],
      languageCodes: ['pms'],
      worldFlagIds: ['piedmontese', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Polish',
      languageAliases: [],
      languageCodes: ['pl', 'pol'],
      worldFlagIds: ['poland'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Portuguese',
      languageAliases: [],
      languageCodes: ['pt', 'por'],
      worldFlagIds: [
        'portugal',
        'brazil',
        'angola',
        'mozambique',
        'guinea_bissau',
        'cape_verde',
        'sao_tome_and_principe',
        'timor_leste',
        'macao',
        'equatorial_guinea',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Punjabi',
      languageAliases: [],
      languageCodes: ['pa', 'pan'],
      worldFlagIds: ['india', 'pakistan'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Romanian',
      languageAliases: [],
      languageCodes: ['ro', 'ron', 'rum'],
      worldFlagIds: ['romania', 'moldova'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Romansh',
      languageAliases: [],
      languageCodes: ['rm', 'roh'],
      worldFlagIds: ['romansh', 'switzerland'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Russian',
      languageAliases: [],
      languageCodes: ['ru', 'rus'],
      worldFlagIds: ['russia', 'belarus', 'kazakhstan', 'kyrgyzstan'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sardinian',
      languageAliases: ['Sardu'],
      languageCodes: ['sc', 'srd'],
      worldFlagIds: ['sardinian', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Scots',
      languageAliases: ['Scotch'],
      languageCodes: ['sco'],
      worldFlagIds: ['scotland', 'united_kingdom'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Scottish Gaelic',
      languageAliases: ['Gàidhlig'],
      languageCodes: ['gd', 'gla'],
      worldFlagIds: ['scotland', 'united_kingdom'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Serbian',
      languageAliases: [],
      languageCodes: ['sr', 'srp'],
      worldFlagIds: [
        'serbia',
        'bosnia_and_herzegowina',
        'kosovo',
        'montenegro',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sicilian',
      languageAliases: ['Sicilianu'],
      languageCodes: ['scn'],
      worldFlagIds: ['sicilian', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sinhala',
      languageAliases: [],
      languageCodes: ['si', 'sin'],
      worldFlagIds: ['sri_lanka'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Slovak',
      languageAliases: [],
      languageCodes: ['sk', 'slk'],
      worldFlagIds: ['slovakia'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Slovenian',
      languageAliases: [],
      languageCodes: ['sl', 'slv'],
      worldFlagIds: ['slovenia', 'austria', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Somali',
      languageAliases: [],
      languageCodes: ['so', 'som'],
      worldFlagIds: ['somalia', 'djibouti', 'ethiopia', 'kenya'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Spanish',
      languageAliases: [],
      languageCodes: ['es', 'spa'],
      worldFlagIds: [
        'spain',
        'mexico',
        'argentina',
        'colombia',
        'venezuela',
        'peru',
        'chile',
        'ecuador',
        'guatemala',
        'cuba',
        'honduras',
        'dominican_republic',
        'bolivia',
        'el_salvador',
        'nicaragua',
        'paraguay',
        'costa_rica',
        'panama',
        'uruguay',
        'equatorial_guinea',
        'puerto_rico',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Swahili',
      languageAliases: [],
      languageCodes: ['sw', 'swa'],
      worldFlagIds: [
        'tanzania',
        'kenya',
        'uganda',
        'democratic_republic_of_the_congo',
      ],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Swati',
      languageAliases: [],
      languageCodes: ['ss', 'ssw'],
      worldFlagIds: ['swaziland', 'south_africa'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Swedish',
      languageAliases: [],
      languageCodes: ['sv', 'swe'],
      worldFlagIds: ['sweden', 'finland', 'aland_islands'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Tamil',
      languageAliases: [],
      languageCodes: ['ta', 'tam'],
      worldFlagIds: ['india', 'sri_lanka', 'singapore'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Thai',
      languageAliases: [],
      languageCodes: ['th', 'tha'],
      worldFlagIds: ['thailand'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Tongan',
      languageAliases: [],
      languageCodes: ['to', 'ton'],
      worldFlagIds: ['tonga'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Tswana',
      languageAliases: [],
      languageCodes: ['tn', 'tsn'],
      worldFlagIds: ['botswana', 'south_africa'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Turkish',
      languageAliases: ['Türkçe'],
      languageCodes: ['tr', 'tur'],
      worldFlagIds: ['t_rki_ye', 'cyprus'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Ukrainian',
      languageAliases: [],
      languageCodes: ['uk', 'ukr'],
      worldFlagIds: ['ukraine'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Urdu',
      languageAliases: [],
      languageCodes: ['ur', 'urd'],
      worldFlagIds: ['pakistan', 'india'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Venetian',
      languageAliases: [],
      languageCodes: ['vec'],
      worldFlagIds: ['venetian', 'italy'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Vietnamese',
      languageAliases: ['Tiếng Việt'],
      languageCodes: ['vi', 'vie'],
      worldFlagIds: ['viet_nam'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Welsh',
      languageAliases: [],
      languageCodes: ['cy', 'cym', 'wel'],
      worldFlagIds: ['wales', 'united_kingdom'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'West Frisian',
      languageAliases: ['Frisian', 'Frysk', 'Frisone'],
      languageCodes: ['fy', 'fry'],
      worldFlagIds: ['west_frisian', 'netherlands'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Xhosa',
      languageAliases: [],
      languageCodes: ['xh', 'xho'],
      worldFlagIds: ['south_africa'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Zulu',
      languageAliases: [],
      languageCodes: ['zu', 'zul'],
      worldFlagIds: ['south_africa'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Amazigh',
      languageAliases: ['Berber', 'Imazighen', 'Tamazight'],
      languageCodes: ['ber'],
      worldFlagIds: ['amazigh'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Esperanto',
      languageAliases: [],
      languageCodes: ['eo', 'epo'],
      worldFlagIds: ['esperanto'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Kabyle',
      languageAliases: ['Taqbaylit'],
      languageCodes: ['kab'],
      worldFlagIds: ['amazigh'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Cornish',
      languageAliases: ['Kernewek'],
      languageCodes: ['kw', 'cor'],
      worldFlagIds: ['cornish'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Livonian',
      languageAliases: ['Līvõ kēļ'],
      languageCodes: ['liv'],
      worldFlagIds: ['livonian'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Ladin',
      languageAliases: ['Ladinia'],
      languageCodes: ['lld'],
      worldFlagIds: ['ladin'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Romani',
      languageAliases: ['Roma language'],
      languageCodes: ['rom'],
      worldFlagIds: ['roma'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Northern Sami',
      languageAliases: ['Northern Sámi', 'Davvisámegiella'],
      languageCodes: ['se', 'sme'],
      worldFlagIds: ['sami'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sámi languages',
      languageAliases: ['Sámi', 'Sami', 'Saami', 'Sami languages'],
      languageCodes: ['smi'],
      worldFlagIds: ['sami'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Standard Moroccan Tamazight',
      languageAliases: [],
      languageCodes: ['zgh'],
      worldFlagIds: ['amazigh'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Lower Sorbian',
      languageAliases: ['Dolnoserbski'],
      languageCodes: ['dsb'],
      worldFlagIds: ['sorbian'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Upper Sorbian',
      languageAliases: ['Hornjoserbsce'],
      languageCodes: ['hsb'],
      worldFlagIds: ['sorbian'],
    ),
    LanguageWorldFlagAssociation(
      languageName: 'Sorbian',
      languageAliases: ['Sorbs', 'Sorbian languages'],
      languageCodes: ['wen'],
      worldFlagIds: ['sorbian'],
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
