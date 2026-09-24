import 'dart:convert';
import 'dart:io';

import 'support/pump_file_io.dart';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_flag_selection.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/course_flag_picker.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/world_flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'creation shared chooser exposes all sources and Automatic stores no override',
    (tester) async {
      await _pumpManager(tester);
      await _openCreation(tester);
      await _openCourseFlagChooser(tester);
      expect(find.text('Use Automatic'), findsOneWidget);
      expect(find.text('Upload custom flag'), findsOneWidget);
      expect(find.text('Flags from installed QQL courses'), findsNothing);
      final search = find.byKey(const Key('course-flag-picker-search'));
      await tester.enterText(search, 'qql-flagpainter-english');
      await tester.pump();
      expect(find.text('QQL FlagPainter Flags'), findsOneWidget);
      await tester.enterText(search, 'world:france');
      await tester.pump();
      expect(find.text('WORLD Flags'), findsOneWidget);
      await tester.tap(find.byKey(const Key('course-flag-picker-automatic')));
      await _settleFlagSelection(tester);

      await _enterBasics(tester, title: 'Automatic flag', target: 'Italian');
      await _create(tester);

      final course = _editorCourse(tester);
      expect(course.flagCode, isEmpty);
      expect(course.worldFlagId, isEmpty);
      expect(course.flagImageBase64, isEmpty);
    },
  );

  testWidgets('Existing QQL source preserves the legacy Welsh CY meaning', (
    tester,
  ) async {
    await _pumpManager(tester);
    await _openCreation(tester);
    await _openCourseFlagChooser(tester);
    await tester.enterText(
      find.byKey(const Key('course-flag-picker-search')),
      'qql-flagpainter-welsh',
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('course-flag-option-qql-flagpainter-welsh')),
    );
    await _settleFlagSelection(tester);
    final selectionPreview = tester.widget<CourseFlagSelectionPreview>(
      find.byType(CourseFlagSelectionPreview),
    );
    expect(selectionPreview.selection.builtInCode, 'CY');

    await _enterBasics(tester, title: 'Legacy Welsh flag', target: 'Welsh');
    await _create(tester);

    final course = _editorCourse(tester);
    expect(course.flagCode, 'CY');
    expect(course.worldFlagId, isEmpty);
    expect(course.flagImageBase64, isEmpty);
    final badge = tester.widget<CourseFlagBadge>(
      find.byType(CourseFlagBadge).first,
    );
    expect(badge.course.flagCode, 'CY');
  });

  testWidgets(
    'World Flags selection previews and reaches the editor as SVG identity',
    (tester) async {
      // The production manifest is large enough for loadString to parse it on
      // an isolate. Complete that real asynchronous work before the picker is
      // built inside the widget-test fake clock.
      await tester.runAsync(() async {
        await WorldFlagRepository().load();
      });
      await _pumpManager(tester);
      await _openCreation(tester);
      await _openCourseFlagChooser(tester);
      expect(
        find.byKey(const Key('course-flag-picker-search')),
        findsOneWidget,
        reason: find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' | '),
      );
      await tester.enterText(
        find.byKey(const Key('course-flag-picker-search')),
        'GB-WLS',
      );
      await tester.pumpAndSettle();
      final walesOption = find.byKey(
        const ValueKey('course-flag-option-world:wales'),
      );
      expect(
        walesOption,
        findsOneWidget,
        reason: find
            .byType(Text)
            .evaluate()
            .map((element) => (element.widget as Text).data)
            .whereType<String>()
            .join(' | '),
      );
      await tester.tap(walesOption);
      await _settleFlagSelection(tester);
      final selectionPreview = tester.widget<CourseFlagSelectionPreview>(
        find.byType(CourseFlagSelectionPreview),
      );
      expect(selectionPreview.selection.worldFlagId, 'wales');
      await _enterBasics(tester, title: 'World Wales flag', target: 'Welsh');
      await tester.runAsync(() async {
        await tester.tap(
          find.widgetWithText(FilledButton, 'Continue to Editor'),
        );
        await tester.pump();
        await WorldFlagRepository().load();
      });
      await _pumpRouteTransition(tester);
      expect(find.byType(CourseEditorScreen), findsOneWidget);
      await tester.pump();

      final course = _editorCourse(tester);
      expect(course.worldFlagId, 'wales');
      expect(course.flagCode, isEmpty);
      expect(course.flagImageBase64, isEmpty);
      final appBarArt = tester.widget<WorldFlagArt>(find.byType(WorldFlagArt));
      expect(appBarArt.entity.id, 'wales');
      expect(
        find.byKey(const ValueKey('course-world-flag-wales')),
        findsOneWidget,
      );
    },
  );

  testWidgets('Custom uploaded source embeds the converted PNG only', (
    tester,
  ) async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    final documents = (await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_course_flag_create_',
      );
      final imports = Directory(
        '${directory.path}${Platform.pathSeparator}QuisquisLingo'
        '${Platform.pathSeparator}Exports',
      );
      await imports.create(recursive: true);
      await File(
        '${imports.path}${Platform.pathSeparator}flag.png',
      ).writeAsBytes(await _png(width: 96, height: 64), flush: true);
      return directory;
    }))!;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => documents.path);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      if (await documents.exists()) await documents.delete(recursive: true);
    });

    await _pumpManager(tester);
    await _openCreation(tester);
    await _openCourseFlagChooser(tester);
    final importButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Upload custom flag'),
    );
    await tester.runAsync(() async {
      // Image decoding uses the engine's real async codec. Invoke and await the
      // handler here so the widget-test fake clock cannot stall it.
      final operation = (importButton.onPressed as dynamic)();
      if (operation is Future) await operation;
    });
    await tester.pumpAndSettle();
    final selectionPreview = tester.widget<CourseFlagSelectionPreview>(
      find.byType(CourseFlagSelectionPreview),
    );
    expect(
      selectionPreview.selection.kind,
      CourseFlagSelectionKind.customImage,
    );

    await _enterBasics(tester, title: 'Custom image flag', target: 'Custom');
    await _create(tester);

    final course = _editorCourse(tester);
    expect(course.flagImageBase64, isNotEmpty);
    expect(base64Decode(course.flagImageBase64).take(8), const [
      0x89,
      0x50,
      0x4e,
      0x47,
      13,
      10,
      26,
      10,
    ]);
    expect(course.flagCode, isEmpty);
    expect(course.worldFlagId, isEmpty);
  });

  testWidgets('cancelling creation leaves the manager without a new course', (
    tester,
  ) async {
    await _pumpManager(tester);
    await _openCreation(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Course Studio'), findsOneWidget);
    expect(find.byType(CourseEditorScreen), findsNothing);
    expect(
      (await tester.runAsync(() => CourseEditorService().listUserCourses()))!,
      isEmpty,
    );
  });

  test(
    'course JSON import rejects an unavailable World Flag and keeps source',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_missing_world_flag_import_',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });
      final source = File(
        '${directory.path}${Platform.pathSeparator}import.json',
      );
      final payload = jsonEncode(
        _baseCourse(worldFlagId: 'removed_world_flag').toJson(),
      );
      await source.writeAsString(payload, flush: true);
      final transfer = CustomCourseTransferService(
        importDirectory: () async => directory,
      );

      await expectLater(
        transfer.importCourse(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('World Flag "removed_world_flag" is unavailable'),
          ),
        ),
      );
      expect(await source.exists(), isTrue);
      expect(await source.readAsString(), payload);
    },
  );

  test(
    'confirmation rejects an unavailable World Flag before profile or writes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'qql_flag_write_',
      );
      addTearDown(() => directory.delete(recursive: true));
      SharedPreferences.setMockInitialValues({});
      var writes = 0;
      final service = CourseEditorService(
        courseStore: CourseFileStore(
          supportDirectory: () async => directory,
          fileWriter: (file, contents) async {
            writes++;
            await file.writeAsString(contents, flush: true);
          },
        ),
      );
      final original = _baseCourse();
      final working = Course.fromJson({
        ...original.toJson(),
        'worldFlagId': 'removed_world_flag',
      });

      await expectLater(
        service.confirmCourseTransaction(
          originalCourse: original,
          workingCourse: working,
          languageCode: 'IT',
          versionNotes: 'must remain a working copy',
          isNewCourse: true,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('World Flag "removed_world_flag" is unavailable'),
          ),
        ),
      );
      expect(writes, 0);
      expect(await service.listUserCourses(), isEmpty);
      expect(await directory.list().toList(), isEmpty);
    },
  );
}

Future<void> _pumpManager(WidgetTester tester) async {
  const profileId = '12345678-1234-4234-9234-123456789abc';
  SharedPreferences.setMockInitialValues({
    ProfileService.profilesKey: [
      const LearnerProfile(
        learnerProfileId: profileId,
        displayName: 'Flag Author',
      ).encode(),
    ],
    ProfileService.activeProfileIdKey: profileId,
  });
  await tester.pumpWidget(
    MaterialApp(home: CourseProjectsScreen(currentCourse: _baseCourse())),
  );
  await tester.pumpUntilFileIoState(
    () =>
        find
            .byKey(const Key('create-course-icon-action'))
            .evaluate()
            .isNotEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty,
  );
}

Future<void> _openCreation(WidgetTester tester) async {
  // Reload assets in the real async zone used by this dialog setup.
  rootBundle.clear();
  await tester.runAsync(() async {
    await WorldFlagRepository().loadManifest();
    await tester.tap(find.byKey(const Key('create-course-icon-action')));
    final service = CourseService();
    await Future.wait(
      CourseService.courseAssets.keys.map(service.loadBundledCourse),
    );
    // Let the action consume the same cached asset loads and schedule the
    // dialog route before returning to the widget-test fake clock.
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Create new course'),
    ),
    findsOneWidget,
  );
}

Future<void> _openCourseFlagChooser(WidgetTester tester) async {
  final button = find.byKey(const Key('course-flag-selector-open'));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await _pumpRouteTransition(tester);
  await tester.pump();
  expect(find.byKey(const Key('course-flag-picker-search')), findsOneWidget);
  expect(find.byKey(const Key('course-flag-picker-results')), findsOneWidget);
}

Future<void> _enterBasics(
  WidgetTester tester, {
  required String title,
  required String target,
}) async {
  final titleField = _textField('Course title *');
  await tester.ensureVisible(titleField);
  await tester.pump();
  await tester.enterText(titleField, title);
  final targetField = _textField('Target language *');
  await tester.ensureVisible(targetField);
  await tester.pump();
  await tester.enterText(targetField, target);
}

Future<void> _create(WidgetTester tester) async {
  final create = find.widgetWithText(FilledButton, 'Continue to Editor');
  await tester.ensureVisible(create);
  await tester.pump();
  final button = tester.widget<FilledButton>(create);
  await tester.runAsync(() async {
    final operation = (button.onPressed as dynamic)();
    if (operation is Future) await operation;
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
  await _pumpRouteTransition(tester);
  await tester.pumpAndSettle();
  expect(
    find.byType(CourseEditorScreen),
    findsOneWidget,
    reason: find
        .byType(Text)
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .whereType<String>()
        .join(' | '),
  );
}

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> _settleFlagSelection(WidgetTester tester) async {
  await _pumpRouteTransition(tester);
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Finder _textField(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Course _editorCourse(WidgetTester tester) =>
    tester.widget<CourseEditorScreen>(find.byType(CourseEditorScreen)).course;

Course _baseCourse({String worldFlagId = ''}) => Course(
  courseId: 'course-creation-flags-base',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Current course',
  ttsLanguage: 'it-IT',
  worldFlagId: worldFlagId,
  lessons: const [],
);

Future<Uint8List> _png({required int width, required int height}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xffcc3344),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
