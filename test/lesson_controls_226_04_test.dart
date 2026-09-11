import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:quisquislingo_app/services/lesson_presentation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Course course({List<Lesson>? lessons, List<String> sections = const []}) =>
    Course(
      courseId: 'controls',
      learningLanguage: 'it',
      interfaceLanguage: 'en',
      sourceLanguage: 'en',
      targetLanguage: 'it',
      title: 'Controls',
      ttsLanguage: 'it-IT',
      version: '1',
      sectionNames: sections,
      lessons:
          lessons ??
          [Lesson(lessonId: 'stable-lesson', title: 'Greetings', rounds: [])],
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  for (final title in ['Greetings', 'Lesson 1']) {
    for (final entry in {
      LessonNumberingMode.lesson: title == 'Greetings'
          ? 'Lesson 1: Greetings'
          : 'Lesson 1',
      LessonNumberingMode.numberOnly: title == 'Greetings'
          ? '1: Greetings'
          : '1',
      LessonNumberingMode.none: title,
    }.entries) {
      test('${entry.key.name} presents $title without changing it', () {
        final original = course(
          lessons: [Lesson(lessonId: 'identity', title: title, rounds: [])],
        );
        final selected = Course.fromJson({
          ...original.toJson(),
          'lessonNumberingMode': entry.key.name,
        });
        expect(
          const LessonPresentationService().identity(selected, 0).fullText,
          entry.value,
        );
        expect(Course.fromJson(selected.toJson()).lessons.single.title, title);
        expect(selected.lessons.single.lessonId, 'identity');
      });
    }
  }

  testWidgets(
    'Lessons keeps Search, Help and IDs as its upper actions at 320 px',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: LessonManagementScreen(
            course: course(),
            initiallyLocked: false,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byKey(const Key('lessons-search-action'));
      expect(tester.widget(search), isA<IconButton>());
      expect(
        find.ancestor(of: search, matching: find.byType(AppBar)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('lesson-management-lock')), findsNothing);
      expect(find.byTooltip('Search the whole course'), findsOneWidget);
      expect(find.byTooltip('Editor Help'), findsOneWidget);
      expect(find.text('Fallback lesson number icons'), findsNothing);
      expect(find.text('Four-color circle'), findsNothing);
      expect(
        find.byTooltip('Internal IDs hidden. Tap to show'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      final lessonEntry = find.byKey(
        const ValueKey('lesson-entry-stable-lesson'),
      );
      await tester.tap(lessonEntry);
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(find.byKey(const Key('lesson-search-action')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'GuideBook passive selectable full ID follows all its actions and toggles immediately',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final source = course();
      await tester.pumpWidget(
        MaterialApp(
          home: LessonEditorScreen(
            course: source,
            lesson: source.lessons.single,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final id = source.lessons.single.guidebookId;
      final line = find.byKey(ValueKey('editor-internal-id-$id'));
      expect(line, findsNothing);
      await tester.tap(find.byTooltip('Internal IDs hidden. Tap to show'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        line,
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('lesson-metadata-controls')),
          matching: find.byType(Scrollable),
        ).first,
      );
      expect(
        tester.widget<SelectableText>(line).style?.fontFamily,
        'monospace',
      );
      expect(find.byTooltip(id), findsOneWidget);
      final generator = find.byKey(const Key('guidebook-round-generator'));
      expect(
        tester.getTopLeft(line).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(generator).dy),
      );
      expect(
        find.ancestor(of: line, matching: find.byType(ListTile)),
        findsNothing,
      );
      await tester.tap(line);
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Internal IDs shown. Tap to hide'));
      await tester.pumpAndSettle();
      expect(line, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Section picker selects, creates trimmed catalog names and protects used names',
    (tester) async {
      var latest = course(sections: ['Basics', 'Unused']);
      await tester.pumpWidget(
        MaterialApp(
          home: LessonEditorScreen(
            course: latest,
            lesson: latest.lessons.single,
            onCourseChanged: (value) => latest = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder picker() => find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.decoration.labelText == 'Section',
      );
      await tester.scrollUntilVisible(
        picker(),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('lesson-metadata-controls')),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(picker());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new section...').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '  Travel  ',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(latest.sectionNames, ['Basics', 'Unused', 'Travel']);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Save as draft'));
      await tester.pumpAndSettle();
      // Saving a published Lesson as Draft requires the existing confirmation.
      final confirm = find.widgetWithText(TextButton, 'Save as draft');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
        await tester.pumpAndSettle();
      }
      expect(latest.lessons.single.sectionName, 'Travel');
    },
  );

  testWidgets(
    'actual GuideBook route preserves derived ID after its Save actions without writing content',
    (tester) async {
      final source = course();
      final before = source.toJson();
      await tester.pumpWidget(
        MaterialApp(
          home: LessonEditorScreen(
            course: source,
            lesson: source.lessons.single,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Internal IDs hidden. Tap to show'));
      await tester.pumpAndSettle();
      final navigation = find.byKey(const Key('lesson-guidebook-navigation'));
      await tester.ensureVisible(navigation);
      await tester.pumpAndSettle();
      await tester.tap(navigation);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<GuidebookEditorScreen>(find.byType(GuidebookEditorScreen))
            .guidebookId,
        source.lessons.single.guidebookId,
      );
      final line = find.byKey(
        ValueKey('editor-internal-id-${source.lessons.single.guidebookId}'),
      );
      await tester.scrollUntilVisible(
        line,
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<SelectableText>(line).style?.fontFamily,
        'monospace',
      );
      for (final key in ['guidebook-save-draft', 'guidebook-save']) {
        expect(
          tester.getTopLeft(line).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(find.byKey(Key(key))).dy),
        );
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(source.toJson(), before);
    },
  );

  testWidgets(
    'used Section reports exact Lesson count; unused Section can be removed immediately',
    (tester) async {
      var latest = course(
        sections: ['Basics', 'Unused'],
        lessons: [
          for (var i = 0; i < 4; i++)
            Lesson(
              lessonId: 'lesson-$i',
              title: 'Lesson $i',
              rounds: [],
              section: true,
              sectionName: 'Basics',
            ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LessonEditorScreen(
            course: latest,
            lesson: latest.lessons.first,
            onCourseChanged: (value) => latest = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(_sectionPicker())
            .initialValue,
        'name:Basics',
      );
      await _chooseSection(tester, 'Manage sections...');
      await tester.tap(find.byTooltip('Remove Basics'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This section is used by 4 Lessons.\nRemove or change those assignments first.',
        ),
        findsOneWidget,
      );
      expect(latest.availableSectionNames, ['Basics', 'Unused']);
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove Unused'));
      await tester.pumpAndSettle();
      expect(latest.sectionNames, ['Basics']);
      expect(
        latest.lessons.every((lesson) => lesson.sectionName == 'Basics'),
        isTrue,
      );
      expect(find.byTooltip('Remove Unused'), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, 'Close'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(_sectionPicker())
            .initialValue,
        'name:Basics',
      );
      expect(
        tester.state<FormFieldState<String>>(_sectionPicker()).value,
        'name:Basics',
      );
    },
  );

  testWidgets(
    'cancel adding Section preserves assignment and catalog; surrounding spaces reuse existing name',
    (tester) async {
      var latest = course(sections: ['Basics']);
      await tester.pumpWidget(
        MaterialApp(
          home: LessonEditorScreen(
            course: latest,
            lesson: latest.lessons.single,
            onCourseChanged: (value) => latest = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _chooseSection(tester, 'Add new section...');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Discard me',
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(latest.sectionNames, ['Basics']);
      expect(latest.lessons.single.sectionName, isNull);
      expect(
        tester.state<FormFieldState<String>>(_sectionPicker()).value,
        'none',
      );
      await _chooseSection(tester, 'Add new section...');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '  Basics  ',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(latest.sectionNames, ['Basics']);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(_sectionPicker())
            .initialValue,
        'name:Basics',
      );
    },
  );

  for (final previous in ['Travel', '', 'first']) {
    testWidgets(
      'new Lesson inherits preceding Section or No section: $previous',
      (tester) async {
        var latest = course(
          lessons: previous == 'first'
              ? []
              : [
                  Lesson(
                    lessonId: 'preceding',
                    title: 'Preceding',
                    rounds: [],
                    section: previous.isNotEmpty,
                    sectionName: previous.isEmpty ? null : previous,
                  ),
                ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: LessonManagementScreen(
              course: latest,
              initiallyLocked: false,
              onCourseChanged: (value) => latest = value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FloatingActionButton, 'New lesson'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          'Next Lesson',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Create'));
        await tester.pumpAndSettle();
        final created = latest.lessons.last;
        expect(created.title, 'Next Lesson');
        expect(created.section, previous == 'Travel');
        expect(created.sectionName, previous == 'Travel' ? 'Travel' : null);
        expect(created.rounds, isEmpty);
        expect(created.lessonId, isNot('preceding'));
        expect(created.publicationState, PublicationState.draft);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'GuideBook and Duel switches update in Edit and are protected in View',
    (tester) async {
      final source = course(sections: ['Retain']);
      var latest = source;
      await tester.pumpWidget(
        MaterialApp(
          home: LessonManagementScreen(
            course: source,
            initiallyLocked: false,
            onCourseChanged: (value) => latest = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in ['course-use-guidebook', 'course-create-duels']) {
        final toggle = find.byKey(Key(key));
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      }
      expect(latest.useGuidebook, isFalse);
      expect(latest.createDuels, isFalse);
      expect(latest.sectionNames, ['Retain']);
      expect(latest.lessons.single.toJson(), source.lessons.single.toJson());
      final reloaded = Course.fromJson(latest.toJson());
      expect(reloaded.useGuidebook, isFalse);
      expect(reloaded.createDuels, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          home: LessonManagementScreen(
            key: const ValueKey('readonly-lessons'),
            course: latest,
            initiallyLocked: false,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in ['course-use-guidebook', 'course-create-duels']) {
        expect(
          tester.widget<SwitchListTile>(find.byKey(Key(key))).onChanged,
          isNull,
        );
      }
      await tester.pumpWidget(
        MaterialApp(
          home: LessonManagementScreen(
            key: const ValueKey('editable-lessons'),
            course: latest,
            initiallyLocked: false,
            onCourseChanged: (value) => latest = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in ['course-use-guidebook', 'course-create-duels']) {
        final toggle = find.byKey(Key(key));
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }
      expect(latest.useGuidebook, isTrue);
      expect(latest.createDuels, isTrue);
      expect(latest.lessons.single.toJson(), source.lessons.single.toJson());
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _sectionPicker() => find.byWidgetPredicate(
  (widget) =>
      widget is DropdownButtonFormField<String> &&
      widget.decoration.labelText == 'Section',
);

Future<void> _chooseSection(WidgetTester tester, String choice) async {
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
