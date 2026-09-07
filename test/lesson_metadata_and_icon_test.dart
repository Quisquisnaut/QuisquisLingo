import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_catalog.dart';
import 'package:quisquislingo_app/widgets/lesson_fallback_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _sectionPicker() => find.byWidgetPredicate(
  (widget) =>
      widget is DropdownButtonFormField<String> &&
      widget.decoration.labelText == 'Section',
);

Future<void> _openSectionChoice(WidgetTester tester, String choice) async {
  if (_sectionPicker().evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      _sectionPicker(),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('lesson-metadata-controls')),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 20,
    );
  }
  await tester.ensureVisible(_sectionPicker());
  await tester.pumpAndSettle();
  await tester.tap(_sectionPicker());
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice).last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every approved Lesson icon decodes as a 256 px square PNG', (
    tester,
  ) async {
    expect(LessonIconCatalog.assetPaths, hasLength(14));
    expect(
      LessonIconCatalog.options.map((option) => option.id).toSet(),
      hasLength(LessonIconCatalog.options.length),
    );
    expect(
      LessonIconCatalog.options.map((option) => option.label).toSet(),
      hasLength(LessonIconCatalog.options.length),
    );
    await tester.runAsync(() async {
      for (final assetPath in LessonIconCatalog.assetPaths) {
        expect(assetPath, startsWith(LessonIconCatalog.directory));
        expect(assetPath, endsWith('.png'));
        final bytes = await rootBundle.load(assetPath);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 256, reason: assetPath);
        expect(frame.image.height, 256, reason: assetPath);
        frame.image.dispose();
        codec.dispose();
      }
    });
  });

  test('Course Audit rejects an unapproved Lesson icon reference', () {
    final course = _course(
      Lesson(
        lessonId: 'lesson',
        title: 'Lesson',
        rounds: const [],
        themeIconAsset: 'assets/lesson_icons/not_in_catalog.png',
      ),
    );
    final result = CourseAuditService().auditCourse(course);
    expect(
      result.issues.where((issue) => issue.code == 'LESSON_THEME_ICON_INVALID'),
      hasLength(1),
    );
  });

  testWidgets('visual icon picker exposes the full catalog at 320 px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final lesson = Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LessonEditorScreen(course: _course(lesson), lesson: lesson),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('lesson-theme-icon-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('lesson-theme-icon-field')));
    await _pumpFrames(tester);

    final gridFinder = find.byKey(const Key('lesson-theme-icon-grid'));
    final grid = tester.widget<GridView>(gridFinder);
    expect(
      grid.childrenDelegate.estimatedChildCount,
      LessonIconCatalog.options.length + 1,
    );
    expect(find.byType(EditableText), findsNothing);
    await tester.drag(gridFinder, const Offset(0, -1000));
    await _pumpFrames(tester);
    final last = LessonIconCatalog.options.last;
    final lastTile = find.byKey(
      ValueKey('lesson-theme-icon-option-${last.id}'),
    );
    expect(lastTile, findsOneWidget);
    expect(
      find.descendant(of: lastTile, matching: find.text(last.label)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: lastTile, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Lesson editor requires Section names and returns controlled icon metadata',
    (tester) async {
      Lesson? saved;
      final lesson = Lesson(
        lessonId: 'lesson',
        publicationState: PublicationState.draft,
        title: 'Lesson',
        rounds: const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<Lesson>(
                  MaterialPageRoute(
                    builder: (_) => LessonEditorScreen(
                      course: _course(lesson),
                      lesson: lesson,
                    ),
                  ),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open editor'));
      await _pumpFrames(tester);
      expect(find.textContaining('Topic'), findsNothing);
      expect(find.byKey(const Key('lesson-section-name')), findsNothing);

      await _openSectionChoice(tester, 'Add new section...');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(find.text('Add new section'), findsOneWidget);
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '  Travel  ',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byKey(const Key('lesson-metadata-controls')),
        const Offset(0, -500),
        2000,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson-theme-icon-field')));
      await _pumpFrames(tester);
      expect(find.byKey(const Key('lesson-theme-icon-grid')), findsOneWidget);
      expect(find.text('None'), findsWidgets);
      await tester.drag(
        find.byKey(const Key('lesson-theme-icon-grid')),
        const Offset(0, -240),
      );
      await _pumpFrames(tester);
      await tester.tap(
        find.byKey(const ValueKey('lesson-theme-icon-option-train')),
      );
      await _pumpFrames(tester);
      await tester.drag(
        find.byKey(const Key('lesson-metadata-controls')),
        const Offset(0, -180),
      );
      await _pumpFrames(tester);
      final preview = find.byKey(const Key('lesson-theme-icon-preview'));
      expect(preview, findsOneWidget);
      expect(tester.widget<Image>(preview).fit, BoxFit.contain);

      await tester.tap(find.byKey(const Key('save-lesson-draft')));
      await _pumpFrames(tester);
      expect(saved, isNotNull);
      expect(saved!.section, isTrue);
      expect(saved!.sectionName, 'Travel');
      expect(saved!.themeIconAsset, 'assets/lesson_icons/train.png');
      final json = saved!.toJson();
      expect(json['lessonId'], 'lesson');
      expect(json.containsKey('id'), isFalse);
      expect(json['section'], isTrue);
      expect(json['sectionName'], 'Travel');
      expect(json['themeIconAsset'], 'assets/lesson_icons/train.png');
    },
  );

  testWidgets('Lesson editor None and disabled Section serialize canonically', (
    tester,
  ) async {
    Lesson? saved;
    final lesson = Lesson(
      lessonId: 'lesson',
      publicationState: PublicationState.draft,
      title: 'Lesson',
      rounds: const [],
      section: true,
      sectionName: 'Travel',
      themeIconAsset: 'assets/lesson_icons/train.png',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<Lesson>(
                MaterialPageRoute(
                  builder: (_) => LessonEditorScreen(
                    course: _course(lesson),
                    lesson: lesson,
                  ),
                ),
              );
            },
            child: const Text('Open editor'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open editor'));
    await _pumpFrames(tester);
    await tester.drag(
      find.byKey(const Key('lesson-metadata-controls')),
      const Offset(0, -500),
    );
    await _pumpFrames(tester);
    expect(find.byKey(const Key('lesson-theme-icon-preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('lesson-theme-icon-field')));
    await _pumpFrames(tester);
    await tester.tap(
      find.byKey(const ValueKey('lesson-theme-icon-option-none')),
    );
    await _pumpFrames(tester);
    expect(find.byKey(const Key('lesson-theme-icon-preview')), findsNothing);
    expect(
      find.byKey(const Key('lesson-theme-icon-fallback-preview')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const Key('lesson-metadata-controls')),
      const Offset(0, 500),
    );
    await _pumpFrames(tester);
    await _openSectionChoice(tester, 'No section');
    expect(find.byKey(const Key('lesson-section-name')), findsNothing);
    await tester.tap(find.byKey(const Key('save-lesson-draft')));
    await _pumpFrames(tester);

    expect(saved!.section, isFalse);
    expect(saved!.sectionName, isNull);
    expect(saved!.themeIconAsset, isNull);
    final json = saved!.toJson();
    expect(json['section'], isFalse);
    expect(json.containsKey('sectionName'), isFalse);
    expect(json.containsKey('themeIconAsset'), isFalse);
  });

  for (final catalogAction in ['Add', 'Manage']) {
    testWidgets(
      'Imported Lesson icon survives $catalogAction Section catalog and Draft Save',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final documents = Directory.systemTemp.createTempSync(
          'qql_section_icon_',
        );
        addTearDown(() => documents.deleteSync(recursive: true));
        final imports = Directory(
          '${documents.path}/QuisquisLingo/Imports/Lesson Icons',
        )..createSync(recursive: true);
        File(
          'assets/lesson_icons/home.png',
        ).copySync('${imports.path}/home.png');
        const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          pathChannel,
          (_) async => documents.path,
        );
        addTearDown(
          () => messenger.setMockMethodCallHandler(pathChannel, null),
        );
        final lesson = Lesson(
          lessonId: 'imported-icon-lesson',
          publicationState: PublicationState.draft,
          title: 'Imported icon',
          rounds: const [],
        );
        final source = Course.fromJson({
          ..._course(lesson).toJson(),
          'sectionNames': ['Unused'],
        });
        final sourceJson = jsonEncode(source.toJson());
        Course? changed;
        Lesson? saved;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  saved = await Navigator.of(context).push<Lesson>(
                    MaterialPageRoute(
                      builder: (_) => LessonEditorScreen(
                        course: source,
                        lesson: lesson,
                        onCourseChanged: (course) => changed = course,
                      ),
                    ),
                  );
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        final iconField = find.byKey(const Key('lesson-theme-icon-field'));
        await tester.scrollUntilVisible(
          iconField,
          200,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 20,
        );
        await tester.tap(iconField);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(find.byKey(const Key('import-custom-lesson-icon')));
          for (var attempt = 0; attempt < 100; attempt++) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            await tester.pump();
            if (find
                .text('Custom icon imported and normalized to a 256x256 PNG.')
                .evaluate()
                .isNotEmpty) {
              return;
            }
          }
          fail('The actual Lesson icon import did not complete.');
        });
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(changed, isNull, reason: 'The imported asset is still pending.');
        if (catalogAction == 'Add') {
          await _openSectionChoice(tester, 'Add new section...');
          await tester.enterText(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextField),
            ),
            ' Travel ',
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Add'));
        } else {
          await _openSectionChoice(tester, 'Manage sections...');
          await tester.tap(find.byTooltip('Remove Unused'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(TextButton, 'Close'));
        }
        await tester.pumpAndSettle();
        expect(changed, isNotNull);
        final imported = changed!.lessonIconAssets.single;
        CourseLessonIconAsset.validateCanonicalPng(imported.base64Png);
        await tester.tap(find.byKey(const Key('save-lesson-draft')));
        await tester.pumpAndSettle();
        expect(saved, isNotNull);
        expect(saved!.themeIconAsset, imported.reference);
        expect(saved!.publicationState, PublicationState.draft);
        expect(changed!.lessonIconAssets.single.toJson(), imported.toJson());
        expect(changed!.lessons.single.themeIconAsset, imported.reference);
        expect(
          changed!.sectionNames,
          catalogAction == 'Add' ? ['Unused', 'Travel'] : isEmpty,
        );
        final reloaded = Course.fromJson(
          jsonDecode(jsonEncode(changed!.toJson())) as Map<String, dynamic>,
        );
        expect(reloaded.lessonIconAssets.single.base64Png, imported.base64Png);
        expect(reloaded.lessons.single.themeIconAsset, imported.reference);
        expect(
          CourseAuditService()
              .auditCourse(reloaded)
              .issues
              .where((issue) => issue.code == 'LESSON_THEME_ICON_INVALID'),
          isEmpty,
        );
        expect(jsonEncode(source.toJson()), sourceJson);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Lesson editor links to one draft-preserving Round management subpage',
    (tester) async {
      Lesson? saved;
      final first = LearningRound(
        id: 'round-a',
        title: 'First title',
        exercises: const [],
      );
      final second = LearningRound(
        id: 'round-b',
        title: 'Round 2',
        exercises: const [],
      );
      final lesson = Lesson(
        lessonId: 'lesson',
        publicationState: PublicationState.draft,
        title: 'Original title',
        rounds: [first, second],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                saved = await Navigator.of(context).push<Lesson>(
                  MaterialPageRoute(
                    builder: (_) => LessonEditorScreen(
                      course: _course(lesson),
                      lesson: lesson,
                    ),
                  ),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open editor'));
      await _pumpFrames(tester);
      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.byKey(const ValueKey('round-a')), findsNothing);

      final titleControl = find.byKey(const Key('lesson-title-control'));
      await tester.ensureVisible(titleControl);
      await tester.pumpAndSettle();
      await tester.tap(titleControl);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Draft title');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      await _openSectionChoice(tester, 'Add new section...');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Draft Section',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      await tester.fling(
        find.byKey(const Key('lesson-metadata-controls')),
        const Offset(0, 1000),
        2000,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonRoundsScreen), findsOneWidget);
      expect(find.text('Rounds · Lesson 1: Draft title'), findsOneWidget);
      expect(find.byKey(const ValueKey('round-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('round-b')), findsOneWidget);

      await tester.tap(find.text('New round'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'New draft round');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      expect(find.text('New draft round'), findsOneWidget);

      final firstHandle = find.descendant(
        of: find.byKey(const ValueKey('round-a')),
        matching: find.byIcon(Icons.drag_handle),
      );
      await tester.drag(firstHandle, const Offset(0, 220));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('round-b'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('round-a'))).dy),
      );

      final newRoundCard = find.ancestor(
        of: find.text('New draft round'),
        matching: find.byType(Card),
      );
      await tester.tap(
        find.descendant(
          of: newRoundCard,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete round?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('New draft round'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('round-a')));
      await tester.pumpAndSettle();
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LessonRoundsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(find.text('Draft title'), findsWidgets);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(_sectionPicker())
            .initialValue,
        'name:Draft Section',
      );
      await tester.tap(find.byKey(const Key('save-lesson-draft')));
      await tester.pumpAndSettle();
      expect(saved!.rounds.map((round) => round.id), ['round-b', 'round-a']);
      expect(saved!.title, 'Draft title');
      expect(saved!.sectionName, 'Draft Section');
    },
  );

  testWidgets(
    'Lessons owns the live fallback number preview and preserves its selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final course = _course(
        Lesson(
          lessonId: 'fallback-lesson',
          title: 'No explicit icon',
          rounds: const [],
        ),
      );
      SharedPreferences.setMockInitialValues({
        'course_editor_locked_${course.courseId.toUpperCase()}': false,
      });
      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Course Info Editor'));
      await tester.pumpAndSettle();
      expect(find.text('Fallback lesson number icons'), findsNothing);
      expect(find.text('Theme-colored circle'), findsNothing);
      expect(find.text('Four-color circle'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('lesson-management-lock')))
            .isSelected,
        isFalse,
      );
      expect(
        find.byKey(const Key('lesson-fallback-theme-colored-preview')),
        findsOneWidget,
      );
      expect(find.text('Fallback lesson number icons'), findsOneWidget);
      expect(find.text('Theme-colored circle'), findsOneWidget);
      final monochromeAvatar = tester.widget<CircleAvatar>(
        find.descendant(
          of: find.byKey(const Key('lesson-fallback-theme-colored-preview')),
          matching: find.byType(CircleAvatar),
        ),
      );
      expect(
        monochromeAvatar.backgroundColor,
        Theme.of(
          tester.element(find.byKey(const Key('lesson-appearance-settings'))),
        ).colorScheme.primaryContainer,
      );
      expect(
        find.byKey(const Key('lesson-fallback-four-color-preview')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const Key('lesson-fallback-number-style')),
      );
      await tester.pumpAndSettle();
      final styleDropdown = find.descendant(
        of: find.byKey(const Key('lesson-fallback-number-style')),
        matching: find.byType(DropdownButton<LessonFallbackIconStyle>),
      );
      expect(
        tester
            .widget<DropdownButton<LessonFallbackIconStyle>>(styleDropdown)
            .onChanged,
        isNotNull,
      );
      await tester.tap(styleDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Four-color circle').hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('lesson-fallback-four-color-preview')),
        findsOneWidget,
      );
      final coloredBoxes = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byKey(const Key('lesson-fallback-four-color-preview')),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((box) => box.color)
          .toSet();
      expect(coloredBoxes, containsAll(LessonFallbackIcon.originalColors));
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CourseEditorScreen), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('lesson-fallback-four-color-preview')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Explicit custom icons do not change'),
        findsOneWidget,
      );
      final saved = Course.fromJson({
        ...course.toJson(),
        'defaultLessonIconStyle': 'coloredLessonNumbers',
      });
      final reloaded = Course.fromJson(saved.toJson());
      expect(
        reloaded.defaultLessonIconStyle,
        LessonFallbackIconStyle.coloredLessonNumbers,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test('fallback mode does not alter an explicit multicolored custom icon', () {
    final png = base64Encode(
      File('assets/lesson_icons/home.png').readAsBytesSync(),
    );
    final asset = CourseLessonIconAsset(
      assetId: 'multicolored-fixture',
      base64Png: png,
    );
    final base = _course(
      Lesson(
        lessonId: 'custom-icon-lesson',
        title: 'Custom icon',
        themeIconAsset: asset.reference,
        rounds: const [],
      ),
    );
    final source = Course.fromJson({
      ...base.toJson(),
      'lessonIconAssets': [asset.toJson()],
      'defaultLessonIconStyle': 'monochrome',
    });
    final colored = Course.fromJson({
      ...source.toJson(),
      'defaultLessonIconStyle': 'coloredLessonNumbers',
    });
    expect(colored.lessons.single.themeIconAsset, asset.reference);
    expect(colored.lessonIconAssets.single.base64Png, png);
    expect(source.lessonIconAssets.single.base64Png, png);
    expect(
      colored.defaultLessonIconStyle,
      LessonFallbackIconStyle.coloredLessonNumbers,
    );
  });
}

Course _course(Lesson lesson) => Course(
  courseId: 'course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [lesson],
);

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 75));
  }
}
