import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/world_flag_entity.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/course_entry_animation.dart';
import 'package:quisquislingo_app/widgets/unified_learner_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CourseEntryAnimationPolicy', () {
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

    test('missing or invalid JSON flags never gain a fallback', () async {
      for (final destination in [
        _course(id: 'missing'),
        _course(id: 'invalid-code', flagCode: 'ZZ'),
        _course(id: 'invalid-world', worldFlagId: 'not-in-manifest'),
      ]) {
        final request = await CourseEntryAnimationPolicy.requestForSwitch(
          currentCourseId: 'course-a',
          destination: destination,
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

  testWidgets('rendering is a restrained 680 ms fade using the resolved flag', (
    tester,
  ) async {
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
    await tester.pump(const Duration(milliseconds: 679));
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 2));
    expect(completed, isTrue);
  });

  group('Home course-switch wiring', () {
    setUp(() async {
      for (final asset in CourseService.courseAssets.values) {
        rootBundle.evict(asset);
      }
      SharedPreferences.setMockInitialValues({
        'one_time_notice_seen_welcome_2.0.28+228': true,
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
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);

        await _selectBundledCourse(tester, 'KO');
        await _pumpUntilCourse(tester, 'sample_ko_en_ko');
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
      },
    );

    testWidgets(
      'Do Not Disturb and a missing JSON flag both switch immediately',
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
        await _pumpUntilCourse(tester, 'sample_de_en_de');
        expect(find.byKey(const Key('course-entry-animation')), findsNothing);
        expect(await SettingsService().getLastSelectedCourseCode(), 'DE');
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
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
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
  await tester.tap(find.byKey(const Key('unified-topbar-course-selector')));
  await _pumpUntil(tester, find.text('Choose course'));
  final tile = find.byKey(ValueKey('bundled-course-$code'));
  tester.widget<ListTile>(tile).onTap!();
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
