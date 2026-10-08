import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/bundled_image_catalog.dart';

// Build 265 Revision 10 (owner decisions of 7 October 2026): historical
// figures and landmarks from more places. Columbus leaves, every figure and
// landmark carries its country as a tag, and figures with sensitive
// histories or with name and likeness rights still enforced stay out.

/// Every new figure: label and file name.
const _newFigures = {
  'simon_bolivar': 'Simón Bolívar',
  'diego_velazquez': 'Diego Velázquez',
  'gabriela_mistral': 'Gabriela Mistral',
  'luis_de_camoes': 'Luís de Camões',
  'alberto_santos_dumont': 'Alberto Santos-Dumont',
  'fernando_pessoa': 'Fernando Pessoa',
  'rembrandt': 'Rembrandt',
  'vincent_van_gogh': 'Vincent van Gogh',
  'erasmus': 'Erasmus',
  'johannes_gutenberg': 'Johannes Gutenberg',
  'bach': 'Bach',
  'clara_schumann': 'Clara Schumann',
  'louis_xiv': 'Louis XIV',
  'victor_hugo': 'Victor Hugo',
  'louis_pasteur': 'Louis Pasteur',
  'abraham_lincoln': 'Abraham Lincoln',
  'queen_victoria': 'Queen Victoria',
  'florence_nightingale': 'Florence Nightingale',
  'jane_austen': 'Jane Austen',
  'tutankhamun': 'Tutankhamun',
  'catherine_the_great': 'Catherine the Great',
  'hokusai': 'Hokusai',
  'murasaki_shikibu': 'Murasaki Shikibu',
  'ibn_battuta': 'Ibn Battuta',
  'mansa_musa': 'Mansa Musa',
  'genghis_khan': 'Genghis Khan',
  'jackson_pollock': 'Jackson Pollock',
  'king_sejong': 'King Sejong',
  'al_khwarizmi': 'Al-Khwarizmi',
  'nicolaus_copernicus': 'Nicolaus Copernicus',
  'hans_christian_andersen': 'Hans Christian Andersen',
  'leif_erikson': 'Leif Erikson',
  'james_watt': 'James Watt',
  'adolphe_sax': 'Adolphe Sax',
  'leo_tolstoy': 'Leo Tolstoy',
  'queen_nzinga': 'Queen Nzinga',
  'benito_juarez': 'Benito Juárez',
  'benjamin_franklin': 'Benjamin Franklin',
  'zheng_he': 'Zheng He',
  'trung_sisters': 'Trưng Sisters',
};

/// Every new landmark: label and file name.
const _newLandmarks = {
  'big_ben': 'Big Ben',
  'tower_bridge': 'Tower Bridge',
  'stonehenge': 'Stonehenge',
  'arc_de_triomphe': 'Arc de Triomphe',
  'brandenburg_gate': 'Brandenburg Gate',
  'neuschwanstein_castle': 'Neuschwanstein Castle',
  'amsterdam_canal_houses': 'Amsterdam canal houses',
  'alhambra': 'Alhambra',
  'belem_tower': 'Belém Tower',
  'rialto_bridge': 'Rialto Bridge',
  'parthenon': 'Parthenon',
  'kremlin': 'Kremlin',
  'mount_fuji': 'Mount Fuji',
  'forbidden_city': 'Forbidden City',
  'gyeongbokgung_palace': 'Gyeongbokgung Palace',
  'machu_picchu': 'Machu Picchu',
  'chichen_itza': 'Chichén Itzá',
  'sugarloaf_mountain': 'Sugarloaf Mountain',
  'golden_gate_bridge': 'Golden Gate Bridge',
  'niagara_falls': 'Niagara Falls',
  'petra': 'Petra',
  'mount_kilimanjaro': 'Mount Kilimanjaro',
};

/// The countries the figures and landmarks are tagged with, as people name
/// them today.
const _countries = {
  'angola',
  'austria',
  'belgium',
  'brazil',
  'canada',
  'chile',
  'china',
  'denmark',
  'egypt',
  'england',
  'france',
  'germany',
  'greece',
  'iceland',
  'india',
  'iraq',
  'italy',
  'japan',
  'jordan',
  'korea',
  'mali',
  'mexico',
  'mongolia',
  'morocco',
  'netherlands',
  'norway',
  'peru',
  'poland',
  'portugal',
  'russia',
  'scotland',
  'south korea',
  'spain',
  'tanzania',
  'united kingdom',
  'united states',
  'usa',
  'uzbekistan',
  'venezuela',
  'vietnam',
};

void main() {
  final records = readBundledImageRecords();
  final figures = [
    for (final r in records)
      if (r['category'] == 'historical_figures') r,
  ];
  final byId = {for (final r in figures) r['id'] as String: r};
  Set<String> keysOf(Map<String, dynamic> r) =>
      (r['tags'] as List).cast<String>().map(imageWordKey).toSet();

  test('the forty new figures are in the catalog with five tags or more', () {
    for (final MapEntry(key: file, value: label) in _newFigures.entries) {
      final record = byId['historical_figures_$file'];
      expect(record, isNotNull, reason: file);
      expect(record!['label'], label);
      expect(record['assetPath'], 'assets/exercise_images/$file.webp');
      expect((record['tags'] as List).length, greaterThanOrEqualTo(5));
    }
    expect(figures, hasLength(26 + _newFigures.length));
  });

  test('Columbus has left the catalog and the bundle', () {
    expect(byId['historical_figures_christopher_columbus'], isNull);
    expect(
      File('assets/exercise_images/christopher_columbus.webp').existsSync(),
      isFalse,
    );
  });

  test('every figure carries its country, Alexander the Great none', () {
    for (final r in figures) {
      final keys = keysOf(r);
      if (r['id'] == 'historical_figures_alexander_the_great') {
        // Greece and North Macedonia both claim him (owner decision).
        expect(keys.intersection(_countries), isEmpty);
        expect(keys, containsAll(['ancient greece', 'macedonian']));
        continue;
      }
      expect(
        keys.intersection(_countries),
        isNotEmpty,
        reason: '${r['id']}: ${r['tags']}',
      );
    }
  });

  test(
    'the twenty-two new landmarks are in the catalog with their country',
    () {
      for (final MapEntry(key: file, value: label) in _newLandmarks.entries) {
        final record = records
            .where((r) => r['id'] == 'landmarks_$file')
            .singleOrNull;
        expect(record, isNotNull, reason: file);
        expect(record!['label'], label);
        expect(record['category'], 'landmarks');
        expect(record['assetPath'], 'assets/exercise_images/$file.webp');
        expect((record['tags'] as List).length, greaterThanOrEqualTo(5));
        expect(
          keysOf(record).intersection(_countries),
          isNotEmpty,
          reason: file,
        );
      }
      expect(
        records.where((r) => r['category'] == 'landmarks'),
        hasLength(8 + _newLandmarks.length),
      );
    },
  );

  test('figures left out stay out', () {
    // Name and likeness rights still enforced, or a sensitive history.
    const excluded = [
      'einstein',
      'picasso',
      'frida kahlo',
      'martin luther',
      'anne frank',
      'sitting bull',
      'moctezuma',
      'montezuma',
      'columbus',
    ];
    for (final r in records) {
      final words = [
        imageWordKey(r['label'] as String),
        ...(r['tags'] as List).cast<String>().map(imageWordKey),
      ].join(' | ');
      for (final name in excluded) {
        expect(words, isNot(contains(name)), reason: '${r['id']}: $name');
      }
    }
  });
}
