import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';

void main() {
  late List<WorldFlagEntity> entities;

  setUpAll(() {
    entities = WorldFlagRepository.parseManifest(
      File('assets/world_flags/manifest.json').readAsStringSync(),
    );
  });

  test('canonical dataset has 249 ISO entities and 193 UN members', () {
    expect(entities, hasLength(266));
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

  test('language-related layer contains exactly the approved nine entries', () {
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
      hasLength(266),
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
      hasLength(9),
    );
  });

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
      expect(
        entity.assetPath,
        'assets/world_flags/flags/${expected.key}.svg',
      );
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
    expect(CourseFlagService.builtInFlags['CY'], 'Wales');
    expect(CourseFlagService.builtInFlags['EN'], 'United Kingdom / English');
    expect(CourseFlagService.builtInFlags['IT'], 'Italy');
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
