import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/app_metadata.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/course_entry_animation.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/unified_learner_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    for (final asset in CourseService.courseAssets.values) {
      rootBundle.evict(asset);
    }
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => throw PlatformException(code: 'test-storage'),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final arguments = call.arguments as Map<Object?, Object?>;
          _installEventChannelMock(
            messenger,
            'xyz.luan/audioplayers/events/${arguments['playerId']}',
          );
        }
        return null;
      },
    );
    _installEventChannelMock(messenger, 'xyz.luan/audioplayers.global/events');
    SharedPreferences.setMockInitialValues({
      'one_time_notice_seen_welcome_${AppMetadata.technicalVersion}': true,
      'sound_effects_enabled': false,
      CourseService.bundledCourseIndexStorageKey: const [
        'IT',
        'DE',
        'ES',
        'EN',
        'CY',
        'NL',
        'PT',
        'FI',
      ],
    });
    await ProfileService().addProfile('Existing Korean tester');
    await SettingsService().setAudioExercisesEnabled(false);
  });

  testWidgets(
    'existing v6 installation discovers, opens, and retains one Korean bundled course through the real selector',
    (tester) async {
      await SettingsService().setAudioExercisesEnabled(true);
      await SettingsService().setTtsEnabled(true);
      final custom = _customCourse();
      await CourseEditorService().saveUserCourse(custom);
      final progress = ProgressService();
      await progress.completeRound(
        'preserved-round',
        courseId: 'preserved-course',
        courseCode: 'IT',
      );

      await _openHome(tester);
      await _openCoursePicker(tester);
      _expectNineBundledTiles();
      final koreanTile = find.byKey(const ValueKey('bundled-course-KO'));
      expect(koreanTile, findsOneWidget);
      expect(
        find.descendant(
          of: koreanTile,
          matching: find.text('AI-Slop Demo: Korean for English Speakers'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: koreanTile,
          matching: find.text('English → Korean · Bundled official'),
        ),
        findsOneWidget,
      );
      final flag = tester.widget<FlagBadge>(
        find.descendant(of: koreanTile, matching: find.byType(FlagBadge)),
      );
      // The selector keeps the KO registry route, while its course-aware
      // badge uses the unchanged persisted KR flag (the same Korean artwork).
      expect(flag.code, 'KR');

      final selectorScrollable = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        koreanTile,
        180,
        scrollable: selectorScrollable,
      );
      await tester.drag(selectorScrollable, const Offset(0, -120));
      await tester.pumpAndSettle();
      await tester.tap(koreanTile);
      await _pumpIo(tester, frames: 30);
      expect(find.byType(BottomSheet), findsNothing);
      await tester.pump(
        CourseEntryAnimationPolicy.duration + const Duration(milliseconds: 50),
      );
      final topBar = tester.widget<UnifiedLearnerTopBar>(
        find.byType(UnifiedLearnerTopBar),
      );
      expect(topBar.course.courseId, 'sample_ko_en_ko');
      expect(topBar.course.title, 'AI-Slop Demo: Korean for English Speakers');
      expect(topBar.course.sourceLanguage, 'English');
      expect(topBar.course.targetLanguage, 'Korean');
      expect(topBar.course.flagCode, 'KR');
      expect(topBar.course.ttsLanguage, 'ko-KR');
      expect(topBar.course.lessons, hasLength(9));

      final firstLesson = topBar.course.lessons.first;
      final firstRound = firstLesson.rounds.first;
      final roundCard = find.byKey(ValueKey('unified-round-${firstRound.id}'));
      await tester.ensureVisible(roundCard);
      await tester.tap(roundCard);
      await _pumpIo(tester, frames: 20);
      final roundScreen = tester.widget<RoundScreen>(find.byType(RoundScreen));
      expect(roundScreen.course.courseId, 'sample_ko_en_ko');
      expect(roundScreen.lesson.lessonId, firstLesson.lessonId);
      expect(roundScreen.round.id, firstRound.id);
      expect(roundScreen.ttsLanguage, 'ko-KR');
      Navigator.of(tester.element(find.byType(RoundScreen))).pop();
      await _pumpIo(tester, frames: 12);

      final duelCard = find.byKey(
        ValueKey('unified-duel-${firstLesson.lessonId}'),
      );
      await tester.ensureVisible(duelCard);
      await tester.tap(duelCard);
      await _pumpIo(tester, frames: 20);
      final duelScreen = tester.widget<DuelScreen>(find.byType(DuelScreen));
      expect(duelScreen.course.courseId, 'sample_ko_en_ko');
      expect(duelScreen.lesson.lessonId, firstLesson.lessonId);
      expect(duelScreen.ttsLanguage, 'ko-KR');
      Navigator.of(tester.element(find.byType(DuelScreen))).pop();
      await _pumpIo(tester, frames: 12);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpIo(tester, frames: 4);
      await _openHome(tester);
      final restartedTopBar = tester.widget<UnifiedLearnerTopBar>(
        find.byType(UnifiedLearnerTopBar),
      );
      expect(restartedTopBar.course.courseId, 'sample_ko_en_ko');
      await _openCoursePicker(tester);
      _expectNineBundledTiles();
      expect(find.byKey(const ValueKey('bundled-course-KO')), findsOneWidget);
      await _expectCourseTile(
        tester,
        ValueKey('local-course-${custom.courseId}'),
        custom.title,
        selected: false,
      );

      final preferences = await SharedPreferences.getInstance();
      final reconciled = preferences.getStringList(
        CourseService.bundledCourseIndexStorageKey,
      );
      expect(reconciled, CourseService.courseAssets.keys);
      expect(reconciled!.where((code) => code == 'KO'), hasLength(1));
      expect(
        (await CourseEditorService().listUserCourses()).map(
          (course) => course.courseId,
        ),
        contains(custom.courseId),
      );
      expect(
        await progress.getCompletedRounds(courseId: 'preserved-course'),
        contains('preserved-round'),
      );
    },
  );

  for (final width in [320.0, 800.0]) {
    for (final selectCustom in [false, true]) {
      testWidgets(
        'course selector uses actual titles for every entry at width $width with ${selectCustom ? 'custom' : 'bundled'} selected',
        (tester) async {
          final custom = _customCourse();
          final otherCustom = Course.fromJson({
            ...custom.toJson(),
            'courseId': 'other_selector_custom_course',
            'title': 'A custom course title that is longer than Esperanto',
          });
          final editor = CourseEditorService();
          await editor.saveUserCourse(custom);
          await editor.saveUserCourse(otherCustom);
          final settings = SettingsService();
          for (final ref in [
            'custom:${otherCustom.courseId}',
            'EN',
            'DE',
            selectCustom ? 'custom:${custom.courseId}' : 'IT',
          ]) {
            await settings.setLastSelectedCourseCode(ref);
          }

          await _openHome(tester, width: width);
          await _openCoursePicker(tester);
          await _expectCourseTile(
            tester,
            const Key('current-course'),
            selectCustom
                ? custom.title
                : 'AI-Slop Demo: Italian for English Speakers',
            selected: true,
          );
          for (final entry in {
            'DE': 'AI-Slop Demo: German for English Speakers',
            'EN': 'AI-Slop Demo: Inglés para hispanohablantes',
            'custom:${otherCustom.courseId}': otherCustom.title,
          }.entries) {
            await _expectCourseTile(
              tester,
              ValueKey('recent-course-${entry.key}'),
              entry.value,
              selected: false,
            );
          }
          await _expectCourseTile(
            tester,
            const ValueKey('bundled-course-IT'),
            'AI-Slop Demo: Italian for English Speakers',
            selected: !selectCustom,
          );
          await _expectCourseTile(
            tester,
            const ValueKey('bundled-course-DE'),
            'AI-Slop Demo: German for English Speakers',
            selected: false,
          );
          await _expectCourseTile(
            tester,
            const ValueKey('bundled-course-EN'),
            'AI-Slop Demo: Inglés para hispanohablantes',
            selected: false,
          );
          await _expectCourseTile(
            tester,
            ValueKey('local-course-${otherCustom.courseId}'),
            otherCustom.title,
            selected: false,
          );
          await _expectCourseTile(
            tester,
            ValueKey('local-course-${custom.courseId}'),
            custom.title,
            selected: selectCustom,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

void _installEventChannelMock(
  TestDefaultBinaryMessenger messenger,
  String channel,
) {
  messenger.setMockMessageHandler(channel, (message) async {
    return const StandardMethodCodec().encodeSuccessEnvelope(null);
  });
}

Future<void> _openHome(WidgetTester tester, {double width = 1200}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  final alphaNotice = find.text('Alpha expiry');
  await _pumpUntilWithIo(tester, alphaNotice);
  await tester.tap(find.widgetWithText(FilledButton, 'OK'));
  await _pumpUntilWithIo(tester, find.byType(UnifiedLearnerTopBar));
}

Future<void> _expectCourseTile(
  WidgetTester tester,
  Key key,
  String title, {
  required bool selected,
}) async {
  final tileFinder = find.byKey(key);
  await tester.scrollUntilVisible(
    tileFinder,
    180,
    scrollable: find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    ),
  );
  final tile = tester.widget<ListTile>(tileFinder);
  expect((tile.title! as Text).data, title);
  expect(
    find.descendant(of: tileFinder, matching: find.byIcon(Icons.check)),
    selected ? findsOneWidget : findsNothing,
  );
  expect(
    find.descendant(of: tileFinder, matching: find.byTooltip('Course actions')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: tileFinder, matching: find.text(title)),
    findsOneWidget,
  );
  expect(
    tester.getSize(tileFinder).width,
    lessThanOrEqualTo(tester.view.physicalSize.width),
  );
  expect(tester.takeException(), isNull);
}

Future<void> _openCoursePicker(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('unified-topbar-course-selector')));
  await _pumpUntilWithIo(tester, find.text('Choose course'));
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilWithIo(WidgetTester tester, Finder finder) async {
  for (var frame = 0; frame < 160; frame++) {
    await _pumpIo(tester, frames: 1);
    if (finder.evaluate().isNotEmpty) return;
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data);
  fail('Timed out waiting for $finder. Visible text: $visibleText');
}

void _expectNineBundledTiles() {
  for (final code in CourseService.courseAssets.keys) {
    expect(find.byKey(ValueKey('bundled-course-$code')), findsOneWidget);
  }
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('bundled-course-'),
    ),
    findsNWidgets(9),
  );
}

Future<void> _pumpIo(WidgetTester tester, {required int frames}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Course _customCourse() => Course(
  courseId: 'user_preserved_during_korean_reconciliation',
  publicationState: PublicationState.published,
  learningLanguage: 'Esperanto',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Esperanto',
  title: 'Preserved custom course',
  ttsLanguage: 'eo',
  lessons: const [],
);
