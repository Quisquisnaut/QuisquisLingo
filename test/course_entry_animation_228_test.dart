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
import 'package:quisquislingo_app/widgets/unified_learner_top_bar.dart';
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
      'flagless bundled German resolves the established DE fallback',
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

    test('a missing JSON flag uses the established course fallback', () async {
      final request = await CourseEntryAnimationPolicy.requestForSwitch(
        currentCourseId: 'course-a',
        destination: _course(id: 'missing'),
        fallbackCode: 'DE',
        animationsEnabled: true,
        reducedMotion: false,
      );

      expect(request?.kind, CourseEntryFlagKind.builtIn);
      expect(request?.identifier, 'DE');
    });

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
        'one_time_notice_seen_welcome_2.0.28+2281': true,
        'sound_effects_enabled': false,
      });
      await ProfileService().addProfile('Course Switch Learner');
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

        tester
            .widget<ListTile>(
              find.byKey(const ValueKey('local-course-explicit-custom')),
            )
            .onTap!();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump(const Duration(milliseconds: 1));

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

        await tester.pump(CourseEntryAnimationPolicy.duration);
        await tester.pump();
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);

        await _selectBundledCourse(tester, 'KO');
        await _pumpUntilCourse(tester, 'sample_ko_en_ko');
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
      },
    );

    testWidgets(
      'Do Not Disturb suppresses while a missing JSON flag uses fallback',
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
}) => Course(
  courseId: id,
  learningLanguage: learningLanguage,
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: targetLanguage,
  title: 'Course $id',
  ttsLanguage: 'en',
  version: '1',
  flagCode: flagCode,
  worldFlagId: worldFlagId,
  flagImageBase64: flagImageBase64,
  lessons: const [],
);

Future<void> _openHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await _pumpUntil(tester, find.text('Alpha expiry'));
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
}

Future<void> _tapBundledCourse(WidgetTester tester, String code) async {
  final tile = find.byKey(ValueKey('bundled-course-$code'));
  tester.widget<ListTile>(tile).onTap!();
  await tester.pump();
}

Future<void> _selectCustomCourse(WidgetTester tester, String courseId) async {
  await _openCoursePicker(tester);
  tester
      .widget<ListTile>(find.byKey(ValueKey('local-course-$courseId')))
      .onTap!();
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
