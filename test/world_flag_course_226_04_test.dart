import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/world_flag_art.dart';
import 'package:quisquislingo_app/widgets/world_flag_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('authoritative World Flag lookup and search', () {
    final values = <WorldFlagEntity>[
      _entity(
        id: 'cyprus',
        name: 'Cyprus',
        iso2: 'CY',
        iso3: 'CYP',
        category: WorldFlagCategory.unMember,
      ),
      _entity(
        id: 'united_kingdom',
        name: 'United Kingdom',
        iso2: 'GB',
        iso3: 'GBR',
        aliases: const ['Great Britain'],
        category: WorldFlagCategory.unMember,
      ),
      _entity(
        id: 'wales',
        name: 'Wales',
        subdivision: 'GB-WLS',
        category: WorldFlagCategory.shortlist,
      ),
    ];
    final repository = _Repository(values);

    test('resolves only an exact stable manifest identity', () async {
      expect((await repository.findById(' wales '))?.displayNameEn, 'Wales');
      expect(await repository.findById('CY'), isNull);
      expect(await repository.findById('missing'), isNull);
    });

    test('searches names, aliases, IDs, ISO codes and subdivision codes', () {
      expect(_ids(WorldFlagRepository.search(values, 'Cyprus')), ['cyprus']);
      expect(_ids(WorldFlagRepository.search(values, 'Britain')), [
        'united_kingdom',
      ]);
      expect(_ids(WorldFlagRepository.search(values, 'united_king')), [
        'united_kingdom',
      ]);
      expect(_ids(WorldFlagRepository.search(values, 'CYP')), ['cyprus']);
      expect(_ids(WorldFlagRepository.search(values, 'GB-WLS')), ['wales']);
    });

    test('keeps existing reference categories authoritative', () {
      expect(
        _ids(
          WorldFlagRepository.referenceFor(
            values,
            WorldFlagReferenceCategory.shortlist,
          ),
        ),
        ['wales'],
      );
      expect(
        _ids(
          WorldFlagRepository.referenceFor(
            values,
            WorldFlagReferenceCategory.unMembers,
          ),
        ),
        ['cyprus', 'united_kingdom'],
      );
    });
  });

  group('course World Flag validation', () {
    final wales = _entity(
      id: 'wales',
      name: 'Wales',
      subdivision: 'GB-WLS',
      category: WorldFlagCategory.shortlist,
    );
    final flags = CourseFlagService();

    test('accepts a manifest identity and ignores an empty identity', () async {
      final repository = _Repository([wales]);

      await flags.validateWorldFlag(
        _course(worldFlagId: 'wales'),
        repository: repository,
      );
      await flags.validateWorldFlag(_course(), repository: repository);
    });

    test(
      'reports an unavailable identity without rewriting course data',
      () async {
        final course = _course(worldFlagId: 'removed_flag', flagCode: 'CY');

        await expectLater(
          flags.validateWorldFlag(course, repository: _Repository(const [])),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('World Flag "removed_flag" is unavailable'),
            ),
          ),
        );
        expect(course.worldFlagId, 'removed_flag');
        expect(course.flagCode, 'CY');
      },
    );
  });

  group('course-aware World Flag rendering', () {
    final wales = _entity(
      id: 'wales',
      name: 'Wales',
      subdivision: 'GB-WLS',
      category: WorldFlagCategory.shortlist,
    );

    testWidgets('badge and backdrop render the selected SVG entity', (
      tester,
    ) async {
      final repository = _Repository([wales]);
      final course = _course(
        worldFlagId: 'wales',
        flagCode: 'CY',
        flagImageBase64: base64Encode(const [1, 2, 3]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CourseFlagBackdrop(
                  course: course,
                  fallbackCode: 'EN',
                  worldFlagRepository: repository,
                ),
                CourseFlagBadge(
                  course: course,
                  fallbackCode: 'EN',
                  worldFlagRepository: repository,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final art = tester.widgetList<WorldFlagArt>(find.byType(WorldFlagArt));
      expect(art, hasLength(2));
      expect(art.every((widget) => widget.entity.id == 'wales'), isTrue);
      expect(
        find.byKey(const ValueKey('course-world-flag-wales')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('course-world-flag-backdrop-wales')),
        findsOneWidget,
      );
    });

    testWidgets(
      'missing identity uses neutral display without legacy fallback',
      (tester) async {
        final repository = _Repository(const []);
        final course = _course(
          worldFlagId: 'removed_flag',
          flagCode: 'CY',
          flagImageBase64: base64Encode(const [1, 2, 3]),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CourseFlagBackdrop(
                    course: course,
                    fallbackCode: 'EN',
                    worldFlagRepository: repository,
                  ),
                  CourseFlagBadge(
                    course: course,
                    fallbackCode: 'EN',
                    worldFlagRepository: repository,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(WorldFlagArt), findsNothing);
        expect(find.byType(Image), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) => widget is CustomPaint && widget.painter is FlagPainter,
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('course-world-flag-unavailable-removed_flag'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey(
              'course-world-flag-backdrop-unavailable-removed_flag',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byTooltip('World Flag unavailable: removed_flag'),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('picker searches metadata and returns the selected entity', (
    tester,
  ) async {
    final values = [
      _entity(
        id: 'cyprus',
        name: 'Cyprus',
        iso2: 'CY',
        iso3: 'CYP',
        category: WorldFlagCategory.unMember,
      ),
      _entity(
        id: 'wales',
        name: 'Wales',
        subdivision: 'GB-WLS',
        category: WorldFlagCategory.shortlist,
      ),
    ];
    WorldFlagEntity? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              selected = await showWorldFlagPicker(
                context: context,
                repository: _Repository(values),
              );
            },
            child: const Text('Open picker'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('world-flag-picker-search')),
      'GB-WLS',
    );
    await tester.pump();
    expect(find.text('Wales'), findsOneWidget);
    expect(find.text('Cyprus'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('world-flag-option-wales')));
    await tester.pumpAndSettle();
    expect(selected?.id, 'wales');
  });

  group('custom PNG and JPEG validation', () {
    final service = CourseFlagService();

    testWidgets('converts and proportionally resizes valid image bytes', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final source = await _png(width: 320, height: 100);

        final prepared = await service.prepareFlag(source);
        final output = base64Decode(prepared.base64Png);

        expect(prepared.sourceWidth, 320);
        expect(prepared.sourceHeight, 100);
        expect(prepared.outputWidth, 256);
        expect(prepared.outputHeight, 80);
        expect(output.take(8), const [0x89, 0x50, 0x4e, 0x47, 13, 10, 26, 10]);
      });
    });

    testWidgets(
      'rejects unsupported, damaged JPEG, small and oversized input',
      (tester) async {
        await tester.runAsync(() async {
          await expectLater(
            service.prepareFlag(Uint8List.fromList(const [1, 2, 3, 4])),
            throwsA(isA<FormatException>()),
          );
          await expectLater(
            service.prepareFlag(
              Uint8List.fromList(const [0xff, 0xd8, 0xff, 0x00]),
            ),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                contains('not a supported PNG or JPEG'),
              ),
            ),
          );
          await expectLater(
            service.prepareFlag(await _png(width: 32, height: 20)),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                contains('Minimum: 64x40'),
              ),
            ),
          );
          await expectLater(
            service.prepareFlag(Uint8List(CourseFlagService.maxInputBytes + 1)),
            throwsA(
              isA<FormatException>().having(
                (error) => error.message,
                'message',
                contains('2 MB safety limit'),
              ),
            ),
          );
        });
      },
    );
  });
}

class _Repository extends WorldFlagRepository {
  final List<WorldFlagEntity> values;

  _Repository(this.values);

  @override
  Future<List<WorldFlagEntity>> load() async => values;
}

WorldFlagEntity _entity({
  required String id,
  required String name,
  required WorldFlagCategory category,
  String? iso2,
  String? iso3,
  String? subdivision,
  List<String> aliases = const [],
}) => WorldFlagEntity(
  id: id,
  displayNameEn: name,
  assetPath: 'assets/world_flags/flags/$id.svg',
  isoAlpha2: iso2,
  isoAlpha3: iso3,
  subdivisionCode: subdivision,
  category: category,
  aliases: aliases,
);

Course _course({
  String worldFlagId = '',
  String flagCode = '',
  String flagImageBase64 = '',
}) => Course(
  courseId: 'world-flag-course',
  learningLanguage: 'Welsh',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Welsh',
  title: 'World Flag course',
  ttsLanguage: 'cy-GB',
  worldFlagId: worldFlagId,
  flagCode: flagCode,
  flagImageBase64: flagImageBase64,
  lessons: const [],
);

List<String> _ids(Iterable<WorldFlagEntity> entities) =>
    entities.map((entity) => entity.id).toList();

Future<Uint8List> _png({required int width, required int height}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff336699),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
