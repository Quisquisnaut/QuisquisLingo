import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/world_flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'creation offers all sources and Automatic stores no explicit override',
    (tester) async {
      await _pumpManager(tester);
      await _openCreation(tester);

      await _openDropdown(tester, 'Flag source');
      for (final source in const [
        'Automatic',
        'Existing QQL course flags',
        'World Flags',
        'Custom uploaded flag',
      ]) {
        expect(find.text(source), findsWidgets);
      }
      await tester.tap(find.text('Automatic').last);
      await tester.pumpAndSettle();

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
    await _chooseDropdown(
      tester,
      label: 'Flag source',
      option: 'Existing QQL course flags',
    );
    await _chooseDropdown(tester, label: 'Course flag', option: 'Wales (CY)');

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
      await _chooseDropdown(
        tester,
        label: 'Flag source',
        option: 'World Flags',
      );

      final chooseWorldFlag = find.byKey(const Key('choose-world-flag'));
      await tester.ensureVisible(chooseWorldFlag);
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(chooseWorldFlag);
        await tester.pump();
        await WorldFlagRepository().load();
      });
      await _pumpRouteTransition(tester);
      expect(
        find.byKey(const Key('world-flag-picker-search')),
        findsOneWidget,
        reason: find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' | '),
      );
      await tester.enterText(
        find.byKey(const Key('world-flag-picker-search')),
        'GB-WLS',
      );
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('world-flag-option-wales')));
        await WorldFlagRepository().load();
      });
      await _pumpRouteTransition(tester);
      expect(find.text('Choose a World Flag'), findsNothing);

      final preview = tester.widget<WorldFlagArt>(find.byType(WorldFlagArt));
      expect(preview.entity.id, 'wales');
      await _enterBasics(tester, title: 'World Wales flag', target: 'Welsh');
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Create'));
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
    await _chooseDropdown(
      tester,
      label: 'Flag source',
      option: 'Custom uploaded flag',
    );
    final importButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Import flag'),
    );
    await tester.runAsync(() async {
      // Image decoding uses the engine's real async codec. Invoke and await the
      // handler here so the widget-test fake clock cannot stall it.
      final operation = (importButton.onPressed as dynamic)();
      if (operation is Future) await operation;
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('96×64 → 96×64 PNG'), findsOneWidget);

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

    expect(find.text('Course Manager'), findsOneWidget);
    expect(find.byType(CourseEditorScreen), findsNothing);
    expect(await CourseEditorService().listUserCourses(), isEmpty);
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
      const storedBefore = '{}';
      SharedPreferences.setMockInitialValues({
        CourseEditorService.userCoursesStorageKey: storedBefore,
      });
      var writes = 0;
      final service = CourseEditorService(
        preferenceWriter: (preferences, key, value) async {
          writes++;
          return preferences.setString(key, value);
        },
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
      final preferences = await SharedPreferences.getInstance();
      expect(writes, 0);
      expect(
        preferences.getString(CourseEditorService.userCoursesStorageKey),
        storedBefore,
      );
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
  await tester.pumpAndSettle();
}

Future<void> _openCreation(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('create-course-icon-action')));
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
  await tester.tap(find.widgetWithText(FilledButton, 'Create'));
  await tester.pumpAndSettle();
  expect(find.byType(CourseEditorScreen), findsOneWidget);
}

Future<void> _pumpRouteTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Finder _textField(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _openDropdown(WidgetTester tester, String label) async {
  final field = find.byWidgetPredicate(
    (widget) =>
        widget is DropdownButtonFormField<String> &&
        widget.decoration.labelText == label,
  );
  expect(field, findsOneWidget);
  await tester.ensureVisible(field);
  await tester.pump();
  await tester.tap(field);
  await tester.pumpAndSettle();
}

Future<void> _chooseDropdown(
  WidgetTester tester, {
  required String label,
  required String option,
}) async {
  await _openDropdown(tester, label);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

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
  version: '1',
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
