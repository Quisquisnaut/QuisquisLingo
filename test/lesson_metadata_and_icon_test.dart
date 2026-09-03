import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_catalog.dart';

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
    await tester.drag(
      find.byKey(const Key('lesson-metadata-controls')),
      const Offset(0, -420),
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

      final sectionToggle = find.byKey(const Key('lesson-section-toggle'));
      await tester.ensureVisible(sectionToggle);
      await _pumpFrames(tester);
      await tester.tap(sectionToggle);
      await _pumpFrames(tester);
      expect(find.byKey(const Key('lesson-section-name')), findsOneWidget);
      await tester.tap(find.byKey(const Key('save-lesson')));
      await tester.pump();
      expect(find.text('Enter a Section name.'), findsOneWidget);
      expect(find.byType(LessonEditorScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('lesson-section-name')),
        '  Travel  ',
      );
      await tester.drag(
        find.byKey(const Key('lesson-metadata-controls')),
        const Offset(0, -420),
      );
      await _pumpFrames(tester);
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

      await tester.tap(find.byKey(const Key('save-lesson')));
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
    await tester.drag(
      find.byKey(const Key('lesson-metadata-controls')),
      const Offset(0, 500),
    );
    await _pumpFrames(tester);
    final sectionToggle = find.byKey(const Key('lesson-section-toggle'));
    await tester.ensureVisible(sectionToggle);
    await _pumpFrames(tester);
    await tester.tap(sectionToggle);
    await _pumpFrames(tester);
    expect(find.byKey(const Key('lesson-section-name')), findsNothing);
    await tester.tap(find.byKey(const Key('save-lesson')));
    await _pumpFrames(tester);

    expect(saved!.section, isFalse);
    expect(saved!.sectionName, isNull);
    expect(saved!.themeIconAsset, isNull);
    final json = saved!.toJson();
    expect(json['section'], isFalse);
    expect(json.containsKey('sectionName'), isFalse);
    expect(json.containsKey('themeIconAsset'), isFalse);
  });

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

      await tester.tap(find.byKey(const Key('lesson-title-control')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Draft title');
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson-section-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('lesson-section-name')),
        'Draft Section',
      );

      await tester.drag(
        find.byKey(const Key('lesson-metadata-controls')),
        const Offset(0, -600),
      );
      await _pumpFrames(tester);
      await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonRoundsScreen), findsOneWidget);
      expect(find.text('Rounds · Draft title'), findsOneWidget);
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
            .widget<TextField>(find.byKey(const Key('lesson-section-name')))
            .controller!
            .text,
        'Draft Section',
      );
      await tester.tap(find.byKey(const Key('save-lesson')));
      await tester.pumpAndSettle();
      expect(saved!.rounds.map((round) => round.id), ['round-b', 'round-a']);
      expect(saved!.title, 'Draft title');
      expect(saved!.sectionName, 'Draft Section');
    },
  );
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
