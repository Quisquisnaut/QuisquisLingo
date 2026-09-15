import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';

void main() {
  late WorldFlagManifest manifest;
  late List<WorldFlagEntity> entities;

  setUpAll(() {
    manifest = WorldFlagRepository.parseManifestDocument(
      File('assets/world_flags/manifest.json').readAsStringSync(),
    );
    entities = manifest.entities;
  });

  test('canonical dataset has 249 ISO entities and 193 UN members', () {
    expect(entities, hasLength(281));
    expect(
      entities.where((entity) => entity.isoAlpha2 != null),
      hasLength(249),
    );
    expect(
      entities.where((entity) => entity.category == WorldFlagCategory.unMember),
      hasLength(193),
    );
    expect(
      entities.where((entity) => entity.category == WorldFlagCategory.isoExtra),
      hasLength(56),
    );
    expect(
      entities.singleWhere((entity) => entity.isoAlpha2 == 'AQ').displayNameEn,
      'Antarctica',
    );
  });

  test('shortlist contains exactly the approved eight entities', () {
    expect(
      WorldFlagRepository.referenceFor(
        entities,
        WorldFlagReferenceCategory.shortlist,
      ).map((entity) => entity.displayNameEn).toSet(),
      {
        'England',
        'Scotland',
        'Wales',
        'Kosovo',
        'Northern Ireland',
        'Catalonia',
        'Basque Country',
        'Galicia',
      },
    );
  });

  test('language-related layer contains exactly the approved 24 entries', () {
    const expected = {
      'Sámi',
      'Roma',
      'Sorbian',
      'Breton',
      'Corsican',
      'Occitan',
      'Cornish',
      'Friulian',
      'Sardinian',
      'Esperanto',
      'Amazigh',
      'Ladin',
      'Asturian',
      'Sicilian',
      'Aragonese',
      'Livonian',
      'West Frisian',
      'Piedmontese',
      'Neapolitan',
      'Ligurian',
      'Lombard',
      'Mirandese',
      'Romansh',
      'Venetian',
    };
    final languageEntries = WorldFlagRepository.referenceFor(
      entities,
      WorldFlagReferenceCategory.languageRelatedFlags,
    );
    final languageNames = languageEntries
        .map((entity) => entity.displayNameEn)
        .toSet();
    expect(languageNames, expected);
    expect(
      entities
          .where(
            (entity) =>
                entity.category ==
                WorldFlagCategory.communityOrRegionalFlagAssociatedWithLanguage,
          )
          .every(
            (entity) =>
                entity.artworkSourcePage != null &&
                entity.artworkLicense != null &&
                entity.artworkAuthor != null &&
                entity.artworkSha1 != null,
          ),
      isTrue,
    );
    expect(
      languageNames.intersection({
        'Wales',
        'Catalonia',
        'Basque Country',
        'Galicia',
      }),
      isEmpty,
    );
  });

  test('new QQL 234 normalized SVGs omit renderer-incompatible markup', () {
    const normalizedIds = {
      'aragonese',
      'livonian',
      'piedmontese',
      'sicilian',
      'west_frisian',
    };
    final unsupportedMarkup = RegExp(
      r'<style\b'
      r'|<(?:metadata\b|sodipodi:namedview\b|inkscape:perspective\b)'
      r'|<defs\b[^>]*/>'
      r'|<defs\b[^>]*>\s*</defs>',
      caseSensitive: false,
      dotAll: true,
    );
    for (final id in normalizedIds) {
      final entity = entities.singleWhere((entity) => entity.id == id);
      final svg = File(entity.assetPath).readAsStringSync();
      expect(unsupportedMarkup.hasMatch(svg), isFalse, reason: entity.id);
    }
  });

  test('gameplay pools and reference groups derive from one dataset', () {
    expect(
      WorldFlagRepository.poolFor(entities, FlagGameMode.unMembers),
      hasLength(193),
    );
    expect(
      WorldFlagRepository.poolFor(entities, FlagGameMode.iso),
      hasLength(249),
    );
    expect(
      WorldFlagRepository.poolFor(entities, FlagGameMode.isoPlusShortlist),
      hasLength(257),
    );
    expect(
      WorldFlagRepository.poolFor(entities, FlagGameMode.allFlags),
      hasLength(281),
    );
    expect(
      WorldFlagRepository.referenceFor(
        entities,
        WorldFlagReferenceCategory.isoExtras,
      ),
      hasLength(56),
    );
    expect(
      WorldFlagRepository.poolFor(entities, FlagGameMode.allFlags).where(
        (entity) =>
            entity.category ==
            WorldFlagCategory.communityOrRegionalFlagAssociatedWithLanguage,
      ),
      hasLength(24),
    );
  });

  test('new language-related artwork keeps exact Commons provenance', () {
    const expected = {
      'esperanto': (
        source: 'https://commons.wikimedia.org/wiki/File:Flag_of_Esperanto.svg',
        license: 'Public domain',
        author: 'Richard H. Geoghegan',
        sha1: 'bbac663a2a7de19187c09474b2e095840858930b',
      ),
      'amazigh': (
        source: 'https://commons.wikimedia.org/wiki/File:Berber_flag.svg',
        license: 'Public domain',
        author: 'Mysid',
        sha1: '8be97d4a459f489f59553919068b8a14186d7d20',
      ),
      'ladin': (
        source: 'https://commons.wikimedia.org/wiki/File:Flag_of_Ladinia.svg',
        license: 'Public domain',
        author: 'Unknown, recreated by Sebastian Walderich',
        sha1: '1e3c6dee1f3a05b884ba05b48f45e11e116485f8',
      ),
      'asturian': (
        source: 'https://commons.wikimedia.org/wiki/File:Flag_of_Asturias.svg',
        license: 'Public domain',
        author: 'Banderas',
        sha1: 'caefb74c9ba07d45bc1548887a6d38c5625d0634',
      ),
      'sicilian': (
        source: 'https://commons.wikimedia.org/wiki/File:Flag_of_Sicily.svg',
        license: 'Public domain',
        author: 'Angelo Romano',
        sha1: 'f1ad00b79b6fe206c749c90990b1bbfaef283464',
      ),
      'aragonese': (
        source: 'https://commons.wikimedia.org/wiki/File:Flag_of_Aragon.svg',
        license: 'CC BY-SA 3.0',
        author: 'Willtron',
        sha1: '9816b944df1e0ae53b4ce259f9205ef3718d9840',
      ),
      'livonian': (
        source:
            'https://commons.wikimedia.org/wiki/File:Flag_of_the_Livonians.svg',
        license: 'Public domain',
        author: 'Tasman',
        sha1: 'cbc9caa198419cc1643cb36a1bb2a5c361343b0f',
      ),
      'west_frisian': (
        source: 'https://commons.wikimedia.org/wiki/File:Frisian_flag.svg',
        license: 'Public domain',
        author: 'P.H. Wagemakers and Joh. Koopmans',
        sha1: '6aa077ea90accf0b74ee70b37a9db8351c9cfbcd',
      ),
      'piedmontese': (
        source: 'https://commons.wikimedia.org/wiki/File:Flag_of_Piedmont.svg',
        license: 'Public domain',
        author: 'Orzetto',
        sha1: 'da5571fdf41da8b673d5f5e0fefb1cb7cf41a1b4',
      ),
      'neapolitan': (
        source: 'https://commons.wikimedia.org/wiki/File:Flag_of_Naples.svg',
        license: 'Public domain',
        author: 'Ninane',
        sha1: '9d222f1582d5e8c008a31ae877b01cef277be0ee',
      ),
      'ligurian': (
        source:
            'https://commons.wikimedia.org/wiki/File:Flag_of_Liguria.svg',
        license: 'Public domain',
        author: 'F l a n k e r',
        sha1: 'f628a40a514b97dc03f98fb679376fc5d7b7d01f',
      ),
      'lombard': (
        source:
            'https://commons.wikimedia.org/wiki/File:Flag_of_Lombardy.svg',
        license: 'Public domain',
        author: 'F l a n k e r',
        sha1: 'b1c2c9d5ba5698e5688b0f72b1d4db062808325e',
      ),
      'mirandese': (
        source:
            'https://commons.wikimedia.org/wiki/File:Proposed_flag_of_Miranda_de_l_Douro_(MPB).svg',
        license: 'CC BY 4.0',
        author: 'ItsGandaM1ke',
        sha1: 'a4d22bed14f8b5ce44506b85887919882f5b5782',
      ),
      'romansh': (
        source:
            'https://commons.wikimedia.org/wiki/File:CHE_Kanton_Graub%C3%BCnden_Flag.svg',
        license: 'Public domain',
        author: 'Kanton Graubünden; Anton Nigg',
        sha1: '0a6ac90b85ed1148a2900022165380ae6c98f295',
      ),
      'venetian': (
        source:
            'https://commons.wikimedia.org/wiki/File:Flag_of_Veneto.svg',
        license: 'CC BY-SA 3.0',
        author: 'F l a n k e r',
        sha1: 'd877bcb78d9834b9d22a2446988137d2b0e8ffa5',
      ),
    };
    const normalizedAssetSha1 = {
      'sicilian': 'ef75025c8b94190dba04f1150b5144ca8bde731c',
      'aragonese': '628d53c4eb614631a24ba109c8550dda27cb6ef2',
      'livonian': 'a03c03e6312dac5dd43304d56bc37b8ed57d528c',
      'west_frisian': '150adca2efd9a5fae63118f9fd86bd27c456cfed',
      'piedmontese': 'f6896671a83cf366b3930854da950453f832e9b9',
    };

    for (final entry in expected.entries) {
      final entity = entities.singleWhere((entity) => entity.id == entry.key);
      final expectedAssetSha1 =
          normalizedAssetSha1[entry.key] ?? entry.value.sha1;
      expect(entity.artworkSourcePage, entry.value.source, reason: entry.key);
      expect(entity.artworkLicense, entry.value.license, reason: entry.key);
      expect(entity.artworkAuthor, entry.value.author, reason: entry.key);
      expect(
        entity.artworkSourceSha1 ?? entity.artworkSha1,
        entry.value.sha1,
        reason: entry.key,
      );
      expect(
        entity.artworkSourceSha1,
        normalizedAssetSha1.containsKey(entry.key) ? entry.value.sha1 : isNull,
        reason: entry.key,
      );
      expect(entity.artworkSha1, expectedAssetSha1, reason: entry.key);
      expect(
        sha1.convert(File(entity.assetPath).readAsBytesSync()).toString(),
        expectedAssetSha1,
        reason: entry.key,
      );
    }
  });

  test('language suggestions are ordered and reference known flags', () {
    expect(manifest.languageSuggestions, isNotEmpty);
    final knownIds = entities.map((entity) => entity.id).toSet();
    for (final suggestion in manifest.languageSuggestions) {
      expect(suggestion.languageTag, isNotEmpty);
      expect(suggestion.worldFlagIds, isNotEmpty);
      expect(
        suggestion.worldFlagIds.toSet(),
        hasLength(suggestion.worldFlagIds.length),
      );
      expect(
        suggestion.worldFlagIds.every(knownIds.contains),
        isTrue,
        reason: suggestion.languageTag,
      );
    }

    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'fy_NL',
        languageName: 'West Frisian',
      ).map((entity) => entity.id),
      ['west_frisian', 'netherlands'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageName: 'Frisone',
      ).map((entity) => entity.id),
      ['west_frisian'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'fy',
      ).map((entity) => entity.id),
      ['west_frisian'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'PMS-it',
      ).map((entity) => entity.id),
      ['piedmontese', 'italy'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'pms',
      ).map((entity) => entity.id),
      ['piedmontese'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'nap-IT',
      ).map((entity) => entity.id),
      ['neapolitan', 'italy'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'nap',
      ).map((entity) => entity.id),
      ['neapolitan'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'nap-US',
      ).map((entity) => entity.id),
      ['neapolitan'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageName: '  PIEMONTÈIS  ',
      ).map((entity) => entity.id),
      ['piedmontese'],
    );
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'unknown',
        languageName: 'Not a known language',
      ),
      isEmpty,
    );
  });

  test('full language tag wins over its base-tag suggestion', () {
    final synthetic = WorldFlagManifest(
      entities: entities,
      languageSuggestions: const [
        WorldFlagLanguageSuggestion(
          languageTag: 'xy',
          worldFlagIds: ['esperanto'],
        ),
        WorldFlagLanguageSuggestion(
          languageTag: 'xy-ZZ',
          worldFlagIds: ['neapolitan', 'italy'],
        ),
      ],
    );

    expect(
      WorldFlagRepository.suggestForLanguage(
        synthetic,
        languageTag: 'xy_zz',
      ).map((entity) => entity.id),
      ['neapolitan', 'italy'],
    );
  });

  test('manifest parser rejects an unknown language-suggestion flag ID', () {
    final decoded =
        jsonDecode(File('assets/world_flags/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    decoded['languageSuggestions'] = [
      {
        'languageTag': 'zz',
        'worldFlagIds': ['not_in_the_manifest'],
      },
    ];

    expect(
      () => WorldFlagRepository.parseManifestDocument(jsonEncode(decoded)),
      throwsFormatException,
    );
  });

  test(
    'language-suggestion metadata remains optional for schema v1 readers',
    () {
      final decoded =
          jsonDecode(
                File('assets/world_flags/manifest.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      decoded.remove('languageSuggestions');

      final parsed = WorldFlagRepository.parseManifestDocument(
        jsonEncode(decoded),
      );
      expect(parsed.entities, hasLength(281));
      expect(parsed.languageSuggestions, isEmpty);
      expect(
        WorldFlagRepository.parseManifest(jsonEncode(decoded)),
        hasLength(281),
      );
    },
  );

  test('IDs and English answer labels are unique and all assets exist', () {
    expect(
      entities.map((entity) => entity.id).toSet(),
      hasLength(entities.length),
    );
    expect(
      entities.map((entity) => entity.displayNameEn).toSet(),
      hasLength(entities.length),
    );
    expect(
      entities.map((entity) => entity.assetPath).toSet(),
      hasLength(entities.length),
    );
    for (final entity in entities) {
      expect(File(entity.assetPath).existsSync(), isTrue, reason: entity.id);
      expect(entity.distractorTags, isNotEmpty, reason: entity.id);
    }
    final referencedAssets = entities
        .map((entity) => File(entity.assetPath).absolute.uri)
        .toSet();
    final packagedAssets = Directory('assets/world_flags/flags')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.svg'))
        .map((file) => file.absolute.uri)
        .toSet();
    expect(packagedAssets, referencedAssets);
  });

  test('near-identical exclusions are symmetric', () {
    final byId = {for (final entity in entities) entity.id: entity};
    for (final entity in entities) {
      for (final avoidedId in entity.avoidAsDistractorWith) {
        expect(byId[avoidedId], isNotNull);
        expect(byId[avoidedId]!.avoidAsDistractorWith, contains(entity.id));
      }
    }
    expect(byId['romania']!.avoidAsDistractorWith, contains('chad'));
    expect(byId['monaco']!.avoidAsDistractorWith, contains('indonesia'));
    expect(byId['aragonese']!.avoidAsDistractorWith, contains('catalonia'));
  });

  test('language flag color tags include representative painted colors', () {
    final byId = {for (final entity in entities) entity.id: entity};
    expect(
      byId['corsican']!.distractorTags,
      containsAll({'color:black', 'color:white'}),
    );
    expect(
      byId['occitan']!.distractorTags,
      containsAll({'color:red', 'color:yellow'}),
    );
    expect(
      byId['japan']!.distractorTags,
      containsAll({'color:red', 'color:white'}),
    );
  });

  test('US and UM use 50 renderer-compatible explicit stars', () {
    for (final expected in {
      'united_states': 'US',
      'united_states_minor_outlying_islands': 'UM',
    }.entries) {
      final entity = entities.singleWhere(
        (entity) => entity.id == expected.key,
      );
      expect(entity.isoAlpha2, expected.value);
      expect(entity.assetPath, 'assets/world_flags/flags/${expected.key}.svg');
      final svg = File(entity.assetPath).readAsStringSync();
      expect(svg, contains('viewBox="0 0 640 480"'));
      expect(svg, contains('fill="#192f5d"'));
      expect(svg, contains('stroke="#fff"'));
      expect(svg, isNot(contains('<marker')));
      expect(svg, isNot(contains('marker-mid=')));
      expect(
        RegExp(
          '<path d="m14 0 9 27L0 10h28L5 27z" transform="translate\\(',
        ).allMatches(svg),
        hasLength(50),
      );
    }
  });

  test('world-flag assets contain no active SVG marker constructs', () {
    final activeMarkerAttribute = RegExp(
      r'''marker-(?:mid|start|end)\s*=\s*["'](?!none["'])''',
      caseSensitive: false,
    );
    for (final file in Directory('assets/world_flags/flags').listSync()) {
      if (file is! File || !file.path.endsWith('.svg')) continue;
      final svg = file.readAsStringSync();
      expect(svg, isNot(matches(RegExp(r'<marker\b', caseSensitive: false))));
      expect(svg, isNot(matches(activeMarkerAttribute)));
    }
  });

  test('legacy course flag namespace remains separate and unchanged', () {
    expect(CourseFlagService.builtInFlags['CY'], 'Welsh');
    expect(CourseFlagService.builtInFlags['EN'], 'English');
    expect(CourseFlagService.builtInFlags['IT'], 'Italian');
    expect(
      entities.singleWhere((entity) => entity.isoAlpha2 == 'CY').displayNameEn,
      'Cyprus',
    );
    expect(
      entities.singleWhere((entity) => entity.isoAlpha2 == 'GB').displayNameEn,
      'United Kingdom',
    );
  });
}
