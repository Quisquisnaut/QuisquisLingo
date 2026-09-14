import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_flag_catalog_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';

void main() {
  test(
    'Italian automatic selection prefers the permanent QQL design',
    () async {
      final manifest = WorldFlagRepository.parseManifestDocument(
        File('assets/world_flags/manifest.json').readAsStringSync(),
      );
      final catalog = await CourseFlagCatalogService().build(
        languageName: 'Italian',
        languageTag: 'it-IT',
        manifest: manifest,
      );

      expect(catalog.automaticCandidate?.identity, 'qql-flagpainter-italian');
      expect(catalog.suggestedWorldFlag?.identity, 'world:italy');
      expect(catalog.sections.map((section) => section.kind), const [
        CourseFlagCatalogSectionKind.qqlFlagPainter,
        CourseFlagCatalogSectionKind.worldFlags,
      ]);
    },
  );

  test(
    'catalog search preserves exact subdivision and language aliases',
    () async {
      final manifest = WorldFlagRepository.parseManifestDocument(
        File('assets/world_flags/manifest.json').readAsStringSync(),
      );
      final catalog = await CourseFlagCatalogService().build(
        languageName: 'Unknown',
        manifest: manifest,
      );

      expect(
        catalog
            .search('GB-WLS')
            .expand((section) => section.candidates)
            .map((candidate) => candidate.identity),
        ['world:wales'],
      );
      expect(
        catalog
            .search('Partenopeo')
            .expand((section) => section.candidates)
            .map((candidate) => candidate.identity),
        contains('world:neapolitan'),
      );
    },
  );

  test('Course selection preserves exactly one portable v9 source', () {
    final source = _course(worldFlagId: 'neapolitan');
    final selection = CourseFlagSelection.fromCourse(source);
    final changed = selection.applyToJson({
      ...source.toJson(),
      'flagCode': 'ES',
      'flagImageBase64': 'encoded-image',
    });
    expect(changed['worldFlagId'], 'neapolitan');
    expect(changed['flagCode'], '');
    expect(changed['flagImageBase64'], '');
    expect((const CourseFlagSelection.automatic()).applyToJson(changed), {
      ...changed,
      'flagCode': '',
      'flagImageBase64': '',
      'worldFlagId': '',
    });
  });
}

Course _course({String worldFlagId = ''}) => Course(
  courseId: 'world-source',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'World source',
  ttsLanguage: 'it-IT',
  worldFlagId: worldFlagId,
  lessons: const [],
);
