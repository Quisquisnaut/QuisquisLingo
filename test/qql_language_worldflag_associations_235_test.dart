import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/language_flag_catalog.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';

void main() {
  test('reviewed associations retain their authoritative order', () {
    expect(
      LanguageFlagCatalog.worldAssociations
          .take(98)
          .map((association) => association.languageName)
          .toList(),
      _reviewedLanguageOrder,
    );
  });

  test('English and regional exceptions use the reviewed WorldFlags', () {
    expect(
      LanguageFlagCatalog.worldAssociationFor(
        languageName: 'English',
      )?.worldFlagIds,
      [
        'united_kingdom',
        'united_states',
        'australia',
        'canada',
        'new_zealand',
        'south_africa',
        'india',
        'ireland',
      ],
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(
        languageName: 'Catalan',
      )?.worldFlagIds.first,
      'catalonia',
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(
        languageName: 'Basque',
      )?.worldFlagIds.first,
      'basque_country',
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(
        languageName: 'Galician',
      )?.worldFlagIds.first,
      'galicia',
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(
        languageName: 'Welsh',
      )?.worldFlagIds.first,
      'wales',
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(
        languageName: 'Scottish Gaelic',
      )?.worldFlagIds.first,
      'scotland',
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(
        languageName: 'Scots',
      )?.worldFlagIds.first,
      'scotland',
    );
  });

  test('aliases and language tags resolve without involving FlagPainter', () {
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageName: 'Bangla'),
      'bangladesh',
    );
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageName: 'Kalaallisut'),
      'greenland',
    );
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageTag: 'gd-GB'),
      'scotland',
    );
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageTag: 'cy-GB'),
      'wales',
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(languageTag: 'lij')?.worldFlagIds,
      ['ligurian', 'italy'],
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(languageTag: 'lmo')?.worldFlagIds,
      ['lombard', 'italy'],
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(languageTag: 'mwl')?.worldFlagIds,
      ['mirandese', 'portugal'],
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(languageTag: 'rm')?.worldFlagIds,
      ['romansh', 'switzerland'],
    );
    expect(
      LanguageFlagCatalog.worldAssociationFor(languageTag: 'vec')?.worldFlagIds,
      ['venetian', 'italy'],
    );
  });

  test('all materialized association IDs exist in the WorldFlag manifest', () {
    final manifest = WorldFlagRepository.parseManifestDocument(
      File('assets/world_flags/manifest.json').readAsStringSync(),
    );
    final ids = manifest.entities.map((entity) => entity.id).toSet();
    for (final association in LanguageFlagCatalog.worldAssociations) {
      expect(
        association.worldFlagIds.every(ids.contains),
        isTrue,
        reason: association.languageName,
      );
    }
  });
}

const _reviewedLanguageOrder = <String>[
  'Afrikaans',
  'Albanian',
  'Amharic',
  'Arabic',
  'Aragonese',
  'Armenian',
  'Asturian',
  'Azerbaijani',
  'Basque',
  'Belarusian',
  'Bengali',
  'Bosnian',
  'Breton',
  'Bulgarian',
  'Burmese',
  'Cantonese',
  'Catalan',
  'Chinese',
  'Chinese (Traditional)',
  'Corsican',
  'Croatian',
  'Czech',
  'Danish',
  'Dutch',
  'English',
  'Estonian',
  'Faroese',
  'Finnish',
  'Flemish',
  'French',
  'Friulian',
  'Galician',
  'Georgian',
  'German',
  'Greek',
  'Greenlandic',
  'Hebrew',
  'Hindi',
  'Hungarian',
  'Icelandic',
  'Indonesian',
  'Irish',
  'Italian',
  'Japanese',
  'Khmer',
  'Korean',
  'Lao',
  'Latvian',
  'Ligurian',
  'Lithuanian',
  'Lombard',
  'Luxembourgish',
  'Macedonian',
  'Malay',
  'Maltese',
  'Mirandese',
  'Māori',
  'Neapolitan',
  'Nepali',
  'Norwegian',
  'Norwegian Bokmål',
  'Norwegian Nynorsk',
  'Occitan',
  'Pashto',
  'Persian',
  'Piedmontese',
  'Polish',
  'Portuguese',
  'Punjabi',
  'Romanian',
  'Romansh',
  'Russian',
  'Sardinian',
  'Scots',
  'Scottish Gaelic',
  'Serbian',
  'Sicilian',
  'Sinhala',
  'Slovak',
  'Slovenian',
  'Somali',
  'Spanish',
  'Swahili',
  'Swati',
  'Swedish',
  'Tamil',
  'Thai',
  'Tongan',
  'Tswana',
  'Turkish',
  'Ukrainian',
  'Urdu',
  'Venetian',
  'Vietnamese',
  'Welsh',
  'West Frisian',
  'Xhosa',
  'Zulu',
];
