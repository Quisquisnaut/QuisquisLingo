import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/language_flag_catalog.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('permanent FlagPainter catalog exposes every unique design once', () {
    expect(
      LanguageFlagCatalog.qqlFlagPainterFlags
          .map((flag) => (flag.id, flag.painterCode, flag.painterCases))
          .toList(),
      const [
        ('qql-flagpainter-dutch', 'NL', {'NL'}),
        ('qql-flagpainter-english', 'EN', {'EN', 'UK'}),
        ('qql-flagpainter-finnish', 'FI', {'FI'}),
        ('qql-flagpainter-german', 'DE', {'DE'}),
        ('qql-flagpainter-italian', 'IT', {'IT'}),
        ('qql-flagpainter-japanese', 'JA', {'JA', 'JP'}),
        ('qql-flagpainter-korean', 'KO', {'KO', 'KR'}),
        ('qql-flagpainter-portuguese', 'PT', {'PT'}),
        ('qql-flagpainter-spanish', 'ES', {'ES'}),
        ('qql-flagpainter-welsh', 'CY', {'CY'}),
      ],
    );
    expect(
      LanguageFlagCatalog.qqlFlagPainterFlags
          .expand((flag) => flag.painterCases)
          .toSet(),
      CourseFlagService.renderableBuiltInCodes,
    );
  });

  testWidgets('every permanent FlagPainter definition renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final flag in LanguageFlagCatalog.qqlFlagPainterFlags)
              FlagBadge(
                flag.painterCode,
                key: ValueKey(flag.id),
                width: 120,
                height: 80,
              ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    for (final flag in LanguageFlagCatalog.qqlFlagPainterFlags) {
      expect(find.byKey(ValueKey(flag.id)), findsOneWidget);
    }
  });

  testWidgets('writes authoritative FlagPainter inventory and contact sheet', (
    tester,
  ) async {
    const contactSheetFont = 'QqlContactSheet';
    final windowsFont = File(r'C:\Windows\Fonts\segoeui.ttf');
    final hasContactSheetFont = windowsFont.existsSync();
    if (hasContactSheetFont) {
      final fontBytes = windowsFont.readAsBytesSync();
      await (FontLoader(contactSheetFont)..addFont(
            Future.value(
              ByteData.view(
                fontBytes.buffer,
                fontBytes.offsetInBytes,
                fontBytes.lengthInBytes,
              ),
            ),
          ))
          .load();
    }
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final courses = <Course>[];
    for (final assetPath in CourseService.courseAssets.values) {
      courses.add(
        Course.fromJson(
          jsonDecode(File(assetPath).readAsStringSync())
              as Map<String, dynamic>,
        ),
      );
    }
    final inventory = <Map<String, Object>>[];
    for (final flag in LanguageFlagCatalog.qqlFlagPainterFlags) {
      final usedBy = <String>[];
      for (final course in courses) {
        final resolved = CourseFlagService.resolve(course);
        if (resolved.kind == ResolvedCourseFlagKind.builtIn &&
            LanguageFlagCatalog.qqlFlagForPainterCode(
                  resolved.identifier,
                )?.id ==
                flag.id) {
          usedBy.add(course.title);
        }
      }
      inventory.add({
        'id': flag.id,
        'displayName': flag.displayName,
        'language': flag.languageName,
        'aliases': flag.languageAliases,
        'languageCodes': flag.languageCodes,
        'flagPainterIdentifier': flag.painterCode,
        'flagPainterCases': flag.painterCases.toList()..sort(),
        'bundledCoursesUsing': usedBy..sort(),
        'rendersSuccessfully': true,
      });
    }

    const boundaryKey = ValueKey('flagpainter-contact-sheet');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(
                  width: 1100,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final flag
                            in LanguageFlagCatalog.qqlFlagPainterFlags)
                          SizedBox(
                            width: 194,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FlagBadge(
                                  flag.painterCode,
                                  width: 194,
                                  height: 116,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  flag.displayName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: contactSheetFont,
                                  ),
                                ),
                                Text(
                                  flag.id,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 11,
                                    fontFamily: contactSheetFont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      return image.toByteData(format: ui.ImageByteFormat.png);
    });
    expect(bytes, isNotNull);

    final output = Directory('build/validation')..createSync(recursive: true);
    File(
      '${output.path}/qql_flagpainter_flags_contact_sheet.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    final flagPainterJson = const JsonEncoder.withIndent('  ').convert({
      'catalog': 'QQL FlagPainter Flags',
      'generatedFrom':
          'LanguageFlagCatalog.qqlFlagPainterFlags and FlagPainter',
      'entries': inventory,
    });
    File(
      '${output.path}/qql_flagpainter_flags_inventory.json',
    ).writeAsStringSync('$flagPainterJson\n');
    final worldFlagsJson = const JsonEncoder.withIndent('  ').convert({
      'associations': [
        for (final association in LanguageFlagCatalog.worldAssociations)
          {
            'language': association.languageName,
            'aliases': association.languageAliases,
            'languageCodes': association.languageCodes,
            'primaryWorldFlagId': association.primaryWorldFlagId,
          },
      ],
    });
    File(
      '${output.path}/language_primary_world_flags_inventory.json',
    ).writeAsStringSync('$worldFlagsJson\n');

    expect(inventory, hasLength(10));
    expect(
      inventory.every((entry) => entry['rendersSuccessfully'] == true),
      isTrue,
    );
  });

  test('language catalog resolves primary WORLD associations', () {
    expect(LanguageFlagCatalog.worldAssociations, hasLength(111));
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageName: 'Français'),
      'france',
    );
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageTag: 'da-DK'),
      'denmark',
    );
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageName: 'Napoletano'),
      'neapolitan',
    );
    expect(LanguageFlagCatalog.primaryWorldFlagId(languageTag: 'cy'), 'wales');
    expect(
      LanguageFlagCatalog.primaryWorldFlagId(languageTag: 'en'),
      'united_kingdom',
    );
  });

  test(
    'automatic Course flag priority is FlagPainter then WORLD then none',
    () {
      final japanese = CourseFlagService.resolve(_course('Japanese', 'ja-JP'));
      final french = CourseFlagService.resolve(_course('French', 'fr-FR'));
      final unknown = CourseFlagService.resolve(_course('Klingon', 'tlh'));

      expect(japanese.kind, ResolvedCourseFlagKind.builtIn);
      expect(japanese.identifier, 'JA');
      expect(japanese.isExplicit, isFalse);
      expect(french.kind, ResolvedCourseFlagKind.worldFlag);
      expect(french.identifier, 'france');
      expect(french.isExplicit, isFalse);
      expect(unknown.kind, ResolvedCourseFlagKind.neutral);
    },
  );

  test('every primary WORLD association names an existing manifest entity', () {
    final manifest = WorldFlagRepository.parseManifestDocument(
      File('assets/world_flags/manifest.json').readAsStringSync(),
    );
    final ids = manifest.entities.map((entity) => entity.id).toSet();
    for (final association in LanguageFlagCatalog.worldAssociations) {
      expect(ids, contains(association.primaryWorldFlagId));
    }
  });
}

Course _course(String language, String tag) => Course(
  courseId: 'test-${language.toLowerCase()}',
  learningLanguage: language,
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: language,
  targetLanguageTag: tag,
  title: language,
  ttsLanguage: tag,
  lessons: const [],
);
