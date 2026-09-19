import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/course_entry_animation.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/unified_learner_top_bar.dart';
import 'package:quisquislingo_app/widgets/world_flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CourseEntryAnimationPolicy', () {
    test(
      'bundled Korean keeps JSON KR while its course fallback is KO',
      () async {
        final korean = await CourseService().loadCourse('KO');

        expect(korean.flagCode, 'KR');
        expect(korean.worldFlagId, isEmpty);
        expect(korean.flagImageBase64, isEmpty);
        expect(CourseService.codeForCourse(korean).toUpperCase(), 'KO');

        final request = await CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: 'sample_it_en_it',
          destination: korean,
          fallbackCode: CourseService.codeForCourse(korean),
          animationsEnabled: true,
          reducedMotion: false,
        );

        expect(request?.kind, CourseEntryFlagKind.builtIn);
        expect(request?.identifier, 'KR');
      },
    );

    test(
      'flagless bundled German uses its automatic FlagPainter flag',
      () async {
        final german = await CourseService().loadCourse('DE');

        expect(german.toJson().containsKey('flagCode'), isFalse);
        expect(german.toJson().containsKey('worldFlagId'), isFalse);
        expect(german.toJson().containsKey('flagImageBase64'), isFalse);
        expect(CourseService.codeForCourse(german).toUpperCase(), 'DE');

        final request = await CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: 'sample_it_en_it',
          destination: german,
          fallbackCode: CourseService.codeForCourse(german),
          animationsEnabled: true,
          reducedMotion: false,
        );

        expect(request?.kind, CourseEntryFlagKind.builtIn);
        expect(request?.identifier, 'DE');
      },
    );

    test('a real switch uses only the destination JSON flag', () async {
      final destination = _course(
        id: 'course-b',
        learningLanguage: 'Italian',
        targetLanguage: 'Italian',
        flagCode: 'KR',
      );

      final request = await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: 'course-a',
        destination: destination,
        fallbackCode: 'IT',
        animationsEnabled: true,
        reducedMotion: false,
      );

      expect(request?.kind, CourseEntryFlagKind.builtIn);
      expect(request?.identifier, 'KR');
      expect(destination.toJson()['flagCode'], 'KR');
      expect(destination.toJson()['learningLanguage'], 'Italian');
      expect(destination.toJson().containsKey('courseEntryAnimation'), isFalse);
      expect(destination.formatVersion, Course.currentFormatVersion);
    });

    test('world flag identity has priority and must resolve exactly', () async {
      const configured = WorldFlagEntity(
        id: 'configured-world-flag',
        displayNameEn: 'Configured flag',
        assetPath: 'assets/world_flags/flags/configured.svg',
        category: WorldFlagCategory.shortlist,
      );
      final destination = _course(
        id: 'course-b',
        worldFlagId: configured.id,
        flagCode: 'IT',
      );
      final lookedUp = <String>[];

      final request = await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: 'course-a',
        destination: destination,
        fallbackCode: 'DE',
        animationsEnabled: true,
        reducedMotion: false,
        worldFlagLookup: (id) async {
          lookedUp.add(id);
          return id == configured.id ? configured : null;
        },
      );

      expect(lookedUp, [configured.id]);
      expect(request?.kind, CourseEntryFlagKind.worldFlag);
      expect(request?.identifier, configured.id);
      expect(request?.worldFlag, same(configured));
    });

    test(
      'a missing JSON flag uses the automatic course language flag',
      () async {
        final request = await CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: 'course-a',
          destination: _course(id: 'missing'),
          fallbackCode: 'DE',
          animationsEnabled: true,
          reducedMotion: false,
        );

        expect(request?.kind, CourseEntryFlagKind.builtIn);
        expect(request?.identifier, 'EN');
      },
    );

    test('automatic World Flag uses the real language association', () async {
      final request = await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: 'course-a',
        destination: _course(
          id: 'automatic-neapolitan',
          learningLanguage: 'Neapolitan',
          targetLanguage: 'Neapolitan',
        ),
        fallbackCode: 'NAP',
        animationsEnabled: true,
        reducedMotion: false,
      );

      expect(request?.kind, CourseEntryFlagKind.worldFlag);
      expect(request?.identifier, 'neapolitan');
      expect(
        request?.worldFlag?.assetPath,
        'assets/world_flags/flags/neapolitan.svg',
      );
    });

    test(
      'a course without any resolvable flag still skips animation',
      () async {
        final request = await CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: 'course-a',
          destination: _course(
            id: 'unknown-language',
            learningLanguage: 'Unknown language',
            targetLanguage: 'Unknown language',
            ttsLanguage: '',
          ),
          fallbackCode: '',
          animationsEnabled: true,
          reducedMotion: false,
        );

        expect(request, isNull);
      },
    );

    test('invalid declared JSON flags never gain a fallback', () async {
      for (final destination in [
        _course(id: 'invalid-code', flagCode: 'ZZ'),
        _course(id: 'invalid-world', worldFlagId: 'not-in-manifest'),
      ]) {
        final request = await CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: 'course-a',
          destination: destination,
          fallbackCode: 'DE',
          animationsEnabled: true,
          reducedMotion: false,
          worldFlagLookup: (_) async => null,
        );
        expect(request, isNull, reason: destination.courseId);
      }
    });

    test('portable custom image must be explicit and decodable', () async {
      final valid = await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: 'course-a',
        destination: _course(id: 'custom-image', flagImageBase64: 'AQID'),
        fallbackCode: 'DE',
        animationsEnabled: true,
        reducedMotion: false,
        imageValidator: (bytes) async => bytes.length == 3,
      );
      final invalid = await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: 'course-a',
        destination: _course(
          id: 'invalid-custom-image',
          flagImageBase64: 'not base64',
        ),
        fallbackCode: 'DE',
        animationsEnabled: true,
        reducedMotion: false,
        imageValidator: (_) async => true,
      );

      expect(valid?.kind, CourseEntryFlagKind.customImage);
      expect(valid?.imageBytes, [1, 2, 3]);
      expect(invalid, isNull);
    });

    test(
      'Do Not Disturb, reduced motion, startup and same course suppress',
      () async {
        final destination = _course(id: 'course-b', flagCode: 'KR');

        Future<CourseEntryFlagSource?> request({
          String? currentCourseId = 'course-a',
          bool animationsEnabled = true,
          bool reducedMotion = false,
        }) => CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: currentCourseId,
          destination: destination,
          fallbackCode: 'KR',
          animationsEnabled: animationsEnabled,
          reducedMotion: reducedMotion,
        );

        expect(await request(animationsEnabled: false), isNull);
        expect(await request(reducedMotion: true), isNull);
        expect(await request(currentCourseId: null), isNull);
        expect(await request(currentCourseId: destination.courseId), isNull);
        expect(await request(), isNotNull);
      },
    );

    test(
      'decision logic does not touch course or Flag Background persistence',
      () async {
        SharedPreferences.setMockInitialValues({});
        final profile = await ProfileService().createProfile('Policy Learner');
        await ProfileService().setActiveProfileById(profile.learnerProfileId);
        await SettingsService().setLastSelectedCourseCode('course-a');
        await ProfileService().setFlagBackgroundMode(
          'course-b',
          LearnerFlagBackgroundMode.softInspired,
        );

        await CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: 'course-a',
          destination: _course(id: 'course-b', flagCode: 'KR'),
          fallbackCode: 'DE',
          animationsEnabled: true,
          reducedMotion: false,
        );

        expect(await SettingsService().getLastSelectedCourseCode(), 'course-a');
        expect(
          await ProfileService().getFlagBackgroundMode('course-b'),
          LearnerFlagBackgroundMode.softInspired,
        );
      },
    );
  });

  testWidgets(
    'rendering is a restrained 2-second fade using the resolved flag',
    (tester) async {
      var completed = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          home: Scaffold(
            body: CourseEntryAnimation(
              flag: const CourseEntryFlagSource.builtIn('KR'),
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('course-entry-animation')), findsOneWidget);
      expect(
        find.byKey(const Key('course-entry-built-in-flag-KR')),
        findsOneWidget,
      );
      expect(completed, isFalse);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(completed, isFalse);
      await tester.pump(const Duration(milliseconds: 2));
      expect(completed, isTrue);
    },
  );

  group('Home course-switch wiring', () {
    setUp(() async {
      for (final asset in CourseService.courseAssets.values) {
        rootBundle.evict(asset);
      }
      SharedPreferences.setMockInitialValues({
        'one_time_notice_seen_welcome_2.0.40+240000': true,
        'sound_effects_enabled': false,
      });
      await ProfileService().addProfile('Course Switch Learner');
      await SettingsService().completeWelcomeWizard();
      await SettingsService().setLastSelectedCourseCode('IT');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => throw PlatformException(
              code: 'test_storage_unavailable',
              message: 'Persistent storage is unavailable in widget tests.',
            ),
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
    });

    testWidgets(
      'course-entry animation starts only after the course picker closes',
      (tester) async {
        _useLargeTestWindow(tester);
        await SettingsService().setAnimationsEnabled(true);
        final custom = Course.fromJson({
          ..._course(id: 'explicit-custom', flagCode: 'KR').toJson(),
          'publicationState': PublicationState.published.name,
        });
        await CourseEditorService().saveUserCourse(custom);
        await _openHome(tester);
        await _openCoursePicker(tester);

        await _tapCustomCourse(tester, 'explicit-custom');

        await _pumpUntilAbsent(tester, find.text('Choose course'));
        await _pumpUntil(
          tester,
          find.byKey(const Key('course-entry-built-in-flag-KR')),
        );
        expect(find.text('Choose course'), findsNothing);
        expect(_activeCourseId(tester), 'explicit-custom');
        expect(
          tester.getSize(find.byKey(const Key('course-entry-animation'))),
          const Size(1200, 1400),
        );
      },
    );

    testWidgets(
      'actual flagged switch animates and persists; same course does not replay',
      (tester) async {
        _useLargeTestWindow(tester);
        await SettingsService().setAnimationsEnabled(true);
        await _openHome(tester);
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);

        await _selectBundledCourse(tester, 'KO');
        await _pumpUntil(
          tester,
          find.byKey(const Key('course-entry-built-in-flag-KR')),
        );
        expect(_activeCourseId(tester), 'sample_ko_en_ko');
        expect(await SettingsService().getLastSelectedCourseCode(), 'KO');

        await tester.pump(
          CourseEntryAnimationPolicy.duration +
              const Duration(milliseconds: 50),
        );
        await tester.pump();
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);

        await _selectBundledCourse(tester, 'KO');
        await _pumpUntilCourse(tester, 'sample_ko_en_ko');
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
      },
    );

    testWidgets(
      'Extended source never paints behind an Off destination during switching',
      (tester) async {
        _useLargeTestWindow(tester);
        await SettingsService().setAnimationsEnabled(false);
        final courses = await tester.runAsync(
          () => Future.wait([
            CourseService().loadCourse('IT'),
            CourseService().loadCourse('DE'),
          ]),
        );
        final italian = courses![0];
        final german = courses[1];
        final profiles = _BlockingFlagBackgroundProfileService();
        await profiles.setFlagBackgroundMode(
          italian.courseId,
          LearnerFlagBackgroundMode.extended,
        );
        await profiles.setFlagBackgroundMode(
          german.courseId,
          LearnerFlagBackgroundMode.off,
        );
        await _openHome(tester, profileService: profiles);

        expect(_activeCourseId(tester), italian.courseId);
        expect(
          tester
              .widget<CourseFlagBackdrop>(
                find.byKey(const Key('unified-learner-flag-background')),
              )
              .course
              .courseId,
          italian.courseId,
        );

        profiles.blockNextFlagReadFor(german.courseId);
        addTearDown(profiles.releaseFlagRead);
        await _openCoursePicker(tester);
        await _tapBundledCourse(tester, 'DE');

        void expectCoherentFrame() {
          if (find.byType(UnifiedLearnerTopBar).evaluate().isEmpty) return;
          final activeCourseId = _activeCourseId(tester);
          final extendedBackdrop = find.byKey(
            const Key('unified-learner-flag-background'),
          );
          if (activeCourseId == german.courseId) {
            expect(
              extendedBackdrop,
              findsNothing,
              reason:
                  'The destination Course and its Off background preference '
                  'must become visible in the same frame.',
            );
            return;
          }

          expect(activeCourseId, italian.courseId);
          expect(extendedBackdrop, findsOneWidget);
          expect(
            tester.widget<CourseFlagBackdrop>(extendedBackdrop).course.courseId,
            italian.courseId,
            reason:
                'While destination state is loading, the source Course and '
                'its Extended background must remain coherent.',
          );
        }

        for (var attempt = 0; attempt < 100; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 10));
          expectCoherentFrame();
          if (profiles.flagReadStarted) break;
        }
        expect(profiles.flagReadStarted, isTrue);
        expectCoherentFrame();
        expect(_activeCourseId(tester), italian.courseId);

        profiles.releaseFlagRead();
        for (var attempt = 0; attempt < 100; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 10));
          expectCoherentFrame();
          if (_activeCourseId(tester) == german.courseId) break;
        }
        expect(_activeCourseId(tester), german.courseId);
        await _pumpUntil(tester, find.byTooltip('Flag background: Off'));
        expect(find.byTooltip('Flag background: Off'), findsOneWidget);
      },
    );

    testWidgets(
      'a stale slow switch cannot replace the latest selected course',
      (tester) async {
        _useLargeTestWindow(tester);
        await SettingsService().setAnimationsEnabled(false);
        final courses = await tester.runAsync(
          () => Future.wait([
            CourseService().loadCourse('DE'),
            CourseService().loadCourse('KO'),
          ]),
        );
        final german = courses![0];
        final korean = courses[1];
        final profiles = _BlockingFlagBackgroundProfileService();
        profiles.blockNextFlagReadFor(german.courseId);
        addTearDown(profiles.releaseFlagRead);
        await _openHome(tester, profileService: profiles);

        await _selectBundledCourse(tester, 'DE');
        for (
          var attempt = 0;
          attempt < 100 && !profiles.flagReadStarted;
          attempt++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(profiles.flagReadStarted, isTrue);

        await _selectBundledCourse(tester, 'KO');
        await _pumpUntilCourse(tester, korean.courseId);
        expect(await SettingsService().getLastSelectedCourseCode(), 'KO');

        profiles.releaseFlagRead();
        for (var attempt = 0; attempt < 20; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump(const Duration(milliseconds: 10));
        }

        expect(_activeCourseId(tester), korean.courseId);
        expect(await SettingsService().getLastSelectedCourseCode(), 'KO');
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
      },
    );

    testWidgets(
      'Do Not Disturb suppresses; enabling animations allows automatic flags',
      (tester) async {
        _useLargeTestWindow(tester);
        await SettingsService().setAnimationsEnabled(false);
        await _openHome(tester);
        await _selectBundledCourse(tester, 'KO');
        await _pumpUntilCourse(tester, 'sample_ko_en_ko');
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
        expect(await SettingsService().getLastSelectedCourseCode(), 'KO');

        await SettingsService().setAnimationsEnabled(true);
        await _selectBundledCourse(tester, 'DE');
        await _pumpUntil(
          tester,
          find.byKey(const Key('course-entry-built-in-flag-DE')),
        );
        expect(_activeCourseId(tester), 'sample_de_en_de');
        expect(await SettingsService().getLastSelectedCourseCode(), 'DE');
      },
    );

    for (final explicit in [false, true]) {
      testWidgets(
        '${explicit ? 'explicit' : 'automatic'} World Flag renders on a real course switch',
        (tester) async {
          _useLargeTestWindow(tester);
          await SettingsService().setAnimationsEnabled(true);
          final custom = Course.fromJson({
            ..._course(
              id: 'world-flag-$explicit',
              learningLanguage: 'Neapolitan',
              targetLanguage: 'Neapolitan',
              worldFlagId: explicit ? 'neapolitan' : '',
            ).toJson(),
            'publicationState': PublicationState.published.name,
          });
          await CourseEditorService().saveUserCourse(custom);
          await _openHome(tester);
          await _selectCustomCourse(tester, custom.courseId);
          final flag = find.byKey(
            const Key('course-entry-world-flag-neapolitan'),
          );
          await _pumpUntil(tester, flag);
          expect(find.text('Choose course'), findsNothing);
          expect(_activeCourseId(tester), custom.courseId);
          expect(
            tester.widget<WorldFlagArt>(flag).entity.assetPath,
            'assets/world_flags/flags/neapolitan.svg',
          );
          await _pumpUntilAbsent(
            tester,
            find.descendant(
              of: flag,
              matching: find.byType(CircularProgressIndicator),
            ),
          );
          expect(flag, findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pump(CourseEntryAnimationPolicy.duration);
          await tester.pump();
          expect(find.byKey(const Key('course-entry-animation')), findsNothing);
        },
      );
    }

    testWidgets(
      'an explicitly invalid flag switches course without using its fallback',
      (tester) async {
        _useLargeTestWindow(tester);
        await SettingsService().setAnimationsEnabled(true);
        final invalid = Course.fromJson({
          ..._course(
            id: 'invalid-explicit-custom',
            targetLanguage: 'English',
            flagCode: 'ZZ',
          ).toJson(),
          'publicationState': PublicationState.published.name,
        });
        expect(CourseService.codeForCourse(invalid).toUpperCase(), 'EN');
        await CourseEditorService().saveUserCourse(invalid);
        await _openHome(tester);

        await _selectCustomCourse(tester, invalid.courseId);
        await _pumpUntilCourse(tester, invalid.courseId);

        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
        expect(
          await SettingsService().getLastSelectedCourseCode(),
          'custom:${invalid.courseId}',
        );
      },
    );

    testWidgets(
      'normal startup with persisted flagged course does not animate',
      (tester) async {
        _useLargeTestWindow(tester);
        await SettingsService().setAnimationsEnabled(true);
        await SettingsService().setLastSelectedCourseCode('KO');
        await _openHome(tester);

        expect(_activeCourseId(tester), 'sample_ko_en_ko');
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
      },
    );
  });
}

void _useLargeTestWindow(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1400);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures();
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Course _course({
  required String id,
  String learningLanguage = 'English',
  String targetLanguage = 'English',
  String flagCode = '',
  String worldFlagId = '',
  String flagImageBase64 = '',
  String ttsLanguage = 'en',
}) => Course(
  courseId: id,
  learningLanguage: learningLanguage,
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: targetLanguage,
  title: 'Course $id',
  ttsLanguage: ttsLanguage,
  flagCode: flagCode,
  worldFlagId: worldFlagId,
  flagImageBase64: flagImageBase64,
  lessons: const [],
);

Future<void> _openHome(
  WidgetTester tester, {
  ProfileService? profileService,
}) async {
  await tester.pumpWidget(
    MaterialApp(home: HomeScreen(profileService: profileService)),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await _pumpUntil(tester, find.text('Beta expiry'));
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await _pumpUntil(tester, find.byType(UnifiedLearnerTopBar));
}

Future<void> _selectBundledCourse(WidgetTester tester, String code) async {
  await _openCoursePicker(tester);
  await _tapBundledCourse(tester, code);
}

Future<void> _openCoursePicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('unified-topbar-course-selector')));
  await _pumpUntil(tester, find.text('Choose course'));
  // The bundled Napoletano row resolves its World Flag asynchronously and
  // legitimately shows an indeterminate progress indicator in the meantime.
  // Waiting for the whole tree to settle would therefore conflate that asset
  // load with the bottom-sheet transition under test.
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> _tapBundledCourse(WidgetTester tester, String code) async {
  final tile = find.byKey(ValueKey('bundled-course-$code'));
  await _revealCourseTile(tester, tile);
  tester.widget<ListTile>(tile).onTap!();
  await tester.pump();
}

Future<void> _selectCustomCourse(WidgetTester tester, String courseId) async {
  await _openCoursePicker(tester);
  await _tapCustomCourse(tester, courseId);
}

Future<void> _tapCustomCourse(WidgetTester tester, String courseId) async {
  final tile = find.byKey(ValueKey('local-course-$courseId'));
  await _revealCourseTile(tester, tile);
  tester.widget<ListTile>(tile).onTap!();
  await tester.pump();
}

Future<void> _revealCourseTile(WidgetTester tester, Finder tile) async {
  final selectorScroll = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(tile, 300, scrollable: selectorScroll);
  await tester.ensureVisible(tile);
  await tester.pump();
}

String _activeCourseId(WidgetTester tester) => tester
    .widget<UnifiedLearnerTopBar>(find.byType(UnifiedLearnerTopBar))
    .course
    .courseId;

Future<void> _pumpUntilCourse(WidgetTester tester, String courseId) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (find.byType(UnifiedLearnerTopBar).evaluate().isNotEmpty &&
        _activeCourseId(tester) == courseId) {
      return;
    }
  }
  fail('Timed out waiting for course $courseId.');
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder.');
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out waiting for $finder to disappear.');
}

class _BlockingFlagBackgroundProfileService extends ProfileService {
  String? _blockedCourseId;
  Completer<void>? _flagReadStarted;
  Completer<void>? _releaseFlagRead;

  bool get flagReadStarted => _flagReadStarted?.isCompleted ?? false;

  void blockNextFlagReadFor(String courseId) {
    _blockedCourseId = courseId;
    _flagReadStarted = Completer<void>();
    _releaseFlagRead = Completer<void>();
  }

  void releaseFlagRead() {
    final release = _releaseFlagRead;
    if (release != null && !release.isCompleted) release.complete();
  }

  @override
  Future<LearnerFlagBackgroundMode> getFlagBackgroundModeForProfile(
    String idOrDisplayName,
    String courseId,
  ) async {
    if (_blockedCourseId == courseId) {
      _blockedCourseId = null;
      final started = _flagReadStarted;
      final release = _releaseFlagRead;
      if (started != null && !started.isCompleted) started.complete();
      if (release != null) await release.future;
    }
    return super.getFlagBackgroundModeForProfile(idOrDisplayName, courseId);
  }
}
