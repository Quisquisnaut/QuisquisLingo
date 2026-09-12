import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/flag_background_palette_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/widgets/flag_inspired_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    '227.02 retains the three baseline modes and adds exactly two modes',
    () {
      expect(
        LearnerFlagBackgroundMode.values
            .map((mode) => (mode.storageValue, mode.label))
            .toList(),
        const [
          ('small', 'Small'),
          ('off', 'Off'),
          ('extended', 'Extended'),
          ('tinted', 'Tinted'),
          ('soft_inspired', 'Inspired'),
        ],
      );
      expect(
        LearnerFlagBackgroundMode.values.map((mode) => mode.next).toList(),
        const [
          LearnerFlagBackgroundMode.off,
          LearnerFlagBackgroundMode.extended,
          LearnerFlagBackgroundMode.tinted,
          LearnerFlagBackgroundMode.softInspired,
          LearnerFlagBackgroundMode.small,
        ],
      );
      expect(
        LearnerFlagBackgroundMode.fromStorage('tinted'),
        LearnerFlagBackgroundMode.tinted,
      );
      expect(
        LearnerFlagBackgroundMode.fromStorage('soft_inspired'),
        LearnerFlagBackgroundMode.softInspired,
      );
      expect(
        LearnerFlagBackgroundMode.fromStorage('soft_inspired').label,
        'Inspired',
      );
      expect(
        LearnerFlagBackgroundMode.values.map((mode) => mode.label),
        isNot(contains('Soft Inspired')),
      );
      expect(
        LearnerFlagBackgroundMode.fromStorage('legacy-unknown'),
        LearnerFlagBackgroundMode.off,
      );
    },
  );

  test('derived palettes are deterministic, restrained, and theme-adaptive', () {
    const service = FlagBackgroundPaletteService();
    final difficultFlags = <String, List<FlagColorSample>>{
      'very light': const [
        FlagColorSample(Color(0xFFFFFFFF), 100),
        FlagColorSample(Color(0xFFD00028), 1),
      ],
      'very dark': const [
        FlagColorSample(Color(0xFF000000), 100),
        FlagColorSample(Color(0xFF0038A8), 1),
      ],
      'saturated bicolor': const [
        FlagColorSample(Color(0xFFFF0000)),
        FlagColorSample(Color(0xFF00FF00)),
      ],
      'tricolor': const [
        FlagColorSample(Color(0xFF009246)),
        FlagColorSample(Color(0xFFFFFFFF)),
        FlagColorSample(Color(0xFFCE2B37)),
      ],
      'multicolor': const [
        FlagColorSample(Color(0xFF002395)),
        FlagColorSample(Color(0xFFFFB612)),
        FlagColorSample(Color(0xFF007A3D)),
        FlagColorSample(Color(0xFFDE3831)),
      ],
      'neutral heavy': const [
        FlagColorSample(Color(0xFFFAFAFA), 20),
        FlagColorSample(Color(0xFF777777), 15),
        FlagColorSample(Color(0xFF111111), 10),
      ],
      'near monochrome': const [
        FlagColorSample(Color(0xFF656565)),
        FlagColorSample(Color(0xFF6A6A6A)),
      ],
    };

    for (final entry in difficultFlags.entries) {
      final light = service.derive(entry.value, brightness: Brightness.light);
      final repeated = service.derive(
        entry.value.reversed,
        brightness: Brightness.light,
      );
      final dark = service.derive(entry.value, brightness: Brightness.dark);

      expect(
        _paletteArgb(repeated),
        _paletteArgb(light),
        reason: '${entry.key} must be stable regardless of sample order',
      );
      expect(
        light.tinted.computeLuminance(),
        greaterThanOrEqualTo(.62),
        reason: '${entry.key} light tint must stay subordinate to dark text',
      );
      expect(
        dark.tinted.computeLuminance(),
        lessThanOrEqualTo(.10),
        reason: '${entry.key} dark tint must stay subordinate to light text',
      );
      expect(HSLColor.fromColor(light.tinted).saturation, lessThan(.40));
      expect(HSLColor.fromColor(dark.tinted).saturation, lessThan(.40));
      for (final color in light.inspiredColors) {
        expect(_contrast(color, const Color(0xFF1A1C1A)), greaterThan(4.5));
        expect(HSLColor.fromColor(color).saturation, lessThan(.60));
      }
      for (final color in dark.inspiredColors) {
        expect(_contrast(color, const Color(0xFFE1E3DF)), greaterThan(4.5));
        expect(HSLColor.fromColor(color).saturation, lessThan(.55));
      }
      expect(light.tinted, isNot(dark.tinted));
    }

    final whiteHeavy = service.derive(
      difficultFlags['very light']!,
      brightness: Brightness.light,
    );
    final whiteHeavyHsl = HSLColor.fromColor(whiteHeavy.tinted);
    expect(whiteHeavyHsl.saturation, greaterThan(.08));
    expect(
      whiteHeavyHsl.hue < 45 || whiteHeavyHsl.hue > 325,
      isTrue,
      reason: 'A small chromatic field must not be erased by a white majority.',
    );

    final multicolor = service.derive(
      difficultFlags['multicolor']!,
      brightness: Brightness.light,
    );
    expect(multicolor.inspiredColors.toSet(), hasLength(3));
    expect(
      _maximumColorDistance(multicolor.inspiredColors),
      greaterThan(.16),
      reason: 'Inspired must expose visibly separated flag-derived colors.',
    );
    expect(
      multicolor.inspiredColors
          .map((color) => HSLColor.fromColor(color).saturation)
          .reduce(math.max),
      greaterThan(HSLColor.fromColor(multicolor.tinted).saturation + .08),
      reason: 'Inspired must have stronger color presence than Tinted.',
    );
    final sourceHues = difficultFlags['multicolor']!
        .map((sample) => HSLColor.fromColor(sample.color).hue)
        .toList(growable: false);
    for (final color in multicolor.inspiredColors) {
      final hue = HSLColor.fromColor(color).hue;
      expect(
        sourceHues.any((sourceHue) => _hueDistance(hue, sourceHue) < 8),
        isTrue,
        reason: 'Inspired colors must retain a representative source hue.',
      );
    }

    for (final entry in {
      'saturated bicolor': .12,
      'tricolor': .12,
      'very light': .07,
      'very dark': .04,
      'multicolor': .16,
      'near monochrome': .015,
    }.entries) {
      final palette = service.derive(
        difficultFlags[entry.key]!,
        brightness: Brightness.light,
      );
      expect(
        _maximumColorDistance(palette.inspiredColors),
        greaterThan(entry.value),
        reason:
            '${entry.key} Inspired composition must remain distinguishable from a uniform tint.',
      );
    }
  });

  test('SVG extraction supports the current flag asset color forms', () {
    final colors = FlagBackgroundPaletteService.colorsFromSvg('''
      <svg>
        <path fill="#fff" />
        <path fill="red" />
        <path fill="rgb(0, 128, 255)" />
        <path fill="none" stroke="olive" />
        <path fill="url(#paint)" />
      </svg>
    ''');
    expect(colors.map((sample) => sample.color.toARGB32()).toSet(), {
      const Color(0xFFFFFFFF).toARGB32(),
      const Color(0xFFFF0000).toARGB32(),
      const Color(0xFF0080FF).toARGB32(),
      const Color(0xFF808000).toARGB32(),
    });
    expect(
      colors
          .singleWhere((sample) => sample.color == const Color(0xFF808000))
          .weight,
      .25,
    );
  });

  testWidgets(
    'resolver uses World Flag and custom pixels with safe built-in fallbacks',
    (tester) async {
      await tester.runAsync(() async {
        final resolver = CourseFlagPaletteResolver();
        final japan = await resolver.resolve(
          _course(worldFlagId: 'japan', flagCode: 'DE'),
          fallbackCode: 'IT',
          brightness: Brightness.light,
        );
        expect(japan.source, CourseFlagPaletteSource.worldFlag);
        expect(japan.usedFallback, isFalse);
        expect(
          HSLColor.fromColor(japan.palette.tinted).saturation,
          greaterThan(.08),
        );

        final custom = await resolver.resolve(
          _course(
            flagCode: 'DE',
            flagImageBase64: base64Encode(
              await _stripedPng(const [
                (Color(0xFFFFFFFF), 9),
                (Color(0xFF7A1FA2), 1),
              ]),
            ),
          ),
          fallbackCode: 'IT',
          brightness: Brightness.light,
        );
        expect(custom.source, CourseFlagPaletteSource.customImage);
        expect(custom.usedFallback, isFalse);
        final customHue = HSLColor.fromColor(custom.palette.tinted).hue;
        expect(customHue, inInclusiveRange(260, 330));

        final malformed = await resolver.resolve(
          _course(
            flagCode: 'DE',
            flagImageBase64: base64Encode(const [1, 2, 3]),
          ),
          fallbackCode: 'IT',
          brightness: Brightness.dark,
        );
        expect(malformed.source, CourseFlagPaletteSource.builtIn);
        expect(malformed.usedFallback, isTrue);

        final unavailable = await resolver.resolve(
          _course(worldFlagId: 'not-in-the-manifest', flagCode: 'CY'),
          fallbackCode: 'IT',
          brightness: Brightness.light,
        );
        expect(unavailable.source, CourseFlagPaletteSource.builtIn);
        expect(unavailable.usedFallback, isTrue);

        final neutral = await resolver.resolve(
          _course(flagCode: 'unsupported-code'),
          fallbackCode: 'also-unsupported',
          brightness: Brightness.light,
        );
        expect(neutral.source, CourseFlagPaletteSource.safeFallback);
        expect(neutral.usedFallback, isTrue);
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tinted is uniform and Inspired is a distinct static color composition',
    (tester) async {
      final course = _course(flagCode: 'IT');
      Widget app(LearnerFlagBackgroundMode mode) => MaterialApp(
        home: Scaffold(
          body: CourseFlagInspiredBackground(
            course: course,
            fallbackCode: 'IT',
            brightness: Brightness.light,
            mode: mode,
          ),
        ),
      );

      await tester.pumpWidget(app(LearnerFlagBackgroundMode.tinted));
      final tinted = find.byKey(
        const ValueKey('unified-learner-flag-background-tinted'),
      );
      var decoration =
          tester.widget<DecoratedBox>(tinted).decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.gradient, isNull);
      expect(
        find.descendant(of: tinted, matching: find.byType(Image)),
        findsNothing,
      );
      expect(
        find.descendant(of: tinted, matching: find.byType(Opacity)),
        findsNothing,
      );

      await tester.pumpWidget(app(LearnerFlagBackgroundMode.softInspired));
      final inspired = find.byKey(
        const ValueKey('unified-learner-flag-background-inspired'),
      );
      decoration =
          tester.widget<DecoratedBox>(inspired).decoration as BoxDecoration;
      expect(decoration.color, isNull);
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors, hasLength(3));
      expect(gradient.stops, const [0, .48, 1]);
      expect(_maximumColorDistance(gradient.colors), greaterThan(.10));
      expect(find.byType(AnimatedContainer), findsNothing);
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inspired surfaces fill phone and desktop widths in both themes',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final brightness in Brightness.values) {
        for (final width in [320.0, 375.0, 430.0, 1100.0]) {
          await tester.binding.setSurfaceSize(Size(width, 900));
          for (final mode in const [
            LearnerFlagBackgroundMode.tinted,
            LearnerFlagBackgroundMode.softInspired,
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(brightness: brightness),
                home: Scaffold(
                  body: SizedBox.expand(
                    child: CourseFlagInspiredBackground(
                      course: _course(flagCode: 'UK'),
                      fallbackCode: 'UK',
                      brightness: brightness,
                      mode: mode,
                    ),
                  ),
                ),
              ),
            );
            await tester.pump();
            final finder = find.byType(CourseFlagInspiredBackground);
            expect(tester.getSize(finder), Size(width, 900));
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );

  test(
    'new modes remain isolated, survive restart, and ignore the shared key',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Alice');
      final aliceId = (await profiles.getActiveProfileId())!;
      final prefs = await SharedPreferences.getInstance();
      final oldSharedKey = profiles.keyForProfileId(
        aliceId,
        'flag_background_mode',
      );
      await prefs.setString(oldSharedKey, 'extended');
      final existingR0Key = profiles.keyForProfileId(
        aliceId,
        'flag_background_mode_course_${sha256.convert(utf8.encode('course-r0'))}',
      );
      await prefs.setString(existingR0Key, 'soft_inspired');
      expect(
        await profiles.getFlagBackgroundMode('course-r0'),
        LearnerFlagBackgroundMode.softInspired,
      );
      expect(
        (await profiles.getFlagBackgroundMode('course-r0')).label,
        'Inspired',
      );

      await profiles.setFlagBackgroundMode(
        'course-a',
        LearnerFlagBackgroundMode.tinted,
      );
      await profiles.setFlagBackgroundMode(
        'course-b',
        LearnerFlagBackgroundMode.softInspired,
      );
      await profiles.addProfile('Bob');
      expect(
        await profiles.getFlagBackgroundMode('course-a'),
        LearnerFlagBackgroundMode.off,
      );
      await profiles.setFlagBackgroundMode(
        'course-a',
        LearnerFlagBackgroundMode.softInspired,
      );

      final restarted = ProfileService();
      await restarted.setActiveProfileById(aliceId);
      expect(
        await restarted.getFlagBackgroundMode('course-a'),
        LearnerFlagBackgroundMode.tinted,
      );
      expect(
        await restarted.getFlagBackgroundMode('course-b'),
        LearnerFlagBackgroundMode.softInspired,
      );
      expect(prefs.getString(oldSharedKey), 'extended');
    },
  );

  test('mode preferences do not change Course JSON, progress, or XP', () async {
    final profiles = ProfileService();
    await profiles.addProfile('Visual learner');
    final progress = ProgressService(now: () => DateTime(2026, 9, 7, 12));
    final course = _course(flagCode: 'IT');
    final courseBefore = course.toJson();
    final progressBefore = await _progressSnapshot(progress, course.courseId);

    await profiles.setFlagBackgroundMode(
      course.courseId,
      LearnerFlagBackgroundMode.tinted,
    );
    await profiles.setFlagBackgroundMode(
      course.courseId,
      LearnerFlagBackgroundMode.softInspired,
    );

    expect(course.toJson(), courseBefore);
    expect(await _progressSnapshot(progress, course.courseId), progressBefore);
  });
}

List<int> _paletteArgb(FlagBackgroundPalette palette) => [
  palette.tinted.toARGB32(),
  ...palette.inspiredColors.map((color) => color.toARGB32()),
];

double _contrast(Color first, Color second) {
  final lighter = math.max(first.computeLuminance(), second.computeLuminance());
  final darker = math.min(first.computeLuminance(), second.computeLuminance());
  return (lighter + .05) / (darker + .05);
}

double _colorDistance(Color first, Color second) {
  final red = first.r - second.r;
  final green = first.g - second.g;
  final blue = first.b - second.b;
  return math.sqrt(red * red + green * green + blue * blue) / math.sqrt(3);
}

double _maximumColorDistance(List<Color> colors) {
  var maximum = 0.0;
  for (var first = 0; first < colors.length; first++) {
    for (var second = first + 1; second < colors.length; second++) {
      maximum = math.max(
        maximum,
        _colorDistance(colors[first], colors[second]),
      );
    }
  }
  return maximum;
}

double _hueDistance(double first, double second) {
  final difference = (first - second).abs();
  return math.min(difference, 360 - difference);
}

Course _course({
  String flagCode = '',
  String flagImageBase64 = '',
  String worldFlagId = '',
}) => Course(
  courseId: 'flag-background-course',
  learningLanguage: 'Test language',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Test language',
  title: 'Flag background test',
  ttsLanguage: 'en-US',
  flagCode: flagCode,
  flagImageBase64: flagImageBase64,
  worldFlagId: worldFlagId,
  lessons: const [],
);

Future<Uint8List> _stripedPng(List<(Color, int)> stripes) async {
  final width = stripes.fold<int>(0, (sum, stripe) => sum + stripe.$2);
  const height = 4;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  var left = 0.0;
  for (final stripe in stripes) {
    canvas.drawRect(
      ui.Rect.fromLTWH(left, 0, stripe.$2.toDouble(), height.toDouble()),
      ui.Paint()..color = stripe.$1,
    );
    left += stripe.$2;
  }
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

Future<Map<String, Object>> _progressSnapshot(
  ProgressService progress,
  String courseId,
) async => {
  'rounds': await progress.getCompletedRounds(courseId: courseId),
  'lessons': await progress.getCompletedLessons(courseId: courseId),
  'laurels': await progress.getPerfectRounds(courseId: courseId),
  'duels': await progress.getWonDuels(courseId: courseId),
  'xp': await progress.getXp(courseCode: 'IT'),
  'weeklyXp': await progress.getWeeklyXp(),
  'studyDays': await progress.getDaysStudied(courseCode: 'IT'),
};
